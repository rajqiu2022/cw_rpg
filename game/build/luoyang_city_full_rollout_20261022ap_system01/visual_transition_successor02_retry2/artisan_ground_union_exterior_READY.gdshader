shader_type canvas_item;
// Fixed exterior union, never a repeated tile or individual section boundary.
uniform vec4 ap_union_segments[32];
uniform vec2 ap_sprite_design_origin = vec2(0.0);
uniform vec2 ap_sprite_source_to_design = vec2(1.0);
varying vec2 ap_design_position;
void vertex() {
    ap_design_position = ap_sprite_design_origin + VERTEX * ap_sprite_source_to_design;
}
float ap_segment_squared(vec2 point, vec4 segment) {
    vec2 line = segment.zw - segment.xy;
    float along = clamp(dot(point - segment.xy, line) / max(dot(line, line), 0.0001), 0.0, 1.0);
    vec2 offset = point - (segment.xy + along * line);
    return dot(offset, offset);
}
void fragment() {
    float nearest_squared = 100000000.0;
    for (int index = 0; index < 32; index++) {
        nearest_squared = min(nearest_squared, ap_segment_squared(ap_design_position, ap_union_segments[index]));
    }
    // Preserve the original texture/modulate/core; no second texture sample.
    COLOR.a *= smoothstep(0.0, 32.0, sqrt(nearest_squared));
}
