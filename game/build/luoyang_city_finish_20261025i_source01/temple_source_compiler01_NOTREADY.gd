extends RefCounted
## Pure source-author successor. The publisher must pin/hash all three inputs
## before this call. No Scene/native load, IO, cached state or old route replay.
const PARENT_AUTHOR_SHA="d03aa28b5eec9ad91296b8d3cc1d6aeb6782bde8be69b268d81f05550b63410a"
const DESIGN_SHA="577d8100ca3e691848533585e89c823f10db7c5b195f04cb2273e4609066bcae"
const LIBRARY_SHA="17217d76c081e3a53a3b7c13c02f075c216c6a36ec8d8304c66f4f1f4df2ae9d"
const SIZE=Vector2(1536,1024)

static func v(a: Variant) -> Vector2:
	if a is Vector2: return a
	if a is Array and a.size()==2 and (a[0] is int or a[0] is float) and (a[1] is int or a[1] is float):
		return Vector2(a[0],a[1])
	return Vector2(INF,INF)

static func index(rows: Array,id: String) -> int:
	var found: int=-1
	for i: int in range(rows.size()):
		if not rows[i] is Dictionary: return -1
		if String(rows[i].get("id",""))==id:
			if found>=0: return -1
			found=i
	return found

static func json_point(p: Vector2) -> Array:
	return [float(p.x),float(p.y)]

static func replace_at(out: Dictionary,key: String,ordinal: int,next: Variant,journal: Array) -> void:
	var rows: Array=out[key]
	journal.append({"kind":"REPLACE_ROW","key":key,"ordinal":ordinal,"old":rows[ordinal].duplicate(true),"new":next.duplicate(true)})
	rows[ordinal]=next

static func compile(parent: Dictionary,design: Dictionary,library: Dictionary,verified_raw_pins: Dictionary) -> Dictionary:
	if verified_raw_pins!={"parent":PARENT_AUTHOR_SHA,"design":DESIGN_SHA,"library":LIBRARY_SHA}: return {}
	if parent.get("scene_id")!="ch4_s4_ancient_temple" or parent.get("placements",[]).size()!=21 or design.get("group_id")!="03_temple_front_courts_and_loop" or design.get("ready")!=false: return {}
	if design.get("same_object_migrations",[]).size()!=2 or design.get("placements",[]).size()!=2 or design.get("same_interaction_migrations",[]).size()!=1: return {}
	var wing: Dictionary=library.get("assets",{}).get("plain_wing",{})
	if wing.is_empty() or wing.get("source_solid_rects_px",[]).size()!=2: return {}
	var out: Dictionary=parent.duplicate(true)
	# Work with the actual source's existing polygon bases, not a roof rectangle.
	var bases_before: Array=parent.geometry.furniture_bases
	var bases: Array=bases_before.duplicate(true)
	var changed_old: Array=[]
	var changed_new: Array=[]
	for move: Dictionary in design.same_object_migrations:
		var p_index: int=index(out.placements,String(move.id))
		var b_index: int=index(bases,String(move.id))
		if p_index<0 or b_index<0: return {}
		var old_p: Dictionary=out.placements[p_index]
		if v(old_p.get("foot_px"))!=v(move.old_foot_px) or float(old_p.get("scale",0))!=float(move.old_scale): return {}
		var next_p: Dictionary=old_p.duplicate(true)
		next_p.foot_px=move.new_foot_px.duplicate()
		next_p.scale=move.new_scale
		out.placements[p_index]=next_p
		var old_b: Dictionary=bases[b_index]
		var next_b: Dictionary=old_b.duplicate(true)
		var points: Array=[]
		var ratio: float=float(move.new_scale)/float(move.old_scale)
		for raw: Variant in old_b.ground_polygon_px:
			var point: Vector2=v(raw)
			if not point.is_finite(): return {}
			points.append(json_point(v(move.new_foot_px)+(point-v(move.old_foot_px))*ratio))
		next_b.ground_polygon_px=points
		bases[b_index]=next_b
		changed_old.append(old_b.duplicate(true))
		changed_new.append(next_b.duplicate(true))
	var wing_asset: Dictionary={"id":"finish_i_plain_wing","texture":wing.texture,"size_px":wing.source_size_px.duplicate(),"source_ground_anchor_px":wing.source_ground_anchor_px.duplicate(),"source_sha256":wing.source_sha256}
	if index(out.assets,String(wing_asset.id))>=0: return {}
	out.assets.append(wing_asset)
	out.texture_count=out.assets.size()
	var additions: Array=[]
	for placement: Dictionary in design.placements:
		if placement.get("asset_id")!="plain_wing" or index(out.placements,String(placement.id))>=0: return {}
		var foot: Vector2=v(placement.foot_px)
		var scale_value: float=float(placement.scale)
		if not foot.is_finite() or scale_value!=.33: return {}
		out.placements.append({"id":placement.id,"asset_id":wing_asset.id,"foot_px":placement.foot_px.duplicate(),"scale":placement.scale,"fade_allowed":false,"role":placement.purpose})
		for ordinal: int in range(wing.source_solid_rects_px.size()):
			var raw: Array=wing.source_solid_rects_px[ordinal]
			if raw.size()!=4: return {}
			var low: Vector2=Vector2(raw[0],raw[1])
			var high: Vector2=low+Vector2(raw[2],raw[3])
			var points: Array=[]
			for point: Vector2 in PackedVector2Array([low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)]):
				points.append(json_point(foot+(point-v(wing.source_ground_anchor_px))*scale_value))
			var base: Dictionary={"id":String(placement.id)+"_base_"+str(ordinal),"blocking":true,"ground_polygon_px":points,"owner_id":placement.id}
			bases.append(base)
			additions.append(base.duplicate(true))
	out.geometry.furniture_bases=bases
	var bell_index: int=index(out.interaction_relocations,"legacy_hotspot_5")
	if bell_index<0 or v(out.interaction_relocations[bell_index].new_foot_px)!=Vector2(1320,670): return {}
	out.interaction_relocations[bell_index].new_foot_px=[1320,620]
	out.interaction_relocations[bell_index].new_pos_uv=json_point(Vector2(1320,620)/SIZE)
	# Only four affected source routes change. All other route rows remain exact.
	var route_delta: Dictionary={
		"default_to_herb_shaded_boundary_stone":[[768,737.28],[730,940],[170,940],[170,740]],
		"ambush_to_real_bell_front":[[920,620],[1080,620],[1320,620]],
		"default_to_market_return":[[768,737.28],[768,960],[170,960],[170,980]],
		"default_to_docks_return":[[768,737.28],[768,960],[1380,960],[1380,980]]}
	for id: String in route_delta:
		var ordinal: int=index(out.required_routes,id)
		if ordinal<0: return {}
		out.required_routes[ordinal].points_px=route_delta[id].duplicate(true)
	for negative: Dictionary in out.negative_points:
		for move: Dictionary in design.same_object_migrations:
			if negative.get("prop_id")==move.id:
				negative.foot_px=json_point(v(move.new_foot_px)+(v(negative.foot_px)-v(move.old_foot_px))*(float(move.new_scale)/float(move.old_scale)))
	out.finish_i_effective_portal_local_migrations=design.portal_local_position_migrations.duplicate(true)
	out.finish_i_incoming_target_migrations=design.incoming_target_migrations.duplicate(true)
	out.finish_i_ready=false
	out.finish_i_no_new_room_or_task=true
	if out.placements.size()!=23 or bases.size()!=25 or additions.size()!=4: return {}
	# Exact reversible field journal. Geometry is one field because it is the
	# actual existing nested container; never remove an unknown source field.
	var journal: Array=[]
	for key: String in out:
		if not parent.has(key): journal.append({"kind":"ADD_FIELD","key":key,"new":out[key]})
		elif var_to_bytes(parent[key])!=var_to_bytes(out[key]): journal.append({"kind":"REPLACE_FIELD","key":key,"old":parent[key],"new":out[key]})
	var result: Dictionary={"ok":true,"author":out,"journal":journal,"retired_bases":changed_old,"replacement_bases":changed_new,"added_bases":additions,"new_route_ids":route_delta.keys(),"no_old_route_replay":true,"new_geometry_or_ART_pass":false}
	if var_to_bytes(restore(result))!=var_to_bytes(parent): return {}
	return result

static func restore(compiled: Dictionary) -> Dictionary:
	if compiled.get("ok")!=true or not compiled.get("author") is Dictionary or not compiled.get("journal") is Array: return {}
	var out: Dictionary=compiled.author.duplicate(true)
	var journal: Array=compiled.journal
	for ordinal: int in range(journal.size()-1,-1,-1):
		var change: Dictionary=journal[ordinal]
		var key: String=String(change.key)
		if not out.has(key) or var_to_bytes(out[key])!=var_to_bytes(change.get("new")): return {}
		if change.kind=="ADD_FIELD": out.erase(key)
		elif change.kind=="REPLACE_FIELD": out[key]=change.old.duplicate(true) if change.old is Array or change.old is Dictionary else change.old
		else: return {}
	return out
