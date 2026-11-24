extends SceneTree

var failed := 0
var checks := 0
var gs: Node
var qm: Node
var dp: Node
var inv: Node

func _init() -> void:
	call_deferred("_run")

func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failed += 1
		push_error(label)

func _run() -> void:
	gs = root.get_node("GameState")
	qm = root.get_node("QuestManager")
	dp = root.get_node("DialogPlayer")
	inv = root.get_node("Inventory")
	gs.flags.clear()
	qm.states.clear()
	inv.call("reset_for_new_game")
	_test_early_arrival()
	_test_authored_progress()
	_test_all_world_destinations()
	_test_old_world_return_coordinates()
	await _test_early_rewards_and_companion()
	await process_frame
	await process_frame
	print("[OpenExploration] checks=%d failed=%d" % [checks, failed])
	quit(1 if failed else 0)

func _test_early_arrival() -> void:
	var scene: Resource = load("res://data/scenes/ch1_s2_qingfeng.tres")
	for controller_path: String in ["res://scripts/field/field_controller.gd", "res://scripts/field/field_walkable_controller.gd"]:
		var controller: Node = load(controller_path).new()
		expect(not controller.call("_should_play_enter_dialog", scene), "fresh game must not autoplay Zhuwei plot: " + controller_path)
		controller.free()
	for id: String in ["ch1_s2_intro", "ch1_s2_guard", "ch1_s2_guard_report", "ch1_s2_inn_keeper", "ch2_zhuwei_intro", "ch3_assembly_intro", "ch4_yamen_intro", "ch7_lieyun_ferry_marks", "ch7_mingwu_courier_table"]:
		var dialogue: Resource = load("res://data/dialogs/%s.tres" % id)
		expect(not dp.call("can_play_script", dialogue), "plot must be gated: " + id)
		dp.call("play_at", dialogue, dialogue.entry_node_id)
		expect(dp.get("_current_script").dialog_id == &"openworld_early_visit", "direct play_at uses safe fallback: " + id)
		dp.call("advance")
		expect(not dp.call("is_playing"), "fallback releases input: " + id)
	expect(qm.states.is_empty(), "early visits must not accept/complete main quests")
	expect(not gs.flags.get("entered_zhuwei_village", false), "early visit must not consume once flag")
	expect(not gs.flags.get("ch7_lieyun_ferry_checked", false), "early visit must not grant chapter7 evidence")

func _test_authored_progress() -> void:
	# Complete actual training through its normal event-driven quest flow.
	qm.call("accept", &"q_ch1_main_training")
	gs.call("set_flag", &"master_training_done", true)
	expect(qm.call("is_completed", &"q_ch1_main_training"), "master training flag completes actual prerequisite quest")
	var scene: Resource = load("res://data/scenes/ch1_s2_qingfeng.tres")
	var controller: Node = load("res://scripts/field/field_walkable_controller.gd").new()
	expect(controller.call("_should_play_enter_dialog", scene), "return after training plays deferred introduction")
	dp.call("play", scene.on_enter_dialog)
	for step in range(8):
		if not dp.call("is_playing"):
			break
		dp.call("advance")
	expect(qm.call("is_active", &"q_ch1_main_village_inquiry"), "proper progression starts village inquiry")
	expect(not controller.call("_should_play_enter_dialog", scene), "normal intro remains once-only")
	controller.free()

func _test_all_world_destinations() -> void:
	var world: Resource = load("res://data/scenes/world_map_jianghu.tres")
	expect(world.map_layout.portals.size() == 13, "all thirteen geographic destinations retained")
	for portal: Dictionary in world.map_layout.portals:
		expect(String(portal.get("require_flag", "")).is_empty(), "no chapter lock on world portal " + String(portal.id))
		var path := "res://data/scenes/%s.tres" % String(portal.get("target_scene", ""))
		expect(ResourceLoader.exists(path), "world destination is real, not a locked empty action: " + path)
		if not ResourceLoader.exists(path):
			continue
		var scene: Resource = load(path)
		expect(scene.map_layout != null and ResourceLoader.exists(scene.background_path), "destination has map and art: " + path)
		for npc: Dictionary in scene.npcs:
			if npc.has("sprite_path"):
				expect(ResourceLoader.exists(npc.sprite_path), "visible NPC asset exists: " + String(npc.sprite_path))

func _test_old_world_return_coordinates() -> void:
	var router: Node = root.get_node("SceneRouter")
	for city: StringName in [&"ch1_s2_qingfeng", &"ch7_s1_lieyun_valley_ferry", &"ch7_s2_mingwu_tea_town"]:
		router.call("reset_for_new_game")
		router.call("resolve_portal_arrival", &"world_map_jianghu", city, Vector2(0.19,0.65), Vector2(0.5,0.8))
		var arrived: Vector2 = router.call("resolve_portal_arrival", city, &"world_map_jianghu", Vector2(0.5,0.9), Vector2(0.775,0.79))
		var expected: Vector2 = router.call("get_world_map_position_for_scene", city)
		expect(arrived.is_equal_approx(expected), "old paired world coordinates migrate to live gateway: " + String(city))

func _test_early_rewards_and_companion() -> void:
	gs.flags.clear()
	qm.states.clear()
	var treasure: Resource = load("res://data/dialogs/openworld_snow_treasure.tres")
	# A full pack cannot permanently consume the one-time cache.
	inv.slots.clear()
	for slot in range(30):
		inv.call("add_item", &"heavy_iron_sword", 1)
	dp.call("play", treasure)
	expect(not gs.flags.get("openworld_snow_treasure_found", false), "full backpack preserves cache")
	dp.call("advance")
	inv.call("reset_for_new_game")
	dp.call("play", treasure)
	dp.call("advance")
	expect(inv.call("count_of", &"heavy_iron_sword") == 1, "cave cache grants purple weapon after its authored route")
	expect(inv.call("count_of", &"cold_ridge_guard_breath_manual") == 1, "cave cache grants a readable manual")
	expect(not gs.player.skills.has(&"cold_ridge_guard_breath") and not gs.pending_skill_unlocks.has(&"cold_ridge_guard_breath"), "opening cache never auto-learns or queues the internal art")
	var reader := ReadingPanel.new()
	root.add_child(reader)
	await process_frame
	var manual: Item = load("res://data/items/cold_ridge_guard_breath_manual.tres")
	expect(reader.open_item(manual), "manual opens in the reusable reading panel")
	expect(reader.get("_study_button").disabled, "manual study is disabled below its insight requirement")
	gs.player.insight = 8
	reader.call("_update_study_ui")
	reader.call("_on_study_pressed")
	expect(gs.player.skills.has(&"cold_ridge_guard_breath"), "manual learns only after the insight condition is met")
	expect(inv.call("count_of", &"cold_ridge_guard_breath_manual") == 1, "studying does not consume the key manual")
	reader.queue_free()
	await process_frame
	dp.call("play", treasure)
	dp.call("advance")
	expect(inv.call("count_of", &"heavy_iron_sword") == 1, "cache does not duplicate rewards on direct replay")
	var recruit: Resource = load("res://data/dialogs/openworld_duan_changfeng_join.tres")
	expect(not dp.call("can_play_script", recruit), "recruit requires open-world favor, not a chapter")
	dp.call("play", load("res://data/dialogs/openworld_snow_medicine.tres"))
	dp.call("advance")
	dp.call("play", recruit)
	dp.call("choose", 1)
	expect(gs.call("get_party_member", &"duan_changfeng") == null, "declining recruitment grants no companion")
	dp.call("play", recruit)
	dp.call("choose", 0)
	dp.call("advance")
	var companion: Resource = gs.call("get_party_member", &"duan_changfeng")
	expect(companion != null and companion.level == 8, "level8 companion joins via favor without chapter completion")
	var party_size: int = gs.party.size()
	gs.call("reconcile_progression_rewards")
	expect(gs.party.size() == party_size, "save reconciliation does not duplicate new companion")
	var save_manager: Node = root.get_node("SaveManager")
	var saved_party: Array = []
	for member: Resource in gs.party:
		saved_party.append(save_manager.call("_serialize_stats", member))
	gs.call("restore_party", saved_party)
	companion = gs.call("get_party_member", &"duan_changfeng")
	expect(companion != null and companion.level == 8, "new companion survives real serializer/restore path")
	expect(not gs.flags.get("chapter1_complete", false) and qm.states.is_empty(), "open-world rewards and recruitment do not advance the main plot")
