shader_type canvas_item;
uniform sampler2D earth_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D dirt_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D path_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
float segment(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/max(dot(v,v),.001),0.,1.));}
void fragment(){float path=0.;
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(1900.0,3450.0),vec2(1900.0,3070.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(1900.0,3070.0),vec2(1900.0,2500.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(1900.0,2500.0),vec2(1900.0,2250.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(1900.0,2250.0),vec2(1900.0,2020.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(1900.0,2020.0),vec2(1900.0,1720.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(1900.0,1720.0),vec2(2150.0,1720.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(2150.0,1720.0),vec2(3000.0,1720.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(3000.0,1720.0),vec2(3250.0,1580.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(3250.0,1580.0),vec2(3250.0,1350.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(3250.0,1350.0),vec2(3250.0,1140.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(1900.0,2500.0),vec2(4000.0,2500.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(4000.0,2500.0),vec2(4000.0,2250.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(4000.0,2250.0),vec2(4120.0,2100.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(4120.0,2100.0),vec2(4120.0,1600.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(4120.0,1600.0),vec2(3950.0,1600.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(3950.0,1600.0),vec2(3950.0,1350.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(3950.0,1350.0),vec2(3950.0,1150.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(1900.0,2020.0),vec2(2140.0,2120.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(2140.0,2120.0),vec2(3000.0,2120.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(3000.0,2120.0),vec2(3450.0,2120.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(3450.0,2120.0),vec2(4120.0,2100.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(1900.0,1720.0),vec2(1300.0,1720.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(1300.0,1720.0),vec2(1300.0,1280.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(1300.0,1280.0),vec2(1750.0,1280.0))));
path=max(path,1.-smoothstep(51.00,85.00,segment(p,vec2(1900.0,2900.0),vec2(1100.0,2900.0))));
path=max(path,1.-smoothstep(.85,1.,length((p-vec2(1900.0,1980.0))/vec2(600.0,340.0))));
path=max(path,1.-smoothstep(.85,1.,length((p-vec2(3250.0,1130.0))/vec2(650.0,260.0))));
path=max(path,1.-smoothstep(.85,1.,length((p-vec2(3850.0,2160.0))/vec2(460.0,200.0))));
vec3 grass=texture(earth_tex,p/1254.).rgb;vec3 stone=texture(path_tex,p/650.).rgb;COLOR=vec4(mix(grass,stone,path*.94),1.);}
