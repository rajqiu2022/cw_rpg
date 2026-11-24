shader_type canvas_item;
render_mode unshaded, blend_disabled;

// No source_color conversion, filtering, normalized UV or CPU correction.
// Stage A must prove this actual backend path against a direct RGBA readback.
uniform sampler2D primary_texture : filter_nearest, repeat_disable;
uniform ivec2 source_origin_px = ivec2(0);

void fragment() {
	COLOR = texelFetch(primary_texture, source_origin_px + ivec2(FRAGCOORD.xy), 0);
}
