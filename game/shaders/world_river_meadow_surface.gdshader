shader_type canvas_item;
render_mode unshaded;

uniform sampler2D river_detail : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D meadow_detail : source_color, repeat_enable, filter_linear_mipmap;
varying vec2 world_px;

float n2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	vec4 h = fract(sin(vec4(dot(i, vec2(127.1,311.7)), dot(i+vec2(1,0),vec2(127.1,311.7)),
		dot(i+vec2(0,1),vec2(127.1,311.7)), dot(i+1.0,vec2(127.1,311.7)))) * 43758.5453);
	return mix(mix(h.x,h.y,f.x),mix(h.z,h.w,f.x),f.y);
}

void vertex() {
	world_px = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	float patch = n2(world_px / 234.0);
	float small = n2(world_px / 32.0);
	float fine = n2(world_px / 9.0);
	float green = src.g - src.r;
	float teal = src.b - src.r;
	// The world mask and travel routes stay authoritative. Break up the
	// transition within the painted shallows, not the solid collision line.
	float edge_warp = (small - 0.50) * 0.037 + (patch - 0.50) * 0.05;
	float bank_chroma = teal + edge_warp * (1.0 - smoothstep(0.045, 0.10, teal));
	float water = smoothstep(0.006, 0.087, bank_chroma) * smoothstep(0.14, 0.24, src.g);
	float meadow = smoothstep(0.029, 0.078, green) * smoothstep(0.29, 0.49, src.g) * (1.0 - smoothstep(-0.20, 0.02, teal));
	float bank = smoothstep(-0.13, -0.03, bank_chroma) * (1.0-smoothstep(-0.012,0.052,bank_chroma)) * smoothstep(0.23,0.30,src.g) * (1.0-smoothstep(0.40,0.52,src.g));
	vec3 soil = mix(vec3(0.48,0.43,0.25), vec3(0.34,0.42,0.22), smoothstep(0.26,0.70,patch));
	vec3 meadow_tex = texture(meadow_detail, world_px / 730.0).rgb;
	vec3 land = mix(src.rgb, mix(src.rgb * (0.76 + 0.48 * patch), soil, 0.30) + (meadow_tex - vec3(0.42,0.43,0.32)) * 0.30, meadow * 0.88);
	land = mix(land, mix(vec3(0.28,0.32,0.21), vec3(0.49,0.43,0.29), small * 0.68 + fine * 0.32), bank * (0.43 + 0.28 * patch));
	vec2 drift = vec2(TIME * 0.007, -TIME * 0.004);
	vec2 warp = vec2(n2(world_px / 103.0), n2(world_px / 89.0 + 17.0)) * 0.12;
	vec3 a = texture(river_detail, world_px / vec2(620.0,425.0) + drift + warp).rgb;
	vec3 b = texture(river_detail, world_px / vec2(910.0,590.0) - drift * 0.5 + vec2(0.44,0.31)).rgb;
	vec3 ripples = mix(a,b,0.37);
	vec3 pool = mix(vec3(0.11,0.24,0.23), vec3(0.21,0.38,0.37), 0.18 + 0.70 * patch);
	pool += (ripples - vec3(0.29,0.39,0.36)) * 0.61;
	float shoal = (1.0-smoothstep(0.041,0.098,bank_chroma)) * water * (0.24 + small * 0.39);
	pool = mix(pool, vec3(0.34,0.42,0.32), shoal);
	COLOR = vec4(mix(land,pool,water*0.96), src.a);
}
