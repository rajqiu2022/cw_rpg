extends "res://build/city_navigation_20261101d_candidate01/navigation_geometry.gd"
## Candidate only: reject disjoint solid bounds before the unchanged narrow phase.
## Bounds are computed from the current polygon on each call (no stale geometry cache).
static func safe_static(id: String, foot: Vector2) -> bool:
	if not foot.is_finite(): return false
	if _regions.has(id):
		return Core.safe_body(_regions[id], foot, Vector2(17,12)) and Core.npc_route_clear(_regions[id], foot, foot, Vector2(17,12))
	var size: Vector2 = size_for(id)
	var rect := Rect2(foot-Vector2(17,12),Vector2(34,24))
	if not Rect2(Vector2.ZERO,size).encloses(rect): return false
	var body := PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	var solids: Array = []
	if _legacy.has(id):
		var payload: Dictionary = _legacy[id]
		solids = payload.effective_solids
		if not _masks.has(id):
			var supported := false
			for floor: PackedVector2Array in payload.effective_walkable_polygons:
				var all_inside := true
				for p: Vector2 in body:
					if not Geometry2D.is_point_in_polygon(p,floor): all_inside=false; break
				if all_inside: supported=true; break
			if not supported: return false
	elif id == ADVENTURE:
		var layout: WalkableMapLayout = _adventure_scene.map_layout
		for blocker: Dictionary in layout.blockers:
			var center: Vector2 = blocker.pos * size
			var extent: Vector2 = blocker.size * size
			var area := Rect2(center-extent*.5,extent)
			if area.intersects(rect,true): return false
		for p: Vector2 in body:
			var supported := false
			for floor: PackedVector2Array in layout.walkable_regions:
				if Geometry2D.is_point_in_polygon(p/size,floor): supported=true; break
			if not supported: return false
	else: return false
	for polygon: PackedVector2Array in solids:
		if polygon.size() > 0:
			var low: Vector2 = polygon[0]
			var high: Vector2 = low
			var finite := low.is_finite()
			for point: Vector2 in polygon:
				finite = finite and point.is_finite()
				low = low.min(point); high = high.max(point)
			# STRICT inequalities: equal edges still run the original touch tests.
			# Non-finite malformed input also falls through to the original oracle.
			if finite and (high.x < rect.position.x or low.x > rect.end.x or high.y < rect.position.y or low.y > rect.end.y): continue
		if not Geometry2D.intersect_polygons(body,polygon).is_empty(): return false
		for p: Vector2 in body:
			if Geometry2D.is_point_in_polygon(p,polygon): return false
		for p: Vector2 in polygon:
			if rect.has_point(p): return false
		for i: int in range(4):
			for j: int in range(polygon.size()):
				if _touch(body[i],body[(i+1)%4],polygon[j],polygon[(j+1)%polygon.size()]): return false
	if _masks.has(id):
		var mask: Image = _masks[id]
		for y: int in range(roundi(rect.position.y),roundi(rect.end.y)+1):
			for x: int in range(roundi(rect.position.x),roundi(rect.end.x)+1):
				var pixel: Color = mask.get_pixel(x,y)
				if pixel.r<.5 or pixel.a<.5: return false
	return true

static func safe_segment(id: String, a: Vector2, b: Vector2) -> bool:
	var steps: int = maxi(1,ceili(a.distance_to(b)))
	for i: int in range(steps+1):
		if not safe_static(id,a.lerp(b,float(i)/steps)): return false
	return not _regions.has(id) or Core.npc_route_clear(_regions[id],a,b,Vector2(17,12))
