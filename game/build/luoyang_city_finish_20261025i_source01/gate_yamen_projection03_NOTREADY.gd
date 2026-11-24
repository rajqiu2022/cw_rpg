extends RefCounted
# Pure source transform. The ROOT-extracted old typed seed is not a new expected result.
const SIZE: Vector2 = Vector2(3072,2048)
const AUTHOR_PATH: String = "res://build/luoyang_city_finish_20261025i_source01/author_gate_yamen_axis03_exact_domains_NOTREADY.json"
const AUTHOR_SHA: String = "0652fabb2ec0ca6a9c40fa0b96ec366f2422f7f77d15386811acc4204eff9785"
const LIBRARY_PATH: String = "res://build/luoyang_city_finish_20261025i_source01/reuse_asset_library01_SOURCE_ONLY.json"
const LIBRARY_SHA: String = "17217d76c081e3a53a3b7c13c02f075c216c6a36ec8d8304c66f4f1f4df2ae9d"

static func v(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size()==2: return Vector2(float(value[0]),float(value[1]))
	return Vector2(INF,INF)

static func digest(value: Variant) -> String:
	var ctx: HashingContext=HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256);ctx.update(var_to_bytes(value))
	return ctx.finish().hex_encode()

static func poly(value: Variant) -> PackedVector2Array:
	var result: PackedVector2Array=PackedVector2Array()
	if not value is Array and not value is PackedVector2Array: return result
	for point: Variant in value:
		var p: Vector2=v(point)
		if not p.is_finite(): return PackedVector2Array()
		result.append(p)
	return result

static func _ids(rows: Array) -> Array:
	var result: Array=[]
	for row: Dictionary in rows: result.append(String(row.id))
	return result

static func _translated(row: Dictionary, move: Dictionary) -> Dictionary:
	if v(row.get("world_foot_px",[]))!=v(move.old_foot_px): return {}
	var delta: Vector2=v(move.new_foot_px)-v(move.old_foot_px)
	var result: Dictionary=row.duplicate(true)
	result.pos=v(row.pos)+delta/SIZE
	result.world_foot_px=[float(v(move.new_foot_px).x),float(v(move.new_foot_px).y)]
	result.physical_center_px=[float(v(row.physical_center_px).x+delta.x),float(v(row.physical_center_px).y+delta.y)]
	result.depth_sort_foot_y=float(v(move.new_foot_px).y)/SIZE.y
	if result.has("depth_foot_y"): result.depth_foot_y=float(v(move.new_foot_px).y)
	var polygons: Array=[]
	for raw: Variant in row.get("city_v3_solid_polygons_px",[]):
		var points: PackedVector2Array=poly(raw)
		if points.size()<3: return {}
		for i: int in range(points.size()): points[i]=points[i]+delta
		polygons.append(points)
	result.city_v3_solid_polygons_px=polygons
	return result

static func _asset_row(placement: Dictionary,asset: Dictionary) -> Dictionary:
	var foot: Vector2=v(placement.foot_px)
	var size: Vector2=v(asset.source_size_px)*float(placement.scale)
	var anchor: Vector2=v(asset.source_ground_anchor_px)
	if not foot.is_finite() or not size.is_finite() or not anchor.is_finite() or size.x<=0 or size.y<=0: return {}
	var center: Vector2=foot+(v(asset.source_size_px)*0.5-anchor)*float(placement.scale)
	var polygons: Array=[]
	for raw: Variant in placement.source_derived_new_ground_polygons_f32:
		var points: PackedVector2Array=poly(raw)
		if points.size()<3: return {}
		polygons.append(points)
	return {"id":String(placement.id),"texture":String(asset.texture),"source_sha256":String(asset.source_sha256),
	 "pos":center/SIZE,"render_size_px":size,"centered":true,"sort_by_feet":true,
	 "depth_sort_foot_y":foot.y/SIZE.y,"world_foot_px":[float(foot.x),float(foot.y)],
	 "physical_center_px":[float(foot.x),float(foot.y)],"collision_size_px":[0.0,0.0],
	 "city_v3_solid_polygons_px":polygons,"blocking":true,"finish_i_asset_id":String(placement.asset_id),
	 "finish_i_closed_external_only":true,"district_life_fade":false}

static func derive(scene_id: String, author: Dictionary, library: Dictionary, old_seed: Dictionary) -> Dictionary:
	var spec: Dictionary={}
	for row: Dictionary in author.get("scenes",[]):
		if String(row.scene_id)==scene_id:
			if not spec.is_empty(): return {}
			spec=row
	if spec.is_empty() or not old_seed.has(scene_id): return {}
	var parent: Dictionary=old_seed[scene_id]
	var old_render: Array=parent.effective_parent_render
	var old_primitives: Array=parent.render_primitive_rows
	if digest([parent.native_record_objects,old_render,old_primitives])!=String(spec.parent_record_and_render_body_bytes_sha256): return {}
	if old_render.size()!=int(spec.parent_render_count) or old_primitives.size()!=int(spec.parent_primitive_count): return {}
	if _ids(old_render)!=spec.parent_ordered_render_ids: return {}
	var moves: Dictionary={}
	for row: Dictionary in spec.get("object_migrations",[]):
		if moves.has(String(row.id)): return {}
		moves[String(row.id)]=row
	var retired: Array=spec.get("retire_exact_visual_ids",[])
	var result: Array=[]
	for row: Dictionary in old_render:
		var id: String=String(row.id)
		if retired.has(id): continue
		if moves.has(id):
			var changed: Dictionary=_translated(row,moves[id])
			if changed.is_empty(): return {}
			result.append(changed)
		else: result.append(row.duplicate(true))
	for placement: Dictionary in spec.placements:
		if _ids(result).has(String(placement.id)) or not library.assets.has(String(placement.asset_id)): return {}
		var added: Dictionary=_asset_row(placement,library.assets[String(placement.asset_id)])
		if added.is_empty(): return {}
		result.append(added)
	if _ids(result)!=spec.new_ordered_render_ids or result.size()!=int(spec.new_render_count): return {}
	var new_ground: Array=[]
	for row: Dictionary in spec.new_all_primitive_rows_source_model:
		var points: PackedVector2Array=poly(row.points_px)
		if points.size()<3: return {}
		new_ground.append(points)
	if new_ground.size()!=int(spec.new_primitive_count): return {}
	# Assert derived render bodies equal the source-declared primitive sequence, never copy packet.solids.
	var derived: Array=[]
	for row: Dictionary in result:
		for raw: Variant in row.get("city_v3_solid_polygons_px",[]): derived.append(poly(raw))
		var rect_size: Vector2=v(row.get("collision_size_px",[0,0]))
		if rect_size.x>0 and rect_size.y>0:
			var low: Vector2=v(row.physical_center_px)-rect_size*0.5
			var high: Vector2=low+rect_size
			derived.append(PackedVector2Array([low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)]))
	if digest(derived)!=digest(new_ground): return {}
	return {"ok":true,"scene_id":scene_id,"render_objects":result,"combined_ground":new_ground,
	 "local_domains_xyxy":spec.local_closed_integer_domains_xyxy,"parent_render":old_render.duplicate(true),
	 "parent_primitives":old_primitives.duplicate(true),"source_model_only_not_runtime_lease":true}

static func restore_render(scene_id: String,author: Dictionary,library: Dictionary,old_seed: Dictionary,child: Array) -> Array:
	var result: Dictionary=derive(scene_id,author,library,old_seed)
	if result.is_empty() or digest(result.render_objects)!=digest(child): return []
	return result.parent_render.duplicate(true)
