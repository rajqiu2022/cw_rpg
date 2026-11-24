shader_type canvas_item;
// Fixed world-space use unions; complete existing textures, no second texture sample.
uniform vec2 source_size=vec2(1536.0,1024.0);
uniform float source_to_world=.25;
uniform vec2 world_origin=vec2(0.0);
uniform vec4 use_rects[8];
uniform int use_rect_count=0;
uniform vec4 exterior_segments[32];
uniform int exterior_count=0;
uniform vec4 building_exclusions[2];
uniform int exclusion_count=0;
uniform float edge_width=20.0;
uniform float wear_world=5.0;
uniform vec4 material_tone : source_color=vec4(.56,.57,.54,1.);
uniform float texture_contrast=.42;
uniform float core_opacity=.55;
varying vec2 world_position;
void vertex(){
 world_position=world_origin+VERTEX*source_to_world;
 UV+=world_origin/(source_size*source_to_world);
}
bool inside_rect(vec2 p,vec4 r){return p.x>=r.x&&p.y>=r.y&&p.x<=r.x+r.z&&p.y<=r.y+r.w;}
float segment_distance(vec2 p,vec4 s){
 vec2 line=s.zw-s.xy;float t=clamp(dot(p-s.xy,line)/max(dot(line,line),.0001),0.,1.);
 return length(p-(s.xy+t*line));
}
void fragment(){
 bool included=false;
 for(int i=0;i<8;i++){if(i>=use_rect_count){break;}if(inside_rect(world_position,use_rects[i])){included=true;}}
 if(!included){discard;}
 for(int i=0;i<2;i++){if(i>=exclusion_count){break;}if(inside_rect(world_position,building_exclusions[i])){discard;}}
 float distance_to_edge=100000.;
 for(int i=0;i<32;i++){if(i>=exterior_count){break;}distance_to_edge=min(distance_to_edge,segment_distance(world_position,exterior_segments[i]));}
 float worn=.5+.25*sin(dot(world_position,vec2(.019,.013))+.7)+.25*sin(dot(world_position,vec2(.041,-.027))+2.1);
 float inset=max(wear_world,0.)*(.35+.65*worn);
 float coverage=smoothstep(inset,max(edge_width,1.)+inset,distance_to_edge);
 COLOR.rgb=mix(material_tone.rgb,COLOR.rgb,clamp(texture_contrast,0.,1.));
 COLOR.a*=coverage*core_opacity;
}
