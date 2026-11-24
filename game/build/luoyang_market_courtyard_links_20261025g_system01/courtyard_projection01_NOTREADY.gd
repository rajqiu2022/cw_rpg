extends RefCounted
## 25g pure exact43 ->45 courtyard delta. No IO, cache, scene, geometry compiler or collector.
const SCENE_ID = "ch4_s3_luoyang_market"
const SIZE = Vector2(3072,2048)
const CHANGE_IDS = ["market_e_court_side_0","market_e_court_side_1","market_e_court_side_2","market_e_court_side_3","market_b_book_rear_wall_e","goods_stall","medicine_stall"]
const ADD_IDS = ["market_g_cloth_gallery","market_g_medicine_gallery"]

static func v(raw: Variant) -> Vector2:
	if raw is Vector2:
		return raw
	if raw is Array and raw.size()==2 and (raw[0] is int or raw[0] is float) and (raw[1] is int or raw[1] is float):
		return Vector2(raw[0],raw[1])
	return Vector2(INF,INF)

static func poly(raw: Variant) -> PackedVector2Array:
	var result := PackedVector2Array()
	if not raw is Array and not raw is PackedVector2Array:
		return result
	for entry: Variant in raw:
		var point: Vector2 = v(entry)
		if not point.is_finite():
			return PackedVector2Array()
		result.append(point)
	return result

static func find(rows: Array,id: String) -> Dictionary:
	var found: Dictionary = {}
	for raw: Variant in rows:
		if not raw is Dictionary:
			return {}
		if String(raw.get("id",""))==id:
			if not found.is_empty():
				return {}
			found=raw
	return found

static func solids(asset: Dictionary,foot: Vector2,scale_value: float) -> Array:
	var result: Array = []
	for raw: Variant in asset.get("ground_solid_polygons_px",[]):
		var source: PackedVector2Array = poly(raw)
		if source.size()<3:
			return []
		var shape := PackedVector2Array()
		for point: Vector2 in source:
			shape.append(foot+(point-v(asset.source_ground_anchor_px))*scale_value)
		if Geometry2D.triangulate_polygon(shape).is_empty():
			return []
		result.append(shape)
	for raw: Variant in asset.get("ground_solid_rects_xywh_px",[]):
		if not raw is Array or raw.size()!=4:
			return []
		var low := Vector2(raw[0],raw[1])
		var size := Vector2(raw[2],raw[3])
		if not low.is_finite() or not size.is_finite() or size.x<=0 or size.y<=0:
			return []
		var high: Vector2 = low+size
		var shape := PackedVector2Array()
		for point: Vector2 in PackedVector2Array([low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)]):
			shape.append(foot+(point-v(asset.source_ground_anchor_px))*scale_value)
		result.append(shape)
	return result

static func row_for(asset: Dictionary,placement: Dictionary,old: Dictionary) -> Dictionary:
	var foot: Vector2 = v(placement.get("foot_px"))
	var source_size: Vector2 = v(asset.get("source_size_px"))
	var anchor: Vector2 = v(asset.get("source_ground_anchor_px"))
	var scale_value: float = float(placement.get("scale",0.0))
	if not foot.is_finite() or not source_size.is_finite() or not anchor.is_finite() or scale_value<=0:
		return {}
	var ground: Array = solids(asset,foot,scale_value)
	if ground.is_empty():
		return {}
	var result: Dictionary = old.duplicate(true)
	result.id=placement.id
	result.texture=asset.texture
	result.source=asset.texture
	result.source_sha256=asset.source_sha256
	result.source_size_px=source_size
	result.foot_uv=anchor/source_size
	result.pos=(foot+(source_size*.5-anchor)*scale_value)/SIZE
	result.render_size_px=source_size*scale_value
	result.centered=true
	result.sort_by_feet=true
	result.depth_sort_foot_y=foot.y/SIZE.y
	result.depth_foot_y=foot.y
	result.world_foot_px=foot
	result.physical_center_px=foot
	result.collision_size_px=Vector2.ZERO
	result.city_v3_solid_polygons_px=ground
	result.blocking=true
	result.walk_support=false
	result.ghost_occlusion=true
	result.district_life_fade=false
	result.market_25g_purpose=placement.purpose
	result.market_25g_height_behavior=asset.get("height_behavior","OPAQUE_ACTOR_LOCAL_GHOST")
	result.market_25g_no_portal=true
	return result

static func project(author: Dictionary,parent43: Array) -> Dictionary:
	if author.get("scene_id")!=SCENE_ID or parent43.size()!=43 or author.get("changes",[]).size()!=7 or author.get("additions",[]).size()!=2:
		return {}
	var ids: Dictionary = {}
	for raw: Variant in parent43:
		if not raw is Dictionary or String(raw.get("id","")).is_empty() or ids.has(String(raw.id)):
			return {}
		ids[String(raw.id)]=true
	var result: Array = parent43.duplicate(true)
	var old_rows: Array = []
	var changed: Array = []
	for index: int in range(7):
		var placement: Dictionary = author.changes[index]
		if String(placement.get("id",""))!=CHANGE_IDS[index]:
			return {}
		var old: Dictionary = find(parent43,placement.id)
		if old.is_empty() or v(old.get("world_foot_px"))!=v(placement.old_foot_px):
			return {}
		var asset: Dictionary = author.assets.get(placement.asset_id,{})
		if asset.is_empty():
			return {}
		if placement.has("old_scale"):
			if old.get("texture")!=asset.texture or v(old.get("render_size_px"))!=v(asset.source_size_px)*float(placement.old_scale):
				return {}
		var next: Dictionary = row_for(asset,placement,old)
		if next.is_empty():
			return {}
		old_rows.append(old.duplicate(true))
		changed.append(next.duplicate(true))
		for ordinal: int in range(result.size()):
			if String(result[ordinal].id)==String(placement.id):
				result[ordinal]=next
				break
	var added: Array = []
	for index: int in range(2):
		var placement: Dictionary = author.additions[index]
		if String(placement.get("id",""))!=ADD_IDS[index] or ids.has(String(placement.id)):
			return {}
		var next: Dictionary = row_for(author.assets.get(placement.asset_id,{}),placement,{})
		if next.is_empty():
			return {}
		result.append(next)
		added.append(next.duplicate(true))
	var output: Dictionary = {"ok":true,"render":result,"old_rows":old_rows,"changed":changed,"added":added}
	if result.size()!=45 or var_to_bytes(restore(output))!=var_to_bytes(parent43):
		return {}
	return output

static func restore(projected: Dictionary) -> Array:
	if projected.get("ok")!=true or projected.get("render",[]).size()!=45 or projected.get("old_rows",[]).size()!=7 or projected.get("changed",[]).size()!=7 or projected.get("added",[]).size()!=2:
		return []
	var result: Array = projected.render.duplicate(true)
	for row: Dictionary in projected.added:
		var actual: Dictionary = find(result,row.id)
		if actual.is_empty() or var_to_bytes(actual)!=var_to_bytes(row):
			return []
		for index: int in range(result.size()):
			if String(result[index].id)==String(row.id):
				result.remove_at(index)
				break
	for ordinal: int in range(7):
		var row: Dictionary = projected.changed[ordinal]
		var actual: Dictionary = find(result,row.id)
		if actual.is_empty() or var_to_bytes(actual)!=var_to_bytes(row):
			return []
		for index: int in range(result.size()):
			if String(result[index].id)==String(row.id):
				result[index]=projected.old_rows[ordinal].duplicate(true)
				break
	return result

static func primitives(rows: Array) -> Array:
	var result: Array = []
	for row: Dictionary in rows:
		if row.get("blocking",false)!=true:
			continue
		var shapes: Variant = row.get("city_v3_solid_polygons_px",[])
		if not shapes is Array:
			return []
		if not shapes.is_empty():
			for index: int in range(shapes.size()):
				var shape: PackedVector2Array = poly(shapes[index])
				if shape.size()<3:
					return []
				result.append({"id":String(row.id)+"_poly_"+str(index),"owner_id":row.id,"kind":"POLYGON","points_px":shape})
		else:
			var size: Vector2 = v(row.get("collision_size_px",[0,0]))
			if not size.is_finite():
				return []
			if size.x>0 and size.y>0:
				var center: Vector2 = v(row.get("physical_center_px",row.get("world_foot_px")))
				var low: Vector2 = center-size*.5
				var high: Vector2 = low+size
				result.append({"id":String(row.id)+"_rect","owner_id":row.id,"kind":"CLOSED_RECT","points_px":PackedVector2Array([low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)])})
	return result

static func domains(projected: Dictionary) -> Array:
	var merged: Array[Rect2i] = []
	for row: Dictionary in projected.old_rows+projected.changed+projected.added:
		for entry: Dictionary in primitives([row]):
			var low := Vector2(INF,INF)
			var high := Vector2(-INF,-INF)
			for point: Vector2 in entry.points_px:
				low=low.min(point)
				high=high.max(point)
			var current := Rect2i(floori(low.x)-1,floori(low.y)-1,ceili(high.x)-floori(low.x)+3,ceili(high.y)-floori(low.y)+3).intersection(Rect2i(0,0,3072,2048))
			var again: bool = true
			while again:
				again=false
				for index: int in range(merged.size()):
					if current.position.x<=merged[index].end.x and current.end.x>=merged[index].position.x and current.position.y<=merged[index].end.y and current.end.y>=merged[index].position.y:
						current=current.merge(merged[index])
						merged.remove_at(index)
						again=true
						break
			merged.append(current)
	return merged
