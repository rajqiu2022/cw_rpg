shader_type canvas_item;
// Fixed real stair openings only. No actor/camera/opacity-fade uniforms.
uniform int slot_count = 0;
uniform vec4 slot0 = vec4(0.0);
uniform vec4 slot1 = vec4(0.0);
uniform vec4 slot2 = vec4(0.0);
uniform vec4 slot3 = vec4(0.0);
uniform vec4 slot4 = vec4(0.0);
varying vec2 scene_xy;
void vertex() { scene_xy = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
bool contains_slot(vec4 r) { return scene_xy.x >= r.x && scene_xy.y >= r.y && scene_xy.x <= r.z && scene_xy.y <= r.w; }
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	bool cut = (slot_count > 0 && contains_slot(slot0)) || (slot_count > 1 && contains_slot(slot1)) || (slot_count > 2 && contains_slot(slot2)) || (slot_count > 3 && contains_slot(slot3)) || (slot_count > 4 && contains_slot(slot4));
	if (cut) { pixel.a = 0.0; }
	COLOR = pixel;
}
