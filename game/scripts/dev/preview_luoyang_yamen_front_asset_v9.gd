extends "res://scripts/dev/preview_luoyang_yamen_front_line_v8.gd"

## Reuse safe renderer helpers only. V8 is rebuilt as current GPU baseline;
## NEW view contains NO V8 native wings and NO original old-front-wall carrier.
const PLATE := preload("res://scripts/dev/luoyang_yamen_front_asset_v9_preview.gd")
const V9_ROOT := "res://build/luoyang_yamen_front_asset_v9_preview/"
const V8_HELPER_SHA := "b543b0d577b6d42b701942678838296dd0fad5e169eac0e0a78cf8fe9e27894f"
const V8_RUNNER_SHA := "efc537c4372e65ddc1000cd07c030f1262b67cbbb682c3638dea4209ea4caa26"
const PROVENANCE_SHA := "79ee2e0c13ccebe1e41a5d7adf2d6fe67328e5febd5b571edfa7357ac620721f"
const BODY_RECT := Rect2i(896,1280,1280,520)
const ASSET_VIEWS := {
	"full":{"rect":Rect2i(656,1120,1760,720),"zoom":1},
	"left_1x":{"rect":Rect2i(1120,1430,480,320),"zoom":1},
	"left_2x":{"rect":Rect2i(1120,1430,480,320),"zoom":2},
	"right_1x":{"rect":Rect2i(1510,1430,480,320),"zoom":1},
	"right_2x":{"rect":Rect2i(1510,1430,480,320),"zoom":2}
}
var plate: PLATE

func _start() -> void:
	# FIRST deferred action after autoload ready, before ANY await or asset work.
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		push_error("V9 requires public checkpoint suspension; no fallback.")
		quit(2)
		return
	bridge.call("set_checkpoint_saves_suspended",true)
	var suspended: Variant = bridge.call("is_checkpoint_saves_suspended")
	if not suspended is bool or not suspended:
		push_error("V9 checkpoint suspension not verified.")
		quit(2)
		return
	checkpoint_guard = {"public_api":"PlatformBridge.set_checkpoint_saves_suspended(true)","before_first_await":true,"actual_verified_suspended":true,"restore_before_quit":false}
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var tag := ""
	for arg: String in args:
		if arg.begins_with("--preview-run-tag="): tag = arg.trim_prefix("--preview-run-tag=")
	var rule := RegEx.new()
	if "--luoyang-yamen-front-asset-v9-preview" not in args or rule.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$") != OK or rule.search(tag) == null or DisplayServer.get_name() == "headless":
		push_error("Explicit V9 GPU flag and safe fresh tag required.")
		quit(2)
		return
	output = V9_ROOT+tag+"/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)):
		push_error("Refusing overwrite of earlier V9 evidence.")
		quit(2)
		return
	var bridge_script: Script = bridge.get_script() as Script
	if bridge_script == null or not _track(bridge_script.resource_path):
		quit(2)
		return
	var pins: Dictionary = {
		"res://scripts/dev/luoyang_yamen_front_line_v8_preview.gd":V8_HELPER_SHA,
		"res://scripts/dev/preview_luoyang_yamen_front_line_v8.gd":V8_RUNNER_SHA,
		"res://scripts/dev/luoyang_yamen_gate_join_native_v7_preview.gd":FRONT.V7_PIN,
		"res://scripts/dev/preview_luoyang_yamen_gate_join_native_v7.gd":V7_RUNNER_PIN,
		PLATE.repo_path(PLATE.WALL_REL):PLATE.WALL_SHA,
		PLATE.GATE_PATH:PLATE.GATE_SHA,
		PLATE.repo_path("assets/raw/scene_module/luoyang_yamen_front_v9/generation_record.json"):PROVENANCE_SHA,
		PLATE.repo_path("prompts/templates/luoyang_yamen_front_wall_v9.yaml"):"e7e98c7b93ca14c615c7423e947ef8931db2dbe3b175919a153913276273349c",
		PLATE.repo_path("game/build/luoyang_yamen_front_line_v8_preview/root_front_line_v8_01/full_new.png"):"ec73a548da55645ff62af8b78c475b5a748f58a09dbc4472cb789c0dda641173"
	}
	for path: String in pins:
		if not _track(path,String(pins[path])):
			push_error(error)
			quit(2)
			return
	for path: String in [get_script().resource_path,"res://scripts/dev/luoyang_yamen_front_asset_v9_preview.gd",PLATE.repo_path("assets/raw/scene_module/luoyang_yamen_front_v9/offline_call_plan.json")]:
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
		push_error("Cannot create unique V9 output.")
		quit(2)
		return
	front_asset = FRONT.new()
	asset = front_asset # Ground/environment and baseline only, NOT new walls.
	plate = PLATE.new()
	if not asset.prepare() or not plate.prepare():
		error = asset.error if asset.error != "" else plate.error
		await _finish(false)
		return
	front_texture = plate.gate_texture
	for id: String in WINGS:
		new_meshes[id] = front_asset.build(WINGS[id]) # CURRENT V8 baseline only.
		if new_meshes[id] == null or asset.error != "" or _measure(new_meshes[id]).is_empty():
			error = "V8 baseline build/measurement failed: "+asset.error+error
			await _finish(false)
			return
	var record: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLATE.repo_path("assets/raw/scene_module/luoyang_yamen_front_v9/generation_record.json")))
	var dimensions: Variant = record.get("actual_dimensions_px") if record is Dictionary else null
	var dimensions_match: bool = _provenance_dimensions_match(dimensions)
	if not record is Dictionary or record.get("sha256") != PLATE.WALL_SHA or not dimensions_match:
		error = "Actual generated provenance does not bind the consumed image. dimensions="+str(dimensions)+" typeof="+str(observations["provenance_dimensions_check"])
		await _finish(false)
		return
	observations["asset_provenance"] = record
	observations["scope"] = {"asset_type":"Actual GPU baked 2.5D carriers, NOT native/PBR", "baseline":"V8 geometry rebuilt/current GPU capture; old PNG read only as reference SHA, never reused as capture", "new":"One uniform-scale wall plate replaces BOTH old front walls and wings; original central gate-only UV carrier; no old native/old-wall double draw", "uniform_xy_scale":PLATE.UNIFORM_SCALE,"new_wall_height_changed":true,"old_height_preserved":false,"collision_navigation_Field_production_credit":false,"gate_outline":"Manually traced UV outline; full source pixels unchanged; actual gate-only probes and PNG review required"}
	if not await _plate_body():
		await _finish(false)
		return
	for name: String in ASSET_VIEWS:
		if not await _asset_view(name):
			await _finish(false)
			return
	await _finish(true)

func _provenance_dimensions_match(value: Variant) -> bool:
	# JSON numeric arrays need not share the literal Array's element types.
	# Validate the number contract before conversion; strings/bools/NIL and
	# nonfinite/fractional numbers must not become accepted dimensions.
	var expected: Vector2i = plate.wall_image.get_size()
	var diagnostic: Dictionary = {"actual_value":str(value),"container_type":type_string(typeof(value)),"element_types":[],"expected_actual_image_px":[expected.x,expected.y],"accepted":false}
	observations["provenance_dimensions_check"] = diagnostic
	if not value is Array or value.size() != 2: return false
	for item: Variant in value:
		diagnostic["element_types"].append(type_string(typeof(item)))
	for i in range(2):
		var item: Variant = value[i]
		if typeof(item) != TYPE_INT and typeof(item) != TYPE_FLOAT:
			diagnostic["rejected_dimension"] = i
			return false
		var number: float = float(item)
		if not is_finite(number) or number != floor(number) or number != float(expected[i]):
			diagnostic["rejected_dimension"] = i
			return false
	diagnostic["accepted"] = true
	return true

func _node_geometry(node: Polygon2D,rect: Rect2i,zoom: int) -> Dictionary:
	var used: Array = []
	var uv: Array = []
	for i in range(node.polygon.size()):
		var actual: Vector2 = node.get_global_transform()*node.polygon[i]
		var world_px: Vector2 = actual/(2.*float(zoom))+Vector2(rect.position)
		used.append([world_px.x,world_px.y])
		uv.append([node.uv[i].x,node.uv[i].y])
	return {"node":String(node.name),"actual_transformed_vertices_global_logical_px":used,"actual_texture_uv_px":uv,"scale": [node.scale.x,node.scale.y],"source_scope":"Actual Polygon2D vertices/transform readback, not native geometry/camera/physical support"}

func _plate_body() -> bool:
	view = _viewport(BODY_RECT.size*2,true)
	var group := Node2D.new()
	view.add_child(group)
	var gate_node: Polygon2D = plate.gate(group,BODY_RECT,1)
	await _sync()
	var gate_raw: Image = await _repeat("V9 original gate-only UV")
	if gate_raw == null: return false
	var probes: Array = []
	for point: Vector2i in PLATE.KEEP_PROBES+PLATE.EXCLUDE_PROBES+PLATE.HOLE_PROBES:
		var pixel := Vector2i((PLATE.GATE_ORIGIN-Vector2(BODY_RECT.position))*2.)+point
		var expected: float = plate.gate_image.get_pixelv(point).a if point in PLATE.KEEP_PROBES else 0.
		var actual: float = gate_raw.get_pixelv(pixel).a
		probes.append({"source_px":[point.x,point.y],"source_alpha":plate.gate_image.get_pixelv(point).a,"actual_gate_only_gpu_alpha":actual,"expected_selected_alpha":expected,"excluded_old_wall":point in PLATE.EXCLUDE_PROBES})
		if absf(actual-expected) > 1./255.:
			error = "Actual gate-only carrier changed a keep probe or retained old wall/hole."
			return false
	observations["gate_only_source_probes"] = probes
	if not _png(output+"gate_only_raw.png",gate_raw) or not _png(output+"gate_only_body.png",_alpha_resize(gate_raw,BODY_RECT.size)): return false
	var wall_nodes: Array[Polygon2D] = plate.walls(group,BODY_RECT,1)
	var geometry: Array = [_node_geometry(gate_node,BODY_RECT,1)]
	for node: Polygon2D in wall_nodes: geometry.append(_node_geometry(node,BODY_RECT,1))
	observations["actual_gpu_carrier_geometry"] = geometry
	await _sync()
	var raw: Image = await _repeat("V9 unified wall + unchanged central gate")
	if raw == null: return false
	for point: Vector2i in PLATE.HOLE_PROBES:
		var pixel := Vector2i((PLATE.GATE_ORIGIN-Vector2(BODY_RECT.position))*2.)+point
		if raw.get_pixelv(pixel).a != 0.:
			error = "NEW unified wall drew into original door aperture."
			return false
	var image: Image = _alpha_resize(raw,BODY_RECT.size)
	var used: Rect2i = image.get_used_rect()
	if used.size.x < 16 or used.size.y < 16 or used.position.x < 24 or used.position.y < 24 or used.end.x > image.get_width()-24 or used.end.y > image.get_height()-24:
		error = "NEW actual carrier alpha empty/clipped; no old-alpha forcing."
		return false
	var crop := Rect2i(used.position-Vector2i(8,8),used.size+Vector2i(16,16))
	var histogram: Array[int] = []
	histogram.resize(256)
	histogram.fill(0)
	var row_counts: Array[int] = []
	row_counts.resize(image.get_height())
	row_counts.fill(0)
	var data: PackedByteArray = image.get_data()
	for i in range(3,data.size(),4):
		histogram[data[i]] += 1
		if data[i] > 0: row_counts[int(int(i/4)/image.get_width())] += 1
	var remaining: int = int(ceil((image.get_width()*image.get_height()-histogram[0])*.02))
	var support_sum := Vector2.ZERO
	var support_count := 0
	for y in range(image.get_height()-1,-1,-1):
		if remaining <= 0: break
		for x in range(image.get_width()):
			if remaining <= 0: break
			if image.get_pixel(x,y).a > 0.:
				support_sum += Vector2(x+.5,y+.5)
				support_count += 1
				remaining -= 1
	var support: Vector2 = support_sum/float(maxi(support_count,1))
	observations["actual_combined_alpha_crop"] = {"raw_px":[raw.get_width(),raw.get_height()],"logical_px":[image.get_width(),image.get_height()],"new_used_rect_px":[used.position.x,used.position.y,used.size.x,used.size.y],"new_crop_rect_px":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"alpha_histogram":histogram,"nonzero_alpha_rows":row_counts,"screen_support_lowest2pct_px":[support.x,support.y],"crop_support_uv":[(support.x-crop.position.x)/crop.size.x,(support.y-crop.position.y)/crop.size.y],"support_scope":"Actual nonzero-alpha bottom 2% pixel aggregate ONLY; not physical feet, native geometry or production support", "old_alpha_forced":false,"raw_repeat_byte_exact":true,"visual_alpha_crop_review":"PENDING"}
	if not _png(output+"front_asset_raw.png",raw) or not _png(output+"front_asset_body.png",image.get_region(crop)): return false
	view.queue_free()
	view = null
	await _sync()
	return true

func _asset_view(name: String) -> bool:
	var spec: Dictionary = ASSET_VIEWS[name]
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
	if support.mesh == null or paving.mesh == null or paving.material_override == null:
		error = "Frozen support/paving unavailable."
		return false
	world.add_child(paving)
	var baseline_nodes: Array[MeshInstance3D] = []
	for id: String in WINGS:
		var node := MeshInstance3D.new()
		node.mesh = new_meshes[id]
		node.transform = front_asset.placement(WINGS[id])
		world.add_child(node)
		baseline_nodes.append(node)
	var camera: Camera3D = _camera(world,logical,_point(Vector2(rect.position)+Vector2(rect.size)*.5),float(zoom))
	var origin: Vector2 = (FRONT.FRONT_ORIGIN-Vector2(rect.position))*float(zoom)*2.
	var baseline_carrier: Polygon2D = _carrier(view,origin,float(zoom),true)
	await _sync()
	var before: Image = await _repeat(name+" CURRENT V8 baseline")
	if before == null: return false
	baseline_carrier.free()
	for node: MeshInstance3D in baseline_nodes:
		node.visible = false
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var group := Node2D.new()
	view.add_child(group)
	plate.walls(group,rect,zoom)
	plate.gate(group,rect,zoom)
	cameras[name] = {"source_rect_px":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"zoom":zoom,"logical_px":[logical.x,logical.y],"raw_px":[view.size.x,view.size.y],"camera_position_m":_v3(camera.position),"camera_basis":[_v3(camera.basis.x),_v3(camera.basis.y),_v3(camera.basis.z)],"orthographic_size_m":camera.size,"msaa":0,"baseline_current_gpu":true,"new_native_wing_draws":0,"old_front_wall_carriers":0,"new_carriers":3,"2x_scope":"GPU inspection magnification, NOT native 2x/3x asset density", "scope":"2.5D straight-front wall only; height changed uniformly; no complete courtyard/Field/collision credit"}
	await _sync()
	var after: Image = await _repeat(name+" NEW V9 carrier")
	if after == null: return false
	before.resize(logical.x,logical.y,Image.INTERPOLATE_LANCZOS)
	after.resize(logical.x,logical.y,Image.INTERPOLATE_LANCZOS)
	if not _png(output+name+"_baseline_v8.png",before) or not _png(output+name+"_new.png",after): return false
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
	if plate != null: plate.release()
	plate = null
	if asset != null: asset.release()
	asset = null
	front_asset = null
	for frame in range(16): await process_frame
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or bridge.call("is_checkpoint_saves_suspended") != true:
		passed = false
		error = "Checkpoint suspension did not remain active through quit."
	var changes: Array[String] = []
	var final_inputs: Dictionary = {}
	for path: String in inputs:
		final_inputs[path] = FileAccess.get_sha256(path).to_lower()
		if final_inputs[path] != inputs[path]: changes.append(path)
	if not changes.is_empty():
		passed = false
		error = "Read-only V9 inputs changed during capture."
	var report: Dictionary = {"status":"PREVIEW_NOT_ADOPTED" if passed else "PREVIEW_FAILED_NOT_ADOPTED","passed_capture_checks":passed,"reason":error,"scope":"UNIFIED BAKED 2.5D FRONT WALL + ORIGINAL CENTRAL GATE UV; NOT native/PBR/Field/collision/navigation/audio/release approval","checkpoint_guard":checkpoint_guard,"inputs_sha256_first":inputs,"inputs_sha256_last":final_inputs,"input_changes":changes,"outputs":outputs,"geometry_and_alpha":observations,"cameras":cameras,"independent_visual_alpha_crop_review":"PENDING","visual_approved":false,"production_approved":false,"audio_credit":"NONE; outer stderr review required, no clean-exit claim"}
	var file: FileAccess = null
	if output != "" and not FileAccess.file_exists(output+"preview_result.json"):
		file = FileAccess.open(output+"preview_result.json",FileAccess.WRITE)
	if file == null:
		passed = false
		error = "Own V9 result save/overwrite refused."
	else:
		file.store_string(JSON.stringify(report,"\t"))
		file.close()
	if not passed: push_error(error)
	quit(0 if passed else 1)
