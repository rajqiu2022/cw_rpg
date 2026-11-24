extends SceneTree
## Read-only actual bindings_report source consumer unit. Not RF derivation,
## renderer, Field or RELEASE acceptance. Frozen report cannot be injected into
## bindings_report: report-field negatives below explicitly exercise only its
## exact in-memory binding expression through the independent _equal predicate.
const PROBE = preload("res://tests/helpers/joint_v15_v9c_derived_geometry_probe.gd")
const HELPER := "res://tests/helpers/joint_v15_v9c_derived_geometry_probe.gd"
const SOURCE := "res://data/maps/world_map_v15_complete_v9c_source.json"
const MANIFEST := "res://art/maps/world_map_v15_complete_v9c/art_contract.json"
const FULL := "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const CPU := "res://build/world_map_v15_v9c_visual_quality_proposal/v9d_broad_soft/1791124651_1751026/derived_geometry/derivation_report.json"
const WRITER := "res://scripts/dev/build_world_map_v15_v9c_visual_quality_proposal_retry5.gd"
const PINS := {
	HELPER:"9cf95257e91c26571d87661aed3986cd037f35803e4b0bab9d723d4156697095",
	SOURCE:"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
	MANIFEST:"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
	FULL:"cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851",
	CPU:"707870fe709b12f9df4eeff76fb253b08c41631bc87065ab2d638828c674f1a0",
	WRITER:"27a2826b93453dc4b4d139b775a6c907a048996f758f87b983769648ec3e5596"
}
var checks := 0
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func _read(path: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary: return {}
	return parser.data

func _binding_expression(probe, full: Dictionary, inputs: Dictionary, audit: Dictionary) -> bool:
	# Exact expression of the repaired source consumer; no whole-report injection
	# API exists. These are local negative units, not altered on-disk captures.
	return probe._equal(full.get("derived_geometry_inputs"),inputs) and probe._equal(full.get("geometry_derivation_audit"),audit)

func _run() -> void:
	var pins: Dictionary = PINS.duplicate()
	for path: String in PROBE.BASE_PINS: pins[path] = PROBE.BASE_PINS[path]
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower() == String(pins[path]).to_lower(), "frozen actual input before: " + path)
	var source := _read(SOURCE)
	var manifest := _read(MANIFEST)
	var full := _read(FULL)
	var cpu := _read(CPU)
	_check(not source.is_empty() and not manifest.is_empty() and not full.is_empty() and not cpu.is_empty(), "actual bound S/M/FULL/CPU dictionaries")
	var actual_summary: Dictionary = {}
	var field_negative_checks := 0
	if errors.is_empty():
		var inputs: Dictionary = source.v9c_revision_evidence.derived_geometry_inputs
		var audit: Dictionary = cpu.audit
		_check(inputs.size() == 4 and inputs.derivation_report.path == CPU and inputs.derivation_report.sha256 == PINS[CPU] and audit.size() == 34, "actual four inputs and exact 34-key CPU audit")
		for role: String in PROBE.ROLES:
			pins[inputs[role].path] = inputs[role].sha256
			if role != "derivation_report": pins[PROBE.ROOT + {"height_rf":"terrain_height.rf","terrain_mesh":"terrain_mesh.res","source_topology":"source_topology.png"}[role]] = inputs[role].sha256
		for field: String in ["executed_helper","caller_source"]: pins[audit[field].path] = audit[field].sha256
		var probe = PROBE.new()
		var actual: Dictionary = probe.bindings_report(inputs,manifest,source)
		_check(actual.get("failed") == 0 and actual.get("complete") == true and actual.get("helper_or_builder_invoked") == false and actual.get("Field_input_executed") == false, "actual full bindings_report all source/runtime-copy branches pass without derivation")
		actual_summary = {"checks":actual.get("checks"),"failures":actual.get("failures"),"errors":actual.get("errors"),"complete":actual.get("complete"),"bound_roles":inputs.keys(),"audit_keys":audit.keys()}
		_check(not full.has("derived_geometry_audit") and full.has("geometry_derivation_audit"), "actual frozen writer top-level field, no invented alias fallback")
		_check(probe._equal(full.geometry_derivation_audit,audit) and probe._equal(full.v9c_revision_evidence.derived_geometry_audit,audit) and probe._equal(source.v9c_revision_evidence.derived_geometry_audit,audit), "all actual top/nested/source audits strictly equal original CPU audit, no JSON reencoding")
		_check(_binding_expression(probe,full,inputs,audit), "actual corrected full-report binding expression")
		var missing := full.duplicate()
		missing.erase("geometry_derivation_audit")
		_check(not _binding_expression(probe,missing,inputs,audit), "local expression missing required top audit rejects even with valid nested audit")
		var renamed := missing.duplicate()
		renamed["derived_geometry_audit"] = full.geometry_derivation_audit
		_check(not _binding_expression(probe,renamed,inputs,audit), "local expression wrong alias rejects, no fallback")
		for wrong: Variant in [null,true,"audit",[],{}]:
			var malformed := full.duplicate()
			malformed["geometry_derivation_audit"] = wrong
			_check(not _binding_expression(probe,malformed,inputs,audit), "local expression malformed audit type/shape rejects")
			field_negative_checks += 1
		for key: String in audit:
			var omitted: Dictionary = audit.duplicate()
			omitted.erase(key)
			var altered := full.duplicate()
			altered["geometry_derivation_audit"] = omitted
			_check(not _binding_expression(probe,altered,inputs,audit), "local expression every audit field mandatory: " + key)
			omitted[key] = null
			_check(not _binding_expression(probe,altered,inputs,audit), "local expression every audit value strictly bound: " + key)
			field_negative_checks += 2
		for role: String in PROBE.ROLES:
			var wrong_inputs := inputs.duplicate()
			wrong_inputs.erase(role)
			var bad_report := full.duplicate()
			bad_report["derived_geometry_inputs"] = wrong_inputs
			_check(not _binding_expression(probe,bad_report,inputs,audit), "local expression exact four original input roles: " + role)
			var negative_probe = PROBE.new()
			var negative: Dictionary = negative_probe.bindings_report(wrong_inputs,manifest,source)
			_check(int(negative.get("failed",0)) > 0 and negative.get("complete") == false, "actual bindings_report API rejects missing input role: " + role)
			negative_probe.release()
		probe.release()
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower() == String(pins[path]).to_lower(), "consumed frozen input unchanged after: " + path)
	print("V9E_DERIVED_BINDINGS_FIELD_CONTRACT_UNITS ",JSON.stringify({"scope":"READ_ONLY_ACTUAL_BINDINGS_REPORT_PLUS_LOCAL_FIELD_EXPRESSION_NEGATIVES_NOT_RELEASE_OR_GEOMETRY_RUN","checks":checks,"failures":errors.size(),"errors":errors,"actual_bindings_report":actual_summary,"local_audit_negative_count":field_negative_checks,"negative_report_injection_executed":false,"report_field_negative_scope":"EXACT_LOCAL_BINDING_EXPRESSION_ONLY","actual_missing_input_API_negatives":4,"consumed_files":pins.size(),"derived_RF_reconstructed":false,"builder_or_gate_invoked":false,"Field_executed":false,"formal_cutover":false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm",.15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
