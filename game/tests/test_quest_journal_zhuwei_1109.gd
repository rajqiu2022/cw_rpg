extends "res://build/victory_quest_20261108/story_live.gd"

const VILLAGE := &"ch1_s2_qingfeng"
const INQUIRY := &"q_ch1_main_village_inquiry"
const TRAINING := &"q_ch1_main_training"
const WILDS := &"q_ch1_main_zhuwei_wilds"
const BANDIT := &"q_ch1_side_10_bandit_cave"

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
	quests.accept(TRAINING)
	quests.complete(TRAINING)
	state.set_flag(&"master_training_done",true)
	state.set_flag(&"entered_zhuwei_village",true)
	quests.accept(INQUIRY)
	state.set_flag(&"zhuwei_inn_clue",true)
	state.set_flag(&"zhuwei_scout_clue",true)
	state.set_flag(&"defeated_bandit_cave_guard",true)
	state.set_flag(&"clue_bandit_cave_mist_mark",true)
	var field := await enter(VILLAGE)
	if field == null: finish(); return
	expect(quests.is_active(INQUIRY) and not state.flags.get("zhuwei_guard_briefed",false),"cleared side cave does not replace the guard clue")
	if not await _speak_guard(field,&"ch1_s2_guard"): finish(); return
	expect(state.flags.get("zhuwei_guard_briefed",false) and quests.is_active(INQUIRY),"first talk records the missing clue")
	if not await _speak_guard(field,&"ch1_s2_guard_report"): finish(); return
	expect(quests.is_completed(INQUIRY) and quests.is_active(WILDS) and zone_to(field,&"ch1_s3_zhuwei_forest") != null,"original report completes inquiry and opens forest")
	await _journal(field)
	finish()

func _speak_guard(field: Node, id: StringName) -> bool:
	await settle(field)
	var guard: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id == "guard":
			guard = npc
			break
	if not expect(is_instance_valid(guard),"official guard exists"): return false
	await position_at(field,guard.global_position + Vector2(0,51))
	await press_space()
	if not expect(await wait_for(func(): return dialogue.is_playing() and dialogue.get("_current_script").dialog_id == id,2200),"real Space dialogue "+String(id)):
		return false
	for i in range(12):
		if not dialogue.is_playing(): break
		dialogue.advance()
		await process_frame
	await settle(field)
	return expect(not dialogue.is_playing(),"finished "+String(id))

func _click(pos: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = pos
	event.pressed = true
	root.push_input(event,true)
	await process_frame
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	root.push_input(event,true)
	await process_frame

func _center(control: Control) -> Vector2:
	return control.get_global_transform_with_canvas() * (control.size * 0.5)

func _journal(field: Node) -> void:
	# Separate the UI case from the earlier post-cave story fixture.
	state.set_flag(&"clue_bandit_cave_mist_mark",false)
	quests.accept(BANDIT)
	await settle(field)
	var panel: Control = field.get("_quest_panel_full")
	panel.open()
	await process_frame
	var main := panel.find_child("ViewMainTarget",true,false) as TextureButton
	if not expect(is_instance_valid(main) and await wait_for(func(): return main.is_visible_in_tree(),2200),"active main target visible"):
		return
	var motion := InputEventMouseMotion.new()
	motion.position = _center(main)
	root.push_input(motion,true)
	await process_frame
	var caption := main.get_node("Caption") as Label
	expect(main.is_hovered() and main.texture_hover != main.texture_normal and caption.get_theme_color("font_color") == Color("#baffef"),"main target hover uses the highlight texture and caption")
	var side := panel.get_node("%TrackBtn") as TextureButton
	await _click(_center(panel.get_node("%StatusDone")))
	await process_frame
	expect(not main.visible and not side.visible,"completed main quest hides both buttons")
	await _click(_center(panel.get_node("%PrimarySide")))
	await process_frame
	expect(not main.visible and not side.visible,"empty side list hides both buttons")
	await _click(_center(panel.get_node("%StatusActive")))
	if not expect(await wait_for(func(): return side.visible and not side.disabled,2200),"active side track remains available"): return
	var rewards := panel.get_node("%RewardList")
	var slot := rewards.get_child(0).get_child(0) as TextureButton
	await _click(_center(slot))
	var tip := panel.get("_reward_detail_tip") as Control
	if not expect(tip.is_visible_in_tree(),"clicking reward opens detail"): return
	var title: Label = tip.get("_title")
	var body: RichTextLabel = tip.get("_text")
	var item: Item = root.get_node("Inventory").call("load_item_by_id",&"antidote_pill")
	expect(title.text == "解毒丹" and body.text == item.description and title.global_position.y + title.size.y < body.global_position.y,"separate reward name and description rows")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://quest_journal_reward_1109.png")
	await _click(_center(title))
	expect(tip.visible,"clicking inside detail keeps it open")
	var frame := panel.get_node("Panel") as Control
	await _click(frame.get_global_transform_with_canvas() * Vector2(780,375))
	expect(not tip.visible and panel.visible,"blank click dismisses reward detail only")
	quests.complete(BANDIT)
	await _click(_center(panel.get_node("%StatusDone")))
	await process_frame
	expect(not side.visible,"completed side quest has no tracking button")
	panel.close()

func finish() -> void:
	print("QUEST_JOURNAL_ZHUWEI_RESULT ",checks,"/",failures)
	quit(1 if failures else 0)
