extends SceneTree
## NEW wall_v4 ordinary Field geometry/camera diagnostic, not JOINT FULL.
## Exact original limited-wrapper predicates are retained; current city helper
## _open/run_routes/run_objects only. Never call phase.run(), world restore,
## migration, publisher, reward/action shortcuts, or write normal player saves.
const ORIGIN_PATH: String="res://tests/test_joint_v15_city_geometry_limited_20261004.gd"
const ORIGIN_SHA: String="7d9871b510f172fadd6ac4e41e3e748711cfe838ea2936c640fa6c5a9f631ded"
const PHASE_PATH: String="res://tests/helpers/joint_v15_wall_street_city_gameplay_lifecycle_grace_phase.gd"
const PREPARED_PATH: String="res://tests/helpers/joint_v15_wall_street_city_prepared_phase.gd"
const PHYSICAL_PATH: String="res://tests/helpers/joint_v15_wall_street_city_physical_alpha_probe.gd"
const RAW_PATH: String="res://tests/helpers/joint_v15_wall_street_ordinary_raw_oracle.gd"
const INPUT_PATH: String="res://tests/helpers/v15_input_driver.gd"
const SUBJECT_PATH: String="res://scripts/city/luoyang_layered_v3_wall_street_candidate_contract.gd"
const ART_ROOT: String="res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v4/"
const CITY_IDS: Array[String]=["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
const MANIFEST_SHA: Dictionary={
	"ch4_s0_luoyang_gate":"eee86daaf99af0c79841d40e542094e8a97ea8d99b347f22f263f77edd65be30",
	"ch4_s1_luoyang_yamen":"160fdba2690f3954e420abdb15b5ba0ff995e0d19a53e684bb5b479edc1ff34b",
	"ch4_s2_canal_docks":"01048fbd06f2a6aaddf1b06834cb1f2bea13558a7f171c2e3805f83366aaf029",
	"ch4_s3_luoyang_market":"97552eb72af1c7d8524fbcd93ee84406f990e32724f0725f3027170b58ea5345"
}
const SOURCE_SHA: Dictionary={
	ORIGIN_PATH:ORIGIN_SHA,
	PHASE_PATH:"fdf51d2e5ab0ac3f35aa72214bc565e4c1addccb17fc19eb576695c0d0588bf8",
	PREPARED_PATH:"9e8b747bef4476de7aa1dbd2d51d367004323af6a33be487fe1438faf16bb4ca",
	PHYSICAL_PATH:"ca5f919320364b2e8346f057044a62a0dd0bfe99b49f2d029b7362d129bbd5f2",
	RAW_PATH:"b758615be40b6bc4c6de126ae1540d0ad0890942b4d7988f1da475e452943089",
	INPUT_PATH:"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	SUBJECT_PATH:"25ca8fcfd5a6ca33e97d99094bf5304a7a200e9a3533e9baf822ee341b65ee3d",
	"res://scripts/city/luoyang_layered_v3_contract.gd":"7664f0c9818440bce39a948f6d9ed6f84015ef74e048c324a2b0c8c780313b7f",
	"res://scripts/dev/luoyang_v3_wall_street_saved_resource_checker.gd":"609d323892e9787e51b1e085db24c13935f94547dc630b21d95949e4a42bec5b",
	"res://scripts/field/field_walkable_controller.gd":"b3301d6064e332e519b0fc3b4daed880ec3d77d98f2c744933b5d7077b9eb8ef"
}
const RUNTIME_PATHS: Array[String]=[
	"res://scripts/city/luoyang_layered_v3_contract.gd",
	"res://scripts/city/luoyang_v3_modular_overlap.gd",
	"res://scripts/world/outskirts_modular_overlap.gd",
	"res://scripts/world/v14_modular_overlap.gd",
	"res://scripts/field/field_walkable_controller.gd",
	"res://scripts/field/player.gd","res://scripts/field/npc_node.gd",
	"res://scripts/autoload/scene_router.gd","res://scripts/autoload/loading_manager.gd",
	"res://scripts/autoload/save_manager.gd",
]
var phase: RefCounted
var checks: int=0
var failed: int=0
var output: String=""
var before_files: Dictionary={}
var before_slot: Variant
var source_before: Dictionary={}
var trials: Dictionary={}
var preflight: Dictionary={}
var navigation_before: Dictionary={}
var screenshots: Array=[]

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:
		failed+=1
		push_error("[CITY WALL V4 GEOMETRY FAIL] "+label)
	return ok

func _normal_files() -> Dictionary:
	var files: Dictionary={}
	for slot in 5:
		for suffix: String in ["",".bak",".tmp"]:
			var path: String="user://save_%d.json%s"%[slot,suffix]
			var entry: Dictionary={"exists":FileAccess.file_exists(path)}
			if bool(entry.exists):
				var file: FileAccess=FileAccess.open(path,FileAccess.READ)
				entry["readable"]=file!=null
				entry["bytes"]=file.get_length() if file!=null else -1
				if file!=null: file.close()
				entry["sha256"]=FileAccess.get_sha256(path)
				entry["mtime_seconds"]=FileAccess.get_modified_time(path)
			files[ProjectSettings.globalize_path(path)]=entry
	return files

func _write(name: String,value: Dictionary) -> bool:
	var path: String=output+name
	if FileAccess.file_exists(path): return false
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	var encoded: String=JSON.stringify(value,"\t")
	file.store_string(encoded)
	file.flush()
	var error: Error=file.get_error()
	file.close()
	return error==OK and JSON.parse_string(FileAccess.get_file_as_string(path))==JSON.parse_string(encoded)

func _source_snapshot(_ready: Dictionary) -> Dictionary:
	var paths: Dictionary={}
	for path: String in SOURCE_SHA: paths[path]=true
	for path: String in RUNTIME_PATHS: paths[path]=true
	paths[get_script().resource_path]=true
	for id: String in CITY_IDS:
		var path: String=ART_ROOT+id+"/art_contract.json"
		paths[path]=true
		var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		if value is Dictionary:
			for asset: String in value.get("asset_sha256",{}): paths[asset]=true
			for source: String in value.get("source_graph",{}): paths[source]=true
	# Snapshot gameplay resources and real reused normal code, not in-flight world
	# outputs. This is protection evidence, never a JOINT approval source catalog.
	_collect_sources("res://data",["tres"],paths)
	for directory: String in ["res://scripts/autoload","res://scripts/field","res://scripts/city","res://scripts/ui","res://scripts/battle"]:
		_collect_sources(directory,["gd"],paths)
	var result: Dictionary={}
	for path: String in paths: result[path]=FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "MISSING"
	return result

func _collect_sources(directory: String,extensions: Array,paths: Dictionary) -> void:
	var listing: DirAccess=DirAccess.open(directory)
	if listing==null: paths[directory+"/MISSING_DIRECTORY"]=true; return
	listing.list_dir_begin()
	var name: String=listing.get_next()
	while not name.is_empty():
		if not name.begins_with("."):
			var path: String=directory+"/"+name
			if listing.current_is_dir(): _collect_sources(path,extensions,paths)
			elif name.get_extension() in extensions: paths[path]=true
		name=listing.get_next()
	listing.list_dir_end()

func _preflight() -> void:
	var subject_script: GDScript=load(SUBJECT_PATH) as GDScript
	if not _check(subject_script!=null and subject_script.can_instantiate(),"current wall_v4 subject compiles in normal autoload context"): return
	preflight={"scope":"CURRENT_WALL_V4_STRICT_CAPTURE_SAVED_RESOURCE_BINDING_NOT_FIELD_APPROVAL","regions":{}}
	for id: String in CITY_IDS:
		var path: String=ART_ROOT+id+"/art_contract.json"
		if not _check(FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==MANIFEST_SHA[id],"exact ROOT156-159 current city manifest: "+id): continue
		var accepted: bool=bool(subject_script.call("prepare",StringName(id)))
		var prepare_errors: Array=subject_script.call("errors")
		_check(accepted,"all current catalog/camera/body/support/18wall saved-resource checks remain mandatory: "+id)
		print("CITY_WALL_V4_PREPARE ",id," accepted=",accepted," errors=",JSON.stringify(prepare_errors))
		(preflight.regions as Dictionary)[id]={"manifest_path":path,"manifest_sha256":MANIFEST_SHA[id],"strict_city_prepare_accepted":accepted,"prepare_errors":prepare_errors}
	subject_script=null

func _run() -> void:
	before_files=_normal_files()
	before_slot=root.get_node("SaveManager").get("active_slot")
	navigation_before=root.get_node("SceneRouter").call("get_navigation_state")
	output="res://build/joint_world_luoyang_20261003_qa/city_wall_v4_geometry_limited_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(output)==OK,"unique four-city LIMITED geometry evidence directory")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	_check("--joint-city-wall-v4-geometry-limited" in args and "--luoyang-v3-candidate" in args,"explicit four-city geometry + candidate flags required")
	for argument: String in args: _check(argument in ["--joint-city-wall-v4-geometry-limited","--luoyang-v3-candidate","--qa-gpu-approved"],"no undeclared argument or world15 bypass: "+argument)
	_check(DisplayServer.get_name()=="headless" or "--qa-gpu-approved" in args,"GPU geometry requires explicit root authorization; headless signs no visual verdict")
	var ready: Dictionary={}
	for path: String in SOURCE_SHA:
		_check(FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==SOURCE_SHA[path],"exact frozen current execution source: "+path)
	source_before=_source_snapshot(ready)
	_check(not source_before.values().has("MISSING"),"all current executing/city/art/semantic sources present")
	if failed>0: await _finish(ready); return
	_preflight()
	_check(_write("four_city_source_preflight.json",preflight),"strict current four-city preflight retained; NOT Field/visual credit")
	if failed>0: await _finish(ready); return
	root.get_node("SceneRouter").call("reset_for_new_game")
	_check(int((root.get_node("SceneRouter").call("get_navigation_state") as Dictionary).get("world_map_version",-1))==14,"ordinary formal world14 baseline retained; no unpublished world15 restore")
	if failed>0: await _finish(ready); return
	var script: GDScript=load(PHASE_PATH) as GDScript
	if not _check(script!=null and script.can_instantiate(),"actual current prepared city phase compiles"): await _finish(ready); return
	phase=script.new() as RefCounted
	script=null
	phase.set("tree",self)
	phase.set("candidate",true)
	phase.set("output",output)
	phase.set("before_files",phase.call("_normal_files"))
	phase.set("before_slot",before_slot)
	var input_script: GDScript=load(INPUT_PATH) as GDScript
	if not _check(input_script!=null and input_script.can_instantiate(),"actual frozen normal input driver compiles"): await _finish(ready); return
	var driver: RefCounted=input_script.new() as RefCounted
	driver.call("configure",self)
	phase.set("driver",driver)
	driver=null
	input_script=null
	for id: String in CITY_IDS:
		var first_screenshot: int=((phase.get("records") as Dictionary).get("screenshots",[]) as Array).size()
		phase.call("_public_fixture",{})
		var opened: bool=await phase.call("_open",id)
		_check(opened,"normal go_field_smart creates actual current city candidate Field: "+id)
		if not opened: continue
		var live_field: Node=phase.get("field") as Node
		var actual_scene: SceneScript=live_field.get("_current_scene") as SceneScript if is_instance_valid(live_field) else null
		_check(actual_scene!=null and actual_scene.player_visual_scale==.91 and actual_scene.camera_zoom==1.05 and float(live_field.get("_camera_zoom"))==1.05,"ordinary actor .91 / normal city camera1.05 remain exact: "+id)
		await phase.call("_capture","arrival_"+id)
		var probe: RefCounted=phase.get("probe") as RefCounted
		_check(probe!=null,"actual ordinary physical/current-alpha probe bound: "+id)
		if probe==null: continue
		await probe.call("run_routes")
		await probe.call("run_objects")
		var evidence: Dictionary=(probe.get("data") as Dictionary).duplicate(true)
		var manifest: Dictionary=phase.get("manifest") as Dictionary
		var actual_ids: Dictionary={}
		for object: Dictionary in evidence.get("objects",[]): actual_ids[String(object.id)]=true
		_check((evidence.get("routes",[]) as Array).size()==(manifest.get("routes",[]) as Array).size(),"every current region route actually trialled: "+id)
		_check(actual_ids.size()==(manifest.get("objects",[]) as Array).size(),"every current region object actually bound and trialled, including explicit water-domain role: "+id)
		for object: Dictionary in manifest.get("objects",[]): _check(actual_ids.has(String(object.id)),"complete current object ID coverage: "+id+"/"+String(object.id))
		trials[id]={"manifest_sha256":FileAccess.get_sha256(ART_ROOT+id+"/art_contract.json"),"physical_and_current_alpha":evidence,"declared_route_count":(manifest.get("routes",[]) as Array).size(),"declared_object_count":(manifest.get("objects",[]) as Array).size(),"actual_object_ids":actual_ids.keys(),"scope":"GEOMETRY_CURRENT_FRAME_ONLY_NOT_ACTION_GAMEPLAY","water_domains_are_not_strong_alpha_credit":true,"camera_zoom":actual_scene.camera_zoom if actual_scene!=null else -1.,"player_visual_scale":actual_scene.player_visual_scale if actual_scene!=null else -1.,"raw_screenshots":((phase.get("records") as Dictionary).get("screenshots",[]) as Array).slice(first_screenshot)}
		probe=null
	screenshots=((phase.get("records") as Dictionary).get("screenshots",[]) as Array).duplicate(true)
	await _finish(ready)

func _finish(ready: Dictionary) -> void:
	var phase_checks: int=int(phase.get("checks")) if phase!=null else 0
	var phase_failed: int=int(phase.get("failures")) if phase!=null else 0
	var actual_field: bool=bool(phase.get("runtime_started")) if phase!=null else false
	var field_ref: WeakRef=weakref(current_scene) if is_instance_valid(current_scene) else null
	if phase!=null:
		await phase.call("natural_field_grace","before_wall_v4_geometry_release")
		phase_checks=int(phase.get("checks"))
		phase_failed=int(phase.get("failures"))
		phase.call("_release_field_oracles")
		var driver: RefCounted=phase.get("driver") as RefCounted
		if driver!=null: driver.call("release")
		driver=null
		phase.set("driver",null)
		phase.set("field",null)
		phase.set("tree",null)
		phase=null
	if is_instance_valid(current_scene):
		var owned: Node=current_scene
		current_scene=null
		owned.queue_free()
	for stage in 8: await process_frame
	_check(field_ref==null or field_ref.get_ref()==null,"owned normal Field naturally released; no forced runtime refresh")
	# No battle runs here, but let normal autoload audio naturally finish/fade.
	var cleanup_started: int=Time.get_ticks_usec()
	var natural_frames: int=0
	while Time.get_ticks_usec()-cleanup_started<9000000:
		await process_frame
		natural_frames+=1
	var audio: Node=root.get_node_or_null("AudioManager")
	if audio!=null: audio.call("stop_bgm",.15)
	var drain_started: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-drain_started<250000: await process_frame
	# Release the DisplayServer's custom-cursor handles after normal Field/audio
	# assertions. Do not modify CursorManager fields or hide stderr warnings.
	for cursor_shape: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]:
		Input.set_custom_mouse_cursor(null,cursor_shape)
	for cursor_stage in 4: await process_frame
	var after_files: Dictionary=_normal_files()
	var after_slot: Variant=root.get_node("SaveManager").get("active_slot")
	_check(before_files==after_files and before_slot==after_slot,"all15 normal player paths/size/SHA/mtime and active slot unchanged")
	var source_after: Dictionary=_source_snapshot(ready)
	_check(source_before==source_after,"all current wall_v4 source/catalog/semantic bytes unchanged through LIMITED trials")
	_check(trials.size()==4,"all four actual current city route/object geometry scopes executed")
	for id: String in CITY_IDS: _check(trials.has(id),"actual region trial record exists: "+id)
	checks+=phase_checks
	failed+=phase_failed
	var report: Dictionary={"schema":1,"scope":"LIMITED_WALL_V4_FOUR_CITY_NORMAL_CAMERA_GEOMETRY_NOT_FULL","checks":checks+1,"failed":failed,"failures":failed,"field_executed":actual_field,"dry_run":false,"full_complete":false,"source_complete":false,"GPU_executed":DisplayServer.get_name()!="headless" and not screenshots.is_empty(),"raw_screenshots":screenshots,"visual_approved":false,"engine_pid":OS.get_process_id(),"executing_script_path":get_script().resource_path,"executing_script_sha256":FileAccess.get_sha256(get_script().resource_path),"source_sha256_before":source_before,"source_sha256_after":source_after,"normal_files_before":before_files,"normal_files_after":after_files,"player_saves_unchanged":before_files==after_files,"active_slot_before":before_slot,"active_slot_after":after_slot,"exact_UTCticks":"ROOT_EXTERNAL_FRESH_BEFORE_AFTER_REQUIRED","navigation_before":navigation_before,"navigation_after":root.get_node("SceneRouter").call("get_navigation_state"),"navigation_cleanup":"NOT_RESTORED; owned process fixture only, no unpublished world15 restore attempted","preflight":preflight,"frozen_manifest_sha256":MANIFEST_SHA,"frozen_execution_sha256":SOURCE_SHA,"natural_cleanup":{"grace_usec":Time.get_ticks_usec()-cleanup_started,"natural_process_frames":natural_frames,"public_audio_fade_seconds":.15,"natural_audio_drain_usec":Time.get_ticks_usec()-drain_started,"timer_cancelled":false},"trials":trials,"output":output,"not_run":["FULL","15NPC_11INTERACTIONS_12PORTALS_GAMEPLAY","QUEST_REWARDS_SHOP_BOUNTY","MIGRATION_SAVE_LOAD","WORLD15","FULL_ANIMATION_WEAPON_ALPHA_DOMAIN","GPU_VISUAL_APPROVAL"],"stderr_acceptance":"ROOT_WRAPPER_MUST_READ_ACTUAL_VERBOSE_WARNINGS_ERRORS_AND_OS_EXIT"}
	_check(_write("result.json",report),"four-city LIMITED geometry result saved with checked readback")
	print("CITY_WALL_V4_GEOMETRY_LIMITED: %d checks / %d failures; LIMITED_WALL_V4_FOUR_CITY_NORMAL_CAMERA_GEOMETRY_NOT_FULL; output=%s"%[checks,failed,output])
	quit(0 if failed==0 else 1)
