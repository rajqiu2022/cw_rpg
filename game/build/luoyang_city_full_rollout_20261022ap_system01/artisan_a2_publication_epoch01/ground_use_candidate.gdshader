shader_type canvas_item;
// Exact A2 authored use union. Default COLOR already contains texture once.
uniform vec4 ap_edges[64];
uniform int ap_edge_count = 0;
uniform vec2 ap_sprite_origin = vec2(0.0);
uniform vec2 ap_source_to_world = vec2(1.0);
uniform vec4 ap_tone : source_color = vec4(0.55,0.53,0.47,1.0);
uniform float ap_contrast = 0.32;
uniform float ap_coverage = 1.0;
uniform float ap_edge_width = 0.0;
uniform bool ap_tree_pit = false;
uniform vec4 ap_tree_rect = vec4(0.0,0.0,1.0,1.0);
uniform float ap_grass_saturation = 0.94;
varying vec2 ap_world;

void vertex() {
    ap_world = ap_sprite_origin + VERTEX * ap_source_to_world;
}
float edge_distance_squared(vec2 p,vec4 edge) {
    vec2 line = edge.zw-edge.xy;
    float t = clamp(dot(p-edge.xy,line)/max(dot(line,line),0.0001),0.0,1.0);
    vec2 d = p-(edge.xy+t*line);
    return dot(d,d);
}
void fragment() {
    float coverage = 1.0;
    if (ap_tree_pit) {
        vec2 q = (ap_world-ap_tree_rect.xy)/ap_tree_rect.zw*2.0-vec2(1.0);
        float inside_distance = (1.0-length(q))*min(ap_tree_rect.z,ap_tree_rect.w)*0.5;
        coverage = smoothstep(0.0,ap_edge_width,inside_distance);
        float luminance = dot(COLOR.rgb,vec3(0.2126,0.7152,0.0722));
        COLOR.rgb = mix(vec3(luminance),COLOR.rgb,ap_grass_saturation);
    } else {
        COLOR.rgb = mix(ap_tone.rgb,COLOR.rgb,ap_contrast);
        if (ap_edge_width>0.0 && ap_edge_count>0) {
            float nearest = 100000000.0;
            for (int i=0; i<64; i++) {
                if (i<ap_edge_count) nearest = min(nearest,edge_distance_squared(ap_world,ap_edges[i]));
            }
            coverage = smoothstep(0.0,ap_edge_width,sqrt(nearest));
        }
    }
    COLOR.a *= coverage*ap_coverage;
}
