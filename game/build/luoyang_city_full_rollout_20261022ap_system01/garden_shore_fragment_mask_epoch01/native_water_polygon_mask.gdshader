shader_type canvas_item;
// Native world polygon is validated by the constructor; render-only coverage.
uniform vec2 native_water_polygon[19];
varying vec2 native_world_position;
void vertex() {
	native_world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	bool inside = false;
	int previous = 18;
	for (int current = 0; current < 19; current++) {
		vec2 a = native_water_polygon[current];
		vec2 b = native_water_polygon[previous];
		if ((a.y > native_world_position.y) != (b.y > native_world_position.y)) {
			float crossing_x = a.x + (native_world_position.y - a.y) * (b.x - a.x) / (b.y - a.y);
			if (native_world_position.x < crossing_x) {
				inside = !inside;
			}
		}
		previous = current;
	}
	if (!inside) {
		discard;
	}
	// Retain built-in COLOR inside. No second texture sample or color multiply.
}
