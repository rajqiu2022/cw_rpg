shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec4 outer_color : source_color = vec4(1.0, 0.18, 0.015, 1.0);
uniform vec4 middle_color : source_color = vec4(1.0, 0.55, 0.04, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.94, 0.52, 1.0);
uniform float speed : hint_range(0.1, 3.0) = 1.0;
uniform float phase : hint_range(0.0, 20.0) = 0.0;
uniform float opacity : hint_range(0.0, 1.0) = 0.92;


float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}


float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	local = local * local * (3.0 - 2.0 * local);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}


float fbm(vec2 p) {
	float result = 0.0;
	float amplitude = 0.55;
	for (int octave = 0; octave < 4; octave++) {
		result += value_noise(p) * amplitude;
		p = p * 2.03 + vec2(13.1, 7.7);
		amplitude *= 0.48;
	}
	return result;
}


void fragment() {
	vec2 uv = UV;
	float height = 1.0 - uv.y;
	float time = TIME * speed + phase;
	float moving_noise = fbm(vec2(uv.x * 3.4, uv.y * 4.6 - time * 1.65));
	float fine_noise = value_noise(vec2(uv.x * 9.0 + time * 0.18, uv.y * 10.0 - time * 2.4));

	float sway = sin(height * 8.0 + time * 2.1) * 0.026;
	sway += (moving_noise - 0.5) * mix(0.025, 0.14, height);
	float center_x = 0.5 + sway;
	float half_width = mix(0.43, 0.035, pow(height, 0.72));
	float horizontal = 1.0 - smoothstep(half_width * 0.56, half_width, abs(uv.x - center_x));

	float tip_height = 0.78 + (moving_noise - 0.5) * 0.22 + sin(time * 2.7 + uv.x * 6.0) * 0.045;
	float vertical = smoothstep(0.0, 0.075, height) * (1.0 - smoothstep(tip_height, tip_height + 0.12, height));
	float broken_edge = smoothstep(0.10, 0.72, moving_noise + fine_noise * 0.30 + (1.0 - height) * 0.20);
	float outer = horizontal * vertical * mix(0.68, 1.0, broken_edge);

	// Two shorter side tongues stop the silhouette reading as one rubber cone.
	float left_center = 0.31 + sin(time * 2.5 + 1.2) * 0.035 + (moving_noise - 0.5) * 0.035;
	float left_width = mix(0.22, 0.018, smoothstep(0.0, 0.58, height));
	float left_side = 1.0 - smoothstep(left_width * 0.52, left_width, abs(uv.x - left_center));
	left_side *= smoothstep(0.0, 0.07, height) * (1.0 - smoothstep(0.43 + moving_noise * 0.08, 0.58, height));
	float right_center = 0.69 + sin(time * 2.1 + 4.6) * 0.032 - (moving_noise - 0.5) * 0.030;
	float right_width = mix(0.20, 0.016, smoothstep(0.0, 0.68, height));
	float right_side = 1.0 - smoothstep(right_width * 0.50, right_width, abs(uv.x - right_center));
	right_side *= smoothstep(0.0, 0.07, height) * (1.0 - smoothstep(0.52 + fine_noise * 0.07, 0.69, height));
	outer = max(outer, max(left_side * 0.88, right_side * 0.82));

	float inner_width = half_width * mix(0.48, 0.68, 1.0 - height);
	float inner_horizontal = 1.0 - smoothstep(inner_width * 0.48, inner_width, abs(uv.x - center_x * 0.985 - 0.006));
	float inner_tip = 0.48 + moving_noise * 0.12;
	float inner_vertical = smoothstep(0.0, 0.09, height) * (1.0 - smoothstep(inner_tip, inner_tip + 0.15, height));
	float core = inner_horizontal * inner_vertical;

	vec3 color = mix(outer_color.rgb, middle_color.rgb, smoothstep(0.08, 0.72, outer));
	color = mix(color, core_color.rgb, smoothstep(0.28, 0.94, core));
	float alpha = max(outer * 0.82, core) * opacity;
	alpha *= mix(0.82, 1.0, fine_noise);
	COLOR = vec4(color, alpha);
}
