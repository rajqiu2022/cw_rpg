shader_type canvas_item;
uniform sampler2D earth_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D dirt_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D path_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
float segment(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/max(dot(v,v),.001),0.,1.));}
void fragment(){float path=0.;
path=max(path,1.-smoothstep(81.00,135.00,segment(p,vec2(1700.0,4200.0),vec2(1700.0,3500.0))));
path=max(path,1.-smoothstep(81.00,135.00,segment(p,vec2(1700.0,3500.0),vec2(2400.0,3250.0))));
path=max(path,1.-smoothstep(81.00,135.00,segment(p,vec2(2400.0,3250.0),vec2(2400.0,2900.0))));
path=max(path,1.-smoothstep(81.00,135.00,segment(p,vec2(2400.0,2900.0),vec2(2400.0,2600.0))));
path=max(path,1.-smoothstep(81.00,135.00,segment(p,vec2(2400.0,2600.0),vec2(2500.0,2200.0))));
path=max(path,1.-smoothstep(81.00,135.00,segment(p,vec2(2500.0,2200.0),vec2(2600.0,1870.0))));
path=max(path,1.-smoothstep(81.00,135.00,segment(p,vec2(2600.0,1870.0),vec2(2600.0,1600.0))));
path=max(path,1.-smoothstep(81.00,135.00,segment(p,vec2(2600.0,1600.0),vec2(2600.0,1200.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(2400.0,3250.0),vec2(3900.0,3250.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(3900.0,3250.0),vec2(3900.0,2900.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(3900.0,2900.0),vec2(3900.0,2700.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(3900.0,2700.0),vec2(4050.0,2470.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(4050.0,2470.0),vec2(4200.0,1900.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(4200.0,1900.0),vec2(3990.0,1870.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(2500.0,2200.0),vec2(3300.0,2200.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(3300.0,2200.0),vec2(3300.0,1600.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(3300.0,1600.0),vec2(3300.0,1310.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(3300.0,1310.0),vec2(2700.0,1190.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(2500.0,2200.0),vec2(1700.0,2200.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(1700.0,2200.0),vec2(1450.0,1770.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(1450.0,1770.0),vec2(1430.0,1650.0))));
path=max(path,1.-smoothstep(.85,1.,length((p-vec2(2500.0,2400.0))/vec2(840.0,510.0))));
path=max(path,1.-smoothstep(.85,1.,length((p-vec2(2700.0,1150.0))/vec2(900.0,400.0))));
path=max(path,1.-smoothstep(.85,1.,length((p-vec2(4050.0,2480.0))/vec2(450.0,210.0))));
vec3 grass=texture(earth_tex,folded(p/1350.)).rgb;vec3 stone=texture(path_tex,folded(p/650.)).rgb;COLOR=vec4(mix(grass,stone,path*.94),1.);}
