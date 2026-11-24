extends "res://tests/helpers/temple_assembly_raw_oracle_20261016.gd"
## NEW narrow fixed rectangular floor predicate; old7ACA source remains unchanged.
## No production G.audit/safe_foot/C._safe_body_cpu used as the oracle.
var mask: Image
var full_solids: Array[PackedVector2Array]=[]
var bounds: Array[Rect2]=[]
func vector(value: Variant) -> Vector2:
	return value if value is Vector2 else Vector2(value[0],value[1])
func compile_delta(data: Dictionary,spec: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for placement: Dictionary in spec.placements:
		var asset: Dictionary=data.assets[placement.asset_id]
		var foot:=vector(placement.foot_px)
		var anchor:=vector(asset.source_ground_anchor_px)
		var scale: float=placement.scale
		var polygons: Array[PackedVector2Array]=[]
		for raw: Array in asset.ground_solid_polygons_px:
			var transformed:=PackedVector2Array()
			for point: Array in raw: transformed.append(foot+(vector(point)-anchor)*scale)
			if transformed.size()<3 or Geometry2D.triangulate_polygon(transformed).is_empty(): return {}
			polygons.append(transformed)
		if polygons.is_empty() or result.has(placement.id): return {}
		result[placement.id]=polygons
	return result
func configure_record(record: Dictionary,image: Image,delta: Dictionary,only_delta: bool=false) -> bool:
	floors.clear(); solids.clear(); full_solids.clear(); bounds.clear(); mask=image
	size=Vector2(3072,2048)
	floors.append(PackedVector2Array([Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)]))
	if not only_delta:
		if image==null or image.get_size()!=Vector2i(3072,2048): return false
		for object: Dictionary in record.objects:
			for raw: Array in object.get("solid_polygons_px",[]): full_solids.append(polygon(raw,Vector2.ONE))
			var extent:=vector(object.collision_size_px)
			if extent.x>0 and extent.y>0:
				var center:=vector(object.physical_center_px)
				var rect:=Rect2(center-extent*.5,extent)
				full_solids.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
	for id: String in delta:
		for poly: PackedVector2Array in delta[id]: full_solids.append(poly)
	for poly: PackedVector2Array in full_solids:
		if poly.size()<3 or Geometry2D.triangulate_polygon(poly).is_empty(): return false
		var rect:=Rect2(poly[0],Vector2.ZERO)
		for point: Vector2 in poly: rect=rect.expand(point)
		bounds.append(rect)
	solids=full_solids
	return not full_solids.is_empty()
func floor_contains(point: Vector2) -> bool:
	return point.is_finite() and point.x>=0.0 and point.y>=0.0 and point.x<=size.x and point.y<=size.y
func point_clear(point: Vector2) -> bool:
	# This floor is exactly the authored axis-aligned3072x2048 rectangle.
	# Root diagnostic49784 proved native point-in-polygon falsely rejects the
	# strict interior2241,1362. No epsilon or polygon-solid predicate changes.
	if not floor_contains(point): return false
	for solid: PackedVector2Array in solids:
		if Geometry2D.is_point_in_polygon(point,solid): return false
	if mask==null: return true # Explicit delta-only protection of original occupied NPC feet.
	var pixel:=Vector2i(point.round())
	if pixel.x<0 or pixel.y<0 or pixel.x>=mask.get_width() or pixel.y>=mask.get_height(): return false
	var color:=mask.get_pixelv(pixel)
	return color.r>=.5 and color.a>=.5
func clear(foot: Vector2) -> bool:
	# Include continuous shoe AND rounded875 box in prefilter. This selects
	# candidates only; it does not change any pixel or collision predicate.
	var rect:=Rect2(foot-Vector2(17,12),Vector2(34,24)).merge(Rect2(foot.round()-Vector2(17,12),Vector2(34,24)))
	solids=[]
	for index: int in full_solids.size():
		if rect.intersects(bounds[index],true): solids.append(full_solids[index])
	var valid: bool=super.clear(foot)
	solids=full_solids
	return valid
func npc_clear(foot: Vector2) -> bool:
	# Union of two unchanged34x24 shoes covers the full34x30 envelope,
	# including every1085 rounded pixel. It never scales the real NPC body.
	return clear(foot) and clear(foot+Vector2(0,-3)) and clear(foot+Vector2(0,3))
func path(points: Array,npc: bool=false,until: int=0) -> Dictionary:
	var samples:=0
	for index: int in range(1,points.size()):
		var start:=vector(points[index-1]); var end:=vector(points[index])
		var steps:=maxi(1,ceili(start.distance_to(end)/4.0))
		for step: int in range(steps+1):
			var foot:=start.lerp(end,float(step)/steps)
			if (until>0 and Time.get_ticks_msec()>=until) or not (npc_clear(foot) if npc else clear(foot)): return {"clear":false,"index":index,"sample":step,"foot":foot,"samples":samples}
			samples+=1
	return {"clear":true,"samples":samples,"max_step_px":4,"half_extent_px":Vector2(17,15) if npc else Vector2(17,12)}
