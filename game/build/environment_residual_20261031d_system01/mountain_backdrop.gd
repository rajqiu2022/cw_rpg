extends Sprite2D
## The native image is the visual; this only fits its whole rect to the window.
var _last_viewport_size:=Vector2.ZERO

func _ready() -> void:
	fit_to_window()

func _process(_delta: float) -> void:
	if get_viewport_rect().size!=_last_viewport_size:fit_to_window()

func fit_to_window() -> void:
	if texture==null:return
	_last_viewport_size=get_viewport_rect().size
	var source:=texture.get_size()
	position=_last_viewport_size*.5
	scale=Vector2.ONE*maxf(_last_viewport_size.x/source.x,_last_viewport_size.y/source.y)
