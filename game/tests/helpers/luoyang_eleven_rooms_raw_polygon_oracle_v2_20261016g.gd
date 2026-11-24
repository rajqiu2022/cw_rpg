extends RefCounted
## Independent source polygons only. No runtime geometry/compiler/clearance calls.
const HALF:=Vector2(17,12)
const SHOES=[Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]
var floors: Array[PackedVector2Array]=[]
var solids: Array[Dictionary]=[]
var forbidden_feet: Array[PackedVector2Array]=[]
var floor_cache: Dictionary={}
const MAX_FLOOR_CACHE_POINTS:=131072
var errors: Array[String]=[]
var scale:=Vector2.ONE
var world_size:=Vector2.ZERO
var last: Dictionary={}
func _vector(value: Variant) -> Vector2:
	return value if value is Vector2 else Vector2(value[0],value[1])
func _poly(raw: Variant) -> PackedVector2Array:
	var poly:=PackedVector2Array()
	for value: Variant in raw: poly.append(_vector(value)*scale)
	return poly
func _valid(poly: PackedVector2Array) -> bool:
	if poly.size()<3 or Geometry2D.triangulate_polygon(poly).is_empty(): return false
	for point: Vector2 in poly:
		if not point.is_finite() or point.x<0 or point.y<0 or point.x>world_size.x or point.y>world_size.y: return false
	return true
func configure(source_floors: Array,source_solids: Array,source_size: Vector2,actual_world_size: Vector2,source_foot_forbidden: Array=[]) -> bool:
	floors.clear();solids.clear();forbidden_feet.clear();floor_cache.clear();errors.clear();last={};world_size=actual_world_size
	if not source_size.is_finite() or source_size.x<=0 or source_size.y<=0 or not world_size.is_finite() or world_size.x<=0 or world_size.y<=0: return false
	scale=world_size/source_size
	for raw: Variant in source_floors:
		var poly:=_poly(raw)
		if not _valid(poly): errors.append("invalid declared source floor");continue
		floors.append(poly)
	for raw: Variant in source_foot_forbidden:
		var poly:=_poly(raw)
		if not _valid(poly): errors.append("invalid foot-only baked architecture exclusion");continue
		forbidden_feet.append(poly)
	var ids: Dictionary={}
	for row: Dictionary in source_solids:
		var id: String=String(row.get("id",""))
		var poly:=_poly(row.get("points_px",[]))
		if id.is_empty() or ids.has(id) or not _valid(poly): errors.append("invalid/duplicate solid "+id);continue
		ids[id]=true
		solids.append({"id":id,"kind":String(row.get("kind","UNSPECIFIED")),"poly":poly,"bounds":_bounds(poly)})
	return errors.is_empty() and not floors.is_empty()
func _bounds(poly: PackedVector2Array) -> Rect2:
	var low: Vector2=poly[0];var high: Vector2=poly[0]
	for point: Vector2 in poly: low=low.min(point);high=high.max(point)
	return Rect2(low,high-low)
func _on_line(point: Vector2,a: Vector2,b: Vector2) -> bool:
	return (b-a).cross(point-a)==0.0 and point.x>=minf(a.x,b.x) and point.x<=maxf(a.x,b.x) and point.y>=minf(a.y,b.y) and point.y<=maxf(a.y,b.y)
func _inside_closed(point: Vector2,poly: PackedVector2Array) -> bool:
	# Own exact closed-boundary ray crossing; do not repeat native rectangular-floor false rejection.
	var inside:=false
	for i: int in poly.size():
		var a: Vector2=poly[i];var b: Vector2=poly[(i+1)%poly.size()]
		if _on_line(point,a,b): return true
		if (a.y>point.y)!=(b.y>point.y):
			var crossing: float=float(b.x-a.x)*float(point.y-a.y)/float(b.y-a.y)+float(a.x)
			if float(point.x)<crossing: inside=not inside
	return inside
func _floor_point(point: Vector2) -> bool:
	if floor_cache.has(point): return bool(floor_cache[point])
	var answer:=false
	for poly: PackedVector2Array in floors:
		if _inside_closed(point,poly): answer=true;break
	if floor_cache.size()>=MAX_FLOOR_CACHE_POINTS: floor_cache.clear()
	floor_cache[point]=answer
	return answer
func _rectangle(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
func _body_in_floor_union(body: PackedVector2Array) -> bool:
	var remaining: Array[PackedVector2Array]=[body]
	for floor_poly: PackedVector2Array in floors:
		var next: Array[PackedVector2Array]=[]
		for piece: PackedVector2Array in remaining: next.append_array(Geometry2D.clip_polygons(piece,floor_poly))
		remaining=next
		if remaining.is_empty(): return true
	return false
func _closed_intersection(a: PackedVector2Array,b: PackedVector2Array) -> bool:
	if not Geometry2D.intersect_polygons(a,b).is_empty(): return true
	for point: Vector2 in a:
		if _inside_closed(point,b): return true
	for point: Vector2 in b:
		if _inside_closed(point,a): return true
	for i: int in a.size():
		for j: int in b.size():
			if Geometry2D.segment_intersects_segment(a[i],a[(i+1)%a.size()],b[j],b[(j+1)%b.size()])!=null: return true
	return false
func _deny(kind: String,point: Vector2,id: String="") -> bool:
	last={"clear":false,"kind":kind,"point":point,"id":id};return false
func clear(foot: Vector2) -> bool:
	last={}
	if not errors.is_empty() or not foot.is_finite(): return _deny("invalid",foot)
	for excluded: PackedVector2Array in forbidden_feet:
		if _inside_closed(foot,excluded): return _deny("baked_visual_foot_only_exclusion_not_extra_body_solid",foot)
	var body_rect:=Rect2(foot-HALF,HALF*2)
	var body:=_rectangle(body_rect)
	if not _body_in_floor_union(body): return _deny("continuous_body_outside_floor_union",foot)
	var rounded: Vector2=foot.round()
	var sample_bounds: Rect2=body_rect.merge(Rect2(rounded-HALF,HALF*2))
	var nearby: Array[Dictionary]=[]
	for solid: Dictionary in solids:
		if not sample_bounds.intersects(solid.bounds,true): continue
		nearby.append(solid)
		if body_rect.intersects(solid.bounds,true) and _closed_intersection(body,solid.poly): return _deny("continuous_body_solid",foot,solid.id)
	for offset: Vector2 in SHOES:
		var point: Vector2=foot+offset
		if not _floor_point(point): return _deny("actual17_floor",point)
		for solid: Dictionary in nearby:
			if _inside_closed(point,solid.poly): return _deny("actual17_solid",point,solid.id)
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			var point: Vector2=rounded+Vector2(x,y)
			if not _floor_point(point): return _deny("rounded875_floor",point)
			for solid: Dictionary in nearby:
				if _inside_closed(point,solid.poly): return _deny("rounded875_solid",point,solid.id)
	last={"clear":true,"foot":foot,"rounded875":875,"actual17":17,"continuous_body":Vector2(34,24)}
	return true
func segment(a: Vector2,b: Vector2,deadline_msec: int) -> Dictionary:
	var steps: int=maxi(1,ceili(a.distance_to(b)/4.0))
	for i: int in range(steps+1):
		if Time.get_ticks_msec()>=deadline_msec: return {"clear":false,"kind":"predeclared_deadline","index":i}
		if not clear(a.lerp(b,float(i)/steps)):
			var denied: Dictionary=last.duplicate(true);denied["index"]=i;denied["steps"]=steps;return denied
	return {"clear":true,"samples":steps+1,"max_world_step_px":a.distance_to(b)/steps,"body":Vector2(34,24),"full875":true,"full17":true}
