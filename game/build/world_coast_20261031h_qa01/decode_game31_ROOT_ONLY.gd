extends SceneTree
## Existing editor-created NEW leaves: inspect actual bytes, never overwrite imports.
const FIXTURE: String="res://build/world_coast_20261031h_qa01/import_isolated02/import_fixture.json"
const FIXTURE_SHA: String="20fc6eeb7e0940939fbbde9bb6ba355ba5cc20d4efa0599f6668b213131a7226"
var suspended:=false
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge":node.call("set_checkpoint_saves_suspended",true);suspended=bool(node.call("is_checkpoint_saves_suspended"))
func _rgba(data: PackedByteArray) -> String:
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(data);return hash.finish().hex_encode()
func _run() -> void:
	await process_frame
	var errors: Array[String]=[];var rows: Array=[];var checks:=0
	var directory: String="res://build/world_coast_20261031h_qa01/decode_game31_actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	if not suspended:errors.append("CHECKPOINT_NOT_SUSPENDED")
	if FileAccess.get_sha256(FIXTURE)!=FIXTURE_SHA:errors.append("EXACT_FIXTURE_SHA")
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)) as Dictionary
	for row: Dictionary in fixture.textures:
		if not errors.is_empty():break
		var path: String=String(row.path);var texture: Texture2D=load(path) as Texture2D
		var source:=Image.load_from_file(path);var decoded: Image=texture.get_image() if texture!=null else null
		checks+=1
		if source==null or decoded==null:errors.append("SOURCE_AND_REAL_TEXTURE_LOAD:"+path);break
		if decoded.is_compressed():decoded.decompress()
		checks+=1
		if source.get_width()!=int(row.size[0]) or source.get_height()!=int(row.size[1]) or decoded.get_size()!=source.get_size():errors.append("ACTUAL_NATIVE_SIZE:"+path);break
		checks+=1
		if source.has_mipmaps() or decoded.has_mipmaps() or decoded.get_mipmap_count()!=0:errors.append("MIP0:"+path);break
		var config:=ConfigFile.new();var params_ok: bool=config.load(path+".import")==OK
		var differences: Array=[]
		if params_ok:
			params_ok=config.get_value("remap","path","")==row.compiled_path and config.get_value("deps","source_file","")==path and int(config.get_value("params","compress/mode",-1))==0
			for key: String in fixture.params:
				if config.get_value("params",key,null)!=fixture.params[key]:differences.append({"key":key,"fixture":fixture.params[key],"actual":config.get_value("params",key,null)})
		checks+=1
		if not params_ok:errors.append("ACTUAL_LOSSLESS_AND_EXACT_PATH:"+path);break
		source.convert(Image.FORMAT_RGBA8);decoded.convert(Image.FORMAT_RGBA8)
		var raw: PackedByteArray=source.get_data();var actual: PackedByteArray=decoded.get_data();var raw_sha: String=_rgba(raw);var decoded_sha: String=_rgba(actual)
		checks+=1
		var equal: bool=raw==actual and raw_sha==row.rgba_sha256 and FileAccess.get_sha256(path)==row.sha256
		rows.append({"path":path,"png_sha256":FileAccess.get_sha256(path),"import_sha256":FileAccess.get_sha256(path+".import"),"compiled_path":row.compiled_path,"compiled_sha256":FileAccess.get_sha256(String(row.compiled_path)),"size":[source.get_width(),source.get_height()],"source_RGBA_sha256":raw_sha,"actual_compiled_RGBA_sha256":decoded_sha,"full_RGBA_exact":equal,"mipmap_count":decoded.get_mipmap_count(),"actual_editor_params_differences_from_isolated":differences})
		if not equal:errors.append("EVERY_RGBA8_BYTE_SOURCE_AND_COMPILED_EXACT:"+path);break
	var passed: bool=errors.is_empty() and rows.size()==29
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":passed,"checks":checks,"errors":errors,"rows":rows,"fixture_sha256":FIXTURE_SHA,"actual_main_game_compiled_leaves":true,"editor_generated_new_leaves_preserved_not_overwritten":true,"checkpoint_suspended":suspended,"real_save_API_calls":0,"production_writes":0,"engine_import_requested":false},"\t"));file.close()
	print(JSON.stringify({"passed":passed,"checks":checks,"errors":errors,"row_count":rows.size(),"report":directory+"/result.json"}))
	quit(0 if passed else 1)
