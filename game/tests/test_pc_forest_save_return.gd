extends "res://build/victory_quest_20261108/story_live.gd"

func _run() -> void:
	await process_frame
	if not OS.get_user_data_dir().replace("\\", "/").contains("/pc_flow_"):
		push_error("Isolated profile required")
		quit(2)
		return
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router = root.get_node("SceneRouter")
	state = root.get_node("GameState")
	dialogue = root.get_node("DialogPlayer")
	state.reset_for_new_game()
	router.reset_for_new_game()
	var forest := &"ch1_s3_zhuwei_forest"
	var field := await enter(forest)
	if field == null:
		finish()
		return
	var saves := root.get_node("SaveManager")
	var prototype := {"current_field": forest, "version": 9}
	var expanded := {"current_field": forest, "version": 10, "quests": {"q_ch1_main_zhuwei_wilds": 1}}
	expect(saves._saved_field_id(prototype) == &"ch2_s3_forest_ambush", "prototype rescue keeps its migration")
	expect(saves._saved_field_id(expanded) == forest, "expanded chapter one remains available in mixed-era slots")
	expect(saves._saved_field_id({"current_field": forest, "version": 11}) == forest, "post-expansion save retains forest")
	var region_id := StringName(router.REGION27D.Entry.SCENE_RESOURCES.keys()[0])
	expect(saves._saved_field_id({"current_field": region_id, "version": 14}) == region_id, "nested region uses registered field path")
	var obsolete := {"current_field": "obsolete_missing_map", "chapter": 2}
	expect(saves._saved_field_id(obsolete) == router.get_chapter_entry(2), "obsolete scene keeps chapter fallback")
	expect(saves.save_to_slot(1), "save current forest slot")
	expect(saves.get_save_field_id(1) == forest, "slot resolves to current forest")
	var other := await enter(&"ch1_s2_qingfeng")
	if other == null:
		finish()
		return
	var other_id := other.get_instance_id()
	var panel := load("res://scenes/ui/save_slot_panel.tscn").instantiate() as Control
	current_scene.add_child(panel)
	panel.open(1)
	panel._slot_container.get_child(1).pressed.emit()
	panel._btn_confirm.pressed.emit()
	panel._formal_dialog.confirmed.emit()
	var arrived := await wait_for(func():
		return is_instance_valid(current_scene) and current_scene.get_instance_id() != other_id \
			and current_scene.has_method("get_field_loading_state") \
			and current_scene.get_field_loading_state().get("complete", false)
	, 25000)
	print("ACTUAL_LOAD ", router.get_current_field_id())
	expect(arrived and router.get_current_field_id() == forest, "load confirmation returns player to original forest")
	finish()
