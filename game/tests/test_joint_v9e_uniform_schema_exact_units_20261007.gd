extends SceneTree
## Actual four saved materials + same-code native schema. READ ONLY unit,
## not source material-factory reconstruction, publish, Field or GPU capture.
const GATE = preload("res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd")
const GATE_PATH := "res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd"
const GATE_SHA := "be862004a0a9867a661c2469e7803a90419aa03a033cbd3a46a087055036066b"
const PROBE_PATH := "res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd"
const PROBE_SHA := "a1f205261be92589e6d1d9b1d665c3441a12c2559c34d290cb7e932c71c5aabc"
const REPORT_PATH := "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const REPORT_SHA := "cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851"
const MATERIALS := {
	"res://art/maps/world_map_v15_complete_v9c/capture/primary/actual_terrain_material.res": "4b8ec4571d316dfce70c893102c1191fbaf67b79286c1f655e5846db9da5e33a",
	"res://art/maps/world_map_v15_complete_v9c/capture/primary/actual_water_material.res": "87cedcb26ea48af86616f52a7b81b3e0c2b93c40bab5325e8d99a566bd07e750",
	"res://art/maps/world_map_v15_complete_v9c/capture/reference/actual_terrain_material.res": "0295ba8c077ae4545df1991bfaf18589396389a8fc9063ca0455b1ec264bddda",
	"res://art/maps/world_map_v15_complete_v9c/capture/reference/actual_water_material.res": "f47944f30905818ec7e451ca77f81e994d6f89ef705390ea82f0a6a9204d993b",
}
var checks: int = 0
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func _wrong_type(value: Variant) -> Variant:
	if typeof(value) == TYPE_INT: return float(value)
	if typeof(value) == TYPE_STRING_NAME: return String(value)
	return StringName(str(value))

func _wrong_value(value: Variant) -> Variant:
	if typeof(value) == TYPE_INT: return int(value) + 1
	if typeof(value) == TYPE_STRING_NAME: return StringName(String(value) + "_CHANGED")
	return String(value) + "_CHANGED"

func _material_units(saved: ShaderMaterial, row: Dictionary) -> void:
	var fresh: ShaderMaterial = ShaderMaterial.new()
	fresh.shader = Shader.new()
	fresh.shader.code = saved.shader.code
	var specs: Array = saved.shader.get_shader_uniform_list()
	var other: Array = fresh.shader.get_shader_uniform_list()
	_check(specs.size() == (26 if row.kind == "terrain" else 3), "actual complete native uniform count: " + row.path)
	_check(var_to_bytes(specs) == var_to_bytes(other), "actual saved/fresh native schemas byte-exact: " + row.path)
	_check(not GATE._json_native_exact(specs, other), "ROOT280 native/StringName versus JSON mismatch reproduced: " + row.path)
	if specs.is_empty(): return
	for index in specs.size():
		var spec: Dictionary = specs[index]
		fresh.set_shader_parameter(String(spec.name), saved.get_shader_parameter(String(spec.name)))
		_check(GATE._json_native_exact(row.actual_uniforms[index].schema, spec), "every actual captured schema uses writer boundary exactly once: " + str(spec.name))
		for key: Variant in spec:
			for replacement: Variant in [_wrong_type(spec[key]), _wrong_value(spec[key])]:
				var wrong: Array = specs.duplicate(true)
				wrong[index][key] = replacement
				_check(var_to_bytes(specs) != var_to_bytes(wrong), "every native schema field/type/value mutation rejected: %s/%s" % [spec.name, key])
			var missing: Array = specs.duplicate(true)
			missing[index].erase(key)
			_check(var_to_bytes(specs) != var_to_bytes(missing), "every native schema missing field rejected: %s/%s" % [spec.name, key])
	var added: Array = specs.duplicate(true)
	added[0]["unexpected_field"] = 0
	_check(var_to_bytes(specs) != var_to_bytes(added), "native extra schema field rejected")
	var reordered: Array = specs.duplicate(true)
	var first: Variant = reordered[0]
	reordered[0] = reordered[1]
	reordered[1] = first
	_check(var_to_bytes(specs) != var_to_bytes(reordered), "native declaration order remains exact")
	_check(GATE._v9c_uniform_error(saved, fresh, row).is_empty(), "all actual native values/texture full mips/schema record pass unchanged validator: " + row.path)
	# Captured first uniform negatives fail before any repeated large-image scan.
	for key: Variant in row.actual_uniforms[0].schema:
		for replacement: Variant in [true, "INCORRECT_FIELD_VALUE"]:
			var wrong: Dictionary = row.duplicate(true)
			wrong.actual_uniforms[0].schema[key] = replacement
			_check(not GATE._v9c_uniform_error(saved, fresh, wrong).is_empty(), "actual gate rejects captured schema type/value: " + str(key))
		var missing: Dictionary = row.duplicate(true)
		missing.actual_uniforms[0].schema.erase(key)
		_check(not GATE._v9c_uniform_error(saved, fresh, missing).is_empty(), "actual gate rejects missing captured schema field: " + str(key))
	for mode: String in ["extra_field", "missing_row", "extra_row", "wrong_order", "wrong_name", "wrong_variant_type", "not_array"]:
		var wrong: Dictionary = row.duplicate(true)
		match mode:
			"extra_field": wrong.actual_uniforms[0].schema["unexpected_field"] = 0
			"missing_row": wrong.actual_uniforms.pop_back()
			"extra_row": wrong.actual_uniforms.append(wrong.actual_uniforms[0].duplicate(true))
			"wrong_order":
				var first_record: Variant = wrong.actual_uniforms[0]
				wrong.actual_uniforms[0] = wrong.actual_uniforms[1]
				wrong.actual_uniforms[1] = first_record
			"wrong_name": wrong.actual_uniforms[0].name = "WRONG_UNIFORM"
			"wrong_variant_type": wrong.actual_uniforms[0].variant_type = TYPE_BOOL
			"not_array": wrong.actual_uniforms = {}
		_check(not GATE._v9c_uniform_error(saved, fresh, wrong).is_empty(), "actual ordered capture record strict negative: " + mode)
	fresh = null

func _run() -> void:
	var pins: Dictionary = MATERIALS.duplicate()
	pins[GATE_PATH] = GATE_SHA
	pins[PROBE_PATH] = PROBE_SHA
	pins[REPORT_PATH] = REPORT_SHA
	pins[GATE.BASE_PATH] = GATE.BASE_SHA
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower() == String(pins[path]).to_lower(), "actual bound source/material/report: " + path)
	var parser: JSON = JSON.new()
	_check(parser.parse(FileAccess.get_file_as_string(REPORT_PATH)) == OK and parser.data is Dictionary, "actual report parses")
	if errors.is_empty():
		var records: Array = parser.data.v9c_revision_evidence.attached_material_creations
		_check(records.size() == 5, "initial plus four actual resource records")
		for index in range(1, records.size()):
			var row: Dictionary = records[index]
			_check(MATERIALS.get(row.path) == row.sha256, "actual capture record binds exact saved material")
			var saved: ShaderMaterial = ResourceLoader.load(row.path, "", ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
			_check(saved != null and saved.shader != null, "actual saved material/shader loads")
			if saved != null and saved.shader != null: _material_units(saved, row)
			saved = null
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower() == String(pins[path]).to_lower(), "actual bound source/material/report unchanged: " + path)
	print("V9E_UNIFORM_SCHEMA_EXACT_UNITS ", JSON.stringify({"scope": "READ_ONLY_ACTUAL_FOUR_MATERIAL_SCHEMA_UNIT_NOT_FACTORY_OR_PUBLISH_OR_FIELD", "checks": checks, "failures": errors.size(), "errors": errors, "ecology_executed": false, "material_factory_executed": false, "GPU_capture_executed": false, "Field_executed": false, "formal_cutover": false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
