extends RefCounted
## Independent bounded candidate evidence checks; no publisher/Field approval.
var failures: Array[String] = []
var comparisons: Array[Dictionary] = []
func _check(value: bool,label: String) -> bool:
	if not value: failures.append(label)
	return value
func _image(record: Dictionary,kind: String) -> Image:
	var path: String=record.get("raw_path" if kind=="raw" else "path","")
	if not _check(FileAccess.get_sha256(path)==record.get("raw_sha256" if kind=="raw" else "sha256"),"Exact capture file "+path): return null
	var image := Image.load_from_file(path)
	if not _check(image != null and image.get_format()==Image.FORMAT_RGBA8 and image.get_width()*image.get_height()<=8404992,"Bounded actual RGBA image"): return null
	return image
func validate(report: Dictionary) -> Dictionary:
	failures.clear(); comparisons.clear()
	_check(report.get("scope")=="WORLD_FARMLAND_NATIVE_WHOLE_CAMERA_TWO_ROI_PHASE1" and report.get("candidate_only")==true and report.get("ready")==true,"Correct finite candidate scope/complete execution")
	_check(report.get("nav_rebuilt")==false and report.get("full64_rebuilt")==false and report.get("Field_loaded")==false and report.get("formal_changed")==false,"No formal/NAV/full64/Field credit")
	var patch: Dictionary=report.get("material_patch",{})
	_check(patch.get("parcel_count")==12 and patch.get("groups")==2 and patch.get("angle_radians")==0.0 and patch.get("old_random18_removed")==true and patch.get("vertex_function_original_preserved")==true,"Actual new12 coherent shader preserves vertex/header")
	_check(patch.get("road_clearance_px")==32 and patch.get("water_clearance_px")==64 and patch.get("clearance_samples_per_fragment")==[9,9] and patch.get("actual_clearance_RF_bound")==true,"Actual hard road32/water64 fragment samplers bound")
	_check(report.get("GPU_canvas")==[24576,16384] and report.get("caster_count")==2578 and report.get("caster_mesh_count")==18 and report.get("guard_count")==4 and report.get("bridge_draw_groups")==93,"Exact native full-camera/caster/guard geometry scope")
	_check(report.get("native_actual",{}).get("camera_exact")==true and report.get("native_actual",{}).get("sun_shadows_enabled")==true,"Actual current full camera and shadow-enabled sun observed")
	var rows: Array=report.get("rows",[])
	_check(rows.size()==8,"TwoROIs / baseline+new / fresh repeat capture count")
	var selected: Dictionary={}
	for row: Dictionary in rows:
		var key: String=String(row.get("variant"))+"/"+String(row.get("id"))+"/"+str(row.get("pass_index"))
		_check(not selected.has(key),"Unique actual capture identity")
		selected[key]=row
		_check(row.get("actual_whole_GPU_canvas")==[24576,16384] and row.get("factor")==2 and row.get("actual_readback_canvas")==[3456,2432] and row.get("actual_transfer_view_released")==true and row.get("source_draw",{}).get("fresh_actual_post_draw_observed")==true,"Actual whole native draw/ROI96 integer transfer release")
	for variant: String in ["baseline","candidate"]:
		for id: String in ["linxi_fields","jiangnan_fields"]:
			var a: Dictionary=selected.get(variant+"/"+id+"/0",{}); var b: Dictionary=selected.get(variant+"/"+id+"/1",{})
			for kind: String in ["raw","logical"]:
				var first: Image=_image(a,kind); var second: Image=_image(b,kind)
				var exact := first != null and second != null and first.get_size()==second.get_size() and first.get_data()==second.get_data()
				_check(exact,"Actual zero-tolerance repeated "+variant+"/"+id+"/"+kind)
				comparisons.append({"variant":variant,"roi":id,"kind":kind,"repeat_byte_exact":exact})
	for id: String in ["linxi_fields","jiangnan_fields"]:
		var old: Image=_image(selected.get("baseline/"+id+"/0",{}),"logical")
		var fresh: Image=_image(selected.get("candidate/"+id+"/0",{}),"logical")
		_check(old != null and fresh != null and old.get_size()==fresh.get_size() and old.get_data()!=fresh.get_data(),"New farmland must actually affect ROI "+id)
	for path: String in report.get("source_pins",{}):
		_check(FileAccess.get_sha256(path).to_lower()==String(report.source_pins[path]).to_lower(),"Current final protected input "+path)
	return {"scope":"NATIVE_TWO_ROI_REPEAT_AND_SOURCE_IDENTITY_NOT_PUBLICATION","passed":failures.is_empty(),"failures":failures.duplicate(),"comparisons":comparisons.duplicate(true),"all12_full_rectangle_clear":false,"dirty_tile_publisher_ready":false,"visual_approved":false,"production_approved":false}
