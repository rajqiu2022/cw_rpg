extends RefCounted
# Pure source rows for authoring overview/publication. RAW new modules stay BUILD-only.
const SIZE: Vector2=Vector2(3072,2048)
static func v(raw: Variant) -> Vector2:
	if raw is Vector2: return raw
	if raw is Array and raw.size()==2: return Vector2(float(raw[0]),float(raw[1]))
	return Vector2(INF,INF)
static func packed(raw: Variant) -> PackedVector2Array:
	var out: PackedVector2Array=PackedVector2Array()
	if not raw is Array and not raw is PackedVector2Array: return out
	for point: Variant in raw:
		var p: Vector2=v(point)
		if not p.is_finite(): return PackedVector2Array()
		out.append(p)
	return out
static func body_polygons(asset: Dictionary,foot: Vector2,ratio: float) -> Array:
	var result: Array=[]
	for rect: Array in asset.get("solid_rects",[]):
		var low: Vector2=foot+(Vector2(float(rect[0]),float(rect[1]))-v(asset.ground_anchor))*ratio
		var hi: Vector2=low+Vector2(float(rect[2]),float(rect[3]))*ratio
		var out: PackedVector2Array=PackedVector2Array()
		for p: Vector2 in PackedVector2Array([low,Vector2(hi.x,low.y),hi,Vector2(low.x,hi.y)]): out.append(p)
		result.append(out)
	for raw: Variant in asset.get("solid_polygons",[]):
		var out: PackedVector2Array=PackedVector2Array()
		for p: Vector2 in packed(raw): out.append(foot+(p-v(asset.ground_anchor))*ratio)
		result.append(out)
	return result
static func render_row(id: String,asset: Dictionary,foot: Vector2,ratio: float,polygons: Array) -> Dictionary:
	var size: Vector2=v(asset.source_size)
	return {"id":id,"texture":String(asset.texture),"pos":(foot+(size*0.5-v(asset.ground_anchor))*ratio)/SIZE,
	 "render_size_px":size*ratio,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y,
	 "world_foot_px":[float(foot.x),float(foot.y)],"physical_center_px":[float(foot.x),float(foot.y)],
	 "collision_size_px":[0.0,0.0],"city_v3_solid_polygons_px":polygons,"blocking":not polygons.is_empty()}
static func derive(a2: Dictionary,life: Dictionary,design: Dictionary) -> Dictionary:
	if a2.get("scenes",[]).size()!=1 or life.get("placements",[]).size()!=4 or design.get("new_asset_lots",[]).size()!=3: return {}
	var old_scene: Dictionary=a2.scenes[0]
	if String(old_scene.scene_id)!="luoyang_artisan_residential_20261022ap" or old_scene.placements.size()!=14: return {}
	var next_scene: Dictionary=old_scene.duplicate(true)
	var migration_ids: Dictionary={}
	for move: Dictionary in design.building_migrations:
		if migration_ids.has(String(move.id)): return {}
		var count: int=0
		for placement: Dictionary in next_scene.placements:
			if String(placement.id)==String(move.id):
				if v(placement.foot)!=v(move.old_foot_px) or String(placement.asset)!=String(move.asset_id) or float(placement.width)!=float(move.old_A1_width_px): return {}
				placement.foot=move.new_foot_px.duplicate();placement.width=move.new_A1_width_px;count+=1
		if count!=1: return {}
		migration_ids[String(move.id)]=true
	if migration_ids.size()!=5: return {}
	for move: Dictionary in design.same_room_migrations:
		var count: int=0
		for portal: Dictionary in next_scene.portals:
			if String(portal.target_scene)==String(move.room_id):
				if v(portal.foot)!=v(move.old_portal_foot_px): return {}
				portal.foot=move.new_portal_foot_px.duplicate();count+=1
		if count!=1: return {}
	next_scene.portals.append({"id":design.new_public_portal.id,"foot":design.new_public_portal.source_foot_px.duplicate(),"target_scene":design.new_public_portal.target,"target_foot":design.new_public_portal.target_foot_px.duplicate(),"label":"Yamen west public branch"})
	var render: Array=[];var old_ground: Array=[];var new_ground: Array=[]
	for i: int in range(next_scene.placements.size()):
		var placement: Dictionary=next_scene.placements[i];var old: Dictionary=old_scene.placements[i]
		var asset: Dictionary=a2.assets.get(String(placement.asset),{})
		if asset.is_empty() or float(asset.used_rect[2])<=0: return {}
		var ratio: float=float(placement.width)/float(asset.used_rect[2])
		var polygons: Array=body_polygons(asset,v(placement.foot),ratio)
		old_ground.append_array(body_polygons(asset,v(old.foot),float(old.width)/float(asset.used_rect[2])))
		new_ground.append_array(polygons)
		render.append(render_row(String(placement.id),asset,v(placement.foot),ratio,polygons))
	if old_ground.size()!=27 or new_ground.size()!=27: return {}
	for placement: Dictionary in life.placements:
		var foot: Vector2=v(placement.foot_px);var ratio: float=float(placement.uniform_scale)
		var polygons: Array=[]
		for raw: Variant in placement.source_ground_solid_polygons_px:
			var out: PackedVector2Array=PackedVector2Array()
			for p: Vector2 in packed(raw): out.append(foot+(p-v(placement.source_ground_anchor_px))*ratio)
			polygons.append(out)
		old_ground.append_array(polygons);new_ground.append_array(polygons)
		var asset: Dictionary={"texture":placement.texture,"source_size":placement.source_size_px,"ground_anchor":placement.source_ground_anchor_px}
		render.append(render_row(String(placement.id),asset,foot,ratio,polygons))
	if old_ground.size()!=31 or new_ground.size()!=31: return {}
	for lot: Dictionary in design.new_asset_lots:
		var measurement: Dictionary=lot.source_asset_measured_raw
		var ratio: float=float(lot.uniform_source_expression.numerator)/float(lot.uniform_source_expression.denominator)
		var foot: Vector2=v(lot.foot_px)
		var polygons: Array=[]
		for row: Dictionary in lot.new_ground_primitive_rows_f32: polygons.append(packed(row.points_world_f32))
		new_ground.append_array(polygons)
		var asset: Dictionary={"texture":"RAW_EXTERNAL_ONLY:"+String(measurement.raw_path),"source_size":measurement.raw_size,"ground_anchor":measurement.manual_threshold_front_anchor_raw}
		var row: Dictionary=render_row(String(lot.asset_id),asset,foot,ratio,polygons)
		row["raw_external_path"]=measurement.raw_path;row["raw_sha256"]=measurement.raw_sha256
		row["raw_BUILD_only_not_clean_imported_or_runtime_bound"]=true
		render.append(row)
	if new_ground.size()!=44 or render.size()!=21 or next_scene.portals.size()!=5: return {}
	# The 118 ground tiles are inherited whole from the current native layout;
	# this array intentionally contains only 18+3 actual sprites, not fake full136.
	return {"ok":true,"scene_source":next_scene,"building_and_life_render":render,"old_ground31":old_ground,
	 "new_ground44":new_ground,"inherited_ground_tile_count":118,"expected_full_visual_count":139,
	 "raw_3_BUILD_only":true,"old132_or136_native_not_rebuilt":true}
