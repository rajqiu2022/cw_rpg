extends SceneTree
## NEW lifecycle LIMITED sibling. Preserves all actual original gameplay predicates.
## No unpublished world15 restore, no FULL credit, no dry action or fake reward.
const PHASE_PATH: String="res://tests/helpers/joint_v15_city_prepared_phase.gd"
const OWN_PHASE_PATH: String="res://tests/helpers/joint_v15_city_gameplay_lifecycle_grace_phase.gd"
const OWN_PHASE_SHA: String="a6375e5a5721f58eeee2f934b3cc8b0cfe24512fdaa636447c4add730868e160"
const BGM_OBSERVER_PATH: String="res://tests/helpers/joint_v15_looped_bgm_continuity.gd"
const BGM_OBSERVER_SHA: String="28252849ab92aee8e687bf4372d24c7f369b6c13fc51180510a1b3e00d6563a3"
const PHYSICAL_PATH: String="res://tests/helpers/joint_v15_city_physical_alpha_probe.gd"
const INPUT_PATH: String="res://tests/helpers/v15_input_driver.gd"
const ORACLE_PATH: String="res://tests/helpers/joint_v15_source_context_oracle.gd"
const READY_PATH: String="res://build/joint_world_luoyang_20261003_qa/source_ready_23_city_lifecycle_limited_20261004.json"
const READY_SHA: String="0447d8ff40c2a1608040bbf62d559831b3ba3c8689adf2b44f86f71008bc5e33"
const INPUTS_PATH: String="res://build/joint_world_luoyang_20261003_qa/frozen_city_inputs_grey_limited_20261004.json"
const INPUTS_SHA: String="2f315e5bdc112c2f16480d8113df048a69fcd9c77dd1439ea5b526cdad0ce9fd"
const SUBJECT_PATH: String="res://scripts/city/luoyang_layered_v3_contract.gd"
const NEGATIVES_PATH: String="res://tests/helpers/joint_v15_city_interaction_negative_probe.gd"
const WORLD_EXCLUSIONS: Array[String]=["ch4_s0_luoyang_gate/return_world","ch4_s2_canal_docks/canal_world_ferry"]
const CITY_IDS: Array[String]=["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
const RUNTIME_PATHS: Array[String]=[
	"res://scripts/autoload/cursor_manager.gd",
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
var cursor_cleanup: Dictionary={}
var expected: Dictionary={"npcs":[],"interactions":[],"portals":[]}
var action_records: Dictionary={}
var omitted: Array[Dictionary]=[]
var negative_result: Dictionary={}
var source_subject: Script
var baseline_navigation: Dictionary={}
var water_summaries: Array=[]
var natural_grace_evidence: Array=[]

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:
		failed+=1
		push_error("[JOINT CITY LIMITED GAMEPLAY FAIL] "+label)
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

func _source_snapshot(ready: Dictionary) -> Dictionary:
	var paths: Dictionary={}
	for entry: Dictionary in ready.get("sources",[]): paths[String(entry.path)]=true
	for path: String in RUNTIME_PATHS: paths[path]=true
	for path: String in [INPUT_PATH,ORACLE_PATH,SUBJECT_PATH,NEGATIVES_PATH,OWN_PHASE_PATH,BGM_OBSERVER_PATH,get_script().resource_path,READY_PATH,INPUTS_PATH]: paths[path]=true
	var inputs: Dictionary={}
	if FileAccess.file_exists(INPUTS_PATH):
		var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(INPUTS_PATH))
		if parsed is Dictionary: inputs=parsed as Dictionary
	if not inputs.is_empty():
		for path: String in inputs.get("artifact_sha256",{}):
			paths[path]=true
			if FileAccess.file_exists(path):
				var manifest_value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
				if manifest_value is Dictionary:
					for asset: String in (manifest_value as Dictionary).get("asset_sha256",{}): paths[asset]=true
	# Bind gameplay resources and ordinary executing code, not mutable unrelated
	# world/outskirts ART WIP. No resource contents or player files are changed.
	_collect_sources("res://data",["tres"],paths)
	for directory: String in ["res://scripts/autoload","res://scripts/battle","res://scripts/ui","res://scripts/field","res://scripts/city"]:
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

func _run() -> void:
	before_files=_normal_files()
	before_slot=root.get_node("SaveManager").get("active_slot")
	navigation_before=root.get_node("SceneRouter").call("get_navigation_state")
	output="res://build/joint_world_luoyang_20261003_qa/city_gameplay_lifecycle_limited_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(output)==OK,"unique LIMITED actual city gameplay evidence directory")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	_check("--joint-city-gameplay-limited" in args and "--luoyang-v3-candidate" in args,"explicit LIMITED city gameplay + candidate flags required")
	for argument: String in args: _check(argument in ["--joint-city-gameplay-limited","--luoyang-v3-candidate","--qa-gpu-approved"],"no undeclared argument or world15 bypass: "+argument)
	_check(DisplayServer.get_name()=="headless" or "--qa-gpu-approved" in args,"GPU gameplay requires explicit root authorization; no automatic visual verdict")
	_check(FileAccess.get_sha256("res://scripts/field/field_walkable_controller.gd").to_lower()=="b3301d6064e332e519b0fc3b4daed880ec3d77d98f2c744933b5d7077b9eb8ef","root-approved live-Viewport/exact-interaction boundary Field source")
	_check(FileAccess.get_sha256(READY_PATH).to_lower()==READY_SHA,"root-reviewed exact23 readiness record")
	_check(INPUTS_SHA.length()==64 and FileAccess.file_exists(INPUTS_PATH) and FileAccess.get_sha256(INPUTS_PATH).to_lower()==INPUTS_SHA,"next exact root-reviewed four-city input pins required; historical041/070 is not final and PENDING fails closed")
	var ready: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(READY_PATH)) as Dictionary
	_check(ready.get("source_count")==23 and (ready.get("sources",[]) as Array).size()==23,"all23 exact current sources; limited runner is additional evidence only")
	for entry: Dictionary in ready.get("sources",[]):
		_check(FileAccess.get_sha256(String(entry.path)).to_lower()==String(entry.sha256),"frozen source unchanged: "+String(entry.path))
	_check(FileAccess.get_sha256(PHASE_PATH).to_lower()=="c23634d6adc149d1c54fc77bf1435a8bcfa5a95428c7a09802cd2df51932a791","current exact parent retains normal gameplay and binds actual loop-observer")
	_check(OWN_PHASE_SHA.length()==64 and FileAccess.get_sha256(OWN_PHASE_PATH).to_lower()==OWN_PHASE_SHA,"exact NEW limited own natural-grace adapter; all23 parents remain frozen")
	_check(FileAccess.get_sha256(PHYSICAL_PATH).to_lower()=="a1117d997b5451f36760ded94c09e240e0aaa58a151ce83f15b8c9e2568b52c8","current physical alpha pre-input lifecycle plus unchanged875/17/Physics/solid stop predicates")
	_check(FileAccess.get_sha256(INPUT_PATH).to_lower()=="a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7","normal non-forced input driver unchanged")
	_check(FileAccess.get_sha256(BGM_OBSERVER_PATH).to_lower()==BGM_OBSERVER_SHA,"exact bounded real event/identity/modulo audio observer closure")
	var extra: Variant=ready.get("additional_explicit_dependencies")
	_check(extra is Array and extra.size()==2,"exact additional adapter and BGM dependencies, not counted as23 legacy sources")
	var extra_seen: Dictionary={}
	if extra is Array:
		for dependency: Variant in extra:
			if not _check(dependency is Dictionary,"typed additional dependency"): continue
			var dependency_path: String=String(dependency.get("path",""))
			var dependency_sha: String=String(dependency.get("sha256",""))
			var approved_sha: String=OWN_PHASE_SHA if dependency_path==OWN_PHASE_PATH else BGM_OBSERVER_SHA if dependency_path==BGM_OBSERVER_PATH else ""
			_check(not approved_sha.is_empty() and dependency_sha==approved_sha and not extra_seen.has(dependency_path) and FileAccess.get_sha256(dependency_path).to_lower()==dependency_sha,"exact approved additional executing dependency: "+dependency_path)
			extra_seen[dependency_path]=true
	_check(extra_seen.size()==2 and extra_seen.has(OWN_PHASE_PATH) and extra_seen.has(BGM_OBSERVER_PATH),"both current supplementary closure identities present")
	source_before=_source_snapshot(ready)
	_check(not source_before.values().has("MISSING"),"all declared real sources present")
	if failed>0: await _finish(ready); return
	var oracle_script: GDScript=load(ORACLE_PATH) as GDScript
	if not _check(oracle_script!=null and oracle_script.can_instantiate(),"independent source preflight in registered autoload context"): await _finish(ready); return
	var oracle: RefCounted=oracle_script.new() as RefCounted
	preflight=oracle.call("run",INPUTS_PATH,"city")
	checks+=int(preflight.get("checks",0))
	failed+=int(preflight.get("failures",1))
	_check(_write("four_city_source_preflight.json",preflight),"real NEXT_ROOT_FROZEN four-city source preflight persisted, NOT Field/visual proof")
	oracle=null
	oracle_script=null
	if failed>0: await _finish(ready); return
	var script: GDScript=load(OWN_PHASE_PATH) as GDScript
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
	var subject_script: Script=load(SUBJECT_PATH) as Script
	if not _check(subject_script!=null and subject_script.can_instantiate(),"normal immutable city source subject loads in registered autoload context"): await _finish(ready); return
	source_subject=subject_script
	subject_script=null
	for id: String in CITY_IDS:
		var legacy: Resource=source_subject.call("legacy_scene",StringName(id)) as Resource
		if not _check(legacy!=null,"exact immutable original city identities exist: "+id): continue
		for entry: Dictionary in legacy.get("npcs"): expected.npcs.append(id+"/"+String(entry.npc_id))
		var layout: Resource=legacy.get("map_layout") as Resource
		for entry: Dictionary in layout.get("interactions"): expected.interactions.append(id+"/"+String(entry.id))
		for entry: Dictionary in layout.get("portals"):
			var key: String=id+"/"+String(entry.id)
			var world_exit: bool=String(entry.get("action",""))=="world_map" or String(entry.get("target_scene","")) in ["world_map_jianghu","world_map_jianghu_v15","world_map_jianghu_staging"]
			if key in WORLD_EXCLUSIONS:
				_check(world_exit,"excluded portal really is an original world exit, not a convenient ordinary omission: "+key)
				omitted.append({"region_id":id,"portal_id":String(entry.id),"original_action":entry.get("action",""),"original_target":entry.get("target_scene",""),"status":"NOT_RUN_DEPENDS_ON_UNPUBLISHED_WORLD15"})
			else:
				_check(not world_exit,"no unexpected world portal routed under limited local credit: "+key)
				if not world_exit: expected.portals.append(key)
	_check(expected.npcs.size()==15 and expected.interactions.size()==11 and expected.portals.size()==10 and omitted.size()==2,"exact15 NPC/11 action/10 nonworld portal identities plus exactly2 deferred world exits")
	if failed>0: await _finish(ready); return
	phase.set("expected",expected.duplicate(true))
	phase.call("_public_fixture",{})
	# Same public normal new-game local navigation initialization. No world15
	# restore and no pretend publication; world version stays the formal baseline.
	root.get_node("SceneRouter").call("reset_for_new_game")
	baseline_navigation=root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
	phase.call("_connect_events")
	for id: String in CITY_IDS:
		var legacy: Resource=source_subject.call("legacy_scene",StringName(id)) as Resource
		if legacy==null: _check(false,"immutable city source disappeared: "+id); continue
		for entry: Dictionary in legacy.get("npcs"):
			for mode: String in ["space","mouse"]: await phase.call("_normal_action_case",id,"npcs",entry,mode)
		var layout: Resource=legacy.get("map_layout") as Resource
		for entry: Dictionary in layout.get("interactions"):
			for mode: String in ["space","mouse"]: await phase.call("_normal_action_case",id,"interactions",entry,mode)
		for entry: Dictionary in layout.get("portals"):
			if not expected.portals.has(id+"/"+String(entry.id)): continue
			for mode: String in ["space","mouse"]: await phase.call("_normal_portal_case",id,entry,mode)
	# Existing ordinary bounty flow publicly travels only to original inland
	# neighboring scenes. Any real routing failure stays FAIL, never fake return.
	await phase.call("_normal_bounty_rewards")
	var negative_script: GDScript=load(NEGATIVES_PATH) as GDScript
	if _check(negative_script!=null and negative_script.can_instantiate(),"frozen11x5 actual input negative helper compiles"):
		var negative: RefCounted=negative_script.new() as RefCounted
		negative_result=await negative.call("run",phase)
		negative=null
	negative_script=null
	_check(bool(negative_result.get("complete",false)),"all55 actual original interaction negatives complete in this process")
	phase.call("_finalize_water_proofs")
	water_summaries=(phase.get("water_summaries") as Array).duplicate(true)
	action_records=(phase.get("records") as Dictionary).duplicate(true)
	_check(_write("actual_city_normal_gameplay.json",action_records),"all actual normal action/effect/event/return evidence checked readback")
	_check(_write("actual_city_interaction_negatives.json",negative_result),"actual55 input negative evidence checked readback")
	for kind: String in expected:
		var seen: Dictionary={}
		for row: Dictionary in action_records.get(kind,[]):
			var key: String=String(row.source_scene_id)+"/"+String(row.source_id)
			var mode: String=String(row.mode)
			_check(key in expected[kind] and mode in ["space","mouse"] and not seen.has(key+"|"+mode),"each actual original input case is unique and in limited declared set: "+key+"|"+mode)
			seen[key+"|"+mode]=true
			_check(row.get("dry_run")==false,"normal real gameplay not dry inspection: "+key)
		_check(seen.size()==expected[kind].size()*2,"both genuine input modes recorded for all original "+kind)
		for key: String in expected[kind]:
			for mode: String in ["space","mouse"]: _check(seen.has(key+"|"+mode),"actual input case exists: "+key+"|"+mode)
	_check((action_records.get("bounties",[]) as Array).size()==2,"both real accepted neighboring bounty battles/rewards recorded; failure is not waived")
	await _finish(ready)

func _release_owned_exit_cursors() -> Dictionary:
	# Only the exiting QA process, after all real input/screenshots/state checks.
	# Never modifies production source or another user's live process.
	var manager: Node=root.get_node_or_null("CursorManager")
	var fields: Array[String]=["_arrow","_hand","_wait"]
	var refs: Array[WeakRef]=[]
	var before: Array[Dictionary]=[]
	_check(manager!=null,"own exiting process has the normal CursorManager")
	if manager==null: return {"complete":false,"reason":"missing_normal_cursor_manager"}
	for name: String in fields:
		var present: bool=is_instance_valid(manager.get(name))
		refs.append(weakref(manager.get(name)) if present else null)
		before.append({"field":name,"present":present,"instance_id":manager.get(name).get_instance_id() if present else 0,"path":manager.get(name).resource_path if present else ""})
		_check(present,"actual normal cursor texture exists before own exit release: "+name)
	for shape: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for name: String in fields: manager.set(name,null)
	for stage in 8: await process_frame
	var after: Array[Dictionary]=[]
	var complete: bool=true
	for index in fields.size():
		var dead: bool=refs[index]==null or refs[index].get_ref()==null
		var cleared: bool=manager.get(fields[index])==null
		complete=complete and dead and cleared
		after.append({"field":fields[index],"texture_field_null":cleared,"weakref_dead":dead})
		_check(dead and cleared,"custom cursor DisplayServer + manager reference naturally released before own quit: "+fields[index])
	return {"complete":complete,"normal_input_already_finished":true,"production_source_unchanged":true,"cleared_shapes":["CURSOR_ARROW","CURSOR_POINTING_HAND","CURSOR_WAIT"],"natural_process_frames":8,"before":before,"after":after,"historical_ROOT070_3RID_12280bytes_and_6Timer_errors_not_erased":true,"stderr_real_result_required":true}

func _finish(ready: Dictionary) -> void:
	if phase!=null:
		await phase.call("natural_field_grace","before_owned_finish_field_release")
		natural_grace_evidence=(phase.get("natural_grace_records") as Array).duplicate(true)
		_check(_write("own_natural_toast_grace.json",{"scope":"OWN_LIMITED_GAMEPLAY_LIFECYCLE_NOT_TIMER_CAUSE_PROOF","adapter_path":OWN_PHASE_PATH,"adapter_sha256":FileAccess.get_sha256(OWN_PHASE_PATH),"frozen_parent_path":PHASE_PATH,"frozen_parent_sha256":FileAccess.get_sha256(PHASE_PATH),"records":natural_grace_evidence,"production_timer_changed":false,"timer_created_by_grace":false,"historical_ROOT087_timer_warnings_preserved":true}),"own natural live-stage grace evidence persisted with exact parsed readback")
	var phase_checks: int=int(phase.get("checks")) if phase!=null else 0
	var phase_failed: int=int(phase.get("failures")) if phase!=null else 0
	var actual_field: bool=bool(phase.get("runtime_started")) if phase!=null else false
	var field_ref: WeakRef=weakref(current_scene) if is_instance_valid(current_scene) else null
	var phase_ref: WeakRef=weakref(phase) if phase!=null else null
	if phase!=null:
		if action_records.is_empty(): action_records=(phase.get("records") as Dictionary).duplicate(true)
		screenshots=((phase.get("records") as Dictionary).get("screenshots",[]) as Array).duplicate(true)
		var bus: Node=root.get_node("EventBus")
		for entry: Dictionary in phase.get("event_connections"):
			if bus.is_connected(entry.signal,entry.callable): bus.disconnect(entry.signal,entry.callable)
		(phase.get("event_connections") as Array).clear()
		phase.call("_release_field_oracles")
		var driver: RefCounted=phase.get("driver") as RefCounted
		if driver!=null: driver.call("release")
		driver=null
		phase.set("driver",null)
		phase.set("field",null)
		phase.set("tree",null)
		phase=null
	source_subject=null
	if is_instance_valid(current_scene):
		var owned: Node=current_scene
		current_scene=null
		owned.queue_free()
	for stage in 8: await process_frame
	_check(field_ref==null or field_ref.get_ref()==null,"owned normal Field naturally released")
	_check(phase_ref==null or phase_ref.get_ref()==null,"owned phase/events/oracle callbacks naturally released")
	cursor_cleanup=await _release_owned_exit_cursors()
	# Cleanup never restores global flags/inventory/quest state over real effects.
	# No migration fixture slots were created by this limited wrapper.
	var after_files: Dictionary=_normal_files()
	var after_slot: Variant=root.get_node("SaveManager").get("active_slot")
	_check(before_files==after_files and before_slot==after_slot,"all15 actual normal paths/size/SHA/mtime and active slot unchanged after all gameplay and cleanup")
	var source_after: Dictionary=_source_snapshot(ready)
	_check(source_before==source_after,"all23 frozen QA/current city/art/ordinary gameplay bytes unchanged through actual LIMITED gameplay")
	checks+=phase_checks
	failed+=phase_failed
	var report: Dictionary={"schema":1,"scope":"LIMITED_CITY_NORMAL_GAMEPLAY_INPUT_NOT_JOINT_FULL","checks":checks+1,"failed":failed,"failures":failed,"field_executed":actual_field,"dry_run":false,"full_complete":false,"source_complete":false,"candidate_before_cutover":true,"mode":"headless" if DisplayServer.get_name()=="headless" else "gpu","GPU_executed":DisplayServer.get_name()!="headless" and not screenshots.is_empty(),"raw_screenshots":screenshots,"visual_approved":false,"engine_pid":OS.get_process_id(),"executing_script_path":get_script().resource_path,"executing_script_sha256":FileAccess.get_sha256(get_script().resource_path),"source_sha256_before":source_before,"source_sha256_after":source_after,"normal_files_before":before_files,"normal_files_after":after_files,"player_saves_unchanged":before_files==after_files,"active_slot_before":before_slot,"active_slot_after":after_slot,"exact_UTCticks":"ROOT_EXTERNAL_FRESH_BEFORE_AFTER_REQUIRED","navigation_before":navigation_before,"public_newgame_local_navigation_baseline":baseline_navigation,"navigation_after":root.get_node("SceneRouter").call("get_navigation_state"),"navigation_cleanup":"NOT_RESTORED; no unpublished world15 restore and no flags/inventory/reward hiding","preflight":preflight,"cursor_exit_cleanup":cursor_cleanup,"expected_exact_ids":expected,"actual_gameplay_records":action_records,"interaction_negatives":negative_result,"water_decoration_source_family_summaries":water_summaries,"deferred_world_portals":omitted,"isolated_migration_slots":{"created":false,"loaded":false,"case_count":0,"status":"NOT_RUN_DEPENDS_ON_UNPUBLISHED_WORLD15; normal primary/bak/tmp15paths protected before/after"},"output":output,"not_run":["JOINT_FULL","2WORLD_CITY_EXIT_INPUT_RETURNS","80ACTUAL_LOCAL1_LOCAL3_MIGRATION_CASES_DEPEND_ON_UNPUBLISHED_WORLD15","WORLD15_FULL","OUTSKIRTS","ALL_OBJECT_ROUTE_GEOMETRY_NOT_REEXECUTED_THIS_SCOPE","FULL_ANIMATION_WEAPON_ALPHA_DOMAIN","GPU_VISUAL_APPROVAL"],"stderr_acceptance":"ROOT_WRAPPER_MUST_READ_ACTUAL_VERBOSE_WARNINGS_ERRORS_AND_OS_EXIT"}
	report["own_natural_toast_grace"]=natural_grace_evidence
	report["lifecycle_revision"]="ROOT118_FAILURES_RETAINED_NEW_INPUT_ALPHA_VIEWPORT_AND_LOOP_OBSERVER"
	report["additional_executing_dependencies"]=[{"path":OWN_PHASE_PATH,"sha256":OWN_PHASE_SHA},{"path":BGM_OBSERVER_PATH,"sha256":BGM_OBSERVER_SHA}]
	_check(_write("result.json",report),"limited normal city gameplay result persisted with checked readback")
	print("JOINT_CITY_GAMEPLAY_LIMITED: %d checks / %d failures; LIMITED_CITY_NORMAL_GAMEPLAY_INPUT_NOT_JOINT_FULL; output=%s"%[checks,failed,output])
	quit(0 if failed==0 else 1)
