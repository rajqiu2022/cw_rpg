extends "res://scripts/drafts/miao_building_variety_20261029h/town_controller.gd"
const Terrain = preload("res://scripts/drafts/miao_terrain_20261029i/terrain.gd")
var terrain: Node2D
var return_level := 0

func _ready() -> void:
	super._ready()
	terrain=get_node_or_null("Terrain")
	if terrain==null:terrain=Terrain.new();terrain.name="Terrain";add_child(terrain)
	terrain.setup(self)
	update_view()

func _physics_process(delta: float) -> void:
	var direction:=Vector2.ZERO
	var before: Vector2=actor.global_position
	if controls_enabled and not show_details:
		direction=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		var velocity: Vector2=direction.normalized()*(600.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 330.0)
		actor.velocity=velocity if in_hall else terrain.before_move(velocity)
		actor.move_and_slide()
	else:actor.velocity=Vector2.ZERO
	if not in_hall:terrain.after_move()
	actor.animate_preview(direction,actor.global_position.distance_squared_to(before)>.0001,delta)
	update_view()

func update_view() -> void:
	super.update_view()
	if terrain==null:return
	if not in_hall:
		terrain.project_actor()
		if view_mode==1:$Camera.position=terrain.projected_foot()-Vector2(0,190)
		$UI/Status.text="溪谷低地 → 街坊台地 → 上层民巷　｜　沿石阶上下山寨"
		if terrain.active_ramp>=0:$UI/Status.text="石阶 · "+str(terrain.ramps[terrain.active_ramp].label)

func set_fade(art: CanvasItem,enabled: bool) -> void:
	super.set_fade(art,enabled)
	if terrain!=null and art.material is ShaderMaterial:
		art.material.set_shader_parameter("hero_foot",terrain.projected_foot())

func enter_hall() -> void:
	if terrain.actor_level!=0 or terrain.active_ramp>=0:return
	return_level=terrain.actor_level
	super.enter_hall()
	if in_hall:actor.collision_mask=1;actor.set_ground_anchored(true)

func leave_hall() -> void:
	if not in_hall:return
	super.leave_hall()
	terrain.reset_actor(return_level);update_view()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_R:
		if in_hall:leave_hall()
		actor.global_position=START;terrain.reset_actor(0);show_details=false;view_mode=1;update_view();get_viewport().set_input_as_handled();return
	super._unhandled_key_input(event)
