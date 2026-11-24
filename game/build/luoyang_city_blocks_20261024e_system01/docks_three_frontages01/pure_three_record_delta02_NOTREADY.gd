extends RefCounted
## BUILD pure record delta only. No IO, engine entry, global cache or formal record mutation.
const IDS=["north_canal_warehouse","harbour_rope_shop","harbour_quay_supply_shop"]
static func v(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size()==2: return Vector2(float(value[0]),float(value[1]))
	return Vector2(INF,INF)
static func xy(point: Vector2) -> Array:
	return [float(point.x),float(point.y)]
static func polygon(value: Variant) -> PackedVector2Array:
	if value is PackedVector2Array: return value.duplicate()
	if not value is Array or value.size()<3: return PackedVector2Array()
	var out:=PackedVector2Array()
	for item: Variant in value:
		var point:=v(item)
		if not point.is_finite(): return PackedVector2Array()
		out.append(point)
	return out
static func find(rows: Array,id: String) -> Dictionary:
	var result: Dictionary={}
	for item: Variant in rows:
		if not item is Dictionary: return {}
		if item.get("id")==id:
			if not result.is_empty(): return {}
			result=item
	return result
static func source_shape(donor: Dictionary,spec: Dictionary,old: bool) -> Dictionary:
	var old_foot:=v(spec.source_foot)
	var foot:=v(spec.old_foot if old else spec.new_foot)
	var ratio: float=float(spec.old_ratio if old else spec.new_ratio)
	if v(donor.get("world_foot_px"))!=old_foot or v(donor.get("collision_size_px"))!=Vector2.ZERO or donor.get("texture")!=spec.texture or donor.get("source_sha256")!=spec.texture_sha256 or not foot.is_finite() or ratio<=0: return {}
	var size:=v(donor.get("render_size_px"))*ratio
	if not size.is_finite() or not donor.get("solid_polygons_px") is Array: return {}
	var shapes: Array=[]
	for raw: Variant in donor.solid_polygons_px:
		var source:=polygon(raw)
		if source.size()<3: return {}
		var points: Array=[]
		for point: Vector2 in source: points.append(xy(foot+(point-old_foot)*ratio))
		shapes.append(points)
	if shapes.size()!=1: return {}
	return {"foot":foot,"size":size,"solids":shapes}
static func exact_solids(current: Variant,expected: Array) -> bool:
	if not current is Array or current.size()!=expected.size(): return false
	for i: int in range(expected.size()):
		if polygon(current[i])!=polygon(expected[i]): return false
	return true
static func project(parent: Dictionary,author: Dictionary,donors: Dictionary) -> Dictionary:
	if author.get("ready")!=false or author.get("scene_id")!="ch4_s2_canal_docks" or parent.get("canonical_scene_id")!="ch4_s2_canal_docks" or not parent.get("objects") is Array or parent.objects.size()!=29 or author.get("changes",[]).size()!=3: return {}
	var child:=parent.duplicate(true)
	var originals: Array=[]
	for i: int in range(3):
		var spec: Dictionary=author.changes[i]
		if spec.get("id")!=IDS[i] or not donors.has(spec.source_manifest): return {}
		var donor:=find(donors[spec.source_manifest].get("objects",[]),spec.source_id)
		var original:=find(parent.objects,spec.id)
		var target:=find(child.objects,spec.id)
		if donor.is_empty() or original.is_empty() or target.is_empty(): return {}
		var before:=source_shape(donor,spec,true)
		var after:=source_shape(donor,spec,false)
		if before.is_empty() or after.is_empty() or original.get("texture")!=spec.texture or v(original.get("world_foot_px"))!=before.foot or v(original.get("physical_center_px"))!=before.foot or v(original.get("render_size_px"))!=before.size or v(original.get("collision_size_px"))!=Vector2.ZERO or not exact_solids(original.get("solid_polygons_px"),before.solids): return {}
		originals.append(original.duplicate(true))
		target.world_foot_px=xy(after.foot)
		target.physical_center_px=xy(after.foot)
		target.render_size_px=xy(after.size)
		target.depth_foot_y=float(after.foot.y)
		target.solid_polygons_px=after.solids
		if target.has("world_origin_px"):
			target.world_origin_px=xy(after.foot+(v(donor.get("world_origin_px"))-v(spec.source_foot))*float(spec.new_ratio))
		if target.has("harbour_transform"):
			var transform: Dictionary=target.harbour_transform
			if v(transform.get("foot"))!=before.foot or float(transform.get("ratio"))!=float(spec.old_ratio): return {}
			transform.foot=xy(after.foot);transform.ratio=float(spec.new_ratio)
	var result: Dictionary={"child":child,"originals":originals,"changed_ids":IDS.duplicate(),"native_count":29,"new_room_count":0}
	if var_to_bytes(restore(result))!=var_to_bytes(parent): return {}
	return result
static func restore(projection: Dictionary) -> Dictionary:
	if not projection.get("child") is Dictionary or not projection.get("originals") is Array or projection.originals.size()!=3: return {}
	var parent: Dictionary=projection.child.duplicate(true)
	for original: Dictionary in projection.originals:
		var matches: int=0
		for i: int in range(parent.objects.size()):
			if parent.objects[i].get("id")==original.id:
				matches+=1;parent.objects[i]=original.duplicate(true)
		if matches!=1: return {}
	return parent

static func bounds(shape: PackedVector2Array) -> Rect2:
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
	for point: Vector2 in shape: low=low.min(point);high=high.max(point)
	return Rect2(low,high-low)
static func native_primitives(objects: Array) -> Array:
	var result: Array=[]
	for row: Dictionary in objects:
		var polys: Variant=row.get("solid_polygons_px",[])
		if not polys is Array: return []
		for i: int in range(polys.size()):
			var points:=polygon(polys[i])
			if points.size()<3: return []
			result.append({"id":String(row.id)+"_poly_"+str(i),"kind":"POLYGON","points_px":points})
		var extent:=v(row.get("collision_size_px",[0,0]))
		if not extent.is_finite() or extent.x<0 or extent.y<0: return []
		if extent.x>0 and extent.y>0:
			var low:=v(row.get("physical_center_px"))-extent*.5;var high:=low+extent
			if not low.is_finite() or not high.is_finite(): return []
			result.append({"id":String(row.id)+"_box","kind":"PARENT_EXACT_CLOSED_RECT","points_px":PackedVector2Array([low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)])})
	return result
static func district10(author: Dictionary) -> Dictionary:
	var spec: Dictionary=author.get("districts",{}).get("ch4_s2_canal_docks",{})
	if spec.get("placements",[]).size()!=10: return {}
	var records: Array=[];var seen: Dictionary={}
	for placement: Dictionary in spec.placements:
		if seen.has(placement.id) or placement.has("replaces"): return {}
		seen[placement.id]=true
		var asset: Dictionary=author.get("assets",{}).get(placement.asset_id,{})
		var foot:=v(placement.foot_px);var anchor:=v(asset.get("source_ground_anchor_px"));var scale: float=float(placement.scale)
		if asset.is_empty() or not foot.is_finite() or not anchor.is_finite() or scale<=0: return {}
		var solids: Array=[]
		for raw: Variant in asset.get("ground_solid_polygons_px",[]):
			var source:=polygon(raw)
			if source.size()<3: return {}
			var points: Array=[]
			for point: Vector2 in source: points.append(xy(foot+(point-anchor)*scale))
			solids.append(points)
		if solids.is_empty(): return {}
		records.append({"id":String(placement.id),"world_foot_px":xy(foot),"physical_center_px":xy(foot),"collision_size_px":[0,0],"solid_polygons_px":solids,"blocking":true})
	return {"records":records,"primitives":native_primitives(records)}
static func domains(projection: Dictionary) -> Array[Rect2i]:
	var merged: Array[Rect2i]=[]
	for rows: Array in [projection.get("originals",[]),projection.get("child",{}).get("objects",[])]:
		for id: String in IDS:
			var row:=find(rows,id)
			if row.is_empty(): return []
			for raw: Variant in row.get("solid_polygons_px",[]):
				var shape:=polygon(raw)
				if shape.size()<3: return []
				var area:=bounds(shape)
				var lo:=Vector2i(floori(area.position.x),floori(area.position.y));var hi:=Vector2i(ceili(area.end.x),ceili(area.end.y))
				if lo.x<0 or lo.y<0 or hi.x>=3072 or hi.y>=2048: return []
				var current:=Rect2i(lo,hi-lo+Vector2i.ONE);var index: int=0
				while index<merged.size():
					var other: Rect2i=merged[index]
					if current.position.x<=other.end.x and current.end.x>=other.position.x and current.position.y<=other.end.y and current.end.y>=other.position.y:
						current=current.merge(other);merged.remove_at(index);index=0
					else: index+=1
				merged.append(current)
	merged.sort_custom(func(a: Rect2i,b: Rect2i) -> bool: return a.position.y<b.position.y if a.position.y!=b.position.y else a.position.x<b.position.x)
	var count: int=0
	for area: Rect2i in merged: count+=area.size.x*area.size.y
	return merged if count<=500000 else []
