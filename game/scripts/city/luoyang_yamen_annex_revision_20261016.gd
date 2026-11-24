extends RefCounted
## Two exact annex translations after the complete existing assembled parent.
## No old author, image, wall, portal, task or history mutation.
const ID=&"ch4_s1_luoyang_yamen"
const META="yamen_annex_separation_20261016"
const SELF="res://scripts/city/luoyang_yamen_annex_revision_20261016.gd"
const PARENT="res://build/luoyang_city_assembled_publication_20261016b/78428_1686/ch4_s1_luoyang_yamen/manifest.json"
const PARENT_SHA="517a0e68c01dd2ff27a648f72736a100c8523780d5f49423b682c3452b94a32f"
const MOVES={"assembled_east_service_annex":{"before":Vector2(2430,1210),"after":Vector2(2640,1210)},"assembled_west_service_annex":{"before":Vector2(650,1110),"after":Vector2(590,1110)}}
const ADDED_ROUTES=[{"id":"annex_east_separated_lane","points_px":[[2190.0,1260.0],[2190.0,780.0]]},{"id":"annex_west_separated_lane","points_px":[[860.0,1240.0],[860.0,660.0]]},{"id":"annex_east_court_crossing","points_px":[[2190.0,1100.0],[2050.0,1100.0]]},{"id":"annex_west_court_crossing","points_px":[[860.0,1080.0],[1100.0,1080.0]]}]
const ROUTE_DELTA={"id":"assembled_east_service_front","before":[[2050.0,1080.0],[2620.0,1080.0],[2620.0,1260.0],[2430.0,1260.0]],"after":[[2050.0,1080.0],[2790.0,1080.0],[2790.0,1260.0],[2430.0,1260.0]]}
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const OLD=preload("res://scripts/city/luoyang_city_assembled_runtime_20261016b.gd")
const SERIAL=preload("res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd")

static func source_paths() -> Dictionary: return {SELF:true,PARENT:true}
static func parent_record() -> Dictionary:
	if FileAccess.get_sha256(PARENT)!=PARENT_SHA: return {}
	var manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(PARENT))
	if not manifest is Dictionary or manifest.get("scene_id")!=String(ID): return {}
	var record: Dictionary=manifest.record.duplicate(true)
	record["assembled_runtime_binding_sha"]=OLD.BIND_SHA
	record["assembled_parent_task_semantics_preserved"]=true
	return record
static func _v(value: Variant) -> Vector2: return C._vec(value)
static func _xy(value: Vector2) -> Array: return [float(value.x),float(value.y)]
static func compose(parent: Dictionary) -> Dictionary:
	var published:=parent_record()
	if published.is_empty() or not OLD.publication_record_equal(parent,published) or parent.get("objects",[]).size()!=24: return {}
	var record: Dictionary=parent.duplicate(true)
	var count: int=0
	for item: Dictionary in record.objects:
		if not MOVES.has(String(item.id)): continue
		var move: Dictionary=MOVES[String(item.id)]
		if _v(item.world_foot_px)!=move.before: return {}
		var delta: Vector2=move.after-move.before
		for key: String in ["world_foot_px","physical_center_px","world_origin_px"]:
			if item.has(key): item[key]=_xy(_v(item[key])+delta)
		for polygon: Array in item.solid_polygons_px:
			for i: int in polygon.size(): polygon[i]=_xy(_v(polygon[i])+delta)
		item.depth_foot_y=float(move.after.y)
		item["annex_separation_delta_20261016"]={"before":_xy(move.before),"after":_xy(move.after)}
		count+=1
	if count!=2: return {}
	var route_count: int=0
	for route: Dictionary in record.routes:
		if route.id!=ROUTE_DELTA.id: continue
		if not C._equal_value(route.points_px,ROUTE_DELTA.before): return {}
		route.points_px=ROUTE_DELTA.after.duplicate(true); route_count+=1
	if route_count!=1: return {}
	record["annex_route_delta_20261016"]=ROUTE_DELTA.duplicate(true)
	for route: Dictionary in ADDED_ROUTES: record.routes.append(route.duplicate(true))
	record["annex_separation_author_sha256"]=FileAccess.get_sha256(SELF)
	return record
static func apply_scene(parent: SceneScript,record: Dictionary,walk: String) -> SceneScript:
	if parent==null or not OLD.bound(parent) or parent.scene_id!=ID or parent.map_layout.visual_objects.size()!=24 or record.get("objects",[]).size()!=24: return null
	var result:=parent.duplicate(true) as SceneScript
	result.map_layout=parent.map_layout.duplicate(true) as WalkableMapLayout
	var count: int=0
	for entry: Dictionary in result.map_layout.visual_objects:
		var id: String=String(entry.get("id",""))
		if not MOVES.has(id): continue
		var delta: Vector2=MOVES[id].after-MOVES[id].before
		if not entry.get("pos") is Vector2: return null
		entry.pos+=delta/C.SIZE
		var changed: Dictionary={}
		for item: Dictionary in record.objects:
			if item.id==id: changed=item; break
		if changed.is_empty(): return null
		for key: String in ["world_foot_px","physical_center_px","depth_foot_y","annex_separation_delta_20261016"]:
			entry[key]=changed[key].duplicate(true) if changed[key] is Array or changed[key] is Dictionary else changed[key]
		entry.city_v3_solid_polygons_px=changed.solid_polygons_px.duplicate(true)
		# Both y translations are zero: native depthfoot stays byte-identical.
		if entry.has("world_origin_px"): entry.erase("world_origin_px")
		count+=1
	if count!=2: return null
	result.map_layout.walkable_mask_path=walk
	result.set_meta(META,FileAccess.get_sha256(SELF))
	return result if geometry_matches(parent,result,record) else null
static func geometry_matches(parent: SceneScript,result: SceneScript,record: Dictionary) -> bool:
	if parent==null or result==null or parent.map_layout.visual_objects.size()!=24 or result.map_layout.visual_objects.size()!=24: return false
	var moved: int=0
	for index: int in 24:
		var entry: Dictionary=result.map_layout.visual_objects[index]
		var original: Dictionary=parent.map_layout.visual_objects[index]
		var item: Dictionary=record.objects[index]
		if String(entry.id)!=String(original.id) or String(entry.id)!=String(item.id): return false
		if not MOVES.has(String(entry.id)):
			if not C._equal_value(entry,original): return false
			continue
		if entry.has("world_origin_px") or not C._equal_value(entry.city_v3_solid_polygons_px,item.solid_polygons_px) or C._equal_value(entry.city_v3_solid_polygons_px,original.city_v3_solid_polygons_px): return false
		if not C._equal_value(entry.physical_center_px,item.physical_center_px) or not C._equal_value(entry.world_foot_px,item.world_foot_px): return false
		moved+=1
	return moved==2
static func routes_audit(record: Dictionary,mask: Image,solids: Array[PackedVector2Array],cancel: Callable=Callable()) -> Dictionary:
	var samples: int=0
	for route: Dictionary in record.routes:
		for index: int in range(route.points_px.size()-1):
			var a:=_v(route.points_px[index]); var b:=_v(route.points_px[index+1])
			var steps: int=maxi(1,ceili(a.distance_to(b)/4.0))
			for j: int in range(steps+1):
				if cancel.is_valid() and cancel.call(): return {"passed":false,"cancelled":true}
				var foot: Vector2=a.lerp(b,float(j)/steps)
				if not C._safe_body_cpu(foot,mask,solids): return {"passed":false,"route":route.id,"foot":_xy(foot),"samples":samples}
				for offset: Vector2 in [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]:
					var point:=Vector2i((foot+offset).round())
					if point.x<0 or point.y<0 or point.x>=3072 or point.y>=2048: return {"passed":false,"outside":true}
					var pixel: Color=mask.get_pixelv(point)
					if pixel.a<.5 or pixel.r<.5: return {"passed":false,"route":route.id,"foot":_xy(foot),"offset":_xy(offset),"samples":samples}
				samples+=1
	return {"passed":true,"samples":samples,"route_count":record.routes.size(),"added_lane_routes":4,"full875_and17":true,"max_step_px":4}
