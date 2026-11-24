extends SceneTree

# Independent CPU authoring diagnostic only. Does not write art/RF/navigation,
# load the full renderer, alter original footprints, or claim Field traversal.
const SOURCE := preload("res://scripts/dev/world_map_v15_complete_v5_source.gd")
const FOOTPRINTS := "res://data/maps/world_map_v15_complete_v5_landmark_footprints_candidate.json"
const OUTPUT := "res://build/world_map_v15_all27_compound_routes_diagnostic/"
var source: SOURCE
var solids: Array[Dictionary]=[]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if "--diagnose-all27-compound-routes" not in OS.get_cmdline_user_args():
		push_error("Explicit CPU all27 diagnosis argument required.")
		quit(2)
		return
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(FOOTPRINTS))
	if not parsed is Dictionary:
		push_error("Actual footprint source unavailable.")
		quit(1)
		return
	source=SOURCE.new()
	source.prepare()
	for landmark: Dictionary in SOURCE.LANDMARKS:
		var record: Dictionary=parsed.get("landmarks",{}).get(landmark["id"],{})
		if record.is_empty() or FileAccess.get_sha256(landmark["source"]).to_lower()!=String(record.get("source_sha256","")).to_lower():
			push_error("Changed actual compound original: "+String(landmark["id"]))
			quit(1)
			return
		var door: Vector2=source.project_source(landmark["foot"])
		var source_door:=Vector2(record["source_doorstep_px"][0],record["source_doorstep_px"][1])
		var scale:=Vector2(record["render_size_px"][0],record["render_size_px"][1])/Vector2(record["source_size_px"][0],record["source_size_px"][1])
		for polygon: Array in record["solid_polygons_source_px"]:
			var actual:=PackedVector2Array()
			for point: Array in polygon: actual.append(door+(Vector2(point[0],point[1])-source_door)*scale)
			solids.append({"compound_id":landmark["id"],"polygon":actual})
	var reports: Array=[]
	var total_bad:=0
	var total_centers:=0
	for route: Dictionary in source.routes:
		var points: PackedVector2Array=route["points"]
		var intervals: Array=[]
		var active: Dictionary={}
		var route_counts: Dictionary={}
		var count:=0
		var bad:=0
		var selector_bad:=0
		for segment in range(points.size()-1):
			var steps: int=maxi(1,ceili(points[segment].distance_to(points[segment+1])/4.))
			for n in range(steps+1):
				var p: Vector2=points[segment].lerp(points[segment+1],float(n)/steps)
				var projected: Vector2=source.project_source(p)
				for structure: Dictionary in source.structures:
					if Geometry2D.is_point_in_polygon(p,structure["source_deck_polygon"]): projected=p
				var hits: Dictionary={}
				var denied_selector:=false
				for offset: Vector2 in SOURCE.foot_offsets():
					if not source.supported_walk(p+offset): denied_selector=true
					for solid: Dictionary in solids:
						if Geometry2D.is_point_in_polygon(projected+offset,solid["polygon"]): hits[solid["compound_id"]]=true
				if denied_selector: selector_bad+=1
				if denied_selector or not hits.is_empty():
					bad+=1
					for id: String in hits: route_counts[id]=int(route_counts.get(id,0))+1
					if active.is_empty(): active={"start_index":count,"start_source_px":[p.x,p.y],"start_projected_px":[projected.x,projected.y],"compound_ids":[],"center_count":0}
					active["end_index"]=count
					active["end_source_px"]=[p.x,p.y]
					active["end_projected_px"]=[projected.x,projected.y]
					active["center_count"]=int(active["center_count"])+1
					for id: String in hits:
						if id not in active["compound_ids"]: active["compound_ids"].append(id)
				elif not active.is_empty():
					intervals.append(active)
					active={}
				count+=1
		if not active.is_empty(): intervals.append(active)
		reports.append({"route_id":route["id"],"centers":count,"bad_centers":bad,"selector_bad_centers":selector_bad,"compound_hit_centers":route_counts,"all_failure_intervals":intervals})
		total_centers+=count
		total_bad+=bad
	var result: Dictionary={"scope":"ALL27_CPU_SOURCE_SELECTOR_AND_CURRENT_PROJECTED_COMPOUND_SOLIDS_NOT_FIELD","passed":total_bad==0,"route_count":reports.size(),"total_centers":total_centers,"bad_centers":total_bad,"routes":reports,"executed_diagnostic_sha256":FileAccess.get_sha256(get_script().resource_path),"source_sha256":FileAccess.get_sha256(source.get_script().resource_path),"source_footprints_sha256":FileAccess.get_sha256(FOOTPRINTS),"no_failure_record_cap":true,"no_art_or_height_outputs_written":true}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var path: String=OUTPUT+"all27_"+str(Time.get_unix_time_from_system()).replace(".","_")+".json"
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:
		push_error("Cannot save all27 source diagnosis.")
		quit(1)
		return
	var text: String=JSON.stringify(result,"\t")
	file.store_string(text)
	file.flush()
	var code: Error=file.get_error()
	file.close()
	var wrote: bool=code==OK and FileAccess.get_file_as_string(path)==text and JSON.parse_string(text) is Dictionary
	print("ALL27 SOURCE DIAGNOSIS ",path," centers=",total_centers," bad=",total_bad)
	source=null
	solids.clear()
	for i in range(4): await process_frame
	quit(0 if wrote and total_bad==0 else 1)
