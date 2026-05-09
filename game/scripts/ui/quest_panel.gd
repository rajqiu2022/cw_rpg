extends Control

signal closed

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")

@onready var quest_list: VBoxContainer = %QuestList
@onready var detail: RichTextLabel = %Detail
@onready var close_btn: Button = %CloseBtn

var _filter_mode := "all"
var _selected_qid: StringName = &""
var _filter_row: HBoxContainer = null
var _summary_label: Label = null
var _track_btn: Button = null
var _tracked_qid: StringName = &""


func _ready() -> void:
	_build_formal_layout()
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


func _build_formal_layout() -> void:
	var body: VBoxContainer = get_node_or_null("Panel/Body") as VBoxContainer
	if body == null:
		return
	if body.get_node_or_null("QuestToolbar") == null:
		var toolbar := HBoxContainer.new()
		toolbar.name = "QuestToolbar"
		toolbar.add_theme_constant_override("separation", 10)
		body.add_child(toolbar)
		body.move_child(toolbar, 1)
		_filter_row = toolbar
		_add_filter_button("全部", "all")
		_add_filter_button("进行中", "active")
		_add_filter_button("主线", "main")
		_add_filter_button("已完成", "done")
		_summary_label = Label.new()
		_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		UI_THEME.style_label(_summary_label, 16, UI_THEME.MUTED, false)
		toolbar.add_child(_summary_label)
	else:
		_filter_row = body.get_node_or_null("QuestToolbar") as HBoxContainer

	var content: HBoxContainer = get_node_or_null("Panel/Body/Content") as HBoxContainer
	if content != null:
		content.add_theme_constant_override("separation", 18)
	var list_scroll: ScrollContainer = get_node_or_null("Panel/Body/Content/ListScroll") as ScrollContainer
	if list_scroll != null:
		list_scroll.custom_minimum_size = Vector2(430, 0)
	var detail_parent: Control = detail.get_parent() as Control
	if detail_parent != null:
		detail_parent.custom_minimum_size = Vector2(610, 0)
	if body.get_node_or_null("QuestActions") == null:
		var actions := HBoxContainer.new()
		actions.name = "QuestActions"
		actions.alignment = BoxContainer.ALIGNMENT_CENTER
		actions.add_theme_constant_override("separation", 12)
		body.add_child(actions)
		_track_btn = Button.new()
		_track_btn.text = "追踪当前任务"
		_track_btn.custom_minimum_size = Vector2(180, 42)
		UI_THEME.style_button(_track_btn, 16, UI_THEME.JADE)
		_track_btn.pressed.connect(_track_selected)
		actions.add_child(_track_btn)
	else:
		var actions_existing: HBoxContainer = body.get_node_or_null("QuestActions") as HBoxContainer
		if actions_existing != null and actions_existing.get_child_count() > 0:
			_track_btn = actions_existing.get_child(0) as Button


func _add_filter_button(label: String, mode: String) -> void:
	if _filter_row == null:
		return
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(96, 38)
	UI_THEME.style_button(btn, 15, UI_THEME.BLUE_STEEL)
	btn.pressed.connect(func(): _set_filter(mode))
	_filter_row.add_child(btn)


func _set_filter(mode: String) -> void:
	_filter_mode = mode
	_refresh()


func _apply_visual_style() -> void:
	var dim: ColorRect = get_node_or_null("Dim") as ColorRect
	if dim != null:
		dim.color = Color(0.005, 0.010, 0.016, 0.58)
	var panel: PanelContainer = get_node_or_null("Panel") as PanelContainer
	if panel != null:
		panel.offset_left = -640
		panel.offset_top = -350
		panel.offset_right = 640
		panel.offset_bottom = 350
		panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.040, 0.060, 0.075, 0.98), UI_THEME.BLUE_STEEL, 18, 3))
	var title: Label = get_node_or_null("Panel/Body/Header/Title") as Label
	if title != null:
		title.text = "任务卷宗"
		UI_THEME.style_label(title, 34, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_button(close_btn, 16, UI_THEME.CRIMSON)
	UI_THEME.style_rich_text(detail, 18)


func _refresh() -> void:
	for child in quest_list.get_children():
		child.queue_free()
	var visible_qids: Array[StringName] = []
	var all_keys: Array = QuestManager.states.keys()
	for key in all_keys:
		var qid := StringName(key)
		var q: QuestDef = QuestManager.load_def(qid)
		if q == null:
			continue
		var status := QuestManager.get_status(qid)
		if not _quest_visible(q, status):
			continue
		visible_qids.append(qid)
		quest_list.add_child(_make_quest_row(qid, q, status))
	_update_summary()
	if visible_qids.is_empty():
		_show_empty()
		return
	if _selected_qid == &"" or not visible_qids.has(_selected_qid):
		_selected_qid = visible_qids[0]
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
	var row_panel := PanelContainer.new()
	row_panel.custom_minimum_size = Vector2(0, 96)
	var border := _status_color(status)
	if qid == _selected_qid:
		border = UI_THEME.GOLD_LIGHT
	row_panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.038, 0.060, 0.072, 0.90), border, 12, 1))
	var btn := Button.new()
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

	detail.text = "[b]%s[/b]\n[color=#9fd3d0]%s · %s[/color]\n\n[b]当前记述[/b]\n%s\n\n[b]完成条件[/b]\n%s\n\n[b]奖励[/b]\n%s\n\n[b]卷宗备注[/b]\n%s" % [
		q.title,
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


func _update_summary() -> void:
	if _summary_label == null:
		return
	var active := 0
	var done := 0
	var total := 0
	for key in QuestManager.states.keys():
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


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
