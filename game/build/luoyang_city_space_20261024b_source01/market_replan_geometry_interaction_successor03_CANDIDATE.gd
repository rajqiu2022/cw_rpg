extends RefCounted
## Build-only pure geometry/typed record delta. No C/Field, filesystem or cache.
## The separate Root publisher supplies the one pinned current packet and assets.
const ID="ch4_s3_luoyang_market"
const SIZE=Vector2(3072,2048)
const TWO_IDS=["market_northeast_rear_frontage","market_east_ward_frontage"]
const MIN_DOOR_HEIGHT=145.0
const MIN_DOOR_WIDTH=60.0
const WALL_IDS=["market_b_drug_rear_wall_w","market_b_drug_rear_wall_e","market_b_book_rear_wall_w","market_b_book_rear_wall_e"]

static func v(raw: Variant) -> Vector2:
	if raw is Vector2: return raw
	if not raw is Array or raw.size()!=2: return Vector2(INF,INF)
	for x: Variant in raw:
		if typeof(x) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(x)): return Vector2(INF,INF)
	return Vector2(raw[0],raw[1])
static func poly(raw: Variant) -> PackedVector2Array:
	var out:=PackedVector2Array()
	if not raw is Array and not raw is PackedVector2Array: return out
	for point: Variant in raw:
		var p: Vector2=v(point)
		if not p.is_finite(): return PackedVector2Array()
		out.append(p)
	return out
static func bounds(points: PackedVector2Array) -> Rect2:
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
	for point: Vector2 in points: low=low.min(point);high=high.max(point)
	return Rect2(low,high-low)
static func source_world(raw: Variant,anchor: Vector2,foot: Vector2,scale_value: float) -> PackedVector2Array:
	var out:=PackedVector2Array()
	for point: Vector2 in poly(raw): out.append(foot+(point-anchor)*scale_value)
	return out
static func exact_row(rows: Array,id: String) -> Dictionary:
	var result: Dictionary={}
	for row: Dictionary in rows:
		if String(row.get("id",""))!=id: continue
		if not result.is_empty(): return {}
		result=row
	return result

static func building(asset: Dictionary,placement: Dictionary) -> Dictionary:
	# No guessed/current-image measurements or scaling to an arbitrary old box.
	if asset.get("measured_source_geometry_ready")!=true or asset.get("complete_building")!=true or placement.get("id") not in TWO_IDS: return {}
	var size: Vector2=v(asset.get("source_size_px"));var anchor: Vector2=v(asset.get("source_ground_anchor_px"));var foot: Vector2=v(placement.get("foot_px"))
	var scale_value: float=float(placement.get("uniform_scale",0.0))
	if not size.is_finite() or not anchor.is_finite() or not foot.is_finite() or size.x<=0 or size.y<=0 or scale_value<=0 or not is_finite(scale_value): return {}
	if not Rect2(Vector2.ZERO,size).has_point(anchor): return {}
	var alpha: Variant=asset.get("alpha_rect_px")
	if not alpha is Array or alpha.size()!=4: return {}
	var visible:=Rect2(v([alpha[0],alpha[1]]),v([alpha[2],alpha[3]]))
	if not Rect2(Vector2.ZERO,size).encloses(visible) or visible.size.x<=0 or visible.size.y<=0: return {}
	var opaque_world:=Rect2(foot+(visible.position-anchor)*scale_value,visible.size*scale_value)
	var lot_raw: Variant=placement.get("opaque_lot_px")
	if not lot_raw is Array or lot_raw.size()!=4: return {}
	var lot:=Rect2(lot_raw[0],lot_raw[1],lot_raw[2],lot_raw[3])
	if not Rect2(Vector2.ZERO,SIZE).encloses(opaque_world) or not lot.encloses(opaque_world): return {}
	# Root accepted the measured tall ONE-storey bodies: the new book source
	# needs about533px whole height at a145px door; do not mislabel it two-storey.
	var maximum_height: float=480.0 if placement.id==TWO_IDS[0] else 560.0
	if opaque_world.size.y<336.0 or opaque_world.size.y>maximum_height: return {}
	var source_door: PackedVector2Array=poly(asset.get("doorway_clear_source_polygon_px"))
	if source_door.size()<4 or Geometry2D.triangulate_polygon(source_door).is_empty(): return {}
	if float(asset.get("conservative_clear_door_height_source_px",0))*scale_value<MIN_DOOR_HEIGHT or float(asset.get("conservative_clear_door_width_source_px",0))*scale_value<MIN_DOOR_WIDTH: return {}
	var solids: Array=[]
	for raw: Variant in asset.get("ground_solid_polygons_px",[]):
		var points: PackedVector2Array=source_world(raw,anchor,foot,scale_value)
		if points.size()<3 or Geometry2D.triangulate_polygon(points).is_empty(): return {}
		solids.append(points)
	if solids.is_empty(): return {}
	var doorway: PackedVector2Array=source_world(source_door,anchor,foot,scale_value)
	for solid: PackedVector2Array in solids:
		if not Geometry2D.intersect_polygons(doorway,solid).is_empty(): return {}
	var texture: String=String(asset.get("texture",""));var source_sha: String=String(asset.get("source_sha256",""))
	if not texture.begins_with("res://") or ".." in texture or source_sha.length()!=64: return {}
	return {"id":placement.id,"prototype":"building","nature":"complete_single_storey_market_shop_20261024b","texture":texture,"source":texture,"source_sha256":source_sha,"source_size_px":size,"render_size_px":size*scale_value,"foot_uv":anchor/size,"world_foot_px":foot,"physical_center_px":foot,"collision_size_px":Vector2.ZERO,"solid_polygons_px":solids,"blocking":true,"sort_by_feet":true,"depth_foot_y":foot.y,"walk_support":false,"ghost_occlusion":true,"spatial_plan_opaque_rect":opaque_world}

static func render_entry(row: Dictionary) -> Dictionary:
	var entry: Dictionary=row.duplicate(true);var foot: Vector2=v(row.world_foot_px);var size: Vector2=v(row.render_size_px)
	entry.pos=(foot+(Vector2(.5,.5)-v(row.foot_uv))*size)/SIZE;entry.centered=true;entry.depth_sort_foot_y=foot.y/SIZE.y
	entry.city_v3_solid_polygons_px=row.solid_polygons_px.duplicate(true);entry.erase("solid_polygons_px")
	return entry

static func district_solids(author: Dictionary) -> Array[PackedVector2Array]:
	# Exact source assets + whole same-ID placement rows, just the new delta's
	# thirteen existing props. No old whole packet, runtime or source collector.
	var output: Array[PackedVector2Array]=[]
	for placement: Dictionary in author.runtime_district.placements:
		var asset: Dictionary=author.district_assets.get(placement.asset_id,{})
		var foot: Vector2=v(placement.foot_px);var anchor: Vector2=v(asset.get("source_ground_anchor_px"));var scale_value: float=float(placement.scale)
		if asset.is_empty() or not foot.is_finite() or not anchor.is_finite() or not is_finite(scale_value) or scale_value<=0: return []
		for raw: Variant in asset.get("ground_solid_polygons_px",[]):
			var points: PackedVector2Array=source_world(raw,anchor,foot,scale_value)
			if points.size()<3 or Geometry2D.triangulate_polygon(points).is_empty(): return []
			output.append(points)
	return output

static func low_wall(asset: Dictionary,placement: Dictionary) -> Dictionary:
	# Exact existing source panel/base, not a painted fence with no body.
	if placement.get("id") not in WALL_IDS or asset.get("source_sha256")!="664cc0734eb126d8a0a0f591a276d0790d7382de18d18cc310e82e6f9dbb5bd0": return {}
	if v(asset.get("source_size_px"))!=Vector2(640,132) or v(asset.get("source_ground_anchor_px"))!=Vector2(319,124) or float(placement.get("uniform_scale",0))!=.5: return {}
	var declared: Variant=asset.get("ground_solid_polygons_px")
	if not declared is Array or declared.size()!=1 or poly(declared[0])!=PackedVector2Array([Vector2(4,112),Vector2(634,112),Vector2(634,124),Vector2(4,124)]): return {}
	var foot: Vector2=v(placement.get("foot_px"))
	if not foot.is_finite(): return {}
	var solids: Array=[source_world([[4,112],[634,112],[634,124],[4,124]],Vector2(319,124),foot,.5)]
	return {"id":placement.id,"prototype":"wall","nature":"source_preserved_low_courtyard_panel_20261024b","texture":asset.texture,"source":asset.texture,"source_sha256":asset.source_sha256,"source_size_px":Vector2(640,132),"render_size_px":Vector2(320,66),"foot_uv":Vector2(319,124)/Vector2(640,132),"world_foot_px":foot,"physical_center_px":foot-Vector2(0,3),"collision_size_px":Vector2.ZERO,"solid_polygons_px":solids,"blocking":true,"sort_by_feet":true,"depth_foot_y":foot.y,"walk_support":false,"ghost_occlusion":true}
static func move_object(original: Dictionary,old_foot: Vector2,new_foot: Vector2,visual: bool=false) -> Dictionary:
	if v(original.get("world_foot_px"))!=old_foot or not old_foot.is_finite() or not new_foot.is_finite(): return {}
	var out: Dictionary=original.duplicate(true);var delta: Vector2=new_foot-old_foot
	out.world_foot_px=new_foot
	if out.has("physical_center_px"): out.physical_center_px=v(out.physical_center_px)+delta
	if out.has("depth_foot_y"): out.depth_foot_y=new_foot.y
	if out.has("pos"): out.pos=v(out.pos)+delta/SIZE
	if out.has("depth_sort_foot_y"): out.depth_sort_foot_y=new_foot.y/SIZE.y
	var key: String="city_v3_solid_polygons_px" if visual else "solid_polygons_px"
	if out.has(key):
		var translated: Array=[]
		for raw: Variant in out[key]:
			var points:=PackedVector2Array()
			for point: Vector2 in poly(raw): points.append(point+delta)
			translated.append(points)
		out[key]=translated
	return out

static func replace_objects(parent: Array,replacements: Array,moves: Array,visual: bool=false) -> Dictionary:
	var changes: Dictionary={}
	for row: Dictionary in replacements:
		var key: String=String(row.get("id",""))
		if key.is_empty() or changes.has(key) or exact_row(parent,key).is_empty(): return {}
		changes[key]=render_entry(row) if visual else row.duplicate(true)
	for move: Dictionary in moves:
		var key: String=String(move.get("id",""))
		if key.is_empty() or changes.has(key): return {}
		var old: Dictionary=exact_row(parent,key)
		var moved: Dictionary=move_object(old,v(move.get("old_foot_px")),v(move.get("new_foot_px")),visual)
		if moved.is_empty(): return {}
		changes[key]=moved
	var out: Array=[];var inverse: Array=[]
	for row: Dictionary in parent:
		var key: String=String(row.get("id",""))
		out.append(changes[key].duplicate(true) if changes.has(key) else row.duplicate(true))
		if changes.has(key): inverse.append({"ordinal":out.size()-1,"id":key,"old":row.duplicate(true)})
	return {"rows":out,"inverse":inverse,"same_count_and_order":out.size()==parent.size()}

static func restore_rows(child: Array,deltas: Array) -> Array:
	var restored: Array=child.duplicate(true)
	for delta: Dictionary in deltas:
		var ordinal: int=int(delta.ordinal)
		if ordinal<0 or ordinal>=restored.size() or String(restored[ordinal].get("id",""))!=String(delta.id): return []
		restored[ordinal]=delta.old.duplicate(true)
	return restored

static func retire_closed_stalls(rows: Array,ids: Array) -> Dictionary:
	# No general deletion API. These exact two current native copies have no
	# doorway, task object ID or source action; the two real task stalls remain.
	if ids!=["market_west_alley_stall","market_east_alley_stall"]: return {}
	var output: Array=[];var retired: Array=[]
	for i: int in rows.size():
		var row: Dictionary=rows[i];var id: String=String(row.get("id",""))
		if id in ids:
			for key: String in ["interaction_action","action","require_flag","hide_flag","target_scene","target_scene_id"]:
				if row.has(key) and str(row[key])!="": return {}
			retired.append({"ordinal":i,"old":row.duplicate(true)})
		else: output.append(row.duplicate(true))
	if retired.size()!=2: return {}
	return {"rows":output,"retired":retired}

static func exact_point_row_migration(rows: Array,deltas: Array,id_key: String,point_key: String,normalized: bool=false) -> Dictionary:
	# Pure same-ID pos/shape projection. Caller stores full old dictionaries.
	var output: Array=rows.duplicate(true);var inverse: Array=[];var seen: Dictionary={}
	for delta: Dictionary in deltas:
		var id: String=String(delta.get("id",""));var ordinal: int=-1
		if id.is_empty() or seen.has(id): return {}
		seen[id]=true
		for i: int in output.size():
			if String(output[i].get(id_key,""))!=id: continue
			if ordinal!=-1: return {}
			ordinal=i
		if ordinal<0: return {}
		var row: Dictionary=output[ordinal];var before: Vector2=v(delta.get("old_foot_px"));var after: Vector2=v(delta.get("new_foot_px"))
		if delta.has("expected_visual_object_id") and (not normalized or id not in ["paper_birdseal","zhao_medicine_parcel","xuantong_note"] or row.get("visual_object_id")!=delta.expected_visual_object_id): return {}
		if not before.is_finite() or not after.is_finite() or v(row.get(point_key))!=(before/SIZE if normalized else before): return {}
		inverse.append({"ordinal":ordinal,"old":row.duplicate(true)})
		row[point_key]=after/SIZE if normalized else after
		var previous_passage: PackedVector2Array=poly(row.get("passage_path_px",[]))
		for key: String in delta.get("translate_point_fields",[]):
			if key!="arrival_foot_px" or not row.has(key) or v(row[key])!=before: return {}
			row[key]=after
		# Only explicitly listed shape/approach fields are translated. Unknown
		# field names cannot silently retain stale portals/interactions.
		for key: String in delta.get("translate_polygon_fields",[]):
			if key not in ["interaction_polygon_px","city_v3_interaction_polygon_px","passage_path_px","points_px"] or not row.has(key): return {}
			var translated: Variant=row[key].duplicate()
			for i: int in translated.size(): translated[i]=v(translated[i])+after-before
			row[key]=translated
		if delta.has("replace_passage_path_px"):
			if id not in ["enter_market_northeast_rear_frontage_room","enter_market_east_ward_frontage_room"] or previous_passage!=PackedVector2Array([before+Vector2(0,24),before]): return {}
			var passage: PackedVector2Array=poly(delta.replace_passage_path_px)
			if passage.size()!=2 or passage[1]!=after or passage[0].x!=after.x or passage[0].y<=after.y: return {}
			var replacement: Variant=row.passage_path_px.duplicate()
			for i: int in replacement.size(): replacement[i]=passage[i]
			row.passage_path_px=replacement
	return {"rows":output,"inverse_full_dictionaries":inverse,"ids_actions_flags_rewards_unchanged":true}
