extends "res://scripts/dev/preview_luoyang_yamen_gate_join_native_v7.gd"

## Reuse only the safe standalone V7 renderer/measurement helpers. Override
## its entry and adjacency: both old and new are CURRENT actual GPU captures.
## Never invoke a publisher, _prototype/_run, Field, routes or save fixtures.
const FRONT := preload("res://scripts/dev/luoyang_yamen_front_line_v8_preview.gd")
const OLD := preload("res://scripts/dev/luoyang_yamen_gate_join_native_v7_preview.gd")
const V8_ROOT := "res://build/luoyang_yamen_front_line_v8_preview/"
const V7_RUNNER_PIN := "a6c885d2f377a38148e5b0c5f004e7145928609eb1f8b26a6e0237ffbdfa973b"
const V8_VIEWS := {
	"full":{"rect":Rect2i(656,1120,1760,720),"zoom":1},
	"left_1x":{"rect":Rect2i(1000,1460,420,300),"zoom":1},
	"left_2x":{"rect":Rect2i(1000,1460,420,300),"zoom":2},
	"right_1x":{"rect":Rect2i(1660,1460,420,300),"zoom":1},
	"right_2x":{"rect":Rect2i(1660,1460,420,300),"zoom":2}
}
var old_asset: OLD
var front_asset: FRONT
var old_meshes: Dictionary = {}
var front_texture: ImageTexture

func _start() -> void:
	# FIRST deferred action after autoload ready, before ANY await/asset work.
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		push_error("V8 preview requires public checkpoint suspension; no fallback.")
		quit(2)
		return
	bridge.call("set_checkpoint_saves_suspended",true)
	var suspended: Variant = bridge.call("is_checkpoint_saves_suspended")
	if not suspended is bool or not suspended:
		push_error("Public checkpoint suspension was not verified.")
		quit(2)
		return
	checkpoint_guard = {"public_api":"PlatformBridge.set_checkpoint_saves_suspended(true)","before_first_await":true,"actual_verified_suspended":true,"restore_before_quit":false}
	var bridge_script: Script = bridge.get_script() as Script
	if bridge_script == null or not _track(bridge_script.resource_path):
		quit(2)
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var tag := ""
	for arg: String in args:
		if arg.begins_with("--preview-run-tag="): tag = arg.trim_prefix("--preview-run-tag=")
	var rule := RegEx.new()
	if "--luoyang-yamen-front-line-v8-preview" not in args or rule.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$") != OK or rule.search(tag) == null or DisplayServer.get_name() == "headless":
		push_error("Explicit V8 GPU flag and fresh safe tag required; headless refused.")
		quit(2)
		return
	output = V8_ROOT+tag+"/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)):
		push_error("Refusing overwrite of any earlier V8 preview.")
		quit(2)
		return
	for path: String in [get_script().resource_path,"res://scripts/dev/luoyang_yamen_front_line_v8_preview.gd"]:
		if not _track(path):
			quit(2)
			return
	if not _track("res://scripts/dev/preview_luoyang_yamen_gate_join_native_v7.gd",V7_RUNNER_PIN) or not _track("res://scripts/dev/luoyang_yamen_gate_join_native_v7_preview.gd",FRONT.V7_PIN):
		quit(2)
		return
	for path: String in OLD.SOURCE_PINS:
		if not _track(path,OLD.SOURCE_PINS[path]):
			quit(2)
			return
	if not _track(INPUT_ROOT+"art_contract.json",MANIFEST_SHA):
		quit(2)
		return
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(INPUT_ROOT+"art_contract.json"))
	if not decoded is Dictionary or decoded.get("scene_id") != "ch4_s1_luoyang_yamen":
		push_error("Exact frozen yamen manifest required.")
		quit(2)
		return
	manifest = decoded
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) != OK:
		push_error("Cannot create independent V8 output.")
		quit(2)
		return
	front_asset = FRONT.new()
	asset = front_asset
	old_asset = OLD.new()
	if not asset.prepare() or not old_asset.prepare():
		error = asset.error if asset.error != "" else old_asset.error
		await _finish(false)
		return
	var gate_object: Dictionary = _object("south_court_gate")
	if gate_object.is_empty() or not _bound(gate_object["texture"]):
		await _finish(false)
		return
	var gate: Image = Image.load_from_file(gate_object["texture"])
	if gate == null or gate.get_size() != Vector2i(1942,809):
		error = "Unmodified original gate texture unavailable."
		await _finish(false)
		return
	gate.convert(Image.FORMAT_RGBA8)
	front_texture = ImageTexture.create_from_image(gate)
	var domain := PackedVector2Array(FRONT.FRONT_UV_POINTS)
	if Geometry2D.triangulate_polygon(domain).is_empty():
		error = "Explicit front-only UV domain cannot triangulate."
		await _finish(false)
		return
	var points: Array = []
	for p: Vector2 in domain: points.append([p.x,p.y])
	observations["v8_front_domain"] = {"source_uv_pixels":points,"source_texture_sha256":OLD.SOURCE_PINS[OLD.GATE_SOURCE],"original_origin_px":[FRONT.FRONT_ORIGIN.x,FRONT.FRONT_ORIGIN.y],"original_scale":FRONT.FRONT_SCALE,"selection":"T-shaped direct GPU Polygon2D source UV; front wall cuts INSIDE x260/x1680, only central roof extends above y340; no original return-wall UV, no CPU crop/blend/cover","native_gate":false,"scope":"BAKED FRONT CARRIER + TWO STRAIGHT NATIVE WINGS ONLY; NOT complete enclosure/Field/collision/production","source_landmark_y_px":{"brick_foot":684,"wall_top":450,"eave":436,"ridge":355},"landmark_semantics":"Manually read original front features; native USED-VERTEX projection compared during actual capture, not an independent collision proof","known_roof_material":"Frozen V7 grey/blur limitation intentionally retained; NO new material/noise/colour iteration"}
	for id: String in WINGS:
		var side: String = WINGS[id]
		old_meshes[id] = old_asset.build(side)
		new_meshes[id] = asset.build(side)
		if old_meshes[id] == null or new_meshes[id] == null or asset.error != "" or old_asset.error != "":
			error = "V8/V7 wall build failed: "+asset.error+old_asset.error
			await _finish(false)
			return
		var measured: Dictionary = _measure(new_meshes[id])
		var old_measured: Dictionary = _measure(old_meshes[id])
		if measured.is_empty() or old_measured.is_empty():
			await _finish(false)
			return
		var transform: Transform3D = front_asset.placement(side)
		var box: AABB = transform*new_meshes[id].get_aabb()
		var min_px: float = box.position.x*64.+1536.
		var max_px: float = box.end.x*64.+1536.
		if measured["minimum"][1] < -.00001 or (side == "left" and max_px >= 1360.) or (side == "right" and min_px <= 1712.):
			error = "Actual V8 wing invades the central avenue/ground."
			await _finish(false)
			return
		observations[id] = {"new_geometry":measured,"current_gpu_baseline_v7_geometry":old_measured,"parts":asset.counts.duplicate(true),"new_transform":{"origin":_v3(transform.origin),"basis_columns":[_v3(transform.basis.x),_v3(transform.basis.y),_v3(transform.basis.z)]},"original_v7_transform":_object(id)["native_transform"],"actual_world_x_bounds_px":[min_px,max_px],"straight_front_base_y_px":FRONT.BASE_Y,"no_return_walls":asset.counts["return_walls"] == 0,"alpha_bounds_scope":"Fresh V8 body/crop/support/used slots; no V7 geometry approval inherited"}
		if not _save_mesh(output+side+"_native_mesh.res",new_meshes[id]) or not await _body(new_meshes[id],side):
			await _finish(false)
			return
	if not await _front_body(gate):
		await _finish(false)
		return
	for name: String in V8_VIEWS:
		if not await _v8_adjacency(name):
			await _finish(false)
			return
	await _finish(true)

func _carrier(viewport: SubViewport,origin: Vector2,scale_factor: float,front_only: bool) -> Polygon2D:
	var polygon := Polygon2D.new()
	var uv := PackedVector2Array(FRONT.FRONT_UV_POINTS) if front_only else PackedVector2Array([Vector2.ZERO,Vector2(1942,0),Vector2(1942,809),Vector2(0,809)])
	var vertices := PackedVector2Array()
	for p: Vector2 in uv: vertices.append(p*scale_factor)
	polygon.polygon = vertices
	polygon.uv = uv
	polygon.texture = front_texture
	polygon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	polygon.position = origin
	polygon.z_index = 10
	viewport.add_child(polygon)
	return polygon

func _front_body(gate: Image) -> bool:
	var logical := Vector2i(1051,485)
	view = _viewport(logical*2,true)
	_carrier(view,Vector2(80,80),1.,true)
	await _sync()
	var raw: Image = await _repeat("V8 front-only carrier alpha")
	if raw == null: return false
	var probes: Array[Dictionary] = []
	for point: Vector2i in [Vector2i(90,420),Vector2i(1850,420),Vector2i(45,500),Vector2i(1900,500),Vector2i(971,420),Vector2i(971,600),Vector2i(971,690)]:
		var actual: float = raw.get_pixelv(point+Vector2i(80,80)).a
		var original: float = gate.get_pixelv(point).a
		var excluded: bool = point.x < 260 or point.x > 1680
		probes.append({"source_px":[point.x,point.y],"original_alpha":original,"actual_gpu_alpha":actual,"excluded_return":excluded})
		if (excluded and actual != 0.) or (not excluded and absf(actual-original) > 1./255.):
			error = "Actual GPU front carrier retained a return or changed a door-hole probe."
			return false
	var image: Image = _alpha_resize(raw,logical)
	var used: Rect2i = image.get_used_rect()
	if used.size.x < 16 or used.size.y < 16 or used.position.x < 24 or used.position.y < 24 or used.end.x > logical.x-24 or used.end.y > logical.y-24:
		error = "Actual front carrier alpha empty/clipped."
		return false
	var crop := Rect2i(used.position-Vector2i(8,8),used.size+Vector2i(16,16))
	var histogram: Array[int] = []
	histogram.resize(256)
	histogram.fill(0)
	var data: PackedByteArray = image.get_data()
	for i in range(3,data.size(),4): histogram[data[i]] += 1
	observations["actual_gpu_front_carrier"] = {"raw_size_px":[raw.get_width(),raw.get_height()],"new_used_rect_px":[used.position.x,used.position.y,used.size.x,used.size.y],"new_crop_rect_px":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"actual_alpha_histogram":histogram,"gpu_source_alpha_probes":probes,"raw_repeat_byte_exact":true,"no_source_bitmap_crop_or_modification":true,"support":"No native carrier support claim: baked front texture carrier only; original gate anchor retained at source(971,705)","independent_visual_review":"PENDING"}
	# These are actual GPU diagnostic captures, NOT new edited source bitmaps.
	if not _png(output+"front_carrier_raw.png",raw) or not _png(output+"front_carrier_body.png",image.get_region(crop)): return false
	view.queue_free()
	view = null
	await _sync()
	return true

func _v8_adjacency(name: String) -> bool:
	var spec: Dictionary = V8_VIEWS[name]
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
		error = "Frozen support/paving cannot load."
		return false
	world.add_child(paving)
	var nodes: Dictionary = {}
	for id: String in WINGS:
		var node := MeshInstance3D.new()
		node.mesh = old_meshes[id]
		node.transform = _transform(_object(id)["native_transform"])
		world.add_child(node)
		nodes[id] = node
	var camera: Camera3D = _camera(world,logical,_point(Vector2(rect.position)+Vector2(rect.size)*.5),float(zoom))
	var origin: Vector2 = (FRONT.FRONT_ORIGIN-Vector2(rect.position))*float(zoom)*2.
	var carrier: Polygon2D = _carrier(view,origin,float(zoom),false)
	cameras[name] = {"source_rect_px":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"zoom":zoom,"logical_px":[logical.x,logical.y],"raw_px":[view.size.x,view.size.y],"camera_position_m":_v3(camera.position),"camera_basis":[_v3(camera.basis.x),_v3(camera.basis.y),_v3(camera.basis.z)],"orthographic_size_m":camera.size,"msaa":0,"old":"Frozen V7_03 helper rebuilt and actually GPU rendered now, with whole original PNG GPU carrier; not an old-result readback","new":"T-shaped front-only original texture UV carrier + two coplanar native wings, no short returns","other_city_objects":"Omitted; NOT a complete enclosed courtyard"}
	await _sync()
	var before: Image = await _repeat(name+" old current GPU")
	if before == null: return false
	carrier.free()
	_carrier(view,origin,float(zoom),true)
	for id: String in WINGS:
		nodes[id].mesh = new_meshes[id]
		nodes[id].transform = front_asset.placement(WINGS[id])
	if not _projection_witnesses(camera,name,rect,zoom): return false
	await _sync()
	var after: Image = await _repeat(name+" new current GPU")
	if after == null: return false
	before.resize(logical.x,logical.y,Image.INTERPOLATE_LANCZOS)
	after.resize(logical.x,logical.y,Image.INTERPOLATE_LANCZOS)
	if not _png(output+name+"_old.png",before) or not _png(output+name+"_new.png",after): return false
	view.queue_free()
	view = null
	await _sync()
	return true

func _projection_witnesses(camera: Camera3D,name: String,rect: Rect2i,zoom: int) -> bool:
	var recorded: Array[Dictionary] = []
	for id: String in WINGS:
		var side: String = WINGS[id]
		var mesh: ArrayMesh = new_meshes[id]
		for spec: Dictionary in front_asset.witnesses(side):
			var distance := INF
			var nearest := Vector3.ZERO
			for surface_index in range(mesh.get_surface_count()):
				if mesh.surface_get_name(surface_index) != spec["role"]: continue
				var arrays: Array = mesh.surface_get_arrays(surface_index)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				for index in indices:
					var d: float = vertices[index].distance_squared_to(spec["target"])
					if d < distance:
						distance = d
						nearest = vertices[index]
			if not is_finite(distance):
				error = "Native used-vertex projection witness missing."
				return false
			var actual: Vector2 = camera.unproject_position(front_asset.placement(side)*nearest)/2.
			var expected: Vector2 = (FRONT.FRONT_ORIGIN+spec["source"]*.5-Vector2(rect.position))*float(zoom)
			var delta: Vector2 = (actual-expected)/float(zoom)
			recorded.append({"id":id,"feature":spec["name"],"source_px":[spec["source"].x,spec["source"].y],"actual_used_vertex_m":_v3(nearest),"actual_view_px":[actual.x,actual.y],"carrier_view_px":[expected.x,expected.y],"delta_logical_px":[delta.x,delta.y]})
			if delta.length() > 1.5:
				error = "V8 actual brick/wall/eave/ridge projection alignment differs: "+side+"/"+String(spec["name"])
				observations[name+"_projection_witnesses"] = recorded
				return false
	observations[name+"_projection_witnesses"] = recorded
	return true

func _finish(passed: bool) -> void:
	old_meshes.clear()
	if old_asset != null: old_asset.release()
	old_asset = null
	front_asset = null
	front_texture = null
	await super._finish(passed)
