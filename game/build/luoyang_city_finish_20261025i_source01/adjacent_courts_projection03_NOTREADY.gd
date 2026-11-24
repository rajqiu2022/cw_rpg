extends RefCounted
# New finite rows only. Caller must first verify the fixed complete old render.
const SIZE: Vector2=Vector2(3072,2048)
const COUNTS: Dictionary={"ch4_s3_luoyang_market":45,"ch4_s2_canal_docks":39,"luoyang_estate_riverside_20261021ai":111,"luoyang_riverside_garden_20261022ap":56}
static func v(raw: Variant) -> Vector2:
	if raw is Vector2: return raw
	if raw is Array and raw.size()==2: return Vector2(float(raw[0]),float(raw[1]))
	return Vector2(INF,INF)
static func derive(scene_id: String,author: Dictionary,library: Dictionary,before: Array,new_kitchen: Dictionary={},navigation_before: Array=[]) -> Dictionary:
	if not COUNTS.has(scene_id): return {}
	if scene_id=="ch4_s2_canal_docks":
		# Fixed NAV39 is distinct from visual rows after the original task policy.
		if navigation_before.size()!=39: return {}
		for target: String in ["north_canal_warehouse","harbour_rope_shop","harbour_quay_supply_shop"]:
			var nav_matches: int=0;var visual_matches: int=0
			for old_nav: Dictionary in navigation_before:
				if String(old_nav.get("id",""))==target: nav_matches+=1
			for old_visual: Dictionary in before:
				if String(old_visual.get("id",""))==target: visual_matches+=1
			if nav_matches!=1 or visual_matches!=1: return {}
	elif before.size()!=int(COUNTS[scene_id]): return {}
	var target: Dictionary={}
	for candidate: Dictionary in author.get("scenes",[]):
		if String(candidate.scene_id)==scene_id: target=candidate
	if target.is_empty(): return {}
	var seen: Dictionary={}
	for row: Dictionary in before:
		var id: String=String(row.get("id",""))
		if id=="" or seen.has(id): return {}
		seen[id]=true
	var added: Array=[];var new_ground: Array=[]
	for placement: Dictionary in target.get("placements",[]):
		var id: String=String(placement.id)
		var asset: Dictionary=library.get("assets",{}).get(String(placement.asset_id),{})
		if asset.is_empty() or seen.has(id): return {}
		var foot: Vector2=v(placement.foot_px);var anchor: Vector2=v(asset.source_ground_anchor_px)
		var ratio: float=float(placement.scale);var size: Vector2=v(asset.source_size_px)
		if not foot.is_finite() or not anchor.is_finite() or not is_finite(ratio) or ratio<=0: return {}
		var polygons: Array=[]
		for raw: Array in asset.get("source_solid_rects_px",[]):
			var low: Vector2=foot+(Vector2(float(raw[0]),float(raw[1]))-anchor)*ratio
			var high: Vector2=low+Vector2(float(raw[2]),float(raw[3]))*ratio
			polygons.append(PackedVector2Array([low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)]))
		for raw: Variant in asset.get("source_solid_polygons_px",[]):
			var p: PackedVector2Array=PackedVector2Array()
			for q: Variant in raw: p.append(foot+(v(q)-anchor)*ratio)
			polygons.append(p)
		for raw: Variant in asset.get("donor_ground_polygons_px",[]):
			var p: PackedVector2Array=PackedVector2Array()
			for q: Variant in raw: p.append(foot+(v(q)-v(asset.donor_foot_px))*(ratio/float(asset.donor_scale)))
			polygons.append(p)
		if polygons.size()!=placement.get("source_derived_new_ground_polygons_f32",[]).size(): return {}
		for i: int in range(polygons.size()):
			var expected: PackedVector2Array=PackedVector2Array()
			for q: Variant in placement.source_derived_new_ground_polygons_f32[i]: expected.append(v(q))
			if var_to_bytes(polygons[i])!=var_to_bytes(expected): return {}
		var row: Dictionary={"id":id,"texture":asset.texture,"pos":(foot+(size*0.5-anchor)*ratio)/SIZE,"render_size_px":size*ratio,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y,"world_foot_px":[float(foot.x),float(foot.y)],"physical_center_px":[float(foot.x),float(foot.y)],"collision_size_px":[0.0,0.0],"city_v3_solid_polygons_px":polygons,"blocking":not polygons.is_empty()}
		added.append(row);new_ground.append_array(polygons);seen[id]=true
	if scene_id=="luoyang_estate_riverside_20261021ai":
		if new_kitchen.is_empty() or String(new_kitchen.get("id",""))!="new_plain_kitchen_rear_house": return {}
		# Same source module/scale, only this estate instance foot is translated.
		var kitchen: Dictionary=new_kitchen.duplicate(true)
		if not kitchen.has("finish_source_ground_polygons_px"): return {}
		var foot: Vector2=Vector2(2520,1640)
		var anchor: Vector2=v(kitchen.finish_source_anchor_px)
		var ratio: float=float(kitchen.finish_source_scale)
		kitchen.id="finish_i_estate_kitchen_rear_house";kitchen.pos=(foot+(v(kitchen.finish_source_size_px)*0.5-anchor)*ratio)/SIZE
		kitchen.world_foot_px=[2520.0,1640.0];kitchen.physical_center_px=[2520.0,1640.0];kitchen.depth_sort_foot_y=1640.0/SIZE.y
		var polygons: Array=[]
		for raw: Variant in kitchen.finish_source_ground_polygons_px:
			var p: PackedVector2Array=PackedVector2Array()
			for q: Variant in raw: p.append(foot+(v(q)-anchor)*ratio)
			polygons.append(p)
		kitchen.city_v3_solid_polygons_px=polygons;added.append(kitchen);new_ground.append_array(polygons)
	var after: Array=before.duplicate(true);after.append_array(added)
	return {"ok":true,"render":after,"added_render":added,"new_ground":new_ground,"old_render":before.duplicate(true),"NPC_migrations":target.get("npc_migrations",[]).duplicate(true),"new_NPCs":target.get("new_NPC_rows",[]).duplicate(true),"old_passed_components_not_rebuilt":true,"Docks_NAV39_not_a_visual_count_gate":true,"old_navigation":navigation_before.duplicate(true)}
