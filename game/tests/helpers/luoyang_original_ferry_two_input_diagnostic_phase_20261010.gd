extends "res://tests/helpers/luoyang_enclosure_v11_city_only_phase.gd"
## Limited actual diagnostic. Inherits the ORIGINAL _normal_portal_case body,
## including approach, real inputs, begin/finish timing, 120s observer budget,
## separate PUBLIC_API_NOT_INPUT return and original indirect normal return.
const FERRY_SCOPE := "ACTUAL_ORIGINAL_DOCKS_FERRY_TWO_INPUT_DIAGNOSTIC_NOT_APPROVAL"
const FERRY_CITY := "ch4_s2_canal_docks"
const FERRY_ID := "canal_world_ferry"
const FERRY_PARENT_PATH := "res://tests/helpers/luoyang_enclosure_v11_city_only_phase.gd"
const FERRY_PARENT_SHA := "be0dc45f4e4f66b7776fcfdeabb59538838270eb8870deaa990a57fad732ddf9"

func run_ferry_diagnostic(owner: SceneTree,directory: String) -> Dictionary:
	tree=owner; candidate=true; output=directory
	before_files=_normal_files(); before_slot=tree.root.get_node("SaveManager").get("active_slot")
	driver=INPUT.new(); driver.call("configure",tree)
	_check("--luoyang-original-ferry-two-input-diagnostic" in OS.get_cmdline_user_args() and "--fresh-start-only" in OS.get_cmdline_user_args() and "--luoyang-v3-candidate" in OS.get_cmdline_user_args() and "--luoyang-enclosure-v11-candidate" in OS.get_cmdline_user_args(),"explicit candidate diagnostic only")
	_check(FileAccess.get_sha256(FERRY_PARENT_PATH).to_lower()==FERRY_PARENT_SHA and FileAccess.get_sha256(V9C_CITY_ORIGIN_PATH).to_lower()==V9C_CITY_ORIGIN_SHA,"current observer join and immutable original portal lifecycle")
	var legacy: SceneScript=ENCLOSURE.legacy_scene(StringName(FERRY_CITY))
	var matches: Array[Dictionary]=[]
	if legacy!=null and legacy.map_layout!=null:
		for entry: Dictionary in legacy.map_layout.portals:
			if typeof(entry.get("id"))==TYPE_STRING and entry.id==FERRY_ID: matches.append(entry.duplicate(true))
	_check(matches.size()==1,"one exact actual legacy ferry, not a manufactured portal")
	if matches.size()==1:
		_check(matches[0].get("action")=="world_map" and matches[0].get("pos")==Vector2(.300,.865) and matches[0].get("size")==Vector2(.130,.080),"original authored ferry action/position/size unchanged")
	if failures==0:
		_public_fixture({})
		var router: Node=tree.root.get_node("SceneRouter")
		router.call("reset_for_new_game")
		router.call("restore_navigation_state",router.call("get_navigation_state"),&"", &"world_map_jianghu")
		before_nav=(router.call("get_navigation_state") as Dictionary).duplicate(true)
		_check(before_nav.get("world_map_version")==14 and String(router.call("get_active_world_map_scene"))=="world_map_jianghu","formal world14 baseline, no world15 selection")
		_connect_events()
		if failures==0:
			for mode: String in ["space","mouse"]:
				await _normal_portal_case(FERRY_CITY,matches[0],mode)
	_check(records.portals.size()==2,"exactly two original ferry input receipts")
	for index in records.portals.size():
		var row: Dictionary=records.portals[index]
		var expected_mode: String="space" if index==0 else "mouse"
		_check(row.get("source_scene_id")==FERRY_CITY and row.get("source_id")==FERRY_ID and row.get("mode")==expected_mode and row.get("dry_run")==false and row.get("target")=="world_map_jianghu" and row.get("entered")==true,"original input identity and actual world14 arrival")
		var memory: Dictionary=row.get("separate_paired_memory_api",{})
		_check(memory.get("scope")=="PUBLIC_API_NOT_INPUT" and memory.get("returned")==true and memory.get("exact_source_feet")==true,"separate paired memory API is never normal-input credit")
		var back: Dictionary=row.get("return",{})
		_check(back.get("kind")=="INDIRECT_WORLD_GATE_YAMEN_DOCKS_INPUT" and back.get("returned")==true and (back.get("steps",[]) as Array).size()==3,"original three-step normal indirect return, no route shortcut")
		var observation: Dictionary=row.get("bgm_observation",{})
		var domain: Dictionary=observation.get("period_domain",{})
		_check(row.get("bgm_started",{}).get("ok")==true and observation.get("ok")==true and observation.get("maximum_duration_sec")==120.0 and domain.get("kind")=="EXACT_SHA_BOUND_JOURNEY52" and domain.get("period_sec")==52.0,"actual original begin/finish with exact journey52 domain and unchanged120s budget")
	return await _finish_ferry_diagnostic()

func _finish_ferry_diagnostic() -> Dictionary:
	# Common cleanup is retained from _finish_city_stage; full stage-count/water
	# claims are deliberately NOT invoked or fabricated for this two-case scope.
	await natural_field_grace("city_only_before_actual_cleanup")
	records["own_natural_grace"]=natural_grace_records.duplicate(true)
	var bus: Node=tree.root.get_node("EventBus")
	for entry: Dictionary in event_connections:
		if bus.is_connected(entry.signal,entry.callable): bus.disconnect(entry.signal,entry.callable)
	event_connections.clear()
	if raw!=null: _check(raw.call("verify_sources"),"last current PNG source verification")
	_release_field_oracles()
	var reference: WeakRef=weakref(field) if is_instance_valid(field) else null
	if is_instance_valid(tree.current_scene): tree.current_scene.queue_free(); tree.current_scene=null
	field=null
	for tick in 8: await tree.process_frame
	_check(reference==null or reference.get_ref()==null,"owned Field released normally")
	_check(_normal_files()==before_files and tree.root.get_node("SaveManager").get("active_slot")==before_slot,"all player paths and slot unchanged")
	if not before_nav.is_empty():
		var router: Node=tree.root.get_node("SceneRouter")
		router.call("reset_for_new_game")
		router.call("restore_navigation_state",router.call("get_navigation_state"),&"", &"world_map_jianghu")
		_check(router.call("get_navigation_state")==before_nav,"public current-format process baseline restored exactly")
	var report: Dictionary={"schema":1,"scope":FERRY_SCOPE,"phase":"ferry_two_input_diagnostic","candidate_before_cutover":true,"diagnostic_complete":failures==0 and runtime_started,"complete":failures==0 and runtime_started,"checks":checks,"failures":failures,"records":records.duplicate(true),"initial_navigation":before_nav.duplicate(true),"current_author_bindings":{},"original_portal_entry":[],"six_slot_eligible":false,"full_geometry_tested":false,"full_gameplay_tested":false,"historical_compatibility_tested":false,"world_subject_version":14,"world_full_tested":false,"visual_verdict":"NOT_REVIEWED","formal_approved":false}
	for id: String in author_records: report.current_author_bindings[id]={"path":ENCLOSURE.manifest_path(StringName(id)),"sha256":ENCLOSURE.manifest_sha(StringName(id)),"base_path":ENCLOSURE.base_manifest_path(StringName(id)),"base_sha256":ENCLOSURE.base_manifest_sha(StringName(id))}
	var legacy: SceneScript=ENCLOSURE.legacy_scene(StringName(FERRY_CITY))
	if legacy!=null and legacy.map_layout!=null:
		for entry: Dictionary in legacy.map_layout.portals:
			if entry.get("id")==FERRY_ID: report.original_portal_entry.append(entry.duplicate(true))
	_check(_write("ferry_diagnostic_stage.json",report),"limited original ferry diagnostic persists")
	if driver!=null: driver.call("release"); driver=null
	manifest.clear(); tree=null
	report.checks=checks; report.failures=failures
	report.complete=report.complete and failures==0; report.diagnostic_complete=report.complete
	return report
