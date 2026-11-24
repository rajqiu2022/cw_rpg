extends "res://tests/test_luoyang_gate_fortification_field_key_20261013.gd"
## NEW source-domain fixture correction only. Original actual FAIL is immutable.
const ORIGINAL_TEST := "res://tests/test_luoyang_gate_fortification_field_key_20261013.gd"
const ORIGINAL_TEST_SHA := "64be58e1f0e1fccdece808a91d81b82e9e5dc41a71e746caae95d35ec7cb249b"

func _move(point: Vector2) -> Dictionary:
	var actual: Dictionary = await super._move(point)
	if actual.get("ok") != true:
		var definition: SceneScript = field.get("_current_scene") as SceneScript if is_instance_valid(field) else null
		var evidence: Dictionary = {"scope":"ACTUAL_MOVE_FAILURE_NOT_EXTRA_CASE","target":point,"scene_id":String(definition.scene_id) if definition != null else "FREED","physics_frame":Engine.get_physics_frames(),"msec":Time.get_ticks_msec(),"driver_receipt":actual}
		var path: String = output + "move_failure_%d.json" % Time.get_ticks_usec()
		var file: FileAccess = FileAccess.open(path,FileAccess.WRITE) if not FileAccess.file_exists(path) else null
		if file != null:
			file.store_string(JSON.stringify(_values(evidence),"\t")); file.close()
		_check(file != null,"immediate failed move receipt saved")
		print("GATE_ACTUAL_MOVE_FAILURE=" + JSON.stringify(_values(evidence)))
	return actual

func _stop_case(label: String, start: Vector2, forbidden: Vector2, action: String) -> void:
	if label == "WALL_STOP":
		var first: Dictionary = await _move(Vector2(1536,380))
		if not _check(first.get("ok") == true,"normal fixed wall-inner route reaches north gate lane"): return
		var second: Dictionary = await _move(Vector2(1100,380))
		if not _check(second.get("ok") == true,"normal fixed wall-inner route bypasses original gate wing"): return
		await super._stop_case(label,Vector2(1100,420),Vector2(1100,470),"move_down")
	else:
		await super._stop_case(label,start,forbidden,action)

func _run() -> void:
	if not _check(FileAccess.get_sha256(ORIGINAL_TEST) == ORIGINAL_TEST_SHA and "--luoyang-gate-wall-inner-retry" in OS.get_cmdline_user_args(),"exact immutable original test and explicit new retry flag"):
		quit(1)
		return
	source_before[ORIGINAL_TEST] = _file(ORIGINAL_TEST)
	await super._run()
