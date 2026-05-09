extends Control

## 可行走探索场景（Field Walkable）控制器。
##
## 工作方式：
##   1. 从 SceneRouter 取当前 scene_id
##   2. 加载对应 SceneScript .tres
##   3. 渲染背景图、实例化 Player、NPC、出口
##   4. 玩家用 WASD/方向键移动，走进 NPC 范围按交互键对话
##   5. 走进出口按交互键（或自动）切换场景
##
## 与经典模式（field_controller.gd）的区别：
##   - 没有热点按钮，所有交互由玩家移动+交互键触发
##   - 玩家是自由的 CharacterBody2D，不是静态背景+按钮

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const NPC_SCENE := preload("res://scenes/npc_node.tscn")
const EXIT_SCENE := preload("res://scenes/exit_zone.tscn")
const INVENTORY_PANEL_SCENE := preload("res://scenes/ui/inventory_panel.tscn")
const EQUIPMENT_PANEL_SCENE := preload("res://scenes/ui/equipment_panel.tscn")
const SKILL_PANEL_SCENE := preload("res://scenes/ui/skill_panel.tscn")
const QUEST_PANEL_SCENE := preload("res://scenes/ui/quest_panel.tscn")
const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")


@onready var background: TextureRect = %Background

@onready var world_container: Node2D = %WorldContainer
@onready var hotspots_container: Control = %HotspotsContainer
@onready var scene_title: Label = %SceneTitle
@onready var hud_gold: Label = %GoldLabel
@onready var quest_list: RichTextLabel = %QuestList
@onready var quest_log_btn: Button = %QuestLogBtn
@onready var inventory_btn: Button = %InventoryBtn
@onready var equipment_btn: Button = %EquipmentBtn
@onready var skill_btn: Button = %SkillBtn
@onready var hint_bar: Control = %HintBar

@onready var hint_label: Label = %HintLabel
@onready var player_info: Label = %PlayerInfo

var _current_scene: SceneScript = null
var _player: Player = null
var _inventory_panel = null
var _equipment_panel = null
var _skill_panel = null
var _quest_panel_full = null


var _npc_nodes: Array[NPCNode] = []
var _exit_nodes: Array[ExitZone] = []
var _collision_bodies: Array[StaticBody2D] = []
var _trigger_areas: Array[Area2D] = []
var _screen_size: Vector2 = Vector2(1920, 1080)

var _hud_btn_normal: StyleBoxFlat
var _hud_btn_hover: StyleBoxFlat


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
	_init_m5_panels()

	_init_field_ui_styles()

	var scene_id: StringName = SceneRouter.get_field_payload().get("scene_id", &"ch1_s2_qingfeng_walkable")
	_current_scene = _load_scene(scene_id)
	if _current_scene == null:
		push_warning("[FieldWalkable] failed to load scene %s" % scene_id)
		return

	_setup_scene(_current_scene)
	_refresh_gold()
	_refresh_quest_panel()

	# 场景进入事件
	EventBus.scene_entered.emit(scene_id)

	# on_enter_dialog
	if _current_scene.on_enter_dialog != null:
		await get_tree().process_frame
		DialogPlayer.play(_current_scene.on_enter_dialog)


func _load_scene(scene_id: StringName) -> SceneScript:
	var path := "res://data/scenes/%s.tres" % String(scene_id)
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is SceneScript:
			return res
	push_warning("[FieldWalkable] scene not found: %s" % path)
	return null


func _setup_scene(scene: SceneScript, player_spawn_override: Variant = null) -> void:
	## 设置背景
	background.texture = null
	var bp := scene.background_path
	if bp != "" and ResourceLoader.exists(bp):
		var res: Resource = load(bp)
		if res is Texture2D:
			background.texture = res

	## 计算实际显示尺寸（保持宽高比下的渲染尺寸）
	var tex_size := _get_bg_display_size(background.texture)
	_screen_size = tex_size if tex_size != Vector2.ZERO else Vector2(1920, 1080)

	scene_title.text = scene.display_name

	## 隐藏经典模式的热点容器
	hotspots_container.visible = false

	## 清空世界容器
	for c in world_container.get_children():
		c.queue_free()
	_npc_nodes.clear()
	_exit_nodes.clear()
	_collision_bodies.clear()
	_trigger_areas.clear()

	## 生成地图边界碰撞（防止走出屏幕）
	_spawn_map_bounds()

	## 生成 NPC
	_spawn_npcs(scene.npcs)

	## 生成出口
	_spawn_exits(scene.exits)

	## 生成静态障碍和剧情触发区
	_spawn_collision_rects(scene.collision_rects)
	_spawn_trigger_zones(scene.trigger_zones)

	## 生成玩家（最后生成，确保在最上层）
	var spawn := scene.player_spawn
	if player_spawn_override is Vector2:
		spawn = player_spawn_override
	_spawn_player(spawn)

	## 更新操作提示
	hint_label.text = "WASD 移动 · 空格/Enter 交互 · I 背包 · E 装备 · K 武学 · J 任务 · Esc 关闭面板"



func _get_bg_display_size(tex: Texture2D) -> Vector2:
	if tex == null:
		return Vector2.ZERO
	var tw: float = tex.get_width()
	var th: float = tex.get_height()
	var vw: float = 1920.0
	var vh: float = 1080.0
	var scale_x: float = vw / tw
	var scale_y: float = vh / th
	var s: float = min(scale_x, scale_y)
	return Vector2(tw * s, th * s)


func _spawn_map_bounds() -> void:
	## 在地图四周创建 StaticBody2D 边界，防止玩家走出画面
	var bounds: StaticBody2D = StaticBody2D.new()

	bounds.name = "MapBounds"
	world_container.add_child(bounds)

	var margin: float = 20.0
	var w: float = _screen_size.x
	var h: float = _screen_size.y

	# 上边界
	_collider(bounds, Vector2(w / 2, -margin), Vector2(w + margin * 2, margin * 2))
	# 下边界
	_collider(bounds, Vector2(w / 2, h + margin), Vector2(w + margin * 2, margin * 2))
	# 左边界
	_collider(bounds, Vector2(-margin, h / 2), Vector2(margin * 2, h + margin * 2))
	# 右边界
	_collider(bounds, Vector2(w + margin, h / 2), Vector2(margin * 2, h + margin * 2))


func _collider(parent: Node, pos: Vector2, size: Vector2) -> void:
	var c := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	c.shape = shape
	c.position = pos
	parent.add_child(c)


func _spawn_player(spawn_norm: Vector2) -> void:
	var pos := Vector2(
		spawn_norm.x * _screen_size.x,
		spawn_norm.y * _screen_size.y
	)
	_player = PLAYER_SCENE.instantiate()
	_player.position = pos
	_player.name = "Player"

	if not _player.uses_directional_walk_sprites():
		## 旧占位逻辑：没有行走动画的 Player 才使用立绘贴图。
		var pp: String = GameState.player.portrait_path if GameState.player != null else ""

		if pp == "":
			pp = "res://art/characters/protagonist_neutral.png"
		if ResourceLoader.exists(pp):
			var tex: Resource = load(pp)
			if tex is Texture2D and _player.sprite != null:
				_player.sprite.texture = tex
				var origin_size: float = max(tex.get_width(), tex.get_height())
				_player.sprite.scale = Vector2.ONE * (96.0 / origin_size)

	_player.interacted.connect(_on_player_interacted)
	world_container.add_child(_player)


func _spawn_npcs(npc_data: Array) -> void:
	for entry in npc_data:
		var d: Dictionary = entry

		var require_flag: String = String(d.get("require_flag", ""))
		var hide_flag: String = String(d.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):

			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue

		var npc: NPCNode = NPC_SCENE.instantiate()
		npc.npc_id = String(d.get("npc_id", ""))
		npc.npc_name = String(d.get("npc_name", ""))
		npc.dialog_id = String(d.get("dialog_id", ""))
		npc.portrait_path = String(d.get("portrait_path", ""))
		npc.sprite_path = String(d.get("sprite_path", ""))
		npc.sprite_scale = float(d.get("scale", 0.08))

		var pos := Vector2(
			float(d.get("pos", Vector2.ZERO).x) * _screen_size.x,
			float(d.get("pos", Vector2.ZERO).y) * _screen_size.y
		)
		npc.position = pos
		npc.npc_interacted.connect(_on_npc_interacted)
		world_container.add_child(npc)
		_npc_nodes.append(npc)

		## 更新 NPC sprite
		if npc.sprite_path != "" and ResourceLoader.exists(npc.sprite_path):
			var tex: Resource = load(npc.sprite_path)
			if tex is Texture2D:
				npc.sprite.texture = tex
				var origin_size: float = max(tex.get_width(), tex.get_height())
				npc.sprite.scale = Vector2.ONE * (96.0 / origin_size)


func _spawn_exits(exit_data: Array) -> void:
	for entry in exit_data:
		var d: Dictionary = entry

		var require_flag: String = String(d.get("require_flag", ""))

		if require_flag != "" and not _flag_truthy(require_flag):
			continue

		var zone: ExitZone = EXIT_SCENE.instantiate()
		zone.exit_label = String(d.get("label", "前往"))
		zone.target_scene_id = String(d.get("target_scene", ""))
		var tpos: Vector2 = d.get("target_pos", Vector2(0.5, 0.5))
		zone.target_spawn_pos = tpos

		var pos := Vector2(
			float(d.get("pos", Vector2.ZERO).x) * _screen_size.x,
			float(d.get("pos", Vector2.ZERO).y) * _screen_size.y
		)
		zone.position = pos
		zone.exit_triggered.connect(_on_exit_triggered)
		world_container.add_child(zone)
		_exit_nodes.append(zone)

		## 调整出口碰撞大小
		var size_norm: Vector2 = d.get("size", Vector2(0.1, 0.3))
		var size_px := Vector2(size_norm.x * _screen_size.x, size_norm.y * _screen_size.y)
		var collider: CollisionShape2D = zone.get_node("CollisionShape2D")
		if collider != null:
			var shape := RectangleShape2D.new()
			shape.size = size_px
			collider.shape = shape
		var visual: Sprite2D = zone.get_node("Visual")
		if visual != null:
			visual.scale = Vector2(size_px.x / 100.0, size_px.y / 200.0)


func _spawn_collision_rects(collision_data: Array) -> void:
	for entry in collision_data:
		var d: Dictionary = entry
		var require_flag: String = String(d.get("require_flag", ""))
		var hide_flag: String = String(d.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):

			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue

		var body := StaticBody2D.new()
		body.name = "Collision_%s" % String(d.get("id", "rect"))
		body.position = _norm_to_screen(d.get("pos", Vector2.ZERO))
		world_container.add_child(body)
		_collider(body, Vector2.ZERO, _norm_size_to_screen(d.get("size", Vector2(0.1, 0.1))))
		_collision_bodies.append(body)


func _spawn_trigger_zones(trigger_data: Array) -> void:
	for entry in trigger_data:
		var d: Dictionary = entry
		var require_flag: String = String(d.get("require_flag", ""))
		var hide_flag: String = String(d.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):

			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue

		var area := Area2D.new()
		area.name = "Trigger_%s" % String(d.get("id", "zone"))
		area.position = _norm_to_screen(d.get("pos", Vector2.ZERO))
		world_container.add_child(area)
		_collider(area, Vector2.ZERO, _norm_size_to_screen(d.get("size", Vector2(0.1, 0.1))))
		var captured := d.duplicate(true)
		area.body_entered.connect(func(body: Node2D): _on_trigger_zone_entered(body, captured))
		_trigger_areas.append(area)


func _norm_to_screen(value: Variant) -> Vector2:
	var v: Vector2 = value if value is Vector2 else Vector2.ZERO
	return Vector2(v.x * _screen_size.x, v.y * _screen_size.y)


func _norm_size_to_screen(value: Variant) -> Vector2:
	var v: Vector2 = value if value is Vector2 else Vector2(0.1, 0.1)
	return Vector2(v.x * _screen_size.x, v.y * _screen_size.y)


func _on_trigger_zone_entered(body: Node2D, data: Dictionary) -> void:
	if not body.is_in_group("player"):
		return
	if DialogPlayer.is_playing():
		return
	var require_flag: String = String(data.get("require_flag", ""))
	var hide_flag: String = String(data.get("hide_flag", ""))

	if require_flag != "" and not _flag_truthy(require_flag):
		return
	if hide_flag != "" and _flag_truthy(hide_flag):
		return
	var action: String = String(data.get("action", ""))

	if action != "":
		SceneRouter.resolve_action(action)


func _on_player_interacted() -> void:
	if DialogPlayer.is_playing():
		return
	## 优先检测 NPC 交互
	for npc in _npc_nodes:
		if npc.try_interact():
			return
	## 其次检测出口交互
	for zone in _exit_nodes:
		if zone.try_interact():
			return


func _on_npc_interacted(_npc_id: String, dialog_id: String) -> void:
	if dialog_id == "":
		return
	var path := "res://data/dialogs/%s.tres" % dialog_id
	if not ResourceLoader.exists(path):
		push_warning("[FieldWalkable] dialog not found: %s" % path)
		return
	var script: Resource = load(path)
	if script is DialogScript:
		_player.set_can_move(false)
		DialogPlayer.play(script)
		EventBus.npc_talked_to.emit(StringName(_npc_id))


func _on_exit_triggered(target_scene: String, target_pos: Vector2) -> void:
	SceneRouter.go_field_smart(StringName(target_scene), target_pos)


func _flag_truthy(key: String) -> bool:
	var v: Variant = GameState.flags.get(key, null)
	if v == null: return false
	if typeof(v) == TYPE_BOOL: return v
	if typeof(v) == TYPE_INT: return v != 0
	if typeof(v) == TYPE_STRING: return v != ""
	return true


# --- UI 样式（与 field_controller.gd 保持一致）---

func _init_field_ui_styles() -> void:
	_hud_btn_normal = _make_hud_style(Color(0.040, 0.058, 0.074, 0.94))
	_hud_btn_hover = _make_hud_style(Color(0.055, 0.145, 0.145, 0.98))
	for b in [inventory_btn, equipment_btn, skill_btn, quest_log_btn]:
		_style_hud_button(b)
	UI_THEME.style_label(scene_title, 24, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_label(player_info, 18, UI_THEME.TEXT, false)
	UI_THEME.style_label(hud_gold, 18, UI_THEME.GOLD, false)
	UI_THEME.style_rich_text(quest_list, 15)
	UI_THEME.style_label(hint_label, 13, Color(0.78, 0.88, 0.90, 0.86), false)


func _make_hud_style(c: Color) -> StyleBoxFlat:
	var s := UI_THEME.button_style(c, UI_THEME.BLUE_STEEL, 8)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


func _style_hud_button(btn: Button) -> void:
	UI_THEME.style_button(btn, 16, UI_THEME.BLUE_STEEL)
	btn.add_theme_stylebox_override("normal", _hud_btn_normal)
	btn.add_theme_stylebox_override("hover", _hud_btn_hover)
	btn.add_theme_stylebox_override("pressed", _hud_btn_hover)
	btn.add_theme_stylebox_override("focus", _hud_btn_hover)
	btn.add_theme_color_override("font_color", UI_THEME.TEXT)


# --- 信号回调 ---

func _on_flag_set(_flag: StringName, _v: Variant) -> void:
	## flag 变化可能解锁/隐藏 NPC/出口/触发区，重新生成场景元素。
	## 重建时保留玩家当前位置，避免触发区 set_flag 后瞬移回出生点。
	if _current_scene != null:
		var spawn := _current_scene.player_spawn
		if _player != null and _screen_size.x > 0.0 and _screen_size.y > 0.0:
			spawn = Vector2(
				clampf(_player.position.x / _screen_size.x, 0.0, 1.0),
				clampf(_player.position.y / _screen_size.y, 0.0, 1.0)
			)
		_setup_scene(_current_scene, spawn)


func _on_gold_changed(_n: int) -> void:
	_refresh_gold()


func _on_dialog_ended(_id: StringName) -> void:
	if _player != null:
		_player.set_can_move(true)


func _refresh_gold() -> void:
	var p: CharacterStats = GameState.player
	if p != null and player_info != null:
		player_info.text = "%s  Lv.%d  HP %d/%d  MP %d/%d" % [p.display_name, p.level, p.hp, p.max_hp, p.mp, p.max_mp]
	hud_gold.text = "金 %d" % GameState.gold


func _refresh_quest_panel() -> void:
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
	var def := QuestManager.load_def(qid)
	if def != null:
		print("[FieldWalkable] quest completed → %s（gold +%d, exp +%d）" % [def.title, def.reward_gold, def.reward_exp])
		## 简单 toast 提示
		_show_toast("任务完成：%s" % def.title)


func _show_toast(text: String) -> void:
	var toast := Label.new()
	toast.text = text
	toast.position = Vector2(_screen_size.x / 2 - 150, _screen_size.y * 0.25)
	toast.custom_minimum_size = Vector2(300, 40)
	toast.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	toast.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	toast.add_theme_font_size_override("font_size", 20)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(toast)
	await get_tree().create_timer(2.5).timeout
	toast.queue_free()


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
	match panel_id:
		&"inventory":
			_open_inventory_panel()
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
		return
	if _inventory_panel != null:
		_inventory_panel.visible = false
	if _skill_panel != null:
		_skill_panel.visible = false
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
