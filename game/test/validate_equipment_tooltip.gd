extends SceneTree

const EQUIPMENT_TOOLTIP_BUTTON := preload("res://scripts/ui/equipment_tooltip_button.gd")


func _initialize() -> void:
	var failed := false
	var stats: Array[String] = [
		"攻击 +16",
		"速度 +2",
		"机敏 +2",
		"暴击率 +6%",
		"兵器招式系数 +6%",
		"林西武功系数 +12%",
		"◆ 暗锋淬毒：命中时有 15% 概率使目标中毒，持续 2 回合。",
	]
	var text: String = EQUIPMENT_TOOLTIP_BUTTON.compose_text("林西铁剑", stats)
	if not text.contains("攻击 +16\n速度 +2\n机敏 +2") or text.contains("  "):
		push_error("[FAIL] 装备属性没有严格逐行排列")
		failed = true
	else:
		print("[PASS] 装备属性严格逐行排列")

	var expected_quality_color := Color("#1eff00")
	var button: Button = EQUIPMENT_TOOLTIP_BUTTON.new()
	button.call("set_quality_color", expected_quality_color)
	# Structured signed values, not punctuation-based text guessing.
	var signed_rows: Array[Dictionary] = [{"text": "攻击 +16", "kind": "stat", "value": 16}, {"text": "速度 -2", "kind": "stat", "value": -2}, {"text": "◆ 暗锋淬毒", "kind": "special", "value": 0}]
	button.call("set_stat_rows", signed_rows)
	var tooltip := button.call("_make_custom_tooltip", text) as Control
	if tooltip == null or tooltip.custom_minimum_size.x < 400.0:
		push_error("[FAIL] 装备属性提示没有使用固定宽度长方形")
		failed = true
	else:
		print("[PASS] 装备属性提示使用固定宽度长方形")
	var name_label := tooltip.find_child("EquipmentTooltipName", true, false) as Label if tooltip != null else null
	if name_label == null or not name_label.get_theme_color("font_color").is_equal_approx(expected_quality_color):
		push_error("[FAIL] 装备名称没有使用装备品质色")
		failed = true
	else:
		print("[PASS] 装备名称使用装备品质色")
	var stat_label := tooltip.find_child("EquipmentTooltipStats", true, false) as RichTextLabel if tooltip != null else null
	if stat_label == null or not stat_label.text.contains("[color=#72d2a6]攻击 +16[/color]") or not stat_label.text.contains("[color=#ff8770]速度 -2[/color]"):
		push_error("[FAIL] 装备属性没有按结构化正负数值着色")
		failed = true
	else:
		print("[PASS] 装备属性按结构化正负数值着色")
	var special_label := tooltip.find_child("EquipmentTooltipSpecial", true, false) as Label if tooltip != null else null
	if special_label == null or not special_label.get_theme_color("font_color").is_equal_approx(expected_quality_color):
		push_error("[FAIL] 武器特殊效果没有使用装备品质色")
		failed = true
	else:
		print("[PASS] 武器特殊效果使用装备品质色")
	var panel_source := FileAccess.get_file_as_string("res://scripts/ui/character_panel.gd")
	if not panel_source.contains("var button := EQUIPMENT_TOOLTIP_BUTTON.new()") or not panel_source.contains("button.set_quality_color(quality_color)"):
		push_error("[FAIL] 角色界面的右侧装备槽没有接入品质色 Tooltip")
		failed = true
	else:
		print("[PASS] 右侧装备槽接入品质色 Tooltip")
	var inventory_source := FileAccess.get_file_as_string("res://scripts/ui/inventory_panel.gd")
	var battle_source := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	if not panel_source.contains("var quality_color: String = QUALITY_COLORS.get(equipment.quality") \
		or not inventory_source.contains("QUALITY_COLORS.get(eq.quality") \
		or battle_source.contains("[color=#dca7ff]◆"):
		push_error("[FAIL] 角色界面、背包或战斗日志仍写死特殊效果颜色")
		failed = true
	else:
		print("[PASS] 角色界面、背包与战斗日志使用动态品质色")
	if tooltip != null:
		tooltip.free()
	button.free()
	quit(1 if failed else 0)
