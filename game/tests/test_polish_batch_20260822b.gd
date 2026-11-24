extends SceneTree

var failures := 0
var displayed: Array[Dictionary] = []


func _initialize() -> void:
	await process_frame
	_test_dialog_portrait_switch()
	await process_frame
	_test_story_and_interactions()
	_test_shop_and_status_ui_source()
	print("[PolishBatch20260822B] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_dialog_portrait_switch() -> void:
	var player := root.get_node("DialogPlayer")
	player.text_displayed.connect(func(speaker: String, _text: String, _choices: bool, portrait: String): displayed.append({"speaker":speaker,"portrait":portrait}))
	var script := DialogScript.new()
	script.dialog_id = &"test_portrait_switch"
	var npc := DialogNode.new()
	npc.node_id = &"npc"
	npc.speaker = "船夫赵大江"
	npc.text = "先说一句。"
	npc.on_end = "next:hero"
	var hero := DialogNode.new()
	hero.node_id = &"hero"
	hero.speaker = "冷孤云"
	hero.text = "轮到主角。"
	hero.on_end = "end"
	script.entry_node_id = &"npc"
	script.nodes = [npc, hero]
	player.set_default_speaker("船夫赵大江")
	player.set_default_portrait("res://art/characters/portraits/generic/portrait_generic_young_man_v1.png")
	player.play(script)
	player.advance()
	_check(displayed.size() >= 2, "dialog emits both speakers")
	if displayed.size() >= 2:
		_check(String(displayed[1].portrait) == "res://art/characters/protagonist_portrait.png", "protagonist line replaces NPC portrait")
	player.advance()


func _test_story_and_interactions() -> void:
	var boss := load("res://data/dialogs/ch1_s3_ruin_boss.tres") as DialogScript
	_check(boss != null and boss.nodes[-1].on_end == "battle_then:boss_zhao_wuji:ch1_s3_ruin_after_boss", "Zhao boss routes into post-battle sequence")
	var after := load("res://data/dialogs/ch1_s3_ruin_after_boss.tres") as DialogScript
	_check(after != null and after.nodes[-1].on_end == "field_cutscene:zhao_wounded_escape", "Zhao dialogue hands off to field cutscene")
	_check(ResourceLoader.exists("res://data/dialogs/ch1_s3_ruin_orders.tres"), "Zhao orders remain a separate physical investigation")
	var deep := load("res://data/maps/ch1_s4_cave_deep_den_layout_v1.tres") as WalkableMapLayout
	var wolf_action := ""
	for interaction in deep.interactions:
		if String(interaction.get("id", "")) == "cave_alpha_wolf":
			wolf_action = String(interaction.get("action", ""))
	_check(wolf_action == "dialog:ch1_zhuwei_cave_wolf_encounter", "visible wolf starts dialogue instead of immediate battle")
	var entrance := load("res://data/maps/ch1_s4_zhuwei_beast_cave_layout_v3.tres") as WalkableMapLayout
	for interaction in entrance.interactions:
		_check(not bool(interaction.get("visual_baked", false)), "cave interaction %s has a visible object" % interaction.get("id", ""))


func _test_shop_and_status_ui_source() -> void:
	var shop_source := FileAccess.get_file_as_string("res://scripts/ui/shop_ui.gd")
	_check(shop_source.contains("QUALITY_COLORS") and shop_source.contains("_shop_item_summary"), "shop colors equipment names and lists stats")
	var battle_source := FileAccess.get_file_as_string("res://scripts/battle/battle_formation_view.gd")
	_check(battle_source.contains("Vector2(26, 20)") and battle_source.contains("StatusAnchor/StatusIcons"), "battle status icons use compact side placement")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
