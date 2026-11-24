shader_type canvas_item;

uniform float repeat_px = 240.0;
uniform float width_px = 120.0;
varying vec2 map_position;
varying vec4 lane_color;

void vertex() {
	map_position = VERTEX;
	lane_color = COLOR;
}

void fragment() {
	vec3 stone = texture(TEXTURE, map_position / repeat_px).rgb;
	// Transverse UV is shared by straight sections and round joins of the Line2D.
	float depth = min(UV.y, 1.0 - UV.y) * width_px;
	float grain = texture(TEXTURE, map_position / 73.0).g;
	float verge = 4.0 + 4.0 * sin(map_position.x * .041 + map_position.y * .026) + 9.0 * grain;
	COLOR = vec4(stone, smoothstep(verge - 5.0, verge + 9.0, depth)) * lane_color;
}
