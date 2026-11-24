extends SceneTree

const CHAPTER_END_SCENE := "res://scenes/chapter_end.tscn"
const BUTTON_NORMAL_PATH := "res://art/ui/button/btn_menu_frame_normal.png"
const BUTTON_HOVER_PATH := "res://art/ui/button/btn_menu_frame_hover.png"
const BUTTON_PRESSED_PATH := "res://art/ui/button/btn_menu_frame_pressed.png"

var _failed: int = 0


func _initialize() -> void:
	root.set_meta("skip_chapter_end_autosave", true)
	var router := root.get_node_or_null("SceneRouter")
	if router != null:
		router.set("_result_payload", {"chapter": 1})
	var packed := load(CHAPTER_END_SCENE) as PackedScene
	_check(packed != null, "chapter end scene cannot load")
	if packed == null:
		quit(1)
		return
	var screen := packed.instantiate() as Control
	root.add_child(screen)
	await process_frame
	await process_frame

	var buttons: Array[Button] = []
	_collect_visible_buttons(screen, buttons)
	_check(buttons.size() == 2, "chapter 1 must show exactly two buttons")
	var texts: Array[String] = []
	for button: Button in buttons:
		texts.append(button.text)
		_check(_has_formal_button_skin(button), "%s does not use the formal three-state skin" % button.name)
		_check(Rect2(Vector2.ZERO, Vector2(1920, 1080)).encloses(button.get_global_rect()), "%s leaves the viewport" % button.name)
	_check(texts.has("继续探索"), "missing explore button")
	_check(texts.has("进入第 2 章"), "missing next chapter button")
	_check(screen.get_node_or_null("ButtonRow/BtnSave") == null, "legacy save button still exists")
	_check(screen.get_node_or_null("ButtonRow/BtnMainMenu") == null, "legacy main-menu button still exists")
	_check(screen.get_node_or_null("FormalBackground") != null, "formal background was not installed")
	_check(screen.get_node_or_null("TitleArt") != null, "chapter title art was not installed")
	_check(screen.get_node_or_null("SummaryLabel") == null, "legacy black summary panel still exists")
	if buttons.size() == 2:
		_check(not buttons[0].get_global_rect().intersects(buttons[1].get_global_rect()), "chapter buttons overlap")

	screen.queue_free()
	await process_frame
	if router != null:
		router.set("_result_payload", {"chapter": 4})
	var final_screen := packed.instantiate() as Control
	root.add_child(final_screen)
	await process_frame
	await process_frame
	var final_buttons: Array[Button] = []
	_collect_visible_buttons(final_screen, final_buttons)
	_check(final_buttons.size() == 1, "chapter 4 must center a single explore button")
	if final_buttons.size() == 1:
		_check(final_buttons[0].text == "继续探索", "chapter 4 single button has wrong text")

	print("[ChapterEndCheck] buttons=%d failed=%d" % [buttons.size(), _failed])
	final_screen.queue_free()
	quit(1 if _failed > 0 else 0)


func _has_formal_button_skin(button: Button) -> bool:
	for state: StringName in [&"normal", &"hover", &"pressed", &"focus"]:
		var style := button.get_theme_stylebox(state)
		if not style is StyleBoxTexture:
			return false
	var normal := button.get_theme_stylebox(&"normal") as StyleBoxTexture
	var hover := button.get_theme_stylebox(&"hover") as StyleBoxTexture
	var pressed := button.get_theme_stylebox(&"pressed") as StyleBoxTexture
	return normal.texture.resource_path == BUTTON_NORMAL_PATH \
		and hover.texture.resource_path == BUTTON_HOVER_PATH \
		and pressed.texture.resource_path == BUTTON_PRESSED_PATH


func _collect_visible_buttons(node: Node, result: Array[Button]) -> void:
	for child: Node in node.get_children():
		if child is Button and (child as Button).is_visible_in_tree():
			result.append(child as Button)
		_collect_visible_buttons(child, result)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed += 1
	push_error("[ChapterEndCheck] %s" % message)
