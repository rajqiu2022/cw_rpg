extends SceneTree

var failures: Array[String] = []
var checks := 0
var companion_notice := ""
var spar_payload := ""
var displayed_dialog_text := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var event_bus := root.get_node_or_null("EventBus")
	var game_state := root.get_node_or_null("GameState")
	var quest_manager := root.get_node_or_null("QuestManager")
	var dialog_player := root.get_node_or_null("DialogPlayer")
	_check(event_bus != null and game_state != null and quest_manager != null and dialog_player != null, "runtime autoloads are available")
	if event_bus == null or game_state == null or quest_manager == null or dialog_player == null:
		_finish()
		return
	event_bus.connect("companion_joined", func(_id: StringName, name: String): companion_notice = name)
	event_bus.connect("dialog_spar_requested", func(payload: String): spar_payload = payload)
	dialog_player.connect("text_displayed", func(_speaker: String, text: String, _has_choices: bool, _portrait: String): displayed_dialog_text = text)

	game_state.call("reset_for_new_game")
	quest_manager.call("reset_for_new_game")
	var offer := _make_side_offer()
	dialog_player.call("play", offer)
	await process_frame
	_check(int(quest_manager.call("get_status", &"q_ch1_side_12_forest_medicine")) == QuestDef.Status.NOT_STARTED, "opening a side offer does not auto-accept it")
	_check("事情的原委" in displayed_dialog_text and "卖菜大婶需要" in displayed_dialog_text, "side offer expands the NPC premise with task context")
	dialog_player.call("choose", 1)
	await process_frame
	_check(int(quest_manager.call("get_status", &"q_ch1_side_12_forest_medicine")) == QuestDef.Status.NOT_STARTED, "declining a side offer keeps it unaccepted")

	dialog_player.call("play", offer)
	await process_frame
	dialog_player.call("choose", 0)
	await process_frame
	_check(int(quest_manager.call("get_status", &"q_ch1_side_12_forest_medicine")) == QuestDef.Status.IN_PROGRESS, "accepting the offer creates the side quest")

	game_state.call("add_companion", &"tang_xingzhou")
	_check(companion_notice == "唐行舟", "companion join emits a player-facing notice")

	var spar_script := DialogScript.new()
	spar_script.dialog_id = &"test_spar_preface"
	spar_script.entry_node_id = &"ready"
	var spar_node := DialogNode.new()
	spar_node.node_id = &"ready"
	spar_node.text = "摆开架势吧。"
	spar_node.on_end = "spar:test_id:test_enemy:试招人:10:2"
	spar_script.nodes.assign([spar_node])
	dialog_player.call("play", spar_script)
	await process_frame
	dialog_player.call("advance")
	await process_frame
	_check(spar_payload == "test_id:test_enemy:试招人:10:2", "spar dialogue resolves through the dedicated spar signal")

	var field_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check(field_source.contains("func _play_sparring_preface"), "NPC sparring opens a pre-battle dialogue")
	_check(field_source.contains("请赐教") and field_source.contains("今日先不打扰"), "sparring preface offers a player choice")
	_check(field_source.contains("队友加入："), "field displays a companion join tip")
	var dialog_source := FileAccess.get_file_as_string("res://scripts/autoload/dialog_player.gd")
	_check(dialog_source.contains("接受委托") and dialog_source.contains("暂且不接"), "side quests require an explicit acceptance choice")
	_finish()


func _make_side_offer() -> DialogScript:
	var script := DialogScript.new()
	script.dialog_id = &"test_side_offer"
	script.entry_node_id = &"start"
	var node := DialogNode.new()
	node.node_id = &"start"
	node.speaker = "卖菜大婶"
	node.text = "后山石缝边长着止血草，我不敢独自入林。"
	node.accept_quest = &"q_ch1_side_12_forest_medicine"
	node.on_end = "end"
	script.nodes.assign([node])
	return script


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _finish() -> void:
	print("[DialogOfferSparFeedback20260818] checks=%d failed=%d" % [checks, failures.size()])
	for failure in failures:
		push_error("[DialogOfferSparFeedback20260818] %s" % failure)
	quit(1 if not failures.is_empty() else 0)
