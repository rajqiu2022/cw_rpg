extends "res://build/victory_quest_20261108/story_live.gd"

const FOREST := &"ch1_s3_zhuwei_forest"
const CAVE := &"ch1_s4_zhuwei_beast_cave"
const INQUIRY := &"q_ch1_main_village_inquiry"

func _run() -> void:
	await process_frame
	set_meta("skip_chapter_end_autosave", true)
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router = root.get_node("SceneRouter")
	state = root.get_node("GameState")
	quests = root.get_node("QuestManager")
	dialogue = root.get_node("DialogPlayer")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	router.reset_for_new_game()

	var menu := await show_screen("res://scenes/main_menu.tscn")
	var bg: TextureRect = menu.get_node("Background")
	expect(bg.material is ShaderMaterial, "main menu uses the animated original artwork")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var first := root.get_texture().get_image()
		await create_timer(1.5).timeout
		await RenderingServer.frame_post_draw
		var second := root.get_texture().get_image()
		expect(first.get_pixel(960,150) == second.get_pixel(960,150), "title stays stable")
		expect(first.get_region(Rect2i(1250,420,200,130)).get_data() != second.get_region(Rect2i(1250,420,200,130)).get_data(), "dawn pixels move")

	var payload: Dictionary = router.get_result_payload()
	payload["elite_loot"] = [{"item_id": &"dark_iron_boots", "collected": true}]
	var result := await show_screen("res://scenes/result_victory.tscn")
	var loot_text: String = result.get_node("%RewardLabel").text
	expect("[img=" in loot_text and "#b56cff" in loot_text and "玄铁重靴" in loot_text, "purple boots use actual icon and inventory quality tint")
	expect(not "未拾取" in loot_text, "collected drop is not marked as missed")
	await snapshot("victory_loot")

	var chapter := await show_screen("res://scenes/chapter_end.tscn")
	var caption: Label = chapter.get_node("%ChapterLabel")
	expect(caption.get_theme_color("font_shadow_color").a == 0.0 and caption.get_theme_font_size("font_size") == 44, "paper caption has clear shadow-free styling")
	await snapshot("chapter_caption")
	if not is_instance_valid(current_scene):
		finish()
		return
	current_scene.queue_free()
	await process_frame
	state.reset_for_new_game()
	quests.reset_for_new_game()
	state.set_flag(&"master_training_done", true)
	quests.states[&"q_ch1_main_training"] = QuestDef.Status.COMPLETED
	quests.accept(INQUIRY)
	var seen := [0]
	root.get_node("EventBus").quest_progressed.connect(func(id: StringName):
		if id == INQUIRY: seen[0] += 1
	)
	var guard: DialogScript = load("res://data/dialogs/ch1_s2_guard.tres")
	for i in 2:
		dialogue.play(guard)
		for j in 6:
			if not dialogue.is_playing(): break
			dialogue.advance()
		expect(seen[0] == 1, "guard dialog repeat %d emits no duplicate progress" % i)
	var clues: DialogScript = load("res://data/dialogs/huilan_openworld_balance.tres")
	dialogue.play_at(clues, &"record")
	var line: String = dialogue.get("_current_node").text
	expect("担杆" in line and not "经验" in line and not "工坊" in line, "porter ending gives only diegetic clue")
	dialogue.advance()
	for flag in [&"entered_zhuwei_forest", &"entered_zhuwei_village", &"zhuwei_village_inquiry_done", &"defeated_linxi_wild_beast"]:
		state.set_flag(flag, true)
	var field := await enter(FOREST)
	if field != null:
		await settle(field)
		var mouth := field.find_child("SceneObject_cave_mouth", true, false) as Sprite2D
		var ridge := field.find_child("SceneObject_cave_ridge", true, false) as Sprite2D
		expect(mouth != null and ridge != null and mouth.z_index > ridge.z_index, "visible mouth stands in front of the overlapping rock")
		var entrance := zone_to(field, CAVE)
		if expect(entrance != null, "local cave entrance exists"):
			await position_at(field, entrance.global_position + Vector2(0,70))
			await snapshot("forest_cave_mouth")
		await roundtrip(field, CAVE, FOREST, 150.0)
	finish()

func show_screen(path: String) -> Node:
	change_scene_to_file(path)
	await scene_changed
	await process_frame
	return current_scene

func snapshot(id: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://"+id+".png")
