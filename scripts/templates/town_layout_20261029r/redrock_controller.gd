extends "res://scripts/drafts/redrock_city_life_20261029a/town_controller.gd"
const Terrain=preload("res://scripts/drafts/town_layout_20261029r/redrock_terrain.gd")
const Ghost=preload("res://scripts/drafts/town_layout_20261029r/actor_ghost.gd")
var terrain:Node2D
var ghost:Node2D
var last_foot:=Vector2.INF
var layout:Dictionary={"terrain":{
	"heights":[0,240,330],"object_moves":{},"portal_half_width":75,"facade_opening_half_width":145,
	"platforms":[{"level":1,"polygon":[[600,450],[5450,450],[5450,1945],[600,1945]]},{"level":2,"polygon":[[600,450],[5450,450],[5450,1230],[2500,1230],[2500,1155],[600,1155]]}],
	"ramps":[{"id":"LaneStairs","label":"下街—民巷高台","low":0,"high":1,"top":[3700,1945],"bottom":[3700,2045],"rise":240,"ground_run":100},{"id":"LookoutStairs","label":"民巷—望关台","low":1,"high":2,"top":[3700,1230],"bottom":[3700,1325],"rise":90,"ground_run":95},{"id":"WestLaneStairs","label":"民巷—西台","low":1,"high":2,"top":[1300,1155],"bottom":[1300,1250],"rise":90,"ground_run":95}]}}
func foot_depth(y:float)->int:return clampi(roundi(y/4.0),-4000,4000)
func _ready()->void:
	super._ready()
	terrain=Terrain.new();terrain.name="RaisedTerrain";add_child(terrain);terrain.setup(self)
	ghost=Ghost.new();ghost.name="OccludedActor";add_child(ghost);ghost.setup(self)
	last_foot=actor.global_position;update_view()
func _physics_process(delta:float)->void:
	if in_hall:
		super._physics_process(delta);return
	var direction:=Vector2.ZERO;var before:=actor.global_position
	if controls_enabled and not show_details:
		direction=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		actor.velocity=terrain.before_move(direction.normalized()*(600.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 330.0));actor.move_and_slide()
	else:actor.velocity=Vector2.ZERO
	terrain.after_move();actor.animate_preview(direction,actor.global_position.distance_squared_to(before)>.001,delta)
	last_foot=actor.global_position;update_view()
func update_view()->void:
	super.update_view()
	if terrain==null:return
	if in_hall:
		actor.set_ground_anchored(true);actor.collision_mask=2;actor.z_as_relative=true;actor.z_index=0
	else:
		if actor.global_position.distance_to(last_foot)>120:terrain.reset_actor(terrain.level_at(actor.global_position))
		terrain.apply_actor_mask()
		terrain.project_actor();actor.z_as_relative=false;actor.z_index=foot_depth(actor.global_position.y)
		if view_mode==1:$Camera.position=terrain.projected_foot()-Vector2(0,190)
		for item in $Town.get_children():
			if item is CharacterBody2D and item!=actor:
				item.show_frame();item.get_node("Art").position.y-=float(item.get_meta("elevation",0));item.z_as_relative=false;item.z_index=foot_depth(item.global_position.y)
	for item in $Town.get_children():
		for name in ["Art","Core"]:
			var art=item.get_node_or_null(name)
			if art is CanvasItem:art.modulate.a=1.0
	if is_instance_valid(ghost):ghost.refresh()
