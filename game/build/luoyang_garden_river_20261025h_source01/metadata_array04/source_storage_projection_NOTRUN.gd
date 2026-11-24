extends "res://build/luoyang_garden_river_20261025h_source01/metadata_array04/garden_river_compiler03_NOTREADY.gd"
## Only deterministic pre-raster storage expressions inherited from approved compiler.
## No compile(), source image, mask raster, route or body audit execution.
static func source_storage_projection(author: Dictionary,id: String) -> Dictionary:
	if id!=IDS[1]: return fail("NEW_PUBLICATION_GARDEN_ONLY_NO_ARTISAN_REPLAY",id)
	var selected: Array=[]
	for raw: Variant in author.get("scenes",[]):
		if raw is Dictionary and raw.get("scene_id")==id: selected.append(raw)
	if selected.size()!=1: return fail("UNIQUE_SCENE_AUTHOR",id)
	var data: Dictionary=selected[0]
	var adult: Dictionary=adult_doors_valid(author,data)
	if adult.get("ok")!=true: return adult
	if not pair(data.get("spawn")) or not path(data.get("background")) or not author.source_sha256.has(data.background): return fail("SCENE_BACKGROUND_OR_SPAWN",id)
	var visuals: Array[Dictionary]=[];var solids: Array[Dictionary]=[];var boxes: Dictionary={};var supports: Array[Rect2]=[];var assets_used: Dictionary={};var object_blocks: Dictionary={};var overlaps: Array=[]
	for raw: Dictionary in data.ground_sections:
		if not author.assets.has(raw.asset): return fail("GROUND_ASSET_MISSING",raw.asset)
		var result: Dictionary=tile_section(raw,author.assets[raw.asset])
		if not result.ok: return result
		visuals.append_array(result.rows);assets_used[raw.asset]=true
	for raw: Dictionary in data.placements:
		if not author.assets.has(raw.asset) or boxes.has(raw.id): return fail("PLACEMENT_ASSET_OR_DUPLICATE",raw.id)
		var result: Dictionary=placement(raw,author.assets[raw.asset])
		if not result.ok: return result
		visuals.append(result.visual);solids.append_array(result.blocks);supports.append_array(result.supports);boxes[raw.id]=result.alpha_box;object_blocks[raw.id]=result.blocks;assets_used[raw.asset]=true
	var waters: Array[PackedVector2Array]=[]
	for raw: Array in data.get("water_polygons",[]):
		var polygon:=PackedVector2Array()
		for point: Variant in raw:
			if not pair(point) or not Rect2(Vector2.ZERO,SIZE).has_point(v(point)): return fail("WATER_POLYGON_WORLD")
			polygon.append(v(point))
		waters.append(polygon)
	if waters.size()!=1 or data.get("river_bridge_walk_support")!=true or data.has("scenic_bridge_no_walk_support") or supports.size()!=1: return fail("GARDEN_ONE_RIVER_ONE_VISIBLE_DECK")
	var deck: Rect2=supports[0]
	if deck.size.y-24.0<128.0 or not Rect2(Vector2.ZERO,SIZE).encloses(deck): return fail("BRIDGE_FULL_BODY_CENTER_CLEARANCE")
	var deck_polygon: PackedVector2Array=PackedVector2Array([deck.position,Vector2(deck.end.x,deck.position.y),deck.end,Vector2(deck.position.x,deck.end.y)])
	var water_pieces: Array[PackedVector2Array]=Geometry2D.clip_polygons(waters[0],deck_polygon)
	if water_pieces.size()!=2: return fail("DECK_MUST_SPLIT_RIVER_INTO_EXACT_TWO_PHYSICAL_PIECES",water_pieces.size())
	for piece: PackedVector2Array in water_pieces:
		solids.append({"id":"garden_river_minus_deck_"+str(solids.size()),"polygon_px":piece.duplicate(),"water_closed":true})
	var bridge: Dictionary={}
	for visual: Dictionary in visuals:
		if visual.id=="garden_stone_bridge_walkable_25h": bridge=visual
	if bridge.is_empty(): return fail("BRIDGE_NATIVE_VISUAL_REQUIRED")
	var source_region: Rect2=rect(author.bridge_contract.front_region_source_rect)
	var source_size: Vector2=v(author.bridge_contract.source_size)
	var uniform: float=float(author.bridge_contract.uniform_scale)
	var bridge_center: Vector2=v(author.bridge_contract.bridge_center)
	var front_center: Vector2=bridge_center+(source_region.get_center()-source_size*.5)*uniform
	var front_foot: float=bridge_center.y+(float(author.bridge_contract.front_region_depth_source_y)-source_size.y*.5)*uniform
	visuals.append({"id":"garden_stone_bridge_front_rail_25h","texture":NATIVE_ROOT+"front_rail.res","pos":front_center/SIZE,"render_size_px":source_region.size*uniform,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":front_foot/SIZE.y,"garden_bridge_source_region":source_region})
	var walk_area: Rect2=rect(data.walk_rect)
	var scene:=SceneScript.new();scene.scene_id=StringName(id);scene.display_name=data.display_name;scene.is_walkable=true;scene.actor_positions_are_feet=true;scene.is_settlement=true;scene.background_path=data.background;scene.bgm_path=data.bgm;scene.player_spawn=v(data.spawn)/SIZE;scene.player_visual_scale=.91;scene.npc_visual_scale=1.0
	var layout:=WalkableMapLayout.new();layout.design_size=Vector2i(3072,2048);layout.walkable_mask_path=NATIVE_ROOT+id+"/walk.png"
	layout.visual_objects=visuals
	for solid: Dictionary in solids:
		if solid.has("polygon_px"):
			layout.blockers.append({"id":solid.id,"ground_polygon_world":solid.polygon_px.duplicate(),"walkability_margin":0.0})
		else:
			var area: Rect2=rect(solid.rect_px)
			layout.blockers.append({"id":solid.id,"pos":area.get_center()/SIZE,"size":area.size/SIZE,"walkability_margin":0.0})
	layout.walkable_regions=[PackedVector2Array([walk_area.position/SIZE,Vector2(walk_area.end.x,walk_area.position.y)/SIZE,walk_area.end/SIZE,Vector2(walk_area.position.x,walk_area.end.y)/SIZE])]
	for portal: Dictionary in data.portals:
		if not pair(portal.get("foot")) or not pair(portal.get("target_foot")) or not portal.get("target_scene") is String or portal.target_scene==id: return fail("PORTAL_NOT_FROZEN",portal.get("id"))
		var target_size: Vector2=v(portal.target_size) if pair(portal.get("target_size")) else SIZE
		if target_size.x<=0 or target_size.y<=0: return fail("PORTAL_TARGET_SIZE",portal.id)
		var projected: Dictionary={"id":portal.id,"pos":v(portal.foot)/SIZE,"size":Vector2(40,32)/SIZE,"auto_trigger":false,"target_scene":portal.target_scene,"target_pos":v(portal.target_foot)/target_size,"label":portal.label}
		if portal.has("target_scene_path"):
			if not path(portal.target_scene_path): return fail("PORTAL_RESOURCE_PATH",portal.id)
			projected.target_scene_path=portal.target_scene_path
		layout.portals.append(projected)
	if not data.npcs.is_empty(): return fail("NEW_QUARTER_NPCS_MUST_USE_FROZEN_PEOPLE_AUTHOR",id)
	var people_data: Variant=JSON.parse_string(FileAccess.get_file_as_string(PEOPLE.DATA))
	if not people_data is Dictionary or author.source_sha256.get(PEOPLE.DATA)!=PEOPLE.DATA_SHA: return fail("PEOPLE_DATA_NOT_PINNED",id)
	var people: Dictionary=PEOPLE.defs_exact(StringName(id),people_data)
	if people.get("ok")!=true: return people
	for npc: Dictionary in people.npcs: scene.npcs.append(npc.duplicate(true))
	if id==IDS[1]:
		var water_metadata_pieces: Array=[]
		for piece: PackedVector2Array in water_pieces: water_metadata_pieces.append(piece.duplicate())
		scene.set_meta("ap_garden_river25h",{"polygon":waters[0].duplicate(),"physics_pieces":water_metadata_pieces,"deck":deck,"texture":"res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/luoyang_riverside_garden_20261022ap/deepwater.res","rgba_sha256":"dc4ba07d16eb32cccc44ee72215e1f2904b5a1998c0163f80c7c5be78c37f63e","texture_size":Vector2i(200,280),"uniform_texture_scale":1.0,"z_index":-18,"front_region":source_region,"front_texture":NATIVE_ROOT+"front_rail.res","front_source":author.assets.stone_bridge.texture,"bridge_center":bridge_center,"bridge_scale":uniform,"whole_bridge_below_actors":true,"physics_is_visual_water_minus_visible_deck":true})
	scene.map_layout=layout
	return {"ok":true,"scene":scene,"solids":solids,"alpha_boxes":boxes,"author_scene":data,"npc_approaches":people.approaches,"exact_natural_depth_overlaps":overlaps,"adult_doors":adult.doors,"bridge_deck":deck,"water_visual_polygon":waters[0].duplicate(),"water_physics_pieces":water_pieces.duplicate(true)}
