extends SceneTree
## READ ONLY real E factory diagnostics; no ecology/map/mesh reconstruction,
## capture, publisher, approval or formal write. Differences are observations,
## not accepted material equality. Production type/byte predicates unchanged.
const GATE = preload("res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd")
const GATE_PATH := "res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd"
const GATE_SHA := "02698bb35b27de82e3fbda9a75c0922b4a7f0575a283acaee39fd6f489e8ae1a"
const REPORT_PATH := "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const REPORT_SHA := "cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851"
const MANIFEST_PATH := "res://art/maps/world_map_v15_complete_v9c/art_contract.json"
const MANIFEST_SHA := "1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a"
const MATERIALS := {
	"res://art/maps/world_map_v15_complete_v9c/capture/primary/actual_terrain_material.res": "4b8ec4571d316dfce70c893102c1191fbaf67b79286c1f655e5846db9da5e33a",
	"res://art/maps/world_map_v15_complete_v9c/capture/primary/actual_water_material.res": "87cedcb26ea48af86616f52a7b81b3e0c2b93c40bab5325e8d99a566bd07e750",
	"res://art/maps/world_map_v15_complete_v9c/capture/reference/actual_terrain_material.res": "0295ba8c077ae4545df1991bfaf18589396389a8fc9063ca0455b1ec264bddda",
	"res://art/maps/world_map_v15_complete_v9c/capture/reference/actual_water_material.res": "f47944f30905818ec7e451ca77f81e994d6f89ef705390ea82f0a6a9204d993b",
}
var errors: Array[String] = []
var observations: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _read(path: String) -> Dictionary:
	var parser: JSON = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary: return {}
	return parser.data

func _describe(value: Variant) -> Dictionary:
	var result: Dictionary = {"variant_type": typeof(value), "value_as_text": str(value)}
	if value is Resource:
		result["resource_class"] = value.get_class()
		if value is Texture2D:
			var image: Image = value.get_image()
			if image != null:
				result["texture"] = {"width": image.get_width(), "height": image.get_height(), "format": image.get_format(), "mip_count": image.get_mipmap_count(), "RGBA_and_all_mips_sha256": GATE._bytes_sha(image.get_data())}
	else:
		result["native_variant_bytes_sha256"] = GATE._bytes_sha(var_to_bytes(value))
	return result

func _inspect(saved: ShaderMaterial, fresh: ShaderMaterial, row: Dictionary, index: int) -> void:
	var specs: Array = saved.shader.get_shader_uniform_list()
	var expected_specs: Array = fresh.shader.get_shader_uniform_list()
	var bare: ShaderMaterial = ShaderMaterial.new()
	bare.shader = Shader.new()
	bare.shader.code = fresh.shader.code
	print("V9E_FACTORY_UNIFORM_MATERIAL ", JSON.stringify({"index": index, "path": row.path, "kind": row.kind, "factory_code_sha256": GATE._bytes_sha(fresh.shader.code.to_utf8_buffer()), "actual_code_equal": saved.shader.code == fresh.shader.code, "native_schema_equal": var_to_bytes(specs) == var_to_bytes(expected_specs), "production_uniform_error": GATE._v9c_uniform_error(saved, fresh, row)}))
	if row.actual_uniforms.size() != specs.size():
		errors.append("Actual record/schema count differs: " + str(row.path))
		return
	for sid in specs.size():
		var name: String = String(specs[sid].name)
		var record: Dictionary = row.actual_uniforms[sid]
		var value: Variant = saved.get_shader_parameter(name)
		var expected: Variant = fresh.get_shader_parameter(name)
		var saved_details: Dictionary = _describe(value)
		var fresh_details: Dictionary = _describe(expected)
		var observation: Dictionary = {"material_index": index, "path": row.path, "name": name, "captured": record, "saved": saved_details, "actual_factory": fresh_details, "same_code_bare_shader_default": _describe(bare.get_shader_parameter(name)), "types_equal": typeof(value) == typeof(expected), "saved_record_type_equal": GATE._num(record.get("variant_type"), typeof(value))}
		if not value is Resource:
			observation["native_bytes_equal"] = var_to_bytes(value) == var_to_bytes(expected)
			observation["saved_record_bytes_equal"] = GATE._same_hash(record.get("native_variant_bytes_sha256"), saved_details.native_variant_bytes_sha256)
			observation["saved_record_text_equal"] = record.get("value_as_text") == str(value)
		else:
			observation["actual_texture_payload_equal"] = saved_details.get("texture") == fresh_details.get("texture")
		observations.append(observation)
		print("V9E_FACTORY_UNIFORM_PARAMETER ", JSON.stringify(observation))
	bare = null

func _run() -> void:
	var pins: Dictionary = MATERIALS.duplicate()
	pins[GATE_PATH] = GATE_SHA
	pins[REPORT_PATH] = REPORT_SHA
	pins[MANIFEST_PATH] = MANIFEST_SHA
	for path: String in GATE.EXACT_INPUTS: pins[path] = GATE.EXACT_INPUTS[path]
	pins[GATE.BASE_PATH] = GATE.BASE_SHA
	for path: String in pins:
		if FileAccess.get_sha256(path).to_lower() != String(pins[path]).to_lower(): errors.append("Actual diagnostic pin differs: " + path)
	var report: Dictionary = _read(REPORT_PATH)
	var manifest: Dictionary = _read(MANIFEST_PATH)
	var surface = GATE.SURFACE.new()
	if errors.is_empty() and not report.is_empty() and not manifest.is_empty():
		var catalog: Dictionary = manifest.asset_sha256
		var graph: Dictionary = manifest.capture_graph
		var maps: Dictionary = {}
		for id: String in ["ecology", "roads"]:
			var path: String = GATE.ROOT + "capture/" + id + "_reconstructed.png"
			if not GATE._bound(catalog, path) or not GATE._same_hash(catalog[path], FileAccess.get_sha256(path)):
				errors.append("Actual saved map is unbound: " + path)
				continue
			pins[path] = catalog[path]
			var image: Image = Image.load_from_file(path)
			if image == null or image.get_size() != Vector2i(3072, 2048) or image.has_mipmaps(): errors.append("Actual saved control map shape differs: " + path)
			else: maps[id] = ImageTexture.create_from_image(image)
		var rf_path: String = graph.height_rf.path
		if not GATE._bound(catalog, rf_path) or not GATE._same_hash(catalog[rf_path], FileAccess.get_sha256(rf_path)): errors.append("Actual RF texture bytes unbound")
		else: pins[rf_path] = catalog[rf_path]
		if not surface.load_sources(): errors.append("Actual factory registered PBR load failed: " + surface.error)
		for row: Dictionary in surface.evidence:
			for key: String in ["path", "source_path"]:
				var path: String = row[key]
				if not GATE._bound(catalog, path) or not GATE._same_hash(catalog[path], FileAccess.get_sha256(path)): errors.append("Actual factory PBR input unbound: " + path)
				else: pins[path] = catalog[path]
		if errors.is_empty():
			var rf_bytes: PackedByteArray = FileAccess.get_file_as_bytes(rf_path)
			if rf_bytes.size() != 1537 * 1025 * 4: errors.append("Actual RF byte length differs")
			else:
				var rf: ImageTexture = ImageTexture.create_from_image(Image.create_from_data(1537, 1025, false, Image.FORMAT_RF, rf_bytes))
				var initial: ShaderMaterial = surface.terrain_material(maps.ecology, maps.roads, Rect2(Vector2.ZERO, GATE.C.SIZE))
				if initial == null: errors.append("Actual initial factory construction failed: " + surface.error)
				var records: Array = report.v9c_revision_evidence.attached_material_creations
				if records.size() != 5: errors.append("Actual five creation records missing")
				if errors.is_empty():
					for index in range(1, 5):
						var row: Dictionary = records[index]
						var fresh: ShaderMaterial = surface.terrain_material(maps.ecology, maps.roads, Rect2(Vector2.ZERO, GATE.C.SIZE)) if index % 2 == 1 else surface.water_material(rf, Vector2i.ZERO, Vector2i(1537, 1025))
						var saved: ShaderMaterial = ResourceLoader.load(row.path, "", ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
						if fresh == null or saved == null or saved.shader == null or fresh.shader == null or not MATERIALS.has(row.path) or not GATE._same_hash(row.sha256, MATERIALS[row.path]): errors.append("Actual material/factory pair missing or changed")
						else: _inspect(saved, fresh, row, index)
						fresh = null
						saved = null
				initial = null
	else:
		errors.append("Diagnostic refused missing/changed frozen inputs")
	surface.release()
	for path: String in pins:
		if FileAccess.get_sha256(path).to_lower() != String(pins[path]).to_lower(): errors.append("Actual diagnostic input changed after read: " + path)
	print("V9E_FACTORY_UNIFORM_READONLY_DIAGNOSTIC ", JSON.stringify({"scope": "READ_ONLY_REAL_FACTORY_DIAGNOSTIC_NOT_MATERIAL_ACCEPTANCE", "display_server": DisplayServer.get_name(), "actual_cmdline": OS.get_cmdline_args(), "parameter_count": observations.size(), "errors": errors, "diagnostic_completed": errors.is_empty(), "material_factory_executed": true, "ecology_executed": false, "map_reconstruction_executed": false, "GPU_capture_executed": false, "Field_executed": false, "formal_cutover": false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
