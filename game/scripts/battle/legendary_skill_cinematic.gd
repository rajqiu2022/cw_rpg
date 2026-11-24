class_name LegendarySkillCinematic
extends Control

## Orange-tier martial arts use a separate cinematic layer above the battle HUD:
## dim battlefield -> name reveal -> authored impact. Group ultimates may own a
## full-screen atlas instead of replaying a small effect on each target.

const FULLSCREEN_EFFECTS := {
	&"canghai_zhenyue_palms": {
		"frames": [
			"res://art/battle_vfx/legendary_cinematics/canghai_zhenyue_fullscreen_hd_v2/canghai_zhenyue_fullscreen_f01_v2.png",
			"res://art/battle_vfx/legendary_cinematics/canghai_zhenyue_fullscreen_hd_v2/canghai_zhenyue_fullscreen_f02_v2.png",
			"res://art/battle_vfx/legendary_cinematics/canghai_zhenyue_fullscreen_hd_v2/canghai_zhenyue_fullscreen_f03_v2.png",
			"res://art/battle_vfx/legendary_cinematics/canghai_zhenyue_fullscreen_hd_v2/canghai_zhenyue_fullscreen_f04_v2.png",
		],
		"frame_seconds": 0.28,
	},
}
const INTRO_EFFECTS := {
	&"canghai_zhenyue_palms": "res://art/battle_vfx/legendary_cinematics/canghai_zhenyue_fullscreen_hd_v2/canghai_zhenyue_intro_palm_4frame_v2.png",
}
const MANUAL_CALLIGRAPHY_FONT := preload("res://art/fonts/LXGWWenKaiLite-Regular.ttf")
const LEGENDARY_TITLE_SFX := "res://art/audio/free/sfx_legendary_title_reveal_v2.wav"

var _active_root: Control = null
var _mask: ColorRect = null
var _intro_effect: TextureRect = null
var _title: Label = null
var _subtitle: Label = null
var _additive_material: CanvasItemMaterial = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = true
	_additive_material = CanvasItemMaterial.new()
	_additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD


func is_playing() -> bool:
	return _active_root != null and is_instance_valid(_active_root)


func has_fullscreen_effect(skill_id: StringName) -> bool:
	return FULLSCREEN_EFFECTS.has(skill_id)


func play_intro(skill: Skill) -> void:
	if skill == null:
		return
	_clear_immediately()
	var view_size := get_viewport_rect().size
	_active_root = Control.new()
	_active_root.name = "LegendaryCinematicRuntime"
	_active_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_active_root.position = Vector2.ZERO
	_active_root.size = view_size
	add_child(_active_root)

	_mask = ColorRect.new()
	_mask.name = "FullscreenDimMask"
	_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mask.position = Vector2.ZERO
	_mask.size = view_size
	_mask.color = Color(0.01, 0.015, 0.02, 0.0)
	_active_root.add_child(_mask)

	var intro_sheet := _load_intro_sheet(skill.animation_id)
	if intro_sheet != null:
		_intro_effect = TextureRect.new()
		_intro_effect.name = "CentralGatherEffect"
		_intro_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_intro_effect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_intro_effect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_intro_effect.material = _additive_material
		var effect_size := minf(view_size.y * 0.62, view_size.x * 0.42)
		_intro_effect.size = Vector2(effect_size, effect_size)
		_intro_effect.position = view_size * 0.5 - _intro_effect.size * 0.5
		_intro_effect.modulate = Color(1.0, 0.92, 0.68, 0.0)
		_active_root.add_child(_intro_effect)

	_subtitle = _make_center_label("传 世 绝 学", 24, Color(0.76, 0.59, 0.31, 1.0), view_size, 3)
	_subtitle.position.y = view_size.y * 0.36
	_subtitle.pivot_offset = _subtitle.size * 0.5
	_subtitle.scale = Vector2(0.55, 0.55)
	_subtitle.modulate.a = 0.0
	_active_root.add_child(_subtitle)

	_title = _make_center_label(skill.display_name, 86, Color(0.93, 0.76, 0.40, 1.0), view_size, 5)
	_title.position.y = view_size.y * 0.43
	_title.pivot_offset = _title.size * 0.5
	_title.scale = Vector2(0.18, 0.18)
	_title.modulate.a = 0.0
	_active_root.add_child(_title)
	# The title sting is synchronized with the first visible scale-up frame, not
	# the later impact, so the calligraphy reveal has an audible sense of weight.
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null:
		event_bus.emit_signal("sfx_requested", LEGENDARY_TITLE_SFX, -1.5)

	var fade_in := create_tween()
	fade_in.set_parallel(true)
	fade_in.tween_property(_mask, "color:a", 0.78, 0.18)
	fade_in.tween_property(_subtitle, "modulate:a", 1.0, 0.24).set_delay(0.08)
	fade_in.tween_property(_subtitle, "scale", Vector2.ONE, 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.08)
	fade_in.tween_property(_title, "modulate:a", 1.0, 0.18).set_delay(0.12)
	fade_in.tween_property(_title, "scale", Vector2.ONE, 0.92).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_delay(0.12)
	if _intro_effect != null:
		fade_in.tween_property(_intro_effect, "modulate:a", 0.92, 0.24)
		fade_in.tween_property(_intro_effect, "scale", Vector2(1.12, 1.12), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if _intro_effect != null and intro_sheet != null:
		await _play_sheet_frames(_intro_effect, intro_sheet, 0.18)
	else:
		await get_tree().create_timer(0.55).timeout
	# Let the scale tween reach full size and hold briefly before the title fades.
	await get_tree().create_timer(0.72).timeout

	var title_out := create_tween()
	title_out.set_parallel(true)
	title_out.tween_property(_title, "modulate:a", 0.0, 0.28)
	title_out.tween_property(_subtitle, "modulate:a", 0.0, 0.28)
	if _intro_effect != null:
		title_out.tween_property(_intro_effect, "modulate:a", 0.0, 0.28)
	await title_out.finished


func reveal_battlefield() -> void:
	if not is_playing():
		return
	var reveal := create_tween()
	reveal.set_parallel(true)
	if _mask != null:
		reveal.tween_property(_mask, "color:a", 0.0, 0.16)
	if _intro_effect != null:
		reveal.tween_property(_intro_effect, "modulate:a", 0.0, 0.12)
	if _title != null:
		reveal.tween_property(_title, "modulate:a", 0.0, 0.12)
	if _subtitle != null:
		reveal.tween_property(_subtitle, "modulate:a", 0.0, 0.12)
	await reveal.finished
	# The root intentionally remains alive and transparent so a later
	# play_fullscreen_effect() can add the authored impact above the battle.


func play_fullscreen_effect(skill_id: StringName, impact_sfx_path: String = "") -> void:
	if not is_playing() or not FULLSCREEN_EFFECTS.has(skill_id):
		return
	var config: Dictionary = FULLSCREEN_EFFECTS[skill_id]
	var frame_paths: Array = config.get("frames", []) as Array
	if frame_paths.size() != 4:
		return
	var frames: Array[Texture2D] = []
	for raw_path in frame_paths:
		var path := String(raw_path)
		if path.is_empty() or not ResourceLoader.exists(path):
			return
		var loaded_frame := load(path) as Texture2D
		if loaded_frame == null:
			return
		frames.append(loaded_frame)
	var effect := TextureRect.new()
	effect.name = "FullscreenLegendaryEffect"
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.position = Vector2.ZERO
	effect.size = get_viewport_rect().size
	effect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	effect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	effect.material = _additive_material
	effect.modulate = Color(1.0, 1.0, 1.0, 0.98)
	_active_root.add_child(effect)

	var flash := ColorRect.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.position = Vector2.ZERO
	flash.size = get_viewport_rect().size
	flash.color = Color(1.0, 0.73, 0.28, 0.0)
	_active_root.add_child(flash)

	var frame_seconds := float(config.get("frame_seconds", 0.16))
	for frame_index in range(4):
		effect.texture = frames[frame_index]
		if frame_index == 2:
			if not impact_sfx_path.is_empty():
				var event_bus := get_node_or_null("/root/EventBus")
				if event_bus != null:
					event_bus.emit_signal("sfx_requested", impact_sfx_path, 0.0)
			flash.color.a = 0.34
			var impact_flash := create_tween()
			impact_flash.tween_property(flash, "color:a", 0.0, frame_seconds * 1.4)
		await get_tree().create_timer(frame_seconds).timeout

	var linger := create_tween()
	linger.set_parallel(true)
	linger.tween_property(effect, "modulate:a", 0.0, 0.55)
	linger.tween_property(effect, "scale", Vector2(1.04, 1.04), 0.55)
	await linger.finished
	effect.queue_free()
	flash.queue_free()


func finish() -> void:
	if not is_playing():
		return
	var root_to_free := _active_root
	var fade_out := create_tween()
	fade_out.set_parallel(true)
	fade_out.tween_property(root_to_free, "modulate:a", 0.0, 0.46)
	if _mask != null:
		fade_out.tween_property(_mask, "color:a", 0.0, 0.46)
	await fade_out.finished
	if is_instance_valid(root_to_free):
		root_to_free.queue_free()
	_reset_refs()


func _load_intro_sheet(animation_id: StringName) -> Texture2D:
	if INTRO_EFFECTS.has(animation_id):
		var intro_path := String(INTRO_EFFECTS[animation_id])
		if ResourceLoader.exists(intro_path):
			return load(intro_path) as Texture2D
	var config := BattleVfxPlayer.get_effect_config(animation_id)
	var path := String(config.get("sheet", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _play_sheet_frames(target: TextureRect, sheet: Texture2D, frame_seconds: float) -> void:
	var frame_size := Vector2(sheet.get_width() * 0.5, sheet.get_height() * 0.5)
	for frame_index in range(4):
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(
			float(frame_index % 2) * frame_size.x,
			float(frame_index / 2) * frame_size.y,
			frame_size.x,
			frame_size.y
		)
		target.texture = frame
		await get_tree().create_timer(frame_seconds).timeout


func _make_center_label(text_value: String, font_size: int, color: Color, view_size: Vector2, outline_size: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text_value
	label.position = Vector2(0.0, view_size.y * 0.5)
	label.size = Vector2(view_size.x, 104.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", MANUAL_CALLIGRAPHY_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.055, 0.018, 0.94))
	label.add_theme_constant_override("outline_size", outline_size)
	label.add_theme_color_override("font_shadow_color", Color(0.50, 0.22, 0.035, 0.58))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 4)
	return label


func _clear_immediately() -> void:
	if _active_root != null and is_instance_valid(_active_root):
		_active_root.queue_free()
	_reset_refs()


func _reset_refs() -> void:
	_active_root = null
	_mask = null
	_intro_effect = null
	_title = null
	_subtitle = null
