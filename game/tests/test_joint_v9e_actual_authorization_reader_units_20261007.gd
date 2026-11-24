extends SceneTree
## Limited current-byte authorization reader units only. No capture, Field,
## approval, publication, activation, production resource or player-slot writes.
const PROBE_PATH: String = "res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd"
const AUTH_PATH: String = "res://build/joint_v9e_ROOT250_full_authorization_20261007.json"
const REPORT_PATH: String = "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const BUILDER_PATH: String = "res://scripts/dev/build_world_map_v15_coherent_whole_v9e_full_proposal.gd"
const PINS: Dictionary = {
	PROBE_PATH:"3c0f3cc779b2a9388704f4276cd292985bac05a3a7ff9a7cc9226298e4824fd1",
	"res://tests/helpers/joint_v15_world_artifact_semantics_probe.gd":"946fcc3f9ba9d1d46b067672bd8bd560e12bc651a96b7096d48d94a5f5f060a9",
	AUTH_PATH:"ff64ba46e1e09a4cf0b211b7b027e0257ca4eb4e3f14da7317ac30ad484febb0",
	REPORT_PATH:"cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851",
	BUILDER_PATH:"dcda6d3227cad5fd646b6fa3390cae5c4f71354fec1adf15552a12188a8d0121"
}
const EXPECTED_BUDGET: Dictionary = {
	"previous_pilot_pixels":8388608,"maximum_pixels":8404992,
	"maximum_native_canvas":[3456,2432],"logical_tile":[1536,1024],
	"logical_halo_px":96,"ssaa_scale":2,"additional_pixels":16384,
	"additional_RGBA_bytes":65536,"whole_CPU_Image_allowed":false
}
var checks: int = 0
var failures: int = 0
var records: Array[Dictionary] = []
var subject: RefCounted
var auth: Dictionary = {}
var executed: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	records.append({"ok":ok,"label":label})
	if not ok:
		failures += 1
		push_error("[ACTUAL AUTHORIZATION READER UNIT] "+label)

func _hashes() -> Dictionary:
	var result: Dictionary = {}
	for path: String in PINS:
		result[path] = FileAccess.get_sha256(path).to_lower() if FileAccess.file_exists(path) else "MISSING"
	return result

func _read(path: String) -> Dictionary:
	var decoder: JSON = JSON.new()
	if decoder.parse(FileAccess.get_file_as_string(path)) != OK or not decoder.data is Dictionary: return {}
	return decoder.data

func _matches(candidate_auth: Variant, candidate_executed: Variant) -> bool:
	return subject.call("_full_authorization_matches",candidate_auth,candidate_executed,EXPECTED_BUDGET) == true

func _auth_negative(key: String, value: Variant, label: String) -> void:
	var changed: Dictionary = auth.duplicate(true)
	changed[key] = value
	_check(not _matches(changed,executed),label)

func _budget_negative(key: String, value: Variant, label: String) -> void:
	var changed: Dictionary = auth.duplicate(true)
	changed.CPU_ROI_budget[key] = value
	_check(not _matches(changed,executed),label)

func _run() -> void:
	var self_path: String = get_script().resource_path
	var self_sha: String = FileAccess.get_sha256(self_path)
	var before: Dictionary = _hashes()
	_check(before == PINS,"actual helper/original parent/frozen authorization/report/executed builder exact SHA pins")
	if failures != 0:
		quit(1)
		return
	var loaded: Script = load(PROBE_PATH) as Script
	_check(loaded != null,"actual current artifact reader script loads")
	if loaded == null:
		quit(1)
		return
	subject = loaded.new() as RefCounted
	_check(subject != null,"actual current artifact reader instantiates without capture/Field")
	if subject == null:
		quit(1)
		return
	auth = _read(AUTH_PATH)
	var report: Dictionary = _read(REPORT_PATH)
	_check(report.get("executed_builder") is Dictionary and report.get("authorization") is Dictionary,"actual pinned report contains both source and authorization bindings")
	if not report.get("executed_builder") is Dictionary or not report.get("authorization") is Dictionary:
		quit(1)
		return
	executed = report.executed_builder.duplicate(true)
	_check(executed.get("path") == BUILDER_PATH and executed.get("sha256") == PINS[BUILDER_PATH],"actual report binds actual executed E builder path and current bytes")
	_check(report.authorization.get("path") == AUTH_PATH and report.authorization.get("sha256") == PINS[AUTH_PATH],"actual report binds unchanged root authorization path and bytes")
	_check(not auth.has("maximum_cpu_roi_pixels") and not auth.has("CPU_whole_402M_Image_allowed"),"actual current authorization has no obsolete V7 top-level aliases")
	_check(_matches(auth,executed),"actual frozen authorization passes the SAME complete predicate used by _whole")
	for candidate: Variant in [null,true,0,1.0,"authorization",[],Vector2.ZERO]:
		_check(not _matches(candidate,executed),"wrong authorization root type rejected: "+str(typeof(candidate)))
		_check(not _matches(auth,candidate),"wrong executed root type rejected: "+str(typeof(candidate)))
	for key: String in ["approved","allow_full64","memory_budget_approved"]:
		for value: Variant in [false,null,0,1,0.0,1.0,"true",[],{},Vector2.ZERO]:
			_auth_negative(key,value,"strict approval boolean rejects wrong value/type: "+key+"/"+str(typeof(value)))
	for key: String in ["scope","builder_path","builder_sha256","output_root"]:
		for value: Variant in ["WRONG",null,true,0,1.0,[],{},Vector2.ZERO,StringName(auth[key])]:
			_auth_negative(key,value,"exact source/scope/root String identity rejects mutation/type: "+key+"/"+str(typeof(value)))
	for value: Variant in [8404991,8404993,0,-1,INF,NAN,null,true,"8404992",[],{},Vector2.ZERO]:
		_auth_negative("maximum_CPU_ROI_pixels",value,"exact finite current CPU ceiling rejects mutation/type: "+str(value))
	for value: Variant in [8404992,8404992.0]:
		var numeric_auth: Dictionary = auth.duplicate(true)
		numeric_auth.maximum_CPU_ROI_pixels = value
		_check(_matches(numeric_auth,executed),"JSON numeric int/float exact CPU ceiling accepted without String/bool coercion")
	for key: String in ["path","sha256"]:
		for value: Variant in ["WRONG",null,true,0,1.0,[],{},Vector2.ZERO,StringName(executed[key])]:
			var changed_execution: Dictionary = executed.duplicate(true)
			changed_execution[key] = value
			_check(not _matches(auth,changed_execution),"executed source identity/type mutation rejected: "+key+"/"+str(typeof(value)))
		var absent_execution: Dictionary = executed.duplicate(true)
		absent_execution.erase(key)
		_check(not _matches(auth,absent_execution),"missing executed source identity rejected: "+key)
	for key: String in ["approved","scope","builder_path","builder_sha256","output_root","allow_full64","memory_budget_approved","maximum_CPU_ROI_pixels","CPU_ROI_budget"]:
		var missing_auth: Dictionary = auth.duplicate(true)
		missing_auth.erase(key)
		_check(not _matches(missing_auth,executed),"missing required current authorization field rejected: "+key)
	for value: Variant in [null,false,0,1.0,"budget",[],Vector2.ZERO]:
		_auth_negative("CPU_ROI_budget",value,"wrong complete budget container type rejected: "+str(typeof(value)))
	for key: String in EXPECTED_BUDGET:
		var absent_budget: Dictionary = auth.duplicate(true)
		absent_budget.CPU_ROI_budget.erase(key)
		_check(not _matches(absent_budget,executed),"complete exact budget rejects missing key: "+key)
		var expected: Variant = EXPECTED_BUDGET[key]
		if expected is Array:
			for axis in expected.size():
				for step: int in [-1,1]:
					var changed_array: Array = expected.duplicate(true)
					changed_array[axis] += step
					_budget_negative(key,changed_array,"exact budget array component rejects ±1: "+key+"/"+str(axis)+"/"+str(step))
			for value: Variant in [[],[expected[0]],expected+[0],str(expected),true,{},Vector2.ZERO]:
				_budget_negative(key,value,"exact budget array shape/type rejected: "+key+"/"+str(value))
			for value: Variant in [null,true,"3456",NAN,INF,[],{}]:
				var wrong_component: Array = expected.duplicate(true)
				wrong_component[0] = value
				_budget_negative(key,wrong_component,"budget array numeric component wrong type/nonfinite rejected: "+key+"/"+str(value))
		elif expected is bool:
			for value: Variant in [true,null,0,0.0,"false",[],{},Vector2.ZERO]:
				_budget_negative(key,value,"whole CPU image requires literal bool false: "+str(value))
		else:
			for value: Variant in [expected-1,expected+1,null,true,str(expected),NAN,INF,[],{},Vector2.ZERO]:
				_budget_negative(key,value,"every exact memory-budget scalar mutation/type rejected: "+key+"/"+str(value))
	var extra_budget: Dictionary = auth.duplicate(true)
	extra_budget.CPU_ROI_budget.unapproved_extra = false
	_check(not _matches(extra_budget,executed),"complete budget exact keyset rejects unexpected field")
	var old_cap_only: Dictionary = auth.duplicate(true)
	old_cap_only.erase("maximum_CPU_ROI_pixels")
	old_cap_only.maximum_cpu_roi_pixels = 8404992
	_check(not _matches(old_cap_only,executed),"obsolete lowercase cap cannot replace missing actual current key")
	var old_whole_only: Dictionary = auth.duplicate(true)
	old_whole_only.CPU_ROI_budget.erase("whole_CPU_Image_allowed")
	old_whole_only.CPU_whole_402M_Image_allowed = false
	_check(not _matches(old_whole_only,executed),"obsolete top-level whole prohibition cannot replace missing actual nested key")
	var old_whole_override: Dictionary = auth.duplicate(true)
	old_whole_override.CPU_ROI_budget.whole_CPU_Image_allowed = true
	old_whole_override.CPU_whole_402M_Image_allowed = false
	_check(not _matches(old_whole_override,executed),"obsolete top-level false never overrides actual nested whole-image permission")
	_check(_matches(auth,executed),"unchanged actual positive retained after all memory-only mutations")
	subject = null
	loaded = null
	for index in 4: await process_frame
	_check(_hashes() == before and FileAccess.get_sha256(self_path) == self_sha,"all bound inputs and unit bytes unchanged after limited units")
	var output: String = "res://build/joint_world_luoyang_20261003_qa/actual_authorization_reader_units_%d_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	_check(not DirAccess.dir_exists_absolute(output) and DirAccess.make_dir_recursive_absolute(output) == OK,"unique BUILD evidence directory only")
	var payload: String = JSON.stringify({"schema":1,"scope":"LIMITED_ACTUAL_AUTHORIZATION_READER_NOT_FULL_ARTIFACT_FIELD_OR_RELEASE","checks":checks,"failures":failures,"source_path":self_path,"source_sha256":self_sha,"pins":before,"records":records,"actual_authorization":AUTH_PATH,"actual_report":REPORT_PATH,"actual_executed_builder":executed,"capture_executed":false,"whole_artifact_executed":false,"ordinary_Field_executed":false,"input_executed":false,"release_complete":false,"formal_cutover":false,"output":output},"\t")
	var file: FileAccess = FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file == null:
		failures += 1
		push_error("authorization unit BUILD evidence open failed")
	else:
		file.store_string(payload)
		file.flush()
		var write_error: Error = file.get_error()
		file.close()
		if write_error != OK or FileAccess.get_file_as_string(output+"result.json") != payload:
			failures += 1
			push_error("authorization unit BUILD evidence write/readback failed")
	print("ACTUAL_AUTHORIZATION_READER_UNITS: %d/%d; output=%s; authorization predicate only" % [checks,failures,output])
	quit(0 if failures == 0 else 1)
