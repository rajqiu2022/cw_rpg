extends SceneTree
## Two original bounties plus passive health/TRAVEL_READY ONLY. Not a SIX slot.
## Requires outer before/after source and all15 player precise UTC ticks.
## No world15, historical migration, approval signing or production writes.
const PHASE_PATH := "res://tests/helpers/luoyang_enclosure_v11_bounty_travel_ready_health_phase_20261012.gd"
const SAVE_PATH := "res://tests/helpers/luoyang_enclosure_v11_city_only_current_save.gd"
const RAW_PATH := "res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd"
const TARGET_RAW_PATH := "res://tests/helpers/luoyang_enclosure_v11_target_root_and_feet_raw_20261011.gd"
const CONTRACT_PATH := "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const ENGINE_SHA := "975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
const BRIDGE_PATH := "res://scripts/autoload/platform_bridge.gd"
const BRIDGE_SHA := "eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a"
const IDS: Array[String]=["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
const PROTECTED: Array[String]=["res://data/scenes/world_map_jianghu.tres","res://data/config/outskirts_native_adoption.json"]
const MUSIC_TRACK_IDS: Array[String]=["city_luoyang","city_bianzhou","city_jinling","city_xiangzhou","town_qinghe","pass_yanmen","village_zhuwei","village_night","outskirts_zhuxi_linxi","outskirts_forest_xiangzhou","outskirts_wetland_jinling","story_tension","story_warm","story_joy","story_danger","battle_spar","battle_river","battle_village","battle_mountain","battle_boss","exploration_mountain","exploration_journey","battle_default"]
const BOUNTY_SOURCES: Array[String]=[
	"res://scenes/bounty_board.tscn",
	"res://scripts/ui/bounty_board.gd",
	"res://scripts/autoload/bounty_manager.gd",
	"res://scripts/domain/bounty_def.gd",
	"res://data/bounties/luoyang_red_scar.tres",
	"res://data/bounties/luoyang_seal_thief.tres",
	"res://data/scenes/openworld_bianzhou_old_post.tres",
	"res://data/scenes/openworld_xiangzhou_mine_valley.tres",
	"res://data/enemies/bounty_red_scar.tres",
	"res://data/enemies/central_road_scout.tres",
	"res://data/enemies/bounty_seal_thief.tres",
	"res://data/enemies/mine_outlaw.tres",
	"res://data/enemies/central_road_raider.tres",
	"res://data/enemies/mine_brute.tres",
]
const PINNED: Dictionary={
	"res://tests/helpers/luoyang_enclosure_v11_bounty_travel_ready_health_phase_20261012.gd":"f5a5551fe19c94cf44636a24494c8d4d4b76a8986e28265b07e075b33d2a2922",
	"res://tests/helpers/luoyang_bounty_health_observation_input_driver_20261012.gd":"d69975fc078b31277b6ed747076c8e1d6d42ed0bcddab090157a90b485ada7b8",
	"res://tests/test_luoyang_enclosure_v11_bounty_live_field_continuation_20261011.gd":"307f9419db38b10ef03230e96a74ee3a0f8b62cc1a00afa9c307ec53dc083888",
	"res://scripts/autoload/loading_manager.gd":"019a2210d6bfd3d13a2d6c939389d3f67c6c9671ffa36d89c563f54fc4b07910",
	"res://scripts/autoload/event_bus.gd":"c42bdb64161dfec0aa7e65e6027b0b335dee358f84558068abb54ccd26785db8",
	"res://scripts/domain/character_stats.gd":"2e502cb6868981ebed1e4c81b88179467fa4dd2aa55e9f0260cfb6002e0aa6a0",
	"res://scripts/battle/battle_combatant.gd":"0c7bcfc193ece9b42ec27e66dca589b5765a9218e2967e79f201d139b367db29",
	"res://tests/helpers/luoyang_enclosure_v11_bounty_encounter_continuation_phase_20261011.gd":"07f171092bec8669dbd25a62ac50ce363c573120a8b023d168810f0a25066893",
	"res://tests/test_luoyang_enclosure_v11_bounty_encounter_continuation_20261011.gd":"e76592e680602a6e48dc18cec2171e7cd2e3900ae24060b61378d1635540d92b",
	"res://tests/helpers/luoyang_bounty_live_field_input_driver_20261011.gd":"905a37e4170bb4fbc0a1f661602262910508c8574858670820d48f0a4d142199",
	"res://scenes/battle.tscn":"8476a5c23a4eec1194d65a390daeaebf860d93845f203aed9e2768d8907cbaa9",
	"res://scripts/battle/battle_controller.gd":"bad948d80679350289dc70c1a550c522a8173cc4c88bef75f02b2db3e6b4a087",
	"res://tests/helpers/luoyang_enclosure_v11_bounty_only_observation_phase_20261011.gd":"5932a7f6cd156b7e70b37f3ad463da80a63d6abd7b6343f11b2795dab7ad4546",
	"res://tests/test_luoyang_enclosure_v11_bounty_only_observation_20261011.gd":"4a2867577a8877fda36b4d69c4617d3d6027c3e0d46c775ae516fa08d2d04095",
	"res://tests/helpers/luoyang_enclosure_v11_bounty_live_field_continuation_phase_20261011.gd":"9e59b6977d8dee0ee4bc349d2ecdddec2d3760b5357508892da4dc404768ec65",
	"res://tests/test_luoyang_enclosure_v11_authored_input_repairs_focused_20261011.gd":"d4973b585fb84baa8c73ed2aadd124705b62264f3f7586dc090eef4ddc2e8277",
	"res://scripts/ui/bounty_board.gd":"c6646f2da0a75527dfc41196081f806a6a08de7f77725a6af567a735487c4583",
	"res://scripts/autoload/bounty_manager.gd":"823a22d748d4ee846b5d68c6479b4e7d0ffd3e8fe859a8525dc0aa9db42111ed",
	"res://data/bounties/luoyang_red_scar.tres":"49420f431307ddc913d5671872d0d843d27d47c3446e3cbda942ab5083201463",
	"res://data/bounties/luoyang_seal_thief.tres":"64b4ed66c835789811bb5baa05ad725f422143c0f6bbfaca9906839df6034a24",
	"res://scripts/audio/music_catalog.gd":"cafbabdd3d82f1ebf6d694e9cc6f2eb2cf04744a4febb36a0503eb0cdf3c39e4",
	"res://scripts/autoload/scene_router.gd":"f3ead7459632188350e1e3383ee915c83b71c1b86d36dadf718bd338a4324eca",
	"res://tests/helpers/luoyang_enclosure_v11_authored_input_repairs_focused_phase_20261011.gd":"9bd4bc5115c5611365b8c7fd390d2fcd07a607c2bcc5f460b45dad8ac58f93da",
	"res://tests/helpers/luoyang_enclosure_v11_city_only_indirect_market_return_phase_20261011.gd":"3c37cf6568f1cd1ba6d41c28c276879ca6a352205c9c5a9f8b8acdaabf0ab1a6",
	"res://tests/helpers/luoyang_enclosure_v11_city_only_phase.gd":"47006fbee07d3d4c88c223816ca3876bdfde2bf3b1583ff5b6ca674c2944045a",
	"res://scripts/field/field_walkable_controller.gd":"8c7d4cad1838e31c2693bf5711095fccba6d895a5f258f9fd967b807ece30a1c",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"558a3edfaa368ff52b67ff0eaade7505191011928c2a724897efc727e43887f6",
	"res://tests/helpers/luoyang_wasapi_catalog3_continuity_20261011.gd":"62acbff384fecf1de7309907745c2e736bdaefd6f3b3d34b7e8dcb86fe9e9f6a",
	"res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd":"3291a768f9cab0ca7ae8d348f4d86532c3aefb846d0749424663dcc13d07b892",
	"res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd":"f926cf876da1afe746411ff5a007a49894b191040e57e709bdbc486021b3e535",
	"res://scripts/city/luoyang_city3_motion_guard_20261009.gd":"aacd53e5020bc5a40353d9cf7537662c44139fa7f861e3a54c6faf59e8ba3a93",
	"res://scripts/field/player.gd":"9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419",
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://data/scenes/world_map_jianghu.tres":"838380fdb05d08b4b521d92efb12a13369358090740dc5c7d4cb7c9ec6f4c015",
	"res://data/maps/world_map_jianghu_layout_v14.tres":"3dfa1f251b5a5319b8cc6d6b902932fde6382470ae597c697e391252e98f2b3b",
}
var checks: int=0
var failed: int=0
var output: String=""
var paths: Dictionary={}
var first: Dictionary={}
var players: Dictionary={}
var slot: Variant
var contract: Script
var checkpoint: Dictionary={}

static func fixture_sources() -> Array[String]:
	# Outer wrapper expands the ordinary literal .gd dependency closure.
	var sources: Array[String]=[PHASE_PATH,SAVE_PATH,RAW_PATH,TARGET_RAW_PATH,CONTRACT_PATH,BRIDGE_PATH,
		"res://tests/test_luoyang_enclosure_v11_bounty_travel_ready_health_20261012.gd",
		"res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd",
		"res://tests/helpers/luoyang_enclosure_v11_city_only_phase.gd",
		"res://tests/helpers/luoyang_wasapi_catalog3_continuity_20261011.gd",
		"res://data/maps/world_map_jianghu_layout_v14.tres",
		"res://scripts/autoload/scene_router.gd","res://scripts/city/luoyang_layered_v3_contract.gd",
		"res://data/scenes/world_map_jianghu.tres","res://data/config/outskirts_native_adoption.json",
		"res://data/scenes/ch4_s0_luoyang_gate.tres","res://data/scenes/ch4_s1_luoyang_yamen.tres",
		"res://data/scenes/ch4_s2_canal_docks.tres","res://data/scenes/ch4_s3_luoyang_market.tres"]
	sources.append_array(BOUNTY_SOURCES)
	for id: String in MUSIC_TRACK_IDS: sources.append("res://art/audio/bgm/wuxia_20261011/"+id+".wav")
	return sources

static func mode(args: Array) -> Dictionary:
	for value: Variant in args:
		if typeof(value)!=TYPE_STRING: return {}
		if value.begins_with("--city-qa-phase="): return {}
	for required: String in ["--luoyang-bounty-only-observation","--fresh-start-only","--luoyang-enclosure-v11-candidate","--luoyang-v3-candidate"]:
		if args.count(required)!=1: return {}
	for forbidden: String in ["--luoyang-city-only-fresh","--candidate-before-cutover","--outskirts-candidate-preview","--outskirts-complete-v5","--qa-phase=release"]:
		if forbidden in args: return {}
	return {"phase":"bounty_only_diagnostic","candidate":true}

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failed+=1; push_error("[CITY ONLY FRESH FAIL] "+label)
	return ok

func _file(path: String) -> Dictionary:
	var present: bool=FileAccess.file_exists(path)
	var file: FileAccess=FileAccess.open(path,FileAccess.READ) if present else null
	return {"exists":present,"bytes":file.get_length() if file!=null else 0,"sha256":FileAccess.get_sha256(path) if present else "ABSENT","mtime_seconds":FileAccess.get_modified_time(path) if present else 0}

func _normal_files() -> Dictionary:
	var result: Dictionary={}
	for index in 5:
		for suffix: String in ["",".bak",".tmp"]:
			var path: String="user://save_%d.json%s"%[index,suffix]
			result[path]=_file(path)
	return result

func _track(path: String) -> void:
	if paths.has(path): return
	paths[path]=true
	if not _check(FileAccess.file_exists(path),"required consumed source exists "+path): return
	if path.get_extension().to_lower() in ["png","jpg","jpeg","webp","wav","ogg","mp3"]:
		var import_path: String=path+".import"
		_track(import_path)
		var config:=ConfigFile.new()
		if _check(config.load(import_path)==OK,"actual import metadata "+path):
			if config.has_section_key("deps","dest_files"):
				var destinations: Variant=config.get_value("deps","dest_files")
				if _check(destinations is Array or destinations is PackedStringArray,"actual import destination list "+path):
					for destination: Variant in destinations:
						if _check(typeof(destination)==TYPE_STRING and not destination.is_empty(),"typed imported destination "+path): _track(destination)
			else:
				_check(config.get_value("remap","importer","") in ["keep","skip"],"no compiled output only explicit keep/skip "+path)
	if path.get_extension()!="gd": return
	var pattern:=RegEx.new()
	pattern.compile('res://[^"\\\r\n]+[.]gd')
	var body: String=FileAccess.get_file_as_string(path)
	for source_match: RegExMatch in pattern.search_all(body):
		# A quoted .gd leaf, never a .gdshader substring or a directory.
		if source_match.get_end()<body.length() and body.substr(source_match.get_end(),1) in ['"',"'"]:
			_track(source_match.get_string())

func _snapshot() -> Dictionary:
	var result: Dictionary={}
	# Each unique path is freshly read once per endpoint, never a reused digest.
	for path: String in paths: result[path]=_file(path)
	return result

func _write(name: String,value: Dictionary) -> bool:
	var path: String=output+name
	if FileAccess.file_exists(path): return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	var encoded: String=JSON.stringify(value,"\t",true)
	file.store_string(encoded); file.flush()
	var ok: bool=file.get_error()==OK
	file.close()
	var parser:=JSON.new()
	return ok and parser.parse(FileAccess.get_file_as_string(path))==OK and parser.data==JSON.parse_string(encoded)

func _run() -> void:
	# First public suspension, before any await or fixture.
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): quit(1); return
	var default: Variant=bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended",true)
	checkpoint={"default_suspended":default,"before_any_await":bridge.call("is_checkpoint_saves_suspended"),"automatic_checkpoint_saves_tested":false,"restored_before_exit":false}
	_check(typeof(default)==TYPE_BOOL and default==false and checkpoint.before_any_await==true and FileAccess.get_sha256(BRIDGE_PATH).to_lower()==BRIDGE_SHA,"exact public defaultfalse/suspendtrue checkpoint source")
	players=_normal_files(); slot=root.get_node("SaveManager").get("active_slot")
	var selected: Dictionary=mode(Array(OS.get_cmdline_user_args()))
	_check(not selected.is_empty(),"explicit unmixed original two-bounty observation mode, not original six")
	output="res://build/joint_world_luoyang_20261003_qa/luoyang_bounty_travel_ready_health_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique actual evidence output")
	var scripts: Dictionary={}
	for path: String in [get_script().resource_path,PHASE_PATH,SAVE_PATH,RAW_PATH,TARGET_RAW_PATH,CONTRACT_PATH,BRIDGE_PATH,"res://scripts/autoload/scene_router.gd","res://scripts/city/luoyang_layered_v3_contract.gd"]:
		_track(path)
		var script: Script=load(path) as Script
		_check(script!=null and script.can_instantiate(),"actual script load/can_instantiate "+path)
		scripts[path]=script
	for path: String in PINNED:
		_track(path)
		_check(PINNED[path].length()==64 and FileAccess.get_sha256(path).to_lower()==PINNED[path],"exact current/source pin "+path)
	for path: String in BOUNTY_SOURCES: _track(path)
	for id: String in MUSIC_TRACK_IDS: _track("res://art/audio/bgm/wuxia_20261011/"+id+".wav")
	for path: String in PROTECTED: _track(path)
	for id: String in IDS: _track("res://data/scenes/"+id+".tres")
	for id: String in IDS:
		_track("res://data/maps/luoyang_v3_legacy/"+id+"_scene.tres")
		_track("res://data/maps/luoyang_v3_legacy/"+id+"_layout.tres")
	_check(AudioServer.get_driver_name()=="WASAPI" and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==ENGINE_SHA and Engine.time_scale==1.0,"actual WASAPI/executable/ordinary time")
	contract=scripts.get(CONTRACT_PATH) as Script
	var records: Dictionary={}
	if failed==0:
		var reader: RefCounted=(scripts[RAW_PATH] as Script).new()
		for id: String in IDS:
			for path: String in [contract.call("base_manifest_path",StringName(id)),contract.call("manifest_path",StringName(id))]:
				_track(path)
			var record: Dictionary=reader.call("independent_record",StringName(id))
			_check(not record.is_empty(),"current independently SHA-bound BASE + new patch "+id)
			if record.is_empty(): continue
			records[id]=record.duplicate(true)
			if record.has("ground_capture_path"): _track(String(record.ground_capture_path))
			for path: String in record.asset_sha256: _track(path)
			if record.has("enclosure_patch_path"):
				var patch: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(record.enclosure_patch_path))
				_track(String(patch.export_plan_path))
			for path: String in [contract.call("candidate_path",StringName(id)),contract.call("layout_path",StringName(id))]:
				if FileAccess.file_exists(path): _track(path)
		reader.call("release"); reader=null
	first=_snapshot()
	_check(_write("source_before.json",first),"initial unique source snapshot")
	var report: Dictionary={}
	if failed==0:
		var phase: RefCounted=(scripts[PHASE_PATH] as Script).new()
		report=await phase.call("run_bounty_diagnostic",self,output)
		_check(report.get("complete")==true,"both original bounties, unchanged UI/input/Physics/reward gates")
		phase=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	for tick in 8: await process_frame
	var cleanup_start: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-cleanup_start<9000000: await process_frame
	root.get_node("AudioManager").call("stop_bgm",.15)
	var drain: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-drain<250000: await process_frame
	for shape: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for tick in 4: await process_frame
	var last: Dictionary=_snapshot()
	_check(first==last,"all consumed unique source/asset bytes and modification seconds unchanged")
	_check(players==_normal_files() and slot==root.get_node("SaveManager").get("active_slot"),"all15 normal player existence/bytes/SHA/mtime_seconds and slot unchanged")
	_check(bridge.call("is_checkpoint_saves_suspended")==true and AudioServer.get_driver_name()=="WASAPI" and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==ENGINE_SHA and Engine.time_scale==1.0,"checkpoint remains suspended; actual audio/engine/time intact")
	var result: Dictionary={"schema":1,"scope":"LUOYANG_TWO_BOUNTY_TRAVEL_READY_HEALTH_NOT_SIX","six_slot_eligible":false,"full_gameplay_tested":false,"full_geometry_tested":false,"mode":selected,"complete":failed==0 and report.get("complete")==true,"checks":checks+1,"failures":failed,"stage":report,"diagnostic_collection_complete":report.get("diagnostic_collection_complete",false),"source_before":first,"source_after":last,"players_before":players,"players_after":_normal_files(),"active_slot_before":slot,"active_slot_after":root.get_node("SaveManager").get("active_slot"),"checkpoint_suspension":checkpoint,"actual_audio_driver":AudioServer.get_driver_name(),"engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"historical_compatibility_tested":false,"world_subject_version":14,"world_full_tested":false,"formal_approved":false,"exact_UTCticks":"ROOT_EXTERNAL_FRESH_BEFORE_AFTER_REQUIRED","stderr_acceptance":"ROOT_MUST_READ_COMPLETE_LOG_AND_ACTUAL_OS_EXIT","output":output}
	_check(_write("result.json",result),"limited original bounty-observation final result checked readback")
	print("BOUNTY_ONLY_OBSERVATION_RESULT "+output+"result.json checks="+str(checks)+" failures="+str(failed))
	quit(0 if failed==0 else 1)


