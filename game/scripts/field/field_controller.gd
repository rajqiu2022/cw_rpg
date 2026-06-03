extends Control

## 探索场景（Field）控制器。
##
## 工作方式：
##   1. 从 SceneRouter 取当前 scene_id
##   2. 加载对应 SceneScript .tres
##   3. 渲染背景 + 标题 + N 个互动热点按钮（按 pos_x/pos_y 浮点比例定位）
##   4. 进场触发 on_enter_dialog（如果有）
##   5. 监听 EventBus.flag_set，flag 变化时刷新热点（require/hide 立即生效）
##
## 热点 dict 格式见 SceneScript.gd 注释。

const INVENTORY_PANEL_SCENE := preload("res://scenes/ui/inventory_panel.tscn")
const EQUIPMENT_PANEL_SCENE := preload("res://scenes/ui/equipment_panel.tscn")
const SKILL_PANEL_SCENE := preload("res://scenes/ui/skill_panel.tscn")
const QUEST_PANEL_SCENE := preload("res://scenes/ui/quest_panel.tscn")
const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const ATTR_ICON_ATLAS_PATH := "res://art/ui/cold_wuxia/v1/ui_cold_wuxia_attribute_icons_v1.png"
const ATTR_ICON_REGIONS := {
	"筋骨": Rect2(37, 55, 203, 204),
	"机敏": Rect2(290, 55, 201, 204),
	"内劲": Rect2(544, 55, 200, 204),
	"悟性": Rect2(794, 55, 195, 203),
	"生命": Rect2(1033, 55, 197, 204),
	"内力": Rect2(1281, 55, 196, 204),
	"防御": Rect2(38, 293, 202, 207),
}

@onready var fallback_bg: ColorRect = %FallbackBg
@onready var background: TextureRect = %Background
@onready var hotspots_container: Control = %HotspotsContainer
@onready var scene_title: Label = %SceneTitle
@onready var hud_gold: Label = %GoldLabel
@onready var quest_list: RichTextLabel = %QuestList
@onready var quest_log_btn: Button = %QuestLogBtn
@onready var inventory_btn: Button = %InventoryBtn
@onready var equipment_btn: Button = %EquipmentBtn
@onready var skill_btn: Button = %SkillBtn
@onready var quest_panel: Control = $QuestPanel
@onready var quest_panel_bg: ColorRect = $QuestPanel/Bg
@onready var quest_header: Label = $QuestPanel/Margin/VBox/QuestHeader
@onready var hint_bg: ColorRect = $HintBar/HintBg
@onready var hint_label: Label = $HintBar/HintLabel
@onready var player_info: Label = %PlayerInfo

var _current_scene: SceneScript = null
var _inventory_panel = null
var _equipment_panel = null
var _panels_ready: bool = false
var _skill_panel = null
var _quest_panel_full = null

var _hud_btn_normal: StyleBoxFlat
var _hud_btn_hover: StyleBoxFlat
var _attr_icon_atlas: Texture2D = null


func _ready() -> void:
	EventBus.flag_set.connect(_on_flag_set)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.dialog_ended.connect(_on_dialog_ended)
	EventBus.ui_requested.connect(_on_ui_requested)
	QuestManager.active_quests_changed.connect(_refresh_quest_panel)
	EventBus.quest_completed.connect(_on_quest_completed)
	quest_log_btn.pressed.connect(_on_quest_log_pressed)
	inventory_btn.pressed.connect(_toggle_inventory_panel)
	equipment_btn.pressed.connect(_toggle_equipment_panel)
	skill_btn.pressed.connect(_toggle_skill_panel)
	if ResourceLoader.exists(ATTR_ICON_ATLAS_PATH):
		_attr_icon_atlas = load(ATTR_ICON_ATLAS_PATH)
	_init_m5_panels()
	_init_field_ui_styles()

	var scene_id: StringName = SceneRouter.get_field_payload().get("scene_id", &"ch1_s1_road")
	_current_scene = _load_scene(scene_id)
	if _current_scene == null:
		push_warning("[Field] failed to load scene %s" % scene_id)
		return

	_render_scene(_current_scene)
	_refresh_gold()
	_refresh_quest_panel()

	# scene_entered 必须在 on_enter_dialog 之前发，
	# 这样 QuestManager 可以推进 "scene_entered:<id>" 触发的任务，
	# UI 在面板里立即看到状态变化。
	EventBus.scene_entered.emit(scene_id)

	if _current_scene.on_enter_dialog != null:
		await get_tree().process_frame
		DialogPlayer.play(_current_scene.on_enter_dialog)


func _load_scene(scene_id: StringName) -> SceneScript:
	var path := "res://data/scenes/%s.tres" % String(scene_id)
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is SceneScript:
			return res
	push_warning("[Field] scene not found: %s" % path)
	return null


func _render_scene(scene: SceneScript) -> void:
	background.texture = null
	var bp := scene.background_path
	if bp != "" and ResourceLoader.exists(bp):
		var res: Resource = load(bp)
		if res is Texture2D:
			background.texture = res
			fallback_bg.visible = false
		else:
			push_warning("[Field] background is not Texture2D: %s" % bp)
			fallback_bg.visible = true
	else:
		if String(bp) != "":
			push_warning("[Field] background missing (仓库里常只有 .import 无 PNG): %s" % bp)
		fallback_bg.visible = true
	if scene_title != null:
		scene_title.text = scene.display_name
	_spawn_hotspots(scene.hotspots)


func _spawn_hotspots(hotspots: Array) -> void:
	for c in hotspots_container.get_children():
		c.queue_free()

	for entry in hotspots:
		var h: Dictionary = entry
		var require_flag: String = String(h.get("require_flag", ""))
		var hide_flag: String = String(h.get("hide_flag", ""))

		if require_flag != "" and not _flag_truthy(require_flag):
			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue

		var btn: Button = Button.new()
		btn.text = String(h.get("label", "?"))
		btn.custom_minimum_size = Vector2(220, 60)
		btn.add_theme_font_size_override("font_size", 18)

		var px: float = float(h.get("pos_x", 0.5))
		var py: float = float(h.get("pos_y", 0.5))
		btn.anchor_left = px
		btn.anchor_top = py
		btn.anchor_right = px
		btn.anchor_bottom = py
		btn.offset_left = -110.0
		btn.offset_top = -30.0
		btn.offset_right = 110.0
		btn.offset_bottom = 30.0

		var action: String = String(h.get("action", ""))
		var captured_label := btn.text
		var captured_action := action
		btn.pressed.connect(func(): _on_hotspot_pressed(captured_label, captured_action))
		_style_hotspot_button(btn)
		hotspots_container.add_child(btn)


func _init_field_ui_styles() -> void:
	_hud_btn_normal = _make_hud_style(Color(0.040, 0.058, 0.074, 0.94), UI_THEME.GOLD, 9)
	_hud_btn_hover = _make_hud_style(Color(0.080, 0.122, 0.156, 0.98), UI_THEME.GOLD_LIGHT, 9)
	_style_hud_button(inventory_btn, "内力", UI_THEME.JADE)
	_style_hud_button(equipment_btn, "防御", UI_THEME.BLUE_STEEL)
	_style_hud_button(skill_btn, "筋骨", UI_THEME.JADE)
	_style_hud_button(quest_log_btn, "悟性", UI_THEME.GOLD)
	if quest_panel_bg != null:
		quest_panel_bg.color = Color(0.020, 0.030, 0.040, 0.82)
	if quest_panel != null:
		quest_panel.modulate = Color(1, 1, 1, 0.97)
	if quest_header != null:
		UI_THEME.style_label(quest_header, 20, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_rich_text(quest_list, 15)
	if hint_bg != null:
		hint_bg.color = Color(0.030, 0.045, 0.060, 0.88)
	if hint_label != null:
		UI_THEME.style_label(hint_label, 16, Color(0.84, 0.90, 0.94, 1.0), false)
	UI_THEME.style_label(scene_title, 30, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_label(hud_gold, 22, UI_THEME.GOLD, false)


func _make_hud_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := UI_THEME.button_style(bg, border, radius)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 7
	s.content_margin_bottom = 7
	return s


func _style_hud_button(btn: Button, icon_key: String, accent: Color) -> void:
	if btn == null:
		return
	UI_THEME.style_button(btn, 18, accent)
	btn.add_theme_stylebox_override("normal", _hud_btn_normal)
	btn.add_theme_stylebox_override("hover", _hud_btn_hover)
	btn.add_theme_stylebox_override("pressed", _hud_btn_hover)
	btn.add_theme_stylebox_override("focus", _hud_btn_hover)
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var icon := _make_hud_icon(icon_key, 22)
	if icon != null:
		btn.icon = icon


func _style_hotspot_button(btn: Button) -> void:
	if btn == null:
		return
	UI_THEME.style_button(btn, 18, UI_THEME.GOLD)
	var n := _make_hud_style(Color(0.090, 0.078, 0.060, 0.90), Color(0.34, 0.30, 0.22, 0.96), 10)
	var h := _make_hud_style(Color(0.145, 0.110, 0.080, 0.96), UI_THEME.GOLD_LIGHT, 10)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", h)
	btn.add_theme_stylebox_override("focus", h)


func _make_hud_icon(icon_key: String, icon_size: int) -> Texture2D:
	if _attr_icon_atlas == null:
		return null
	var region: Rect2 = ATTR_ICON_REGIONS.get(icon_key, Rect2())
	if region.size.x <= 0 or region.size.y <= 0:
		return null
	var atlas_img := _attr_icon_atlas.get_image()
	if atlas_img == null:
		return null
	var src_rect := Rect2i(int(region.position.x), int(region.position.y), int(region.size.x), int(region.size.y))
	var img := Image.create(src_rect.size.x, src_rect.size.y, false, Image.FORMAT_RGBA8)
	img.blit_rect(atlas_img, src_rect, Vector2i.ZERO)
	img.resize(icon_size, icon_size, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


func _flag_truthy(key: String) -> bool:
	var v: Variant = GameState.flags.get(key, null)
	if v == null: return false
	if typeof(v) == TYPE_BOOL: return v
	if typeof(v) == TYPE_INT: return v != 0
	if typeof(v) == TYPE_STRING: return v != ""
	return true


# --- 信号回调 ---

func _on_hotspot_pressed(label: String, action: String) -> void:
	if DialogPlayer.is_playing():
		return
	EventBus.hotspot_triggered.emit(SceneRouter.get_current_field_id(), label)
	SceneRouter.resolve_action(action)


func _on_flag_set(_flag: StringName, _v: Variant) -> void:
	# Flag 变化可能让某个热点解锁/隐藏，立即刷新
	if _current_scene != null:
		_spawn_hotspots(_current_scene.hotspots)


func _on_gold_changed(_n: int) -> void:
	_refresh_gold()


func _on_dialog_ended(_id: StringName) -> void:
	# 对话结束后刷新热点（对话副作用可能改了 flag/物品）
	if _current_scene != null:
		_spawn_hotspots(_current_scene.hotspots)


func _refresh_gold() -> void:
	var p: CharacterStats = GameState.player
	if p != null and player_info != null:
		player_info.text = "%s  Lv.%d  HP %d/%d  MP %d/%d" % [p.display_name, p.level, p.hp, p.max_hp, p.mp, p.max_mp]
	if hud_gold != null:
		hud_gold.text = "金 %d" % GameState.gold


func _refresh_quest_panel() -> void:
	if quest_list == null:
		return
	var actives := QuestManager.get_active_quests()
	if actives.is_empty():
		quest_list.text = "[i]暂无任务[/i]"
		return
	var lines: Array[String] = []
	for q in actives:
		var prefix: String = "[color=#e3a64a]●[/color] " if (q as QuestDef).kind == QuestDef.Kind.MAIN else "[color=#88aabb]○[/color] "
		lines.append("%s[b]%s[/b]\n  %s" % [prefix, (q as QuestDef).title, (q as QuestDef).desc_in_progress])
	quest_list.text = "\n\n".join(lines)


func _on_quest_completed(qid: StringName) -> void:
	# 完成提示：直接借用对话框做最简版"toast"——
	# M3 范围只在控制台 print + 让面板从列表里移除，避免阻塞玩家流程。
	# 真正的弹幕/Toast UI 留给 M5+ 美术 UI 阶段。
	var def := QuestManager.load_def(qid)
	if def != null:
		print("[Field] quest completed → %s（gold +%d, exp +%d）" % [def.title, def.reward_gold, def.reward_exp])


func _on_quest_log_pressed() -> void:
	_toggle_quest_log_panel()


func _open_quest_log_panel() -> void:
	if _quest_panel_full == null:
		return
	if _inventory_panel != null:
		_inventory_panel.visible = false
	if _equipment_panel != null:
		_equipment_panel.visible = false
	if _skill_panel != null:
		_skill_panel.visible = false
	_quest_panel_full.open()


func _toggle_quest_log_panel() -> void:
	if _quest_panel_full == null:
		return
	if _quest_panel_full.visible:
		_quest_panel_full.close()
	else:
		_open_quest_log_panel()


func _on_ui_requested(panel_id: StringName) -> void:
	if DialogPlayer.is_playing():
		return
	if not _panels_ready:
		return
	match panel_id:
		&"inventory":
			_open_inventory_panel()
		&"close_equipment":
			if _equipment_panel: _equipment_panel.close()
		&"equipment":
			_open_equipment_panel()
		&"skills":
			_open_skill_panel()
		&"quest_log":
			_open_quest_log_panel()


func _init_m5_panels() -> void:
	_inventory_panel = INVENTORY_PANEL_SCENE.instantiate()
	_equipment_panel = EQUIPMENT_PANEL_SCENE.instantiate()
	_skill_panel = SKILL_PANEL_SCENE.instantiate()
	_quest_panel_full = QUEST_PANEL_SCENE.instantiate()
	add_child(_inventory_panel)
	add_child(_equipment_panel)
	_equipment_panel.visible = false
	add_child(_skill_panel)
	add_child(_quest_panel_full)


func _open_inventory_panel() -> void:
	if _inventory_panel == null:
		return
	if _equipment_panel != null:
		_equipment_panel.visible = false
	if _skill_panel != null:
		_skill_panel.visible = false
	if _quest_panel_full != null:
		_quest_panel_full.visible = false
	_inventory_panel.open()


func _toggle_inventory_panel() -> void:
	if _inventory_panel == null:
		return
	if _inventory_panel.visible:
		_inventory_panel.close()
	else:
		_open_inventory_panel()


func _open_equipment_panel() -> void:
	if _equipment_panel == null:
		_init_m5_panels()
	if _equipment_panel == null:
		return
	_equipment_panel.position = Vector2(640, 0)
	if _inventory_panel != null and not _inventory_panel.visible:
		_inventory_panel.open()
	_equipment_panel.open()


func _toggle_equipment_panel() -> void:
	if _equipment_panel == null:
		return
	if _equipment_panel.visible:
		_equipment_panel.close()
	else:
		_open_equipment_panel()


func _open_skill_panel() -> void:
	if _skill_panel == null:
		return
	if _inventory_panel != null:
		_inventory_panel.visible = false
	if _equipment_panel != null:
		_equipment_panel.visible = false
	if _quest_panel_full != null:
		_quest_panel_full.visible = false
	_skill_panel.open()


func _toggle_skill_panel() -> void:
	if _skill_panel == null:
		return
	if _skill_panel.visible:
		_skill_panel.close()
	else:
		_open_skill_panel()


func _unhandled_input(event: InputEvent) -> void:
	if DialogPlayer.is_playing():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J:
			_on_quest_log_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_I:
			_toggle_inventory_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E:
			_toggle_equipment_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_K:
			_toggle_skill_panel()
			get_viewport().set_input_as_handled()
