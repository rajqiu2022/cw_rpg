extends "res://tests/helpers/luoyang_enclosure_v11_authored_input_repairs_focused_phase_20261011.gd"
## ONLY original groups03/04: five real portal inputs and one real spar.
## ALL55 interaction negatives and both bounties are explicitly NOT executed.
const PORTAL_SCOPE := "LUOYANG_FIVE_ORIGINAL_PORTALS_ONE_SPAR_NOT_SIX"
const PORTAL_FLAG := "--luoyang-five-portals-one-spar"
const PORTAL_PARENT_PATH := "res://tests/helpers/luoyang_enclosure_v11_authored_input_repairs_focused_phase_20261011.gd"
const PORTAL_PARENT_SHA := "9bd4bc5115c5611365b8c7fd390d2fcd07a607c2bcc5f460b45dad8ac58f93da"

func run_focused_diagnostic(owner: SceneTree,directory: String) -> Dictionary:
	tree=owner; candidate=true; output=directory
	before_files=_normal_files(); before_slot=tree.root.get_node("SaveManager").get("active_slot")
	driver=INPUT.new(); driver.call("configure",tree)
	_check(PORTAL_FLAG in OS.get_cmdline_user_args() and "--fresh-start-only" in OS.get_cmdline_user_args() and "--luoyang-v3-candidate" in OS.get_cmdline_user_args() and "--luoyang-enclosure-v11-candidate" in OS.get_cmdline_user_args(),"explicit finite candidate diagnostic, never full gameplay/six")
	_check(FileAccess.get_sha256(PORTAL_PARENT_PATH)==PORTAL_PARENT_SHA and FileAccess.get_sha256(FOCUSED_PARENT_PATH)==FOCUSED_PARENT_SHA and FileAccess.get_sha256(V9C_CITY_ORIGIN_PATH)==V9C_CITY_ORIGIN_SHA,"frozen new source substitutions and unchanged original lifecycle")
	if failures!=0: return await _finish_focused_diagnostic()
	_public_fixture({})
	var router: Node=tree.root.get_node("SceneRouter")
	router.call("reset_for_new_game")
	router.call("restore_navigation_state",router.call("get_navigation_state"),&"", &"world_map_jianghu")
	before_nav=(router.call("get_navigation_state") as Dictionary).duplicate(true)
	_check(before_nav.get("world_map_version")==14 and String(router.call("get_active_world_map_scene"))=="world_map_jianghu","formal world14 baseline, no world15 or historical migration")
	_connect_events()
	if failures!=0: return await _finish_focused_diagnostic()
	for sid: String in ["to_city_gate","to_ancient_temple"]:
		var entry: Dictionary=_focused_original_entry("ch4_s3_luoyang_market","portals",sid)
		if entry.is_empty(): return await _finish_focused_diagnostic()
		for mode: String in ["space","mouse"]:
			await _normal_portal_case("ch4_s3_luoyang_market",entry,mode)
			if failures!=0: return await _finish_focused_diagnostic()
	var world_entry: Dictionary=_focused_original_entry("ch4_s0_luoyang_gate","portals","return_world")
	if world_entry.is_empty(): return await _finish_focused_diagnostic()
	await _normal_portal_case("ch4_s0_luoyang_gate",world_entry,"space")
	_check(records.portals.size()==5,"four original problem-edge modes plus one normal Gate world14 return")
	if not _focused_group("03_five_original_portals"): return await _finish_focused_diagnostic()
	var spar: Dictionary=_focused_original_entry("ch4_s1_luoyang_yamen","npcs","spar_yamen_patrol")
	if not spar.is_empty(): await _normal_action_case("ch4_s1_luoyang_yamen","npcs",spar,"space")
	_check(records.npcs.size()==1,"one original spar victory and original exact pre-battle feet return")
	_focused_group("04_original_spar")
	return await _finish_focused_diagnostic()

func _finish_focused_diagnostic() -> Dictionary:
	# Common cleanup is retained from _finish_city_stage; full stage-count/water
	# claims are deliberately NOT invoked or fabricated for this finite scope.
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
	var report: Dictionary={"schema":1,"scope":PORTAL_SCOPE,"phase":"five_portals_one_spar","excluded_checks":{"all55_interaction_negatives_executed":false,"two_bounty_rewards_executed":false},"candidate_before_cutover":true,"diagnostic_complete":failures==0 and runtime_started,"complete":failures==0 and runtime_started,"checks":checks,"failures":failures,"records":records.duplicate(true),"initial_navigation":before_nav.duplicate(true),"current_author_bindings":{},"coverage":{"interaction_negatives":records.interaction_negatives.get("complete",false),"bounty_rewards":records.bounties.size(),"portal_inputs":records.portals.size(),"spar_inputs":records.npcs.size()},"six_slot_eligible":false,"full_geometry_tested":false,"full_gameplay_tested":false,"historical_compatibility_tested":false,"world_subject_version":14,"world_full_tested":false,"visual_verdict":"NOT_REVIEWED","formal_approved":false}
	for id: String in author_records: report.current_author_bindings[id]={"path":ENCLOSURE.manifest_path(StringName(id)),"sha256":ENCLOSURE.manifest_sha(StringName(id)),"base_path":ENCLOSURE.base_manifest_path(StringName(id)),"base_sha256":ENCLOSURE.base_manifest_sha(StringName(id))}
	_check(_write("five_portals_one_spar_stage.json",report),"limited original input regressions persists")
	if driver!=null: driver.call("release"); driver=null
	manifest.clear(); tree=null
	report.checks=checks; report.failures=failures
	report.complete=report.complete and failures==0; report.diagnostic_complete=report.complete
	return report
