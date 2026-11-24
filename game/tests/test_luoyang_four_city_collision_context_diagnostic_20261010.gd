extends SceneTree
## Source-only prepared city scope. Root executes this entry serially.
## Requires outer before/after source and all15 player precise UTC ticks.
## No world15, historical migration, approval signing or production writes.
const PHASE_PATH := "res://tests/helpers/luoyang_four_city_collision_context_phase_20261010.gd"
const SAVE_PATH := "res://tests/helpers/luoyang_enclosure_v11_city_only_current_save.gd"
const RAW_PATH := "res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd"
const TARGET_RAW_PATH := "res://tests/helpers/luoyang_enclosure_v11_city_only_target_raw.gd"
const CONTRACT_PATH := "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const ENGINE_SHA := "975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
const BRIDGE_PATH := "res://scripts/autoload/platform_bridge.gd"
const BRIDGE_SHA := "eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a"
const IDS: Array[String]=["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
const PROTECTED: Array[String]=["res://data/scenes/world_map_jianghu.tres","res://data/config/outskirts_native_adoption.json"]
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
	return [PHASE_PATH,SAVE_PATH,RAW_PATH,TARGET_RAW_PATH,CONTRACT_PATH,BRIDGE_PATH,
		"res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd",
		"res://scripts/autoload/scene_router.gd","res://scripts/city/luoyang_layered_v3_contract.gd",
		"res://data/scenes/world_map_jianghu.tres","res://data/config/outskirts_native_adoption.json",
		"res://data/scenes/ch4_s0_luoyang_gate.tres","res://data/scenes/ch4_s1_luoyang_yamen.tres",
		"res://data/scenes/ch4_s2_canal_docks.tres","res://data/scenes/ch4_s3_luoyang_market.tres"]

static func mode(args: Array) -> Dictionary:
	var phase: String=""
	var selected: int=0
	for value: Variant in args:
		if typeof(value)!=TYPE_STRING: return {}
		if value.begins_with("--city-qa-phase="): phase=value.trim_prefix("--city-qa-phase="); selected+=1
	if selected!=1 or phase not in ["source","geometry","gameplay","save"] or "--luoyang-city-only-fresh" not in args or "--fresh-start-only" not in args: return {}
	var candidate: bool="--luoyang-enclosure-v11-candidate" in args
	if candidate!=("--luoyang-v3-candidate" in args): return {}
	for forbidden: String in ["--candidate-before-cutover","--outskirts-candidate-preview","--outskirts-complete-v5","--qa-phase=release"]:
		if forbidden in args: return {}
	return {"phase":phase,"candidate":candidate}

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
	if not FileAccess.file_exists(path): return
	if path.get_extension()!="gd": return
	var pattern:=RegEx.new()
	pattern.compile('res://[^"\\\r\n]+[.]gd')
	for source_match: RegExMatch in pattern.search_all(FileAccess.get_file_as_string(path)): _track(source_match.get_string())

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
	_check(not selected.is_empty(),"explicit unmixed city-only fresh mode")
	output="res://build/joint_world_luoyang_20261003_qa/luoyang_enclosure_v11_city_only_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique actual evidence output")
	var scripts: Dictionary={}
	for path: String in [get_script().resource_path,PHASE_PATH,SAVE_PATH,RAW_PATH,TARGET_RAW_PATH,CONTRACT_PATH,BRIDGE_PATH,"res://scripts/autoload/scene_router.gd","res://scripts/city/luoyang_layered_v3_contract.gd"]:
		_track(path)
		var script: Script=load(path) as Script
		_check(script!=null and script.can_instantiate(),"actual script load/can_instantiate "+path)
		scripts[path]=script
	for path: String in PROTECTED: _track(path)
	for id: String in IDS: _track("res://data/scenes/"+id+".tres")
	_check(AudioServer.get_driver_name()=="WASAPI" and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==ENGINE_SHA and Engine.time_scale==1.0,"actual WASAPI/executable/ordinary time")
	contract=scripts.get(CONTRACT_PATH) as Script
	var records: Dictionary={}
	if failed==0 and selected.phase!="source":
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
		if selected.phase=="source":
			var legal: Array=["--luoyang-city-only-fresh","--fresh-start-only","--city-qa-phase=source"]
			_check(not mode(legal).is_empty(),"formal mode accepted")
			_check(not mode(legal+["--luoyang-v3-candidate","--luoyang-enclosure-v11-candidate"]).is_empty(),"paired explicit candidate mode accepted")
			for extra: Array in [["--luoyang-v3-candidate"],["--outskirts-candidate-preview"],["--candidate-before-cutover"],["--city-qa-phase=geometry"]]:
				_check(mode(legal+extra).is_empty(),"mixed/incomplete mode rejects "+str(extra))
			_check(mode(["--city-qa-phase=source"]).is_empty(),"missing explicit scope rejects")
			report={"scope":"CITY_ONLY_SOURCE_LOAD_MODE_UNITS_NOT_FIELD","complete":failed==0,"Field_executed":false}
		elif selected.phase=="save":
			var menu: RefCounted=(scripts[SAVE_PATH] as Script).new()
			var new_game: Dictionary=await menu.call("run_new_game",self,selected.candidate)
			_check(new_game.get("complete")==true,"actual unchanged menu NewGame input and world14 reset")
			menu=null
			var saver: RefCounted=(scripts[SAVE_PATH] as Script).new()
			report=await saver.call("run_current",self,selected.candidate)
			report["new_game"]=new_game
			_check(report.get("complete")==true,"all four current city save/load/two-birth/20 invalid cases")
			saver=null
		else:
			var phase: RefCounted=(scripts[PHASE_PATH] as Script).new()
			report=await phase.call("run_city_stage",self,selected.candidate,selected.phase,output)
			_check(report.get("complete")==true,"entire selected actual city stage")
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
	var result: Dictionary={"schema":1,"scope":"FOUR_CITY_COLLISION_DIAGNOSTIC_NOT_APPROVAL","mode":selected,"complete":failed==0 and report.get("complete")==true,"checks":checks+1,"failures":failed,"stage":report,"source_before":first,"source_after":last,"players_before":players,"players_after":_normal_files(),"active_slot_before":slot,"active_slot_after":root.get_node("SaveManager").get("active_slot"),"checkpoint_suspension":checkpoint,"actual_audio_driver":AudioServer.get_driver_name(),"engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"historical_compatibility_tested":false,"world_subject_version":14,"world_full_tested":false,"formal_approved":false,"exact_UTCticks":"ROOT_EXTERNAL_FRESH_BEFORE_AFTER_REQUIRED","stderr_acceptance":"ROOT_MUST_READ_COMPLETE_LOG_AND_ACTUAL_OS_EXIT","output":output}
	_check(_write("result.json",result),"city-only final result checked readback")
	print("CITY_ONLY_RESULT "+output+"result.json checks="+str(checks)+" failures="+str(failed))
	quit(0 if failed==0 else 1)

