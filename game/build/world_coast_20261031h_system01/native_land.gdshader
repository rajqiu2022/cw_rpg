shader_type spatial;
render_mode unshaded,cull_disabled;
varying vec3 terrain_position;
void vertex(){terrain_position=VERTEX;}
void fragment(){vec3 normal=normalize(cross(dFdx(terrain_position),dFdy(terrain_position)));float grade=length(normal.xz)/max(abs(normal.y),.0001);if(terrain_position.y<=-.025||grade>.72)discard;ALBEDO=vec3(1.);}
