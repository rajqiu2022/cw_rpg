extends SceneTree
## Read-only historical-memory regression, not capture/Field/publication approval.
## Reconstruct both baselines independently from the immutable ROOT078 result.
const GATE = preload("res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd")
const GATE_PATH := "res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd"
const GATE_SHA := "c98be791f06ba99321ec72fe8b2c1a8f5b6c609594bf62a82845c0b923386d84"
const ORIGIN := "res://build/world_map_v15_whole_framebuffer_memory/1791062610_2434323/"
const RESULT_SHA := "635f79565e1258f077c47ab53ed5e22c235921896c48079dbdc695b5859cd6fe"
const IMAGE_SHA := "d9a06a25a2bd0394d86a2ba246cafe6b5229f8d64f0b0751277da131348a97e5"
const CAPTURE_PATH := "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const CAPTURE_SHA := "cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851"
const SAMPLE_KEYS: Array[String] = ["allocated", "first_readback_memory", "two_readbacks_memory", "byte_comparison_peak_memory", "after_save_memory"]
var checks: int = 0
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func _peaks(square: Dictionary, baseline: Dictionary) -> Dictionary:
	var peaks: Dictionary = {"vram_peak_delta_bytes": 0, "process_peak_delta_bytes": 0}
	for key: String in SAMPLE_KEYS:
		var sample: Dictionary = square[key]
		peaks.vram_peak_delta_bytes = maxi(peaks.vram_peak_delta_bytes, int(sample.vram_used_bytes) - int(baseline.vram_used_bytes))
		peaks.process_peak_delta_bytes = maxi(peaks.process_peak_delta_bytes, int(sample.process_private_bytes) - int(baseline.process_private_bytes))
	return peaks

func _run() -> void:
	for pair: Array in [[GATE_PATH, GATE_SHA], [ORIGIN + "result.json", RESULT_SHA], [CAPTURE_PATH, CAPTURE_SHA]]:
		_check(FileAccess.get_sha256(pair[0]).to_lower() == pair[1], "literal actual input bytes: " + pair[0])
	var original: Variant = JSON.parse_string(FileAccess.get_file_as_string(ORIGIN + "result.json"))
	var capture: Variant = JSON.parse_string(FileAccess.get_file_as_string(CAPTURE_PATH))
	_check(original is Dictionary and original.get("square") is Dictionary and original.get("baseline") is Dictionary and original.square.get("baseline") is Dictionary, "actual distinct typed process/square baselines")
	_check(capture is Dictionary and capture.get("actual_memory_history") is Dictionary, "actual current capture history, not manufactured success")
	if errors.is_empty():
		var square: Dictionary = original.square
		for key: String in SAMPLE_KEYS: _check(square.get(key) is Dictionary, "all five original square samples: " + key)
		if errors.is_empty():
			var actual_peaks: Dictionary = _peaks(square, square.baseline)
			var wrong_peaks: Dictionary = _peaks(square, original.baseline)
			_check(actual_peaks == {"vram_peak_delta_bytes": 519045120, "process_peak_delta_bytes": 1898823680}, "actual square-component baseline exact peaks")
			_check(wrong_peaks == {"vram_peak_delta_bytes": 503316480, "process_peak_delta_bytes": 1896071168} and wrong_peaks != actual_peaks, "old process-start baseline reproduces distinct erroneous peaks")
			var history: Dictionary = capture.actual_memory_history
			for key: String in actual_peaks: _check(history.get(key) == actual_peaks[key], "real current capture used component baseline: " + key)
			var catalog: Dictionary = {ORIGIN + "result.json": RESULT_SHA, ORIGIN + "native_8192x8192_raw.png": IMAGE_SHA, ORIGIN + "native_8192x8192_raw_repeat.png": IMAGE_SHA}
			_check(GATE._history_error(history, catalog).is_empty(), "real bound original history accepted with square baseline")
			for changed_keys: Array in [["vram_peak_delta_bytes"], ["process_peak_delta_bytes"], ["vram_peak_delta_bytes", "process_peak_delta_bytes"]]:
				var wrong: Dictionary = history.duplicate(true)
				for key: String in changed_keys: wrong[key] = wrong_peaks[key]
				_check(GATE._history_error(wrong, catalog) == "Historical whole estimate is not recomputed from actual square peaks", "old baseline error remains strictly rejected: " + str(changed_keys))
	for pair: Array in [[GATE_PATH, GATE_SHA], [ORIGIN + "result.json", RESULT_SHA], [CAPTURE_PATH, CAPTURE_SHA]]:
		_check(FileAccess.get_sha256(pair[0]).to_lower() == pair[1], "actual input unchanged after units: " + pair[0])
	print("V9E_SQUARE_MEMORY_BASELINE_UNITS ", JSON.stringify({"scope": "READ_ONLY_HISTORICAL_MEMORY_UNIT_NOT_FIELD_OR_PUBLICATION", "checks": checks, "failures": errors.size(), "errors": errors, "Field_executed": false, "GPU_executed": false, "formal_cutover": false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
