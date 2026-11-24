extends RefCounted
## Exact single-Market child. Not hooked, authored geometry is still pending.
const SELF="res://scripts/city/luoyang_market_frontage_20261020af.gd"
const AUTHOR="res://build/luoyang_market_frontage_20261020af_system01/author_READY.json"
const AUTHOR_SHA="PENDING_ART_ALPHA_SOLIDS_AND_AUTHOR_FREEZE"
const INDEX="res://scripts/city/luoyang_market_frontage_index_20261020af.gd"
const ROOT="res://data/maps/luoyang_market_frontage_20261020af/runtime/"
const ROOM_ROOT="res://data/maps/luoyang_market_frontage_rooms_20261020af/"
const ID=&"ch4_s3_luoyang_market"
const SIZE=Vector2(3072,2048)
const BASIS="MARKET_AF_EXACT_ONE_FRONTAGE_TO_THREE_PUBLISHED_CHILD"
const META="luoyang_market_frontage_20261020af"
const T_META="luoyang_layout_quest_20261018t"
const OLD_ID="market_east_ward_frontage"
const NEW_IDS=["market_northeast_rear_frontage","market_east_ward_frontage","southeast_market_front"]
const ROOM_IDS=["luoyang_market_market_northeast_rear_frontage_interior_20261015","luoyang_market_market_east_ward_frontage_interior_20261015","luoyang_functional_mansion_candidate_20261016"]
const DISTRICT_T_AUTHOR="res://build/luoyang_layout_quest_20261018t_layout_source01/author_retry2.json"
const DISTRICT_T_AUTHOR_SHA="8f708341b9923e53d016aa2198900e2a8c93085e11b154b42b6c44ff4bc1ba6e"
static func b() -> Variant: return load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
static func c() -> Variant: return load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
static func v(raw: Variant) -> Vector2:
	return raw if raw is Vector2 else (Vector2(float(raw[0]),float(raw[1])) if raw is Array and raw.size()==2 else Vector2(INF,INF))
static func uv(raw: Array) -> Vector2:
	return Vector2(float(raw[0])/3072.0,float(raw[1])/2048.0)
static func same(a: Variant,d: Variant) -> bool: return b().equal(a,d)
static func wire(value: Variant) -> Variant: return JSON.parse_string(JSON.stringify(value,"\t",true,true))
static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
static func pair(value: Variant) -> bool:
	return value is Array and value.size()==2 and number(value[0]) and number(value[1])
static func _spec(spec: Dictionary) -> bool:
	if spec.get("status")!="SOURCE_READY_AF_EXACT_THREE_FRONTAGES" or spec.get("scene_id")!=String(ID) or not number(spec.get("parent_count")) or spec.parent_count!=24 or not number(spec.get("child_count")) or spec.child_count!=26 or spec.get("old_id")!=OLD_ID or not pair(spec.get("old_foot_px")) or v(spec.old_foot_px)!=Vector2(2540,1680): return false
	if not spec.get("new_objects") is Array or spec.new_objects.size()!=3 or not spec.get("room_moves") is Array or spec.room_moves.size()!=3 or not spec.get("route_replacements") is Array or not spec.get("additional_routes") is Array or not spec.get("source_sha256") is Dictionary: return false
	for i: int in 3:
		var row: Variant=spec.new_objects[i]; var room: Variant=spec.room_moves[i]
		if not row is Dictionary or row.get("id")!=NEW_IDS[i] or row.get("blocking")!=true or not c()._object_solids_valid(row) or not room is Dictionary or room.get("scene_id")!=ROOM_IDS[i] or room.get("building_id")!=NEW_IDS[i] or not pair(room.get("old_return_foot_px")) or not pair(room.get("return_foot_px")) or not number(room.get("native_portal_expected")) or room.native_portal_expected!=(0 if i==2 else 1): return false
		if not row.get("texture") is String or spec.source_sha256.get(row.texture)!=row.get("source_sha256"): return false
	return true
static func author() -> Dictionary:
	if AUTHOR_SHA.length()!=64 or FileAccess.get_sha256(AUTHOR)!=AUTHOR_SHA: return {}
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
	if not raw is Dictionary or not _spec(raw): return {}
	for path: String in raw.source_sha256:
		if not path.begins_with("res://") or ".." in path or path in [SELF,INDEX,AUTHOR] or FileAccess.get_sha256(path)!=raw.source_sha256[path]: return {}
	return raw
static func source_paths() -> Dictionary:
	var spec: Dictionary=author()
	if spec.is_empty(): return {}
	var result: Dictionary={SELF:true,AUTHOR:true}
	for path: String in spec.source_sha256: result[path]=true
	return result # INDEX is an external authority, never in its own manifest.
static func district_author() -> Dictionary:
	if FileAccess.get_sha256(DISTRICT_T_AUTHOR)!=DISTRICT_T_AUTHOR_SHA: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(DISTRICT_T_AUTHOR))
	return value if value is Dictionary else {}
static func bound(scene: SceneScript) -> bool:
	return scene!=null and scene.scene_id==ID and scene.map_layout!=null and scene.get_meta(META,"")==AUTHOR_SHA and scene.get_meta(T_META,"")==DISTRICT_T_AUTHOR_SHA and scene.map_layout.visual_objects.size()==26 and b().whole_bound(scene)
static func packet_valid(child: Dictionary) -> bool:
	# Caller B first binds full child bytes to its externally approved artifact SHA.
	var spec: Dictionary=author()
	if spec.is_empty() or child.get("af_author_sha256")!=AUTHOR_SHA or FileAccess.get_sha256(spec.parent_packet_path)!=spec.parent_packet_sha256: return false
	var parent: Variant=bytes_to_var(FileAccess.get_file_as_bytes(spec.parent_packet_path))
	if not parent is Dictionary or not b()._plain(parent): return false
	var expected: Dictionary=compose(parent.record,spec,ROOT+String(ID)+"/walk.png")
	return not expected.is_empty() and same(wire(expected),wire(child.get("record"))) and same(c().object_solids(expected.objects),child.get("solids")) and packet_inverse(child,parent,spec)
static func find(rows: Array,key: String) -> Dictionary:
	var result: Dictionary={}
	for row: Dictionary in rows:
		if String(row.get("id",""))!=key: continue
		if not result.is_empty(): return {}
		result=row
	return result
static func compose(parent: Dictionary,spec: Dictionary,walk: String) -> Dictionary:
	if not _spec(spec) or parent.get("canonical_scene_id")!=String(ID) or parent.get("objects",[]).size()!=24 or walk!=ROOT+String(ID)+"/walk.png": return {}
	var old: Dictionary=find(parent.objects,OLD_ID)
	if old.is_empty() or v(old.get("world_foot_px"))!=v(spec.old_foot_px): return {}
	for key: String in [NEW_IDS[0],NEW_IDS[2]]:
		if not find(parent.objects,key).is_empty(): return {}
	var result: Dictionary=parent.duplicate(true); var objects: Array=[]
	for row: Dictionary in parent.objects:
		if row.id==OLD_ID: objects.append_array(spec.new_objects.duplicate(true))
		else: objects.append(row.duplicate(true))
	result.objects=objects; result.walk_path=walk; result["af_geometry_basis"]=BASIS
	var changed: Dictionary={}; var routes: Array=[]
	for original: Dictionary in parent.routes:
		var route: Dictionary=original.duplicate(true)
		for replacement: Dictionary in spec.route_replacements:
			if replacement.id!=route.id: continue
			if changed.has(String(route.id)) or replacement.get("old_points_px")==null or not same(wire(original.points_px),wire(replacement.old_points_px)): return {}
			route["af_old_points_px"]=original.points_px.duplicate(true); route.points_px=replacement.points_px.duplicate(true); changed[String(route.id)]=true
		routes.append(route)
	if changed.size()!=spec.route_replacements.size(): return {}
	for added: Dictionary in spec.additional_routes:
		if not find(parent.routes,String(added.id)).is_empty(): return {}
		var route: Dictionary=added.duplicate(true);route["af_new_route"]=true;routes.append(route)
	result.routes=routes
	var portal_matches: Array[int]=[0,0,0]
	for slot: Dictionary in result.gameplay_slots.get("portals",[]):
		for i: int in 3:
			var room: Dictionary=spec.room_moves[i]
			if v(slot.get("foot_px"))!=v(room.old_return_foot_px): continue
			slot["af_original_slot"]=slot.duplicate(true);slot.foot_px=room.return_foot_px.duplicate();slot.arrival_foot_px=room.return_foot_px.duplicate()
			slot.passage_path_px=[[float(room.return_foot_px[0]),float(room.return_foot_px[1])+24.0],room.return_foot_px.duplicate()]
			portal_matches[i]+=1
	for i: int in 3:
		if portal_matches[i]!=int(spec.room_moves[i].native_portal_expected): return {}
	return result if result.objects.size()==26 and same(inverse_record(result,parent,spec),parent) else {}
static func inverse_record(child: Dictionary,parent: Dictionary,spec: Dictionary) -> Dictionary:
	var result: Dictionary=child.duplicate(true);var rows: Array=[];var seen: Array=[];var inserted: bool=false
	for row: Dictionary in child.get("objects",[]):
		if String(row.id) in NEW_IDS:
			if String(row.id) in seen: return {}
			seen.append(String(row.id))
			if not inserted: rows.append(find(parent.objects,OLD_ID).duplicate(true));inserted=true
		else: rows.append(row.duplicate(true))
	if seen!=NEW_IDS: return {}
	result.objects=rows; result.walk_path=parent.walk_path; result.erase("af_geometry_basis")
	var routes: Array=[]
	for row: Dictionary in child.routes:
		if row.get("af_new_route")==true:
			if find(spec.additional_routes,String(row.id)).is_empty(): return {}
			continue
		var route: Dictionary=row.duplicate(true)
		if route.has("af_old_points_px"): route.points_px=route.af_old_points_px.duplicate(true);route.erase("af_old_points_px")
		routes.append(route)
	result.routes=routes
	for i: int in result.gameplay_slots.get("portals",[]).size():
		var slot: Dictionary=result.gameplay_slots.portals[i]
		if slot.has("af_original_slot"): result.gameplay_slots.portals[i]=slot.af_original_slot.duplicate(true)
	return result
static func render_entry(row: Dictionary) -> Dictionary:
	var result: Dictionary=row.duplicate(true);var render: Vector2=v(row.render_size_px);var foot: Vector2=v(row.world_foot_px)
	result.pos=(foot+(Vector2(.5,.5)-v(row.foot_uv))*render)/SIZE
	result.centered=true;result.sort_by_feet=true;result.depth_sort_foot_y=foot.y/SIZE.y
	result.city_v3_solid_polygons_px=row.solid_polygons_px.duplicate(true)
	result.erase("solid_polygons_px")
	return result
static func doorway(foot: Array) -> PackedVector2Array:
	var center: Vector2=uv(foot)*SIZE
	return PackedVector2Array([center+Vector2(-20,-16),center+Vector2(20,-16),center+Vector2(20,16),center+Vector2(-20,16)])
static func materialize(parent: SceneScript,record: Dictionary,spec: Dictionary,author_sha: String) -> SceneScript:
	if not _spec(spec) or parent==null or parent.scene_id!=ID or parent.map_layout==null or parent.map_layout.visual_objects.size()!=24 or not parent.has_meta(T_META) or parent.has_meta(META) or record.get("objects",[]).size()!=26 or author_sha.length()!=64: return null
	var scene:=parent.duplicate(true) as SceneScript
	scene.map_layout=parent.map_layout.duplicate(true) as WalkableMapLayout
	var entries: Array[Dictionary]=[]
	for original: Dictionary in parent.map_layout.visual_objects:
		if original.get("id")==OLD_ID:
			for row: Dictionary in spec.new_objects: entries.append(render_entry(row))
		else: entries.append(original.duplicate(true))
	scene.map_layout.visual_objects=entries;scene.map_layout.walkable_mask_path=String(record.walk_path)
	var counts: Array[int]=[0,0,0]
	for portal: Dictionary in scene.map_layout.portals:
		for i: int in 3:
			var room: Dictionary=spec.room_moves[i]
			if String(portal.get("target_scene",""))!=room.scene_id: continue
			if portal.get("pos")!=uv(room.old_return_foot_px): return null
			portal.pos=uv(room.return_foot_px);portal.interaction_polygon_px=doorway(room.return_foot_px)
			counts[i]+=1
	for i: int in 3:
		if counts[i]!=int(spec.room_moves[i].native_portal_expected): return null
	scene.set_meta(META,author_sha)
	return scene
static func packet_inverse(child: Dictionary,parent: Dictionary,spec: Dictionary) -> bool:
	if not _spec(spec) or child.get("geometry_basis")!=BASIS or child.get("af_parent_packet_sha256")!=spec.get("parent_packet_sha256") or not same(child.get("af_parent_record"),parent.get("record")) or not same(inverse_record(child.get("record",{}),parent.record,spec),parent.record): return false
	var inverse: Dictionary=child.duplicate(true)
	for key: String in ["geometry_basis","record","solids","walk_bytes","mask_sha","scene_storage","layout_storage"]: inverse[key]=parent[key]
	for key: String in ["af_parent_record","af_parent_packet_sha256","af_author_sha256"]: inverse.erase(key)
	return same(inverse,parent)

