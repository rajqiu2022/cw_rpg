extends "res://scripts/dev/build_world_map_native_pair_ortho_v5.gd"

# Art iteration only. Author broad ridge changes and a restrained palette;
# retain the shared coast/road source and render navigation with the geometry.


func _output_prefix() -> String:
	return "res://build/world_native_pair_ortho_v6_"


func _height(pixel: Vector2, topology: Image) -> float:
	var height := super._height(pixel, topology)
	var sample := topology.get_pixel(clampi(roundi(pixel.x), 0, SIZE.x - 1), clampi(roundi(pixel.y), 0, SIZE.y - 1))
	# Keep the authored road stable; modulation belongs to the rocky shoulders.
	var off_road := 1.0 - smoothstep(0.0, 0.08, sample.g)
	var ridge := 0.15 * sin(pixel.x * 0.023 + pixel.y * 0.011) + 0.09 * sin(pixel.x * 0.008 - pixel.y * 0.027)
	var hill_weight := smoothstep(0.6, 1.8, height)
	return maxf(0.0, height + ridge * hill_weight * off_road)


func _surface_material(color: Texture2D, selector: Texture2D, mask: bool) -> ShaderMaterial:
	var material := super._surface_material(color, selector, mask)
	if mask:
		return material
	var source := material.shader.code
	source = source.replace("vec3(1.43,1.55,1.32)", "vec3(1.14,1.36,1.34)")
	source = source.replace("macro*vec3(1.00,1.05,0.94),0.28", "macro*vec3(0.91,1.02,1.04),0.18")
	source = source.replace("vec3 road=", "grass=mix(vec3(0.22,0.28,0.17),grass,0.78);\n vec3 road=")
	source = source.replace("vec3(1.79,1.63,1.38)", "vec3(1.62,1.58,1.45)")
	source = source.replace("vec3(0.95,0.99,0.98)", "vec3(0.80,0.88,0.87)")
	# Streaks follow ridge structure rather than a circular bare-rock ring.
	source = source.replace("(0.72+0.20*broad)", "(0.57+0.24*noise(vec2(p.x/150.0+p.y/210.0,p.y/72.0)))")
	material.shader.code = source
	return material
