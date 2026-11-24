extends "res://tests/helpers/luoyang_enclosure_v11_city_only_indirect_market_return_phase_20261011.gd"
## Bounded real-input regression, NOT the full gameplay or original six slots.
## Failed groups preserve all original checks and stop before slower later groups.
const FOCUSED_SCOPE := "LUOYANG_AUTHORED_INPUT_REPAIRS_NOT_FULL_GAMEPLAY_SIX_INELIGIBLE"
const FOCUSED_FLAG := "--luoyang-authored-input-repairs-focused"
const FOCUSED_PARENT_PATH := "res://tests/helpers/luoyang_enclosure_v11_city_only_indirect_market_return_phase_20261011.gd"
const FOCUSED_PARENT_SHA := "3c37cf6568f1cd1ba6d41c28c276879ca6a352205c9c5a9f8b8acdaabf0ab1a6"

func _focused_original_entry(id: String,kind: String,sid: String) -> Dictionary:
	var legacy: SceneScript=ENCLOSURE.legacy_scene(StringName(id))
	var entries: Array=legacy.npcs if legacy!=null and kind=="npcs" else legacy.map_layout.portals if legacy!=null and legacy.map_layout!=null and kind=="portals" else []
	var found: Array[Dictionary]=[]
	for entry: Dictionary in entries:
		if entry.get("npc_id" if kind=="npcs" else "id")==sid: found.append(entry.duplicate(true))
	if not _check(found.size()==1,"unique immutable authored focused entry "+id+"/"+sid): return {}
	return found[0]

func _focused_group(name: String) -> bool:
	var result: Dictionary={"group":name,"checks":checks,"failures":failures,"original_checks_retained":true,"next_group_allowed":failures==0,"six_slot_eligible":false}
	_check(_write("focused_group_"+name+".json",result),"focused group immediate original outcome readback")
	return failures==0

func run_focused_diagnostic(owner: SceneTree,directory: String) -> Dictionary:
	tree=owner; candidate=true; output=directory
	before_files=_normal_files(); before_slot=tree.root.get_node("SaveManager").get("active_slot")
	driver=INPUT.new(); driver.call("configure",tree)
	_check(FOCUSED_FLAG in OS.get_cmdline_user_args() and "--fresh-start-only" in OS.get_cmdline_user_args() and "--luoyang-v3-candidate" in OS.get_cmdline_user_args() and "--luoyang-enclosure-v11-candidate" in OS.get_cmdline_user_args(),"explicit finite candidate diagnostic, never full gameplay/six")
	_check(FileAccess.get_sha256(FOCUSED_PARENT_PATH)==FOCUSED_PARENT_SHA and FileAccess.get_sha256(V9C_CITY_ORIGIN_PATH)==V9C_CITY_ORIGIN_SHA,"frozen new source substitutions and unchanged original lifecycle")
	if failures!=0: return await _finish_focused_diagnostic()
	_public_fixture({})
	var router: Node=tree.root.get_node("SceneRouter")
	router.call("reset_for_new_game")
	router.call("restore_navigation_state",router.call("get_navigation_state"),&"", &"world_map_jianghu")
	before_nav=(router.call("get_navigation_state") as Dictionary).duplicate(true)
	_check(before_nav.get("world_map_version")==14 and String(router.call("get_active_world_map_scene"))=="world_map_jianghu","formal world14 baseline, no world15 or historical migration")
	_connect_events()
	if failures!=0: return await _finish_focused_diagnostic()
	var negatives: RefCounted=INTERACTION_NEGATIVES.new()
	records.interaction_negatives=await negatives.call("run",self)
	negatives=null
	_check(records.interaction_negatives.get("complete")==true and (records.interaction_negatives.get("records",[]) as Array).size()==55,"ALL55 original eleven-interaction input negatives")
	if not _focused_group("01_all55_negatives"): return await _finish_focused_diagnostic()
	await _normal_bounty_rewards()
	_check(records.bounties.size()==2,"both original UI-accepted bounty battles and exact rewards")
	if not _focused_group("02_two_bounty_rewards"): return await _finish_focused_diagnostic()
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
	var report: Dictionary={"schema":1,"scope":FOCUSED_SCOPE,"phase":"focused_input_regressions","candidate_before_cutover":true,"diagnostic_complete":failures==0 and runtime_started,"complete":failures==0 and runtime_started,"checks":checks,"failures":failures,"records":records.duplicate(true),"initial_navigation":before_nav.duplicate(true),"current_author_bindings":{},"coverage":{"interaction_negatives":records.interaction_negatives.get("complete",false),"bounty_rewards":records.bounties.size(),"portal_inputs":records.portals.size(),"spar_inputs":records.npcs.size()},"six_slot_eligible":false,"full_geometry_tested":false,"full_gameplay_tested":false,"historical_compatibility_tested":false,"world_subject_version":14,"world_full_tested":false,"visual_verdict":"NOT_REVIEWED","formal_approved":false}
	for id: String in author_records: report.current_author_bindings[id]={"path":ENCLOSURE.manifest_path(StringName(id)),"sha256":ENCLOSURE.manifest_sha(StringName(id)),"base_path":ENCLOSURE.base_manifest_path(StringName(id)),"base_sha256":ENCLOSURE.base_manifest_sha(StringName(id))}
	_check(_write("focused_diagnostic_stage.json",report),"limited original input regressions persists")
	if driver!=null: driver.call("release"); driver=null
	manifest.clear(); tree=null
	report.checks=checks; report.failures=failures
	report.complete=report.complete and failures==0; report.diagnostic_complete=report.complete
	return report

