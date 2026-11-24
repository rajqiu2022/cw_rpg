extends SceneTree
## ROOT-only isolated verification of THREE new byte aliases. No game autoload,
## old import loading, conversion, texture edits, resource import or save access.
const SOURCE_READY=false
const PREPARED="res://prepared3.json"
const PREPARED_SHA="PENDING_ART_EXACT_PREPARED_SHA"
const LIMIT_MS=30000
const IDS=["reuse_bamboo0","reuse_bamboo1","reuse_boulder0"]
const PARAMS={
	"compress/mode":0,"compress/high_quality":false,"compress/lossy_quality":0.7,
	"compress/uastc_level":0,"compress/rdo_quality_loss":0.0,"compress/hdr_compression":1,
	"compress/normal_map":0,"compress/channel_pack":0,"mipmaps/generate":false,"mipmaps/limit":-1,
	"roughness/mode":0,"roughness/src_normal":"","process/channel_remap/red":0,
	"process/channel_remap/green":1,"process/channel_remap/blue":2,"process/channel_remap/alpha":3,
	"process/fix_alpha_border":false,"process/premult_alpha":false,"process/normal_map_invert_y":false,
	"process/hdr_as_srgb":false,"process/hdr_clamp_exposure":false,"process/size_limit":0,"detect_3d/compress_to":0
}
var failures: Array[String]=[]
var rows: Array[Dictionary]=[]
var checks:=0
func _initialize() -> void: call_deferred("_run")
func require(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures.append(label); printerr("TEMPLE_REUSE_IMPORT_FAIL ",label)
	return ok
func sha(bytes: PackedByteArray) -> String:
	var h:=HashingContext.new(); h.start(HashingContext.HASH_SHA256); h.update(bytes)
	return h.finish().hex_encode()
func image(texture: Texture2D) -> Image:
	if texture==null: return null
	var result:=texture.get_image()
	if result!=null and result.is_compressed() and result.decompress()!=OK: return null
	if result!=null: result.convert(Image.FORMAT_RGBA8)
	return result
func verify(asset: Dictionary) -> void:
	var id: String=String(asset.get("id",""))
	var path: String=String(asset.get("path",""))
	var pin: String=String(asset.get("source_sha256",""))
	var size: Array=asset.get("size_px",[])
	if not require(id in IDS and path.begins_with("res://art/modules/ancient_temple_assembled_20261016/") and ".." not in path and path.ends_with(".png") and pin.length()==64 and size.size()==2,"Exact new alias row schema "+id): return
	if not require(float(size[0])==floorf(float(size[0])) and float(size[1])==floorf(float(size[1])) and float(size[0])>0 and float(size[1])>0,"Positive exact integer source size "+id): return
	var expected:=Vector2i(int(size[0]),int(size[1]))
	var original: String=String(asset.get("source_path",""))
	if not require(path==String(asset.get("game_target_path","")) and FileAccess.file_exists(original) and FileAccess.get_sha256(original)==pin and FileAccess.get_sha256(path)==pin,"Exact original PNG bytes copied to NEW same-path alias, no old import read "+id): return
	var cfg:=ConfigFile.new()
	if not require(cfg.load(path+".import")==OK,"New import config exists "+id): return
	var params_ok: bool=cfg.has_section("params") and cfg.get_section_keys("params").size()==23
	for key: String in PARAMS:
		params_ok=require(cfg.get_value("params",key,null)==PARAMS[key],"Exact new seed param "+id+":"+key) and params_ok
	params_ok=require(params_ok,"Exactly23 settings, no alpha-border/mip/detect3D conversion "+id) and params_ok
	var compiled: String=String(cfg.get_value("remap","path",""))
	var identity: bool=compiled.begins_with("res://.godot/imported/") and compiled.ends_with(".ctex") and ".." not in compiled and FileAccess.file_exists(compiled)
	var destinations: Variant=cfg.get_value("deps","dest_files",null)
	var destinations_ok: bool=(destinations is Array or destinations is PackedStringArray) and destinations.size()==1 and typeof(destinations[0])==TYPE_STRING and destinations[0]==compiled
	identity=identity and destinations_ok and cfg.get_value("remap","importer","")=="texture" and cfg.get_value("remap","type","")=="CompressedTexture2D" and cfg.get_value("deps","source_file","")==path
	if not require(identity,"Native new import remap/deps/destination identity "+id): return
	var raw:=Image.load_from_file(path)
	var texture:=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var imported:=image(texture)
	var native:=CompressedTexture2D.new()
	var native_error: Error=native.load(compiled)
	var direct: Image=image(native) if native_error==OK else null
	if raw!=null: raw.convert(Image.FORMAT_RGBA8)
	var exact: bool=raw!=null and imported!=null and direct!=null
	if exact:
		exact=raw.get_size()==expected and imported.get_size()==expected and direct.get_size()==expected and imported.get_mipmap_count()==0 and direct.get_mipmap_count()==0 and raw.get_data()==imported.get_data() and raw.get_data()==direct.get_data()
	require(native_error==OK,"Native CTEX loader success "+id)
	require(exact,"Full source-import-directcompiled RGBA exact/no mip "+id)
	rows.append({"id":id,"texture":path,"source_path":original,"game_target_path":asset.game_target_path,"source_sha256":FileAccess.get_sha256(path),"import_path":path+".import","import_sha256":FileAccess.get_sha256(path+".import"),"compiled_path":compiled,"compiled_sha256":FileAccess.get_sha256(compiled),"rgba_sha256":sha(imported.get_data()) if imported!=null else "","size_px":[expected.x,expected.y],"full_rgba_exact":exact,"params23":params_ok,"source_import_native_full_rgba_exact":exact,"mipmap_count":imported.get_mipmap_count() if imported!=null else -1})
func _run() -> void:
	var began:=Time.get_ticks_msec()
	if require(SOURCE_READY and PREPARED_SHA.length()==64 and FileAccess.get_sha256(PREPARED)==PREPARED_SHA,"Explicit final prepared source readiness; draft refuses"):
		var prepared: Variant=JSON.parse_string(FileAccess.get_file_as_string(PREPARED))
		if require(prepared is Dictionary and prepared.get("assets",[]).size()==3,"Only three new aliases, not previous six"):
			var seen: Dictionary={}
			for asset: Dictionary in prepared.assets:
				if not require(not seen.has(asset.get("id")) and Time.get_ticks_msec()-began<LIMIT_MS,"Unique finite alias row"): break
				seen[asset.get("id")]=true; verify(asset)
			require(seen.size()==3,"Exactly three unique source identities")
	require(Time.get_ticks_msec()-began<LIMIT_MS,"Fixed30s finite three-texture verification")
	var report: Dictionary={"passed":failures.is_empty() and rows.size()==3,"checks":checks,"failures":failures,"rows":rows,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":LIMIT_MS,"status":"ISOLATED_THREE_ALIAS_IMPORT_ONLY_NOT_TEMPLE_RUNTIME","prepared_sha256":PREPARED_SHA,"script_sha256":FileAccess.get_sha256(get_script().resource_path)}
	var output:="res://result_"+str(OS.get_process_id())+".json"
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(report,"\t",true,true)); file.close()
	else: report.passed=false; printerr("TEMPLE_REUSE_IMPORT_FAIL result_write")
	print(JSON.stringify({"passed":report.passed,"checks":checks,"rows":rows.size(),"failures":failures,"result":output}))
	quit(0 if report.passed else 1)
