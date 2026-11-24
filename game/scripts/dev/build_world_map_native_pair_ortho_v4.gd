extends SceneTree

# Fixed-camera 3D terrain probe over the same v2 two-region topology. The
# terrain and its navigation silhouette are rendered through one camera, then
# split from the same full frame. This is an isolated visual candidate only.
const SIZE := Vector2i(3072, 1024)
const SOURCE_PREFIX := "res://build/world_native_pair_shared_v2_"
const OUTPUT_PREFIX := "res://build/world_native_pair_ortho_v4_"
const CAMERA_SIZE := 10.0
const Z_HALF := 7.0710678
const COLS := 192
const ROWS := 64


func _initialize() -> void:
	call_deferred("_build")


func _output_prefix() -> String:
	return OUTPUT_PREFIX


func _base_material(color: Texture2D) -> Material:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = color
	return material


func _walk_texture(_topology: Image, walk: Texture2D) -> Texture2D:
	return walk


func _after_outputs_saved(_topology: Image) -> void:
	pass


func _height(pixel: Vector2, topology: Image) -> float:
	var western := 1.00 * exp(-pow((pixel.x - 620.0) / 390.0, 2.0) - pow((pixel.y - 180.0) / 280.0, 2.0))
	var heartland := 0.78 * exp(-pow((pixel.x - 1420.0) / 520.0, 2.0) - pow((pixel.y - 760.0) / 340.0, 2.0))
	var eastern := 0.82 * exp(-pow((pixel.x - 2110.0) / 370.0, 2.0) - pow((pixel.y - 190.0) / 280.0, 2.0))
	var folds := 0.10 * sin(pixel.x * 0.008 + sin(pixel.y * 0.004)) + 0.07 * sin(pixel.y * 0.012 - pixel.x * 0.004)
	var sample := topology.get_pixel(clampi(roundi(pixel.x), 0, SIZE.x - 1), clampi(roundi(pixel.y), 0, SIZE.y - 1))
	var coast_distance := sample.a * 256.0 - 128.0
	var shore_taper := smoothstep(58.0, 245.0, coast_distance)
	var road_relief := lerpf(1.0, 0.55, sample.g)
	return maxf(0.0, western + heartland + eastern + folds) * shore_taper * road_relief


func _point(pixel: Vector2, topology: Image, flat: bool = false) -> Vector3:
	return Vector3((pixel.x / SIZE.x - 0.5) * 30.0, 0.0 if flat else _height(pixel, topology), (pixel.y / SIZE.y - 0.5) * Z_HALF * 2.0)


func _mesh(topology: Image, flat: bool = false) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in ROWS:
		for col in COLS:
			var uv0 := Vector2(float(col) / COLS, float(row) / ROWS)
			var uv1 := Vector2(float(col + 1) / COLS, float(row + 1) / ROWS)
			var a := Vector2(uv0.x, uv0.y)
			var b := Vector2(uv1.x, uv0.y)
			var c := Vector2(uv0.x, uv1.y)
			var d := Vector2(uv1.x, uv1.y)
			for uv in [a, c, b, b, c, d]:
				surface.set_uv(uv)
				surface.add_vertex(_point(uv * Vector2(SIZE), topology, flat))
	surface.index()
	surface.generate_normals()
	return surface.commit()


func _surface_material(color: Texture2D, selector: Texture2D, mask: bool) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = "shader_type spatial;\nrender_mode cull_disabled, depth_draw_opaque" + (", unshaded;\n" if mask else ";\n") + """
uniform sampler2D color_tex : source_color, filter_linear;
uniform sampler2D selector_tex : source_color, filter_nearest;
uniform bool mask_pass = false;
void fragment() {
	vec4 selector = texture(selector_tex, UV);
	if (selector.r < 0.5) { discard; }
	ALBEDO = mask_pass ? vec3(1.0) : texture(color_tex, UV).rgb;
	ROUGHNESS = 1.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("color_tex", color)
	material.set_shader_parameter("selector_tex", selector)
	material.set_shader_parameter("mask_pass", mask)
	return material


func _make_viewport(color: Texture2D, selector: Texture2D, topology: Image, mask: bool) -> SubViewport:
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
	settings.background_color = Color.BLACK if mask else Color(0.08, 0.19, 0.24)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color.WHITE
	settings.ambient_light_energy = 0.62
	environment.environment = settings
	world.add_child(environment)
	if not mask:
		var base := MeshInstance3D.new()
		base.mesh = _mesh(topology, true)
		base.material_override = _base_material(color)
		base.position.y = -0.03
		world.add_child(base)
	var land := MeshInstance3D.new()
	land.mesh = _mesh(topology)
	land.material_override = _surface_material(color, selector, mask)
	world.add_child(land)
	if not mask:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-55.0, -34.0, 0.0)
		light.light_energy = 1.15
		# Shadow-map acne produces a repeating diagonal grid at this vast scale.
		# Contact shadows belong to separately placed foreground props instead.
		light.shadow_enabled = false
		world.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = CAMERA_SIZE
	camera.position = Vector3(0.0, 12.0, 12.0)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	return viewport


func _read_png(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	return image if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK else null


func _save_pair(image: Image, suffix: String) -> bool:
	if image.save_png(_output_prefix() + suffix + ".png") != OK:
		return false
	var center := image.get_region(Rect2i(0, 0, SIZE.x / 2, SIZE.y))
	var coast := image.get_region(Rect2i(SIZE.x / 2, 0, SIZE.x / 2, SIZE.y))
	var stem := "" if suffix == "visual" else "_" + suffix
	return center.save_png(_output_prefix() + "center" + stem + ".png") == OK and coast.save_png(_output_prefix() + "coast" + stem + ".png") == OK


func _build() -> void:
	var color_path := SOURCE_PREFIX + "visual.png"
	var topology := _read_png(SOURCE_PREFIX + "topology.png")
	var walk_path := SOURCE_PREFIX + "walk.png"
	if topology == null or not ResourceLoader.exists(color_path) or not ResourceLoader.exists(walk_path):
		push_error("Build/import the v2 single-source pair before the orthographic lab")
		quit(1)
		return
	var color := load(color_path) as Texture2D
	var walk := load(walk_path) as Texture2D
	var visual_viewport := _make_viewport(color, ImageTexture.create_from_image(topology), topology, false)
	var mask_viewport := _make_viewport(color, _walk_texture(topology, walk), topology, true)
	var land_viewport := _make_viewport(color, ImageTexture.create_from_image(topology), topology, true)
	for frame in range(24):
		await process_frame
	var visual := visual_viewport.get_texture().get_image()
	var mask_image := mask_viewport.get_texture().get_image()
	var land_image := land_viewport.get_texture().get_image()
	if visual == null or mask_image == null or land_image == null:
		push_error("Orthographic map rendering requires a graphics driver; run with --rendering-driver opengl3")
		quit(1)
		return
	if not _save_pair(visual, "visual") or not _save_pair(mask_image, "walk") or not _save_pair(land_image, "land"):
		push_error("Could not save orthographic terrain candidate")
		quit(1)
		return
	_after_outputs_saved(topology)
	print("[WorldNativePairOrtho] shared fixed-camera terrain, crop and navigation rendered: ", _output_prefix())
	visual_viewport.queue_free()
	mask_viewport.queue_free()
	land_viewport.queue_free()
	await process_frame
	quit(0)
