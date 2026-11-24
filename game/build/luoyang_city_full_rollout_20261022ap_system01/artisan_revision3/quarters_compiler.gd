extends RefCounted
## AP native quarter compiler. Source art, body, masks and real portals share
## one author; creating a visual never makes an obstacle implicitly walkable.
const SIZE=Vector2(3072,2048)
const IDS=["luoyang_artisan_residential_20261022ap","luoyang_riverside_garden_20261022ap"]
const META="luoyang_full_city_AP"
const NATIVE_ROOT="res://data/maps/luoyang_full_city_20261022ap/quarters/revision3/"
const B_PATH="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const PEOPLE=preload("res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people.gd")
static func b() -> Variant: return load(B_PATH)
static func pair(value: Variant) -> bool:
	return value is Array and value.size()==2 and number(value[0]) and number(value[1])
static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
static func v(value: Array) -> Vector2: return Vector2(float(value[0]),float(value[1]))
static func rect(value: Array) -> Rect2: return Rect2(float(value[0]),float(value[1]),float(value[2]),float(value[3]))
static func path(value: Variant) -> bool: return value is String and value.begins_with("res://") and not ".." in value
static func fail(error: String,detail: Variant=null) -> Dictionary: return {"ok":false,"error":error,"detail":detail}
static func source_pins(author: Dictionary) -> Dictionary:
	if author.get("schema_version")!=1 or author.get("status")!="ART_BOUND_AP_QUARTERS" or not pair(author.get("design_size")) or v(author.design_size)!=SIZE or not pair(author.get("body")) or v(author.body)!=Vector2(34,24): return fail("AUTHOR_NOT_ART_BOUND")
	if not author.get("assets") is Dictionary or author.assets.is_empty() or not author.get("source_sha256") is Dictionary: return fail("NO_ART_BINDINGS")
	var pins: Dictionary=author.source_sha256.duplicate(true)
	for asset_id: String in author.assets:
		var asset: Dictionary=author.assets[asset_id]
		if not path(asset.get("texture")) or not pins.has(asset.texture) or not pair(asset.get("source_size")) or not pair(asset.get("ground_anchor")) or not asset.get("used_rect") is Array or asset.used_rect.size()!=4: return fail("ASSET_FIELDS",asset_id)
		var source_size: Vector2=v(asset.source_size)
		if source_size.x<=0 or source_size.y<=0 or source_size.x!=floorf(source_size.x) or source_size.y!=floorf(source_size.y) or not Rect2(Vector2.ZERO,source_size).has_point(v(asset.ground_anchor)): return fail("ASSET_INTEGER_SIZE_OR_ANCHOR",asset_id)
		for scalar: Variant in asset.used_rect:
			if not number(scalar) or float(scalar)!=floorf(float(scalar)): return fail("USED_RECT_INTEGER",asset_id)
		if not Rect2(Vector2.ZERO,source_size).encloses(rect(asset.used_rect)) or not rect(asset.used_rect).has_area(): return fail("USED_RECT_DOMAIN",asset_id)
	for p: Variant in pins:
		if not path(p) or not pins[p] is String or pins[p].length()!=64 or FileAccess.get_sha256(p)!=pins[p]: return fail("PINNED_SOURCE_CHANGED",p)
	return {"ok":true,"pins":pins}
static func source_image(asset: Dictionary) -> Image:
	var image: Image
	if String(asset.texture).ends_with(".tres"):
		var native_texture: Texture2D=ResourceLoader.load(asset.texture) as Texture2D
		image=native_texture.get_image() if native_texture!=null else null
	else: image=Image.load_from_file(asset.texture)
	if image==null: return null
	image.convert(Image.FORMAT_RGBA8)
	if Vector2(image.get_size())!=v(asset.source_size) or image.get_used_rect()!=Rect2i(rect(asset.used_rect)): return null
	return image
static func placement(row: Dictionary,asset: Dictionary) -> Dictionary:
	if not row.get("id") is String or not pair(row.get("foot")) or not number(row.get("width")) or float(row.width)<=0: return fail("PLACEMENT_FIELDS",row.get("id"))
	var scale_value: float=float(row.width)/float(asset.used_rect[2])
	var foot: Vector2=v(row.foot);var source_size: Vector2=v(asset.source_size);var anchor: Vector2=v(asset.ground_anchor)
	var full: Rect2=rect(asset.used_rect)
	var box:=Rect2(foot+(full.position-anchor)*scale_value,full.size*scale_value)
	if not Rect2(Vector2.ZERO,SIZE).encloses(box): return fail("FULL_ALPHA_OUTSIDE_WORLD",row.id)
	if asset.has("door_lower_px") and float(asset.door_lower_px)*scale_value<120.0: return fail("ADULT_DOOR_BELOW_120",row.id)
	var blocks: Array[Dictionary]=[]
	for i: int in asset.get("solid_rects",[]).size():
		var raw: Variant=asset.solid_rects[i]
		if not raw is Array or raw.size()!=4 or not Rect2(Vector2.ZERO,source_size).encloses(rect(raw)) or not rect(raw).has_area(): return fail("SOURCE_SOLID_RECT",row.id)
		var world:=Rect2(foot+(rect(raw).position-anchor)*scale_value,rect(raw).size*scale_value)
		blocks.append({"id":row.id+"_base_"+str(i),"rect_px":[world.position.x,world.position.y,world.size.x,world.size.y],"asset":row.asset,"source_rect":raw.duplicate()})
	for i: int in asset.get("solid_polygons",[]).size():
		var original: Array=asset.solid_polygons[i];var polygon:=PackedVector2Array()
		for raw: Variant in original:
			if not pair(raw) or not Rect2(Vector2.ZERO,source_size).has_point(v(raw)): return fail("SOURCE_POLYGON_DOMAIN",row.id)
			polygon.append(foot+(v(raw)-anchor)*scale_value)
		if polygon.size()<3 or Geometry2D.triangulate_polygon(polygon).is_empty(): return fail("SOURCE_POLYGON_NOT_TRIANGULABLE",row.id)
		blocks.append({"id":row.id+"_hull_"+str(i),"polygon_px":polygon,"asset":row.asset,"source_polygon":original.duplicate(true)})
	var supports: Array[Rect2]=[]
	for raw: Array in asset.get("support_rects",[]):
		if raw.size()!=4 or not rect(raw).has_area() or not Rect2(Vector2.ZERO,source_size).encloses(rect(raw)): return fail("SOURCE_SUPPORT_RECT",row.id)
		supports.append(Rect2(foot+(rect(raw).position-anchor)*scale_value,rect(raw).size*scale_value))
	var visual: Dictionary={"id":row.id,"texture":asset.texture,"pos":(foot+(source_size*.5-anchor)*scale_value)/SIZE,"render_size_px":source_size*scale_value,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y}
	return {"ok":true,"visual":visual,"blocks":blocks,"supports":supports,"alpha_box":box,"foot":foot,"scale":scale_value}
static func tile_section(section: Dictionary,asset: Dictionary) -> Dictionary:
	if not section.get("rect") is Array or section.rect.size()!=4 or not pair(section.get("tile_size")): return fail("GROUND_FIELDS",section.get("id"))
	var area: Rect2=rect(section.rect);var tile: Vector2=v(section.tile_size);var size: Vector2=v(asset.source_size)
	if tile.x<=0 or tile.y<=0 or tile.x/size.x!=tile.y/size.y or not Rect2(Vector2.ZERO,SIZE).encloses(area): return fail("UNIFORM_NATIVE_TILE_SECTION",section.id)
	var scale_value: float=tile.x/size.x
	var out: Array[Dictionary]=[]
	for y: int in ceili(area.size.y/tile.y):
		for x: int in ceili(area.size.x/tile.x):
			var offset:=Vector2(x,y)*tile
			var shown: Vector2=(area.size-offset).min(tile)
			var texture: String=asset.texture
			if shown!=tile:
				var crop_size: Vector2=shown/scale_value
				if crop_size.x!=floorf(crop_size.x) or crop_size.y!=floorf(crop_size.y): return fail("EXACT_INTEGER_TILE_CROP",section.id)
				var key: String=str(int(crop_size.x))+"x"+str(int(crop_size.y))
				texture=String(section.get("clip_textures",{}).get(key,""))
				if texture.is_empty(): return fail("DECLARED_NATIVE_ATLAS_EDGE_REQUIRED",{"section":section.id,"crop":key})
				var edge: AtlasTexture=ResourceLoader.load(texture) as AtlasTexture
				if edge==null or edge.atlas==null or edge.atlas.resource_path!=asset.texture or edge.region!=Rect2(Vector2.ZERO,crop_size) or edge.margin!=Rect2(): return fail("EXACT_TILE_ATLAS_SOURCE",texture)
			out.append({"id":String(section.id)+"_"+str(x)+"_"+str(y),"texture":texture,"pos":(area.position+offset+shown*.5)/SIZE,"render_size_px":shown,"centered":true,"sort_by_feet":false,"z_index":int(section.z)})
	return {"ok":true,"rows":out}
static func visual_pair_allowed(left: String,right: String,data: Dictionary) -> bool:
	var count: int=0
	for pair_ids: Array in data.get("visual_depth_overlap_pairs",[]):
		if pair_ids.size()==2 and ((pair_ids[0]==left and pair_ids[1]==right) or (pair_ids[1]==left and pair_ids[0]==right)): count+=1
	return count==1
static func solid_polygon(solid: Dictionary) -> PackedVector2Array:
	if solid.has("polygon_px"): return solid.polygon_px
	var area: Rect2=rect(solid.rect_px)
	return PackedVector2Array([area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)])
static func pair_bodies_clear(left: Array,right: Array) -> bool:
	for a: Dictionary in left:
		for b_solid: Dictionary in right:
			var ap: PackedVector2Array=solid_polygon(a);var bp: PackedVector2Array=solid_polygon(b_solid)
			if not Geometry2D.intersect_polygons(ap,bp).is_empty(): return false
			for i: int in ap.size():
				for j: int in bp.size():
					if Geometry2D.segment_intersects_segment(ap[i],ap[(i+1)%ap.size()],bp[j],bp[(j+1)%bp.size()])!=null: return false
	return true
static func compile(author: Dictionary,id: String) -> Dictionary:
	if id not in IDS: return fail("UNKNOWN_AP_QUARTER",id)
	var selected: Array=[]
	for raw: Variant in author.get("scenes",[]):
		if raw is Dictionary and raw.get("scene_id")==id: selected.append(raw)
	if selected.size()!=1: return fail("UNIQUE_SCENE_AUTHOR",id)
	var data: Dictionary=selected[0]
	if not pair(data.get("spawn")) or not path(data.get("background")) or not author.source_sha256.has(data.background): return fail("SCENE_BACKGROUND_OR_SPAWN",id)
	var background: Image=Image.load_from_file(data.background)
	if background==null or background.get_width()*2048!=background.get_height()*3072: return fail("REAL_3_TO_2_BACKGROUND",id)
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
		for other: String in boxes:
			if result.alpha_box.intersects(boxes[other]):
				if not visual_pair_allowed(other,raw.id,data) or not pair_bodies_clear(object_blocks[other],result.blocks): return fail("UNAPPROVED_ALPHA_OR_TRUE_BODY_INTERSECTION",[other,raw.id])
				overlaps.append([other,raw.id])
		visuals.append(result.visual);solids.append_array(result.blocks);supports.append_array(result.supports);boxes[raw.id]=result.alpha_box;object_blocks[raw.id]=result.blocks;assets_used[raw.asset]=true
	for asset_id: String in assets_used:
		if source_image(author.assets[asset_id])==null: return fail("ACTUAL_SOURCE_SIZE_FULL_ALPHA",asset_id)
	var image:=Image.create(3072,2048,false,Image.FORMAT_RGBA8);image.fill(Color(0,0,0,1))
	var walk_area: Rect2=rect(data.walk_rect)
	if not Rect2(Vector2.ZERO,SIZE).encloses(walk_area): return fail("WALK_DOMAIN")
	image.fill_rect(Rect2i(walk_area),Color.WHITE)
	for raw: Array in data.water_regions: paint_closed(image,rect(raw),Color(0,0,0,1))
	# Positive bridge support opens only measured visible support within water;
	# bank/column real solids are painted afterwards and always win.
	for support: Rect2 in supports: paint_closed(image,support,Color.WHITE)
	for solid: Dictionary in solids:
		if solid.has("polygon_px"): paint_polygon(image,solid.polygon_px)
		else: paint_closed(image,rect(solid.rect_px),Color(0,0,0,1))
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
	scene.map_layout=layout
	return {"ok":true,"scene":scene,"mask":image,"solids":solids,"alpha_boxes":boxes,"author_scene":data,"npc_approaches":people.approaches,"exact_natural_depth_overlaps":overlaps}
static func paint_closed(image: Image,area: Rect2,color: Color) -> void:
	var start:=Vector2i(ceili(area.position.x),ceili(area.position.y));var end:=Vector2i(floori(area.end.x),floori(area.end.y))
	image.fill_rect(Rect2i(start,end-start+Vector2i.ONE).intersection(Rect2i(0,0,3072,2048)),color)
static func paint_polygon(image: Image,polygon: PackedVector2Array) -> void:
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
	for point: Vector2 in polygon: low=low.min(point);high=high.max(point)
	for y: int in range(maxi(0,floori(low.y)),mini(2048,ceili(high.y)+1)):
		for x: int in range(maxi(0,floori(low.x)),mini(3072,ceili(high.x)+1)):
			if Geometry2D.is_point_in_polygon(Vector2(x,y),polygon): image.set_pixel(x,y,Color(0,0,0,1))
static func safe_body(foot: Vector2,image: Image,solids: Array) -> bool:
	if not foot.is_finite() or image==null or image.get_size()!=Vector2i(3072,2048): return false
	var body:=Rect2(foot-Vector2(17,12),Vector2(34,24))
	if not Rect2(Vector2.ZERO,SIZE).encloses(body): return false
	for solid: Dictionary in solids:
		if solid.has("polygon_px"):
			var polygon:=PackedVector2Array([body.position,Vector2(body.end.x,body.position.y),body.end,Vector2(body.position.x,body.end.y)])
			if not Geometry2D.intersect_polygons(polygon,solid.polygon_px).is_empty(): return false
		elif body.intersects(rect(solid.rect_px),true): return false
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			if not walk_pixel(image,foot+Vector2(x,y)): return false
	for offset: Vector2 in [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]:
		if not walk_pixel(image,foot+offset): return false
	return true
static func walk_pixel(image: Image,foot: Vector2) -> bool:
	var p:=Vector2i(foot.round())
	return p.x>=0 and p.x<3072 and p.y>=0 and p.y<2048 and image.get_pixelv(p).r>=.5 and image.get_pixelv(p).a>=.5
static func audit(compiled: Dictionary,parent: Dictionary={}) -> Dictionary:
	if compiled.get("ok")!=true: return compiled
	var data: Dictionary=compiled.author_scene;var samples: int=0;var inherited: int=0;var result: Array=[]
	for route: Dictionary in data.routes:
		if not route.get("points") is Array or route.points.size()<2: return fail("ROUTE_FIELDS",route.get("id"))
		var count: int=0
		for i: int in route.points.size()-1:
			var first: Vector2=v(route.points[i]);var last: Vector2=v(route.points[i+1]);var steps: int=maxi(1,ceili(first.distance_to(last)/4.0))
			for n: int in range(steps+1):
				var foot: Vector2=first.lerp(last,float(n)/steps)
				var inherit_sample: bool=false
				if parent.get("exact_route_ids",{}).has(route.id):
					inherit_sample=true
					var body: Rect2=Rect2(foot-Vector2(17,12),Vector2(34,24))
					for area: Rect2 in parent.get("changed_areas",[]):
						if body.intersects(area,true): inherit_sample=false;break
				if inherit_sample: inherited+=1
				elif not safe_body(foot,compiled.mask,compiled.solids): return fail("ROUTE_FULL875_PLUS17",{"route":route.id,"foot":foot})
				for npc: Dictionary in compiled.get("npc_approaches",[]):
					if Rect2(foot-Vector2(17,12),Vector2(34,24)).intersects(Rect2(npc.foot_px-Vector2(17,15),Vector2(34,30)),true): return fail("ROUTE_STATIC_NPC_BODY",{"route":route.id,"npc_id":npc.npc_id,"foot":foot})
				count+=1
				if not inherit_sample: samples+=1
		result.append({"id":route.id,"samples":count,"passed":true})
	var feet: Array=[data.spawn]
	for portal: Dictionary in data.portals: feet.append(portal.foot)
	for raw: Array in feet:
		for dy: float in [0.0,10.0,24.0]:
			if not safe_body(v(raw)+Vector2(0,dy),compiled.mask,compiled.solids): return fail("PORTAL_SPAWN_PLUS10_PLUS24",raw)
	for npc: Dictionary in compiled.get("npc_approaches",[]):
		if not safe_body(npc.foot_px,compiled.mask,compiled.solids) or not safe_body(npc.foot_px+Vector2(0,3),compiled.mask,compiled.solids) or not safe_body(npc.foot_px-Vector2(0,3),compiled.mask,compiled.solids) or not safe_body(npc.approach_px,compiled.mask,compiled.solids): return fail("NPC34X30_AND_SOUTH48_APPROACH",npc.npc_id)
	return {"ok":true,"routes":result,"samples":samples,"unchanged_route_samples_inherited":inherited,"full875_plus17":true,"body":[34,24],"mask_size":[3072,2048],"blockers":compiled.solids.size(),"new_life_people":compiled.get("npc_approaches",[]).size(),"npc34x30_and_south48_safe":true,"routes_avoid_static_NPC_bodies":true}
