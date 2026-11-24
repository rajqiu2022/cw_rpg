shader_type canvas_item;
uniform sampler2D water_tex:source_color,repeat_enable,filter_linear;
varying vec2 p;
void vertex(){p=VERTEX;}
vec2 folded(vec2 x){return 1.-abs(mod(x,2.)-1.);}
void fragment(){vec2 q=p/650.+vec2(TIME*.004,TIME*.007);vec3 c=texture(water_tex,folded(q)).rgb;COLOR=vec4(c*.9,1.);}
