extends RefCounted
## Two-domain child author. Parent Scene/NPC/interaction/portal values are not
## editable through this interface; only explicit new physical objects/routes.
const PATH="res://scripts/city/luoyang_harbour_life_author_retry3_20261016.gd"
const META="city_harbour_life_author_sha_20261016"
const IDS=[&"ch4_s0_luoyang_gate",&"ch4_s2_canal_docks"]
const DOCK="res://art/maps/luoyang_city_revision_v1_20261015/ch4_s2_canal_docks/candidate_manifest.json"
const MARKET="res://art/maps/luoyang_city_revision_retry2_20261015/ch4_s3_luoyang_market/candidate_manifest.json"
const COMPONENTS="res://art/maps/luoyang_harbour_life_20261016/components-author-v1.json"
const ROOT="res://art/maps/luoyang_harbour_life_20261016/"
const PINS={DOCK:"fae2b99d98499fc255c9c5607b9811fd29d6b539a2969cec0937884f29f02451",MARKET:"e103039fcf1d332fbb9cebe289cee88bcdb82c4c5fc28274e3737be489dc62f3",COMPONENTS:"920a06ca4e2390c831215c643c9bde5263f85d64ca1b3472cfa9a52021d8b2bb",ROOT+"cargo_ship_v1.png":"d3cfd7f962d6f28ebab88ce1cb69d757e3ed7d4e491c34704b804c655b6a7ee8",ROOT+"covered_ferry_v1.png":"d67140a7afa0fdfffff97de9e34a0680b0069fc9dbd05bbcf85fb7e4ef989357",ROOT+"harbour_warehouse_v1.png":"2fdc857210f17b59c4a6132e33a53a1b092f940a356ceb90266d1a11c917171e"}
static func v(value: Variant) -> Vector2:
	return Vector2(value[0],value[1]) if value is Array and value.size()==2 else Vector2(INF,INF)
static func xy(value: Vector2) -> Array: return [float(value.x),float(value.y)]
static func author_sha() -> String: return FileAccess.get_sha256(PATH)
static func sources_valid(cancel: Callable=Callable()) -> bool:
	for path: String in PINS:
		if cancel.is_valid() and cancel.call(): return false
		if FileAccess.get_sha256(path)!=PINS[path]: return false
	return true
static func spec(id: StringName) -> Dictionary:
	if id not in IDS: return {}
	if id==IDS[0]: return {"scene_id":String(id),"parent_objects":28,"remove_objects":[],"stock":[],"components":[],"routes":[],"protected_feet":[[1536,500],[1536,1860],[1740,1540],[700,1460]],"ordinary_houses_added":false}
	return {"scene_id":String(id),"parent_objects":21,"remove_objects":[{"id":"moored_canal_boat","foot":[2570,1430]}],
		"stock":[
			{"id":"harbour_small_cargo_store","manifest":DOCK,"source_id":"north_canal_warehouse","source_foot":[870,580],"foot":[500,1130],"ratio":1.0,"usage":"Existing masonry cargo-store at unchanged native adult doorway scale, approximately154px visible door"},
			{"id":"harbour_rope_shop","manifest":MARKET,"source_id":"shop","source_foot":[2320,850],"foot":[720,1420],"ratio":0.85,"usage":"Existing single-shop frontage reused, no new shop rules or room door"},
			{"id":"harbour_cargo_trade_front","manifest":MARKET,"source_id":"southwest_market_front","source_foot":[600,1810],"foot":[1720,1790],"ratio":0.85,"usage":"Existing broad two-bay trading frontage, not a newly authored house"},
			{"id":"harbour_loading_shelter","manifest":MARKET,"source_id":"goods_stall","source_foot":[1320,1160],"foot":[1610,1010],"ratio":1.0,"usage":"Open-sided goods-handling shelter"},
			{"id":"harbour_quay_supply_shop","manifest":MARKET,"source_id":"shop","source_foot":[2320,850],"foot":[1930,530],"ratio":0.8,"usage":"Second small supply shop, separated from warehouse main frontage"}],
		"components":[
			{"id":"harbour_main_warehouse","component":"harbour_warehouse_v1","foot":[1450,650],"scale":0.62},
			{"id":"harbour_cargo_ship","component":"cargo_ship_v1","water_center":[2600,1110],"scale":0.48},
			{"id":"harbour_covered_ferry","component":"covered_ferry_v1","water_center":[2610,1700],"scale":0.30}],
		"routes":[],"protected_feet":[[260,790],[260,1740],[2140,1840],[940,750],[1740,1310],[1830,1190],[1930,970]],"new_door_enabled":false}
static func find(items: Array,id: String) -> Dictionary:
	var result: Dictionary={}
	for item: Dictionary in items:
		if item.get("id")==id:
			if not result.is_empty(): return {}
			result=item
	return result
static func _transform(source: Dictionary,item: Dictionary) -> Dictionary:
	var old:=v(source.get("world_foot_px")); var foot:=v(item.foot); var ratio:=float(item.ratio)
	if old!=v(item.source_foot) or not foot.is_finite() or ratio<=0: return {}
	var result:=source.duplicate(true)
	result.id=item.id; result.world_foot_px=xy(foot); result.physical_center_px=xy(foot)
	result.render_size_px=xy(v(source.render_size_px)*ratio); result.depth_foot_y=float(foot.y)
	if result.has("world_origin_px"): result.world_origin_px=xy(foot+(v(source.world_origin_px)-old)*ratio)
	# These donor buildings have polygon-only physical bases. Do not silently
	# translate a nonzero box through a new, approximate numeric representation.
	if v(source.collision_size_px)!=Vector2.ZERO: return {}
	result.collision_size_px=[0.0,0.0]
	var solids: Array=[]
	for polygon: Variant in source.solid_polygons_px:
		if not polygon is Array: return {}
		var changed: Array=[]
		for point: Variant in polygon: changed.append(xy(foot+(v(point)-old)*ratio))
		solids.append(changed)
	result.solid_polygons_px=solids
	result["harbour_transform"]={"source_id":source.id,"source_foot":xy(old),"foot":xy(foot),"ratio":ratio}
	result["harbour_usage"]=item.usage; result["harbour_no_new_door"]=true
	return result
static func _component(source: Dictionary,item: Dictionary) -> Dictionary:
	var scale:=float(item.scale); var size:=v(source.source_size_px)
	var anchor:=v(source.source_ground_anchor_px); var foot:=v(item.get("foot",[]))
	var water: bool=source.get("role","")=="water_decoration_only_no_boarding_or_task"
	if water: foot=(v(item.water_center)+(anchor-v(source.source_water_placement_anchor_px))*scale).round()
	if not foot.is_finite() or scale<=0 or not size.is_finite(): return {}
	var solids: Array=[]
	for polygon: Array in source.ground_solid_polygons_px:
		var changed: Array=[]
		for point: Variant in polygon: changed.append(xy(foot+(v(point)-anchor)*scale))
		solids.append(changed)
	return {"id":item.id,"texture":ROOT+String(source.id)+".png","source":ROOT+String(source.id)+".png","source_sha256":source.source_sha256,"source_size_px":xy(size),"world_foot_px":xy(foot),"physical_center_px":xy(foot),"world_origin_px":xy(foot-anchor*scale),"render_size_px":xy(size*scale),"foot_uv":xy(anchor/size),"depth_foot_y":float(foot.y),"blocking":not solids.is_empty(),"collision_size_px":[0.0,0.0],"solid_polygons_px":solids,"role":"water_decoration" if water else "building","sort_by_feet":true,"walk_support":false,"ghost_occlusion":false,"interaction_required":false,"harbour_component":source.id,"harbour_component_scale":scale,"harbour_no_new_door":true,"harbour_water_center":item.get("water_center",[]),"harbour_source_water_hull":source.get("water_hull_projection_polygon_px",[]).duplicate(true)}
static func compose(parent: Dictionary,id: StringName) -> Dictionary:
	var data:=spec(id)
	if data.is_empty() or parent.get("canonical_scene_id")!=String(id) or parent.get("objects",[]).size()!=int(data.parent_objects): return {}
	if id==IDS[0] and not parent.has("gate_fortification_manifest_sha"): return {}
	if id==IDS[1] and (parent.get("city_revision_manifest_sha")!=PINS[DOCK] or parent.get("city_revision_binding_sha")!="aa2cc1e741598a9dfc38e2c065e90c892a2795c1eb54456c745426e3a7782dac"): return {}
	var result:=parent.duplicate(true)
	for removed: Dictionary in data.remove_objects:
		var old:=find(result.objects,removed.id)
		if old.is_empty() or v(old.world_foot_px)!=v(removed.foot): return {}
		result.objects.erase(old)
	var donors: Dictionary={}
	for item: Dictionary in data.stock:
		if not donors.has(item.manifest): donors[item.manifest]=JSON.parse_string(FileAccess.get_file_as_string(item.manifest))
		var source:=find(donors[item.manifest].get("objects",[]),item.source_id)
		if source.is_empty() or not find(result.objects,item.id).is_empty(): return {}
		var changed:=_transform(source,item)
		if changed.is_empty(): return {}
		result.objects.append(changed)
	var components: Variant=JSON.parse_string(FileAccess.get_file_as_string(COMPONENTS))
	if not components is Dictionary: return {}
	for item: Dictionary in data.components:
		var source:=find(components.get("components",[]),item.component)
		if source.is_empty() or not find(result.objects,item.id).is_empty(): return {}
		result.objects.append(_component(source,item))
	result["harbour_author_sha"]=author_sha(); result["harbour_parent_gameplay_unchanged"]=true
	return result
static func apply_scene(parent: SceneScript,record: Dictionary,walk: String) -> SceneScript:
	if parent==null or parent.scene_id not in IDS or parent.map_layout==null or record.get("harbour_author_sha")!=author_sha(): return null
	var result:=parent.duplicate(true) as SceneScript
	result.map_layout=parent.map_layout.duplicate(true) as WalkableMapLayout
	if parent.scene_id==IDS[0]:
		# Gate has ZERO object edits in this change. Preserve the fully proven
		# parent's original GATE.apply_entry projection, including Rect2i atlas,
		# exact gate_sort/z/ghost flags and removal of unused world_origin_px.
		# Re-generating these unchanged entries would alter real moat semantics.
		result.map_layout.walkable_mask_path=walk
		result.set_meta(META,author_sha()); result.set_meta("harbour_parent_scene_id",String(parent.scene_id))
		return result
	var entries: Array[Dictionary]=[]
	for object: Dictionary in record.objects:
		if not String(object.id).begins_with("harbour_"):
			# All twenty retained dock objects are unchanged. Keep their complete
			# proven parent projection; removed old boat has no record entry here.
			var old:=find(parent.map_layout.visual_objects,String(object.id))
			if old.is_empty(): return null
			entries.append(old.duplicate(true)); continue
		var entry:=object.duplicate(true); var foot:=v(object.world_foot_px); var render:=v(object.render_size_px)
		# Field renders through native pos/foot_uv/render_size below, never this
		# redundant source annotation. Full original author/record retains it.
		# 24824 diagnosed all eight differences only at these unused new values.
		entry.erase("world_origin_px")
		entry.pos=(foot+(Vector2(.5,.5)-v(object.foot_uv))*render)/Vector2(3072,2048)
		entry.render_size_px=render; entry.centered=true; entry.sort_by_feet=object.get("role","")!="ground_overlay"
		entry.depth_sort_foot_y=foot.y/2048.0
		entry.city_v3_solid_polygons_px=object.solid_polygons_px.duplicate(true); entry.erase("solid_polygons_px")
		entries.append(entry)
	result.map_layout.visual_objects=entries; result.map_layout.walkable_mask_path=walk
	result.set_meta(META,author_sha()); result.set_meta("harbour_parent_scene_id",String(parent.scene_id))
	return result
