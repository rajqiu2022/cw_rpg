shader_type canvas_item;

// Use the existing ground tile for grain and broad damp spots, not brick joints.
void fragment() {
	vec3 grit = texture(TEXTURE, UV).rgb;
	vec3 broad = texture(TEXTURE, UV * 0.28).rgb;
	float grain = dot(grit, vec3(0.299, 0.587, 0.114));
	float patch = smoothstep(0.18, 0.54, dot(broad, vec3(0.299, 0.587, 0.114)));
	float crust = clamp(0.20 + 0.47 * grain + patch * 0.33, 0.0, 1.0);
	COLOR = vec4(mix(vec3(0.48, 0.46, 0.39), vec3(0.94, 0.92, 0.83), crust), 1.0);
}
