shader_type canvas_item;
render_mode unshaded;
uniform float contact_y = 644.0;
uniform bool south_bank = false;
varying vec2 bank_world_px;
varying vec4 bank_tint;
float hash21(vec2 p) {
	p=fract(p*vec2(123.34,456.21)); p+=dot(p,p+45.32); return fract(p.x*p.y);
}
float noise2(vec2 p) {
	vec2 i=floor(p),f=fract(p); vec2 u=f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1.0,0.0)),u.x),
		mix(hash21(i+vec2(0.0,1.0)),hash21(i+vec2(1.0)),u.x),u.y);
}
void vertex() {
	bank_world_px=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;
	bank_tint=COLOR;
}
void fragment() {
	vec4 stone=texture(TEXTURE,UV)*bank_tint;
	float distance_from_water=south_bank ? max(0.0,bank_world_px.y-contact_y) : max(0.0,contact_y-bank_world_px.y);
	float stain_height=6.0+8.0*noise2(vec2(bank_world_px.x*0.036,6.0));
	float wet=1.0-smoothstep(stain_height*0.25,stain_height,distance_from_water);
	float patches=noise2(bank_world_px*vec2(0.082,0.075));
	stone.rgb*=1.0-wet*(0.20+0.16*patches);
	stone.rgb=mix(stone.rgb,stone.rgb*vec3(0.91,1.0,0.94),wet*0.4);
	COLOR=stone;
}
