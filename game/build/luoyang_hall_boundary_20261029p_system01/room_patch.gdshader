shader_type canvas_item;
render_mode unshaded;
uniform vec2 patch_origin_px;
uniform vec2 patch_size_px;
uniform vec2 source_size_px;
varying vec4 vertex_tint;
void vertex() {
	vertex_tint = COLOR;
}
void fragment() {
	// Polygon2D's authored UVs are pixels, but fragment UV is normalized.
	vec2 source_px = patch_origin_px + mod(UV * source_size_px, patch_size_px);
	// Do not multiply fragment COLOR: that already contains the full PNG's
	// default texture/alpha sample and would reintroduce its shell silhouette.
	COLOR = vertex_tint * texture(TEXTURE, source_px / source_size_px);
}
