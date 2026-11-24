shader_type canvas_item;
render_mode unshaded;

uniform vec2 layer_size = vec2(800.0, 512.0);
varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec2 edge = min(local_position, layer_size - local_position);
	COLOR.a *= smoothstep(1.0, 22.0, min(edge.x, edge.y));
}
