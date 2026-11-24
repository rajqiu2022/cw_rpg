class_name SystemMenu
extends Control

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const SLOT_PANEL := preload("res://scenes/ui/save_slot_panel.tscn")
const JOURNAL := preload("res://scripts/ui/journal_ui.gd")
const BUTTON_ART := preload("res://scripts/ui/menu_button_art.gd")

signal closed

@onready var settings_btn: Button = %SettingsBtn
@onready var settings_page: Control = %SettingsPage
@onready var save_btn: Button = %SaveBtn
@onready var load_btn: Button = %LoadBtn
@onready var bgm_slider: HSlider = %BgmSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var close_btn: BaseButton = %CloseBtn

var _slot_panel: SaveSlotPanel
var _sidebar_heading: Label

func _ready() -> void:
	UI_THEME.style_label(%Title, 32, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_label(%SettingsTitle, 30, UI_THEME.GOLD_LIGHT)
	_sidebar_heading = JOURNAL.add_label(%Content, "江湖行录", Rect2(82, 151, 265, 40), 23, UI_THEME.JADE)
	JOURNAL.add_label(settings_page, "分别调节场景音乐和动作音效。", Rect2(441, 230, 625, 46), 19, UI_THEME.JADE)
	JOURNAL.add_label(settings_page, "O 关闭系统菜单", Rect2(441, 614, 625, 36), 17, UI_THEME.JADE)
	for button in [settings_btn, save_btn, load_btn]:
		button.toggle_mode = true
		BUTTON_ART.style_button(button, "system", 22)
		var height: float = button.size.x / BUTTON_ART.aspect("system")
		button.position.y += (button.size.y - height) * 0.5
		button.size.y = height
	settings_btn.pressed.connect(_show_settings)
	save_btn.pressed.connect(_open_slots.bind(SaveSlotPanel.Mode.SAVE))
	load_btn.pressed.connect(_open_slots.bind(SaveSlotPanel.Mode.LOAD))
	close_btn.pressed.connect(close)
	_slot_panel = SLOT_PANEL.instantiate() as SaveSlotPanel
	_slot_panel.embedded = true
	add_child(_slot_panel)
	_slot_panel.closed.connect(_restore_menu)
	_restore_menu()
	bgm_slider.value = AudioManager.bgm_volume
	sfx_slider.value = AudioManager.sfx_volume
	_style_audio_row(bgm_slider)
	_style_audio_row(sfx_slider)
	bgm_slider.value_changed.connect(AudioManager.set_bgm_volume)
	sfx_slider.value_changed.connect(AudioManager.set_sfx_volume)

func _style_audio_row(slider: HSlider) -> void:
	slider.get_parent().add_theme_constant_override("separation", 16)
	UI_THEME.style_label(slider.get_parent().get_node("Label"), 19)
	for state in ["slider", "grabber_area", "grabber_area_highlight"]:
		var bar := StyleBoxFlat.new()
		bar.bg_color = Color(0.10, 0.19, 0.24) if state == "slider" else Color(0.33, 0.63, 0.67)
		bar.set_corner_radius_all(4)
		bar.content_margin_top = 4
		bar.content_margin_bottom = 4
		slider.add_theme_stylebox_override(state, bar)
	var value := Label.new()
	value.custom_minimum_size.x = 62
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UI_THEME.style_label(value, 19, UI_THEME.GOLD_LIGHT)
	slider.get_parent().add_child(value)
	slider.value_changed.connect(func(amount: float) -> void: value.text = "%d%%" % roundi(amount * 100))
	value.text = "%d%%" % roundi(slider.value * 100)

func allows_hotkey_close() -> bool:
	return not _slot_panel.visible or not _slot_panel.has_pending_confirmation()

func open() -> void:
	show()

func close() -> void:
	if not visible:
		return
	if _slot_panel.visible:
		_slot_panel.close()
	hide()
	closed.emit()

func _open_slots(mode: SaveSlotPanel.Mode) -> void:
	if _slot_panel.has_pending_confirmation():
		return
	_select_page(save_btn if mode == SaveSlotPanel.Mode.SAVE else load_btn)
	_sidebar_heading.text = "存档" if mode == SaveSlotPanel.Mode.SAVE else "读档"
	settings_page.hide()
	_slot_panel.open(mode)

func _show_settings() -> void:
	if _slot_panel.has_pending_confirmation():
		return
	if _slot_panel.visible:
		_slot_panel.close()
	else:
		_restore_menu()

func _restore_menu() -> void:
	_sidebar_heading.text = "江湖行录"
	_select_page(settings_btn)
	settings_page.show()

func _select_page(active: Button) -> void:
	for button in [settings_btn, save_btn, load_btn]:
		button.set_pressed_no_signal(button == active)

func _unhandled_input(event: InputEvent) -> void:
	if visible and not _slot_panel.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
