extends RefCounted
## Actual-art AO successor. Geometry is projected once from pinned source pixels.
const AUTHOR="res://build/luoyang_market_two_shops_20261021ao_system01/author_READY.json"
const AUTHOR_SHA="227735f42114e843e62109b127a3c57d4a7b9ffdb4e545799ba9d50dc77cc849"
const ROOT="res://data/maps/luoyang_market_two_shops_20261021ao/runtime/"
const ROOM_ROOT="res://data/maps/luoyang_market_two_shops_20261021ao/rooms/"
const ID=&"ch4_s3_luoyang_market"
const SIZE=Vector2(3072,2048)
const BASIS="AO_EXACT_SHARED_FRONTAGE_AND_WALL_TO_TWO_SHOPS"
const META="luoyang_market_two_shops_20261021ao"
const OLD_IDS=["market_east_ward_frontage","v13_market_east_plot_wall"]
const NEW_IDS=["market_northeast_rear_frontage","market_east_ward_frontage"]
const ROOM_IDS=["luoyang_market_market_northeast_rear_frontage_interior_20261015","luoyang_market_market_east_ward_frontage_interior_20261015"]
const STREET_RECTS=[Rect2(1472,800,128,1224),Rect2(220,1012,2620,96),Rect2(220,1928,1252,96),Rect2(1600,1692,1350,96)]
static func b() -> Variant: return load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
static func c() -> Variant: return load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
static func v(raw: Variant) -> Vector2: return raw if raw is Vector2 else Vector2(raw[0],raw[1])
static func uv(raw: Variant) -> Vector2: return v(raw)/SIZE
static func wire(raw: Variant) -> Variant: return JSON.parse_string(JSON.stringify(raw,"\t",true,true))
static func same(a: Variant,z: Variant) -> bool: return b().equal(a,z)
static func find(rows: Array,id: String) -> Dictionary:
	var found: Dictionary={}
	for row: Dictionary in rows:
		if row.get("id")==id:
			if not found.is_empty(): return {}
			found=row
	return found
static func author() -> Dictionary:
	if AUTHOR_SHA.length()!=64 or FileAccess.get_sha256(AUTHOR)!=AUTHOR_SHA: return {}
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
	if not raw is Dictionary: return {}
	var spec: Dictionary=project_spec(raw)
	return spec if spec_valid(spec) else {}
static func project_spec(raw: Dictionary) -> Dictionary:
	# JSON source pixels/scale/feet are authority; derived vectors use Godot
	# Vector2f in this one place, never pre-rounded external world geometry.
	var spec: Dictionary=raw.duplicate(true)
	if not spec.get("new_objects") is Array or spec.new_objects.size()!=2: return {}
	for i: int in 2:
		var key: String="apothecary" if i==0 else "study"
		var asset: Dictionary=spec.get("assets",{}).get(key,{})
		if not asset.get("source_size_px") is Array or asset.source_size_px.size()!=2 or not asset.get("source_ground_anchor_px") is Array or asset.source_ground_anchor_px.size()!=2 or not asset.get("ground_solid_polygons_px") is Array or asset.ground_solid_polygons_px.size()!=2: return {}
		var row: Dictionary=spec.new_objects[i]
		if not row.get("world_foot_px") is Array or row.world_foot_px.size()!=2: return {}
		var size: Vector2=v(asset.source_size_px);var anchor: Vector2=v(asset.source_ground_anchor_px);var foot: Vector2=v(row.world_foot_px);var scale: float=float(asset.scale)
		row.texture=asset.texture;row.source=asset.texture;row.source_sha256=asset.source_sha256;row.source_size_px=asset.source_size_px.duplicate()
		row.render_size_px=size*scale;row.foot_uv=anchor/size;row.physical_center_px=foot;row.collision_size_px=Vector2.ZERO
		var polygons: Array=[]
		for original: Variant in asset.ground_solid_polygons_px:
			var projected: Array=[]
			for point: Vector2 in c()._polygon(original): projected.append(foot+(point-anchor)*scale)
			polygons.append(projected)
		row.solid_polygons_px=polygons
	return spec
static func spec_valid(spec: Dictionary) -> bool:
	if spec.get("status")!="READY_AO_TWO_SHOPS_ACTUAL_ART" or spec.get("scene_id")!=String(ID) or spec.get("parent_count")!=24 or spec.get("child_count")!=24 or spec.get("retire_ids")!=OLD_IDS: return false
	if not spec.get("new_objects") is Array or spec.new_objects.size()!=2 or not spec.get("room_moves") is Array or spec.room_moves.size()!=2: return false
	if not spec.get("source_sha256") is Dictionary or spec.source_sha256.is_empty(): return false
	for i: int in 2:
		var row: Dictionary=spec.new_objects[i];var move: Dictionary=spec.room_moves[i]
		if row.get("id")!=NEW_IDS[i] or move.get("scene_id")!=ROOM_IDS[i] or move.get("building_id")!=NEW_IDS[i] or move.get("native_portal_expected")!=1: return false
		if not c()._object_solids_valid(row) or not c()._object_render_role_valid(ID,row) or row.get("blocking")!=true or row.get("solid_polygons_px",[]).is_empty() or row.get("walk_support",false)!=false or row.get("sort_by_feet",true)!=true: return false
	return true
static func streets_clear(spec: Dictionary) -> bool:
	for row: Dictionary in spec.new_objects:
		for raw: Variant in row.solid_polygons_px:
			var polygon: PackedVector2Array=c()._polygon(raw)
			for rect: Rect2 in STREET_RECTS:
				var box:=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
				if not Geometry2D.intersect_polygons(polygon,box).is_empty(): return false
	return true
static func compose(parent: Dictionary,spec: Dictionary,walk: String) -> Dictionary:
	if not spec_valid(spec) or parent.get("canonical_scene_id")!=String(ID) or parent.get("objects",[]).size()!=24 or walk!=ROOT+String(ID)+"/walk.png" or not streets_clear(spec): return {}
	for id: String in OLD_IDS:
		if find(parent.objects,id).is_empty(): return {}
	if not find(parent.objects,NEW_IDS[0]).is_empty(): return {}
	var child: Dictionary=parent.duplicate(true);var objects: Array=[]
	for row: Dictionary in parent.objects:
		if row.id==OLD_IDS[0]: objects.append_array(spec.new_objects.duplicate(true))
		elif row.id!=OLD_IDS[1]: objects.append(row.duplicate(true))
	child.objects=objects;child.walk_path=walk;child["ao_geometry_basis"]=BASIS
	var changed: Dictionary={}
	for route: Dictionary in child.routes:
		for replacement: Dictionary in spec.route_replacements:
			if route.id!=replacement.id: continue
			if changed.has(route.id) or not same(wire(route.points_px),wire(replacement.old_points_px)): return {}
			route["ao_original_points_px"]=route.points_px.duplicate(true);route.points_px=replacement.points_px.duplicate(true);changed[route.id]=true
	if changed.size()!=spec.route_replacements.size(): return {}
	for route: Dictionary in spec.additional_routes:
		if not find(parent.routes,String(route.id)).is_empty(): return {}
		var added: Dictionary=route.duplicate(true);added["ao_added_route"]=true;child.routes.append(added)
	var counts: Array[int]=[0,0]
	for slot: Dictionary in child.gameplay_slots.portals:
		for i: int in 2:
			var move: Dictionary=spec.room_moves[i]
			if v(slot.foot_px)!=v(move.old_return_foot_px): continue
			slot["ao_original_slot"]=slot.duplicate(true);slot.foot_px=move.return_foot_px.duplicate();slot.arrival_foot_px=move.return_foot_px.duplicate();slot.passage_path_px=[v(move.return_foot_px)+Vector2(0,24),v(move.return_foot_px)];slot.interaction_polygon_px=doorway(move.return_foot_px);counts[i]+=1
	for count: int in counts:
		if count!=1: return {}
	return child if child.objects.size()==24 and same(inverse_record(child,parent,spec),parent) else {}
static func inverse_record(child: Dictionary,parent: Dictionary,spec: Dictionary) -> Dictionary:
	var inverse: Dictionary=child.duplicate(true);var kept: Array=[];var inserted: Array=[]
	for row: Dictionary in child.get("objects",[]):
		if String(row.id) in NEW_IDS: inserted.append(String(row.id))
		else: kept.append(row)
	if inserted!=NEW_IDS: return {}
	var rows: Array=[];var n: int=0
	for row: Dictionary in parent.objects:
		if String(row.id) in OLD_IDS: rows.append(row.duplicate(true))
		else:
			if n>=kept.size() or kept[n].id!=row.id: return {}
			rows.append(kept[n].duplicate(true));n+=1
	if n!=kept.size(): return {}
	inverse.objects=rows;inverse.walk_path=parent.walk_path;inverse.erase("ao_geometry_basis")
	var routes: Array=[]
	for row: Dictionary in inverse.routes:
		if row.get("ao_added_route")==true:
			if find(spec.additional_routes,String(row.id)).is_empty(): return {}
			continue
		if row.has("ao_original_points_px"): row.points_px=row.ao_original_points_px.duplicate(true);row.erase("ao_original_points_px")
		routes.append(row)
	inverse.routes=routes
	for i: int in inverse.gameplay_slots.portals.size():
		var row: Dictionary=inverse.gameplay_slots.portals[i]
		if row.has("ao_original_slot"): inverse.gameplay_slots.portals[i]=row.ao_original_slot.duplicate(true)
	return inverse
static func render_entry(row: Dictionary) -> Dictionary:
	var result: Dictionary=row.duplicate(true);var render: Vector2=v(row.render_size_px);var foot: Vector2=v(row.world_foot_px)
	result.pos=(foot+(Vector2(.5,.5)-v(row.foot_uv))*render)/SIZE;result.centered=true;result.sort_by_feet=true;result.depth_sort_foot_y=foot.y/SIZE.y
	result.city_v3_solid_polygons_px=row.solid_polygons_px.duplicate(true);result.erase("solid_polygons_px")
	return result
static func doorway(foot: Variant) -> PackedVector2Array:
	var p: Vector2=v(foot)
	return PackedVector2Array([p+Vector2(-20,-16),p+Vector2(20,-16),p+Vector2(20,16),p+Vector2(-20,16)])
static func materialize(parent: SceneScript,record: Dictionary,spec: Dictionary) -> SceneScript:
	if not spec_valid(spec) or parent==null or parent.scene_id!=ID or parent.map_layout==null or parent.map_layout.visual_objects.size()!=24: return null
	var scene:=parent.duplicate(true) as SceneScript;scene.map_layout=parent.map_layout.duplicate(true) as WalkableMapLayout
	var entries: Array[Dictionary]=[]
	for row: Dictionary in parent.map_layout.visual_objects:
		if row.id==OLD_IDS[0]:
			for item: Dictionary in spec.new_objects: entries.append(render_entry(item))
		elif row.id!=OLD_IDS[1]: entries.append(row.duplicate(true))
	if entries.size()!=24: return null
	scene.map_layout.visual_objects=entries;scene.map_layout.walkable_mask_path=record.walk_path
	var counts: Array[int]=[0,0]
	for portal: Dictionary in scene.map_layout.portals:
		for i: int in 2:
			var move: Dictionary=spec.room_moves[i]
			if String(portal.get("target_scene",""))!=ROOM_IDS[i]: continue
			if portal.pos!=uv(move.old_return_foot_px): return null
			portal.pos=uv(move.return_foot_px);portal.arrival_foot_px=v(move.return_foot_px);portal.passage_path_px=[v(move.return_foot_px)+Vector2(0,24),v(move.return_foot_px)];portal.interaction_polygon_px=doorway(move.return_foot_px);portal.building_id=NEW_IDS[i];portal.target_scene_path=ROOM_ROOT+ROOM_IDS[i]+"/scene.res";counts[i]+=1
	for count: int in counts:
		if count!=1: return null
	scene.set_meta(META,AUTHOR_SHA)
	return scene
static func native_inverse(child: SceneScript,parent: SceneScript,spec: Dictionary) -> bool:
	var inverse:=child.duplicate(true) as SceneScript;inverse.map_layout=child.map_layout.duplicate(true) as WalkableMapLayout;inverse.remove_meta(META)
	var remaining: Array=[]
	for row: Dictionary in inverse.map_layout.visual_objects:
		if String(row.id) not in NEW_IDS: remaining.append(row)
	var restored: Array[Dictionary]=[];var n: int=0
	for row: Dictionary in parent.map_layout.visual_objects:
		if String(row.id) in OLD_IDS: restored.append(row.duplicate(true))
		else:
			if n>=remaining.size() or remaining[n].id!=row.id: return false
			restored.append(remaining[n]);n+=1
	if n!=remaining.size(): return false
	inverse.map_layout.visual_objects=restored;inverse.map_layout.walkable_mask_path=parent.map_layout.walkable_mask_path
	for i: int in inverse.map_layout.portals.size():
		if String(inverse.map_layout.portals[i].get("target_scene","")) in ROOM_IDS: inverse.map_layout.portals[i]=parent.map_layout.portals[i].duplicate(true)
	return same(b().storage(inverse),b().storage(parent)) and same(b().storage(inverse.map_layout),b().storage(parent.map_layout))

