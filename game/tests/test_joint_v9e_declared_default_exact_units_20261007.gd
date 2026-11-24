extends SceneTree
## READ ONLY exact single declared default units with the real E factory.
## No ecology/map/mesh/capture/publish/formal writes. Saved and record predicates unchanged.
const GATE = preload("res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd")
const GATE_PATH := "res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd"
const GATE_SHA := "7de74b5a3eafa62475c456a0828a2a06e02b258d664a51652850b07adeb8bdcd"
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

var checks: int = 0

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func _copy(material: ShaderMaterial) -> ShaderMaterial:
	# Material parameters are independent; frozen actual shader/textures shared.
	return material.duplicate(false) as ShaderMaterial

func _adjacent_float(value: float, step: int) -> float:
	var bytes: PackedByteArray = PackedFloat32Array([value]).to_byte_array()
	bytes.encode_u32(0, bytes.decode_u32(0) + step)
	return bytes.decode_float(0)

func _inspect(saved: ShaderMaterial, fresh: ShaderMaterial, row: Dictionary, index: int) -> void:
	var code: String = fresh.shader.code
	if row.kind == "terrain":
		_check(code.count("world_size") == 1, "actual current terrain does not consume world_size elsewhere")
		var declared: Variant = GATE._v9c_declared_world_size(code)
		_check(declared is Vector2 and var_to_bytes(declared) == var_to_bytes(Vector2(12288, 8192)), "independent frozen literal equals native C.SIZE")
		var before: Variant = fresh.get_shader_parameter("world_size")
		_check(before == null or (typeof(before) == TYPE_VECTOR2 and var_to_bytes(before) == var_to_bytes(declared)), "actual unmodified factory implicit default is null or exact declared native value")
		_check(GATE._v9c_expected_world_size_error(fresh).is_empty(), "single expected default reconstructed without reading saved/record")
		_check(typeof(fresh.get_shader_parameter("world_size")) == TYPE_VECTOR2 and var_to_bytes(fresh.get_shader_parameter("world_size")) == var_to_bytes(declared), "exact expected Vector2, no generic type waiver")
		_check(GATE._v9c_expected_world_size_error(fresh).is_empty(), "already exact explicit expected value remains valid")
		for changed_code: String in [code.replace("world_size", "world_extent"), code.replace("vec2(12288.,8192.)", "vec2(12289.,8192.)"), code.replace("uniform vec2 world_size", "uniform ivec2 world_size"), code + "\nuniform vec2 world_size=vec2(12288.,8192.);", code + "\n// different full shader"]:
			_check(GATE._v9c_declared_world_size(changed_code) == null, "wrong name/default/type/duplicate/fullcode rejected without compiling malformed shader")
		for invalid: Variant in [Vector2i(12288, 8192), [12288, 8192], "12288,8192", true, 0.0, Vector2(12289, 8192), Vector2(12288, 8193), Vector2(NAN, 8192), Vector2(INF, 8192)]:
			var wrong: ShaderMaterial = _copy(fresh)
			wrong.set_shader_parameter("world_size", invalid)
			_check(not GATE._v9c_expected_world_size_error(wrong).is_empty(), "wrong non-null explicit expected value is never overwritten")
		for axis in 2:
			for step: int in [-1, 1]:
				var adjacent: Vector2 = Vector2(12288, 8192)
				adjacent[axis] = _adjacent_float(adjacent[axis], step)
				var wrong_expected: ShaderMaterial = _copy(fresh)
				wrong_expected.set_shader_parameter("world_size", adjacent)
				_check(not GATE._v9c_expected_world_size_error(wrong_expected).is_empty(), "one native Float32 ULP explicit expected refused")
				var wrong_saved: ShaderMaterial = _copy(saved)
				wrong_saved.set_shader_parameter("world_size", adjacent)
				_check(not GATE._v9c_uniform_error(wrong_saved, fresh, row).is_empty(), "one native Float32 ULP actual saved refused by unchanged strict uniform gate")
	_check(GATE._v9c_uniform_error(saved, fresh, row).is_empty(), "real factory versus actual saved native code/schema/58 total parameters/fullmips " + str(index))
	var specs: Array = saved.shader.get_shader_uniform_list()
	_check(row.actual_uniforms.size() == specs.size(), "all actual parameters have captured rows")
	for sid in specs.size():
		var name: String = String(specs[sid].name)
		var record: Dictionary = row.actual_uniforms[sid]
		var value: Variant = saved.get_shader_parameter(name)
		var actual: Variant = fresh.get_shader_parameter(name)
		_check(typeof(value) == typeof(actual), "every actual/factory parameter native type " + name)
		if not value is Resource:
			_check(var_to_bytes(value) == var_to_bytes(actual) and GATE._same_hash(record.get("native_variant_bytes_sha256"), GATE._bytes_sha(var_to_bytes(value))) and record.get("value_as_text") == str(value), "every nontexture actual/factory/record native byte and text " + name)
		# Other 56 parameters are exhaustively positive above and in ROOT287/288;
		# target only this repair with negatives, avoiding repeated PBR mip scans.
		if name == "world_size":
			var wrong_row: Dictionary = row.duplicate(true)
			wrong_row.actual_uniforms[sid].name = name + "_WRONG"
			_check(not GATE._v9c_uniform_error(saved, fresh, wrong_row).is_empty(), "wrong record name refused " + name)
			wrong_row = row.duplicate(true)
			wrong_row.actual_uniforms[sid].variant_type = -1
			_check(not GATE._v9c_uniform_error(saved, fresh, wrong_row).is_empty(), "wrong record native type refused " + name)
			if not value is Resource:
				wrong_row = row.duplicate(true)
				wrong_row.actual_uniforms[sid].native_variant_bytes_sha256 = "0".repeat(64)
				_check(not GATE._v9c_uniform_error(saved, fresh, wrong_row).is_empty(), "wrong record native byte digest refused " + name)
				wrong_row = row.duplicate(true)
				wrong_row.actual_uniforms[sid].value_as_text = str(value) + "_WRONG"
				_check(not GATE._v9c_uniform_error(saved, fresh, wrong_row).is_empty(), "wrong record exact text refused " + name)
			var wrong_saved: ShaderMaterial = _copy(saved)
			wrong_saved.set_shader_parameter(name, "WRONG_NATIVE_TYPE")
			_check(not GATE._v9c_uniform_error(wrong_saved, fresh, row).is_empty(), "wrong actual saved value/type refused " + name)
			var wrong_fresh: ShaderMaterial = _copy(fresh)
			wrong_fresh.set_shader_parameter(name, "WRONG_NATIVE_TYPE")
			_check(not GATE._v9c_uniform_error(saved, wrong_fresh, row).is_empty(), "wrong current expected value/type refused " + name)
			var wrong_saved_integer: ShaderMaterial = _copy(saved)
			wrong_saved_integer.set_shader_parameter(name, Vector2i(12288, 8192))
			_check(not GATE._v9c_uniform_error(wrong_saved_integer, fresh, row).is_empty(), "equal-coordinate Vector2i actual saved is still rejected")
		observations.append({"material_index": index, "name": name, "actual_type": typeof(value), "factory_type": typeof(actual)})
	if row.kind == "terrain":
		var other_null: ShaderMaterial = _copy(fresh)
		other_null.set_shader_parameter("source_rect", null)
		_check(not GATE._v9c_uniform_error(saved, other_null, row).is_empty(), "no unrelated null uniform receives a waiver")
	_check(GATE._v9c_uniform_error(saved, fresh, row).is_empty(), "all negative targets were independent memory copies")
	print("V9E_DECLARED_DEFAULT_MATERIAL_COMPLETE ", JSON.stringify({"index": index, "kind": row.kind, "actual_parameters": specs.size(), "failures_so_far": errors.size()}))

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
	print("V9E_DECLARED_DEFAULT_EXACT_UNITS ", JSON.stringify({"scope": "READ_ONLY_SINGLE_DECLARED_DEFAULT_AND_REAL_FACTORY_UNITS_NOT_FULL_OR_FIELD_OR_PUBLISH", "display_server": DisplayServer.get_name(), "actual_cmdline": OS.get_cmdline_args(), "parameter_count": observations.size(), "checks": checks, "failures": errors.size(), "errors": errors, "diagnostic_completed": errors.is_empty(), "material_factory_executed": true, "ecology_executed": false, "map_reconstruction_executed": false, "GPU_capture_executed": false, "Field_executed": false, "formal_cutover": false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
