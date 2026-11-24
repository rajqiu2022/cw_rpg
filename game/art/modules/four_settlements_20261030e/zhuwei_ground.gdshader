shader_type canvas_item;
uniform sampler2D earth_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D dirt_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D path_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
float segment(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/max(dot(v,v),.001),0.,1.));}
void fragment(){float path=0.;
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(2100.0,2950.0),vec2(2100.0,2700.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(2100.0,2700.0),vec2(2100.0,2120.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(2100.0,2120.0),vec2(2100.0,1930.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(2100.0,1930.0),vec2(1500.0,1460.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(1500.0,1460.0),vec2(1500.0,1000.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(1500.0,1000.0),vec2(1500.0,840.0))));
path=max(path,1.-smoothstep(75.00,125.00,segment(p,vec2(430.0,2360.0),vec2(1300.0,2180.0))));
path=max(path,1.-smoothstep(75.00,125.00,segment(p,vec2(1300.0,2180.0),vec2(2100.0,2120.0))));
path=max(path,1.-smoothstep(75.00,125.00,segment(p,vec2(2100.0,2120.0),vec2(2800.0,2130.0))));
path=max(path,1.-smoothstep(75.00,125.00,segment(p,vec2(2800.0,2130.0),vec2(3500.0,2130.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(2800.0,2130.0),vec2(2800.0,1200.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(2800.0,1200.0),vec2(2800.0,1000.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(2800.0,1000.0),vec2(2800.0,850.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(2800.0,850.0),vec2(3180.0,850.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(3180.0,850.0),vec2(3180.0,430.0))));
path=max(path,1.-smoothstep(46.00,83.00,segment(p,vec2(3370.0,995.0),vec2(3370.0,908.0))));
path=max(path,1.-smoothstep(46.00,83.00,segment(p,vec2(3370.0,908.0),vec2(3180.0,850.0))));
path=max(path,1.-smoothstep(49.00,92.00,segment(p,vec2(3370.0,1080.0),vec2(3370.0,1265.0))));
path=max(path,1.-smoothstep(49.00,92.00,segment(p,vec2(3370.0,1265.0),vec2(3500.0,1520.0))));
path=max(path,1.-smoothstep(49.00,92.00,segment(p,vec2(3500.0,1520.0),vec2(3500.0,1800.0))));
path=max(path,1.-smoothstep(51.00,85.00,segment(p,vec2(1500.0,1270.0),vec2(700.0,1270.0))));
path=max(path,1.-smoothstep(51.00,85.00,segment(p,vec2(700.0,1270.0),vec2(430.0,1000.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(3500.0,2130.0),vec2(3500.0,2940.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(1550.0,695.0),vec2(1670.0,830.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(2590.0,755.0),vec2(2710.0,890.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(730.0,1305.0),vec2(850.0,1440.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(3400.0,1255.0),vec2(3520.0,1390.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(1470.0,2855.0),vec2(1590.0,2990.0))));
path=max(path,1.-smoothstep(68.20,110.00,segment(p,vec2(950.0,1838.0),vec2(950.0,2100.0))));
path=max(path,1.-smoothstep(68.20,110.00,segment(p,vec2(950.0,2100.0),vec2(1300.0,2180.0))));
path=max(path,1.-smoothstep(49.60,80.00,segment(p,vec2(890.0,850.0),vec2(1500.0,850.0))));
path=max(path,1.-smoothstep(49.60,80.00,segment(p,vec2(1500.0,850.0),vec2(2140.0,850.0))));
path=max(path,1.-smoothstep(49.60,80.00,segment(p,vec2(2140.0,850.0),vec2(2800.0,850.0))));
path=max(path,1.-smoothstep(42.16,68.00,segment(p,vec2(1010.0,2730.0),vec2(1430.0,2710.0))));
path=max(path,1.-smoothstep(42.16,68.00,segment(p,vec2(1430.0,2710.0),vec2(1800.0,2680.0))));
path=max(path,1.-smoothstep(42.16,68.00,segment(p,vec2(1800.0,2680.0),vec2(2100.0,2700.0))));
path=max(path,1.-smoothstep(46.50,75.00,segment(p,vec2(3500.0,2130.0),vec2(3500.0,1800.0))));
path=max(path,1.-smoothstep(46.50,75.00,segment(p,vec2(3500.0,1800.0),vec2(3760.0,1735.0))));
vec3 grass=texture(earth_tex,p/1000.).rgb;vec3 stone=mix(texture(dirt_tex,p/650.).rgb,texture(path_tex,p/280.).rgb,.18);COLOR=vec4(mix(grass,stone,path*.94),1.);}
