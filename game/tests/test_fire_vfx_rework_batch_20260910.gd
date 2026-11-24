extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var shader_path := "res://shaders/environment_flame.gdshader"
	_check(FileAccess.file_exists(shader_path), "environment flame shader exists")
	var shader_source := FileAccess.get_file_as_string(shader_path)
	_check("fbm" in shader_source and "left_side" in shader_source and "right_side" in shader_source, "environment flame has turbulent body and independent side tongues")
	var controller_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check("ENVIRONMENT_FLAME_SHADER" in controller_source and "_loop_flame_ember" in controller_source, "field flame combines shader body, glow and rising embers")

	var crimson := BattleVfxPlayer.get_effect_config(&"crimson_palm")
	var rupture := BattleVfxPlayer.get_effect_config(&"gufeng_liedi")
	_check(String(crimson.get("sheet", "")).ends_with("vfx_crimson_palm_4frame_v2.png"), "crimson palm uses the literal flame v2 atlas")
	_check(String(rupture.get("sheet", "")).ends_with("vfx_gufeng_liedi_4frame_v2.png"), "Gufeng ground rupture uses the semantic v2 atlas")
	_validate_sheet(String(crimson.get("sheet", "")), "crimson palm")
	_validate_sheet(String(rupture.get("sheet", "")), "Gufeng ground rupture")
	print("[FireVfxRework20260910] failures=%d" % failures)
	quit(1 if failures else 0)


func _validate_sheet(path: String, label: String) -> void:
	_check(FileAccess.file_exists(path), "%s runtime atlas exists" % label)
	if not FileAccess.file_exists(path):
		return
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	_check(image != null and image.detect_alpha(), "%s runtime atlas has true alpha" % label)
	if image == null:
		return
	_check(image.get_width() % 2 == 0 and image.get_height() % 2 == 0, "%s runtime atlas keeps an exact 2x2 grid" % label)
	for row in range(2):
		for column in range(2):
			var frame := image.get_region(Rect2i(column * image.get_width() / 2, row * image.get_height() / 2, image.get_width() / 2, image.get_height() / 2))
			_check(frame.get_used_rect().has_area(), "%s frame %d is not empty" % [label, row * 2 + column + 1])


func _check(ok: bool, message: String) -> void:
	if ok:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
