extends SceneTree

# Single-source two-region terrain experiment. No world-map scene references it.
# The 3072x1024 terrain topology is generated once; visuals and walk mask use
# that same pixel source, then split at x=1536 without re-rendering either half.
const SIZE := Vector2i(3072, 1024)
const GRASS := "res://art/modules/world_map_v13/terrain_mat_dry_grass_v1_candidate.png"
const ROAD := "res://art/modules/world_map_v13/terrain_mat_beach_sand_v1_candidate.png"
const ROCK := "res://art/modules/world_map_v13/terrain_mat_rock_gravel_v1_candidate.png"
const WATER := "res://art/modules/world_map_v13/terrain_mat_coastal_water_v1_candidate.png"
const CLIFF_BLOCK_WIDTH := 82.0


func _initialize() -> void:
	call_deferred("_build")


func _output_prefix() -> String:
	return "res://build/world_native_pair_shared_v1_"


func _macro_ground_path() -> String:
	return ""


func _macro_blend() -> float:
	return 0.0


func _water_tint() -> Color:
	return Color(0.41, 0.68, 0.77)


func _relief_strength() -> float:
	return 0.0


func _coast_x(y: float) -> float:
	return 2795.0 - 0.39 * y + 46.0 * sin(y * 0.0082) + 24.0 * sin(y * 0.021)


func _road_y(x: float) -> float:
	var stops := [Vector2(0, 535), Vector2(480, 425), Vector2(1120, 455), Vector2(1560, 343), Vector2(2110, 514), Vector2(2580, 665)]
	for index in range(stops.size() - 1):
		var a: Vector2 = stops[index]
		var b: Vector2 = stops[index + 1]
		if x <= b.x:
			var t := clampf((x - a.x) / (b.x - a.x), 0.0, 1.0)
			var smooth_t := t * t * (3.0 - 2.0 * t)
			return lerpf(a.y, b.y, smooth_t)
	return stops[-1].y


func _build_topology() -> Image:
	var topology := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	var road_centers := PackedFloat32Array()
	road_centers.resize(SIZE.x)
	for x in SIZE.x:
		road_centers[x] = _road_y(float(x))
	for y in SIZE.y:
		var shore := _coast_x(float(y))
		var road_wiggle := 11.0 * sin(float(y) * 0.018)
		for x in SIZE.x:
			var dist := shore - float(x)
			var road_distance := absf(float(y) - road_centers[x] - road_wiggle)
			var road_coverage := 1.0 - smoothstep(27.0, 39.0, road_distance)
			if dist < 110.0:
				road_coverage = 0.0
			var land := 1.0 if dist >= 0.0 else 0.0
			var distance_band := clampf((dist + 128.0) / 256.0, 0.0, 1.0)
			topology.set_pixel(x, y, Color(land, road_coverage, 0.0, distance_band))
	return topology


func _build_walk(topology: Image) -> Image:
	var walk := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	for y in SIZE.y:
		for x in SIZE.x:
			var signed_distance := topology.get_pixel(x, y).a * 256.0 - 128.0
			walk.set_pixel(x, y, Color.WHITE if signed_distance >= CLIFF_BLOCK_WIDTH else Color.BLACK)
	return walk


func _make_visual_viewport(topology: Image) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var canvas := ColorRect.new()
	canvas.size = Vector2(SIZE)
	viewport.add_child(canvas)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D topology_tex : source_color, filter_nearest;
uniform sampler2D grass_tex : source_color, repeat_enable;
uniform sampler2D road_tex : source_color, repeat_enable;
uniform sampler2D rock_tex : source_color, repeat_enable;
uniform sampler2D water_tex : source_color, repeat_enable;
uniform sampler2D macro_tex : source_color;
uniform float macro_blend = 0.0;
uniform float relief_strength = 0.0;
uniform vec3 water_tint = vec3(0.41, 0.68, 0.77);
float noise(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float terrain_height(vec2 p) {
	float western = 1.12 * exp(-dot((p - vec2(620.0, 180.0)) / vec2(380.0, 260.0), (p - vec2(620.0, 180.0)) / vec2(380.0, 260.0)));
	float heartland = 0.87 * exp(-dot((p - vec2(1420.0, 760.0)) / vec2(490.0, 330.0), (p - vec2(1420.0, 760.0)) / vec2(490.0, 330.0)));
	float eastern = 0.95 * exp(-dot((p - vec2(2110.0, 190.0)) / vec2(340.0, 260.0), (p - vec2(2110.0, 190.0)) / vec2(340.0, 260.0)));
	float folds = 0.16 * sin(p.x * 0.0072 + sin(p.y * 0.0045)) + 0.11 * sin(p.y * 0.011 - p.x * 0.0037);
	return western + heartland + eastern + folds;
}
void fragment() {
	vec2 p = UV * vec2(3072.0, 1024.0);
	vec4 topo = texture(topology_tex, UV);
	float coast_dist = topo.a * 256.0 - 128.0;
	float broad = 0.5 + 0.22 * sin(p.x * 0.0042 + sin(p.y * 0.0061)) + 0.18 * sin(p.y * 0.0082 - p.x * 0.0021);
	float patch = smoothstep(0.25, 0.68, broad);
	vec3 grass_a = texture(grass_tex, p / 860.0).rgb;
	vec3 grass_b = texture(grass_tex, (p.yx + vec2(391.0, 147.0)) / 690.0).rgb;
	vec3 grass = mix(grass_a, grass_b, 0.24 + 0.20 * patch) * mix(vec3(0.78, 0.83, 0.67), vec3(0.85, 0.86, 0.70), patch);
	vec3 macro_ground = texture(macro_tex, UV).rgb;
	grass = mix(grass, macro_ground * vec3(0.94, 0.95, 0.87), macro_blend);
	vec3 road = texture(road_tex, p / 780.0).rgb * vec3(0.89, 0.76, 0.55);
	float road_coverage = topo.g * smoothstep(94.0, 130.0, coast_dist);
	vec3 land = mix(grass, road, road_coverage * 0.92);
	vec2 terrain_slope = vec2(terrain_height(p + vec2(6.0, 0.0)) - terrain_height(p - vec2(6.0, 0.0)), terrain_height(p + vec2(0.0, 6.0)) - terrain_height(p - vec2(0.0, 6.0))) / 12.0;
	vec3 terrain_normal = normalize(vec3(-terrain_slope * 620.0, 1.0));
	float daylight = clamp(dot(terrain_normal, normalize(vec3(-0.46, -0.65, 0.83))), 0.15, 1.0);
	float relief_light = 0.66 + 0.42 * daylight;
	float hill_foot = clamp((terrain_height(p) - terrain_height(p - vec2(32.0, 46.0))) * 0.36, -0.08, 0.08);
	float road_lip = 4.0 * topo.g * (1.0 - topo.g) * smoothstep(94.0, 130.0, coast_dist);
	float relief = relief_light - hill_foot - road_lip * 0.065;
	land *= mix(1.0, relief, relief_strength * smoothstep(100.0, 270.0, coast_dist));
	vec3 cliff = texture(rock_tex, p / 740.0).rgb * vec3(0.77, 0.76, 0.68);
	float cliff_strength = 1.0 - smoothstep(0.0, 87.0, coast_dist);
	land = mix(land, cliff * (0.76 + coast_dist * 0.0022), cliff_strength);
	vec3 water = texture(water_tex, p / 960.0).rgb * water_tint;
	water *= 0.93 + 0.05 * sin(p.x * 0.024 + p.y * 0.010);
	float foam = exp(-pow((coast_dist + 7.0) / 9.0, 2.0));
	water = mix(water, vec3(0.72, 0.81, 0.78), foam * 0.50);
	COLOR = vec4(mix(water, land, topo.r), 1.0);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("topology_tex", ImageTexture.create_from_image(topology))
	material.set_shader_parameter("grass_tex", load(GRASS))
	material.set_shader_parameter("road_tex", load(ROAD))
	material.set_shader_parameter("rock_tex", load(ROCK))
	material.set_shader_parameter("water_tex", load(WATER))
	if not _macro_ground_path().is_empty():
		material.set_shader_parameter("macro_tex", load(_macro_ground_path()))
	material.set_shader_parameter("macro_blend", _macro_blend())
	material.set_shader_parameter("relief_strength", _relief_strength())
	material.set_shader_parameter("water_tint", Vector3(_water_tint().r, _water_tint().g, _water_tint().b))
	canvas.material = material
	return viewport


func _save_split(visual: Image) -> bool:
	var half_width := SIZE.x / 2
	var center := Image.create(half_width, SIZE.y, false, Image.FORMAT_RGBA8)
	var coast := Image.create(half_width, SIZE.y, false, Image.FORMAT_RGBA8)
	visual.convert(Image.FORMAT_RGBA8)
	center.blit_rect(visual, Rect2i(0, 0, half_width, SIZE.y), Vector2i.ZERO)
	coast.blit_rect(visual, Rect2i(half_width, 0, half_width, SIZE.y), Vector2i.ZERO)
	return center.save_png(_output_prefix() + "center.png") == OK and coast.save_png(_output_prefix() + "coast.png") == OK


func _build() -> void:
	var required_paths := [GRASS, ROAD, ROCK, WATER]
	if not _macro_ground_path().is_empty():
		required_paths.append(_macro_ground_path())
	for path in required_paths:
		if not ResourceLoader.exists(path):
			push_error("Material missing: " + path)
			quit(1)
			return
	var topology := _build_topology()
	var walk := _build_walk(topology)
	var viewport := _make_visual_viewport(topology)
	for frame in 12:
		await process_frame
	var visual := viewport.get_texture().get_image()
	if topology.save_png(_output_prefix() + "topology.png") != OK or walk.save_png(_output_prefix() + "walk.png") != OK or visual.save_png(_output_prefix() + "visual.png") != OK or not _save_split(visual):
		push_error("Could not save shared-source terrain outputs")
		quit(1)
		return
	print("[WorldNativePairShared] visuals/navigation from one 3072x1024 topology; center/coast cropped from same render")
	viewport.queue_free()
	await process_frame
	quit(0)
