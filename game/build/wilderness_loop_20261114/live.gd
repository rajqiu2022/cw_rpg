extends "res://build/victory_quest_20261108/story_live.gd"

const FOREST := &"ch1_s3_zhuwei_forest"
const HUNT := &"adventure_zhuwei_hunting_ground"

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
	var inventory := root.get_node("Inventory")
	var gather := load("res://scripts/life_skills/gathering_service.gd")
	var craft := load("res://scripts/life_skills/crafting_service.gd")
	var herbs := {}
	for row: Dictionary in gather.catalog().sites:
		if row.get("type") != "herb":
			continue
		var id := StringName(row.get("item_id", "herb_bundle"))
		var item: Item = inventory.load_item_by_id(id)
		expect(item != null and ResourceLoader.exists(String(row.texture)), "medicine resource "+String(id))
		herbs[id] = true
	expect(herbs.size() == 10, "ten distinct mapped herbs")
	for id: StringName in herbs:
		inventory.add_item(id, 4)
	for recipe in ["field_healing_blend","field_antidote_blend","field_edge_pill","field_breath_pill","field_guard_powder"]:
		expect(craft.craft(recipe, 1, "medicine").ok, "craft "+recipe)
	# A pre-acceptance battle flag must never qualify for hand-in.
	state.flags["defeated_bandit_mountain"] = true
	expect(quests.accept(&"q_ch1_side_08_mountain_patrol"), "accept mountain patrol")
	expect(state.get_flag(&"mountain_patrol_bandits_repelled") != true, "historical kill did not credit the commission")
	router.set("_battle_payload", {"return_scene": &"ch1_s3_zhuwei_forest"})
	quests._on_enemy_defeated(&"bandit_mountain")
	expect(state.get_flag(&"mountain_patrol_bandits_repelled") != true, "victory at wrong scene does not credit commission")
	router.set("_battle_payload", {"return_scene": &"ch1_s1_road"})
	quests._on_enemy_defeated(&"bandit_mountain")
	expect(state.get_flag(&"mountain_patrol_bandits_repelled") == true, "new road victory credits the active commission")
	router.set("_battle_payload", {})
	for flag in [&"entered_zhuwei_forest", &"entered_zhuwei_village", &"zhuwei_village_inquiry_done"]:
		state.set_flag(flag, true)
	var field := await enter(FOREST)
	if field == null:
		finish()
		return
	await settle(field)
	var life := root.get_node("LifeSkills")
	var actor: Player = field.get("_player")
	var points: Dictionary = life.get("_site_nodes")
	var herb: Node2D = points.get("life_forest_herb_01")
	if expect(is_instance_valid(herb), "herb sprite exists in actual forest"):
		expect(not herb.get_node("GatherGlow").is_visible_in_tree(), "distant glow hidden")
		var before: int = inventory.count_of(&"field_herb_mugwort")
		await position_at(field, herb.global_position + Vector2(23, 16))
		if expect(await wait_for(func(): return herb.get_node("GatherGlow").is_visible_in_tree(), 1400), "near herb glow"):
			await press_space()
			expect(await wait_for(func(): return inventory.count_of(&"field_herb_mugwort") > before, 5000), "Space gathers named herb")
			expect(not herb.visible, "collected herb disappears")
	expect(field.find_child("SceneObject_hunting_stairs", true, false) == null, "no miniature stairs")
	field = await take(field, HUNT)
	if field != null:
		var adventure := root.get_node("AdventureRuntime")
		var features: Dictionary = adventure.get("_features")
		var dog: Node2D = features.get("forest_wolf_trail", {}).get("node")
		if expect(is_instance_valid(dog), "world dog exists"):
			var before := dog.position
			await create_timer(0.35).timeout
			expect(dog.position.distance_to(before) > 4.0, "dog patrols")
		var clue: Node2D = features.get("forest_old_marks", {}).get("node")
		if expect(is_instance_valid(clue), "optional old marks spawned"):
			await position_at(field, clue.global_position + Vector2(21, 8))
			if expect(await wait_for(func(): return adventure.get("_near") == "forest_old_marks", 1400), "old marks glow within reach"):
				await press_space()
				if expect(adventure.get_adventure_state().modal_open, "Space opens clue"):
					adventure.get("_dialog").confirmed.emit()
					expect(not features.has("forest_old_marks"), "read clue removes node and hot spot")
		field = await take(field, FOREST)
	finish()
