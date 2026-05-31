class_name FieldPrimaryHud
extends Control
## 一级 HUD 场景脚本。

signal inventory_pressed
signal equipment_pressed
signal skill_pressed
signal quest_pressed
signal system_pressed

# -- 角色面板 --
@onready var _player_panel: Control = $PlayerInfoPanel
@onready var _name_label: Label = $PlayerInfoPanel/NameLabel
@onready var _level_label: Label = $PlayerInfoPanel/LevelLabel
@onready var _gold_label: Label = $PlayerInfoPanel/GoldLabel
@onready var _hp_clip: Control = $PlayerInfoPanel/HpClip
@onready var _hp_fill: TextureRect = $PlayerInfoPanel/HpClip/HpFill
@onready var _hp_text: Label = $PlayerInfoPanel/HpText
@onready var _mp_clip: Control = $PlayerInfoPanel/MpClip
@onready var _mp_fill: TextureRect = $PlayerInfoPanel/MpClip/MpFill
@onready var _mp_text: Label = $PlayerInfoPanel/MpText

# -- 场景名牌 --
@onready var _map_panel: Control = $MapInfoPanel
@onready var _scene_label: Label = $MapInfoPanel/SceneLabel
@onready var _region_label: Label = $MapInfoPanel/RegionLabel

# -- 任务追踪 --
@onready var _quest_summary: RichTextLabel = $QuestSummaryPanel/QuestSummary

# -- 系统按钮 --
@onready var _btn_inventory: TextureButton = $BtnInventory
@onready var _btn_equipment: TextureButton = $BtnEquipment
@onready var _btn_skill: TextureButton = $BtnSkill
@onready var _btn_quest: TextureButton = $BtnQuest
@onready var _btn_system: TextureButton = $BtnSystem

var _hp_bar_width := 160.0
var _mp_bar_width := 160.0

# 右侧菜单 — 所有按钮一起滑动
var _right_menu_visible: bool = false
var _right_menu_was_visible: bool = false
var _menu_tween: Tween = null
const BTN_OFFSCREEN_X := 1950.0
const BTN_ONSCREEN_X := 1670.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_connect_signals()

	if is_instance_valid(_quest_summary):
		_quest_summary.get_parent().visible = false

	if is_instance_valid(_hp_clip):
		_hp_bar_width = _hp_clip.size.x
	if is_instance_valid(_mp_clip):
		_mp_bar_width = _mp_clip.size.x

	# 右侧菜单默认藏在屏幕外
	_set_all_btn_x(BTN_OFFSCREEN_X)


func _connect_signals() -> void:
	_btn_inventory.pressed.connect(func() -> void: inventory_pressed.emit())
	_btn_equipment.pressed.connect(func() -> void: equipment_pressed.emit())
	_btn_skill.pressed.connect(func() -> void: skill_pressed.emit())
	_btn_quest.pressed.connect(func() -> void: quest_pressed.emit())
	_btn_system.pressed.connect(func() -> void: system_pressed.emit())


# ── 右侧菜单 ──

func _all_btns() -> Array[TextureButton]:
	return [_btn_inventory, _btn_equipment, _btn_skill, _btn_quest, _btn_system]


func _set_all_btn_x(x: float) -> void:
	for btn in _all_btns():
		if is_instance_valid(btn):
			btn.position.x = x


func is_right_menu_visible() -> bool:
	return _right_menu_visible


func toggle_right_menu() -> void:
	if _right_menu_visible:
		slide_right_menu_out()
	else:
		slide_right_menu_in()


func slide_right_menu_in() -> void:
	_right_menu_visible = true
	_tween_menu_to(BTN_ONSCREEN_X)


func slide_right_menu_out() -> void:
	_right_menu_visible = false
	_tween_menu_to(BTN_OFFSCREEN_X)


func hide_right_menu_now() -> void:
	_right_menu_was_visible = _right_menu_visible
	_right_menu_visible = false
	if _menu_tween != null and _menu_tween.is_valid():
		_menu_tween.kill()
	_set_all_btn_x(BTN_OFFSCREEN_X)


func restore_right_menu() -> void:
	if _right_menu_was_visible:
		slide_right_menu_in()
	_right_menu_was_visible = false


func _tween_menu_to(target_x: float) -> void:
	if _menu_tween != null and _menu_tween.is_valid():
		_menu_tween.kill()
	_menu_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_menu_tween.set_parallel(true)
	for btn in _all_btns():
		if is_instance_valid(btn):
			_menu_tween.tween_property(btn, "position:x", target_x, 0.22)


# ── 系统UI切换时隐藏/恢复主HUD ──

func hide_for_system_ui() -> void:
	_player_panel.visible = false
	_map_panel.visible = false
	hide_right_menu_now()


func show_after_system_ui() -> void:
	_player_panel.visible = true
	_map_panel.visible = true
	restore_right_menu()


# ── 公开接口 ──

func set_player_stats(player: CharacterStats, gold: int) -> void:
	if player == null:
		return
	if _name_label != null:
		_name_label.text = player.display_name
	if _level_label != null:
		_level_label.text = "%d" % player.level

	var hp_ratio := clampf(float(player.hp) / max(player.max_hp, 1), 0.0, 1.0)
	var mp_ratio := clampf(float(player.mp) / max(player.max_mp, 1), 0.0, 1.0)

	if is_instance_valid(_hp_clip):
		_hp_clip.size.x = _hp_bar_width * hp_ratio
	if is_instance_valid(_mp_clip):
		_mp_clip.size.x = _mp_bar_width * mp_ratio

	if _hp_text != null:
		_hp_text.text = "%d / %d" % [player.hp, player.max_hp]
	if _mp_text != null:
		_mp_text.text = "%d / %d" % [player.mp, player.max_mp]
	if _gold_label != null:
		_gold_label.text = "金 %d" % gold


func set_scene_info(scene_name: String, region_name: String = "第一章 · 林西村") -> void:
	if _scene_label != null:
		_scene_label.text = "%s" % scene_name
	if _region_label != null:
		_region_label.text = region_name


func set_quest_summary(title: String, desc: String, progress: String = "") -> void:
	if _quest_summary == null:
		return
	if title == "":
		_quest_summary.text = "[color=#8fa7ad]暂无追踪任务[/color]"
		return
	var progress_text := ""
	if progress != "":
		progress_text = "\n[color=#9bc8a2]◆ %s[/color]" % progress
	_quest_summary.text = "[color=#d85f62]主线[/color]\n[b]%s[/b]\n%s%s" % [title, desc, progress_text]


func set_hint_text(text: String) -> void:
	pass


func set_hint_visible(value: bool) -> void:
	pass
