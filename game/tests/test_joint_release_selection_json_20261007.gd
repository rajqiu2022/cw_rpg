extends SceneTree
## Regression fixture ONLY: archived ROOT234 spatial inventory is immutable.
## No old rendering, Field or current E release approval is inherited here.
const GATE = preload("res://scripts/dev/joint_world_city_v15_release_acceptance.gd")
const GATE_PATH := "res://scripts/dev/joint_world_city_v15_release_acceptance.gd"
const GATE_SHA := "bfe47ed8c0cdd51d64bca55fe1c2cb3092872b01cbb5d15799c86b95c9a8bfef"
const FIXTURE := "res://build/world_v9c_ROOT234_before_v9e_material_20261005_01/world_map_v15_complete_v9c_source.json"
const FIXTURE_SHA := "79ffac820dd6a2f475b4595475d0535b9de0b3c29fb21db03e77bc1fa73273fd"
var checks := 0
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func _run() -> void:
	_check(FileAccess.get_sha256(GATE_PATH).to_lower() == GATE_SHA, "exact repaired gate source")
	_check(FileAccess.get_sha256(FIXTURE).to_lower() == FIXTURE_SHA, "exact old immutable spatial fixture only")
	if errors.is_empty():
		var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
		_check(source is Dictionary, "actual archived JSON dictionary")
		if source is Dictionary:
			var parsed_selection: Variant = JSON.parse_string(FileAccess.get_file_as_string(GATE.RELEASE_SELECTION_PATH))
			_check(parsed_selection is Dictionary and typeof(parsed_selection.seams[0].actual_input_witness_indices[0]) == TYPE_FLOAT, "real frozen witness JSON reaches float representation")
			var error: String = GATE._selection_error(source)
			_check(error.is_empty(), "all2687/44PNG/130/112 archived spatial selection accepted after numeric fix: " + error)
			# Mutate only an in-memory field, restore it immediately. No files or
			# actual captured metadata/selection are rewritten to make tests pass.
			var first_object: Dictionary = source.objects[0]
			var old_id: Variant = first_object.id
			first_object.id = "REGRESSION_UNKNOWN_OBJECT"
			_check(not GATE._selection_error(source).is_empty(), "unknown original inventory identity still rejected")
			first_object.id = old_id
			var first_seam: Dictionary = source.seams[0]
			var old_class: Variant = first_seam.classification
			first_seam.classification = "REGRESSION_CHANGED_BOUNDARY"
			_check(not GATE._selection_error(source).is_empty(), "changed full boundary remains rejected")
			first_seam.classification = old_class
			source.clear()
	_check(FileAccess.get_sha256(FIXTURE).to_lower() == FIXTURE_SHA, "archived source is still immutable after units")
	print("RELEASE_SELECTION_JSON_REGRESSION ",JSON.stringify({"scope":"ARCHIVED_SPATIAL_FIXTURE_JSON_REGRESSION_NOT_CURRENT_E_APPROVAL","checks":checks,"failures":errors.size(),"errors":errors,"Field_executed":false,"GPU_executed":false,"formal_cutover":false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm",.15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
