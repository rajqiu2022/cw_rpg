extends SceneTree
## CPU-only native type diagnostic. No material, renderer, imports or publication.
const PLAN := preload("res://scripts/dev/world_farmland_dirty_plan_v2_20261014.gd")
const SOURCE_PATH := "res://art/maps/world_map_v15_complete_v9c/source_contract.json"
const SOURCE_SHA := "85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f"
const EXECUTOR_PATH := "res://scripts/dev/publish_world_farmland_visual_patch_candidate_v2_20261014.gd"
const EXECUTOR_SHA := "82ae3338879fa01be899c8ada8ec31a0e768a882ca534456da36019c3b38a1be"
const PLAN_PATH := "res://scripts/dev/world_farmland_dirty_plan_v2_20261014.gd"
const PLAN_SHA := "e5e2174c5aed9457769f5762eca5088e9c03f4b212bbf3427f6835f4207411f9"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var started:=Time.get_ticks_msec()
	var failures: Array[String]=[]
	if FileAccess.get_sha256(SOURCE_PATH)!=SOURCE_SHA: failures.append("Exact original source pin")
	if FileAccess.get_sha256(EXECUTOR_PATH)!=EXECUTOR_SHA: failures.append("Exact failed executor pin")
	if FileAccess.get_sha256(PLAN_PATH)!=PLAN_SHA: failures.append("Exact frozen twelve-cell plan pin")
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SOURCE_PATH))
	var rows: Array[Dictionary]=[]
	var keys: Dictionary={}; var resized_pixels:=0; var draws:=0
	var fractional_rows: Array[Dictionary]=[]
	for object: Dictionary in source.objects:
		# These operations are copied exactly from the failed preflight and
		# original _v7_composite_roi, not a double-precision scout approximation.
		var size:=Vector2i(object.render_size_px[0],object.render_size_px[1])
		var center:=Vector2(object.pos[0]*12288.0,object.pos[1]*8192.0)
		var bounds:=Rect2i(Vector2i((center-Vector2(size)*.5).round()),size)
		var touched: Array[String]=[]
		for id: String in PLAN.IDS:
			var pieces:=id.split("_")
			var row:=int(pieces[0].trim_prefix("r")); var col:=int(pieces[1].trim_prefix("c"))
			if bounds.intersects(Rect2i(col*1536,row*1024,1536,1024)): touched.append(id)
		if touched.is_empty(): continue
		draws+=touched.size()
		var key:=String(object.texture)+"|"+str(size.x)+"|"+str(size.y)
		if not keys.has(key): keys[key]=true; resized_pixels+=size.x*size.y
		var item: Dictionary={"id":object.id,"texture":object.texture,"original_pos":object.pos,"original_render_size_px":object.render_size_px,"actual_native_size":[size.x,size.y],"actual_native_center":[center.x,center.y],"actual_native_bounds":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"tiles":touched,"tile_draws":touched.size(),"depth_sort_foot_y":object.depth_sort_foot_y}
		rows.append(item)
		if float(object.render_size_px[0])!=float(size.x) or float(object.render_size_px[1])!=float(size.y): fractional_rows.append(item)
	var counts: Dictionary={"original_object_count":source.objects.size(),"used_objects":rows.size(),"tile_draws":draws,"unique_texture_render_keys":keys.size(),"summed_resized_pixels":resized_pixels}
	var report: Dictionary={"scope":"CPU_ONLY_ORIGINAL_NATIVE_OVERVIEW_SUBSET_DIAGNOSTIC_NOT_GPU_NOT_PUBLISHER","source_path":SOURCE_PATH,"source_sha256":SOURCE_SHA,"failed_executor_path":EXECUTOR_PATH,"failed_executor_sha256":EXECUTOR_SHA,"diagnostic_source_path":get_script().resource_path,"diagnostic_source_sha256":FileAccess.get_sha256(get_script().resource_path),"actual_counts":counts,"failed_scout_expectation":{"used_objects":45,"tile_draws":47,"unique_texture_render_keys":45,"summed_resized_pixels":1555023},"actual_used_object_rows":rows,"fractional_original_render_sizes":fractional_rows,"exact_operation":"Vector2i(original size), Float32 Vector2 center, original round(), Rect2i.intersects twelve declared cells","ids":PLAN.IDS,"elapsed_ms":Time.get_ticks_msec()-started,"failures":failures,"GPU_allocated":false,"old_source_changed":false,"thresholds_changed":false}
	var output:="res://build/world_farmland_overview_subset_diagnostic_20261014/%d_%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) or DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))!=OK: quit(1); return
	var file:=FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file==null: quit(1); return
	file.store_string(JSON.stringify(report,"\t")); file.close()
	print("FARM_OVERVIEW_CPU_DIAGNOSTIC="+output+"result.json counts="+JSON.stringify(counts)+" fractional="+JSON.stringify(fractional_rows))
	quit(0 if failures.is_empty() else 1)
