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
	if item.has("solid_polygons_px"):
		item.solid_polygons_px=translate_polys(item.solid_polygons_px,delta)
		if item.solid_polygons_px.is_empty(): return {}
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
static func audit(record: Dictionary,mask: Image,author: Dictionary,delta: Array[PackedVector2Array],crowd_routes: Array) -> Dictionary:
	var solids: Array[PackedVector2Array]=c().object_solids(record.objects)
	solids.append_array(delta)
	var spec: Dictionary=author.districts[String(record.canonical_scene_id)]
	var paths: Array=record.routes.duplicate(true); paths.append_array(crowd_routes)
	for raw: Variant in spec.get("protected_task_feet_px",[]): paths.append({"id":"protected_task","points_px":[raw,raw]})
	for key: String in ["entry_foot_px","return_foot_px"]: paths.append({"id":key,"points_px":[record[key],record[key]]})
	for kind: String in ["interactions","npcs","portals"]:
		for slot: Dictionary in record.gameplay_slots.get(kind,[]):
			var foot: Variant=slot.get("stand_px",slot.get("foot_px"))
			if foot!=null: paths.append({"id":kind+":"+String(slot.get("source_id","")),"points_px":[foot,foot]})
	var samples: int=0
	for route: Dictionary in paths:
		for segment: int in range(route.points_px.size()-1):
			var first: Vector2=v(route.points_px[segment]); var last: Vector2=v(route.points_px[segment+1])
			var steps: int=maxi(1,ceili(first.distance_to(last)/4.0))
			for index: int in range(steps+1):
				var foot: Vector2=first.lerp(last,float(index)/steps)
				if not c()._safe_body_cpu(foot,mask,solids) or not seventeen(foot,mask): return {"passed":false,"route":route.id,"segment":segment,"sample":index,"foot_px":xy(foot),"samples_before_failure":samples}
				if route.get("npc",false):
					if not DISTRICT_GEOMETRY._npc_clear(foot,mask,solids): return {"passed":false,"route":route.id,"foot_px":xy(foot),"error":"NPC_34x30_CONTINUOUS_1085"}
				samples+=1
	return {"passed":true,"samples":samples,"route_count":paths.size(),"full87517":true,"continuous_body_px":[34,24],"npc_body_px":[34,30],"max_step_px":4,"basis":BASIS}
