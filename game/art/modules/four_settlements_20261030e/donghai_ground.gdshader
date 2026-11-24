shader_type canvas_item;
uniform sampler2D earth_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D dirt_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D path_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
float segment(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/max(dot(v,v),.001),0.,1.));}
void fragment(){float path=0.;
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(540.0,2890.0),vec2(1050.0,2740.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(1050.0,2740.0),vec2(1050.0,2160.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(1050.0,2160.0),vec2(1600.0,2160.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(1600.0,2160.0),vec2(1600.0,1410.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(1600.0,1410.0),vec2(1600.0,1200.0))));
path=max(path,1.-smoothstep(84.00,140.00,segment(p,vec2(1600.0,1200.0),vec2(1600.0,920.0))));
path=max(path,1.-smoothstep(78.00,130.00,segment(p,vec2(1600.0,2160.0),vec2(2800.0,2110.0))));
path=max(path,1.-smoothstep(78.00,130.00,segment(p,vec2(2800.0,2110.0),vec2(2800.0,1700.0))));
path=max(path,1.-smoothstep(78.00,130.00,segment(p,vec2(2800.0,1700.0),vec2(3340.0,1715.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(1050.0,2740.0),vec2(1850.0,2920.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(1850.0,2920.0),vec2(2800.0,2920.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(2800.0,2920.0),vec2(2800.0,2660.0))));
path=max(path,1.-smoothstep(66.00,110.00,segment(p,vec2(2800.0,2660.0),vec2(3340.0,2665.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(2800.0,2110.0),vec2(2800.0,1450.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(2800.0,1450.0),vec2(2500.0,1400.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(2500.0,1400.0),vec2(2500.0,1200.0))));
path=max(path,1.-smoothstep(60.00,100.00,segment(p,vec2(2500.0,1200.0),vec2(2500.0,1010.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(430.0,2665.0),vec2(550.0,2800.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(1330.0,2645.0),vec2(1450.0,2780.0))));
path=max(path,1.-smoothstep(45.00,75.00,segment(p,vec2(2240.0,2235.0),vec2(2360.0,2370.0))));
vec3 grass=texture(earth_tex,p/1000.).rgb;vec3 stone=texture(path_tex,p/280.).rgb;COLOR=vec4(mix(grass,stone,path*.94),1.);}
