extends SceneTree
## READ ONLY revision-tail consumer units. Directly consume the exact saved RF;
## do NOT reconstruct ecology, authored RF formula, control maps or materials.
## The complete publisher/revision must still reconstruct and validate all.
const GATE = preload("res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd")
const GATE_PATH := "res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd"
const GATE_SHA := "460fb5d0dad60917429a169e4be502894a156a1ac4ed88fbdfb50153ef3376c2"
const SOURCE_PATH := "res://data/maps/world_map_v15_complete_v9c_source.json"
const SOURCE_SHA := "85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f"
const MANIFEST_PATH := "res://art/maps/world_map_v15_complete_v9c/art_contract.json"
const MANIFEST_SHA := "1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a"
const REPORT_PATH := "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const REPORT_SHA := "cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851"
var checks: int = 0
var errors: Array[String] = []
var body_failures: Array[Dictionary] = []
var caster_failures: Array[Dictionary] = []
var checked_body_count: int = 0
var checked_caster_count: int = 0
var v8_count: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func _read(path: String) -> Dictionary:
	var parser: JSON = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary: return {}
	return parser.data

func _bind(path: String, catalog: Dictionary, pins: Dictionary) -> void:
	if pins.has(path): return
	_check(GATE._bound(catalog, path) and GATE._same_hash(catalog.get(path), FileAccess.get_sha256(path)), "actual consumed file/catalog SHA: " + path)
	if GATE._bound(catalog, path): pins[path] = catalog[path]

func _record(stage: String, id: String, error: String) -> void:
	_check(error.is_empty(), stage + "/" + id + ": " + error)
	if not error.is_empty():
		var row: Dictionary = {"id": id, "error": error}
		if stage == "body": body_failures.append(row)
		else: caster_failures.append(row)

func _v8_negatives(body: Dictionary, catalog: Dictionary, receiver) -> void:
	_check(not body.has("collision_size") and body.blocking == false and GATE._pair_eq(body.collision_size_px, Vector2.ZERO), "actual frozen writer absent normalized field/nonblocking/zero physical size: " + str(body.id))
	# Earlier metadata association also remains mandatory. Mutated dictionaries
	# must fail the real full-body validator, never be silently defaulted to zero.
	for invalid: Variant in [null, [0.0, 0.0], [1.0, 0.0], "0,0", true]:
		var wrong: Dictionary = body.duplicate()
		wrong["collision_size"] = invalid
		_check(wrong.has("collision_size") and not GATE._v7_body_error(wrong, catalog, receiver).is_empty(), "explicit normalized field null/zero/nonzero/type rejected: " + str(body.id))

func _run() -> void:
	var pins: Dictionary = {GATE_PATH:GATE_SHA, SOURCE_PATH:SOURCE_SHA, MANIFEST_PATH:MANIFEST_SHA, REPORT_PATH:REPORT_SHA}
	for path: String in GATE.EXACT_INPUTS: pins[path] = GATE.EXACT_INPUTS[path]
	pins[GATE.BASE_PATH] = GATE.BASE_SHA
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower() == String(pins[path]).to_lower(), "actual frozen source pin: " + path)
	var source: Dictionary = _read(SOURCE_PATH)
	var manifest: Dictionary = _read(MANIFEST_PATH)
	var report: Dictionary = _read(REPORT_PATH)
	_check(not source.is_empty() and not manifest.is_empty() and not report.is_empty(), "actual frozen S/M/report dictionaries")
	if errors.is_empty():
		GATE._report = report
		GATE._v7_tiles.clear()
		GATE._v7_tile_order.clear()
		GATE._v7_plane_validation.clear()
		var catalog: Dictionary = manifest.asset_sha256
		var graph: Dictionary = manifest.capture_graph
		var rf_path: String = graph.height_rf.path
		_bind(rf_path, catalog, pins)
		_check(GATE._same_hash(graph.height_rf.sha256, catalog.get(rf_path)) and GATE._same_hash(GATE.DERIVED_INPUTS.height_rf.sha256, catalog.get(rf_path)), "actual RF graph/derived/catalog binding")
		var raw: PackedByteArray = FileAccess.get_file_as_bytes(rf_path)
		_check(raw.size() == 1537 * 1025 * 4, "actual complete native RF byte length")
		var receiver = GATE.ECOLOGY.new()
		receiver.heights = raw.to_float32_array()
		_check(receiver.heights.to_byte_array() == raw, "read-only RF consumer exact stored Float32, not authored regeneration")
		for r in 8:
			for c in 8: _bind(GATE.ROOT + "chunks/r%d_c%d_raw_walk.png" % [r, c], catalog, pins)
		var objects: Array[Dictionary] = []
		var native: Dictionary = {}
		var counts: Dictionary = {"tree":0, "bamboo":0, "herb":0, "boulder":0}
		for body: Dictionary in source.objects:
			objects.append(body)
			if body.get("kind") not in counts: continue
			var id: String = body.id
			_check(not native.has(id), "native body id unique: " + id)
			native[id] = body
			counts[body.kind] += 1
			var prototype: Dictionary = body.prototype_actual_sourcebody_evidence
			var origin: Dictionary = prototype.sourcebody_capture_origin
			for path: String in [body.metadata_path, body.texture, prototype.texture, origin.original_metadata_path, origin.original_metadata_copy_path]: _bind(path, catalog, pins)
			checked_body_count += 1
			_record("body", id, GATE._v7_body_error(body, catalog, receiver))
			if id.begins_with("v8_"):
				v8_count += 1
				_v8_negatives(body, catalog, receiver)
		_check(objects.size() == 2687 and native.size() == 2578 and v8_count == 77, "complete source/native/V8 population, not first-herb spot check")
		_check(GATE._equal_exact_value(counts, source.v7_revision_evidence.ecology.actual_registered_counts), "actual entire native population matches recorded counts")
		_check(GATE._equal_exact_value(counts, {"tree":655, "bamboo":1517, "herb":360, "boulder":46}), "current exact native population identities")
		print("V9E_TAIL_ALL_BODIES ", JSON.stringify({"checked":checked_body_count, "v8_absent":v8_count, "counts":counts, "failures":body_failures}))
		for identity: String in ["primary", "reference"]:
			var seen: Dictionary = {}
			var casters: Array = report.worlds[identity].casters
			for record: Dictionary in casters:
				var id: String = record.id
				_check(native.has(id) and not seen.has(id), "actual caster current id/exactly once: " + identity + "/" + id)
				seen[id] = true
				_bind(record.actual_draw_mesh_path, catalog, pins)
				if native.has(id):
					checked_caster_count += 1
					_record(identity, id, GATE._v7_caster_error(native[id], record, catalog, receiver))
			_check(seen.size() == native.size(), "every native body has actual caster in " + identity)
		_check(checked_caster_count == 5156, "both complete current per-id caster populations")
		print("V9E_TAIL_ALL_CASTERS ", JSON.stringify({"checked":checked_caster_count, "validated_plane_meshes":GATE._v7_plane_validation.size(), "failures":caster_failures}))
		var planes: Array = []
		for caster: Dictionary in report.worlds.reference.casters:
			if caster.get("identity") != "V7_ACTUAL_PROTOTYPE_RGBA_CAMERA_PLANE_CASTER_SOURCE_ONLY": continue
			var original: Dictionary = caster.duplicate(true)
			for key: String in ["id", "kind", "pose", "source_foot_px", "transform", "shadow_on_enum", "sourcebody_baked"]: original.erase(key)
			planes.append(original)
		_check(GATE._equal_exact_value(planes, source.v7_revision_evidence.actual_plane_casters), "all reference plane records match actual source evidence")
		var union: Dictionary = receiver.measure_v7_alpha_union(objects)
		_check(GATE._true(union.get("passed")) and GATE._json_native_exact(source.v7_revision_evidence.get("actual_alpha_union"), union) and GATE._json_native_exact(report.get("alpha_union"), union), "actual four-region source PNG union binds FULL source/report")
		_check(union.get("regions") is Array and union.regions.size() == 4, "all four actual union regions")
		for region: Dictionary in union.get("regions", []):
			_check(GATE._true(region.get("passed")) and GATE._num(region.get("alpha_threshold_byte"), 30) and GATE._num(region.get("minimum_exclusive"), .08) and GATE._positive(region.get("actual_union_fraction")) and float(region.actual_union_fraction) > .08, "unchanged strict >8% actual alpha union: " + str(region.id))
		print("V9E_TAIL_ALL_UNIONS ", JSON.stringify({"regions":union.get("regions"), "passed":union.get("passed"), "exact_source_writer_equal":GATE._json_native_exact(source.v7_revision_evidence.get("actual_alpha_union"), union), "exact_report_writer_equal":GATE._json_native_exact(report.get("alpha_union"), union)}))
		_check(receiver.vertex_cache.is_empty(), "complete stored RF consumed, no lazy authored-height fallback")
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower() == String(pins[path]).to_lower(), "actual consumed input unchanged after unit: " + path)
	print("V9E_BODY_CASTER_TAIL_READONLY_UNITS ", JSON.stringify({"scope":"READ_ONLY_COMPLETE_REVISION_TAIL_CONSUMER_NOT_RF_RECONSTRUCTION_OR_PUBLISH", "checks":checks, "failures":errors.size(), "errors":errors, "body_count":checked_body_count, "caster_count":checked_caster_count, "v8_count":v8_count, "consumed_files_bound_and_rechecked":pins.size(), "ecology_prepared":false, "RF_formula_reconstructed":false, "maps_materials_reconstructed":false, "GPU_capture_executed":false, "Field_executed":false, "formal_cutover":false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
