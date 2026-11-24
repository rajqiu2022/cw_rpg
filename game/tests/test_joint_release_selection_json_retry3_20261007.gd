extends SceneTree
## Independent CPU regression; archived spatial fixture is NOT E/Field credit.
const GATE = preload("res://scripts/dev/joint_world_city_v15_release_acceptance.gd")
const OBJECTS = preload("res://tests/helpers/joint_v15_release_world_object_input_probe.gd")
const FIXTURE := "res://build/world_v9c_ROOT234_before_v9e_material_20261005_01/world_map_v15_complete_v9c_source.json"
const PINS := {
 FIXTURE:"79ffac820dd6a2f475b4595475d0535b9de0b3c29fb21db03e77bc1fa73273fd",
 "res://scripts/dev/joint_world_city_v15_release_acceptance.gd":"e29f17f22e2c17beb44f9dff6dd2612b4dd08e33fa21932ccde75c640dace1ff",
 "res://tests/helpers/joint_v15_release_world_object_input_probe.gd":"bebeb23b6e6bdae458990845380b57f81e9bf4d72986918b12d4d01a658ea43b"
}
var checks := 0
var errors: Array[String] = []
class Owner extends RefCounted:
	var source: Dictionary = {}
	var checks := 0
	var errors: Array[String] = []
	func _check(ok: bool, label: String) -> bool:
		checks += 1
		if not ok: errors.append(label)
		return ok
func _initialize() -> void:
	call_deferred("_run")
func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)
func _run() -> void:
	for path: String in PINS: _check(FileAccess.get_sha256(path).to_lower() == PINS[path],"exact fixed unit input " + path)
	var differences := 0
	if errors.is_empty():
		var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
		var selection: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GATE.RELEASE_SELECTION_PATH))
		var owner := Owner.new()
		owner.source = source
		var probe := OBJECTS.new()
		probe.phase = owner
		_check(probe._read_selection(),"actual QA inventory reader accepts entire frozen2687/44/130 source fixture")
		checks += owner.checks
		errors.append_array(owner.errors)
		var message: String = GATE._selection_error(source)
		_check(message.is_empty(),"actual release gate accepts all inventory and112 frozen seams: " + message)
		var actual: Dictionary = {}
		for object: Dictionary in source.objects: actual[object.id] = object
		for expected: Dictionary in selection.all_bindings:
			var row: Dictionary = actual[expected.id]
			for key: String in expected:
				if key == "texture_sha256" or row.get(key) == expected[key]: continue
				differences += 1
				_check(key == "collision_offset", "only known native Vector2 field has a text-parser tail")
				_check(GATE._release_binding_value_equal(key,row[key],expected[key]) and probe._release_binding_value_equal(key,row[key],expected[key]),"both independent readers require exact native Vector2 bytes")
		_check(differences == 17, "all17 actual decimal/exponent parser differences reproduced")
		var offset: Array = actual.north_shoulder_0_boulder_2.collision_offset
		var bits: PackedInt32Array = PackedFloat32Array([offset[0]]).to_byte_array().to_int32_array()
		bits[0] += 1
		var next: float = bits.to_byte_array().to_float32_array()[0]
		_check(not GATE._release_binding_value_equal("collision_offset",offset,[next,offset[1]]) and not probe._release_binding_value_equal("collision_offset",offset,[next,offset[1]]),"one native Float32 ULP change stays rejected, no epsilon")
		for invalid: Variant in [null,{},[],[0],[0,0,0],[false,0],["0",0],[NAN,0],[INF,0],[1e100,0]]:
			_check(not GATE._release_binding_value_equal("collision_offset",invalid,invalid) and not probe._release_binding_value_equal("collision_offset",invalid,invalid),"malformed offsets rejected even when text-identical")
		for pair: Array in [[[1e100,0],[0,0]],[[0,0],[1e100,0]]]:
			_check(not GATE._release_binding_value_equal("collision_offset",pair[0],pair[1]) and not probe._release_binding_value_equal("collision_offset",pair[0],pair[1]),"either side native overflow remains rejected")
		_check(not GATE._release_binding_value_equal("foot_uv",offset,[next,offset[1]]) and not probe._release_binding_value_equal("foot_uv",offset,[next,offset[1]]),"all non-whitelisted fields keep original exact comparison")
		var old_id: Variant = source.objects[0].id
		source.objects[0].id = "REGRESSION_UNKNOWN_OBJECT"
		_check(not GATE._selection_error(source).is_empty(),"unknown inventory ID rejected")
		source.objects[0].id = old_id
		var old_class: Variant = source.seams[0].classification
		source.seams[0].classification = "REGRESSION_CHANGED_BOUNDARY"
		_check(not GATE._selection_error(source).is_empty(),"changed full seam rejected")
		source.seams[0].classification = old_class
		probe.phase = null
		probe = null
		owner.source.clear()
		owner = null
	for path: String in PINS: _check(FileAccess.get_sha256(path).to_lower() == PINS[path],"unit input unchanged " + path)
	print("RELEASE_SELECTION_JSON_RETRY3 ",JSON.stringify({"scope":"ARCHIVED_SPATIAL_JSON_NATIVE_VECTOR2_UNITS_NOT_E_OR_FIELD_APPROVAL","checks":checks,"failures":errors.size(),"errors":errors,"actual_decimal_exponent_differences":differences,"Field_executed":false,"GPU_executed":false,"formal_cutover":false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm",.15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
