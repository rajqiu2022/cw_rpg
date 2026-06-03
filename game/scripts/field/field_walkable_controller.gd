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
const FIELD_PRIMARY_HUD_SCENE := preload("res://scenes/ui/field_primary_hud.tscn")
const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const UI_TEXTURE_SKIN := preload("res://scripts/ui/ui_texture_skin.gd")
const HUD_ART_DIR := "res://art/ui/field_hud/v1"


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
var _panels_ready: bool = false
var _skill_panel = null
var _quest_panel_full = null


var _npc_nodes: Array[NPCNode] = []
var _exit_nodes: Array[ExitZone] = []
var _collision_bodies: Array[StaticBody2D] = []
var _trigger_areas: Array[Area2D] = []
var _scene_object_nodes: Array[Sprite2D] = []
var _animated_prop_nodes: Array[Node2D] = []
var _screen_size: Vector2 = Vector2(1920, 1080)

var _hud_btn_normal: StyleBoxFlat
var _hud_btn_hover: StyleBoxFlat
var _primary_hud = null
var _formal_hud_layer: Control = null
var _formal_portrait: TextureRect = null
var _formal_name_label: Label = null
var _formal_hp_bar: TextureRect = null
var _formal_mp_bar: TextureRect = null
var _formal_gold_label: Label = null
var _formal_scene_label: Label = null
var _formal_hint_label: Label = null
var _formal_bottom_bar: TextureRect = null


func _ready() -> void:
	EventBus.flag_set.connect(_on_flag_set)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.dialog_started.connect(_on_dialog_started)
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

	_init_formal_hud()
	_apply_formal_hud_mode()
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

	if scene_title != null:
		scene_title.text = scene.display_name
	if _primary_hud != null:
		_primary_hud.set_scene_info(scene.display_name)

	## 隐藏经典模式的热点容器
	hotspots_container.visible = false

	## 清空世界容器
	for c in world_container.get_children():
		c.queue_free()
	_npc_nodes.clear()
	_exit_nodes.clear()
	_collision_bodies.clear()
	_trigger_areas.clear()
	_scene_object_nodes.clear()
	_animated_prop_nodes.clear()

	## 生成地图边界碰撞（防止走出屏幕）
	_spawn_map_bounds()

	## 生成 Tiled / 模块化场景元素
	_spawn_scene_objects(scene.scene_objects)

	## 生成背景上方的程序化小动画（旗子、炊烟、炉火等）
	_spawn_animated_props(scene.animated_props)

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

	## 操作提示已移除（不用底部提示条）



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
	var c: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
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
				npc.sprite.scale = Vector2.ONE * (npc.sprite_scale)


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
			var shape: RectangleShape2D = RectangleShape2D.new()
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

		var body: StaticBody2D = StaticBody2D.new()
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

		var area: Area2D = Area2D.new()
		area.name = "Trigger_%s" % String(d.get("id", "zone"))
		area.position = _norm_to_screen(d.get("pos", Vector2.ZERO))
		world_container.add_child(area)
		_collider(area, Vector2.ZERO, _norm_size_to_screen(d.get("size", Vector2(0.1, 0.1))))
		var captured := d.duplicate(true)
		area.body_entered.connect(func(body: Node2D): _on_trigger_zone_entered(body, captured))
		_trigger_areas.append(area)

func _spawn_scene_objects(scene_objects: Array) -> void:
	for entry in scene_objects:
		var d: Dictionary = entry
		var require_flag: String = String(d.get("require_flag", ""))
		var hide_flag: String = String(d.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):
			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue
		var texture_path: Variant = String(d.get("texture", ""))
		if texture_path == "" or not ResourceLoader.exists(texture_path):
			push_warning("[FieldWalkable] scene object texture missing: %s" % texture_path)
			continue
		var tex: Resource = load(texture_path)
		if not tex is Texture2D:
			push_warning("[FieldWalkable] scene object is not Texture2D: %s" % texture_path)
			continue
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "SceneObject_%s" % String(d.get("id", "object"))
		sprite.texture = tex
		sprite.centered = bool(d.get("centered", true))
		sprite.position = _norm_to_screen(d.get("pos", Vector2.ZERO))
		sprite.scale = _scale_value(d.get("scale", Vector2.ONE))
		sprite.rotation_degrees = float(d.get("rotation", 0.0))
		sprite.z_index = int(d.get("z_index", 0))
		if d.has("modulate") and d["modulate"] is Color:
			sprite.modulate = d["modulate"]
		world_container.add_child(sprite)
		_scene_object_nodes.append(sprite)


func _spawn_animated_props(animated_props: Array) -> void:
	for entry in animated_props:
		var d: Dictionary = entry
		var require_flag: String = String(d.get("require_flag", ""))
		var hide_flag: String = String(d.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):
			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue
		var prop_type: Variant = String(d.get("type", "")).to_lower()
		var node: Node2D = null
		match prop_type:
			"banner":
				node = _make_banner_prop(d)
			"texture_sway":
				node = _make_texture_sway_prop(d)
			"hammer":
				node = _make_hammer_prop(d)
			"smoke":
				node = _make_smoke_prop(d)
			"glow":
				node = _make_glow_prop(d)
			_:
				push_warning("[FieldWalkable] unknown animated prop type: %s" % prop_type)
		if node == null:
			continue
		node.name = "AnimatedProp_%s" % String(d.get("id", prop_type))
		node.position = _norm_to_screen(d.get("pos", Vector2.ZERO))
		node.z_index = int(d.get("z_index", 22))
		world_container.add_child(node)
		_animated_prop_nodes.append(node)


func _make_banner_prop(d: Dictionary) -> Node2D:
	var root: Node2D = Node2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.04, 0.08)))
	var speed: float = maxf(0.1, float(d.get("speed", 1.0)))
	var color: Variant = _parse_html_color(String(d.get("color", "#b72f24")), Color(0.72, 0.18, 0.13, 0.92))
	var pole: Line2D = Line2D.new()
	pole.width = maxf(2.0, size_px.x * 0.08)
	pole.default_color = Color(0.18, 0.12, 0.08, 0.85)
	pole.points = PackedVector2Array([Vector2.ZERO, Vector2(0.0, size_px.y)])
	root.add_child(pole)
	var cloth: Polygon2D = Polygon2D.new()
	cloth.color = color
	cloth.polygon = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(size_px.x, size_px.y * 0.16),
		Vector2(size_px.x * 0.82, size_px.y * 0.55),
		Vector2(0.0, size_px.y * 0.44),
	])
	cloth.position = Vector2(0.0, size_px.y * 0.10)
	root.add_child(cloth)
	var tween := create_tween().set_loops()
	tween.tween_property(cloth, "scale:x", 0.82, 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cloth, "scale:x", 1.08, 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return root


func _make_texture_sway_prop(d: Dictionary) -> Node2D:
	var texture_path: Variant = String(d.get("texture", ""))
	if texture_path == "" or not ResourceLoader.exists(texture_path):
		push_warning("[FieldWalkable] animated prop texture missing: %s" % texture_path)
		return null
	var tex: Resource = load(texture_path)
	if not tex is Texture2D:
		push_warning("[FieldWalkable] animated prop is not Texture2D: %s" % texture_path)
		return null
	var texture := tex as Texture2D
	var root: Node2D = Node2D.new()
	var sprite: Sprite2D = Sprite2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.04, 0.08)))
	var speed: float = maxf(0.1, float(d.get("speed", 1.0)))
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2.ZERO
	sprite.scale = Vector2(size_px.x / texture.get_width(), size_px.y / texture.get_height())
	root.add_child(sprite)
	var tween := create_tween().set_loops()
	tween.tween_property(sprite, "skew", deg_to_rad(-4.0), 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "scale:x", sprite.scale.x * 0.92, 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "skew", deg_to_rad(4.0), 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "scale:x", sprite.scale.x * 1.06, 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return root


func _make_hammer_prop(d: Dictionary) -> Node2D:
	var texture_path: Variant = String(d.get("texture", ""))
	if texture_path == "" or not ResourceLoader.exists(texture_path):
		push_warning("[FieldWalkable] hammer prop texture missing: %s" % texture_path)
		return null
	var tex: Resource = load(texture_path)
	if not tex is Texture2D:
		push_warning("[FieldWalkable] hammer prop is not Texture2D: %s" % texture_path)
		return null
	var texture := tex as Texture2D
	var root: Node2D = Node2D.new()
	var sprite: Sprite2D = Sprite2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.035, 0.06)))
	var speed: float = maxf(0.1, float(d.get("speed", 1.0)))
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2.ZERO
	sprite.position = Vector2(0.0, -size_px.y * 0.65)
	sprite.scale = Vector2(size_px.x / texture.get_width(), size_px.y / texture.get_height())
	root.add_child(sprite)
	var tween := create_tween().set_loops()
	tween.tween_property(sprite, "rotation_degrees", -42.0, 0.22 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "rotation_degrees", 24.0, 0.10 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(0.18 / speed)
	return root


func _make_smoke_prop(d: Dictionary) -> Node2D:
	var root: Node2D = Node2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.06, 0.12)))
	var speed: float = maxf(0.1, float(d.get("speed", 1.0)))
	var color: Variant = _parse_html_color(String(d.get("color", "#d8d8cf")), Color(0.78, 0.78, 0.72, 0.22))
	var tex := _make_radial_texture(64, color, Color(color.r, color.g, color.b, 0.0))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(d.get("id", "smoke"))
	for i in range(6):
		var puff: Sprite2D = Sprite2D.new()
		puff.texture = tex
		puff.centered = true
		var ox: float = size_px.x * (rng.randf_range(-0.06, 0.06))
		var oy := -size_px.y * rng.randf_range(0.0, 0.10)
		puff.position = Vector2(ox, oy)
		var s := rng.randf_range(0.04, 0.10)
		puff.scale = Vector2.ONE * s
		puff.modulate.a = 0.0
		root.add_child(puff)
		_loop_smoke_puff(puff, size_px, speed, rng.randf_range(0.0, 1.0), rng)
	return root


func _loop_smoke_puff(puff: Sprite2D, size_px: Vector2, speed: float, delay: float, rng: RandomNumberGenerator) -> void:
	var base_pos := puff.position
	var base_scale := puff.scale
	var drift_x := size_px.x * rng.randf_range(-0.03, 0.05)
	var rise_y := -size_px.y * rng.randf_range(0.20, 0.40)
	var grow := rng.randf_range(1.3, 2.0)
	var life := rng.randf_range(1.5, 2.8) / speed
	var tween := create_tween().set_loops()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		if is_instance_valid(puff):
			puff.position = base_pos
			puff.scale = base_scale
			puff.modulate.a = 0.0
	)
	tween.tween_property(puff, "modulate:a", 0.22, life * 0.25)
	tween.parallel().tween_property(puff, "position", base_pos + Vector2(drift_x, rise_y), life)
	tween.parallel().tween_property(puff, "scale", base_scale * grow, life)
	tween.tween_property(puff, "modulate:a", 0.0, life * 0.35)


func _make_glow_prop(d: Dictionary) -> Node2D:
	var root: Node2D = Node2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.08, 0.08)))
	var speed: float = maxf(0.1, float(d.get("speed", 1.0)))
	var color: Variant = _parse_html_color(String(d.get("color", "#ff8a22")), Color(1.0, 0.45, 0.12, 0.55))
	var glow: Sprite2D = Sprite2D.new()
	glow.texture = _make_radial_texture(256, color, Color(color.r, color.g, color.b, 0.0))
	glow.centered = true
	glow.scale = Vector2(size_px.x / 128.0, size_px.y / 128.0)
	glow.modulate.a = 0.45
	root.add_child(glow)
	var tween := create_tween().set_loops()
	tween.tween_property(glow, "modulate:a", 0.18, 0.65 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(glow, "modulate:a", 0.52, 0.65 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return root


func _make_radial_texture(size: int, inner: Color, outer: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var r: float = size / 2.0
	for y in range(size):
		for x in range(size):
			var dist: float = sqrt((x - cx) ** 2 + (y - cy) ** 2) / r
			var t: float = clampf(dist, 0.0, 1.0)
			var c: Color = inner.lerp(outer, t)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _scale_value(v: Variant) -> Vector2:
	if v is Vector2:
		return v
	if v is float or v is int:
		return Vector2(float(v), float(v))
	return Vector2.ONE


func _parse_html_color(hex_str: String, fallback: Color) -> Color:
	var s := hex_str.strip_edges()
	if s.begins_with("#"):
		s = s.substr(1)
	if s.length() == 6:
		return Color(
			float(("0x" + s.substr(0, 2)).hex_to_int()) / 255.0,
			float(("0x" + s.substr(2, 2)).hex_to_int()) / 255.0,
			float(("0x" + s.substr(4, 2)).hex_to_int()) / 255.0,
			0.9
		)
	return fallback



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
		# 传递 NPC 头像给对话系统
		for npc in _npc_nodes:
			if npc.npc_id == _npc_id:
				DialogPlayer.set_default_portrait(npc.portrait_path)
				DialogPlayer.set_default_speaker(npc.npc_name)
				break
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
	quest_list.visible = false
	quest_log_btn.visible = false
	UI_THEME.style_label(hint_label, 13, Color(0.78, 0.88, 0.90, 0.86), false)


func _make_hud_style(c: Color) -> StyleBoxFlat:
	var s := UI_THEME.button_style(c, UI_THEME.BLUE_STEEL, 8)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func _hud_asset(name: String) -> String:
	return HUD_ART_DIR + "/hud_" + name + ".png"


func _make_tex_rect(node_name: String, asset_name: String, pos: Vector2, sz: Vector2) -> TextureRect:
	var r: TextureRect = TextureRect.new()
	r.name = node_name
	r.texture = UI_TEXTURE_SKIN.load_texture(_hud_asset(asset_name))
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.position = pos
	r.size = sz
	return r


func _init_formal_hud() -> void:
	_primary_hud = FIELD_PRIMARY_HUD_SCENE.instantiate()
	_primary_hud.name = "FieldPrimaryHud"
	add_child(_primary_hud)
	_formal_hud_layer = _primary_hud
	_primary_hud.inventory_pressed.connect(_toggle_inventory_panel)
	_primary_hud.equipment_pressed.connect(_toggle_equipment_panel)
	_primary_hud.skill_pressed.connect(_toggle_skill_panel)
	_primary_hud.quest_pressed.connect(_toggle_quest_log_panel)
	_primary_hud.system_pressed.connect(func() -> void: _show_toast("系统功能暂未开放"))


func _apply_formal_hud_mode() -> void:
	if scene_title != null:
		scene_title.visible = false
	if player_info != null:
		player_info.visible = false
	if hud_gold != null:
		hud_gold.visible = false
	if quest_list != null:
		quest_list.visible = false
	if hint_bar != null:
		hint_bar.visible = false
	if inventory_btn != null:
		inventory_btn.visible = false
	if equipment_btn != null:
		equipment_btn.visible = false
	if skill_btn != null:
		skill_btn.visible = false
	if quest_log_btn != null:
		quest_log_btn.visible = false


func _build_player_info_panel() -> void:
	var panel := _make_tex_rect("PlayerPanel", "player_panel", Vector2(10, 10), Vector2(340, 98))
	_formal_hud_layer.add_child(panel)

	var portrait: TextureRect = TextureRect.new()
	portrait.name = "Portrait"
	portrait.position = Vector2(22, 22)
	portrait.size = Vector2(44, 44)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var pp: String = GameState.player.portrait_path if GameState.player != null else ""
	if pp == "":
		pp = "res://art/characters/protagonist_neutral.png"
	if ResourceLoader.exists(pp):
		portrait.texture = load(pp)
	_formal_hud_layer.add_child(portrait)
	_formal_portrait = portrait

	var name_label: Label = Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(76, 14)
	name_label.size = Vector2(180, 18)
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", UI_THEME.TEXT)
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.62))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	_formal_hud_layer.add_child(name_label)
	_formal_name_label = name_label

	var hp_label: Label = Label.new()
	hp_label.name = "HpLabel"
	hp_label.position = Vector2(76, 40)
	hp_label.size = Vector2(30, 14)
	hp_label.text = "生命"
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.82, 0.85))
	_formal_hud_layer.add_child(hp_label)

	var hp_bg: TextureRect = TextureRect.new()
	hp_bg.name = "HpBg"
	hp_bg.texture = UI_TEXTURE_SKIN.load_texture(_hud_asset("hp_bg"))
	hp_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hp_bg.stretch_mode = TextureRect.STRETCH_SCALE
	hp_bg.position = Vector2(108, 40)
	hp_bg.size = Vector2(160, 14)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_formal_hud_layer.add_child(hp_bg)

	var hp_fill: TextureRect = TextureRect.new()
	hp_fill.name = "HpFill"
	hp_fill.texture = UI_TEXTURE_SKIN.load_texture(_hud_asset("hp_fill"))
	hp_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hp_fill.stretch_mode = TextureRect.STRETCH_SCALE
	hp_fill.position = Vector2(108, 40)
	hp_fill.size = Vector2(160, 14)
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_formal_hud_layer.add_child(hp_fill)
	_formal_hp_bar = hp_fill

	var mp_label: Label = Label.new()
	mp_label.name = "MpLabel"
	mp_label.position = Vector2(76, 60)
	mp_label.size = Vector2(30, 14)
	mp_label.text = "内力"
	mp_label.add_theme_font_size_override("font_size", 11)
	mp_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.82, 0.85))
	_formal_hud_layer.add_child(mp_label)

	var mp_bg: TextureRect = TextureRect.new()
	mp_bg.name = "MpBg"
	mp_bg.texture = UI_TEXTURE_SKIN.load_texture(_hud_asset("mp_bg"))
	mp_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mp_bg.stretch_mode = TextureRect.STRETCH_SCALE
	mp_bg.position = Vector2(108, 60)
	mp_bg.size = Vector2(160, 14)
	mp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_formal_hud_layer.add_child(mp_bg)

	var mp_fill: TextureRect = TextureRect.new()
	mp_fill.name = "MpFill"
	mp_fill.texture = UI_TEXTURE_SKIN.load_texture(_hud_asset("mp_fill"))
	mp_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mp_fill.stretch_mode = TextureRect.STRETCH_SCALE
	mp_fill.position = Vector2(108, 60)
	mp_fill.size = Vector2(160, 14)
	mp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_formal_hud_layer.add_child(mp_fill)
	_formal_mp_bar = mp_fill

	var gold_label: Label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.position = Vector2(76, 78)
	gold_label.size = Vector2(180, 16)
	gold_label.add_theme_font_size_override("font_size", 13)
	gold_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.50, 0.94))
	gold_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.58))
	gold_label.add_theme_constant_override("shadow_offset_x", 1)
	gold_label.add_theme_constant_override("shadow_offset_y", 1)
	_formal_hud_layer.add_child(gold_label)
	_formal_gold_label = gold_label


func _build_scene_name_badge() -> void:
	var badge := _make_tex_rect("SceneBadgeBg", "scene_badge", Vector2(1730, 10), Vector2(180, 26))
	_formal_hud_layer.add_child(badge)
	var label: Label = Label.new()
	label.name = "FormalSceneLabel"
	label.position = badge.position
	label.size = badge.size
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.82, 0.90, 0.94, 0.92))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formal_hud_layer.add_child(label)
	_formal_scene_label = label


func _build_quest_display() -> void:
	var panel := _make_tex_rect("QuestPanel", "quest_panel", Vector2(1600, 46), Vector2(300, 100))
	_formal_hud_layer.add_child(panel)


func _build_bottom_bar() -> void:
	var bar := _make_tex_rect("BottomBar", "bottom_bar", Vector2(0, 937), Vector2(1920, 143))
	_formal_hud_layer.add_child(bar)
	_formal_bottom_bar = bar
	var label: Label = Label.new()
	label.name = "FormalHintLabel"
	label.position = Vector2(0, 955)
	label.size = Vector2(1920, 30)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.82, 0.90, 0.94, 0.90))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formal_hud_layer.add_child(label)
	_formal_hint_label = label


func _init_hud_right_buttons() -> void:
	var btn_keys := ["inventory", "equipment", "skill", "quest", "system"]
	var positions := [
		Vector2(1670, 120),
		Vector2(1670, 218),
		Vector2(1670, 316),
		Vector2(1670, 414),
		Vector2(1670, 512),
	]
	for i in range(btn_keys.size()):
		var key: String = btn_keys[i]
		var tex_normal := UI_TEXTURE_SKIN.load_texture(_hud_asset("btn_" + key + "_normal"))
		if tex_normal == null:
			continue
		var btn: TextureButton = TextureButton.new()
		btn.name = "FormalBtn_" + key.capitalize()
		btn.texture_normal = tex_normal
		btn.texture_hover = UI_TEXTURE_SKIN.load_texture(_hud_asset("btn_" + key + "_hover"))
		btn.texture_pressed = UI_TEXTURE_SKIN.load_texture(_hud_asset("btn_" + key + "_pressed"))
		btn.position = positions[i]
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		_formal_hud_layer.add_child(btn)
		match key:
			"inventory": btn.pressed.connect(_toggle_inventory_panel)
			"equipment": btn.pressed.connect(_toggle_equipment_panel)
			"skill": btn.pressed.connect(_toggle_skill_panel)
			"quest": btn.pressed.connect(_toggle_quest_log_panel)
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


func _on_dialog_started(_id: StringName) -> void:
	if _player != null:
		_player.set_can_move(false)
	if _primary_hud != null:
		_primary_hud.set_hint_visible(false)
	if _formal_bottom_bar != null:
		_formal_bottom_bar.visible = false
	if _formal_hint_label != null:
		_formal_hint_label.visible = false

func _on_dialog_ended(_id: StringName) -> void:
	if _player != null:
		_player.set_can_move(true)
	if _primary_hud != null:
		_primary_hud.set_hint_visible(true)
	if _formal_bottom_bar != null:
		_formal_bottom_bar.visible = true
	if _formal_hint_label != null:
		_formal_hint_label.visible = true


func _refresh_gold() -> void:
	var p: CharacterStats = GameState.player
	if p != null:
		if player_info != null:
			player_info.text = "%s  Lv.%d  HP %d/%d  MP %d/%d" % [p.display_name, p.level, p.hp, p.max_hp, p.mp, p.max_mp]
		if _formal_name_label != null:
			_formal_name_label.text = "%s  Lv.%d" % [p.display_name, p.level]
		if _formal_hp_bar != null:
			_formal_hp_bar.size.x = 160.0 * clampf(float(p.hp) / float(p.max_hp), 0.0, 1.0)
		if _formal_mp_bar != null:
			_formal_mp_bar.size.x = 160.0 * clampf(float(p.mp) / float(p.max_mp), 0.0, 1.0)
		if _primary_hud != null:
			_primary_hud.set_player_stats(p, GameState.gold)
	if hud_gold != null:
		hud_gold.text = "金 %d" % GameState.gold
	if _formal_gold_label != null:
		_formal_gold_label.text = "金 %d" % GameState.gold
	if _primary_hud != null and p == null:
		_primary_hud.set_hint_text("WASD 移动   空格/Enter 交互   I 背包   E 装备   K 武学   J 任务   Esc 关闭")


func _refresh_quest_panel() -> void:
	if quest_list == null:
		return
	var actives := QuestManager.get_active_quests()
	if actives.is_empty():
		quest_list.text = "[i]暂无任务[/i]"
		if _primary_hud != null:
			_primary_hud.set_quest_summary("", "")
		return
	var lines: Array[String] = []
	for q in actives:
		var prefix: String = "[color=#e3a64a]●[/color] " if (q as QuestDef).kind == QuestDef.Kind.MAIN else "[color=#88aabb]○[/color] "
		lines.append("%s[b]%s[/b]\n  %s" % [prefix, (q as QuestDef).title, (q as QuestDef).desc_in_progress])
	quest_list.text = "\n\n".join(lines)
	if _primary_hud != null:
		var tracked := actives[0] as QuestDef
		_primary_hud.set_quest_summary(tracked.title, tracked.desc_in_progress)


func _on_quest_completed(qid: StringName) -> void:
	var def := QuestManager.load_def(qid)
	if def != null:
		print("[FieldWalkable] quest completed → %s（gold +%d, exp +%d）" % [def.title, def.reward_gold, def.reward_exp])
		## 简单 toast 提示
		_show_toast("任务完成：%s" % def.title)


func _show_toast(text: String) -> void:
	var toast: Label = Label.new()
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
	_on_system_panel_opened()

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
	_inventory_panel.visible = false
	add_child(_equipment_panel)
	_equipment_panel.visible = false
	add_child(_skill_panel)
	_skill_panel.visible = false
	add_child(_quest_panel_full)
	# 面板自行关闭时（ESC/关闭按钮），也要恢复主 HUD
	_inventory_panel.closed.connect(_on_system_panel_closed)
	_equipment_panel.closed.connect(_on_system_panel_closed)
	_panels_ready = true
	_skill_panel.closed.connect(_on_system_panel_closed)
	_quest_panel_full.closed.connect(_on_system_panel_closed)


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
	_on_system_panel_opened()

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
	if _inventory_panel != null:
		if not _inventory_panel.visible:
			_inventory_panel.open()
		# Shift inventory left to make room
		var mp: Control = _inventory_panel.get_node_or_null("MainPanel")
		if mp:
			mp.offset_left = -960
			mp.offset_right = -320
	_equipment_panel.open()
	_on_system_panel_opened()

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
	_on_system_panel_opened()

func _toggle_skill_panel() -> void:
	if _skill_panel == null:
		return
	if _skill_panel.visible:
		_skill_panel.close()
	else:
		_open_skill_panel()


var _system_panel_open: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if DialogPlayer.is_playing():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		# ESC — 关闭系统面板 或 切换右侧菜单
		if event.keycode == KEY_ESCAPE:
			if _system_panel_open:
				_close_all_system_panels()
			else:
				if _primary_hud != null:
					_primary_hud.toggle_right_menu()
			get_viewport().set_input_as_handled()
			return
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


func _on_system_panel_opened() -> void:
	_system_panel_open = true
	if _primary_hud != null:
		_primary_hud.hide_for_system_ui()
	if _player != null:
		_player.set_can_move(false)



func _on_system_panel_closed() -> void:
	if _player != null:
		_player.can_move = true
	# Restore inventory position
	if _inventory_panel != null:
		var mp: Control = _inventory_panel.get_node_or_null("MainPanel")
		if mp:
			mp.offset_left = -640
			mp.offset_right = 640
	_system_panel_open = false
	if _primary_hud != null:
		_primary_hud.show_after_system_ui()
	if _player != null:
		_player.set_can_move(true)


func _close_all_system_panels() -> void:
	if _inventory_panel != null and _inventory_panel.visible:
		_inventory_panel.close()
	if _equipment_panel != null and _equipment_panel.visible:
		_equipment_panel.close()
	if _skill_panel != null and _skill_panel.visible:
		_skill_panel.close()
	if _quest_panel_full != null and _quest_panel_full.visible:
		_quest_panel_full.close()
	_on_system_panel_closed()
