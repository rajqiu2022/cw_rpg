extends Control

## 武侠风格主菜单 —— 底框(frame)三态 + 文字贴图(text)分层叠加

# 底框三态路径（共用同一套底框）
const BTN_FRAME_DIR := "res://art/ui/button/"
const FRAME_NORMAL := "btn_menu_frame_normal.png"
const FRAME_HOVER := "btn_menu_frame_hover.png"
const FRAME_PRESSED := "btn_menu_frame_pressed.png"

# 文字贴图路径（每个按钮各一张独立文字）
const BTN_TEXT_DIR := "res://art/ui/button/"
const TEXT_MAP := {
	"btn_new_game": "btn_menu_text_new_game.png",
	"btn_continue": "btn_menu_text_load.png",
	"btn_quit": "btn_menu_text_quit.png",
}

# v5 原图裁出的完整按钮（含文字、含每个按钮独立配色），优先使用。
const V5_BUTTON_MAP := {
	"btn_new_game": {
		"normal": "btn_menu_v5_new_game_normal.png",
		"hover": "btn_menu_v5_new_game_hover.png",
		"pressed": "btn_menu_v5_new_game_pressed.png",
	},
	"btn_continue": {
		"normal": "btn_menu_v5_load_normal.png",
		"hover": "btn_menu_v5_load_hover.png",
		"pressed": "btn_menu_v5_load_pressed.png",
	},
	"btn_quit": {
		"normal": "btn_menu_v5_quit_normal.png",
		"hover": "btn_menu_v5_quit_hover.png",
		"pressed": "btn_menu_v5_quit_pressed.png",
	},
}

@onready var fallback_bg: ColorRect = $FallbackBg
@onready var background: TextureRect = $Background
@onready var button_panel: VBoxContainer = %ButtonPanel
@onready var btn_new_game: Button = %BtnNewGame
@onready var btn_continue: Button = %BtnContinue
@onready var btn_quit: Button = %BtnQuit
@onready var version_label: Label = %VersionLabel

# 文字贴图 TextureRect 引用（用于 disabled 灰化等）
var _text_rects: Dictionary = {}


func _ready() -> void:
	print("[MainMenu] _ready() START ========")
	
	# 1. 确保按钮面板可见
	if button_panel == null:
		push_error("[MainMenu] ButtonPanel is null!")
		return
	button_panel.visible = true
	button_panel.z_index = 10
	
	# 2. 用底框+文字分层样式化按钮
	_apply_frame_text_button(btn_new_game, "btn_new_game")
	_apply_frame_text_button(btn_continue, "btn_continue")
	_apply_frame_text_button(btn_quit, "btn_quit")
	
	# 3. 背景
	if fallback_bg != null:
		fallback_bg.color = Color(0.05, 0.08, 0.12, 1.0)
		fallback_bg.visible = true
	_try_load_bg()
	
	# 4. 隐藏装饰节点
	_hide_decorations_safe()
	
	# 5. 版本号
	if version_label != null:
		version_label.text = "v0.4.0"
		version_label.visible = true
	
	# 6. 连接信号
	if btn_new_game != null:
		btn_new_game.pressed.connect(_on_new_game)
	if btn_continue != null:
		btn_continue.pressed.connect(_on_continue)
	if btn_quit != null:
		btn_quit.pressed.connect(_on_quit)
	
	# 7. 存档状态
	_check_save_state()
	
	print("[MainMenu] _ready() DONE ========")


func _apply_frame_text_button(btn: Button, key: String) -> void:
	"""底框三态做按钮背景 + 文字贴图作为子节点叠加"""
	if btn == null:
		return
	
	# 优先加载 v5 完整按钮；缺失时回落到底框 + 文字分层方案。
	var uses_embedded_text := false
	var tex_frame_n: Texture2D = null
	var tex_frame_h: Texture2D = null
	var tex_frame_p: Texture2D = null
	var v5_files: Dictionary = V5_BUTTON_MAP.get(key, {})
	if not v5_files.is_empty():
		tex_frame_n = _load_tex_path(BTN_FRAME_DIR + String(v5_files.get("normal", "")))
		if tex_frame_n != null:
			tex_frame_h = _load_tex_path(BTN_FRAME_DIR + String(v5_files.get("hover", "")))
			tex_frame_p = _load_tex_path(BTN_FRAME_DIR + String(v5_files.get("pressed", "")))
			uses_embedded_text = true
	
	if tex_frame_n == null:
		tex_frame_n = _load_tex_path(BTN_FRAME_DIR + FRAME_NORMAL)
		tex_frame_h = _load_tex_path(BTN_FRAME_DIR + FRAME_HOVER)
		tex_frame_p = _load_tex_path(BTN_FRAME_DIR + FRAME_PRESSED)
	
	if tex_frame_n == null:
		# 底框不存在，走代码保底样式
		_style_button_fallback(btn, key)
		return
	
	# 设置按钮大小为底框大小
	var frame_size := tex_frame_n.get_size()
	btn.custom_minimum_size = frame_size
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# 必须保持非 flat，否则 Godot 不绘制 normal/hover/pressed 的底框 StyleBox。
	btn.flat = false
	btn.text = ""
	
	# 底框三态 StyleBoxTexture
	var style_normal := StyleBoxTexture.new()
	style_normal.texture = tex_frame_n
	style_normal.content_margin_left = 0
	style_normal.content_margin_right = 0
	style_normal.content_margin_top = 0
	style_normal.content_margin_bottom = 0
	
	var style_hover := StyleBoxTexture.new()
	style_hover.texture = tex_frame_h if tex_frame_h else tex_frame_n
	style_hover.content_margin_left = 0
	style_hover.content_margin_right = 0
	style_hover.content_margin_top = 0
	style_hover.content_margin_bottom = 0
	
	var style_pressed := StyleBoxTexture.new()
	style_pressed.texture = tex_frame_p if tex_frame_p else tex_frame_n
	style_pressed.content_margin_left = 0
	style_pressed.content_margin_right = 0
	style_pressed.content_margin_top = 0
	style_pressed.content_margin_bottom = 0
	
	var style_empty := StyleBoxEmpty.new()
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_empty)
	btn.add_theme_stylebox_override("disabled", style_normal)
	
	# 隐藏原生文字
	btn.add_theme_font_size_override("font_size", 1)
	btn.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_disabled_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_focus_color", Color(0, 0, 0, 0))
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	btn.add_theme_constant_override("outline_size", 0)
	
	if uses_embedded_text:
		print("[MainMenu] V5 button OK: %s (%dx%d)" % [key, int(frame_size.x), int(frame_size.y)])
		return
	
	# 叠加文字贴图（独立 TextureRect 子节点）
	var text_file: String = TEXT_MAP.get(key, "")
	if text_file != "":
		var tex_text := _load_tex_path(BTN_TEXT_DIR + text_file)
		if tex_text != null:
			var text_rect := TextureRect.new()
			text_rect.texture = tex_text
			text_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			text_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_rect.anchors_preset = Control.PRESET_FULL_RECT
			text_rect.anchor_left = 0.0
			text_rect.anchor_top = 0.0
			text_rect.anchor_right = 1.0
			text_rect.anchor_bottom = 1.0
			text_rect.offset_left = 0.0
			text_rect.offset_top = 0.0
			text_rect.offset_right = 0.0
			text_rect.offset_bottom = 0.0
			btn.add_child(text_rect)
			_text_rects[key] = text_rect
			print("[MainMenu] Frame+Text button OK: %s (%dx%d)" % [key, int(frame_size.x), int(frame_size.y)])
		else:
			print("[MainMenu] Frame OK but text missing: %s" % key)
	else:
		print("[MainMenu] Frame OK, no text mapping for: %s" % key)


func _load_tex_path(path: String) -> Texture2D:
	"""安全加载贴图（按完整路径）"""
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	return null


func _style_button_fallback(btn: Button, key: String) -> void:
	"""贴图缺失时的代码保底样式"""
	var labels := {"btn_new_game": "新游戏", "btn_continue": "读取存档", "btn_quit": "离开"}
	btn.text = labels.get(key, key)
	btn.visible = true
	btn.custom_minimum_size = Vector2(400, 64)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.1, 0.13, 0.18, 0.95)
	style_normal.border_color = Color(0.4, 0.5, 0.6, 1.0)
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(4)
	style_normal.content_margin_left = 20
	style_normal.content_margin_right = 20
	style_normal.content_margin_top = 12
	style_normal.content_margin_bottom = 12
	
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.13, 0.18, 0.25, 0.98)
	style_hover.border_color = Color(0.3, 0.75, 0.85, 1.0)
	style_hover.set_border_width_all(2)
	style_hover.set_corner_radius_all(4)
	style_hover.content_margin_left = 20
	style_hover.content_margin_right = 20
	style_hover.content_margin_top = 12
	style_hover.content_margin_bottom = 12
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_normal)
	btn.add_theme_stylebox_override("focus", style_hover)
	
	btn.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_font_size_override("font_size", 26)


func _try_load_bg() -> void:
	if background == null:
		return
	var paths := [
		"res://art/backgrounds/bg_main_menu_v6_clean.png",
		"res://art/backgrounds/bg_main_menu_v5.png",
		"res://art/backgrounds/bg_main_menu_gpt_v7_clean.png",
		"res://art/backgrounds/bg_main_menu_gpt_v6.png",
		"res://art/backgrounds/bg_main_menu_gpt_v5.png",
	]
	for path in paths:
		if ResourceLoader.exists(path):
			var tex = load(path)
			if tex is Texture2D:
				background.texture = tex
				print("[MainMenu] BG: %s" % path)
				return
	print("[MainMenu] No BG found, using solid color")


func _hide_decorations_safe() -> void:
	var names := ["TopBeam", "BottomBeam", "TitlePlaque", "MenuBoard",
		"MenuSectionLabel", "MenuSubHint", "PortraitFrame",
		"NewsBoard", "NewsTitle", "NewsBody",
		"LeftRoleTag", "RightRoleTag", "RibbonLeft", "RibbonRight",
		"Title", "Subtitle", "ProtagonistCard", "ProtagonistNameplate",
		"LeftRoleLabel", "RightRoleLabel", "FooterTip", "Vignette"]
	for n in names:
		var node = get_node_or_null(n)
		if node != null:
			node.visible = false


func _check_save_state() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm == null:
		print("[MainMenu] SaveManager not found, skip save check")
		_disable_continue_button()
		return
	var has_save := false
	for slot in range(SaveManager.SLOT_COUNT):
		if SaveManager.has_save(slot):
			has_save = true
			break
	if not has_save:
		_disable_continue_button()


func _disable_continue_button() -> void:
	"""禁用读取存档按钮（底框+文字一起灰化）"""
	if btn_continue == null:
		return
	btn_continue.disabled = true
	btn_continue.modulate = Color(0.58, 0.60, 0.64, 0.94)
	# 文字贴图也一起灰化（跟随按钮 modulate 自动生效，因为是子节点）


func _on_new_game() -> void:
	print("[MainMenu] New Game pressed")
	if get_node_or_null("/root/GameState") != null:
		GameState.reset_for_new_game()
	if get_node_or_null("/root/Inventory") != null:
		Inventory.reset_for_new_game()
	if get_node_or_null("/root/QuestManager") != null:
		QuestManager.reset_for_new_game()
	if get_node_or_null("/root/SceneRouter") != null:
		SceneRouter.go_field_smart(&"ch1_s1_road")


func _on_continue() -> void:
	print("[MainMenu] Continue pressed")
	if get_node_or_null("/root/SaveManager") != null:
		if SaveManager.load_from_slot(0):
			var sid: StringName = SaveManager.get_save_field_id(0)
			if String(sid) == "":
				sid = &"ch1_s1_road"
			if get_node_or_null("/root/SceneRouter") != null:
				SceneRouter.go_field_smart(sid)


func _on_quit() -> void:
	print("[MainMenu] Quit pressed")
	get_tree().quit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
