extends "res://build/city_navigation_20261101d_qa01/finite_ROOT_ONLY.gd"
## QA-only label oracle correction. Original114340 whole FAIL and frozen96
## production leaves are preserved. Never re-execute proven static/Gate prefix.
const RESIDUAL := "res://build/city_navigation_20261101d_residual02/"
const RESIDUAL_INPUTS := RESIDUAL + "residual_inputs_ROOT_READY.json"
var residual: Dictionary = {}

func run() -> void:
	directory = RESIDUAL + "actual/" + str(OS.get_process_id()); DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"RESIDUAL02_EARLIEST_CHECKPOINT_SUSPEND_NO_USERSTATE"): finish(); return
	residual = JSON.parse_string(FileAccess.get_file_as_string(RESIDUAL_INPUTS)) as Dictionary
	if not need(residual.get("schema") == "CITY_NAVIGATION_20261101D_RESIDUAL02_QA_V1" and residual.get("ready") == true,"ROOT_EXPLICIT_RESIDUAL02_QA_PINS"): finish(); return
	if not need(FileAccess.get_sha256(INPUTS) == residual.base_inputs_sha256 and FileAccess.get_sha256(MANIFEST) == residual.approved_candidate_manifest_sha256,"ORIGINAL_QA_INPUTS_AND_FROZEN96_MANIFEST_UNCHANGED"): finish(); return
	cfg = JSON.parse_string(FileAccess.get_file_as_string(INPUTS)) as Dictionary
	pins = cfg.get("source_pins",{}).duplicate(true)
	for path: String in residual.required_source_paths:
		if not need(residual.get("source_pins",{}).has(path),"ROOT_EXPLICIT_RESIDUAL02_PIN:"+path): finish(); return
	for path: String in residual.source_pins:
		var expected: String = String(residual.source_pins[path])
		if not need(path.begins_with("res://") and not ".." in path and expected.length() == 64 and (not pins.has(path) or pins[path] == expected),"RESIDUAL02_NEVER_OVERRIDES_FROZEN_EXPECTED:"+path): finish(); return
		pins[path] = expected
	pins[INPUTS] = residual.base_inputs_sha256
	pins[RESIDUAL_INPUTS] = FileAccess.get_sha256(RESIDUAL_INPUTS) # Root launch also pins this JSON externally.
	first = facts()
	for path: String in pins:
		if not need(path.begins_with("res://") and not ".." in path and first[path].sha256 == pins[path],"RESIDUAL02_SOURCE_FIRST:"+path): finish(); return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)) as Dictionary
	if not need(manifest.get("ready") == true and manifest.get("source_pins",{}).size() == 96,"UNCHANGED_ORIGINAL_96_PRODUCTION_LEAVES"): finish(); return
	router = root.get_node("SceneRouter"); host = root.get_node_or_null("CityNavigationRuntime")
	if not need(host != null and host.get_script().resource_path == HOST and ProjectSettings.get_setting("autoload/CityNavigationRuntime","") == "*"+HOST,"ACTUAL_UNCHANGED_CITYNAV_AUTOLOAD"): finish(); return
	pair_data = load(PAIRS) as GDScript
	var until := Time.get_ticks_msec()+3000
	while Time.get_ticks_msec() < until and host.call("get_debug_state").get("ready") != true: await process_frame
	if not _inherit_prefix(): finish(); return
	# The public Region.start exact extension works without a legacy Gate near
	# context. Direct Civic near below is not a second Gate/bootstrap/travel test.
	for id: String in cfg.real_pair_ids:
		var pair: Dictionary = _pair(id)
		if not need(not pair.is_empty(),"EXACT_UNEXECUTED_FINITE_PAIR:"+id): finish(); return
		var a: Dictionary = _endpoint(pair,"a"); var b: Dictionary = _endpoint(pair,"b")
		if not await _near(a,a.arrival) or not await _cross(a): finish(); return
		if id == "docks_temple" and not await _capture("temple_south_roadmouth_minimap_normal"): finish(); return
		if not await _cross(b): finish(); return
		if id == "market_artisan":
			if not await _civic_adults_near(a) or not _mini_check() or not await _capture("civic_blademaster_adult_and_services_minimap_normal"): finish(); return
	var temple: Dictionary = _endpoint(_pair("temple_riverside"),"a")
	var hall_foot := Vector2(cfg.temple_hall_foot[0],cfg.temple_hall_foot[1])
	if not await _near(temple,hall_foot) or not _hall_check() or not await _capture("temple_scripture_hall_adult_scale_normal"): finish(); return
	finish()

func _inherit_prefix() -> bool:
	var path: String = String(residual.inherited_report)
	if not need(FileAccess.get_sha256(path) == residual.inherited_report_sha256,"IMMUTABLE_114340_WHOLE_FAIL_REPORT_PRESERVED"): return false
	var prior: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary
	if not need(prior.get("passed") == false and prior.get("checks") == 265 and prior.get("errors") == ["ACTUAL_TRIGGER_MARKER_MINI_TARGET_COHERENT:market_artisan:a"] and prior.get("input_events") == 0 and prior.get("normal_images") == 0,"EXACT_114340_QA_LABEL_ORACLE_FAILURE_ONLY_NO_REAL_PAIRS_EXECUTED"): return false
	var audits: Array = prior.get("records",[]).filter(func(row: Dictionary) -> bool: return row.has("static_only_no_travel"))
	var civic: Array = prior.get("records",[]).filter(func(row: Dictionary) -> bool: return row.get("public_near_setup_not_continuous_travel") == true and row.get("physical") == "luoyang_civic_market_region_27d" and row.get("logical") == "ch4_s3_luoyang_market")
	if not need(audits.size() == 1 and civic.size() == 1 and audits[0].static_only_no_travel.get("ok") == true and audits[0].static_only_no_travel.get("end_count") == 22 and audits[0].get("pair_source_sha256") == pins[PAIRS] and var_to_bytes(prior.get("source_first",{})) == var_to_bytes(prior.get("source_final",{})),"INHERIT_EXACT_STATIC22_SOURCE_PASS_AND_FROZEN_CONTROL_FLOW_GATE_PREFIX"): return false
	records.append({"inherited_not_reexecuted":["source checks in114340","static11pairs22safe_endpoints","directGate_bootstrap"],"report":path,"report_sha256":residual.inherited_report_sha256,"prior_whole_passed":false,"Gate_success_evidence":"immutable6e76_QA_control_flow_reached_Civic_near_after_successful_Gate_wait","new_source_FIRST_still_executed":true,"true_pair_directions_still_all_required":8,"sole_oracle_fix":"exact target-only Chinese destination label, not relation title"})
	return true

func _actual_coherence(endpoint: Dictionary, zone: ExitZone) -> bool:
	var metadata: Dictionary = zone.get_meta("citynav_endpoint",{})
	var source: Dictionary = host.call("get_debug_state").get("metadata",{})
	var rows: Array = source.get("portals",[]).filter(func(row: Dictionary) -> bool: return row.get("pair_id") == endpoint.pair_id and row.get("source_portal") == endpoint.source_portal)
	var visual: Sprite2D = zone.get_node_or_null("MarkerVisual") as Sprite2D
	var prompt: Label = zone.get_node_or_null("Prompt") as Label
	var collision: CollisionShape2D = zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var expected_label: String = "空格 · 前往" + String(pair_data.call("destination_name",String(endpoint.target.logical_id)))
	var ok: bool = zone.position.distance_to(endpoint.mouth) < .01 and zone.target_scene_id == endpoint.target.logical_id and metadata.get("mouth") == endpoint.mouth and rows.size() == 1 and rows[0].get("foot") == endpoint.mouth and rows[0].get("kind") == "area_exit"
	ok = ok and visual != null and prompt != null and prompt.text == zone.exit_label and zone.exit_label == expected_label and collision != null and collision.shape is RectangleShape2D and (collision.shape as RectangleShape2D).size == endpoint.activation_size
	records.append({"actual_zone_marker_label_cohere":ok,"pair":endpoint.pair_id,"side":endpoint.side,"zone":String(zone.get_path()),"zone_position":zone.position,"label":zone.exit_label,"expected_target_only_label":expected_label,"prompt":prompt.text if prompt != null else "","target":zone.target_scene_id,"marker_rotation":visual.rotation if visual != null else 0,"mini_rows":rows,"qa_oracle_only_corrected":true})
	return need(ok,"ACTUAL_TRIGGER_MARKER_MINI_TARGET_COHERENT:"+endpoint.pair_id+":"+endpoint.side)
