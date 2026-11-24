shader_type canvas_item;
varying vec2 ground_point;
float grain(vec2 p) { return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453); }
float noise(vec2 p) {
	vec2 cell=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(grain(cell),grain(cell+vec2(1,0)),f.x),mix(grain(cell+vec2(0,1)),grain(cell+vec2(1,1)),f.x),f.y);
}
void vertex() { ground_point=VERTEX; }
void fragment() {
	vec4 tex=texture(TEXTURE,UV);
	float edge=abs(UV.y*2.0-1.0);
	float rough=noise(ground_point/29.0);
	float feather=1.0-smoothstep(0.52+rough*0.20,0.96,edge);
	COLOR=vec4(tex.rgb*vec3(0.83,0.84,0.79),tex.a*feather*0.92)*COLOR;
}
