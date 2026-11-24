shader_type canvas_item;
render_mode unshaded;

// Project-original 2D water. Coordinates are world pixels, never screen UV.
uniform vec4 shallow_color : source_color = vec4(0.39, 0.43, 0.34, 1.0);
uniform vec4 deep_color : source_color = vec4(0.20, 0.29, 0.255, 1.0);
uniform float bank_north_y = 620.0;
uniform float bank_south_y = 940.0;
uniform float shallow_width_px = 64.0;
uniform float wave_amplitude = 0.024;
uniform float wave_speed = 0.35;
uniform float shore_glint = 0.018;
uniform vec4 bridge_shadow_rect = vec4(1450.0, 616.0, 208.0, 348.0);
uniform float bridge_shadow_strength = 0.24;
uniform bool use_preview_time = false;
uniform float preview_time = 0.0;
varying vec2 water_world_px;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float soft_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0)), u.x), u.y);
}

void vertex() {
	water_world_px = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float t = (use_preview_time ? preview_time : TIME) * wave_speed;
	vec2 p = water_world_px;
	float shore_distance = max(0.0, min(p.y - bank_north_y, bank_south_y - p.y));
	float depth = smoothstep(0.0, shallow_width_px, shore_distance);
	vec3 color = mix(shallow_color.rgb, deep_color.rgb, depth);
	// Slowly advected, broad irregular tone; no stretched source water bitmap.
	float broad = soft_noise(p * vec2(0.005, 0.013) + vec2(t * 0.055, -t * 0.04));
	float breakup = soft_noise(p * vec2(0.017, 0.024) + vec2(-t * 0.065, t * 0.03));
	color += (broad - 0.5) * 0.045;
	// Two low-amplitude, noise-broken families: not uniform white sine stripes.
	float a = sin(p.x * 0.023 + p.y * 0.19 + broad * 5.0 - t);
	float b = sin(p.x * -0.041 + p.y * 0.29 + breakup * 6.0 + t * 0.63);
	float thin = pow(max(0.0, a), 12.0) * smoothstep(0.30, 0.72, breakup);
	float fine = pow(max(0.0, b), 18.0) * smoothstep(0.48, 0.82, broad);
	color += vec3(0.75, 0.85, 0.73) * wave_amplitude * (thin + fine * 0.45);
	color -= (1.0 - depth) * (0.014 + breakup * 0.01);
	// Restrained broken glint close to stone, no foam ribbons or white surf.
	float shore = 1.0 - smoothstep(6.0, 32.0, shore_distance);
	color += vec3(0.7, 0.76, 0.62) * shore_glint * shore * thin;
	// Soft eastward bridge shadow, applied ONLY to the water polygon.
	vec2 center = bridge_shadow_rect.xy + bridge_shadow_rect.zw * 0.5;
	vec2 q = abs(p - center) - bridge_shadow_rect.zw * 0.5;
	float outside = length(max(q, vec2(0.0)));
	float shadow = 1.0 - smoothstep(0.0, 26.0, outside);
	color *= 1.0 - shadow * bridge_shadow_strength;
	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), 1.0);
}
