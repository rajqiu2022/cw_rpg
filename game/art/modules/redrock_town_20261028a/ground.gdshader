shader_type canvas_item;
render_mode unshaded;
uniform sampler2D earth_tex : source_color, repeat_enable, filter_linear;
uniform sampler2D rock_tex : source_color, repeat_enable, filter_linear;
varying vec2 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy;}
float distseg(vec2 p,vec2 a,vec2 b){vec2 ab=b-a;return length(p-a-ab*clamp(dot(p-a,ab)/dot(ab,ab),0.0,1.0));}
void fragment(){vec2 p=world_pos;float d=99999.0;
d=min(d,distseg(p,vec2(2250,4480),vec2(2250,3380)));
d=min(d,distseg(p,vec2(2250,3380),vec2(3650,3380)));
d=min(d,distseg(p,vec2(3650,3380),vec2(3650,2720)));
d=min(d,distseg(p,vec2(3650,2720),vec2(2350,2720)));
d=min(d,distseg(p,vec2(2350,2720),vec2(2350,2100)));
d=min(d,distseg(p,vec2(2350,2100),vec2(3700,2100)));
d=min(d,distseg(p,vec2(3700,2100),vec2(3700,1010)));
d=min(d,distseg(p,vec2(3700,1010),vec2(4300,1010)));
d=min(d,distseg(p,vec2(2350,2720),vec2(1750,2720)));
d=min(d,distseg(p,vec2(1750,2720),vec2(1750,2390)));
d=min(d,distseg(p,vec2(1750,2390),vec2(1150,2390)));
d=min(d,distseg(p,vec2(3650,2720),vec2(3650,2400)));
d=min(d,distseg(p,vec2(3650,2400),vec2(4470,2400)));
d=min(d,distseg(p,vec2(3700,2100),vec2(3700,1560)));
d=min(d,distseg(p,vec2(3700,1560),vec2(1300,1560)));
d=min(d,distseg(p,vec2(1300,1560),vec2(1300,1020)));
d=min(d,distseg(p,vec2(1300,1020),vec2(3500,1020)));
d=min(d,distseg(p,vec2(3500,1020),vec2(3700,1150)));
d=min(d,distseg(p,vec2(2250,3380),vec2(2250,3170)));
d=min(d,distseg(p,vec2(2250,3170),vec2(1650,3170)));
d=min(d,distseg(p,vec2(2250,3170),vec2(3050,3170)));
d=min(d,distseg(p,vec2(3050,3170),vec2(3650,3170)));
vec3 dirt=texture(earth_tex,p/1450.0).rgb; vec3 stone=texture(rock_tex,p/1850.0).rgb; float road=1.0-smoothstep(125.0,230.0,d); vec3 smoothdirt=(dirt+texture(earth_tex,p/1450.0+vec2(.31,.27)).rgb)*0.5; vec3 path=mix(smoothdirt,vec3(0.68,0.47,0.29),0.56); COLOR=vec4(mix(mix(dirt,stone,0.28)*0.86,path,road),1.0);}
