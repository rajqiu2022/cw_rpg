extends SceneTree
## ROOT-only independent import verification. Does not publish to the game.
const ROOT := "res://art/modules/luoyang_assembled_20261016b/"
const EXPECTED := {
	"shell_v1.png":"81e9fc873d6c52ed5f189023a4bbf1acb50a7a47217182e9b85405efc1bbb8b4",
	"forge_v1.png":"e5341ec20602604b0c0fb28e689df741b5d346237d7e27831fb491f19270de61",
	"anvil_stump_v1.png":"3e4e48b61a7f71aa9fc05f8aae14910a1d2e7d4b5479123aece2c731427b85bb",
	"bellows_v1.png":"641b0d20b5c3aab2cb0e6c2eee077139fa11835d485388214d6f0abf480f8a3b",
	"quench_tub_v1.png":"81e74615f03e9deefa7e2592adb271e3c7c995c0e3731c74bc68f6c17cc60ad7",
	"workbench_v1.png":"863f2b71f747af494d62012e56f8a1480800a62d4d86eaad95254d717cdf4aaf",
	"weapon_rack_v1.png":"0998af7e5e6b8de9cdcd5baa409e2e1515b1dc2e8ff852acb46c560b78096ad8"
}
const PARAMS := {
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
func _run() -> void:
	for name: String in EXPECTED:
		var path:=ROOT+name
		_require(FileAccess.get_sha256(path)==EXPECTED[name],name+":source_sha")
		var config:=ConfigFile.new()
		_require(config.load(path+".import")==OK,name+":config_load")
		_require(config.get_section_keys("params").size()==PARAMS.size(),name+":exact_23_params")
		for key: String in PARAMS: _require(config.get_value("params",key,null)==PARAMS[key],name+":"+key)
		var compiled: String=config.get_value("remap","path","")
		_require(compiled.begins_with("res://.godot/imported/") and compiled.ends_with(".ctex") and FileAccess.file_exists(compiled),name+":native_ctex")
		var raw:=Image.load_from_file(path)
		var texture:=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		var actual: Image=texture.get_image() if texture!=null else null
		var equal:=false
		if raw!=null and actual!=null:
			_require(raw.get_size()==Vector2i(1536,1024) and actual.get_size()==raw.get_size(),name+":dimensions")
			raw.convert(Image.FORMAT_RGBA8); actual.convert(Image.FORMAT_RGBA8)
			equal=raw.get_data()==actual.get_data()
		_require(equal,name+":full_rgba_exact")
		rows.append({"source":path,"source_sha256":FileAccess.get_sha256(path),"import":path+".import","import_sha256":FileAccess.get_sha256(path+".import"),"compiled":compiled,"compiled_sha256":FileAccess.get_sha256(compiled),"full_rgba_exact":equal,"params23":true})
		texture=null; raw=null; actual=null
	var report: Dictionary={"passed":failures.is_empty(),"failures":failures,"rows":rows,"status":"ISOLATED_IMPORT_ONLY_NOT_PUBLISHED","script_sha256":FileAccess.get_sha256("res://verify_import.gd")}
	var out: String="res://result_"+str(OS.get_process_id())+".json"
	var file:=FileAccess.open(out,FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(report,"\t")); file.close()
	print(JSON.stringify({"passed":failures.is_empty(),"rows":rows.size(),"failures":failures,"result":out}))
	quit(0 if failures.is_empty() else 1)
