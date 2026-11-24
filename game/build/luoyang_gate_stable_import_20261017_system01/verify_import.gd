extends SceneTree
## Isolated four textures only. ROOT copies this verifier into the isolated same-res-path project.
const SOURCE_READY=true
const PREPARED_SHA="ad0ad8f8dd8ee8fc5c2c25e46b8063393c1fec1d825594eb7709f16c102646f5"
const WHOLE_MS=30000
var failures: Array[String]=[]
var rows: Array[Dictionary]=[]
var first: Dictionary={}
func _initialize() -> void: call_deferred("_run")
func require(ok: bool,label: String) -> bool:
	if not ok: failures.append(label)
	return ok
func sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new();context.start(HashingContext.HASH_SHA256);context.update(bytes);return context.finish().hex_encode()
func source(path: String,expected: String) -> bool:
	var actual: String=FileAccess.get_sha256(path)
	if not require(expected.length()==64 and actual==expected.to_lower(),"Exact source "+path): return false
	first[path]=actual;return true
func decoded(image: Image) -> Image:
	if image==null: return null
	if image.is_compressed() and not require(image.decompress()==OK,"Native lossless decode"): return null
	image.convert(Image.FORMAT_RGBA8);return image
func _run() -> void:
	var began:=Time.get_ticks_msec()
	var prepared: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://prepared.json"))
	if require(SOURCE_READY,"Draft fail-closed until exact SYSTEM prepared freeze") and source("res://prepared.json",PREPARED_SHA) and require(prepared is Dictionary and prepared.get("rows",[]).size()==4 and prepared.get("params23",{}).size()==23,"Exactly four prepared textures"):
		var identities: Dictionary={}
		for item: Dictionary in prepared.rows:
			if not require(Time.get_ticks_msec()-began<WHOLE_MS,"Fixed30s budget"): break
			var path: String=item.texture
			if not require(not identities.has(item.id) and path.begins_with("res://") and ".." not in path,"Unique exact safe identity"): continue
			identities[item.id]=true
			if not source(path,item.source_sha256) or not source(item.old_import_snapshot,item.old_import_sha256) or not source(item.new_import_path,item.new_import_sha256) or not source(item.expected_compiled_snapshot,item.expected_compiled_sha256): continue
			var old: String=FileAccess.get_file_as_string(item.old_import_snapshot)
			var current: String=FileAccess.get_file_as_string(item.new_import_path)
			if not require(old.count("detect_3d/compress_to=1")==1 and old.replace("detect_3d/compress_to=1","detect_3d/compress_to=0")==current,"Only historical detect3D1->0 exact text; no remap/mip/normal relax "+path): continue
			var config:=ConfigFile.new()
			if not require(config.load(item.new_import_path)==OK and config.get_section_keys("params").size()==23 and prepared.params23.size()==23,"Actual exact23 settings "+path): continue
			var params_ok:=true
			for key: String in item.params23:
				if not require(config.get_value("params",key,null)==item.params23[key],"Strict parameter "+path+":"+key): params_ok=false
			var compiled: String=config.get_value("remap","path","")
			if not require(compiled==item.compiled_path and config.get_value("deps","source_file","")==path and config.get_value("deps","dest_files",PackedStringArray())==PackedStringArray([compiled]) and not config.has_section_key("remap","path.s3tc"),"Ordinary non-VRAM exact remap/deps "+path): continue
			if not source(compiled,item.expected_compiled_sha256): continue
			var texture: Texture2D=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
			var direct:=CompressedTexture2D.new();var historical:=CompressedTexture2D.new()
			if not require(texture!=null and direct.load(compiled)==OK and historical.load(item.expected_compiled_snapshot)==OK,"Native current/import/direct/historical compiled available "+path): continue
			var raw: Image=decoded(Image.load_from_file(path));var imported: Image=decoded(texture.get_image());var binary: Image=decoded(direct.get_image());var original_binary: Image=decoded(historical.get_image())
			var equal:=false;var rgba: String="";var size:=Vector2i(int(item.size_px[0]),int(item.size_px[1]))
			if raw!=null and imported!=null and binary!=null and original_binary!=null:
				equal=raw.get_size()==size and imported.get_size()==size and binary.get_size()==size and original_binary.get_size()==size and raw.get_data()==imported.get_data() and raw.get_data()==binary.get_data() and raw.get_data()==original_binary.get_data()
				rgba=sha(raw.get_data())
				require(imported.get_mipmap_count()==0 and binary.get_mipmap_count()==0 and original_binary.get_mipmap_count()==0,"All native no-mip "+path)
			require(equal,"Complete source/import/direct/original compiled RGBA exact "+path)
			rows.append({"id":item.id,"texture":path,"source_sha256":FileAccess.get_sha256(path),"old_import_sha256":item.old_import_sha256,"import_path":item.new_import_path,"import_sha256":FileAccess.get_sha256(item.new_import_path),"compiled_path":compiled,"compiled_sha256":FileAccess.get_sha256(compiled),"original_compiled_sha256":item.expected_compiled_sha256,"original_ctex_byte_exact":FileAccess.get_sha256(compiled)==item.expected_compiled_sha256,"rgba_sha256":rgba,"size_px":item.size_px,"full_rgba_exact":equal,"params23":params_ok,"mipmap_count":imported.get_mipmap_count() if imported!=null else -1})
	for path: String in first: require(FileAccess.get_sha256(path)==first[path],"Own source unchanged "+path)
	require(Time.get_ticks_msec()-began<WHOLE_MS,"Whole30s finite verification")
	var passed: bool=failures.is_empty() and rows.size()==4
	var output: String="res://gate_import_result_%d.json"%OS.get_process_id()
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify({"passed":passed,"failures":failures,"rows":rows,"elapsed_ms":Time.get_ticks_msec()-began,"prepared_sha256":FileAccess.get_sha256("res://prepared.json"),"script_sha256":FileAccess.get_sha256(get_script().resource_path),"source_first":first,"scope":"ISOLATED_EXACT4_IMPORT_NO_GAME_WRITE_OR_FIELD"},"\t",true,true));file.close()
	else: passed=false
	print(JSON.stringify({"passed":passed,"output":output,"failures":failures}))
	quit(0 if passed else 1)
