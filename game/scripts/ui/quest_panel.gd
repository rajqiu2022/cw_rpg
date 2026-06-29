extends Control

signal closed

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const ART_DIR := "res://art/ui/quest/"
const SHARED_BTN_DIR := "res://art/ui/inventory/buttons/"

@onready var quest_list: VBoxContainer = %QuestList
@onready var detail: RichTextLabel = %Detail
@onready var close_btn: Button = %CloseBtn

var _filter_mode: String = "all"
var _chapter_filter: String = "all"
var _selected_qid: StringName = &""
var _tracked_qid: StringName = &""
var _chapter_filter_btn: OptionButton = null
var _summary_label: Label = null
var _track_btn: Button = null
var _dismiss_btn: Button = null
var _filter_btns: Dictionary = {}

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
	visible = false
	_setup_filter_buttons()
	_setup_chapter_filter()
	_setup_action_buttons()
	_apply_visual_style()
	close_btn.pressed.connect(close)
	QuestManager.active_quests_changed.connect(_refresh)
	_refresh()


func open() -> void:
	visible = true
	_refresh()
	close_btn.grab_focus()


func close() -> void:
	visible = false
	emit_signal("closed")


func _setup_filter_buttons() -> void:
	_filter_btns.clear()
	var data := {
		"BtnAll": ["all", "tab_all"],
		"BtnActive": ["active", "tab"],
		"BtnMain": ["main", "tab_main"],
		"BtnDone": ["done", "tab_done"],
	}
	for btn_name in data:
		var d: Array = data[btn_name]
		var mode: String = str(d[0])
		var tex_base: String = str(d[1])
		var btn: Button = get_node_or_null(str(btn_name)) as Button
		if btn == null: continue
		_filter_btns[mode] = btn
		_setup_texture_button(btn, tex_base, {"all": "全部", "active": "进行中", "main": "主线", "done": "已完成"}[mode])
		btn.pressed.connect(func(): _set_filter(mode))


func _setup_chapter_filter() -> void:
	_chapter_filter_btn = get_node_or_null("ChapterFilter") as OptionButton
	if _chapter_filter_btn == null: return
	_chapter_filter_btn.add_item("全部章节", 0)
	_chapter_filter_btn.set_item_metadata(0, "all")
	var idx: int = 1
	for ch_key in ["ch1", "ch2", "ch3", "ch4", "ch5", "ch6", "ch7", "ch8"]:
		_chapter_filter_btn.add_item(CHAPTER_NAMES[ch_key], idx)
		_chapter_filter_btn.set_item_metadata(idx, ch_key)
		idx += 1
	_chapter_filter_btn.item_selected.connect(_on_chapter_filter_changed)


func _setup_action_buttons() -> void:
	_track_btn = get_node_or_null("TrackBtn") as Button
	if _track_btn != null:
		_apply_btn_textures(_track_btn, "btn_track")
		_track_btn.pressed.connect(_track_selected)
	_dismiss_btn = get_node_or_null("DismissBtn") as Button
	if _dismiss_btn != null:
		UI_THEME.style_button(_dismiss_btn, 16, UI_THEME.CRIMSON)
		_dismiss_btn.pressed.connect(_untrack)
	_summary_label = get_node_or_null("Summary") as Label
	if _summary_label != null:
		UI_THEME.style_label(_summary_label, 16, UI_THEME.MUTED, false)


func _on_chapter_filter_changed(idx: int) -> void:
	if _chapter_filter_btn != null:
		_chapter_filter = str(_chapter_filter_btn.get_item_metadata(idx))
	_refresh()


func _set_filter(mode: String) -> void:
	_filter_mode = mode
	_update_filter_highlights()
	_refresh()


func _apply_visual_style() -> void:
	var title: Label = get_node_or_null("Title") as Label
	if title != null:
		UI_THEME.style_label(title, 34, UI_THEME.GOLD_LIGHT)

	var cn: Texture2D = load(SHARED_BTN_DIR + "btn_x_normal.png") as Texture2D
	if cn != null:
		close_btn.flat = true
		close_btn.text = ""
		close_btn.custom_minimum_size = Vector2(cn.get_width(), cn.get_height())
		close_btn.add_theme_stylebox_override("normal", _tex_stylebox(cn))
		close_btn.add_theme_stylebox_override("hover", _tex_stylebox(load(SHARED_BTN_DIR + "btn_x_hover.png")))
		close_btn.add_theme_stylebox_override("pressed", _tex_stylebox(load(SHARED_BTN_DIR + "btn_x_pressed.png")))
	UI_THEME.style_rich_text(detail, 18)


func _setup_texture_button(btn: Button, tex_base: String, label_text: String) -> void:
	var t_n: Texture2D = load(ART_DIR + tex_base + "_normal.png") as Texture2D
	if t_n == null: return
	btn.flat = true
	btn.text = ""
	btn.custom_minimum_size = Vector2(t_n.get_width(), t_n.get_height())
	btn.add_theme_stylebox_override("normal", _tex_stylebox(t_n))
	var t_h: Texture2D = load(ART_DIR + tex_base + "_hover.png") as Texture2D
	if t_h != null: btn.add_theme_stylebox_override("hover", _tex_stylebox(t_h))
	var t_p: Texture2D = load(ART_DIR + tex_base + "_pressed.png") as Texture2D
	if t_p != null: btn.add_theme_stylebox_override("pressed", _tex_stylebox(t_p))
	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.98))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.anchors_preset = Control.PRESET_FULL_RECT
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)


func _update_filter_highlights() -> void:
	for mode in _filter_btns:
		var btn: Button = _filter_btns[mode] as Button
		if btn == null: continue
		var tex_base: String = "tab"
		match mode:
			"all": tex_base = "tab_all"
			"main": tex_base = "tab_main"
			"done": tex_base = "tab_done"
		var tex: Texture2D = load(ART_DIR + tex_base + ("_selected.png" if _filter_mode == mode else "_normal.png")) as Texture2D
		if tex != null:
			btn.add_theme_stylebox_override("normal", _tex_stylebox(tex))


func _update_summary() -> void:
	if _summary_label == null: return
	var active: int = 0
	var done: int = 0
	var total: int = 0
	@warning_ignore("untyped_declaration")
	for key in QuestManager.states:
		total += 1
		var s: int = QuestManager.get_status(StringName(key))
		if s == QuestDef.Status.IN_PROGRESS: active += 1
		elif s == QuestDef.Status.COMPLETED: done += 1
	_summary_label.text = "卷宗 %d · 进行中 %d · 已完成 %d" % [total, active, done]


func _refresh() -> void:
	for child in quest_list.get_children():
		child.queue_free()

	var chapters: Dictionary = {}
	@warning_ignore("untyped_declaration")
	for key in QuestManager.states:
		var qid: StringName = StringName(key)
		var q: QuestDef = QuestManager.load_def(qid)
		if q == null: continue
		var status: int = QuestManager.get_status(qid)
		if not _quest_visible(q, status): continue
		var ch: String = _extract_chapter(qid)
		if ch == "": ch = "unknown"
		if not chapters.has(ch): chapters[ch] = []
		chapters[ch].append({"qid": qid, "def": q, "status": status})

	var sorted_chapters: Array[String] = []
	for ch_key in ["ch1", "ch2", "ch3", "ch4", "ch5", "ch6", "ch7", "ch8", "unknown"]:
		if chapters.has(ch_key) and (_chapter_filter == "all" or ch_key == _chapter_filter):
			sorted_chapters.append(ch_key)

	var visible_qids: Array[StringName] = []
	var _first_visible_qid: StringName = &""

	for ch_key in sorted_chapters:
		var entries: Array = chapters[ch_key]
		entries.sort_custom(func(a, b): return String(a.qid) < String(b.qid))
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
			visible_qids.append(qid)
			if _first_visible_qid == &"": _first_visible_qid = qid
			quest_list.add_child(_make_quest_row(qid, entry["def"], entry.status))

	_update_summary()
	if visible_qids.is_empty(): _show_empty(); return
	if _selected_qid == &"" or not visible_qids.has(_selected_qid):
		_selected_qid = _first_visible_qid
	_show_selected()


func _quest_visible(q: QuestDef, status: int) -> bool:
	match _filter_mode:
		"active": return status == QuestDef.Status.IN_PROGRESS
		"main":   return q.kind == QuestDef.Kind.MAIN
		"done":   return status == QuestDef.Status.COMPLETED
		_: return true


func _make_quest_row(qid: StringName, q: QuestDef, status: int) -> Control:
	var row_panel: PanelContainer = PanelContainer.new()
	row_panel.custom_minimum_size = Vector2(0, 56)
	var is_sel: bool = qid == _selected_qid
	var tex_name: String = "quest_row_selected.png" if is_sel else "quest_row_normal.png"
	var row_tex: Texture2D = _try_load(tex_name)
	var hover_tex: Texture2D = _try_load("quest_row_hover.png")
	if row_tex != null:
		var sb: StyleBoxTexture = StyleBoxTexture.new()
		sb.texture = row_tex
		row_panel.add_theme_stylebox_override("panel", sb)
		if hover_tex != null and not is_sel:
			var sb_h: StyleBoxTexture = StyleBoxTexture.new()
			sb_h.texture = hover_tex
			row_panel.add_theme_stylebox_override("hover", sb_h)
	else:
		var border: Color = UI_THEME.GOLD_LIGHT if is_sel else _status_color(status)
		row_panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.038, 0.060, 0.072, 0.90), border, 12, 1))

	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(0, 44)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.text = "%s  ·  %s\n%s  ·  %s" % [q.title, _status_text(status), _kind_text(q), _preview_text(q, status)]
	UI_THEME.style_button(btn, 16, _status_color(status))
	var captured_qid: StringName = qid
	btn.pressed.connect(func(): _select_quest(captured_qid))
	row_panel.add_child(btn)
	return row_panel


func _select_quest(qid: StringName) -> void:
	_selected_qid = qid
	_refresh()


func _show_selected() -> void:
	var q: QuestDef = QuestManager.load_def(_selected_qid)
	if q == null: _show_empty(); return
	var status: int = QuestManager.get_status(_selected_qid)
	if _track_btn != null:
		_track_btn.disabled = status != QuestDef.Status.IN_PROGRESS
		_track_btn.text = "已追踪" if _selected_qid == _tracked_qid else "追踪"
	if _dismiss_btn != null:
		_dismiss_btn.visible = _selected_qid == _tracked_qid

	var ch_key: String = _extract_chapter(q.quest_id)
	var ch_name: String = CHAPTER_NAMES.get(ch_key, "")
	var ch_line: String = "" if ch_name == "" else "[color=#b8a060]%s · [/color]" % ch_name

	detail.text = "[b]%s[/b]\n[color=#9fd3d0]%s%s · %s[/color]\n\n[b]当前记述[/b]\n%s\n\n[b]完成条件[/b]\n%s\n\n[b]奖励[/b]\n%s\n\n[b]卷宗备注[/b]\n%s" % [
		q.title, ch_line, _kind_text(q), _status_text(status),
		q.get_description(status), _trigger_text(q), _reward_text(q), _note_text(q, status),
	]


func _show_empty() -> void:
	detail.text = "[b]任务卷宗[/b]\n\n当前分类下暂无任务。"
	if _track_btn != null: _track_btn.disabled = true
	if _dismiss_btn != null: _dismiss_btn.visible = false


func _track_selected() -> void:
	if _selected_qid == &"": return
	if QuestManager.get_status(_selected_qid) != QuestDef.Status.IN_PROGRESS: return
	_tracked_qid = _selected_qid
	_show_selected()


func _untrack() -> void:
	_tracked_qid = &""
	_refresh()


func _note_text(q: QuestDef, status: int) -> String:
	if status == QuestDef.Status.IN_PROGRESS and q.quest_id == _tracked_qid:
		return "「当前正在追踪此任务。」"
	if status == QuestDef.Status.IN_PROGRESS: return "可点击下方按钮设为追踪。"
	if status == QuestDef.Status.COMPLETED: return "此卷宗已归档。"
	if status == QuestDef.Status.FAILED: return "此任务已经失败。"
	return "尚未正式接取。"


func _preview_text(q: QuestDef, status: int) -> String:
	var desc: String = q.get_description(status).strip_edges()
	if desc.length() > 22: return desc.substr(0, 22) + "…"
	return desc


func _trigger_text(q: QuestDef) -> String:
	if q.completion_triggers.is_empty(): return "暂无明确条件"
	var lines: Array[String] = []
	for t in q.completion_triggers: lines.append("- %s" % t)
	return "\n".join(lines)


func _reward_text(q: QuestDef) -> String:
	var lines: Array[String] = []
	if q.reward_gold > 0: lines.append("金钱 +%d" % q.reward_gold)
	if q.reward_exp > 0: lines.append("经验 +%d" % q.reward_exp)
	for entry in q.reward_items:
		lines.append("物品 × %d" % int(entry.get("count", 1)))
	return "\n".join(lines) if not lines.is_empty() else "无额外奖励"


func _extract_chapter(qid: StringName) -> String:
	var s: String = String(qid)
	for ch_key in CHAPTER_NAMES:
		if s.begins_with("q_" + ch_key + "_"): return ch_key
	return ""


func _kind_text(q: QuestDef) -> String:
	return "主线" if q.kind == QuestDef.Kind.MAIN else "支线"


func _status_text(status: int) -> String:
	match status:
		QuestDef.Status.NOT_STARTED: return "未开始"
		QuestDef.Status.IN_PROGRESS: return "进行中"
		QuestDef.Status.COMPLETED: return "已完成"
		QuestDef.Status.FAILED: return "已失败"
		_: return "未知"


func _status_color(status: int) -> Color:
	match status:
		QuestDef.Status.IN_PROGRESS: return UI_THEME.JADE
		QuestDef.Status.COMPLETED: return UI_THEME.BLUE_STEEL
		QuestDef.Status.FAILED: return UI_THEME.CRIMSON
		_: return UI_THEME.GOLD


func _try_load(name: String) -> Texture2D:
	if ResourceLoader.exists(ART_DIR + name): return load(ART_DIR + name)
	return null


func _apply_btn_textures(btn: Button, base_name: String) -> void:
	var t_n: Texture2D = _try_load(base_name + "_normal.png")
	if t_n == null: return
	btn.flat = true
	btn.text = ""
	btn.custom_minimum_size = Vector2(t_n.get_width(), t_n.get_height())
	btn.add_theme_stylebox_override("normal", _tex_stylebox(t_n))
	var t_h: Texture2D = _try_load(base_name + "_hover.png")
	if t_h != null: btn.add_theme_stylebox_override("hover", _tex_stylebox(t_h))
	var t_p: Texture2D = _try_load(base_name + "_pressed.png")
	if t_p != null: btn.add_theme_stylebox_override("pressed", _tex_stylebox(t_p))
	var lbl: Label = Label.new()
	lbl.text = btn.tooltip_text if btn.tooltip_text != "" else ""
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.98))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.anchors_preset = Control.PRESET_FULL_RECT
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)


func _tex_stylebox(tex: Texture2D) -> StyleBoxTexture:
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = tex
	return sb


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
