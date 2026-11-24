extends "res://scripts/dev/preview_luoyang_yamen_front_asset_v9.gd"

## Reuse standalone GPU/PNG/source-binding helpers, NEVER parent entry/finish.
## Current V9 baseline is freshly rendered, not copied from earlier evidence.
const CORNER := preload("res://scripts/dev/luoyang_yamen_corner_pair_v10b_preview.gd")
const PAIR_ROOT := "res://build/luoyang_yamen_corner_pair_v10b_preview/"
const PAIR_BODY_RECT := Rect2i(840,1200,1392,640)
const PAIR_VIEWS := {
	"full":{"rect":Rect2i(656,1120,1760,720),"zoom":1},
	"left_2x":{"rect":Rect2i(840,1240,560,520),"zoom":2},
	"right_2x":{"rect":Rect2i(1672,1240,560,520),"zoom":2}
}
const PAIR_RECORD_REL := "assets/raw/scene_module/luoyang_yamen_enclosure_v10b/generation_record.json"
const PAIR_RECORD_SHA := "b974727d5e8f020dc013d5e76cd836fd1becba5e414b0b79b611ee6179523b41"
var corner_plate: CORNER

func _start() -> void:
	# FIRST deferred action, after autoload ready and before ANY await/work.
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		push_error("V10b requires public checkpoint suspension; no fallback.")
		quit(2)
		return
	bridge.call("set_checkpoint_saves_suspended",true)
	var suspended: Variant = bridge.call("is_checkpoint_saves_suspended")
	if not suspended is bool or not suspended:
		push_error("V10b checkpoint suspension not verified.")
		quit(2)
		return
	checkpoint_guard = {"public_api":"PlatformBridge.set_checkpoint_saves_suspended(true)","before_first_await":true,"actual_verified_suspended":true,"restore_before_quit":false}
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var tag := ""
	for arg: String in args:
		if arg.begins_with("--preview-run-tag="): tag = arg.trim_prefix("--preview-run-tag=")
	var rule := RegEx.new()
	if "--luoyang-yamen-corner-pair-v10b-preview" not in args or rule.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$") != OK or rule.search(tag) == null or DisplayServer.get_name() == "headless":
		push_error("Explicit V10b GPU flag and unique safe tag required.")
		quit(2)
		return
	output = PAIR_ROOT+tag+"/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)):
		push_error("Refusing overwrite of previous V10b evidence.")
		quit(2)
		return
	var bridge_script: Script = bridge.get_script() as Script
	if bridge_script == null or not _track(bridge_script.resource_path):
		quit(2)
		return
	var pins: Dictionary = {
		"res://scripts/dev/luoyang_yamen_front_asset_v9_preview.gd":"aa03179f421e2e93c6e4387693ef9e7581312f0c0cf6518f8f5f6cc3f6f9e309",
		"res://scripts/dev/preview_luoyang_yamen_front_asset_v9.gd":"3d39f583feca1cd8ee2c333ef9ee81848d3d03fe74b9eca5b781765dc7f135a0",
		"res://scripts/dev/luoyang_yamen_front_line_v8_preview.gd":V8_HELPER_SHA,
		"res://scripts/dev/preview_luoyang_yamen_front_line_v8.gd":V8_RUNNER_SHA,
		"res://scripts/dev/luoyang_yamen_gate_join_native_v7_preview.gd":FRONT.V7_PIN,
		"res://scripts/dev/preview_luoyang_yamen_gate_join_native_v7.gd":V7_RUNNER_PIN,
		PLATE.repo_path(PLATE.WALL_REL):PLATE.WALL_SHA,
		PLATE.GATE_PATH:PLATE.GATE_SHA,
		PLATE.repo_path("assets/raw/scene_module/luoyang_yamen_front_v9/generation_record.json"):PROVENANCE_SHA,
		PLATE.repo_path(CORNER.ATLAS_REL):CORNER.ATLAS_SHA,
		PLATE.repo_path(PAIR_RECORD_REL):PAIR_RECORD_SHA,
		PLATE.repo_path("assets/raw/scene_module/luoyang_yamen_enclosure_v10/enclosure_modules_v10_candidate.png"):"7711bdf86226b47dc8e96899b051130900f1cf276c3bd2ae48180ca066292002",
		PLATE.repo_path("prompts/templates/luoyang_yamen_enclosure_modules_v10b.yaml"):"072e5dd5c990233f9b4d4b39fd8d1e1509e3260cf91518a972a040f673e30dd1"
	}
	for path: String in pins:
		if not _track(path,String(pins[path])):
			push_error(error)
			quit(2)
			return
	for path: String in [get_script().resource_path,"res://scripts/dev/luoyang_yamen_corner_pair_v10b_preview.gd",PLATE.repo_path("assets/raw/scene_module/luoyang_yamen_enclosure_v10b/offline_call_plan.json")]:
		if not _track(path):
			push_error(error)
			quit(2)
			return
	for path: String in OLD.SOURCE_PINS:
		if not _track(path,OLD.SOURCE_PINS[path]):
			push_error(error)
			quit(2)
			return
	if not _track(INPUT_ROOT+"art_contract.json",MANIFEST_SHA):
		push_error(error)
		quit(2)
		return
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(INPUT_ROOT+"art_contract.json"))
	if not decoded is Dictionary or decoded.get("scene_id") != "ch4_s1_luoyang_yamen":
		push_error("Exact frozen yamen manifest required.")
		quit(2)
		return
	manifest = decoded
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) != OK:
		push_error("Cannot create unique V10b output.")
		quit(2)
		return
	front_asset = FRONT.new()
	asset = front_asset # Ground/environment only: no native wall meshes built.
	corner_plate = CORNER.new()
	plate = corner_plate
	if not asset.prepare() or not corner_plate.prepare():
		error = asset.error if asset.error != "" else corner_plate.error
		await _finish(false)
		return
	var record: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLATE.repo_path(PAIR_RECORD_REL)))
	if not _record_matches_actual(record,CORNER.ATLAS_SHA,corner_plate.atlas_image.get_size()):
		error = "Actual V10b provenance SHA/numeric dimensions do not bind consumed atlas."
		await _finish(false)
		return
	observations["actual_asset_provenance"] = record
	observations["scope"] = {"preview":"V10b SOUTH_CORNER_PAIR_ONLY", "baseline":"Current actual GPU V9, no earlier result PNG used", "carriers":5,"native_walls":0,"A_module_drawn":false,"complete_longitudinal_walls":false,"complete_courtyard":false,"left_replaced_interval":[960,1200],"right_replaced_interval":[1870,2110],"V9_inner_intervals":[[1200,1450.5],[1620.5,1870]],"uniform_BC_scale":CORNER.CORNER_SCALE,"selected_north_run_logical_px":160,"new_thickness_footprint_not_old54px":true,"collision_navigation_Field_production_credit":false,"source_png_edits":false,"alpha_threshold_or_forced_old_alpha":false}
	if not await _pair_body():
		await _finish(false)
		return
	for name: String in PAIR_VIEWS:
		if not await _pair_view(name):
			await _finish(false)
			return
	await _finish(true)

func _record_matches_actual(record: Variant,sha: String,size: Vector2i) -> bool:
	if not record is Dictionary or record.get("sha256") != sha: return false
	var dimensions: Variant = record.get("actual_dimensions_px")
	if not dimensions is Array or dimensions.size() != 2: return false
	for i in range(2):
		var item: Variant = dimensions[i]
		if typeof(item) != TYPE_INT and typeof(item) != TYPE_FLOAT: return false
		var number: float = float(item)
		if not is_finite(number) or number != floor(number) or number != float(size[i]): return false
	return true

func _pair_body() -> bool:
	var rect := PAIR_BODY_RECT
	view = _viewport(rect.size*2,true)
	var group := Node2D.new()
	view.add_child(group)
	var gate_node: Polygon2D = plate.gate(group,rect,1)
	await _sync()
	var gate_raw: Image = await _repeat("V10b unchanged original gate-only UV")
	if gate_raw == null: return false
	var probes: Array = []
	for point: Vector2i in PLATE.KEEP_PROBES+PLATE.EXCLUDE_PROBES+PLATE.HOLE_PROBES:
		var pixel := Vector2i((PLATE.GATE_ORIGIN-Vector2(rect.position))*2.)+point
		var expected: float = plate.gate_image.get_pixelv(point).a if point in PLATE.KEEP_PROBES else 0.
		var actual: float = gate_raw.get_pixelv(pixel).a
		probes.append({"source_px":[point.x,point.y],"source_alpha":plate.gate_image.get_pixelv(point).a,"actual_gpu_alpha":actual,"expected_selected_alpha":expected})
		if absf(actual-expected)>1./255.:
			error = "Actual unchanged gate-only keep/exclude/hole alpha mismatch."
			return false
	observations["gate_only_source_probes"] = probes
	if not _png(output+"gate_only_raw.png",gate_raw): return false
	var nodes: Array[Polygon2D] = plate.walls(group,rect,1)
	var geometry: Array = [_node_geometry(gate_node,rect,1)]
	for node: Polygon2D in nodes: geometry.append(_node_geometry(node,rect,1))
	observations["actual_gpu_carrier_geometry"] = geometry
	await _sync()
	var raw: Image = await _repeat("V10b whole pair actual transparent body")
	if raw == null: return false
	for point: Vector2i in PLATE.HOLE_PROBES:
		var pixel := Vector2i((PLATE.GATE_ORIGIN-Vector2(rect.position))*2.)+point
		if raw.get_pixelv(pixel).a != 0.:
			error = "V10b pair drew inside original door aperture."
			return false
	var image: Image = _alpha_resize(raw,rect.size)
	var used: Rect2i = image.get_used_rect()
	if used.size.x<16 or used.size.y<16 or used.position.x<24 or used.position.y<24 or used.end.x>image.get_width()-24 or used.end.y>image.get_height()-24:
		error = "NEW pair alpha empty/clipped: actual24px breathing boundary required."
		return false
	var crop := Rect2i(used.position-Vector2i(8,8),used.size+Vector2i(16,16))
	var histogram: Array[int] = []
	histogram.resize(256)
	histogram.fill(0)
	var data: PackedByteArray = image.get_data()
	for i in range(3,data.size(),4): histogram[data[i]] += 1
	var remaining: int = int(ceil((image.get_width()*image.get_height()-histogram[0])*.02))
	var support_sum := Vector2.ZERO
	var support_count := 0
	for y in range(image.get_height()-1,-1,-1):
		if remaining<=0: break
		for x in range(image.get_width()):
			if remaining<=0: break
			if image.get_pixel(x,y).a>0.:
				support_sum += Vector2(x+.5,y+.5)
				support_count += 1
				remaining -= 1
	var support: Vector2 = support_sum/float(maxi(support_count,1))
	observations["actual_combined_alpha_crop"] = {"source_rect_global_logical_px":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"raw_px":[raw.get_width(),raw.get_height()],"new_used_rect_px":[used.position.x,used.position.y,used.size.x,used.size.y],"new_crop_rect_px":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"alpha_histogram":histogram,"screen_support_lowest2pct_px":[support.x,support.y],"crop_support_uv":[(support.x-crop.position.x)/crop.size.x,(support.y-crop.position.y)/crop.size.y],"support_scope":"Nonzero-alpha bottom2% screen pixel aggregate ONLY, not physical feet or old footprint", "raw_repeat_byte_exact":true,"old_alpha_forced":false,"visual_alpha_crop_review":"PENDING"}
	if not _png(output+"corner_pair_raw.png",raw) or not _png(output+"corner_pair_body.png",image.get_region(crop)): return false
	view.queue_free()
	view = null
	await _sync()
	return true

func _pair_view(name: String) -> bool:
	var spec: Dictionary = PAIR_VIEWS[name]
	var rect: Rect2i = spec["rect"]
	var zoom: int = spec["zoom"]
	var logical: Vector2i = rect.size*zoom
	view = _viewport(logical*2,false)
	var world: Node3D = _world(view,false)
	for path: String in ["support_plane.res","paving_mesh.res","paving_material.res"]:
		if not _bound_resource(INPUT_ROOT+path): return false
	var support := MeshInstance3D.new()
	support.mesh = ResourceLoader.load(INPUT_ROOT+"support_plane.res","",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	support.material_override = asset.surface.shoulder()
	support.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(support)
	var paving := MeshInstance3D.new()
	paving.mesh = ResourceLoader.load(INPUT_ROOT+"paving_mesh.res","",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	paving.material_override = ResourceLoader.load(INPUT_ROOT+"paving_material.res","",ResourceLoader.CACHE_MODE_IGNORE) as Material
	paving.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(paving)
	if support.mesh == null or paving.mesh == null or paving.material_override == null:
		error = "Frozen support/paving unavailable."
		return false
	var camera: Camera3D = _camera(world,logical,_point(Vector2(rect.position)+Vector2(rect.size)*.5),float(zoom))
	var baseline := Node2D.new()
	view.add_child(baseline)
	corner_plate.baseline_walls(baseline,rect,zoom)
	plate.gate(baseline,rect,zoom)
	await _sync()
	var before: Image = await _repeat(name+" CURRENT V9 actual baseline")
	if before == null: return false
	baseline.free()
	var group := Node2D.new()
	view.add_child(group)
	var nodes: Array[Polygon2D] = plate.walls(group,rect,zoom)
	var gate_node: Polygon2D = plate.gate(group,rect,zoom)
	var geometry: Array = [_node_geometry(gate_node,rect,zoom)]
	for node: Polygon2D in nodes: geometry.append(_node_geometry(node,rect,zoom))
	cameras[name] = {"source_rect_px":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"zoom":zoom,"logical_px":[logical.x,logical.y],"raw_px":[view.size.x,view.size.y],"camera_position_m":_v3(camera.position),"camera_basis":[_v3(camera.basis.x),_v3(camera.basis.y),_v3(camera.basis.z)],"orthographic_size_m":camera.size,"msaa":0,"baseline_current_gpu":true,"baseline_carriers":3,"new_carriers":5,"actual_new_geometry":geometry,"old_native_wall_draws":0,"A_module_draws":0,"whole_enclosure_credit":false,"2x_scope":"GPU magnification only, not native2x density"}
	await _sync()
	var after: Image = await _repeat(name+" NEW V10b actual corner pair")
	if after == null: return false
	before.resize(logical.x,logical.y,Image.INTERPOLATE_LANCZOS)
	after.resize(logical.x,logical.y,Image.INTERPOLATE_LANCZOS)
	if not _png(output+name+"_baseline_v9.png",before) or not _png(output+name+"_new.png",after): return false
	view.queue_free()
	view = null
	await _sync()
	return true

func _finish(passed: bool) -> void:
	if view != null:
		view.queue_free()
		view = null
	new_meshes.clear()
	front_texture = null
	if corner_plate != null: corner_plate.release()
	corner_plate = null
	plate = null
	if asset != null: asset.release()
	asset = null
	front_asset = null
	for frame in range(16): await process_frame
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("is_checkpoint_saves_suspended") or bridge.call("is_checkpoint_saves_suspended") != true:
		passed = false
		error = "Checkpoint suspension did not remain active through quit."
	var changes: Array[String] = []
	var final_inputs: Dictionary = {}
	for path: String in inputs:
		final_inputs[path] = FileAccess.get_sha256(path).to_lower()
		if final_inputs[path] != inputs[path]: changes.append(path)
	if not changes.is_empty():
		passed = false
		error = "Read-only V10b input changed during capture."
	var report: Dictionary = {"status":"PREVIEW_NOT_ADOPTED" if passed else "PREVIEW_FAILED_NOT_ADOPTED","passed_capture_checks":passed,"reason":error,"scope":"V10b TWO SOUTH CORNERS + V9 INNER WALLS + ORIGINAL GATE UV ONLY; longitudinal walls/full courtyard/native/PBR/Field/collision/navigation/audio/release NOT approved", "checkpoint_guard":checkpoint_guard,"inputs_sha256_first":inputs,"inputs_sha256_last":final_inputs,"input_changes":changes,"outputs":outputs,"geometry_and_alpha":observations,"cameras":cameras,"independent_visual_alpha_crop_review":"PENDING","visual_approved":false,"production_approved":false,"audio_credit":"NONE; outer full stderr independent review required, no clean-exit claim"}
	var file: FileAccess = null
	if output != "" and not FileAccess.file_exists(output+"preview_result.json"): file = FileAccess.open(output+"preview_result.json",FileAccess.WRITE)
	if file == null:
		passed = false
		error = "Own V10b result save/overwrite refused."
	else:
		file.store_string(JSON.stringify(report,"\t"))
		file.close()
	if not passed: push_error(error)
	quit(0 if passed else 1)
