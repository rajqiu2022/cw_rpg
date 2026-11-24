shader_type canvas_item;
render_mode unshaded;

// Original local 2D river: architecture-only render target, never screen/HUD.
uniform sampler2D building_reflection : filter_linear, repeat_disable;
uniform vec2 reflection_source_size = vec2(3072.0, 560.0);
uniform float reflection_source_foot_y = 500.0;
uniform float reflection_bank_y = 620.0;
uniform float reflection_compression = 0.52;
uniform float reflection_strength = 0.20;
uniform vec4 shallow_color : source_color = vec4(0.255, 0.34, 0.325, 1.0);
uniform vec4 deep_color : source_color = vec4(0.14, 0.235, 0.25, 1.0);
uniform float visible_north_y = 644.0;
uniform float visible_south_y = 916.0;
uniform float wave_speed = 0.48;
uniform float wave_amplitude = 0.012;
uniform float specular_strength = 0.085;
uniform bool use_preview_time = false;
uniform float preview_time = 0.0;
varying vec2 water_world_px;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float noise2(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i+vec2(1.0,0.0)), u.x),
		mix(hash21(i+vec2(0.0,1.0)), hash21(i+vec2(1.0)), u.x), u.y);
}
vec4 reflection_sample(vec2 px) {
	vec2 uv = px / reflection_source_size;
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return vec4(0.0);
	return texture(building_reflection, uv);
}
vec4 soft_reflection(vec2 px) {
	// Five source-space taps soften walls; no full-screen mirror or floor copy.
	return reflection_sample(px)*0.36
		+reflection_sample(px+vec2(5.0,0.0))*0.16
		+reflection_sample(px-vec2(5.0,0.0))*0.16
		+reflection_sample(px+vec2(0.0,6.0))*0.16
		+reflection_sample(px-vec2(0.0,6.0))*0.16;
}
float local_ao(vec2 p, vec2 center) {
	vec2 q = (p-center)/vec2(24.0,20.0);
	return exp(-dot(q,q)*2.2);
}
void vertex() {
	water_world_px = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy;
}
void fragment() {
	vec2 p = water_world_px;
	float t = (use_preview_time ? preview_time : TIME) * wave_speed;
	float shore = max(0.0,min(p.y-visible_north_y,visible_south_y-p.y));
	float depth = smoothstep(0.0,60.0,shore);
	vec2 flow = vec2(p.x-t*7.0,p.y);
	float broad = noise2(flow*vec2(0.004,0.011));
	float breakup = noise2((p+vec2(t*5.0,-t*2.0))*vec2(0.018,0.033));
	float micro = noise2((p+vec2(-t*9.0,t*3.0))*vec2(0.052,0.07));
	// Near-horizontal 28px medium ripples + broken ~7px fine ripples.
	float medium_phase = p.y*0.2244 + broad*5.0 - t*0.65;
	float fine_phase = p.y*0.924-p.x*0.018 + breakup*8.0 + t*1.05;
	float medium = sin(medium_phase), fine = sin(fine_phase);
	vec3 normal = normalize(vec3(0.07*cos(fine_phase)*sin(breakup*6.28),
		0.20*cos(medium_phase)+0.12*cos(fine_phase),1.0));
	vec3 color = mix(shallow_color.rgb,deep_color.rgb,depth);
	color += (broad-0.5)*vec3(0.022,0.034,0.039);
	// Soft silver-grey open-sky reflection, modulated by actual ripple slope.
	float sky_weight = 0.06+0.035*(1.0-normal.z)+0.022*broad;
	color = mix(color,vec3(0.60,0.66,0.70),sky_weight);
	float spec = pow(max(0.0,dot(normal,normalize(vec3(-0.16,-0.19,1.0)))),64.0);
	spec *= 0.30+0.70*smoothstep(0.35,0.80,micro);
	float broken_ridge = pow(max(0.0,medium),10.0)*smoothstep(0.48,0.83,breakup)
		+pow(max(0.0,fine),16.0)*smoothstep(0.60,0.90,micro)*0.35;
	// Reflect five original buildings using WORLD x and the fixed 620->500 axis.
	float distance_to_source_bank = max(0.0,p.y-reflection_bank_y);
	vec2 reflection_px = vec2(p.x+normal.x*13.0,
		reflection_source_foot_y-distance_to_source_bank/reflection_compression+normal.y*9.0);
	vec4 reflected = soft_reflection(reflection_px);
	float fade = 1.0-smoothstep(22.0,210.0,distance_to_source_bank);
	float reflected_weight = reflection_strength*fade*reflected.a*(0.75+0.25*breakup);
	color = mix(color,reflected.rgb,reflected_weight);
	// Irregular 6..14px wet contact; sparse glints instead of a luminous edge.
	float wet_width = 6.0+8.0*noise2(vec2(p.x*0.033,4.0));
	float wet = 1.0-smoothstep(wet_width*0.25,wet_width,shore);
	color *= 1.0-wet*(0.08+0.06*micro);
	float contact_glint = wet*broken_ridge*smoothstep(0.70,0.93,breakup)*0.006;
	// Elliptical soft bridge cast + four local abutment contacts, NOT a rectangle.
	vec2 shadow_q = (p-vec2(1562.0,785.0))/vec2(106.0,187.0);
	float bridge_cast = exp(-dot(shadow_q,shadow_q)*2.0);
	float abutment = local_ao(p,vec2(1436.0,646.0))+local_ao(p,vec2(1636.0,646.0))
		+local_ao(p,vec2(1436.0,915.0))+local_ao(p,vec2(1636.0,915.0));
	color *= 1.0-bridge_cast*0.22-min(abutment,1.0)*0.19;
	color += vec3(0.76,0.82,0.84)*(spec*specular_strength+broken_ridge*wave_amplitude+contact_glint)*(1.0-bridge_cast*0.7);
	COLOR = vec4(clamp(color,vec3(0.0),vec3(1.0)),1.0);
}
