extends Control

signal closed

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const ART_DIR := "res://art/ui/quest/runtime_v1/"
const ITEM_FALLBACK := preload("res://art/ui/inventory/icons/icon_scroll_sm.png")
const TITLE_ART_PATH := "res://art/ui/title/title_quest_log_v1.png"
const FORMAL_CHOICE_SCENE := preload("res://scenes/ui/formal_choice_menu.tscn")
const ITEM_DETAIL_TIP := preload("res://scripts/ui/item_detail_tip.gd")
const REWARD_GOLD_ICON := "res://art/ui/quest/reward_gold_icon_v1.png"
const REWARD_EXP_ICON := "res://art/ui/quest/reward_exp_icon_v1.png"
const REWARD_FRAME_NORMAL := "res://art/ui/inventory/cells/cell_default.png"
const REWARD_FRAME_HOVER := "res://art/ui/inventory/cells/cell_selected.png"

const CHAPTER_NAMES := {
	"all": "当前章节",
	"ch1": "第一章 · 林西村下山",
	"ch2": "第二章 · 竹尾风波",
	"ch3": "第三章 · 入派抉择",
	"ch4": "第四章 · 洛阳奇遇",
	"ch5": "第五章 · 古月峰之围",
	"ch6": "第六章 · 师承之谜",
	"ch7": "第七章 · 烈云盟真相",
	"ch8": "第八章 · 茗雾决战",
}

@onready var quest_list: VBoxContainer = %QuestList
@onready var detail_text: RichTextLabel = %DetailText
@onready var close_btn: TextureButton = %CloseBtn
@onready var chapter_dropdown: TextureButton = %ChapterDropdown
@onready var reward_list: FlowContainer = %RewardList
@onready var reward_text: Label = %RewardText
@onready var track_btn: TextureButton = %TrackBtn

var _status_page := "active"
var _kind_filter := "main"
var _chapter_filter := "all"
var _selected_qid: StringName = &""
var _status_btns: Dictionary = {}
var _kind_btns: Dictionary = {}
var _chapter_menu: FormalChoiceMenu
var _reward_detail_tip


func _ready() -> void:
	visible = false
	_setup_close_button()
	_setup_tabs()
	_setup_chapter_menu()
	_setup_track_button()
	_setup_text()
	_setup_reward_detail_tip()
	QuestManager.active_quests_changed.connect(_refresh)
	QuestManager.tracked_quest_changed.connect(_on_tracked_quest_changed)
	InvestigationState.state_changed.connect(_refresh)
	_refresh()


func open() -> void:
	visible = true
	move_to_front()
	_rebuild_chapter_menu()
	_refresh()
	close_btn.grab_focus()


func close() -> void:
	if _reward_detail_tip != null:
		_reward_detail_tip.hide_tip()
	visible = false
	emit_signal("closed")


func _setup_close_button() -> void:
	close_btn.texture_normal = load("res://art/ui/inventory/buttons/btn_x_normal.png")
	close_btn.texture_hover = load("res://art/ui/inventory/buttons/btn_x_hover.png")
	close_btn.texture_pressed = load("res://art/ui/inventory/buttons/btn_x_pressed.png")
	close_btn.tooltip_text = "关闭 (Esc)"
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(close)


func _setup_tabs() -> void:
	_kind_btns = {"main": %PrimaryMain, "side": %PrimarySide}
	_status_btns = {"active": %StatusActive, "done": %StatusDone}
	for mode in _kind_btns:
		var button: TextureButton = _kind_btns[mode]
		_setup_primary_tab(button, "主线" if mode == "main" else "支线")
		button.pressed.connect(func(): _set_kind_filter(mode))
	for mode in _status_btns:
		var button: TextureButton = _status_btns[mode]
		_setup_texture_button(button, "secondary", "进行中" if mode == "active" else "已完成", 15, true)
		button.pressed.connect(func(): _set_status_page(mode))
	_update_tab_states()


func _setup_chapter_menu() -> void:
	_setup_texture_button(chapter_dropdown, "chapter", CHAPTER_NAMES[_chapter_filter], 15)
	chapter_dropdown.pressed.connect(_open_chapter_menu)
	_chapter_menu = FORMAL_CHOICE_SCENE.instantiate() as FormalChoiceMenu
	_chapter_menu.name = "ChapterMenu"
	add_child(_chapter_menu)
	_chapter_menu.item_selected.connect(func(id: StringName): _set_chapter_filter(String(id)))
	_rebuild_chapter_menu()


func _rebuild_chapter_menu() -> void:
	if _chapter_menu == null:
		return
	var unlocked_chapter: int = clampi(GameState.current_chapter, 1, 8)
	var selected_number: int = int(_chapter_filter.trim_prefix("ch")) if _chapter_filter.begins_with("ch") else 0
	if selected_number > unlocked_chapter:
		_chapter_filter = "all"
	var options: Array[Dictionary] = [{"id": &"all", "label": CHAPTER_NAMES["all"]}]
	for chapter_number: int in range(1, unlocked_chapter + 1):
		var chapter_key: String = "ch%d" % chapter_number
		options.append({"id": StringName(chapter_key), "label": CHAPTER_NAMES[chapter_key]})
	_chapter_menu.set_meta("chapter_options", options)
	_set_caption(chapter_dropdown, CHAPTER_NAMES.get(_chapter_filter, CHAPTER_NAMES["all"]))


func _setup_track_button() -> void:
	_setup_texture_button(track_btn, "track", "追踪", 17)
	track_btn.pressed.connect(_toggle_tracking)


func _setup_text() -> void:
	var title := $Panel/Title as Label
	if ResourceLoader.exists(TITLE_ART_PATH):
		var title_art := TextureRect.new()
		title_art.name = "TitleArt"
		title_art.texture = load(TITLE_ART_PATH) as Texture2D
		title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_art.position = Vector2(485, 32)
		title_art.size = Vector2(230, 100)
		$Panel.add_child(title_art)
		title.visible = false
	else:
		UI_THEME.style_label(title, 31, UI_THEME.GOLD_LIGHT)
	detail_text.add_theme_font_size_override("normal_font_size", 17)
	detail_text.add_theme_color_override("default_color", Color(0.84, 0.91, 0.93, 1.0))
	detail_text.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	UI_THEME.style_label($Panel/RewardLabel as Label, 17, UI_THEME.JADE)
	UI_THEME.style_label(reward_text, 14, Color(0.72, 0.82, 0.84, 1.0))


func _setup_reward_detail_tip() -> void:
	_reward_detail_tip = ITEM_DETAIL_TIP.new()
	_reward_detail_tip.name = "RewardItemDetailTip"
	_reward_detail_tip.position = Vector2(650, 370)
	_reward_detail_tip.size = Vector2(390, 166)
	_reward_detail_tip.z_index = 80
	$Panel.add_child(_reward_detail_tip)


func _setup_button(button: Button, texture_prefix: String, caption: String, font_size: int) -> void:
	button.flat = true
	button.text = ""
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = caption
	_set_button_style(button, texture_prefix, "normal", "hover", "pressed")
	_add_caption(button, caption, font_size)


func _setup_primary_tab(button: TextureButton, caption: String) -> void:
	button.texture_normal = null
	button.texture_hover = null
	button.texture_pressed = null
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = caption
	_add_caption(button, caption, 19)


func _setup_texture_button(button: TextureButton, texture_prefix: String, caption: String, font_size: int, keep_aspect: bool = false) -> void:
	button.texture_normal = _texture("%s_normal.png" % texture_prefix)
	button.texture_hover = _texture("%s_hover.png" % texture_prefix)
	button.texture_pressed = _texture("%s_pressed.png" % texture_prefix)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED if keep_aspect else TextureButton.STRETCH_SCALE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = caption
	_add_caption(button, caption, font_size)


func _set_button_style(button: Button, prefix: String, normal: String, hover: String, pressed: String) -> void:
	_apply_stylebox(button, "normal", _texture("%s_%s.png" % [prefix, normal]))
	_apply_stylebox(button, "hover", _texture("%s_%s.png" % [prefix, hover]))
	_apply_stylebox(button, "pressed", _texture("%s_%s.png" % [prefix, pressed]))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _apply_stylebox(button: Button, state: String, texture: Texture2D) -> void:
	if texture == null:
		return
	var style := StyleBoxTexture.new()
	style.texture = texture
	button.add_theme_stylebox_override(state, style)


func _add_caption(button: BaseButton, caption: String, font_size: int) -> void:
	var old := button.get_node_or_null("Caption")
	if old != null:
		old.queue_free()
	var label := Label.new()
	label.name = "Caption"
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_top = -2.0
	label.offset_bottom = -2.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.93, 0.97, 0.98, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	button.add_child(label)


func _set_caption(button: BaseButton, text: String) -> void:
	var label := button.get_node_or_null("Caption") as Label
	if label != null:
		label.text = text
	button.tooltip_text = text


func _open_chapter_menu() -> void:
	if _kind_filter != "main":
		return
	var options: Array[Dictionary] = _chapter_menu.get_meta("chapter_options", [])
	_chapter_menu.show_choices("选择章节", options, StringName(_chapter_filter))


func _set_status_page(mode: String) -> void:
	_status_page = mode
	_selected_qid = &""
	_update_tab_states()
	_refresh()


func _set_kind_filter(mode: String) -> void:
	_kind_filter = mode
	_selected_qid = &""
	chapter_dropdown.visible = mode == "main"
	_update_tab_states()
	_refresh()


func _set_chapter_filter(mode: String) -> void:
	_chapter_filter = mode
	_selected_qid = &""
	_set_caption(chapter_dropdown, CHAPTER_NAMES.get(mode, CHAPTER_NAMES["all"]))
	_refresh()


func _update_tab_states() -> void:
	for mode in _kind_btns:
		_set_primary_tab_state(_kind_btns[mode] as TextureButton, mode == _kind_filter)
	for mode in _status_btns:
		_set_tab_state(_status_btns[mode] as TextureButton, "secondary", mode == _status_page)


func _set_primary_tab_state(button: TextureButton, selected: bool) -> void:
	var caption := button.get_node_or_null("Caption") as Label
	if caption != null:
		caption.add_theme_color_override("font_color", UI_THEME.JADE if selected else Color(0.84, 0.90, 0.93, 1.0))
		caption.add_theme_color_override("font_outline_color", Color(0.01, 0.04, 0.05, 1.0))
		caption.add_theme_constant_override("outline_size", 2)


func _set_tab_state(button: TextureButton, prefix: String, selected: bool) -> void:
	button.texture_normal = _texture("%s_%s.png" % [prefix, "selected" if selected else "normal"])
	button.texture_hover = _texture("%s_%s.png" % [prefix, "selected" if selected else "hover"])
	button.texture_pressed = _texture("%s_pressed.png" % prefix)


func _refresh() -> void:
	if quest_list == null:
		return
	for child in quest_list.get_children():
		child.queue_free()
	var entries: Array[Dictionary] = []
	for key in QuestManager.states:
		var qid := StringName(key)
		var quest: QuestDef = QuestManager.load_def(qid)
		if quest == null:
			continue
		var status := QuestManager.get_status(qid)
		if _quest_visible(quest, status):
			entries.append({"qid": qid, "quest": quest, "status": status})
	entries.sort_custom(func(a: Dictionary, b: Dictionary): return String(a.qid) < String(b.qid))
	for entry in entries:
		quest_list.add_child(_make_quest_row(entry.qid, entry.quest, entry.status))
	if entries.is_empty():
		_show_empty()
		return
	var visible_ids: Array[StringName] = []
	for entry in entries:
		visible_ids.append(entry.qid)
	if not visible_ids.has(_selected_qid):
		_selected_qid = visible_ids[0]
	_show_selected()


func _quest_visible(quest: QuestDef, status: int) -> bool:
	if _status_page == "active" and status != QuestDef.Status.IN_PROGRESS:
		return false
	if _status_page == "done" and status != QuestDef.Status.COMPLETED:
		return false
	if _kind_filter == "side":
		return quest.kind == QuestDef.Kind.SIDE
	if quest.kind != QuestDef.Kind.MAIN:
		return false
	return _chapter_filter == "all" or _extract_chapter(quest.quest_id) == _chapter_filter


func _make_quest_row(qid: StringName, quest: QuestDef, _status: int) -> TextureButton:
	var row := TextureButton.new()
	row.custom_minimum_size = Vector2(276, 66)
	row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.texture_normal = load("res://art/ui/quest/quest_row_selected.png" if qid == _selected_qid else "res://art/ui/quest/quest_row_normal.png")
	row.texture_hover = load("res://art/ui/quest/quest_row_selected.png" if qid == _selected_qid else "res://art/ui/quest/quest_row_hover.png")
	row.texture_pressed = load("res://art/ui/quest/quest_row_selected.png")
	row.ignore_texture_size = true
	row.stretch_mode = TextureButton.STRETCH_SCALE
	row.tooltip_text = quest.title
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_add_row_text(row, _trim(quest.title, 16), _map_text(quest))
	row.pressed.connect(func(): _select_quest(qid))
	return row


func _add_row_text(row: TextureButton, title: String, subtitle: String) -> void:
	var title_label := Label.new()
	title_label.text = title
	title_label.position = Vector2(47, 7)
	title_label.size = Vector2(214, 25)
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.97, 1.0))
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(title_label)
	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.position = Vector2(47, 33)
	subtitle_label.size = Vector2(214, 23)
	subtitle_label.add_theme_font_size_override("font_size", 12)
	subtitle_label.add_theme_color_override("font_color", Color(0.55, 0.77, 0.78, 1.0))
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(subtitle_label)


func _select_quest(qid: StringName) -> void:
	_selected_qid = qid
	_refresh()


func _show_selected() -> void:
	var quest: QuestDef = QuestManager.load_def(_selected_qid)
	if quest == null:
		_show_empty()
		return
	var status := QuestManager.get_status(_selected_qid)
	var chapter := _extract_chapter(quest.quest_id)
	var chapter_name: String = CHAPTER_NAMES.get(chapter, "")
	detail_text.text = "[font_size=24][color=#e7eef0]%s[/color][/font_size]\n[color=#9fd3d0]%s · %s · %s[/color]\n\n[color=#7fc4c1]任务描述[/color]\n%s" % [
		quest.title, chapter_name, _kind_text(quest), _status_text(status), quest.get_description(status),
	]
	var clue_records := QuestManager.get_progress_record_texts(_selected_qid)
	if not quest.progress_records.is_empty():
		detail_text.text += "\n\n[color=#7fc4c1]线索记录[/color]\n"
		detail_text.text += "[color=#82949c]尚未记录新线索[/color]" if clue_records.is_empty() else "\n".join(clue_records.map(func(text: String): return "• %s" % text))
	_populate_rewards(quest)
	track_btn.disabled = status != QuestDef.Status.IN_PROGRESS or quest.kind != QuestDef.Kind.SIDE
	_set_caption(track_btn, "取消追踪" if QuestManager.tracked_side_quest_id == _selected_qid else "追踪")


func _show_empty() -> void:
	detail_text.text = "[font_size=24][color=#e7eef0]任务卷宗[/color][/font_size]\n\n当前分类下暂无任务。"
	for child in reward_list.get_children():
		child.queue_free()
	reward_text.text = ""
	reward_text.visible = false
	track_btn.disabled = true
	_set_caption(track_btn, "追踪")


func _populate_rewards(quest: QuestDef) -> void:
	if _reward_detail_tip != null:
		_reward_detail_tip.hide_tip()
	for child in reward_list.get_children():
		child.queue_free()
	for entry in quest.reward_items:
		var item_id: StringName = StringName(entry.get("item_id", entry.get("id", "")))
		var count: int = int(entry.get("count", 1))
		reward_list.add_child(_make_reward_slot(item_id, count))
	if quest.reward_gold > 0:
		reward_list.add_child(_make_value_reward_slot(REWARD_GOLD_ICON, "金钱 +%d" % quest.reward_gold, Color("e5c06b")))
	if quest.reward_exp > 0:
		reward_list.add_child(_make_value_reward_slot(REWARD_EXP_ICON, "经验 +%d" % quest.reward_exp, Color("72d2c9")))
	reward_text.text = ""
	reward_text.visible = false
	if reward_list.get_child_count() == 0:
		var none := Label.new()
		none.text = "无道具奖励"
		none.add_theme_color_override("font_color", Color(0.62, 0.70, 0.72, 1.0))
		reward_list.add_child(none)


func _make_reward_slot(item_id: StringName, count: int) -> VBoxContainer:
	var item := Inventory.load_item_by_id(item_id)
	var name := item.display_name if item != null else String(item_id)
	var entry := VBoxContainer.new()
	entry.custom_minimum_size = Vector2(92, 92)
	entry.alignment = BoxContainer.ALIGNMENT_CENTER
	var button := _make_reward_base("点击查看%s详情" % name)
	var icon := TextureRect.new()
	icon.texture = _item_icon(item)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(13, 13)
	icon.size = Vector2(56, 56)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	_add_reward_count(button, "×%d" % count)
	button.pressed.connect(_show_reward_item_detail.bind(item, count, button))
	entry.add_child(button)
	return entry


func _make_reward_base(tooltip: String) -> TextureButton:
	var button := TextureButton.new()
	button.custom_minimum_size = Vector2(82, 82)
	button.size = Vector2(82, 82)
	button.texture_normal = load(REWARD_FRAME_NORMAL) as Texture2D
	button.texture_hover = load(REWARD_FRAME_HOVER) as Texture2D
	button.texture_pressed = load(REWARD_FRAME_HOVER) as Texture2D
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.tooltip_text = tooltip
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button


func _make_value_reward_slot(icon_path: String, caption: String, color: Color) -> VBoxContainer:
	var entry := VBoxContainer.new()
	entry.custom_minimum_size = Vector2(92, 92)
	entry.alignment = BoxContainer.ALIGNMENT_CENTER
	var base := _make_reward_base(caption)
	var icon := TextureRect.new()
	icon.texture = load(icon_path) as Texture2D if ResourceLoader.exists(icon_path) else ITEM_FALLBACK
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(19, 7)
	icon.size = Vector2(44, 44)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(icon)
	var label := Label.new()
	label.text = caption
	label.position = Vector2(2, 54)
	label.size = Vector2(78, 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(label)
	entry.add_child(base)
	return entry


func _show_reward_item_detail(item: Item, count: int, source_button: Control) -> void:
	if item == null or source_button == null or _reward_detail_tip == null:
		return
	var panel := $Panel as Control
	if panel == null:
		return
	# Control has no Node2D.to_local(). Convert both controls through the canvas
	# transform so this remains correct under the centered panel and safe-area UI
	# scaling used by desktop and WeChat layouts.
	var panel_canvas := panel.get_global_transform_with_canvas()
	var source_canvas := source_button.get_global_transform_with_canvas()
	var anchor: Vector2 = panel_canvas.affine_inverse() * source_canvas.origin
	if _reward_detail_tip != null:
		var max_x: float = panel.size.x - _reward_detail_tip.size.x - 54.0
		_reward_detail_tip.position = Vector2(
			clampf(anchor.x + source_button.size.x + 14.0, 430.0, max_x),
			clampf(anchor.y - 88.0, 315.0, 470.0)
		)
		_reward_detail_tip.show_item(item, count)


func _add_reward_count(button: TextureButton, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 7)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)


func _item_icon(item: Item) -> Texture2D:
	if item != null and item.icon_path != "" and ResourceLoader.exists(item.icon_path):
		return load(item.icon_path) as Texture2D
	return ITEM_FALLBACK


func _toggle_tracking() -> void:
	if _selected_qid == &"" or QuestManager.get_status(_selected_qid) != QuestDef.Status.IN_PROGRESS:
		return
	var quest := QuestManager.load_def(_selected_qid)
	if quest == null or quest.kind != QuestDef.Kind.SIDE:
		return
	QuestManager.toggle_tracked_side_quest(_selected_qid)
	_show_selected()


func _on_tracked_quest_changed(_qid: StringName) -> void:
	if visible:
		_refresh()


func _extract_chapter(qid: StringName) -> String:
	var quest_id := String(qid)
	for chapter in CHAPTER_NAMES:
		if chapter != "all" and quest_id.begins_with("q_%s_" % chapter):
			return chapter
	return ""


func _map_text(quest: QuestDef) -> String:
	var place: String = CHAPTER_NAMES.get(_extract_chapter(quest.quest_id), "江湖")
	return ("主线" if quest.kind == QuestDef.Kind.MAIN else "支线") + " · " + place


func _trim(text: String, length: int) -> String:
	return text.substr(0, length) + "…" if text.length() > length else text


func _kind_text(quest: QuestDef) -> String:
	return "主线" if quest.kind == QuestDef.Kind.MAIN else "支线"


func _status_text(status: int) -> String:
	return "进行中" if status == QuestDef.Status.IN_PROGRESS else "已完成"


func _texture(name: String) -> Texture2D:
	var path := ART_DIR + name
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _chapter_menu != null and _chapter_menu.is_open():
			return
		close()
		get_viewport().set_input_as_handled()
