extends SceneTree
## NEW ROOT194 normal-dialog asynchronous battle lifecycle diagnostic, not FULL.
## Complete D78B/FDB0 normal action/input/effect/end predicates are retained.
## Only lifecycle phase binding, provenance and unique evidence differ.
const BATTLE_ACTIONS_ORIGIN_PATH: String="res://tests/test_joint_v15_city_wall_v5_two_authored_choices_limited_20261004.gd"
const BATTLE_ACTIONS_ORIGIN_SHA: String="d78b7e54727473da102982faf5b5f93b0977bd7655ea48792c78866aeadaaf9d"
## Exact original limited-wrapper predicates are retained; current city helper
## original normal action helpers only. Never call phase.run(), world restore,
## migration, publisher, reward/action shortcuts, or write normal player saves.
const TWO_ACTIONS_ORIGIN_PATH: String="res://tests/test_joint_v15_city_wall_v5_authored_choices_limited_20261004.gd"
const TWO_ACTIONS_ORIGIN_SHA: String="fdb0e7550a5dd26a7cd6901647294772b98def4ec450600caa9d11eaca2a7932"
const CLOSURE_ORIGIN_PATH: String="res://tests/test_joint_v15_city_wall_v5_visual_water_ui_limited_retry1_20261004.gd"
const CLOSURE_ORIGIN_SHA: String="a8c0166f3e8c12686b8232a45858add55137bc9563d950421bffb58a82c5a443"
const CITY_SCENE_FORMAT_TEMPLATE: String="res://data/scenes/%s.tres"
const LIMITED_GEOMETRY_ORIGIN_PATH: String="res://tests/test_joint_v15_city_wall_v5_fine_geometry_limited_20261004.gd"
const LIMITED_GEOMETRY_ORIGIN_SHA: String="d52ccdd5aea041c65863046a40b27b9dd865fee4fdecafbed659fb043bec49bc"
const ORIGIN_PATH: String="res://tests/test_joint_v15_city_geometry_limited_20261004.gd"
const ORIGIN_SHA: String="7d9871b510f172fadd6ac4e41e3e748711cfe838ea2936c640fa6c5a9f631ded"
const ACTIONS_ORIGIN_PATH: String="res://tests/test_joint_v15_city_wall_v5_actions_limited_20261004.gd"
const ACTIONS_ORIGIN_SHA: String="ca933a4cd34813c0012c221feed21e138e2404614aa2c3fecb57c8f6ef4397a1"
const PHASE_PATH: String="res://tests/helpers/joint_v15_v8_city_authored_battle_lifecycle_phase.gd"
const PREPARED_PATH: String="res://tests/helpers/joint_v15_v8_city_prepared_phase.gd"
const PHYSICAL_PATH: String="res://tests/helpers/joint_v15_wall_v5_fine_alpha_probe.gd"
const RAW_PATH: String="res://tests/helpers/joint_v15_wall_v5_ordinary_raw_oracle.gd"
const INPUT_PATH: String="res://tests/helpers/v15_input_driver.gd"
const SUBJECT_PATH: String="res://scripts/city/luoyang_layered_v3_wall_v5_candidate_contract.gd"
const ART_ROOT: String="res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/"
const CITY_IDS: Array[String]=["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
const MANIFEST_SHA: Dictionary={
	"ch4_s0_luoyang_gate":"2818f9fca10d30abbbbd386ff2b26a3d4ed87f300a9b8ef47f882bcb83f7640d",
	"ch4_s1_luoyang_yamen":"b7bfdd920ba69858b70c9cf77c5d3b65161f14032ae3eb0e1f5f5f0b04385315",
	"ch4_s2_canal_docks":"5ac079c73a9ab7716c62d7ba540d39a513be93ed17f5feef0effbd2e1ac26cdb",
	"ch4_s3_luoyang_market":"260a526e6232e4600c91653033c3a5f398c30a6c4f4bff882143124ffc945fc7"
}
const SOURCE_SHA: Dictionary={
	BATTLE_ACTIONS_ORIGIN_PATH:BATTLE_ACTIONS_ORIGIN_SHA,
	"res://tests/helpers/joint_v15_v8_city_authored_two_choice_phase.gd":"97a8d255a7148074ff5a2fbb334a675c92697b992b12565b0d14fb52d859b126",
	"res://tests/helpers/joint_v15_existing_battle_ui_probe.gd":"6ac3b45a23f75f528710677c591a8e51725d2fe57c0d4e8b1de3c8ef552c8ff7",
	TWO_ACTIONS_ORIGIN_PATH:TWO_ACTIONS_ORIGIN_SHA,
	CLOSURE_ORIGIN_PATH:CLOSURE_ORIGIN_SHA,
	"res://tests/helpers/joint_v15_v8_city_authored_choice_phase.gd":"6ac90705b6c40866f307af188a7382f70fed0a4d1d08d2cf5ac607306b40ef79",
	"res://data/dialogs/ch4_guyun_sword_notches.tres":"1fc1354cbc1b8df3d3f5375760e1e5fe77041c2efbc1fa987d75070324433f02",
	ACTIONS_ORIGIN_PATH:ACTIONS_ORIGIN_SHA,
	"res://tests/helpers/joint_v15_v8_city_gameplay_lifecycle_grace_phase.gd":"a5877e5940262baa74737d9e28ba06d5367a1b5823f51896a52068ee98077e2a",
	"res://data/dialogs/huilan_openworld_water_rule.tres":"e6bb99f246af07f4d447881c05d1b0591aea9bd8be14426341d7e92a95e1acd5",
 LIMITED_GEOMETRY_ORIGIN_PATH:LIMITED_GEOMETRY_ORIGIN_SHA,
 "res://tests/test_joint_v15_city_wall_v4_fine_geometry_limited_20261004.gd":"6e94fc5bcb210c55ebd17be6af6706fef7d7036d2f418b446c6c25af05f15112",
 "res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd":"40b42c901ef05ac1971ccaae9ba049b60cfe439baea8778f796f978c4bd54450",
 "res://tests/helpers/joint_v15_wall_v5_city_migration_load_probe.gd":"53e4e69672b7ab3f35c580917e6c167d84274358c3b40d7700aa1cc522f9cded",
 "res://tests/helpers/joint_v15_looped_bgm_continuity.gd":"28252849ab92aee8e687bf4372d24c7f369b6c13fc51180510a1b3e00d6563a3",
 "res://tests/test_joint_v15_city_wall_v4_geometry_limited_20261004.gd":"a61cfacf62122cf755b967be4fde00055a886888b4dda7dbf688d6ad404b4f81",
 "res://tests/helpers/joint_v15_wall_street_city_gameplay_lifecycle_grace_phase.gd":"fdf51d2e5ab0ac3f35aa72214bc565e4c1addccb17fc19eb576695c0d0588bf8",
 "res://tests/helpers/joint_v15_wall_street_city_physical_alpha_probe.gd":"ca5f919320364b2e8346f057044a62a0dd0bfe99b49f2d029b7362d129bbd5f2",
	ORIGIN_PATH:ORIGIN_SHA,
	PHASE_PATH:"44687491cbe761ef92f97a20592a5cee21ffe4c385b94894095722fbe67583d5",
	PREPARED_PATH:"568a4a869e10afd857246c505e35ab72d0e6ddbe2678b1c67e96c0299fa04967",
	PHYSICAL_PATH:"8950ddbf02416cffa4e608d68938cbab2051ff3ebcd1afa7478614a1d2fa31dc",
	RAW_PATH:"46c3d80b804a2c2566d60563e500c2e84d9369a9ae80d246466a4b5c6a56b4a5",
	INPUT_PATH:"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	SUBJECT_PATH:"99d1a8b6f38e99ef1abb215fefdae54b29e874ec95aec716871b3a35744b110e",
	"res://scripts/city/luoyang_layered_v3_contract.gd":"9cab4325074ed3ee9c69507e455709c421520bfe5b3d7582edbcc035c2e5b0c4",
	"res://scripts/dev/luoyang_v3_wall_v5_saved_resource_checker.gd":"ad231d62314fb6a0d37683c223259f218a252db987f2c50a41277bd89de12a15",
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
var actual_phase_records: Dictionary={}
var dynamic_template_declarations: Array[Dictionary]=[]
var dynamic_template_declarations_before: Array[Dictionary]=[]

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:
		failed+=1
		push_error("[CITY WALL V5 GEOMETRY FAIL] "+label)
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
	# Explicit current city/gameplay closure. Do not enumerate res://data/scenes
	# or res://data/maps recursively: unrelated future world candidate additions
	# are not executed in this limited process and must not contaminate evidence.
	dynamic_template_declarations.clear()
	var resolved_city_scenes: Array[String]=[]
	for id: String in CITY_IDS: resolved_city_scenes.append("res://data/scenes/"+id+".tres")
	var paths: Dictionary={TWO_ACTIONS_ORIGIN_PATH:true,CLOSURE_ORIGIN_PATH:true,PHASE_PATH:true,get_script().resource_path:true,"res://project.godot":true,"res://scenes/field_walkable.tscn":true,"res://scenes/player.tscn":true,"res://scenes/npc_node.tscn":true}
	for path: String in SOURCE_SHA: paths[path]=true
	for path: String in RUNTIME_PATHS: paths[path]=true
	for id: String in CITY_IDS:
		for path: String in ["res://data/scenes/"+id+".tres","res://data/scenes/luoyang_v3_candidates/"+id+".tres","res://data/maps/"+id+"_layout_v3.tres","res://data/maps/luoyang_v3_legacy/"+id+"_scene.tres","res://data/maps/luoyang_v3_legacy/"+id+"_layout.tres",ART_ROOT+id+"/art_contract.json"]: paths[path]=true
		var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(ART_ROOT+id+"/art_contract.json"))
		if parsed is Dictionary:
			for path: String in parsed.get("asset_sha256",{}): paths[path]=true
			for path: String in parsed.get("source_graph",{}): paths[path]=true
	# Normal public fixtures and the exact authored dialogue use these real
	# gameplay catalogues. No candidate/world scene catalogue enumeration.
	for category: String in ["dialogs","quests","items","equipment","skills","shops","enemies"]:
		_collect_sources("res://data/"+category,["tres"],paths)
	_collect_sources("res://art/characters/weapon_variants/lengguyun/v7_idle_stable",["png"],paths)
	var queue: Array=[]
	queue.append_array(paths.keys())
	var seen: Dictionary={}
	var dependencies: RegEx=RegEx.new()
	dependencies.compile("(?:extends\\s+|(?:preload|load)\\(\\s*)[\"'](res://[^\"']+)[\"']")
	var resources: RegEx=RegEx.new()
	resources.compile("[\"'](res://[^\"']+)[\"']")
	var index: int=0
	while index<queue.size():
		var path: String=String(queue[index])
		index+=1
		if seen.has(path): continue
		seen[path]=true
		if not FileAccess.file_exists(path) or path.get_extension() not in ["gd","tres","tscn","godot"]: continue
		var source: String=FileAccess.get_file_as_string(path)
		var matcher: RegEx=dependencies if path.get_extension()=="gd" else resources
		for match: RegExMatch in matcher.search_all(source):
			var dependency: String=match.get_string(1)
			# Only this exact scene template followed by the actual format operator
			# is a declaration, not a physical filename. Concrete missing resources
			# and other templates still enter the strict MISSING check unchanged.
			if path.get_extension()=="gd" and dependency==CITY_SCENE_FORMAT_TEMPLATE and source.substr(match.get_end()).strip_edges().begins_with("%"):
				dynamic_template_declarations.append({"declaring_source_path":path,"declaring_source_sha256":FileAccess.get_sha256(path),"match_offset":match.get_start(),"template":dependency,"reason":"FORMAT_TEMPLATE_NOT_PHYSICAL_DEPENDENCY","resolution_scope":"LIMITED_CURRENT_CITY_INPUTS_ONLY_NOT_ALL_POSSIBLE_TEMPLATE_CALLS","resolved_required_paths":resolved_city_scenes.duplicate()})
				continue
			if dependency.get_extension() not in ["gd","tres","tscn","png","wav","ogg","gdshader","res"]: continue
			if not paths.has(dependency): paths[dependency]=true; queue.append(dependency)
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
	if not _check(subject_script!=null and subject_script.can_instantiate(),"current wall_v5 subject compiles in normal autoload context"): return
	preflight={"scope":"CURRENT_WALL_V5_STRICT_CAPTURE_SAVED_RESOURCE_BINDING_NOT_FIELD_APPROVAL","regions":{}}
	for id: String in CITY_IDS:
		var path: String=ART_ROOT+id+"/art_contract.json"
		if not _check(FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==MANIFEST_SHA[id],"exact producer-frozen current V5 city manifest (PENDING refuses): "+id): continue
		var accepted: bool=bool(subject_script.call("prepare",StringName(id)))
		var prepare_errors: Array=subject_script.call("errors")
		_check(accepted,"all current catalog/camera/body/support/18wall saved-resource checks remain mandatory: "+id)
		print("CITY_WALL_V5_PREPARE ",id," accepted=",accepted," errors=",JSON.stringify(prepare_errors))
		(preflight.regions as Dictionary)[id]={"manifest_path":path,"manifest_sha256":MANIFEST_SHA[id],"strict_city_prepare_accepted":accepted,"prepare_errors":prepare_errors}
	subject_script=null

func _run() -> void:
	before_files=_normal_files()
	before_slot=root.get_node("SaveManager").get("active_slot")
	navigation_before=root.get_node("SceneRouter").call("get_navigation_state")
	output="res://build/joint_world_luoyang_20261003_qa/city_wall_v5_authored_battle_lifecycle_limited_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(output)==OK,"unique four-city LIMITED NPC/action evidence directory")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	_check("--joint-city-wall-v5-authored-battle-lifecycle-limited" in args and "--luoyang-v3-candidate" in args,"explicit four-city normal actions + candidate flags required")
	for argument: String in args: _check(argument in ["--joint-city-wall-v5-authored-battle-lifecycle-limited","--luoyang-v3-candidate","--qa-gpu-approved"],"no undeclared argument or world15 bypass: "+argument)
	_check(DisplayServer.get_name()=="headless" or "--qa-gpu-approved" in args,"GPU normal actions require explicit root authorization; headless signs no visual verdict")
	_check(FileAccess.get_sha256(LIMITED_GEOMETRY_ORIGIN_PATH).to_lower()==LIMITED_GEOMETRY_ORIGIN_SHA,"unchanged successful geometry origin; this run never inherits its PASS")
	var ready: Dictionary={}
	for path: String in SOURCE_SHA:
		_check(FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==SOURCE_SHA[path],"exact frozen current execution source: "+path)
	source_before=_source_snapshot(ready)
	dynamic_template_declarations_before=dynamic_template_declarations.duplicate(true)
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
	phase.call("_connect_events")
	var subject: GDScript=load(SUBJECT_PATH) as GDScript
	for id: String in CITY_IDS:
		var original: SceneScript=subject.call("legacy_scene",StringName(id)) as SceneScript
		if not _check(original!=null,"exact immutable original city action identities: "+id): continue
		var start_records: Dictionary=(phase.get("records") as Dictionary).duplicate(true)
		var expected_actions: Dictionary={"npcs":[],"interactions":[]}
		for kind: String in ["npcs","interactions"]:
			var entries: Array=original.npcs if kind=="npcs" else original.map_layout.interactions
			for entry: Dictionary in entries:
				var source_id: String=String(entry.get("npc_id" if kind=="npcs" else "id",""))
				for mode: String in ["space","mouse"]:
					expected_actions[kind].append(source_id+"/"+mode)
					await phase.call("_normal_action_case",id,kind,entry,mode)
		var current_records: Dictionary=phase.get("records") as Dictionary
		var actual_actions: Dictionary={}
		for kind: String in ["npcs","interactions"]:
			var rows: Array=(current_records[kind] as Array).slice((start_records[kind] as Array).size())
			var seen: Dictionary={}
			for row: Dictionary in rows:
				var key: String=String(row.source_id)+"/"+String(row.mode)
				_check(row.source_scene_id==id and row.dry_run==false and key in expected_actions[kind] and not seen.has(key),"actual original identity and unique normal-input mode: "+id+"/"+key)
				seen[key]=true
			_check(rows.size()==(expected_actions[kind] as Array).size(),"all original action identities actually executed in both input modes: "+id+"/"+kind)
			for key: String in expected_actions[kind]: _check(seen.has(key),"normal action record present: "+id+"/"+kind+"/"+key)
			actual_actions[kind]=rows.duplicate(true)
		trials[id]={"manifest_sha256":FileAccess.get_sha256(ART_ROOT+id+"/art_contract.json"),"expected_actions":expected_actions,"actual_actions":actual_actions,"scope":"LIMITED_NORMAL_NPC_AND_INTERACTION_INPUT_NOT_PORTALS_OR_FULL"}
		subject=null if id==CITY_IDS.back() else subject
	screenshots=((phase.get("records") as Dictionary).get("screenshots",[]) as Array).duplicate(true)
	await _finish(ready)

func _finish(ready: Dictionary) -> void:
	var phase_checks: int=int(phase.get("checks")) if phase!=null else 0
	var phase_failed: int=int(phase.get("failures")) if phase!=null else 0
	var actual_field: bool=bool(phase.get("runtime_started")) if phase!=null else false
	var field_ref: WeakRef=weakref(current_scene) if is_instance_valid(current_scene) else null
	if phase!=null:
		var bus: Node=root.get_node("EventBus")
		for connection: Dictionary in phase.get("event_connections"):
			if bus.is_connected(connection.signal,connection.callable): bus.disconnect(connection.signal,connection.callable)
		(phase.get("event_connections") as Array).clear()
		await phase.call("natural_field_grace","before_wall_v5_actions_release")
		phase_checks=int(phase.get("checks"))
		phase_failed=int(phase.get("failures"))
		actual_phase_records=(phase.get("records") as Dictionary).duplicate(true)
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
	# Normal NPC spar/dialog battle may run above. Let existing victory sting
	# and normal autoload audio naturally finish/fade after all assertions.
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
	_check(source_before==source_after,"all current wall_v5 source/catalog/semantic bytes unchanged through LIMITED trials")
	_check(not dynamic_template_declarations_before.is_empty() and dynamic_template_declarations_before==dynamic_template_declarations,"ROOT190 exact formatted scene declaration evidence unchanged; concrete missing paths still refuse")
	_check(trials.size()==4,"all four actual current city NPC/action scopes executed")
	for id: String in CITY_IDS: _check(trials.has(id),"actual region trial record exists: "+id)
	checks+=phase_checks
	failed+=phase_failed
	var report: Dictionary={"geometry_routes_objects":"NOT_RUN_IN_THIS_PROCESS","NPC_ACTION_COUNTS_REQUIRED":{"npcs":30,"interactions":22},"schema":1,"scope":"LIMITED_WALL_V5_FOUR_CITY_AUTHORED_BATTLE_LIFECYCLE_NORMAL_NPC_ACTION_INPUT_NOT_FULL","checks":checks+1,"failed":failed,"failures":failed,"field_executed":actual_field,"dry_run":false,"full_complete":false,"source_complete":false,"GPU_executed":DisplayServer.get_name()!="headless" and not screenshots.is_empty(),"raw_screenshots":screenshots,"visual_approved":false,"engine_pid":OS.get_process_id(),"executing_script_path":get_script().resource_path,"executing_script_sha256":FileAccess.get_sha256(get_script().resource_path),"origin_battle_lifecycle_actions":{"path":BATTLE_ACTIONS_ORIGIN_PATH,"sha256":BATTLE_ACTIONS_ORIGIN_SHA},"origin_actions":{"path":TWO_ACTIONS_ORIGIN_PATH,"sha256":TWO_ACTIONS_ORIGIN_SHA},"origin_source_closure":{"path":CLOSURE_ORIGIN_PATH,"sha256":CLOSURE_ORIGIN_SHA},"dialog_records":actual_phase_records,"dynamic_template_declarations_before":dynamic_template_declarations_before,"dynamic_template_declarations_after":dynamic_template_declarations.duplicate(true),"source_sha256_before":source_before,"source_sha256_after":source_after,"normal_files_before":before_files,"normal_files_after":after_files,"player_saves_unchanged":before_files==after_files,"active_slot_before":before_slot,"active_slot_after":after_slot,"exact_UTCticks":"ROOT_EXTERNAL_FRESH_BEFORE_AFTER_REQUIRED","navigation_before":navigation_before,"navigation_after":root.get_node("SceneRouter").call("get_navigation_state"),"navigation_cleanup":"NOT_RESTORED; owned process fixture only, no unpublished world15 restore attempted","preflight":preflight,"frozen_manifest_sha256":MANIFEST_SHA,"frozen_execution_sha256":SOURCE_SHA,"natural_cleanup":{"grace_usec":Time.get_ticks_usec()-cleanup_started,"natural_process_frames":natural_frames,"public_audio_fade_seconds":.15,"natural_audio_drain_usec":Time.get_ticks_usec()-drain_started,"timer_cancelled":false},"trials":trials,"output":output,"not_run":["FULL","12PORTALS_GAMEPLAY","EXHAUSTIVE_QUEST_SHOP_AND_BOUNTY_PURSUIT_SETTLEMENT","MIGRATION_SAVE_LOAD","WORLD15","FULL_ANIMATION_WEAPON_ALPHA_DOMAIN","GPU_VISUAL_APPROVAL"],"stderr_acceptance":"ROOT_WRAPPER_MUST_READ_ACTUAL_VERBOSE_WARNINGS_ERRORS_AND_OS_EXIT"}
	_check(_write("result.json",report),"four-city LIMITED NPC/action result saved with checked readback")
	print("CITY_WALL_V5_AUTHORED_BATTLE_LIFECYCLE_LIMITED: %d checks / %d failures; LIMITED_WALL_V5_FOUR_CITY_AUTHORED_BATTLE_LIFECYCLE_NORMAL_NPC_ACTION_INPUT_NOT_FULL; output=%s"%[checks,failed,output])
	quit(0 if failed==0 else 1)

