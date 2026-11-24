extends SceneTree
## CPU-only pinned closure/kernel preflight. ROOT alone launches this driver.
## Does not instantiate Field, allocate GPU viewports/textures, rebuild NAV,
## decode the 119MB source catalogue, or touch player saves/production files.
const PLAN_PATH := "res://scripts/dev/world_farmland_dirty_plan_v2_20261014.gd"
const PLAN_SHA := "e5e2174c5aed9457769f5762eca5088e9c03f4b212bbf3427f6835f4207411f9"
const PROOF_PATH := "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const PROOF_SHA := "cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851"
const RF_PATH := "res://art/maps/world_map_v15_complete_v9c/terrain_height.rf"
const RF_SHA := "7158eaf91c38ce55541e895b449ee5645a772a2cd037479357eedaf1917e6f4b"
const IDS := ["r2_c1", "r2_c2", "r2_c3", "r3_c1", "r3_c2", "r3_c3", "r4_c2", "r4_c3", "r5_c4", "r5_c5", "r6_c4", "r6_c5"]
const BUDGET_MS := 30000
var started: int
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var plan_record: Dictionary = {}
var camera_record: Dictionary = {}
var pins: Dictionary = {}

func _initialize() -> void:
	started = Time.get_ticks_msec()
	_run.call_deferred()

func _check(ok: bool, label: String) -> bool:
	checks.append({"label": label, "passed": ok})
	if not ok: failures.append(label)
	print("[FARM DIRTY CPU] ", "PASS " if ok else "FAIL ", label)
	return ok

func _pin(path: String, expected: String) -> bool:
	var actual := FileAccess.get_sha256(path).to_lower()
	pins[path] = actual
	return _check(expected.length() == 64 and actual == expected, "Exact input " + path)

func _numbers(value: Variant, expected: Array) -> bool:
	if not value is Array or value.size() != expected.size(): return false
	for index in expected.size():
		if typeof(value[index]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value[index])) or float(value[index]) != float(expected[index]): return false
	return true

func _run() -> void:
	if not _pin(PLAN_PATH, PLAN_SHA) or not _pin(PROOF_PATH, PROOF_SHA) or not _pin(RF_PATH, RF_SHA):
		_finish(); return
	var proof: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROOF_PATH))
	if not _check(proof is Dictionary, "Pinned actual whole proof parses as dictionary"):
		_finish(); return
	var camera: Variant = proof.get("worlds", {}).get("primary", {}).get("camera")
	if not _check(camera is Dictionary, "Actual native primary camera, not invented ROI camera"):
		_finish(); return
	camera_record = camera.duplicate(true)
	_check(proof.get("actual_RF", {}).get("sha256") == RF_SHA, "Actual whole proof binds the same original RF")
	_check(camera.get("projection") == 1 and camera.get("keep_aspect") == 1 and camera.get("size_m") == 80.0 and camera.get("PPM_X") == 102.4, "Actual fixed orthographic source projection scalars")
	_check(_numbers(camera.get("whole_visual_native_canvas"), [24576, 16384]) and _numbers(camera.get("whole_logical_canvas"), [12288, 8192]) and _numbers(camera.get("source_center_px"), [6144, 4096]), "Exact typed JSON dimensions and centered world")
	var transform: Dictionary = camera.get("transform", {})
	var columns: Array = transform.get("basis_columns", [])
	_check(columns.size() == 3 and _numbers(columns[0], [1.0, 0.0, 0.0]) and _numbers(columns[1], [0.0, 0.707106828689575, -0.707106828689575]) and _numbers(columns[2], [0.0, 0.707106828689575, 0.707106828689575]) and _numbers(transform.get("origin"), [0.0, 60.0, 60.0]), "Pinned actual 45-degree transform without epsilon")
	var rf := FileAccess.get_file_as_bytes(RF_PATH)
	if not _check(rf.size() == 1537 * 1025 * 4, "Original RF byte grid size, no image/NAV conversion"):
		_finish(); return
	var script := load(PLAN_PATH) as GDScript
	if not _check(script != null, "Pinned independent plan loads"):
		_finish(); return
	var plan := script.new() as RefCounted
	plan_record = plan.call("derive", rf, camera)
	if not _check(not plan_record.is_empty(), "Actual derive accepts typed JSON camera: " + String(plan.get("error"))):
		_finish(); return
	_check(plan_record.get("scope") == "CONSERVATIVE_OLD18_NEW12_ORIGINAL_RF_SCREEN_PROJECTION_PLUS96" and plan_record.get("ids") == IDS and plan_record.get("tile_count") == 12 and plan_record.get("old_count") == 18 and plan_record.get("new_count") == 12, "Actual fixed twelve dirty IDs and old18/new12 closure")
	_check(plan_record.get("halo_px") == 96 and plan_record.get("numeric_source_padding_px") == 1 and plan_record.get("numeric_screen_padding_px") == 1 and plan_record.get("RF_or_NAV_changed") == false and plan_record.get("pixel_tight_minimum_claim") == false, "Original conservative closure margins, no minimum/math/NAV claim")
	var tiles: Array = plan_record.get("tiles", [])
	var tile_rows: Array[Dictionary] = []
	var tile_ok := tiles.size() == 12
	for index in tiles.size():
		var tile: Dictionary = tiles[index]
		var row: int = tile.get("row", -1)
		var col: int = tile.get("col", -1)
		var rect: Rect2i = tile.get("rect", Rect2i())
		tile_ok = tile_ok and index < IDS.size() and tile.get("id") == IDS[index] and row >= 0 and row < 8 and col >= 0 and col < 8 and tile.get("id") == "r%d_c%d" % [row, col] and rect == Rect2i(Vector2i(col * 1536, row * 1024), Vector2i(1536, 1024))
		tile_rows.append({"id": tile.get("id"), "row": row, "col": col, "rect_px": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]})
	_check(tile_ok, "All twelve original-grid rectangles/ranges exact")
	var parcels: Array = plan_record.get("parcels", [])
	var parcel_ok := parcels.size() == 30
	var revisions := {"old18": 0, "new12": 0}
	for parcel: Dictionary in parcels:
		var revision: String = parcel.get("revision", "")
		if not revisions.has(revision): parcel_ok = false; continue
		revisions[revision] += 1
		var extrema: Array = parcel.get("RF_vertex_extrema", [])
		parcel_ok = parcel_ok and extrema.size() == 2 and is_finite(float(extrema[0])) and is_finite(float(extrema[1])) and float(extrema[0]) <= float(extrema[1])
		for id: String in parcel.get("tiles", []): parcel_ok = parcel_ok and IDS.has(id)
	_check(parcel_ok and revisions.old18 == 18 and revisions.new12 == 12, "Finite RF extrema and all thirty parcels stay in declared closure")
	var binding: Dictionary = plan_record.get("projection_binding", {})
	_check(binding.get("original_whole_camera") == camera and binding.get("fixed_original45_only") == true and binding.get("source_PPM_X") == 102.4 and binding.get("source_PPM_Z") == 72.40773439, "Actual projection binder retains pinned primary camera")
	var kernel: Dictionary = plan_record.get("resampler_support", {})
	var cases: Array = kernel.get("cases", [])
	var measured: int = kernel.get("measured_logical_radius", -1)
	var kernel_ok := cases.size() == 16 and measured > 0 and measured <= 4
	var case_ids: Dictionary = {}
	var observed_max := 0
	for item: Dictionary in cases:
		var phase: Array = item.get("source_phase", [])
		var bg: int = item.get("background", -1)
		var impulse: int = item.get("impulse", -1)
		var radius: int = item.get("logical_radius", -1)
		var affected: int = item.get("affected_pixels", -1)
		var key := str(phase) + "/" + str(bg) + "/" + str(impulse)
		kernel_ok = kernel_ok and phase.size() == 2 and phase[0] in [0, 1] and phase[1] in [0, 1] and bg in [0, 127, 255] and impulse in [0, 255] and bg != impulse and not case_ids.has(key) and radius >= 0 and radius <= 4 and affected > 0 and affected <= 1024
		case_ids[key] = true
		observed_max = maxi(observed_max, radius)
	_check(kernel_ok and observed_max == measured and kernel.get("allowed_logical_support_px") == measured + 1 and kernel.get("extra_phase_alignment_guard_px") == 1 and kernel.get("CPU_max_probe_pixels") == 4096 and kernel.get("wholeCPU_Image") == false and kernel.get("actual_measured") == true and kernel.get("implementation") == "ACTUAL_GODOT_IMAGE_RGBA8_INTERPOLATE_LANCZOS_64_TO32_SCALE2", "Actual sixteen bounded discrete kernel cases, not mathematical support proof")
	var wrong_camera: Dictionary = camera.duplicate(true)
	wrong_camera.whole_visual_native_canvas = [24576.25, 16384.0]
	_check((plan.call("derive", rf, wrong_camera) as Dictionary).is_empty(), "Fractional JSON dimension rejected without truncation")
	wrong_camera = camera.duplicate(true)
	wrong_camera.projection = 0
	_check((plan.call("derive", rf, wrong_camera) as Dictionary).is_empty(), "Different projection rejected before kernel work")
	_check((plan.call("derive", PackedByteArray([0, 0, 0, 0]), camera) as Dictionary).is_empty(), "Wrong RF grid rejected")
	# Small output only: no whole JSON/caster/source catalogue duplication.
	plan_record = {"ids": plan_record.ids, "tiles": tile_rows, "tile_count": 12, "old_count": 18, "new_count": 12, "halo_px": 96, "parcels_count": parcels.size(), "resampler_support": kernel, "projection_binding": binding, "pixel_tight_minimum_claim": false, "RF_or_NAV_changed": false}
	_finish()

func _finish() -> void:
	_pin(PLAN_PATH, PLAN_SHA)
	_pin(PROOF_PATH, PROOF_SHA)
	_pin(RF_PATH, RF_SHA)
	_check(Time.get_ticks_msec() - started < BUDGET_MS, "Independent CPU-only shared30 second budget")
	var report := {"scope": "PINNED_ACTUAL_CAMERA_RF_DIRTY12_CPU_KERNEL_PREFLIGHT_NOT_GPU_OR_PUBLICATION", "passed": failures.is_empty(), "failures": failures.duplicate(), "checks": checks.duplicate(true), "input_pins": pins.duplicate(), "actual_primary_camera": camera_record, "plan": plan_record, "elapsed_ms": Time.get_ticks_msec() - started, "budget_ms": BUDGET_MS, "Field_loaded": false, "GPU_allocation_requested": false, "NAV_or_formal_changed": false, "player_saves_written": false, "whole_source_catalogue_read": false, "discrete_kernel_cases_not_mathematical_proof": true}
	var out_dir := "res://build/world_farmland_dirty_plan_cpu_20261014/%d_%d" % [OS.get_process_id(), started]
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir)) != OK:
		push_error("Cannot create independent CPU test report directory"); quit(1); return
	var file := FileAccess.open(out_dir + "/result.json", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write independent CPU test report"); quit(1); return
	file.store_string(JSON.stringify(report, "\t")); file.flush(); file.close()
	print("[FARM DIRTY CPU] RESULT ", out_dir + "/result.json", " checks=", checks.size(), " failures=", failures.size(), " elapsed_ms=", report.elapsed_ms)
	quit(0 if failures.is_empty() else 1)
