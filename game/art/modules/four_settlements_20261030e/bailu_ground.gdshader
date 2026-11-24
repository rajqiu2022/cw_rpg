shader_type canvas_item;
uniform sampler2D earth_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D dirt_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D path_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
float segment(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/max(dot(v,v),.001),0.,1.));}
void fragment(){float path=0.;
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(620.0,2600.0),vec2(1150.0,2550.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(1150.0,2550.0),vec2(1150.0,1970.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(1150.0,1970.0),vec2(1720.0,1970.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(1720.0,1970.0),vec2(2450.0,1970.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(1150.0,1970.0),vec2(1150.0,1180.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(1150.0,1180.0),vec2(1750.0,1430.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(1750.0,1430.0),vec2(2500.0,1360.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(2500.0,1360.0),vec2(2930.0,1360.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(1720.0,1970.0),vec2(1720.0,2360.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(1720.0,2360.0),vec2(2500.0,2260.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(2500.0,2260.0),vec2(2930.0,2260.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(1150.0,1180.0),vec2(2150.0,1010.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(2150.0,1010.0),vec2(2450.0,1010.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(2450.0,1010.0),vec2(2450.0,2260.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(1500.0,865.0),vec2(1620.0,1000.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(550.0,1315.0),vec2(670.0,1450.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(1370.0,2855.0),vec2(1490.0,2990.0))));
vec3 grass=texture(earth_tex,p/1000.).rgb;vec3 stone=mix(texture(dirt_tex,p/650.).rgb,texture(path_tex,p/280.).rgb,.18);COLOR=vec4(mix(grass,stone,path*.94),1.);}
