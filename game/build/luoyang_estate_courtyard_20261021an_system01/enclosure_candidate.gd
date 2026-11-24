extends RefCounted
## Ordinary rectangular entities; immutable AL83/AK20 parent, add-only mask.
const E=preload("res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd")
const A=preload("res://build/luoyang_estate_courtyard_20261021ak_system01/architecture_candidate.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const SIZE=Vector2(3072,2048)
const DOORS=[Vector2(1536,544),Vector2(700,884),Vector2(2222,884)]
static func integer(value: Variant) -> bool:
	return A.number(value) and float(value)==floorf(float(value))
static func valid(a: Dictionary) -> bool:
	if a.get("status")!="ROOT_ADMITTED_AM_ENCLOSURE_CANDIDATE" or a.get("formal_enabled")!=false or a.get("scene_id")!=String(E.ID) or not a.get("source_sha256") is Dictionary or not a.get("assets") is Array or not a.get("components") is Array or a.components.is_empty() or not a.get("new_routes") is Array or a.new_routes.is_empty(): return false
	if not a.get("include_peony_beds") is bool: return false
	var assets: Dictionary={};var ids: Dictionary={}
	for asset: Dictionary in a.assets:
		if not asset.get("id") in ["low_wall_left","low_wall_right","angled_wall_left","angled_wall_right","grass_stone_edge","flower_bed"] or assets.has(asset.id) or not A.pair(asset.get("source_size")) or not A.pair(asset.get("ground_anchor")) or not A.rect_valid(asset.get("alpha_rect_px")) or not asset.get("solid_rects_px") is Array or asset.solid_rects_px.is_empty() or not a.source_sha256.has(asset.get("texture")): return false
		var canvas:=Rect2(Vector2.ZERO,E.v(asset.source_size));var used: Rect2=E.rect(asset.alpha_rect_px)
		if not integer(asset.source_size[0]) or not integer(asset.source_size[1]) or canvas.size.x<=0 or canvas.size.y<=0 or not canvas.encloses(used) or used.position!=Vector2(Vector2i(used.position)) or used.size!=Vector2(Vector2i(used.size)) or not canvas.has_point(E.v(asset.ground_anchor)): return false
		for raw: Variant in asset.solid_rects_px:
			if not A.rect_valid(raw) or not canvas.encloses(E.rect(raw)): return false
		assets[asset.id]=asset
	for row: Dictionary in a.components:
		if not row.get("id") is String or not (row.id.begins_with("estate_am_") or row.id.begins_with("estate_an_")) or ids.has(row.id) or not assets.has(row.get("asset_id")) or not A.pair(row.get("foot")) or not A.number(row.get("scale")) or float(row.scale)<=0: return false
		# No arbitrary yaw/non-uniform scaling: footprint derives from same source.
		if row.keys().size()!=4: return false
		ids[row.id]=true
	var routes: Dictionary={}
	for row: Dictionary in a.new_routes:
		if not row.get("id") is String or not row.id.begins_with("am_") or routes.has(row.id) or not row.get("points") is Array or row.points.size()<2: return false
		for point: Variant in row.points:
			if not A.pair(point): return false
		routes[row.id]=true
	if not a.get("route_replacements") is Array or a.route_replacements.size()!=1 or a.route_replacements[0].get("id")!="forecourt_to_garden" or not a.route_replacements[0].get("old_points") is Array or not a.route_replacements[0].get("points") is Array or a.route_replacements[0].points.size()<2 or not a.get("allowed_visual_contact_pairs") is Array: return false
	for point: Variant in a.route_replacements[0].old_points+a.route_replacements[0].points:
		if not A.pair(point): return false
	return assets.size()==(6 if a.include_peony_beds else 5) and assets.has("flower_bed")==a.include_peony_beds and a.components.size()==(12 if a.include_peony_beds else 10)
static func visual_contact_allowed(a: Dictionary,first: String,last: String,first_box: Rect2,last_box: Rect2,solids: Array[Dictionary]) -> bool:
	var count: int=0;var approved: Dictionary={}
	for row: Dictionary in a.allowed_visual_contact_pairs:
		if row.get("ids") not in [[first,last],[last,first]]: continue
		if not A.number(row.get("max_intersection_area_px2")) or float(row.max_intersection_area_px2)<=0 or row.get("reason") not in ["EXACT_MASONRY_JUNCTION","PEONY_IN_FRONT_OF_EXISTING_STONE_SHOULDER"]: return false
		count+=1;approved=row
	if count!=1: return false
	var intersection: Rect2=first_box.intersection(last_box)
	if intersection.get_area()>float(approved.max_intersection_area_px2): return false
	# Permission is visual contact, never permission for overlapping bodies.
	for left: Dictionary in solids:
		if not String(left.id).begins_with(first+"_solid_"): continue
		for right: Dictionary in solids:
			if not String(right.id).begins_with(last+"_solid_"): continue
			if E.rect(left.rect_px).intersects(E.rect(right.rect_px),true): return false
	return true
static func source_image(asset: Dictionary,a: Dictionary) -> Image:
	if not asset.has("atlas_region"): return Image.load_from_file(asset.texture)
	if not A.rect_valid(asset.atlas_region) or not a.source_sha256.has(asset.get("source_image")): return null
	var rect: Rect2=E.rect(asset.atlas_region)
	if rect.position!=Vector2(Vector2i(rect.position)) or rect.size!=E.v(asset.source_size): return null
	var source: Image=Image.load_from_file(asset.source_image)
	var texture: Variant=load(asset.texture)
	if source==null or not Rect2(Vector2.ZERO,Vector2(source.get_size())).encloses(rect) or not texture is AtlasTexture or texture.region!=rect or texture.atlas.resource_path!=asset.source_image: return null
	return source.get_region(Rect2i(rect))
static func geometry(a: Dictionary,scene: SceneScript) -> Dictionary:
	if not valid(a) or scene==null or scene.scene_id!=E.ID or scene.map_layout.visual_objects.size()!=83 or scene.map_layout.blockers.size()!=20: return {}
	var assets: Dictionary={};var boxes: Dictionary={};var visuals: Array[Dictionary]=[];var solids: Array[Dictionary]=[]
	for row: Dictionary in a.assets:
		var image: Image=source_image(row,a)
		if image==null or image.get_size()!=Vector2i(E.v(row.source_size)): return {}
		image.convert(Image.FORMAT_RGBA8)
		if image.get_used_rect()!=Rect2i(E.rect(row.alpha_rect_px)): return {}
		assets[row.id]=row
	for row: Dictionary in a.components:
		var asset: Dictionary=assets[row.asset_id];var scale: float=float(row.scale);var anchor: Vector2=E.v(asset.ground_anchor);var foot: Vector2=E.v(row.foot);var used: Rect2=E.rect(asset.alpha_rect_px)
		var box:=Rect2(foot+(used.position-anchor)*scale,used.size*scale)
		if not Rect2(Vector2.ZERO,SIZE).encloses(box) or not (box.end.x<=1344.0 or box.position.x>=1728.0): return {}
		boxes[row.id]=box;visuals.append(E.visual(row.id,asset.texture,foot,E.v(asset.source_size),anchor,scale))
		for i: int in asset.solid_rects_px.size():
			var raw: Rect2=E.rect(asset.solid_rects_px[i]);var solid:=Rect2(foot+(raw.position-anchor)*scale,raw.size*scale)
			solids.append({"id":String(row.id)+"_solid_"+str(i),"rect_px":[solid.position.x,solid.position.y,solid.size.x,solid.size.y],"source_semantics":"ROOT_admitted_AM_rectangular_ground_entity"})
	return {"visual":visuals,"solids":solids,"alpha":boxes}
static func mask_after(bytes: PackedByteArray,solids: Array[Dictionary]) -> Image:
	if bytes.size()!=3072*2048*4: return null
	var mask:=Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,bytes)
	for row: Dictionary in solids:
		var box: Rect2=E.rect(row.rect_px);var left: int=ceili(box.position.x);var top: int=ceili(box.position.y)
		mask.fill_rect(Rect2i(left,top,floori(box.end.x)-left+1,floori(box.end.y)-top+1),Color(0,0,0,1))
	return mask
static func audit(a: Dictionary,parent: Dictionary,scene: SceneScript,delta: Dictionary,mask: Image) -> Dictionary:
	if delta.is_empty() or mask==null or parent.get("rectangular_solids",[]).size()!=20: return {}
	var solids: Array[Dictionary]=[]
	for row: Dictionary in parent.rectangular_solids: solids.append(row.duplicate(true))
	solids.append_array(delta.solids)
	for added: Dictionary in delta.solids:
		for other: Dictionary in solids:
			if added.id!=other.id and E.rect(added.rect_px).intersects(E.rect(other.rect_px),true): return {"passed":false,"error":"NEW_BODY_INTERSECTS_EXISTING_OR_NEW_BODY","ids":[added.id,other.id]}
	# Recompute original visible prop bounds from five component/raw placements,
	# not old route samples. Ground/depth backdrops intentionally excluded.
	var old_boxes: Dictionary={}
	for row: Dictionary in scene.map_layout.visual_objects:
		if not row.get("sort_by_feet",false): continue
		var image: Image=Image.load_from_file(row.texture)
		if image==null: return {"passed":false,"error":"PARENT_A1_TEXTURE"}
		image.convert(Image.FORMAT_RGBA8)
		var scale: Vector2=row.render_size_px/Vector2(image.get_size());var used: Rect2i=image.get_used_rect()
		old_boxes[row.id]=Rect2(row.pos*SIZE-row.render_size_px*.5+Vector2(used.position)*scale,Vector2(used.size)*scale)
	for id: String in delta.alpha:
		for old_id: String in old_boxes:
			if delta.alpha[id].intersects(old_boxes[old_id]) and not visual_contact_allowed(a,id,old_id,delta.alpha[id],old_boxes[old_id],solids): return {"passed":false,"error":"NEW_VS_OLD_FULL_A1_OVERLAP","ids":[id,old_id]}
		for other: String in delta.alpha:
			if id!=other and delta.alpha[id].intersects(delta.alpha[other]) and not visual_contact_allowed(a,id,other,delta.alpha[id],delta.alpha[other],solids): return {"passed":false,"error":"NEW_FULL_A1_OVERLAP","ids":[id,other]}
	var reports: Array=[];var old_routes: Array=[]
	var base: Dictionary=E.author()
	for row: Dictionary in base.routes:
		if row.id!="dry_garden_loop": old_routes.append(row)
	old_routes.append_array(parent.architecture_successor.new_routes)
	for route: Dictionary in old_routes:
		if route.id=="forecourt_to_garden":
			var replacement: Dictionary=a.route_replacements[0]
			if route.points.size()!=replacement.old_points.size(): return {"passed":false,"error":"OLD_REPLACED_ROUTE_EXACT"}
			for i: int in route.points.size():
				if E.v(route.points[i])!=E.v(replacement.old_points[i]): return {"passed":false,"error":"OLD_REPLACED_ROUTE_EXACT"}
			if E.v(replacement.points[0])!=E.v(route.points[0]) or E.v(replacement.points[-1])!=E.v(route.points[-1]): return {"passed":false,"error":"REPLACEMENT_ROUTE_SAME_REAL_ENDPOINTS"}
			var changed_report: Dictionary=A.route_check(replacement,mask,solids,delta.solids,false);changed_report["explicit_parent_route_replacement"]=true;reports.append(changed_report)
			if changed_report.get("passed")!=true: return {"passed":false,"error":"REPLACEMENT_FORECOURT_ROUTE","routes":reports}
			continue
		var report: Dictionary=A.route_check(route,mask,solids,delta.solids,true)
		report["inheritance_basis"]="AK_248273_FULL87517_AND_AI_91C9_ONLY_UNCHANGED_REGION"
		reports.append(report)
		if report.get("passed")!=true: return {"passed":false,"error":"OLD_ROUTE_AFFECTED_AM_REGION","routes":reports}
	for route: Dictionary in a.new_routes:
		var report: Dictionary=A.route_check(route,mask,solids,delta.solids,false);reports.append(report)
		if report.get("passed")!=true: return {"passed":false,"error":"NEW_AM_ROUTE","routes":reports}
	for foot: Vector2 in DOORS+[Vector2(1536,1840),Vector2(1536,1940)]:
		for offset: Vector2 in [Vector2.ZERO,Vector2(0,24)]:
			if not E.safe_body(foot+offset,mask,solids): return {"passed":false,"error":"THREE_DOORS_SPAWN_EXIT_PLUS24","foot":var_to_str(foot+offset)}
	for row: Dictionary in delta.solids:
		var center: Vector2=E.rect(row.rect_px).get_center()
		if E.safe_body(center,mask,solids): return {"passed":false,"error":"NEW_ENTITY_CENTER_NOT_BLOCKED"}
	return {"passed":true,"all_solids":solids,"routes":reports,"old_2710_plus661_not_full_rerun":true,"old20_kept":true,"new_solids":delta.solids.size(),"new_visuals":delta.visual.size(),"new_a1_boxes":var_to_str(delta.alpha),"three_doors_plus24_safe":true,"body_world_size":[34,24],"mask_operation":"ONLY_CLOSED_INTEGER_NEW_RECTANGLES_WHITE_TO_BLACK"}
