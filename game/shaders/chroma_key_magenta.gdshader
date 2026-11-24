shader_type canvas_item;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float magenta = smoothstep(0.78, 0.96, color.r) * smoothstep(0.78, 0.96, color.b) * (1.0 - smoothstep(0.08, 0.24, color.g));
	COLOR = vec4(color.rgb, color.a * (1.0 - magenta));
}
