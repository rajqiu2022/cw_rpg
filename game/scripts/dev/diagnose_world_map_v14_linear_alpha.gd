extends SceneTree
## Tiny source-only alpha sampler probe. No Field/GPU rendering/save/art output.
const OVERLAP = preload("res://scripts/world/v14_modular_overlap.gd")
var _checks := 0
var _failures := 0

func _check(actual: float, expected: float, label: String) -> void:
	_checks += 1
	if absf(actual - expected) > .00001:
		_failures += 1
		push_error("linear alpha %s expected %f got %f" % [label, expected, actual])

func _initialize() -> void:
	var helper := OVERLAP.new()
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, Color(1, 1, 1, 0))
	image.set_pixel(1, 0, Color(1, 1, 1, 1))
	image.set_pixel(0, 1, Color(1, 1, 1, 1))
	image.set_pixel(1, 1, Color(1, 1, 1, 0))
	for entry: Array in [[Vector2(0, 0), 0.0], [Vector2(1, 0), 1.0], [Vector2(0, 1), 1.0], [Vector2(1, 1), 0.0], [Vector2(.5, .5), .5], [Vector2(.25, .25), .375], [Vector2(-.5, -.5), 0.0], [Vector2(1.5, -.5), 1.0], [Vector2(-.5, 1.5), 1.0], [Vector2(1.5, 1.5), 0.0]]:
		_check(helper._linear_alpha(image, entry[0]), entry[1], str(entry[0]))
	var prop := Sprite2D.new()
	prop.texture = ImageTexture.create_from_image(image)
	prop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_check(helper._alpha_at(prop, image, Vector2.ZERO), .5, "quad center bilinear")
	_check(helper._alpha_at(prop, image, Vector2(-.5, -.5)), 0, "texel center")
	prop.flip_h = true
	_check(helper._alpha_at(prop, image, Vector2(-.5, -.5)), 1, "horizontal flip")
	prop.modulate.a = .4
	prop.self_modulate.a = .5
	_check(helper._alpha_at(prop, image, Vector2(-.5, -.5)), .2, "modulate product")
	prop.flip_h = false
	prop.modulate.a = 1
	prop.self_modulate.a = 1
	prop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_check(helper._alpha_at(prop, image, Vector2.ZERO), 0, "nearest unchanged")
	prop.region_enabled = true
	prop.region_rect = Rect2(-1, 0, 2, 2)
	_check(helper._alpha_at(prop, image, Vector2.ZERO), 0, "invalid region rejected")
	var atlas := Image.create(4, 2, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(1, 1, 1, 0))
	atlas.set_pixel(1, 0, Color(1, 1, 1, 1))
	prop.region_enabled = false
	prop.texture = ImageTexture.create_from_image(atlas)
	prop.hframes = 2
	prop.frame = 1
	prop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_check(helper._alpha_at(prop, atlas, Vector2(-1, -.5)), .5, "frame edge samples adjacent atlas texel")
	prop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_check(helper._alpha_at(prop, atlas, Vector2(-1, -.5)), 0, "nearest frame edge retains current texel")
	prop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	prop.position = Vector2(150, 300)
	prop.scale = Vector2(2, 3)
	prop.rotation = PI / 7
	_check(helper._alpha_at(prop, atlas, prop.to_global(Vector2(-1, -.5))), .5, "transformed atlas frame edge")
	prop.free()
	print("WORLD_V14_LINEAR_ALPHA_SOURCE checks=%d failures=%d; no GPU/Field rendered" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
