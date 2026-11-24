shader_type canvas_item;
uniform sampler2D earth_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D dirt_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D path_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
float segment(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/max(dot(v,v),.001),0.,1.));}
void fragment(){float path=0.;
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(2600.0,3800.0),vec2(2600.0,3320.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(2600.0,3320.0),vec2(2600.0,2780.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(2600.0,2780.0),vec2(2600.0,2500.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(2600.0,2500.0),vec2(2600.0,2240.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(2600.0,2240.0),vec2(2800.0,1800.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(2800.0,1800.0),vec2(3100.0,1600.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(3100.0,1600.0),vec2(3100.0,1350.0))));
path=max(path,1.-smoothstep(72.00,120.00,segment(p,vec2(3100.0,1350.0),vec2(3100.0,1170.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(2600.0,3100.0),vec2(1660.0,3100.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(1660.0,3100.0),vec2(1250.0,3000.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(2600.0,2780.0),vec2(4000.0,2780.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(4000.0,2780.0),vec2(4000.0,2500.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(4000.0,2500.0),vec2(4080.0,2360.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(4080.0,2360.0),vec2(4280.0,1840.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(4280.0,1840.0),vec2(3900.0,1590.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(3900.0,1590.0),vec2(3900.0,1350.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(3900.0,1350.0),vec2(3900.0,1230.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(2600.0,2240.0),vec2(2140.0,2140.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(2140.0,2140.0),vec2(2140.0,2040.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(2600.0,2240.0),vec2(3350.0,2240.0))));
path=max(path,1.-smoothstep(54.00,90.00,segment(p,vec2(3350.0,2240.0),vec2(4080.0,2360.0))));
path=max(path,1.-smoothstep(.85,1.,length((p-vec2(2600.0,2920.0))/vec2(530.0,330.0))));
path=max(path,1.-smoothstep(.85,1.,length((p-vec2(2800.0,2240.0))/vec2(600.0,300.0))));
path=max(path,1.-smoothstep(.85,1.,length((p-vec2(3100.0,1180.0))/vec2(730.0,250.0))));
vec3 grass=mix(texture(earth_tex,p/1254.).rgb,texture(dirt_tex,p/800.).rgb,0.55);vec3 stone=texture(path_tex,p/650.).rgb;COLOR=vec4(mix(grass,stone,path*.94),1.);}
