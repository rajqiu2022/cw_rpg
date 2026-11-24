shader_type canvas_item;
// Existing complete source only; no second TEXTURE sample and no tile-local alpha.
uniform vec2 ap_rect_size_world = vec2(1.0);
uniform float ap_source_to_world = 1.0;
uniform float ap_feather_world = 32.0;
uniform float ap_core_opacity = 0.66;
// Authored use: left, top, right, bottom widths. Entire original rect stays fixed.
uniform vec4 ap_edge_widths_world = vec4(32.0);
uniform float ap_wear_world = 8.0;
uniform vec2 ap_world_origin = vec2(0.0);
uniform vec4 ap_material_tone : source_color = vec4(0.55, 0.56, 0.53, 1.0);
uniform float ap_texture_contrast = 0.42;
varying vec2 ap_rect_position_world;

void vertex() {
	ap_rect_position_world = VERTEX * ap_source_to_world;
}

void fragment() {
	vec2 p = ap_rect_position_world;
	vec4 edge = vec4(p.x, p.y, ap_rect_size_world.x-p.x, ap_rect_size_world.y-p.y);
	vec4 cap = vec4(ap_rect_size_world.x, ap_rect_size_world.y, ap_rect_size_world.x, ap_rect_size_world.y)*0.45;
	vec4 widths = min(max(ap_edge_widths_world,vec4(1.0)),cap);
	float coverage = 1.0;
	// The interior has no alpha noise. Edge wear is static, world-anchored and
	// smoothly varies over ~140-400world pixels, never per repeating stone tile.
	if (min(min(edge.x,edge.y),min(edge.z,edge.w)) < max(max(widths.x,widths.y),max(widths.z,widths.w))+ap_wear_world) {
		vec2 world = p+ap_world_origin;
		float worn = 0.5+0.25*sin(dot(world,vec2(0.019,0.013))+0.7)+0.25*sin(dot(world,vec2(0.041,-0.027))+2.1);
		float inset = max(ap_wear_world,0.0)*(0.35+0.65*worn);
		vec4 coverage_by_edge = smoothstep(vec4(inset),widths+vec4(inset),edge);
		coverage = coverage_by_edge.x*coverage_by_edge.y*coverage_by_edge.z*coverage_by_edge.w;
	}
	// COLOR already contains source texture exactly once. Compress only its
	// contrast around a purpose-specific neutral tone; preserve true stone detail.
	COLOR.rgb = mix(ap_material_tone.rgb,COLOR.rgb,clamp(ap_texture_contrast,0.0,1.0));
	COLOR.a *= coverage*ap_core_opacity;
}
