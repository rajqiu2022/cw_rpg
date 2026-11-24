extends "res://tests/test_luoyang_city_life_cpu_key_20261016f.gd"
## Single fixed failure decomposition only. No city preparation/full route rerun.
const FOOT=Vector2(2226,1350)
func components(oracle: RefCounted,label: String) -> Dictionary:
	var accepted: bool=oracle.clear(FOOT)
	var rect:=Rect2(FOOT-Vector2(17,12),Vector2(34,24))
	var rounded:=Rect2(FOOT.round()-Vector2(17,12),Vector2(34,24))
	var body:=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	var selected: Array=[]; var intersections: Array=[]; var clips: Array=[]
	for i: int in oracle.full_solids.size():
		if rect.merge(rounded).intersects(oracle.bounds[i],true):
			selected.append(i)
			var hit:=Geometry2D.intersect_polygons(body,oracle.full_solids[i])
			if not hit.is_empty(): intersections.append({"index":i,"polygons":hit})
	for floor_poly: PackedVector2Array in oracle.floors: clips.append(Geometry2D.clip_polygons(body,floor_poly))
	var bad17: Array=[]; var first875: Dictionary={}; var bad_count:=0
	for offset: Vector2 in oracle.OFFSETS:
		var point:=FOOT+offset
		if not oracle.point_clear(point): bad17.append(point_parts(oracle,point))
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			var point:=FOOT.round()+Vector2(x,y)
			if not oracle.point_clear(point):
				bad_count+=1
				if first875.is_empty(): first875=point_parts(oracle,point)
	return {"case":label,"accepted":accepted,"world_size":oracle.size,"floors":oracle.floors,"body":body,"prefilter_indices":selected,"all_solids_count":oracle.full_solids.size(),"continuous_intersections":intersections,"floor_clip_results":clips,"bad17":bad17,"bad875_count":bad_count,"first_bad875":first875}
func point_parts(oracle: RefCounted,point: Vector2) -> Dictionary:
	var floors_inside: Array=[]; var solid_inside: Array=[]
	for i: int in oracle.floors.size():
		if Geometry2D.is_point_in_polygon(point,oracle.floors[i]): floors_inside.append(i)
	for i: int in oracle.full_solids.size():
		if Geometry2D.is_point_in_polygon(point,oracle.full_solids[i]): solid_inside.append(i)
	var color: Variant=null
	if oracle.mask!=null: color=oracle.mask.get_pixelv(Vector2i(point.round()))
	return {"point":point,"floor_inside":floors_inside,"solid_inside":solid_inside,"raw_mask_color":color,"point_clear":oracle.point_clear(point)}
func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+10000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true); players_before=saves()
	var complete:=false
	if track(R.AUTHOR_PATH,"d98c65879681b58feea64158a4d0bde33d2ef9fc6b8a25d7d2f33dc961a9c59c") and track("res://tests/helpers/city_life_independent_oracle_20261016f.gd","7acaec19355a492e5788014ffc1850cbd8db12c6d53bfa896460b10521c1aa33"):
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(R.AUTHOR_PATH))
		var spec: Dictionary=data.districts.ch4_s3_luoyang_market
		if track(spec.parent_manifest.path,spec.parent_manifest.sha256):
			var parent: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.parent_manifest.path))
			if track(parent.walk_path,parent.walk_sha256):
				var mask:=Image.load_from_file(parent.walk_path)
				var builder:=RAW.new(); var delta:=builder.compile_delta(data,spec)
				for label: String in ["old_only","combined","delta_only"]:
					var oracle:=RAW.new()
					var ok: bool=oracle.configure_record(parent.record,mask,{} if label=="old_only" else delta,label=="delta_only")
					if not check(ok,"Fixed-point oracle configuration "+label): break
					if label=="delta_only": oracle.mask=null
					records.append(components(oracle,label))
				complete=records.size()==3
	finish("res://build/luoyang_city_life_point_diagnostic_20261016f/%d_%d"%[OS.get_process_id(),began],began,complete,"ONE_FIXED_POINT_COMPONENTS_NOT_GEOMETRY_ACCEPTANCE")
