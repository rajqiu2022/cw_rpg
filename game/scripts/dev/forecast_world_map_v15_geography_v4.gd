extends SceneTree

const SOURCE := preload("res://scripts/dev/world_map_v15_source_geography_v4.gd")
const OUT := "res://build/world_map_v15_geography_v4/"
var source: SOURCE

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not "--geography-source-plan" in OS.get_cmdline_user_args():
		push_error("CPU authoring forecast only; no rendering or production writes")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	source=SOURCE.new()
	source.prepare()
	var bad: Array[Dictionary]=[]
	var centers := 0
	for route in source.routes:
		var points: PackedVector2Array=route["points"]
		for segment in range(points.size()-1):
			var count: int=maxi(1,ceili(points[segment].distance_to(points[segment+1])/4.))
			for n in range(count+1):
				var point: Vector2=points[segment].lerp(points[segment+1],float(n)/count)
				centers+=1
				for foot in SOURCE.foot_offsets():
					var q: Vector2=point+foot
					if not source.supported_walk(q):
						if bad.size()<256: bad.append({"route_id":route["id"],"center_px":[point.x,point.y],"shoe_px":[q.x,q.y],"selector":source.selector_cell_info(q)})
						break
	var anchors: Array[Dictionary]=[]
	for entry in SOURCE.LANDMARKS:
		var p: Vector2=entry["foot"]
		var projected: Vector2=source.project_source(p)
		var safe := true
		for offset in SOURCE.foot_offsets():
			if not source.supported_walk(p+offset): safe=false
		anchors.append({"id":entry["id"],"source_XZ_foot_px":[p.x,p.y],"projected_door_foot_px":[projected.x,projected.y],"height_m":source.triangle_height(p),"source_full17":safe,"target_scene":entry["target"]})
		if not safe: bad.append({"portal_id":entry["id"],"kind":"actual_source_anchor_full17"})
	var spacing: Dictionary=source.core_spacing()
	if not spacing["passed"]: bad.append({"kind":"projected_nine_door_spacing","measurement":spacing})
	var bridges: Array[Dictionary]=[]
	for bridge in source.structures:
		var p: Vector2=bridge["center"]
		var polygon: Array=[]
		for vertex in bridge["source_deck_polygon"]: polygon.append([vertex.x,vertex.y])
		bridges.append({"id":bridge["id"],"route_id":bridge["route_id"],"river_id":bridge["river_id"],"source_center_px":[p.x,p.y],"actual_bed_m":source.triangle_height(p),"deck_height_m":0.,"source_deck_polygon":polygon,"status":"REAL_NATIVE_SUPPORT_AUTHORED_NOT_GPU_OR_FIELD_APPROVED"})
	var result: Dictionary={"status":"CPU_SOURCE_FORECAST_NOT_PRODUCTION_APPROVED","passed":bad.is_empty(),"route_count":source.routes.size(),"full17_centers":centers,"shoe_count_per_center":SOURCE.foot_offsets().size(),"first_failures":bad,"anchors":anchors,"nine_door_spacing":spacing,"structures":bridges,"source_graph":{source.get_script().resource_path:FileAccess.get_sha256(source.get_script().resource_path),get_script().resource_path:FileAccess.get_sha256(get_script().resource_path)},"unchanged_world_size":[12288,8192],"compound_center_spacing_status":"PENDING_12_LEGACY_SOURCE_DOORSTEP_MEASUREMENTS; doorway spacing is not falsely labelled sprite-center spacing","forecast_scope":"Float32 exact8px affine source surface + real authored support polygons + exact16-angle17 ellipse; no PNG/render/Field or solid polygon approval","production_approved":false}
	var text: String=JSON.stringify(result,"\t")
	var file:=FileAccess.open(OUT+"result.json",FileAccess.WRITE)
	var wrote := file!=null
	if wrote:
		file.store_string(text)
		file.flush()
		wrote=file.get_error()==OK
		file.close()
		wrote=wrote and FileAccess.get_file_as_string(OUT+"result.json")==text and JSON.parse_string(text) is Dictionary
	print("NINE_CORE_FORECAST routes=",source.routes.size()," centers=",centers," bridges=",bridges.size()," bad=",bad.size()," spacing=",spacing)
	source=null
	for i in range(4): await process_frame
	quit(0 if wrote and bad.is_empty() else 1)
