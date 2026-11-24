shader_type canvas_item;
render_mode unshaded;
uniform vec2 line_start;
uniform vec2 line_end;
uniform float lane_half = 40.0;
uniform float shoulder = 18.0;
// Mode0 preserves every old endpoint's shader behavior. Mode1 is the single
// Root-review02a sample; only existing material textures supply visible pixels.
uniform int sample_mode = 0;
uniform sampler2D soil_texture : source_color, repeat_enable, filter_linear;
uniform vec2 soil_period = vec2(768.0);
uniform vec2 sample_points[5];
uniform float sample_half_widths[5];
uniform float sample_soft_shoulder = 28.0;
varying vec2 world_point;
varying vec4 vertex_tint;
void vertex() {
 world_point = VERTEX;
 vertex_tint = COLOR;
}
void fragment() {
 if (sample_mode == 1) {
  float road_distance = 1000000.0;
  for (int i=0; i<4; i++) {
   vec2 a = sample_points[i];
   vec2 axis = sample_points[i+1]-a;
   float t = clamp(dot(world_point-a,axis)/max(dot(axis,axis),0.001),0.0,1.0);
   float half_width = mix(sample_half_widths[i],sample_half_widths[i+1],t);
   road_distance = min(road_distance,length(world_point-a-axis*t)-half_width);
  }
  float stone_weight = 1.0-smoothstep(0.0,sample_soft_shoulder,road_distance);
  vec4 soil = texture(soil_texture,world_point/soil_period);
  vec4 stone = texture(TEXTURE,UV);
  COLOR = mix(soil,stone,stone_weight)*vertex_tint;
 } else {
 vec2 axis = line_end-line_start;
 float t = clamp(dot(world_point-line_start,axis)/max(dot(axis,axis),0.001),0.0,1.0);
 float distance_from_road = length(world_point-line_start-axis*t);
 vec4 source = texture(TEXTURE,UV)*vertex_tint;
 source.a *= 0.72*(1.0-smoothstep(lane_half,lane_half+shoulder,distance_from_road));
 COLOR = source;
 }
}
