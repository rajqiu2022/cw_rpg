extends "res://scripts/dev/build_world_map_native_pair_ortho_v4.gd"

# Authored terrain heights and material zones share v2 road/shore topology.
# Only isolated candidate outputs are produced; no shipping scene references.
const GRASS_PH := "res://art/external/polyhaven/terrain/aerial_grass_rock_diff_4k.jpg"
const ROAD_PH := "res://art/external/polyhaven/terrain/rock_path_diff_4k.jpg"
const ROCK_MAT := "res://art/modules/world_map_v13/terrain_mat_rock_gravel_v1_candidate.png"
const WATER_MAT := "res://art/modules/world_map_v13/terrain_mat_coastal_water_v1_candidate.png"
const MACRO := "res://art/modules/world_map_v13/terrain_macro_ground_v2_candidate.png"


func _output_prefix() -> String:
	return "res://build/world_native_pair_ortho_v5_"


func _coast_distance(pixel: Vector2) -> float:
	var y := clampf(pixel.y, 0.0, float(SIZE.y - 1))
	return 2795.0 - 0.39 * y + 46.0 * sin(y * 0.0082) + 24.0 * sin(y * 0.021) - pixel.x


func _height(pixel: Vector2, topology: Image) -> float:
	# The RGBA topology alpha saturates at 128px inland. It cannot describe
	# inland elevation or a 245px shore taper; use the analytic distance here.
	var distance := _coast_distance(pixel)
	var western := 2.85 * exp(-pow((pixel.x - 560.0) / 270.0, 2.0) - pow((pixel.y - 230.0) / 185.0, 2.0))
	var heartland := 2.15 * exp(-pow((pixel.x - 1390.0) / 390.0, 2.0) - pow((pixel.y - 1030.0) / 270.0, 2.0))
	var eastern := 2.65 * exp(-pow((pixel.x - 2070.0) / 290.0, 2.0) - pow((pixel.y - 230.0) / 185.0, 2.0))
	var folds := 0.075 * sin(pixel.x * 0.010 + sin(pixel.y * 0.008)) + 0.045 * sin(pixel.y * 0.017 - pixel.x * 0.006)
	var sample := topology.get_pixel(clampi(roundi(pixel.x), 0, SIZE.x - 1), clampi(roundi(pixel.y), 0, SIZE.y - 1))
	var inland := maxf(0.0, western + heartland + eastern + folds) * smoothstep(85.0, 340.0, distance)
	var shore_bank := 0.32 * smoothstep(0.0, 72.0, distance)
	return shore_bank + maxf(0.0, inland - sample.g * 0.035)


func _walk_texture(topology: Image, walk: Texture2D) -> Texture2D:
	var image := walk.get_image()
	# Steep rocky shoulders are physical terrain, so they also block feet.
	# Low-resolution sampling is conservatively stamped in 4px cells.
	for y in range(0, SIZE.y, 4):
		for x in range(0, SIZE.x, 4):
			if image.get_pixel(x, y).r < 0.5:
				continue
			if topology.get_pixel(x, y).g > 0.02:
				continue
			var pixel := Vector2(x, y)
			var dx := (_height(pixel + Vector2(6, 0), topology) - _height(pixel - Vector2(6, 0), topology)) / (12.0 * 30.0 / SIZE.x)
			var dz := (_height(pixel + Vector2(0, 6), topology) - _height(pixel - Vector2(0, 6), topology)) / (12.0 * Z_HALF * 2.0 / SIZE.y)
			if Vector2(dx, dz).length() > 0.72:
				image.fill_rect(Rect2i(x, y, mini(4, SIZE.x - x), mini(4, SIZE.y - y)), Color.BLACK)
	return ImageTexture.create_from_image(image)


func _after_outputs_saved(topology: Image) -> void:
	var route: Array = []
	for x in range(32, 2320, 24):
		var total := 0.0
		var weighted_y := 0.0
		for y in SIZE.y:
			var coverage := topology.get_pixel(x, y).g
			total += coverage
			weighted_y += y * coverage
		if total <= 0.0:
			continue
		var point := Vector2(x, weighted_y / total)
		var projected_y := point.y - _height(point, topology) * SIZE.y / CAMERA_SIZE / sqrt(2.0)
		route.append([point.x, projected_y])
	var output := FileAccess.open(_output_prefix() + "route.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"road_feet": route, "height_west": _height(Vector2(560, 230), topology), "height_east": _height(Vector2(2070, 230), topology)}, "\t"))
	output.close()


func _mesh(topology: Image, flat: bool = false) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Padding lets raised foreground terrain continue beyond the camera crop.
	var lower := Vector2(-64, -224)
	var upper := Vector2(SIZE) + Vector2(64, 224)
	var grid := Vector2i(200, 92)
	for row in grid.y:
		for col in grid.x:
			var a := lower + (upper - lower) * Vector2(float(col) / grid.x, float(row) / grid.y)
			var d := lower + (upper - lower) * Vector2(float(col + 1) / grid.x, float(row + 1) / grid.y)
			var b := Vector2(d.x, a.y)
			var c := Vector2(a.x, d.y)
			for pixel in [a, c, b, b, c, d]:
				var dx := 0.0 if flat else (_height(pixel + Vector2(4, 0), topology) - _height(pixel - Vector2(4, 0), topology)) / (8.0 * 30.0 / SIZE.x)
				var dz := 0.0 if flat else (_height(pixel + Vector2(0, 4), topology) - _height(pixel - Vector2(0, 4), topology)) / (8.0 * Z_HALF * 2.0 / SIZE.y)
				surface.set_normal(Vector3(-dx, 1.0, -dz).normalized())
				surface.set_uv(pixel / Vector2(SIZE))
				surface.add_vertex(_point(pixel, topology, flat))
	surface.index()
	return surface.commit()


func _surface_material(color: Texture2D, selector: Texture2D, mask: bool) -> ShaderMaterial:
	if mask:
		return super._surface_material(color, selector, true)
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
uniform sampler2D topology_tex : filter_nearest;
uniform sampler2D grass_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D road_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D rock_tex : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D macro_tex : source_color, filter_linear;
varying vec3 terrain_normal;
void vertex() { terrain_normal = NORMAL; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float road_y(float x) {
 vec2 a=vec2(0,535); vec2 b=vec2(480,425);
 if(x>480.0){a=b;b=vec2(1120,455);}
 if(x>1120.0){a=b;b=vec2(1560,343);}
 if(x>1560.0){a=b;b=vec2(2110,514);}
 if(x>2110.0){a=b;b=vec2(2580,665);}
 float t=clamp((x-a.x)/(b.x-a.x),0.0,1.0);t=t*t*(3.0-2.0*t);
 return mix(a.y,b.y,t);
}
void fragment() {
 vec2 p=UV*vec2(3072.0,1024.0);
 vec4 topo=texture(topology_tex,clamp(UV,vec2(0),vec2(1)));
 if (topo.r<0.5) { discard; }
 float y=clamp(p.y,0.0,1023.0);
 float coast=2795.0-0.39*y+46.0*sin(y*0.0082)+24.0*sin(y*0.021)-p.x;
 float broad=noise(p/410.0); float detail=noise(p/27.0);
 vec3 grass_a=texture(grass_tex,p/930.0).rgb;
 vec3 grass_b=texture(grass_tex,(p.yx+vec2(213,417))/740.0).rgb;
 vec3 grass=mix(grass_a,grass_b,smoothstep(0.22,0.78,broad));
 vec3 macro=texture(macro_tex,clamp(UV,vec2(0),vec2(1))).rgb;
 grass=mix(grass*vec3(1.43,1.55,1.32),macro*vec3(1.00,1.05,0.94),0.28);
 vec3 road=texture(road_tex,p/560.0).rgb*vec3(1.79,1.63,1.38);
 // Fade the grass shoulder irregularly while preserving the authored route.
 float lateral=p.y-road_y(p.x)-11.0*sin(p.y*0.018);
 float road_dist=abs(lateral)+(noise(p/38.0)-0.5)*9.0;
 float coverage=(1.0-smoothstep(20.0,46.0,road_dist))*smoothstep(110.0,180.0,coast);
 float ruts=exp(-pow((abs(lateral)-11.0)/3.0,2.0));
 road*=1.02-0.08*ruts;
 vec3 land=mix(grass,road,coverage*0.88);
 vec3 rock=texture(rock_tex,(p+vec2(95,211))/700.0).rgb*vec3(0.95,0.99,0.98);
 float slope=1.0-normalize(terrain_normal).y;
 float exposed=smoothstep(0.05,0.30,slope)*(0.72+0.20*broad)*(1.0-coverage);
 float bank=(1.0-smoothstep(32.0,105.0,coast))*(0.90+0.10*detail);
 land=mix(land,rock,max(exposed,bank));
 land*=0.94+0.10*broad;
 ALBEDO=land; ROUGHNESS=1.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("topology_tex", selector)
	material.set_shader_parameter("grass_tex", load(GRASS_PH))
	material.set_shader_parameter("road_tex", load(ROAD_PH))
	material.set_shader_parameter("rock_tex", load(ROCK_MAT))
	material.set_shader_parameter("macro_tex", load(MACRO))
	return material


func _base_material(_color: Texture2D) -> Material:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled, unshaded;
uniform sampler2D water_tex : source_color, repeat_enable, filter_linear_mipmap;
void fragment() {
 vec2 p=UV*vec2(3072.0,1024.0);
 float y=clamp(p.y,0.0,1023.0);
 float distance=p.x-(2795.0-0.39*y+46.0*sin(y*0.0082)+24.0*sin(y*0.021));
 vec3 texture_color=texture(water_tex,p/1500.0).rgb;
 float foam=exp(-pow((distance-5.0)/9.0,2.0));
 vec3 water=mix(vec3(0.035,0.145,0.18),vec3(0.105,0.255,0.27),exp(-max(distance,0.0)/160.0));
 water*=0.72+texture_color.r*0.48;
 ALBEDO=mix(water,vec3(0.49,0.60,0.57),foam*0.60);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("water_tex", load(WATER_MAT))
	return material
