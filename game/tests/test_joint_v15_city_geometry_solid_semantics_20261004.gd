extends SceneTree
## NEW solid-semantics revision: LIMITED geometry, frozen ROOT070 preserved.
## Next four-city manifest input is PENDING; source-ready is not run-ready.
## No FULL/gameplay/migration/world credit, no world15 restore or Player teleport.
const PHASE_PATH: String="res://tests/helpers/joint_v15_city_prepared_phase.gd"
const PHYSICAL_PATH: String="res://tests/helpers/joint_v15_city_physical_alpha_probe.gd"
const INPUT_PATH: String="res://tests/helpers/v15_input_driver.gd"
const ORACLE_PATH: String="res://tests/helpers/joint_v15_source_context_oracle.gd"
const READY_PATH: String="res://build/joint_world_luoyang_20261003_qa/source_ready_23_city_solid_semantics_revision_20261004.json"
const READY_SHA: String="210a2a8739bee52e23e790f7c504b36c62743feec96868c2a94e67096fd2520d"
const INPUTS_PATH: String="res://build/joint_world_luoyang_20261003_qa/frozen_city_inputs_next_geometry.json"
const INPUTS_SHA: String="3bfdc91eae8f24abda288a7aa761b9b28395926667af81648fd65220d56646fa"
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

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:
		failed+=1
		push_error("[JOINT CITY GEOMETRY FAIL] "+label)
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
	for path: String in [INPUT_PATH,ORACLE_PATH,get_script().resource_path,READY_PATH,INPUTS_PATH]: paths[path]=true
	var inputs: Dictionary={}
	if FileAccess.file_exists(INPUTS_PATH):
		var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(INPUTS_PATH))
		if parsed is Dictionary: inputs=parsed as Dictionary
	if not inputs.is_empty():
		for path: String in inputs.get("artifact_sha256",{}): paths[path]=true
	var result: Dictionary={}
	for path: String in paths: result[path]=FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "MISSING"
	return result

func _run() -> void:
	before_files=_normal_files()
	before_slot=root.get_node("SaveManager").get("active_slot")
	navigation_before=root.get_node("SceneRouter").call("get_navigation_state")
	output="res://build/joint_world_luoyang_20261003_qa/city_geometry_solid_semantics_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(output)==OK,"unique four-city LIMITED geometry evidence directory")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	_check("--joint-city-geometry-limited" in args and "--luoyang-v3-candidate" in args,"explicit four-city geometry + candidate flags required")
	for argument: String in args: _check(argument in ["--joint-city-geometry-limited","--luoyang-v3-candidate","--qa-gpu-approved"],"no undeclared argument or world15 bypass: "+argument)
	_check(DisplayServer.get_name()=="headless" or "--qa-gpu-approved" in args,"GPU geometry requires explicit root authorization; headless signs no visual verdict")
	_check(FileAccess.get_sha256("res://scripts/field/field_walkable_controller.gd").to_lower()=="552335aa5156518cd6ef095752df20984d1969098aae14d159a5ecd26d347661","ROOT069 exact approved City pulse-only highlight source")
	_check(FileAccess.get_sha256(READY_PATH).to_lower()==READY_SHA,"root-reviewed exact23 readiness record")
	_check(INPUTS_SHA.length()==64 and FileAccess.file_exists(INPUTS_PATH) and FileAccess.get_sha256(INPUTS_PATH).to_lower()==INPUTS_SHA,"next exact root-reviewed four-city input pins required; historical041/070 is not final and PENDING fails closed")
	var ready: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(READY_PATH)) as Dictionary
	_check(ready.get("source_count")==23 and (ready.get("sources",[]) as Array).size()==23,"all23 exact current sources; limited runner is additional evidence only")
	for entry: Dictionary in ready.get("sources",[]):
		_check(FileAccess.get_sha256(String(entry.path)).to_lower()==String(entry.sha256),"frozen source unchanged: "+String(entry.path))
	_check(FileAccess.get_sha256(PHASE_PATH).to_lower()=="855f5d71b9a490831ec374a6661c5c21a5cca6f5b4f6f96c53b84c43def62277","actual new stale-field stage guard")
	_check(FileAccess.get_sha256(PHYSICAL_PATH).to_lower()=="1c0d721e7f0279d12042b650a23802aebabf04fe9608312467e895194514140f","actual approved local own-solid stop, exact shore negatives/bidirectional land trial and unchanged alpha snapshots")
	_check(FileAccess.get_sha256(INPUT_PATH).to_lower()=="a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7","normal non-forced input driver unchanged")
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
		phase.call("_public_fixture",{})
		var opened: bool=await phase.call("_open",id)
		_check(opened,"normal go_field_smart creates actual current city candidate Field: "+id)
		if not opened: continue
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
		trials[id]={"manifest_sha256":FileAccess.get_sha256("res://art/maps/luoyang_modular_v3/"+id+"/art_contract.json"),"physical_and_current_alpha":evidence,"declared_route_count":(manifest.get("routes",[]) as Array).size(),"declared_object_count":(manifest.get("objects",[]) as Array).size(),"actual_object_ids":actual_ids.keys(),"scope":"GEOMETRY_CURRENT_FRAME_ONLY_NOT_ACTION_GAMEPLAY","water_domains_are_not_strong_alpha_credit":true}
		probe=null
	screenshots=((phase.get("records") as Dictionary).get("screenshots",[]) as Array).duplicate(true)
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
	var phase_checks: int=int(phase.get("checks")) if phase!=null else 0
	var phase_failed: int=int(phase.get("failures")) if phase!=null else 0
	var actual_field: bool=bool(phase.get("runtime_started")) if phase!=null else false
	var field_ref: WeakRef=weakref(current_scene) if is_instance_valid(current_scene) else null
	if phase!=null:
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
	cursor_cleanup=await _release_owned_exit_cursors()
	var after_files: Dictionary=_normal_files()
	var after_slot: Variant=root.get_node("SaveManager").get("active_slot")
	_check(before_files==after_files and before_slot==after_slot,"all15 normal player paths/size/SHA/mtime and active slot unchanged")
	var source_after: Dictionary=_source_snapshot(ready)
	_check(source_before==source_after,"all actual source and NEXT_ROOT_FROZEN manifest bytes unchanged through LIMITED trials")
	_check(trials.size()==4,"all four actual current city route/object geometry scopes executed")
	for id: String in CITY_IDS: _check(trials.has(id),"actual region trial record exists: "+id)
	checks+=phase_checks
	failed+=phase_failed
	var report: Dictionary={"schema":1,"scope":"LIMITED_FOUR_CITY_GEOMETRY_ACTUAL_FIELD_NOT_FULL","checks":checks+1,"failed":failed,"failures":failed,"field_executed":actual_field,"dry_run":false,"full_complete":false,"source_complete":false,"GPU_executed":DisplayServer.get_name()!="headless" and not screenshots.is_empty(),"raw_screenshots":screenshots,"visual_approved":false,"engine_pid":OS.get_process_id(),"executing_script_path":get_script().resource_path,"executing_script_sha256":FileAccess.get_sha256(get_script().resource_path),"source_sha256_before":source_before,"source_sha256_after":source_after,"normal_files_before":before_files,"normal_files_after":after_files,"player_saves_unchanged":before_files==after_files,"active_slot_before":before_slot,"active_slot_after":after_slot,"exact_UTCticks":"ROOT_EXTERNAL_FRESH_BEFORE_AFTER_REQUIRED","navigation_before":navigation_before,"navigation_after":root.get_node("SceneRouter").call("get_navigation_state"),"navigation_cleanup":"NOT_RESTORED; owned process fixture only, no unpublished world15 restore attempted","preflight":preflight,"cursor_exit_cleanup":cursor_cleanup,"trials":trials,"output":output,"not_run":["FULL","15NPC_11INTERACTIONS_12PORTALS_GAMEPLAY","QUEST_REWARDS_SHOP_BOUNTY","MIGRATION_SAVE_LOAD","WORLD15","FULL_ANIMATION_WEAPON_ALPHA_DOMAIN","GPU_VISUAL_APPROVAL"],"stderr_acceptance":"ROOT_WRAPPER_MUST_READ_ACTUAL_VERBOSE_WARNINGS_ERRORS_AND_OS_EXIT"}
	_check(_write("result.json",report),"four-city LIMITED geometry result saved with checked readback")
	print("JOINT_CITY_GEOMETRY_LIMITED: %d checks / %d failures; LIMITED_FOUR_CITY_GEOMETRY_ACTUAL_FIELD_NOT_FULL; output=%s"%[checks,failed,output])
	quit(0 if failed==0 else 1)
