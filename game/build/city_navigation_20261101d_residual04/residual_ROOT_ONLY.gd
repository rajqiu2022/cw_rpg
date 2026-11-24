extends "res://build/city_navigation_20261101d_residual03/residual_ROOT_ONLY.gd"
## Root-only four remaining real directions. All load failures retain actual
## public/LoadingManager/Field/C/host/toast state before their oracle fires.
const R4 := "res://build/city_navigation_20261101d_residual04/"
const R4_INPUTS := R4 + "residual_inputs_ROOT_READY.json"
const C_DIAGNOSTIC := "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
var r4: Dictionary = {}
var inherited_temple := false
var qa4_toasts: Array[String] = []
var _contract_diagnostic: GDScript

func _early(node: Node) -> void:
	super._early(node)
	if node.name == &"EventBus" and node.has_signal("toast_requested") and not node.is_connected("toast_requested",_observe_toast):
		node.connect("toast_requested",_observe_toast)
func _observe_toast(message: String) -> void:
	qa4_toasts.append(message)
	if qa4_toasts.size() > 16: qa4_toasts.pop_front()
func _property(object: Object, key: String, fallback: Variant = null) -> Variant:
	if not is_instance_valid(object): return fallback
	for row: Dictionary in object.get_property_list():
		if String(row.name) == key: return object.get(key)
	return fallback
func _actual_wait_state(reason: String) -> Dictionary:
	var result: Dictionary = {"reason":reason,"msec":Time.get_ticks_msec(),"observed_toasts":qa4_toasts.duplicate(),"read_only":true}
	if is_instance_valid(router):
		result["public_preparation"] = router.call("get_public_city_preparation_state")
		result["current_logical"] = router.call("get_current_field_id")
		result["field_payload"] = router.call("get_field_payload")
	var loader: Node = root.get_node_or_null("LoadingManager")
	var loading: Dictionary = {}
	if loader != null:
		for key: String in ["_transition_active","_external_active","_finishing","_loading_path","_transition_kind","_transition_context","_started_msec","_field_preparation_token","_external_token","_handoff_progress"]:
			loading[key] = _property(loader,key)
		if loader.has_method("get_field_preload_metrics"): loading["preload_metrics"] = loader.call("get_field_preload_metrics")
		var screen: Node = _property(loader,"_screen") as Node
		var labels: Array[Dictionary] = []
		if is_instance_valid(screen):
			for label: Node in screen.find_children("*","Label",true,false):
				if label is Label and label.is_visible_in_tree() and not label.text.is_empty(): labels.append({"path":String(label.get_path()),"text":label.text.left(800)})
		loading["visible_status_labels"] = labels
	result["loading_manager"] = loading
	var current: Node = current_scene
	if is_instance_valid(current):
		var observed: Dictionary = {"instance":current.get_instance_id(),"path":String(current.get_path()),"script":current.get_script().resource_path if current.get_script() != null else "","physical":_physical(current),"queued_for_deletion":current.is_queued_for_deletion()}
		if current.has_method("get_field_loading_state"): observed["loading_state"] = current.call("get_field_loading_state")
		if current.has_method("get_field_loading_profile"): observed["loading_profile"] = current.call("get_field_loading_profile")
		for key: String in ["_scene_rebuilding","_field_loading_failed","_field_loading_complete","_field_loading_stage"]:
			observed[key] = _property(current,key)
		var actor: Node2D = _property(current,"_player") as Node2D
		if is_instance_valid(actor): observed["player"] = {"foot":actor.position,"can_move":_property(actor,"can_move")}
		var toast: Label = _property(current,"_feedback_toast") as Label
		if is_instance_valid(toast): observed["current_field_toast"] = {"text":toast.text,"visible":toast.is_visible_in_tree()}
		result["actual_current_field"] = observed
	if is_instance_valid(host): result["navigation_host"] = host.call("get_debug_state")
	if _contract_diagnostic == null: _contract_diagnostic = load(C_DIAGNOSTIC) as GDScript
	if _contract_diagnostic != null:
		# Only scalar read-only accessors. Never restart the2494 collector while
		# a source-validation worker is active. Root's separate static C/B probe
		# can identify the exact stale/missing source map when needed.
		result["C_errors"] = _contract_diagnostic.call("errors")
		result["C_transition"] = _contract_diagnostic.call("transition_validation_state")
	return result
func _retain_wait_state(reason: String) -> void:
	var state: Dictionary = _actual_wait_state(reason)
	records.append({"actual_loading_diagnostic_before_oracle":state})
	print("CITYNAV31D_LOAD_STATE ",JSON.stringify(state))
func need(ok: bool, label: String) -> bool:
	if not ok and is_instance_valid(router): _retain_wait_state("FAIL_BEFORE_ORACLE:"+label)
	return super.need(ok,label)

func _wait_field(previous: int, physical: String) -> bool:
	var limit := Time.get_ticks_msec()+30000
	var last_signature := ""
	var last_record := 0
	var observations := 0
	_retain_wait_state("WAIT_BEGIN:"+physical)
	while not done and Time.get_ticks_msec() < limit:
		await process_frame
		var candidate: Node = current_scene
		var preparation: Dictionary = router.call("get_public_city_preparation_state")
		var state: Dictionary = candidate.call("get_field_loading_state") if is_instance_valid(candidate) and candidate.has_method("get_field_loading_state") else {}
		var signature: String = var_to_str([preparation.get("phase"),preparation.get("error"),preparation.get("active"),_physical(candidate),state.get("stage"),state.get("failed"),_busy()])
		if observations < 24 and (signature != last_signature or Time.get_ticks_msec()-last_record >= 2000):
			last_signature=signature; last_record=Time.get_ticks_msec(); observations+=1
			_retain_wait_state("WAIT_PHASE:"+physical)
		if preparation.get("scene_id") == physical and preparation.get("active") == false and preparation.get("phase") in ["FAILED","REJECTED","CANCELLED"]:
			return need(false,"ACTUAL_PUBLIC_PREPARATION_FAILED:"+physical+":"+String(preparation.get("error","")))
		if not is_instance_valid(candidate) or candidate.get_instance_id() == previous or _physical(candidate) != physical: continue
		if state.get("failed") == true: return need(false,"ACTUAL_FIELD_LOAD_FAILED:"+physical)
		var actor: Node = candidate.get("_player")
		if state.get("complete") != true or candidate.get("_scene_rebuilding") == true or _busy() or not is_instance_valid(actor) or actor.get("can_move") != true: continue
		field=candidate
		var host_state: Dictionary = host.call("get_debug_state")
		if not String(host_state.get("last_error","")).is_empty(): return need(false,"ACTUAL_HOST_RUNTIME_ERROR:"+String(host_state.last_error))
		if host_state.get("ready") != true or host_state.get("metadata",{}).get("scene_id") != physical: continue
		var mini: Node = field.get("_world_travel_minimap") as Node
		var cache: Node = mini.get("_visual_cache") as Node if is_instance_valid(mini) else null
		if cache != null and cache.get("capture_ready") != true: continue
		await physics_frame; await RenderingServer.frame_post_draw
		_retain_wait_state("WAIT_SUCCESS:"+physical)
		return true
	# need() logs actual public/LM/Field/host/C/toast before recording timeout.
	return need(false,"ACTUAL_FIELD_FINITE_READY:"+physical)

func run() -> void:
	directory = R4 + "actual/" + str(OS.get_process_id()); DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"RESIDUAL04_EARLIEST_CHECKPOINT_SUSPEND"): finish(); return
	r4 = JSON.parse_string(FileAccess.get_file_as_string(R4_INPUTS)) as Dictionary
	if not need(r4.get("schema") == "CITY_NAVIGATION_20261101D_RESIDUAL04_QA_V1" and r4.get("ready") == true,"ROOT_EXPLICIT_RESIDUAL04_FREEZE"): finish(); return
	if not need(FileAccess.get_sha256(INPUTS) == r4.base_inputs_sha256 and FileAccess.get_sha256(RESIDUAL_INPUTS) == r4.parent_inputs_sha256 and FileAccess.get_sha256(MANIFEST) == r4.approved_candidate_manifest_sha256,"UNCHANGED_BASE_AND_PARENT_QA_INPUTS_AND_FROZEN96"): finish(); return
	if not need(FileAccess.get_sha256(R3_INPUTS) == r4.parent03_inputs_sha256,"ORIGINAL_RESIDUAL03_INPUTS_UNCHANGED"): finish(); return
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
	for path: String in r4.required_source_paths:
		if not need(r4.get("source_pins",{}).has(path),"ROOT_EXPLICIT_RESIDUAL04_PIN:"+path): finish(); return
	for path: String in r4.source_pins:
		var expected: String = String(r4.source_pins[path])
		if not need(path.begins_with("res://") and not ".." in path and expected.length() == 64 and (not pins.has(path) or pins[path] == expected),"RESIDUAL04_DOES_NOT_OVERRIDE_FROZEN_PIN:"+path): finish(); return
		pins[path] = expected
	pins[INPUTS] = r3.base_inputs_sha256; pins[RESIDUAL_INPUTS] = r3.parent_inputs_sha256
	pins[R3_INPUTS] = r4.parent03_inputs_sha256
	pins[R4_INPUTS] = FileAccess.get_sha256(R4_INPUTS) # Also exact-pinned by Root outer launch.
	first = facts()
	for path: String in pins:
		if not need(path.begins_with("res://") and not ".." in path and first[path].sha256 == pins[path],"RESIDUAL04_SOURCE_FIRST:"+path): finish(); return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)) as Dictionary
	if not need(manifest.get("ready") == true and manifest.get("source_pins",{}).size() == 96,"ORIGINAL96_LEAVES_UNCHANGED"): finish(); return
	router = root.get_node("SceneRouter"); host = root.get_node_or_null("CityNavigationRuntime")
	if not need(host != null and host.get_script().resource_path == HOST and ProjectSettings.get_setting("autoload/CityNavigationRuntime","") == "*"+HOST,"ACTUAL_UNCHANGED_HOST"): finish(); return
	pair_data = load(PAIRS) as GDScript
	var until := Time.get_ticks_msec()+3000
	while Time.get_ticks_msec() < until and host.call("get_debug_state").get("ready") != true: await process_frame
	if not _inherit_prefix() or not _inherit_market_artisan() or not _inherit_market_temple(): finish(); return
	# No static audit/Gate/bootstrap/market_artisan travel repeated. Do all real
	# unfinished legs before a visual/height oracle can stop this residual.
	for id: String in ["docks_temple","temple_riverside"]:
		var pair: Dictionary = _pair(id)
		if not need(not pair.is_empty(),"EXACT_UNFINISHED_PAIR:"+id): finish(); return
		var a: Dictionary = _endpoint(pair,"a"); var b: Dictionary = _endpoint(pair,"b")
		if not await _near(a,a.arrival) or not await _cross(a) or not await _cross(b): finish(); return
	var south: Dictionary = _endpoint(_pair("docks_temple"),"b")
	if not await _near(south,south.arrival) or not await _capture("temple_south_roadmouth_minimap_normal"): finish(); return
	var civic: Dictionary = _endpoint(_pair("market_artisan"),"a")
	if not await _civic_adults_near(civic) or not _mini_check() or not await _capture("civic_blademaster_adult_and_services_minimap_normal"): finish(); return
	var temple: Dictionary = _endpoint(_pair("temple_riverside"),"a")
	var hall_foot := Vector2(cfg.temple_hall_foot[0],cfg.temple_hall_foot[1])
	if not await _near(temple,hall_foot) or not _hall_check() or not await _capture("temple_scripture_hall_adult_scale_normal"): finish(); return
	finish()


func _inherit_market_temple() -> bool:
	if not need(FileAccess.get_sha256(r4.inherited_report) == r4.inherited_report_sha256,"IMMUTABLE25304_WHOLE_FAIL_PRESERVED"): return false
	var prior: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(r4.inherited_report)) as Dictionary
	if not need(prior.get("passed") == false and prior.get("checks") == 144 and prior.get("errors") == ["ACTUAL_FIELD_FINITE_READY:ch4_s2_canal_docks"] and prior.get("input_events") == 8 and prior.get("normal_images") == 0,"EXACT25304_DOCKS_CONTEXT_WAIT_FAILURE_ONLY"): return false
	var trips: Array = prior.get("records",[]).filter(func(row: Dictionary) -> bool: return row.get("true_space_crossing") == true)
	if not need(trips.size() == 2 and trips[0].get("pair") == "market_temple" and trips[0].get("side") == "a" and trips[1].get("pair") == "market_temple" and trips[1].get("side") == "b" and trips[0].get("actual_foot") == trips[0].get("expected_arrival") and trips[1].get("actual_foot") == trips[1].get("expected_arrival") and trips[0].get("actual_logical") == "ch4_s4_ancient_temple" and trips[1].get("actual_logical") == "ch4_s3_luoyang_market" and var_to_bytes(prior.get("source_first",{})) == var_to_bytes(prior.get("source_final",{})),"INHERIT_TWO_MORE_TRUE_MARKET_TEMPLE_DIRECTIONS_NO_RETEST"): return false
	inherited_temple=true
	records.append({"inherited_true_market_temple_directions_only":trips,"report":r4.inherited_report,"report_sha256":r4.inherited_report_sha256,"prior_whole_passed":false,"four_true_directions_inherited_total":4,"remaining_true_directions_required":4,"no_missing_prior_loader_state_invented":true})
	return true

func finish() -> void:
	if done: return
	done = true
	for code: Key in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SPACE]:
		if Input.is_physical_key_pressed(code): _key(code,false)
	var final_sources: Dictionary = facts() if not pins.is_empty() else {}
	if not first.is_empty(): need(var_to_bytes(first) == var_to_bytes(final_sources),"SOURCE_FIRST_FINAL_EXACT_NO_OLD_WRITES")
	var executed: int = records.filter(func(row: Dictionary) -> bool: return row.get("true_space_crossing") == true).size()
	records.append({"scope":"RESIDUAL04_FOUR_REAL_DIRECTIONS_PLUS_FOUR_INHERITED_MAX_THREE_IMAGES","inherited_true_directions":4 if inherited_temple else (2 if inherited_market else 0),"executed_true_directions":executed,"no_Gate_or_static22_retest":true,"no_battle_crafting_or_gait_retest":true,"save_apis":0,"save_metadata_samples":0,"userstate_reads_writes":0,"player_router_camera_private_writes":0})
	var result: Dictionary = {"passed":errors.is_empty(),"checks":checks,"errors":errors,"input_events":inputs,"normal_images":images,"inherited_true_directions":4 if inherited_temple else (2 if inherited_market else 0),"executed_true_directions":executed,"records":records,"source_first":first,"source_final":final_sources,"checkpoint_suspended":suspended,"root_only":true}
	var file := FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result,"\t")+"\n")
	print("CITYNAV31D_RESIDUAL04 ",JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"inputs":inputs,"images":images,"inherited":4 if inherited_temple else (2 if inherited_market else 0),"executed":executed,"result":directory+"/result.json"}))
	quit(0 if errors.is_empty() else 1)
