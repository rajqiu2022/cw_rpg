extends SceneTree

const SOURCE := "res://art/external/polyhaven/boulder_01/boulder_01_1k.gltf"
const OUTPUT_DIR := "res://build/world_map_v13_cc0_render"
const ADOPTED_SPRITE := "res://art/modules/world_map_v13/boulder_01_cc0_southwest_v1.png"
const CONTACT_SEPARATED_SPRITE := "res://art/modules/world_map_v13/boulder_01_cc0_southwest_v2.png"
const VIEW_SIZE := Vector2i(768, 768)


func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	if not ResourceLoader.exists(SOURCE):
		push_error("CC0 boulder source was not imported: %s" % SOURCE)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var packed_scene := load(SOURCE) as PackedScene
	if packed_scene == null:
		push_error("CC0 boulder glTF did not load")
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = VIEW_SIZE
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	world.add_child(packed_scene.instantiate())
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.72, 0.77, 0.81)
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	light.light_energy = 1.8
	world.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.8
	camera.position = Vector3(-3.2, 2.5, 5.4)
	world.add_child(camera)
	camera.look_at(Vector3(-0.10, 0.35, 0.0))
	camera.current = true
	for frame in range(12):
		await process_frame
	var image := viewport.get_texture().get_image()
	var visible_rect := image.get_used_rect()
	if visible_rect.size.x < 200 or visible_rect.size.y < 200:
		push_error("CC0 boulder render has no usable transparent cutout")
		quit(1)
		return
	visible_rect = visible_rect.grow(12).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var cutout := image.get_region(visible_rect)
	# The model is rendered without a floor. Add only a soft contact shadow to
	# the transparent prop, otherwise it appears to float over the terrain.
	var sprite := Image.create(cutout.get_width() + 40, cutout.get_height() + 40, false, Image.FORMAT_RGBA8)
	sprite.fill(Color.TRANSPARENT)
	var center := Vector2(sprite.get_width() * 0.50, cutout.get_height() * 0.97 + 16.0)
	var radius := Vector2(cutout.get_width() * 0.40, 25.0)
	for y in range(sprite.get_height()):
		for x in range(sprite.get_width()):
			var distance := pow((float(x) - center.x) / radius.x, 2.0) + pow((float(y) - center.y) / radius.y, 2.0)
			if distance < 1.0:
				var opacity := 0.48 * pow(1.0 - distance, 2.0)
				sprite.set_pixel(x, y, Color(0.08, 0.07, 0.05, opacity))
	sprite.blend_rect(cutout, Rect2i(Vector2i.ZERO, cutout.get_size()), Vector2i(20, 8))
	# New layered-map variant: keep the rock alone. The Field object contract
	# owns its ground shadow so the silhouette cannot hover over a baked oval.
	var isolated := Image.create(cutout.get_width() + 24, cutout.get_height() + 24, false, Image.FORMAT_RGBA8)
	isolated.fill(Color.TRANSPARENT)
	isolated.blend_rect(cutout, Rect2i(Vector2i.ZERO, cutout.get_size()), Vector2i(12, 10))
	var preview := OUTPUT_DIR.path_join("boulder_01_southwest_v1.png")
	if image.save_png(preview) != OK or sprite.save_png(ADOPTED_SPRITE) != OK or isolated.save_png(CONTACT_SEPARATED_SPRITE) != OK:
		push_error("Could not export CC0 boulder sprite")
		quit(1)
		return
	print("[CC0Boulder] original=", ADOPTED_SPRITE, " layered=", CONTACT_SEPARATED_SPRITE, " ", isolated.get_size())
	viewport.queue_free()
	await process_frame
	quit(0)
