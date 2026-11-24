shader_type canvas_item;
uniform vec2 hero_foot=vec2(0.);
uniform float fade_enabled=0.;
varying vec2 world_pixel;
void vertex(){world_pixel=(MODEL_MATRIX*vec4(VERTEX,0.,1.)).xy;}
void fragment(){vec4 t=texture(TEXTURE,UV);vec2 d=world_pixel-hero_foot;
 float x=1.-smoothstep(72.,125.,abs(d.x));float y=smoothstep(-195.,-155.,d.y)*(1.-smoothstep(8.,40.,d.y));
 COLOR=vec4(t.rgb,t.a*mix(1.,.13,x*y*fade_enabled));}
