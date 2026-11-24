shader_type canvas_item;

uniform sampler2D armor_surface : source_color, filter_linear_mipmap;
uniform vec4 frame_window;
uniform bool mirror_material = false;

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	vec2 local_uv = (UV - frame_window.xy) / frame_window.zw;
	float warm = smoothstep(0.055, 0.14, original.r - original.b);
	float skin_light = smoothstep(0.29, 0.50, original.r);
	float coverage = warm * skin_light;
	vec2 surface_uv = vec2(mirror_material ? 1.0 - local_uv.x : local_uv.x, local_uv.y);
	vec3 armor = texture(armor_surface, vec2(0.23, 0.11) + surface_uv * vec2(0.36, 0.43)).rgb;
	float shading = dot(original.rgb, vec3(0.299, 0.587, 0.114));
	vec3 fitted = armor * (0.66 + shading * 0.44);
	COLOR = vec4(fitted, original.a * coverage);
}
