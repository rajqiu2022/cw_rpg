extends SceneTree
## NEW LIMITED causal runner. Normal candidate Field/input only; no FULL credit,
## world15 restore/publication, Player teleport, forced overlap or result injection.
const PHASE_PATH: String="res://tests/helpers/joint_v15_city_prepared_phase.gd"
const PHYSICAL_PATH: String="res://tests/helpers/joint_v15_city_physical_alpha_probe.gd"
const INPUT_PATH: String="res://tests/helpers/v15_input_driver.gd"
const ORACLE_PATH: String="res://tests/helpers/joint_v15_source_context_oracle.gd"
const READY_PATH: String="res://build/joint_world_luoyang_20261003_qa/source_ready_23_city_instant_revision_20261004.json"
const READY_SHA: String="66334ce09e422a5f3196909b5bb39333f34431d8e5cdd982af358c14a8ddf062"
const INPUTS_PATH: String="res://build/joint_world_luoyang_20261003_qa/064_city_actual_limited_before_world/frozen_city_inputs_041.json"
const INPUTS_SHA: String="3aff228903876699aa310b090c5f136ff2360165a3ecd08acf2c6cd22f82dcef"
const GATE_ID: String="ch4_s0_luoyang_gate"
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

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:
		failed+=1
		push_error("[JOINT CITY CAUSAL FAIL] "+label)
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
	var inputs: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(INPUTS_PATH)) as Dictionary
	for path: String in inputs.get("artifact_sha256",{}): paths[path]=true
	var result: Dictionary={}
	for path: String in paths: result[path]=FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "MISSING"
	return result

func _run() -> void:
	before_files=_normal_files()
	before_slot=root.get_node("SaveManager").get("active_slot")
	navigation_before=root.get_node("SceneRouter").call("get_navigation_state")
	output="res://build/joint_world_luoyang_20261003_qa/city_alpha_causal_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(output)==OK,"unique LIMITED causal evidence directory")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	_check("--joint-city-alpha-causal-diagnosis" in args and "--luoyang-v3-candidate" in args,"explicit causal diagnosis + candidate flags required")
	for argument: String in args: _check(argument in ["--joint-city-alpha-causal-diagnosis","--luoyang-v3-candidate"],"no undeclared argument or world15 bypass: "+argument)
	_check(DisplayServer.get_name()=="headless","this authorized LIMITED diagnostic has no GPU scope")
	_check(FileAccess.get_sha256(READY_PATH).to_lower()==READY_SHA,"root-reviewed exact23 readiness record")
	_check(FileAccess.get_sha256(INPUTS_PATH).to_lower()==INPUTS_SHA,"exact ROOT041 four-city input pins, not newest self-selected manifests")
	var ready: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(READY_PATH)) as Dictionary
	_check(ready.get("source_count")==23 and (ready.get("sources",[]) as Array).size()==23,"all23 exact current sources; limited runner is additional evidence only")
	for entry: Dictionary in ready.get("sources",[]):
		_check(FileAccess.get_sha256(String(entry.path)).to_lower()==String(entry.sha256),"frozen source unchanged: "+String(entry.path))
	_check(FileAccess.get_sha256(PHASE_PATH).to_lower()=="855f5d71b9a490831ec374a6661c5c21a5cca6f5b4f6f96c53b84c43def62277","actual new stale-field stage guard")
	_check(FileAccess.get_sha256(PHYSICAL_PATH).to_lower()=="6a4e1b63012857f6a65a89add5f7e6b39676ec34a41f1cd1d40822fe1fe4ab87","actual new legal-union trials and first/second snapshots")
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
	_check(_write("four_city_source_preflight.json",preflight),"real ROOT041 four-city source preflight persisted, NOT Field/visual proof")
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
	phase.call("_public_fixture",{})
	# Only public initial native spawn selection, never a post-spawn teleport.
	var opened: bool=await phase.call("_open",GATE_ID,Vector2(768,1760)/Vector2(3072,2048))
	_check(opened,"normal go_field_smart creates actual gate candidate Field")
	if opened:
		var probe: RefCounted=phase.get("probe") as RefCounted
		for id: String in ["south_wall_1028","south_wall_2044"]:
			_check((probe.get("blocking_ids") as Dictionary).has(id),"exact original failed blocking ID present: "+id)
			if (probe.get("blocking_ids") as Dictionary).has(id): trials[id]=await probe.call("_collision_trial",id)
		probe=null
		# Real same-ID routing is intentional: the stage guard must bind the
		# actually completed current Field, not the discarded previous instance.
		opened=await phase.call("_open",GATE_ID,Vector2(700,1416)/Vector2(3072,2048))
		_check(opened,"normal same-ID native routing completes before notice oracle binding")
		if opened:
			var object: Dictionary={}
			for entry: Dictionary in (phase.get("manifest") as Dictionary).objects:
				if String(entry.id)=="notice_pavilion": object=entry; break
			_check(not object.is_empty(),"exact current notice independent object, not substituted preview")
			if not object.is_empty():
				var current_probe: RefCounted=phase.get("probe") as RefCounted
				trials["notice_pavilion"]=await current_probe.call("_alpha_trial",object)
				current_probe=null
	await _finish(ready)

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
	var after_files: Dictionary=_normal_files()
	var after_slot: Variant=root.get_node("SaveManager").get("active_slot")
	_check(before_files==after_files and before_slot==after_slot,"all15 normal player paths/size/SHA/mtime and active slot unchanged")
	var source_after: Dictionary=_source_snapshot(ready)
	_check(source_before==source_after,"all actual source and ROOT041 manifest bytes unchanged through LIMITED trials")
	_check(trials.size()==3,"both original wall trials and exact notice front/behind diagnostic executed")
	checks+=phase_checks
	failed+=phase_failed
	var report: Dictionary={"schema":1,"scope":"LIMITED_CAUSAL_NOT_FULL","checks":checks+1,"failed":failed,"failures":failed,"field_executed":actual_field,"dry_run":false,"full_complete":false,"source_complete":false,"GPU_executed":false,"visual_approved":false,"engine_pid":OS.get_process_id(),"executing_script_path":get_script().resource_path,"executing_script_sha256":FileAccess.get_sha256(get_script().resource_path),"source_sha256_before":source_before,"source_sha256_after":source_after,"normal_files_before":before_files,"normal_files_after":after_files,"player_saves_unchanged":before_files==after_files,"active_slot_before":before_slot,"active_slot_after":after_slot,"exact_UTCticks":"ROOT_EXTERNAL_FRESH_BEFORE_AFTER_REQUIRED","navigation_before":navigation_before,"navigation_after":root.get_node("SceneRouter").call("get_navigation_state"),"navigation_cleanup":"NOT_RESTORED; owned process fixture only, no unpublished world15 restore attempted","preflight":preflight,"trials":trials,"output":output,"not_run":["FULL","OTHER3_REGION_FIELD","15NPC_11INTERACTIONS_12PORTALS_GAMEPLAY","MIGRATION_SAVE_LOAD","WORLD15","GPU_VISUAL_APPROVAL"],"stderr_acceptance":"ROOT_WRAPPER_MUST_READ_ACTUAL_VERBOSE_WARNINGS_ERRORS_AND_OS_EXIT"}
	_check(_write("result.json",report),"LIMITED current-snapshot trial result saved with checked readback")
	print("JOINT_CITY_ALPHA_CAUSAL: %d checks / %d failures; LIMITED_CAUSAL_NOT_FULL; output=%s"%[checks,failed,output])
	quit(0 if failed==0 else 1)
