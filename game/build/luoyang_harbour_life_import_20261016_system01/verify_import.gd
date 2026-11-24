extends SceneTree
## ROOT-only full native import proof; no publication or game autoload.
const ROOT="res://art/maps/luoyang_harbour_life_20261016/"
const EXPECTED={"cargo_ship_v1.png":{"sha":"d3cfd7f962d6f28ebab88ce1cb69d757e3ed7d4e491c34704b804c655b6a7ee8","size":Vector2i(1024,1536)},"covered_ferry_v1.png":{"sha":"d67140a7afa0fdfffff97de9e34a0680b0069fc9dbd05bbcf85fb7e4ef989357","size":Vector2i(1024,1536)},"harbour_warehouse_v1.png":{"sha":"2fdc857210f17b59c4a6132e33a53a1b092f940a356ceb90266d1a11c917171e","size":Vector2i(1536,1024)}}
const PARAMS={"compress/mode":0,"compress/high_quality":false,"compress/lossy_quality":0.7,"compress/uastc_level":0,"compress/rdo_quality_loss":0.0,"compress/hdr_compression":1,"compress/normal_map":0,"compress/channel_pack":0,"mipmaps/generate":false,"mipmaps/limit":-1,"roughness/mode":0,"roughness/src_normal":"","process/channel_remap/red":0,"process/channel_remap/green":1,"process/channel_remap/blue":2,"process/channel_remap/alpha":3,"process/fix_alpha_border":false,"process/premult_alpha":false,"process/normal_map_invert_y":false,"process/hdr_as_srgb":false,"process/hdr_clamp_exposure":false,"process/size_limit":0,"detect_3d/compress_to":0}
var failures: Array=[]
var rows: Array=[]
func _initialize() -> void: call_deferred("_run")
func _require(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
func _run() -> void:
	for name: String in EXPECTED:
		var path:=ROOT+name; var expected: Dictionary=EXPECTED[name]
		_require(FileAccess.get_sha256(path)==expected.sha,name+":source")
		var config:=ConfigFile.new()
		_require(config.load(path+".import")==OK,name+":import_config")
		_require(config.get_section_keys("params").size()==PARAMS.size(),name+":exact23params")
		for key: String in PARAMS: _require(config.get_value("params",key,null)==PARAMS[key],name+":"+key)
		var compiled: String=config.get_value("remap","path","")
		_require(compiled.begins_with("res://.godot/imported/") and compiled.ends_with(".ctex") and FileAccess.file_exists(compiled),name+":native_ctex")
		var raw:=Image.load_from_file(path)
		var texture:=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		var actual: Image=texture.get_image() if texture!=null else null
		var equal: bool=false
		if raw!=null and actual!=null:
			_require(raw.get_size()==expected.size and actual.get_size()==expected.size,name+":dimensions")
			raw.convert(Image.FORMAT_RGBA8); actual.convert(Image.FORMAT_RGBA8)
			equal=raw.get_data()==actual.get_data()
		_require(equal,name+":full_rgba")
		rows.append({"source":path,"source_sha256":FileAccess.get_sha256(path),"import":path+".import","import_sha256":FileAccess.get_sha256(path+".import"),"compiled":compiled,"compiled_sha256":FileAccess.get_sha256(compiled),"full_rgba_exact":equal,"params23":true})
		texture=null; raw=null; actual=null
	var report: Dictionary={"passed":failures.is_empty(),"failures":failures,"rows":rows,"status":"ISOLATED_HARBOUR_IMPORT_ONLY_NOT_PUBLISHED","script_sha256":FileAccess.get_sha256("res://verify_import.gd")}
	var output: String="res://result_"+str(OS.get_process_id())+".json"
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(report,"\t",true,true)); file.close()
	print(JSON.stringify({"passed":failures.is_empty(),"failures":failures,"result":output})); quit(0 if failures.is_empty() else 1)
