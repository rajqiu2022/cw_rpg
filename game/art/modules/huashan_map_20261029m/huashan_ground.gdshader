shader_type canvas_item;
uniform sampler2D earth_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D dirt_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D path_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
float segment(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/max(dot(v,v),.001),0.,1.));}
void fragment(){float path=0.;
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(2780.0,4550.0),vec2(2770.0,4050.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(2770.0,4050.0),vec2(2640.0,3560.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(2640.0,3560.0),vec2(2700.0,3200.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(2700.0,3200.0),vec2(2700.0,2800.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(2700.0,2800.0),vec2(2700.0,2480.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(2700.0,2480.0),vec2(2700.0,2080.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(2700.0,2080.0),vec2(2700.0,1550.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(2700.0,1550.0),vec2(2770.0,1270.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(2640.0,3560.0),vec2(1700.0,3210.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(1700.0,3210.0),vec2(1400.0,3200.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(1400.0,3200.0),vec2(1400.0,2800.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(1400.0,2800.0),vec2(1450.0,2590.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(1450.0,2590.0),vec2(1500.0,2260.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(1500.0,2260.0),vec2(1550.0,1600.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(1450.0,2590.0),vec2(2100.0,2590.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(2100.0,2590.0),vec2(2240.0,2200.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(2240.0,2200.0),vec2(2700.0,2200.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(2770.0,1270.0),vec2(3420.0,1350.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(3420.0,1350.0),vec2(3420.0,1550.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(3420.0,1550.0),vec2(3420.0,2080.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(3420.0,2080.0),vec2(3890.0,2020.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(3890.0,2020.0),vec2(4480.0,1880.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(4480.0,1880.0),vec2(4880.0,1880.0))));
path=max(path,1.-smoothstep(63.00,105.00,segment(p,vec2(3420.0,2080.0),vec2(3930.0,2350.0))));
path=max(path,1.-smoothstep(63.00,105.00,segment(p,vec2(3930.0,2350.0),vec2(3930.0,2800.0))));
path=max(path,1.-smoothstep(63.00,105.00,segment(p,vec2(3930.0,2800.0),vec2(3930.0,3100.0))));
path=max(path,1.-smoothstep(63.00,105.00,segment(p,vec2(3930.0,3100.0),vec2(4470.0,3400.0))));
path=max(path,1.-smoothstep(63.00,105.00,segment(p,vec2(4470.0,3400.0),vec2(4720.0,3500.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(2700.0,3200.0),vec2(3500.0,3180.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(3500.0,3180.0),vec2(3930.0,3100.0))));
path=max(path,1.-smoothstep(.85,1.,length((p-vec2(2780.0,2280.0))/vec2(710.0,540.0))));
path=max(path,1.-smoothstep(.85,1.,length((p-vec2(2770.0,1270.0))/vec2(850.0,350.0))));
path=max(path,1.-smoothstep(.85,1.,length((p-vec2(1510.0,2320.0))/vec2(650.0,400.0))));
path=max(path,1.-smoothstep(.85,1.,length((p-vec2(4800.0,1900.0))/vec2(280.0,150.0))));
path=max(path,1.-smoothstep(.85,1.,length((p-vec2(4650.0,3450.0))/vec2(220.0,140.0))));
vec3 grass=texture(earth_tex,folded(p/700.)).rgb;vec3 stone=texture(path_tex,folded(p/300.)).rgb;COLOR=vec4(mix(grass,stone,path*.94),1.);}
