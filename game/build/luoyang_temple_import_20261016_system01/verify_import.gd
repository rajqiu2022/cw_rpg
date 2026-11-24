extends SceneTree
## ROOT-only: all six actual sizes; exact source/import/native RGBA, no edits.
const DIR="res://art/modules/ancient_temple_assembled_20261016/"
const ASSETS={
	"courtyard_floor_v1.png":{"sha":"39c898f7ac8c409b7b244077dd30016c398b21313156c8fc36911ddc859a5c0e","size":Vector2i(1536,1024)},
	"temple_hall_v1.png":{"sha":"8868b0d665f7fc24dd117fe06c7b36a0cf7d95f835858bf6e780af249f7880cf","size":Vector2i(1536,1024)},
	"broken_buddha_v1.png":{"sha":"4e6bb9f62b99f27f9c8c62b05b521d60fcf3cec723881488e27a7d84e57190da","size":Vector2i(1254,1254)},
	"low_incense_altar_v1.png":{"sha":"a3ff96b7e39de9186471178d6e4535fb970534cd1db72b44eb5212f3818faf3e","size":Vector2i(1536,1024)},
	"broken_vermilion_wall_v1.png":{"sha":"4a87da86e62cdb8a9f59e2cca448db150e44945747be2f41aa14a8de08172447","size":Vector2i(1536,1024)},
	"ancient_bell_v1.png":{"sha":"0c03b559c093fea233b8efcb01dd7f92177cdb10bf6818518776be9acdaaa0d6","size":Vector2i(1254,1254)}
}
const PARAMS={
	"compress/mode":0,"compress/high_quality":false,"compress/lossy_quality":0.7,
	"compress/uastc_level":0,"compress/rdo_quality_loss":0.0,"compress/hdr_compression":1,
	"compress/normal_map":0,"compress/channel_pack":0,"mipmaps/generate":false,"mipmaps/limit":-1,
	"roughness/mode":0,"roughness/src_normal":"","process/channel_remap/red":0,
	"process/channel_remap/green":1,"process/channel_remap/blue":2,"process/channel_remap/alpha":3,
	"process/fix_alpha_border":false,"process/premult_alpha":false,"process/normal_map_invert_y":false,
	"process/hdr_as_srgb":false,"process/hdr_clamp_exposure":false,"process/size_limit":0,"detect_3d/compress_to":0
}
var failures: Array=[]
var rows: Array=[]
func _initialize() -> void: call_deferred("_run")
func _require(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
func _sha(bytes: PackedByteArray) -> String:
	var h:=HashingContext.new(); h.start(HashingContext.HASH_SHA256); h.update(bytes); return h.finish().hex_encode()
func _run() -> void:
	for name: String in ASSETS:
		var path: String=DIR+name; var source: Dictionary=ASSETS[name]
		_require(FileAccess.get_sha256(path)==source.sha,name+":source_sha")
		var cfg:=ConfigFile.new(); var loaded: bool=cfg.load(path+".import")==OK
		_require(loaded,name+":import_load")
		if not loaded: continue
		_require(cfg.get_section_keys("params").size()==PARAMS.size(),name+":exact23")
		for key: String in PARAMS: _require(cfg.get_value("params",key,null)==PARAMS[key],name+":"+key)
		var compiled: String=String(cfg.get_value("remap","path",""))
		_require(compiled.begins_with("res://.godot/imported/") and compiled.ends_with(".ctex") and FileAccess.file_exists(compiled),name+":native_ctex")
		_require(cfg.get_value("deps","source_file","")==path,name+":source_identity")
		var raw:=Image.load_from_file(path)
		var texture:=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		var actual: Image=texture.get_image() if texture!=null else null
		var equal: bool=false; var rgba: String=""
		if raw!=null and actual!=null:
			_require(raw.get_size()==source.size and actual.get_size()==source.size,name+":actual_size")
			raw.convert(Image.FORMAT_RGBA8); actual.convert(Image.FORMAT_RGBA8)
			equal=raw.get_data()==actual.get_data(); rgba=_sha(actual.get_data())
		_require(equal,name+":full_rgba_exact")
		rows.append({"texture":path,"source_sha256":FileAccess.get_sha256(path),"import_path":path+".import","import_sha256":FileAccess.get_sha256(path+".import"),"compiled_path":compiled,"compiled_sha256":FileAccess.get_sha256(compiled),"full_rgba_exact":equal,"rgba_sha256":rgba,"size_px":[source.size.x,source.size.y],"params23":true})
		raw=null; actual=null; texture=null
	var report: Dictionary={"passed":failures.is_empty() and rows.size()==6,"failures":failures,"rows":rows,"status":"ISOLATED_IMPORT_ONLY_NOT_PUBLISHED","script_sha256":FileAccess.get_sha256("res://verify_import.gd")}
	var output: String="res://result_"+str(OS.get_process_id())+".json"
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(report,"\t",true,true)); file.close()
	print(JSON.stringify({"passed":report.passed,"rows":rows.size(),"failures":failures,"result":output}))
	quit(0 if report.passed else 1)
