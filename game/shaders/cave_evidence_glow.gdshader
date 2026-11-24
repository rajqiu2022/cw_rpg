shader_type canvas_item;

uniform float pulse = 0.0;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec4 prop = texture(TEXTURE, UV);
	vec2 d = TEXTURE_PIXEL_SIZE * 12.0;
	float a = prop.a;
	float outer = 0.0;
	float inner = 1.0;
	for (int i = 0; i < 8; i++) {
		float angle = float(i) * 0.785398;
		float neighbor = texture(TEXTURE, UV + d * vec2(cos(angle), sin(angle))).a;
		outer = max(outer, neighbor);
		inner = min(inner, neighbor);
	}
	float breath = 0.78 + 0.22 * sin(TIME * 2.8);
	float energy = mix(0.33, 0.94, pulse) * breath;
	vec3 gold = vec3(1.0, 0.69, 0.28);
	float halo = max(0.0, outer - a) * energy;
	float alpha = a + halo * (1.0 - a);
	vec3 base = mix(prop.rgb, gold, max(0.0, a - inner) * energy * 0.63);
	COLOR = vec4((base * a + gold * halo * (1.0 - a)) / max(alpha, 0.0001), alpha) * vertex_tint;
}
