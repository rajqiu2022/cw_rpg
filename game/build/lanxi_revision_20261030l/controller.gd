extends "res://scripts/drafts/miao_terrain_20261029i/town_controller.gd"
const VisibilityGhost=preload("res://build/lanxi_revision_20261030l/ghost.gd")
var visibility_ghost:Node2D
var moved_objects:Dictionary
var migrated_foot:=false
func _ready()->void:
	super._ready()
	visibility_ghost=VisibilityGhost.new();add_child(visibility_ghost);visibility_ghost.setup(self);update_view()
	moved_objects=JSON.parse_string(FileAccess.get_file_as_string("res://build/lanxi_revision_20261030l/moved_objects.json"))
	# The lower weaving lane ends before the natural bank, keeping its walker off the rim.
	$Town/WestWeaver.route=PackedVector2Array([Vector2(1650,2050),Vector2(1900,2050)])
	restore_revised_foot.call_deferred()
func set_fade(art:CanvasItem,_enabled:bool)->void:
	if art.material is ShaderMaterial:art.material.set_shader_parameter("fade_enabled",0.0)
func update_view()->void:
	super.update_view()
	if is_instance_valid(visibility_ghost):visibility_ghost.refresh()

func foot_clear(foot:Vector2,exclude_moved:bool=false)->bool:
	var shape:CollisionShape2D=actor.get_node("CollisionShape2D")
	var q:=PhysicsShapeQueryParameters2D.new();q.shape=shape.shape;q.transform=shape.global_transform
	q.transform.origin+=foot-actor.global_position;q.collision_mask=actor.collision_mask
	var excluded:Array[RID]=[actor.get_rid()]
	if exclude_moved:
		for object_name:String in moved_objects:
			for body in get_node("Town/"+object_name).find_children("*","StaticBody2D",true,false):excluded.append(body.get_rid())
	q.exclude=excluded
	return actor.get_world_2d().direct_space_state.intersect_shape(q,1).is_empty()

func legacy_clear(foot:Vector2)->bool:
	if not foot_clear(foot,true):return false
	var shape:CollisionShape2D=actor.get_node("CollisionShape2D");var transform:=shape.global_transform
	transform.origin+=foot-actor.global_position
	for object_name:String in moved_objects:
		var item:Node2D=get_node("Town/"+object_name);var old:Array=moved_objects[object_name].old
		var delta:=Vector2(old[0],old[1])-item.position
		for outline in item.find_children("*","CollisionPolygon2D",true,false):
			if outline.disabled or (outline.get_parent().collision_layer & actor.collision_mask)==0:continue
			var previous:Transform2D=outline.global_transform;previous.origin+=delta
			if outline_overlap(shape.shape,transform,outline,previous):return false
	return true

func outline_overlap(shape:Shape2D,transform:Transform2D,outline:CollisionPolygon2D,other:Transform2D)->bool:
	for points in Geometry2D.decompose_polygon_in_convex(outline.polygon):
		var polygon:=ConvexPolygonShape2D.new();polygon.points=points
		if shape.collide(transform,polygon,other):return true
	return false

func restore_revised_foot()->void:
	await get_tree().physics_frame
	# Only a previously walkable foot covered by one of this revision's moved objects
	# may move to that object's authored front clearance. Valid feet stay exact.
	if in_hall or terrain.active_ramp>=0 or foot_clear(actor.global_position) or not legacy_clear(actor.global_position):return
	var shape:CollisionShape2D=actor.get_node("CollisionShape2D")
	for object_name:String in moved_objects:
		var item:Node2D=get_node("Town/"+object_name);var overlaps:=false
		for outline in item.find_children("*","CollisionPolygon2D",true,false):
			if outline.disabled or (outline.get_parent().collision_layer & actor.collision_mask)==0:continue
			overlaps=overlaps or outline_overlap(shape.shape,shape.global_transform,outline,outline.global_transform)
		if not overlaps:continue
		var p:Array=moved_objects[object_name].return_foot;var destination:=Vector2(p[0],p[1])
		if terrain.level_at(destination)==terrain.actor_level and foot_clear(destination):
			actor.global_position=destination;migrated_foot=true;update_view();return
