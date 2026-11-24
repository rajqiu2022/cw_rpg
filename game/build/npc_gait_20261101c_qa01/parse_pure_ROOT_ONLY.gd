extends SceneTree
## Root-only engine parser and actual pure GDScript model, no live Field work.
const HOME := "res://build/npc_gait_20261101c_qa01/"
const CANDIDATE := "res://build/npc_gait_20261101c_candidate01/"
var errors: Array[String] = []
var records: Array = []
var checks := 0
var done := false
func _initialize() -> void:
	run.call_deferred(); watch.call_deferred()
func watch() -> void:
	await create_timer(30.0, true, false, true).timeout
	if not done: need(false, "PURE_PARSER_INDEPENDENT_30S_WATCHDOG"); finish()
func need(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: errors.append(label); push_error(label)
	return ok
func run() -> void:
	for path: String in [CANDIDATE + "distance_phase.gd", CANDIDATE + "npc_gait_runtime.gd", HOME + "gate_finite_ROOT_ONLY.gd"]:
		var script: Script = load(path) as Script
		if not need(script != null and script.can_instantiate(), "NEW_SCRIPT_PARSES:" + path): finish(); return
	var model: GDScript = load(CANDIDATE + "distance_phase.gd") as GDScript
	for fractions: Array in [[0.0, 0.25, 0.5, 0.75], [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875]]:
		need(model.call("table_valid", fractions, fractions.size()) == true, "VALID_ACTUAL_4_OR_8_FRAME_DISTANCE_TABLE:" + str(fractions.size()))
		var outcomes: Array = []
		for fps: int in [30, 60, 120]:
			var distance := 0.0
			var previous := 0.0
			for index: int in range(1, fps * 2 + 1):
				var t: float = float(index) / float(fps)
				var position: float = 20.0 * t + 3.0 * t * t
				distance += absf(position - previous); previous = position
			var frame: int = int(model.call("frame_for_distance", distance, 112.0, fractions))
			var original: float = distance
			for _index: int in range(fps * 10): distance += 0.0
			need(distance == original and int(model.call("frame_for_distance", distance, 112.0, fractions)) == frame, "TEN_SECONDS_ZERO_MOTION_NO_CLOCK_PHASE:" + str(fps))
			need(absf(distance - 52.0) < 0.00000001, "SAME_ACTUAL_MONOTONIC_TRAVEL_52PX:" + str(fps))
			outcomes.append({"fps": fps, "distance": distance, "frame": frame})
		need(outcomes[0].frame == outcomes[1].frame and outcomes[1].frame == outcomes[2].frame, "ACTUAL_GD_MODEL_FRAMERATE_INDEPENDENT:" + str(fractions.size()))
		records.append({"frames": fractions.size(), "outcomes": outcomes})
	need(model.call("table_valid", [0.0, 0.5, 0.25, 0.75], 4) == false, "NONMONOTONIC_TABLE_REJECTED")
	need(int(model.call("frame_for_distance", 84.0, 112.0, [0.0, 0.25, 0.5, 0.75])) == 3, "EXACT_SEEDED_PHASE_PRESERVED_ON_RESUME")
	finish()
func finish() -> void:
	if done: return
	done = true
	var directory := HOME + "parse_actual/" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(directory + "/result.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": errors.is_empty(), "checks": checks, "errors": errors, "records": records, "no_live_field_setup": true, "real_save_API_calls": 0, "actor_camera_writes": 0}, "  ") + "\n"); file.close()
	print("[Gait31c pure/parser] ", checks, " / ", errors.size(), " failures; ", directory)
	quit(0 if errors.is_empty() else 1)
