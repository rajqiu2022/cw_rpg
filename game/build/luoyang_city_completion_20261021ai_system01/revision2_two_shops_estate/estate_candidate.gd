extends RefCounted
## New ordinary Scene family. It never claims C four-city identity or evidence.
const SELF="res://scripts/city/luoyang_estate_riverside_20261021ai.gd"
const INDEX="res://scripts/city/luoyang_market_frontage_index_20261021ai.gd"
const AUTHOR="res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_author_candidate.json"
const AUTHOR_SHA="a3f4dab6e3e85b9a1d044f7a76c86045e0da3384d155e0431b7a63ba42855fcf"
const ROOT="res://data/maps/luoyang_estate_riverside_20261021ai/"
const ID=&"luoyang_estate_riverside_20261021ai"
const MARKET=&"ch4_s3_luoyang_market"
const ROOM=&"luoyang_functional_mansion_candidate_20261016"
const SIZE=Vector2(3072,2048)
const META="luoyang_estate_riverside_20261021ai"
const SEMANTICS="res://art/maps/luoyang_modular_v3/source/module_semantics.json"
static func b() -> Variant: return load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
static func v(a: Array) -> Vector2: return Vector2(float(a[0]),float(a[1]))
static func uv(a: Array) -> Vector2: return Vector2(float(a[0])/3072.0,float(a[1])/2048.0)
static func rect(a: Array) -> Rect2: return Rect2(float(a[0]),float(a[1]),float(a[2]),float(a[3]))
static func json(path: String) -> Dictionary:
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}
static func author() -> Dictionary:
	if FileAccess.get_sha256(AUTHOR)!=AUTHOR_SHA: return {}
	var a: Dictionary=json(AUTHOR)
	if a.get("status")!="SOURCE_BOUND_AI_DRY_ESTATE_GEOMETRY_CANDIDATE" or a.get("scene_id")!=String(ID) or a.get("source_sha256",{}).size()!=13 or a.get("trees",[]).size()!=4 or not a.get("npcs",[]).is_empty(): return {}
	for path: String in a.source_sha256:
		if not path.begins_with("res://") or ".." in path or FileAccess.get_sha256(path)!=a.source_sha256[path]: return {}
	return a
static func blockers(a: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	var module: Dictionary=json(SEMANTICS).get("modules",{}).get(a.gate.semantics_id,{})
	if module.get("source_sha256")!=a.source_sha256.get(a.gate.texture) or v(module.get("source_size_px",[]))!=v(a.gate.source_size) or module.get("solid_polygons_uv",[]).size()!=2: return []
	for i: int in 2:
		var points: Array=module.solid_polygons_uv[i]
		var bounds:=Rect2(v(points[0])*v(a.gate.source_size),Vector2.ZERO)
		for point: Array in points: bounds=bounds.expand(v(point)*v(a.gate.source_size))
		bounds=Rect2(v(a.gate.foot)+(bounds.position-v(a.gate.ground_anchor))*float(a.gate.scale),bounds.size*float(a.gate.scale))
		out.append({"id":"estate_gate_jamb_"+str(i),"rect_px":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"source_semantics":"qualified_source_polygon_enclosing_rectangle_not_narrower"})
	for tree: Dictionary in a.trees:
		var foot: Vector2=v(tree.foot)
		out.append({"id":tree.id,"rect_px":[foot.x-12.0,foot.y-18.0,24.0,18.0],"source_semantics":"existing_native_tree_24x18_ground_base"})
	return out
static func mask(a: Dictionary,solids: Array[Dictionary]) -> Image:
	if solids.size()!=6: return null
	var image:=Image.create(3072,2048,false,Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,1))
	var area: Rect2=rect(a.outer_walk_rect)
	image.fill_rect(Rect2i(Vector2i(area.position),Vector2i(area.size)),Color.WHITE)
	for row: Dictionary in solids:
		var box: Rect2=rect(row.rect_px)
		var left: int=ceili(box.position.x);var top: int=ceili(box.position.y)
		image.fill_rect(Rect2i(left,top,floori(box.end.x)-left+1,floori(box.end.y)-top+1),Color(0,0,0,1))
	return image
static func safe_body(foot: Vector2,image: Image,solids: Array[Dictionary],seventeen: bool=true) -> bool:
	if not foot.is_finite() or image==null or image.get_size()!=Vector2i(3072,2048): return false
	var body:=Rect2(foot-Vector2(17,12),Vector2(34,24))
	if not Rect2(Vector2.ZERO,SIZE).encloses(body): return false
	for row: Dictionary in solids:
		if body.intersects(rect(row.rect_px),true): return false
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			var p:=Vector2i((foot+Vector2(x,y)).round())
			if p.x<0 or p.y<0 or p.x>=3072 or p.y>=2048: return false
			var color: Color=image.get_pixelv(p)
			if color.r<.5 or color.a<.5: return false
	if seventeen:
		for offset: Vector2 in [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]:
			var p:=Vector2i((foot+offset).round())
			if p.x<0 or p.y<0 or p.x>=3072 or p.y>=2048 or image.get_pixelv(p).r<.5: return false
	return true
static func audit(a: Dictionary,image: Image,solids: Array[Dictionary]) -> Dictionary:
	var samples: int=0;var routes: Array=[]
	for route: Dictionary in a.routes:
		var count: int=0
		for i: int in route.points.size()-1:
			var first: Vector2=v(route.points[i]);var last: Vector2=v(route.points[i+1]);var n: int=maxi(1,ceili(first.distance_to(last)/4.0))
			for step: int in range(n+1):
				var foot: Vector2=first.lerp(last,float(step)/n)
				if not safe_body(foot,image,solids): return {"passed":false,"route":route.id,"foot":var_to_str(foot),"samples":samples}
				count+=1;samples+=1
		routes.append({"id":route.id,"samples":count,"passed":true})
	for point: Array in [a.spawn,a.market_portal.foot,a.mansion_portal.foot]:
		if not safe_body(v(point),image,solids): return {"passed":false,"error":"EXACT_AUTHORED_FOOT","foot":point}
	return {"passed":true,"routes":routes,"samples":samples,"body_px":[34,24],"all875_and_seventeen":true,"rectangular_solids":solids.size(),"new_NPC_or_culture_credit":false}
static func visual(id: String,texture: String,foot: Vector2,size: Vector2,anchor: Vector2,scale: float) -> Dictionary:
	return {"id":id,"texture":texture,"pos":(foot+(size*.5-anchor)*scale)/SIZE,"render_size_px":size*scale,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y}
static func scene(a: Dictionary,solids: Array[Dictionary]) -> SceneScript:
	var result:=SceneScript.new();result.scene_id=ID;result.display_name="洛阳 · 宅园门庭（候选干院）"
	result.is_walkable=true;result.actor_positions_are_feet=true;result.is_settlement=true;result.player_spawn=uv(a.spawn);result.player_visual_scale=.91;result.camera_zoom=1.05
	result.background_path=a.ground.grass;result.bgm_path="res://art/audio/bgm/bgm_market_lively_v4.wav"
	var layout:=WalkableMapLayout.new();layout.design_size=Vector2i(3072,2048);layout.walkable_mask_path=ROOT+"walk.png"
	layout.walkable_regions=[PackedVector2Array([Vector2(64.0/3072,64.0/2048),Vector2(3008.0/3072,64.0/2048),Vector2(3008.0/3072,1984.0/2048),Vector2(64.0/3072,1984.0/2048)])]
	var objects: Array[Dictionary]=[]
	# Native material references, uniform square tiles; not a new painted image.
	for y: int in 2:
		for x: int in 3: objects.append({"id":"estate_grass_"+str(x)+"_"+str(y),"texture":a.ground.grass,"pos":Vector2(x*1024+512,y*1024+512)/SIZE,"render_size_px":Vector2(1024,1024),"sort_by_feet":false,"z_index":-10})
	for y: int in 2: objects.append({"id":"estate_stone_path_"+str(y),"texture":a.ground.stone,"pos":Vector2(1536,y*1024+512)/SIZE,"render_size_px":Vector2(1024,1024),"sort_by_feet":false,"z_index":-9})
	objects.append(visual(a.gate.id,a.gate.texture,v(a.gate.foot),v(a.gate.source_size),v(a.gate.ground_anchor),float(a.gate.scale)))
	for tree: Dictionary in a.trees: objects.append(visual(tree.id,a.tree_asset.texture,v(tree.foot),v(a.tree_asset.source_size),v(a.tree_asset.ground_anchor),1.0))
	layout.visual_objects=objects
	var blocks: Array[Dictionary]=[]
	for row: Dictionary in solids:
		var box: Rect2=rect(row.rect_px)
		blocks.append({"id":row.id,"pos":box.get_center()/SIZE,"size":box.size/SIZE,"walkability_margin":0.0})
	layout.blockers=blocks
	layout.portals=[{"id":a.market_portal.id,"pos":uv(a.market_portal.foot),"size":Vector2(40.0/3072,32.0/2048),"auto_trigger":false,"target_scene":String(MARKET),"target_pos":uv(a.market_portal.target_foot),"label":a.market_portal.label},{"id":a.mansion_portal.id,"pos":uv(a.mansion_portal.foot),"size":Vector2(40.0/3072,32.0/2048),"auto_trigger":false,"target_scene":String(ROOM),"target_scene_path":a.mansion_portal.target_scene_path,"target_pos":Vector2(float(a.mansion_portal.target_spawn[0])/1536.0,float(a.mansion_portal.target_spawn[1])/1024.0),"label":a.mansion_portal.label}]
	result.map_layout=layout;result.set_meta(META,AUTHOR_SHA)
	return result
static func known_id(id: StringName) -> bool: return id==ID
static func manifest() -> Dictionary:
	var authority: Variant=load(INDEX)
	if not authority is GDScript or authority.resource_path!=INDEX or not authority.formal_enabled(): return {}
	var entry: Dictionary=authority.estate_entry()
	if entry.get("manifest_path")!=ROOT+"manifest.json" or not b()._hash(entry.get("manifest_sha256")) or FileAccess.get_sha256(entry.manifest_path)!=entry.manifest_sha256: return {}
	var data: Dictionary=json(entry.manifest_path)
	if data.get("scene_id")!=String(ID) or data.get("author_path")!=AUTHOR or data.get("author_sha256")!=AUTHOR_SHA or author().is_empty(): return {}
	for path: String in data.get("source_sha256",{}):
		if not path.begins_with("res://") or path==INDEX or ".." in path or FileAccess.get_sha256(path)!=data.source_sha256[path]: return {}
	return data if not data.get("source_sha256",{}).is_empty() else {}
static func approved_scene_path(id: StringName) -> String:
	if id!=ID or manifest().is_empty(): return ""
	var expected: Dictionary=manifest()
	var packet: Variant=bytes_to_var(FileAccess.get_file_as_bytes(ROOT+"packet.bin"))
	var resource:=ResourceLoader.load(ROOT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not packet is Dictionary or not b()._plain(packet) or resource==null or resource.get_meta(META,"")!=AUTHOR_SHA or not b().equal(b().storage(resource),packet.scene_storage) or not b().equal(b().storage(resource.map_layout),packet.layout_storage): return ""
	if expected.get("packet_sha256")!=FileAccess.get_sha256(ROOT+"packet.bin"): return ""
	return ROOT+"scene.res"
static func runtime_safe(foot: Vector2) -> bool:
	if approved_scene_path(ID).is_empty(): return false
	var image: Image=Image.load_from_file(ROOT+"walk.png")
	return safe_body(foot,image,blockers(author()))
static func arrival(source: StringName,target: StringName,authored: Variant,remembered: Variant) -> Dictionary:
	if source!=ID and target!=ID: return {}
	var a: Dictionary=author()
	if a.is_empty() or manifest().is_empty() or not authored is Vector2: return {}
	var wanted: Vector2
	if target==ID:
		if source==MARKET: wanted=uv(a.spawn)
		elif source==ROOM: wanted=uv(a.mansion_portal.foot)
		else: return {}
		if authored!=wanted: return {}
		var foot: Vector2=remembered if remembered is Vector2 else wanted
		if not runtime_safe(foot*SIZE): return {}
		return {"arrival":foot,"local_version":3,"reason":"exact_estate_family_arrival"}
	if source==ID and target==MARKET:
		wanted=uv(a.market_portal.target_foot)
		if authored!=wanted: return {}
		var foot: Vector2=remembered if remembered is Vector2 else wanted
		return {"arrival":foot,"local_version":3,"reason":"exact_estate_to_C_market"} if load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd").safe_body(MARKET,foot*SIZE) else {}
	# Estate->mansion admission remains owned by the exact room resource loader.
	return {"arrival":authored,"local_version":-1,"reason":"exact_estate_mansion_room"} if source==ID and target==ROOM and authored==Vector2(0.5,0.8203125) else {}
