extends "res://build/quest_warrants_20261110/live.gd"

const TEA := &"ch7_s2_mingwu_tea_town"
const TEA_QUEST := &"q_ch7_side_05_tea_basket"
const CAMP_QUEST := &"q_ch8_side_01_camp_supplies"

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router = root.get_node("SceneRouter")
	state = root.get_node("GameState")
	quests = root.get_node("QuestManager")
	dialogue = root.get_node("DialogPlayer")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	router.reset_for_new_game()
	var bag: Node = root.get_node("Inventory")
	var reverse := "west_first" in OS.get_cmdline_user_args()
	if not reverse: await check_tea(bag)
	await check_camp(bag, reverse)
	print("CHAPTER_7_8_SIDE checks=", checks, " failures=", failures)
	quit(1 if failures else 0)

func check_tea(bag: Node) -> void:
	state.current_chapter = 7
	state.set_flag(&"chapter6_complete",true)
	var field := await enter(TEA)
	if field == null: return
	await settle(field)
	expect(area(field,"ch7_tea_basket_start")==null,"no tea commission before chapter approach")
	state.set_flag(&"ch7_dual_route_chosen",true)
	await settle(field)
	expect(area(field,"ch7_tea_basket_tag")==null and area(field,"ch7_tea_basket_rope")==null,"two clues hidden before acceptance")
	expect(gate_closed(field,MINGWU_WARD),"manor door starts locked")
	if not await inspect(field,"ch7_tea_basket_start",&"ch7_tea_basket_start",[1]): return
	await settle(field)
	expect(not quests.is_active(TEA_QUEST) and area(field,"ch7_tea_basket_start")!=null,"decline leaves commission available")
	var offer := area(field,"ch7_tea_basket_start")
	await position_at(field,offer.global_position + Vector2(125,0))
	await wait_for(func(): return not field.get("_trigger_events_in_flight").has("ch7_tea_basket_start"),1500)
	if not await inspect(field,"ch7_tea_basket_start",&"ch7_tea_basket_start",[0]): return
	await settle(field)
	expect(quests.is_active(TEA_QUEST) and area(field,"ch7_tea_basket_start")==null,"acceptance changes state once")
	expect(area(field,"ch7_tea_basket_rope")==null and area(field,"ch7_tea_basket_report")==null,"second clue and report wait for evidence")
	if not await inspect(field,"ch7_tea_basket_tag",&"ch7_tea_basket_tag"): return
	await settle(field)
	expect(state.flags.get("ch7_tea_basket_tag_seen",false) and not quests.is_completed(TEA_QUEST),"first clue records without finishing")
	if not await inspect(field,"ch7_tea_basket_rope",&"ch7_tea_basket_rope"): return
	await settle(field)
	var herbs: int = bag.count_of(&"herb_bundle")
	if not await inspect(field,"ch7_tea_basket_report",&"ch7_tea_basket_report",[0,1]): return
	await settle(field)
	expect(quests.is_completed(TEA_QUEST) and bag.count_of(&"herb_bundle")==herbs+3,"wrong answer retries, correct answer grants herbs")
	expect(area(field,"ch7_tea_basket_report")==null,"report cannot repeat")
	expect(area(field,"ch7_mingwu_courier_table")!=null and gate_closed(field,MINGWU_WARD),"main evidence and locked gate unchanged")

func check_camp(bag: Node, west_first: bool) -> void:
	state.current_chapter = 8
	state.set_flag(&"chapter7_complete",true)
	var field := await enter(MUSTER)
	if field == null: return
	await settle(field)
	expect(gate_closed(field,MISTWOOD),"mistwood gate starts locked")
	expect(area(field,"ch8_camp_supplies_east")==null and area(field,"ch8_camp_supplies_west")==null,"supplies hidden before accepting")
	if not await inspect(field,"ch8_camp_supplies_start",&"ch8_camp_supplies_start",[0]): return
	await settle(field)
	expect(quests.is_active(CAMP_QUEST) and area(field,"ch8_camp_supplies_start")==null,"acceptance hides repeated offer")
	var wood: int = bag.count_of(&"timber_bundle")
	var pills: int = bag.count_of(&"life_extend_pill")
	var first := "ch8_camp_supplies_west" if west_first else "ch8_camp_supplies_east"
	var second := "ch8_camp_supplies_east" if west_first else "ch8_camp_supplies_west"
	if not await inspect(field,first,StringName(first)): return
	await settle(field)
	expect(quests.is_active(CAMP_QUEST) and not quests.is_completed(CAMP_QUEST) and bag.count_of(&"timber_bundle")==wood,"first stop alone neither finishes nor pays")
	if not await inspect(field,second,StringName(second)): return
	await settle(field)
	expect(quests.is_completed(CAMP_QUEST) and bag.count_of(&"timber_bundle")==wood+2 and bag.count_of(&"life_extend_pill")==pills+1,"both stations grant exact rewards")
	expect(area(field,"ch8_camp_supplies_east")==null and area(field,"ch8_camp_supplies_west")==null,"both finished stations disappear")
	expect(gate_closed(field,MISTWOOD) and not state.flags.get("ch8_alliance_mustered",false),"side quest does not unlock the main gate")

func gate_closed(field: Node, target: StringName) -> bool:
	var gate := zone_to(field,target)
	return gate == null or gate.is_locked

func inspect(field: Node, id: String, dialog_id: StringName, choices: Array[int] = []) -> bool:
	var trigger := area(field, id)
	if not expect(trigger != null, "spawned " + id): return false
	var actor := await position_at(field, trigger.global_position)
	var hits := await wait_for(func(): return is_instance_valid(trigger) and trigger.overlaps_body(actor), 1000)
	var clear := check_clear(actor, id)
	if not expect(hits and clear, "clear footprint %s foot=%s overlap=%s" % [id,actor.global_position,hits]): return false
	await press_space()
	if not expect(await wait_for(func(): return dialogue.is_playing() and dialogue.get("_current_script").dialog_id == dialog_id,1800), "Space opens "+id):
		print("SIDE_DEBUG ",id," events=",field.get("_trigger_events_in_flight")," at ",actor.global_position)
		return false
	print("SIDE_INTERACTION ",id," at ",actor.global_position)
	for choice in choices:
		dialogue.choose(choice)
		if dialogue.is_playing() and not dialogue.get("_current_node").has_choices():
			dialogue.advance()
	while dialogue.is_playing() and not dialogue.get("_current_node").has_choices():
		dialogue.advance()
	return expect(not dialogue.is_playing(), "dialogue closed " + id)
