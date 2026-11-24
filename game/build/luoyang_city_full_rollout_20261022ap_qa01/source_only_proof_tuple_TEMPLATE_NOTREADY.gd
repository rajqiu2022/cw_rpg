extends SceneTree
## SOURCE_ONLY existing proof-image tuple; no importer, autoload, Field or collector.
const READY=false
const FIXTURE="PENDING_FIXTURE_PATH"
const FIXTURE_SHA="PENDING_FIXTURE_SHA"
const LIMIT_MS=15000
const SOURCE="res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision4/publication_assets/walk.png"
const COMPILED="res://.godot/imported/walk.png-eb63fda1eba65c60ad6a24b15599ec76.ctex"
const PARAMS: Dictionary={
	"compress/mode":0,"compress/high_quality":false,"compress/lossy_quality":0.7,
	"compress/uastc_level":0,"compress/rdo_quality_loss":0.0,"compress/hdr_compression":1,
	"compress/normal_map":0,"compress/channel_pack":0,"mipmaps/generate":false,"mipmaps/limit":-1,
	"roughness/mode":0,"roughness/src_normal":"","process/channel_remap/red":0,
	"process/channel_remap/green":1,"process/channel_remap/blue":2,"process/channel_remap/alpha":3,
	"process/fix_alpha_border":true,"process/premult_alpha":false,"process/normal_map_invert_y":false,
	"process/hdr_as_srgb":false,"process/hdr_clamp_exposure":false,"process/size_limit":0,"detect_3d/compress_to":1
}
var checks: int=0
var failures: Array[String]=[]
var before: Dictionary={}
var players_before: Dictionary={}
var rows: Array[Dictionary]=[]
var began: int=0
var fixture: Dictionary={}
func _initialize() -> void: call_deferred("run")
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures.append(label);printerr("PROOF_TUPLE_FAIL ",label)
	return ok
func sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	if context.start(HashingContext.HASH_SHA256)!=OK or context.update(bytes)!=OK: return ""
	return context.finish().hex_encode()
func fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false}
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null: return {"exists":true,"unreadable":true}
	var count: int=file.get_length();file.close()
	return {"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":count,"mtime_seconds":FileAccess.get_modified_time(path)}
func track(path: String,digest: String) -> bool:
	var value: Dictionary=fact(path)
	if not need(value.get("exists")==true and value.get("sha256")==digest,"Frozen existing file "+path): return false
	if not need(not before.has(path) or before[path]==value,"Same existing tracked file "+path): return false
	before[path]=value
	return true
func saves() -> Dictionary:
	var result: Dictionary={}
	var base: String="C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传"
	for slot: int in 5:
		for suffix: String in [".json",".json.bak",".json.tmp"]:
			var path: String=base.path_join("save_"+str(slot)+suffix)
			result[path]=fact(path)
	return result
func parameter_same(left: Variant,right: Variant) -> bool:
	if typeof(right)==TYPE_INT or typeof(right)==TYPE_FLOAT:
		return (typeof(left)==TYPE_INT or typeof(left)==TYPE_FLOAT) and is_finite(float(left)) and float(left)==float(right)
	return typeof(left)==typeof(right) and left==right
func verify() -> bool:
	var raw_path: String=String(fixture.absolute_png)
	var sidecar: String=raw_path+".import"
	var compiled_path: String=String(fixture.absolute_ctex)
	for path: String in fixture.source_sha256:
		if not track(path,fixture.source_sha256[path]): return false
	if not need(COMPILED=="res://.godot/imported/walk.png-"+SOURCE.md5_text()+".ctex","Unique compiled path from original source identity"): return false
	var config:=ConfigFile.new()
	if not need(config.load(sidecar)==OK,"Existing sidecar read only"): return false
	if not need(config.get_value("remap","importer","")=="texture" and config.get_value("remap","type","")=="CompressedTexture2D" and config.get_value("remap","path","")==COMPILED,"Fixed texture remap/type/path"): return false
	var dest: Variant=config.get_value("deps","dest_files",null)
	if not need(config.get_value("deps","source_file","")==SOURCE and dest is Array and dest.size()==1 and dest[0]==COMPILED,"Unique original source and destination"): return false
	for name: String in config.get_section_keys("remap"):
		if not need(not name.begins_with("path.") and not name.contains("s3tc"),"No alternate platform remap"): return false
	if not need(config.has_section("params") and config.get_section_keys("params").size()==23 and PARAMS.size()==23,"Exactly23 predeclared parameters"): return false
	for name: String in PARAMS:
		if not need(parameter_same(config.get_value("params",name,null),PARAMS[name]),"Original proof-only parameter "+name): return false
	if not need(Time.get_ticks_msec()-began<LIMIT_MS,"15s before two existing image reads"): return false
	# No PNG Texture resource entry point: it could consult/generate an import.
	var raw:=Image.new()
	if not need(raw.load(raw_path)==OK,"Original PNG direct CPU decode"): return false
	var texture: Texture2D=ResourceLoader.load(compiled_path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if not need(texture is CompressedTexture2D,"Only already-existing direct.ctex resource"): return false
	var imported: Image=texture.get_image()
	if not need(imported!=null,"Existing compiled full image payload"): return false
	var native_states: Array[Dictionary]=[]
	for image: Image in [raw,imported]:
		native_states.append({"format":image.get_format(),"compressed":image.is_compressed(),"mipmaps":image.has_mipmaps(),"size":[image.get_width(),image.get_height()]})
		if not need(image.get_size()==Vector2i(3072,2048) and not image.has_mipmaps(),"Full original3072x2048/mip0"): return false
		if image.is_compressed() and not need(image.decompress()==OK,"In-memory decoded payload decompression only"): return false
		image.convert(Image.FORMAT_RGBA8)
		if not need(image.get_format()==Image.FORMAT_RGBA8,"Canonical fullRGBA8 representation; native formats not assumed equal"): return false
	rows.append({"kind":"NATIVE_IMAGE_STATES_BEFORE_RGBA_NORMALIZATION","raw_then_compiled":native_states,"native_format_equality_not_a_frozen53624_contract":true})
	var raw_bytes: PackedByteArray=raw.get_data()
	var imported_bytes: PackedByteArray=imported.get_data()
	if not need(raw_bytes.size()==25165824 and imported_bytes.size()==25165824,"Both completeRGBA payloads, no sampling/crop"): return false
	if not need(raw_bytes==imported_bytes and sha(raw_bytes)=="6e72541153449e571516c340838794ff44fdf96dfc8b601b93733b3d4ff4c6da" and sha(imported_bytes)=="6e72541153449e571516c340838794ff44fdf96dfc8b601b93733b3d4ff4c6da","Full original and compiled bytes equal independent53624RGBA"): return false
	rows.append({"scope":"SOURCE_ONLY_HISTORICAL_PROOF_TUPLE_NOT_RUNTIME_TEXTURE_ADMISSION","source":SOURCE,"compiled":COMPILED,"raw_sha256":fixture.source_sha256[raw_path],"sidecar_sha256":fixture.source_sha256[sidecar],"compiled_sha256":fixture.source_sha256[compiled_path],"RGBA_sha256":"6e72541153449e571516c340838794ff44fdf96dfc8b601b93733b3d4ff4c6da","full_RGBA_exact":true,"native_states":native_states,"size":[3072,2048],"mipmaps":0,"exact_params23":true,"fix_alpha_border":true,"detect_3d_compress_to":1,"new_import_calls":0,"runtime_texture_promotion":false})
	return true
func run() -> void:
	began=Time.get_ticks_msec();players_before=saves()
	var passed: bool=need(READY and DisplayServer.get_name()=="headless" and root.get_child_count()==0 and current_scene==null and OS.get_cmdline_user_args().is_empty(),"Frozen headless empty project only; noautoload")
	if passed: passed=track(FIXTURE,FIXTURE_SHA)
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)) if passed else null
	if passed: passed=need(parsed is Dictionary and parsed.get("ready")==true,"Frozen independent source-only tuple fixture")
	if passed:
		fixture=parsed
		passed=need(fixture.limit_ms==LIMIT_MS,"Fixed15s wholebudget") and verify()
	var after: Dictionary={}
	for path: String in before:
		after[path]=fact(path)
		if not need(after[path]==before[path],"Existing source wholeFIRSTFINAL unchanged "+path): passed=false
	var players_after: Dictionary=saves()
	if not need(players_before==players_after and players_before.size()==15,"Original mainproject15save unchanged, no restoration"): passed=false
	if not need(Time.get_ticks_msec()-began<LIMIT_MS and root.get_child_count()==0 and current_scene==null,"Whole15s/noNodes/Field"): passed=false
	var folder: String="res://output/%d_%d"%[OS.get_process_id(),began]
	if not need(not DirAccess.dir_exists_absolute(folder) and DirAccess.make_dir_recursive_absolute(folder)==OK,"NEW resultfolder only"): passed=false
	var result: Dictionary={"complete":passed and failures.is_empty(),"scope":"ONE_EXISTING_SOURCE_ONLY_PROOF_PNG_SIDECAR_CTEX_READONLY_NO_IMPORT_OR_RUNTIME","checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":LIMIT_MS,"rows":rows,"source_first":before,"source_final":after,"players_before":players_before,"players_after":players_after,"import_calls":0,"collector_Field_Scene_geometry_calls":0,"screenshots":0,"canonical_write":false,"runtime_ART_admission":false}
	var file:=FileAccess.open(folder.path_join("result.json"),FileAccess.WRITE)
	if file==null: passed=false
	else:file.store_string(JSON.stringify(result,"\t",true,true));file.close()
	print("SOURCE_ONLY_PROOF_TUPLE_RESULT=",folder,"/result.json")
	quit(0 if passed and failures.is_empty() else 1)
