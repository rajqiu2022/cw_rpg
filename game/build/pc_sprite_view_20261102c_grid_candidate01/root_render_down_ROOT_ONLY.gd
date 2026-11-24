extends SceneTree
## ROOT ONLY visual sample, not adoption. Two stills and ONE eight-phase cycle.
## Generic display sprites only: no actors, second adapter, HUD or save access.
const AUDIT := "res://build/sprite_hd_20261102c_art01/down_v3_mapping_CANDIDATE.json"
const STONE := "res://art/modules/luoyang_moat_v1/cobblestone_floor_08_diff_1k.jpg"
const OUT := "res://build/pc_sprite_view_20261102c_grid_candidate01/render_preview/"
const RATIO := 132.0 / 458.0
var _audit: Dictionary = {}
var _world: Node2D
var _camera: Camera2D
var _old_idle: Sprite2D
var _old_walk: Sprite2D
var _new_idle: Sprite2D
var _new_walk: Sprite2D
var _idle_frames: Array[AtlasTexture] = []
var _walk_frames: Array[AtlasTexture] = []


func _initialize() -> void:
	call_deferred("_run")


func _raw_frames(section: Dictionary, count: int) -> Array[AtlasTexture]:
	var result: Array[AtlasTexture] = []
	var path := ProjectSettings.globalize_path("res://").path_join("..").path_join(String(section.raw_path)).simplify_path()
	if FileAccess.get_sha256(path) != String(section.raw_sha256):
		push_error("ROOT_RENDER_RAW_SHA:" + path)
		return result
	var image := Image.new()
	if image.load(path) != OK or image.get_size() != Vector2i(int(section.size[0]), int(section.size[1])) or section.frames.size() != count:
		push_error("ROOT_RENDER_RAW_LAYOUT:" + path)
		return result
	# Texture creation only. No crop, resample, alpha change or image file write.
	var texture := ImageTexture.create_from_image(image)
	for index: int in range(count):
		var rect: Array = section.frames[index].rect
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]))
		frame.filter_clip = true
		result.append(frame)
	return result


func _sprite(texture: Texture2D, position: Vector2, hframes: int = 1) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = texture
	sprite.hframes = hframes
	sprite.position = position
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_world.add_child(sprite)
	return sprite


func _label(text: String, position: Vector2, width: float = 360) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = Vector2(width, 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9))
	_world.add_child(label)


func _apply_phase(phase: int, log_sample: bool = true) -> void:
	# One .8s down-walk cycle, with native .28s idle timing alongside it.
	var idle_phase := mini(3, int(floor(float(phase) * 0.10 / 0.28)))
	_old_idle.frame = idle_phase
	_old_walk.frame = phase
	_new_idle.texture = _idle_frames[idle_phase]
	_new_walk.texture = _walk_frames[phase]
	var idle_old_y := float(_audit.old_v7.idle_alpha128_foot_y[idle_phase])
	var walk_old_y := float(_audit.old_v7.walk_alpha128_foot_y[phase])
	var idle_new_y := float(_audit.idle.frames[idle_phase].foot_y_alpha128)
	var walk_new_y := float(_audit.walk.frames[phase].foot_y_alpha128)
	# Old source sprites remain at fixed origin; their native 1px foot motion
	# stays present. Only HD child-equivalent display aligns to that same foot.
	_new_idle.position = Vector2(1160, _old_idle.position.y + idle_old_y) - Vector2(192, idle_new_y) * RATIO
	_new_walk.position = Vector2(1160, _old_walk.position.y + walk_old_y) - Vector2(192, walk_new_y) * RATIO
	if log_sample:
		print("ROOT_RENDER_DOWN_PHASE ", JSON.stringify({"walk_phase": phase, "idle_phase": idle_phase, "uniform_ratio": RATIO, "old_walk_foot_y": _old_walk.position.y + walk_old_y, "new_walk_foot_y": _new_walk.position.y + walk_new_y * RATIO, "new_walk_alpha24_body_height_world": float(_audit.walk.frames[phase].body_height_alpha24) * RATIO, "walk_cell": (_new_walk.texture as AtlasTexture).region, "not_motion_acceptance": true}))


func _shot(filename: String) -> bool:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png(OUT + filename)
	print("ROOT_RENDER_DOWN_STILL ", JSON.stringify({"path": OUT + filename, "zoom": _camera.zoom, "size": image.get_size(), "save_error": result}))
	return result == OK


func _run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(AUDIT))
	if not parsed is Dictionary or parsed.get("schema") != "PC_HERO_HD_DOWN_SOURCE_MAPPING_CANDIDATE_V1":
		push_error("ROOT_RENDER_AUDIT_SCHEMA")
		quit(1)
		return
	_audit = parsed
	_idle_frames = _raw_frames(_audit.idle, 4)
	_walk_frames = _raw_frames(_audit.walk, 8)
	if _idle_frames.size() != 4 or _walk_frames.size() != 8:
		quit(1)
		return
	var out_absolute := ProjectSettings.globalize_path(OUT)
	if DirAccess.make_dir_recursive_absolute(out_absolute) != OK:
		push_error("ROOT_RENDER_OUTPUT_DIRECTORY")
		quit(1)
		return
	root.size = Vector2i(1920, 1080)
	_world = Node2D.new()
	_world.name = "RootOnlyDownVisualFixture"
	root.add_child(_world)
	var ground := Polygon2D.new()
	ground.polygon = PackedVector2Array([Vector2(-1920,-1080),Vector2(3840,-1080),Vector2(3840,2160),Vector2(-1920,2160)])
	ground.uv = PackedVector2Array([Vector2(-3840,-2160),Vector2(7680,-2160),Vector2(7680,4320),Vector2(-3840,4320)])
	ground.texture = load(STONE) as Texture2D
	ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ground.color = Color(0.35, 0.38, 0.4, 1)
	_world.add_child(ground)
	_old_idle = _sprite(load(String(_audit.old_v7.idle_path)) as Texture2D, Vector2(760 - 80, 470 - 150), 4)
	_old_walk = _sprite(load(String(_audit.old_v7.walk_path)) as Texture2D, Vector2(760 - 80, 710 - 150), 8)
	_new_idle = _sprite(_idle_frames[0], Vector2.ZERO)
	_new_walk = _sprite(_walk_frames[0], Vector2.ZERO)
	_new_idle.scale = Vector2.ONE * RATIO
	_new_walk.scale = Vector2.ONE * RATIO
	_label("现役 v7 · PC线性采样", Vector2(580, 286))
	_label("新原生图 · 下向剑式样板", Vector2(980, 286))
	_label("待机 · 同一倍率，稳定脚线", Vector2(780, 490))
	_label("行走 · 8相位，保留原脚线起伏", Vector2(780, 735))
	_camera = Camera2D.new()
	_camera.position = Vector2(960, 540)
	_camera.zoom = Vector2.ONE
	_world.add_child(_camera)
	_camera.make_current()
	_apply_phase(0, false)
	await process_frame
	await process_frame
	var normal_saved: bool = await _shot("normal1_contact0.png")
	await create_timer(0.35).timeout
	_camera.zoom = Vector2.ONE * 2
	var zoom_saved := false
	# Exactly one eight-phase cycle. No 4x8/all-directions matrix or repeat loop.
	for phase: int in range(8):
		_apply_phase(phase)
		await RenderingServer.frame_post_draw
		if phase == 4:
			zoom_saved = await _shot("zoom2_contact4.png")
		await create_timer(0.10).timeout
	await create_timer(0.35).timeout
	print("ROOT_RENDER_DOWN_RESULT ", JSON.stringify({"normal1_saved": normal_saved, "zoom2_saved": zoom_saved, "walk_cycles": 1, "walk_phases": 8, "still_count": 2, "body_reference_idle132_world": true, "ratio_for_all_frames_and_states": RATIO, "walk_heights_not_fitted_to132": true, "alpha_or_art_acceptance_by_root_only": true, "source_png_edits": 0, "formal_mapping_or_hud_edits": 0, "real_save_access": false}))
	_world.queue_free()
	await process_frame
	quit(0 if normal_saved and zoom_saved else 1)
