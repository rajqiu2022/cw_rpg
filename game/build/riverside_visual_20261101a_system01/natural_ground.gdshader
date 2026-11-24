shader_type canvas_item;
render_mode unshaded;

uniform sampler2D earth_tex : source_color, repeat_enable, filter_linear;
uniform sampler2D dirt_tex : source_color, repeat_enable, filter_linear;
uniform sampler2D stone_tex : source_color, repeat_enable, filter_linear;
uniform vec4 route_segments[32];
uniform vec2 route_widths[32];
uniform int segment_count = 0;
varying vec2 ground_point;

void vertex() {
	// Local map pixels, before either the main camera or miniature transform.
	ground_point = VERTEX;
}

void fragment() {
	vec2 p = ground_point;
	vec3 earth = texture(earth_tex, p / 1000.0).rgb;
	vec3 dirt = texture(dirt_tex, p / 650.0).rgb;
	vec3 stone = texture(stone_tex, p / 280.0).rgb;
	// Texture-derived erosion, not repeated Line2D UVs or per-pixel hash noise.
	float broad = smoothstep(0.28, 0.60, dot(texture(earth_tex, p / 1960.0 + vec2(0.31, 0.67)).rgb, vec3(0.299, 0.587, 0.114)));
	float broken = smoothstep(0.20, 0.58, dot(texture(dirt_tex, p / 470.0 + vec2(0.63, 0.17)).rgb, vec3(0.299, 0.587, 0.114)));
	float signed_distance = 100000.0;
	for (int i = 0; i < 32; i++) {
		if (i >= segment_count) {
			break;
		}
		vec2 a = route_segments[i].xy;
		vec2 v = route_segments[i].zw - a;
		float t = clamp(dot(p - a, v) / max(dot(v, v), 0.001), 0.0, 1.0);
		float radius = mix(route_widths[i].x, route_widths[i].y, t);
		float distance_to_verge = length(p - a - v * t) - radius;
		// One distance-field union: intersections never double-darken or form rings.
		signed_distance = min(signed_distance, distance_to_verge);
	}
	float erosion = (broad - 0.5) * 32.0 + (broken - 0.5) * 16.0;
	float edge_width = max(fwidth(signed_distance), 1.0);
	float path = 1.0 - smoothstep(-24.0 - edge_width, 38.0 + edge_width, signed_distance + erosion);
	// Existing Linxi native earth/gravel recipe; no brown tint or dark edge layer.
	vec3 verge = mix(earth, dirt, 0.035 + broad * 0.14);
	vec3 worn = mix(dirt, stone, 0.18);
	float wear = path * (0.72 + broad * 0.17);
	COLOR = vec4(mix(verge, worn, wear), 1.0);
}
