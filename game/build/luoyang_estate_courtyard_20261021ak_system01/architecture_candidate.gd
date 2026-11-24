extends RefCounted
## Ordinary layout rectangular physics. No C polygon identity or owner bypass.
const E=preload("res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const SIZE=Vector2(3072,2048)
const ROLES=["main_hall","west_wing","east_wing","west_corridor","east_corridor"]
const NEW_ROUTES=["entrance_to_hall","inner_court_west_wing","inner_court_east_wing","public_outer_loop"]
static func pair(value: Variant) -> bool:
	return value is Array and value.size()==2 and number(value[0]) and number(value[1])
static func number(value: Variant) -> bool: return (value is int or value is float) and is_finite(float(value))
static func rect_valid(value: Variant) -> bool:
	return value is Array and value.size()==4 and number(value[0]) and number(value[1]) and number(value[2]) and number(value[3]) and float(value[2])>0 and float(value[3])>0
static func author_valid(a: Dictionary) -> bool:
	if a.get("status")!="ROOT_ADMITTED_AK_ARCHITECTURE_CANDIDATE" or a.get("formal_enabled")!=false or a.get("scene_id")!=String(E.ID) or a.get("assets",[]).size()!=3 or a.get("components",[]).size()!=5 or not a.get("source_sha256") is Dictionary: return false
	var assets: Dictionary={}
	for asset: Dictionary in a.assets:
		if not asset.get("id") in ["main_hall","wing","corridor"] or assets.has(asset.id) or not pair(asset.get("source_size")) or not pair(asset.get("ground_anchor")) or not rect_valid(asset.get("alpha_rect_px")) or not asset.get("solid_rects_px") is Array or asset.solid_rects_px.is_empty(): return false
		var dimensions: Vector2=E.v(asset.source_size)
		if dimensions.x<=0 or dimensions.y<=0 or dimensions!=Vector2(Vector2i(dimensions)): return false
		var canvas:=Rect2(Vector2.ZERO,dimensions)
		var used: Rect2=E.rect(asset.alpha_rect_px)
		if used.position!=Vector2(Vector2i(used.position)) or used.size!=Vector2(Vector2i(used.size)) or not canvas.encloses(used) or not canvas.has_point(E.v(asset.ground_anchor)): return false
		for rect: Variant in asset.solid_rects_px:
			if not rect_valid(rect) or not canvas.encloses(E.rect(rect)): return false
		if not a.source_sha256.has(asset.get("texture")) or not a.source_sha256.has(asset.get("admission_path")) or a.source_sha256[asset.admission_path]!=asset.get("admission_sha256"): return false
		assets[asset.id]=asset
	var roles: Array=[]
	for row: Dictionary in a.components:
		if not row.get("role") in ROLES or roles.has(row.role) or row.get("id")!="estate_ak_"+String(row.role) or not assets.has(row.get("asset_id")) or not pair(row.get("foot")) or not number(row.get("scale")) or float(row.scale)<=0: return false
		if (row.role=="main_hall" and row.asset_id!="main_hall") or (String(row.role).ends_with("wing") and row.asset_id!="wing") or (String(row.role).ends_with("corridor") and row.asset_id!="corridor"): return false
		var asset: Dictionary=assets[row.asset_id]
		var extent: Vector2=E.rect(asset.alpha_rect_px).size*float(row.scale)
		var maximum:=Vector2(760,450) if row.role=="main_hall" else (Vector2(520,330) if String(row.role).ends_with("wing") else Vector2(640,250))
		if extent.x>maximum.x or extent.y>maximum.y: return false
		if (String(row.role).ends_with("wing") and extent.x<440) or (String(row.role).ends_with("corridor") and extent.x<620): return false
		if not String(row.role).ends_with("corridor") and (not number(asset.get("door_clear_px")) or float(asset.door_clear_px)*float(row.scale)<120.0): return false
		if String(row.role).ends_with("corridor") and (not number(asset.get("passage_clear_px")) or float(asset.passage_clear_px)*float(row.scale)<120.0): return false
		roles.append(row.role)
	if a.get("replace_old_route_ids")!=["dry_garden_loop"] or a.get("new_routes",[]).size()!=4: return false
	var routes: Array=[]
	for row: Dictionary in a.new_routes:
		if not row.get("id") in NEW_ROUTES or routes.has(row.id) or not row.get("points") is Array or row.points.size()<2: return false
		for point: Variant in row.points:
			if not pair(point): return false
		routes.append(row.id)
	var move: Dictionary=a.get("portal_move",{})
	if move.get("id")!="estate_enter_mansion_hall" or move.get("target_scene")!=String(E.ROOM) or not pair(move.get("old_foot")) or E.v(move.old_foot)!=Vector2(1536,1144) or not pair(move.get("new_foot")) or a.source_sha256.size()<4: return false
	if not a.get("tree_moves") is Array or a.tree_moves.size()!=2: return false
	var seen: Array=[]
	for row: Dictionary in a.tree_moves:
		if not row.get("id") in ["estate_tree_nw","estate_tree_ne"] or row.id in seen or not pair(row.get("old_foot")) or not pair(row.get("new_foot")): return false
		var old: Vector2=Vector2(900,860) if row.id=="estate_tree_nw" else Vector2(2200,880)
		if E.v(row.old_foot)!=old or E.v(row.new_foot)==old: return false
		seen.append(row.id)
	var expected_door: Vector2
	for row: Dictionary in a.components:
		if row.role=="main_hall": expected_door=E.v(row.foot)+Vector2(0,24)
	return E.v(move.new_foot)==expected_door
static func asset_for(a: Dictionary,id: String) -> Dictionary:
	for row: Dictionary in a.assets:
		if row.id==id: return row
	return {}
static func geometry(a: Dictionary) -> Dictionary:
	var added: Array[Dictionary]=[];var visual: Array[Dictionary]=[];var alpha: Dictionary={}
	for row: Dictionary in a.components:
		var asset: Dictionary=asset_for(a,row.asset_id)
		var image: Image=Image.load_from_file(asset.texture)
		if image==null or image.get_size()!=Vector2i(E.v(asset.source_size)): return {}
		image.convert(Image.FORMAT_RGBA8)
		var used: Rect2i=image.get_used_rect()
		if used!=Rect2i(E.rect(asset.alpha_rect_px)): return {}
		var foot: Vector2=E.v(row.foot);var anchor: Vector2=E.v(asset.ground_anchor);var scale: float=float(row.scale)
		var source: Rect2=E.rect(asset.alpha_rect_px)
		var bounds:=Rect2(foot+(source.position-anchor)*scale,source.size*scale)
		if not Rect2(Vector2.ZERO,SIZE).encloses(bounds): return {}
		alpha[row.id]=bounds
		visual.append(E.visual(row.id,asset.texture,foot,E.v(asset.source_size),anchor,scale))
		for i: int in asset.solid_rects_px.size():
			var rect: Rect2=E.rect(asset.solid_rects_px[i])
			rect=Rect2(foot+(rect.position-anchor)*scale,rect.size*scale)
			added.append({"id":String(row.id)+"_solid_"+str(i),"rect_px":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"source_semantics":"ROOT_admitted_source_rectangle_not_C_polygon"})
	return {"visual":visual,"solids":added,"alpha":alpha}
static func tree_delta(a: Dictionary,parent_author: Dictionary,parent: Dictionary) -> Dictionary:
	var base: Array[Dictionary]=[];var removed: Array[Dictionary]=[];var relocated: Array[Dictionary]=[];var visuals: Dictionary={}
	for row: Dictionary in parent.rectangular_solids: base.append(row.duplicate(true))
	for move: Dictionary in a.tree_moves:
		var found: int=0
		for tree: Dictionary in parent_author.trees:
			if tree.id!=move.id: continue
			if E.v(tree.foot)!=E.v(move.old_foot): return {}
			found+=1
		if found!=1: return {}
		found=0
		for rect: Dictionary in base:
			if rect.id!=move.id: continue
			var old: Vector2=E.v(move.old_foot);var foot: Vector2=E.v(move.new_foot)
			if E.rect(rect.rect_px)!=Rect2(old-Vector2(12,18),Vector2(24,18)): return {}
			removed.append(rect.duplicate(true));rect.rect_px=[foot.x-12.0,foot.y-18.0,24.0,18.0];relocated.append(rect.duplicate(true));found+=1
		if found!=1: return {}
		visuals[move.id]=E.visual(move.id,parent_author.tree_asset.texture,E.v(move.new_foot),E.v(parent_author.tree_asset.source_size),E.v(parent_author.tree_asset.ground_anchor),1.0)
	return {"base_solids":base,"old_tree_rects":removed,"new_tree_rects":relocated,"visuals":visuals}
static func point_in_solids(point: Vector2,solids: Array[Dictionary]) -> bool:
	for row: Dictionary in solids:
		var rect: Rect2=E.rect(row.rect_px)
		if point.x>=rect.position.x and point.x<=rect.end.x and point.y>=rect.position.y and point.y<=rect.end.y: return true
	return false
static func clone_mask(parent: PackedByteArray,trees: Dictionary,added: Array[Dictionary]) -> Image:
	if parent.size()!=3072*2048*4 or trees.is_empty(): return null
	var mask:=Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,parent)
	# Recover only the old two tree raster rectangles. The exact parent was
	# outer[64,3008)x[64,1984) white minus six closed integer rectangles.
	# Consult all remaining/relocated base rectangles, never carve a corridor.
	for row: Dictionary in trees.old_tree_rects:
		var box: Rect2=E.rect(row.rect_px)
		for y: int in range(ceili(box.position.y),floori(box.end.y)+1):
			for x: int in range(ceili(box.position.x),floori(box.end.x)+1):
				var white: bool=x>=64 and x<3008 and y>=64 and y<1984 and not point_in_solids(Vector2(x,y),trees.base_solids)
				mask.set_pixel(x,y,Color.WHITE if white else Color(0,0,0,1))
	var black: Array[Dictionary]=[]
	black.append_array(trees.new_tree_rects);black.append_array(added)
	for row: Dictionary in black:
		var box: Rect2=E.rect(row.rect_px);var left: int=ceili(box.position.x);var top: int=ceili(box.position.y)
		mask.fill_rect(Rect2i(left,top,floori(box.end.x)-left+1,floori(box.end.y)-top+1),Color(0,0,0,1))
	return mask
static func affected(foot: Vector2,added: Array[Dictionary]) -> bool:
	# Round-to-nearest raster may reach another half-pixel: use a conservative
	# 35x25 test envelope only to choose retest, never to shrink real physics.
	var envelope:=Rect2(foot-Vector2(17.5,12.5),Vector2(35,25))
	for row: Dictionary in added:
		if envelope.intersects(E.rect(row.rect_px),true): return true
	return false
static func route_check(route: Dictionary,mask: Image,all_solids: Array[Dictionary],added: Array[Dictionary],inherit: bool) -> Dictionary:
	var checked: int=0;var inherited: int=0
	for i: int in route.points.size()-1:
		var first: Vector2=E.v(route.points[i]);var last: Vector2=E.v(route.points[i+1]);var n: int=maxi(1,ceili(first.distance_to(last)/4.0))
		for step: int in range(n+1):
			var foot: Vector2=first.lerp(last,float(step)/n)
			if inherit and not affected(foot,added): inherited+=1;continue
			if not E.safe_body(foot,mask,all_solids): return {"passed":false,"id":route.id,"foot":var_to_str(foot),"checked":checked,"inherited":inherited}
			checked+=1
	return {"passed":true,"id":route.id,"checked_full875_plus17":checked,"inherited_from_91c9_unchanged_region":inherited}
static func audit(a: Dictionary,parent_author: Dictionary,parent: Dictionary,delta: Dictionary,trees: Dictionary,mask: Image) -> Dictionary:
	var added: Array[Dictionary]=delta.solids;var solids: Array[Dictionary]=[]
	for row: Dictionary in trees.base_solids: solids.append(row.duplicate(true))
	solids.append_array(added)
	var changed: Array[Dictionary]=added.duplicate(true)
	changed.append_array(trees.old_tree_rects);changed.append_array(trees.new_tree_rects)
	# Actual A>0 envelopes, not nominal PNG box or alpha16 substitute.
	var alpha: Dictionary=delta.alpha.duplicate(true)
	var parent_props: Array[Dictionary]=[]
	parent_props.append(E.visual(parent_author.gate.id,parent_author.gate.texture,E.v(parent_author.gate.foot),E.v(parent_author.gate.source_size),E.v(parent_author.gate.ground_anchor),float(parent_author.gate.scale)))
	for row: Dictionary in parent_author.trees:
		if trees.visuals.has(row.id): parent_props.append(trees.visuals[row.id])
		else: parent_props.append(E.visual(row.id,parent_author.tree_asset.texture,E.v(row.foot),E.v(parent_author.tree_asset.source_size),E.v(parent_author.tree_asset.ground_anchor),1.0))
	# Recompute just five retained prop boxes at original float placement; this
	# is not a rerun of the 2226 old route/body samples or old raster.
	for row: Dictionary in parent_props:
		var image: Image=Image.load_from_file(row.texture)
		if image==null: return {"passed":false,"error":"OLD_PROP_ALPHA_SOURCE"}
		image.convert(Image.FORMAT_RGBA8)
		var used: Rect2i=image.get_used_rect();var size: Vector2=row.render_size_px
		var origin: Vector2=row.pos*SIZE-size*.5
		alpha[row.id]=Rect2(origin+Vector2(used.position)*size/Vector2(image.get_size()),Vector2(used.size)*size/Vector2(image.get_size()))
	for first: String in alpha:
		for last: String in alpha:
			if first!=last and alpha[first].intersects(alpha[last],true): return {"passed":false,"error":"FULL_ALPHA_OVERLAP","pair":[first,last]}
	var doors: Dictionary={}
	for row: Dictionary in a.components:
		if row.role in ["west_wing","east_wing"]: doors[row.role]=E.v(row.foot)+Vector2(0,24)
	for row: Dictionary in a.new_routes:
		var start: Vector2=E.v(row.points[0]);var finish: Vector2=E.v(row.points[-1]);var expected_start: Vector2;var expected_finish: Vector2
		match String(row.id):
			"entrance_to_hall": expected_start=E.v(a.portal_move.old_foot);expected_finish=E.v(a.portal_move.new_foot)
			"inner_court_west_wing": expected_start=E.v(a.portal_move.new_foot);expected_finish=doors.west_wing
			"inner_court_east_wing": expected_start=E.v(a.portal_move.new_foot);expected_finish=doors.east_wing
			"public_outer_loop": expected_start=E.v(parent_author.spawn);expected_finish=expected_start
			_: return {"passed":false,"error":"UNKNOWN_NEW_ROUTE"}
		if start!=expected_start or finish!=expected_finish: return {"passed":false,"error":"EXACT_ROUTE_DOOR_ENDPOINTS","id":row.id}
	var routes: Array=[]
	for row: Dictionary in parent_author.routes:
		if row.id in a.replace_old_route_ids: continue
		var report: Dictionary=route_check(row,mask,solids,changed,true);routes.append(report)
		if report.get("passed")!=true: return {"passed":false,"error":"OLD_ROUTE_CHANGED_REGION","routes":routes}
	for row: Dictionary in a.new_routes:
		var report: Dictionary=route_check(row,mask,solids,changed,false);routes.append(report)
		if report.get("passed")!=true: return {"passed":false,"error":"NEW_ROUTE","routes":routes}
	for foot: Vector2 in [E.v(parent_author.spawn),E.v(parent_author.market_portal.foot),E.v(a.portal_move.new_foot),E.v(a.portal_move.new_foot)+Vector2(0,24)]:
		if not E.safe_body(foot,mask,solids): return {"passed":false,"error":"SPAWN_EXIT_NEW_DOOR_AND24","foot":var_to_str(foot)}
	return {"passed":true,"routes":routes,"two_old_tree_rects_relocated":true,"other_four_parent_rects_unchanged":true,"old_2226_not_full_rerun":true,"replaced_old_route_ids":a.replace_old_route_ids,"new_routes":4,"new_solids":added.size(),"tree_moves":a.tree_moves,"full_alpha_boxes":var_to_str(alpha),"all_solids":solids}
