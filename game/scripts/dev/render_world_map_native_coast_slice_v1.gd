extends SceneTree

# Isolated art/navigation experiment. Does not replace any runtime world map.
# All geometry, road points and the walk mask are produced from the functions below.
const SIZE := Vector2i(1536, 1024)
const GROUND_SOURCE := "res://../assets/raw/external/polyhaven/aerial_grass_rock/aerial_grass_rock_diff_4k.jpg"
const ROAD_SOURCE := "res://../assets/raw/external/polyhaven/rock_path/rock_path_diff_4k.jpg"
const BOULDER := "res://art/external/polyhaven/boulder_01/boulder_01_1k.gltf"
const OUT_SCENE := "res://build/world_map_v13_native_coast_slice_v1.png"
const OUT_WALK := "res://build/world_map_v13_native_coast_walk_v1.png"
const BOULDER_CENTER := Vector2(-4.95, -2.0)
const ROAD_POINTS := [Vector2(-10.0, 2.9), Vector2(-7.4, 2.7), Vector2(-4.8, 2.1), Vector2(-2.0, 2.0), Vector2(0.7, 2.8), Vector2(3.4, 2.7)]


func _scene_output() -> String:
	return OUT_SCENE


func _walk_output() -> String:
	return OUT_WALK


func _initialize() -> void:
	call_deferred("_render")


func _coast_x(z: float) -> float:
	return 4.65 + 0.34 * sin(z * 0.63) + 0.16 * sin(z * 1.49)


func _height(x: float, z: float) -> float:
	var western_ridge := 1.00 * exp(-pow((x + 5.5) / 2.3, 2.0) - pow((z + 3.4) / 2.7, 2.0))
	var northern_ridge := 0.70 * exp(-pow((x + 0.3) / 3.6, 2.0) - pow((z + 6.0) / 1.9, 2.0))
	var low_hills := 0.12 * sin(x * 0.64 + z * 0.30) + 0.08 * sin(z * 1.2 - x * 0.4)
	var shore_factor := clampf((_coast_x(z) - x) / 1.4, 0.0, 1.0)
	return (0.19 + western_ridge + northern_ridge + low_hills) * shore_factor + 0.035


func _terrain_mesh(coast_inset: float = 0.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const ROWS := 96
	const COLS := 112
	for zi in ROWS:
		var z0 := lerpf(-9.0, 9.0, float(zi) / float(ROWS))
		var z1 := lerpf(-9.0, 9.0, float(zi + 1) / float(ROWS))
		for xi in COLS:
			var t0 := float(xi) / float(COLS)
			var t1 := float(xi + 1) / float(COLS)
			var a := _terrain_point(t0, z0, coast_inset)
			var b := _terrain_point(t1, z0, coast_inset)
			var c := _terrain_point(t0, z1, coast_inset)
			var d := _terrain_point(t1, z1, coast_inset)
			_add_tri(st, a, c, b, true)
			_add_tri(st, b, c, d, true)
	st.generate_normals()
	return st.commit()


func _terrain_point(t: float, z: float, coast_inset: float) -> Vector3:
	var x := lerpf(-10.5, _coast_x(z) - coast_inset, t)
	return Vector3(x, _height(x, z), z)


func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, terrain_uv: bool) -> void:
	for p in [a, b, c]:
		st.set_uv(Vector2((p.x + 10.5) * 0.29, (p.z + 9.0) * 0.29) if terrain_uv else Vector2.ZERO)
		st.add_vertex(p)


func _road_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var traveled := 0.0
	for segment in range(ROAD_POINTS.size() - 1):
		var p0: Vector2 = ROAD_POINTS[segment]
		var p1: Vector2 = ROAD_POINTS[segment + 1]
		var steps := maxi(2, ceili(p0.distance_to(p1) / 0.14))
		var dir := (p1 - p0).normalized()
		var perpendicular := Vector2(-dir.y, dir.x) * 0.48
		for step in steps:
			var t0 := float(step) / float(steps)
			var t1 := float(step + 1) / float(steps)
			var q0 := p0.lerp(p1, t0)
			var q1 := p0.lerp(p1, t1)
			var v0 := traveled + p0.distance_to(p1) * t0
			var v1 := traveled + p0.distance_to(p1) * t1
			var a := _road_point(q0 + perpendicular)
			var b := _road_point(q0 - perpendicular)
			var c := _road_point(q1 + perpendicular)
			var d := _road_point(q1 - perpendicular)
			_road_tri(st, a, c, b, Vector2(0, v0), Vector2(0, v1), Vector2(1, v0))
			_road_tri(st, b, c, d, Vector2(1, v0), Vector2(0, v1), Vector2(1, v1))
		traveled += p0.distance_to(p1)
	st.generate_normals()
	return st.commit()


func _road_point(p: Vector2) -> Vector3:
	return Vector3(p.x, _height(p.x, p.y) + 0.035, p.y)


func _road_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	for pair in [[a, ua], [b, ub], [c, uc]]:
		st.set_uv(pair[1])
		st.add_vertex(pair[0])


func _make_viewport(mask: bool, ground_image: Image, road_image: Image, boulder_scene: PackedScene) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = SIZE
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color.BLACK if mask else Color(0.09, 0.22, 0.29)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.72, 0.75, 0.76)
	settings.ambient_light_energy = 0.47
	environment.environment = settings
	world.add_child(environment)
	var land := MeshInstance3D.new()
	land.mesh = _terrain_mesh(0.42 if mask else 0.0)
	var ground_material := StandardMaterial3D.new()
	ground_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if mask:
		ground_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ground_material.albedo_color = Color.WHITE
		land.material_override = ground_material
	else:
		land.material_override = _make_ground_material(ground_image, road_image)
	world.add_child(land)
	if not mask:
		var road := MeshInstance3D.new()
		road.mesh = _road_mesh()
		var road_material := StandardMaterial3D.new()
		road_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		road_material.albedo_texture = ImageTexture.create_from_image(road_image)
		road_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		road_material.albedo_color = Color(0.88, 0.78, 0.61)
		road.material_override = road_material
		world.add_child(road)
		var rock := boulder_scene.instantiate() as Node3D
		rock.position = Vector3(BOULDER_CENTER.x, _height(BOULDER_CENTER.x, BOULDER_CENTER.y), BOULDER_CENTER.y)
		rock.scale = Vector3.ONE * 0.70
		world.add_child(rock)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-57.0, -31.0, 0.0)
		light.light_energy = 0.92
		light.shadow_enabled = true
		world.add_child(light)
	else:
		# One object owns both the visible rock and the impassable footprint.
		var footprint := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.48
		disc.bottom_radius = 0.48
		disc.height = 0.03
		footprint.mesh = disc
		footprint.position = Vector3(BOULDER_CENTER.x, _height(BOULDER_CENTER.x, BOULDER_CENTER.y) + 0.09, BOULDER_CENTER.y)
		var blocker_material := StandardMaterial3D.new()
		blocker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		blocker_material.albedo_color = Color.BLACK
		footprint.material_override = blocker_material
		world.add_child(footprint)
	_decorate_world(world, mask)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.0
	camera.position = Vector3(-1.0, 12.0, 11.5)
	world.add_child(camera)
	camera.look_at(Vector3(-1.0, 0.0, 0.0))
	_configure_camera(camera)
	camera.current = true
	return viewport


func _configure_camera(_camera: Camera3D) -> void:
	pass


func _make_ground_material(ground_image: Image, _road_image: Image) -> Material:
	var material := StandardMaterial3D.new()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = ImageTexture.create_from_image(ground_image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.albedo_color = Color(0.78, 0.78, 0.72)
	return material


func _decorate_world(_world: Node3D, _mask: bool) -> void:
	pass


func _render() -> void:
	var ground_image := Image.load_from_file(ProjectSettings.globalize_path(GROUND_SOURCE))
	var road_image := Image.load_from_file(ProjectSettings.globalize_path(ROAD_SOURCE))
	var boulder_scene := load(BOULDER) as PackedScene
	if ground_image == null or ground_image.is_empty() or road_image == null or road_image.is_empty() or boulder_scene == null:
		push_error("Licensed source is missing; see docs/licensed-world-assets-polyhaven-20260929.md")
		quit(1)
		return
	var scene_viewport := _make_viewport(false, ground_image, road_image, boulder_scene)
	var mask_viewport := _make_viewport(true, ground_image, road_image, boulder_scene)
	for frame in 24:
		await process_frame
	var scene_image := scene_viewport.get_texture().get_image()
	var mask_image := mask_viewport.get_texture().get_image()
	var camera := mask_viewport.get_camera_3d()
	var passed := 0
	for p in ROAD_POINTS.slice(1):
		if not _expect_mask(mask_image, camera, p, true):
			quit(1)
			return
		passed += 1
	for p in [Vector2(-7.0, -1.0), Vector2(-1.0, 0.0), Vector2(2.0, -2.0)]:
		if not _expect_mask(mask_image, camera, p, true):
			quit(1)
			return
		passed += 1
	for z in [-6.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0]:
		if not _expect_mask(mask_image, camera, Vector2(_coast_x(z) - 1.7, z), true):
			quit(1)
			return
		passed += 1
		if not _expect_mask(mask_image, camera, Vector2(_coast_x(z) + 1.0, z), false):
			quit(1)
			return
		passed += 1
	if not _expect_mask(mask_image, camera, BOULDER_CENTER, false):
		quit(1)
		return
	passed += 1
	if scene_image.save_png(_scene_output()) != OK or mask_image.save_png(_walk_output()) != OK:
		push_error("Could not save native coast slice")
		quit(1)
		return
	print("[WorldNativeCoast] ", passed, " geometry/mask probes passed; scene=", _scene_output(), " walk=", _walk_output())
	scene_viewport.queue_free()
	mask_viewport.queue_free()
	await process_frame
	quit(0)


func _expect_mask(mask_image: Image, camera: Camera3D, point: Vector2, expected_walkable: bool) -> bool:
	var ground := Vector3(point.x, _height(point.x, point.y), point.y)
	var pixel := Vector2i(camera.unproject_position(ground).round())
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= SIZE.x or pixel.y >= SIZE.y:
		push_error("Probe projected outside render: %s -> %s" % [point, pixel])
		return false
	var actual_walkable := mask_image.get_pixelv(pixel).r > 0.8
	if actual_walkable != expected_walkable:
		push_error("Mask mismatch at %s -> %s: expected %s, got %s" % [point, pixel, expected_walkable, actual_walkable])
		return false
	return true
