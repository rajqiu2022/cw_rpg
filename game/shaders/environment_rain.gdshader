shader_type canvas_item;
render_mode unshaded, blend_mix;

// Two rain depths share one fullscreen quad. The sparse pattern is generated
// once by FieldWalkableController and sampled twice here. This avoids rebuilding
// several pseudo-random hashes for every screen pixel on every frame, which was
// especially expensive while a painted background was also moving.
uniform vec4 rain_color : source_color = vec4(0.68, 0.82, 0.88, 1.0);
uniform sampler2D rain_pattern : repeat_enable, filter_linear;
uniform float intensity : hint_range(0.0, 1.0) = 0.62;
uniform float speed : hint_range(0.1, 3.0) = 1.0;
uniform float slant : hint_range(-1.0, 1.0) = 0.18;
uniform float aspect_ratio : hint_range(0.5, 4.0) = 1.7778;
uniform float phase : hint_range(0.0, 100.0) = 0.0;


float rain_depth(vec2 uv, vec2 tiling, float time_scale, float phase_offset) {
	vec2 sample_uv = vec2(uv.x * aspect_ratio, uv.y) * tiling;
	// Apply the authored wind in texture space and keep horizontal drift coupled
	// to the fall speed so streaks do not slide sideways independently.
	sample_uv.x -= sample_uv.y * slant;
	// UVs must move opposite to the desired on-screen motion. Subtracting Y
	// makes the visible rain fall downward; the previous positive offset made
	// the texture appear to climb upward.
	sample_uv += vec2(-TIME * speed * slant * 0.20, -TIME * speed * time_scale + phase * phase_offset);
	return texture(rain_pattern, sample_uv).a;
}


void fragment() {
	vec2 uv = UV;
	float far_rain = rain_depth(uv, vec2(2.35, 2.70), 0.92, 0.011);
	float near_rain = rain_depth(uv + vec2(0.173, 0.071), vec2(1.48, 1.82), 1.34, 0.019);
	float depth_alpha = far_rain * 0.34 + near_rain * 0.66;
	// Slightly soften the rain toward the horizon; foreground streaks stay crisp.
	float depth_fade = mix(0.62, 1.0, smoothstep(0.08, 0.90, uv.y));
	float alpha = clamp(depth_alpha * intensity * depth_fade, 0.0, 0.82);
	vec3 color = mix(rain_color.rgb * 0.76, rain_color.rgb, near_rain);
	COLOR = vec4(color, alpha);
}
