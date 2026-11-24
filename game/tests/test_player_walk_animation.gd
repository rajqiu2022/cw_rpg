extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)

	_expect(player.uses_directional_walk_sprites(), "player uses directional walk sprites")

	player.set_walk_direction(Vector2.RIGHT, true)
	_expect_eq(player.sprite.hframes, 8, "right walk uses 8 frames")
	_expect_eq(player.sprite.texture.resource_path, _expected_path("right"), "right v7 weapon texture selected")
	player.sprite.frame = 3
	player.set_walk_direction(Vector2.RIGHT, true)
	_expect_eq(player.sprite.frame, 3, "unchanged direction keeps the current animation frame")

	player.set_walk_direction(Vector2.DOWN, true)
	_expect_eq(player.sprite.hframes, 8, "down walk uses 8 frames")
	_expect_eq(player.sprite.texture.resource_path, _expected_path("down"), "down v7 weapon texture selected")

	player.set_walk_direction(Vector2.LEFT, true)
	_expect_eq(player.sprite.texture.resource_path, _expected_path("left"), "left v7 weapon texture selected")

	player.set_walk_direction(Vector2.UP, true)
	_expect_eq(player.sprite.texture.resource_path, _expected_path("up"), "up v7 weapon texture selected")

	player.queue_free()
	if _failures > 0:
		push_error("[Player Walk Animation Test] %d failure(s)" % _failures)
	quit(_failures)


func _expected_path(direction: String) -> String:
	return "res://art/characters/weapon_variants/lengguyun/v7_idle_stable/sword/lengguyun_sword_walk_%s_25d_8f.png" % direction


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		push_error("[FAIL] %s" % message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s (expected=%s actual=%s)" % [message, str(expected), str(actual)])
