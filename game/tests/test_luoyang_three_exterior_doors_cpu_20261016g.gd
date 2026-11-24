extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Three source-bound doors only. No C.prepare, Field, imports, old route suite.
const CONTRACT="res://data/maps/luoyang_assembled_interiors_20261016g/exterior_door_candidates_v2.json"
const CONTRACT_SHA="015ba5cf02fa20c1619389bc750c6363421e8ca5f8ff3cdf066c34e7431a52b1"
const RAW=preload("res://tests/helpers/luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd")
const RAW_PATH="res://tests/helpers/luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd"
const RAW_SHA="0f00d4a8a7bc7f514d4b0859275c2eb6d03296dd81eaa170416694c6068b2835"
const WORLD:=Vector2(3072,2048)
var author: Dictionary={}
var contexts: Dictionary={}
func _v(value: Variant) -> Vector2: return value if value is Vector2 else Vector2(value[0],value[1])
func _poly(value: Array) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for point: Variant in value: result.append(_v(point))
	return result
func _context(door: Dictionary) -> Dictionary:
	if contexts.has(door.city_id): return contexts[door.city_id]
	var spec: Dictionary=author.districts[door.city_id]
	if not check(spec.parent_manifest.path==door.parent_manifest and spec.parent_manifest.sha256==door.parent_manifest_sha256,"Current district parent exactly same as door parent"): return {}
	if not track(door.parent_manifest,door.parent_manifest_sha256): return {}
	var parent: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(door.parent_manifest))
	if not check(spec.parent_walk.path==parent.walk_path and spec.parent_walk.sha256==parent.walk_sha256,"Current original mask identity, not a guessed old walk"): return {}
	if not track(parent.walk_path,parent.walk_sha256): return {}
	var physical: Array=[]
	for object: Dictionary in parent.record.objects:
		var index: int=0
		for raw: Array in object.get("solid_polygons_px",[]):
			physical.append({"id":String(object.id)+"_parentpoly_"+str(index),"kind":"UNCHANGED_PARENT_SOLID","points_px":raw});index+=1
		var extent: Vector2=_v(object.collision_size_px)
		if extent.x>0 and extent.y>0:
			var center: Vector2=_v(object.physical_center_px)
			var low: Vector2=center-extent*.5;var high: Vector2=center+extent*.5
			physical.append({"id":String(object.id)+"_parentrect","kind":"UNCHANGED_PARENT_RECT","points_px":[low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)]})
	var parent_count: int=physical.size()
	for placement: Dictionary in spec.placements:
		var asset: Dictionary=author.assets[placement.asset_id]
		var foot: Vector2=_v(placement.foot_px);var anchor: Vector2=_v(asset.source_ground_anchor_px);var ratio: float=placement.scale
		var index: int=0
		for source: Array in asset.ground_solid_polygons_px:
			var points: Array=[]
			for point: Variant in source: points.append(foot+(_v(point)-anchor)*ratio)
			physical.append({"id":String(placement.id)+"_newbase_"+str(index),"kind":"ADDITIVE_DISTRICT_BASE_PARENT_NOT_REMOVED","points_px":points});index+=1
	var oracle:=RAW.new()
	if not check(oracle.configure([[[0,0],[3072,0],[3072,2048],[0,2048]]],physical,WORLD,WORLD),"Independent combined parent plus every current district base",oracle.errors): return {}
	var mask:=Image.load_from_file(parent.walk_path)
	if not check(mask!=null and mask.get_size()==Vector2i(3072,2048),"Actual original source mask, no NAV rebuild"): return {}
	var result: Dictionary={"oracle":oracle,"mask":mask,"parent":parent,"parent_count":parent_count,"combined_count":physical.size(),"delta_count":physical.size()-parent_count}
	contexts[door.city_id]=result
	return result
func _mask_clear(mask: Image,foot: Vector2) -> bool:
	var points: Array=[]
	points.append_array(RAW.SHOES)
	for offset: Vector2 in points:
		var point:=Vector2i((foot+offset).round())
		if point.x<0 or point.y<0 or point.x>=3072 or point.y>=2048: return false
		var color: Color=mask.get_pixelv(point)
		if color.r<.5 or color.a<.5: return false
	var rounded:=foot.round()
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			var point:=Vector2i(rounded+Vector2(x,y))
			if point.x<0 or point.y<0 or point.x>=3072 or point.y>=2048: return false
			var color: Color=mask.get_pixelv(point)
			if color.r<.5 or color.a<.5: return false
	return true
func _door(door: Dictionary) -> bool:
	var context: Dictionary=_context(door)
	if context.is_empty(): return false
	if not track(door.source_texture,door.source_sha256): return false
	var found: Array=[]
	for object: Dictionary in context.parent.record.objects:
		if object.id==door.building_id: found.append(object)
	if not check(found.size()==1,"Exactly one immutable current exterior building"): return false
	var building: Dictionary=found[0]
	if not check(building.texture==door.source_texture and building.source_sha256==door.source_sha256 and _v(building.source_size_px)==_v(door.source_size_px) and _v(building.world_foot_px)==_v(door.expected_parent_foot_px) and _v(building.render_size_px)==_v(door.render_size_px),"Actual source, canvas, render size and original parent foot all exact"): return false
	var source_step: Vector2=_v(door.source_door_step_px);var anchor: Vector2=_v(door.source_ground_anchor_px)
	var projected: Vector2=_v(building.world_foot_px)+(source_step-anchor)*(_v(building.render_size_px)/_v(building.source_size_px))
	if not check(projected==_v(door.world_door_step_px),"Independent native source-foot doorway projection, not alpha bounding box",{"projected":projected,"declared":_v(door.world_door_step_px)}): return false
	if not check(door.enabled==false and _v(door.entry_size_px)==Vector2(40,32) and _v(door.approach_route_px[-1])==_v(door.return_foot_px),"Candidate remains disabled; original full interaction size and exact final return"): return false
	var oracle: RefCounted=context.oracle;var mask: Image=context.mask;var samples: int=0
	for index: int in range(1,door.approach_route_px.size()):
		var a: Vector2=_v(door.approach_route_px[index-1]);var b: Vector2=_v(door.approach_route_px[index])
		var steps: int=maxi(1,ceili(a.distance_to(b)/4.0))
		for step: int in range(steps+1):
			var foot: Vector2=a.lerp(b,float(step)/steps)
			if not check(Time.get_ticks_msec()<deadline and oracle.clear(foot) and _mask_clear(mask,foot),"Three-door short approach continuous34x24/full87517/closed bases <=4world",{"id":door.room_id,"segment":index,"sample":step,"foot":foot,"raw":oracle.last}): return false
			samples+=1
	var uv: Vector2=_v(door.return_foot_px)/WORLD
	records.append({"kind":"THREE_EXTERIOR_SOURCE_AND_COMBINED_CPU","room_id":door.room_id,"city":door.city_id,"building_id":door.building_id,"source_step":source_step,"world_step":projected,"return_native_foot":_v(door.return_foot_px),"return_native_uv":uv,"entry_native_size_uv":Vector2(40,32)/WORLD,"samples":samples,"parent_solids":context.parent_count,"additive_solids":context.delta_count,"combined_solids":context.combined_count,"no_old_solid_removed":true,"Physics_or_Space_claimed":false,"door_enabled":false})
	return true
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+60000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=track(CONTRACT,CONTRACT_SHA) and track(RAW_PATH,RAW_SHA)
	if complete:
		var contract: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
		for key: String in ["district_author","district_binding","district_geometry","district_runtime"]:
			var source: Dictionary=contract.combined_navigation_sources[key]
			if not track(source.path,source.sha256): complete=false;break
		for path: String in [get_script().resource_path,"res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"]:
			if not track(path,FileAccess.get_sha256(path)): complete=false
		if complete:
			author=JSON.parse_string(FileAccess.get_file_as_string(contract.combined_navigation_sources.district_author.path))
			complete=check(contract.no_original_scene_record_or_navigation_mutation and contract.doors.size()==3,"Only frozen three disabled doors; no city scene/Nav mutation")
			for door: Dictionary in contract.doors:
				if not complete or not _door(door): complete=false;break
	contexts.clear()
	finish("res://build/luoyang_three_exterior_doors_cpu_20261016g/%d_%d"%[OS.get_process_id(),began],began,complete,"ONLY_THREE_SOURCE_DOOR_AXES_AND_CURRENT_COMBINED_APPROACHES_NOT_FIELD_PHYSICS_OR_OPEN_DOORS")
