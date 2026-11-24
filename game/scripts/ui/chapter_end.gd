extends Control

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const FORMAL_BACKGROUND_PATH := "res://art/ui/system/ui_result_panel_formal_v1.png"
const TITLE_ART_PATH := "res://art/ui/title/title_chapter_complete_v1.png"
const BUTTON_NORMAL_PATH := "res://art/ui/button/btn_menu_frame_normal.png"
const BUTTON_HOVER_PATH := "res://art/ui/button/btn_menu_frame_hover.png"
const BUTTON_PRESSED_PATH := "res://art/ui/button/btn_menu_frame_pressed.png"

@onready var bg: ColorRect = $Bg
@onready var title: Label = %Title
@onready var chapter_label: Label = %ChapterLabel
@onready var auto_save_label: Label = %AutoSaveLabel
@onready var main_stats_value: Label = %MainStatsValue
@onready var side_stats_value: Label = %SideStatsValue
@onready var next_stats_value: Label = %NextStatsValue
@onready var btn_explore: Button = %BtnExplore
@onready var btn_next_chapter: Button = %BtnNextChapter

var _formal_background_active: bool = false
var _chapter: int = 1


func _ready() -> void:
	_install_formal_background()
	_install_title_art()
	_apply_visual_style()
	_fill_summary()
	btn_explore.pressed.connect(_on_explore_pressed)
	btn_next_chapter.pressed.connect(_on_next_chapter_pressed)
	# Chapter completion always updates the single automatic save slot. Test and
	# screenshot harnesses opt out so they never touch the player's real save.
	if not get_tree().get_meta("skip_chapter_end_autosave", false):
		SaveManager.save_to_slot(0)


func _install_formal_background() -> void:
	if not ResourceLoader.exists(FORMAL_BACKGROUND_PATH):
		return
	var texture: Texture2D = load(FORMAL_BACKGROUND_PATH) as Texture2D
	if texture == null:
		return
	var formal_background := TextureRect.new()
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
	title_art.position = Vector2(-280, 86)
	title_art.size = Vector2(560, 244)
	title_art.modulate = Color(1, 1, 1, 0.98)
	add_child(title_art)
	title.visible = false


func _apply_visual_style() -> void:
	bg.visible = not _formal_background_active
	UI_THEME.style_label(title, 88, UI_THEME.GOLD_LIGHT)
	# Small ink text on paper needs clean glyphs instead of a second dark edge.
	_style_chapter_caption(chapter_label, 44, Color("#142735"))
	_style_chapter_caption(auto_save_label, 27, Color("#294c56"))
	for heading: Label in [$MainStats/MainStatsTitle, $SideStats/SideStatsTitle, $NextStats/NextStatsTitle]:
		UI_THEME.style_label(heading, 24, UI_THEME.TEXT)
	UI_THEME.style_label(main_stats_value, 46, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_label(side_stats_value, 46, UI_THEME.JADE)
	UI_THEME.style_label(next_stats_value, 30, UI_THEME.TEXT)
	for button: Button in [btn_explore, btn_next_chapter]:
		if not _install_button_art(button):
			UI_THEME.style_button(button, 26, UI_THEME.JADE)
		button.icon = null
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER


func _style_chapter_caption(label: Label, font_size: int, ink: Color) -> void:
	UI_THEME.style_label(label, font_size, ink if _formal_background_active else UI_THEME.TEXT, false)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_color_override("font_outline_color", Color.TRANSPARENT)
	label.add_theme_constant_override("outline_size", 0)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _install_button_art(button: Button) -> bool:
	for path: String in [BUTTON_NORMAL_PATH, BUTTON_HOVER_PATH, BUTTON_PRESSED_PATH]:
		if not ResourceLoader.exists(path):
			return false
	button.add_theme_stylebox_override("normal", _button_style(BUTTON_NORMAL_PATH))
	button.add_theme_stylebox_override("hover", _button_style(BUTTON_HOVER_PATH))
	button.add_theme_stylebox_override("pressed", _button_style(BUTTON_PRESSED_PATH))
	button.add_theme_stylebox_override("focus", _button_style(BUTTON_HOVER_PATH))
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", UI_THEME.TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", UI_THEME.GOLD_LIGHT)
	return true


func _button_style(path: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(path) as Texture2D
	style.texture_margin_left = 24.0
	style.texture_margin_top = 12.0
	style.texture_margin_right = 24.0
	style.texture_margin_bottom = 12.0
	style.content_margin_left = 20.0
	style.content_margin_top = 8.0
	style.content_margin_right = 20.0
	style.content_margin_bottom = 8.0
	return style


func _fill_summary() -> void:
	var payload: Dictionary = SceneRouter.get_result_payload()
	_chapter = int(payload.get("chapter", GameState.current_chapter))
	var chapter_titles := {
		1: "第一章 · 云影初卷",
		2: "第二章 · 竹尾风波",
		3: "第三章 · 入派抉择",
		4: "第四章 · 洛阳奇遇",
		5: "第五章 · 古峰残雪",
		6: "第六章 · 归村问师",
		7: "第七章 · 两盟一局",
		8: "第八章 · 雾散之后",
	}
	chapter_label.text = chapter_titles.get(_chapter, "第 %d 章 · 阶段结算" % _chapter)

	var main_done: int = 0
	var side_done: int = 0
	for qid in QuestManager.states.keys():
		if not String(qid).begins_with("q_ch%d_" % _chapter):
			continue
		if QuestManager.get_status(qid) != QuestDef.Status.COMPLETED:
			continue
		var quest := QuestManager.load_def(qid)
		if quest == null:
			continue
		if quest.kind == QuestDef.Kind.MAIN:
			main_done += 1
		else:
			side_done += 1

	var next_entry := SceneRouter.get_chapter_entry(_chapter + 1)
	var platform := get_node_or_null("/root/PlatformBridge")
	var next_chapter_allowed := platform == null or bool(platform.call("is_chapter_allowed", _chapter + 1))
	btn_next_chapter.visible = next_chapter_allowed and String(next_entry) != "" and ResourceLoader.exists("res://data/scenes/%s.tres" % next_entry)
	btn_explore.text = "继续探索"
	btn_next_chapter.text = "进入第 %d 章" % (_chapter + 1)
	main_stats_value.text = "%d 项" % main_done
	side_stats_value.text = "%d 项" % side_done
	if btn_next_chapter.visible:
		next_stats_value.text = "第 %d 章已解锁" % (_chapter + 1)
	elif _chapter == 8 and GameState.get_flag(&"chapter8_complete"):
		next_stats_value.text = "主线已完结\n可继续自由探索"
	elif not next_chapter_allowed:
		next_stats_value.text = "试玩内容已完成\n可继续自由探索"
	else:
		next_stats_value.text = "后续章节\n尚未开放"
	var unlocked_chapter := _chapter + 1 if btn_next_chapter.visible else _chapter
	# The router advances on completion. Cap that provisional value before autosaving.
	var last_chapter := int(SceneRouter.CHAPTER_ENTRIES.keys().max())
	GameState.current_chapter = clampi(maxi(GameState.current_chapter, unlocked_chapter), 1, last_chapter)


func _on_explore_pressed() -> void:
	SceneRouter.resume_current_field()


func _on_next_chapter_pressed() -> void:
	SceneRouter.go_chapter(_chapter + 1)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_explore_pressed()
