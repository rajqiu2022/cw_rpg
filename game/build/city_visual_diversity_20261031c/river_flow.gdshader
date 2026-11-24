shader_type canvas_item;
render_mode unshaded;

// Visual sampling only: original Polygon/UV/walkability remain unchanged.
uniform vec2 flow_uv_per_second = vec2(0.004, -0.0012);
uniform float ripple_uv_amplitude = 0.0015;
uniform float moving_mix = 0.65;
varying vec4 source_tint;

void vertex() {
    source_tint = COLOR;
}

void fragment() {
    vec4 still_sample = texture(TEXTURE, UV);
    vec2 ripple = vec2(
        sin(UV.y * 21.0 + TIME * 0.72),
        cos(UV.x * 17.0 - TIME * 0.53)
    ) * ripple_uv_amplitude;
    vec2 flow_uv = UV + TIME * flow_uv_per_second + ripple;
    vec4 moving_sample = texture(TEXTURE, flow_uv);
    // Keep the original alpha, no bank displacement or second COLOR sampling.
    COLOR = vec4(mix(still_sample.rgb, moving_sample.rgb, moving_mix), still_sample.a) * source_tint;
}
