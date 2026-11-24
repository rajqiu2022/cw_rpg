shader_type canvas_item;

// The blade and scabbard share a continuous halo drawn from the art silhouette.
uniform bool sheathed = false;
uniform bool compact_ready_wrap = false;
uniform float phase = 0.0;
uniform vec2 texel = vec2(0.001);
uniform bool custom_palette = false;
uniform vec3 tint = vec3(0.44, 0.76, 1.0);
uniform float glow_end = 0.725;
uniform bool paired_tips = false;
uniform vec2 blade_span = vec2(0.0);
uniform vec2 hilt_span = vec2(0.0);
uniform float intensity = 1.0;

void fragment() {
	vec2 art_uv = UV;
	// Only shorten the wrapped middle of the handle in the ready pose.
	// The blade, guard and pommel retain their original shape.
	const float wrap_start = 1117.0 / 1536.0;
	const float wrap_end = 1323.0 / 1536.0;
	const float wrap_ratio = 0.62;
	float shortened_end = wrap_start + (wrap_end - wrap_start) * wrap_ratio;
	if (compact_ready_wrap && UV.y > wrap_start) {
		art_uv.y = UV.y < shortened_end
			? wrap_start + (UV.y - wrap_start) / wrap_ratio
			: UV.y + (wrap_end - shortened_end);
	}
	vec4 art = art_uv.y <= 1.0 ? texture(TEXTURE, art_uv) : vec4(0.0);
	float longitudinal = 1.0 - smoothstep(glow_end - 0.04, glow_end, UV.y);
	if (paired_tips) {
		longitudinal = max(1.0 - smoothstep(0.20, 0.36, UV.y), smoothstep(0.64, 0.80, UV.y));
	}
	bool full_blade = blade_span.y > blade_span.x;
	bool hilt_only = hilt_span.y > hilt_span.x;
	if (full_blade) {
		longitudinal = smoothstep(blade_span.x - 0.02, blade_span.x + 0.018, UV.y);
		longitudinal *= 1.0 - smoothstep(blade_span.y - 0.022, blade_span.y + 0.012, UV.y);
	}
	float sweep = pow(0.5 + 0.5 * cos(UV.y * 14.0 + phase), 3.0);
	float pigment = smoothstep(0.035, 0.18, art.b - art.r);
	float emissive = sheathed ? pigment * (0.29 + 0.34 * sweep) : 0.22 + 0.41 * sweep;
	vec3 cyan = mix(vec3(0.44, 0.76, 1.0), vec3(0.88, 0.98, 1.0), sweep);
	if (custom_palette) {
		cyan = mix(tint, mix(tint, vec3(1.0), 0.62), sweep);
		emissive = sheathed ? 0.08 + 0.19 * sweep : 0.17 + 0.34 * sweep;
	}
	float strength = intensity;
	if (full_blade) {
		emissive = sheathed ? 0.32 + 0.23 * sweep : 0.31 + 0.30 * sweep;
		cyan = mix(custom_palette ? tint : vec3(0.44, 0.76, 1.0), vec3(1.0), 0.24);
		strength = min(intensity, 1.12);
	}
	if (hilt_only) {
		float handle_uv = (UV.y - hilt_span.x) / max(hilt_span.y - hilt_span.x, 0.0001);
		longitudinal = 1.0 - smoothstep(0.52, 0.90, handle_uv);
		emissive = 0.25 + 0.24 * sweep;
	}
	vec3 lit = mix(art.rgb, cyan, min(0.90, emissive * longitudinal * strength));

	// A soft fringe hugs the actual silhouette instead of drawing a line over the hilt.
	float near_alpha = 0.0;
	float far_alpha = 0.0;
	for (int i = -3; i <= 3; i++) {
		float f = float(i);
		near_alpha += texture(TEXTURE, UV + vec2(f * texel.x * 7.0, 0.0)).a / 7.0;
		far_alpha += texture(TEXTURE, UV + vec2(f * texel.x * 16.0, 0.0)).a / 7.0;
	}
	float halo = longitudinal * (0.44 * near_alpha + 0.31 * far_alpha);
	halo *= (0.77 + 0.23 * sweep) * (sheathed ? 0.52 : 1.0);
	if (full_blade) {
		halo = longitudinal * ((sheathed ? 0.32 : 0.46) * near_alpha + (sheathed ? 0.20 : 0.33) * far_alpha);
		halo *= (0.89 + 0.11 * sweep) * (sheathed ? 0.76 : 1.0);
	}
	float exposed = min(1.0, halo * strength) * (1.0 - art.a);
	float alpha = art.a + exposed;
	vec3 halo_tint = custom_palette ? tint : vec3(0.18, 0.65, 1.0);
	if (full_blade) {
		halo_tint = cyan;
	}
	vec3 rgb = (lit * art.a + halo_tint * exposed) / max(alpha, 0.0001);
	COLOR = vec4(rgb, alpha);
}
