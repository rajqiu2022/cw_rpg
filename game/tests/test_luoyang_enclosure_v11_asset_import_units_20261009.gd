extends SceneTree
## Independent fixed-manifest source/import test; no Field or producer oracle.
## Root must additionally protect all15 player exact UTC ticks in its wrapper.
const CITY_ROOT := "res://art/maps/luoyang_enclosure_v11/"
const ENGINE_SHA := "975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
const BRIDGE_PATH := "res://scripts/autoload/platform_bridge.gd"
const BRIDGE_SHA := "eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a"
const PATCHES := {
	"ch4_s0_luoyang_gate":"20cb77de45df28def34fdeee5f7c75300182ade0a1f6af338088059e47f05de1",
	"ch4_s1_luoyang_yamen":"2e1f562c429aabc89ebd38f044192e0f8dd71738147cb51b5fba4f9d6b7b50d4",
	"ch4_s2_canal_docks":"b4b06110c299bf97dad8eb7134d8b0902135b37bc7c7f4952522ce6f30a5cf23",
	"ch4_s3_luoyang_market":"ba46bfa02e4152918d6696033450bf1f0329be01318f69449a7fad7355a85c84",
}
const GROUNDS := {
	"ch4_s0_luoyang_gate":"1976d00447c8c399b92c9c2b1abdd1c8ce09d97f45263e7449b726f16bbaa3d3",
	"ch4_s1_luoyang_yamen":"1fd971708ac0375e557749f8175b804ac58d71409e717e7be88cab7eb78e181f",
	"ch4_s2_canal_docks":"aa2aba7052cb289511eb83d68e6135d96e4001c2950763bb9309e2cdbac2e744",
	"ch4_s3_luoyang_market":"559c0ffc87f822873e9fbf04aa9b0ce49d98794a806b29a6efd75c16e3847fae",
}
var checks := 0
var failures := 0
var first: Dictionary = {}
var rows: Array[Dictionary] = []
var output := ""
var players: Dictionary = {}
var active_slot: Variant

static func fixture_sources() -> Array[String]:
	var files: Array[String] = ["res://tests/test_luoyang_enclosure_v11_asset_import_units_20261009.gd",BRIDGE_PATH,"res://scripts/autoload/save_manager.gd","res://data/scenes/world_map_jianghu.tres","res://data/config/outskirts_native_adoption.json"]
	for id: String in PATCHES:
		files.append("res://data/scenes/"+id+".tres")
		files.append(CITY_ROOT+id+"/art_patch.json")
		files.append(CITY_ROOT+id+"/ground_v14/root_ground_v14_02/ground_capture.json")
	return files

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures+=1; push_error("[CITY ASSET IMPORT FAIL] "+label)
	return ok
func _file(path: String) -> Dictionary:
	var exists: bool=FileAccess.file_exists(path)
	var file: FileAccess=FileAccess.open(path,FileAccess.READ) if exists else null
	return {"exists":exists,"bytes":file.get_length() if file!=null else 0,"sha256":FileAccess.get_sha256(path) if exists else "ABSENT","mtime_seconds":FileAccess.get_modified_time(path) if exists else 0}
func _track(path: String) -> bool:
	var now: Dictionary=_file(path)
	if not _check(now.exists,"consumed source exists "+path): return false
	if first.has(path): return _check(first[path]==now,"same-run repeated source identity "+path)
	first[path]=now
	return true
func _players() -> Dictionary:
	var result: Dictionary={}
	for index in 5:
		for suffix: String in ["",".bak",".tmp"]: result["user://save_%d.json%s"%[index,suffix]]=_file("user://save_%d.json%s"%[index,suffix])
	return result
func _json(path: String) -> Variant:
	var parser:=JSON.new()
	return parser.data if parser.parse(FileAccess.get_file_as_string(path))==OK else null
func _bound(path: String,digest: Variant) -> bool:
	return typeof(digest)==TYPE_STRING and digest.length()==64 and FileAccess.get_sha256(path).to_lower()==digest.to_lower() and _track(path)
func _sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	context.start(HashingContext.HASH_SHA256); context.update(bytes)
	return context.finish().hex_encode()

func _run() -> void:
	# Public guard is the first action, before any await or fixture.
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	if not _check(bridge.call("is_checkpoint_saves_suspended")==true,"public checkpoint suspension acknowledged"): quit(1); return
	players=_players(); active_slot=root.get_node("SaveManager").get("active_slot")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if not _check("--luoyang-enclosure-asset-import-units" in args and not "--activate" in args,"explicit nonpublication import scope"): quit(1); return
	output="res://build/joint_world_luoyang_20261003_qa/luoyang_asset_import_units_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique evidence only"): quit(1); return
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==ENGINE_SHA,"actual WASAPI/executable/start time")
	_check(FileAccess.get_sha256(BRIDGE_PATH).to_lower()==BRIDGE_SHA,"public checkpoint source pin")
	for path: String in fixture_sources(): _track(path)
	var seen: Dictionary={}
	for id: String in PATCHES:
		var patch_path: String=CITY_ROOT+id+"/art_patch.json"
		var ground_path: String=CITY_ROOT+id+"/ground_v14/root_ground_v14_02/ground_capture.json"
		if not _check(_bound(patch_path,PATCHES[id]) and _bound(ground_path,GROUNDS[id]),"independent fixed patch/ground SHA "+id): continue
		var patch: Variant=_json(patch_path); var ground: Variant=_json(ground_path)
		if not _check(patch is Dictionary and ground is Dictionary,"actual JSON containers "+id): continue
		if not _check(typeof(patch.get("canonical_scene_id"))==TYPE_STRING and patch.canonical_scene_id==id and typeof(ground.get("canonical_scene_id"))==TYPE_STRING and ground.canonical_scene_id==id and patch.get("objects") is Array and patch.get("asset_sha256") is Dictionary and ground.get("asset_sha256") is Dictionary,"fixed container identities/catalogs "+id): continue
		for object: Variant in patch.objects:
			if not _check(object is Dictionary and typeof(object.get("id"))==TYPE_STRING and typeof(object.get("texture"))==TYPE_STRING,"actual entity declaration "+id): continue
			var path: String=CITY_ROOT+id+"/entities/"+object.id+".png"
			if not _check(object.texture==path and not seen.has(path) and _bound(path,patch.asset_sha256.get(path)),"unique exact named entity/source SHA "+path): continue
			seen[path]=true; _image(id,"entity",object.id,path)
		var walk: String=CITY_ROOT+id+"/walk.png"
		if _check(typeof(patch.get("walk_path"))==TYPE_STRING and patch.walk_path==walk and _bound(walk,patch.asset_sha256.get(walk)),"exact current walk/source SHA "+id): _image(id,"walk","walk",walk)
		var floor: String=ground_path.get_base_dir()+"/floor.png"
		if _check(typeof(ground.get("ground_path"))==TYPE_STRING and ground.ground_path==floor and _bound(floor,ground.asset_sha256.get(floor)),"exact current floor/source SHA "+id): _image(id,"floor","floor",floor)
	var counts: Dictionary={"entity":0,"walk":0,"floor":0}
	for row: Dictionary in rows: counts[row.role]+=1
	_check(counts=={"entity":28,"walk":4,"floor":4} and rows.size()==36,"all36 exact current assets, no subset")
	_finish(bridge,counts)

func _image(id: String,role: String,oid: String,path: String) -> void:
	if not _track(path+".import"): return
	var config:=ConfigFile.new()
	if not _check(config.load(path+".import")==OK,"actual import configuration "+path): return
	var compiled: Variant=config.get_value("remap","path",null)
	if not _check(typeof(compiled)==TYPE_STRING and compiled.begins_with("res://.godot/imported/") and not ".." in compiled,"actual compiled import path "+path): return
	if not _track(compiled): return
	var source: Image=Image.load_from_file(path)
	var texture: Texture2D=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var imported: Image=texture.get_image() if texture!=null else null
	if not _check(source!=null and imported!=null,"actual raw and ResourceLoader images "+path): return
	var original_format: int=source.get_format(); var loaded_format: int=imported.get_format(); var loaded_mips: int=imported.get_mipmap_count()
	if not _check(not source.has_mipmaps() and (not imported.is_compressed() or imported.decompress()==OK),"raw base/no mip plus loaded decode "+path): return
	source.convert(Image.FORMAT_RGBA8); imported.convert(Image.FORMAT_RGBA8)
	var expected: PackedByteArray=source.get_data()
	var full: PackedByteArray=imported.get_data()
	var byte_count: int=source.get_width()*source.get_height()*4
	var actual: PackedByteArray=full.slice(0,byte_count)
	var exact: bool=source.get_size()==imported.get_size() and expected.size()==byte_count and actual.size()==byte_count and expected==actual
	_check(exact,"all base RGBA bytes exact "+path)
	if role=="entity": _check(typeof(config.get_value("params","process/fix_alpha_border"))==TYPE_BOOL and config.get_value("params","process/fix_alpha_border")==false,"current entity alpha-border processing explicitly disabled "+path)
	rows.append({"city_id":id,"role":role,"object_id":oid,"path":path,"source_sha256":first[path].sha256,"import_path":path+".import","import_sha256":first[path+".import"].sha256,"compiled_path":compiled,"compiled_sha256":first[compiled].sha256,"dimensions":[source.get_width(),source.get_height()],"source_format_before":original_format,"imported_format_before":loaded_format,"imported_mipmap_count":loaded_mips,"base_bytes":byte_count,"source_rgba_base_sha256":_sha(expected),"imported_rgba_base_sha256":_sha(actual),"all_base_rgba_exact":exact,"fix_alpha_border":config.get_value("params","process/fix_alpha_border"),"source_or_import_modified_by_test":false})

func _finish(bridge: Node,counts: Dictionary) -> void:
	var last: Dictionary={}
	for path: String in first: last[path]=_file(path)
	_check(last==first,"all consumed raw/config/compiled/manifest/protected files unchanged")
	var players_after: Dictionary=_players()
	_check(players==players_after and active_slot==root.get_node("SaveManager").get("active_slot"),"all15 player files/slot unchanged")
	_check(bridge.call("is_checkpoint_saves_suspended")==true and AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==ENGINE_SHA,"public checkpoint suspension/actual engine/audio at finish")
	var result: Dictionary={"scope":"LUOYANG_FIXED_CURRENT_ASSET_IMPORT_ALL_BASE_RGBA_NOT_FIELD","complete":failures==0,"checks":checks,"failures":failures,"counts":counts,"rows":rows,"source_before":first,"source_after":last,"players_before":players,"players_after":players_after,"active_slot_before":active_slot,"active_slot_after":root.get_node("SaveManager").get("active_slot"),"exact_UTCticks":"ROOT_EXTERNAL_FRESH_BEFORE_AFTER_REQUIRED","actual_audio_driver":AudioServer.get_driver_name(),"engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"Field_executed":false,"producer_expected_called":false,"formal_approved":false,"checkpoint_restored":false}
	var file:=FileAccess.open(output+"result.json",FileAccess.WRITE)
	if not _check(file!=null,"unique result writable"): quit(1); return
	var encoded: String=JSON.stringify(result,"\t",false)
	file.store_string(encoded); file.flush(); var saved: bool=file.get_error()==OK; file.close()
	_check(saved and _json(output+"result.json")==JSON.parse_string(encoded),"actual result readback")
	print("CITY_ASSET_IMPORT_RESULT "+output+"result.json count="+str(rows.size())+" checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures==0 else 1)
