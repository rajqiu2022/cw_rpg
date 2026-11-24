extends "res://build/quest_map_audit_20261108/huilan_live.gd"

const YAMEN := &"ch4_s1_luoyang_yamen"
const AFTERMATH := &"q_ch8_main_13_aftermath_returns"

func finish() -> void:
	print("YAMEN_QUEST_LIVE checks=",checks," failures=",failures)
	quit(1 if failures else 0)

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router=root.get_node("SceneRouter")
	state=root.get_node("GameState")
	quests=root.get_node("QuestManager")
	dialogue=root.get_node("DialogPlayer")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	router.reset_for_new_game()
	if not expect(router.go_field_smart(YAMEN),"Router accepts formal Yamen"):
		finish()
		return
	if not expect(await wait_for(func():
		var field:=current_scene
		if field==null or not field.has_method("get_field_loading_state") or not field.get_field_loading_state().get("complete",false):
			return false
		var loading:=root.get_node("LoadingManager")
		var screen: Node=loading.get("_screen")
		var actor: Player=field.get("_player")
		return field.has_meta("city_navigation11d") and not loading.get("_transition_active") and not screen.get("_view_job") and is_instance_valid(actor) and actor.can_move
	,45000),"formal Yamen ready"):
		finish()
		return
	var field:=current_scene
	var water: Area2D
	for trigger: Area2D in field.get("_trigger_areas"):
		if trigger.get_meta("trigger_data",{}).get("action","")=="dialog:huilan_openworld_water_rule":
			water=trigger
	if expect(water!=null,"Yamen retained the water puzzle"):
		await play_at(field,water.get_meta("trigger_data").id,&"huilan_openworld_water_rule",[1])
		expect(state.flags.get("huilan_water_rule_understood",false),"water puzzle records a clue")
	quests.accept(AFTERMATH)
	expect(await wait_for(func():
		for npc: NPCNode in field.get("_npc_nodes"):
			if npc.npc_id=="ch8_luoyang_final_clerk": return true
		return false
	),"active chapter eight quest spawns formal Yamen clerk")
	finish()
