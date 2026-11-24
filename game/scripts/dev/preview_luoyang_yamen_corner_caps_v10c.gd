extends "res://scripts/dev/preview_luoyang_yamen_corner_pair_v10b.gd"

## Frozen B supplies ONLY current-GPU renderer/body/probe helpers. This
## entry/finish never call its parent entry/finish and own a new output root.
const CAPS := preload("res://scripts/dev/luoyang_yamen_corner_caps_v10c_preview.gd")
const CAPS_ROOT := "res://build/luoyang_yamen_corner_caps_v10c_preview/"
var caps_plate: CAPS

func _start() -> void:
	# FIRST deferred action after autoload ready, before every await/work.
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		push_error("V10c requires public checkpoint suspension; no fallback.")
		quit(2)
		return
	bridge.call("set_checkpoint_saves_suspended",true)
	var suspended: Variant = bridge.call("is_checkpoint_saves_suspended")
	if not suspended is bool or not suspended:
		push_error("V10c checkpoint suspension not verified.")
		quit(2)
		return
	checkpoint_guard = {"public_api":"PlatformBridge.set_checkpoint_saves_suspended(true)","before_first_await":true,"actual_verified_suspended":true,"restore_before_quit":false}
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var tag := ""
	for arg: String in args:
		if arg.begins_with("--preview-run-tag="): tag = arg.trim_prefix("--preview-run-tag=")
	var rule := RegEx.new()
	if "--luoyang-yamen-corner-caps-v10c-preview" not in args or rule.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$") != OK or rule.search(tag) == null or DisplayServer.get_name() == "headless":
		push_error("Explicit V10c GPU flag and safe unique tag required.")
		quit(2)
		return
	output = CAPS_ROOT+tag+"/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)):
		push_error("Refusing overwrite of prior V10c evidence.")
		quit(2)
		return
	var bridge_script: Script = bridge.get_script() as Script
	if bridge_script == null or not _track(bridge_script.resource_path):
		quit(2)
		return
	var pins: Dictionary = {
		"res://scripts/dev/luoyang_yamen_corner_pair_v10b_preview.gd":"c940f4bfe817c0aef32ba9b70d9f632b143dba360b642144d6453feb8a817cb5",
		"res://scripts/dev/preview_luoyang_yamen_corner_pair_v10b.gd":"e1e6c846b3f90333f650e213784f7616c1a221fd3c27b47efe3bfc438b81fec3",
		"res://scripts/dev/luoyang_yamen_front_asset_v9_preview.gd":"aa03179f421e2e93c6e4387693ef9e7581312f0c0cf6518f8f5f6cc3f6f9e309",
		"res://scripts/dev/preview_luoyang_yamen_front_asset_v9.gd":"3d39f583feca1cd8ee2c333ef9ee81848d3d03fe74b9eca5b781765dc7f135a0",
		"res://scripts/dev/luoyang_yamen_front_line_v8_preview.gd":V8_HELPER_SHA,
		"res://scripts/dev/preview_luoyang_yamen_front_line_v8.gd":V8_RUNNER_SHA,
		"res://scripts/dev/luoyang_yamen_gate_join_native_v7_preview.gd":FRONT.V7_PIN,
		"res://scripts/dev/preview_luoyang_yamen_gate_join_native_v7.gd":V7_RUNNER_PIN,
		PLATE.repo_path(PLATE.WALL_REL):PLATE.WALL_SHA,
		PLATE.GATE_PATH:PLATE.GATE_SHA,
		PLATE.repo_path("assets/raw/scene_module/luoyang_yamen_front_v9/generation_record.json"):PROVENANCE_SHA,
		PLATE.repo_path(CORNER.ATLAS_REL):CORNER.ATLAS_SHA,
		PLATE.repo_path(PAIR_RECORD_REL):PAIR_RECORD_SHA,
		PLATE.repo_path("assets/raw/scene_module/luoyang_yamen_enclosure_v10/enclosure_modules_v10_candidate.png"):"7711bdf86226b47dc8e96899b051130900f1cf276c3bd2ae48180ca066292002",
		PLATE.repo_path("prompts/templates/luoyang_yamen_enclosure_modules_v10b.yaml"):"072e5dd5c990233f9b4d4b39fd8d1e1509e3260cf91518a972a040f673e30dd1"
	}
	for path: String in pins:
		if not _track(path,String(pins[path])):
			push_error(error)
			quit(2)
			return
	for path: String in [get_script().resource_path,"res://scripts/dev/luoyang_yamen_corner_caps_v10c_preview.gd",PLATE.repo_path("assets/raw/scene_module/luoyang_yamen_enclosure_v10b/offline_call_plan.json")]:
		if not _track(path):
			push_error(error)
			quit(2)
			return
	for path: String in OLD.SOURCE_PINS:
		if not _track(path,OLD.SOURCE_PINS[path]):
			push_error(error)
			quit(2)
			return
	if not _track(INPUT_ROOT+"art_contract.json",MANIFEST_SHA):
		push_error(error)
		quit(2)
		return
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(INPUT_ROOT+"art_contract.json"))
	if not decoded is Dictionary or decoded.get("scene_id") != "ch4_s1_luoyang_yamen":
		push_error("Exact frozen yamen manifest required.")
		quit(2)
		return
	manifest = decoded
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) != OK:
		push_error("Cannot create unique V10c output.")
		quit(2)
		return
	front_asset = FRONT.new()
	asset = front_asset # Unchanged ground/environment; no native wall meshes.
	caps_plate = CAPS.new()
	corner_plate = caps_plate
	plate = caps_plate
	if not asset.prepare() or not caps_plate.prepare():
		error = asset.error if asset.error != "" else caps_plate.error
		await _finish(false)
		return
	var record: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLATE.repo_path(PAIR_RECORD_REL)))
	if not _record_matches_actual(record,CORNER.ATLAS_SHA,caps_plate.atlas_image.get_size()):
		error = "Frozen actual atlas provenance SHA/numeric dimensions mismatch."
		await _finish(false)
		return
	observations["actual_asset_provenance"] = record
	observations["scope"] = {"preview":"V10c ROOF_TURNS_AND_PIERS_ONLY", "baseline":"Current actual GPU V9, not old result PNGs", "expected_carriers":9,"native_walls":0,"A_module_drawn":false,"long_atlas_horizontal_arms_drawn":false,"complete_longitudinal_walls":false,"complete_courtyard":false,"all_horizontal_body_plinth":"Original V9 all spans960..1450.5 and1620.5..2110; no B/C panels", "V9_roof_intervals":[[CAPS.LEFT_TANGENT_X,1450.5],[1620.5,CAPS.RIGHT_TANGENT_X]],"BC_uniform_scale":CORNER.CORNER_SCALE,"actual_new_bounds_required":true,"production_collision_or_old_footprint_credit":false,"source_png_edits":false,"alpha_threshold_or_forced_old_alpha":false,"consumer_change_provenance":"No new generation. Same original atlas; explicit roof-only and pier-only UV polygons in NEW helper; actual node UV/transform readback below."}
	if not await _pair_body():
		await _finish(false)
		return
	observations["actual_carrier_count"] = observations["actual_gpu_carrier_geometry"].size()
	for name: String in PAIR_VIEWS:
		if not await _pair_view(name):
			await _finish(false)
			return
	await _finish(true)

func _pair_view(name: String) -> bool:
	var passed: bool = await super._pair_view(name)
	if passed:
		# Parent captures actual dynamic helper geometry; replace its old
		# hard-coded B count with actual returned9-carrier geometry count.
		cameras[name]["new_carriers"] = cameras[name]["actual_new_geometry"].size()
		cameras[name]["scope"] = "V10c roof turns+piers, all horizontal body/plinth/straight roof V9; NOT full enclosure"
	return passed

func _finish(passed: bool) -> void:
	if view != null:
		view.queue_free()
		view = null
	new_meshes.clear()
	front_texture = null
	if caps_plate != null: caps_plate.release()
	caps_plate = null
	corner_plate = null
	plate = null
	if asset != null: asset.release()
	asset = null
	front_asset = null
	for frame in range(16): await process_frame
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("is_checkpoint_saves_suspended") or bridge.call("is_checkpoint_saves_suspended") != true:
		passed = false
		error = "Checkpoint suspension did not remain active through quit."
	var changes: Array[String] = []
	var final_inputs: Dictionary = {}
	for path: String in inputs:
		final_inputs[path] = FileAccess.get_sha256(path).to_lower()
		if final_inputs[path] != inputs[path]: changes.append(path)
	if not changes.is_empty():
		passed = false
		error = "Read-only V10c input changed during capture."
	var report: Dictionary = {"status":"PREVIEW_NOT_ADOPTED" if passed else "PREVIEW_FAILED_NOT_ADOPTED","passed_capture_checks":passed,"reason":error,"scope":"V10c ATLAS ROOF TURNS+PIERS ONLY, UNIFIED V9 HORIZONTAL WALL+ORIGINAL GATE; NOT full courtyard/longitudinal walls/native/PBR/Field/collision/navigation/audio/release approval", "checkpoint_guard":checkpoint_guard,"inputs_sha256_first":inputs,"inputs_sha256_last":final_inputs,"input_changes":changes,"outputs":outputs,"geometry_and_alpha":observations,"cameras":cameras,"independent_visual_alpha_crop_review":"PENDING","visual_approved":false,"production_approved":false,"audio_credit":"NONE; outer stderr independent review required, no clean-exit claim"}
	var file: FileAccess = null
	if output != "" and not FileAccess.file_exists(output+"preview_result.json"): file = FileAccess.open(output+"preview_result.json",FileAccess.WRITE)
	if file == null:
		passed = false
		error = "Own V10c result save/overwrite refused."
	else:
		file.store_string(JSON.stringify(report,"\t"))
		file.close()
	if not passed: push_error(error)
	quit(0 if passed else 1)
