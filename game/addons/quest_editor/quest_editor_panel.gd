@tool
extends Control

## Quest Editor 主面板。
##
## 功能：
##   - 左侧列表：加载 game/data/quests/*.tres，按章节分组、按主线/支线筛选
##   - 右侧详情：选中任务的可编辑字段
##   - 底部操作栏：新建 / 保存 / 删除 / 刷新

const QUESTS_DIR := "res://data/quests/"
const QUEST_DEF_SCRIPT := "res://scripts/domain/quest_def.gd"

var _quest_list: ItemList
var _detail_panel: Control  ## QuestDetailPanel 实例
var _status_label: Label
var _filter_option: OptionButton
var _all_quests: Array[Dictionary] = []  ## [{id, path, def}]
var _selected_index: int = -1
var _dirty: bool = false


func _ready() -> void:
	_build_ui()
	_refresh_list()


func _build_ui() -> void:
	custom_minimum_size = Vector2(900, 500)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL

	# 主水平分割
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.size_flags_vertical = SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 4)
	add_child(hbox)

	# --- 左侧面板：列表 + 筛选 + 按钮 ---
	var left: VBoxContainer = VBoxContainer.new()
	left.custom_minimum_size = Vector2(320, 0)
	left.size_flags_vertical = SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	hbox.add_child(left)

	# 筛选工具栏
	var toolbar: HBoxContainer = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	left.add_child(toolbar)

	var filter_label: Label = Label.new()
	filter_label.text = "筛选："
	toolbar.add_child(filter_label)

	_filter_option = OptionButton.new()
	_filter_option.add_item("全部")
	_filter_option.add_item("主线")
	_filter_option.add_item("支线")
	_filter_option.item_selected.connect(_on_filter_changed)
	toolbar.add_child(_filter_option)

	# 新建按钮
	var new_btn: Button = Button.new()
	new_btn.text = "➕ 新建任务"
	new_btn.pressed.connect(_new_quest)
	toolbar.add_child(new_btn)

	# 任务列表
	_quest_list = ItemList.new()
	_quest_list.size_flags_horizontal = SIZE_EXPAND_FILL
	_quest_list.size_flags_vertical = SIZE_EXPAND_FILL
	_quest_list.allow_reselect = true
	_quest_list.item_selected.connect(_on_quest_selected)
	left.add_child(_quest_list)

	# 状态栏
	_status_label = Label.new()
	_status_label.text = "就绪"
	_status_label.add_theme_font_size_override("font_size", 12)
	left.add_child(_status_label)

	# 左侧底部按钮
	var left_btns: HBoxContainer = HBoxContainer.new()
	left_btns.add_theme_constant_override("separation", 8)
	left.add_child(left_btns)

	var refresh_btn: Button = Button.new()
	refresh_btn.text = "🔄 刷新列表"
	refresh_btn.pressed.connect(_refresh_list)
	left_btns.add_child(refresh_btn)

	var open_folder_btn: Button = Button.new()
	open_folder_btn.text = "📂 打开目录"
	open_folder_btn.pressed.connect(_open_quests_folder)
	left_btns.add_child(open_folder_btn)

	# --- 右侧：详情编辑面板 ---
	_detail_panel = preload("res://addons/quest_editor/quest_detail_panel.tscn").instantiate()
	_detail_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	_detail_panel.size_flags_vertical = SIZE_EXPAND_FILL
	_detail_panel.connect("data_changed", _on_data_changed)
	_detail_panel.connect("save_requested", _on_save_requested)
	_detail_panel.connect("delete_requested", _on_delete_requested)
	hbox.add_child(_detail_panel)


func _refresh_list() -> void:
	_save_if_dirty()
	_quest_list.clear()
	_all_quests.clear()
	_selected_index = -1

	var dir := DirAccess.open(QUESTS_DIR)
	if dir == null:
		_status_label.text = "❌ 无法打开目录: %s" % QUESTS_DIR
		return

	dir.list_dir_begin()
	var fname := dir.get_next()
	var found: Array[Dictionary] = []
	while fname != "":
		if fname.ends_with(".tres") and not dir.current_is_dir():
			var path := QUESTS_DIR + fname
			var res := load(path)
			if res is QuestDef:
				found.append({"id": res.quest_id, "path": path, "def": res})
		fname = dir.get_next()

	# 按 quest_id 排序
	found.sort_custom(func(a, b): return String(a.id) < String(b.id))

	var filter := _filter_option.selected
	var idx := 0
	var last_chapter := ""
	for entry in found:
		var def: QuestDef = entry["def"]
		var qid: String = String(entry["id"])

		# 筛选
		if filter == 1 and def.kind != QuestDef.Kind.MAIN:
			continue
		if filter == 2 and def.kind != QuestDef.Kind.SIDE:
			continue

		# 章节分组标题
		var chapter := _extract_chapter(qid)
		if chapter != last_chapter and chapter != "":
			_quest_list.add_item("—— %s ——" % chapter)
			_quest_list.set_item_disabled(idx, true)
			_quest_list.set_item_custom_fg_color(idx, Color(0.5, 0.7, 0.9))
			idx += 1
			last_chapter = chapter

		var kind_icon := "🔴" if def.kind == QuestDef.Kind.MAIN else "🟡"
		var status_text := _status_text(def)
		var text := "%s [%s] %s" % [kind_icon, status_text, def.title]
		_quest_list.add_item(text)
		_quest_list.set_item_metadata(idx, _all_quests.size())
		_all_quests.append(entry)
		idx += 1

	var total := _all_quests.size()
	var main_count := 0
	var side_count := 0
	for e in _all_quests:
		if e["def"].kind == QuestDef.Kind.MAIN:
			main_count += 1
		else:
			side_count += 1
	_status_label.text = "共 %d 个任务（主线 %d · 支线 %d）" % [total, main_count, side_count]

	if total > 0:
		_quest_list.select(0)
		_on_quest_selected(0)


func _on_filter_changed(_idx: int) -> void:
	_refresh_list()


func _on_quest_selected(idx: int) -> void:
	var meta = _quest_list.get_item_metadata(idx)
	if meta == null:
		return
	var data_idx: int = int(meta)
	if data_idx < 0 or data_idx >= _all_quests.size():
		return
	_save_if_dirty()
	_selected_index = data_idx
	var entry := _all_quests[data_idx]
	_detail_panel.load_quest(entry["id"], entry["path"], entry["def"])
	_dirty = false


func _on_data_changed() -> void:
	_dirty = true
	# 更新列表中的标题
	if _selected_index >= 0 and _selected_index < _all_quests.size():
		var title := _detail_panel.get_edited_title()
		if title != "":
			var def: QuestDef = _all_quests[_selected_index]["def"]
			_status_label.text = "✏️ 已修改: %s" % title


func _on_save_requested() -> void:
	if _selected_index < 0:
		return
	var entry: Dictionary = _all_quests[_selected_index]
	var def: QuestDef = entry["def"]
	var path: String = entry["path"]

	# 将编辑面板的数据写回 QuestDef
	_detail_panel.apply_to(def)

	var err := ResourceSaver.save(def, path)
	if err == OK:
		_dirty = false
		_status_label.text = "✅ 已保存: %s" % def.title
		_refresh_list()
	else:
		_status_label.text = "❌ 保存失败 (error %d): %s" % [err, path]
		push_error("[QuestEditor] save failed: %s (err=%d)" % [path, err])


func _on_delete_requested() -> void:
	if _selected_index < 0:
		return
	var entry: Dictionary = _all_quests[_selected_index]
	var path: String = entry["path"]

	# 确认对话框使用原生 ConfirmationDialog
	var confirm: ConfirmationDialog = ConfirmationDialog.new()
	confirm.title = "删除任务"
	confirm.dialog_text = "确定要删除任务吗？\n\n%s\n\n此操作不可撤销，.tres 文件将被删除。" % entry["id"]
	confirm.confirmed.connect(func():
		var err := DirAccess.remove_absolute(path)
		if err == OK:
			_status_label.text = "🗑️ 已删除: %s" % path
			_detail_panel.clear()
			_dirty = false
			_selected_index = -1
			_refresh_list()
		else:
			_status_label.text = "❌ 删除失败 (error %d)" % err
	)
	add_child(confirm)
	confirm.popup_centered()


func _save_if_dirty() -> void:
	if _dirty and _selected_index >= 0:
		_status_label.text = "⚠️ 有未保存的修改，切换前请先保存"


func _open_quests_folder() -> void:
	OS.shell_open(ProjectSettings.globalize_path(QUESTS_DIR))


func _new_quest() -> void:
	_save_if_dirty()

	# 弹出对话框填写 quest_id
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "新建任务"
	dialog.ok_button_text = "创建"

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	dialog.add_child(vbox)

	var label: Label = Label.new()
	label.text = "输入 quest_id（如 q_ch2_main_01_investigate）："
	vbox.add_child(label)

	var id_edit: LineEdit = LineEdit.new()
	id_edit.placeholder_text = "q_chX_main_01_xxx"
	vbox.add_child(id_edit)

	var kind_opt: OptionButton = OptionButton.new()
	kind_opt.add_item("主线 (MAIN)")
	kind_opt.add_item("支线 (SIDE)")
	vbox.add_child(kind_opt)

	dialog.register_text_enter(id_edit)
	dialog.confirmed.connect(func():
		var qid := id_edit.text.strip_edges()
		if qid == "":
			_status_label.text = "❌ quest_id 不能为空"
			return

		# 检查是否已存在
		for entry in _all_quests:
			if String(entry["id"]) == qid:
				_status_label.text = "❌ quest_id 已存在: %s" % qid
				return

		var path := QUESTS_DIR + qid + ".tres"
		var def: QuestDef = QuestDef.new()
		def.quest_id = StringName(qid)
		def.title = "新任务"
		def.kind = QuestDef.Kind.MAIN if kind_opt.selected == 0 else QuestDef.Kind.SIDE
		def.desc_in_progress = "任务进行中…"

		var err := ResourceSaver.save(def, path)
		if err == OK:
			_status_label.text = "✅ 已创建: %s" % qid
			_refresh_list()
			# 选中新建的任务
			for i in range(_all_quests.size()):
				if String(_all_quests[i]["id"]) == qid:
					_quest_list.select(i)
					_on_quest_selected(i)
					break
		else:
			_status_label.text = "❌ 创建失败 (error %d)" % err
	)

	add_child(dialog)
	dialog.popup_centered(Vector2i(500, 180))
	id_edit.grab_focus()


func _extract_chapter(qid: String) -> String:
	if qid.begins_with("q_ch1"):
		return "第一章 · 林西村下山"
	if qid.begins_with("q_ch2"):
		return "第二章 · 竹尾风波"
	if qid.begins_with("q_ch3"):
		return "第三章 · 入派抉择"
	if qid.begins_with("q_ch4"):
		return "第四章 · 洛阳奇遇"
	if qid.begins_with("q_ch5"):
		return "第五章 · 古月峰之围"
	if qid.begins_with("q_ch6"):
		return "第六章 · 师承之谜"
	if qid.begins_with("q_ch7"):
		return "第七章 · 烈云盟真相"
	if qid.begins_with("q_ch8"):
		return "第八章 · 茗雾决战"
	return ""


func _status_text(def: QuestDef) -> String:
	# 编辑器环境下无法访问运行时 QuestManager.states，显示 quest_id 预览
	var kind := "主线" if def.kind == QuestDef.Kind.MAIN else "支线"
	var trigger_count := def.completion_triggers.size()
	var has_reward := def.reward_gold > 0 or def.reward_exp > 0 or not def.reward_items.is_empty()
	var reward_mark := "💰" if has_reward else "  "
	return "%s · %d条件 %s" % [kind, trigger_count, reward_mark]
