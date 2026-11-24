extends "res://build/city_navigation_20261101d_residual04/residual_ROOT_ONLY.gd"
## Presentation-only: three public near views. No Docks request, no Space, no
## travel matrix, no camera writes. Existing four true directions are inherited.
const V5 := "res://build/city_navigation_20261101d_visual05/"
const V5_INPUTS := V5 + "visual_inputs_ROOT_READY.json"
var v5: Dictionary = {}

func run() -> void:
	directory = V5 + "actual/" + str(OS.get_process_id()); DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"VISUAL_ONLY05_EARLIEST_CHECKPOINT_SUSPEND"): finish(); return
	v5 = JSON.parse_string(FileAccess.get_file_as_string(V5_INPUTS)) as Dictionary
	if not need(v5.get("schema") == "CITY_NAVIGATION_20261101D_VISUAL_ONLY05_QA_V1" and v5.get("ready") == true,"ROOT_EXPLICIT_VISUAL_ONLY05_FREEZE"): finish(); return
	if not need(FileAccess.get_sha256(INPUTS) == v5.base_inputs_sha256 and FileAccess.get_sha256(RESIDUAL_INPUTS) == v5.parent_inputs_sha256 and FileAccess.get_sha256(MANIFEST) == v5.approved_candidate_manifest_sha256,"UNCHANGED_BASE_AND_PARENT_QA_INPUTS_AND_FROZEN96"): finish(); return
	if not need(FileAccess.get_sha256(R3_INPUTS) == v5.parent03_inputs_sha256,"ORIGINAL_RESIDUAL03_INPUTS_UNCHANGED"): finish(); return
	r3 = JSON.parse_string(FileAccess.get_file_as_string(R3_INPUTS)) as Dictionary
	cfg = JSON.parse_string(FileAccess.get_file_as_string(INPUTS)) as Dictionary
	residual = JSON.parse_string(FileAccess.get_file_as_string(RESIDUAL_INPUTS)) as Dictionary
	pins = cfg.get("source_pins",{}).duplicate(true)
	for path: String in residual.get("source_pins",{}):
		if not need(not pins.has(path) or pins[path] == residual.source_pins[path],"PARENT_QA_DOES_NOT_OVERRIDE_SOURCE_PIN:"+path): finish(); return
		pins[path] = residual.source_pins[path]
	for path: String in r3.get("source_pins",{}):
		if not need(not pins.has(path) or pins[path] == r3.source_pins[path],"RESIDUAL03_PIN_NOT_OVERRIDDEN:"+path): finish(); return
		pins[path] = r3.source_pins[path]
	for path: String in v5.required_source_paths:
		if not need(v5.get("source_pins",{}).has(path),"ROOT_EXPLICIT_VISUAL_ONLY05_PIN:"+path): finish(); return
	for path: String in v5.source_pins:
		var expected: String = String(v5.source_pins[path])
		if not need(path.begins_with("res://") and not ".." in path and expected.length() == 64 and (not pins.has(path) or pins[path] == expected),"VISUAL_ONLY05_DOES_NOT_OVERRIDE_FROZEN_PIN:"+path): finish(); return
		pins[path] = expected
	pins[INPUTS] = r3.base_inputs_sha256; pins[RESIDUAL_INPUTS] = r3.parent_inputs_sha256
	pins[R3_INPUTS] = v5.parent03_inputs_sha256
	pins[V5_INPUTS] = FileAccess.get_sha256(V5_INPUTS) # Also exact-pinned by Root outer launch.
	first = facts()
	for path: String in pins:
		if not need(path.begins_with("res://") and not ".." in path and first[path].sha256 == pins[path],"VISUAL_ONLY05_SOURCE_FIRST:"+path): finish(); return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)) as Dictionary
	if not need(manifest.get("ready") == true and manifest.get("source_pins",{}).size() == 96,"ORIGINAL96_LEAVES_UNCHANGED"): finish(); return
	router = root.get_node("SceneRouter"); host = root.get_node_or_null("CityNavigationRuntime")
	if not need(host != null and host.get_script().resource_path == HOST and ProjectSettings.get_setting("autoload/CityNavigationRuntime","") == "*"+HOST,"ACTUAL_UNCHANGED_HOST"): finish(); return
	pair_data = load(PAIRS) as GDScript
	var until := Time.get_ticks_msec()+3000
	while Time.get_ticks_msec() < until and host.call("get_debug_state").get("ready") != true: await process_frame
	r4 = v5
	if not _inherit_prefix() or not _inherit_market_artisan() or not _inherit_market_temple(): finish(); return

	records.append({"visual_only_no_new_travel":true,"Docks_requests":0,"World_requests":0,"inherited_true_directions":4,"normal_camera_unchanged":true,"source_checks_still_executed":true})
	var civic: Dictionary = _endpoint(_pair("market_artisan"),"a")
	var adults_ok: bool = await _civic_adults_near(civic)
	# Retain all three normal images even if a dimension/mini oracle fails.
	# A failed actual load is still terminal: never screenshot the wrong scene.
	if _physical(field) != civic.scene_id: finish(); return
	var mini_ok: bool = _mini_check()
	records.append({"civic_adult_check":adults_ok,"civic_mini_check":mini_ok,"no_extra_input_or_dialogue":true})
	if not await _capture("civic_blademaster_adult_and_services_minimap_normal"): finish(); return
	var south: Dictionary = _endpoint(_pair("docks_temple"),"b")
	if not await _near(south,south.arrival): finish(); return
	var zone: ExitZone = _zone(south)
	if need(zone != null,"ACTUAL_TEMPLE_SOUTH_ROADMOUTH_VISUAL_ONLY"):
		_actual_coherence(south,zone)
	if not await _capture("temple_south_roadmouth_minimap_normal"): finish(); return
	var temple: Dictionary = _endpoint(_pair("temple_riverside"),"a")
	var hall_foot := Vector2(cfg.temple_hall_foot[0],cfg.temple_hall_foot[1])
	if not await _near(temple,hall_foot): finish(); return
	var hall_ok: bool = _hall_check()
	records.append({"hall_existing_measurements":hall_ok,"all_checks_before_third_normal_image":true})
	if not await _capture("temple_scripture_hall_adult_scale_normal"): finish(); return
	finish()

func finish() -> void:
	if done: return
	done = true
	var final_sources: Dictionary = facts() if not pins.is_empty() else {}
	if not first.is_empty(): need(var_to_bytes(first) == var_to_bytes(final_sources),"VISUAL_ONLY05_SOURCE_FIRST_FINAL_EXACT")
	need(inputs == 0,"VISUAL_ONLY05_ZERO_PLAYER_INPUT_OR_ROUTE_TRAVEL")
	records.append({"scope":"THREE_NORMAL_PUBLIC_NEAR_VIEWS_ONLY_FOUR_TRUE_DIRECTIONS_INHERITED","inherited_true_directions":4 if inherited_temple else (2 if inherited_market else 0),"executed_true_directions":0,"Docks_requests":0,"World_requests":0,"no_camera_zoom_writes":true,"save_metadata_samples":0,"save_APIs":0,"userstate_reads_writes":0})
	var result: Dictionary = {"passed":errors.is_empty(),"checks":checks,"errors":errors,"input_events":inputs,"normal_images":images,"inherited_true_directions":4 if inherited_temple else (2 if inherited_market else 0),"executed_true_directions":0,"visual_only":true,"records":records,"source_first":first,"source_final":final_sources,"checkpoint_suspended":suspended,"root_only":true}
	var file := FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result,"\t")+"\n")
	print("CITYNAV31D_VISUAL_ONLY05 ",JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"inputs":inputs,"images":images,"Docks_requests":0,"result":directory+"/result.json"}))
	quit(0 if errors.is_empty() else 1)
