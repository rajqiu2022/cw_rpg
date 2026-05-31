@tool
extends Control

## 单个任务的详情编辑面板。
##
## 可编辑字段：
##   quest_id / title / kind / desc_* / completion_triggers / rewards
## 信号：
##   data_changed — 任意字段被修改
##   save_requested — 用户点击保存
##   delete_requested — 用户点击删除

signal data_changed
signal save_requested
signal delete_requested

# 当前编辑的任务
var _quest_id: StringName = &""
var _quest_path: String = ""

# UI 节点引用
var _id_edit: LineEdit
var _title_edit: LineEdit
var _kind_option: OptionButton
var _desc_edits: Dictionary = {}  # "not_started" | "in_progress" | "completed" → TextEdit
var _triggers_list: ItemList
var _triggers_edit: LineEdit
var _gold_edit: SpinBox
var _exp_edit: SpinBox
var _reward_items_list: ItemList
var _reward_item_id_edit: LineEdit
var _reward_item_count_edit: SpinBox

# 临时编辑数据
var _triggers: Array[String] = []
var _reward_items: Array[Dictionary] = []


func _ready() -> void:
	_build_ui()
	clear()


func _build_ui() -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	# ── 头部：标题 + 操作按钮 ──
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var header_label: Label = Label.new()
	header_label.text = "📝 任务详情"
	header_label.add_theme_font_size_override("font_size", 18)
	header_label.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(header_label)

	var delete_btn: Button = Button.new()
	delete_btn.text = "🗑️ 删除任务"
	delete_btn.pressed.connect(func(): emit_signal("delete_requested"))
	header.add_child(delete_btn)

	var save_btn: Button = Button.new()
	save_btn.text = "💾 保存"
	save_btn.pressed.connect(func(): emit_signal("save_requested"))
	header.add_child(save_btn)

	# ── 基本信息区 ──
	vbox.add_child(_make_section_label("基本信息"))

	var info_grid: GridContainer = GridContainer.new()
	info_grid.columns = 2
	info_grid.add_theme_constant_override("h_separation", 12)
	info_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(info_grid)

	# quest_id
	info_grid.add_child(_make_field_label("quest_id"))
	_id_edit = LineEdit.new()
	_id_edit.placeholder_text = "如 q_ch1_main_01_thug"
	_id_edit.text_changed.connect(_emit_changed)
	info_grid.add_child(_id_edit)

	# title
	info_grid.add_child(_make_field_label("标题"))
	_title_edit = LineEdit.new()
	_title_edit.placeholder_text = "任务标题"
	_title_edit.text_changed.connect(_emit_changed)
	info_grid.add_child(_title_edit)

	# kind
	info_grid.add_child(_make_field_label("类型"))
	_kind_option = OptionButton.new()
	_kind_option.add_item("主线 (MAIN)")
	_kind_option.add_item("支线 (SIDE)")
	_kind_option.item_selected.connect(_emit_changed)
	info_grid.add_child(_kind_option)

	# ── 描述区 ──
	vbox.add_child(_make_section_label("任务描述"))

	for key in ["not_started", "in_progress", "completed"]:
		var label_text := ""
		match key:
			"not_started": label_text = "未开始时显示"
			"in_progress": label_text = "进行中显示"
			"completed": label_text = "完成后显示"

		vbox.add_child(_make_field_label(label_text))
		var te: TextEdit = TextEdit.new()
		te.custom_minimum_size = Vector2(0, 50)
		te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		te.text_changed.connect(_emit_changed)
		_desc_edits[key] = te
		vbox.add_child(te)

	# ── 完成条件区 ──
	vbox.add_child(_make_section_label("完成条件 (completion_triggers)"))

	var trig_toolbar: HBoxContainer = HBoxContainer.new()
	trig_toolbar.add_theme_constant_override("separation", 6)
	vbox.add_child(trig_toolbar)

	_triggers_edit = LineEdit.new()
	_triggers_edit.placeholder_text = "如 enemy_defeated:thug_lone"
	_triggers_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	trig_toolbar.add_child(_triggers_edit)

	var add_trig_btn: Button = Button.new()
	add_trig_btn.text = "+ 添加"
	add_trig_btn.pressed.connect(_add_trigger)
	trig_toolbar.add_child(add_trig_btn)

	var del_trig_btn: Button = Button.new()
	del_trig_btn.text = "- 删除选中"
	del_trig_btn.pressed.connect(_remove_trigger)
	trig_toolbar.add_child(del_trig_btn)

	_triggers_list = ItemList.new()
	_triggers_list.custom_minimum_size = Vector2(0, 72)
	_triggers_list.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.add_child(_triggers_list)

	# ── 奖励区 ──
	vbox.add_child(_make_section_label("奖励"))

	var reward_grid: GridContainer = GridContainer.new()
	reward_grid.columns = 4
	reward_grid.add_theme_constant_override("h_separation", 12)
	reward_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(reward_grid)

	reward_grid.add_child(_make_field_label("金币"))
	_gold_edit = SpinBox.new()
	_gold_edit.min_value = 0
	_gold_edit.max_value = 99999
	_gold_edit.value_changed.connect(func(_v): _emit_changed())
	reward_grid.add_child(_gold_edit)

	reward_grid.add_child(_make_field_label("经验"))
	_exp_edit = SpinBox.new()
	_exp_edit.min_value = 0
	_exp_edit.max_value = 99999
	_exp_edit.value_changed.connect(func(_v): _emit_changed())
	reward_grid.add_child(_exp_edit)

	# 物品奖励
	vbox.add_child(_make_field_label("物品奖励"))

	var item_toolbar: HBoxContainer = HBoxContainer.new()
	item_toolbar.add_theme_constant_override("separation", 6)
	vbox.add_child(item_toolbar)

	_reward_item_id_edit = LineEdit.new()
	_reward_item_id_edit.placeholder_text = "item_id"
	_reward_item_id_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	item_toolbar.add_child(_reward_item_id_edit)

	_reward_item_count_edit = SpinBox.new()
	_reward_item_count_edit.min_value = 1
	_reward_item_count_edit.max_value = 99
	_reward_item_count_edit.value = 1
	_reward_item_count_edit.custom_minimum_size = Vector2(60, 0)
	item_toolbar.add_child(_reward_item_count_edit)

	var add_item_btn: Button = Button.new()
	add_item_btn.text = "+ 添加物品"
	add_item_btn.pressed.connect(_add_reward_item)
	item_toolbar.add_child(add_item_btn)

	var del_item_btn: Button = Button.new()
	del_item_btn.text = "- 删除选中"
	del_item_btn.pressed.connect(_remove_reward_item)
	item_toolbar.add_child(del_item_btn)

	_reward_items_list = ItemList.new()
	_reward_items_list.custom_minimum_size = Vector2(0, 60)
	_reward_items_list.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox.add_child(_reward_items_list)


# ── 公开 API ──

func load_quest(qid: StringName, path: String, def: QuestDef) -> void:
	_quest_id = qid
	_quest_path = path

	_id_edit.text = String(qid)
	_title_edit.text = def.title
	_kind_option.select(0 if def.kind == QuestDef.Kind.MAIN else 1)

	_desc_edits["not_started"].text = def.desc_not_started
	_desc_edits["in_progress"].text = def.desc_in_progress
	_desc_edits["completed"].text = def.desc_completed

	_triggers = def.completion_triggers.duplicate()
	_refresh_triggers_list()

	_gold_edit.value = def.reward_gold
	_exp_edit.value = def.reward_exp

	_reward_items = def.reward_items.duplicate()
	_refresh_reward_items_list()


func apply_to(def: QuestDef) -> void:
	def.quest_id = StringName(_id_edit.text.strip_edges())
	def.title = _title_edit.text.strip_edges()
	def.kind = QuestDef.Kind.MAIN if _kind_option.selected == 0 else QuestDef.Kind.SIDE
	def.desc_not_started = _desc_edits["not_started"].text
	def.desc_in_progress = _desc_edits["in_progress"].text
	def.desc_completed = _desc_edits["completed"].text
	def.completion_triggers = _triggers.duplicate()
	def.reward_gold = int(_gold_edit.value)
	def.reward_exp = int(_exp_edit.value)
	def.reward_items = _reward_items.duplicate()


func get_edited_title() -> String:
	return _title_edit.text.strip_edges()


func clear() -> void:
	_quest_id = &""
	_quest_path = ""
	_id_edit.text = ""
	_title_edit.text = ""
	_kind_option.select(0)
	_desc_edits["not_started"].text = ""
	_desc_edits["in_progress"].text = ""
	_desc_edits["completed"].text = ""
	_triggers.clear()
	_refresh_triggers_list()
	_gold_edit.value = 0
	_exp_edit.value = 0
	_reward_items.clear()
	_refresh_reward_items_list()


# ── 内部辅助 ──

func _make_section_label(text: String) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	return lbl


func _make_field_label(text: String) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	return lbl


func _emit_changed(_arg = null) -> void:
	emit_signal("data_changed")


func _refresh_triggers_list() -> void:
	_triggers_list.clear()
	for t in _triggers:
		_triggers_list.add_item(t)


func _add_trigger() -> void:
	var text := _triggers_edit.text.strip_edges()
	if text == "":
		return
	if not text in _triggers:
		_triggers.append(text)
		_refresh_triggers_list()
		_emit_changed()
	_triggers_edit.text = ""


func _remove_trigger() -> void:
	var selected := _triggers_list.get_selected_items()
	if selected.is_empty():
		return
	var idx: int = selected[0]
	if idx >= 0 and idx < _triggers.size():
		_triggers.remove_at(idx)
		_refresh_triggers_list()
		_emit_changed()


func _refresh_reward_items_list() -> void:
	_reward_items_list.clear()
	for entry in _reward_items:
		var iid: String = String(entry.get("item_id", entry.get("id", "?")))
		var count: int = int(entry.get("count", 1))
		_reward_items_list.add_item("%s × %d" % [iid, count])


func _add_reward_item() -> void:
	var iid := _reward_item_id_edit.text.strip_edges()
	if iid == "":
		return
	var count := int(_reward_item_count_edit.value)
	_reward_items.append({"item_id": iid, "count": count})
	_refresh_reward_items_list()
	_emit_changed()
	_reward_item_id_edit.text = ""


func _remove_reward_item() -> void:
	var selected := _reward_items_list.get_selected_items()
	if selected.is_empty():
		return
	var idx: int = selected[0]
	if idx >= 0 and idx < _reward_items.size():
		_reward_items.remove_at(idx)
		_refresh_reward_items_list()
		_emit_changed()
