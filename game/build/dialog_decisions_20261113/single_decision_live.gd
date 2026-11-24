extends SceneTree

const PAIRS := [
	["ch1_s2_crying_woman", &"start", &"q_ch1_side_01_rescue_husband", &"accepted_rescue_husband"],
	["ch1_s2_bandit_cave_rumour", &"start", &"q_ch1_side_10_bandit_cave", &"rumour_bandit_cave"],
	["ch1_s2_patrol_scout", &"start", &"q_ch1_side_08_mountain_patrol", &""],
	["ch1_s2_vegetable_vendor", &"start", &"q_ch1_side_12_forest_medicine", &"heard_forest_warning"],
	["ch1_side_caravan_offer", &"start", &"q_ch1_side_06_caravan_escort", &""],
	["ch1_side_stone_teacher_offer", &"start", &"q_ch1_side_03_stone_inscription", &""],
	["linxi_cliff_herb_offer", &"ask", &"q_ch1_side_02_cliff_herb", &"cliff_herb_accepted"],
]
var checks := 0
var failures := 0
var dialog: Node
var box: Control
var quests: Node
var state: Node

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ", message)

func get_dialog(id: String) -> DialogScript:
	return load("res://data/dialogs/%s.tres" % id) as DialogScript

func click(control: Control) -> void:
	for i in range(4):
		await process_frame
	for down in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = control.get_global_rect().get_center()
		ev.pressed = down
		root.push_input(ev, true)
	await process_frame

func press_one() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_1
	ev.pressed = true
	root.push_input(ev, true)
	await process_frame

func run() -> void:
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	state = root.get_node("GameState")
	quests = root.get_node("QuestManager")
	dialog = root.get_node("DialogPlayer")
	box = dialog.get("_box").get_node("DialogBox") as Control
	for row: Array in PAIRS:
		state.reset_for_new_game()
		quests.reset_for_new_game()
		var script := get_dialog(row[0])
		var quest: StringName = row[2]
		var flag: StringName = row[3]
		var accepted := [0]
		var accept_event: Callable = func(id: StringName):
			if id == quest:
				accepted[0] += 1
		root.get_node("EventBus").quest_accepted.connect(accept_event)
		dialog.play_at(script, row[1])
		var buttons: Array = box.get("_decision_buttons")
		check(buttons.size() == 2 and dialog.get("_pending_side_offer_id") == &"", "%s: authored buttons only" % row[0])
		if buttons.size() != 2:
			quit(1)
			return
		await click(buttons[1])
		check(quests.get_status(quest) == QuestDef.Status.NOT_STARTED and (flag == &"" or not state.get_flag(flag, false)), "%s: mouse decline changes neither state nor flag" % row[0])
		if dialog.is_playing():
			dialog.advance()
		dialog.play_at(script, row[1])
		if row[0] == "ch1_s2_crying_woman":
			await click(box.get("_decision_buttons")[0])
		else:
			await press_one()
		check(quests.is_active(quest) and accepted[0] == 1 and (flag == &"" or state.get_flag(flag, false)), "%s: one acceptance, original flag set" % row[0])
		check(dialog.get("_current_node").node_id == &"accept" and dialog.get("_pending_side_offer_id") == &"" and box.get("_decision_buttons").is_empty(), "%s: original reply, no second decision" % row[0])
		dialog.advance()
		check(not dialog.is_playing(), "%s: normal close" % row[0])
		root.get_node("EventBus").quest_accepted.disconnect(accept_event)
	for path: Array in [["ch1_martial_hall_master", &"start", 1, &"senior", "battle_solo:linxi_dojo_senior"], ["ch1_forest_yuewuxing", &"n6", 0, &"fight5", "battle:masked_killer_ambush"], ["ch1_forest_yuewuxing", &"n6", 1, &"obs3", "battle:masked_killer_ambush"]]:
		state.reset_for_new_game()
		quests.reset_for_new_game()
		dialog.play_at(get_dialog(path[0]), path[1])
		check(box.get("_decision_buttons").is_empty(), "%s: keeps normal story options" % path[0])
		dialog.choose(path[2])
		for i in range(5):
			if dialog.get("_current_node").node_id == path[3]:
				break
			dialog.advance()
		var node: DialogNode = dialog.get("_current_node")
		check(node.node_id == path[3] and node.on_end == path[4] and quests.is_active(node.accept_quest) and dialog.get("_pending_side_offer_id") == &"", "%s: keeps branch, battle action and accepts without asking" % path[3])
		dialog.call("_end_dialog")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	var ledger := get_dialog("linxi_scholar_house_ledger")
	dialog.play(ledger)
	var ledger_quest := &"q_ch1_side_11_old_ledger"
	check(box.get("_decision_buttons").size() == 2 and dialog.get("_pending_side_offer_id") == ledger_quest, "ordinary commission still asks once")
	dialog.advance()
	check(dialog.is_playing() and not quests.is_active(ledger_quest), "continue cannot bypass actual decision")
	dialog.choose(0)
	check(quests.is_active(ledger_quest), "ordinary commission accepts once")
	print("SINGLE_DECISION checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
