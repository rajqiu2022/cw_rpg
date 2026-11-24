shader_type canvas_item;
uniform sampler2D earth_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D dirt_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D path_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
float segment(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/max(dot(v,v),.001),0.,1.));}
void fragment(){float path=0.;
path=max(path,1.-smoothstep(81.00,135.00,segment(p,vec2(300.0,1500.0),vec2(3800.0,1500.0))));
path=max(path,1.-smoothstep(51.00,85.00,segment(p,vec2(700.0,1500.0),vec2(700.0,1000.0))));
path=max(path,1.-smoothstep(51.00,85.00,segment(p,vec2(1850.0,1500.0),vec2(1850.0,950.0))));
path=max(path,1.-smoothstep(51.00,85.00,segment(p,vec2(3100.0,1500.0),vec2(3100.0,1000.0))));
path=max(path,1.-smoothstep(51.00,85.00,segment(p,vec2(700.0,1500.0),vec2(700.0,2250.0))));
path=max(path,1.-smoothstep(51.00,85.00,segment(p,vec2(700.0,2250.0),vec2(2300.0,2350.0))));
path=max(path,1.-smoothstep(51.00,85.00,segment(p,vec2(2300.0,2350.0),vec2(3600.0,2350.0))));
path=max(path,1.-smoothstep(51.00,85.00,segment(p,vec2(3600.0,2350.0),vec2(3600.0,1500.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(1220.0,935.0),vec2(1340.0,1070.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(2490.0,935.0),vec2(2610.0,1070.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(3600.0,965.0),vec2(3720.0,1100.0))));
vec3 grass=texture(earth_tex,p/1000.).rgb;vec3 stone=mix(texture(dirt_tex,p/650.).rgb,texture(path_tex,p/280.).rgb,.18);COLOR=vec4(mix(grass,stone,path*.94),1.);}
