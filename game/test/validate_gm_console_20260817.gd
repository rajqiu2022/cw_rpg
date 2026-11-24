extends SceneTree

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var gm := root.get_node_or_null("GMConsole")
	_check(gm != null, "GMConsole autoload exists")
	if gm == null:
		_finish()
		return
	_check(gm.layer == 220, "GM console stays above normal UI")
	var launcher := gm.get_node_or_null("GMFloatingButton") as Button
	var panel := gm.get_node_or_null("GMPanel") as PanelContainer
	_check(launcher != null, "draggable GM launcher exists")
	_check(panel != null and not panel.visible, "GM panel starts closed")
	gm.call("_toggle_panel")
	_check(panel != null and panel.visible, "launcher toggle opens GM panel")

	var game_state := root.get_node("GameState")
	var inventory := root.get_node("Inventory")
	game_state.call("reset_for_new_game")
	inventory.call("reset_for_new_game")
	gm.call("_add_gold", 321)
	_check(int(game_state.get("gold")) == 321, "GM adds gold through GameState")
	var player := game_state.get("player") as CharacterStats
	var exp_before := player.exp
	gm.call("_add_exp", 25)
	_check(player.exp > exp_before, "GM adds experience through CharacterStats")
	gm.call("_add_training", 77)
	_check(int(game_state.get("training_points_total")) == 77 and int(game_state.get("training_points_available")) == 77, "GM adds total and available training points")

	var item_select := gm.get("_item_select") as OptionButton
	var item_count := gm.get("_item_count") as SpinBox
	gm.call("_refresh_item_options", "linxi_jiu")
	_check(item_select != null and item_select.item_count >= 1, "item search filters by resource id")
	if item_select != null and item_select.item_count > 0 and item_count != null:
		var before_count := int(inventory.call("count_of", &"linxi_jiu"))
		item_select.select(0)
		item_count.value = 2
		gm.call("_give_selected_item")
		_check(int(inventory.call("count_of", &"linxi_jiu")) == before_count + 2, "GM grants selected item count")
	gm.call("_refresh_item_options", "掌法")
	_check(item_select != null and item_select.item_count >= 7, "GM search finds all palm hand equipment")
	_check(_select_metadata(item_select, &"iron_knuckles"), "GM exposes 铁指虎")
	_check(_select_metadata(item_select, &"xuantong_fist_gauntlets"), "GM exposes 紫色拳套")
	_check(_select_metadata(item_select, &"immortal_gauntlets"), "GM exposes 橙色仙尊护手")
	if item_select != null:
		_check("掌法" in item_select.get_item_text(item_select.selected), "GM item label identifies palm equipment")

	var move_select := gm.get("_move_select") as OptionButton
	var mind_select := gm.get("_mind_select") as OptionButton
	_check(_select_metadata(move_select, &"wanxiang_breaking_sword"), "active martial art is available in move selector")
	gm.call("_learn_selected", move_select)
	_check(&"wanxiang_breaking_sword" in player.skills, "GM force-learns active martial art")
	var hp_before := player.max_hp
	_check(_select_metadata(mind_select, &"jingang_tempered_meridians"), "internal art is available in mind selector")
	gm.call("_learn_selected", mind_select)
	_check(&"jingang_tempered_meridians" in player.skills, "GM force-learns internal art")
	_check(player.max_hp > hp_before, "GM learning still applies passive heart-art attributes")

	var breakdown := BattleFormula.calc_damage_breakdown(80, 12, 125, 18, 1.0, 2.8)
	breakdown.annotate("冷孤云", "测试木桩", "林西剑法")
	gm.call("record_damage_breakdown", breakdown)
	var damage_label := gm.get("_damage_label") as RichTextLabel
	_check(damage_label != null and "最终伤害" in damage_label.text, "GM shows the latest damage breakdown")
	_check("已封顶" in damage_label.text and "2.20" in damage_label.text, "GM explains the critical multiplier cap")

	var source := FileAccess.get_file_as_string("res://scripts/autoload/gm_console.gd")
	_check(source.contains("OS.is_debug_build()"), "GM UI is restricted to debug builds")
	_check(source.contains("_on_launcher_gui_input"), "launcher implements drag/click separation")
	_check(source.contains("delta.length() >= 6.0"), "launcher uses a drag threshold")
	_check(source.contains("KEY_F12"), "F12 toggles the GM panel")
	_check(source.contains("func _refresh_resource_options"), "GM rebuilds lists after resource changes")
	_check(source.contains("ResourceLoader.CACHE_MODE_REPLACE"), "GM reloads current resource data instead of stale cache")
	_check(source.contains("刷新数据"), "GM exposes a manual resource refresh button")
	_check(String(ProjectSettings.get_setting("autoload/GMConsole", "")).contains("gm_console.gd"), "project registers GMConsole autoload")
	_finish()


func _select_metadata(select: OptionButton, target: StringName) -> bool:
	if select == null:
		return false
	for index in range(select.item_count):
		if StringName(String(select.get_item_metadata(index))) == target:
			select.select(index)
			return true
	return false


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _finish() -> void:
	print("[GMConsole20260817] checks=%d failed=%d" % [checks, failures.size()])
	for failure in failures:
		push_error("[GMConsole20260817] %s" % failure)
	quit(1 if not failures.is_empty() else 0)
