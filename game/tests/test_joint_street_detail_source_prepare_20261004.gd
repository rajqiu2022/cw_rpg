extends SceneTree
## Read-only stored city preparation/compile, never Field or formal approval.
const CITY = preload("res://scripts/city/luoyang_layered_v3_street_detail_candidate_contract.gd")
const CHECKER = preload("res://scripts/dev/luoyang_v3_street_detail_material_checker.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var paths: Array[String] = [
		"res://tests/helpers/joint_v15_v7_source_context_oracle.gd",
		"res://tests/helpers/joint_v15_v7_world_prepared_phase.gd",
		"res://tests/helpers/joint_v15_world_artifact_semantics_v7_probe.gd",
		"res://tests/helpers/joint_v15_street_detail_city_prepared_phase.gd",
		"res://tests/helpers/joint_v15_street_detail_city_gameplay_lifecycle_grace_phase.gd"]
	for path: String in paths:
		var script: GDScript = load(path) as GDScript
		if script == null or not script.can_instantiate():
			failures += 1
			push_error("Compile failed: " + path)
	for id: String in CITY.LEGACY_SHAS:
		var ok: bool = CITY.prepare(StringName(id))
		print("CITY_STORED_PREPARE ", id, " ", ok)
		if not ok:
			failures += 1
			push_error("Stored city preparation: " + str(CITY.errors()))
	for frame in 4: await process_frame
	print("READ_ONLY_CITY_SOURCE_PREPARE failures=", failures, " NO_FIELD_OR_FORMAL_APPROVAL")
	quit(0 if failures == 0 else 1)
