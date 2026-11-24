extends SceneTree

## Isolated technical probe: a native 3072x1024 center/east render generated
## from editable orthographic geometry. No existing world map or nav is changed.

const OUTPUT_DIR := "res://build/world_map_v13_ortho_terrain_probe"
const SIZE := Vector2i(3072, 1024)
const DEPTH := 1182.414
const STEP := 24.0

const GRASS := "res://art/modules/world_map_v13/terrain_mat_dry_grass_v1_candidate.png"
const ROCK := "res://art/modules/world_map_v13/terrain_mat_rock_gravel_v1_candidate.png"
const SAND := "res://art/modules/world_map_v13/terrain_mat_beach_sand_v1_candidate.png"
const WATER := "res://art/modules/world_map_v13/terrain_mat_coastal_water_v1_candidate.png"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("The orthographic terrain probe requires a rendering display")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var viewport := SubViewport.new()
	viewport.size = SIZE
	viewport.disable_3d = false
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.11, 0.23, 0.30)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.63, 0.69, 0.69)
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	world.add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-57, -35, 0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	world.add_child(sun)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = 1024.0
	camera.near = 0.1
	camera.far = 6000.0
	camera.position = Vector3(1536, 1700, DEPTH * 0.5 + 981.5)
	world.add_child(camera)
	camera.look_at(Vector3(1536, 0, DEPTH * 0.5))
	camera.current = true
	print("[ORTHO_CAMERA] current=", camera.current, " viewport_camera=", viewport.get_camera_3d(), " forward=", -camera.global_basis.z, " origin=", camera.position)
	_add_terrain(world)
	for frame in range(20):
		await process_frame
	print("[ORTHO_FRAME] viewport_camera=", viewport.get_camera_3d(), " meshes=", world.get_child_count())
	await create_timer(0.3).timeout
	var image := viewport.get_texture().get_image()
	if image == null or image.get_size() != SIZE:
		push_error("Orthographic viewport failed to render at native sample size")
		quit(1)
		return
	var output := OUTPUT_DIR.path_join("center_east_orthographic_native_probe.png")
	if image.save_png(output) != OK:
		push_error("Failed to save orthographic probe")
		quit(1)
		return
	print("[ORTHO_PROBE] " + ProjectSettings.globalize_path(output))
	camera.size = 819.2 # 1.25x at a fixed orthographic world scale.
	for sample in [
		{"name": "center_river_1p25.png", "x": 1220.0},
		{"name": "double_cove_1p25.png", "x": 1940.0},
	]:
		camera.position.x = sample["x"]
		camera.look_at(Vector3(sample["x"], 0, DEPTH * 0.5))
		for frame in range(5):
			await process_frame
		var sample_path := OUTPUT_DIR.path_join(sample["name"])
		if viewport.get_texture().get_image().save_png(sample_path) != OK:
			push_error("Failed to save orthographic 1.25x probe")
			quit(1)
			return
		print("[ORTHO_PROBE] " + ProjectSettings.globalize_path(sample_path))
	quit(0)


func _material(path: String, tint: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.albedo_texture = load(path) as Texture2D
	material.roughness = roughness
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _add_terrain(world: Node3D) -> void:
	var materials := {
		"grass": _material(GRASS, Color(0.68, 0.71, 0.60), 0.95),
		"rock": _material(ROCK, Color(0.67, 0.66, 0.62), 0.96),
		"sand": _material(SAND, Color(0.78, 0.75, 0.66), 0.92),
		"water": _material(WATER, Color(0.28, 0.52, 0.72), 0.25),
	}
	var surfaces := {}
	for kind in materials:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surfaces[kind] = surface
	var cols := int(ceil(float(SIZE.x) / STEP))
	var rows := int(ceil(DEPTH / STEP))
	for row in range(rows):
		for col in range(cols):
			var x := float(col) * STEP
			var z := float(row) * STEP
			var center_x := x + STEP * 0.5
			var center_z := z + STEP * 0.5
			var kind := _biome(center_x, center_z)
			_add_cell(surfaces[kind], x, z, false)
			if _water_at(center_x, center_z):
				_add_cell(surfaces["water"], x, z, true)
	for kind in surfaces:
		var surface: SurfaceTool = surfaces[kind]
		surface.generate_normals()
		var mesh := MeshInstance3D.new()
		mesh.name = "Biome_" + String(kind)
		mesh.mesh = surface.commit()
		mesh.material_override = materials[kind]
		world.add_child(mesh)
		print("[ORTHO_MESH] ", kind, " vertices=", mesh.mesh.surface_get_array_len(0), " aabb=", mesh.get_aabb())
		print("[ORTHO_MESH] ", kind, " vertices=", mesh.mesh.surface_get_array_len(0))


func _add_cell(surface: SurfaceTool, x: float, z: float, water_plane: bool) -> void:
	var a := _vertex(x, z, water_plane)
	var b := _vertex(x + STEP, z, water_plane)
	var c := _vertex(x, z + STEP, water_plane)
	var d := _vertex(x + STEP, z + STEP, water_plane)
	for point in [a, c, b, b, c, d]:
		surface.set_uv(Vector2(point.x / 450.0, point.z / 450.0))
		surface.add_vertex(point)


func _vertex(x: float, z: float, water_plane: bool) -> Vector3:
	if water_plane:
		return Vector3(x, -5.0, z)
	return Vector3(x, _height_at(x, z), z)


func _shore_x(z: float) -> float:
	return 2920.0 - 445.0 * exp(-pow((z - 235.0) / 135.0, 2.0)) - 530.0 * exp(-pow((z - 795.0) / 170.0, 2.0))


func _river_distance(x: float, z: float) -> float:
	var river_x := 335.0 + 85.0 * sin(z / 165.0) + z * 0.28
	return abs(x - river_x)


func _water_at(x: float, z: float) -> bool:
	return x > _shore_x(z) or (z > 510.0 and _river_distance(x, z) < 46.0)


func _hill(x: float, z: float, cx: float, cz: float, sx: float, sz: float, amplitude: float) -> float:
	return amplitude * exp(-pow((x - cx) / sx, 2.0) - pow((z - cz) / sz, 2.0))


func _height_at(x: float, z: float) -> float:
	if _water_at(x, z):
		return -22.0
	var ridge := _hill(x, z, 1510, 155, 360, 145, 170)
	ridge += _hill(x, z, 2070, 340, 240, 200, 122)
	ridge += _hill(x, z, 2250, 1010, 265, 155, 110)
	ridge += _hill(x, z, 1020, 1015, 240, 125, 58)
	var fine := 3.4 * sin(x / 93.0) * cos(z / 77.0) + 2.2 * sin(x / 39.0 + z / 44.0)
	var shore_slope := -16.0 * exp(-pow((x - _shore_x(z)) / 95.0, 2.0))
	var river_slope := -13.0 * exp(-pow(_river_distance(x, z) / 80.0, 2.0)) if z > 500.0 else 0.0
	return ridge + fine + shore_slope + river_slope


func _biome(x: float, z: float) -> String:
	if _water_at(x, z):
		return "sand"
	if abs(x - _shore_x(z)) < 95.0:
		return "sand"
	if _height_at(x, z) > 46.0:
		return "rock"
	return "grass"
