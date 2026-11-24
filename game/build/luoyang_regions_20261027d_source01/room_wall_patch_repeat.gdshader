shader_type canvas_item;
render_mode unshaded;
// UV is authored in world pixels. Repeat only this fixed material patch, never
// stretch the original complete room shell into an unrelated collision shape.
uniform vec2 patch_origin_px;
uniform vec2 patch_size_px;
uniform vec2 source_size_px;
void fragment() {
	vec2 sample_px = patch_origin_px + mod(UV, patch_size_px);
	COLOR *= texture(TEXTURE, sample_px / source_size_px);
}
