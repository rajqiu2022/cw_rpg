extends SceneTree
## Pure protocol units only. No Field, navigation, resources or player writes.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const FIELD_PATH := ["visual_objects", 16, "city_v3_solid_polygons_px"]
var checks := 0
var failures := 0

func _init() -> void: call_deferred("_run")

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; push_error("[NATIVE SOLID SERIALIZATION FAIL] " + label)

func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	var expected := [[[2852.97998046875, 1040.1240234375], [2320.9599609375, 1040.1240234375], [2320.9599609375, 1050.0]]]
	var saved := [[[2852.98, 1040.124], [2320.96, 1040.124], [2320.96, 1050.0]]]
	_check(C.equal_visual_serialized_value(expected, saved, FIELD_PATH), "ROOT542 native-identical saved decimals")
	_check(C.equal_visual_serialized_value(expected, saved, ["visual_objects", 16, &"city_v3_solid_polygons_px"]), "native TRES StringName field path")
	var expected_envelope := [{&"city_v3_solid_polygons_px": expected}]
	var saved_envelope := [{&"city_v3_solid_polygons_px": saved}]
	_check(C.equal_visual_serialized_value(expected_envelope, saved_envelope, ["visual_objects"]), "native StringName dictionary envelope dispatch")
	_check(not C.equal_visual_serialized_value(expected, saved, ["visual_objects", 16, &"unknown_solid_polygons_px"]), "wrong StringName field does not select adapter")
	_check(not C.equal_visual_serialized_value(expected, saved, ["visual_objects", 16, 7]), "integer field key does not select adapter")
	_check(not C.equal_visual_serialized_value(expected, saved, ["visual_objects", -1, &"city_v3_solid_polygons_px"]), "negative object index rejects")
	_check(C.equal_visual_serialized_value(expected, expected, FIELD_PATH), "exact sequence")
	_check(C.equal_visual_serialized_value([], [], FIELD_PATH), "empty no-solid sequence")
	var bits := PackedFloat32Array([saved[0][0][0]]).to_byte_array()
	bits.encode_u32(0, bits.decode_u32(0) + 1)
	var one_ulp: Array = saved.duplicate(true)
	one_ulp[0][0][0] = float(bits.decode_float(0))
	_check(not C.equal_visual_serialized_value(expected, one_ulp, FIELD_PATH), "one native ULP rejects")
	for value: Variant in [2852, "2852.98", true, NAN, INF, -INF, 1.0e100]:
		var changed: Array = saved.duplicate(true)
		changed[0][0][0] = value
		_check(not C.equal_visual_serialized_value(expected, changed, FIELD_PATH), "wrong scalar type/nonfinite/overflow " + str(value))
	_check(not C.equal_visual_serialized_value(expected, saved, ["visual_objects", 16, "unknown_solid_polygons_px"]), "unknown field remains strict")
	_check(not C.equal_visual_serialized_value(expected, saved, ["visual_objects", 16, "authoring", "unknown"]), "unapproved annotation remains strict")
	_check(not C.equal_visual_serialized_value(expected, saved, ["visual_objects", 16.0, "city_v3_solid_polygons_px"]), "float index cannot select adapter")
	_check(not C.equal_visual_serialized_value(expected, saved, ["scene", 16, "city_v3_solid_polygons_px"]), "nonvisual field remains strict")
	_check(not C.equal_visual_serialized_value(expected, saved, ["visual_objects", 16, "city_v3_solid_polygons_px", 0]), "incorrect field path depth rejects")
	for changed: Array in [[[[2852.98, 1040.124], [2320.96, 1040.124]]], [[[2852.98, 1040.124, 0.0], [2320.96, 1040.124], [2320.96, 1050.0]]], [[[2852.98, 1040.124], [2320.96, 1040.124], [2320.96, 1050.0]], []]]:
		_check(not C.equal_visual_serialized_value(expected, changed, FIELD_PATH), "polygon shape/count differs")
	var reversed: Array = saved.duplicate(true)
	reversed[0].reverse()
	_check(not C.equal_visual_serialized_value(expected, reversed, FIELD_PATH), "vertex order differs")
	print("LUOYANG_NATIVE_SOLID_SERIALIZATION_UNITS=" + JSON.stringify({"scope": "PURE_NATIVE_SERIALIZATION_NOT_FIELD_APPROVAL", "checks": checks, "failures": failures}))
	quit(0 if failures == 0 else 1)
