shader_type canvas_item;
// Original32 union exterior and original tile coordinates; RGB-only A1 change.
uniform vec4 ap_union_segments[32];
uniform vec2 ap_sprite_design_origin = vec2(0.0);
uniform vec2 ap_sprite_source_to_design = vec2(1.0);
uniform vec4 ap_stone_tone : source_color = vec4(0.53,0.55,0.52,1.0);
uniform float ap_stone_contrast = 0.45;
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
    // Default COLOR contains the real texture once. No resample/double multiply.
    COLOR.rgb = mix(ap_stone_tone.rgb,COLOR.rgb,clamp(ap_stone_contrast,0.0,1.0));
    COLOR.a *= smoothstep(0.0, 32.0, sqrt(nearest_squared));
}
