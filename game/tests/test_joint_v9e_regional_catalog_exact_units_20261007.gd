extends SceneTree
## READ ONLY fixed regional catalog closure units. No ecology, ROI recapture,
## approval, formal writes or publication. Full ROI predicates remain in gate.
const GATE = preload("res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd")
const GATE_PATH := "res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd"
const GATE_SHA := "02698bb35b27de82e3fbda9a75c0922b4a7f0575a283acaee39fd6f489e8ae1a"
const SOURCE_PATH := "res://data/maps/world_map_v15_complete_v9c_source.json"
const SOURCE_SHA := "85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f"
const MANIFEST_PATH := "res://art/maps/world_map_v15_complete_v9c/art_contract.json"
const MANIFEST_SHA := "1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a"
const REPORT_PATH := "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const REPORT_SHA := "cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851"
const RESULT_PATH := "res://build/world_map_v15_coherent_whole_v9c_regional/v9d_broad_soft/1791137714_2690526/result.json"
const RESULT_SHA := "fe50ec4312753bd62eee0e4c62a1944dfb29859e6f339e04282dc05864f960d0"
var checks: int = 0
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func _read(path: String) -> Dictionary:
	var parser: JSON = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary: return {}
	return parser.data

func _refused(result: Dictionary, catalog: Dictionary, source: Dictionary, label: String, path: String = RESULT_PATH) -> void:
	var outcome: Dictionary = GATE._regional_catalog_records(result, path, catalog, source)
	_check(not outcome.has("catalog") and not String(outcome.get("error", "")).is_empty(), label)

func _run() -> void:
	var pins: Dictionary = {GATE_PATH: GATE_SHA, SOURCE_PATH: SOURCE_SHA, MANIFEST_PATH: MANIFEST_SHA, REPORT_PATH: REPORT_SHA, RESULT_PATH: RESULT_SHA}
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower() == pins[path], "actual frozen unit source: " + path)
	var source: Dictionary = _read(SOURCE_PATH)
	var manifest: Dictionary = _read(MANIFEST_PATH)
	var report: Dictionary = _read(REPORT_PATH)
	var result: Dictionary = _read(RESULT_PATH)
	_check(not source.is_empty() and not manifest.is_empty() and not report.is_empty() and not result.is_empty(), "actual four frozen JSON dictionaries")
	if errors.is_empty():
		var catalog: Dictionary = manifest.asset_sha256
		var before: PackedByteArray = var_to_bytes(catalog)
		var closure: Dictionary = GATE._regional_catalog_view(result, RESULT_PATH, catalog)
		_check(closure.has("catalog") and closure.get("added") == 2307 and closure.get("ROI_PNGs") == 240 and closure.get("alpha_PNGs") == 2063 and closure.get("materials") == 4, "actual fixed 240/2063/4 closure, every actual digest checked")
		_check(closure.get("catalog", {}).size() == catalog.size() + 2307 and var_to_bytes(catalog) == before, "private view adds exact keys without mutating FULL catalog")
		if closure.has("catalog"):
			for path: String in catalog: _check(closure.catalog.get(path) == catalog[path], "all original FULL catalog entries preserved: " + path)
		var wrong: Dictionary = result.duplicate(true)
		wrong.worlds.primary.roles.visual.windows.farmland.path = "res://art/maps/world_map_v15_complete_v9c/overview.png"
		_refused(wrong, catalog, source, "wrong prefix rejected")
		wrong = result.duplicate(true)
		wrong.worlds.primary.roles.visual.windows.farmland.path = RESULT_PATH.get_base_dir() + "/primary/../primary/visual_farmland_pass0.png"
		_refused(wrong, catalog, source, "path traversal spelling rejected despite same target")
		wrong = result.duplicate(true)
		wrong.worlds.primary.roles.visual.windows.farmland = wrong.worlds.primary.roles.land.windows.farmland.duplicate(true)
		_refused(wrong, catalog, source, "cross-role actual existing PNG substitution rejected")
		wrong = result.duplicate(true)
		wrong.worlds.primary.roles.visual.windows.farmland.sha256 = "0".repeat(64)
		_refused(wrong, catalog, source, "incorrect actual ROI digest rejected")
		for mode: String in ["missing", "extra", "duplicate", "wrong_pass"]:
			wrong = result.duplicate(true)
			var windows: Dictionary = wrong.worlds.primary.roles.visual.windows
			match mode:
				"missing": windows.erase("farmland")
				"extra": windows["unapproved_ROI"] = windows.farmland.duplicate(true)
				"duplicate": windows.marsh = windows.farmland.duplicate(true)
				"wrong_pass": windows.farmland.repeat_transfer_evidence = windows.farmland.duplicate(true)
			_refused(wrong, catalog, source, "exact ROI coverage negative: " + mode)
		var override: Dictionary = catalog.duplicate()
		override[result.worlds.primary.roles.visual.windows.farmland.path] = result.worlds.primary.roles.visual.windows.farmland.sha256
		_refused(result, override, source, "FULL catalog key cannot be overridden even with same digest")
		_refused(result, catalog, source, "other result domain rejected", RESULT_PATH.replace("1791137714_2690526", "other_capture"))
		var first_alpha: Dictionary = result.alpha_union.regions[0].actual_sourcebody_sha256
		var alpha_path: String = first_alpha.keys()[0]
		var alpha_id: String = alpha_path.get_file().get_basename()
		var canonical: String = GATE.ROOT + "entities/" + alpha_id + ".png"
		for mode: String in ["prefix", "id", "missing", "extra", "sha", "duplicate_region"]:
			wrong = result.duplicate(true)
			var images: Dictionary = wrong.alpha_union.regions[0].actual_sourcebody_sha256
			var digest: String = images[alpha_path]
			match mode:
				"prefix":
					images.erase(alpha_path)
					images[alpha_path.replace("/evidence/entities/", "/evidence/../evidence/entities/")] = digest
				"id":
					images.erase(alpha_path)
					images[alpha_path.replace(alpha_id + ".png", "UNKNOWN_ID.png")] = digest
				"missing": images.erase(alpha_path)
				"extra": images[alpha_path + ".extra"] = digest
				"sha": images[alpha_path] = "0".repeat(64)
				"duplicate_region": wrong.alpha_union.regions[1].id = wrong.alpha_union.regions[0].id
			_refused(wrong, catalog, source, "alpha same-id coverage negative: " + mode)
		var unbound: Dictionary = catalog.duplicate()
		unbound.erase(canonical)
		_refused(result, unbound, source, "current canonical FULL texture must remain bound")
		var changed_source: Dictionary = source.duplicate(true)
		for row: Dictionary in changed_source.objects:
			if row.id == alpha_id: row.texture = GATE.ROOT + "entities/WRONG_CANONICAL.png"
		_refused(result, catalog, changed_source, "same-id source cannot point at another canonical texture")
		var changed_record: Dictionary = result.duplicate(true)
		changed_record.worlds.primary.roles.visual.windows.farmland.sha256 = "0".repeat(64)
		_check(not GATE._regional_catalog_view(changed_record, RESULT_PATH, catalog).has("catalog"), "production wrapper rejects dictionary not associated with actual SHA-bound result")
		for mode: String in ["path", "kind", "sha", "missing", "extra"]:
			wrong = result.duplicate(true)
			var materials: Array = wrong.v9c_revision_evidence.attached_material_creations
			match mode:
				"path": materials[1].path = materials[3].path
				"kind": materials[1].kind = "water"
				"sha": materials[1].sha256 = "0".repeat(64)
				"missing": materials.pop_back()
				"extra": materials.append(materials[1].duplicate(true))
			_refused(wrong, catalog, source, "four actual material fixed domain negative: " + mode)
		var regional_materials: Array = result.v9c_revision_evidence.attached_material_creations
		var full_materials: Array = report.v9c_revision_evidence.attached_material_creations
		for index in range(1, 5):
			var regional: ShaderMaterial = ResourceLoader.load(regional_materials[index].path, "", ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
			var full: ShaderMaterial = ResourceLoader.load(full_materials[index].path, "", ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
			_check(regional != null and full != null and regional.shader != null and full.shader != null, "actual regional/FULL native material pair loads")
			if regional != null and full != null and regional.shader != null and full.shader != null:
				_check(regional.shader.code == full.shader.code and GATE._v9c_uniform_error(regional, full, regional_materials[index]).is_empty(), "actual native code/schema/values/all texture mips match current FULL: " + str(index))
			regional = null
			full = null
		_check(var_to_bytes(catalog) == before, "all negative targets were memory-only; FULL catalog unchanged")
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower() == pins[path], "actual frozen unit source unchanged: " + path)
	print("V9E_REGIONAL_CATALOG_EXACT_UNITS ", JSON.stringify({"scope": "READ_ONLY_FIXED_REGIONAL_CATALOG_UNIT_NOT_FULL_ROI_OR_FIELD_OR_PUBLISH", "checks": checks, "failures": errors.size(), "errors": errors, "ecology_executed": false, "GPU_capture_executed": false, "Field_executed": false, "formal_cutover": false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
