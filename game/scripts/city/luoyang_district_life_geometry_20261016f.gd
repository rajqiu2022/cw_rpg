extends RefCounted
## Additive physical contract. The original city Scene/record/mask is never edited.
const SIZE=Vector2(3072,2048)
const BODY=Vector2(34,24)
static func _c() -> Variant: return load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
static func v(value: Variant) -> Vector2:
	return value if value is Vector2 else (Vector2(value[0],value[1]) if value is Array and value.size()==2 else Vector2(INF,INF))
static func xy(point: Vector2) -> Array: return [float(point.x),float(point.y)]
static func polygon(value: Variant) -> PackedVector2Array:
	var out:=PackedVector2Array()
	if not value is Array and not value is PackedVector2Array: return out
	for point: Variant in value: out.append(v(point))
	return out
static func find(rows: Array,id: String) -> Dictionary:
	for row: Dictionary in rows:
		if String(row.get("id",""))==id: return row
	return {}
static func manifest(path: String,sha: String) -> Dictionary:
	if not path.begins_with("res://") or ".." in path or sha.length()!=64 or FileAccess.get_sha256(path)!=sha: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary and value.get("record") is Dictionary else {}
static func project(author: Dictionary,id: StringName) -> Dictionary:
	var spec: Dictionary=author.get("districts",{}).get(String(id),{})
	if spec.is_empty(): return {}
	var parent:=manifest(spec.parent_manifest.path,spec.parent_manifest.sha256)
	if parent.is_empty() or parent.record.get("canonical_scene_id")!=String(id): return {}
	var additions: Array=[]; var replacements: Array=[]; var ids: Dictionary={}
	for placement: Dictionary in spec.get("placements",[]):
		var key: String=String(placement.get("id","")); var asset: Dictionary=author.get("assets",{}).get(String(placement.get("asset_id","")),{})
		if key.is_empty() or ids.has(key) or asset.is_empty(): return {}
		ids[key]=true
		var foot:=v(placement.get("foot_px")); var scale: float=float(placement.get("scale",0))
		var size:=v(asset.get("size_px")); var anchor:=v(asset.get("source_ground_anchor_px"))
		if not foot.is_finite() or not size.is_finite() or not anchor.is_finite() or scale<=0 or not is_finite(scale): return {}
		var solids: Array=[]
		for raw: Variant in asset.get("ground_solid_polygons_px",[]):
			var poly: Array=[]
			for point: Vector2 in polygon(raw): poly.append(xy(foot+(point-anchor)*scale))
			if poly.size()<3 or Geometry2D.triangulate_polygon(polygon(poly)).is_empty(): return {}
			solids.append(poly)
		if solids.is_empty(): return {} # No painted, pass-through props.
		var entry: Dictionary={"id":key,"texture":String(asset.texture),"pos":(foot+(size*.5-anchor)*scale)/SIZE,"render_size_px":size*scale,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y,"world_foot_px":xy(foot),"physical_center_px":xy(foot),"collision_size_px":[0.0,0.0],"city_v3_solid_polygons_px":solids,"blocking":true,"district_life_asset_id":placement.asset_id,"district_life_fade":placement.get("fade",false)}
		var old_id: String=String(placement.get("replaces",""))
		if old_id.is_empty():
			if not find(parent.record.objects,key).is_empty(): return {}
			additions.append(entry)
		else:
			var old:=find(parent.record.objects,old_id)
			if old.is_empty() or key!=old_id: return {}
			if foot!=v(old.world_foot_px):
				# Sole authorized closed-facade alignment; no active door moved.
				if id!=&"ch4_s1_luoyang_yamen" or old_id!="assembled_east_service_annex" or v(old.world_foot_px)!=Vector2(2640,1210) or v(placement.get("expected_parent_foot_px"))!=Vector2(2640,1210) or v(placement.get("render_foot_px"))!=Vector2(2610,1210) or v(placement.get("render_foot_delta_px"))!=Vector2(-30,0) or foot!=Vector2(2610,1210) or scale!=.46: return {}
			# Keep the old exact base as well as the new visible base. No hidden
			# walkability expansion, old door or task/hotspot mutation is authorized.
			entry["replaces"]=old_id
			replacements.append(entry)
	return {"additions":additions,"replacements":replacements,"parent":parent.record,"spec":spec}
static func delta_solids(projected: Dictionary) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array]=[]
	for entry: Dictionary in projected.get("additions",[])+projected.get("replacements",[]):
		for raw: Variant in entry.city_v3_solid_polygons_px: result.append(polygon(raw))
	return result
static func safe_foot(solids: Array[PackedVector2Array],foot: Vector2,half: Vector2=Vector2(17,12),full: bool=false) -> bool:
	if not foot.is_finite() or foot.x<half.x or foot.y<half.y or foot.x>=SIZE.x-half.x or foot.y>=SIZE.y-half.y: return false
	var rect:=Rect2(foot-half,half*2)
	var body:=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	for solid: PackedVector2Array in solids:
		if not Geometry2D.intersect_polygons(body,solid).is_empty(): return false
		# Closed boundaries remain forbidden, including point-only portal queries.
		for point: Vector2 in body:
			if Geometry2D.is_point_in_polygon(point,solid): return false
		for point: Vector2 in solid:
			if rect.has_point(point): return false
		for i: int in body.size():
			for j: int in solid.size():
				if _touch(body[i],body[(i+1)%body.size()],solid[j],solid[(j+1)%solid.size()]): return false
	if full:
		for y: int in range(roundi(rect.position.y),roundi(rect.end.y)+1):
			for x: int in range(roundi(rect.position.x),roundi(rect.end.x)+1):
				for solid: PackedVector2Array in solids:
					if Geometry2D.is_point_in_polygon(Vector2(x,y),solid): return false
	return true
static func apply_render(original: Array,projected: Dictionary) -> Array:
	var result: Array=original.duplicate(true)
	for replacement: Dictionary in projected.replacements:
		var count: int=0
		for entry: Dictionary in result:
			if String(entry.get("id",""))!=replacement.id: continue
			for key: String in ["texture","pos","render_size_px","centered","sort_by_feet","depth_sort_foot_y","district_life_asset_id","district_life_fade"]: entry[key]=replacement[key]
			var existing: Array=entry.get("city_v3_solid_polygons_px",[]).duplicate(true)
			existing.append_array(replacement.city_v3_solid_polygons_px.duplicate(true))
			entry.city_v3_solid_polygons_px=existing; count+=1
		if count!=1: return []
	result.append_array(projected.additions.duplicate(true)); return result
static func audit(author: Dictionary,id: StringName,mask: Image,cancel: Callable=Callable()) -> Dictionary:
	var p:=project(author,id)
	if p.is_empty() or mask==null or mask.get_size()!=Vector2i(SIZE): return {"passed":false,"error":"SOURCE_OR_PROJECT"}
	var c: Variant=_c(); var all: Array[PackedVector2Array]=c.object_solids(p.parent.objects)
	var extra:=delta_solids(p); all.append_array(extra)
	var paths: Array=p.parent.routes.duplicate(true)
	var existing_lanes: Array=[]
	if id in [&"ch4_s0_luoyang_gate",&"ch4_s2_canal_docks"]:
		existing_lanes=load("res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd").lanes(id)
		for lane: Dictionary in existing_lanes:
			var preserved: Dictionary=lane.duplicate(true); preserved["new_npc"]=true
			paths.append(preserved)
	var crowd: Array=p.spec.get("crowd",[])
	for person: Dictionary in crowd:
		var foot:=v(person.foot_px); var distance: float=float(person.get("distance_px",0))
		paths.append({"id":"district_life_"+String(person.id),"points_px":[xy(foot-Vector2(distance,0)),xy(foot+Vector2(distance,0))],"new_npc":true})
	paths.append_array(p.spec.get("required_routes",[]))
	paths.append_array(p.spec.get("protected_routes",[]))
	var approach_boxes: Array[Rect2]=[]
	var protected: Array=[p.parent.entry_foot_px,p.parent.return_foot_px]
	for type: String in ["interactions","npcs","portals"]:
		for slot: Dictionary in p.parent.gameplay_slots.get(type,[]):
			protected.append(slot.get("stand_px",slot.get("foot_px",[])))
			if type=="portals":
				protected.append(slot.arrival_foot_px)
				paths.append({"id":"portal_"+String(slot.source_id),"points_px":slot.passage_path_px})
				var points: Array=slot.passage_path_px
				for i: int in range(points.size()-1):
					var from:=v(points[i]); var to:=v(points[i+1]); var low:=from.min(to); var high:=from.max(to)
					approach_boxes.append(Rect2(low-Vector2(34,30),high-low+Vector2(68,60)))
	for route: Dictionary in p.spec.get("protected_routes",[]):
		for i: int in range(route.points_px.size()-1):
			var from:=v(route.points_px[i]); var to:=v(route.points_px[i+1]); var low:=from.min(to); var high:=from.max(to)
			approach_boxes.append(Rect2(low-Vector2(34,30),high-low+Vector2(68,60)))
	# New always-present task artisan and exact original safe approaches.
	protected.append_array(p.spec.get("protected_feet",[]))
	var samples: int=0; var moving: int=0; var lane_boxes: Array[Rect2]=[]
	for lane: Dictionary in existing_lanes:
		var left:=v(lane.points_px[0]); var right:=v(lane.points_px[1])
		lane_boxes.append(Rect2(left-Vector2(34,30),right-left+Vector2(68,60)))
	for route: Dictionary in paths:
		var npc: bool=bool(route.get("new_npc",false))
		for index: int in range(route.points_px.size()-1):
			var start:=v(route.points_px[index]); var finish:=v(route.points_px[index+1]); var steps: int=maxi(1,ceili(start.distance_to(finish)/4.0))
			if npc:
				var center: Vector2=(start+finish)*.5
				var half: Vector2=(finish-start).abs()*.5+Vector2(17,15)
				if not safe_foot(all,center,half): return {"passed":false,"error":"NPC_CONTINUOUS_SWEEP","route":route.id}
			for i: int in range(steps+1):
				if cancel.is_valid() and cancel.call(): return {"passed":false,"error":"CANCELLED"}
				var foot:=start.lerp(finish,float(i)/steps)
				if not c._safe_body_cpu(foot,mask,all) or not _seventeen(foot,mask) or (npc and not _npc_clear(foot,mask,all)):
					return {"passed":false,"error":"BODY_OR_MASK","route":route.id,"foot_px":xy(foot),"samples":samples}
				samples+=1
	for raw: Variant in protected:
		var foot:=v(raw)
		# Only the additional solids are checked here: original NPC feet can be
		# on their own original occupancy. Original parent proof remains intact.
		if not safe_foot(extra,foot,Vector2(17,15),true): return {"passed":false,"error":"PROTECTED_ANCHOR","foot_px":raw}
	for person: Dictionary in crowd:
		var foot:=v(person.foot_px); var distance: float=float(person.get("distance_px",0))
		var box:=Rect2(foot-Vector2(distance+34,30),Vector2(distance*2+68,60))
		for other: Rect2 in lane_boxes:
			if box.intersects(other,true): return {"passed":false,"error":"LANE_CONFLICT","npc":person.id}
		for other: Rect2 in approach_boxes:
			if box.intersects(other,true): return {"passed":false,"error":"APPROACH_CORRIDOR_CONFLICT","npc":person.id}
		for raw: Variant in protected:
			if box.grow(34).has_point(v(raw)): return {"passed":false,"error":"NPC_APPROACH_CONFLICT","npc":person.id,"foot_px":raw}
		lane_boxes.append(box)
		if distance>0: moving+=1
	return {"passed":true,"scene_id":String(id),"samples":samples,"new_npcs":crowd.size(),"moving":moving,"stationary":crowd.size()-moving,"delta_polygons":extra.size(),"full875":true,"seventeen":true,"npc_continuous_body_px":[34,30],"max_step_px":4,"old_nav_unchanged":true}
static func _cross(a: Vector2,b: Vector2,p: Vector2) -> float:
	return (float(b.x)-a.x)*(float(p.y)-a.y)-(float(b.y)-a.y)*(float(p.x)-a.x)
static func _on(a: Vector2,b: Vector2,p: Vector2) -> bool:
	return _cross(a,b,p)==0.0 and p.x>=minf(a.x,b.x) and p.x<=maxf(a.x,b.x) and p.y>=minf(a.y,b.y) and p.y<=maxf(a.y,b.y)
static func _touch(a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> bool:
	var x: float=_cross(a,b,c); var y: float=_cross(a,b,d); var u: float=_cross(c,d,a); var w: float=_cross(c,d,b)
	return (x*y<0.0 and u*w<0.0) or _on(a,b,c) or _on(a,b,d) or _on(c,d,a) or _on(c,d,b)
static func _seventeen(foot: Vector2,mask: Image) -> bool:
	for offset: Vector2 in [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]:
		var p:=Vector2i((foot+offset).round())
		if p.x<0 or p.y<0 or p.x>=mask.get_width() or p.y>=mask.get_height(): return false
		var color:=mask.get_pixelv(p)
		if color.r<.5 or color.a<.5: return false
	return true
static func _npc_clear(foot: Vector2,mask: Image,solids: Array[PackedVector2Array]) -> bool:
	# Preserve the original continuous envelope AND every closed rounded pixel
	# through its full rectangle hull. This is stronger than testing the1085
	# rounded centers individually; no poly-per-pixel inner loop is necessary.
	if not safe_foot(solids,foot,Vector2(17,15)): return false
	var lower: Vector2=(foot-Vector2(17,15)).round()
	var upper: Vector2=(foot+Vector2(17,15)).round()
	if not safe_foot(solids,(lower+upper)*.5,(upper-lower)*.5): return false
	for y: int in range(-15,16):
		for x: int in range(-17,18):
			var p:=Vector2i((foot+Vector2(x,y)).round())
			if p.x<0 or p.y<0 or p.x>=mask.get_width() or p.y>=mask.get_height(): return false
			var color:=mask.get_pixelv(p)
			if color.r<.5 or color.a<.5: return false
	return true
