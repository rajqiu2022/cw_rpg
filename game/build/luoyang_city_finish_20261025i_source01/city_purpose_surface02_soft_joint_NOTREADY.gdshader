shader_type canvas_item;
render_mode unshaded;
// Visual ground only: world-periodic existing material, never a NAV mask.
uniform sampler2D source_material : repeat_enable, filter_linear;
uniform vec2 bounds_origin_px;
uniform vec2 bounds_size_px;
uniform vec2 repeat_period_px=vec2(256.0);
uniform vec4 tint=vec4(1.0);
uniform float contrast=1.0;
uniform float shoulder_px=14.0;
uniform float opacity=1.0;
uniform bool is_path=false;
uniform bool full_base_coverage=false;
uniform int path_count=0;
uniform vec2 path_points[16];
uniform float path_half_width_px=72.0;
uniform float corner_radius_px=20.0;
float hash21(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453123);}
float grain(vec2 p){vec2 q=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash21(q),hash21(q+vec2(1,0)),f.x),mix(hash21(q+vec2(0,1)),hash21(q+vec2(1)),f.x),f.y);}
float segment_distance(vec2 p,vec2 a,vec2 b){vec2 d=b-a;return length(p-a-d*clamp(dot(p-a,d)/max(dot(d,d),0.0001),0.0,1.0));}
void fragment(){
 vec2 world=bounds_origin_px+UV*bounds_size_px;
 float distance_to_edge;
 if(is_path){
  float d=1e20;
  for(int i=0;i<15;i++){if(i+1<path_count){d=min(d,segment_distance(world,path_points[i],path_points[i+1]));}}
  distance_to_edge=d-path_half_width_px;
 }else{
  vec2 q=abs(world-(bounds_origin_px+bounds_size_px*0.5))-bounds_size_px*0.5+vec2(corner_radius_px);
  distance_to_edge=length(max(q,vec2(0.0)))+min(max(q.x,q.y),0.0)-corner_radius_px;
 }
 float weather=(grain(world/23.0)-0.5)*shoulder_px*0.72;
 float alpha=full_base_coverage ? opacity : (1.0-smoothstep(-shoulder_px,shoulder_px*0.3,distance_to_edge+weather))*opacity;
 vec4 tex=texture(source_material,world/repeat_period_px);
 vec3 rgb=clamp((tex.rgb-vec3(0.5))*contrast+vec3(0.5),vec3(0),vec3(1))*tint.rgb;
 COLOR=vec4(rgb,tex.a*tint.a*alpha);
}
