extends RefCounted
## Presentation only: one native strike signal per action, no damage or RNG changes.
const AUDIO := {
	"slash": "res://art/audio/free/sfx_blade_light_wuxia_v2.wav",
	"blade": "res://art/audio/free/sfx_blade_whoosh_wuxia_v2.wav",
	"staff": "res://art/audio/free/sfx_staff_whoosh_wuxia_v2.wav",
	"palm": "res://art/audio/free/sfx_palm_burst_wuxia_v2.wav",
}
const SINGLE := {"slash": "fast_slash", "blade": "fast_blade_chop", "staff": "fast_staff", "palm": "fast_palm", "hidden": "fast_hidden_single"}
const GROUP := {"slash": "fast_sword_group", "blade": "fast_blade_group", "staff": "fast_staff_group", "palm": "fast_palm_group", "hidden": "fast_hidden_group"}
const SWORD_THRUSTS := [&"linxi_basic_sword_one", &"huashan_yijian", &"qinghe_swallow_sword", &"shadow_swallow_piercing_sword", &"huashan_poyun", &"huashan_jianduan_qianshan"]
const STAFF_THRUSTS := [&"lingyue_lingbo_yizhi", &"lingyue_hanshuang_zhen", &"tang_staff_breaker"]
const CIRCULAR_STYLES := [&"linxi_basic_sword_two", &"huashan_lanhui_sandie", &"wudang_raozhirou_sword", &"wudang_rouyun_sword", &"wudang_taiji_sword", &"snow_pass_returning_blade", &"rolling_cloud_staff_storm", &"wudang_mianzhang", &"circling_breath_palm", &"wudang_taiji_sixiang", &"wudang_taiji_liangyi"]

static func available(actor: Control) -> bool:
	if actor.unit_id != &"player":
		return false
	var runtime := actor.get_node_or_null("/root/LayeredAppearanceRuntime")
	return runtime != null and not _clip(actor, runtime.manifest.get("clips", {})).is_empty()

static func can_cast(actor: Control) -> bool:
	if actor.unit_id != &"player":
		return false
	var runtime := actor.get_node_or_null("/root/LayeredAppearanceRuntime")
	return runtime != null and runtime.manifest.get("clips", {}).has("fast_palm_group")

static func cast(actor: Control) -> void:
	var skill := actor.action_skill as Skill
	var healing := skill != null and (skill.kind == Skill.Kind.HEAL or skill.active_effect_type == &"heal_guard")
	var guarding := skill != null and skill.active_effect_type in [&"guard", &"redirect"]
	var release := 1 if healing else (3 if guarding else 2)
	actor._manual_animation = true
	actor._reset_idle_motion()
	_show(actor, "fast_palm_group", 0)
	await actor.get_tree().create_timer(0.19 if skill != null and skill.quality == Skill.Quality.LEGENDARY else 0.11).timeout
	_show(actor, "fast_palm_group", release)
	await actor.get_tree().create_timer(0.12).timeout
	_show(actor, "fast_palm_group", 0)
	await actor.get_tree().create_timer(0.065).timeout
	actor.combat_clip = ""
	actor._manual_animation = false
	actor._set_visual_state(actor.ready_frames, 0.16)

static func kind(actor: Control) -> String:
	if actor.action_pose in ["attack_fist", "attack_palm"]:
		return "palm"
	var inventory := actor.get_node("/root/Inventory")
	var equipment: Equipment = inventory.get_equipped(Equipment.Slot.WEAPON)
	var equipped := Equipment.normalize_weapon_type(equipment.weapon_type) if equipment != null else &"palm"
	return style_for(actor.action_skill, equipped)

static func style_for(skill: Skill, equipped: StringName) -> String:
	var style := equipped
	if skill != null and skill.skill_id != &"basic_attack":
		var authored := skill.get_martial_category()
		if authored in [&"sword", &"blade", &"staff", &"palm", &"hidden"]:
			style = authored
			if style == &"hidden" and skill.delivery == Skill.Delivery.MELEE and skill.motion_style >= Skill.MotionStyle.DASH_THROUGH and equipped == &"sword":
				style = &"sword"
	match style:
		&"staff": return "staff"
		&"blade": return "blade"
		&"palm": return "palm"
		&"hidden": return "hidden"
	return "slash"

static func clip_for(skill: Skill, style: String) -> String:
	return (GROUP if skill != null and skill.target == Skill.Target.ENEMY_ALL else SINGLE)[style]

static func _clip(actor: Control, clips: Dictionary) -> String:
	var style := kind(actor)
	var preferred := clip_for(actor.action_skill, style)
	if clips.has(preferred):
		if style == "palm" and actor.action_pose == "attack_fist" and clips.has("fast_palm_fist"):
			return "fast_palm_fist"
		return preferred
	var fallback := "fast_slash" if style == "blade" else String(SINGLE[style])
	return fallback if clips.has(fallback) else ""

static func _is_group(actor: Control) -> bool:
	return actor.action_skill != null and actor.action_skill.target == Skill.Target.ENEMY_ALL

static func uses_kaishan_poses(actor: Control, clips: Dictionary) -> bool:
	var skill := actor.action_skill as Skill
	return skill != null and skill.skill_id in [&"gufeng_fuhu", &"gufeng_liedi"] and clips.has("fast_blade_chop") and clips.has("fast_blade_group")

static func _profile(actor: Control, clip: String, frame_count: int) -> Dictionary:
	var skill := actor.action_skill as Skill
	var id := skill.skill_id if skill != null else &""
	var basic := id in [&"", &"basic_attack"]
	var legendary: bool = actor.legendary_choreography
	var circular := id in CIRCULAR_STYLES
	var windup := 0.040 if basic else (0.095 if legendary else 0.060)
	var travel := 0.17 if basic else (0.28 if legendary else 0.23)
	var recovery := 0.18 if basic else (0.32 if legendary else 0.24)
	var order: Array = range(frame_count)
	var impact := mini(2, frame_count - 1)
	match clip:
		"fast_slash":
			order = [0, 2, 3, 2] if id in SWORD_THRUSTS else [0, 2, 1]
		"fast_sword_group":
			order = [0, 1, 2, 3]
			impact = 3
		"fast_blade_chop":
			order = [0, 1]
			impact = 1
			windup += 0.08
		"fast_blade_group":
			order = [0, 1]
			impact = 1
		"fast_staff":
			order = [1, 2, 3, 2] if id in STAFF_THRUSTS else [0, 1, 2, 3]
			impact = 2 if id in STAFF_THRUSTS else 3
		"fast_staff_group":
			order = [0, 1, 2, 3] if id == &"heaven_pillar_staff" else [0, 2, 3]
			impact = order.size() - 1
		"fast_palm":
			order = [0, 1, 0] if actor.action_pose == "attack_fist" else ([0, 2, 3, 2] if circular or legendary else [0, 2, 0])
			impact = 2 if order.size() == 4 else 1
		"fast_palm_fist":
			order = [0, 1, 2, 3]
		"fast_palm_group":
			order = [0, 1, 2, 3]
		"fast_hidden_single", "fast_hidden_group":
			order = [0, 1]
			impact = 1
			windup += 0.025
	return {"windup": windup, "travel": travel, "recovery": recovery, "order": order, "impact": impact, "circular": circular, "basic": basic}

static func _show(actor: Control, clip: String, frame: int) -> void:
	actor.combat_clip = clip
	actor.combat_frame = frame

static func _blade_sequence(actor: Control, clips: Dictionary) -> bool:
	return kind(actor) == "blade" and clips.has("walk") and clips.has("ready_blade") and clips.has("fast_blade_group") and clips.has("fast_blade_chop") and clips.has("fast_sword_group")

static func _blade_sweeps(actor: Control) -> bool:
	var skill := actor.action_skill as Skill
	return _is_group(actor) or (skill != null and skill.skill_id in CIRCULAR_STYLES)

static func _step_frames(actor: Control, from: Vector2, to: Vector2, duration: float, backward: bool) -> void:
	var clips: Dictionary = actor.get_node("/root/LayeredAppearanceRuntime").manifest.clips
	var frame_count: int = clips.walk.frames.size()
	var step := actor.create_tween()
	# Drive feet from distance, not a single attack posture dragged by the tween.
	step.tween_method(func(t: float):
		var stride := mini(frame_count - 1, int(t * frame_count))
		_show(actor, "walk", frame_count - 1 - stride if backward else stride)
		actor.position = from.lerp(to, t)
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await step.finished
	actor.position = to

static func _blade_swing(actor: Control, contact: Vector2, play_default_sfx: bool, approach: bool) -> void:
	var sweep := _blade_sweeps(actor)
	var skill := actor.action_skill as Skill
	var basic := skill == null or skill.skill_id == &"basic_attack"
	var heavy: bool = actor.legendary_choreography or uses_kaishan_poses(actor, actor.get_node("/root/LayeredAppearanceRuntime").manifest.clips)
	var direction: float = actor._attack_direction
	var lead := Vector2(direction, 0)
	# Weight settles before the swing: low draw for a sweep, high load for a chop.
	_show(actor, "fast_blade_group" if sweep else "fast_blade_chop", 0)
	await actor.get_tree().create_timer(0.14 if heavy else (0.050 if basic else 0.080)).timeout
	if not sweep:
		_show(actor, "fast_sword_group", 1)
		await actor.get_tree().create_timer(0.045 if basic else 0.055).timeout
		_show(actor, "fast_sword_group", 2)
	else:
		_show(actor, "fast_sword_group", 0)
	var lunge := actor.create_tween()
	var impact_position := contact + lead * (15.0 if approach else 8.0)
	lunge.tween_property(actor, "position", impact_position, 0.065 if sweep else 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await lunge.finished
	_show(actor, "fast_blade_group" if sweep else "fast_blade_chop", 1)
	if play_default_sfx:
		actor.sound_requested.emit(&"attack")
	else:
		_sfx(actor, "blade", -7.0 if heavy else -9.0)
	actor.strike_reached.emit()
	# Let this pose render before the battle controller starts hit feedback.
	await actor.get_tree().process_frame

static func approach(actor: Control, target: Control, is_skill: bool) -> void:
	actor._capture_home()
	actor._adopt_contact_depth(target)
	actor._attack_direction = signf(target.get_global_rect().get_center().x - actor.get_global_rect().get_center().x)
	if is_zero_approx(actor._attack_direction):
		actor._attack_direction = 1.0
	actor._set_attack_facing(actor._attack_direction)
	actor._manual_animation = true
	actor._reset_idle_motion()
	var start: Vector2 = actor.position
	var contact: Vector2 = actor._contact_position(target)
	var style := kind(actor)
	var clips: Dictionary = actor.get_node("/root/LayeredAppearanceRuntime").manifest.clips
	var skill := actor.action_skill as Skill
	var motion := skill.motion_style if skill != null else Skill.MotionStyle.AUTO
	var leap: bool = skill != null and skill.skill_id == &"wanxiang_breaking_sword" and clips.has("fast_leap")
	var kaishan := uses_kaishan_poses(actor, clips)
	var clip := _clip(actor, clips)
	var profile := _profile(actor, clip, clips[clip].frames.size())
	if _is_group(actor):
		contact = start.lerp(contact, 0.50 if style in ["slash", "blade", "staff"] else 0.34)
	if _blade_sequence(actor, clips):
		_show(actor, "ready_blade", 1)
		await actor.get_tree().create_timer(0.055).timeout
		var plant := contact - Vector2(actor._attack_direction * 16.0, 0.0)
		await _step_frames(actor, start, plant, clampf(start.distance_to(plant) / 1900.0, 0.14, 0.27), false)
		await _blade_swing(actor, plant, not is_skill, true)
		if motion in [Skill.MotionStyle.DASH_THROUGH, Skill.MotionStyle.SHADOW_FLURRY]:
			await _pass_target(actor, target, motion == Skill.MotionStyle.SHADOW_FLURRY)
		return
	if not leap and clips.has("walk") and not kaishan:
		var plant_margin := 12.0 if style == "palm" else (9.0 if style == "hidden" else 16.0)
		var plant := contact - Vector2(float(actor._attack_direction) * plant_margin, 0.0)
		await _step_frames(actor, start, plant, clampf(start.distance_to(plant) / 1850.0, 0.14, 0.28), false)
		_show(actor, clip, profile.order[0])
		await actor.get_tree().create_timer(profile.windup).timeout
		await strike(actor, not is_skill)
		if motion in [Skill.MotionStyle.DASH_THROUGH, Skill.MotionStyle.SHADOW_FLURRY]:
			await _pass_target(actor, target, motion == Skill.MotionStyle.SHADOW_FLURRY)
		_settle_guard(actor)
		return
	_show(actor, "fast_blade_group" if kaishan else ("fast_leap" if leap else clip), 0 if kaishan or leap else profile.order[0])
	var anticipation := actor.create_tween()
	var backstep := Vector2(-actor._attack_direction * (24.0 if profile.circular or kaishan else 14.0), 5.0)
	anticipation.tween_property(actor, "position", start + backstep, 0.27 if kaishan else (0.085 if leap else profile.windup)).set_trans(Tween.TRANS_SINE)
	await anticipation.finished
	if kaishan:
		actor.combat_clip = "fast_blade_chop"
		actor.combat_frame = 0
		await actor.get_tree().create_timer(0.26 if _is_group(actor) else 0.18).timeout
	start = actor.position
	if not kaishan:
		_sfx(actor, "staff" if leap else style, -10.0)
	var travel := actor.create_tween()
	var travel_seconds: float = 0.32 if leap else (0.27 if kaishan else profile.travel)
	var arc := 64.0 if leap else (22.0 if profile.circular else 5.0)
	travel.tween_method(func(t: float):
		actor.position = start.lerp(contact, t) + Vector2(0, -sin(t * PI) * arc)
		if leap:
			actor.combat_frame = mini(3, int(t * 4.0))
	, 0.0, 1.0, travel_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await travel.finished
	actor.position = contact
	if leap:
		_show(actor, clip, profile.order[0])
		await actor.get_tree().create_timer(0.045).timeout
	await strike(actor, not is_skill)
	if motion in [Skill.MotionStyle.DASH_THROUGH, Skill.MotionStyle.SHADOW_FLURRY] and not leap:
		await _pass_target(actor, target, motion == Skill.MotionStyle.SHADOW_FLURRY)
	_settle_guard(actor)

static func _settle_guard(actor: Control) -> void:
	actor.combat_clip = ""
	actor._manual_animation = false
	actor._set_visual_state(actor.ready_frames, 0.16)

static func _pass_target(actor: Control, target: Control, flurry: bool) -> void:
	if target == null:
		return
	var stage := actor.get_parent() as Control
	if stage == null:
		return
	var target_rect := target.get_global_rect()
	var far_edge := target_rect.end.x if actor._attack_direction > 0.0 else target_rect.position.x
	var local_target := stage.get_global_transform_with_canvas().affine_inverse() * Vector2(far_edge, target_rect.get_center().y)
	var pass_position: Vector2 = actor.position
	pass_position.x = clampf(local_target.x - actor.size.x * 0.5 + actor._attack_direction * (68.0 if flurry else 36.0), -actor.size.x * 0.33, stage.size.x - actor.size.x * 0.67)
	actor._spawn_afterimage(Color(0.64, 0.74, 0.99, 0.45), Vector2.ZERO, 0.25)
	var clips: Dictionary = actor.get_node("/root/LayeredAppearanceRuntime").manifest.clips
	if clips.has("walk"):
		await _step_frames(actor, actor.position, pass_position, 0.21 if flurry else 0.16, false)
	else:
		var pass_step := actor.create_tween()
		pass_step.tween_property(actor, "position", pass_position, 0.21 if flurry else 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await pass_step.finished

static func stationary(actor: Control, play_default_sfx: bool) -> void:
	var clips: Dictionary = actor.get_node("/root/LayeredAppearanceRuntime").manifest.clips
	var clip := _clip(actor, clips)
	var profile := _profile(actor, clip, clips[clip].frames.size())
	actor._manual_animation = true
	actor._reset_idle_motion()
	if _blade_sequence(actor, clips):
		await _blade_swing(actor, actor.position, play_default_sfx, false)
		actor.combat_clip = ""
		actor._manual_animation = false
		return
	_show(actor, clip, profile.order[0])
	await actor.get_tree().create_timer(profile.windup).timeout
	await strike(actor, play_default_sfx)
	actor.combat_clip = ""
	actor._manual_animation = false

static func strike(actor: Control, play_default_sfx: bool) -> void:
	var style := kind(actor)
	var clips: Dictionary = actor.get_node("/root/LayeredAppearanceRuntime").manifest.clips
	if uses_kaishan_poses(actor, clips):
		actor.combat_clip = "fast_blade_group" if _is_group(actor) else "fast_blade_chop"
		actor.combat_frame = 1
		actor.position.x += actor._attack_direction * (22.0 if _is_group(actor) else 12.0)
		_sfx(actor, "blade", -7.0)
		actor.strike_reached.emit()
		# Carry the landed pose into the impact and hit reaction until recovery.
		await actor.get_tree().create_timer(0.14).timeout
		return
	var clip := _clip(actor, clips)
	var profile := _profile(actor, clip, clips[clip].frames.size())
	var order: Array = profile.order
	var skill := actor.action_skill as Skill
	var echoes := skill != null and (skill.motion_style == Skill.MotionStyle.SHADOW_FLURRY or skill.skill_id == &"mingwu_yinying_duoming")
	actor._manual_animation = true
	actor._reset_idle_motion()
	actor.combat_clip = clip
	var contact: Vector2 = actor.position
	var advances := {"slash": 16.0, "blade": 21.0, "staff": 13.0, "palm": 24.0, "hidden": 5.0}
	var rooted := style == "hidden" or (skill != null and (skill.motion_style == Skill.MotionStyle.STATIONARY or skill.delivery != Skill.Delivery.MELEE))
	var lead := Vector2(float(actor._attack_direction) * (0.0 if rooted else float(advances[style])), 0.0)
	for i in range(1, order.size()):
		var impact: bool = i == profile.impact
		actor.combat_frame = order[i]
		if impact:
			var release := actor.create_tween()
			release.tween_property(actor, "position", contact + lead, 0.030).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			if play_default_sfx:
				actor.sound_requested.emit(&"attack")
			elif style != "hidden":
				_sfx(actor, style, -8.0)
			actor.strike_reached.emit()
			await release.finished
			if rooted:
				# The layered renderer samples on idle frames. Keep the brief
				# throw/cast silhouette through a full update even at low FPS.
				await actor.get_tree().process_frame
				await actor.get_tree().process_frame
			continue
		if echoes and i <= profile.impact:
			actor._spawn_afterimage(Color(0.58, 0.72, 0.99, 0.45), Vector2(-actor._attack_direction * 43.0, -7.0), 0.28)
		if i > profile.impact:
			var recoil := actor.create_tween()
			recoil.tween_property(actor, "position", contact + lead * 0.25, 0.045).set_trans(Tween.TRANS_SINE)
			await recoil.finished
		else:
			await actor.get_tree().create_timer(0.052 if actor.legendary_choreography else 0.040).timeout

static func recover(actor: Control) -> void:
	var clips: Dictionary = actor.get_node("/root/LayeredAppearanceRuntime").manifest.clips
	var clip := _clip(actor, clips)
	var profile := _profile(actor, clip, clips[clip].frames.size())
	var kaishan := uses_kaishan_poses(actor, clips)
	actor._manual_animation = true
	var origin: Vector2 = actor.position
	var home: Vector2 = actor._home_position
	if _blade_sequence(actor, clips):
		_show(actor, "ready_blade", 2)
		await actor.get_tree().create_timer(0.065).timeout
		var backing: bool = (home.x - origin.x) * actor._attack_direction < 0.0
		await _step_frames(actor, origin, home, clampf(origin.distance_to(home) / 1650.0, 0.19, 0.32), backing)
	elif clips.has("walk") and not kaishan:
		var backing: bool = (home.x - origin.x) * actor._attack_direction < 0.0
		await _step_frames(actor, origin, home, clampf(origin.distance_to(home) / 1650.0, 0.18, 0.31), backing)
	else:
		_show(actor, clip, 1 if kaishan else profile.order.back())
		var retreat := actor.create_tween()
		retreat.tween_method(func(t: float):
			actor.position = origin.lerp(home, t) + Vector2(0, -sin(t * PI) * 18)
		, 0.0, 1.0, 0.30 if kaishan else profile.recovery).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await retreat.finished
	actor.position = home
	actor.rotation = 0
	actor.scale = actor._home_scale
	actor.modulate = Color.WHITE
	actor.combat_clip = ""
	actor._manual_animation = false
	actor._restore_formation_depth()
	actor._visual_direction = actor._idle_direction
	actor._set_visual_state(actor.ready_frames, 0.16)

static func _sfx(actor: Control, style: String, gain: float) -> void:
	var bus := actor.get_node_or_null("/root/EventBus")
	if bus != null:
		bus.sfx_requested.emit(AUDIO.get(style, AUDIO.slash), gain)
