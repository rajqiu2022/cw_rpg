shader_type canvas_item;
render_mode unshaded;
uniform sampler2D earth_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D rock_tex:source_color,repeat_enable,filter_linear;
uniform sampler2D paving_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
vec2 fold_uv(vec2 uv){return abs(fract(uv)*2.-1.);}

void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
float dseg(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return length(x-a-v*clamp(dot(x-a,v)/dot(v,v),0.,1.));}
float side(vec2 x,vec2 a,vec2 b){vec2 v=b-a;return (v.x*(x.y-a.y)-v.y*(x.x-a.x))/length(v);}
float court(vec2 x,vec2 a,vec2 b,vec2 c,vec2 d){return smoothstep(0.,12.,min(min(side(x,a,b),side(x,b,c)),min(side(x,c,d),side(x,d,a))));}
void fragment(){float main=99999.;float secondary=99999.;float alley=99999.;
main=min(main,dseg(p,vec2(2250,4480),vec2(2250,3380)));
main=min(main,dseg(p,vec2(2250,3380),vec2(2475,3380)));
main=min(main,dseg(p,vec2(2475,3380),vec2(2475,2720)));
main=min(main,dseg(p,vec2(2475,2720),vec2(2350,2720)));
main=min(main,dseg(p,vec2(2350,2720),vec2(2350,2100)));
main=min(main,dseg(p,vec2(2350,2100),vec2(3700,2100)));
main=min(main,dseg(p,vec2(3700,2100),vec2(3700,1010)));
main=min(main,dseg(p,vec2(3700,1010),vec2(4300,1010)));
secondary=min(secondary,dseg(p,vec2(2350,2720),vec2(1900,2720)));
secondary=min(secondary,dseg(p,vec2(1900,2720),vec2(1900,2560)));
secondary=min(secondary,dseg(p,vec2(1900,2560),vec2(1100,2560)));
secondary=min(secondary,dseg(p,vec2(1100,2560),vec2(1100,2380)));
secondary=min(secondary,dseg(p,vec2(2475,2720),vec2(3650,2720)));
secondary=min(secondary,dseg(p,vec2(3650,2720),vec2(3650,2570)));
secondary=min(secondary,dseg(p,vec2(3650,2570),vec2(4500,2570)));
secondary=min(secondary,dseg(p,vec2(4500,2570),vec2(4500,2380)));
alley=min(alley,dseg(p,vec2(3700,2100),vec2(3700,1560)));
alley=min(alley,dseg(p,vec2(3700,1560),vec2(1300,1560)));
alley=min(alley,dseg(p,vec2(1300,1560),vec2(1300,1020)));
alley=min(alley,dseg(p,vec2(1300,1020),vec2(3500,1020)));
alley=min(alley,dseg(p,vec2(3500,1020),vec2(3700,1020)));
alley=min(alley,dseg(p,vec2(3700,1020),vec2(3700,1150)));
secondary=min(secondary,dseg(p,vec2(2250,3380),vec2(1550,3380)));
secondary=min(secondary,dseg(p,vec2(1550,3380),vec2(1550,3150)));
secondary=min(secondary,dseg(p,vec2(1550,3150),vec2(1530,3110)));
secondary=min(secondary,dseg(p,vec2(2475,3340),vec2(3400,3340)));
secondary=min(secondary,dseg(p,vec2(3400,3340),vec2(3400,3170)));
secondary=min(secondary,dseg(p,vec2(2250,4480),vec2(2250,5100)));
secondary=min(secondary,dseg(p,vec2(2250,5100),vec2(2950,5600)));
secondary=min(secondary,dseg(p,vec2(2950,5600),vec2(2950,6200)));
secondary=min(secondary,dseg(p,vec2(2950,6200),vec2(2400,6850)));
secondary=min(secondary,dseg(p,vec2(2950,6000),vec2(3650,6000)));
secondary=min(secondary,dseg(p,vec2(3650,6000),vec2(3650,5840)));
secondary=min(secondary,dseg(p,vec2(2400,6850),vec2(1700,6850)));
secondary=min(secondary,dseg(p,vec2(1700,6850),vec2(1550,6500)));
secondary=min(secondary,dseg(p,vec2(3700,2100),vec2(3700,1720)));
secondary=min(secondary,dseg(p,vec2(3700,1720),vec2(3700,1320)));
secondary=min(secondary,dseg(p,vec2(3700,1320),vec2(3700,1010)));
secondary=min(secondary,dseg(p,vec2(3700,1010),vec2(4300,1010)));
secondary=min(secondary,dseg(p,vec2(1300,1560),vec2(1150,1560)));
secondary=min(secondary,dseg(p,vec2(1150,1560),vec2(1150,1715)));
secondary=min(secondary,dseg(p,vec2(1150,1715),vec2(800,1715)));
secondary=min(secondary,dseg(p,vec2(3700,1560),vec2(5000,1560)));
secondary=min(secondary,dseg(p,vec2(1300,1560),vec2(1700,1560)));
secondary=min(secondary,dseg(p,vec2(4300,1010),vec2(4300,1100)));
secondary=min(secondary,dseg(p,vec2(4300,1100),vec2(4900,1100)));
vec3 a=mix(texture(earth_tex,fold_uv(p/1450.)).rgb,texture(earth_tex,fold_uv(p/2670.+vec2(.31,.27))).rgb,.4);vec3 b=texture(rock_tex,fold_uv(p/1850.)).rgb;float m=1.-smoothstep(120.,160.,main);float s=1.-smoothstep(65.,100.,secondary);float l=1.-smoothstep(45.,72.,alley);vec3 smoothsoil=(a+texture(earth_tex,fold_uv(p/1450.+vec2(.31,.27))).rgb)*.5;float path=max(m,max(s,l));vec3 base_ground=mix(mix(a,b,.28)*.86,mix(smoothsoil,vec3(.68,.47,.29),.56),path);
float yards=0.;
yards=max(yards,court(p,vec2(1130,2925),vec2(2020,2925),vec2(2180,3110),vec2(940,3110)));
yards=max(yards,court(p,vec2(2980,2945),vec2(3870,2945),vec2(4030,3130),vec2(2790,3130)));
yards=max(yards,court(p,vec2(680,2155),vec2(1570,2155),vec2(1730,2340),vec2(490,2340)));
yards=max(yards,court(p,vec2(4080,2175),vec2(4970,2175),vec2(5130,2360),vec2(3890,2360)));
float town_band=smoothstep(580.,680.,p.y)*(1.-smoothstep(3520.,3700.,p.y));
float paving=max(max(m,l)*town_band,s*.86*town_band);paving=max(paving,yards*.94);
vec3 slabs=texture(paving_tex,fold_uv(p/512.)).rgb;
COLOR=vec4(mix(base_ground,slabs,paving*.9),1.);}
