shader_type canvas_item;
// Existing texture only. One whole author rect, not one repeating texture tile.
uniform vec2 ap_rect_size_world = vec2(1.0);
uniform float ap_source_to_world = 1.0;
uniform float ap_feather_world = 32.0;
uniform float ap_core_opacity = 0.66;
varying vec2 ap_rect_position_world;

void vertex() {
	ap_rect_position_world = VERTEX * ap_source_to_world;
}

void fragment() {
	vec2 ap_edge = min(ap_rect_position_world, ap_rect_size_world - ap_rect_position_world);
	float ap_width = min(ap_feather_world, min(ap_rect_size_world.x, ap_rect_size_world.y) * 0.45);
	float ap_coverage = smoothstep(0.0, ap_width, min(ap_edge.x, ap_edge.y));
	COLOR = texture(TEXTURE, UV) * COLOR;
	COLOR.a *= ap_coverage * ap_core_opacity;
}
