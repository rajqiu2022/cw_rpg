extends SceneTree

var failures: Array[String] = []
var checks := 0
var _game_state: Node
var _inventory: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_game_state = get_root().get_node_or_null("GameState")
	_inventory = get_root().get_node_or_null("Inventory")
	_check(_game_state != null and _inventory != null, "角色与背包自动加载可用")
	_validate_skill_ui()
	_validate_shen_qinghe_flow()
	_validate_weapon_requirements()
	_validate_shared_equipment_lock()
	_validate_sword_tip()
	print("[UiPersonalityWeaponLock20260822] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[UiPersonalityWeaponLock20260822] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_skill_ui() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/skill_panel.gd")
	_check(source.contains("name_label.position = Vector2(80, 7)"), "武学卡名称右移")
	_check(source.contains("meta_label.position = Vector2(80, 34)"), "武学卡类型与等级右移")
	_check(source.contains("[color=#%s]常驻功效（习得即生效）[/color]"), "心法关键功效使用品质色")
	_check(source.contains('"upgrade_pressed.png", 17, 72.0'), "装备/提升按钮文字避开左侧圆纹")
	_check(not source.contains("[b]条件不足"), "悟性条件取消模糊粗体")


func _validate_shen_qinghe_flow() -> void:
	var dialog := load("res://data/dialogs/linxi_companion_shen_qinghe.tres") as DialogScript
	_check(dialog != null, "沈青禾首次对白可加载")
	if dialog == null:
		return
	var explain := dialog.find_node_by_id(&"explain")
	var pushback := dialog.find_node_by_id(&"pushback")
	var offer := dialog.find_node_by_id(&"offer")
	var joined := dialog.find_node_by_id(&"joined")
	_check(explain != null and explain.on_end == "next:pushback", "说明缘由后继续进入青禾回应")
	_check(pushback != null and pushback.on_end == "next:offer", "青禾回应后同轮提出同行")
	_check(offer != null and offer.choices.size() == 2, "首次对白内直接给出同行选择")
	_check(joined != null and joined.set_flags.any(func(entry: Dictionary): return String(entry.get("key", "")) == "companion_shen_qinghe_joined"), "同行选择仍正常加入队伍")
	_check(pushback != null and "休想" in pushback.text and joined != null and "逞强" in joined.text, "青梅竹马的蛮横直率口吻已落地")
	for node_id: String in ["start", "pushback", "offer", "joined", "offer_later", "later"]:
		var node := dialog.find_node_by_id(StringName(node_id))
		if node == null or node.speaker != "沈青禾":
			continue
		var voice := "res://art/audio/voices/lin/linxi_companion_shen_qinghe/沈青禾_%s_seg01_dialog.mp3" % node_id
		_check(ResourceLoader.exists(voice), "沈青禾连续对白语音已重制：%s" % node_id)
	var generator := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../scripts/gen_dialog_voices.py"))
	_check(generator.contains('"沈青禾": {"pitch": "+1Hz", "rate": "+7%", "volume": "+3%"}'), "沈青禾使用利落强势的统一声线参数")


func _validate_weapon_requirements() -> void:
	_game_state.call("reset_for_new_game")
	_inventory.call("reset_for_new_game")
	var player := _game_state.get("player") as CharacterStats
	var controller := Control.new()
	controller.set_script(load("res://scripts/battle/battle_controller.gd"))
	var sword_skill := load("res://data/skills/linxi_basic_sword_one.tres") as Skill
	var palm_skill := load("res://data/skills/palm_strike.tres") as Skill
	var basic_skill := load("res://data/skills/basic_attack.tres") as Skill
	_check(not bool(controller.call("_matches_current_weapon", sword_skill, player)), "未装备剑时隐藏剑法")
	_check(not bool(controller.call("_matches_current_weapon", palm_skill, player)), "未装备拳套时隐藏掌法")
	_check(bool(controller.call("_matches_current_weapon", basic_skill, player)), "普通攻击不要求武器")
	var sword_instance := _add_and_find_instance(&"linxi_iron_sword")
	_check(not sword_instance.is_empty() and bool(_inventory.call("equip_instance_for", &"protagonist", sword_instance)), "测试剑可装备")
	_check(bool(controller.call("_matches_current_weapon", sword_skill, player)), "装备剑后显示剑法")
	_inventory.call("unequip_for", &"protagonist", Equipment.Slot.WEAPON)
	var palm_instance := _add_and_find_instance(&"iron_knuckles")
	_check(not palm_instance.is_empty() and bool(_inventory.call("equip_instance_for", &"protagonist", palm_instance)), "测试指虎可装备")
	_check(bool(controller.call("_matches_current_weapon", palm_skill, player)), "装备拳套/指虎后显示掌法")
	controller.free()


func _validate_shared_equipment_lock() -> void:
	_game_state.call("reset_for_new_game")
	_inventory.call("reset_for_new_game")
	_game_state.call("add_companion", &"shen_qinghe")
	var instance_id := _add_and_find_instance(&"linxi_iron_sword")
	_check(bool(_inventory.call("equip_instance_for", &"shen_qinghe", instance_id)), "沈青禾可装备共享背包中的剑")
	_check(StringName(_inventory.call("get_instance_equipped_character_id", instance_id)) == &"shen_qinghe", "装备实例记录当前队友")
	_check(not bool(_inventory.call("equip_instance_for", &"protagonist", instance_id)), "其他队友占用的装备不能被直接抢穿")
	_check(StringName(_inventory.call("get_instance_equipped_character_id", instance_id)) == &"shen_qinghe", "抢穿失败后原队友装备保持不变")
	var ui_source := FileAccess.get_file_as_string("res://scripts/ui/character_panel.gd")
	_check(ui_source.contains("occupied_by_other") and ui_source.contains("其他队友已装备"), "角色界面灰显并禁用队友占用装备")


func _validate_sword_tip() -> void:
	for path: String in ["res://scripts/field/field_controller.gd", "res://scripts/field/field_walkable_controller.gd"]:
		var source := FileAccess.get_file_as_string(path)
		_check(source.contains("装备剑后，方可使用林西剑法"), "获得林西剑显示装备提示：%s" % path.get_file())


func _add_and_find_instance(item_id: StringName) -> String:
	_inventory.call("add_item", item_id, 1)
	var slots: Array = _inventory.get("slots") as Array
	for entry: Dictionary in slots:
		var item := entry.get("item") as Item
		if item != null and item.item_id == item_id:
			return String(entry.get("instance_id", ""))
	return ""


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
