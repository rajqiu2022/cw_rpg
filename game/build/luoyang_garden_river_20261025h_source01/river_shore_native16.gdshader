shader_type canvas_item;
// Rendering only. Native physics and mask use the separately proved deck cut.
uniform vec2 native_water_polygon[16];
varying vec2 native_world_position;
void vertex() {
    native_world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
    bool inside = false;
    int previous = 15;
    for (int current = 0; current < 16; current++) {
        vec2 a = native_water_polygon[current];
        vec2 b = native_water_polygon[previous];
        if ((a.y > native_world_position.y) != (b.y > native_world_position.y)) {
            float crossing_x = a.x + (native_world_position.y - a.y) * (b.x - a.x) / (b.y - a.y);
            if (native_world_position.x < crossing_x) { inside = !inside; }
        }
        previous = current;
    }
    if (!inside) { discard; }
    // Built-in COLOR already includes the original texture sample.
}
