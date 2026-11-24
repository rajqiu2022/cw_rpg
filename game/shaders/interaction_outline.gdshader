shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.45, 1.0, 0.68, 1.0);
uniform float outline_width = 3.0;
uniform float pulse = 0.0;
uniform float base_strength = 0.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	vec2 texel = TEXTURE_PIXEL_SIZE * outline_width;
	float nearby_alpha = 0.0;
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV + vec2(texel.x, 0.0)).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV - vec2(texel.x, 0.0)).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV + vec2(0.0, texel.y)).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV - vec2(0.0, texel.y)).a);
	float outline = clamp(nearby_alpha - base.a, 0.0, 1.0);
	float idle_breathe = base_strength * (0.72 + 0.18 * (sin(TIME * 3.2) * 0.5 + 0.5));
	float strength = mix(idle_breathe, 1.05, clamp(pulse, 0.0, 1.0));
	vec4 glow = outline_color * outline * strength;
	COLOR = base + glow * (1.0 - base.a);
}
