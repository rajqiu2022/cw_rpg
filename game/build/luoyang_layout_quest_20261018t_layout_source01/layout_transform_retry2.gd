extends RefCounted
## Pure successor transformation. No C.prepare, no file writes, no runtime cache.
## Caller proves the exact r3 packet/Scene first and captures complete sources.
const SIZE=Vector2(3072,2048)
const BASIS="PARENT_PUBLISHED_PLUS_T_LAYOUT_PROOF"
const META="luoyang_layout_quest_20261018t"
const BUNDLE=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const DISTRICT_GEOMETRY=preload("res://scripts/city/luoyang_district_life_geometry_20261016f.gd")
static func c() -> Variant: return load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
static func v(value: Variant) -> Vector2:
	return value if value is Vector2 else (Vector2(value[0],value[1]) if value is Array and value.size()==2 else Vector2(INF,INF))
static func xy(point: Vector2) -> Array: return [float(point.x),float(point.y)]
static func uv(raw: Array) -> Vector2: return Vector2(float(raw[0])/3072.0,float(raw[1])/2048.0)
static func find(rows: Array,id: String) -> Dictionary:
	var found: Dictionary={}
	for row: Dictionary in rows:
		if String(row.get("id",""))!=id: continue
		if not found.is_empty(): return {}
		found=row
	return found
static func translate_polys(raw: Array,delta: Vector2) -> Array:
	var out: Array=[]
	for polygon: Variant in raw:
		var points: Array=[]
		for point: Variant in polygon: points.append(xy(v(point)+delta))
		if points.size()<3: return []
		out.append(points)
	return out
static func move_record(old: Dictionary,move: Dictionary) -> Dictionary:
	if v(old.get("world_foot_px"))!=v(move.old_foot_px): return {}
	var item: Dictionary=old.duplicate(true)
	var delta: Vector2=v(move.new_foot_px)-v(move.old_foot_px)
	for key: String in ["world_foot_px","physical_center_px","world_origin_px"]:
		if item.has(key): item[key]=xy(v(item[key])+delta)
	if item.has("depth_foot_y"): item.depth_foot_y=float(item.depth_foot_y)+delta.y
	var polygons: Variant=item.get("solid_polygons_px")
	var collision: Vector2=v(item.get("collision_size_px"))
	if item.get("blocking")!=true or not polygons is Array or not collision.is_finite(): return {}
	if move.get("shape_contract")=="POLYGON_TRANSLATION":
		if polygons.is_empty() or collision!=Vector2.ZERO: return {}
		item.solid_polygons_px=translate_polys(polygons,delta)
		if item.solid_polygons_px.is_empty(): return {}
	elif move.get("shape_contract")=="TREE_RECTANGLE_24X18_TRANSLATION":
		# Only the two explicitly authored native rectangular trees. Empty
		# polygons are retained, not replaced by a guessed polygon or no body.
		if String(old.get("id","")) not in ["street_tree_0","street_tree_1"] or not polygons.is_empty() or collision!=Vector2(24,18) or v(move.get("expected_collision_size_px"))!=collision or v(old.get("physical_center_px"))!=v(move.get("expected_old_physical_center_px")) or float(old.get("depth_foot_y",INF))!=float(move.get("expected_old_depth_foot_y",-INF)): return {}
		if v(item.physical_center_px)!=v(move.expected_old_physical_center_px)+delta or float(item.depth_foot_y)!=float(move.new_foot_px[1]): return {}
		item.solid_polygons_px=polygons.duplicate(true)
	else: return {}
	item["t_transform"]={"old_foot_px":move.old_foot_px.duplicate(),"new_foot_px":move.new_foot_px.duplicate(),"delta_px":xy(delta),"parent_native_values_preserved_except_explicit_translation":true}
	return item
static func compose(parent: Dictionary,id: StringName,author: Dictionary,walk: String) -> Dictionary:
	var spec: Dictionary=author.get("districts",{}).get(String(id),{})
	if spec.is_empty() or parent.get("canonical_scene_id")!=String(id) or walk.is_empty(): return {}
	var result: Dictionary=parent.duplicate(true); var objects: Array=[]; var removed: Dictionary={}; var moved: Dictionary={}
	for old: Dictionary in parent.objects:
		var key: String=String(old.id)
		if key in spec.remove_ids:
			if removed.has(key): return {}
			removed[key]=true; continue
		var next: Dictionary=old.duplicate(true)
		for move: Dictionary in spec.moves:
			if move.id!=key: continue
			if moved.has(key): return {}
			next=move_record(old,move); moved[key]=true
		if next.is_empty(): return {}
		objects.append(next)
	if removed.size()!=spec.remove_ids.size() or moved.size()!=spec.moves.size(): return {}
	result.objects=objects; result.walk_path=walk
	var routes: Array=[]; var replaced: Dictionary={}
	for old: Dictionary in parent.routes:
		var route: Dictionary=old.duplicate(true)
		for replacement: Dictionary in spec.route_replacements:
			if replacement.id!=old.id: continue
			replaced[String(old.id)]=true; route.points_px=replacement.points_px.duplicate(true)
			route["t_original_points_px"]=old.points_px.duplicate(true)
		routes.append(route)
	if replaced.size()!=spec.route_replacements.size(): return {}
	routes.append_array(spec.additional_routes.duplicate(true)); result.routes=routes
	if id==&"ch4_s3_luoyang_market":
		for slot: Dictionary in result.gameplay_slots.get("portals",[]):
			for room: Dictionary in author.room_moves:
				if v(slot.get("foot_px"))!=v(room.old_return_foot_px): continue
				slot["t_original_slot"]=slot.duplicate(true)
				slot.foot_px=room.return_foot_px.duplicate(); slot.arrival_foot_px=room.return_foot_px.duplicate()
				slot.passage_path_px=[xy(v(room.return_foot_px)+Vector2(0,24)),room.return_foot_px.duplicate()]
	result["t_geometry_basis"]=BASIS
	return result
static func move_entry(entry: Dictionary,record: Dictionary,move: Dictionary) -> Dictionary:
	var result: Dictionary=entry.duplicate(true)
	var delta: Vector2=v(move.new_foot_px)-v(move.old_foot_px)
	if not result.get("pos") is Vector2: return {}
	result.pos+=delta/SIZE
	# Native Physics consumes these exact arrays; NEVER only move the Sprite.
	result.city_v3_solid_polygons_px=record.get("solid_polygons_px",[]).duplicate(true)
	for key: String in ["world_foot_px","physical_center_px","collision_size_px"]:
		if record.has(key): result[key]=record[key].duplicate(true) if record[key] is Array else record[key]
	if result.has("world_origin_px"): result.world_origin_px=record.world_origin_px.duplicate(true)
	result.depth_sort_foot_y=float(record.depth_foot_y)/SIZE.y
	result["t_transform"]=record.t_transform.duplicate(true)
	return result
static func doorway(foot: Array) -> PackedVector2Array:
	# Match Field normalized->world native float operations, fixed 40x32 only.
	var center: Vector2=uv(foot)*SIZE
	return PackedVector2Array([center+Vector2(-20,-16),center+Vector2(20,-16),center+Vector2(20,16),center+Vector2(-20,16)])
static func district_projection(original: Dictionary,id: StringName,author: Dictionary) -> Dictionary:
	if original.is_empty(): return {}
	var projected: Dictionary=original.duplicate(true)
	for move: Dictionary in author.get("districts",{}).get(String(id),{}).get("crowd_moves",[]):
		var found: int=0
		for person: Dictionary in projected.spec.crowd:
			if person.id!=move.id: continue
			if v(person.foot_px)!=v(move.old_foot_px) or float(person.distance_px)!=float(move.distance_px): return {}
			person.foot_px=move.new_foot_px.duplicate(); found+=1
		if found!=1: return {}
	for relocation: Dictionary in author.get("districts",{}).get(String(id),{}).get("protected_foot_moves",[]):
		if relocation.get("semantic")!="EXISTING_ROOM_DOOR_APPROACH_PLUS_10_WORLD_Y": return {}
		var room: Dictionary={}
		for candidate: Dictionary in author.room_moves:
			if candidate.scene_id==relocation.room_scene_id:
				if not room.is_empty(): return {}
				room=candidate
		if room.is_empty() or v(relocation.old_foot_px)!=v(room.old_return_foot_px)+Vector2(0,10) or v(relocation.new_foot_px)!=v(room.return_foot_px)+Vector2(0,10): return {}
		var count: int=0
		for index: int in projected.spec.protected_feet.size():
			if v(projected.spec.protected_feet[index])==v(relocation.old_foot_px):
				projected.spec.protected_feet[index]=relocation.new_foot_px.duplicate()
				count+=1
		if count!=1: return {}
	return projected
static func materialize(parent: SceneScript,record: Dictionary,author: Dictionary,author_sha: String) -> SceneScript:
	if parent==null or parent.map_layout==null or record.get("t_geometry_basis")!=BASIS: return null
	var spec: Dictionary=author.get("districts",{}).get(String(parent.scene_id),{})
	if spec.is_empty(): return null
	var scene:=parent.duplicate(true) as SceneScript
	scene.map_layout=parent.map_layout.duplicate(true) as WalkableMapLayout
	var entries: Array[Dictionary]=[]
	for old: Dictionary in parent.map_layout.visual_objects:
		if old.get("id") in spec.remove_ids: continue
		var next: Dictionary=old.duplicate(true)
		for move: Dictionary in spec.moves:
			if move.id==old.get("id"): next=move_entry(old,find(record.objects,String(move.id)),move)
		if next.is_empty(): return null
		entries.append(next)
	scene.map_layout.visual_objects=entries; scene.map_layout.walkable_mask_path=record.walk_path
	# Existing seven immutable entry identities remain; only approved door feet
	# move. Three appended bays and hall are handled by the t room facade.
	if parent.scene_id==&"ch4_s3_luoyang_market":
		for portal: Dictionary in scene.map_layout.portals:
			for room: Dictionary in author.room_moves:
				if String(portal.get("target_scene",""))!=room.scene_id: continue
				if portal.get("pos")!=uv(room.old_return_foot_px): return null
				portal.pos=uv(room.return_foot_px); portal.interaction_polygon_px=doorway(room.return_foot_px)
	scene.set_meta(META,author_sha)
	return scene
static func seventeen(foot: Vector2,mask: Image) -> bool:
	return DISTRICT_GEOMETRY._seventeen(foot,mask)
static func audit_reason(foot: Vector2,mask: Image,record: Dictionary,projection: Dictionary,npc: bool) -> Dictionary:
	var half:=Vector2(17,15) if npc else Vector2(17,12)
	var rect:=Rect2(foot-half,half*2)
	var body:=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	var hits: Array=[]
	for object: Dictionary in record.objects:
		for polygon: PackedVector2Array in c().object_solids([object]):
			if not Geometry2D.intersect_polygons(body,polygon).is_empty(): hits.append({"id":object.id,"origin":"record","polygon":var_to_str(polygon)})
	for entry: Dictionary in projection.get("additions",[])+projection.get("replacements",[]):
		for raw: Variant in entry.city_v3_solid_polygons_px:
			var polygon: PackedVector2Array=DISTRICT_GEOMETRY.polygon(raw)
			if not Geometry2D.intersect_polygons(body,polygon).is_empty(): hits.append({"id":entry.id,"origin":"district_delta","polygon":var_to_str(polygon)})
	var bad: Array=[]
	for y: int in range(roundi(rect.position.y),roundi(rect.end.y)+1):
		for x: int in range(roundi(rect.position.x),roundi(rect.end.x)+1):
			if x<0 or y<0 or x>=mask.get_width() or y>=mask.get_height(): bad=[x,y]; break
			var color: Color=mask.get_pixel(x,y)
			if color.a<.5 or color.r<.5: bad=[x,y]; break
		if not bad.is_empty(): break
	return {"body_rect_native":var_to_str(rect),"solid_hits":hits,"first_bad_rounded_pixel":bad}
static func audit(record: Dictionary,mask: Image,author: Dictionary,delta: Array[PackedVector2Array],crowd_routes: Array,projection: Dictionary={}) -> Dictionary:
	var solids: Array[PackedVector2Array]=c().object_solids(record.objects)
	solids.append_array(delta)
	var spec: Dictionary=author.districts[String(record.canonical_scene_id)]
	var paths: Array=record.routes.duplicate(true); paths.append_array(crowd_routes)
	for index: int in spec.get("protected_task_feet_px",[]).size():
		var task_foot: Variant=spec.protected_task_feet_px[index]
		paths.append({"id":"protected_task:"+str(index),"points_px":[task_foot,task_foot]})
	for key: String in ["entry_foot_px","return_foot_px"]: paths.append({"id":key,"points_px":[record[key],record[key]]})
	for kind: String in ["interactions","npcs","portals"]:
		var ordinal: int=0
		for slot: Dictionary in record.gameplay_slots.get(kind,[]):
			var label: String=kind+":"+String(slot.get("source_id",slot.get("id",str(ordinal))))
			var anchor: Variant=slot.get("stand_px",slot.get("foot_px"))
			if anchor!=null: paths.append({"id":label,"npc":kind=="npcs","points_px":[anchor,anchor]})
			if slot.has("arrival_foot_px"): paths.append({"id":label+":arrival","points_px":[slot.arrival_foot_px,slot.arrival_foot_px]})
			for path_key: String in ["patrol_path_px","passage_path_px"]:
				var points: Array=slot.get(path_key,[]).duplicate(true)
				if points.size()==1: points.append(points[0])
				if points.size()>1: paths.append({"id":label+":"+path_key,"npc":kind=="npcs","points_px":points})
			ordinal+=1
	if String(record.canonical_scene_id)=="ch4_s3_luoyang_market":
		for room: Dictionary in author.room_moves: paths.append({"id":"successor_return:"+room.scene_id,"points_px":[room.return_foot_px,room.return_foot_px]})
	else:
		var hall_foot: Array=author.official_hall.return_foot_px
		paths.append({"id":"successor_return:"+author.official_hall.scene_id,"points_px":[hall_foot,hall_foot]})
	var samples: int=0; var failures: Array=[]; var route_results: Array=[]
	for route: Dictionary in paths:
		var rejected: bool=false; var checked: int=0
		for segment: int in range(route.points_px.size()-1):
			if rejected: break
			var first: Vector2=v(route.points_px[segment]); var last: Vector2=v(route.points_px[segment+1])
			var steps: int=maxi(1,ceili(first.distance_to(last)/4.0))
			for index: int in range(steps+1):
				var foot: Vector2=first.lerp(last,float(index)/steps)
				var player_ok: bool=c()._safe_body_cpu(foot,mask,solids)
				var seventeen_ok: bool=seventeen(foot,mask)
				var npc_ok: bool=DISTRICT_GEOMETRY._npc_clear(foot,mask,solids) if route.get("npc",false) else true
				samples+=1; checked+=1
				if player_ok and seventeen_ok and npc_ok: continue
				failures.append({"route":route.id,"segment":segment,"sample":index,"steps":steps,"foot_px":xy(foot),"player_full875":player_ok,"seventeen":seventeen_ok,"npc_full1085_continuous":npc_ok,"reason":audit_reason(foot,mask,record,projection,not npc_ok)})
				rejected=true; break
		route_results.append({"id":route.id,"passed":not rejected,"checked_samples":checked})
	return {"passed":failures.is_empty(),"samples":samples,"route_count":paths.size(),"route_results":route_results,"failures":failures,"all_routes_aggregated":true,"full87517":true,"continuous_body_px":[34,24],"npc_body_px":[34,30],"max_step_px":4,"basis":BASIS}
