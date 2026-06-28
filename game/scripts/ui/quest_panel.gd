extends Control

signal closed

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const ART_DIR := "res://art/ui/quest/"

@onready var quest_list: VBoxContainer = %QuestList
@onready var detail: RichTextLabel = %Detail
@onready var close_btn: Button = %CloseBtn
@onready var summary_label: Label = $Content/Body/Toolbar/Summary
@onready var chapter_filter: OptionButton = $Content/Body/Toolbar/ChapterFilter
@onready var track_btn: Button = $Content/Body/Actions/TrackBtn
@onready var dismiss_btn: Button = $Content/Body/Actions/DismissBtn

var _filter_mode := "all"
var _chapter_filter := "all"
var _selected_qid: StringName = &""
var _filter_row: HBoxContainer = null
var _chapter_filter_btn: OptionButton = null
var _summary_label: Label = null
var _track_btn: Button = null
var _tracked_qid: StringName = &""

const CHAPTER_NAMES := {
	"ch1": "第一章 · 林西村下山",
	"ch2": "第二章 · 竹尾风波",
	"ch3": "第三章 · 入派抉择",
	"ch4": "第四章 · 洛阳奇遇",
	"ch5": "第五章 · 古月峰之围",
	"ch6": "第六章 · 师承之谜",
	"ch7": "第七章 · 烈云盟真相",
	"ch8": "第八章 · 茗雾决战",
}


func _ready() -> void:
	_build_formal_layout()
	_apply_visual_style()
	close_btn.pressed.connect(close)
	if dismiss_btn != null: dismiss_btn.pressed.connect(_untrack)
	QuestManager.active_quests_changed.connect(_refresh)
	_refresh()


func open() -> void:
	visible = true
	_refresh()
	close_btn.grab_focus()


func close() -> void:
	visible = false
	emit_signal("closed")


func _build_formal_layout() -> void:
	var body: VBoxContainer = get_node_or_null("Content/Body") as VBoxContainer
	if body == null:
		return

	var toolbar: HBoxContainer = body.get_node_or_null("Toolbar") as HBoxContainer
	if toolbar != null:
		if _filter_row == null:
			_filter_row = toolbar
			_apply_toolbar_style(toolbar)
	else:
		_build_toolbar_in_code(body)
		toolbar = body.get_node_or_null("Toolbar") as HBoxContainer

	var content: HBoxContainer = get_node_or_null("Content/Body/ListContent") as HBoxContainer
	if content != null:
		content.add_theme_constant_override("separation", 18)
	var list_scroll: ScrollContainer = get_node_or_null("Content/Body/ListContent/ListScroll") as ScrollContainer
	if list_scroll != null:
		list_scroll.custom_minimum_size = Vector2(430, 0)
	var detail_parent: Control = detail.get_parent() as Control
	if detail_parent != null:
		detail_parent.custom_minimum_size = Vector2(610, 0)

	var actions: HBoxContainer = body.get_node_or_null("Actions") as HBoxContainer
	if actions != null:
		if _track_btn == null:
			_track_btn = actions.get_node_or_null("TrackBtn") as Button
			if _track_btn != null:
				UI_THEME.style_button(_track_btn, 16, UI_THEME.JADE)
				_apply_btn_textures(_track_btn, "btn_track")
				_track_btn.pressed.connect(_track_selected)
		if dismiss_btn == null:
			dismiss_btn = actions.get_node_or_null("DismissBtn") as Button
			if dismiss_btn != null:
				UI_THEME.style_button(dismiss_btn, 16, UI_THEME.CRIMSON)
				dismiss_btn.pressed.connect(_untrack)
	else:
		_build_actions_in_code(body)


func _apply_toolbar_style(toolbar: HBoxContainer) -> void:
	var filter_pairs: Array = [["BtnAll", "all"], ["BtnActive", "active"], ["BtnMain", "main"], ["BtnDone", "done"]]
	for pair in filter_pairs:
		var btn: Button = toolbar.get_node_or_null(str(pair[0])) as Button
		if btn == null: continue
		var mode: String = str(pair[1])
		# all/main/done 有专属贴图; active 回退到通用 tab
		var tex_base: String = "tab_" + mode if mode in ["all", "main", "done"] else "tab"
		_apply_btn_textures(btn, tex_base)
		btn.tooltip_text = {"all": "全部", "active": "进行中", "main": "主线", "done": "已完成"}[mode]
		var lbl := btn.get_child(btn.get_child_count() - 1) as Label
		if lbl != null: lbl.text = btn.tooltip_text
		btn.pressed.connect(func(): _set_filter(mode))

	_chapter_filter_btn = toolbar.get_node_or_null("ChapterFilter") as OptionButton
	if _chapter_filter_btn != null:
		_chapter_filter_btn.add_item("全部章节", 0)
		_chapter_filter_btn.set_item_metadata(0, "all")
		var idx: int = 1
		for ch_key in ["ch1", "ch2", "ch3", "ch4", "ch5", "ch6", "ch7", "ch8"]:
			_chapter_filter_btn.add_item(CHAPTER_NAMES[ch_key], idx)
			_chapter_filter_btn.set_item_metadata(idx, ch_key)
			idx += 1
		_chapter_filter_btn.item_selected.connect(_on_chapter_filter_changed)

	_summary_label = toolbar.get_node_or_null("Summary") as Label
	if _summary_label != null:
		UI_THEME.style_label(_summary_label, 16, UI_THEME.MUTED, false)

	_update_filter_highlights()


func _update_filter_highlights() -> void:
	var toolbar: HBoxContainer = get_node_or_null("Content/Body/Toolbar") as HBoxContainer
	if toolbar == null: return
	var mode_map := {"BtnAll": "all", "BtnActive": "active", "BtnMain": "main", "BtnDone": "done"}
	for btn_name in mode_map:
		var btn: Button = toolbar.get_node_or_null(str(btn_name)) as Button
		if btn == null: continue
		var mode: String = str(mode_map[btn_name])
		var tex_base: String = "tab_" + mode if mode in ["all", "main", "done"] else "tab"
		var is_sel: bool = _filter_mode == mode
		var tex: Texture2D = _try_load(tex_base + ("_selected.png" if is_sel else "_normal.png"))
		if tex != null:
			btn.add_theme_stylebox_override("normal", _make_texture_stylebox(tex))


func _build_toolbar_in_code(body: VBoxContainer) -> void:
	var toolbar: HBoxContainer = HBoxContainer.new()
	toolbar.name = "Toolbar"
	toolbar.add_theme_constant_override("separation", 10)
	body.add_child(toolbar)
	body.move_child(toolbar, 1)
	_filter_row = toolbar
	_add_filter_button("全部", "all")
	_add_filter_button("进行中", "active")
	_add_filter_button("主线", "main")
	_add_filter_button("已完成", "done")

	_chapter_filter_btn = OptionButton.new()
	_chapter_filter_btn.add_item("全部章节", 0)
	_chapter_filter_btn.set_item_metadata(0, "all")
	var chap_idx: int = 1
	for ch_key in ["ch1", "ch2", "ch3", "ch4", "ch5", "ch6", "ch7", "ch8"]:
		_chapter_filter_btn.add_item(CHAPTER_NAMES[ch_key], chap_idx)
		_chapter_filter_btn.set_item_metadata(chap_idx, ch_key)
		chap_idx += 1
	_chapter_filter_btn.item_selected.connect(_on_chapter_filter_changed)
	toolbar.add_child(_chapter_filter_btn)
	_summary_label = Label.new()
	_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UI_THEME.style_label(_summary_label, 16, UI_THEME.MUTED, false)
	toolbar.add_child(_summary_label)


func _build_actions_in_code(body: VBoxContainer) -> void:
	var actions: HBoxContainer = HBoxContainer.new()
	actions.name = "Actions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	body.add_child(actions)
	_track_btn = Button.new()
	_track_btn.text = "追踪当前任务"
	_track_btn.custom_minimum_size = Vector2(190, 50)
	_track_btn.tooltip_text = "追踪当前任务"
	UI_THEME.style_button(_track_btn, 16, UI_THEME.JADE)
	_apply_btn_textures(_track_btn, "btn_track")
	_track_btn.pressed.connect(_track_selected)
	actions.add_child(_track_btn)


func _add_filter_button(label: String, mode: String) -> void:
	if _filter_row == null:
		return
	var btn: Button = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(105, 42)
	btn.tooltip_text = label
	UI_THEME.style_button(btn, 15, UI_THEME.BLUE_STEEL)
	# 使用 tab 贴图
	_apply_btn_textures(btn, "tab")
	# 覆盖文字（_apply_btn_textures 清空了 text）
	var lbl := btn.get_child(btn.get_child_count() - 1) as Label
	if lbl != null:
		lbl.text = label
	btn.pressed.connect(func(): _set_filter(mode))
	_filter_row.add_child(btn)


func _set_filter(mode: String) -> void:
	_filter_mode = mode
	_update_filter_highlights()
	_refresh()


func _on_chapter_filter_changed(idx: int) -> void:
	if _chapter_filter_btn != null:
		_chapter_filter = String(_chapter_filter_btn.get_item_metadata(idx))
	else:
		_chapter_filter = "all"
	_refresh()


func _extract_chapter(qid: StringName) -> String:
	var s := String(qid)
	for ch_key in CHAPTER_NAMES:
		if s.begins_with("q_" + ch_key + "_"):
			return ch_key
	return ""


func _apply_visual_style() -> void:
	var dim: ColorRect = get_node_or_null("Dim") as ColorRect
	if dim != null:
		dim.color = Color(0.005, 0.010, 0.016, 0.58)

	# 面板背景贴图
	var panel: PanelContainer = get_node_or_null("Panel") as PanelContainer
	if panel != null:
		panel.offset_left = -640
		panel.offset_top = -350
		panel.offset_right = 640
		panel.offset_bottom = 350
		var panel_tex = _try_load("panel_bg.png")
		if panel_tex != null:
			var sb := StyleBoxTexture.new()
			sb.texture = panel_tex
			sb.modulate_color = Color(1, 1, 1, 0.97)
			panel.add_theme_stylebox_override("panel", sb)
		else:
			panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.040, 0.060, 0.075, 0.98), UI_THEME.BLUE_STEEL, 18, 3))

	var title: Label = get_node_or_null("Content/Body/Header/Title") as Label
	if title != null:
		title.text = "任务卷宗"
		UI_THEME.style_label(title, 34, UI_THEME.GOLD_LIGHT)

	# 关闭按钮贴图
	close_btn.tooltip_text = "关闭"
	_apply_btn_textures(close_btn, "btn_close")
	# 覆盖文字
	var cl := close_btn.get_child(close_btn.get_child_count() - 1) as Label
	if cl != null:
		cl.text = "✕"

	# 详情区贴图
	var detail_tex := _try_load("detail_panel.png")
	var detail_parent := detail.get_parent() as Control
	if detail_parent != null and detail_tex != null:
		var dt := TextureRect.new()
		dt.texture = detail_tex
		dt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dt.stretch_mode = TextureRect.STRETCH_SCALE
		dt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		detail_parent.add_child(dt)
		detail_parent.move_child(dt, 0)

	UI_THEME.style_rich_text(detail, 18)


func _refresh() -> void:
	for child in quest_list.get_children():
		child.queue_free()

	# 收集并按章节分组
	var chapters: Dictionary = {}  ## ch_key → Array[{qid, def, status}]
	@warning_ignore("untyped_declaration")
	for key in QuestManager.states:
		var qid := StringName(key)
		var q: QuestDef = QuestManager.load_def(qid)
		if q == null:
			continue
		var status := QuestManager.get_status(qid)
		if not _quest_visible(q, status):
			continue
		var ch := _extract_chapter(qid)
		if ch == "":
			ch = "unknown"
		if not chapters.has(ch):
			chapters[ch] = []
		chapters[ch].append({"qid": qid, "def": q, "status": status})

	# 章节排序
	var sorted_chapters: Array[String] = []
	for ch_key in ["ch1", "ch2", "ch3", "ch4", "ch5", "ch6", "ch7", "ch8", "unknown"]:
		if chapters.has(ch_key):
			sorted_chapters.append(ch_key)

	var visible_qids: Array[StringName] = []
	var _first_visible_qid: StringName = &""

	for ch_key in sorted_chapters:
		# 章节筛选
		if _chapter_filter != "all" and ch_key != _chapter_filter:
			continue

		var entries: Array = chapters[ch_key]
		# 章内按 quest_id 排序
		entries.sort_custom(func(a, b): return String(a.qid) < String(b.qid))

		# 章节标题
		if sorted_chapters.size() > 1 or _chapter_filter != "all":
			var ch_name: String = CHAPTER_NAMES.get(ch_key, "其他")
			var ch_label: Label = Label.new()
			ch_label.text = "—— %s ——" % ch_name
			ch_label.add_theme_font_size_override("font_size", 15)
			ch_label.add_theme_color_override("font_color", UI_THEME.GOLD_LIGHT)
			ch_label.add_theme_constant_override("margin_top", 8)
			ch_label.add_theme_constant_override("margin_bottom", 4)
			ch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			quest_list.add_child(ch_label)

		for entry in entries:
			var qid: StringName = entry.qid
			var q: QuestDef = entry["def"]
			var status: int = entry.status
			visible_qids.append(qid)
			if _first_visible_qid == &"":
				_first_visible_qid = qid
			quest_list.add_child(_make_quest_row(qid, q, status))

	_update_summary()
	if visible_qids.is_empty():
		_show_empty()
		return
	if _selected_qid == &"" or not visible_qids.has(_selected_qid):
		_selected_qid = _first_visible_qid
	_show_selected()


func _quest_visible(q: QuestDef, status: int) -> bool:
	match _filter_mode:
		"active":
			return status == QuestDef.Status.IN_PROGRESS
		"main":
			return q.kind == QuestDef.Kind.MAIN
		"done":
			return status == QuestDef.Status.COMPLETED
		_:
			return true


func _make_quest_row(qid: StringName, q: QuestDef, status: int) -> Control:
	var is_sel := qid == _selected_qid
	var tex_name := "quest_row_selected.png" if is_sel else "quest_row_normal.png"
	var row_tex := _try_load(tex_name)

	var row_panel: PanelContainer = PanelContainer.new()
	row_panel.custom_minimum_size = Vector2(0, 100)

	if row_tex != null:
		var sb := StyleBoxTexture.new()
		sb.texture = row_tex
		row_panel.add_theme_stylebox_override("panel", sb)
	else:
		var border := UI_THEME.GOLD_LIGHT if is_sel else _status_color(status)
		row_panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.038, 0.060, 0.072, 0.90), border, 12, 1))

	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(0, 84)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.text = "%s  ·  %s\n%s  ·  %s" % [q.title, _status_text(status), _kind_text(q), _preview_text(q, status)]
	UI_THEME.style_button(btn, 16, _status_color(status))
	btn.pressed.connect(func(): _select_quest(qid))
	row_panel.add_child(btn)
	return row_panel


func _select_quest(qid: StringName) -> void:
	_selected_qid = qid
	_refresh()


func _show_selected() -> void:
	var q: QuestDef = QuestManager.load_def(_selected_qid)
	if q == null:
		_show_empty()
		return
	var status := QuestManager.get_status(_selected_qid)
	_show_quest(q, status)


func _show_empty() -> void:
	detail.text = "[b]任务卷宗[/b]\n\n当前分类下暂无任务。\n\n江湖事多，待接到线索后会在此处记录。"
	if _track_btn != null:
		_track_btn.disabled = true


func _show_quest(q: QuestDef, status: int) -> void:
	if _track_btn != null:
		_track_btn.disabled = status != QuestDef.Status.IN_PROGRESS
		if _selected_qid == _tracked_qid:
			_track_btn.text = "已追踪"
		else:
			_track_btn.text = "追踪当前任务"

	var ch_key := _extract_chapter(q.quest_id)
	var ch_name: String = CHAPTER_NAMES.get(ch_key, "")
	var ch_line := ""
	if ch_name != "":
		ch_line = "[color=#b8a060]%s · [/color]" % ch_name

	detail.text = "[b]%s[/b]\n[color=#9fd3d0]%s%s · %s[/color]\n\n[b]当前记述[/b]\n%s\n\n[b]完成条件[/b]\n%s\n\n[b]奖励[/b]\n%s\n\n[b]卷宗备注[/b]\n%s" % [
		q.title,
		ch_line,
		_kind_text(q),
		_status_text(status),
		q.get_description(status),
		_trigger_text(q),
		_reward_text(q),
		_note_text(q, status),
	]


func _track_selected() -> void:
	if _selected_qid == &"":
		return
	var status := QuestManager.get_status(_selected_qid)
	if status != QuestDef.Status.IN_PROGRESS:
		return
	_tracked_qid = _selected_qid
	_show_selected()


func _untrack() -> void:
	_tracked_qid = &""
	_refresh()


func _update_summary() -> void:
	if _summary_label == null:
		return
	var active := 0
	var done := 0
	var total := 0
	@warning_ignore("untyped_declaration")
	for key in QuestManager.states:
		total += 1
		var status := QuestManager.get_status(StringName(key))
		if status == QuestDef.Status.IN_PROGRESS:
			active += 1
		elif status == QuestDef.Status.COMPLETED:
			done += 1
	_summary_label.text = "卷宗 %d · 进行中 %d · 已完成 %d" % [total, active, done]


func _preview_text(q: QuestDef, status: int) -> String:
	var desc := q.get_description(status).strip_edges()
	if desc.length() > 22:
		return desc.substr(0, 22) + "…"
	return desc


func _trigger_text(q: QuestDef) -> String:
	if q.completion_triggers.is_empty():
		return "暂无明确条件"
	var lines: Array[String] = []
	for trigger in q.completion_triggers:
		lines.append("- %s" % trigger)
	return "\n".join(lines)


func _reward_text(q: QuestDef) -> String:
	var lines: Array[String] = []
	if q.reward_gold > 0:
		lines.append("金钱 +%d" % q.reward_gold)
	if q.reward_exp > 0:
		lines.append("经验 +%d" % q.reward_exp)
	for entry in q.reward_items:
		var item_id: String = String(entry.get("item_id", entry.get("id", "")))
		var count: int = int(entry.get("count", 1))

		if item_id != "":
			lines.append("物品 %s × %d" % [item_id, count])
	return "\n".join(lines) if not lines.is_empty() else "无额外奖励"


func _note_text(q: QuestDef, status: int) -> String:
	if status == QuestDef.Status.IN_PROGRESS and q.quest_id == _tracked_qid:
		return "当前正在追踪此任务。"
	if status == QuestDef.Status.IN_PROGRESS:
		return "可点击下方按钮将此任务设为当前追踪。"
	if status == QuestDef.Status.COMPLETED:
		return "此卷宗已归档。"
	if status == QuestDef.Status.FAILED:
		return "此任务已经失败。"
	return "尚未正式接取。"


func _kind_text(q: QuestDef) -> String:
	return "主线" if q.kind == QuestDef.Kind.MAIN else "支线"


func _status_text(status: int) -> String:
	match status:
		QuestDef.Status.NOT_STARTED:
			return "未开始"
		QuestDef.Status.IN_PROGRESS:
			return "进行中"
		QuestDef.Status.COMPLETED:
			return "已完成"
		QuestDef.Status.FAILED:
			return "已失败"
		_:
			return "未知"


func _status_color(status: int) -> Color:
	match status:
		QuestDef.Status.IN_PROGRESS:
			return UI_THEME.JADE
		QuestDef.Status.COMPLETED:
			return UI_THEME.BLUE_STEEL
		QuestDef.Status.FAILED:
			return UI_THEME.CRIMSON
		_:
			return UI_THEME.GOLD


func _try_load(name: String) -> Texture2D:
	var path := ART_DIR + name
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _apply_btn_textures(btn: Button, base_name: String) -> void:
	var t_n := _try_load(base_name + "_normal.png")
	var t_h := _try_load(base_name + "_hover.png")
	var t_p := _try_load(base_name + "_pressed.png")
	if t_n == null:
		return
	btn.flat = true
	btn.text = ""
	btn.custom_minimum_size = Vector2(t_n.get_width(), t_n.get_height())
	btn.add_theme_stylebox_override("normal", _make_texture_stylebox(t_n))
	if t_h != null:
		btn.add_theme_stylebox_override("hover", _make_texture_stylebox(t_h))
	if t_p != null:
		btn.add_theme_stylebox_override("pressed", _make_texture_stylebox(t_p))
	# 文字叠在按钮上
	var lbl := Label.new()
	lbl.text = btn.tooltip_text if btn.tooltip_text != "" else ""
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.98))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.anchors_preset = Control.PRESET_FULL_RECT
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)


func _make_texture_stylebox(tex: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	return sb


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
