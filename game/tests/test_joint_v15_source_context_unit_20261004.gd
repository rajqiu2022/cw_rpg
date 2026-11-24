extends SceneTree
## Read-only, autoload-context synthetic/source unit. No candidate/Field setup,
## cache-path takeover, public migration, save/load, publisher or gameplay action.
const ORACLE: String = "res://tests/helpers/joint_v15_source_context_oracle.gd"
const GATE: String = "res://scripts/dev/world_map_v15_complete_v5_publication_gate.gd"
const CITY: String = "res://scripts/city/luoyang_layered_v3_contract.gd"
var checks: int = 0
var failures: int = 0
var evidence: Array[Dictionary] = []
var before_files: Dictionary = {}
var before_nav: Dictionary = {}
var before_slot: Variant

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[JOINT source unit FAIL] " + label)

func _files() -> Dictionary:
	var result: Dictionary = {}
	for slot in 5:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = "user://save_%d.json%s" % [slot,suffix]
			var entry: Dictionary = {"exists":FileAccess.file_exists(path)}
			if entry.exists:
				var file: FileAccess = FileAccess.open(path,FileAccess.READ)
				entry["readable"] = file != null
				if file != null:
					entry["bytes"] = file.get_length()
					file.close()
				entry["sha256"] = FileAccess.get_sha256(path)
				entry["modified_seconds"] = FileAccess.get_modified_time(path)
			result[path] = entry
	return result

func _legacy(oracle: RefCounted, city: GDScript) -> void:
	var totals: Vector3i = Vector3i.ZERO
	var ids: Array[String] = ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
	for id: String in ids:
		var pair: Dictionary = oracle.call("load_legacy_pair",id)
		_check(not pair.is_empty(),"literal legacy scene and separately loaded backup layout " + id)
		if pair.is_empty(): continue
		var original: Dictionary = oracle.call("legacy_semantics",pair)
		_check(not original.is_empty(),"hash/path-bound old semantics " + id)
		if original.is_empty(): continue
		totals += Vector3i(original.npcs.size(),original.interactions.size(),original.portals.size())
		var fixture_scene: SceneScript = (pair.scene as SceneScript).duplicate(false) as SceneScript
		var replacement: WalkableMapLayout = WalkableMapLayout.new()
		fixture_scene.map_layout = replacement
		var fixture_pair: Dictionary = pair.duplicate(false)
		fixture_pair["scene"] = fixture_scene
		var altered: Dictionary = oracle.call("legacy_semantics",fixture_pair)
		_check(altered == original,"changing only scene.map_layout cannot substitute old backup interactions/portals " + id)
		fixture_pair["layout"] = replacement
		var rejected: Dictionary = oracle.call("legacy_semantics",fixture_pair)
		_check(rejected.is_empty(),"unbound replacement layout rejected rather than treated as old authority " + id)
		var owner_scene: SceneScript = city.call("legacy_scene",StringName(id)) as SceneScript
		_check(owner_scene != null,"production readonly legacy loader resolves " + id)
		if owner_scene != null:
			_check(owner_scene.map_layout != null and owner_scene.map_layout.interactions == original.interactions and owner_scene.map_layout.portals == original.portals and owner_scene.npcs == original.npcs,"production backup semantics equal independent frozen originals " + id)
			evidence.append({"id":id,"scene_sha256":FileAccess.get_sha256(pair.scene_path),"layout_sha256":FileAccess.get_sha256(pair.layout_path),"counts":[original.npcs.size(),original.interactions.size(),original.portals.size()],"in_memory_replacement_only":true,"canonical_file_written":false})
		owner_scene = null
		fixture_pair.clear()
		fixture_scene = null
		replacement = null
		pair.clear()
	_check(totals == Vector3i(15,11,12),"immutable four-region source totals15/11/12; no action execution claim")
	var unknown: Dictionary = oracle.call("load_legacy_pair","not_a_city")
	_check(unknown.is_empty(),"unknown legacy identity refuses")

func _spacing(gate: GDScript) -> void:
	var ids: Array[String] = ["huashan","luoyang","bianzhou","gufeng","wudang","xiangzhou","jinling","lingyue","mingwu"]
	var source: Dictionary = {"core_landmarks":[],"portals":[],"objects":[]}
	for index in ids.size():
		var desired: Vector2 = Vector2(10+(index%3)*4000,10+floori(float(index)/3.0)*4000)
		var normalized: Vector2 = desired / Vector2(12288,8192)
		var actual: Vector2 = normalized * Vector2(12288,8192)
		var point: Array = [actual.x,actual.y]
		source.core_landmarks.append({"id":ids[index],"center_px":point.duplicate(),"door_foot_px":point.duplicate()})
		source.portals.append({"id":ids[index],"door_foot_px":point.duplicate(),"compound_id":"fixture_"+ids[index]})
		source.objects.append({"id":"fixture_"+ids[index],"pos":[normalized.x,normalized.y]})
	var outcome: String = gate.call("_spacing",source)
	_check(outcome.is_empty(),"synthetic nine-core mechanism positive, not actual world spacing evidence")
	var detached: Dictionary = source.duplicate(true)
	detached.core_landmarks[0].center_px[0] += 1
	_check(not String(gate.call("_spacing",detached)).is_empty(),"self-declared separated core not bound to actual compound must refuse")
	var too_close: Dictionary = source.duplicate(true)
	too_close.core_landmarks[1].door_foot_px = source.core_landmarks[0].door_foot_px.duplicate()
	too_close.portals[1].door_foot_px = source.core_landmarks[0].door_foot_px.duplicate()
	_check(not String(gate.call("_spacing",too_close)).is_empty(),"door spacing independently refuses even when compound centers separated")
	_check(bool(gate.call("_pair_eq",[3072.0,2048.0],Vector2(1536,1024)*2)),"exact visual native SSAA2 dimensions accept")
	_check(not bool(gate.call("_pair_eq",[1536.0,1024.0],Vector2(1536,1024)*2)),"logical canvas cannot impersonate actual native SSAA2 dimensions")
	_check(not bool(gate.call("_pair_eq",[3072.4,2048.0],Vector2(1536,1024)*2)),"fractional dimension not truncated")

func _run() -> void:
	before_files = _files()
	for id: String in ["GameState","Inventory","QuestManager","BountyManager","SceneRouter","SaveManager"]:
		_check(root.has_node(id),"normal autoload registered before dynamic source load " + id)
	if failures > 0:
		quit(1)
		return
	before_nav = root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
	before_slot = root.get_node("SaveManager").get("active_slot")
	var oracle_script: GDScript = load(ORACLE) as GDScript
	var gate: GDScript = load(GATE) as GDScript
	var city: GDScript = load(CITY) as GDScript
	_check(oracle_script != null and oracle_script.can_instantiate(),"oracle loads in actual autoload context")
	_check(gate != null and gate.can_instantiate(),"publication gate source loads without publishing")
	_check(city != null and city.can_instantiate(),"city contract source loads without preparing artifacts")
	if failures == 0:
		var oracle: RefCounted = oracle_script.new() as RefCounted
		_legacy(oracle,city)
		_spacing(gate)
		_check(not bool(oracle.call("_number",15.5,15)),"numeric schema refuses truncation")
		_check(not bool(oracle.call("_pair",[NAN,1])),"nonfinite projected pair refuses")
		_check(not bool(oracle.call("_hash","PENDING")),"pending source hash refuses")
		oracle = null
	oracle_script = null
	gate = null
	city = null
	_check(before_nav == root.get_node("SceneRouter").call("get_navigation_state"),"readonly mechanism checks leave full managed navigation unchanged")
	_check(before_slot == root.get_node("SaveManager").get("active_slot"),"active slot unchanged; no save/load called")
	_check(before_files == _files(),"all15 normal primary/bak/tmp positions bytes/size/seconds unchanged; root exactUTCticks still required")
	var output: String = "res://build/joint_world_luoyang_20261003_qa/source_unit_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(output) == OK,"new evidence output only")
	var result: Dictionary = {"schema":1,"scope":"JOINT_READONLY_SOURCE_SYNTHETIC_UNIT_NOT_FIELD","completed":failures==0,"checks":checks+1,"failures":failures,"evidence":evidence,"engine_pid":OS.get_process_id(),"executing_script_path":get_script().resource_path,"executing_script_sha256":FileAccess.get_sha256(get_script().resource_path),"oracle_sha256":FileAccess.get_sha256(ORACLE),"production_gate_sha256":FileAccess.get_sha256(GATE),"city_contract_sha256":FileAccess.get_sha256(CITY),"normal_files_before":before_files,"normal_files_after":_files(),"field_executed":false,"candidate_ready":false,"visual_approved":false}
	var file: FileAccess = FileAccess.open(output+"result.json",FileAccess.WRITE)
	var saved: bool = file != null
	if file != null:
		var encoded: String = JSON.stringify(result,"\t")
		file.store_string(encoded)
		file.flush()
		saved = file.get_error() == OK
		file.close()
		saved = saved and JSON.parse_string(FileAccess.get_file_as_string(output+"result.json")) == JSON.parse_string(encoded)
	_check(saved,"unit evidence persisted exact JSON readback")
	for frame in 4: await process_frame
	print("JOINT_SOURCE_UNIT_ONLY: %d checks / %d failures; NO FIELD/GPU/PUBLICATION; output=%s" % [checks,failures,output])
	quit(0 if failures==0 else 1)
