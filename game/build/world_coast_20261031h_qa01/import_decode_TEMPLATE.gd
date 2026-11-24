extends SceneTree
## Reuses30m full-source-vs-actual-ctex RGBA proof, isolated project only.
const FIXTURE_SHA: String="__FIXTURE_SHA__"
func _initialize() -> void:_run.call_deferred()
func _rgba(data: PackedByteArray) -> String:
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(data);return hash.finish().hex_encode()
func _run() -> void:
	var errors: Array[String]=[];var rows: Array=[];var checks:=0
	var directory: String="res://decode_actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	if FileAccess.get_sha256("res://import_fixture.json")!=FIXTURE_SHA:errors.append("EXACT_FIXTURE_SHA")
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://import_fixture.json")) as Dictionary
	for row: Dictionary in fixture.textures:
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
		if params_ok:
			params_ok=config.get_section_keys("params").size()==fixture.params.size() and config.get_value("remap","path","")==row.compiled_path and config.get_value("deps","source_file","")==path
			for key: String in fixture.params:params_ok=params_ok and config.get_value("params",key,null)==fixture.params[key]
		checks+=1
		if not params_ok:errors.append("APPROVED_LOSSLESS_EXACT_PARAMS_AND_PATH:"+path);break
		source.convert(Image.FORMAT_RGBA8);decoded.convert(Image.FORMAT_RGBA8)
		var raw: PackedByteArray=source.get_data();var actual: PackedByteArray=decoded.get_data();var raw_sha: String=_rgba(raw);var decoded_sha: String=_rgba(actual)
		checks+=1
		var equal: bool=raw==actual and raw_sha==row.rgba_sha256 and FileAccess.get_sha256(path)==row.sha256
		rows.append({"path":path,"png_sha256":FileAccess.get_sha256(path),"import_sha256":FileAccess.get_sha256(path+".import"),"compiled_path":row.compiled_path,"compiled_sha256":FileAccess.get_sha256(String(row.compiled_path)),"size":[source.get_width(),source.get_height()],"source_RGBA_sha256":raw_sha,"actual_compiled_RGBA_sha256":decoded_sha,"full_RGBA_exact":equal,"mipmap_count":decoded.get_mipmap_count()})
		if not equal:errors.append("EVERY_RGBA8_BYTE_SOURCE_AND_COMPILED_EXACT:"+path);break
	var passed: bool=errors.is_empty() and rows.size()==29
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":passed,"checks":checks,"errors":errors,"rows":rows,"fixture_sha256":FIXTURE_SHA,"isolated_no_autoloads":true,"real_save_API_calls":0,"production_writes":0},"\t"));file.close()
	print(JSON.stringify({"passed":passed,"checks":checks,"errors":errors,"row_count":rows.size(),"report":directory+"/result.json"}))
	quit(0 if passed else 1)
