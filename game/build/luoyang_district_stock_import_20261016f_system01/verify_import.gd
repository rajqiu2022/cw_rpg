extends SceneTree
## ROOT-only: four stock aliases, byte-exact to original PNGs; exact source/import/native RGBA, no edits.
const DIR="res://art/modules/luoyang_district_life_20261016f/"
const ASSETS={
	"stock_goods.png":{"sha":"85cfbe6b14d6aef518d33acb3c3034e07a7b26e0d3e57dc3e9c1047452d416d0","size":Vector2i(1536,1024)},
	"stock_tree.png":{"sha":"e7cddeee8d3d9f71a0bf8cc61a0949f328591f2e38aacef12853ab650f9df430","size":Vector2i(178,250)},
	"stock_lamp.png":{"sha":"8efad8443a667ca9d382ca96b0ef4ceea543a095b838259aaab8c01ebeb63043","size":Vector2i(1024,1536)},
	"stock_crate.png":{"sha":"d985d13d8095b2456a7ee4819058af620e777b6b023c8034986ecd2690cabc6b","size":Vector2i(117,118)}
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
	var report: Dictionary={"passed":failures.is_empty() and rows.size()==4,"failures":failures,"rows":rows,"status":"ISOLATED_IMPORT_ONLY_NOT_PUBLISHED","script_sha256":FileAccess.get_sha256("res://verify_import.gd")}
	var output: String="res://result_"+str(OS.get_process_id())+".json"
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(report,"\t",true,true)); file.close()
	print(JSON.stringify({"passed":report.passed,"rows":rows.size(),"failures":failures,"result":output}))
	quit(0 if report.passed else 1)
