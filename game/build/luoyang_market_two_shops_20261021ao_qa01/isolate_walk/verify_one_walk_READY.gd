extends SceneTree
## NEW only: Root freezes READY/PREPARED_SHA in a distinct successor before run.
const READY=true
const PREPARED="res://prepared_READY.json"
const PREPARED_SHA="9dade3ee78cf65f3fd7c3b9d5d7e66876782241e23964fcc56796a5636b404b0"
const LIMIT_MS=30000
const PATHS={"walk":"res://data/maps/luoyang_market_two_shops_20261021ao/runtime/ch4_s3_luoyang_market/walk.png"}
const PARAMS={
	"compress/mode":0,"compress/high_quality":false,"compress/lossy_quality":0.7,
	"compress/uastc_level":0,"compress/rdo_quality_loss":0,"compress/hdr_compression":1,
	"compress/normal_map":0,"compress/channel_pack":0,"mipmaps/generate":false,"mipmaps/limit":-1,
	"roughness/mode":0,"roughness/src_normal":"","process/channel_remap/red":0,
	"process/channel_remap/green":1,"process/channel_remap/blue":2,"process/channel_remap/alpha":3,
	"process/fix_alpha_border":false,"process/premult_alpha":false,"process/normal_map_invert_y":false,
	"process/hdr_as_srgb":false,"process/hdr_clamp_exposure":false,"process/size_limit":0,"detect_3d/compress_to":0
}
var checks: int=0
var failures: Array[String]=[]
var sources: Dictionary={}
var rows: Array[Dictionary]=[]
var began: int=0
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures.append(label); printerr("AO_ONE_WALK_IMPORT_FAIL ",label)
	return ok
func sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	if context.start(HashingContext.HASH_SHA256)!=OK or context.update(bytes)!=OK: return ""
	return context.finish().hex_encode()
func track(path: String,expected: String) -> bool:
	var actual: String=FileAccess.get_sha256(path)
	if not need(path.begins_with("res://") and ".." not in path and actual.length()==64 and actual==expected,"Frozen isolated source "+path): return false
	if not need(not sources.has(path) or sources[path]==actual,"Single exact source identity "+path): return false
	sources[path]=actual; return true
func number(value: Variant) -> bool:
	return (typeof(value)==TYPE_INT or typeof(value)==TYPE_FLOAT) and is_finite(float(value))
func valid_size(actual: Vector2i,expected: Variant) -> bool:
	if not expected is Array or expected.size()!=2: return false
	for i: int in 2:
		if not number(expected[i]) or float(expected[i])!=float(actual[i]): return false
	return true
func same_param(actual: Variant,expected: Variant) -> bool:
	if number(expected): return number(actual) and float(actual)==float(expected)
	return typeof(actual)==typeof(expected) and actual==expected
func exact_scope(spec: Dictionary) -> bool:
	if spec.get("status")!="AO_EXACT_ONE_MARKET_WALK_READY_FOR_ISOLATED_IMPORT" or spec.get("schema_version")!=1 or not spec.get("textures") is Array or spec.textures.size()!=1: return false
	var seen: Dictionary={}
	for row: Variant in spec.textures:
		if not row is Dictionary or not row.get("visual_kind") is String or not PATHS.has(row.visual_kind) or seen.has(row.visual_kind) or row.get("texture")!=PATHS[row.visual_kind]: return false
		seen[row.visual_kind]=true
	return seen.size()==1
func verify(spec: Dictionary) -> bool:
	if not need(exact_scope(spec),"Exactly one new Market walk, no shop or prior project imports"): return false
	var seen: Dictionary={}
	for item: Dictionary in spec.textures:
		var path: String=String(item.get("texture",""))
		if not need(PATHS.get(item.get("visual_kind"))==path and path.ends_with(".png") and ".." not in path and not seen.has(path),"Unique adopted NEW ground PNG "+path): return false
		seen[path]=true
		if not track(path,String(item.get("source_sha256",""))): return false
		var expected_compiled: String="res://.godot/imported/"+path.get_file()+"-"+path.md5_text()+".ctex"
		if not need(item.get("compiled_path")==expected_compiled,"Concrete remap path from full res path MD5"): return false
		var import_path: String=path+".import"
		var config:=ConfigFile.new()
		if not need(config.load(import_path)==OK,"Actual isolated sidecar "+path): return false
		if not need(config.get_value("remap","importer","")=="texture" and config.get_value("remap","type","")=="CompressedTexture2D" and config.get_value("remap","path","")==expected_compiled,"Ordinary concrete lossless import "+path): return false
		if not need(config.has_section("params") and config.get_section_keys("params").size()==23,"Exactly23 import parameters"): return false
		for key: String in PARAMS:
			if not need(same_param(config.get_value("params",key,null),PARAMS[key]),"Exact typed import parameter "+key): return false
		for key: String in config.get_section_keys("remap"):
			if not need(not key.begins_with("path.") and not key.contains("s3tc"),"No alternate compressed remap"): return false
		var destinations: Variant=config.get_value("deps","dest_files",null)
		if not need(config.get_value("deps","source_file","")==path and destinations is Array and destinations.size()==1 and destinations[0] is String and destinations[0]==expected_compiled,"Exact source and ordinary Array of one destination"): return false
		var import_sha: String=FileAccess.get_sha256(import_path)
		var compiled_sha: String=FileAccess.get_sha256(expected_compiled)
		if not track(import_path,import_sha) or not track(expected_compiled,compiled_sha): return false
		var raw:=Image.load_from_file(path)
		var texture:=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		var direct:=ResourceLoader.load(expected_compiled,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		if not need(raw!=null and texture!=null and direct!=null,"Raw/import/directctex actual entry points"): return false
		var imported: Image=texture.get_image(); var compiled: Image=direct.get_image()
		if not need(imported!=null and compiled!=null and not raw.has_mipmaps() and not imported.has_mipmaps() and not compiled.has_mipmaps(),"Three complete real images zero mipmaps"): return false
		for image: Image in [raw,imported,compiled]:
			if image.is_compressed() and not need(image.decompress()==OK,"Real image decompression"): return false
			image.convert(Image.FORMAT_RGBA8)
			if not need(valid_size(image.get_size(),item.get("size")),"Exact full image dimensions, integral JSON numeric domain"): return false
		if not need(raw.get_data()==imported.get_data() and raw.get_data()==compiled.get_data() and sha(raw.get_data())==item.get("rgba_sha256"),"Entire RGBA including A1 and hidden RGB raw/import/directctex exact"): return false
		rows.append({"texture":path,"visual_kind":String(item.visual_kind),"source_sha256":String(item.source_sha256),"rgba_sha256":String(item.rgba_sha256),"size":[raw.get_width(),raw.get_height()],"import_path":import_path,"import_sha256":import_sha,"compiled_path":expected_compiled,"compiled_sha256":compiled_sha,"params23":true,"full_rgba_exact":true,"zero_mipmaps":true,"detect3d_compress_to":0})
		if not need(Time.get_ticks_msec()-began<LIMIT_MS,"Fixed30s selected cohort verification"): return false
	return true
func _run() -> void:
	began=Time.get_ticks_msec()
	var result_path: String="res://ao_one_walk_import_result_%d.json"%OS.get_process_id()
	if not need(not FileAccess.file_exists(result_path),"NEW PID report; preserve every prior result"):
		print(JSON.stringify({"passed":false,"report_exists":true,"report_path":result_path,"failures":failures})); quit(1); return
	var passed: bool=need(READY and OS.get_cmdline_user_args().is_empty(),"Frozen READY verifier, no main project/autoload flags")
	if passed: passed=track(PREPARED,PREPARED_SHA)
	var spec: Variant=JSON.parse_string(FileAccess.get_file_as_string(PREPARED)) if passed else null
	if passed: passed=need(spec is Dictionary,"Frozen preparation decoded")
	if passed: passed=track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)) and track("res://project.godot",String(spec.get("project_sha256","")))
	if passed: passed=verify(spec)
	var after: Dictionary={}
	for path: String in sources: after[path]=FileAccess.get_sha256(path)
	if not need(sources==after,"Every prepared/script/project/PNG/import/ctex remains exact"): passed=false
	if not need(Time.get_ticks_msec()-began<LIMIT_MS,"Whole verification fixed30s"): passed=false
	var result: Dictionary={"scope":"AO_EXACT_ONE_NEW_WALK_ISOLATED_IMPORT_NOT_TWO_SHOP_REIMPORT_OR_FIELD","passed":passed and failures.is_empty(),"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":LIMIT_MS,"rows":rows,"source_first":sources,"source_final":after,"prepared_sha256":PREPARED_SHA,"art_or_Field_credit":false}
	var file:=FileAccess.open(result_path,FileAccess.WRITE)
	if file==null: passed=false
	else: file.store_string(JSON.stringify(result,"\t",true,true)); file.close()
	print(JSON.stringify({"passed":passed and failures.is_empty(),"checks":checks,"failures":failures,"report_path":result_path}))
	quit(0 if passed and failures.is_empty() else 1)





