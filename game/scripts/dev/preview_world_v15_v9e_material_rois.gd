extends SceneTree

## Small native diagnostic, never FULL64/seam/NAV/Field/publication approval.
## Translate the same orthographic basis to four explicit crops; reuse exact
## completed V9D mesh/RF/owners. No whole-world CPU or 402M GPU allocation.
const OLD := preload("res://scripts/dev/world_map_v15_v9d_material_quality_proposal_surface.gd")
const NEW := preload("res://scripts/dev/world_map_v15_v9e_material_refinement_surface.gd")
const ART := "res://art/maps/world_map_v15_complete_v9c/"
const SIZE := Vector2i(12288,8192)
const GRID := Vector2i(1537,1025)
const CASES := [
	{"id":"snow", "rect":Rect2i(4360,0,1280,1024)},
	{"id":"marsh", "rect":Rect2i(10160,6576,1280,1024)},
	{"id":"river", "rect":Rect2i(7960,2489,1280,1024)},
	{"id":"farmland", "rect":Rect2i(3460,2582,1280,1024)}]
var output: String
var inputs: Dictionary = {}
var failures: Array[String] = []
var rows: Array = []
var surfaces: Array = []
var view: SubViewport
var world: Node3D
var terrain: MeshInstance3D
var water: MeshInstance3D
var camera: Camera3D
var eco: Texture2D
var roads: Texture2D
var rf: Texture2D
var terrain_mesh: ArrayMesh

func _initialize() -> void:
	call_deferred("_run")

func _require(ok: bool, message: String) -> bool:
	if not ok:
		failures.append(message)
		push_error(message)
	return ok

func _json(path: String, value: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(value,"\t"))
	file.flush()
	var ok: bool = file.get_error() == OK
	file.close()
	return ok and JSON.parse_string(FileAccess.get_file_as_string(path)) is Dictionary

func _load_inputs(auth: Dictionary) -> bool:
	if not _require(auth.get("scope") == "V9E_FOUR_BOUNDED_ORTHOGRAPHIC_MATERIAL_COMPARISONS_NOT_FULL" and auth.get("approved") == true and auth.get("builder_path") == get_script().resource_path and auth.get("builder_sha256") == FileAccess.get_sha256(get_script().resource_path),"Exact independent preview authorization required."): return false
	inputs = auth.get("input_sha256",{})
	for path: String in inputs:
		if not _require(FileAccess.get_sha256(path).to_lower() == String(inputs[path]).to_lower(),"Frozen preview input changed: "+path): return false
	for path: String in [ART+"terrain_mesh.res",ART+"terrain_height.rf",ART+"capture/ecology_reconstructed.png",ART+"capture/roads_reconstructed.png","res://scripts/dev/world_map_v15_v9d_material_quality_proposal_surface.gd","res://scripts/dev/world_map_v15_v9e_material_refinement_surface.gd"]:
		if not _require(inputs.has(path),"Required preview input missing: "+path): return false
	terrain_mesh = ResourceLoader.load(ART+"terrain_mesh.res","",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var rf_bytes := FileAccess.get_file_as_bytes(ART+"terrain_height.rf")
	if not _require(terrain_mesh != null and rf_bytes.size() == GRID.x*GRID.y*4,"Exact native mesh/RF dimensions required."): return false
	rf = ImageTexture.create_from_image(Image.create_from_data(GRID.x,GRID.y,false,Image.FORMAT_RF,rf_bytes))
	for kind: String in ["ecology","roads"]:
		var image := Image.load_from_file(ART+"capture/"+kind+"_reconstructed.png")
		if not _require(image != null and image.get_size() == SIZE/4,"Current 4px owner map required: "+kind): return false
		if kind == "ecology": eco = ImageTexture.create_from_image(image)
		else: roads = ImageTexture.create_from_image(image)
	for script: GDScript in [OLD,NEW]:
		var surface: RefCounted = script.new()
		if not _require(surface.call("load_sources") == true,"Registered 18 CC0 samplers failed."): return false
		for item: Dictionary in surface.get("evidence"):
			for key: String in ["path","source_path"]:
				if not _require(inputs.has(item[key]) and String(inputs[item[key]]).to_lower() == FileAccess.get_sha256(item[key]).to_lower(),"Unpinned actual CC0 sampler/source: "+String(item[key])): return false
		surfaces.append(surface)
	return true

func _make_world() -> void:
	view = SubViewport.new()
	view.size = Vector2i(2560,2048)
	view.own_world_3d = true
	view.msaa_3d = Viewport.MSAA_DISABLED
	view.msaa_2d = Viewport.MSAA_DISABLED
	view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(view)
	world = Node3D.new()
	view.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = surfaces[0].call("environment")
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-34,0)
	sun.light_energy = .85
	sun.shadow_enabled = false
	world.add_child(sun)
	terrain = MeshInstance3D.new()
	terrain.mesh = terrain_mesh
	terrain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(terrain)
	water = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(float(SIZE.x+2048)/102.4,float(SIZE.y+2048)/72.40773439)
	water.mesh = plane
	water.position.y = -.025
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(water)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = 1024./102.4
	camera.near = .05
	camera.far = 200.
	world.add_child(camera)
	camera.current = true

func _capture(surface: RefCounted, variant: String) -> bool:
	var material: ShaderMaterial = surface.call("terrain_material",eco,roads,Rect2(Vector2.ZERO,Vector2(SIZE)))
	var water_material: ShaderMaterial = surface.call("water_material",rf,Vector2i.ZERO,GRID)
	if not _require(material != null and water_material != null,"Actual experiment materials failed: "+String(surface.get("error"))): return false
	terrain.material_override = material
	water.material_override = water_material
	for pair: Array in [["terrain",material],["water",water_material]]:
		var path: String = output+variant+"_actual_"+pair[0]+".res"
		if not _require(ResourceSaver.save(pair[1],path) == OK,"Actual material save failed."): return false
	for item: Dictionary in CASES:
		var rect: Rect2i = item.rect
		var center := Vector2(rect.get_center())
		var target := Vector3((center.x-6144.)/102.4,0.,(center.y-4096.)/72.40773439)
		camera.position = target+Vector3(0,60,60)
		camera.look_at(target)
		var first: PackedByteArray
		var record: Dictionary = {"variant":variant,"id":item.id,"logical_rect_px":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"camera_position":str(camera.position),"projection":"same orthographic basis translated to bounded crop","fresh_draws":[],"no_whole_camera_authority":true,"objects_and_shadows_included":false}
		for pass_index in 2:
			# The first request allows sky/material compilation to settle. Each
			# captured pass still observes its own actual post-draw fence.
			for settle_frame in 4:
				view.render_target_update_mode = SubViewport.UPDATE_ONCE
				await process_frame
				await RenderingServer.frame_post_draw
			var image: Image = view.get_texture().get_image()
			if not _require(image != null and image.get_size() == view.size and image.get_width()*image.get_height() <= 8404992,"Bounded actual GPU image required."): return false
			image.convert(Image.FORMAT_RGBA8)
			var raw := image.get_data()
			if pass_index == 0: first = raw
			elif not _require(first == raw,"Fresh actual repeat differs: "+variant+"/"+item.id): return false
			image.resize(1280,1024,Image.INTERPOLATE_LANCZOS)
			var path: String = output+variant+"_"+item.id+("" if pass_index == 0 else "_repeat")+".png"
			if not _require(image.save_png(path) == OK,"Actual PNG save failed."): return false
			record.fresh_draws.append({"path":path,"sha256":FileAccess.get_sha256(path),"native_canvas":[2560,2048],"native_RGBA_repeat_exact":pass_index == 1,"actual_post_draw_observed":true})
		rows.append(record)
	return true

func _run() -> void:
	output = "res://build/joint_world_luoyang_20261003_qa/v9e_material_preview_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(output)
	var auth_path: String
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--authorization="): auth_path = arg.trim_prefix("--authorization=")
	var auth: Variant = JSON.parse_string(FileAccess.get_file_as_string(auth_path)) if not auth_path.is_empty() else null
	if _require(DisplayServer.get_name() != "headless" and "--v9e-material-refinement-preview" in OS.get_cmdline_user_args() and auth is Dictionary,"Explicit bounded GPU preview arguments required.") and _load_inputs(auth):
		_make_world()
		if await _capture(surfaces[0],"v9d_reference"):
			await _capture(surfaces[1],"v9e_experiment")
	for path: String in inputs:
		_require(FileAccess.get_sha256(path).to_lower() == String(inputs[path]).to_lower(),"Preview input changed after: "+path)
	var actual_materials: Array = []
	for surface: RefCounted in surfaces:
		actual_materials.append({"source_path":surface.get_script().resource_path,"source_sha256":FileAccess.get_sha256(surface.get_script().resource_path),"samplers":surface.get("evidence"),"v9e_records":surface.get("v9e_records") if surface == surfaces.back() else []})
	_json(output+"result.json",{"scope":"V9E_FOUR_BOUNDED_ORTHOGRAPHIC_MATERIAL_COMPARISONS_NOT_FULL","passed":failures.is_empty() and rows.size() == 8,"failures":failures,"rows":rows,"input_sha256":inputs,"actual_materials":actual_materials,"engine_pid":OS.get_process_id(),"executed_builder_sha256":FileAccess.get_sha256(get_script().resource_path),"objects_and_shadows_included":false,"geometry_navigation_changed":false,"FULL_NAV_Field_credit":false,"visual_approved":false,"production_approved":false})
	if view != null: view.queue_free()
	for frame in 20: await process_frame
	for surface: RefCounted in surfaces: surface.call("release")
	surfaces.clear()
	eco = null
	roads = null
	rf = null
	terrain_mesh = null
	# Release the isolated tool's native cursor bindings before GLES shutdown,
	# matching the project's existing preview-tool lifecycle. Player processes
	# and stored cursor/preferences remain untouched.
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]:
		Input.set_custom_mouse_cursor(null,shape)
	var cursor: Node = root.get_node_or_null("CursorManager")
	if cursor != null:
		for key: String in ["_arrow","_hand","_wait"]: cursor.set(key,null)
	for frame in 16: await process_frame
	print("V9E_MATERIAL_PREVIEW ",output," passed=",failures.is_empty() and rows.size() == 8)
	quit(0 if failures.is_empty() and rows.size() == 8 else 1)
