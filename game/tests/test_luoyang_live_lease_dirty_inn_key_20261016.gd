extends "res://tests/helpers/luoyang_live_lease_key_20261016.gd"
## One Market setup and one true inn dirty roundtrip, no world/city journey.
const INN_ID="luoyang_market_inn_interior_20261015"
const PAPER_QUEST=&"q_ch4_side_02_luoyang_paper"
const PAPER_FLAG=&"luoyang_paper_started"
const TASK_PREFIX="luoyang_city_tasks_20261016/"
func _run() -> void:
	await _lease_run("DIRTY_INN_KEY",90000)
func _ambient_ids() -> Array:
	var ids: Array=[]
	for npc: Node in field.get("_npc_nodes"):
		var id: String=String(npc.get("npc_id"))
		if id.begins_with("district_life_") or id.begins_with("harbour_life_"): ids.append(npc.get_instance_id())
	ids.sort();return ids
func _exercise() -> bool:
	var router: Node=root.get_node("SceneRouter")
	var began: int=Time.get_ticks_usec()
	var accepted: bool=router.call("go_field_smart",&"ch4_s3_luoyang_market",Vector2(735,920)/Vector2(3072,2048),"",-1,C.VERSION)
	records.append({"kind":"PUBLIC_MARKET_NEAR_SETUP_NOT_TRAVEL","accepted":accepted,"call_usec":Time.get_ticks_usec()-began})
	if not check(accepted,"One legal current3 Market setup") or not await _wait_target("ch4_s3_luoyang_market") or not _bind_city("ch4_s3_luoyang_market"): return false
	if not await _walk(PackedVector2Array([Vector2(735,920),Vector2(735,864)])) or not _zone(INN_ID) or not _retain(): return false
	var ambient_before: Array=_ambient_ids()
	var validations_before: int=C._transition_full_validations
	if not await _space(INN_ID,"ONE_REAL_INN_ENTRY") or not _bind_room(): return false
	if not check(is_instance_valid(retained_field) and not retained_field.is_inside_tree() and router.call("get_resident_city_state").get("excursion_kind")=="room","Real inn while exact exterior parked"): return false
	var quests: Node=root.get_node("QuestManager")
	var before: Dictionary=quests.call("to_dict")
	var quest_accepted: bool=quests.call("accept",PAPER_QUEST)
	root.get_node("GameState").call("set_flag",PAPER_FLAG,true)
	var expected: Dictionary=quests.call("to_dict")
	if not check(quest_accepted and not C._equal_value(before,expected),"Isolated actual quest/flag changed only in memory while exterior parked"): return false
	var exit: Dictionary=scene.map_layout.portals[0]
	var target: Vector2=exit.pos*Vector2(field.get("_world_size"))-Vector2(0,36)
	if not await _walk(PackedVector2Array([(field.get("_player") as Node2D).position,target])) or not _zone("ch4_s3_luoyang_market"): return false
	if not await _space("ch4_s3_luoyang_market","DIRTY_INN_RETURN",true) or not _bind_city("ch4_s3_luoyang_market") or not _same_retained(): return false
	var refreshed: Dictionary=field.call("get_resident_dynamic_refresh_state")
	var scholar: Array=[]
	for npc: Node in field.get("_npc_nodes"):
		if String(npc.get("npc_id"))=="luoyang_paper_scholar": scholar.append(npc)
	if not check(refreshed.get("dynamic_only")==true and refreshed.get("static_objects_preserved")==true and refreshed.get("current_flags_applied")==true and _ambient_ids()==ambient_before and int(refreshed.get("ambient_preserved",0))==ambient_before.size() and C._transition_full_validations==validations_before and C._equal_value(quests.call("to_dict"),expected) and root.get_node("GameState").call("get_flag",PAPER_FLAG)==true and scholar.size()==1 and String(scholar[0].get("dialog_id"))==TASK_PREFIX+"paper_progress" and (scholar[0] as CanvasItem).is_visible_in_tree(),"Dirty current task NPC reprojected; original static identity and live ambient instances retained",refreshed): return false
	if not check((field.get("_player") as Node2D).position==Vector2(735,864),"Exact remembered actual door foot, not authored marker735854"): return false
	records.append({"kind":"DIRTY_STATE","quest":PAPER_QUEST,"flag":PAPER_FLAG,"quest_expected":expected,"refresh":refreshed,"ambient_instances_before":ambient_before,"ambient_instances_after":_ambient_ids(),"disk_save_called":false})
	return await _walk(PackedVector2Array([Vector2(735,864),Vector2(751,864)])) and await _capture("live_static_preserved_dirty_inn_return")
