extends SceneTree
## ROOT-only one PNG, native ResourceLoader + direct CTEX fullRGBA proof.
## Independent project: no game autoloads, no geometry replay, no save writes.
const LIMIT_MS: int=30000
const PREPARED_SHA: String="4c86409c68c8a959778132a7e3fa2be827e50b0e1637d4378ada3ac764f8bb28"
var _started: int=0
var failures: Array=[]
var rows: Array=[]
func _initialize() -> void: call_deferred("_run")
func _require(value: bool,label: String) -> void:
	if not value: failures.append(label)
func _sha(bytes: PackedByteArray) -> String:
	var hash: HashingContext=HashingContext.new()
	hash.start(HashingContext.HASH_SHA256); hash.update(bytes)
	return hash.finish().hex_encode()
func _run() -> void:
	_started=Time.get_ticks_msec()
	_require(FileAccess.get_sha256("res://prepared.json")==PREPARED_SHA,"prepared_exact_sha")
	var prepared: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://prepared.json"))
	if not prepared is Dictionary or prepared.get("texture")!="res://build/luoyang_spacing_publication_20261017p/67340_1837/walk.png" or prepared.get("params23",{}).size()!=23:
		failures.append("prepared_schema")
	else:
		var path: String=String(prepared.texture)
		_require(FileAccess.get_sha256(path)==prepared.source_sha256,"cpu_png_exact_sha")
		_require(FileAccess.get_sha256(prepared.cpu_result_path)==prepared.cpu_result_sha256,"cpu_result_exact_original_bytes")
		_require(FileAccess.get_sha256(prepared.cpu_manifest_path)==prepared.cpu_manifest_sha256,"cpu_manifest_exact_original_bytes")
		var cpu: Variant=JSON.parse_string(FileAccess.get_file_as_string(prepared.cpu_result_path))
		var manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(prepared.cpu_manifest_path))
		_require(cpu is Dictionary and cpu.get("passed")==true and cpu.get("walk_path")==path and cpu.get("walk_sha256")==prepared.source_sha256,"passed_cpu_identity")
		_require(manifest is Dictionary and manifest.get("walk_path")==path and manifest.get("walk_sha256")==prepared.source_sha256 and manifest.get("walk_rgba_sha256")==prepared.rgba_sha256,"manifest_pixels_identity")
		var config: ConfigFile=ConfigFile.new()
		if config.load(path+".import")!=OK:
			failures.append("import_load")
		else:
			var exact_params: bool=config.get_section_keys("params").size()==23
			_require(exact_params,"exact23params_count")
			for key: String in prepared.params23:
				var matches: bool=config.get_value("params",key,null)==prepared.params23[key]
				exact_params=exact_params and matches; _require(matches,"param:"+key)
			var compiled: String=String(config.get_value("remap","path",""))
			_require(compiled==prepared.compiled_path and FileAccess.file_exists(compiled),"exact_compiled_identity")
			_require(config.get_value("remap","importer","")=="texture" and config.get_value("remap","type","")=="CompressedTexture2D","import_type")
			_require(config.get_value("deps","source_file","")==path,"deps_source_identity")
			var dest: Variant=config.get_value("deps","dest_files",null)
			_require((dest is Array or dest is PackedStringArray) and dest.size()==1 and String(dest[0])==compiled,"deps_single_ctex")
			var raw: Image=Image.load_from_file(path)
			var texture: Texture2D=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
			var direct: CompressedTexture2D=CompressedTexture2D.new()
			var direct_error: Error=direct.load(compiled)
			_require(direct_error==OK,"direct_native_ctex_load")
			var imported: Image=texture.get_image() if texture!=null else null
			var native: Image=direct.get_image() if direct_error==OK else null
			var equal: bool=false; var rgba: String=""; var no_mip: bool=false
			if raw!=null and imported!=null and native!=null:
				raw.convert(Image.FORMAT_RGBA8); imported.convert(Image.FORMAT_RGBA8); native.convert(Image.FORMAT_RGBA8)
				var size: Vector2i=Vector2i(int(prepared.size_px[0]),int(prepared.size_px[1]))
				equal=raw.get_size()==size and imported.get_size()==size and native.get_size()==size and raw.get_data()==imported.get_data() and raw.get_data()==native.get_data()
				rgba=_sha(raw.get_data())
				no_mip=not raw.has_mipmaps() and not imported.has_mipmaps() and not native.has_mipmaps()
			_require(equal and rgba==prepared.rgba_sha256,"all_pixels_raw_import_native_ctex_equal_cpu")
			_require(no_mip,"all_native_images_no_mipmaps")
			rows.append({"texture":path,"source_sha256":FileAccess.get_sha256(path),"import_path":path+".import","import_sha256":FileAccess.get_sha256(path+".import"),"compiled_path":compiled,"compiled_sha256":FileAccess.get_sha256(compiled),"size_px":prepared.size_px,"rgba_sha256":rgba,"full_rgba_exact":equal and rgba==prepared.rgba_sha256,"params23":exact_params,"direct_ctex_full_rgba_exact":equal,"no_mipmaps":no_mip})
			texture=null; direct=null; raw=null; imported=null; native=null
	_require(Time.get_ticks_msec()-_started<LIMIT_MS,"original30s_budget")
	var passed: bool=failures.is_empty() and rows.size()==1
	var report: Dictionary={"passed":passed,"failures":failures,"rows":rows,"prepared_sha256":FileAccess.get_sha256("res://prepared.json"),"script_sha256":FileAccess.get_sha256("res://verify_import.gd"),"elapsed_ms":Time.get_ticks_msec()-_started,"limit_ms":LIMIT_MS,"status":"ISOLATED_SPACING_WALK_IMPORT_ONLY_NOT_GAME_READBACK_NOT_RUNTIME"}
	var output: String="res://result_"+str(OS.get_process_id())+".json"
	var file: FileAccess=FileAccess.open(output,FileAccess.WRITE)
	if file==null:
		print("Spacing import report write refused"); quit(1); return
	file.store_string(JSON.stringify(report,"\t",true,true)); file.close()
	print(JSON.stringify({"passed":passed,"failures":failures,"rows":rows.size(),"output":output})); quit(0 if passed else 1)
