extends "res://build/lanxi_revision_20261030l/controller.gd"
## Only the two boardwalk side edges; original30l controller/ghost stay intact.
const BOARDWALKS := ["RaisedMarket3","RaisedMarket4"]
const LEFT := -574.2
const RIGHT := 575.94
const OLD_BACK := 494.5602
var boardwalk_edge_migration: Dictionary={"migrated":false,"reason":"NOT_EVALUATED"}

func _ready() -> void:
	super._ready()
	_restore_boardwalk_edge_foot.call_deferred()

func _rectangle(points: Rect2) -> PackedVector2Array:
	return PackedVector2Array([points.position,Vector2(points.end.x,points.position.y),points.end,Vector2(points.position.x,points.end.y)])

func _overlap_points(shape: Shape2D,transform: Transform2D,points: PackedVector2Array,other: Transform2D) -> bool:
	var polygon:=ConvexPolygonShape2D.new();polygon.points=points
	return shape.collide(transform,polygon,other)

func _new_edge_overlap(item: Node2D,shape: Shape2D,transform: Transform2D) -> bool:
	# Front is entirely new. Back's middle already existed and is NOT a repair domain.
	var bands: Array[Rect2]=[]
	bands.append(Rect2(LEFT,20.3,RIGHT-LEFT,12.0))
	bands.append(Rect2(LEFT,-34.3,-OLD_BACK-LEFT,12.0))
	bands.append(Rect2(OLD_BACK,-34.3,RIGHT-OLD_BACK,12.0))
	for band: Rect2 in bands:
		if _overlap_points(shape,transform,_rectangle(band),item.global_transform):return true
	return false

func _edge_exclusions() -> Array[RID]:
	var result: Array[RID]=[];result.append(actor.get_rid())
	for name: String in BOARDWALKS:
		for rail: String in ["FrontRail","BackRail"]:
			var body:=get_node("Town/"+name+"/"+rail) as StaticBody2D
			result.append(body.get_rid())
	return result

func _full_foot_clear(foot: Vector2,old_edges: bool) -> bool:
	var contact:=actor.get_node("CollisionShape2D") as CollisionShape2D
	var full:=RectangleShape2D.new();full.size=Vector2(35,25)
	var transform:=contact.global_transform;transform.origin+=foot-actor.global_position
	var query:=PhysicsShapeQueryParameters2D.new();query.shape=full;query.transform=transform
	query.collision_mask=actor.collision_mask;query.collide_with_areas=false;query.collide_with_bodies=true;query.margin=0.0
	var excluded: Array[RID]=[];excluded.append(actor.get_rid())
	query.exclude=_edge_exclusions() if old_edges else excluded
	if not actor.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():return false
	if old_edges:
		# Restore the exact old BackRail test after excluding its extended current
		# body. Every other real collider, water and previous30l object stays live.
		var old:=_rectangle(Rect2(-OLD_BACK,-34.3,OLD_BACK*2,12.0))
		for name: String in BOARDWALKS:
			var item:=get_node("Town/"+name) as Node2D
			var rail:=item.get_node("BackRail") as StaticBody2D
			if (rail.collision_layer&actor.collision_mask)!=0 and _overlap_points(full,transform,old,item.global_transform):return false
	return true

func _restore_boardwalk_edge_foot() -> void:
	await get_tree().physics_frame
	if not is_inside_tree() or not is_instance_valid(actor) or in_hall or terrain.active_ramp>=0 or terrain.actor_level!=0:
		boardwalk_edge_migration.reason="UNCHANGED_NOT_OUTDOOR_LEVEL0";return
	var contact:=actor.get_node("CollisionShape2D") as CollisionShape2D
	var before: Vector2=actor.global_position
	for name: String in BOARDWALKS:
		var item:=get_node("Town/"+name) as Node2D
		if not _new_edge_overlap(item,contact.shape,contact.global_transform):continue
		boardwalk_edge_migration={"migrated":false,"boardwalk":name,"before":before,"reason":"UNCHANGED_GUARD_REFUSED"}
		var local: Vector2=item.to_local(before)
		# Exact original X, with the entire35px foot inside this deck. No clamp,
		# nearest search, endpoint warp or relocation of ground below the supports.
		if local.x-17.5<LEFT or local.x+17.5>RIGHT:
			boardwalk_edge_migration.reason="UNCHANGED_FULL_X_OUTSIDE_DECK";return
		if not _full_foot_clear(before,true):
			boardwalk_edge_migration.reason="UNCHANGED_OLD_FOOT_OR_OTHER_COLLIDER_BLOCKED";return
		var destination:=Vector2(before.x,item.global_position.y)
		if terrain.level_at(destination)!=0 or not _full_foot_clear(destination,false) or not foot_clear(destination):
			boardwalk_edge_migration.reason="UNCHANGED_AUTHORED_CENTER_NOT_CLEAR";return
		actor.global_position=destination
		boardwalk_edge_migration={"migrated":true,"boardwalk":name,"before":before,"after":destination,"reason":"OLD_LEGAL_NEW_EDGE_ONLY_EXACT_X_CENTERLINE_Y"}
		update_view();return
	boardwalk_edge_migration={"migrated":false,"reason":"UNCHANGED_NOT_NEW_EDGE"}

func get_boardwalk_edge_debug() -> Dictionary:
	var rows: Array[Dictionary]=[]
	for name: String in BOARDWALKS:
		var item:=get_node("Town/"+name) as Node2D
		var back:=item.get_node("BackRail/Outline") as CollisionPolygon2D
		var front:=item.get_node("FrontRail/Outline") as CollisionPolygon2D
		rows.append({"name":name,"node_path":String(item.get_path()),"ground_foot":item.global_position,"level":item.get_meta("terrain_level",0),"elevation":item.get_meta("elevation",0),"back_polygon":back.polygon,"front_polygon":front.polygon,"back_layer":back.get_parent().collision_layer,"front_layer":front.get_parent().collision_layer})
	return {"boardwalks":rows,"migration":boardwalk_edge_migration.duplicate(true),"actor_foot":actor.global_position,"actor_mask":actor.collision_mask,"actor_level":terrain.actor_level,"actor_height":terrain.actor_height,"active_ramp":terrain.active_ramp,"in_hall":in_hall}
