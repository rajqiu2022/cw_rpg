extends SceneTree
## Representation diagnostic only, not material acceptance/publish/Field.
## Loads actual four bound materials; no ecology/factory/map/capture execution.
const GATE = preload("res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd")
const GATE_PATH := "res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd"
const GATE_SHA := "eeee454a71337d509ec89b3bff19fd0224b5fd3c70d7abd0a27d0ad27b2b8ab1"
const REPORT_PATH := "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const REPORT_SHA := "cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851"
const MATERIALS := {
	"res://art/maps/world_map_v15_complete_v9c/capture/primary/actual_terrain_material.res": "4b8ec4571d316dfce70c893102c1191fbaf67b79286c1f655e5846db9da5e33a",
	"res://art/maps/world_map_v15_complete_v9c/capture/primary/actual_water_material.res": "87cedcb26ea48af86616f52a7b81b3e0c2b93c40bab5325e8d99a566bd07e750",
	"res://art/maps/world_map_v15_complete_v9c/capture/reference/actual_terrain_material.res": "0295ba8c077ae4545df1991bfaf18589396389a8fc9063ca0455b1ec264bddda",
	"res://art/maps/world_map_v15_complete_v9c/capture/reference/actual_water_material.res": "f47944f30905818ec7e451ca77f81e994d6f89ef705390ea82f0a6a9204d993b",
}
const CODES := {"terrain": "4b060ef119e340e6c1eaaa095623944d999312a56ab2508e1792f1b6994bbbeb", "water": "40192a289930ee9e0dabcfceeea494c04db6f2fd4ccee3d816481b01458b8a0c"}
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _sha(bytes: PackedByteArray) -> String:
	var hashing: HashingContext = HashingContext.new()
	if hashing.start(HashingContext.HASH_SHA256) != OK or hashing.update(bytes) != OK: return ""
	return hashing.finish().hex_encode()

func _field_types(spec: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: Variant in spec: result[String(key)] = {"type": typeof(spec[key]), "value": str(spec[key])}
	return result

func _run() -> void:
	var pins: Dictionary = MATERIALS.duplicate()
	pins[GATE_PATH] = GATE_SHA
	pins[REPORT_PATH] = REPORT_SHA
	pins[GATE.SURFACE_PATH] = GATE.EXACT_INPUTS[GATE.SURFACE_PATH]
	pins[GATE.BASE_PATH] = GATE.BASE_SHA
	for path: String in pins:
		if FileAccess.get_sha256(path).to_lower() != String(pins[path]).to_lower(): errors.append("Changed bound input: " + path)
	var parser: JSON = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(REPORT_PATH)) != OK or not parser.data is Dictionary: errors.append("Actual frozen report parse failed")
	var rows: Array = []
	if errors.is_empty():
		var records: Variant = parser.data.get("v9c_revision_evidence", {}).get("attached_material_creations")
		if not records is Array or records.size() != 5:
			errors.append("Actual initial plus four material records missing")
		else:
			for index in range(1, 5):
				var record: Dictionary = records[index]
				var path: String = record.path
				if not MATERIALS.has(path) or record.sha256 != MATERIALS[path] or not record.get("actual_uniforms") is Array:
					errors.append("Unbound actual material/record: " + path)
					continue
				var saved: ShaderMaterial = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
				if saved == null or saved.shader == null or _sha(saved.shader.code.to_utf8_buffer()) != CODES.get(record.kind):
					errors.append("Actual shader resource/code differs: " + path)
					continue
				var expected: Shader = Shader.new()
				expected.code = saved.shader.code # Same actual code; never fabricated schema.
				var specs: Array[Dictionary] = saved.shader.get_shader_uniform_list()
				var other: Array[Dictionary] = expected.get_shader_uniform_list()
				var summary: Dictionary = {"path": path, "kind": record.kind, "actual_record_count": record.actual_uniforms.size(), "saved_native_count": specs.size(), "same_code_fresh_native_count": other.size(), "native_direct_equal": GATE._equal_exact_value(specs, other), "native_vs_native_expected_json_equal": GATE._json_native_exact(specs, other), "native_variant_bytes_equal": var_to_bytes(specs) == var_to_bytes(other), "record_count_matches_saved": record.actual_uniforms.size() == specs.size()}
				rows.append(summary)
				print("V9E_UNIFORM_SCHEMA_DIAGNOSTIC_SUMMARY ", JSON.stringify(summary))
				for sid in maxi(specs.size(), record.actual_uniforms.size()):
					var spec: Dictionary = specs[sid] if sid < specs.size() else {}
					var fresh: Dictionary = other[sid] if sid < other.size() else {}
					var captured: Dictionary = record.actual_uniforms[sid] if sid < record.actual_uniforms.size() else {}
					var writer: Variant = JSON.parse_string(JSON.stringify(spec, "\t"))
					print("V9E_UNIFORM_SCHEMA_DIAGNOSTIC_FIELD ", JSON.stringify({"path": path, "index": sid, "captured_name": captured.get("name"), "native_fields": _field_types(spec), "fresh_native_fields": _field_types(fresh), "default_writer_fields": _field_types(writer) if writer is Dictionary else {}, "captured_schema_fields": _field_types(captured.get("schema", {})), "saved_vs_fresh_native_direct": GATE._equal_exact_value(spec, fresh), "saved_native_vs_fresh_json": GATE._json_native_exact(spec, fresh), "captured_vs_native_writer": GATE._json_native_exact(captured.get("schema"), spec), "captured_variant_type": captured.get("variant_type")}))
				expected = null
				saved = null
	for path: String in pins:
		if FileAccess.get_sha256(path).to_lower() != String(pins[path]).to_lower(): errors.append("Bound input changed after diagnostic: " + path)
	print("V9E_UNIFORM_SCHEMA_READONLY_DIAGNOSTIC ", JSON.stringify({"scope": "READ_ONLY_NATIVE_VS_JSON_SCHEMA_DIAGNOSTIC_NOT_ACCEPTANCE", "display_server": DisplayServer.get_name(), "actual_cmdline": OS.get_cmdline_args(), "rows": rows, "errors": errors, "diagnostic_completed": errors.is_empty(), "ecology_executed": false, "material_factory_executed": false, "Field_executed": false, "GPU_capture_executed": false, "formal_cutover": false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
