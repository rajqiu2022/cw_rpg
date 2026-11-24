extends Control
## 武学面板的破境题签，与本次成功的九重到十重操作同生同灭。

const GOLD := Color("#efc879")
const JADE := Color("#93d3bd")
var technique: Skill
var emblem: Texture2D
var reveal := 0.0


func celebrate(skill: Skill) -> void:
	technique = skill
	if ResourceLoader.exists(skill.icon_path):
		emblem = load(skill.icon_path) as Texture2D
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modulate.a = 0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.22)
	tween.parallel().tween_method(_set_reveal, 0.0, 1.0, 0.85).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.65)
	tween.tween_property(self, "modulate:a", 0.0, 0.42)
	tween.tween_callback(queue_free)


func _set_reveal(value: float) -> void:
	reveal = value
	queue_redraw()


func _draw() -> void:
	if technique == null or size.x < 1 or size.y < 1:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.05, 0.06, 0.60))
	var scale_factor := minf(size.x / 680.0, size.y / 360.0)
	draw_set_transform(size * 0.5, 0, Vector2.ONE * minf(1.18, scale_factor))
	var panel := Rect2(-280, -122, 560, 244)
	draw_rect(panel, Color("#112d2d"))
	draw_rect(panel.grow(-5), Color("#577568"), false, 1.0)
	for side in [-1, 1]:
		var edge := float(side) * 266.0
		draw_line(Vector2(edge, -110), Vector2(edge - side * 45 * reveal, -110), GOLD, 2)
		draw_line(Vector2(edge, 110), Vector2(edge - side * 45 * reveal, 110), GOLD, 2)
	var seal := Vector2(0, -62)
	draw_circle(seal, 34, Color("#29463e"))
	if emblem:
		draw_texture_rect(emblem, Rect2(seal - Vector2(26, 26), Vector2(52, 52)), false)
	for sector in 4:
		var angle := sector * PI / 2.0 + reveal * 0.32
		draw_arc(seal, 36 + 4 * reveal, angle, angle + 1.23 * reveal, 20, GOLD, 1.8, true)
	for i in 24:
		var ray := Vector2.from_angle(TAU * i / 24.0)
		draw_line(seal + ray * (39 + reveal * 4), seal + ray * (42 + reveal * (7 if i % 3 == 0 else 3)), Color(GOLD, 0.68), 1.4, true)
	var font := get_theme_default_font()
	draw_string(font, Vector2(-260, 10), "绝学圆满", HORIZONTAL_ALIGNMENT_CENTER, 520, 23, JADE)
	draw_string(font, Vector2(-270, 59), technique.display_name, HORIZONTAL_ALIGNMENT_CENTER, 540, 40, GOLD)
	draw_string(font, Vector2(-270, 94), "恭喜突破第十重", HORIZONTAL_ALIGNMENT_CENTER, 540, 19, Color("#dfebdc"))
