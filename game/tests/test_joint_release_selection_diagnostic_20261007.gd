extends SceneTree
## Read-only numeric/type diagnostic, not an acceptance test.
const SOURCE := "res://build/world_v9c_ROOT234_before_v9e_material_20261005_01/world_map_v15_complete_v9c_source.json"
const SELECTION := "res://build/joint_world_luoyang_20261003_qa/release_selection_root234_20261005_01/representative_selection.json"
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	var selection: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SELECTION))
	var actual: Dictionary = {}
	for object: Dictionary in source.objects: actual[object.id] = object
	var differences := 0
	for expected: Dictionary in selection.all_bindings:
		var row: Dictionary = actual[expected.id]
		for key: String in expected:
			if key == "texture_sha256" or row.get(key) == expected[key]: continue
			differences += 1
			if differences <= 12:
				print("SELECTION_FIELD_DIFFERENCE ",JSON.stringify({"id":expected.id,"key":key,"actual_type":typeof(row.get(key)),"expected_type":typeof(expected[key]),"actual":str(row.get(key)),"expected":str(expected[key]),"actual_bytes":var_to_bytes(row.get(key)).hex_encode(),"expected_bytes":var_to_bytes(expected[key]).hex_encode()}))
	print("SELECTION_DIAGNOSTIC_DIFFERENCES ",differences)
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm",.15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for frame in 16: await process_frame
	quit(0)
