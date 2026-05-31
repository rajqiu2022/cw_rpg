extends Control

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const ATTR_ICON_ATLAS_PATH := "res://art/ui/cold_wuxia/v1/ui_cold_wuxia_attribute_icons_v1.png"
const ATTR_ICON_REGIONS := {
	"悟性": Rect2(794, 55, 195, 203),
	"内力": Rect2(1281, 55, 196, 204),
}

@onready var bg: ColorRect = $Bg
@onready var title: Label = %Title
@onready var chapter_label: Label = %ChapterLabel
@onready var summary_label: RichTextLabel = %SummaryLabel
@onready var btn_save: Button = %BtnSave
@onready var btn_main_menu: Button = %BtnMainMenu

var _attr_icon_atlas: Texture2D = null

func _ready() -> void:
	if ResourceLoader.exists(ATTR_ICON_ATLAS_PATH):
		_attr_icon_atlas = load(ATTR_ICON_ATLAS_PATH)
	_apply_visual_style()
	_fill_summary()
	btn_save.pressed.connect(_on_save_pressed)
	btn_main_menu.pressed.connect(_on_main_menu_pressed)

func _apply_visual_style() -> void:
	bg.color = Color(0.018, 0.026, 0.036, 1.0)
	UI_THEME.style_label(title, 72, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_label(chapter_label, 30, UI_THEME.GOLD)
	UI_THEME.style_rich_text(summary_label, 22)
	UI_THEME.style_button(btn_save, 24, UI_THEME.JADE)
	UI_THEME.style_button(btn_main_menu, 24, UI_THEME.GOLD)
	_apply_button_icon(btn_save, "内力")
	_apply_button_icon(btn_main_menu, "悟性")

func _apply_button_icon(btn: Button, icon_key: String) -> void:
	if btn == null or _attr_icon_atlas == null:
		return
	var region: Rect2 = ATTR_ICON_REGIONS.get(icon_key, Rect2())
	if region.size.x <= 0 or region.size.y <= 0:
		return
	var tex: AtlasTexture = AtlasTexture.new()
	tex.atlas = _attr_icon_atlas
	tex.region = region
	btn.icon = tex
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT

func _fill_summary() -> void:
	var payload: Dictionary = SceneRouter.get_result_payload()
	var chapter: int = int(payload.get("chapter", GameState.current_chapter))

	chapter_label.text = "第一章 · 云影初卷"
	if chapter > 1:
		chapter_label.text = "第 %d 章 · 阶段结算" % chapter

	var main_done: int = 0
	var side_done: int = 0

	for qid in QuestManager.states.keys():
		if QuestManager.get_status(qid) != QuestDef.Status.COMPLETED:
			continue
		var q := QuestManager.load_def(qid)
		if q == null:
			continue
		if q.kind == QuestDef.Kind.MAIN:
			main_done += 1
		else:
			side_done += 1

	summary_label.text = "[b]章节完成[/b]\n主线任务完成：%d\n支线任务完成：%d\n\n[b]下一步[/b]\n第二章入口已解锁（后续内容开发中）" % [main_done, side_done]
	GameState.current_chapter = max(GameState.current_chapter, chapter + 1)

func _on_save_pressed() -> void:
	var slot := SaveManager.clamp_slot(SaveManager.active_slot)
	if SaveManager.save_to_slot(slot):
		btn_save.text = "已存档到槽 %d" % (slot + 1)
		btn_save.disabled = true

func _on_main_menu_pressed() -> void:
	SceneRouter.go_main_menu()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_main_menu_pressed()
