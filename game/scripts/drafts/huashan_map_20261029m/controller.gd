extends Node2D
const Terrain=preload("res://scripts/drafts/huashan_map_20261029m/terrain.gd")
@export var layout_path: String
var layout: Dictionary
var terrain: Node2D
var controls_enabled:=true
var show_details:=false
var view_mode:=1
@onready var actor: CharacterBody2D=$Town/Player

func _ready() -> void:
	layout=JSON.parse_string(FileAccess.get_file_as_string(layout_path))
	actor.set_ground_anchored(true);actor.set_can_move(false)
	for item: Node in $Town.get_children():
		if item is Node2D:
			item.z_as_relative=false
			if not item.has_meta("ground_cover"):item.z_index=foot_depth(item.global_position.y)
	terrain=get_node_or_null("Terrain")
	if terrain==null:terrain=Terrain.new();terrain.name="Terrain";add_child(terrain)
	terrain.setup(self);update_view()

func foot_depth(y: float) -> int:return clampi(roundi(y/4.0),-4000,4000)
func _physics_process(delta: float) -> void:
	var direction:=Vector2.ZERO;var before: Vector2=actor.global_position
	if controls_enabled and not show_details:
		direction=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		actor.velocity=terrain.before_move(direction.normalized()*(600.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 330.0));actor.move_and_slide()
	else:actor.velocity=Vector2.ZERO
	terrain.after_move();actor.animate_preview(direction,actor.global_position.distance_squared_to(before)>.0001,delta);update_view()

func update_view() -> void:
	if terrain==null:return
	terrain.project_actor();actor.z_as_relative=false;actor.z_index=foot_depth(actor.global_position.y)
	$Camera.position=Vector2(layout.overview[0],layout.overview[1]) if view_mode==0 else terrain.projected_foot()-Vector2(0,190)
	$Camera.zoom=Vector2.ONE*(float(layout.overview_zoom) if view_mode==0 else .9)
	$UI/Title.text=str(layout.title)+(" · 全景" if view_mode==0 else "")
	$UI/Status.text=str(layout.subtitle) if terrain.active_ramp<0 else str(terrain.ramps[terrain.active_ramp].label)
	$UI/Detail.visible=show_details
	for item: Node in $Town.get_children():
		if not item.has_meta("fade"):continue
		var art:=item.get_node("Art") as Sprite2D
		if art==null or not art.material is ShaderMaterial:continue
		var mat:=art.material as ShaderMaterial;var r: Rect2=item.get_meta("visual_rect")
		var delta: Vector2=terrain.projected_foot()-(item.global_position-Vector2(0,float(item.get_meta("elevation",0))))
		mat.set_shader_parameter("hero_foot",terrain.projected_foot())
		mat.set_shader_parameter("fade_enabled",1.0 if view_mode==1 and delta.y<0 and delta.y>-r.size.y and absf(delta.x)<r.size.x*.5 else 0.0)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.physical_keycode:
		KEY_TAB:view_mode=1 if view_mode==0 else 0
		KEY_ESCAPE:show_details=false
		KEY_R:
			actor.position=Vector2(layout.spawn[0],layout.spawn[1]);terrain.reset_actor(0);show_details=false;view_mode=1
		KEY_SPACE:
			var nearest: Node2D;var distance:=220.0
			for item: Node in $Town.get_children():
				if not item is Node2D or not item.has_meta("label") or int(item.get_meta("terrain_level",0))!=terrain.actor_level:continue
				var d: float=actor.global_position.distance_to(item.global_position)
				if d<distance:distance=d;nearest=item
			$UI/Detail/Text.text=str(nearest.get_meta("label")) if nearest!=null else str(layout.description)
			show_details=true
		_:return
	update_view();get_viewport().set_input_as_handled()
