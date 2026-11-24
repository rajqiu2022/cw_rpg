extends SceneTree
## Ordinary autoload, no World instances, no Input or save API. Root-only execution.
const FIXTURE := "res://build/world_bridges_20261030m_qa01/import_decode_inputs_READY.json"
const OUT := "res://build/world_bridges_20261030m_qa01/import_decode_actual/"
const PARAMS := {
	"compress/mode":0,"compress/high_quality":false,"compress/lossy_quality":0.7,"compress/uastc_level":0,"compress/rdo_quality_loss":0.0,"compress/hdr_compression":1,"compress/normal_map":0,"compress/channel_pack":0,
	"mipmaps/generate":false,"mipmaps/limit":-1,"roughness/mode":0,"roughness/src_normal":"",
	"process/channel_remap/red":0,"process/channel_remap/green":1,"process/channel_remap/blue":2,"process/channel_remap/alpha":3,
	"process/fix_alpha_border":false,"process/premult_alpha":false,"process/normal_map_invert_y":false,"process/hdr_as_srgb":false,"process/hdr_clamp_exposure":false,"process/size_limit":0,"detect_3d/compress_to":0}
var checks := 0
var errors: Array[String] = []
var records: Array = []
var sources_first: Dictionary = {}
var pins: Dictionary = {}
var done := false
var suspended := false
var directory := ""

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred();_watch.call_deferred()

func _early(node: Node) -> void:
	if node.name==&"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true)
		suspended=bool(node.call("is_checkpoint_saves_suspended"))

func _watch() -> void:
	await create_timer(35.0,true,false,true).timeout
	if not done:need(false,"WATCHDOG35_NO_FIELD_OR_RECOVERY");finish()

func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("BRIDGE_IMPORT_FAIL ",label)
	return ok

func facts() -> Dictionary:
	var result: Dictionary={}
	for path: String in pins:
		var file:=FileAccess.open(path,FileAccess.READ)
		result[path]={"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file!=null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return result

func rgba_sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	context.start(HashingContext.HASH_SHA256);context.update(bytes)
	return context.finish().hex_encode()

func one_texture(row: Dictionary) -> bool:
	var path: String=String(row.path)
	var config:=ConfigFile.new()
	if not need(config.load(path+".import")==OK,"REAL_IMPORT_CONFIG:"+String(row.id)):return false
	var actual_params: Dictionary={}
	for key: String in config.get_section_keys("params"):actual_params[key]=config.get_value("params",key)
	if not need(actual_params.size()==PARAMS.size(),"EXACT23_IMPORT_PARAMS:"+String(row.id)):return false
	for key: String in PARAMS:
		if not need(actual_params.get(key)==PARAMS[key],"IMPORT_PARAM:"+String(row.id)+":"+key):return false
	if not need(String(config.get_value("remap","path",""))==String(row.compiled_path) and String(config.get_value("deps","source_file",""))==path,"SAME_URI_AND_COMPILED_IMPORT_TARGET:"+String(row.id)):return false
	var texture: Texture2D=ResourceLoader.load(path,"Texture2D",ResourceLoader.CACHE_MODE_REUSE) as Texture2D
	if not need(texture!=null,"REAL_TEXTURE2D_LOAD:"+String(row.id)):return false
	var decoded: Image=texture.get_image()
	var source:=Image.new()
	if not need(source.load(path)==OK and decoded!=null and not decoded.is_empty(),"REAL_SOURCE_PNG_AND_IMPORTED_IMAGE:"+String(row.id)):return false
	var mipmap_count: int=decoded.get_mipmap_count()
	if not need(mipmap_count==0 and not decoded.has_mipmaps() and not source.has_mipmaps(),"REAL_MIP0:"+String(row.id)):return false
	var expected: Array=row.size
	if not need([texture.get_width(),texture.get_height()]==expected and [decoded.get_width(),decoded.get_height()]==expected and source.get_size()==decoded.get_size(),"ACTUAL_NATIVE_PNG_TEXTURE_IMAGE_SIZE:"+String(row.id)):return false
	decoded.convert(Image.FORMAT_RGBA8);source.convert(Image.FORMAT_RGBA8)
	var source_bytes: PackedByteArray=source.get_data();var decoded_bytes: PackedByteArray=decoded.get_data()
	var full_exact: bool=source_bytes==decoded_bytes
	var source_rgba: String=rgba_sha(source_bytes);var imported_rgba: String=rgba_sha(decoded_bytes)
	if not need(source_bytes.size()==int(expected[0])*int(expected[1])*4 and full_exact and source_rgba==String(row.rgba_sha256),"EVERY_RGBA8_BYTE_EXACT_IMPORTED_VS_SOURCE_AND_ART_SHA:"+String(row.id)):return false
	records.append({"id":row.id,"resource":{"path":path,"sha256":FileAccess.get_sha256(path),"import_sha256":FileAccess.get_sha256(path+".import"),"compiled_path":row.compiled_path,"compiled_sha256":FileAccess.get_sha256(String(row.compiled_path)),"size":expected,"full_RGBA_exact":full_exact,"mipmap_count":mipmap_count},"source_RGBA8_sha256":source_rgba,"imported_RGBA8_sha256":imported_rgba,"RGBA8_bytes":source_bytes.size(),"actual_import_params":actual_params,"source_version":row.version,"texture_resource_path":texture.resource_path})
	return true

func _run() -> void:
	directory=OUT+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	if not need(suspended and root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"EARLIEST_PLATFORM_CHECKPOINT_SUSPEND"):finish();return
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not need(raw is Dictionary and raw.get("textures",[]).size()==5 and raw.get("parse_scripts",[]).size()==3,"EXACT_FIVE_IMAGES_AND_THREE_SCRIPT_LOADS"):finish();return
	pins=raw.pins;sources_first=facts()
	for path: String in pins:
		if not need(sources_first[path].sha256==String(pins[path]).to_lower(),"EXACT_FROZEN_INPUT:"+path):finish();return
	for row: Dictionary in raw.textures:
		if not one_texture(row):finish();return
	for path: String in raw.parse_scripts:
		var script: Script=ResourceLoader.load(path,"Script",ResourceLoader.CACHE_MODE_REUSE) as Script
		if not need(script!=null and script.can_instantiate(),"SCRIPT_LOAD_AND_CAN_INSTANTIATE_ONLY_NOT_NEW:"+path):finish();return
		records.append({"parsed_script":path,"sha256":FileAccess.get_sha256(path),"instance_created":false})
	finish()

func finish() -> void:
	if done:return
	done=true
	var last: Dictionary=facts() if not sources_first.is_empty() else {}
	if not sources_first.is_empty():need(sources_first==last,"EXACT_INPUT_FIRST_FINAL_METADATA")
	need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"CHECKPOINT_STILL_SUSPENDED_UNTIL_OWNED_EXIT")
	var path: String=directory+"/result.json"
	if FileAccess.file_exists(path):quit(2);return
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"first_sources":sources_first,"final_sources":last,"Field_instances":0,"World_instances":0,"game_input":0,"SaveManager_API_calls":0,"save_reads":0,"save_writes":0,"production_writes":0,"decode_is_not_geometry_or_GPU_scene_acceptance":true},"\t")+"\n");file.close()
	print("BRIDGE_IMPORT_DECODE_RESULT ",checks," / ",errors.size());quit(0 if errors.is_empty() else 1)
