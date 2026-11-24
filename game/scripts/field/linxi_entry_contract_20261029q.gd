extends RefCounted
## A single legacy room's doorway/restore contract. No save writes or nearest-wall search.
const ROOM:=&"linxi_farmer_cottage"
const VILLAGE:=&"linxi_village_center"
const SCENE:="res://data/scenes/linxi_farmer_cottage.tres"

static func repair_saved_origin(requested:Vector2)->Vector2:
	var scene:Resource=load(SCENE)
	return requested if safe_origin(scene,requested) else scene.player_spawn

static func portal_arrival(source:StringName,target:StringName,requested:Vector2)->Vector2:
	if source==VILLAGE and target==ROOM:
		# Re-entry belongs to this door, never an unrelated remembered room point.
		return load(SCENE).player_spawn
	if source==ROOM and target==VILLAGE:
		var scene:Resource=load("res://data/scenes/linxi_village_center.tres")
		for row:Dictionary in scene.map_layout.portals:
			if row.get("target_scene")==String(ROOM):return row.get("pos")
	return requested

static func safe_origin(scene:Resource,p:Vector2)->bool:
	if not p.is_finite() or p.x<0 or p.y<0 or p.x>1 or p.y>1:return false
	var layout:Resource=scene.map_layout
	# Same logical origin coordinates as this legacy field, with a conservative contact rim.
	var size:Vector2=Vector2(layout.design_size)
	for i in range(17):
		var sample:=p if i==16 else p+Vector2(cos(TAU*i/16.0)*18.0/size.x,sin(TAU*i/16.0)*13.0/size.y)
		var inside:=false
		for polygon:PackedVector2Array in layout.walkable_regions:
			if Geometry2D.is_point_in_polygon(sample,polygon):inside=true;break
		if not inside:return false
		for row:Dictionary in layout.blockers:
			var rect:=Rect2(row.pos-row.size*.5,row.size)
			if rect.has_point(sample):return false
		for row:Dictionary in layout.visual_objects:
			if not row.has("collision_size"):continue
			var center:Vector2=row.pos+row.get("collision_offset",Vector2.ZERO)
			if Rect2(center-row.collision_size*.5,row.collision_size).has_point(sample):return false
	return true
