shader_type canvas_item;
uniform sampler2D earth_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D dirt_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D path_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
float segment(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/max(dot(v,v),.001),0.,1.));}
void fragment(){float path=0.;
path=max(path,1.-smoothstep(81.00,135.00,segment(p,vec2(400.0,2420.0),vec2(1200.0,2440.0))));
path=max(path,1.-smoothstep(81.00,135.00,segment(p,vec2(1200.0,2440.0),vec2(1290.0,1750.0))));
path=max(path,1.-smoothstep(81.00,135.00,segment(p,vec2(1290.0,1750.0),vec2(1600.0,1620.0))));
path=max(path,1.-smoothstep(81.00,135.00,segment(p,vec2(1600.0,1620.0),vec2(2480.0,1650.0))));
path=max(path,1.-smoothstep(81.00,135.00,segment(p,vec2(2480.0,1650.0),vec2(3320.0,1650.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(1290.0,1750.0),vec2(1150.0,1280.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(1150.0,1280.0),vec2(1650.0,1040.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(1650.0,1040.0),vec2(1650.0,840.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(2480.0,1650.0),vec2(2840.0,1300.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(2840.0,1300.0),vec2(2840.0,1160.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(2480.0,1650.0),vec2(2510.0,2290.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(2510.0,2290.0),vec2(2790.0,2210.0))));
path=max(path,1.-smoothstep(63.00,105.00,segment(p,vec2(2480.0,1650.0),vec2(2480.0,1000.0))));
path=max(path,1.-smoothstep(63.00,105.00,segment(p,vec2(2480.0,1000.0),vec2(2840.0,750.0))));
path=max(path,1.-smoothstep(63.00,105.00,segment(p,vec2(2840.0,750.0),vec2(3070.0,400.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(1190.0,775.0),vec2(1310.0,910.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(650.0,705.0),vec2(770.0,840.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(2260.0,2525.0),vec2(2380.0,2660.0))));
vec3 grass=texture(earth_tex,p/1000.).rgb;vec3 stone=mix(texture(dirt_tex,p/650.).rgb,texture(path_tex,p/280.).rgb,.18);COLOR=vec4(mix(grass,stone,path*.94),1.);}
