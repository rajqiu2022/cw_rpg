extends SceneTree

const VICTORY_SCENE := "res://scenes/result_victory.tscn"


func _initialize() -> void:
	var packed: PackedScene = load(VICTORY_SCENE) as PackedScene
	if packed == null:
		push_error("[VictoryResultCheck] victory scene cannot load")
		quit(1)
		return
	var screen: Control = packed.instantiate() as Control
	root.add_child(screen)
	await process_frame
	var buttons: Array[Button] = []
	_collect_visible_buttons(screen, buttons)
	var ok := buttons.size() == 1
	if ok:
		var button := buttons[0]
		ok = button.name == "BtnContinue" and button.text == "返回游戏"
		ok = ok and not _contains_save_or_load_copy(button.text)
		ok = ok and Rect2(Vector2.ZERO, Vector2(1920, 1080)).encloses(button.get_global_rect())
	ok = ok and screen.get_node_or_null("ButtonRow/BtnSave") == null
	print("[VictoryResultCheck] visible_buttons=%d only_return=%s" % [buttons.size(), ok])
	screen.queue_free()
	quit(0 if ok else 1)


func _collect_visible_buttons(node: Node, result: Array[Button]) -> void:
	for child: Node in node.get_children():
		if child is Button and (child as Button).is_visible_in_tree():
			result.append(child as Button)
		_collect_visible_buttons(child, result)


func _contains_save_or_load_copy(text: String) -> bool:
	return text.contains("读取") or text.contains("存档") or text.contains("保存")
