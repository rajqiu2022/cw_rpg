extends SceneTree

# Headless UI screenshot helper.
# Usage from game/:
#   godot --headless --script test/capture_ui.gd -- scene=quest
# Output:
#   screenshots/<target>_<timestamp>.png

var _capture_target: String = "main_menu"
var _quest_capture_filter: String = ""
var _field_stage: String = ""
var _party_count: int = 1
var _battle_arena: StringName = &"bamboo_platforms"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("scene="):
			_capture_target = arg.replace("scene=", "")
		elif arg.begins_with("battle="):
			_capture_target = "battle:" + arg.replace("battle=", "")
		elif arg.begins_with("field="):
			_capture_target = "field:" + arg.replace("field=", "")
		elif arg.begins_with("quest_filter="):
			_quest_capture_filter = arg.replace("quest_filter=", "")
		elif arg.begins_with("stage="):
			_field_stage = arg.replace("stage=", "")
		elif arg.begins_with("party="):
			_party_count = maxi(1, int(arg.replace("party=", "")))
		elif arg.begins_with("arena="):
			_battle_arena = StringName(arg.replace("arena=", ""))

	DirAccess.make_dir_recursive_absolute("screenshots")
	print("[CaptureUI] target=%s" % _capture_target)

	if _capture_target == "main_menu":
		await _capture_main_menu()
	elif _capture_target == "quest":
		await _capture_quest()
	elif _capture_target == "quest_choice":
		await _capture_quest_choice()
	elif _capture_target == "inventory":
		await _capture_panel("inventory", "res://scenes/ui/inventory_panel.tscn")
	elif _capture_target == "equipment":
		await _capture_panel("equipment", "res://scenes/ui/equipment_panel.tscn")
	elif _capture_target == "character":
		await _capture_character_panel()
	elif _capture_target == "skill":
		await _capture_skill_panel()
	elif _capture_target == "shop":
		await _capture_shop()
	elif _capture_target == "victory":
		await _capture_result("victory", "res://scenes/result_victory.tscn")
	elif _capture_target == "defeat":
		await _capture_result("defeat", "res://scenes/result_defeat.tscn")
	elif _capture_target == "chapter_end":
		await _capture_chapter_end()
	elif _capture_target == "gm":
		await _capture_gm_console()
	elif _capture_target == "world_map_panel":
		await _capture_world_map_panel()
	elif _capture_target.begins_with("battle:"):
		await _capture_battle(_capture_target.replace("battle:", ""))
	elif _capture_target.begins_with("field:"):
		await _capture_field(_capture_target.replace("field:", ""))
	else:
		print("[CaptureUI] unknown target: %s" % _capture_target)
		_finish(1)


func _capture_main_menu() -> void:
	change_scene_to_file("res://scenes/main_menu.tscn")
	await _wait_frames(5)
	_screenshot("main_menu")
	_finish(0)


func _capture_world_map_panel() -> void:
	var router := get_root().get_node_or_null("SceneRouter")
	if router != null:
		router.set("_current_field_id", &"ch1_s2_qingfeng")
	var panel := _instantiate_panel("res://scenes/ui/world_map_panel.tscn")
	get_root().add_child(panel)
	await _wait_frames(3)
	panel.call("open")
	await _wait_frames(6)
	_screenshot("world_map_panel_v8")
	_finish(0)


func _capture_gm_console() -> void:
	await _wait_frames(4)
	var gm := get_root().get_node_or_null("GMConsole")
	if gm == null or gm.get_node_or_null("GMFloatingButton") == null:
		push_error("[CaptureUI] GM console is unavailable; pass show_gm=true in a debug build")
		_finish(1)
		return
	if _field_stage == "damage":
		var modifiers := DamageModifierStack.new()
		modifiers.add_outgoing_bonus("影杀", 0.20)
		var breakdown := BattleFormula.calc_damage_breakdown(94, 34, 165, 41, 1.03, 2.65, false, false, 184, 303, 1.0, "", modifiers)
		breakdown.annotate("冷孤云", "赵无忌", "孤云九式")
		gm.call("record_damage_breakdown", breakdown)
	gm.call("_toggle_panel")
	if _field_stage == "palm_equipment":
		gm.call("_refresh_item_options", "掌法")
	await _wait_frames(4)
	_screenshot("gm_console_damage" if _field_stage == "damage" else ("gm_console_palm_equipment" if _field_stage == "palm_equipment" else "gm_console"))
	_finish(0)


func _capture_quest() -> void:
	_seed_quest_states()
	if _field_stage == "clue_records":
		var game_state := get_root().get_node_or_null("GameState")
		var quest_manager := get_root().get_node_or_null("QuestManager")
		if game_state != null:
			game_state.call("set_flag", &"zhuwei_guard_briefed", true)
			game_state.call("set_flag", &"zhuwei_inn_clue", true)
		if quest_manager != null:
			var states: Dictionary = quest_manager.get("states")
			states.clear()
			states[&"q_ch1_main_village_inquiry"] = QuestDef.Status.IN_PROGRESS
	var panel := _instantiate_panel("res://scenes/ui/quest_panel.tscn")
	get_root().add_child(panel)
	await _wait_frames(2)
	panel.call("open")
	if _field_stage == "clue_records":
		panel.set("_selected_qid", &"q_ch1_main_village_inquiry")
		panel.call("_refresh")
	if _quest_capture_filter != "":
		panel.call("_set_kind_filter", _quest_capture_filter)
	if _field_stage == "reward_tip":
		panel.call("_set_status_page", "done")
		var reward_list := panel.get_node_or_null("Panel/RewardList")
		var reward_button := _find_first_texture_button(reward_list)
		if reward_button != null:
			reward_button.pressed.emit()
	await _wait_frames(6)
	_screenshot("quest_clue_records" if _field_stage == "clue_records" else "quest_" + (_quest_capture_filter if _quest_capture_filter != "" else "main"))
	_finish(0)


func _capture_quest_choice() -> void:
	_seed_quest_states()
	var panel := _instantiate_panel("res://scenes/ui/quest_panel.tscn")
	get_root().add_child(panel)
	await _wait_frames(2)
	panel.call("open")
	panel.call("_open_chapter_menu")
	await _wait_frames(6)
	_screenshot("quest_choice")
	_finish(0)


func _capture_panel(name: String, path: String) -> void:
	if name == "inventory" and _field_stage == "readable":
		var inventory := get_root().get_node_or_null("Inventory")
		if inventory != null:
			inventory.call("reset_for_new_game")
			inventory.call("add_item", &"qingming_sword_record", 1)
	var panel := _instantiate_panel(path)
	get_root().add_child(panel)
	await _wait_frames(2)
	panel.call("open")
	if name == "inventory" and _field_stage == "readable":
		var item := load("res://data/items/qingming_sword_record.tres") as Item
		panel.call("_open_reading", item)
	await _wait_frames(6)
	_screenshot("inventory_readable" if name == "inventory" and _field_stage == "readable" else name)
	_finish(0)


func _capture_skill_panel() -> void:
	# Autoload _ready runs after this SceneTree script starts. Seed only after one
	# frame so GameState does not replace the prepared player with its defaults.
	await process_frame
	var game_state := get_root().get_node_or_null("GameState")
	if game_state != null:
		game_state.call("reset_for_new_game")
		var player := game_state.get("player") as CharacterStats
		if player != null:
			player.insight = 6 if _field_stage == "mind_gate" else 20
		game_state.call("learn_skill", &"linxi_basic_sword_two")
		game_state.call("learn_skill", &"linxi_inner_breath")
		if _field_stage == "mind_gate":
			game_state.call("debug_force_learn_skill", &"jingang_tempered_meridians")
		if _field_stage == "icons":
			for skill_id: StringName in [&"canghai_zhenyue_palms", &"examiner_staff_sweep", &"gufeng_kaishan_yidao", &"toxic_needle", &"mingwu_mingwu_bu", &"qinghe_returning_breath"]:
				game_state.call("learn_skill", skill_id)
		if _field_stage == "legendary_detail":
			game_state.call("debug_force_learn_skill", &"canghai_zhenyue_palms")
		game_state.set("training_points_total", 120)
		game_state.set("training_points_available", 120)
	var panel := _instantiate_panel("res://scenes/ui/skill_panel.tscn")
	get_root().add_child(panel)
	await _wait_frames(2)
	panel.call("open")
	if _field_stage in ["mind", "mind_gate"]:
		panel.set("_runtime_group", "mind")
		panel.set("_runtime_route", "general")
		if _field_stage == "mind_gate":
			panel.set("_runtime_selected_id", &"jingang_tempered_meridians")
		panel.call("_refresh_runtime_v2")
	elif _field_stage == "legendary_detail":
		panel.set("_runtime_group", "move")
		panel.set("_runtime_route", "palm")
		panel.set("_runtime_selected_id", &"canghai_zhenyue_palms")
		panel.call("_refresh_runtime_v2")
	await _wait_frames(6)
	_screenshot("skill_legendary_detail" if _field_stage == "legendary_detail" else ("skill_mind_gate" if _field_stage == "mind_gate" else ("skill_mind" if _field_stage == "mind" else ("skill_icons" if _field_stage == "icons" else "skill"))))
	_finish(0)


func _capture_character_panel() -> void:
	var game_state := get_root().get_node_or_null("GameState")
	var inventory := get_root().get_node_or_null("Inventory")
	if game_state != null:
		game_state.call("reset_for_new_game")
		game_state.call("set_flag", &"companion_tang_xingzhou_joined", true)
		game_state.call("set_flag", &"companion_shen_qinghe_joined", true)
		game_state.call("add_companion", &"tang_xingzhou")
		game_state.call("add_companion", &"shen_qinghe")
	if inventory != null:
		inventory.call("reset_for_new_game")
		inventory.call("add_item", &"wooden_staff", 1)
		inventory.call("add_item", &"linxi_iron_sword", 1)
		inventory.call("add_item", &"cloth_armor", 1)
		if _field_stage == "equipment_compare":
			inventory.call("add_item", &"heart_guard_armor", 1)
			var cloth_instance := ""
			for entry: Dictionary in inventory.get("slots"):
				var compare_item := entry.get("item") as Item
				if compare_item != null and compare_item.item_id == &"cloth_armor":
					cloth_instance = String(entry.get("instance_id", ""))
					break
			if not cloth_instance.is_empty():
				inventory.call("equip_instance_for", &"protagonist", cloth_instance)
		if _field_stage == "equipment_quality":
			inventory.call("add_item", &"xuantong_fist_gauntlets", 1)
			inventory.call("add_item", &"immortal_gauntlets", 1)
			inventory.call("add_item", &"seven_star_sword", 1)
		if _field_stage == "occupied_equipment":
			inventory.call("add_item", &"linxi_iron_sword", 1)
			for entry: Dictionary in inventory.get("slots"):
				var occupied_item := entry.get("item") as Item
				if occupied_item != null and occupied_item.item_id == &"linxi_iron_sword":
					inventory.call("equip_instance_for", &"shen_qinghe", String(entry.get("instance_id", "")))
					break
		if _field_stage == "use_linxi_jiu" and int(inventory.call("count_of", &"linxi_jiu")) <= 0:
			inventory.call("add_item", &"linxi_jiu", 1)
	var panel := _instantiate_panel("res://scenes/ui/character_panel.tscn")
	get_root().add_child(panel)
	await _wait_frames(3)
	panel.call("open")
	if _field_stage == "use_linxi_jiu":
		panel.call("_use_consumable_for", &"protagonist", &"linxi_jiu")
	elif _field_stage == "equipment_compare" and inventory != null:
		for entry: Dictionary in inventory.get("slots"):
			var compare_item := entry.get("item") as Item
			if compare_item != null and compare_item.item_id == &"heart_guard_armor":
				panel.call("_select_inventory_entry", entry)
				break
	await _wait_frames(8)
	var screenshot_name := "character_item_tip" if _field_stage == "use_linxi_jiu" else ("character_equipment_compare" if _field_stage == "equipment_compare" else ("character_equipment_occupied" if _field_stage == "occupied_equipment" else ("character_equipment_quality" if _field_stage == "equipment_quality" else "character")))
	_screenshot(screenshot_name)
	_finish(0)


func _capture_shop() -> void:
	var game_state := get_root().get_node_or_null("GameState")
	if game_state != null:
		game_state.set("gold", 100)
	var router := get_root().get_node_or_null("SceneRouter")
	if router != null:
		router.set("_shop_payload", {"shop_id": &"linxi_apothecary"})
	change_scene_to_file("res://scenes/shop.tscn")
	await _wait_frames(8)
	if _field_stage == "sell_tab":
		var sell_tab := current_scene.get_node_or_null("Panel/SellTabButton") as TextureButton
		if sell_tab == null:
			push_error("[CaptureUI] shop sell tab not found")
			_finish(1)
			return
		sell_tab.pressed.emit()
		await _wait_frames(3)
		_screenshot("shop_sell_tab")
		_finish(0)
		return
	if _field_stage == "base":
		_screenshot("shop_base")
		_finish(0)
		return
	var plus_button := _find_button_by_text(current_scene, "+")
	if plus_button == null:
		push_error("[CaptureUI] shop quantity button not found")
		_finish(1)
		return
	plus_button.pressed.emit()
	await _wait_frames(3)
	var confirm_button := current_scene.get_node_or_null("Panel/ConfirmTradeButton") as Button
	if confirm_button == null or confirm_button.disabled:
		push_error("[CaptureUI] shop confirm button is unavailable")
		_finish(1)
		return
	confirm_button.pressed.emit()
	await _wait_frames(4)
	var overlay := current_scene.get_node_or_null("Panel/TradeConfirmOverlay") as Control
	var prompt := current_scene.get_node_or_null("Panel/TradeConfirmOverlay/Dialog/Margin/VBox/ConfirmPrompt") as Label
	if overlay == null or not overlay.visible or prompt == null or "15" not in prompt.text:
		push_error("[CaptureUI] shop confirmation did not open with the expected total")
		_finish(1)
		return
	_screenshot("shop_confirm")
	_finish(0)


func _find_button_by_text(root_node: Node, target_text: String) -> Button:
	if root_node is Button and (root_node as Button).text == target_text:
		return root_node as Button
	for child: Node in root_node.get_children():
		var match_button := _find_button_by_text(child, target_text)
		if match_button != null:
			return match_button
	return null


func _find_first_texture_button(root_node: Node) -> TextureButton:
	if root_node == null:
		return null
	if root_node is TextureButton:
		return root_node as TextureButton
	for child: Node in root_node.get_children():
		var match_button := _find_first_texture_button(child)
		if match_button != null:
			return match_button
	return null


func _capture_result(name: String, path: String) -> void:
	var router := get_root().get_node_or_null("SceneRouter")
	if router != null:
		router.set("_result_payload", {"gold": 11, "exp": 40, "return_scene": &"linxi_tutorial"})
	var scene := load(path) as PackedScene
	if scene == null:
		_finish(1)
		return
	get_root().add_child(scene.instantiate())
	await _wait_frames(8)
	_screenshot(name)
	_finish(0)


func _capture_chapter_end() -> void:
	get_root().set_meta("skip_chapter_end_autosave", true)
	var router := get_root().get_node_or_null("SceneRouter")
	if router != null:
		router.set("_result_payload", {"chapter": 1})
	var scene := load("res://scenes/chapter_end.tscn") as PackedScene
	if scene == null:
		_finish(1)
		return
	get_root().add_child(scene.instantiate())
	await _wait_frames(8)
	_screenshot("chapter_end")
	_finish(0)


func _capture_field(scene_id: String) -> void:
	if scene_id == "":
		scene_id = "linxi_tutorial"
	if _field_stage == "quest_tracker":
		_seed_field_quest_tracker()
	elif _field_stage == "staff_weapon":
		var inventory := get_root().get_node_or_null("Inventory")
		if inventory != null:
			inventory.call("reset_for_new_game")
			inventory.call("add_item", &"wooden_staff", 1)
			for entry: Dictionary in inventory.get("slots"):
				var item := entry.get("item") as Item
				if item != null and item.item_id == &"wooden_staff":
					inventory.call("equip_instance", String(entry.get("instance_id", "")))
					break
	elif scene_id == "linxi_master_hall" and _field_stage in ["archive_hidden", "archive_revealed"]:
		var game_state := get_root().get_node_or_null("GameState")
		if game_state != null:
			game_state.call("reset_for_new_game")
			if _field_stage == "archive_revealed":
				game_state.call("set_flag", &"ch6_archive_entry_found", true)
	elif _field_stage == "occluder_demo" and scene_id in ["ch1_s2_qingfeng", "ch2_s1_zhuwei_market"]:
		var game_state := get_root().get_node_or_null("GameState")
		if game_state != null:
			if scene_id == "ch1_s2_qingfeng":
				game_state.call("set_flag", &"entered_zhuwei_village", true)
			else:
				game_state.call("set_flag", &"seen_ch2_zhuwei_intro", true)
	elif scene_id == "ch1_s2_qingfeng" and _field_stage == "forest_exit":
		var game_state := get_root().get_node_or_null("GameState")
		if game_state != null:
			game_state.call("set_flag", &"zhuwei_village_inquiry_done", true)
	elif scene_id == "ch1_s2_qingfeng" and _field_stage in ["side_accept", "anxious_dialog", "vegetable_dialog"]:
		var game_state := get_root().get_node_or_null("GameState")
		if game_state != null:
			game_state.call("set_flag", &"entered_zhuwei_village", true)
	elif scene_id == "ch1_s2_qingfeng" and _field_stage == "npc_motion":
		var game_state := get_root().get_node_or_null("GameState")
		if game_state != null:
			game_state.call("set_flag", &"entered_zhuwei_village", true)
	elif scene_id == "ch1_s3_zhuwei_forest" and _field_stage == "cave_locked":
		var game_state := get_root().get_node_or_null("GameState")
		if game_state != null:
			game_state.call("set_flag", &"entered_zhuwei_forest", true)
			game_state.call("set_flag", &"zhuwei_village_inquiry_done", true)
	elif scene_id == "ch1_s4_cave_deep_den" and _field_stage == "wolf_active":
		var quest_manager := get_root().get_node_or_null("QuestManager")
		if quest_manager != null:
			quest_manager.call("accept", &"q_ch1_main_zhuwei_wilds")
	elif scene_id == "ch1_s3_ruin_inner" and _field_stage == "zhao_post_boss":
		var game_state := get_root().get_node_or_null("GameState")
		if game_state != null:
			game_state.call("set_flag", &"master_training_done", true)
			game_state.call("set_flag", &"defeated_boss_zhao_wuji", true)
	elif scene_id == "ch1_s1_road" and _field_stage == "cliff_herb":
		var game_state := get_root().get_node_or_null("GameState")
		var quest_manager := get_root().get_node_or_null("QuestManager")
		if game_state != null:
			game_state.call("set_flag", &"seen_ch1_road_intro", true)
			game_state.call("set_flag", &"master_training_done", true)
		if quest_manager != null:
			quest_manager.call("accept", &"q_ch1_side_02_cliff_herb")
	elif scene_id == "ch1_s1_road" and _field_stage == "bandit_cave_locked":
		var game_state := get_root().get_node_or_null("GameState")
		if game_state != null:
			game_state.call("set_flag", &"seen_ch1_road_intro", true)
	if scene_id == "linxi_tutorial" and _field_stage == "post_sword":
		var game_state := get_root().get_node_or_null("GameState")
		if game_state != null:
			var flags: Dictionary = game_state.get("flags")
			flags["master_farewell_done"] = true
			flags["got_sword"] = true
	elif scene_id == "linxi_tutorial" and _field_stage == "blacksmith_conversation":
		var game_state := get_root().get_node_or_null("GameState")
		if game_state != null:
			var flags: Dictionary = game_state.get("flags")
			flags["master_farewell_done"] = true
			flags.erase("got_sword")
	var router := get_root().get_node_or_null("SceneRouter")
	if router != null:
		var scene_path: String = router.call("get_field_scene_path", StringName(scene_id))
		var spawn := Vector2(0.5, 0.8)
		var scene_def: Resource = load("res://data/scenes/%s.tres" % scene_id)
		if scene_def != null and scene_def.get("player_spawn") is Vector2:
			spawn = scene_def.get("player_spawn")
		var payload := {"scene_id": StringName(scene_id), "player_spawn": spawn}
		if scene_id == "ch1_s3_ruin_inner" and _field_stage == "zhao_post_boss":
			payload["pending_action"] = "dialog:ch1_s3_ruin_after_boss"
		router.set("_field_payload", payload)
		router.set("_current_field_id", StringName(scene_id))
		change_scene_to_file(scene_path)
	await _wait_frames(12)
	if _field_stage == "militia_coach_conversation":
		var coach: NPCNode = null
		for candidate: Node in get_nodes_in_group("npc"):
			if candidate is NPCNode and String(candidate.get("npc_id")) == "linxi_south_militia_coach":
				coach = candidate as NPCNode
				break
		var field_scene: Node = current_scene
		var player_node: Node2D = null
		if field_scene != null:
			player_node = field_scene.get("_player") as Node2D
		if coach == null or player_node == null:
			push_error("[CaptureUI] militia coach conversation setup failed")
			_finish(1)
			return
		player_node.global_position = coach.global_position + Vector2(-72.0, 58.0)
		coach.begin_conversation(player_node.global_position)
		await _wait_frames(8)
	elif _field_stage in ["blacksmith_conversation", "blacksmith_conversation_right"]:
		var blacksmith: NPCNode = null
		for candidate: Node in get_nodes_in_group("npc"):
			if candidate is NPCNode and String(candidate.get("npc_id")).begins_with("duqingshan"):
				blacksmith = candidate as NPCNode
				break
		var field_scene: Node = current_scene
		var player_node: Node2D = null
		if field_scene != null:
			player_node = field_scene.get("_player") as Node2D
		if blacksmith == null or player_node == null:
			push_error("[CaptureUI] blacksmith conversation setup failed")
			_finish(1)
			return
		var horizontal_offset := 92.0 if _field_stage == "blacksmith_conversation_right" else -92.0
		player_node.global_position = blacksmith.global_position + Vector2(horizontal_offset, 12.0)
		blacksmith.begin_conversation(player_node.global_position)
		await _wait_frames(8)
	elif _field_stage == "scroll_center":
		var field_scene: Node = current_scene
		if field_scene != null:
			var player_variant: Variant = field_scene.get("_player")
			var player_node: Node2D = player_variant as Node2D
			if player_node != null:
				player_node.position = Vector2(3218.0, 968.0)
				await _wait_frames(12)
	elif _field_stage in ["world_connector", "world_luoyang"] and scene_id == "world_map_jianghu":
		var field_scene: Node = current_scene
		if field_scene != null:
			var player_node := field_scene.get("_player") as Node2D
			var world_size := field_scene.get("_world_size") as Vector2
			var normalized := Vector2(0.325, 0.718) if _field_stage == "world_connector" else Vector2(0.704, 0.606)
			if player_node != null:
				player_node.position = Vector2(world_size.x * normalized.x, world_size.y * normalized.y)
				field_scene.call("_on_player_moved", player_node.global_position)
				await _wait_frames(12)
	elif _field_stage == "portal_audit" and scene_id == "linxi_village_center":
		var field_scene: Node = current_scene
		if field_scene != null:
			var player_node := field_scene.get("_player") as Node2D
			var world_size := field_scene.get("_world_size") as Vector2
			if player_node != null:
				player_node.position = Vector2(world_size.x * 0.60, world_size.y * 0.62)
				await _wait_frames(12)
	elif _field_stage == "occluder_demo":
		var field_scene: Node = current_scene
		if field_scene != null:
			var player_node := field_scene.get("_player") as Node2D
			var world_size := field_scene.get("_world_size") as Vector2
			var demo_positions := {
				"linxi_village_center": Vector2(0.72, 0.780),
				"linxi_village_scrollmap": Vector2(0.36, 0.61),
				"ch1_s2_qingfeng": Vector2(0.29, 0.78),
				"ch2_s1_zhuwei_market": Vector2(0.70, 0.55),
			}
			if player_node != null and demo_positions.has(scene_id):
				var normalized: Vector2 = demo_positions[scene_id]
				player_node.position = Vector2(world_size.x * normalized.x, world_size.y * normalized.y)
				field_scene.call("_on_player_moved", player_node.global_position)
				await _wait_frames(12)
	elif _field_stage == "forest_exit" and scene_id == "ch1_s2_qingfeng":
		var field_scene: Node = current_scene
		if field_scene != null:
			var player_node := field_scene.get("_player") as Node2D
			var world_size := field_scene.get("_world_size") as Vector2
			if player_node != null:
				player_node.position = Vector2(world_size.x * 0.925, world_size.y * 0.735)
				await _wait_frames(12)
	elif _field_stage == "side_accept" and scene_id == "ch1_s2_qingfeng":
		var quest_manager := get_root().get_node_or_null("QuestManager")
		if quest_manager != null:
			quest_manager.call("accept", &"q_ch1_side_12_forest_medicine")
			await _wait_frames(4)
	elif _field_stage == "cave_locked" and scene_id == "ch1_s3_zhuwei_forest":
		var field_scene: Node = current_scene
		if field_scene != null:
			var player_node := field_scene.get("_player") as Node2D
			var world_size := field_scene.get("_world_size") as Vector2
			if player_node != null:
				player_node.position = Vector2(world_size.x * 0.88, world_size.y * 0.12)
				field_scene.call("_on_player_moved", player_node.global_position)
				await _wait_frames(6)
				field_scene.call("_on_player_interacted")
				await _wait_frames(4)
	elif _field_stage == "cliff_herb" and scene_id == "ch1_s1_road":
		var field_scene: Node = current_scene
		if field_scene != null:
			var player_node := field_scene.get("_player") as Node2D
			var world_size := field_scene.get("_world_size") as Vector2
			if player_node != null:
				player_node.position = Vector2(world_size.x * 0.825, world_size.y * 0.515)
				field_scene.call("_on_player_moved", player_node.global_position)
				await _wait_frames(10)
	elif _field_stage == "npc_motion" and scene_id == "ch1_s2_qingfeng":
		await _wait_frames(30)
	elif _field_stage in ["anxious_dialog", "vegetable_dialog"] and scene_id == "ch1_s2_qingfeng":
		var target_id := "crying_woman" if _field_stage == "anxious_dialog" else "vegetable_vendor"
		var target_npc: NPCNode = null
		for candidate: Node in get_nodes_in_group("npc"):
			if candidate is NPCNode and String(candidate.get("npc_id")) == target_id:
				target_npc = candidate as NPCNode
				break
		var field_scene: Node = current_scene
		var player_node: Node2D = null
		if field_scene != null:
			player_node = field_scene.get("_player") as Node2D
		if target_npc != null and player_node != null:
			player_node.global_position = target_npc.global_position + Vector2(-76.0, 14.0)
			target_npc.begin_conversation(player_node.global_position)
			var dialog_player := get_root().get_node_or_null("DialogPlayer")
			var dialog_id := "ch1_s2_crying_woman" if _field_stage == "anxious_dialog" else "ch1_s2_vegetable_vendor"
			var dialog := load("res://data/dialogs/%s.tres" % dialog_id) as DialogScript
			if dialog_player != null and dialog != null:
				dialog_player.call("set_default_portrait", String(target_npc.get("portrait_path")))
				dialog_player.call("set_default_speaker", String(target_npc.get("npc_name")))
				dialog_player.call("play", dialog)
			await _wait_frames(8)
	elif _field_stage == "bandit_cave_locked" and scene_id == "ch1_s1_road":
		var field_scene: Node = current_scene
		if field_scene != null:
			var player_node := field_scene.get("_player") as Node2D
			var world_size := field_scene.get("_world_size") as Vector2
			if player_node != null:
				player_node.position = Vector2(world_size.x * 0.705, world_size.y * 0.585)
				field_scene.call("_on_player_moved", player_node.global_position)
				await _wait_frames(6)
				field_scene.call("_on_player_interacted")
				await _wait_frames(6)
	elif _field_stage == "inventory_overlay":
		var field_scene: Node = current_scene
		if field_scene != null:
			var player_node := field_scene.get("_player") as Node2D
			if player_node != null:
				# Deliberately use the highest legal world z-index and place the actor
				# behind the detail pane. The system CanvasLayer must still cover it.
				player_node.z_index = 4096
				player_node.position = Vector2(1510.0, 760.0)
			field_scene.call("_open_inventory_panel")
			await _wait_frames(8)
	elif _field_stage == "zhao_post_boss" and scene_id == "ch1_s3_ruin_inner":
		var dialog_player := get_root().get_node_or_null("DialogPlayer")
		if dialog_player != null:
			for _step in range(3):
				dialog_player.call("advance")
				await _wait_frames(4)
			await _wait_frames(18)
	if _field_stage == "advance_dialog":
		var dialog_player := get_root().get_node_or_null("DialogPlayer")
		if dialog_player != null:
			dialog_player.call("advance")
			await _wait_frames(3)
	elif _field_stage == "finish_dialog":
		var dialog_player := get_root().get_node_or_null("DialogPlayer")
		if dialog_player != null:
			for _step in range(8):
				if not bool(dialog_player.call("is_playing")):
					break
				dialog_player.call("advance")
				await _wait_frames(2)
	_screenshot("field_%s" % scene_id)
	_finish(0)


func _seed_field_quest_tracker() -> void:
	var quest_manager := get_root().get_node_or_null("QuestManager")
	if quest_manager == null:
		return
	var states: Dictionary = quest_manager.get("states")
	states.clear()
	states[&"q_ch1_main_zhuwei"] = QuestDef.Status.IN_PROGRESS
	states[&"q_ch1_side_02_cliff_herb"] = QuestDef.Status.IN_PROGRESS
	quest_manager.set("states", states)
	quest_manager.call("set_tracked_side_quest", &"q_ch1_side_02_cliff_herb")
	quest_manager.emit_signal("active_quests_changed")


func _capture_battle(enemy_id: String) -> void:
	if enemy_id == "":
		enemy_id = "thug_lone"
	if _field_stage in ["staff_weapon", "staff_attack"]:
		await process_frame
		var inventory := get_root().get_node_or_null("Inventory")
		if inventory != null:
			inventory.call("reset_for_new_game")
			inventory.call("add_item", &"wooden_staff", 1)
			for entry: Dictionary in inventory.get("slots"):
				var item := entry.get("item") as Item
				if item != null and item.item_id == &"wooden_staff":
					inventory.call("equip_instance", String(entry.get("instance_id", "")))
					break
	if _field_stage.begins_with("legendary_"):
		# Autoload defaults settle on the first frame; seed the prototype after it.
		await process_frame
		var game_state := get_root().get_node_or_null("GameState")
		if game_state != null:
			game_state.call("reset_for_new_game")
			var player := game_state.get("player") as CharacterStats
			if player != null:
				player.insight = 20
				player.mp = player.max_mp
			game_state.call("learn_skill", &"canghai_zhenyue_palms")
	var enemy_ids: Array[StringName] = []
	for raw_id in enemy_id.split("|"):
		if not raw_id.is_empty():
			enemy_ids.append(StringName(raw_id))
	var router := get_root().get_node_or_null("SceneRouter")
	if router != null:
		var player_party: Array[Dictionary] = []
		for index in range(1, mini(_party_count, 5)):
			var is_tang := index % 2 == 1
			var companion_prefix := "tang_xingzhou" if is_tang else "shen_qinghe"
			var companion_root := "res://art/sprites/battle/companions_v4/%s" % companion_prefix
			player_party.append({
				"unit_id": StringName("ally_%d" % (index + 1)),
				"display_name": "唐行舟" if is_tang else "沈青禾",
				"actor_path": "%s/%s_ready_01.png" % [companion_root, companion_prefix],
				"battle_sprite_root": companion_root,
				"battle_sprite_prefix": companion_prefix,
				"scale": 0.42,
				"hp": 150,
				"max_hp": 150,
				"mp": 36,
				"max_mp": 36,
				"attack": 18,
				"defense": 9,
				"speed": 12,
			})
		var battle_payload := {"enemy_id": String(enemy_ids[0]), "enemy_ids": enemy_ids, "player_party": player_party, "battle_arena": _battle_arena, "return_scene": &"linxi_tutorial"}
		if _field_stage == "sparring":
			battle_payload["battle_mode"] = &"sparring"
			battle_payload["spar_id"] = &"capture_spar"
			battle_payload["spar_opponent_name"] = "唐行舟"
		router.set("_battle_payload", battle_payload)
	change_scene_to_file("res://scenes/battle.tscn")
	await _wait_for_battle_player_turn()
	var battle := current_scene
	if _field_stage in ["legendary_intro", "legendary_impact"] and battle != null:
		var skill_index := -1
		var player_skills: Array = battle.get("_player_skills") as Array
		for index in range(player_skills.size()):
			var skill := player_skills[index] as Skill
			if skill != null and skill.skill_id == &"canghai_zhenyue_palms":
				skill_index = index
				break
		if skill_index < 0:
			push_error("[CaptureUI] legendary prototype skill is unavailable")
			_finish(1)
			return
		battle.call("_player_action_skill_use", skill_index)
		await create_timer(0.72 if _field_stage == "legendary_intro" else 3.55).timeout
		_screenshot("battle_canghai_%s" % _field_stage.trim_prefix("legendary_"))
		await _wait_for_battle_action_settle(battle)
		_finish(0)
		return
	if _field_stage == "skills" and battle != null:
		battle.call("_show_skill_popup")
		await _wait_frames(4)
	if _field_stage == "status_hover" and battle != null and not enemy_ids.is_empty():
		var formation := battle.get("formation_view") as BattleFormationView
		if formation != null:
			var enemy_unit_id := StringName("%s_1" % String(enemy_ids[0]))
			formation.update_unit_effects(enemy_unit_id, {"internal_injury": 36, "poison": 2})
			await process_frame
			var status_widget := formation.status_widgets.get(enemy_unit_id) as VBoxContainer
			var status_row := status_widget.get_node_or_null("StatusAnchor/StatusIcons") as HBoxContainer if status_widget != null else null
			var status_icon := status_row.get_child(0) as Button if status_row != null and status_row.get_child_count() > 0 else null
			if status_icon != null:
				status_icon.mouse_entered.emit()
				await process_frame
	if _field_stage in ["attack", "staff_attack"] and battle != null:
		print("[CaptureUI] battle_state_before_attack=%s" % str(battle.get("_state")))
		battle.call("_player_action_skill_use", 0)
		await process_frame
		if int(battle.get("_team_pending_skill_index")) >= 0 and not enemy_ids.is_empty():
			battle.call("_on_team_target_selected", StringName("%s_1" % String(enemy_ids[0])))
		# Normal attacks need the actor lunge before their four-frame impact VFX.
		await create_timer(1.05).timeout
	var attack_suffix := "_staff_attack" if _field_stage == "staff_attack" else ("_attack" if _field_stage == "attack" else ("_sparring" if _field_stage == "sparring" else ("_status_hover" if _field_stage == "status_hover" else "")))
	_screenshot("battle_%s%s" % [enemy_id.replace("|", "_"), attack_suffix])
	if _field_stage in ["attack", "staff_attack"]:
		# Let the action and enemy response finish before quitting. Terminating the
		# SceneTree while attack tweens are still awaiting can crash the renderer
		# after an otherwise valid screenshot has been written.
		await _wait_for_battle_action_settle(battle)
	_finish(0)


func _seed_quest_states() -> void:
	var quest_manager := get_root().get_node_or_null("QuestManager")
	if quest_manager == null:
		return
	var states: Dictionary = quest_manager.get("states")
	states.clear()
	states[&"q_ch1_main_road"] = QuestDef.Status.IN_PROGRESS
	states[&"q_ch1_side_01_rescue_husband"] = QuestDef.Status.IN_PROGRESS
	quest_manager.set("states", states)
	quest_manager.emit_signal("active_quests_changed")


func _instantiate_panel(path: String) -> Node:
	var scene := load(path) as PackedScene
	if scene == null:
		push_error("[CaptureUI] cannot load: %s" % path)
		return Node.new()
	return scene.instantiate()


func _screenshot(name: String) -> void:
	var display_name := DisplayServer.get_name()
	if display_name == "headless":
		print("[CaptureUI] screenshot skipped for headless display")
		return
	var ts := Time.get_unix_time_from_system()
	var fname := "screenshots/%s_%d.png" % [name, ts]
	var tex := get_root().get_viewport().get_texture()
	if tex == null:
		print("[CaptureUI] screenshot texture is null")
		return
	var img := tex.get_image()
	if img == null:
		print("[CaptureUI] screenshot image is null")
		return
	var err := img.save_png(fname)
	if err == OK:
		print("[CaptureUI] saved=%s" % fname)
	else:
		print("[CaptureUI] save failed err=%d" % err)


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _wait_for_battle_player_turn() -> void:
	const PLAYER_TURN_STATE := 1
	# Battle actors enter on real-time tweens. Counting render frames can exhaust the
	# timeout almost instantly on an uncapped desktop capture run, leaving us with
	# a misleading screenshot of the entrance animation.
	for _i in range(300):
		var battle := current_scene
		if battle != null and battle.get("_state") == PLAYER_TURN_STATE:
			# Give ready poses and the active-unit arrow one frame to settle.
			await create_timer(0.08).timeout
			return
		await create_timer(0.02).timeout
	push_error("[CaptureUI] battle did not reach player turn before timeout")


func _wait_for_battle_action_settle(battle: Node) -> void:
	const PLAYER_TURN_STATE := 1
	const ENDED_STATE := 5
	for _i in range(600):
		if not is_instance_valid(battle) or current_scene != battle:
			return
		var state := int(battle.get("_state"))
		if state == PLAYER_TURN_STATE or state == ENDED_STATE:
			return
		await create_timer(0.02).timeout
	push_error("[CaptureUI] battle action did not settle before timeout")


func _finish(code: int) -> void:
	if code != 0:
		push_error("[CaptureUI] exit code %d" % code)
	quit(code)
