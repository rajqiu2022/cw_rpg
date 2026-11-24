shader_type canvas_item;
render_mode unshaded;

// Blend two unmodified native materials in world space. No tiled repetition,
// raster repainting, painted-on buildings, or generated cliffs are involved.
uniform sampler2D earth_tex : source_color, filter_linear;
uniform sampler2D rock_tex : source_color, filter_linear;

float segment_distance(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	return length(p - a - ab * clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0));
}

void fragment() {
	vec2 p = UV * vec2(2560.0, 1760.0);
	vec2 native_uv = UV * vec2(1.0, 0.6875);
	vec4 earth = texture(earth_tex, native_uv);
	vec4 rock = texture(rock_tex, native_uv);
	float d = segment_distance(p, vec2(500.0, 1760.0), vec2(930.0, 1460.0));
	d = min(d, segment_distance(p, vec2(930.0, 1460.0), vec2(1280.0, 1240.0)));
	d = min(d, segment_distance(p, vec2(1280.0, 1240.0), vec2(1280.0, 650.0)));
	d = min(d, segment_distance(p, vec2(1280.0, 650.0), vec2(1880.0, 390.0)));
	d = min(d, segment_distance(p, vec2(1880.0, 390.0), vec2(2360.0, 390.0)));
	float road = 1.0 - smoothstep(158.0, 264.0, d + (earth.r - earth.b) * 45.0);
	float water_bay = 1.0 - smoothstep(0.74, 1.08, length((p - vec2(650.0, 1340.0)) / vec2(430.0, 210.0)));
	float cargo_bay = 1.0 - smoothstep(0.7, 1.1, length((p - vec2(1860.0, 1355.0)) / vec2(480.0, 220.0)));
	float tower_path = 1.0 - smoothstep(70.0, 130.0, segment_distance(p, vec2(1240.0, 630.0), vec2(530.0, 810.0)));
	float material_mix = max(road, max(tower_path, max(water_bay, cargo_bay)));
	COLOR = vec4(mix(rock.rgb * 0.89, earth.rgb, material_mix), 1.0);
}
