extends Control

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const ATTR_ICON_ATLAS_PATH := "res://art/ui/cold_wuxia/v1/ui_cold_wuxia_attribute_icons_v1.png"
const ATTR_ICON_REGIONS := {
	"机敏": Rect2(290, 55, 201, 204),
}

@onready var bg: ColorRect = $Bg
@onready var title: Label = $Title
@onready var subtitle: Label = $Subtitle
@onready var btn_back: Button = %BtnBack

var _attr_icon_atlas: Texture2D = null


func _ready() -> void:
	if ResourceLoader.exists(ATTR_ICON_ATLAS_PATH):
		_attr_icon_atlas = load(ATTR_ICON_ATLAS_PATH)
	_apply_visual_style()
	btn_back.pressed.connect(func(): SceneRouter.go_main_menu())


func _apply_visual_style() -> void:
	if bg != null:
		bg.color = Color(0.018, 0.012, 0.016, 1.0)
	UI_THEME.style_label(title, 112, Color(0.68, 0.24, 0.28, 1.0))
	UI_THEME.style_label(subtitle, 24, UI_THEME.MUTED)
	UI_THEME.style_button(btn_back, 24, UI_THEME.CRIMSON)
	_apply_button_icon(btn_back, "机敏")


func _apply_button_icon(btn: Button, icon_key: String) -> void:
	if btn == null or _attr_icon_atlas == null:
		return
	var region: Rect2 = ATTR_ICON_REGIONS.get(icon_key, Rect2())
	if region.size.x <= 0 or region.size.y <= 0:
		return
	var atlas_tex: AtlasTexture = AtlasTexture.new()
	atlas_tex.atlas = _attr_icon_atlas
	atlas_tex.region = region
	btn.icon = atlas_tex
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_confirm"):
		SceneRouter.go_main_menu()

