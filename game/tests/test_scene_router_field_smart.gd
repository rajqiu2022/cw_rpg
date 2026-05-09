extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect_eq(
		SceneRouter.get_field_scene_path(&"ch1_s2_qingfeng_walkable"),
		"res://scenes/field_walkable.tscn",
		"walkable SceneScript opens field_walkable.tscn"
	)
	_expect_eq(
		SceneRouter.get_field_scene_path(&"ch1_s1_road"),
		"res://scenes/field.tscn",
		"classic SceneScript opens field.tscn"
	)

	if _failures > 0:
		push_error("[SceneRouter Field Smart Test] %d failure(s)" % _failures)
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		push_error("[FAIL] %s" % message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s (expected=%s actual=%s)" % [message, str(expected), str(actual)])
