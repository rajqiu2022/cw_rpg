extends "res://tests/test_luoyang_gate_fortification_field_key_20261013.gd"
## Three receipts ONLY: bound source and two normal portal round trips.
## 90s arrival is diagnosis of the old 30s refusal, not a speed/whole9 claim.
const OLD_KEY := "res://tests/test_luoyang_gate_fortification_field_key_20261013.gd"
const OLD_KEY_SHA := "64be58e1f0e1fccdece808a91d81b82e9e5dc41a71e746caae95d35ec7cb249b"
const OLD_WALL := "res://tests/test_luoyang_gate_fortification_field_key_wall_inner_retry_20261013.gd"
const OLD_WALL_SHA := "5b9938a084be3bf521d1fb7b7f6ee3985adbe9ada86c212a63e91f87fed2d710"
var arrival_observations: Array[Dictionary] = []
var gallery: Array[Dictionary] = []

func _observe_arrival(id: String, phase: String, started: int) -> void:
	var manager: Node = root.get_node("LoadingManager")
	var actual: Node = current_scene
	var definition: SceneScript = actual.get("_current_scene") as SceneScript if is_instance_valid(actual) and actual.scene_file_path == "res://scenes/field_walkable.tscn" else null
	var player: Node = actual.get("_player") as Node if definition != null else null
	var observation: Dictionary = {"target":id,"phase":phase,"msec":Time.get_ticks_msec(),"elapsed_ms":Time.get_ticks_msec()-started,"process_frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames(),"LM_transition_active":manager.get("_transition_active"),"LM_external_active":manager.get("_external_active"),"LM_external_token":manager.get("_external_token"),"LM_field_preparation_token":manager.get("_field_preparation_token"),"current_file":actual.scene_file_path if is_instance_valid(actual) else "NONE","current_scene_id":String(definition.scene_id) if definition != null else "NONE","current_field_id":actual.get_instance_id() if definition != null else 0,"Field_stage":actual.get("_field_loading_stage") if definition != null else "NONE","Field_rebuilding":actual.get("_scene_rebuilding") if definition != null else false,"Player_exists":is_instance_valid(player),"Player_inside":player.is_inside_tree() if is_instance_valid(player) else false,"Player_queued":player.is_queued_for_deletion() if is_instance_valid(player) else false,"C_state":C.transition_validation_state(),"C_errors":C.errors()}
	arrival_observations.append(_values(observation))
	var file: FileAccess = FileAccess.open(output+"arrival_observations.json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"scope":"ENTRY_WAIT_DIAGNOSTIC_NOT_GEOMETRY_OR_SPEED","records":arrival_observations},"\t")); file.close()
	_check(file != null,"arrival state saved synchronously before cleanup")
	print("GATE_ENTRY_WAIT="+JSON.stringify(_values(observation)))

func _wait_field(id: String) -> bool:
	var started: int = Time.get_ticks_msec()
	var end: int = mini(deadline,started+90000)
	_observe_arrival(id,"begin",started)
	while Time.get_ticks_msec() < end:
		await process_frame
		if bool(root.get_node("LoadingManager").get("_transition_active")): continue
		var pending: Node = current_scene
		if not is_instance_valid(pending) or not pending.is_inside_tree() or pending.is_queued_for_deletion() or pending.scene_file_path != "res://scenes/field_walkable.tscn": continue
		var definition: SceneScript = pending.get("_current_scene") as SceneScript
		var player: Node2D = pending.get("_player") as Node2D
		if definition == null or String(definition.scene_id) != id or not is_instance_valid(player) or not player.is_inside_tree() or player.is_queued_for_deletion() or bool(pending.get("_scene_rebuilding")): continue
		await driver.call("completed_actor_stage")
		if not is_instance_valid(pending) or current_scene != pending or pending.is_queued_for_deletion() or bool(root.get_node("LoadingManager").get("_transition_active")) or bool(pending.get("_scene_rebuilding")) or not is_instance_valid(player) or pending.get("_player") != player: continue
		field = pending
		_observe_arrival(id,"arrived",started)
		return true
	_observe_arrival(id,"timeout_before_cleanup",started)
	return _check(false,"diagnostic90 shared270 live Field arrival " + id)

func _save_gallery() -> void:
	var file: FileAccess = FileAccess.open(output+"gallery.json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_values({"scope":"ACTUAL_GATE_BRIDGE_GPU_GALLERY_NOT_EXTRA_CASES","records":gallery}),"\t")); file.close()
	_check(file != null,"actual gallery saved before portal waits")
	print("GATE_ENTRY_GALLERY="+JSON.stringify(_values(gallery)))

func _exercise_gate() -> void:
	if not _sources_gate(): return
	if not _check(bool(root.get_node("SceneRouter").call("go_field_smart",StringName(GATE_ID),null,"",-1,3)),"public real Gate startup"): return
	if not await _wait_field(GATE_ID) or not _bind(): return
	var north: Dictionary = await _move(Vector2(1536,560))
	if not _check(north.get("ok") == true,"normal source-bound movement to actual Gate image"): return
	gallery.append({"kind":"GATE_GPU","movement":north,"image":await _capture_gate("gate_entry_before_portals")})
	_save_gallery()
	var bridge: Dictionary = await _move(Vector2(1536,760))
	if not _check(bridge.get("ok") == true,"normal source-bound movement to actual bridge image"): return
	gallery.append({"kind":"BRIDGE_GPU","movement":bridge,"image":await _capture_gate("gate_bridge_before_portals")})
	_save_gallery()
	for mode: String in ["space","mouse"]:
		await _trip(mode)
		if failures != 0:
			_observe_arrival(YAMEN_ID,"case_failure_before_cleanup",Time.get_ticks_msec())
			return

func _run() -> void:
	var exact: bool = FileAccess.get_sha256(OLD_KEY) == OLD_KEY_SHA and FileAccess.get_sha256(OLD_WALL) == OLD_WALL_SHA
	if not _check(exact and "--luoyang-gate-entry-diagnostic" in OS.get_cmdline_user_args(),"two immutable tests and explicit entry-only diagnostic"):
		quit(1)
		return
	source_before[OLD_KEY] = _file(OLD_KEY); source_before[OLD_WALL] = _file(OLD_WALL)
	expected_rows = 3
	print("GATE_ENTRY_ONLY_SCOPE=SOURCE_SPACE_MOUSE_NOT_GEOMETRY9_NOT_SPEED")
	await super._run()
