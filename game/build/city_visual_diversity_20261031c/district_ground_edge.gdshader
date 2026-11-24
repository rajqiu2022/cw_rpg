shader_type canvas_item;
render_mode unshaded;
uniform vec2 edge_points[16];
uniform int edge_count = 0;
uniform float feather_px = 24.0;
varying vec2 ground_point;
varying vec4 source_tint;

void vertex() {
    ground_point = VERTEX;
    source_tint = COLOR;
}

void fragment() {
    float nearest = 1000000.0;
    for (int i = 0; i < 16; i++) {
        if (i >= edge_count) { break; }
        int j = i + 1;
        if (j >= edge_count) { j = 0; }
        vec2 a = edge_points[i];
        vec2 b = edge_points[j];
        vec2 segment = b - a;
        float t = clamp(dot(ground_point - a, segment) / max(dot(segment, segment), 0.0001), 0.0, 1.0);
        nearest = min(nearest, length(ground_point - (a + segment * t)));
    }
    vec4 sample_color = texture(TEXTURE, UV);
    float fade = smoothstep(0.0, max(feather_px, 0.001), nearest);
    COLOR = vec4(sample_color.rgb, sample_color.a * fade) * source_tint;
}
