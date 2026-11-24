extends SceneTree
## ROOT-only isolated three-runtime-texture import; no autoload or game writes.
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
	var prepared: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://prepared.json"))
	if not prepared is Dictionary or prepared.get("rows",[]).size()!=3 or prepared.get("params23",{}).size()!=23:
		failures.append("prepared_schema")
	else:
		for source: Dictionary in prepared.rows:
			var path: String=String(source.texture)
			_require(path.begins_with("res://art/modules/luoyang_docks_office_20261016h/") and ".." not in path,path+":namespace")
			_require(FileAccess.get_sha256(path)==source.source_sha256,path+":runtime_sha")
			_require(FileAccess.get_sha256(source.raw_path)==source.raw_sha256,path+":original_raw_sha")
			var config: ConfigFile=ConfigFile.new()
			if config.load(path+".import")!=OK: failures.append(path+":import_load"); continue
			_require(config.get_section_keys("params").size()==23,path+":exact23")
			for key: String in prepared.params23: _require(config.get_value("params",key,null)==prepared.params23[key],path+":"+key)
			var compiled: String=String(config.get_value("remap","path",""))
			_require(compiled.begins_with("res://.godot/imported/") and compiled.ends_with(".ctex"),path+":compiled_namespace")
			_require(config.get_value("deps","source_file","")==path,path+":source_identity")
			var raw: Image=Image.load_from_file(path)
			var texture: Texture2D=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
			var direct: Texture2D=ResourceLoader.load(compiled,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
			var imported: Image=texture.get_image() if texture!=null else null
			var native: Image=direct.get_image() if direct!=null else null
			var equal: bool=false; var rgba: String=""
			if raw!=null and imported!=null and native!=null:
				raw.convert(Image.FORMAT_RGBA8); imported.convert(Image.FORMAT_RGBA8); native.convert(Image.FORMAT_RGBA8)
				var size: Vector2i=Vector2i(int(source.size_px[0]),int(source.size_px[1]))
				equal=raw.get_size()==size and imported.get_size()==size and native.get_size()==size and raw.get_data()==imported.get_data() and raw.get_data()==native.get_data()
				rgba=_sha(raw.get_data())
				_require(not imported.has_mipmaps() and not native.has_mipmaps(),path+":no_mipmaps")
			_require(equal and rgba==source.rgba_sha256,path+":full_rgba_runtime_import_directctex")
			rows.append({"texture":path,"source_sha256":FileAccess.get_sha256(path),"import_path":path+".import","import_sha256":FileAccess.get_sha256(path+".import"),"compiled_path":compiled,"compiled_sha256":FileAccess.get_sha256(compiled),"size_px":source.size_px,"rgba_sha256":rgba,"full_rgba_exact":equal,"params23":true,"raw_runtime_equality_claimed":source.runtime_raw_byte_identical})
	var passed: bool=failures.is_empty() and rows.size()==3
	var report: Dictionary={"passed":passed,"failures":failures,"rows":rows,"prepared_sha256":FileAccess.get_sha256("res://prepared.json"),"script_sha256":FileAccess.get_sha256("res://verify_import.gd"),"status":"ISOLATED_RUNTIME_TEXTURES_ONLY_NOT_GAME_PUBLISHED_NOT_FIELD"}
	var output: String="res://result_"+str(OS.get_process_id())+".json"
	var file: FileAccess=FileAccess.open(output,FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(report,"\t",true,true)); file.close()
	print(JSON.stringify({"passed":passed,"failures":failures,"rows":rows.size(),"output":output}))
	quit(0 if passed else 1)
