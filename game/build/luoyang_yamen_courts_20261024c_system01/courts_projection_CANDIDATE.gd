extends RefCounted
## Pure exact two-row projection. Caller owns sameScene/source-FIRST/session admission.
## Never changes the frozen native record, global DG author, or any object node.
const ID="ch4_s1_luoyang_yamen"
const IDS=["assembled_west_service_annex","assembled_east_service_annex"]
const SIZE=Vector2(3072,2048)
static func v(raw: Variant) -> Vector2:
	return raw if raw is Vector2 else (Vector2(raw[0],raw[1]) if raw is Array and raw.size()==2 else Vector2(INF,INF))
static func poly(raw: Variant) -> PackedVector2Array:
	var out:=PackedVector2Array()
	if not raw is Array and not raw is PackedVector2Array: return out
	for point: Variant in raw:
		var value:=v(point)
		if not value.is_finite(): return PackedVector2Array()
		out.append(value)
	return out
static func same_poly(a: Variant,b: Variant) -> bool:
	var left:=poly(a);var right:=poly(b)
	return left.size()>=3 and var_to_bytes(left)==var_to_bytes(right)
static func find(rows: Array,id: String) -> Dictionary:
	var found: Dictionary={}
	for row: Variant in rows:
		if not row is Dictionary: return {}
		if String(row.get("id",""))==id:
			if not found.is_empty(): return {}
			found=row
	return found
static func derive(author: Dictionary) -> Dictionary:
	if author.get("scene_id")!=ID or author.get("combined_count_before")!=42 or author.get("combined_count_after")!=40 or not author.get("original_combined_geometry") is Array or author.original_combined_geometry.size()!=42 or not author.get("annex_changes") is Array or author.annex_changes.size()!=2: return {}
	var before: Array=author.original_combined_geometry
	var retired: Array=[];var fresh: Array=[];var native_before: Array=[]
	for row: Dictionary in before:
		if String(row.get("kind",""))!="ADDITIVE_NATIVE_BASE": native_before.append(row.duplicate(true))
	if native_before.size()!=32: return {}
	for index: int in range(2):
		var id: String=IDS[index];var change: Dictionary=author.annex_changes[index]
		if change.get("id")!=id or float(change.get("new_uniform_scale",0))!=.5: return {}
		for key: String in [id+"_poly_0","district_"+id+"_0"]:
			var old:=find(before,key)
			if old.is_empty() or not same_poly(old.get("points_px"),old.get("points_px")): return {}
			retired.append(key)
		var points: Array=[]
		var foot:=v(change.new_foot_px);var anchor:=v(author.asset.source_ground_anchor_px)
		for point: Vector2 in poly(author.asset.ground_solid_polygons_px[0]):
			var result: Vector2=foot+(point-anchor)*.5
			points.append([float(result.x),float(result.y)])
		if not same_poly(points,change.new_primitive.points_px): return {}
		fresh.append(change.new_primitive.duplicate(true))
	if retired!=author.retired_primitive_ids: return {}
	var combined: Array=[];var native: Array=[]
	for row: Dictionary in before:
		if String(row.id) not in retired: combined.append(row.duplicate(true))
	for row: Dictionary in native_before:
		if String(row.id) not in retired: native.append(row.duplicate(true))
	combined.append_array(fresh.duplicate(true));native.append_array(fresh.duplicate(true))
	if combined.size()!=40 or native.size()!=32: return {}
	for index: int in range(40):
		if combined[index].id!=author.new_combined_geometry[index].id or not same_poly(combined[index].points_px,author.new_combined_geometry[index].points_px): return {}
	return {"ok":true,"combined":combined,"native_before":native_before,"native_after":native,"retired_ids":retired,"fresh":fresh}
static func project_render(author: Dictionary,old_render: Array) -> Dictionary:
	var geometry:=derive(author)
	if geometry.is_empty(): return {}
	var result: Array=old_render.duplicate(true);var old_rows: Array=[];var changed: Array=[]
	for index: int in range(2):
		var id: String=IDS[index];var entry:=find(result,id);var change: Dictionary=author.annex_changes[index]
		if entry.is_empty() or entry.get("texture")!=author.asset.texture or entry.get("district_life_asset_id")!=author.asset.id or not entry.get("city_v3_solid_polygons_px") is Array or entry.city_v3_solid_polygons_px.size()!=2: return {}
		if v(entry.get("pos"))!=v(change.render_fields_before.pos) or v(entry.get("render_size_px"))!=v(change.render_fields_before.render_size_px): return {}
		var old_native:=find(author.original_combined_geometry,id+"_poly_0")
		var old_dg:=find(author.original_combined_geometry,"district_"+id+"_0")
		if not same_poly(entry.city_v3_solid_polygons_px[0],old_native.points_px) or not same_poly(entry.city_v3_solid_polygons_px[1],old_dg.points_px): return {}
		old_rows.append(entry.duplicate(true))
		var foot:=v(change.new_foot_px);var size:=v(author.asset.size_px);var anchor:=v(author.asset.source_ground_anchor_px)
		entry.pos=(foot+(size*.5-anchor)*.5)/SIZE
		entry.render_size_px=size*.5
		entry.world_foot_px=[float(foot.x),float(foot.y)]
		entry.physical_center_px=entry.world_foot_px.duplicate()
		entry.depth_foot_y=float(foot.y)
		entry.depth_sort_foot_y=foot.y/SIZE.y
		entry.city_v3_solid_polygons_px=[change.new_primitive.points_px.duplicate(true)]
		changed.append(entry.duplicate(true))
	return {"ok":true,"render":result,"geometry":geometry,"old_rows":old_rows,"new_rows":changed,"render_count_unchanged":result.size()==old_render.size(),"only_two_existing_IDs":true}
static func restore_render(projected: Dictionary) -> Array:
	if projected.get("ok")!=true or projected.get("old_rows",[]).size()!=2 or projected.get("new_rows",[]).size()!=2: return []
	var result: Array=projected.render.duplicate(true)
	for index: int in range(2):
		var id: String=IDS[index];var hits: int=0
		for ordinal: int in range(result.size()):
			if String(result[ordinal].get("id",""))!=id: continue
			if var_to_bytes(result[ordinal])!=var_to_bytes(projected.new_rows[index]): return []
			result[ordinal]=projected.old_rows[index].duplicate(true);hits+=1
		if hits!=1: return []
	return result
