extends SceneTree

const INK_PATH := "res://scripts/ui/dialog_box_ink.gd"
const HERO := "res://art/characters/protagonist_portrait.png"
var _checks := 0
var _failures := 0
var _player: Node
var _box: Control


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_player = root.get_node("DialogPlayer")
	_box = _player.get_node_or_null("DialogLayer/DialogBox")
	_check(_box != null and _box.get_script().resource_path == INK_PATH, "actual global scene uses ink")
	if _box == null:
		quit(1)
		return
	var portrait := _box.get_node("Frame/Portrait") as TextureRect
	var name := _box.get_node("Frame/SpeakerLabel") as Label
	var body := _box.get_node("Frame/TextLabel") as RichTextLabel
	var footer := _box.get_node("Frame/ContinueHint") as Label
	var frame := _box.get_node("Frame") as Control
	_check(frame.find_child("InkSilk", true, false) != null, "imported silk texture is in live dialogue")
	if "field" in OS.get_cmdline_user_args():
		root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
		var router := root.get_node("SceneRouter")
		_check(router.go_field_smart(&"interior_inn_hall"), "normal Zhuwei inn route accepted")
		var until := Time.get_ticks_msec() + 16000
		while Time.get_ticks_msec() < until:
			await process_frame
			if current_scene != null and not root.get_node("LoadingManager").get("_transition_active"):
				break
		var field_ready := current_scene != null and current_scene.has_method("get_field_loading_state") and bool(current_scene.get_field_loading_state().get("complete", false))
		_check(field_ready, "normal Zhuwei inn field ready")
		if field_ready:
			current_scene.call("_on_npc_primary_dialog", "inn_waiter_inside", "ch1_s2_inn_waiter")
			await _settle()
			_check(_box.visible and name.text == "冷孤云", "formal inn dialogue opens on protagonist")
			await _capture("00_zhuwei_actual_dialog.png")
			_input_key(KEY_SPACE)
			await _settle()
			_check(name.text == "店小二" and body.get_parsed_text().contains("掌柜"), "actual speaker and text switch together")
			_input_key(KEY_SPACE)
			await _settle()
			_check(not _player.is_playing(), "actual dialogue closed before isolated cases")
	var line := _node(&"start", "冷孤云", "打扰了，想向你请教几句。", HERO)
	line.on_end = "next:aside"
	var aside := _node(&"aside", "", "檐前风起，树影摇动。")
	_player.play(_dialog([line, aside]))
	await _settle()
	_check(_box.visible and portrait.visible and portrait.texture.resource_path == HERO, "hero portrait")
	_check(name.text == "冷孤云" and name.get_global_rect().end.y < body.get_global_rect().position.y, "speaker above body")
	_check(footer.visible and not _box.get_node("Frame/FrameArt").visible, "plain continue and no old frame")
	await _capture("01_portrait.png")
	_input_key(KEY_SPACE)
	await _settle()
	_check(not portrait.visible and name.text == "旁白", "space advances to no-portrait narration")
	_check(body.position.x < 60.0, "narration recovers portrait column")
	await _capture("02_narration.png")
	_input_key(KEY_SPACE)
	await _settle()
	_check(not _box.visible and not _player.is_playing(), "space ends narration")

	var options := _node(&"start", "船夫", "前面是外海，浪会大一些。\n先看海图，再选你要去的地方。", HERO)
	for i in 9:
		options.choices.append({"text":"第 %d 项：等潮水转向，沿礁石外侧乘船前行，靠岸后到市集找掌柜问路。" % (i + 1), "next":"first" if i == 0 else "last"})
	var first := _node(&"first", "船夫", "第一条路。")
	var last := _node(&"last", "船夫", "另一条路。")
	var fixture := _dialog([options, first, last])
	_player.play(fixture)
	await _settle()
	var scroll := _box.get("_scroll") as ScrollContainer
	var rows: Array = _box.get("_choice_rows")
	_check(rows.size() == 9 and not footer.visible, "nine choices and no continue hint")
	_check(body.get_parsed_text().contains("先看海图"), "choice setup is not shortened")
	_check(body.get_global_rect().end.y < scroll.get_global_rect().position.y, "separate body and choice bands")
	var p: Vector2 = rows[0].get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = p
	root.push_input(move, true)
	_check(_box.get("_hovered_idx") == 0, "real mouse motion sets hover")
	await _capture("03_choices.png")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = p
	click.pressed = true
	root.push_input(click, true)
	await _settle()
	_check(body.get_parsed_text() == "第一条路。", "mouse selects correct story branch")
	_player.play(fixture)
	await _settle()
	_input_key(KEY_9)
	await _settle()
	_check(body.get_parsed_text() == "另一条路。", "numeric choice selects original branch")
	_input_key(KEY_SPACE)
	await _settle()
	_check(not _box.visible, "no stale options after story ends")

	_box.size = Vector2(780, 490)
	_player.play(fixture)
	await _settle()
	_check(frame.position.y >= 0 and frame.get_rect().end.y <= _box.size.y, "narrow layout remains in viewport")
	_check(scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page, "narrow long choices are scrollable")
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await _settle()
	_box.call("_refresh_choice_rects")
	var rects: Array = _box.get("_choice_rects")
	_check(not rects[0].has_area() and rects[-1].has_area(), "only visible choice area is clickable")
	print("DIALOG_INK checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _capture(file: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png("user://" + file) == OK, "screenshot " + file)


func _node(id: StringName, who: String, line: String, image: String = "") -> DialogNode:
	var node := DialogNode.new()
	node.node_id = id
	node.speaker = who
	node.text = line
	node.portrait_path = image
	return node


func _dialog(nodes: Array[DialogNode]) -> DialogScript:
	var fixture := DialogScript.new()
	fixture.dialog_id = &"qa_dialog_ink"
	fixture.nodes = nodes
	return fixture


func _input_key(key: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.pressed = true
	root.push_input(ev, true)
	ev = InputEventKey.new()
	ev.keycode = key
	root.push_input(ev, true)


func _settle() -> void:
	for _i in 6:
		await process_frame


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("INK: " + what)
