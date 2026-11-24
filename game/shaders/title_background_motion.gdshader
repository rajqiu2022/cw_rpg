shader_type canvas_item;
render_mode unshaded;

float soft_oval(vec2 uv, vec2 center, vec2 radii) {
	return 1.0 - smoothstep(0.35, 1.0, length((uv - center) / radii));
}

void fragment() {
	vec2 uv = UV;
	vec4 base = texture(TEXTURE, uv);
	// Use the existing painted cloud texture, never move the title or foreground character.
	float valley = soft_oval(uv, vec2(0.66, 0.68), vec2(0.333, 0.228));
	float cloud = smoothstep(0.37, 0.69, base.b) * smoothstep(0.27, 0.64, base.g);
	vec2 drift = vec2(0.0022 * sin(TIME * 0.34), 0.0009 * cos(TIME * 0.31 + uv.x * 10.0));
	vec3 mist = texture(TEXTURE, uv + drift).rgb;
	float dawn = soft_oval(uv, vec2(0.719, 0.487), vec2(0.18, 0.086));
	vec3 breath = vec3(0.040, 0.025, 0.010) * dawn * (0.5 + 0.5 * sin(TIME * 0.45));
	COLOR = vec4(mix(base.rgb, mist, valley * cloud * 0.36) + breath, base.a);
}
