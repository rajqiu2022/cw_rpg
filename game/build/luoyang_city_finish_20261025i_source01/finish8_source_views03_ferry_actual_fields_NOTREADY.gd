extends RefCounted
# Deterministic terminal views from fixed native resources and source expressions.
# No live owner, collector, Field, image sampling, packet decode or publication.
const SIZE: Vector2=Vector2(3072,2048)
static func v(raw: Variant) -> Vector2:
	if raw is Vector2: return raw
	if raw is Array and raw.size()==2: return Vector2(float(raw[0]),float(raw[1]))
	return Vector2(INF,INF)
static func p(raw: Variant) -> PackedVector2Array:
	var points: PackedVector2Array=PackedVector2Array()
	if not raw is Array and not raw is PackedVector2Array: return points
	for q: Variant in raw:
		var point: Vector2=v(q)
		if not point.is_finite(): return PackedVector2Array()
		points.append(point)
	return points
static func rect(low: Vector2,size: Vector2) -> PackedVector2Array:
	var high: Vector2=low+size
	return PackedVector2Array([low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)])
static func primitives(rows: Array) -> Array:
	var out: Array=[]
	for row: Dictionary in rows:
		for raw: Variant in row.get("city_v3_solid_polygons_px",[]):
			var poly: PackedVector2Array=p(raw)
			if poly.size()<3: return []
			out.append(poly)
		var size: Vector2=v(row.get("collision_size_px",[0,0]))
		if size.x>0 and size.y>0: out.append(rect(v(row.physical_center_px)-size*.5,size))
	return out
static func blocker_solids(blockers: Array,size: Vector2) -> Array:
	var out: Array=[]
	for row: Dictionary in blockers:
		if row.has("ground_polygon_world"):
			var world_polygon: PackedVector2Array=p(row.ground_polygon_world)
			if world_polygon.size()<3: return []
			out.append(world_polygon)
		elif row.has("ground_polygon"):
			var poly: PackedVector2Array=p(row.ground_polygon)
			if poly.size()<3: return []
			for i: int in range(poly.size()): poly[i]=poly[i]*size
			out.append(poly)
		elif row.has("pos") and row.has("size"):
			var box: Vector2=v(row.size)*size
			out.append(rect((v(row.pos)+v(row.get("foot_offset",[0,0])))*size-box*.5,box))
		else: return []
	return out
static func district_entries(author: Dictionary,id: String) -> Array:
	# Exact D98/C320 dictionary-only formula; no DG.project/triangulation.
	var out: Array=[]
	for placement: Dictionary in author.get("districts",{}).get(id,{}).get("placements",[]):
		if not String(placement.get("replaces","")).is_empty(): return []
		var asset: Dictionary=author.assets.get(String(placement.asset_id),{})
		if asset.is_empty(): return []
		var foot: Vector2=v(placement.foot_px);var size: Vector2=v(asset.size_px)
		var anchor: Vector2=v(asset.source_ground_anchor_px);var ratio: float=float(placement.scale)
		var shapes: Array=[]
		for raw: Variant in asset.get("ground_solid_polygons_px",[]):
			var shape: Array=[]
			for q: Vector2 in p(raw):
				var point: Vector2=foot+(q-anchor)*ratio;shape.append([float(point.x),float(point.y)])
			shapes.append(shape)
		out.append({"id":placement.id,"texture":String(asset.texture),"pos":(foot+(size*.5-anchor)*ratio)/SIZE,"render_size_px":size*ratio,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y,"world_foot_px":[float(foot.x),float(foot.y)],"physical_center_px":[float(foot.x),float(foot.y)],"collision_size_px":[0.0,0.0],"city_v3_solid_polygons_px":shapes,"blocking":true,"district_life_asset_id":placement.asset_id,"district_life_fade":placement.get("fade",false)})
	return out
static func find(rows: Array,id: String) -> Dictionary:
	var out: Dictionary={}
	for row: Dictionary in rows:
		if String(row.get("id",""))==id:
			if not out.is_empty(): return {}
			out=row
	return out
static func docks_parent(native: Array,projection: Dictionary,district: Dictionary) -> Array:
	if native.size()!=29: return []
	var extra: Array=district_entries(district,"ch4_s2_canal_docks")
	if extra.size()!=10: return []
	var out: Array=native.duplicate(true);out.append_array(extra)
	for id: String in projection.changed_ids:
		var old: Dictionary=find(projection.originals,id);var child: Dictionary=find(projection.child.objects,id);var row: Dictionary=find(out,id)
		if old.is_empty() or child.is_empty() or row.is_empty() or row.get("texture")!=old.texture or v(row.world_foot_px)!=v(old.world_foot_px) or v(row.render_size_px)!=v(old.render_size_px): return []
		var foot: Vector2=v(child.world_foot_px);var size: Vector2=v(child.render_size_px)
		row.pos=(foot+(Vector2(.5,.5)-v(child.foot_uv))*size)/SIZE
		row.render_size_px=size;row.world_foot_px=child.world_foot_px.duplicate();row.physical_center_px=child.physical_center_px.duplicate()
		row.depth_sort_foot_y=foot.y/SIZE.y;row.city_v3_solid_polygons_px=child.solid_polygons_px.duplicate(true)
		for key: String in ["depth_foot_y","world_origin_px","harbour_transform"]:
			if child.has(key): row[key]=child[key].duplicate(true) if child[key] is Dictionary or child[key] is Array else child[key]
	return out
static func named_rect_solids(rows: Array) -> Array:
	var out: Array=[]
	for row: Dictionary in rows:
		# Old production receipt explicitly stores position/size float32.
		if row.has("position") and row.has("size"): out.append(rect(v(row.position),v(row.size)))
		elif row.has("rect") and row.rect is Array and row.rect.size()==4: out.append(rect(Vector2(float(row.rect[0]),float(row.rect[1])),Vector2(float(row.rect[2]),float(row.rect[3]))))
		elif row.has("rect_px") and row.rect_px is Array and row.rect_px.size()==4: out.append(rect(Vector2(float(row.rect_px[0]),float(row.rect_px[1])),Vector2(float(row.rect_px[2]),float(row.rect_px[3]))))
		else: return []
	return out
static func portal_row(id: String,foot: Vector2,target: String,target_uv: Vector2,size: Vector2) -> Dictionary:
	return {"id":id,"pos":foot/size,"size":Vector2(40,32)/size,"target_scene":target,"target_pos":target_uv,"auto_trigger":false,"label":"City public branch","interaction_polygon_px":rect(foot-Vector2(20,16),Vector2(40,32))}
static func portal_delta(id: String,parent: Array,axis_author: Dictionary,artisan: Dictionary,temple_layout: WalkableMapLayout) -> Dictionary:
	var before: Array=[];var after: Array=[]
	if id=="ch4_s1_luoyang_yamen":
		for row: Dictionary in axis_author.scenes:
			if String(row.scene_id)==id:
				var spec: Dictionary=row.new_public_portal
				after.append(portal_row(String(spec.id),v(spec.source_foot_px),String(spec.target),v(spec.target_foot_px)/SIZE,SIZE))
	elif id=="luoyang_artisan_residential_20261022ap":
		for spec: Dictionary in artisan.portals:
			if String(spec.get("id",""))=="finish_i_artisan_to_yamen":
				after.append(portal_row(String(spec.id),v(spec.foot),String(spec.target_scene),v(spec.target_foot)/SIZE,SIZE))
	elif id=="ch4_s2_canal_docks":
		var old: Dictionary=find(parent,"canal_world_ferry")
		if old.is_empty() or String(old.get("action",""))!="world_map" or not String(old.get("target_scene","")).is_empty(): return {}
		var next: Dictionary=old.duplicate(true);next.action="";next.target_scene="ch4_s4_ancient_temple";next.target_pos=Vector2(1380,980)/Vector2(1536,1024)
		next.label="城内东支路 · 古寺"
		before.append(old.duplicate(true));after.append(next)
	elif id=="ch4_s3_luoyang_market":
		var old: Dictionary=find(parent,"to_ancient_temple")
		if old.is_empty(): return {}
		var next: Dictionary=old.duplicate(true);next.target_pos=Vector2(170,980)/Vector2(1536,1024)
		before.append(old.duplicate(true));after.append(next)
	elif id=="ch4_s4_ancient_temple":
		for portal: Dictionary in temple_layout.portals:
			var old: Dictionary=find(parent,String(portal.id))
			if old.is_empty(): return {}
			before.append(old.duplicate(true));after.append(portal.duplicate(true))
	return {"before":before,"after":after}
static func route_contracts() -> Array:
	# Exact source declarations. UV construction is native Vector2 division.
	return [
	 {"source_id":"ch4_s1_luoyang_yamen","target_id":"luoyang_artisan_residential_20261022ap","source_portal_id":"finish_i_yamen_to_artisan","source_foot":Vector2(120,1240),"normalized":Vector2(128,1300)/SIZE,"target_foot":Vector2(128,1300),"target_kind":"ORIGINAL_FIRST_COLD_LEASE"},
	 {"source_id":"luoyang_artisan_residential_20261022ap","target_id":"ch4_s1_luoyang_yamen","source_portal_id":"finish_i_artisan_to_yamen","source_foot":Vector2(128,1300),"normalized":Vector2(120,1240)/SIZE,"target_foot":Vector2(120,1240),"target_kind":"ORIGINAL_FIRST_COLD_LEASE"},
	 {"source_id":"ch4_s3_luoyang_market","target_id":"ch4_s4_ancient_temple","source_portal_id":"to_ancient_temple","source_foot":Vector2(1170,1600),"normalized":Vector2(170,980)/Vector2(1536,1024),"target_foot":(Vector2(170,980)/Vector2(1536,1024))*Vector2(1920,1280),"target_kind":"TEMPLE_DEFERRED_ORIGINAL_PREPARE"},
	 {"source_id":"ch4_s2_canal_docks","target_id":"ch4_s4_ancient_temple","source_portal_id":"canal_world_ferry","source_foot":Vector2(340,1840),"normalized":Vector2(1380,980)/Vector2(1536,1024),"target_foot":(Vector2(1380,980)/Vector2(1536,1024))*Vector2(1920,1280),"target_kind":"TEMPLE_DEFERRED_ORIGINAL_PREPARE"}]

static func named_polygons(rows: Array,kind: String="NEW_SOURCE_AUTHORED_GROUND_POLYGON") -> Array:
	var out: Array=[]
	for row: Dictionary in rows:
		for ordinal: int in range(row.get("city_v3_solid_polygons_px",[]).size()):
			out.append({"id":String(row.id)+"_poly_"+str(ordinal),"owner_id":String(row.id),"kind":kind,"points_px":p(row.city_v3_solid_polygons_px[ordinal])})
	return out
static func named_artisan(craft: Dictionary,a2: Dictionary) -> Array:
	var out: Array=[]
	for row: Dictionary in craft.building_and_life_render:
		var original_placement: Dictionary={}
		for source: Dictionary in craft.scene_source.placements:
			if String(source.id)==String(row.id): original_placement=source
		var rectangle_count: int=0
		if not original_placement.is_empty(): rectangle_count=a2.assets[String(original_placement.asset)].get("solid_rects",[]).size()
		for index: int in range(row.city_v3_solid_polygons_px.size()):
			out.append({"id":String(row.id)+"_source_shape_"+str(index),"kind":"AP_RECT_CEIL_LOW_FLOOR_HIGH_INCLUSIVE" if index<rectangle_count else "SOURCE_POLYGON","points_px":p(row.city_v3_solid_polygons_px[index])})
	return out
static func native_temple_render(authored: Dictionary,size: Vector2) -> Array:
	# Same original TEMPLE.project_objects expression, not native raw placement rows.
	var out: Array=[]
	for placement: Dictionary in authored.placements:
		var asset: Dictionary={}
		for source: Dictionary in authored.assets:
			if String(source.id)==String(placement.asset_id): asset=source
		if asset.is_empty(): return []
		var ratio: float=float(placement.scale);var foot: Vector2=v(placement.foot_px)
		out.append({"id":String(placement.id),"texture":String(asset.texture),"centered":false,"pos":(foot-v(asset.source_ground_anchor_px)*ratio)/Vector2(1536,1024),"render_size_px":v(asset.size_px)*ratio*(size/Vector2(1536,1024)),"sort_by_feet":true,"depth_sort_foot_y":foot.y/1024.0})
	return out
static func scene_spec(author: Dictionary,id: String) -> Dictionary:
	for row: Dictionary in author.get("scenes",[]):
		if String(row.get("scene_id",""))==id: return row
	return {}
static func derive(id: String,parent_scene: SceneScript,inputs: Dictionary,helpers: Dictionary) -> Dictionary:
	if parent_scene==null or parent_scene.map_layout==null or String(parent_scene.scene_id)!=id: return {}
	var native: Array=parent_scene.map_layout.visual_objects
	var parent: Array=[];var next: Array=[];var old_solids: Array=[];var solids: Array=[];var added_named: Array=[]
	var floor: Array=[];var migrations: Array=[];var actors: Array=[];var interaction_patches: Array=[]
	var local: Dictionary={};var craft: Dictionary=inputs.craft
	var size: Vector2=Vector2(1920,1280) if id=="ch4_s4_ancient_temple" else SIZE
	var next_temple_layout: WalkableMapLayout
	if id in ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen"]:
		var seed: Dictionary=inputs.parent_seed[id]
		if var_to_bytes(native)!=var_to_bytes(seed.native_visual_rows): return {}
		local=helpers.axis.derive(id,inputs.axis_author,inputs.axis_library,inputs.parent_seed)
		if local.get("ok")!=true: return {}
		parent=local.parent_render;next=local.render_objects;solids=local.combined_ground
		for row: Dictionary in local.parent_primitives: old_solids.append(row.points_px)
		var spec: Dictionary=scene_spec(inputs.axis_author,id)
		for raw: Dictionary in spec.new_all_primitive_rows_source_model:
			added_named.append({"id":String(raw.id),"owner_id":String(raw.owner_id),"kind":String(raw.kind),"points_px":p(raw.points_px)})
		for move: Dictionary in spec.get("same_interaction_migrations",[]):
			var old: Dictionary=find(parent_scene.map_layout.interactions,String(move.id))
			if old.is_empty() or v(old.get("pos"))*SIZE!=v(move.old_stand_world_px) or var_to_bytes(p(old.get("city_v3_interaction_polygon_px",[])))!=var_to_bytes(p(move.old_interaction_polygon_world_px)): return {}
			var changed: Dictionary=old.duplicate(true);changed.pos=v(move.new_stand_world_px)/SIZE
			changed.city_v3_interaction_polygon_px=p(move.new_interaction_polygon_world_f32)
			interaction_patches.append({"id":String(move.id),"before":old.duplicate(true),"after":changed})
	elif id=="luoyang_artisan_residential_20261022ap":
		if native.size()!=136 or craft.get("ok")!=true: return {}
		parent=native;next=native.slice(0,118)
		var props: Array=helpers.payload.retain_old_properties(native.slice(118),craft.building_and_life_render)
		if props.size()!=21: return {}
		next.append_array(props);old_solids=craft.old_ground31;solids=craft.new_ground44
	elif id=="ch4_s4_ancient_temple":
		local=helpers.temple.build(parent_scene,inputs.temple_old_author,inputs.temple_author)
		if local.get("ok")!=true: return {}
		next_temple_layout=local.layout
		parent=native_temple_render(inputs.temple_old_author,size);next=native_temple_render(inputs.temple_author,size)
		old_solids=blocker_solids(parent_scene.map_layout.blockers,size);solids=blocker_solids(next_temple_layout.blockers,size)
		for region: Variant in inputs.temple_author.geometry.floor_regions_px:
			var points: PackedVector2Array=p(region)
			for i: int in range(points.size()): points[i]=(points[i]/Vector2(1536,1024))*size
			floor.append(points)
	else:
		if id=="ch4_s3_luoyang_market":
			if native.size()!=25: return {}
			parent=inputs.market_projection.render;old_solids=inputs.market_geometry
		elif id=="ch4_s2_canal_docks":
			parent=docks_parent(native,inputs.docks_projection,inputs.district_author);old_solids=inputs.docks_geometry
		elif id=="luoyang_estate_riverside_20261021ai":
			parent=native;old_solids=blocker_solids(parent_scene.map_layout.blockers,size)
		elif id=="luoyang_riverside_garden_20261022ap":
			parent=native;old_solids=blocker_solids(parent_scene.map_layout.blockers,size)
		else: return {}
		var kitchen: Dictionary=find(craft.building_and_life_render,"new_plain_kitchen_rear_house")
		local=helpers.adjacent.derive(id,inputs.adjacent_author,inputs.adjacent_library,parent,kitchen,parent if id=="ch4_s2_canal_docks" else [])
		if local.get("ok")!=true: return {}
		next=local.render;solids=old_solids.duplicate(true);solids.append_array(local.new_ground)
		added_named=named_polygons(local.added_render)
		migrations=local.NPC_migrations;actors=helpers.payload.source_NPC_rows(local.new_NPCs,size)
	var portal_change: Dictionary=portal_delta(id,parent_scene.map_layout.portals,inputs.axis_author,craft.scene_source,next_temple_layout)
	if portal_change.is_empty(): return {}
	if parent.is_empty() or next.is_empty() or old_solids.is_empty() or solids.is_empty(): return {}
	return {"ok":true,"scene_id":id,"world_size_px":size,"parent_native_navigation":native,"parent_navigation":parent,"effective_navigation":next,"parent_solids":old_solids,"effective_solids":solids,"parent_blockers":parent_scene.map_layout.blockers,"portal_before":portal_change.before,"portal_after":portal_change.after,"interaction_patches":interaction_patches,"npc_migrations":migrations,"new_NPCs":actors,"effective_walkable_polygons":floor,"named_ground":added_named,"local_projection":local}

static func diagnose(id: String,parent_scene: SceneScript,inputs: Dictionary,helpers: Dictionary) -> Dictionary:
	var result: Dictionary={"scene_present":parent_scene!=null}
	if parent_scene==null or parent_scene.map_layout==null: return result
	var native: Array=parent_scene.map_layout.visual_objects
	result["scene_id"]=String(parent_scene.scene_id);result["layout_path"]=parent_scene.map_layout.resource_path
	if id in ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen"]:
		var seed: Dictionary=inputs.parent_seed[id]
		result["native_count"]=native.size();result["seed_count"]=seed.native_visual_rows.size()
		result["native_typed_equal"]=var_to_bytes(native)==var_to_bytes(seed.native_visual_rows)
		result["native_var_sha"]=helpers.axis.digest(native);result["seed_var_sha"]=helpers.axis.digest(seed.native_visual_rows)
		result["axis_source_derive_ok"]=helpers.axis.derive(id,inputs.axis_author,inputs.axis_library,inputs.parent_seed).get("ok")==true
		result["interactions"]=[]
		var spec: Dictionary=scene_spec(inputs.axis_author,id)
		for move: Dictionary in spec.get("same_interaction_migrations",[]):
			var prior: Dictionary=find(parent_scene.map_layout.interactions,String(move.id))
			result.interactions.append({"id":move.id,"present":not prior.is_empty(),"keys":prior.keys(),"position":prior.get("pos"),"expected_position":v(move.old_stand_world_px)/SIZE,"old_polygon_type":typeof(prior.get("city_v3_interaction_polygon_px")),"polygon_exact":var_to_bytes(p(prior.get("city_v3_interaction_polygon_px",[])))==var_to_bytes(p(move.old_interaction_polygon_world_px))})
	if id=="ch4_s2_canal_docks":
		result["native_count"]=native.size();result["DG_entries_count"]=district_entries(inputs.district_author,id).size()
		var parent: Array=docks_parent(native,inputs.docks_projection,inputs.district_author)
		result["parent39_source_projection_count"]=parent.size();result["changed_ids"]=inputs.docks_projection.get("changed_ids",[])
		result["three_rows"]=[]
		for target: String in inputs.docks_projection.get("changed_ids",[]):
			var prior: Dictionary=find(native,target);var declared: Dictionary=find(inputs.docks_projection.originals,target)
			result.three_rows.append({"id":target,"present":not prior.is_empty(),"texture":prior.get("texture"),"expected_texture":declared.get("texture"),"world_foot":prior.get("world_foot_px"),"expected_world_foot":declared.get("world_foot_px"),"render_size":prior.get("render_size_px"),"expected_render_size":declared.get("render_size_px")})
		result["ferry_source_row"]=find(parent_scene.map_layout.portals,"canal_world_ferry").duplicate(true)
		if not parent.is_empty():
			var craft: Dictionary=inputs.craft
			result["adjacent_source_derive_ok"]=helpers.adjacent.derive(id,inputs.adjacent_author,inputs.adjacent_library,parent,find(craft.building_and_life_render,"new_plain_kitchen_rear_house"),parent).get("ok")==true
	return result
