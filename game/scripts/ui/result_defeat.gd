extends Control

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const FORMAL_BACKGROUND_PATH := "res://art/ui/system/ui_result_panel_formal_v1.png"
const TITLE_ART_PATH := "res://art/ui/title/title_defeat_v1.png"
const BTN_NORMAL := preload("res://art/ui/button/btn_menu_frame_normal.png")
const BTN_HOVER := preload("res://art/ui/button/btn_menu_frame_hover.png")
const BTN_PRESSED := preload("res://art/ui/button/btn_menu_frame_pressed.png")

@onready var bg: ColorRect = $Bg
@onready var title: Label = $Title
@onready var subtitle: Label = $Subtitle
@onready var btn_back: Button = %BtnBack

var _formal_background_active: bool = false


func _ready() -> void:
	_install_formal_background()
	_install_title_art()
	var payload := SceneRouter.get_result_payload()
	if StringName(payload.get("battle_mode", &"")) == &"sparring":
		var training := int(payload.get("training", 0))
		var opponent := String(payload.get("opponent_name", "江湖同道"))
		if training > 0:
			subtitle.text = "与 %s 切磋落败，但有所领悟\n获得阅历 %d 点（失败见识奖仅一次）" % [opponent, training]
		else:
			subtitle.text = "与 %s 切磋落败\n本次没有额外奖励，可调整招式后再试" % opponent
	elif StringName(payload.get("battle_mode", &"")) == &"bounty":
		var escape: Variant = payload.get("bounty_escape", {})
		if escape is Dictionary:
			subtitle.text = String((escape as Dictionary).get("message", "通缉犯趁乱脱身，需重查线报后再追。"))
	_apply_visual_style()
	btn_back.pressed.connect(_on_back_pressed)


func _install_formal_background() -> void:
	if not ResourceLoader.exists(FORMAL_BACKGROUND_PATH):
		return
	var texture: Texture2D = load(FORMAL_BACKGROUND_PATH) as Texture2D
	if texture == null:
		return
	var formal_background: TextureRect = TextureRect.new()
	formal_background.name = "FormalBackground"
	formal_background.texture = texture
	formal_background.modulate = Color.WHITE
	formal_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	formal_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	formal_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	formal_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(formal_background)
	move_child(formal_background, 0)
	_formal_background_active = true


func _install_title_art() -> void:
	if not ResourceLoader.exists(TITLE_ART_PATH) or title == null:
		return
	var title_art := TextureRect.new()
	title_art.name = "TitleArt"
	title_art.texture = load(TITLE_ART_PATH) as Texture2D
	title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_art.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_art.position = Vector2(-320, 150)
	title_art.size = Vector2(640, 220)
	title_art.pivot_offset = title_art.size * 0.5
	title_art.modulate = Color(1, 1, 1, 0.98)
	add_child(title_art)
	title.visible = false


func _apply_visual_style() -> void:
	if bg != null:
		bg.visible = not _formal_background_active
	UI_THEME.style_label(title, 112, Color(0.68, 0.24, 0.28, 1.0))
	UI_THEME.style_label(subtitle, 24, UI_THEME.MUTED)
	btn_back.add_theme_font_size_override("font_size", 20)
	btn_back.add_theme_color_override("font_color", UI_THEME.TEXT)
	btn_back.add_theme_color_override("font_hover_color", Color.WHITE)
	btn_back.add_theme_color_override("font_pressed_color", UI_THEME.GOLD_LIGHT)
	btn_back.add_theme_stylebox_override("normal", _button_style(BTN_NORMAL))
	btn_back.add_theme_stylebox_override("hover", _button_style(BTN_HOVER))
	btn_back.add_theme_stylebox_override("pressed", _button_style(BTN_PRESSED))
	btn_back.add_theme_stylebox_override("focus", _button_style(BTN_HOVER))
	btn_back.icon = null
	btn_back.alignment = HORIZONTAL_ALIGNMENT_CENTER


func _button_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 24.0
	style.texture_margin_top = 12.0
	style.texture_margin_right = 24.0
	style.texture_margin_bottom = 12.0
	style.content_margin_left = 20.0
	style.content_margin_top = 8.0
	style.content_margin_right = 20.0
	style.content_margin_bottom = 8.0
	return style


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_confirm"):
		_on_back_pressed()


func _on_back_pressed() -> void:
	var payload: Dictionary = SceneRouter.get_result_payload()
	var return_scene: StringName = payload.get("return_scene", &"")
	if String(return_scene) != "":
		SceneRouter.return_from_battle_payload(payload)
	else:
		SceneRouter.go_field_smart(SceneRouter.START_FIELD_SCENE)

