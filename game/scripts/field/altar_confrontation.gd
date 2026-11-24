extends Node2D

const DIALOG := &"ch8_false_order_prebattle"
const MAP := &"ch8_s5_alliance_ceremonial_platform"
const QUEST := &"q_ch8_main_06_first_false_order"
const CURSOR := preload("res://scripts/field/altar_dialogue.gd").CURSOR
const ACTION := "battle_group_then:ch8_false_order_courier,ch8_false_order_escort:ch8_false_order_victory"
const TENSION := preload("res://scripts/audio/music_catalog.gd")
const DELEGATE := preload("res://art/characters/npc_identity_20261117/wudang_disciple_idle.png")
const LIEYUN := preload("res://art/characters/luoyang_soldier_diversity_20261019y/npc_escort_guard_luoyang_squad_leader_idle_down_1f_y1_runtime.png")
const OFFICER := preload("res://art/characters/luoyang_soldier_diversity_20261019y/npc_escort_guard_luoyang_young_gate_sentry_idle_down_1f_y1_runtime.png")
const SCRIBE := preload("res://art/modules/luoyang_docks_office_20261016h/npc_docks_booking_clerk_idle_down_1f_v1_runtime.png")
const TEACHER := preload("res://art/characters/npc_zhuwei_innkeeper_v1_idle_down_25d_4f.png")
const COURIER := preload("res://art/sprites/battle/story_duels_20261121/courier/field_ready.tres")
const ESCORT := preload("res://art/sprites/battle/story_duels_20261121/escort/field_ready.tres")
const DRAWN := preload("res://art/sprites/battle/story_duels_20261121/escort/field_drawn.tres")

var field: Node
var courier: NPCNode
var hero: Player
var origin: Vector2
var hero_origin: Vector2
var actors := {}
var camera: Camera2D
var previous_camera: Camera2D
var field_hud: CanvasLayer
var hud_was_visible := false
var skip: Button
var hint: Label
var motion: Tween
var dispatched := false
var pending_battle := false
var witness_plan := "split"
var beat := &""
var pose_targets := {}

static func install(tree: SceneTree) -> void:
	EventBus.dialog_started.connect(mount.bind(tree))
	EventBus.battle_ended.connect(save_victory)

static func save_victory(won: bool, fled: bool) -> void:
	if won and not fled and SceneRouter.get_current_field_id() == MAP and SceneRouter.get_battle_payload().get("victory_action") == "dialog:ch8_false_order_victory":
		# Combat has granted gold, loot and XP. The two native defeat flags now
		# route a result-screen save to the victory dialogue instead of another fight.
		GameState.flags.erase(CURSOR)
		PlatformBridge.request_checkpoint_save.call_deferred()

static func mount(id: StringName, tree: SceneTree) -> void:
	if id != DIALOG or SceneRouter.get_current_field_id() != MAP or not QuestManager.is_active(QUEST):
		return
	var host := tree.current_scene
	if host == null or host.has_node("AltarConfrontation") or host.get("_current_scene") == null:
		return
	for npc: NPCNode in host._npc_nodes:
		if npc.npc_id == "ch8_false_order_courier_field":
			var stage := new()
			stage.name = "AltarConfrontation"
			stage.field = host
			stage.courier = npc
			host.add_child(stage)
			return

func _ready() -> void:
	hero = field._player
	hero_origin = hero.global_position
	origin = courier.global_position - Vector2(240, -35)
	global_position = origin
	courier.hide()
	field_hud = field._hud_canvas_layer
	if field_hud:
		hud_was_visible = field_hud.visible
		field_hud.hide()
	previous_camera = get_viewport().get_camera_2d()
	camera = Camera2D.new()
	add_child(camera)
	camera.position = Vector2(0, 100)
	var view := get_viewport_rect().size
	camera.zoom = Vector2.ONE * minf(view.x / 1120.0, view.y / 780.0)
	camera.make_current()
	if GameState.get_flag(&"ch7_witness_plan_luoyang"):
		witness_plan = "luoyang"
	elif GameState.get_flag(&"ch7_witness_plan_public"):
		witness_plan = "public"
	var scribe := Vector2(-246, -52)
	var teacher := Vector2(-49, -92)
	var watch := Vector2(-260, 48)
	var guard_name := "烈云暗哨"
	var guard_art: Texture2D = LIEYUN
	if witness_plan == "luoyang":
		scribe = Vector2(-70,-90)
		teacher = Vector2(45,-108)
		watch = Vector2(-15,-18)
		guard_name = "洛阳官差"
		guard_art = OFFICER
	elif witness_plan == "public":
		scribe = Vector2(-225,-52)
		teacher = Vector2(-105,-58)
		watch = Vector2(-278,28)
		guard_name = "烈云明哨"
	actor("scribe", "内院录事", SCRIBE, 1, scribe)
	actor("teacher", "茗雾旧教习", TEACHER, 4, teacher)
	actor("watch", guard_name, guard_art, 1, watch)
	if witness_plan == "split":
		actor("helper", "行义帮护送人", OFFICER, 1, scribe + Vector2(-66,71))
		actors.watch.position = teacher + Vector2(52, 67)
	actor("delegate", "五派代表", DELEGATE, 4, Vector2(-345,123))
	actor("lieyun", "烈云护使", LIEYUN, 1, Vector2(-342,-40))
	actor("courier", "茗雾假令传使", COURIER, 1, Vector2(240,-35))
	actor("escort", "茗雾护令客", ESCORT, 1, Vector2(373,72))
	var layer := CanvasLayer.new()
	layer.layer = 110
	add_child(layer)
	var bar := HBoxContainer.new()
	layer.add_child(bar)
	bar.position = Vector2(22, 18)
	bar.add_theme_constant_override("separation", 16)
	hint = Label.new()
	hint.text = "F5 存档"
	hint.add_theme_constant_override("outline_size", 5)
	bar.add_child(hint)
	skip = Button.new()
	skip.text = "跳过演出（Esc）"
	skip.focus_mode = Control.FOCUS_NONE
	bar.add_child(skip)
	skip.pressed.connect(request_skip)
	DialogPlayer.text_displayed.connect(_line)
	EventBus.field_cutscene_requested.connect(_finish_requested)

func actor(key: String, title: String, tex: Texture2D, frames: int, at: Vector2) -> void:
	var root := Node2D.new()
	add_child(root)
	root.position = at
	root.name = key
	actors[key] = root
	var sprite := Sprite2D.new()
	sprite.name = "Body"
	sprite.texture = tex
	sprite.hframes = frames
	sprite.scale = Vector2.ONE * 145.0 / tex.get_height()
	sprite.position.y = -69
	root.add_child(sprite)
	var caption := Label.new()
	caption.text = title
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.position = Vector2(-85,-168)
	caption.size.x = 170
	caption.add_theme_font_size_override("font_size",18)
	caption.add_theme_constant_override("outline_size",5)
	root.add_child(caption)

func _line(_speaker: String, _text: String, _choices: bool, _portrait: String) -> void:
	if DialogPlayer._current_script == null or DialogPlayer._current_script.dialog_id != DIALOG:
		return
	beat = DialogPlayer._current_node.node_id
	GameState.flags[CURSOR] = String(beat)
	# Reconstruct the previous pose when a saved line is opened in a fresh field.
	apply_targets()
	if beat != &"assembly":
		actors.delegate.position = Vector2(-167,108)
	if beat in [&"challenge",&"draw",&"shield"]:
		actors.courier.position = Vector2(140,-18)
		if AudioManager.get_current_bgm() != TENSION.track_path(&"story_tension"):
			AudioManager.play_dialog_node_music(DIALOG, &"declare")
	if beat in [&"draw",&"shield"]:
		actors.delegate.position = Vector2(-98,76)
	if beat == &"shield":
		actors.escort.position = Vector2(61,75)
		actors.escort.get_node("Body").texture = DRAWN
	motion = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	match beat:
		&"assembly": move_actor(actors.delegate, Vector2(-167,108), 0.78)
		&"declare": move_actor(actors.courier, Vector2(140,-18), 0.64)
		&"challenge": move_actor(actors.delegate, Vector2(-98,76), 0.54)
		&"draw":
			actors.escort.get_node("Body").texture = DRAWN
			move_actor(actors.escort, Vector2(61,75), 0.70)
		&"shield":
			# Use the real hero and respect the same walkable map as ordinary movement.
			var dest := origin + Vector2(0,101)
			var safe := true
			for i in range(1, 17):
				if not field._is_inside_walkable_screen(hero.global_position.lerp(dest, i/16.0)):
					safe = false
					break
			if not safe:
				dest = hero.global_position
			hero.set_walk_direction(dest - hero.global_position, true)
			motion.tween_property(hero, "global_position", dest, 0.72)
		_: motion.tween_interval(0.05)
	motion.finished.connect(_motion_finished)

func move_actor(who: Node2D, target: Vector2, duration: float) -> void:
	pose_targets[who] = target
	motion.tween_property(who,"position",target,duration)

func apply_targets() -> void:
	if motion and motion.is_valid():
		motion.kill()
	for who: Node2D in pose_targets:
		who.position = pose_targets[who]
	pose_targets.clear()

func _motion_finished() -> void:
	if beat == &"shield":
		hero.set_walk_direction(Vector2.RIGHT, false)
	if pending_battle:
		dispatch()

func _process(_delta: float) -> void:
	for who: Node2D in actors.values():
		field._update_actor_depth(who)
		var sprite := who.get_node("Body") as Sprite2D
		if sprite.hframes > 1:
			sprite.frame = int(Time.get_ticks_msec() / 190) % sprite.hframes

func _input(event: InputEvent) -> void:
	if dispatched:
		get_viewport().set_input_as_handled()
		return
	if event.is_echo():
		return
	var escape: bool = event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE
	var skip_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and skip.get_global_rect().has_point(event.position)
	if escape or event.is_action_pressed("ui_cancel") or skip_click:
		get_viewport().set_input_as_handled()
		request_skip()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		get_viewport().set_input_as_handled()
		hint.text = "已存入槽 %d" % SaveManager.active_slot if SaveManager.save_to_slot(SaveManager.active_slot) else "存档失败"
	elif (AudioManager.is_voice_playing() or (motion and motion.is_running())) and (event.is_action_pressed("ui_accept") or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()

func request_skip() -> void:
	if dispatched or not is_inside_tree():
		return
	apply_targets()
	dispatch()

func _finish_requested(id: StringName) -> void:
	if id != &"altar_false_order_battle" or dispatched:
		return
	if motion and motion.is_running():
		pending_battle = true
		hero.set_can_move(false)
	else:
		dispatch()

func dispatch() -> void:
	if dispatched or get_tree().current_scene != field or not QuestManager.is_active(QUEST):
		return
	dispatched = true
	if DialogPlayer.is_playing() and DialogPlayer._current_script.dialog_id == DIALOG:
		DialogPlayer._end_dialog()
	hero.global_position = hero_origin
	hero.set_walk_direction(Vector2.RIGHT, false)
	hero.set_can_move(false)
	if GameState.get_flag(&"defeated_ch8_false_order_courier") and GameState.get_flag(&"defeated_ch8_false_order_escort"):
		SceneRouter.resolve_action("dialog:ch8_false_order_victory")
		queue_free()
	else:
		skip.hide()
		hint.hide()
		SceneRouter.resolve_action(ACTION)

func _exit_tree() -> void:
	if is_instance_valid(field_hud):
		field_hud.visible = hud_was_visible
	if is_instance_valid(courier):
		courier.show()
	if is_instance_valid(previous_camera) and previous_camera.is_inside_tree():
		previous_camera.make_current()
