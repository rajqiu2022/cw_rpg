extends Node

var _failed := false


func _ready() -> void:
	_run()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] ", message)
	else:
		_failed = true
		push_error("[FAIL] " + message)


func _run() -> void:
	var game_state := get_node_or_null("/root/GameState")
	var inventory := get_node_or_null("/root/Inventory")
	_check(game_state != null and inventory != null, "项目 Autoload 可用")
	if game_state == null or inventory == null:
		get_tree().quit(1)
		return
	game_state.reset_for_new_game()
	inventory.reset_for_new_game()
	game_state.set_flag(&"companion_tang_xingzhou_joined", true)
	game_state.set_flag(&"companion_shen_qinghe_joined", true)
	_check(game_state.party.size() == 3, "两名伙伴加入后队伍共三人")
	var tang: CharacterStats = game_state.get_party_member(&"tang_xingzhou")
	var qinghe: CharacterStats = game_state.get_party_member(&"shen_qinghe")
	_check(tang != null and &"tang_staff_sweep" in tang.skills, "唐行舟持有固定棍法")
	_check(qinghe != null and &"qinghe_returning_breath" in qinghe.skills and &"qinghe_jade_guard" in qinghe.skills, "沈青禾持有剑法、治疗和护元心法")
	_check(tang != null and tang.battle_sprite_root.contains("companions_v4/tang_xingzhou") and not tang.battle_sprite_root.contains("dojo_senior"), "唐行舟使用独立队友战斗精灵")
	_check(tang != null and tang.portrait_path.ends_with("portrait_tang_xingzhou_v2.png"), "唐行舟使用与主角分离的新版身份立绘")
	_check(qinghe != null and qinghe.battle_sprite_root.contains("companions_v4/shen_qinghe") and not qinghe.battle_sprite_root.contains("yuewuxing"), "沈青禾使用独立队友战斗精灵")
	var linxi_center := load("res://data/scenes/linxi_village_center.tres") as SceneScript
	var tang_entry: Dictionary = {}
	if linxi_center != null:
		for npc: Dictionary in linxi_center.npcs:
			if String(npc.get("npc_id", "")) == "tang_xingzhou_recruit":
				tang_entry = npc
	_check(not tang_entry.is_empty() and String(tang_entry.get("sprite_path", "")).ends_with("staff_dummy_practice_4f_v2.png"), "唐行舟在村中使用新版练棍精灵")
	var tang_intro := load("res://data/dialogs/linxi_companion_tang_xingzhou.tres") as DialogScript
	var tang_intro_text := FileAccess.get_file_as_string("res://data/dialogs/linxi_companion_tang_xingzhou.tres")
	_check(tang_intro != null and tang_intro_text.contains("spar_then:tang_xingzhou_recruit"), "唐行舟必须先切磋再进入邀请对话")
	_check(not tang_intro_text.contains("companion_tang_xingzhou_joined"), "唐行舟初次交谈不能直接入队")
	var qinghe_intro_text := FileAccess.get_file_as_string("res://data/dialogs/linxi_companion_shen_qinghe.tres")
	_check(qinghe_intro_text.contains("shen_qinghe_reunion_spoken") and not qinghe_intro_text.contains("companion_shen_qinghe_joined"), "沈青禾首次说明情况后不会直接入队")

	var boss := load("res://data/enemies/boss_zhao_wuji.tres") as EnemyDef
	_check(boss != null and &"zhao_broken_gate_strike" in boss.skill_ids, "赵无忌配置强力单体招式")
	_check(boss != null and &"zhao_black_wind_sweep" in boss.skill_ids, "赵无忌配置全体招式")
	var group_skill := load("res://data/skills/zhao_black_wind_sweep.tres") as Skill
	_check(group_skill != null and group_skill.target == Skill.Target.ENEMY_ALL, "赵无忌全体招式目标类型正确")

	inventory.add_item(&"wooden_staff", 1)
	inventory.add_item(&"linxi_iron_sword", 1)
	inventory.add_item(&"cloth_armor", 1)
	inventory.add_item(&"heart_guard_armor", 1)
	var staff_instance := ""
	var sword_instance := ""
	var cloth_instance := ""
	var armor_candidate_entry: Dictionary = {}
	for entry: Dictionary in inventory.slots:
		var item: Item = entry.get("item")
		if item != null and item.item_id == &"wooden_staff":
			staff_instance = String(entry.get("instance_id", ""))
		if item != null and item.item_id == &"linxi_iron_sword":
			sword_instance = String(entry.get("instance_id", ""))
		if item != null and item.item_id == &"cloth_armor":
			cloth_instance = String(entry.get("instance_id", ""))
		if item != null and item.item_id == &"heart_guard_armor":
			armor_candidate_entry = entry
	_check(inventory.equip_instance_for(&"tang_xingzhou", staff_instance), "可为唐行舟装备棍")
	_check(inventory.equip_instance_for(&"shen_qinghe", sword_instance), "可为沈青禾装备剑")
	_check(inventory.equip_instance_for(&"protagonist", cloth_instance), "可为主角装备粗布麻衣作为对比基准")
	_check(inventory.get_equipped_for(&"tang_xingzhou", Equipment.Slot.WEAPON) != null, "唐行舟装备槽独立")
	_check(inventory.get_equipped_for(&"shen_qinghe", Equipment.Slot.WEAPON) != null, "沈青禾装备槽独立")
	var round_trip: Dictionary = inventory.to_dict()
	inventory.from_dict(round_trip)
	_check(inventory.get_equipped_for(&"tang_xingzhou", Equipment.Slot.WEAPON) != null, "队友装备可序列化恢复")

	var panel_scene := load("res://scenes/ui/character_panel.tscn") as PackedScene
	var panel := panel_scene.instantiate() as CharacterPanel
	_check(panel != null, "统一角色界面可实例化")
	if panel != null:
		add_child(panel)
		# Reproduce the former Field bug: a legacy equipment-layout path reset the
		# fullscreen overlay to the top-left. Opening must always repair it.
		panel.anchors_preset = Control.PRESET_TOP_LEFT
		panel.open()
		var artwork := panel.get_node_or_null("Panel") as Control
		_check(panel.anchor_right == 1.0 and panel.anchor_bottom == 1.0, "角色界面打开时恢复全屏锚点")
		_check(artwork != null and (artwork.position + artwork.size * 0.5).distance_to(panel.size * 0.5) < 1.0, "角色界面固定居中而非贴在左上角")
		var panel_source := FileAccess.get_file_as_string("res://scripts/ui/character_panel.gd")
		_check(panel_source.contains('"队伍"') and not panel_source.contains('"同行者"'), "角色界面左栏命名为队伍")
		_check(panel_source.contains("var button := Button.new()"), "队伍卡片不再创建空装备提示框")
		var inventory_action := panel.find_child("InventoryAction", true, false) as Button
		var character_portrait := panel.find_child("CharacterPortrait", true, false) as TextureRect
		panel.call("_select_character", &"shen_qinghe")
		_check(character_portrait != null and character_portrait.texture is AtlasTexture, "伙伴详情使用头像裁切而非缩小的整张全身立绘")
		if character_portrait != null and character_portrait.texture is AtlasTexture:
			var shen_avatar := character_portrait.texture as AtlasTexture
			_check(shen_avatar.atlas != null and is_equal_approx(shen_avatar.region.size.x, shen_avatar.region.size.y), "沈青禾详情头像与队伍卡共用正方形头像裁切")
			_check(shen_avatar.atlas != null and shen_avatar.region.size.x <= shen_avatar.atlas.get_width() * 0.40, "伙伴头像收紧到头肩范围而非半身或全身")
		_check(character_portrait != null and character_portrait.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "统一头像铺满详情肖像区域")
		panel.call("_select_character", &"protagonist")
		_check(inventory_action != null and inventory_action.text == "使用", "背包操作按钮统一显示使用")
		panel.call("_set_inventory_filter", "equipment")
		panel.call("_select_inventory_entry", armor_candidate_entry)
		_check(inventory_action != null and inventory_action.text == "装备", "未由当前角色穿戴的装备显示装备")
		var comparison := panel.find_child("EquipmentComparison", true, false)
		var comparison_name := panel.find_child("EquippedComparisonName", true, false) as Label
		var comparison_delta := panel.find_child("EquipmentComparisonDelta", true, false) as RichTextLabel
		_check(comparison != null, "选择同部位新装备时右侧切换为属性对比界面")
		_check(comparison_name != null and comparison_name.text == "粗布麻衣", "对比界面显示当前已装备名称")
		_check(comparison_delta != null and comparison_delta.text.contains("防御 +8"), "对比界面显示装备后的属性差值")
		var staff_entry: Dictionary = inventory.find_slot_by_instance(staff_instance)
		panel.call("_select_character", &"tang_xingzhou")
		panel.call("_set_selected_inventory_entry", staff_entry)
		panel.call("_refresh_inventory_detail")
		_check(inventory_action != null and inventory_action.text == "卸下", "当前角色已穿戴的背包装备显示卸下")
		panel.call("_on_inventory_action_pressed")
		_check(inventory.get_equipped_for(&"tang_xingzhou", Equipment.Slot.WEAPON) == null, "点击背包卸下按钮会卸下当前装备")
		_check(inventory.equip_instance_for(&"tang_xingzhou", staff_instance), "可重新装备以验证右侧槽位交互")
		panel.call("_select_equipment_slot", Equipment.Slot.WEAPON)
		var detail_text := panel.find_child("InventoryDetailText", true, false) as RichTextLabel
		_check(detail_text != null and detail_text.text.contains("木棍") and detail_text.text.contains("攻击"), "左键选中右侧装备槽会显示装备名称和属性")
		var equipped_button := panel.find_child("EquipmentSlot%d" % Equipment.Slot.WEAPON, true, false) as Button
		var tooltip_text := String(panel.call("_equipment_tooltip", inventory.get_equipped_for(&"tang_xingzhou", Equipment.Slot.WEAPON)))
		_check(tooltip_text.contains("攻击 +") and not tooltip_text.contains("  "), "装备提示中的属性严格一条一行")
		var tooltip_panel := equipped_button.call("_make_custom_tooltip", tooltip_text) as Control if equipped_button != null else null
		_check(tooltip_panel != null and tooltip_panel.custom_minimum_size.x >= 400.0, "装备提示使用固定宽度的长方形面板")
		if tooltip_panel != null:
			tooltip_panel.free()
		var right_click := InputEventMouseButton.new()
		right_click.button_index = MOUSE_BUTTON_RIGHT
		right_click.pressed = true
		panel.call("_on_equipment_slot_input", right_click, Equipment.Slot.WEAPON)
		_check(inventory.get_equipped_for(&"tang_xingzhou", Equipment.Slot.WEAPON) == null, "右键点击右侧装备槽会卸下装备")
		panel.call("_set_inventory_filter", "all")
		var linxi_jiu := load("res://data/items/linxi_jiu.tres") as Item
		var minor_pill := load("res://data/items/healing_pill_minor.tres") as Item
		_check(bool(panel.call("_requires_precious_use_confirmation", linxi_jiu)), "紫色永久成长丹药需要二次确认")
		_check(not bool(panel.call("_requires_precious_use_confirmation", minor_pill)), "普通消耗品无需二次确认")
		panel.call("_show_precious_use_confirmation", linxi_jiu)
		var confirmation := panel.find_child("PreciousUseConfirmation", true, false) as Control
		_check(confirmation != null and confirmation.visible, "珍贵丹药会显示指定角色确认框")
		panel.call("_hide_precious_use_confirmation")
		panel.call("_on_inventory_drop_pressed")
		var confirm_title := panel.find_child("ConfirmTitle", true, false) as Label
		var confirm_action := panel.find_child("ConfirmAction", true, false) as Button
		_check(confirm_title != null and confirm_title.text == "确认丢弃物品", "丢弃操作使用独立确认标题")
		_check(confirm_action != null and confirm_action.text == "确认丢弃", "丢弃操作使用确认按钮而非立即删除")
		panel.call("_hide_precious_use_confirmation")
		panel.queue_free()
	var battle_scene := load("res://scenes/battle.tscn") as PackedScene
	var battle := battle_scene.instantiate()
	battle.set("_player", game_state.player)
	var party_payload: Array = battle.call("_build_player_party_payload", {})
	_check(party_payload.size() == 3, "普通遭遇会自动带入持久队伍")
	if party_payload.size() == 3:
		var ally_stats: CharacterStats = battle.call("_build_party_stats", party_payload[1], false)
		_check(ally_stats.character_id == "tang_xingzhou" and &"tang_staff_breaker" in ally_stats.skills, "队友战斗数据保留自己的武功而非复制主角")
	battle.free()

	print("[SUMMARY] validate_party_character_system ", "FAIL" if _failed else "PASS")
	get_tree().quit(1 if _failed else 0)
