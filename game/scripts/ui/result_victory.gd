extends Control

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const ATTR_ICON_ATLAS_PATH := "res://art/ui/cold_wuxia/v1/ui_cold_wuxia_attribute_icons_v1.png"
const ATTR_ICON_REGIONS := {
	"筋骨": Rect2(37, 55, 203, 204),
	"内劲": Rect2(544, 55, 200, 204),
}

@onready var bg: ColorRect = $Bg
@onready var title: Label = $Title
@onready var reward_label: Label = %RewardLabel
@onready var btn_continue: Button = %BtnContinue
@onready var btn_save: Button = %BtnSave

var _attr_icon_atlas: Texture2D = null


func _ready() -> void:
	if ResourceLoader.exists(ATTR_ICON_ATLAS_PATH):
		_attr_icon_atlas = load(ATTR_ICON_ATLAS_PATH)
	var payload: Dictionary = SceneRouter.get_result_payload()
	var gold: int = int(payload.get("gold", 0))
	var exp: int = int(payload.get("exp", 0))

	reward_label.text = "获得金钱  %d 两\n获得经验  %d 点" % [gold, exp]
	_apply_visual_style()
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_save.pressed.connect(_on_save_pressed)


func _apply_visual_style() -> void:
	if bg != null:
		bg.color = Color(0.028, 0.038, 0.052, 1.0)
	UI_THEME.style_label(title, 96, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_label(reward_label, 34, UI_THEME.TEXT)
	UI_THEME.style_button(btn_save, 24, UI_THEME.JADE)
	UI_THEME.style_button(btn_continue, 24, UI_THEME.GOLD)
	_apply_button_icon(btn_save, "内劲")
	_apply_button_icon(btn_continue, "筋骨")


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


func _on_continue_pressed() -> void:
	var payload: Dictionary = SceneRouter.get_result_payload()

	var return_scene: StringName = payload.get("return_scene", &"")
	if String(return_scene) != "":
		SceneRouter.go_field_smart(return_scene)
	else:
		SceneRouter.go_main_menu()


func _on_save_pressed() -> void:
	var slot := SaveManager.clamp_slot(SaveManager.active_slot)
	if SaveManager.save_to_slot(slot):
		btn_save.text = "已存档到槽 %d" % (slot + 1)
		btn_save.disabled = true



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_continue_pressed()

