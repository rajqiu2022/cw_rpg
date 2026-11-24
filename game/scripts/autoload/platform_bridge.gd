extends Node

## 微信小游戏 / Web 运行时最小平台桥。
##
## 这里不直接依赖微信 JS SDK，保持桌面与普通 Web 仍可运行。微信官方
## 通用引擎转换工具负责触摸事件、屏幕和 WASM 胶水适配；本桥负责游戏
## 自己必须统一处理的生命周期、首次用户手势、暂停存档和安全区信息。

signal user_gesture_detected
signal application_paused
signal application_resumed
signal safe_area_changed(rect: Rect2i)

const WECHAT_TRIAL_MAX_CHAPTER := 3
const UI_FONT_PATH := "res://art/fonts/LXGWWenKaiLite-Regular.ttf"

var _user_gesture_seen := false
var _last_safe_area := Rect2i()
var _pause_save_in_progress := false
var _checkpoint_saves_suspended := false
var _bundled_ui_font: Font = null
var _bundled_ui_font_bold: FontVariation = null


func _init() -> void:
	# Web/小游戏没有可依赖的中文系统字体。ThemeDB fallback会覆盖所有
	# 没有显式字体的Label、Button和RichTextLabel。
	_bundled_ui_font = load(UI_FONT_PATH) as Font
	if _bundled_ui_font != null:
		# The bundled WenKai face has only a Regular master. A restrained synthetic
		# embolden keeps Chinese strokes clear on bright battle art and survives the
		# Web/WeChat export without adding another multi-megabyte font file.
		_bundled_ui_font_bold = FontVariation.new()
		_bundled_ui_font_bold.base_font = _bundled_ui_font
		_bundled_ui_font_bold.variation_embolden = 0.55
		ThemeDB.fallback_font = _bundled_ui_font_bold


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	_last_safe_area = get_safe_area()
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	get_tree().node_added.connect(_on_node_added)
	_apply_font_recursive(get_tree().root)


func _on_node_added(node: Node) -> void:
	if node is Control:
		_apply_font_to_control(node as Control)


func _apply_font_recursive(node: Node) -> void:
	if node is Control:
		_apply_font_to_control(node as Control)
	for child in node.get_children():
		_apply_font_recursive(child)


func _apply_font_to_control(control: Control) -> void:
	if _bundled_ui_font_bold == null:
		return
	control.add_theme_font_override("font", _bundled_ui_font_bold)
	if control is RichTextLabel:
		for font_name in [&"normal_font", &"bold_font", &"italics_font", &"bold_italics_font", &"mono_font"]:
			(control as RichTextLabel).add_theme_font_override(font_name, _bundled_ui_font_bold)


func _input(event: InputEvent) -> void:
	if _user_gesture_seen:
		return
	var pressed_pointer: bool = (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	var pressed_key: bool = event is InputEventKey and event.pressed and not event.echo
	if pressed_pointer or pressed_key:
		_user_gesture_seen = true
		user_gesture_detected.emit()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			_handle_application_paused()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_WM_WINDOW_FOCUS_IN:
			_handle_application_resumed()


func is_web_runtime() -> bool:
	return OS.has_feature("web")


func is_wechat_trial_build() -> bool:
	return OS.has_feature("wechat_trial")


func ambient_animation_density() -> float:
	## Environment animation is decorative. Preserve gameplay and UI budgets on
	## Web/WeChat by reducing child sprites while keeping every authored prop.
	if is_wechat_trial_build():
		return 0.55
	if is_web_runtime():
		return 0.70
	return 1.0


func has_user_gesture() -> bool:
	return _user_gesture_seen or not is_web_runtime()


func max_playable_chapter() -> int:
	return WECHAT_TRIAL_MAX_CHAPTER if is_wechat_trial_build() else 999


func is_chapter_allowed(chapter: int) -> bool:
	return chapter <= max_playable_chapter()


func is_scene_allowed(scene_id: String) -> bool:
	if not is_wechat_trial_build() or scene_id.is_empty():
		return true
	var chapter_pattern := RegEx.new()
	chapter_pattern.compile("^ch([0-9]+)_")
	var matched := chapter_pattern.search(scene_id)
	if matched == null:
		return true
	return is_chapter_allowed(int(matched.get_string(1)))


func is_action_allowed(action: String) -> bool:
	if not is_wechat_trial_build() or action.is_empty():
		return true
	if action.begins_with("scene:"):
		return is_scene_allowed(action.trim_prefix("scene:"))
	return true


func get_safe_area() -> Rect2i:
	var viewport_size := get_viewport().get_visible_rect().size
	var full := Rect2i(Vector2i.ZERO, Vector2i(roundi(viewport_size.x), roundi(viewport_size.y)))
	var platform_rect := DisplayServer.get_display_safe_area()
	if platform_rect.size.x <= 0 or platform_rect.size.y <= 0:
		return full
	# Web/小游戏适配器可能返回物理屏幕像素，而 Godot UI 使用逻辑画布。
	# 无法可靠换算时宁可保留完整逻辑画布，由微信 screen-adapter 处理。
	if platform_rect.size.x > full.size.x * 2 or platform_rect.size.y > full.size.y * 2:
		return full
	return platform_rect.intersection(full)


func get_safe_margins() -> Vector4:
	var full_size := Vector2i(roundi(get_viewport().get_visible_rect().size.x), roundi(get_viewport().get_visible_rect().size.y))
	var safe := get_safe_area()
	return Vector4(
		float(safe.position.x),
		float(safe.position.y),
		float(maxi(0, full_size.x - safe.end.x)),
		float(maxi(0, full_size.y - safe.end.y))
	)


func set_checkpoint_saves_suspended(suspended: bool) -> void:
	_checkpoint_saves_suspended = suspended


func is_checkpoint_saves_suspended() -> bool:
	return _checkpoint_saves_suspended


func request_checkpoint_save() -> bool:
	if _checkpoint_saves_suspended:
		return false
	if _pause_save_in_progress:
		return false
	if not is_instance_valid(GameState.player):
		return false
	if String(SceneRouter.get_current_field_id()).is_empty():
		return false
	_pause_save_in_progress = true
	var ok := SaveManager.save_to_slot(SaveManager.active_slot)
	_pause_save_in_progress = false
	return ok


func _handle_application_paused() -> void:
	request_checkpoint_save()
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("pause_for_platform"):
		audio.call("pause_for_platform")
	application_paused.emit()


func _handle_application_resumed() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null and audio.has_method("resume_after_platform"):
		audio.call("resume_after_platform")
	application_resumed.emit()


func _on_viewport_size_changed() -> void:
	var current := get_safe_area()
	if current == _last_safe_area:
		return
	_last_safe_area = current
	safe_area_changed.emit(current)
