extends SceneTree

const QUEST := &"q_ch1_side_06_caravan_escort"
var failures := 0
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ", message)

func layout_frames() -> void:
	for i in 5:
		await process_frame

func run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	root.get_node("GameState").reset_for_new_game()
	var quests := root.get_node("QuestManager")
	quests.reset_for_new_game()
	var dialog := root.get_node("DialogPlayer")
	var box := dialog.get("_box").get_node("DialogBox") as Control
	var offer: DialogScript = load("res://data/dialogs/ch1_side_caravan_offer.tres")
	dialog.play(offer)
	await layout_frames()
	check(box.get("_choice_rows").size() == 2 and box.get("_decision_buttons").is_empty(), "unrelated binary choices keep list")
	dialog.play_at(offer, &"accept")
	await layout_frames()
	var buttons: Array = box.get("_decision_buttons")
	check(buttons.size() == 2, "actual quest offer renders two buttons")
	if buttons.size() != 2:
		quit(1)
		return
	var accept: Button = buttons[0]
	var decline: Button = buttons[1]
	check(accept.get_global_rect().end.x < decline.get_global_rect().position.x, "two separate click targets")
	check(accept.get_theme_stylebox("normal").modulate_color != decline.get_theme_stylebox("normal").modulate_color, "distinct skins")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://quest_decisions.png")
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = decline.get_global_rect().get_center()
	down.pressed = true
	root.push_input(down)
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up)
	await process_frame
	check(not dialog.is_playing() and not quests.is_active(QUEST), "mouse decline leaves quest unaccepted")
	dialog.play_at(offer, &"accept")
	await layout_frames()
	var key := InputEventKey.new()
	key.keycode = KEY_1
	key.pressed = true
	root.push_input(key)
	await process_frame
	check(not dialog.is_playing() and quests.is_active(QUEST), "number 1 accepts quest")
	print("DIALOG_DECISIONS checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
