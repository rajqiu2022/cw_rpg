shader_type canvas_item;
uniform vec2 source_size;
uniform vec2 clip_points[128];
uniform int clip_counts[32];
uniform int clip_owners[32];
uniform int polygon_count = 0;
uniform int part_index = -1;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
	vec2 p = UV * source_size;
	int owner = -1;
	int offset = 0;
	for (int poly = 0; poly < 32; poly++) {
		if (poly >= polygon_count) { break; }
		int count = clip_counts[poly];
		bool inside = false;
		for (int i = 0; i < 128; i++) {
			if (i >= count) { break; }
			int j = i == 0 ? count - 1 : i - 1;
			vec2 a = clip_points[offset + i];
			vec2 b = clip_points[offset + j];
			if ((a.y > p.y) != (b.y > p.y)) {
				float crossing = (b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x;
				if (p.x < crossing) { inside = !inside; }
			}
		}
		if (inside) { owner = max(owner, clip_owners[poly]); }
		offset += count;
	}
	// Disjoint ownership: every native source pixel is drawn exactly once,
	// including semi-transparent edges/shadows. No default-texture double tint.
	if (owner == part_index) { COLOR = texture(TEXTURE, UV) * vertex_tint; }
	else { COLOR = vec4(0.0); }
}
