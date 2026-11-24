shader_type canvas_item;
uniform sampler2D sand_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
float line_dist(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/dot(v,v),0.,1.));}
void fragment(){
 float d=1e5;
 d=min(d,line_dist(p,vec2(2560.,5100.),vec2(2560.,3800.)));
 d=min(d,line_dist(p,vec2(2560.,3800.),vec2(2860.,3800.)));
 d=min(d,line_dist(p,vec2(2860.,3800.),vec2(2860.,2400.)));
 d=min(d,line_dist(p,vec2(800.,3900.),vec2(7600.,3900.)));
 d=min(d,line_dist(p,vec2(1500.,3130.),vec2(6800.,3130.)));
 d=min(d,line_dist(p,vec2(1600.,2400.),vec2(6900.,2400.)));
 d=min(d,line_dist(p,vec2(6100.,2400.),vec2(6100.,3700.)));
 d=min(d,line_dist(p,vec2(4300.,2400.),vec2(4300.,3130.)));
 d=min(d,line_dist(p,vec2(1780.,3130.),vec2(1780.,2950.)));
 d=min(d,line_dist(p,vec2(6610.,3130.),vec2(6610.,2980.)));
 d=min(d,line_dist(p,vec2(1450.,3900.),vec2(1450.,3730.)));
 d=min(d,line_dist(p,vec2(3850.,3900.),vec2(3850.,3730.)));
 d=min(d,line_dist(p,vec2(6375.,3900.),vec2(6375.,3730.)));
 float road=1.-smoothstep(65.,125.,d);
 vec3 a=texture(sand_tex,folded(p/1100.)).rgb;
 vec3 b=texture(sand_tex,folded(p/2200.+.31)).rgb;
 vec3 sand=mix(a,b,.26);
 vec3 worn=mix(sand,vec3(.71,.55,.34),.28);
 COLOR=vec4(mix(sand,worn,road*.72),1.);
}
