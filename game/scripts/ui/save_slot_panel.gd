class_name SaveSlotPanel
extends Control

const JOURNAL := preload("res://scripts/ui/journal_ui.gd")
const THEME := preload("res://scripts/ui/wuxia_theme.gd")
const BUTTON_ART := preload("res://scripts/ui/menu_button_art.gd")
const FORMAL_CONFIRM_SCENE := preload("res://scenes/ui/formal_confirm_dialog.tscn")
const ROW_NORMAL := preload("res://art/ui/skill/runtime_v2/skill_row_normal.png")
const ROW_SELECTED := preload("res://art/ui/skill/runtime_v2/skill_row_selected.png")
## 多槽存档面板（M7）。
## 支持 SAVE / LOAD 两种模式。

signal closed

enum Mode { SAVE, LOAD }

var _mode: int = Mode.SAVE
var _selected_slot: int = -1
var _slot_metadata: Array[Dictionary] = []
var embedded := false

@onready var _slot_heading: Label = $Content/SlotHeading
@onready var _title_label: Label = $Content/TitleLabel
@onready var _timestamp: Label = $Content/Timestamp
@onready var _progress: Label = $Content/Progress
@onready var _description: Label = $Content/Description
@onready var _slot_container: VBoxContainer = $Content/SlotContainer
@onready var _btn_confirm: Button = $Content/BtnHBox/BtnConfirm
@onready var _btn_cancel: Button = $Content/BtnHBox/BtnCancel
var _frame_title: Label
var _formal_dialog: FormalConfirmDialog
var _pending_dialog_action: StringName = &""

const TITLE_SAVE := "保存游戏"
const TITLE_LOAD := "读取存档"
const BTN_SAVE := "保存到所选槽位"
const BTN_LOAD := "读取所选槽位"
const SLOT_NAMES := ["存档一", "存档二", "存档三", "存档四", "存档五"]

func _ready() -> void:
	if embedded:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slot_heading.hide()
		_slot_container.position.y = 427.0
		_slot_container.add_theme_constant_override("separation", 5)
	else:
		_install_formal_background()
	THEME.style_label(_slot_heading, 24, THEME.JADE)
	THEME.style_label(_title_label, 30, THEME.GOLD_LIGHT)
	THEME.style_label(_timestamp, 21, THEME.JADE)
	THEME.style_label(_progress, 23, THEME.GOLD_LIGHT)
	THEME.style_label(_description, 21)
	for label in [_slot_heading, _title_label, _timestamp, _progress, _description]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_btn_confirm.disabled = true
	_btn_cancel.pressed.connect(close)
	_btn_confirm.pressed.connect(_on_confirm)
	for button in [_btn_confirm, _btn_cancel]:
		BUTTON_ART.style_button(button, "compact", 18)
		button.custom_minimum_size.y = button.custom_minimum_size.x / BUTTON_ART.aspect("compact")
	_formal_dialog = FORMAL_CONFIRM_SCENE.instantiate() as FormalConfirmDialog
	_formal_dialog.name = "SaveSlotConfirmation"
	_formal_dialog.confirmed.connect(_on_dialog_confirmed)
	_formal_dialog.cancelled.connect(_clear_dialog_action)
	add_child(_formal_dialog)


func _install_formal_background() -> void:
	var frame := JOURNAL.add_frame(self)
	move_child(frame, 0)
	_frame_title = JOURNAL.add_label(frame, "", Rect2(405, 49, 390, 65), 32, THEME.GOLD_LIGHT)
	_frame_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frame_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func has_pending_confirmation() -> bool:
	return is_instance_valid(_formal_dialog) and _formal_dialog.is_open()

func open(mode: int = Mode.SAVE) -> void:
	if _formal_dialog.is_open():
		_formal_dialog.close_dialog()
	_clear_dialog_action()
	_mode = mode
	_selected_slot = -1
	_btn_confirm.disabled = true

	if mode == Mode.SAVE:
		if _frame_title != null:
			_frame_title.text = TITLE_SAVE
		_slot_heading.text = "存档"
		_btn_confirm.text = BTN_SAVE
	else:
		if _frame_title != null:
			_frame_title.text = TITLE_LOAD
		_slot_heading.text = "读档"
		_btn_confirm.text = BTN_LOAD

	_refresh_slots()
	_show_slot_details()
	visible = true


func close() -> void:
	if _formal_dialog != null:
		_formal_dialog.close_dialog()
	_clear_dialog_action()
	visible = false
	emit_signal("closed")


func _refresh_slots() -> void:
	for c in _slot_container.get_children():
		_slot_container.remove_child(c)
		c.queue_free()

	_slot_metadata.clear()
	for i in range(SaveManager.SLOT_COUNT):
		var slot_btn: Button = Button.new()
		slot_btn.custom_minimum_size.y = 50.0 if embedded else 56.0
		slot_btn.toggle_mode = true
		slot_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		slot_btn.add_theme_font_size_override("font_size", 19)
		slot_btn.add_theme_color_override("font_disabled_color", Color(0.68, 0.73, 0.77))
		slot_btn.add_theme_stylebox_override("normal", _texture_stylebox(ROW_NORMAL))
		slot_btn.add_theme_stylebox_override("hover", _texture_stylebox(ROW_SELECTED))
		slot_btn.add_theme_stylebox_override("pressed", _texture_stylebox(ROW_SELECTED))
		slot_btn.add_theme_stylebox_override("disabled", _texture_stylebox(ROW_NORMAL))

		var has_save := SaveManager.has_save(i)
		var meta := SaveManager.get_slot_meta(i) if has_save else {}
		_slot_metadata.append(meta)
		if _mode == Mode.LOAD and not has_save:
			slot_btn.disabled = true

		slot_btn.text = SLOT_NAMES[i]
		slot_btn.button_pressed = i == _selected_slot
		slot_btn.pressed.connect(_on_slot_selected.bind(i, slot_btn))
		_slot_container.add_child(slot_btn)


func _on_slot_selected(idx: int, btn: Button) -> void:
	# 取消其他按钮选中
	for c in _slot_container.get_children():
		if c is BaseButton:
			c.button_pressed = (c == btn)

	_selected_slot = idx
	_btn_confirm.disabled = false
	_show_slot_details()


func _show_slot_details() -> void:
	_timestamp.text = ""
	_progress.text = ""
	_description.text = ""
	if _selected_slot < 0:
		_title_label.text = "选择要保存的槽位" if _mode == Mode.SAVE else "选择要读取的存档"
		return
	_title_label.text = SLOT_NAMES[_selected_slot]
	var meta := _slot_metadata[_selected_slot]
	if not meta.get("exists", false):
		_description.text = "此存档记录无法预览。" if not meta.is_empty() else "空存档"
		return
	_timestamp.text = "存档时间  " + SaveManager.format_timestamp(int(meta.get("timestamp", 0)))
	var progress: Dictionary = meta.get("main_progress", {})
	_progress.text = "第 %d 章" % int(meta.get("chapter", 1))
	if progress.has("title"):
		var state := "已完成" if progress.completed else "进行中"
		_progress.text += " · %s（%s）" % [progress.title, state]
	_description.text = progress.get("description", "")


func _on_confirm() -> void:
	if _selected_slot < 0:
		return

	if _mode == Mode.SAVE:
		if SaveManager.has_save(_selected_slot):
			# 已有存档，请求确认覆盖
			var meta := SaveManager.get_slot_meta(_selected_slot)
			var ts: String = SaveManager.format_timestamp(int(meta.get("timestamp", 0)))
			_pending_dialog_action = &"overwrite"
			_formal_dialog.show_confirm(
				"确认覆盖存档",
				"[center]%s 已有数据\n[color=#d6c4a4]%s[/color]\n\n覆盖后原存档无法恢复。[/center]" % [SLOT_NAMES[_selected_slot], ts],
				"确认覆盖",
				"取消"
			)
		else:
			_do_save()
	else:
		if SaveManager.has_save(_selected_slot):
			_pending_dialog_action = &"load"
			_formal_dialog.show_confirm(
				"确认读取存档",
				"[center]读取%s？[/center]" % SLOT_NAMES[_selected_slot] if not embedded else
				"[center]读取后将离开当前进度。\n[color=#d6c4a4]尚未保存的内容会丢失。[/color][/center]",
				"确认读取",
				"取消"
			)
		else:
			_formal_dialog.show_notice("无法读取", "[center]该存档位为空。[/center]")


func _on_dialog_confirmed() -> void:
	var action := _pending_dialog_action
	_clear_dialog_action()
	match action:
		&"overwrite":
			_do_save()
		&"load":
			_do_load()
		&"save_success":
			close()


func _clear_dialog_action() -> void:
	_pending_dialog_action = &""


func _do_save() -> void:
	if SaveManager.save_to_slot(_selected_slot):
		_refresh_slots()
		_show_slot_details()
		_pending_dialog_action = &"save_success"
		_formal_dialog.show_notice("保存成功", "[center]已保存到%s。[/center]" % SLOT_NAMES[_selected_slot])
	else:
		_formal_dialog.show_notice("保存失败", "[center]保存失败，请重试。[/center]")


func _do_load() -> void:
	if await SaveManager.load_from_menu(_selected_slot):
		var sid := SaveManager.get_save_field_id(_selected_slot)
		if String(sid) == "":
			sid = SceneRouter.START_FIELD_SCENE
		SceneRouter.go_field_smart(sid)
	else:
		_formal_dialog.show_notice("读取失败", "[center]当前进度已保留。请检查游戏资源版本，或选择其他存档。[/center]")


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _formal_dialog != null and _formal_dialog.is_open():
			return
		close()
		get_viewport().set_input_as_handled()


func _texture_stylebox(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	return style
