extends SceneTree

const BOULDER := "res://art/external/polyhaven/boulder_01/boulder_01_1k.gltf"
const GROUND_SOURCE := "res://../assets/raw/external/polyhaven/aerial_grass_rock/aerial_grass_rock_diff_4k.jpg"
const OUTPUT := "res://build/world_map_v13_cc0_ground_lab.png"


func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	var boulder_scene := load(BOULDER) as PackedScene
	var ground_image := Image.load_from_file(ProjectSettings.globalize_path(GROUND_SOURCE))
	if boulder_scene == null or ground_image == null or ground_image.is_empty():
		push_error("CC0 ground lab source missing")
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1536, 1024)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.29, 0.33, 0.25)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.72, 0.77, 0.81)
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	world.add_child(environment)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(18.0, 18.0)
	ground.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_texture = ImageTexture.create_from_image(ground_image)
	ground_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ground.material_override = ground_material
	world.add_child(ground)
	var rock := boulder_scene.instantiate()
	rock.position = Vector3(0.0, 0.074, 0.0)
	world.add_child(rock)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	light.light_energy = 1.8
	light.shadow_enabled = true
	world.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.0
	camera.position = Vector3(-1.0, 9.0, 10.0)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	for frame in range(20):
		await process_frame
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(OUTPUT) != OK:
		push_error("Could not save CC0 ground lab")
		quit(1)
		return
	print("[WorldGroundCC0Lab] ", OUTPUT)
	viewport.queue_free()
	await process_frame
	quit(0)
