extends RefCounted
## NEW candidate layout author. The caller supplies the completely proven
## parent record; explicit object transforms never mutate that parent or proof.
const AUTHOR_PATH := "res://data/maps/luoyang_city_assembled_20261016b/author.json"
const AUTHOR_SHA := "70baf04e38c74bb9402e80ee750e797ea8807e323c9c6e9a38157cb17232aac4"
const META := "city_assembled_author_sha_20261016b"
const IDS := [&"ch4_s1_luoyang_yamen",&"ch4_s3_luoyang_market"]

static func _v(value: Variant) -> Vector2:
	return Vector2(value[0],value[1]) if value is Array and value.size()==2 else Vector2(INF,INF)
static func _xy(value: Vector2) -> Array: return [float(value.x),float(value.y)]

static func author() -> Dictionary:
	if FileAccess.get_sha256(AUTHOR_PATH)!=AUTHOR_SHA: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR_PATH))
	if not value is Dictionary or value.get("schema_version")!=1 or value.get("status")!="LAYOUT_CANDIDATE_NOT_PUBLISHED" or value.get("scenes",[]).size()!=2: return {}
	for path: String in value.get("source_sha256",{}):
		if not path.begins_with("res://") or ".." in path or FileAccess.get_sha256(path)!=value.source_sha256[path]: return {}
	return value

static func spec_for(data: Dictionary,id: StringName) -> Dictionary:
	for spec: Dictionary in data.get("scenes",[]):
		if String(spec.get("scene_id",""))==String(id): return spec
	return {}

static func _find(items: Array,id: String) -> Dictionary:
	var found: Dictionary={}
	for item: Dictionary in items:
		if item.get("id")==id:
			if not found.is_empty(): return {}
			found=item
	return found

static func _slot(items: Array,id: String) -> Dictionary:
	var found: Dictionary={}
	for item: Dictionary in items:
		if item.get("source_id")==id:
			if not found.is_empty(): return {}
			found=item
	return found

static func _transform(source: Dictionary,new_id: String,foot: Vector2,ratio: float) -> Dictionary:
	if source.is_empty() or not foot.is_finite() or not is_finite(ratio) or ratio<=0: return {}
	var old:=_v(source.get("world_foot_px"))
	if not old.is_finite(): return {}
	var out:=source.duplicate(true)
	for key: String in ["world_foot_px","physical_center_px","world_origin_px"]:
		if out.has(key): out[key]=_xy(foot+(_v(source[key])-old)*ratio)
	for key: String in ["render_size_px","collision_size_px"]:
		if out.has(key): out[key]=_xy(_v(source[key])*ratio)
	var solids: Array=[]
	for polygon: Array in source.get("solid_polygons_px",[]):
		var transformed: Array=[]
		for point: Variant in polygon: transformed.append(_xy(foot+(_v(point)-old)*ratio))
		solids.append(transformed)
	out.solid_polygons_px=solids; out.id=new_id; out.depth_foot_y=float(foot.y)
	out["assembled_transform_20261016b"]={"source_id":source.id,"old_foot_px":_xy(old),"new_foot_px":_xy(foot),"scale":ratio}
	return out

static func compose(parent: Dictionary,spec: Dictionary,donors: Dictionary) -> Dictionary:
	if spec.is_empty() or StringName(spec.get("scene_id","")) not in IDS or parent.get("canonical_scene_id")!=spec.scene_id or not parent.get("objects") is Array: return {}
	for key: String in spec.parent_identity:
		if parent.get(key)!=spec.parent_identity[key]: return {}
	for protected: Dictionary in spec.protected_objects:
		var item:=_find(parent.objects,protected.id)
		if item.is_empty() or _v(item.world_foot_px)!=_v(protected.foot_px): return {}
	var record:=parent.duplicate(true)
	for move: Dictionary in spec.object_moves:
		var original:=_find(parent.objects,move.id)
		if original.is_empty() or _v(original.world_foot_px)!=_v(move.before_foot_px): return {}
		var changed:=_transform(original,move.id,_v(move.to_foot_px),1.0)
		if changed.is_empty(): return {}
		for index: int in record.objects.size():
			if record.objects[index].id==move.id: record.objects[index]=changed
	for addition: Dictionary in spec.object_additions:
		if not _find(record.objects,addition.id).is_empty() or not donors.has(addition.donor_manifest): return {}
		var source:=_find(donors[addition.donor_manifest].get("objects",[]),addition.donor_id)
		if source.is_empty() or _v(source.world_foot_px)!=_v(addition.donor_foot_px): return {}
		var object:=_transform(source,addition.id,_v(addition.foot_px),float(addition.scale_ratio))
		if object.is_empty(): return {}
		object["assembled_usage"]=addition.usage
		object["assembled_no_new_door"]=true
		record.objects.append(object)
	# Only explicitly relocated home portals change. Their associated room return
	# resource is derived separately; task/NPC/interaction feet stay exact.
	for move: Dictionary in spec.get("portal_moves",[]):
		var portal:=_slot(record.gameplay_slots.portals,move.source_id)
		if portal.is_empty() or _v(portal.foot_px)!=_v(move.before_foot_px) or _v(portal.arrival_foot_px)!=_v(move.before_foot_px): return {}
		var delta:=_v(move.foot_px)-_v(move.before_foot_px)
		portal.foot_px=move.foot_px.duplicate(); portal.arrival_foot_px=move.foot_px.duplicate()
		for key: String in ["interaction_polygon_px","passage_path_px"]:
			var values: Array=[]
			for point: Variant in portal.get(key,[]): values.append(_xy(_v(point)+delta))
			portal[key]=values
	for replacement: Dictionary in spec.route_replacements:
		var route:=_find(record.routes,replacement.id)
		if route.is_empty() or route.get("points_px")!=replacement.before_points_px: return {}
		route.points_px=replacement.points_px.duplicate(true)
	for route: Dictionary in spec.routes_append:
		if not _find(record.routes,route.id).is_empty(): return {}
		record.routes.append(route.duplicate(true))
	record["assembled_parent_identity_20261016b"]=spec.parent_identity.duplicate(true)
	record["assembled_author_sha_20261016b"]=AUTHOR_SHA
	record["assembled_relocated_rooms"]=spec.get("portal_moves",[]).duplicate(true)
	record["assembled_portals_preserved_except_explicit_room_moves"]=true
	return record

static func apply_scene(parent: SceneScript,record: Dictionary,walk_path: String) -> SceneScript:
	if parent==null or parent.map_layout==null or parent.scene_id not in IDS or record.get("assembled_author_sha_20261016b")!=AUTHOR_SHA: return null
	var result:=parent.duplicate(true) as SceneScript
	result.map_layout=parent.map_layout.duplicate(true) as WalkableMapLayout
	var entries: Array[Dictionary]=[]
	for item: Dictionary in record.objects:
		var entry:=item.duplicate(true)
		var foot:=_v(item.world_foot_px); var render:=_v(item.render_size_px)
		entry.pos=(foot+(Vector2(.5,.5)-_v(item.foot_uv))*render)/Vector2(3072,2048)
		entry.render_size_px=render; entry.centered=true; entry.sort_by_feet=item.get("role","")!="ground_overlay"
		entry.depth_sort_foot_y=foot.y/2048.0
		entry.city_v3_solid_polygons_px=item.solid_polygons_px.duplicate(true); entry.erase("solid_polygons_px")
		entries.append(entry)
	result.map_layout.visual_objects=entries; result.map_layout.walkable_mask_path=walk_path
	for move: Dictionary in record.get("assembled_relocated_rooms",[]):
		var found:=0
		for portal: Dictionary in result.map_layout.portals:
			if portal.get("id")!=move.source_id: continue
			if portal.get("target_scene")!=move.room_id or portal.get("pos")!=_v(move.before_foot_px)/Vector2(3072,2048): return null
			var slot:=_slot(record.gameplay_slots.portals,move.source_id)
			if slot.is_empty(): return null
			portal.pos=_v(move.foot_px)/Vector2(3072,2048)
			portal.arrival_foot_px=_v(move.foot_px)
			portal.interaction_polygon_px=_polygon(slot.interaction_polygon_px)
			portal.passage_path_px=slot.passage_path_px.duplicate(true)
			found+=1
		if found!=1: return null
	result.set_meta(META,AUTHOR_SHA)
	result.set_meta("city_assembled_parent_scene_path",parent.resource_path)
	result.set_meta("city_assembled_status","CANDIDATE_NOT_FORMAL")
	return result

static func _polygon(value: Array) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for point: Variant in value: result.append(_v(point))
	return result

static func derive_return_room(original: SceneScript,move: Dictionary) -> SceneScript:
	if original==null or original.map_layout==null or original.scene_id!=StringName(move.room_id) or original.resource_path!=move.old_scene_path or original.map_layout.resource_path!=move.old_layout_path: return null
	# Prove the complete old room before making an explicit NEW return variant.
	if not load("res://scripts/city/luoyang_city_revision_runtime_20261015.gd").room_matches(original,original.scene_id): return null
	var result:=original.duplicate(true) as SceneScript
	result.map_layout=original.map_layout.duplicate(true) as WalkableMapLayout
	var count:=0
	for portal: Dictionary in result.map_layout.portals:
		if portal.get("target_scene")!="ch4_s3_luoyang_market": continue
		if portal.get("target_pos")!=_v(move.before_foot_px)/Vector2(3072,2048): return null
		portal.target_pos=_v(move.foot_px)/Vector2(3072,2048); count+=1
	if count!=1: return null
	result.set_meta("city_relocated_room_author_sha_20261016b",AUTHOR_SHA)
	result.set_meta("city_relocated_room_parent_path",move.old_scene_path)
	return result
