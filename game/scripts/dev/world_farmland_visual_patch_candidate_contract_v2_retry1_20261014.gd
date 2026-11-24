extends RefCounted
## Technical candidate proof only. Never activates a runtime patch or rewrites NAV.
const PLAN := preload("res://scripts/dev/world_farmland_dirty_plan_v2_20261014.gd")
const SCOPE := "WORLD_FARMLAND_NATIVE_VISUAL_PATCH_12_DIRTY_CANDIDATE_PHASE2"
var failures: Array[String]=[]
var comparisons: Array[Dictionary]=[]
var outside: Array[Dictionary]=[]

func _check(ok: bool,label: String) -> bool:
	if not ok: failures.append(label)
	return ok
func _image(row: Dictionary,raw: bool) -> Image:
	var path: String=row.get("raw_path" if raw else "path","")
	if not _check(FileAccess.get_sha256(path)==row.get("raw_sha256" if raw else "sha256"),"Actual capture bytes "+path): return null
	var image:=Image.load_from_file(path)
	if not _check(image!=null and image.get_format()==Image.FORMAT_RGBA8 and image.get_width()*image.get_height()<=8404992,"Bounded actual RGBA capture"): return null
	return image

func validate(report: Dictionary) -> Dictionary:
	failures.clear(); comparisons.clear(); outside.clear()
	_check(report.get("scope")==SCOPE and report.get("candidate_only")==true and report.get("ready")==true,"Complete independent phase2 candidate")
	_check(report.get("shared_budget_ms")==360000 and float(report.get("elapsed_ms",INF))<360000.0,"Distinct phase2 bounded360 budget")
	_check(report.get("nav_rebuilt")==false and report.get("full64_rebuilt")==false and report.get("Field_loaded")==false and report.get("formal_changed")==false,"No formal/Field/NAV/full64 changes")
	_check(report.get("GPU_canvas")==[24576,16384] and report.get("caster_count")==2578 and report.get("caster_mesh_count")==18 and report.get("bridge_draw_groups")==93 and report.get("guard_count")==4,"Exact whole native world retained")
	_check(report.get("native_actual",{}).get("camera_exact")==true and report.get("native_actual",{}).get("sun_shadows_enabled")==true,"Current actual camera and sun")
	var author: Dictionary=report.get("author_audit",{})
	_check(author.get("all_rectangles_clear")==true and author.get("parcel_count")==12,"All12 actual4px author rectangles clear")
	var plan: Dictionary=report.get("dirty_plan",{})
	_check(plan.get("ids")==PLAN.IDS and plan.get("tile_count")==12 and plan.get("old_count")==18 and plan.get("new_count")==12 and plan.get("halo_px")==96,"Actual fixed12 conservative dirty closure")
	_check(plan.get("projection_binding",{}).get("fixed_original45_only")==true and plan.get("projection_binding",{}).get("original_whole_camera")==report.get("same_whole_camera"),"Dirty closure bound to the original whole45 camera")
	var kernel: Dictionary=plan.get("resampler_support",{})
	var support: int=int(kernel.get("allowed_logical_support_px",0))
	_check(kernel.get("actual_measured")==true and support>0 and support<=5 and support==int(kernel.get("measured_logical_radius",0))+1,"Actual current finite Lanczos2 support plus1 alignment, not96halo")
	var prerequisite: Dictionary=report.get("baseline_QA",{})
	_check(prerequisite.get("sha256")=="13ff6db57dc7041791bad00a2b3525dc6d3f6e48a06e658aed36e29f0d443d49" and FileAccess.get_sha256(prerequisite.get("path",""))==prerequisite.get("sha256") and prerequisite.get("passed")==true,"Independent twoROI formal-baseline prerequisite retained")
	var patch: Dictionary=report.get("material_patch",{})
	_check(patch.get("parcel_count")==12 and patch.get("groups")==2 and patch.get("angle_radians")==0.0 and patch.get("old_random18_removed")==true and patch.get("vertex_function_original_preserved")==true,"Actual new12-only coherent shader")
	_check(patch.get("road_clearance_px")==32 and patch.get("water_clearance_px")==64 and patch.get("clearance_samples_per_fragment")==[9,9] and patch.get("actual_clearance_RF_bound")==true,"Actual road32/RFwater64 sampler exclusion")
	var rows: Array=report.get("rows",[])
	_check(rows.size()==36 and report.get("baseline_pass_count")==1 and report.get("candidate_pass_count")==2,"Baseline12once + new12two repeats")
	var selected: Dictionary={}
	for row: Dictionary in rows:
		var key:=String(row.get("variant"))+"/"+String(row.get("id"))+"/"+str(row.get("pass_index"))
		_check(not selected.has(key),"Unique native capture row")
		selected[key]=row
		_check(PLAN.IDS.has(row.get("id")) and row.get("actual_whole_GPU_canvas")==[24576,16384] and row.get("factor")==2 and row.get("actual_readback_canvas")==[3456,2432] and row.get("actual_transfer_view_released")==true and row.get("source_draw",{}).get("fresh_actual_post_draw_observed")==true,"Actual world draw and bounded integer ROI96 transfer")
	var baselines: Array=report.get("baseline_formal",[])
	_check(baselines.size()==12,"Every old chunk baseline proved")
	var baseline_ids: Array[String]=[]
	for baseline: Dictionary in baselines:
		baseline_ids.append(String(baseline.get("id")))
		_check(baseline.get("byte_exact")==true and baseline.get("pixels")==1572864 and baseline.get("old_RGBA_sha256")==baseline.get("actual_RGBA_sha256") and FileAccess.get_sha256(baseline.get("old_path",""))==baseline.get("old_sha256") and FileAccess.get_sha256(baseline.get("actual_path",""))==baseline.get("actual_sha256"),"Exact full current formal baseline "+String(baseline.get("id")))
	_check(baseline_ids==PLAN.IDS,"Exact12 distinct formal baseline identities")
	var entries: Array=report.get("visual_patch_entries",[])
	_check(entries.size()==12,"Exactly12 candidate visual replacement entries")
	var entry_ids: Array[String]=[]
	for entry: Dictionary in entries:
		entry_ids.append(String(entry.get("id")))
		var captured: Dictionary=selected.get("candidate/"+String(entry.get("id"))+"/0",{})
		_check(entry.get("path")==captured.get("path") and entry.get("sha256")==captured.get("sha256") and entry.get("logical_rect")==captured.get("logical_rect_px") and entry.get("draw_scale")==1.0 and entry.get("old_path")=="res://art/maps/world_map_v15_complete_v9c/chunks/"+String(entry.get("id"))+"_visual.png","Replacement is exactly its native unchanged-scale tile capture")
	_check(entry_ids==PLAN.IDS,"Exact12 distinct replacement identities")
	var mask := Image.create(1536,1024,false,Image.FORMAT_R8)
	for id: String in PLAN.IDS:
		var a: Dictionary=selected.get("candidate/"+id+"/0",{}); var b: Dictionary=selected.get("candidate/"+id+"/1",{})
		for raw: bool in [false,true]:
			var first:=_image(a,raw); var second:=_image(b,raw)
			var exact:=first!=null and second!=null and first.get_size()==second.get_size() and first.get_data()==second.get_data()
			_check(exact,"New raw/logical zero-tolerance repeat "+id)
			comparisons.append({"id":id,"raw":raw,"byte_exact":exact})
		var old:=_image(selected.get("baseline/"+id+"/0",{}),false)
		var fresh:=_image(a,false)
		if old==null or fresh==null: continue
		var rect_array: Array=a.logical_rect_px
		var tile:=Rect2i(int(rect_array[0]),int(rect_array[1]),1536,1024)
		mask.fill(Color.BLACK)
		for parcel: Dictionary in plan.get("parcels",[]):
			var r: Array=parcel.screen_bounds
			var possible:=Rect2i(int(r[0]),int(r[1]),int(r[2]),int(r[3])).grow(support).intersection(tile)
			if possible.has_area(): mask.fill_rect(Rect2i(possible.position-tile.position,possible.size),Color.WHITE)
		var allowed:=mask.get_data(); var old_bytes:=old.get_data(); var new_bytes:=fresh.get_data()
		var changed:=0; var bad:=0
		for pixel in 1536*1024:
			var offset:=pixel*4
			if old_bytes[offset]==new_bytes[offset] and old_bytes[offset+1]==new_bytes[offset+1] and old_bytes[offset+2]==new_bytes[offset+2] and old_bytes[offset+3]==new_bytes[offset+3]: continue
			changed+=1
			if allowed[pixel]==0: bad+=1
		_check(bad==0,"Every non-farm pixel fullRGBA unchanged "+id)
		outside.append({"id":id,"compared_pixels":1536*1024,"changed_pixels":changed,"changed_outside_conservative_parcel_union":bad,"actual_resampler_support_px":support,"mask":"OLD18_NEW12_PROJECTED_RF_VERTEX_EXTREMA_PLUS1_NUMERIC_PLUS_MEASURED_LANCZOS2_SUPPORT_NOT96HALO"})
	var overview: Dictionary=report.get("overview",{})
	var subset: Dictionary=report.get("overview_schema_preflight",{})
	_check(subset.get("used_objects")==45 and subset.get("tile_draws")==47 and subset.get("unique_texture_render_keys")==45 and subset.get("summed_resized_pixels")==1554563 and subset.get("resize_cache_added")==false,"Original12-cell finite actual native body subset preflight before GPU")
	var diagnostic: Dictionary=subset.get("actual_native_diagnostic",{})
	_check(diagnostic.get("sha256")=="7df04d16138233806ecf8f8a7d6fc6203fcec1f46e9af30bf157a318dbbad280" and FileAccess.get_sha256(diagnostic.get("path",""))==diagnostic.get("sha256") and diagnostic.get("source_sha256")=="3bc14fa260556f26a2a56331dc461c46b1174cec7dcbc4f3c3e22c7622a5c129" and diagnostic.get("old_failed_executor_sha256")=="82ae3338879fa01be899c8ada8ec31a0e768a882ca534456da36019c3b38a1be","Actual native CPU counts/source/old failure bound, not geometry tolerance relaxation")
	_check(overview.get("size")==[3072,2048] and overview.get("original_object_count")==2687 and overview.get("replaced_cells")==PLAN.IDS and overview.get("unchanged_cells",[]).size()==52 and overview.get("whole_CPU_Image_requested")==false,"Bounded overview with original2687 bodies and52 unchanged cells")
	_check(FileAccess.get_sha256(overview.get("path",""))==overview.get("sha256") and FileAccess.get_sha256(overview.get("original_path",""))==overview.get("original_sha256"),"Exact new/original overview bytes")
	var original:=Image.load_from_file(overview.get("original_path",""))
	var candidate:=Image.load_from_file(overview.get("path",""))
	if _check(original!=null and candidate!=null and original.get_size()==Vector2i(3072,2048) and candidate.get_size()==original.get_size(),"Actual overview canvas"):
		original.convert(Image.FORMAT_RGBA8); candidate.convert(Image.FORMAT_RGBA8)
		for cell: Dictionary in overview.unchanged_cells:
			var pieces:=String(cell.id).split("_")
			var row:=int(pieces[0].trim_prefix("r")); var col:=int(pieces[1].trim_prefix("c"))
			var rect:=Rect2i(col*384,row*256,384,256)
			_check(not PLAN.IDS.has(cell.id) and original.get_region(rect).get_data()==candidate.get_region(rect).get_data(),"Independent52-cell fullRGBA unchanged "+String(cell.id))
	for path: String in report.get("source_pins",{}): _check(FileAccess.get_sha256(path).to_lower()==String(report.source_pins[path]).to_lower(),"Fresh final exact original/source "+path)
	return {"scope":"CANDIDATE_ONLY12_VISUAL_TILES_NOT_RUNTIME_NOT_FORMAL","passed":failures.is_empty(),"failures":failures.duplicate(),"repeat_comparisons":comparisons.duplicate(true),"outside_farm_RGBA":outside.duplicate(true),"all12_discrete_rectangle_layout_clear":true,"continuous_shader_clearance_not_claimed":true,"production_approved":false,"visual_approved":false,"NAV_credit":false,"Field_credit":false}
