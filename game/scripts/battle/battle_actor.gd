class_name BattleActor
extends Control

## 战斗单位视图。只负责姿态、位移与受击反馈，不参与数值结算。
const VICTORY_MUSIC := "res://art/audio/bgm/bgm_victory_wuxia_cadence_20261109.wav"
const HERO_COMBAT := preload("res://scripts/appearance/hero_combat_motion.gd")

@onready var artwork: TextureRect = %Artwork
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var mana_bar: ProgressBar = %ManaBar
@onready var mana_label: Label = %ManaLabel

signal sound_requested(cue: StringName)
signal strike_reached
var unit_id: StringName = &""
var home_position: Vector2
var ready_frames: Array[Texture2D] = []
var move_frames: Array[Texture2D] = []
var attack_frames: Array[Texture2D] = []
var default_attack_frames: Array[Texture2D] = []
var action_pose: String = ""
var combat_clip: String = ""
var action_skill: Skill
var combat_frame: int = 0
var legendary_choreography: bool = false
var hit_frames: Array[Texture2D] = []
var defeat_frames: Array[Texture2D] = []
var retain_on_defeat := false
var victory_frame: int = -1
var _attack_frame_duration: float = 0.22
var _reaction_frame_duration: float = 0.10
var _action_time_scale: float = 1.0
var stepped_combat := false

var _home_position: Vector2
var _home_scale: Vector2
var _attack_direction: float = 1.0
var _idle_direction: float = 1.0
var _visual_direction: float = 1.0
var _last_recoil_direction: float = -1.0
var _action_frames_face_right: bool = false
var _visual_frames: Array[Texture2D] = []
var _visual_clock: float = 0.0
var _visual_frame_index: int = 0
var _visual_frame_duration: float = 0.14
var _manual_animation: bool = false
var _defeated: bool = false
var _idle_motion_clock: float = 0.0
var _idle_motion_phase: float = 0.0
var _idle_motion_strength: float = 1.0
var _idle_motion_speed: float = 1.0
var _idle_visual_active: bool = false
var _held_windup: Texture2D
var _action_depth_restore: int = 0
var _action_depth_overridden: bool = false


func _ready() -> void:
	var bar_background := StyleBoxFlat.new()
	bar_background.bg_color = Color(0.03, 0.05, 0.05, 0.90)
	bar_background.border_color = Color(0.72, 0.66, 0.42, 0.85)
	bar_background.set_border_width_all(1)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.20, 0.72, 0.33, 0.96)
	health_bar.add_theme_stylebox_override("background", bar_background)
	health_bar.add_theme_stylebox_override("fill", bar_fill)
	var mana_background := bar_background.duplicate() as StyleBoxFlat
	var mana_fill := StyleBoxFlat.new()
	mana_fill.bg_color = Color(0.20, 0.56, 0.92, 0.96)
	mana_bar.add_theme_stylebox_override("background", mana_background)
	mana_bar.add_theme_stylebox_override("fill", mana_fill)
	# Runtime breathing scales around the visible foot line, not the transparent
	# canvas bottom. This keeps the platform contact point stable.
	artwork.pivot_offset = Vector2(size.x * 0.5, size.y * 0.82)


func _process(delta: float) -> void:
	if _manual_animation or _defeated:
		_reset_idle_motion()
		return
	_update_idle_motion(delta)
	if _visual_frames.size() <= 1:
		return
	_visual_clock += delta * (_idle_motion_speed if _idle_visual_active else 1.0)
	if _visual_clock < _visual_frame_duration:
		return
	_visual_clock = 0.0
	_visual_frame_index = (_visual_frame_index + 1) % _visual_frames.size()
	_set_artwork_texture(_visual_frames[_visual_frame_index])


func configure(texture: Texture2D, initial_flip_h: bool, authored_face_right: bool, idle_frames: Array[Texture2D] = [], movement_frames: Array[Texture2D] = [], frames: Array[Texture2D] = [], reaction_frames: Array[Texture2D] = [], defeat_reaction_frames: Array[Texture2D] = []) -> void:
	_held_windup = null
	ready_frames = idle_frames
	move_frames = movement_frames
	artwork.texture = ready_frames[0] if not ready_frames.is_empty() else texture
	artwork.flip_h = initial_flip_h
	_action_frames_face_right = authored_face_right
	# These legacy arguments describe the intended formation facing. Individual
	# textures can disagree with that default and are corrected when displayed.
	_idle_direction = 1.0 if authored_face_right != initial_flip_h else -1.0
	_visual_direction = _idle_direction
	_last_recoil_direction = -_idle_direction
	attack_frames = frames
	default_attack_frames = frames.duplicate()
	hit_frames = reaction_frames
	defeat_frames = defeat_reaction_frames
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_set_visual_state(ready_frames, 0.16)


func _set_visual_state(frames: Array[Texture2D], frame_duration: float) -> void:
	if _held_windup != null and frames == ready_frames:
		frames = [_held_windup]
	_visual_frames = frames
	_visual_frame_duration = frame_duration
	_visual_clock = 0.0
	_visual_frame_index = 0
	_idle_visual_active = not frames.is_empty() and frames == ready_frames
	if not frames.is_empty():
		_set_artwork_texture(frames[0])


func set_idle_motion_profile(strength: float, phase_key: StringName, speed: float = 1.0) -> void:
	_idle_motion_strength = clampf(strength, 0.0, 1.5)
	_idle_motion_phase = float(abs(hash(String(phase_key))) % 628) / 100.0
	_idle_motion_speed = speed


func _update_idle_motion(delta: float) -> void:
	if not _idle_visual_active or _idle_motion_strength <= 0.0:
		_reset_idle_motion()
		return
	_idle_motion_clock += delta * _idle_motion_speed
	var wave := sin(_idle_motion_clock * 2.15 + _idle_motion_phase)
	var sway := sin(_idle_motion_clock * 1.05 + _idle_motion_phase * 0.7)
	artwork.scale = Vector2(1.0 - wave * 0.0025 * _idle_motion_strength, 1.0 + wave * 0.0065 * _idle_motion_strength)
	artwork.rotation = sway * 0.0035 * _idle_motion_strength


func _reset_idle_motion() -> void:
	artwork.scale = Vector2.ONE
	artwork.rotation = 0.0

func set_action_frames(frames: Array[Texture2D], visual_pose := "") -> void:
	attack_frames = default_attack_frames if frames.is_empty() else frames
	action_pose = visual_pose


func set_action_time_scale(value: float) -> void:
	_action_time_scale = clampf(value, 0.70, 1.60)


func play_enter(from_left: bool) -> void:
	sound_requested.emit(&"ready")
	_capture_home()
	var direction: float = -1.0 if from_left else 1.0
	position = _home_position + Vector2(180.0 * direction, 18.0)
	_set_visual_state(move_frames, 0.09)
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", _home_position, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.20)
	tween.tween_property(self, "scale", _home_scale * 1.04, 0.18)
	tween.chain().tween_property(self, "scale", _home_scale, 0.16)
	await tween.finished
	_set_visual_state(ready_frames, 0.16)


func play_attack(target: Control, is_skill: bool) -> void:
	await play_attack_approach(target, is_skill)
	await play_attack_recover()


func clear_held_windup() -> void:
	if _held_windup == null:
		return
	var showing_windup := _visual_frames.has(_held_windup)
	_held_windup = null
	if showing_windup and not _defeated:
		_set_visual_state(ready_frames, 0.16)


func play_boss_windup(target: Control, advancing: bool, hold_pose := false) -> void:
	_capture_home()
	if target != null:
		var direction := signf(target.get_global_rect().get_center().x - get_global_rect().get_center().x)
		_set_attack_facing(direction if not is_zero_approx(direction) else _idle_direction)
	_manual_animation = true
	var pose := attack_frames.front() as Texture2D if not attack_frames.is_empty() else artwork.texture
	if hold_pose:
		_held_windup = pose
	_set_artwork_texture(pose)
	var anticipation := Vector2(-_visual_direction * 12.0, 6.0) if advancing else Vector2(0.0, -5.0)
	var windup := create_tween()
	windup.tween_property(self, "position", _home_position + anticipation, 0.22).set_trans(Tween.TRANS_SINE)
	windup.tween_interval(0.22)
	windup.tween_property(self, "position", _home_position, 0.16).set_trans(Tween.TRANS_SINE)
	await windup.finished
	_manual_animation = false
	_visual_direction = _idle_direction
	_set_visual_state(ready_frames, 0.16)


func play_boss_pounce(target: Control) -> void:
	_capture_home()
	_adopt_contact_depth(target)
	_attack_direction = signf(target.get_global_rect().get_center().x - get_global_rect().get_center().x)
	if is_zero_approx(_attack_direction):
		_attack_direction = _idle_direction
	_set_attack_facing(_attack_direction)
	var landing := _contact_position(target)
	var takeoff := _home_position + Vector2(-_attack_direction * 20.0, 7.0)
	_manual_animation = true
	if not move_frames.is_empty():
		_set_artwork_texture(move_frames.front())
	var crouch := create_tween()
	crouch.tween_property(self, "position", takeoff, 0.22).set_trans(Tween.TRANS_SINE)
	await crouch.finished
	if move_frames.size() > 1:
		_set_artwork_texture(move_frames[1])
	var leap := create_tween()
	leap.tween_method(func(progress: float) -> void:
		position = takeoff.lerp(landing, progress) + Vector2(0.0, -64.0 * sin(PI * progress))
	, 0.0, 1.0, 0.32)
	await leap.finished
	if attack_frames.size() > 1:
		_set_artwork_texture(attack_frames[1])
	sound_requested.emit(&"attack")
	strike_reached.emit()
	await get_tree().create_timer(0.18).timeout
	_manual_animation = false
	_set_visual_state(ready_frames, 0.16)


func play_stationary_attack(target: Control, is_skill: bool) -> void:
	_capture_home()
	if target != null:
		_attack_direction = signf(target.get_global_rect().get_center().x - get_global_rect().get_center().x)
	if is_zero_approx(_attack_direction):
		_attack_direction = 1.0
	_set_attack_facing(_attack_direction)
	if HERO_COMBAT.available(self):
		await HERO_COMBAT.stationary(self, not is_skill)
	elif not attack_frames.is_empty():
		await _play_attack_frames(not is_skill)
	else:
		await _play_fallback_strike(not is_skill)
	position = _home_position
	rotation = 0.0
	scale = _home_scale
	modulate = Color.WHITE
	_visual_direction = _idle_direction
	_set_visual_state(ready_frames, 0.16)


func play_attack_approach(target: Control, is_skill: bool) -> void:
	if HERO_COMBAT.available(self):
		await HERO_COMBAT.approach(self, target, is_skill)
		return
	_capture_home()
	_adopt_contact_depth(target)
	_attack_direction = signf(target.get_global_rect().get_center().x - get_global_rect().get_center().x)
	if is_zero_approx(_attack_direction):
		_attack_direction = 1.0
	_set_attack_facing(_attack_direction)
	var contact_position: Vector2 = _contact_position(target)
	if _has_stepped_combat():
		await _travel_on_authored_steps(contact_position, false)
		await _play_attack_frames(not is_skill)
		_set_visual_state(ready_frames, 0.16)
		return
	_set_visual_state(move_frames, 0.08)
	var windup: Tween = create_tween()
	var anticipation := _home_position + Vector2(-_attack_direction * 20.0, 8.0)
	var mid_step := _home_position.lerp(contact_position, 0.52) + Vector2(0.0, 4.0)
	windup.tween_property(self, "position", anticipation, 0.16 * _action_time_scale)
	windup.tween_property(self, "position", mid_step, 0.18 * _action_time_scale).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	windup.tween_property(self, "position", contact_position, 0.22 * _action_time_scale).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await windup.finished
	# Keep the contact pose visible for one short beat. Damage/VFX are triggered
	# by the controller after this function returns, so the actor must be still
	# at the target before the authored strike frames begin.
	await get_tree().create_timer(0.14 * _action_time_scale).timeout
	# Action art is intentionally played at contact, not while the actor is
	# standing in its formation slot. Skills use the same physical contract.
	if not attack_frames.is_empty():
		await _play_attack_frames(not is_skill)
	else:
		# Every combatant still needs a readable strike even before its dedicated
		# sprite sequence is available. This is deliberately a short body lunge,
		# not a static slide: authored action frames replace it automatically.
		await _play_fallback_strike(not is_skill)
	# Damage/VFX resolution can hold the actor at contact for several frames.
	# Show the battle-ready pose during that beat; movement resumes only when
	# the recovery trip back to formation actually starts.
	_set_visual_state(ready_frames, 0.16)


func _has_stepped_combat() -> bool:
	return stepped_combat and move_frames.size() > 1 and not attack_frames.is_empty()


func _travel_on_authored_steps(destination: Vector2, backward: bool) -> void:
	var origin := position
	var distance := origin.distance_to(destination)
	if distance < 1.0:
		return
	_manual_animation = true
	var count := move_frames.size()
	var steps := count * maxi(1, ceili(distance / 340.0))
	var travel := create_tween()
	travel.tween_method(func(t: float):
		var step := mini(steps - 1, int(t * steps)) % count
		_set_artwork_texture(move_frames[count - 1 - step if backward else step])
		position = origin.lerp(destination, t)
	, 0.0, 1.0, clampf(distance / 1450.0, 0.18, 0.38)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await travel.finished
	position = destination
	_manual_animation = false


func play_shadow_dash_through(target: Control, _is_skill: bool) -> void:
	_capture_home()
	_adopt_contact_depth(target)
	_attack_direction = signf(target.get_global_rect().get_center().x - get_global_rect().get_center().x)
	if is_zero_approx(_attack_direction):
		_attack_direction = 1.0
	_set_attack_facing(_attack_direction)
	var contact_position := _contact_position(target)
	var pass_position := contact_position + Vector2(_attack_direction * 118.0, -8.0)
	_set_visual_state(move_frames if not move_frames.is_empty() else ready_frames, 0.045)
	var windup := create_tween()
	windup.tween_property(self, "position", _home_position + Vector2(-_attack_direction * 20.0, 6.0), 0.12 * _action_time_scale)
	await windup.finished
	modulate.a = 0.48
	var has_signature := attack_frames != default_attack_frames
	var use_contact_strike := not attack_frames.is_empty() and (has_signature or (action_skill != null and action_skill.skill_id == &"masked_crosscut"))
	for destination: Vector2 in [contact_position, pass_position]:
		_spawn_afterimage(Color(0.52, 0.86, 1.0, 0.62))
		var dash := create_tween()
		dash.tween_property(self, "position", destination, 0.14 * _action_time_scale).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		await dash.finished
		if use_contact_strike and destination == contact_position:
			modulate.a = 1.0
			await _play_attack_frames(true)
			_set_visual_state(move_frames if not move_frames.is_empty() else ready_frames, 0.045)
			modulate.a = 0.48
	if not use_contact_strike:
		sound_requested.emit(&"attack")
		strike_reached.emit()
	_spawn_afterimage(Color(0.74, 0.54, 1.0, 0.74))
	modulate.a = 0.88
	_set_visual_state(ready_frames, 0.16)


func play_shadow_flurry(target: Control, _is_skill: bool, use_attack_frames: bool = false) -> void:
	_capture_home()
	_adopt_contact_depth(target)
	_attack_direction = signf(target.get_global_rect().get_center().x - get_global_rect().get_center().x)
	if is_zero_approx(_attack_direction):
		_attack_direction = 1.0
	_set_attack_facing(_attack_direction)
	var contact_position := _contact_position(target)
	var pass_position := contact_position + Vector2(_attack_direction * 132.0, -4.0)
	var path: Array[Vector2] = [
		contact_position + Vector2(-_attack_direction * 44.0, -34.0),
		contact_position + Vector2(_attack_direction * 30.0, 22.0),
		contact_position + Vector2(-_attack_direction * 18.0, -10.0),
		pass_position,
	]
	_set_visual_state(move_frames if not move_frames.is_empty() else ready_frames, 0.035)
	modulate.a = 0.30
	for index in range(path.size()):
		_spawn_afterimage(Color(0.62, 0.42 + index * 0.05, 1.0, 0.68))
		var dash := create_tween()
		dash.set_parallel(true)
		dash.tween_property(self, "position", path[index], 0.11 * _action_time_scale).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
		dash.tween_property(self, "rotation", _attack_direction * (0.035 if index % 2 == 0 else -0.035), 0.11 * _action_time_scale)
		await dash.finished
		if index == 1:
			if use_attack_frames and not attack_frames.is_empty():
				modulate.a = 1.0
				await _play_attack_frames(true)
				modulate.a = 0.30
			else:
				sound_requested.emit(&"attack")
				strike_reached.emit()
	_spawn_afterimage(Color(0.82, 0.70, 1.0, 0.78))
	rotation = 0.0
	modulate.a = 0.84
	_set_visual_state(ready_frames, 0.16)


func _spawn_afterimage(tint: Color, offset := Vector2.ZERO, lifetime := 0.22) -> void:
	var parent := get_parent() as CanvasItem
	if parent == null or artwork.texture == null:
		return
	var artwork_transform := parent.get_global_transform_with_canvas().affine_inverse() * artwork.get_global_transform_with_canvas()
	var ghost := TextureRect.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.texture = artwork.texture
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ghost.flip_h = artwork.flip_h
	ghost.position = artwork_transform.origin + offset
	ghost.size = artwork.size
	ghost.scale = artwork_transform.get_scale()
	ghost.rotation = artwork_transform.get_rotation()
	ghost.z_index = z_index - 1
	ghost.modulate = tint
	parent.add_child(ghost)
	var fade := ghost.create_tween()
	fade.set_parallel(true)
	fade.tween_property(ghost, "modulate:a", 0.0, lifetime)
	fade.tween_property(ghost, "scale", ghost.scale * Vector2(1.04, 0.98), lifetime)
	fade.chain().tween_callback(ghost.queue_free)


func play_attack_recover() -> void:
	if _defeated:
		return
	if HERO_COMBAT.available(self):
		await HERO_COMBAT.recover(self)
		return
	if _has_stepped_combat():
		await _travel_on_authored_steps(_home_position, (_home_position.x - position.x) * _attack_direction < 0.0)
	else:
		_set_visual_state(move_frames, 0.09)
		var recover: Tween = create_tween()
		recover.set_parallel(true)
		recover.tween_property(self, "position", _home_position, 0.28 * _action_time_scale).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		recover.tween_property(self, "rotation", _attack_direction * 0.025, 0.10 * _action_time_scale)
		recover.chain().tween_property(self, "rotation", 0.0, 0.18 * _action_time_scale)
		await recover.finished
	_restore_formation_depth()
	modulate = Color.WHITE
	_visual_direction = _idle_direction
	_set_visual_state(ready_frames, 0.16)


func _set_attack_facing(direction: float) -> void:
	_visual_direction = direction
	_set_artwork_texture(artwork.texture)


func _contact_position(target: Control) -> Vector2:
	if target == null:
		return _home_position + Vector2(_attack_direction * 92.0, -10.0)
	var target_rect: Rect2 = target._visible_art_rect() if target is BattleActor else target.get_global_rect()
	var attacker_rect: Rect2 = _visible_art_rect()
	var desired_contact_global := Vector2.ZERO
	var attacker_contact_global := Vector2.ZERO
	if _attack_direction > 0.0:
		desired_contact_global = Vector2(target_rect.position.x - 18.0, target_rect.end.y)
		attacker_contact_global = Vector2(attacker_rect.end.x, attacker_rect.end.y)
	else:
		desired_contact_global = Vector2(target_rect.end.x + 18.0, target_rect.end.y)
		attacker_contact_global = Vector2(attacker_rect.position.x, attacker_rect.end.y)
	var parent_canvas := get_parent() as CanvasItem
	if parent_canvas == null:
		return _home_position
	var inverse: Transform2D = parent_canvas.get_global_transform_with_canvas().affine_inverse()
	var global_delta: Vector2 = desired_contact_global - attacker_contact_global
	var local_delta: Vector2 = inverse * global_delta - inverse * Vector2.ZERO
	return position + local_delta


func _visible_art_rect() -> Rect2:
	var control_rect := artwork.get_global_rect()
	var texture := artwork.texture
	if texture == null:
		return control_rect
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return control_rect
	var display_scale := minf(control_rect.size.x / texture_size.x, control_rect.size.y / texture_size.y)
	var displayed_size := texture_size * display_scale
	var displayed_origin := control_rect.position + (control_rect.size - displayed_size) * 0.5
	var image := texture.get_image()
	if image == null:
		return Rect2(displayed_origin, displayed_size)
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO:
		return Rect2(displayed_origin, displayed_size)
	var used_position := Vector2(used.position)
	# AtlasTexture.get_image() returns the region without its drawing margin.
	if texture is AtlasTexture:
		used_position += texture.margin.position
	if artwork.flip_h:
		used_position.x = texture_size.x - used_position.x - float(used.size.x)
	return Rect2(displayed_origin + used_position * display_scale, Vector2(used.size) * display_scale)


func set_health(hp: int, max_hp: int, defeated: bool = false) -> void:
	if health_bar == null:
		return
	health_bar.max_value = max(1, max_hp)
	health_bar.value = max(0, hp)
	health_bar.modulate = Color(0.50, 0.50, 0.50, 0.72) if defeated else Color.WHITE
	health_label.text = "气 %d/%d" % [maxi(0, hp), maxi(1, max_hp)]
	health_label.modulate = health_bar.modulate


func set_mana(mp: int, max_mp: int, defeated: bool = false) -> void:
	if mana_bar == null:
		return
	mana_bar.max_value = max(1, max_mp)
	mana_bar.value = max(0, mp)
	mana_bar.modulate = Color(0.50, 0.50, 0.50, 0.72) if defeated else Color.WHITE
	mana_label.text = "内 %d/%d" % [maxi(0, mp), maxi(0, max_mp)]
	mana_label.modulate = mana_bar.modulate


func set_embedded_status_visible(value: bool) -> void:
	health_bar.visible = value
	health_label.visible = value
	mana_bar.visible = value
	mana_label.visible = value


func _play_attack_frames(play_default_sfx: bool) -> void:
	if HERO_COMBAT.available(self):
		await HERO_COMBAT.strike(self, play_default_sfx)
		return
	var original_texture: Texture2D = artwork.texture
	var impact_index: int = maxi(0, attack_frames.size() / 2)
	var quick := _has_stepped_combat()
	_manual_animation = true
	for index in range(attack_frames.size()):
		_set_artwork_texture(attack_frames[index])
		if index == impact_index:
			if play_default_sfx:
				sound_requested.emit(&"attack")
			strike_reached.emit()
		var hold := _attack_frame_duration * _action_time_scale
		if quick:
			hold = (0.064 if index == 0 or index == impact_index else 0.047) * clampf(_action_time_scale, 0.9, 1.25)
		await get_tree().create_timer(hold).timeout
	if not quick:
		_set_artwork_texture(original_texture)
	_manual_animation = false


func _play_fallback_strike(play_default_sfx: bool) -> void:
	var contact_position: Vector2 = position
	var strike: Tween = create_tween()
	strike.set_parallel(true)
	strike.tween_property(self, "position", position + Vector2(_attack_direction * 20.0, -5.0), 0.14 * _action_time_scale).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	strike.tween_property(self, "rotation", _attack_direction * 0.09, 0.14 * _action_time_scale)
	strike.tween_property(self, "scale", _home_scale * Vector2(1.06, 0.96), 0.14 * _action_time_scale)
	await strike.finished
	if play_default_sfx:
		sound_requested.emit(&"attack")
	strike_reached.emit()
	var settle: Tween = create_tween()
	settle.set_parallel(true)
	settle.tween_property(self, "position", contact_position, 0.16 * _action_time_scale).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	settle.tween_property(self, "rotation", 0.0, 0.16 * _action_time_scale)
	settle.tween_property(self, "scale", _home_scale, 0.16 * _action_time_scale)
	await settle.finished


func _play_frames(frames: Array[Texture2D], duration: float, hold_last: bool = false) -> void:
	var original_texture: Texture2D = artwork.texture
	_manual_animation = true
	for frame in frames:
		_set_artwork_texture(frame)
		await get_tree().create_timer(duration).timeout
	if not hold_last:
		_set_artwork_texture(original_texture)
	_manual_animation = false


func play_cast() -> void:
	if HERO_COMBAT.can_cast(self):
		await HERO_COMBAT.cast(self)
		return
	_capture_home()
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", _home_scale * 1.05, 0.25 * _action_time_scale)
	tween.tween_property(self, "modulate", Color(0.72, 0.96, 0.90, 1.0), 0.20 * _action_time_scale)
	tween.chain().tween_property(self, "scale", _home_scale, 0.35 * _action_time_scale)
	tween.chain().tween_property(self, "modulate", Color.WHITE, 0.16 * _action_time_scale)
	await tween.finished
	await get_tree().create_timer(0.24 * _action_time_scale).timeout


func play_legendary_cast() -> void:
	_capture_home()
	_manual_animation = true
	_reset_idle_motion()
	var windup := create_tween()
	windup.set_parallel(true)
	windup.tween_property(self, "position", _home_position + Vector2(0.0, 10.0), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	windup.tween_property(self, "scale", _home_scale * Vector2(0.96, 0.94), 0.28)
	windup.tween_property(self, "modulate", Color(0.72, 0.86, 0.78, 1.0), 0.28)
	await windup.finished
	var charge := create_tween()
	charge.set_parallel(true)
	charge.tween_property(self, "position", _home_position + Vector2(0.0, -10.0), 0.50).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	charge.tween_property(self, "scale", _home_scale * 1.10, 0.50)
	charge.tween_property(self, "modulate", Color(1.0, 0.82, 0.42, 1.0), 0.50)
	await charge.finished
	await get_tree().create_timer(0.30).timeout
	var release := create_tween()
	release.set_parallel(true)
	release.tween_property(self, "position", _home_position, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	release.tween_property(self, "scale", _home_scale, 0.32)
	release.tween_property(self, "modulate", Color.WHITE, 0.32)
	await release.finished
	_manual_animation = false
	_set_visual_state(ready_frames, 0.16)


func play_hit(damage: int, is_critical: bool = false, play_sound: bool = true, source: Control = null) -> void:
	var duration := start_hit_reaction(damage, is_critical, play_sound, source)
	await get_tree().create_timer(duration).timeout


func play_dodge(source: Control = null) -> void:
	var duration := start_dodge_reaction(source)
	await get_tree().create_timer(duration).timeout


func start_dodge_reaction(source: Control = null) -> float:
	## Misses need their own readable result instead of silently producing no
	## damage number. The short sidestep reinforces the text without competing
	## with authored hit/defeat sprite frames.
	_capture_home()
	_spawn_feedback_text("闪避", Color(0.50, 0.94, 1.0, 1.0), 76)
	var direction := recoil_direction_from(source)
	var tween := create_tween()
	tween.tween_property(self, "position", _home_position + Vector2(direction * 38.0, -5.0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", _home_position, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	return 0.32


func start_hit_reaction(damage: int, is_critical: bool = false, play_sound: bool = true, source: Control = null) -> float:
	## Starts the complete hit presentation without awaiting it. Group skills call
	## this on every target in the same frame, then wait only for the longest one.
	if play_sound:
		sound_requested.emit(&"hit")
	_capture_home()
	_spawn_damage_number(damage, is_critical)
	var original_texture: Texture2D = artwork.texture
	_manual_animation = true
	# Recoil follows the actual strike origin, including a dash-through attacker
	# now behind the victim. DoT has no source and recoils away from idle facing.
	var direction := recoil_direction_from(source)
	_last_recoil_direction = direction
	_visual_direction = -direction
	var sequence := create_tween()
	for frame: Texture2D in hit_frames:
		sequence.tween_callback(_set_artwork_texture.bind(frame))
		sequence.tween_interval(_reaction_frame_duration)
	sequence.tween_callback(_set_artwork_texture.bind(original_texture))
	sequence.tween_property(self, "position", _home_position + Vector2(direction * 26.0, 7.0), 0.09)
	sequence.parallel().tween_property(self, "modulate", Color(1.0, 0.48, 0.48, 1.0), 0.08)
	sequence.tween_property(self, "position", _home_position, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sequence.parallel().tween_property(self, "modulate", Color.WHITE, 0.12)
	sequence.tween_callback(func() -> void:
		_manual_animation = false
		_visual_direction = _idle_direction
		_set_visual_state(ready_frames, 0.16)
	)
	return float(hit_frames.size()) * _reaction_frame_duration + 0.29


func recoil_direction_from(source: Control) -> float:
	if source != null and is_instance_valid(source):
		var delta_x := get_global_rect().get_center().x - source.get_global_rect().get_center().x
		if not is_zero_approx(delta_x):
			return signf(delta_x)
	return -_idle_direction


func play_defend() -> void:
	sound_requested.emit(&"defend")
	_capture_home()
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", _home_position + Vector2(0.0, 12.0), 0.12)
	tween.tween_property(self, "modulate", Color(0.58, 0.78, 1.0, 1.0), 0.12)
	tween.chain().tween_property(self, "position", _home_position, 0.20)
	tween.chain().tween_property(self, "modulate", Color.WHITE, 0.16)
	await tween.finished


func play_player_victory() -> void:
	if _defeated:
		return
	_manual_animation = true
	_visual_direction = _idle_direction
	# One celebration, with a held crest before the arm comes back down.
	var durations := [0.13, 0.16, 0.34, 0.21]
	for frame in durations.size():
		victory_frame = frame
		await get_tree().create_timer(durations[frame]).timeout
	victory_frame = -1
	_manual_animation = false
	_set_visual_state(ready_frames, 0.16)


func play_victory() -> void:
	sound_requested.emit(&"victory")
	_capture_home()
	# Existing opponent celebration after the player loses.
	if not attack_frames.is_empty():
		await _play_attack_frames(false)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", _home_position + Vector2(0.0, -22.0), 0.20)
	tween.tween_property(self, "rotation", deg_to_rad(-5.0), 0.20)
	tween.chain().tween_property(self, "position", _home_position, 0.34)
	tween.parallel().tween_property(self, "rotation", 0.0, 0.34)
	await tween.finished


func play_defeat() -> void:
	var duration := start_defeat_reaction()
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout


func start_defeat_reaction() -> float:
	## Non-blocking counterpart used when several targets fall to one group hit.
	if _defeated:
		return 0.0
	sound_requested.emit(&"defeat")
	_capture_home()
	_defeated = true
	_manual_animation = true
	_visual_direction = -_last_recoil_direction
	var sequence := create_tween()
	for frame: Texture2D in defeat_frames:
		sequence.tween_callback(_set_artwork_texture.bind(frame))
		sequence.tween_interval(_reaction_frame_duration)
	if retain_on_defeat:
		set_embedded_status_visible(false)
		if not defeat_frames.is_empty():
			return float(defeat_frames.size()) * _reaction_frame_duration
		# Keep a grounded falling pose even if the actor has no defeat artwork.
		sequence.tween_property(self, "rotation", _last_recoil_direction * PI * 0.5, 0.24)
		return 0.24
	sequence.tween_property(self, "position", _home_position + Vector2(_last_recoil_direction * 18.0, 12.0), 0.52)
	sequence.parallel().tween_property(self, "modulate:a", 0.0, 0.48)
	return float(defeat_frames.size()) * _reaction_frame_duration + 0.54


func _set_artwork_texture(texture: Texture2D) -> void:
	artwork.texture = texture
	artwork.flip_h = (_visual_direction > 0.0) != BattleSpriteFacing.faces_right(texture, _action_frames_face_right)


func _capture_home() -> void:
	_home_position = position
	_home_scale = scale


func _adopt_contact_depth(target: Control) -> void:
	## Formation Y describes the combatant's ground contact.  An attacker that
	## starts above its target must stay behind that target while crossing the
	## same patch of ground; raising every active unit made rear attackers cover
	## the front row regardless of perspective.
	_action_depth_restore = int(get_meta("formation_depth_z", z_index))
	_action_depth_overridden = true
	if target == null:
		z_index = _action_depth_restore
		return
	var target_depth := int(target.get_meta("formation_depth_z", target.z_index))
	var target_home_y := target.position.y
	if target is BattleActor:
		target_home_y = (target as BattleActor).home_position.y
	z_index = target_depth - 1 if home_position.y < target_home_y else target_depth + 1


func _restore_formation_depth() -> void:
	if not _action_depth_overridden:
		return
	z_index = _action_depth_restore
	_action_depth_overridden = false


func _spawn_damage_number(damage: int, is_critical: bool = false) -> void:
	var label: Label = Label.new()
	label.text = "暴击！\n-%d" % damage if is_critical else "-%d" % damage
	var base_font_size: int = 68
	label.add_theme_font_size_override("font_size", base_font_size if not is_critical else 96)
	label.add_theme_color_override("font_color", Color(1.0, 0.30, 0.12, 1.0) if is_critical else Color(1.0, 0.78, 0.36, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.06, 0.01, 0.01, 0.98))
	label.add_theme_constant_override("outline_size", 8 if is_critical else 3)
	label.add_theme_color_override("font_shadow_color", Color(0.10, 0.02, 0.02, 1.0))
	label.add_theme_constant_override("shadow_offset_x", 5 if is_critical else 2)
	label.add_theme_constant_override("shadow_offset_y", 5 if is_critical else 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 720
	label.size = Vector2(280.0, 190.0) if is_critical else Vector2(150.0, 90.0)
	label.position = size * 0.5 + (Vector2(-140.0, -135.0) if is_critical else Vector2(-42.0, -44.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	if is_critical:
		_spawn_critical_burst(size * 0.5 + Vector2(0.0, -34.0))
		label.pivot_offset = label.size * 0.5
		label.scale = Vector2.ONE * 0.42
	var tween: Tween = create_tween()
	if is_critical:
		tween.tween_property(label, "scale", Vector2.ONE * 1.22, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "scale", Vector2.ONE, 0.09)
		tween.tween_interval(0.72)
		tween.tween_property(label, "position:y", label.position.y - 68.0, 0.55)
		tween.parallel().tween_property(label, "modulate:a", 0.0, 0.55)
	else:
		tween.tween_interval(1.35)
		tween.tween_property(label, "position:y", label.position.y - 52.0, 0.78)
		tween.parallel().tween_property(label, "modulate:a", 0.0, 0.78)
	tween.tween_callback(label.queue_free)


func _spawn_feedback_text(text: String, color: Color, font_size: int) -> void:
	var label := Label.new()
	label.name = "BattleFeedbackText"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(220.0, 100.0)
	label.position = size * 0.5 + Vector2(-110.0, -82.0)
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE * 0.55
	label.z_index = 715
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.06, 0.10, 0.98))
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2.ONE * 1.16, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.08)
	tween.tween_interval(0.48)
	tween.tween_property(label, "position:y", label.position.y - 58.0, 0.45)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.45)
	tween.tween_callback(label.queue_free)


func _spawn_critical_burst(center: Vector2) -> void:
	var burst := Node2D.new()
	burst.name = "CriticalBurst"
	burst.position = center
	burst.z_index = 710
	burst.scale = Vector2.ONE * 0.28
	add_child(burst)
	for index in 12:
		var angle := TAU * float(index) / 12.0
		var ray := Line2D.new()
		ray.width = 7.0 if index % 2 == 0 else 4.0
		ray.default_color = Color(1.0, 0.64, 0.12, 0.92)
		ray.points = PackedVector2Array([
			Vector2.from_angle(angle) * 34.0,
			Vector2.from_angle(angle) * (84.0 if index % 2 == 0 else 64.0),
		])
		burst.add_child(ray)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(burst, "scale", Vector2.ONE * 1.18, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(burst, "modulate:a", 0.0, 0.38).set_delay(0.12)
	tween.chain().tween_callback(burst.queue_free)
