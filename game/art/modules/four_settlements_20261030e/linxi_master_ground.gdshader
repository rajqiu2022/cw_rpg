shader_type canvas_item;
uniform sampler2D earth_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D dirt_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D path_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
float segment(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/max(dot(v,v),.001),0.,1.));}
void fragment(){float path=0.;
path=max(path,1.-smoothstep(78.00,130.00,segment(p,vec2(1450.0,2210.0),vec2(1450.0,1690.0))));
path=max(path,1.-smoothstep(78.00,130.00,segment(p,vec2(1450.0,1690.0),vec2(1150.0,1330.0))));
path=max(path,1.-smoothstep(78.00,130.00,segment(p,vec2(1150.0,1330.0),vec2(1150.0,1100.0))));
path=max(path,1.-smoothstep(78.00,130.00,segment(p,vec2(1150.0,1100.0),vec2(1150.0,900.0))));
path=max(path,1.-smoothstep(51.00,85.00,segment(p,vec2(1450.0,1690.0),vec2(2050.0,1800.0))));
path=max(path,1.-smoothstep(51.00,85.00,segment(p,vec2(2050.0,1800.0),vec2(2220.0,1450.0))));
path=max(path,1.-smoothstep(51.00,85.00,segment(p,vec2(2220.0,1450.0),vec2(2050.0,1300.0))));
path=max(path,1.-smoothstep(51.00,85.00,segment(p,vec2(2050.0,1300.0),vec2(2050.0,1100.0))));
path=max(path,1.-smoothstep(51.00,85.00,segment(p,vec2(2050.0,1100.0),vec2(2050.0,940.0))));
path=max(path,1.-smoothstep(.85,1.,length((p-vec2(1450.0,1690.0))/vec2(480.0,300.0))));
vec3 grass=texture(earth_tex,p/1000.).rgb;vec3 stone=mix(texture(dirt_tex,p/650.).rgb,texture(path_tex,p/280.).rgb,.18);COLOR=vec4(mix(grass,stone,path*.94),1.);}
