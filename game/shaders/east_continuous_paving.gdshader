shader_type canvas_item;

varying vec2 map_position;
varying vec4 tint;

void vertex() {
	// East road vertices are authored in map pixels, all with the same origin.
	map_position = VERTEX;
	tint = COLOR;
}

void fragment() {
	COLOR = tint * texture(TEXTURE, map_position / 425.0);
}
