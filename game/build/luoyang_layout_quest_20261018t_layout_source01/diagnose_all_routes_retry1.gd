extends "res://build/luoyang_layout_quest_20261018t_layout_source01/publish_layout_retry1.gd"
## ROOT-only, finite read-only geometry scout. No room compiler, city output,
## ResourceSaver, source mutation or publication. First rejection per route.
const DIAGNOSTIC_KIND="T_RETRY1_ALL_ROUTES_FIRST_REJECTION_NOT_PUBLICATION"
const EXPECTED_AUTHOR_SHA="5a938b9f84f103442ba6096bd6c1f06e2af5b68ad9d1fd8de8b0411d6b0ecfab"
const EXPECTED_TRANSFORM_SHA="d11bf9f3c03e263c5cfd68fd8800982ff8638e7de32163fefee3dee0bb6ef8f4"
const EXPECTED_PUBLISHER_SHA="4e776b53868a47fb39f185f67a55b43d6f24fb5d64c116c06d7b0c79d49b9a02"
var _diagnostic_rows: Array=[]
var _checked_samples: int=0
var _rejected_routes: int=0
var _deadline_hit: bool=false

func mask_pixel(image: Image,p: Vector2i) -> Dictionary:
	if p.x<0 or p.y<0 or p.x>=image.get_width() or p.y>=image.get_height(): return {"outside_image":true,"pixel":[p.x,p.y]}
	var color: Color=image.get_pixelv(p)
	return {"pixel":[p.x,p.y],"rgba":[color.r,color.g,color.b,color.a],"clear":color.a>=.5 and color.r>=.5}

func tagged_solids(record: Dictionary,projection: Dictionary) -> Array:
	var rows: Array=[]
	for object: Dictionary in record.objects:
		for poly: PackedVector2Array in T.c().object_solids([object]): rows.append({"id":String(object.id),"origin":"transformed_parent_record","polygon":poly})
	for entry: Dictionary in projection.additions+projection.replacements:
		for raw_poly: Variant in entry.city_v3_solid_polygons_px: rows.append({"id":String(entry.id),"origin":"unchanged_district_delta","polygon":DG.polygon(raw_poly)})
	return rows

func rejection_reason(foot: Vector2,mask: Image,raw: Image,tags: Array,npc: bool) -> Dictionary:
	var half:=Vector2(17,15) if npc else Vector2(17,12)
	var rect:=Rect2(foot-half,half*2)
	var body:=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	var hits: Array=[]
	for row: Dictionary in tags:
		var intersections: Array=Geometry2D.intersect_polygons(body,row.polygon)
		var single: Array[PackedVector2Array]=[row.polygon]
		var closed_clear: bool=DG.safe_foot(single,foot,half)
		if not intersections.is_empty() or (npc and not closed_clear):
			hits.append({"id":row.id,"origin":row.origin,"continuous_intersection":not intersections.is_empty(),"closed_npc_envelope_clear":closed_clear,"polygon_native":var_to_str(row.polygon)})
	var first_bad: Dictionary={}
	for y: int in range(roundi(rect.position.y),roundi(rect.end.y)+1):
		for x: int in range(roundi(rect.position.x),roundi(rect.end.x)+1):
			var pixel:=Vector2i(x,y)
			var state: Dictionary=mask_pixel(mask,pixel)
			if state.get("clear",false): continue
			first_bad={"mask":state,"raw_support":mask_pixel(raw,pixel),"parent_pixel_solid_ids":[]}
			for row: Dictionary in tags:
				if Geometry2D.is_point_in_polygon(Vector2(pixel),row.polygon): first_bad.parent_pixel_solid_ids.append(row.id)
			break
		if not first_bad.is_empty(): break
	return {"body_rect_native":var_to_str(rect),"solid_hits":hits,"first_bad_rounded_pixel":first_bad,"player_full875":T.c()._safe_body_cpu(foot,mask,_solid_array(tags)),"original_seventeen":T.seventeen(foot,mask),"npc_full1085_continuous":DG._npc_clear(foot,mask,_solid_array(tags)) if npc else null,"classification":"RAW_SUPPORT_OR_PARENT_RASTER_PIXEL" if not first_bad.is_empty() and hits.is_empty() else "NATIVE_SOLID_OR_COMBINED_MASK"}

func _solid_array(tags: Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array]=[]
	for row: Dictionary in tags: result.append(row.polygon)
	return result

func all_paths(record: Dictionary,projection: Dictionary,id: String) -> Array:
	# Same collection as T.audit, plus every authored gameplay patrol/passage/
	# arrival and all ten successor room landings (which aren't all in parent).
	var paths: Array=record.routes.duplicate(true)
	paths.append_array(crowd_routes(id,projection))
	var spec: Dictionary=_author.districts[id]
	for index: int in spec.get("protected_task_feet_px",[]).size():
		var raw: Variant=spec.protected_task_feet_px[index]
		paths.append({"id":"protected_task:"+str(index),"points_px":[raw,raw]})
	for key: String in ["entry_foot_px","return_foot_px"]: paths.append({"id":key,"points_px":[record[key],record[key]]})
	for kind: String in ["interactions","npcs","portals"]:
		var index: int=0
		for slot: Dictionary in record.gameplay_slots.get(kind,[]):
			var key: String=kind+":"+String(slot.get("source_id",slot.get("id",str(index))))
			var anchor_foot: Variant=slot.get("stand_px",slot.get("foot_px"))
			if anchor_foot!=null: paths.append({"id":key,"npc":kind=="npcs","points_px":[anchor_foot,anchor_foot]})
			for point_key: String in ["arrival_foot_px"]:
				if slot.has(point_key): paths.append({"id":key+":"+point_key,"points_px":[slot[point_key],slot[point_key]]})
			for path_key: String in ["patrol_path_px","passage_path_px"]:
				var points: Array=slot.get(path_key,[]).duplicate(true)
				if points.size()==1: points.append(points[0])
				if points.size()>1: paths.append({"id":key+":"+path_key,"npc":kind=="npcs","points_px":points})
			index+=1
	if id=="ch4_s3_luoyang_market":
		for room: Dictionary in _author.room_moves:
			var room_foot: Array=room.return_foot_px
			paths.append({"id":"successor_return:"+room.scene_id,"points_px":[room_foot,room_foot]})
	else:
		var hall_foot: Array=_author.official_hall.return_foot_px
		paths.append({"id":"successor_return:"+_author.official_hall.scene_id,"points_px":[hall_foot,hall_foot]})
	return paths

func inspect_path(route: Dictionary,mask: Image,raw: Image,tags: Array,solids: Array[PackedVector2Array]) -> Dictionary:
	var checked: int=0
	for segment: int in range(route.points_px.size()-1):
		var first: Vector2=T.v(route.points_px[segment]); var last: Vector2=T.v(route.points_px[segment+1])
		var steps: int=maxi(1,ceili(first.distance_to(last)/4.0))
		for sample: int in range(steps+1):
			if Time.get_ticks_msec()-_started>=LIMIT_MS:
				_deadline_hit=true
				return {"id":route.id,"completed":false,"error":"FINITE_60S_BUDGET","checked_samples":checked}
			var foot: Vector2=first.lerp(last,float(sample)/steps)
			checked+=1; _checked_samples+=1
			var player_ok: bool=T.c()._safe_body_cpu(foot,mask,solids)
			var seventeen_ok: bool=T.seventeen(foot,mask)
			var npc_ok: bool=DG._npc_clear(foot,mask,solids) if route.get("npc",false) else true
			if player_ok and seventeen_ok and npc_ok: continue
			return {"id":route.id,"completed":true,"passed":false,"segment":segment,"sample":sample,"steps":steps,"segment_start_px":T.xy(first),"segment_end_px":T.xy(last),"foot_px":T.xy(foot),"checked_samples":checked,"npc":route.get("npc",false),"reason":rejection_reason(foot,mask,raw,tags,not npc_ok)}
	return {"id":route.id,"completed":true,"passed":true,"checked_samples":checked,"npc":route.get("npc",false)}

func inspect_city(id: String) -> bool:
	var p: Dictionary=parent(id)
	if p.is_empty(): return false
	var record: Dictionary=T.compose(p.packet.record,StringName(id),_author,"res://DIAGNOSTIC_ONLY_NO_OUTPUT_WALK.png")
	if not require(not record.is_empty(),"Exact pure transform "+id): return false
	if not track(String(record.raw_walk_path)): return false
	var raw: Image=Image.load_from_file(record.raw_walk_path)
	var mask: Image=T.c().raster_walk(raw,record.objects)
	var projection: Dictionary=district_projection(id)
	if not require(mask!=null and not projection.is_empty(),"Original raw raster / District proof "+id): return false
	var tags: Array=tagged_solids(record,projection)
	var solids: Array[PackedVector2Array]=_solid_array(tags)
	var results: Array=[]
	for route: Dictionary in all_paths(record,projection,id):
		var row: Dictionary=inspect_path(route,mask,raw,tags,solids)
		results.append(row)
		if row.get("completed")==true and row.get("passed")==false: _rejected_routes+=1
		if _deadline_hit: break
	var scout: Array=[]
	if id=="ch4_s3_luoyang_market" and not _deadline_hit:
		# Not an author edit or path waiver; test the Root-suggested central/
		# southern alternative with the identical complete predicates.
		scout.append(inspect_path({"id":"PROPOSAL_ONLY_NW_VIA_MAIN_AND_SOUTH","points_px":[[220,1060],[1536,1060],[1536,1976],[318.08,1976],[318.08,1944]]},mask,raw,tags,solids))
	_diagnostic_rows.append({"scene_id":id,"rows":results,"proposal_scout":scout,"raw_walk_path":record.raw_walk_path,"new_object_count":record.objects.size(),"district_delta_count":DG.delta_solids(projection).size(),"mask_sha256":B.bytes_sha(mask.get_data())})
	return not _deadline_hit

func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	_started=Time.get_ticks_msec(); _geometry_only=true
	_author=read_json(AUTHOR); _migration=read_json(MIGRATION)
	var ok: bool=track(AUTHOR,EXPECTED_AUTHOR_SHA) and track("res://build/luoyang_layout_quest_20261018t_layout_source01/layout_transform.gd",EXPECTED_TRANSFORM_SHA) and track("res://build/luoyang_layout_quest_20261018t_layout_source01/publish_layout_retry1.gd",EXPECTED_PUBLISHER_SHA) and track(get_script().resource_path) and track(MIGRATION)
	if ok:
		for id: String in ["ch4_s3_luoyang_market","ch4_s1_luoyang_yamen"]:
			if not inspect_city(id): ok=false; break
	var final_sources: Dictionary={}
	for path: String in _sources:
		final_sources[path]=FileAccess.get_sha256(path)
		if not require(final_sources[path]==_sources[path],"Diagnostic source changed "+path): ok=false
	var report: Dictionary={"kind":DIAGNOSTIC_KIND,"diagnostic_completed":ok,"error":_error,"all_routes_clear":ok and _rejected_routes==0,"rejected_routes":_rejected_routes,"checked_samples":_checked_samples,"rows":_diagnostic_rows,"source_first":_sources,"source_final":final_sources,"elapsed_ms":Time.get_ticks_msec()-_started,"limit_ms":LIMIT_MS,"rooms_recomputed":0,"city_files_written":0,"not_publication":true,"original_full875_17_continuous34x24_npc1085_34x30_max4px_preserved":true}
	var out: String="res://build/luoyang_layout_route_diagnostic_20261018t/"+str(OS.get_process_id())+"/result.json"
	if not write_json(out,report): ok=false
	print(JSON.stringify({"diagnostic_completed":ok,"rejected_routes":_rejected_routes,"output":out})); quit(0 if ok else 1)
