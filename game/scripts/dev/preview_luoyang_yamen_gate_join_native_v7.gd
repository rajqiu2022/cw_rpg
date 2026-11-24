extends SceneTree

## Standalone visual prototype: no inheritance/calls into old publishers,
## _prototype/_run, Field, routes, collision or save/load fixtures.
const ASSET := preload("res://scripts/dev/luoyang_yamen_gate_join_native_v7_preview.gd")
const INPUT_ROOT := "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s1_luoyang_yamen/"
const MANIFEST_SHA := "b7bfdd920ba69858b70c9cf77c5d3b65161f14032ae3eb0e1f5f5f0b04385315"
const OUTPUT_ROOT := "res://build/luoyang_yamen_gate_join_native_v7_preview/"
const WINGS := {"court_southwest_wing":"left","court_southeast_wing":"right"}
const VIEWS := {
	"full":{"rect":Rect2i(656,1120,1760,720),"zoom":1},
	"left_closeup":{"rect":Rect2i(760,1360,640,360),"zoom":2},
	"right_closeup":{"rect":Rect2i(1672,1360,640,360),"zoom":2}
}
var output := ""
var error := ""
var inputs: Dictionary = {}
var outputs: Dictionary = {}
var manifest: Dictionary = {}
var asset: ASSET
var view: SubViewport
var new_meshes: Dictionary = {}
var baseline_mesh: ArrayMesh
var observations: Dictionary = {}
var checkpoint_guard: Dictionary = {}
var cameras: Dictionary = {}

func _initialize() -> void:
	call_deferred("_start")

func _start() -> void:
	# FIRST deferred action after autoload ready, before every await/fixture.
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		push_error("Native art preview requires public checkpoint suspension; no fallback.")
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
	if "--luoyang-yamen-native-join-v7-preview" not in args or rule.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$") != OK or rule.search(tag) == null or DisplayServer.get_name() == "headless":
		push_error("Explicit native-join GPU flag and fresh safe tag required; headless refused.")
		quit(2)
		return
	output = OUTPUT_ROOT+tag+"/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)):
		push_error("Refusing overwrite of any earlier native art preview.")
		quit(2)
		return
	for path: String in [get_script().resource_path,"res://scripts/dev/luoyang_yamen_gate_join_native_v7_preview.gd"]:
		if not _track(path):
			quit(2)
			return
	for path: String in ASSET.SOURCE_PINS:
		if not _track(path,ASSET.SOURCE_PINS[path]):
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
		push_error("Cannot create independent native prototype output.")
		quit(2)
		return
	asset = ASSET.new()
	if not asset.prepare():
		error = asset.error
		await _finish(false)
		return
	var old_path: String = INPUT_ROOT+"entities/native_wall_horizontal.res"
	if not _bound_resource(old_path):
		await _finish(false)
		return
	baseline_mesh = ResourceLoader.load(old_path,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if baseline_mesh == null:
		error = "Actual baseline native wall unavailable."
		await _finish(false)
		return
	observations["old_native_geometry"] = _measure(baseline_mesh)
	if observations["old_native_geometry"].is_empty():
		await _finish(false)
		return
	for id: String in WINGS:
		var side: String = WINGS[id]
		var mesh: ArrayMesh = asset.build(side)
		if mesh == null or asset.error != "":
			error = asset.error
			await _finish(false)
			return
		var measured: Dictionary = _measure(mesh)
		if measured.is_empty():
			await _finish(false)
			return
		var object: Dictionary = _object(id)
		if object.is_empty():
			await _finish(false)
			return
		var transform: Transform3D = _transform(object["native_transform"])
		# Conservative actual AABB X projection, not a claim of production
		# foot/collision compatibility. Both prototypes must stay outside avenue.
		var box: AABB = transform*mesh.get_aabb()
		var min_px: float = box.position.x*64.+1536.
		var max_px: float = box.end.x*64.+1536.
		if measured["minimum"][1] < -.00001 or (side == "left" and max_px >= 1360.) or (side == "right" and min_px <= 1712.):
			error = "New visual geometry invades the central door/avenue or ground."
			await _finish(false)
			return
		new_meshes[id] = mesh
		observations[id] = {"new_geometry":measured,"parts":asset.counts.duplicate(true),"saved_original_transform":object["native_transform"],"actual_world_x_bounds_px":[min_px,max_px],"central_avenue_x1360_to1712_clear":true,"alpha_bounds_scope":"NEW actual measurements, NOT old-alpha preservation or production collision approval"}
		var path: String = output+side+"_native_mesh.res"
		if not _save_mesh(path,mesh) or not await _body(mesh,side):
			await _finish(false)
			return
	var gate_object: Dictionary = _object("south_court_gate")
	if gate_object.is_empty() or not _bound(gate_object["texture"]):
		await _finish(false)
		return
	var gate: Image = Image.load_from_file(gate_object["texture"])
	if gate == null:
		error = "Original detailed gate PNG unavailable."
		await _finish(false)
		return
	gate.convert(Image.FORMAT_RGBA8)
	for name: String in VIEWS:
		if not await _adjacency(name,baseline_mesh,gate,gate_object):
			await _finish(false)
			return
	await _finish(true)

func _track(path: String,expected: String = "") -> bool:
	var actual: String = FileAccess.get_sha256(path).to_lower()
	if actual.length() != 64 or (expected != "" and actual != expected) or (inputs.has(path) and inputs[path] != actual):
		error = "Input SHA missing/mismatch/change: " + path
		return false
	inputs[path] = actual
	return true

func _bound(path: String) -> bool:
	var catalog: Dictionary = manifest.get("asset_sha256",{})
	if not catalog.has(path):
		error = "Unbound frozen input: " + path
		return false
	return _track(path,String(catalog[path]))

func _bound_resource(path: String,seen: Dictionary = {}) -> bool:
	if not _bound(path): return false
	if seen.has(path): return true
	seen[path] = true
	for dependency: String in ResourceLoader.get_dependencies(path):
		var target := ""
		for part: String in dependency.split("::"):
			if part.begins_with("res://"): target = part
		if target == "" or not _bound_resource(target,seen):
			error = "Unresolved/unbound native dependency: " + dependency
			return false
	return true

func _object(id: String) -> Dictionary:
	for item: Dictionary in manifest.get("objects",[]):
		if item.get("id") == id: return item
	error = "Exact frozen adjacency object missing: " + id
	return {}

func _transform(data: Dictionary) -> Transform3D:
	var b: Array = data["basis_columns"]
	return Transform3D(Basis(_vec(b[0]),_vec(b[1]),_vec(b[2])),_vec(data["origin"]))

func _vec(a: Array) -> Vector3:
	return Vector3(a[0],a[1],a[2])

func _v3(v: Vector3) -> Array:
	return [v.x,v.y,v.z]

func _point(pixel: Vector2) -> Vector3:
	return Vector3((pixel.x-1536.)/64.,0.,(pixel.y-1024.)/32.)

func _measure(mesh: ArrayMesh) -> Dictionary:
	var low := Vector3(INF,INF,INF)
	var high := Vector3(-INF,-INF,-INF)
	var surfaces: Array[Dictionary] = []
	var triangles := 0
	var used := PackedVector3Array()
	for surface_index in range(mesh.get_surface_count()):
		if mesh.surface_get_primitive_type(surface_index) != Mesh.PRIMITIVE_TRIANGLES:
			error = "Actual native surface is not triangles."
			return {}
		var a: Array = mesh.surface_get_arrays(surface_index)
		if a.size() != Mesh.ARRAY_MAX or not a[Mesh.ARRAY_VERTEX] is PackedVector3Array or not a[Mesh.ARRAY_NORMAL] is PackedVector3Array:
			error = "Actual native slot count/vertex/normal types invalid."
			return {}
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
		var index_variant: Variant = a[Mesh.ARRAY_INDEX]
		var indices := PackedInt32Array()
		var index_mode := "indexed"
		if typeof(index_variant) == TYPE_NIL:
			index_mode = "non_indexed_sequential_vertices"
			if v.size()%3 != 0:
				error = "Actual non-indexed triangle vertex count is not divisible by three."
				return {}
			for i in range(v.size()): indices.append(i)
		elif typeof(index_variant) == TYPE_PACKED_INT32_ARRAY:
			indices = index_variant
		else:
			error = "Actual native index slot must be NIL or PackedInt32Array."
			return {}
		if v.is_empty() or n.size() != v.size() or indices.size() == 0 or indices.size()%3 != 0:
			error = "Actual new/baseline native arrays incomplete."
			return {}
		for index in indices:
			if index < 0 or index >= v.size() or not v[index].is_finite() or not n[index].is_finite() or n[index].length_squared() < .99:
				error = "Actual draw index/vertex/normal invalid."
				return {}
			low = low.min(v[index])
			high = high.max(v[index])
			used.append(v[index])
		for i in range(0,indices.size(),3):
			var cross: Vector3 = (v[indices[i+1]]-v[indices[i]]).cross(v[indices[i+2]]-v[indices[i]])
			if cross.length_squared() < .000000000001 or cross.dot(n[indices[i]]) >= 0.:
				error = "Actual native triangle degenerate or wrong clockwise normal."
				return {}
			triangles += 1
		var slots: Array[Dictionary] = []
		for slot in range(Mesh.ARRAY_MAX): slots.append({"slot":slot,"type":typeof(a[slot]),"sha256":_hash(var_to_bytes(a[slot]))})
		surfaces.append({"surface":surface_index,"primitive":mesh.surface_get_primitive_type(surface_index),"draw_index_mode":index_mode,"slots":slots})
	var sum_x := 0.
	var front := -INF
	var count := 0
	for p: Vector3 in used:
		if p.y <= low.y+(high.y-low.y)*.02:
			sum_x += p.x
			front = maxf(front,p.z)
			count += 1
	if count == 0:
		error = "Actual native lowest-draw support set empty."
		return {}
	return {"minimum":_v3(low),"maximum":_v3(high),"support_lowest2pct_m":[sum_x/count,low.y,front],"support_draw_sample_count":count,"triangles":triangles,"finite_draw_vertices_indices_clockwise_normals":true,"native_aabb":str(mesh.get_aabb()),"all_native_slots":surfaces}

func _body(mesh: ArrayMesh,side: String) -> bool:
	var logical := Vector2i(1024,768)
	view = _viewport(logical*2,true)
	var world: Node3D = _world(view,true)
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(body)
	var camera: Camera3D = _camera(world,logical,Vector3.ZERO,1.)
	await _sync()
	var raw: Image = await _repeat(side+" body")
	if raw == null: return false
	var image: Image = _alpha_resize(raw,logical)
	var used: Rect2i = image.get_used_rect()
	var raw_used: Rect2i = raw.get_used_rect()
	if used.size.x < 16 or used.size.y < 16 or used.position.x < 24 or used.position.y < 24 or used.end.x > logical.x-24 or used.end.y > logical.y-24:
		error = "New native body empty/clipped/insufficient transparent margin."
		return false
	var crop := Rect2i(used.position-Vector2i(8,8),used.size+Vector2i(16,16))
	var cropped: Image = image.get_region(crop)
	var alpha_data: PackedByteArray = image.get_data()
	var histogram: Array[int] = []
	histogram.resize(256)
	histogram.fill(0)
	for i in range(3,alpha_data.size(),4): histogram[alpha_data[i]] += 1
	var measured: Dictionary = _measure(mesh)
	if measured.is_empty(): return false
	var foot: Vector2 = camera.unproject_position(_vec(measured["support_lowest2pct_m"]))/2.
	observations[side+"_actual_body"] = {"raw_size_px":[raw.get_width(),raw.get_height()],"raw_used_rect_px":[raw_used.position.x,raw_used.position.y,raw_used.size.x,raw_used.size.y],"logical_size_px":[logical.x,logical.y],"new_used_rect_px":[used.position.x,used.position.y,used.size.x,used.size.y],"new_crop_rect_px":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"actual_alpha_histogram":histogram,"measured_ground_front_anchor_px":[foot.x,foot.y],"new_crop_foot_uv":[(foot.x-crop.position.x)/crop.size.x,(foot.y-crop.position.y)/crop.size.y],"raw_repeat_byte_exact":true,"old_alpha_forced":false,"independent_alpha_crop_visual_review":"PENDING"}
	if not _png(output+side+"_body_raw.png",raw) or not _png(output+side+"_body.png",cropped): return false
	view.queue_free()
	view = null
	await _sync()
	return true

func _adjacency(name: String,old_mesh: ArrayMesh,gate: Image,gate_object: Dictionary) -> bool:
	var spec: Dictionary = VIEWS[name]
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
		error = "Frozen support/paving input cannot load."
		return false
	world.add_child(paving)
	var nodes: Dictionary = {}
	for id: String in WINGS:
		var node := MeshInstance3D.new()
		node.mesh = old_mesh
		node.transform = _transform(_object(id)["native_transform"])
		world.add_child(node)
		nodes[id] = node
	var center: Vector2 = Vector2(rect.position)+Vector2(rect.size)*.5
	var camera: Camera3D = _camera(world,logical,_point(center),float(zoom))
	cameras[name] = {"source_rect_px":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"zoom":zoom,"logical_px":[logical.x,logical.y],"raw_px":[view.size.x,view.size.y],"camera_position_m":_v3(camera.position),"camera_basis":[_v3(camera.basis.x),_v3(camera.basis.y),_v3(camera.basis.z)],"orthographic_size_m":camera.size,"msaa":0,"gate":"Original source PNG composited at original foot/scale; no native gate/caster exists","other_city_objects":"Omitted intentionally; two-wing adjacency visual prototype only"}
	await _sync()
	var before: Image = await _repeat(name+" baseline")
	if before == null: return false
	for id: String in WINGS: nodes[id].mesh = new_meshes[id]
	await _sync()
	var after: Image = await _repeat(name+" new")
	if after == null: return false
	before.resize(logical.x,logical.y,Image.INTERPOLATE_LANCZOS)
	after.resize(logical.x,logical.y,Image.INTERPOLATE_LANCZOS)
	var gate_size := Vector2i(int(round(float(gate_object["render_size_px"][0])*zoom)),int(round(float(gate_object["render_size_px"][1])*zoom)))
	var display_gate: Image = gate if gate.get_size() == gate_size else _alpha_resize(gate,gate_size)
	var foot := Vector2(gate_object["world_foot_px"][0],gate_object["world_foot_px"][1])
	var uv := Vector2(gate_object["foot_uv"][0],gate_object["foot_uv"][1])
	var origin := Vector2i(((foot-Vector2(rect.position))*zoom-uv*Vector2(gate_size)).round())
	before.blend_rect(display_gate,Rect2i(Vector2i.ZERO,gate_size),origin)
	after.blend_rect(display_gate,Rect2i(Vector2i.ZERO,gate_size),origin)
	if not _png(output+name+"_baseline.png",before) or not _png(output+name+"_new.png",after): return false
	view.queue_free()
	view = null
	await _sync()
	return true

func _viewport(size: Vector2i,transparent: bool) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.own_world_3d = true
	viewport.transparent_bg = transparent
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	return viewport

func _world(viewport: SubViewport,transparent: bool) -> Node3D:
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = asset.surface.environment(transparent)
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-34,0)
	sun.light_energy = .85
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 120.
	sun.shadow_bias = .02
	sun.shadow_normal_bias = 1.
	world.add_child(sun)
	return world

func _camera(world: Node3D,logical: Vector2i,target: Vector3,zoom: float) -> Camera3D:
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = logical.y/(64.*zoom)
	camera.near = .1
	camera.far = 160.
	world.add_child(camera)
	camera.position = target+Vector3(0,32,55.4256258422)
	camera.look_at(target,Vector3.UP)
	return camera

func _alpha_resize(image: Image,size: Vector2i) -> Image:
	# Same premultiplied RGBAF Lanczos method, not old-alpha forcing.
	var result: Image = image.duplicate() as Image
	result.convert(Image.FORMAT_RGBAF)
	for y in range(result.get_height()):
		for x in range(result.get_width()):
			var c: Color = result.get_pixel(x,y)
			result.set_pixel(x,y,Color(c.r*c.a,c.g*c.a,c.b*c.a,c.a))
	result.resize(size.x,size.y,Image.INTERPOLATE_LANCZOS)
	for y in range(size.y):
		for x in range(size.x):
			var c: Color = result.get_pixel(x,y)
			result.set_pixel(x,y,Color(c.r/c.a,c.g/c.a,c.b/c.a,c.a) if c.a>.00001 else Color(0,0,0,0))
	result.convert(Image.FORMAT_RGBA8)
	return result

func _sync() -> void:
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw

func _repeat(label: String) -> Image:
	var a: Image = view.get_texture().get_image()
	a.convert(Image.FORMAT_RGBA8)
	await _sync()
	var b: Image = view.get_texture().get_image()
	b.convert(Image.FORMAT_RGBA8)
	if a.get_data() != b.get_data():
		error = "Native GPU repeat not byte exact: " + label
		return null
	return a

func _hash(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK: return ""
	if context.update(bytes) != OK: return ""
	return context.finish().hex_encode()

func _save_mesh(path: String,mesh: ArrayMesh) -> bool:
	if not path.begins_with(output) or FileAccess.file_exists(path) or ResourceSaver.save(mesh,path) != OK:
		error = "Own new native mesh save refused."
		return false
	outputs[path] = {"sha256":FileAccess.get_sha256(path),"scope":"Actual rendered NEW mesh resource; NOT a production candidate"}
	return true

func _png(path: String,image: Image) -> bool:
	if output == "" or not path.begins_with(output) or FileAccess.file_exists(path) or image.save_png(path) != OK:
		error = "Own preview PNG overwrite/path/save refused."
		return false
	var readback: Image = Image.load_from_file(path)
	if readback == null or readback.get_size() != image.get_size() or readback.get_format() != image.get_format() or readback.get_data() != image.get_data():
		error = "Actual captured PNG readback differs."
		return false
	outputs[path] = {"sha256":FileAccess.get_sha256(path),"rgba_sha256":_hash(image.get_data()),"size_px":[image.get_width(),image.get_height()],"lossless_readback_exact":true}
	return true

func _finish(passed: bool) -> void:
	var patches: Dictionary = asset.patch_observations.duplicate(true) if asset != null else {}
	if view != null:
		view.queue_free()
		view = null
	new_meshes.clear()
	# Do not retain baseline .res materials/CompressedTextures in the suspended
	# _start coroutine through quit; release before the existing drain frames.
	baseline_mesh = null
	if asset != null: asset.release()
	asset = null
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
		error = "Read-only asset inputs changed during preview."
	var report: Dictionary = {"status":"PREVIEW_NOT_ADOPTED" if passed else "PREVIEW_FAILED_NOT_ADOPTED","passed_capture_checks":passed,"reason":error,"scope":"TWO NEW NATIVE GATE-ADJACENT WALL ASSETS ONLY; NOT Field/collision/navigation/save-load/audio/release approval","checkpoint_guard":checkpoint_guard,"inputs_sha256_first":inputs,"inputs_sha256_last":final_inputs,"input_changes":changes,"outputs":outputs,"geometry_and_alpha":observations,"source_image_rgb_patch_reuse":patches,"cameras":cameras,"gate_provenance":"Existing project-original generated PNG, not native geometry or a licensed plaster/tile scan; original pixels unmodified; native materials reuse high-alpha interior RGB only","independent_visual_alpha_crop_review":"PENDING","visual_approved":false,"production_approved":false,"audio_credit":"NONE; outer full stderr must be reviewed independently"}
	var path: String = output+"preview_result.json"
	var file: FileAccess = null
	if not FileAccess.file_exists(path): file = FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		passed = false
		error = "Own result save/overwrite refused."
	else:
		file.store_string(JSON.stringify(report,"\t"))
		file.close()
	if not passed: push_error(error)
	quit(0 if passed else 1)
