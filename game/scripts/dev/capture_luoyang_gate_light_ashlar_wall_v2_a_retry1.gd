extends "res://scripts/dev/capture_luoyang_gate_light_ashlar_wall_v2_a.gd"

## Narrow retry for root01's correctly rejected foot mismatch.
##
## Reuses the complete v2 A-only material, bevel, GPU, comparison and guard
## helpers.  The only art change is to author against the measured v1 straight
## wall draw depth and its separate minimum-Y support hull, rather than against
## the removed tile-cap source bounds.

const RETRY_RUN_FLAG := "--capture-luoyang-gate-light-ashlar-wall-v2-a-retry1"
const PARENT_CAPTURE_SCRIPT := "res://scripts/dev/capture_luoyang_gate_light_ashlar_wall_v2_a.gd"
const PARENT_CAPTURE_SCRIPT_SHA := "47113e00feb4e108a95e0adb2a8b7362afb704d013baa71ffb6674bf4f8c6695"
const PARENT_CONTRACT := "res://art/modules/luoyang_gate_fortification_v2_a/source_contract.json"
const PARENT_CONTRACT_SHA := "a1dc57bf8dba164ae227136c21d84353df3f2e776de092b1f7efc9a689f60893"
const RETRY_OUTPUT_ROOT := "res://art/modules/luoyang_gate_fortification_v2_a_retry1/"
const RETRY_AUTHORING_CONTRACT := RETRY_OUTPUT_ROOT + "source_contract.json"
const RETRY_OUTPUTS := {
	"wall_mesh": RETRY_OUTPUT_ROOT + "luoyang_gate_wall_light_ashlar_straight_v2_a_retry1.res",
	"wall_png": RETRY_OUTPUT_ROOT + "luoyang_gate_wall_light_ashlar_straight_v2_a_retry1.png",
	"comparison_png": RETRY_OUTPUT_ROOT + "luoyang_gate_wall_light_ashlar_v2_a_retry1_vs_south_gate.png",
	"result": RETRY_OUTPUT_ROOT + "capture_result.json",
}

const RETRY_DRAW_MIN := Vector3(-2.5,0.0,-0.361250013113022)
const RETRY_DRAW_MAX := Vector3(2.5,1.98000001907349,0.361250013113022)
const RETRY_SUPPORT_MIN := Vector3(-2.46,0.0,-0.34375)
const RETRY_SUPPORT_MAX := Vector3(2.46,0.0,0.34375)


func _start() -> void:
	# First deferred action and strictly before the first await.
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		_fail_now("A-only retry requires public checkpoint suspension; no fallback.")
		return
	bridge.call("set_checkpoint_saves_suspended",true)
	if bridge.call("is_checkpoint_saves_suspended") != true:
		_fail_now("Checkpoint suspension was not verified before A-only retry authoring.")
		return
	checkpoint_guard = {
		"public_api":"PlatformBridge.set_checkpoint_saves_suspended(true)",
		"before_first_await":true,
		"verified_suspended":true,
		"restored_before_quit":false,
	}

	var args: PackedStringArray = OS.get_cmdline_user_args()
	var run_tag := ""
	for arg: String in args:
		if arg.begins_with("--capture-run-tag="):
			run_tag = arg.trim_prefix("--capture-run-tag=")
	var tag_rule := RegEx.new()
	if RETRY_RUN_FLAG not in args or tag_rule.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$") != OK or tag_rule.search(run_tag) == null:
		_fail_now("Explicit retry1 flag and a safe unique --capture-run-tag are required.")
		return
	if DisplayServer.get_name() == "headless":
		_fail_now("Transparent native GPU capture refuses a headless display server.")
		return
	for path: String in RETRY_OUTPUTS.values():
		if FileAccess.file_exists(path):
			_fail_now("Refusing to overwrite an existing retry1 output: " + path)
			return

	if not _track(get_script().resource_path) or not _track(PARENT_CAPTURE_SCRIPT,PARENT_CAPTURE_SCRIPT_SHA) or not _track(PARENT_CONTRACT,PARENT_CONTRACT_SHA) or not _track(BASE_CAPTURE_SCRIPT,BASE_CAPTURE_SCRIPT_SHA) or not _track(RETRY_AUTHORING_CONTRACT) or not _track(V1_RESULT,V1_RESULT_SHA) or not _track(SOURCE_CONTRACT,SOURCE_CONTRACT_SHA):
		_fail_now(error)
		return
	var art_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_CONTRACT))
	if not art_value is Dictionary or art_value.get("scene_id") != "ch4_s0_luoyang_gate":
		_fail_now("Exact frozen Luoyang gate art contract is required.")
		return
	source_contract = art_value
	if not _validate_gate_contract(source_contract):
		_fail_now(error)
		return
	var author_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(RETRY_AUTHORING_CONTRACT))
	if not author_value is Dictionary or author_value.get("asset_pack") != "luoyang_gate_fortification_v2_a_retry1" or author_value.get("status") != "SOURCE_AUTHORED_CAPTURE_PENDING":
		_fail_now("Exact pending retry1 source contract is required.")
		return
	authoring_contract = author_value

	if not _bound(SOURCE_MESH) or not _bound(SOURCE_META) or not _bound(ROCK_SOURCE):
		_fail_now(error)
		return
	for texture_path: String in [ROCK_DIFFUSE,ROCK_NORMAL,ROCK_ARM,GATE_TEXTURE]:
		if not _track_imported_texture(texture_path):
			_fail_now(error)
			return
	var meta_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_META))
	if not meta_value is Dictionary or not _validate_source_metadata(meta_value):
		_fail_now(error if error != "" else "Frozen native wall source metadata mismatch.")
		return
	var v1_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(V1_RESULT))
	if not v1_value is Dictionary or not _validate_actual_v1_baseline(v1_value):
		_fail_now(error if error != "" else "Pinned actual v1 straight-wall baseline mismatch.")
		return

	var stone_material: ShaderMaterial = _make_ashlar_material(Color(0.62,0.63,0.62),0.13,0.20,0.78)
	var mortar_material: ShaderMaterial = _make_ashlar_material(Color(0.31,0.32,0.32),0.055,0.08,0.88)
	if stone_material == null or mortar_material == null:
		_fail_now(error if error != "" else "Could not build inherited ashlar materials.")
		return
	var wall: ArrayMesh = _build_light_ashlar_wall(stone_material,mortar_material)
	if wall == null or error != "" or not _validate_retry_support_geometry(wall):
		_fail_now(error if error != "" else "Retry1 support geometry build failed.")
		return
	var wall_measure: Dictionary = _measure(wall)
	if wall_measure.is_empty() or not _measure_matches_source_bounds(wall_measure):
		_fail_now(error if error != "" else "Retry1 mesh does not match actual v1 draw bounds.")
		return
	geometry["wall"] = wall_measure

	var wall_capture: Dictionary = await _capture(wall,"light_ashlar_wall_v2_a_retry1")
	if wall_capture.is_empty():
		await _finish(false,run_tag,bridge)
		return
	geometry["wall_capture"] = wall_capture
	var wall_size := Vector2i(wall_capture.crop_size_px[0],wall_capture.crop_size_px[1])
	print(JSON.stringify({"event":"gate_light_ashlar_v2_a_retry1_capture_measurement","crop_size_px":wall_capture.crop_size_px,"foot_uv":wall_capture.foot_uv,"foot_anchor_px":wall_capture.foot_anchor_px}))
	if wall_size.x < 650 or wall_size.x > 662 or wall_size.y < 274 or wall_size.y > 288:
		error = "Retry1 actual crop falls outside the unchanged narrow 650..662 by 274..288 range; do not widen the gate."
		await _finish(false,run_tag,bridge)
		return
	var geometry_value: Variant = v1_value.get("geometry_and_capture",{})
	var v1_capture: Dictionary = geometry_value.get("straight_capture",{})
	if not _foot_is_preserved(wall_capture,v1_capture):
		error = "Retry1 actual foot anchor still exceeds the unchanged <=3 px v1 guard."
		await _finish(false,run_tag,bridge)
		return

	var wall_image: Image = wall_capture["_verified_image"]
	var comparison: Dictionary = await _compose_gate_comparison(wall_image,wall_capture)
	if comparison.is_empty():
		await _finish(false,run_tag,bridge)
		return
	comparison_record = comparison
	var comparison_image: Image = comparison["_verified_image"]
	wall_capture.erase("_verified_image")
	comparison_record.erase("_verified_image")
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RETRY_OUTPUT_ROOT)) != OK:
		error = "Cannot create the isolated retry1 candidate directory."
		await _finish(false,run_tag,bridge)
		return
	if not _save_mesh(RETRY_OUTPUTS.wall_mesh,wall,"Retry1 A-only: same six-course/chamfer/eleven-merlon art; draw Z ±0.3612500131 and separate minimum-Y support x±2.46/z±0.34375 from actual v1"):
		await _finish(false,run_tag,bridge)
		return
	if not _save_png(RETRY_OUTPUTS.wall_png,wall_image) or not _save_png(RETRY_OUTPUTS.comparison_png,comparison_image):
		await _finish(false,run_tag,bridge)
		return
	await _finish(true,run_tag,bridge)


func _validate_actual_v1_baseline(v1: Dictionary) -> bool:
	if v1.get("passed_capture_checks",false) != true:
		error = "Pinned v1 result is not a passed actual capture."
		return false
	var geometry_value: Variant = v1.get("geometry_and_capture",{})
	if not geometry_value is Dictionary:
		error = "Pinned v1 result has no geometry_and_capture dictionary."
		return false
	var straight_value: Variant = geometry_value.get("straight",{})
	var capture_value: Variant = geometry_value.get("straight_capture",{})
	if not straight_value is Dictionary or not capture_value is Dictionary:
		error = "Pinned v1 result has no actual straight mesh/capture records."
		return false
	var minimum: Vector3 = _array_v3(straight_value.get("minimum_m",[]))
	var maximum: Vector3 = _array_v3(straight_value.get("maximum_m",[]))
	var foot: Variant = capture_value.get("foot_anchor_px",[])
	var crop: Variant = capture_value.get("crop_size_px",[])
	if not _v3_near(minimum,RETRY_DRAW_MIN,0.000001) or not _v3_near(maximum,RETRY_DRAW_MAX,0.000001):
		error = "Pinned v1 actual straight draw bounds changed."
		return false
	if not foot is Array or foot.size() != 2 or absf(float(foot[0])-328.0) > 0.000001 or absf(float(foot[1])-272.3623046875) > 0.000001:
		error = "Pinned v1 actual foot anchor changed."
		return false
	if not crop is Array or crop.size() != 2 or int(crop[0]) != 656 or int(crop[1]) != 280:
		error = "Pinned v1 actual crop changed."
		return false
	return true


func _build_light_ashlar_wall(stone_material: ShaderMaterial, mortar_material: ShaderMaterial) -> ArrayMesh:
	var result := ArrayMesh.new()
	var mortar_boxes: Array[Dictionary] = [{"center":Vector3(0.0,0.73,-0.0105),"size":Vector3(4.976,1.34,0.675)}]
	var mortar_arrays: Array = _boxes_arrays(mortar_boxes)
	if mortar_arrays.is_empty():
		return null
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mortar_arrays)
	result.surface_set_material(0,mortar_material)
	var stones: Array[Dictionary] = []
	# The support plinth is intentionally smaller than the visible wall.  Its
	# minimum-Y hull exactly matches the v1 A draw asset, independently of full bounds.
	stones.append({"minimum":RETRY_SUPPORT_MIN,"maximum":Vector3(RETRY_SUPPORT_MAX.x,0.06,RETRY_SUPPORT_MAX.z),"bevel":0.0,"role":"measured_v1_support_plinth"})
	var body_start := 0.06
	var body_end := 1.396
	var course_step := (body_end-body_start)/6.0
	for row in range(6):
		var y0 := body_start+float(row)*course_step
		var y1 := y0+course_step-0.014
		_retry_append_staggered_course(stones,row,y0,y1,0.018)
	_retry_append_even_course(stones,10,body_end,1.49,0.012,0.015,"cap_course")
	_retry_append_even_course(stones,11,1.49,1.68,0.014,0.018,"parapet_course")
	var merlon_cell := 5.0/21.0
	for index in range(11):
		var x0 := -2.5+float(index*2)*merlon_cell
		var x1 := x0+merlon_cell
		stones.append({"minimum":Vector3(x0,1.68,RETRY_DRAW_MIN.z),"maximum":Vector3(x1,RETRY_DRAW_MAX.y,RETRY_DRAW_MAX.z),"bevel":0.022,"role":"narrow_merlon"})
	var stone_arrays: Array = _beveled_blocks_arrays(stones)
	if stone_arrays.is_empty():
		return null
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,stone_arrays)
	result.surface_set_material(1,stone_material)
	return result


func _retry_append_staggered_course(blocks: Array[Dictionary], row: int, y0: float, y1: float, bevel: float) -> void:
	var boundaries: Array[float] = []
	if row % 2 == 0:
		for index in range(9):
			boundaries.append(-2.5+float(index)*0.625)
	else:
		boundaries.append(-2.5)
		boundaries.append(-2.1875)
		for index in range(1,8):
			boundaries.append(-2.1875+float(index)*0.625)
		boundaries.append(2.5)
	_retry_append_from_boundaries(blocks,boundaries,y0,y1,0.022,bevel,"ashlar_course_%d" % row)


func _retry_append_even_course(blocks: Array[Dictionary], count: int, y0: float, y1: float, joint: float, bevel: float, role: String) -> void:
	var boundaries: Array[float] = []
	for index in range(count+1):
		boundaries.append(-2.5+5.0*float(index)/float(count))
	_retry_append_from_boundaries(blocks,boundaries,y0,y1,joint,bevel,role)


func _retry_append_from_boundaries(blocks: Array[Dictionary], boundaries: Array[float], y0: float, y1: float, joint: float, bevel: float, role: String) -> void:
	for index in range(boundaries.size()-1):
		var x0: float = boundaries[index] if index == 0 else boundaries[index]+joint*0.5
		var x1: float = boundaries[index+1] if index == boundaries.size()-2 else boundaries[index+1]-joint*0.5
		blocks.append({"minimum":Vector3(x0,y0,RETRY_DRAW_MIN.z),"maximum":Vector3(x1,y1,RETRY_DRAW_MAX.z),"bevel":bevel,"role":role})


func _validate_retry_support_geometry(mesh: ArrayMesh) -> bool:
	var low := INF
	var used: Array[Vector3] = []
	for surface in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for index: int in indices:
			low = minf(low,vertices[index].y)
			used.append(vertices[index])
	var support_min := Vector3(INF,INF,INF)
	var support_max := Vector3(-INF,-INF,-INF)
	var count := 0
	for point: Vector3 in used:
		if point.y <= low+0.000001:
			support_min = support_min.min(point)
			support_max = support_max.max(point)
			count += 1
	if count < 3 or not _v3_near(support_min,RETRY_SUPPORT_MIN,0.000001) or not _v3_near(support_max,RETRY_SUPPORT_MAX,0.000001):
		error = "Retry1 minimum-Y support does not match actual v1 x±2.46/z±0.34375."
		return false
	geometry["minimum_y_support_bounds_m"] = {"minimum":_v3(support_min),"maximum":_v3(support_max),"used_index_visits":count,"separate_from_full_draw_bounds":true}
	return true


func _measure_matches_source_bounds(measure: Dictionary) -> bool:
	var minimum: Vector3 = _array_v3(measure.get("minimum_m",[]))
	var maximum: Vector3 = _array_v3(measure.get("maximum_m",[]))
	if not minimum.is_finite() or not maximum.is_finite() or not _v3_near(minimum,RETRY_DRAW_MIN,0.000001) or not _v3_near(maximum,RETRY_DRAW_MAX,0.000001):
		error = "Retry1 measured bounds differ from the pinned actual v1 A draw bounds."
		return false
	if measure.get("surface_count",0) != 2 or measure.get("triangles",0) < 1000:
		error = "Retry1 lost the independent mortar/stone surfaces or bevel topology."
		return false
	return true


func _save_mesh(path: String, mesh: ArrayMesh, revision: String) -> bool:
	if not path.begins_with(RETRY_OUTPUT_ROOT) or FileAccess.file_exists(path) or ResourceSaver.save(mesh,path) != OK:
		error = "Own NEW retry1 mesh save/overwrite refused: " + path
		return false
	var reloaded: ArrayMesh = ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var readback: Dictionary = _measure(reloaded) if reloaded != null else {}
	if readback.is_empty() or not _measure_matches_source_bounds(readback) or not _validate_retry_support_geometry(reloaded):
		error = "Saved retry1 mesh failed strict draw/support readback."
		return false
	var dependencies: Array[String] = []
	for dependency: String in ResourceLoader.get_dependencies(path):
		for part: String in dependency.split("::"):
			if part.begins_with("res://") and part not in dependencies:
				dependencies.append(part)
	for required: String in [ROCK_DIFFUSE,ROCK_NORMAL,ROCK_ARM]:
		if required not in dependencies:
			error = "Saved retry1 mesh lost registered microdetail dependency: " + required
			return false
	outputs[path] = {"sha256":FileAccess.get_sha256(path),"bytes":FileAccess.get_file_as_bytes(path).size(),"revision":revision,"strict_mesh_and_support_readback":true,"resource_dependencies":dependencies}
	return true


func _save_png(path: String, image: Image) -> bool:
	if not path.begins_with(RETRY_OUTPUT_ROOT) or FileAccess.file_exists(path) or image.save_png(path) != OK:
		error = "Own NEW retry1 PNG save/overwrite refused: " + path
		return false
	var readback: Image = Image.load_from_file(path)
	if readback == null:
		error = "Retry1 PNG readback failed for " + path
		return false
	readback.convert(Image.FORMAT_RGBA8)
	if readback.get_size() != image.get_size() or readback.get_data() != image.get_data():
		error = "Retry1 PNG readback differs for " + path
		return false
	outputs[path] = {"sha256":FileAccess.get_sha256(path),"bytes":FileAccess.get_file_as_bytes(path).size(),"rgba_sha256":_hash(image.get_data()),"size_px":[image.get_width(),image.get_height()],"lossless_readback_exact":true}
	return true


func _retry_consumer_entry(capture: Dictionary) -> Dictionary:
	return {"asset_id":"luoyang_gate_wall_light_ashlar_straight_v2_a_retry1","mesh_path":RETRY_OUTPUTS.wall_mesh,"mesh_sha256":outputs[RETRY_OUTPUTS.wall_mesh]["sha256"],"texture_path":RETRY_OUTPUTS.wall_png,"texture_sha256":outputs[RETRY_OUTPUTS.wall_png]["sha256"],"texture_bytes":outputs[RETRY_OUTPUTS.wall_png]["bytes"],"render_size_px":capture.crop_size_px,"foot_uv":capture.foot_uv,"foot_anchor_px":capture.foot_anchor_px,"support_polygon_px":capture.actual_min_y_support_polygon_px,"ground_y_definition":"For candidate ground_y=500, place texture top-left at [world_x-foot_anchor_px.x,500-foot_anchor_px.y]; translate support_polygon_px by the same top-left. Art placement only; not collision/Field approval.","source_catalog_key":"source_catalog.sha256_by_res_path"}


func _finish(passed: bool, run_tag: String, bridge: Node) -> void:
	if viewport != null:
		viewport.queue_free()
		viewport = null
	for frame in range(4):
		await process_frame
	var inputs_last: Dictionary = {}
	var input_changes: Array[String] = []
	for path: String in inputs_first:
		inputs_last[path] = FileAccess.get_sha256(path).to_lower()
		if inputs_last[path] != inputs_first[path]:
			input_changes.append(path)
	if not input_changes.is_empty():
		passed = false
		error = "Read-only source input changed during retry1 capture."
	if bridge == null or bridge.call("is_checkpoint_saves_suspended") != true:
		passed = false
		error = "Checkpoint suspension did not remain active through retry1 capture."
	if bridge != null and bridge.has_method("set_checkpoint_saves_suspended"):
		bridge.call("set_checkpoint_saves_suspended",false)
	checkpoint_guard["restored_before_quit"] = bridge != null and bridge.call("is_checkpoint_saves_suspended") == false
	if checkpoint_guard["restored_before_quit"] != true:
		passed = false
		error = "Checkpoint suspension was not restored before quit."
	var consumer_catalog := {}
	if passed:
		consumer_catalog = {"schema_version":1,"ground_y_reference_world_px":500,"ground_y_definition":"ground_y is the world-space Y assigned to the captured front-centre minimum-mesh-Y foot anchor; not PNG bottom/collision.","source_catalog":{"sha256_by_res_path":inputs_first,"last_readback_sha256_by_res_path":inputs_last,"unchanged":input_changes.is_empty()},"wall":_retry_consumer_entry(geometry["wall_capture"])}
	var report := {
		"status":"A_ONLY_RETRY1_NATIVE_CANDIDATE_CAPTURED_NOT_FIELD_OR_FORMAL" if passed else "A_ONLY_RETRY1_CAPTURE_FAILED_NOT_ADOPTED",
		"passed_capture_checks":passed,
		"reason":error,
		"scope":"ONLY ONE RETRY1 LIGHT-GREY ASHLAR WALL A; NO tower B, runtime publisher, city layout, Field, Physics, portal, bridge, water, NPC, save, audio or formal write",
		"run_tag":run_tag,
		"source_contract":authoring_contract,
		"root01_failure_preserved":{"script_sha256":PARENT_CAPTURE_SCRIPT_SHA,"contract_sha256":PARENT_CONTRACT_SHA,"actual_crop_px":[656,285],"actual_foot_anchor_px":[328.0,277.4111328125],"v1_foot_anchor_px":[328.0,272.3623046875],"guard_px_unchanged":3.0},
		"geometry_revision":{"actual_v1_draw_bounds_m":{"minimum":_v3(RETRY_DRAW_MIN),"maximum":_v3(RETRY_DRAW_MAX)},"actual_v1_minimum_y_support_bounds_m":{"minimum":_v3(RETRY_SUPPORT_MIN),"maximum":_v3(RETRY_SUPPORT_MAX)},"full_removed_tilecap_source_bounds_not_claimed":true,"six_courses_chamfers_material_eleven_merlons_unchanged":true},
		"inputs_sha256_first":inputs_first,
		"inputs_sha256_last":inputs_last,
		"input_changes":input_changes,
		"outputs":outputs,
		"geometry_and_capture":geometry,
		"offline_comparison":comparison_record,
		"consumer_catalog":consumer_catalog,
		"visual_review":"PENDING_ROOT_ACTUAL_GPU_READBACK",
		"field_or_physics_approved":false,
		"production_or_formal_approved":false,
		"checkpoint_guard":checkpoint_guard,
	}
	if passed:
		var report_file := FileAccess.open(RETRY_OUTPUTS.result,FileAccess.WRITE)
		if report_file == null:
			passed = false
			error = "Could not create final retry1 result."
		else:
			report_file.store_string(JSON.stringify(report,"\t")+"\n")
			report_file.close()
			outputs[RETRY_OUTPUTS.result] = {"sha256":FileAccess.get_sha256(RETRY_OUTPUTS.result),"bytes":FileAccess.get_file_as_bytes(RETRY_OUTPUTS.result).size()}
	if not passed:
		push_error(error)
	quit(0 if passed else 1)
