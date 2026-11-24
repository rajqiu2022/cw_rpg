extends SceneTree
## ROOT-only isolated verifier for the single Temple monk texture.
## It does not read or write the main project's .godot directory.

const PREPARED_PATH := "res://prepared.json"
const PREPARED_SHA := "e49472b263af4a630bdf58576e8e13df1f72461b8aee0f83fb6cbaddbb1d80e1"
const PNG_PATH := "res://art/characters/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png"
const PNG_SHA := "6268061eab18d2bf8c1ea0c13873f0d718feb82a119f00a67edf7c52bcb077ad"
const IMPORT_PATH := PNG_PATH + ".import"
const IMPORT_SHA := "55fdbb3fd6e7aa8e179635e028a5de7930d32c2213d03f0ddc943dd1aedd6732"
const COMPILED_PATH := "res://.godot/imported/npc_temple_gate_monk_idle_down_1f_v1.png-5a32dda14a63529913ae5db13222be4d.ctex"
const EXPECTED_SIZE := Vector2i(160,160)
const EXPECTED_ALPHA_RECT := Rect2i(52,6,58,148)
const WHOLE_MS := 15000

var failures: Array[String]=[]
var first: Dictionary={}

func _initialize() -> void:
	call_deferred("_run")

func require(ok: bool,label: String) -> bool:
	if not ok: failures.append(label)
	return ok

func sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func source(path: String,expected: String="") -> bool:
	var actual:=FileAccess.get_sha256(path)
	if not require(actual.length()==64 and (expected.is_empty() or actual==expected),"Exact source "+path): return false
	first[path]=actual
	return true

func decoded(image: Image) -> Image:
	if image==null: return null
	if image.is_compressed() and not require(image.decompress()==OK,"Lossless native decode"): return null
	image.convert(Image.FORMAT_RGBA8)
	return image

func alpha_rect(image: Image) -> Rect2i:
	var min_x:=image.get_width()
	var min_y:=image.get_height()
	var max_x:=-1
	var max_y:=-1
	for y: int in image.get_height():
		for x: int in image.get_width():
			if image.get_pixel(x,y).a>0.0:
				min_x=mini(min_x,x);min_y=mini(min_y,y)
				max_x=maxi(max_x,x);max_y=maxi(max_y,y)
	return Rect2i() if max_x<0 else Rect2i(min_x,min_y,max_x-min_x+1,max_y-min_y+1)

func edge_alpha_max(image: Image) -> int:
	var result:=0
	for x: int in image.get_width():
		result=maxi(result,roundi(image.get_pixel(x,0).a*255.0))
		result=maxi(result,roundi(image.get_pixel(x,image.get_height()-1).a*255.0))
	for y: int in image.get_height():
		result=maxi(result,roundi(image.get_pixel(0,y).a*255.0))
		result=maxi(result,roundi(image.get_pixel(image.get_width()-1,y).a*255.0))
	return result

func _run() -> void:
	var began:=Time.get_ticks_msec()
	var prepared: Variant=JSON.parse_string(FileAccess.get_file_as_string(PREPARED_PATH))
	require(source(PREPARED_PATH,PREPARED_SHA),"Prepared source")
	require(source(PNG_PATH,PNG_SHA),"PNG source")
	require(source(IMPORT_PATH,IMPORT_SHA),"Import source")
	source("res://project.godot")
	source(get_script().resource_path)
	require(prepared is Dictionary and prepared.get("status")=="ISOLATED_SINGLE_IMPORT_SOURCE_READY_NOT_RUN","Prepared schema")
	var config:=ConfigFile.new()
	var config_ok:=require(config.load(IMPORT_PATH)==OK,"Import config parses")
	var params_ok:=false
	if config_ok and prepared is Dictionary:
		var expected_params: Dictionary=prepared.get("params23",{})
		params_ok=require(expected_params.size()==23 and config.get_section_keys("params").size()==23,"Exactly 23 import params")
		for key: String in expected_params:
			params_ok=require(config.get_value("params",key,null)==expected_params[key],"Strict import param "+key) and params_ok
		var remap_meta: Variant=config.get_value("remap","metadata",null)
		var destinations: Variant=config.get_value("deps","dest_files",null)
		params_ok=require(config.get_value("remap","importer","")=="texture","Texture importer") and params_ok
		params_ok=require(config.get_value("remap","type","")=="CompressedTexture2D","CompressedTexture2D type") and params_ok
		params_ok=require(config.get_value("remap","path","")==COMPILED_PATH and not config.has_section_key("remap","path.s3tc"),"Ordinary non-VRAM compiled path") and params_ok
		params_ok=require(remap_meta is Dictionary and remap_meta.get("vram_texture",true)==false,"Non-VRAM metadata") and params_ok
		params_ok=require(config.get_value("deps","source_file","")==PNG_PATH and destinations is Array and destinations.size()==1 and destinations[0]==COMPILED_PATH,"Exact import dependencies") and params_ok
	require(source(COMPILED_PATH),"Actual isolated ctex exists")
	var raw:=decoded(Image.load_from_file(PNG_PATH))
	var imported_texture:=ResourceLoader.load(PNG_PATH,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var direct_texture:=CompressedTexture2D.new()
	var direct_ok:=require(direct_texture.load(COMPILED_PATH)==OK,"Direct ctex load")
	var imported:=decoded(imported_texture.get_image()) if imported_texture!=null else null
	var direct:=decoded(direct_texture.get_image()) if direct_ok else null
	var rect:=Rect2i()
	var edge_max:=-1
	var rgba:=""
	var full_rgba_exact:=false
	var mipmaps_zero:=false
	if raw!=null and imported!=null and direct!=null:
		rect=alpha_rect(raw)
		edge_max=edge_alpha_max(raw)
		rgba=sha(raw.get_data())
		full_rgba_exact=raw.get_size()==EXPECTED_SIZE and imported.get_size()==EXPECTED_SIZE and direct.get_size()==EXPECTED_SIZE and raw.get_data()==imported.get_data() and raw.get_data()==direct.get_data()
		mipmaps_zero=raw.get_mipmap_count()==0 and imported.get_mipmap_count()==0 and direct.get_mipmap_count()==0
	require(full_rgba_exact,"Complete raw/import/direct ctex RGBA exact")
	require(mipmaps_zero,"All three images have zero mipmaps")
	require(rect==EXPECTED_ALPHA_RECT,"Authored alpha foot bounds unchanged")
	require(edge_max==0,"Transparent canvas edge preserved")
	var scale:=140.0/float(EXPECTED_ALPHA_RECT.size.y)
	var foot_error:=absf(0.45*float(EXPECTED_SIZE.y)-float(EXPECTED_ALPHA_RECT.end.y-80))*scale
	require(is_equal_approx(scale,0.9459459459459459) and foot_error<=12.0,"Existing non-calibrated foot-anchor contract")
	var last: Dictionary={}
	for path: String in first:
		last[path]=FileAccess.get_sha256(path)
		require(last[path]==first[path],"Own source unchanged "+path)
	require(Time.get_ticks_msec()-began<WHOLE_MS,"Whole15s finite verifier")
	var passed:=failures.is_empty()
	var report:={
		"passed":passed,
		"scope":"ISOLATED_SINGLE_MONK_IMPORT_NO_MAIN_PROJECT_WRITE_OR_FIELD",
		"failures":failures,
		"elapsed_ms":Time.get_ticks_msec()-began,
		"raw_png":{"path":PNG_PATH,"bytes":FileAccess.get_file_as_bytes(PNG_PATH).size(),"sha256":FileAccess.get_sha256(PNG_PATH)},
		"import":{"path":IMPORT_PATH,"sha256":FileAccess.get_sha256(IMPORT_PATH),"params23":params_ok,"fix_alpha_border":config.get_value("params","process/fix_alpha_border",null) if config_ok else null,"detect_3d_compress_to":config.get_value("params","detect_3d/compress_to",null) if config_ok else null},
		"ctex":{"path":COMPILED_PATH,"bytes":FileAccess.get_file_as_bytes(COMPILED_PATH).size(),"sha256":FileAccess.get_sha256(COMPILED_PATH)},
		"pixels":{"size_px":[EXPECTED_SIZE.x,EXPECTED_SIZE.y],"rgba_sha256":rgba,"full_rgba_exact":full_rgba_exact,"mipmap_count":imported.get_mipmap_count() if imported!=null else -1,"alpha_gt_zero_rect_xywh":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"edge_alpha_max":edge_max},
		"foot_anchor":{"display_scale":scale,"noncal_ground_foot_error_px":foot_error,"asset_bytes_unchanged":FileAccess.get_sha256(PNG_PATH)==PNG_SHA},
		"prepared_sha256":FileAccess.get_sha256(PREPARED_PATH),
		"script_sha256":FileAccess.get_sha256(get_script().resource_path),
		"source_first":first,
		"source_last":last
	}
	var output:="res://monk_import_result_%d.json"%OS.get_process_id()
	var file:=FileAccess.open(output,FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify(report,"\t",true,true));file.close()
	else:
		passed=false;failures.append("Open report output")
	print(JSON.stringify({"passed":passed,"output":output,"failures":failures}))
	quit(0 if passed else 1)
