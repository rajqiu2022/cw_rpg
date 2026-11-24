extends RefCounted
## Pure 24e exact Market projection. No IO/cache/SceneTree/collectors.
const ID="ch4_s3_luoyang_market"
const SIZE=Vector2(3072,2048)
static func v(raw: Variant) -> Vector2:
	return raw if raw is Vector2 else (Vector2(raw[0],raw[1]) if raw is Array and raw.size()==2 else Vector2(INF,INF))
static func poly(raw: Variant) -> PackedVector2Array:
	var out:=PackedVector2Array()
	if not raw is Array and not raw is PackedVector2Array: return out
	for p: Variant in raw:
		var point:=v(p)
		if not point.is_finite(): return PackedVector2Array()
		out.append(point)
	return out
static func bounds(shape: PackedVector2Array) -> Rect2:
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
	for point: Vector2 in shape: low=low.min(point);high=high.max(point)
	return Rect2(low,high-low)
static func find(rows: Array,id: String) -> Dictionary:
	var result: Dictionary={}
	for row: Dictionary in rows:
		if String(row.get("id",""))!=id: continue
		if not result.is_empty(): return {}
		result=row
	return result
static func xy(value: Vector2) -> Array: return [float(value.x),float(value.y)]
static func source_solids(asset: Dictionary,foot: Vector2,scale_value: float) -> Array:
	var result: Array=[]
	for raw: Variant in asset.get("ground_solid_polygons_px",[]):
		var shape:=PackedVector2Array()
		for point: Vector2 in poly(raw): shape.append(foot+(point-v(asset.source_ground_anchor_px))*scale_value)
		if shape.size()<3 or Geometry2D.triangulate_polygon(shape).is_empty(): return []
		result.append(shape)
	return result
static func new_row(asset: Dictionary,placement: Dictionary) -> Dictionary:
	var foot:=v(placement.foot_px);var size:=v(asset.source_size_px);var anchor:=v(asset.source_ground_anchor_px)
	var scale_value: float=float(placement.scale);var solids:=source_solids(asset,foot,scale_value)
	if not foot.is_finite() or scale_value<=0 or solids.is_empty(): return {}
	return {"id":placement.id,"texture":asset.texture,"source":asset.texture,"source_sha256":asset.source_sha256,"source_size_px":size,"foot_uv":anchor/size,"pos":(foot+(size*.5-anchor)*scale_value)/SIZE,"render_size_px":size*scale_value,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y,"depth_foot_y":foot.y,"world_foot_px":foot,"physical_center_px":foot,"collision_size_px":Vector2.ZERO,"city_v3_solid_polygons_px":solids,"blocking":true,"ghost_occlusion":true,"walk_support":false,"market_24e_purpose":placement.get("purpose","closed service court"),"market_24e_no_portal":true}
static func move_row(row: Dictionary,old: Vector2,next: Vector2) -> Dictionary:
	if v(row.get("world_foot_px"))!=old: return {}
	var result: Dictionary=row.duplicate(true);var delta: Vector2=next-old
	result.world_foot_px=next
	if result.has("pos"): result.pos=v(result.pos)+delta/SIZE
	if result.has("physical_center_px"): result.physical_center_px=v(result.physical_center_px)+delta
	if result.has("depth_foot_y"): result.depth_foot_y=next.y
	if result.has("depth_sort_foot_y"): result.depth_sort_foot_y=next.y/SIZE.y
	var solids: Array=[]
	for raw: Variant in result.get("city_v3_solid_polygons_px",[]):
		var points:=PackedVector2Array()
		for point: Vector2 in poly(raw): points.append(point+delta)
		solids.append(points)
	if result.has("city_v3_solid_polygons_px"): result.city_v3_solid_polygons_px=solids
	return result
static func district_parent(native_render: Array,prior: Dictionary) -> Array:
	if native_render.size()!=25 or not prior.get("runtime_district",{}).get("placements") is Array: return []
	var result: Array=native_render.duplicate(true)
	for placement: Dictionary in prior.runtime_district.placements:
		var asset: Dictionary=prior.district_assets.get(placement.asset_id,{})
		if asset.is_empty(): return []
		var foot:=v(placement.foot_px);var size:=v(asset.size_px);var anchor:=v(asset.source_ground_anchor_px);var scale_value: float=float(placement.scale)
		var solids: Array=[]
		for raw: Variant in asset.ground_solid_polygons_px:
			var shape: Array=[]
			for point: Vector2 in poly(raw): shape.append(xy(foot+(point-anchor)*scale_value))
			solids.append(shape)
		var entry: Dictionary={"id":placement.id,"texture":asset.texture,"pos":(foot+(size*.5-anchor)*scale_value)/SIZE,"render_size_px":size*scale_value,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y,"world_foot_px":xy(foot),"physical_center_px":xy(foot),"collision_size_px":[0.0,0.0],"city_v3_solid_polygons_px":solids,"blocking":true,"district_life_asset_id":placement.asset_id,"district_life_fade":placement.get("fade",false)}
		if String(placement.get("replaces","")).is_empty():
			if not find(result,placement.id).is_empty(): return []
			result.append(entry)
		else:
			var old:=find(result,placement.id)
			if old.is_empty(): return []
			for key: String in ["texture","pos","render_size_px","centered","sort_by_feet","depth_sort_foot_y","district_life_asset_id","district_life_fade"]: old[key]=entry[key]
			var combined_solids: Array=old.get("city_v3_solid_polygons_px",[]).duplicate(true)
			combined_solids.append_array(entry.city_v3_solid_polygons_px.duplicate(true));old.city_v3_solid_polygons_px=combined_solids
	return result if result.size()==37 else []
static func project(author: Dictionary,before: Array) -> Dictionary:
	if author.get("scene_id")!=ID or before.size()!=37 or author.get("new_components",[]).size()!=6 or author.get("building_changes",[]).size()!=6 or author.get("wall_changes",[]).size()!=4: return {}
	var result: Array=before.duplicate(true);var old_rows: Array=[];var changed: Array=[];var ids: Dictionary={}
	var operations: Array=[]
	for row: Dictionary in author.building_changes: operations.append({"kind":"building","row":row})
	for row: Dictionary in author.wall_changes: operations.append({"kind":"wall","row":row})
	for row: Dictionary in author.native_prop_moves+author.district_moves: operations.append({"kind":"move","row":row})
	for operation: Dictionary in operations:
		var change: Dictionary=operation.row;var id: String=String(change.id)
		if ids.has(id): return {}
		ids[id]=true
		var old:=find(result,id)
		if old.is_empty() or v(old.get("world_foot_px"))!=v(change.old_foot_px): return {}
		var moved:=move_row(old,v(change.old_foot_px),v(change.foot_px))
		if moved.is_empty(): return {}
		if operation.kind=="building" or operation.kind=="wall":
			var asset: Dictionary=author.assets.get(change.asset_id,{})
			if asset.is_empty() or old.get("texture")!=asset.texture: return {}
			if v(old.get("render_size_px"))!=v(asset.source_size_px)*float(change.old_scale): return {}
			var foot:=v(change.foot_px);var scale_value: float=float(change.scale)
			moved.render_size_px=v(asset.source_size_px)*scale_value
			moved.pos=(foot+(v(asset.source_size_px)*.5-v(asset.source_ground_anchor_px))*scale_value)/SIZE
			if change.get("rebuild_source_plinths",false) or operation.kind=="wall":
				var solids:=source_solids(asset,foot,scale_value)
				if solids.is_empty(): return {}
				moved.city_v3_solid_polygons_px=solids
		old_rows.append(old.duplicate(true));changed.append(moved.duplicate(true))
		for index: int in range(result.size()):
			if String(result[index].id)==id: result[index]=moved;break
	var added: Array=[]
	for placement: Dictionary in author.new_components:
		if ids.has(placement.id) or not find(result,placement.id).is_empty(): return {}
		var row:=new_row(author.assets[placement.asset_id],placement)
		if row.is_empty(): return {}
		ids[placement.id]=true;result.append(row);added.append(row.duplicate(true))
	if result.size()!=43: return {}
	var projected: Dictionary={"ok":true,"render":result,"old_rows":old_rows,"changed":changed,"added":added}
	if var_to_bytes(restore(projected))!=var_to_bytes(before): return {}
	return projected
static func restore(projected: Dictionary) -> Array:
	if projected.get("ok")!=true: return []
	var result: Array=projected.render.duplicate(true)
	for row: Dictionary in projected.added:
		var old:=find(result,row.id)
		if old.is_empty() or var_to_bytes(old)!=var_to_bytes(row): return []
		for index: int in range(result.size()):
			if result[index].id==row.id: result.remove_at(index);break
	for ordinal: int in range(projected.changed.size()):
		var row: Dictionary=projected.changed[ordinal];var old:=find(result,row.id)
		if old.is_empty() or var_to_bytes(old)!=var_to_bytes(row): return []
		for index: int in range(result.size()):
			if result[index].id==row.id: result[index]=projected.old_rows[ordinal].duplicate(true);break
	return result
static func primitives(render: Array) -> Array:
	var result: Array=[]
	for row: Dictionary in render:
		if row.get("blocking",false)!=true: continue
		var polygons: Variant=row.get("city_v3_solid_polygons_px",[])
		if not polygons is Array: return [] # Outer container is fixed Array; inner polygons may be PackedVector2Array.
		if not polygons.is_empty():
			var ordinal: int=0
			for raw: Variant in polygons:
				var shape:=poly(raw)
				if shape.size()<3: return []
				result.append({"id":String(row.id)+"_poly_"+str(ordinal),"owner_id":row.id,"kind":"POLYGON","points_px":shape});ordinal+=1
		else:
			var size:=v(row.get("collision_size_px",[0,0]))
			if size.x<=0 or size.y<=0: continue
			var center:=v(row.get("physical_center_px",row.get("world_foot_px")))
			var low: Vector2=center-size*.5;var high: Vector2=low+size
			result.append({"id":String(row.id)+"_rect","owner_id":row.id,"kind":"PARENT_EXACT_CLOSED_RECT","points_px":PackedVector2Array([low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)])})
	return result
static func domains(projected: Dictionary) -> Array:
	var raw: Array=[]
	for row: Dictionary in projected.old_rows+projected.changed+projected.added:
		for shape: Variant in row.get("city_v3_solid_polygons_px",[]):
			var area:=bounds(poly(shape))
			raw.append(Rect2i(floori(area.position.x)-1,floori(area.position.y)-1,ceili(area.end.x)-floori(area.position.x)+3,ceili(area.end.y)-floori(area.position.y)+3))
		var size:=v(row.get("collision_size_px",[0,0]))
		if size.x>0 and size.y>0:
			var center:=v(row.get("physical_center_px",row.get("world_foot_px")));var low:=center-size*.5;var high:=low+size
			raw.append(Rect2i(floori(low.x)-1,floori(low.y)-1,ceili(high.x)-floori(low.x)+3,ceili(high.y)-floori(low.y)+3))
	var merged: Array=[]
	for rect: Rect2i in raw:
		rect=rect.intersection(Rect2i(0,0,3072,2048))
		if not rect.has_area(): continue
		var current: Rect2i=rect;var again: bool=true
		while again:
			again=false
			for index: int in range(merged.size()):
				if current.position.x<=merged[index].end.x and current.end.x>=merged[index].position.x and current.position.y<=merged[index].end.y and current.end.y>=merged[index].position.y:
					current=current.merge(merged[index]);merged.remove_at(index);again=true;break
		merged.append(current)
	return merged
