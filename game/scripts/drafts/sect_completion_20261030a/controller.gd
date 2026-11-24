extends "res://scripts/drafts/sect_maps_20261029k/controller.gd"
const Ghost=preload("res://scripts/drafts/sect_completion_20261030a/ghost.gd")
var ghost:Node2D
var in_hall:=false
var return_foot:=Vector2.ZERO
var solid_front_edges: Array[CollisionPolygon2D]=[]
func _ready()->void:
	super._ready()
	if has_meta("sort_projected_feet"):
		for item: Node in $Town.get_children():
			if item is Node2D and item.has_meta("visual_rect") and not item.has_meta("ground_cover"):
				item.z_index=foot_depth(item.global_position.y-float(item.get_meta("elevation",0.0)))
				var shape:=item.get_node_or_null("Body/Shape") as CollisionPolygon2D
				if shape!=null and shape.has_meta("sort_front_edge"):
					solid_front_edges.append(shape)
	ghost=Ghost.new();add_child(ghost);ghost.setup(self);update_view()

func _update_solid_front_depth() -> void:
	for shape in solid_front_edges:
		var item:=shape.get_parent().get_parent() as Node2D
		var local_x:=shape.to_local(actor.global_position).x
		var points:=shape.polygon
		var front_y:=0.0
		var hit_edge:=false
		for i in points.size():
			var a:=points[i]
			var b:=points[(i+1)%points.size()]
			if is_equal_approx(a.x,b.x) or local_x<minf(a.x,b.x) or local_x>maxf(a.x,b.x):
				continue
			var y:=lerpf(a.y,b.y,(local_x-a.x)/(b.x-a.x))
			front_y=maxf(front_y,y) if hit_edge else y
			hit_edge=true
		# The leading foundation edge can be diagonal on screen. At the
		# actor's x, depth follows the footprint rather than the center of the prop.
		var foot_y:=shape.to_global(Vector2(local_x,front_y)).y
		item.z_index=foot_depth(foot_y-float(item.get_meta("elevation",0.0)))

func update_view()->void:
	super.update_view()
	if terrain!=null and has_meta("sort_projected_feet"):
		actor.z_index=foot_depth(terrain.projected_foot().y)
		_update_solid_front_depth()
	for item in $Town.get_children():
		var art=item.get_node_or_null("Art")
		if art is Sprite2D and art.material is ShaderMaterial:art.material.set_shader_parameter("fade_enabled",0.0)
	if is_instance_valid(ghost):ghost.refresh()
func examine()->void:
	var e:=InputEventKey.new();e.keycode=KEY_SPACE;e.physical_keycode=KEY_SPACE;e.pressed=true
	super._unhandled_key_input(e)
