extends Node2D
## Ground contact highlight, shared by gathering and optional exploration.
var _phase := 0.0

func _ready() -> void:
	visibility_changed.connect(_update_processing)
	_update_processing()
	for style: Array in [[8.0, Color(0.49, 0.85, 0.68, 0.12)], [4.0, Color(0.58, 0.92, 0.73, 0.24)], [1.7, Color(0.85, 1.0, 0.78, 0.86)]]:
		var line := Line2D.new()
		line.antialiased = true
		line.closed = true
		line.width = style[0]
		line.default_color = style[1]
		for i in 48:
			var angle := TAU * float(i) / 48.0
			line.add_point(Vector2(cos(angle) * 23.0, sin(angle) * 9.0))
		add_child(line)

func _update_processing() -> void:
	set_process(is_visible_in_tree())

func _process(delta: float) -> void:
	_phase = fmod(_phase + delta * 3.5, TAU)
	modulate.a = 0.79 + sin(_phase) * 0.21
