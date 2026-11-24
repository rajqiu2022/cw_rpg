extends RefCounted
## One exact AP child of the already-published AO Market. No new C schema.
const AUTHOR="res://build/luoyang_city_full_rollout_20261022ap_system01/market_alpha_pin_retry6/market_author.json"
const ROOT="res://data/maps/luoyang_full_city_20261022ap/market/"
const ROOM_ROOT="res://data/maps/luoyang_full_city_20261022ap/rooms/"
const ID=&"ch4_s3_luoyang_market"
const SIZE=Vector2(3072,2048)
const BASIS="AP_MARKET_PAWN_TAILOR_AND_THREE_ROOM_QUARTER_RELOCATION"
const META="luoyang_market_full_rollout_20261022ap"
const OLD_IDS=["north_market_front","market_west_ward_frontage"]
const NEW_IDS=["market_west_ward_frontage","north_market_front"]
const ROOM_IDS=["luoyang_functional_pawnshop_candidate_20261016","luoyang_market_north_market_front_interior_20261015","luoyang_market_market_west_ward_frontage_interior_20261015","luoyang_market_market_northwest_rear_frontage_interior_20261015","luoyang_market_southeast_market_front_interior_20261015"]
const MOVED_NATIVE_IDS=["assembled_market_tree_group_a","street_tree_2","v13_market_west_plot_wall"]
const MOVED_DISTRICT_IDS=["district_luoyang_market_stock_goods_0","district_luoyang_market_stock_tree_0","district_luoyang_market_stock_tree_1"]
const NATIVE_COUNTS=[0,1,1,1,1]
const RETIRED_ROUTES=["room_southeast_market_front_approach","room_westward_approach","room_northwestrear_approach","t_west_three_bays","room_southwest_market_front_approach"]
static func b() -> Variant: return load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
static func c() -> Variant: return load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
static func v(raw: Variant) -> Vector2: return raw if raw is Vector2 else Vector2(raw[0],raw[1])
static func wire(raw: Variant) -> Variant: return JSON.parse_string(JSON.stringify(raw,"\t",true,true))
static func same(left: Variant,right: Variant) -> bool: return b().equal(left,right)
static func find(rows: Array,id: String) -> Dictionary:
	var result: Dictionary={}
	for row: Dictionary in rows:
		if row.get("id")==id:
			if not result.is_empty(): return {}
			result=row
	return result
static func author() -> Dictionary:
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
	return project_spec(raw) if raw is Dictionary else {}
static func project_spec(raw: Dictionary) -> Dictionary:
	if raw.get("status")!="ROOT_BOUND_AP_MARKET_TWO_WHOLE_BUILDINGS" or raw.get("scene_id")!=String(ID) or raw.get("parent_count")!=24 or raw.get("child_count")!=24 or raw.get("retire_ids")!=OLD_IDS or not raw.get("room_moves") is Array or raw.room_moves.size()!=5: return {}
	var spec: Dictionary=raw.duplicate(true)
	for i: int in 2:
		var key: String="pawn" if i==0 else "tailor"
		var asset: Dictionary=spec.assets.get(key,{})
		var row: Dictionary=spec.new_objects[i]
		var size: Vector2=v(asset.source_size_px);var anchor: Vector2=v(asset.source_ground_anchor_px);var foot: Vector2=v(row.world_foot_px);var scale_value: float=float(asset.scale)
		if float(asset.door_lower_px)*scale_value<120: return {}
		row.texture=asset.texture;row.source=asset.texture;row.source_sha256=asset.source_sha256;row.source_size_px=asset.source_size_px.duplicate()
		row.render_size_px=size*scale_value;row.foot_uv=anchor/size;row.physical_center_px=foot;row.collision_size_px=Vector2.ZERO
		var polygons: Array=[]
		for source_rect: Array in asset.solid_rects:
			var rect:=Rect2(source_rect[0],source_rect[1],source_rect[2],source_rect[3])
			var points: Array=[]
			for point: Vector2 in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]: points.append(foot+(point-anchor)*scale_value)
			polygons.append(points)
		row.solid_polygons_px=polygons
		if not c()._object_solids_valid(row) or not c()._object_render_role_valid(ID,row): return {}
	for i: int in 5:
		if spec.room_moves[i].scene_id!=ROOM_IDS[i] or spec.room_moves[i].native_portal_expected!=NATIVE_COUNTS[i]: return {}
	return spec
static func render_entry(row: Dictionary) -> Dictionary:
	var out: Dictionary=row.duplicate(true);var render: Vector2=v(row.render_size_px);var foot: Vector2=v(row.world_foot_px)
	out.pos=(foot+(Vector2(.5,.5)-v(row.foot_uv))*render)/SIZE;out.centered=true;out.sort_by_feet=true;out.depth_sort_foot_y=foot.y/SIZE.y
	out.city_v3_solid_polygons_px=row.solid_polygons_px.duplicate(true);out.erase("solid_polygons_px")
	return out
static func doorway(foot: Variant) -> PackedVector2Array:
	var p: Vector2=v(foot)
	return PackedVector2Array([p+Vector2(-20,-16),p+Vector2(20,-16),p+Vector2(20,16),p+Vector2(-20,16)])
static func _record(parent: Dictionary,spec: Dictionary,walk: String) -> Dictionary:
	if parent.get("canonical_scene_id")!=String(ID) or parent.get("objects",[]).size()!=24 or walk!=ROOT+String(ID)+"/walk.png": return {}
	var out: Dictionary=parent.duplicate(true);var count: Dictionary={}
	for i: int in out.objects.size():
		for replacement: Dictionary in spec.new_objects:
			if out.objects[i].id==replacement.id:
				if count.has(replacement.id): return {}
				out.objects[i]=replacement.duplicate(true);count[replacement.id]=true
	if count.size()!=2: return {}
	out.objects=relocate_native_record(out.objects,spec)
	if out.objects.size()!=24: return {}
	var routes: Array=[];var retired: Dictionary={};var replaced: Dictionary={}
	for row: Dictionary in parent.routes:
		if row.id in RETIRED_ROUTES:
			var old: Dictionary=find(spec.retired_routes,row.id)
			if old.is_empty() or not same(wire(row.points_px),wire(old.points_px)) or retired.has(row.id): return {}
			retired[row.id]=true
			continue
		var next: Dictionary=row.duplicate(true)
		for move: Dictionary in spec.route_replacements:
			if next.id==move.id:
				if not same(wire(next.points_px),wire(move.old_points_px)) or replaced.has(next.id): return {}
				next.points_px=move.points_px.duplicate(true);replaced[next.id]=true
		routes.append(next)
	if retired.size()!=RETIRED_ROUTES.size() or replaced.size()!=spec.route_replacements.size(): return {}
	for added: Dictionary in spec.additional_routes:
		if not find(parent.routes,added.id).is_empty(): return {}
		routes.append(added.duplicate(true))
	out.routes=routes
	var portals: Array=[];var found: Array[int]=[0,0,0,0,0]
	for row: Dictionary in parent.gameplay_slots.portals:
		var index: int=-1
		for i: int in 5:
			if v(row.foot_px)==v(spec.room_moves[i].old_return):
				if index!=-1: return {}
				index=i
		if index==-1: portals.append(row.duplicate(true));continue
		found[index]+=1
		if index>=2: continue
		var next: Dictionary=row.duplicate(true);var point: Vector2=v(spec.room_moves[index]["return"])
		next.foot_px=point;next.arrival_foot_px=point;next.passage_path_px=[point+Vector2(0,24),point];next.interaction_polygon_px=doorway(point);portals.append(next)
	for i: int in 5:
		if found[i]!=NATIVE_COUNTS[i]: return {}
	out.gameplay_slots.portals=portals;out.walk_path=walk;out["ap_geometry_basis"]=BASIS
	return out
static func compose(parent: Dictionary,spec: Dictionary,walk: String) -> Dictionary:
	var child: Dictionary=_record(parent,spec,walk)
	return child if not child.is_empty() and same(inverse_record(child,parent,spec),parent) else {}
static func inverse_record(child: Dictionary,parent: Dictionary,spec: Dictionary) -> Dictionary:
	var expected: Dictionary=_record(parent,spec,ROOT+String(ID)+"/walk.png")
	if expected.is_empty() or not same(child,expected): return {}
	var inverse: Dictionary=child.duplicate(true)
	inverse.objects=parent.objects.duplicate(true);inverse.routes=parent.routes.duplicate(true);inverse.gameplay_slots.portals=parent.gameplay_slots.portals.duplicate(true);inverse.walk_path=parent.walk_path;inverse.erase("ap_geometry_basis")
	return inverse
static func materialize(parent: SceneScript,record: Dictionary,spec: Dictionary) -> SceneScript:
	if parent==null or parent.scene_id!=ID or parent.map_layout==null or parent.map_layout.visual_objects.size()!=24: return null
	var scene:=parent.duplicate(true) as SceneScript;scene.map_layout=parent.map_layout.duplicate(true) as WalkableMapLayout
	var count: Dictionary={}
	for i: int in scene.map_layout.visual_objects.size():
		for row: Dictionary in spec.new_objects:
			if scene.map_layout.visual_objects[i].id==row.id:
				if count.has(row.id): return null
				scene.map_layout.visual_objects[i]=render_entry(row);count[row.id]=true
	if count.size()!=2: return null
	if not relocate_native_visuals(scene.map_layout.visual_objects,spec): return null
	var portals: Array[Dictionary]=[];var found: Array[int]=[0,0,0,0,0]
	for old: Dictionary in scene.map_layout.portals:
		var index: int=ROOM_IDS.find(String(old.get("target_scene","")))
		if index==-1: portals.append(old.duplicate(true));continue
		var move: Dictionary=spec.room_moves[index]
		if old.pos!=v(move.old_return)/SIZE: return null
		found[index]+=1
		if index>=2: continue
		var next: Dictionary=old.duplicate(true);var point: Vector2=v(move["return"])
		next.pos=point/SIZE;next.arrival_foot_px=point;next.interaction_polygon_px=doorway(point);next.passage_path_px=[point+Vector2(0,24),point];next.building_id=move.building_id;next.target_scene_path=ROOM_ROOT+move.scene_id+"/scene.res";portals.append(next)
	for i: int in 5:
		if found[i]!=NATIVE_COUNTS[i]: return null
	scene.map_layout.portals=portals;scene.map_layout.walkable_mask_path=record.walk_path;scene.set_meta(META,FileAccess.get_sha256(AUTHOR))
	return scene
static func native_inverse(child: SceneScript,parent: SceneScript,spec: Dictionary) -> bool:
	var expected: SceneScript=materialize(parent,{"walk_path":ROOT+String(ID)+"/walk.png"},spec)
	if child==null or expected==null or not same(b().storage(child),b().storage(expected)) or not same(b().storage(child.map_layout),b().storage(expected.map_layout)): return false
	var inverse:=child.duplicate(true) as SceneScript;inverse.map_layout=child.map_layout.duplicate(true) as WalkableMapLayout
	inverse.remove_meta(META);inverse.map_layout.visual_objects=parent.map_layout.visual_objects.duplicate(true);inverse.map_layout.portals=parent.map_layout.portals.duplicate(true);inverse.map_layout.walkable_mask_path=parent.map_layout.walkable_mask_path
	return same(b().storage(inverse),b().storage(parent)) and same(b().storage(inverse.map_layout),b().storage(parent.map_layout))

static func translate_polygons(raw: Array,delta: Vector2) -> Array:
	var out: Array=[]
	for polygon: Variant in raw:
		var next: Array=[]
		for point: Variant in polygon: next.append(v(point)+delta)
		out.append(next)
	return out
static func wall_record(spec: Dictionary) -> Dictionary:
	var wall: Dictionary=spec.layout_successor.wall;var r: Array=wall.solid
	var poly: Array=[Vector2(r[0],r[1]),Vector2(r[0]+r[2],r[1]),Vector2(r[0]+r[2],r[1]+r[3]),Vector2(r[0],r[1]+r[3])]
	return {"id":wall.id,"prototype":"building","nature":"exact_retained_visible_wall_panel","texture":wall.texture,"source":wall.texture,"source_size_px":[110,123],"render_size_px":Vector2(110,123),"foot_uv":Vector2(55.0/110.0,120.0/123.0),"world_foot_px":v(wall.foot),"physical_center_px":Vector2(90,1414),"collision_size_px":Vector2.ZERO,"solid_polygons_px":[poly],"blocking":true,"sort_by_feet":true,"ghost_occlusion":true,"walk_support":false}
static func relocate_native_record(original: Array,spec: Dictionary) -> Array:
	var out: Array=original.duplicate(true);var seen: Dictionary={}
	for index: int in out.size():
		var row: Dictionary=out[index]
		for move: Dictionary in spec.layout_successor.native_moves:
			if row.id!=move.id: continue
			if seen.has(row.id) or v(row.world_foot_px)!=v(move.old_foot): return []
			var delta: Vector2=v(move.new_foot)-v(move.old_foot)
			row.world_foot_px=v(move.new_foot);row.physical_center_px=v(row.physical_center_px)+delta
			if row.has("depth_foot_y"): row.depth_foot_y=float(row.depth_foot_y)+delta.y
			if row.has("world_origin_px"): row.world_origin_px=v(row.world_origin_px)+delta
			row.solid_polygons_px=translate_polygons(row.solid_polygons_px,delta);seen[row.id]=true
		if row.id==spec.layout_successor.wall.id:
			if seen.has(row.id) or v(row.world_foot_px)!=v(spec.layout_successor.wall.old_foot): return []
			out[index]=wall_record(spec);seen[row.id]=true
	return out if seen.size()==3 else []
static func relocate_native_visuals(rows: Array,spec: Dictionary) -> bool:
	var seen: Dictionary={}
	for index: int in rows.size():
		var row: Dictionary=rows[index]
		for move: Dictionary in spec.layout_successor.native_moves:
			if row.id!=move.id: continue
			if seen.has(row.id): return false
			var delta: Vector2=v(move.new_foot)-v(move.old_foot)
			row.pos=v(row.pos)+delta/SIZE
			if row.has("world_foot_px"): row.world_foot_px=v(row.world_foot_px)+delta
			if row.has("physical_center_px"): row.physical_center_px=v(row.physical_center_px)+delta
			if row.has("depth_sort_foot_y"): row.depth_sort_foot_y=float(row.depth_sort_foot_y)+delta.y/SIZE.y
			if row.has("city_v3_solid_polygons_px"): row.city_v3_solid_polygons_px=translate_polygons(row.city_v3_solid_polygons_px,delta)
			seen[row.id]=true
		if row.id==spec.layout_successor.wall.id:
			if seen.has(row.id): return false
			rows[index]=render_entry(wall_record(spec));seen[row.id]=true
	return seen.size()==3
static func project_district(original: Dictionary,spec: Dictionary) -> Dictionary:
	if original.is_empty() or original.get("additions",[]).size()!=12: return {}
	var out: Dictionary=original.duplicate(true);var seen: Dictionary={}
	for move: Dictionary in spec.layout_successor.district_moves:
		var delta: Vector2=v(move.new_foot)-v(move.old_foot);var count: int=0
		for row: Dictionary in out.additions:
			if row.id!=move.id: continue
			if v(row.world_foot_px)!=v(move.old_foot) or seen.has(row.id): return {}
			row.pos=v(row.pos)+delta/SIZE;row.world_foot_px=v(move.new_foot);row.physical_center_px=v(row.physical_center_px)+delta
			row.depth_sort_foot_y=float(row.depth_sort_foot_y)+delta.y/SIZE.y
			row.city_v3_solid_polygons_px=translate_polygons(row.city_v3_solid_polygons_px,delta);count+=1;seen[row.id]=true
		if count!=1: return {}
		count=0
		for placement: Dictionary in out.spec.placements:
			if placement.id==move.id:
				if v(placement.foot_px)!=v(move.old_foot): return {}
				placement.foot_px=v(move.new_foot);count+=1
		if count!=1: return {}
	var inverse: Dictionary=out.duplicate(true)
	for move: Dictionary in spec.layout_successor.district_moves:
		for index: int in inverse.additions.size():
			if inverse.additions[index].id==move.id: inverse.additions[index]=find(original.additions,move.id).duplicate(true)
		for index: int in inverse.spec.placements.size():
			if inverse.spec.placements[index].id==move.id: inverse.spec.placements[index]=find(original.spec.placements,move.id).duplicate(true)
	return out if seen.size()==3 and same(inverse,original) else {}
