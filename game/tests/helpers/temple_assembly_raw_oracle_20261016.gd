extends RefCounted
## Independent new-author source-feet oracle. No C/Field/production clearance.
const HALF=Vector2(17,12)
const OFFSETS=[Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]
var floors: Array[PackedVector2Array]=[]
var solids: Array[PackedVector2Array]=[]
var size:=Vector2.ZERO
func polygon(points: Array,scale: Vector2) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for point: Array in points: result.append(Vector2(point[0],point[1])*scale)
	return result
func configure(author: Dictionary,world_size: Vector2) -> bool:
	floors.clear(); solids.clear(); size=world_size
	if not world_size.is_finite() or world_size.x<=0 or world_size.y<=0: return false
	var scale:=world_size/Vector2(1536,1024)
	for points: Array in author.get("geometry",{}).get("floor_regions_px",[]):
		var poly:=polygon(points,scale)
		if poly.size()<3 or Geometry2D.triangulate_polygon(poly).is_empty(): return false
		floors.append(poly)
	for base: Dictionary in author.get("geometry",{}).get("furniture_bases",[]):
		if base.get("blocking")!=true: continue
		var poly:=polygon(base.ground_polygon_px,scale)
		if poly.size()<3 or Geometry2D.triangulate_polygon(poly).is_empty(): return false
		solids.append(poly)
	return not floors.is_empty() and not solids.is_empty()
func point_clear(point: Vector2) -> bool:
	var inside:=false
	for floor_poly: PackedVector2Array in floors:
		if Geometry2D.is_point_in_polygon(point,floor_poly): inside=true; break
	if not inside: return false
	for solid: PackedVector2Array in solids:
		if Geometry2D.is_point_in_polygon(point,solid): return false
	return true
func clear(foot: Vector2) -> bool:
	if not foot.is_finite(): return false
	var rect:=Rect2(foot-HALF,HALF*2)
	var body:=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	var fits:=false
	for floor_poly: PackedVector2Array in floors:
		if Geometry2D.clip_polygons(body,floor_poly).is_empty(): fits=true; break
	if not fits: return false
	for solid: PackedVector2Array in solids:
		if not Geometry2D.intersect_polygons(body,solid).is_empty(): return false
	for offset: Vector2 in OFFSETS:
		if not point_clear(foot+offset): return false
	var rounded:=foot.round()
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			if not point_clear(rounded+Vector2(x,y)): return false
	return true
func segment(from: Vector2,to: Vector2) -> Dictionary:
	var steps: int=maxi(1,ceili(from.distance_to(to)/4.0))
	for index: int in range(steps+1):
		var foot:=from.lerp(to,float(index)/steps)
		if not clear(foot): return {"clear":false,"foot":foot,"index":index}
	return {"clear":true,"samples":steps+1,"max_world_step_px":from.distance_to(to)/steps}
