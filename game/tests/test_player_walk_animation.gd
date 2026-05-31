extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var player := load("res://scenes/player.tscn").instantiate()
	root.add_child(player)

	_expect(player.uses_directional_walk_sprites(), "player uses directional walk sprites")

	player.set_walk_direction(Vector2.RIGHT, true)
	_expect_eq(player.sprite.hframes, 9, "right walk uses 9 frames")
	_expect_eq(player.sprite.texture.resource_path, "res://art/characters/hero_walk_right_9f.png", "right texture selected")

	player.set_walk_direction(Vector2.DOWN, true)
	_expect_eq(player.sprite.hframes, 9, "down walk uses 9 frames")
	_expect_eq(player.sprite.texture.resource_path, "res://art/characters/hero_walk_down_9f.png", "down texture selected")

	player.queue_free()
	if _failures > 0:
		push_error("[Player Walk Animation Test] %d failure(s)" % _failures)
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		push_error("[FAIL] %s" % message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s (expected=%s actual=%s)" % [message, str(expected), str(actual)])
