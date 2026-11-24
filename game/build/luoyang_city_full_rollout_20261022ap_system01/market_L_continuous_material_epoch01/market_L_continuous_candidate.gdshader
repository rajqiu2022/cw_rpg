shader_type canvas_item;
// One shared stone sample: vertex UV shift aligns both original Sprite regions.
// The only fading boundary is this authored six-segment L UNION exterior.
uniform vec2 ap_rect_size_world = vec2(1.0); // Legacy binding; not a fade boundary.
uniform float ap_source_to_world = 0.25;
uniform vec2 ap_source_size = vec2(1536.0, 1024.0);
uniform vec2 ap_world_origin = vec2(0.0);
uniform vec4 ap_union_segments[6];
uniform float ap_feather_world = 32.0; // Legacy binding; widths below are used.
uniform vec4 ap_edge_widths_world = vec4(28.0, 20.0, 28.0, 20.0);
uniform float ap_wear_world = 6.0;
uniform vec4 ap_material_tone : source_color = vec4(0.56, 0.57, 0.54, 1.0);
uniform float ap_texture_contrast = 0.46;
uniform float ap_core_opacity = 0.50;
varying vec2 ap_world_position;

void vertex() {
	ap_world_position = ap_world_origin + VERTEX * ap_source_to_world;
	UV += ap_world_origin / (ap_source_size * ap_source_to_world);
}

float ap_segment_distance(vec2 point, vec4 segment) {
	vec2 line = segment.zw - segment.xy;
	float along = clamp(dot(point - segment.xy, line) / max(dot(line, line), 0.0001), 0.0, 1.0);
	return length(point - (segment.xy + along * line));
}

void fragment() {
	float worn = 0.5 + 0.25 * sin(dot(ap_world_position, vec2(0.019, 0.013)) + 0.7)
		+ 0.25 * sin(dot(ap_world_position, vec2(0.041, -0.027)) + 2.1);
	float inset = max(ap_wear_world, 0.0) * (0.35 + 0.65 * worn);
	float coverage = 1.0;
	for (int index = 0; index < 6; index++) {
		vec4 segment = ap_union_segments[index];
		bool vertical = abs(segment.z - segment.x) < 0.0001;
		float width = vertical ? min(ap_edge_widths_world.x, ap_edge_widths_world.z)
			: min(ap_edge_widths_world.y, ap_edge_widths_world.w);
		coverage = min(coverage, smoothstep(inset, max(width, 1.0) + inset,
			ap_segment_distance(ap_world_position, segment)));
	}
	// COLOR already includes the complete repeating texture once. Never sample
	// TEXTURE again or multiply the source texture into itself.
	COLOR.rgb = mix(ap_material_tone.rgb, COLOR.rgb, clamp(ap_texture_contrast, 0.0, 1.0));
	COLOR.a *= coverage * ap_core_opacity;
}
