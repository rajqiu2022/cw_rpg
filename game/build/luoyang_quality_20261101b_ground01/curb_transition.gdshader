shader_type canvas_item;
render_mode unshaded;
uniform sampler2D soil_texture : source_color, repeat_enable, filter_linear;
uniform vec2 soil_period = vec2(768.0);
uniform vec2 edge_origin;
uniform vec2 edge_outward;
uniform float dust_width = 6.0;
uniform float curb_width = 18.0;
varying vec2 ground_point;
varying vec4 source_tint;

void vertex() {
    ground_point = VERTEX;
    source_tint = COLOR;
}

void fragment() {
    // Both materials are approved existing raster assets. No procedural grain,
    // noise, random patches, or painted replacement main ground is generated.
    float outward = dot(ground_point - edge_origin, edge_outward);
    float course_y = 704.0 + clamp(outward + curb_width, 0.0, curb_width) * 6.0;
    vec2 stone_uv = vec2(UV.x, course_y / float(textureSize(TEXTURE, 0).y));
    vec4 stone = texture(TEXTURE, stone_uv);
    vec4 soil = texture(soil_texture, ground_point / soil_period);
    float dust = smoothstep(0.0, max(dust_width, 0.001), outward);
    COLOR = mix(stone, soil, dust) * source_tint;
}
