extends CanvasLayer

## Debug-build-only global GM console.
## The launcher survives scene changes because this script is an autoload.

const LAYER := 220
const PANEL_SIZE := Vector2(700, 880)
const LAUNCHER_SIZE := Vector2(72, 46)
const QUALITY_NAMES := ["白", "绿", "蓝", "紫", "橙"]
const EQUIPMENT_SLOT_NAMES := ["武器", "头盔", "衣甲", "护手", "鞋子", "饰品"]
const MARTIAL_STYLE_NAMES := {
	&"sword": "剑法",
	&"blade": "刀法",
	&"staff": "棍法",
	&"palm": "掌法",
	&"hidden": "暗器",
	&"dagger": "短兵",
}

var _launcher: Button = null
var _panel: PanelContainer = null
var _status: Label = null
var _damage_label: RichTextLabel = null
var _last_damage_breakdown: DamageBreakdown = null
var _item_search: LineEdit = null
var _item_select: OptionButton = null
var _item_count: SpinBox = null
var _move_select: OptionButton = null
var _mind_select: OptionButton = null
var _all_items: Array[Dictionary] = []
var _all_moves: Array[Dictionary] = []
var _all_minds: Array[Dictionary] = []
var _press_origin := Vector2.ZERO
var _launcher_origin := Vector2.ZERO
var _drag_candidate := false
var _dragged := false


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.is_debug_build() or _is_automated_capture():
		return
	_scan_resources()
	_build_ui()
	EventBus.damage_calculated.connect(record_damage_breakdown)
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _is_automated_capture() -> bool:
	for argument in OS.get_cmdline_user_args():
		if argument == "show_gm=true":
			return false
	for argument in OS.get_cmdline_args():
		if "capture_ui.gd" in argument:
			return true
	return false


func _scan_resources() -> void:
	_all_items.clear()
	_all_moves.clear()
	_all_minds.clear()
	for directory in ["res://data/items", "res://data/equipment"]:
		for path in _resource_paths(directory):
			var item := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as Item
			if item == null:
				continue
			var label := "%s  [%s]" % [item.display_name, item.item_id]
			if item is Equipment:
				var equipment := item as Equipment
				var quality := String(QUALITY_NAMES[clampi(equipment.quality, 0, QUALITY_NAMES.size() - 1)])
				var slot_name := String(EQUIPMENT_SLOT_NAMES[clampi(equipment.slot, 0, EQUIPMENT_SLOT_NAMES.size() - 1)])
				var style_name := String(MARTIAL_STYLE_NAMES.get(equipment.get_martial_style(), ""))
				var style_suffix := "·%s" % style_name if not style_name.is_empty() else ""
				label = "【%s·%s%s】%s  [%s]" % [quality, slot_name, style_suffix, item.display_name, item.item_id]
			_all_items.append({
				"id": item.item_id,
				"label": label,
			})
	for path in _resource_paths("res://data/skills"):
		var skill := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as Skill
		if skill == null or skill.skill_id in [&"basic_attack", &"defend"]:
			continue
		var quality: String = String(QUALITY_NAMES[clampi(skill.quality, 0, QUALITY_NAMES.size() - 1)])
		var entry := {
			"id": skill.skill_id,
			"label": "%s·%s  [%s]" % [quality, skill.display_name, skill.skill_id],
		}
		if skill.is_internal_art:
			_all_minds.append(entry)
		else:
			_all_moves.append(entry)
	_sort_entries(_all_items)
	_sort_entries(_all_moves)
	_sort_entries(_all_minds)


func _resource_paths(directory_path: String) -> Array[String]:
	var result: Array[String] = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return result
	for file_name in directory.get_files():
		if file_name.ends_with(".tres"):
			result.append("%s/%s" % [directory_path, file_name])
	result.sort()
	return result


func _sort_entries(entries: Array[Dictionary]) -> void:
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("label", "")).naturalnocasecmp_to(String(b.get("label", ""))) < 0
	)


func _build_ui() -> void:
	_launcher = Button.new()
	_launcher.name = "GMFloatingButton"
	_launcher.text = "GM"
	_launcher.tooltip_text = "拖动调整位置；单击打开GM测试面板（F12）"
	_launcher.size = LAUNCHER_SIZE
	_launcher.position = Vector2(get_viewport().get_visible_rect().size.x - 94.0, 150.0)
	_launcher.mouse_default_cursor_shape = Control.CURSOR_MOVE
	_apply_button_style(_launcher, Color(0.52, 0.19, 0.12, 0.96), Color(0.82, 0.42, 0.22, 1.0))
	_launcher.gui_input.connect(_on_launcher_gui_input)
	add_child(_launcher)

	_panel = PanelContainer.new()
	_panel.name = "GMPanel"
	_panel.visible = false
	_panel.size = PANEL_SIZE
	_panel.custom_minimum_size = PANEL_SIZE
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(_panel)
	_center_panel()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var content := VBoxContainer.new()
	content.custom_minimum_size.x = PANEL_SIZE.x - 70.0
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = "GM测试工具"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.97, 0.80, 0.42, 1.0))
	header.add_child(title)
	var close := Button.new()
	close.text = "关闭"
	close.pressed.connect(func(): _panel.visible = false)
	_apply_button_style(close, Color(0.15, 0.20, 0.23, 1.0), Color(0.26, 0.43, 0.48, 1.0))
	header.add_child(close)
	var refresh := Button.new()
	refresh.text = "刷新数据"
	refresh.tooltip_text = "重新读取所有道具、装备、武功和心法资源"
	refresh.pressed.connect(_refresh_resource_options)
	_apply_button_style(refresh, Color(0.12, 0.34, 0.30, 1.0), Color(0.18, 0.55, 0.46, 1.0))
	header.add_child(refresh)

	content.add_child(_divider())
	content.add_child(_section_label("角色资源"))
	content.add_child(_make_amount_row("增加金钱", 100, 1, 999999, _add_gold))
	content.add_child(_make_amount_row("增加经验", 100, 1, 999999, _add_exp))
	content.add_child(_make_amount_row("增加历练", 100, 1, 999999, _add_training))
	content.add_child(_make_amount_row("增加声望", 10, 1, 999999, _add_reputation))

	content.add_child(_divider())
	content.add_child(_section_label("发放道具 / 装备"))
	_item_search = LineEdit.new()
	_item_search.placeholder_text = "输入名称或ID筛选"
	_item_search.text_changed.connect(_refresh_item_options)
	content.add_child(_item_search)
	var item_row := HBoxContainer.new()
	item_row.add_theme_constant_override("separation", 10)
	_item_select = OptionButton.new()
	_item_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_row.add_child(_item_select)
	_item_count = SpinBox.new()
	_item_count.min_value = 1
	_item_count.max_value = 99
	_item_count.value = 1
	_item_count.custom_minimum_size.x = 90
	item_row.add_child(_item_count)
	var give_item := Button.new()
	give_item.text = "发放"
	give_item.pressed.connect(_give_selected_item)
	_apply_button_style(give_item, Color(0.12, 0.34, 0.30, 1.0), Color(0.18, 0.55, 0.46, 1.0))
	item_row.add_child(give_item)
	content.add_child(item_row)
	_refresh_item_options("")

	content.add_child(_divider())
	content.add_child(_section_label("学习武功"))
	_move_select = _make_resource_select(_all_moves)
	content.add_child(_make_learning_row(_move_select, "学习武功"))
	content.add_child(_section_label("学习心法"))
	_mind_select = _make_resource_select(_all_minds)
	content.add_child(_make_learning_row(_mind_select, "学习心法"))

	content.add_child(_divider())
	content.add_child(_section_label("伤害分析（最近一次）"))
	_damage_label = RichTextLabel.new()
	_damage_label.name = "DamageBreakdownLabel"
	_damage_label.bbcode_enabled = false
	_damage_label.fit_content = false
	_damage_label.scroll_active = true
	_damage_label.custom_minimum_size = Vector2(PANEL_SIZE.x - 80.0, 190.0)
	_damage_label.add_theme_font_size_override("normal_font_size", 15)
	_damage_label.add_theme_color_override("default_color", Color(0.84, 0.90, 0.88, 1.0))
	_damage_label.add_theme_constant_override("line_separation", 3)
	content.add_child(_damage_label)
	_refresh_damage_label()

	content.add_child(_divider())
	_status = Label.new()
	_status.text = "仅调试构建启用；所有修改会进入正常存档。"
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 16)
	_status.add_theme_color_override("font_color", Color(0.66, 0.82, 0.82, 1.0))
	content.add_child(_status)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.055, 0.97)
	style.border_color = Color(0.22, 0.66, 0.68, 0.92)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.72)
	style.shadow_size = 16
	return style


func _apply_button_style(button: Button, normal_color: Color, hover_color: Color) -> void:
	button.custom_minimum_size.y = 42
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color(0.94, 0.96, 0.92, 1.0))
	for state in ["normal", "pressed", "hover", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = hover_color if state in ["hover", "focus"] else normal_color.darkened(0.16) if state == "pressed" else normal_color
		style.border_color = Color(0.42, 0.73, 0.74, 0.88)
		style.set_border_width_all(1)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		button.add_theme_stylebox_override(state, style)


func _section_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", Color(0.48, 0.83, 0.83, 1.0))
	return label


func _divider() -> HSeparator:
	var separator := HSeparator.new()
	separator.custom_minimum_size.y = 8
	return separator


func _make_amount_row(label_text: String, initial: int, minimum: int, maximum: int, callback: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 140
	row.add_child(label)
	var amount := SpinBox.new()
	amount.min_value = minimum
	amount.max_value = maximum
	amount.step = 1
	amount.value = initial
	amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(amount)
	var action := Button.new()
	action.text = "增加"
	action.pressed.connect(func(): callback.call(int(amount.value)))
	_apply_button_style(action, Color(0.12, 0.34, 0.30, 1.0), Color(0.18, 0.55, 0.46, 1.0))
	row.add_child(action)
	return row


func _make_resource_select(entries: Array[Dictionary]) -> OptionButton:
	var select := OptionButton.new()
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for entry in entries:
		select.add_item(String(entry.get("label", entry.get("id", ""))))
		select.set_item_metadata(select.item_count - 1, entry.get("id", &""))
	return select


func _replace_resource_select_options(select: OptionButton, entries: Array[Dictionary]) -> void:
	if select == null:
		return
	var previous_id := StringName(String(select.get_item_metadata(select.selected))) if select.selected >= 0 and select.selected < select.item_count else &""
	select.clear()
	for entry in entries:
		select.add_item(String(entry.get("label", entry.get("id", ""))))
		select.set_item_metadata(select.item_count - 1, entry.get("id", &""))
		if StringName(entry.get("id", &"")) == previous_id:
			select.select(select.item_count - 1)
	select.disabled = select.item_count == 0


func _make_learning_row(select: OptionButton, button_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(select)
	var learn := Button.new()
	learn.text = button_text
	learn.pressed.connect(func(): _learn_selected(select))
	_apply_button_style(learn, Color(0.32, 0.20, 0.10, 1.0), Color(0.58, 0.37, 0.14, 1.0))
	row.add_child(learn)
	return row


func _refresh_item_options(filter_text: String) -> void:
	if _item_select == null:
		return
	_item_select.clear()
	var needle := filter_text.strip_edges().to_lower()
	for entry in _all_items:
		var label := String(entry.get("label", ""))
		if not needle.is_empty() and needle not in label.to_lower():
			continue
		_item_select.add_item(label)
		_item_select.set_item_metadata(_item_select.item_count - 1, entry.get("id", &""))
	_item_select.disabled = _item_select.item_count == 0


func _refresh_resource_options() -> void:
	_scan_resources()
	_refresh_item_options(_item_search.text if _item_search != null else "")
	_replace_resource_select_options(_move_select, _all_moves)
	_replace_resource_select_options(_mind_select, _all_minds)
	_set_status("数据已刷新：%d 道具/装备、%d 武功、%d 心法。搜索“掌法”可查看护手。" % [_all_items.size(), _all_moves.size(), _all_minds.size()], true)


func _add_gold(amount: int) -> void:
	GameState.add_gold(amount)
	_set_status("已增加 %d 金钱；当前 %d。" % [amount, GameState.gold], true)


func _add_exp(amount: int) -> void:
	if GameState.player == null:
		_set_status("当前没有可用角色。", false)
		return
	var old_level := GameState.player.level
	GameState.player.gain_exp(amount)
	GameState.player_changed.emit()
	_set_status("已增加 %d 经验；等级 %d → %d。" % [amount, old_level, GameState.player.level], true)


func _add_training(amount: int) -> void:
	GameState.add_training_points(amount)
	_set_status("已增加 %d 历练；可用历练 %d。" % [amount, GameState.training_points_available], true)


func _add_reputation(amount: int) -> void:
	GameState.add_reputation(amount)
	_set_status("已增加 %d 声望；当前 %d（%s）。" % [amount, GameState.reputation, GameState.get_reputation_title()], true)


func _give_selected_item() -> void:
	if _item_select == null or _item_select.selected < 0 or _item_select.item_count == 0:
		_set_status("没有可发放的道具。", false)
		return
	var item_id := StringName(String(_item_select.get_item_metadata(_item_select.selected)))
	var count := int(_item_count.value)
	if Inventory.add_item(item_id, count):
		_set_status("已发放 %s ×%d。" % [_item_select.get_item_text(_item_select.selected), count], true)
	else:
		_set_status("发放失败：背包已满或资源无效。", false)


func _learn_selected(select: OptionButton) -> void:
	if select == null or select.selected < 0 or select.item_count == 0:
		_set_status("没有可学习的武学。", false)
		return
	var skill_id := StringName(String(select.get_item_metadata(select.selected)))
	if skill_id in GameState.player.skills:
		_set_status("已经学会：%s。" % select.get_item_text(select.selected), false)
		return
	if GameState.debug_force_learn_skill(skill_id):
		_set_status("已强制学会：%s。" % select.get_item_text(select.selected), true)
	else:
		_set_status("学习失败：资源无效或非调试构建。", false)


func _set_status(message: String, success: bool) -> void:
	if _status == null:
		return
	_status.text = message
	_status.add_theme_color_override("font_color", Color(0.52, 0.92, 0.70, 1.0) if success else Color(1.0, 0.55, 0.42, 1.0))


func record_damage_breakdown(breakdown: DamageBreakdown) -> void:
	if breakdown == null:
		return
	_last_damage_breakdown = breakdown
	_refresh_damage_label()


func _refresh_damage_label() -> void:
	if _damage_label == null:
		return
	_damage_label.text = (
		_last_damage_breakdown.to_gm_text()
		if _last_damage_breakdown != null
		else "尚无伤害记录。进入战斗并完成一次攻击后，这里会显示完整结算链路。"
	)


func _on_launcher_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_candidate = true
			_dragged = false
			_press_origin = event.global_position
			_launcher_origin = _launcher.position
		else:
			if _drag_candidate and not _dragged:
				_toggle_panel()
			_drag_candidate = false
		_launcher.accept_event()
	elif event is InputEventMouseMotion and _drag_candidate:
		var delta: Vector2 = event.global_position - _press_origin
		if delta.length() >= 6.0:
			_dragged = true
		_launcher.position = _clamp_launcher(_launcher_origin + delta)
		_launcher.accept_event()


func _toggle_panel() -> void:
	if _panel == null:
		return
	_panel.visible = not _panel.visible
	if _panel.visible:
		_refresh_resource_options()
		_refresh_damage_label()
		_center_panel()
		_panel.move_to_front()


func _unhandled_input(event: InputEvent) -> void:
	if _launcher != null and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F12:
		_toggle_panel()
		get_viewport().set_input_as_handled()


func _center_panel() -> void:
	if _panel == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	_panel.position = (viewport_size - PANEL_SIZE) * 0.5


func _clamp_launcher(candidate: Vector2) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	return Vector2(
		clampf(candidate.x, 0.0, maxf(0.0, viewport_size.x - LAUNCHER_SIZE.x)),
		clampf(candidate.y, 0.0, maxf(0.0, viewport_size.y - LAUNCHER_SIZE.y))
	)


func _on_viewport_size_changed() -> void:
	if _launcher != null:
		_launcher.position = _clamp_launcher(_launcher.position)
	if _panel != null and _panel.visible:
		_center_panel()
