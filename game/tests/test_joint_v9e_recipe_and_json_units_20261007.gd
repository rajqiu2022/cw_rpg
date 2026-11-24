extends SceneTree
## CPU-only units against frozen regional evidence. No Field, rendering,
## publication, reward, approval or formal-map mutation is performed here.
const ARTIFACT_PATH := "res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd"
const ARTIFACT_SHA := "334fb0a665acf1cdaed46b949f71bc9cf9850bc915402c16293e2da2ffa7bcdd"
const GATE_PATH := "res://scripts/dev/joint_world_city_v15_release_acceptance.gd"
const GATE_SHA := "bfe47ed8c0cdd51d64bca55fe1c2cb3092872b01cbb5d15799c86b95c9a8bfef"
const GATE = preload("res://scripts/dev/joint_world_city_v15_release_acceptance.gd")
const REGIONAL_PATH := "res://build/world_map_v15_coherent_whole_v9c_regional/v9d_broad_soft/1791137714_2690526/result.json"
const REGIONAL_SHA := "fe50ec4312753bd62eee0e4c62a1944dfb29859e6f339e04282dc05864f960d0"
const EXPECTED_CODE := {
 "terrain":"4b060ef119e340e6c1eaaa095623944d999312a56ab2508e1792f1b6994bbbeb",
 "water":"40192a289930ee9e0dabcfceeea494c04db6f2fd4ccee3d816481b01458b8a0c"
}
var checks := 0
var errors: Array[String] = []

class RecipeProbe extends "res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd":
	var unit_errors: Array[String] = []
	func _check(ok: bool, label: String) -> bool:
		checks += 1
		if not ok:
			failures += 1
			unit_errors.append(label)
		return ok

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func _sole_numeric_zero(value: Variant) -> bool:
	return value is Array and value.size() == 1 and GATE._number(value[0], 0)

func _run() -> void:
	for pair: Array in [[ARTIFACT_PATH,ARTIFACT_SHA],[GATE_PATH,GATE_SHA],[REGIONAL_PATH,REGIONAL_SHA]]:
		_check(FileAccess.get_sha256(pair[0]).to_lower() == pair[1], "literal current unit input " + pair[0])
	if errors.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(REGIONAL_PATH))
		_check(data is Dictionary and data.get("cached_inputs_sha256") is Dictionary, "typed frozen regional fixture")
		if data is Dictionary and data.get("cached_inputs_sha256") is Dictionary:
			var probe := RecipeProbe.new()
			probe.catalog = data.cached_inputs_sha256.duplicate(true)
			probe.execution_inputs = probe.V9E_EXECUTION_PINS.duplicate(true)
			probe.derived_inputs = data.get("derived_geometry_inputs",{}).duplicate(true)
			var controls: Dictionary = probe._actual_shader_controls()
			_check(controls.size() == 2, "independent original-literal terrain/water reconstruction")
			for kind: String in EXPECTED_CODE:
				_check(controls.get(kind) is String and probe._sha(String(controls.get(kind,"")).to_utf8_buffer()) == EXPECTED_CODE[kind], "independently reconstructed actual E shader bytes " + kind)
			if controls.size() == 2:
				_check(probe._v9e_revision_records(data, controls, true), "actual five-creation regional E record semantics")
			checks += probe.checks
			errors.append_array(probe.unit_errors)
			probe.geometry.call("release")
			probe.geometry = null
			probe.catalog.clear()
			probe = null
	var parsed: Variant = JSON.parse_string('{"indices":[0]}')
	_check(parsed is Dictionary and parsed.indices is Array and typeof(parsed.indices[0]) == TYPE_FLOAT, "actual JSON zero is float, reproducing the old native-array mismatch")
	_check(parsed is Dictionary and _sole_numeric_zero(parsed.indices), "exact sole JSON numeric zero remains accepted")
	_check(_sole_numeric_zero([0]) and _sole_numeric_zero([0.0]), "native int and float zero represent the same fixed witness")
	for invalid: Variant in [null,{},[],[1],[-1],[0,0],["0"],[false],[NAN],[INF]]:
		_check(not _sole_numeric_zero(invalid), "malformed/nonzero/nonfinite witness stays rejected: " + str(invalid))
	print("V9E_RECIPE_JSON_UNITS ", JSON.stringify({"scope":"CPU_RECIPE_AND_JSON_UNITS_NOT_FIELD_OR_FULL","checks":checks,"failures":errors.size(),"errors":errors,"Field_executed":false,"GPU_executed":false,"formal_cutover":false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
