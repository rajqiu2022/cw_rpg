class_name BattleVfxPlayer
extends Control

const DRAGON_SHEET := "res://art/characters/combat_forms_20261112/dragon.png"
const DRAGON_FRAMES := [Rect2(0, 0, 768, 512), Rect2(768, 0, 768, 512), Rect2(0, 512, 815, 512), Rect2(815, 512, 721, 512)]
const DRAGON_EDGE := preload("res://art/characters/combat_forms_20261112/dragon_edge.gdshader")
const ANIMAL_CONTACT := "res://art/battle_vfx/basic_weapon_v1/vfx_basic_blade_4frame_v1.png"
const ANIMAL_IMPACT := "res://art/battle_vfx/basic_weapon_v1/vfx_basic_palm_4frame_v1.png"

const EFFECTS: Dictionary = {
	&"wolf_rending_bite": {"sheet": ANIMAL_CONTACT, "size": Vector2(210, 210), "frame_seconds": 0.065, "tint": Color(0.94, 0.83, 0.74), "delivery": "melee"},
	&"animal_tiger_pounce": {"sheet": ANIMAL_CONTACT, "size": Vector2(250, 250), "frame_seconds": 0.072, "tint": Color(1.0, 0.82, 0.60), "delivery": "melee"},
	&"animal_bear_rake": {"sheet": ANIMAL_IMPACT, "size": Vector2(260, 260), "frame_seconds": 0.087, "tint": Color(0.84, 0.89, 0.96), "delivery": "melee"},
	&"animal_lion_sweep": {"sheet": ANIMAL_CONTACT, "size": Vector2(285, 285), "frame_seconds": 0.080, "tint": Color(1.0, 0.80, 0.47), "delivery": "melee"},
	&"animal_serpent_strike": {"sheet": ANIMAL_CONTACT, "size": Vector2(215, 215), "frame_seconds": 0.072, "tint": Color(0.69, 0.85, 0.57), "delivery": "melee"},
	&"animal_eagle_dive": {"sheet": ANIMAL_CONTACT, "size": Vector2(205, 205), "frame_seconds": 0.065, "tint": Color(0.81, 0.93, 1.0), "delivery": "melee"},
	&"linxi_sword_one": {
		"sheet": "res://art/battle_vfx/vfx_linxi_sword_one_4frame_v1.png",
		"size": Vector2(360, 360),
		"frame_seconds": 0.10,
		"tint": Color(0.62, 0.90, 1.0, 1.0),
		"delivery": "melee",
	},
	&"sword_arc": {
		"sheet": "res://art/battle_vfx/vfx_sword_arc_4frame_v1.png",
		"size": Vector2(320, 320),
		"frame_seconds": 0.085,
		"tint": Color(0.72, 0.92, 1.0, 1.0),
		"delivery": "melee",
	},
	&"heavy_cleave": {
		"sheet": "res://art/battle_vfx/vfx_heavy_cleave_4frame_v1.png",
		"size": Vector2(420, 420),
		"frame_seconds": 0.12,
		"tint": Color(1.0, 0.76, 0.38, 1.0),
		"delivery": "melee",
	},
	&"frost_needle": {
		"sheet": "res://art/battle_vfx/vfx_frost_needle_4frame_v1.png",
		"size": Vector2(280, 280),
		"frame_seconds": 0.075,
		"tint": Color(0.55, 0.88, 1.0, 1.0),
		"delivery": "projectile",
	},
	&"taiji": {
		"sheet": "res://art/battle_vfx/vfx_taiji_4frame_v1.png",
		"size": Vector2(360, 360),
		"frame_seconds": 0.11,
		"tint": Color(0.82, 0.94, 1.0, 1.0),
		"delivery": "melee",
	},
	&"shadow": {
		"sheet": "res://art/battle_vfx/vfx_shadow_4frame_v1.png",
		"size": Vector2(340, 340),
		"frame_seconds": 0.09,
		"tint": Color(0.72, 0.52, 1.0, 1.0),
		"delivery": "projectile",
	},
	&"inner_aura": {
		"sheet": "res://art/battle_vfx/vfx_inner_aura_4frame_v1.png",
		"size": Vector2(380, 380),
		"frame_seconds": 0.13,
		"tint": Color(0.45, 0.96, 0.86, 1.0),
		"delivery": "self",
	},
	&"crimson_palm": {
		"sheet": "res://art/battle_vfx/vfx_crimson_palm_4frame_v2.png",
		"size": Vector2(430, 430),
		"frame_seconds": 0.115,
		"tint": Color.WHITE,
		"delivery": "melee",
	},
	&"gufeng_liedi": {
		"sheet": "res://art/battle_vfx/skill_unique_v1/vfx_gufeng_liedi_4frame_v2.png",
		"size": Vector2(500, 500),
		"frame_seconds": 0.12,
		"tint": Color.WHITE,
		"delivery": "melee",
	},
	&"sword_tier_1": {"sheet": "res://art/battle_vfx/weapon_tiers_v1/vfx_sword_tier1_4frame_v1.png", "size": Vector2(300, 300), "frame_seconds": 0.085, "tint": Color.WHITE, "delivery": "melee"},
	&"sword_tier_2": {"sheet": "res://art/battle_vfx/weapon_tiers_v1/vfx_sword_tier2_4frame_v1.png", "size": Vector2(370, 370), "frame_seconds": 0.095, "tint": Color.WHITE, "delivery": "melee"},
	&"sword_tier_3": {"sheet": "res://art/battle_vfx/weapon_tiers_v1/vfx_sword_tier3_4frame_v1.png", "size": Vector2(460, 460), "frame_seconds": 0.11, "tint": Color.WHITE, "delivery": "melee"},
	&"dao_tier_1": {"sheet": "res://art/battle_vfx/weapon_tiers_v1/vfx_dao_tier1_4frame_v1.png", "size": Vector2(320, 320), "frame_seconds": 0.095, "tint": Color.WHITE, "delivery": "melee"},
	&"dao_tier_2": {"sheet": "res://art/battle_vfx/weapon_tiers_v1/vfx_dao_tier2_4frame_v1.png", "size": Vector2(400, 400), "frame_seconds": 0.105, "tint": Color.WHITE, "delivery": "melee"},
	&"dao_tier_3": {"sheet": "res://art/battle_vfx/weapon_tiers_v1/vfx_dao_tier3_4frame_v1.png", "size": Vector2(480, 480), "frame_seconds": 0.12, "tint": Color.WHITE, "delivery": "melee"},
	&"staff_tier_1": {"sheet": "res://art/battle_vfx/weapon_tiers_v1/vfx_staff_tier1_4frame_v1.png", "size": Vector2(320, 320), "frame_seconds": 0.10, "tint": Color.WHITE, "delivery": "melee"},
	&"staff_tier_2": {"sheet": "res://art/battle_vfx/weapon_tiers_v1/vfx_staff_tier2_4frame_v1.png", "size": Vector2(410, 410), "frame_seconds": 0.11, "tint": Color.WHITE, "delivery": "melee"},
	&"staff_tier_3": {"sheet": "res://art/battle_vfx/weapon_tiers_v1/vfx_staff_tier3_4frame_v1.png", "size": Vector2(500, 500), "frame_seconds": 0.125, "tint": Color.WHITE, "delivery": "melee"},
	&"palm_tier_1": {"sheet": "res://art/battle_vfx/weapon_tiers_v1/vfx_palm_tier1_4frame_v1.png", "size": Vector2(310, 310), "frame_seconds": 0.09, "tint": Color.WHITE, "delivery": "projectile"},
	&"palm_tier_2": {"sheet": "res://art/battle_vfx/weapon_tiers_v1/vfx_palm_tier2_4frame_v1.png", "size": Vector2(390, 390), "frame_seconds": 0.105, "tint": Color.WHITE, "delivery": "projectile"},
	&"palm_tier_3": {"sheet": "res://art/battle_vfx/weapon_tiers_v1/vfx_palm_tier3_4frame_v1.png", "size": Vector2(480, 480), "frame_seconds": 0.12, "tint": Color.WHITE, "delivery": "projectile"},
	# Ordinary attacks deliberately use restrained contact effects instead of the
	# named-skill sheets.  The controller resolves one of these ids from the
	# combatant's equipped weapon or fixed weapon specialty.
	&"basic_sword": {"sheet": "res://art/battle_vfx/basic_weapon_v1/vfx_basic_sword_4frame_v1.png", "size": Vector2(285, 285), "frame_seconds": 0.075, "tint": Color.WHITE, "delivery": "melee"},
	&"basic_blade": {"sheet": "res://art/battle_vfx/basic_weapon_v1/vfx_basic_blade_4frame_v1.png", "size": Vector2(310, 310), "frame_seconds": 0.080, "tint": Color.WHITE, "delivery": "melee"},
	&"basic_staff": {"sheet": "res://art/battle_vfx/basic_weapon_v1/vfx_basic_staff_4frame_v1.png", "size": Vector2(300, 300), "frame_seconds": 0.080, "tint": Color.WHITE, "delivery": "melee"},
	&"basic_palm": {"sheet": "res://art/battle_vfx/basic_weapon_v1/vfx_basic_palm_4frame_v1.png", "size": Vector2(260, 260), "frame_seconds": 0.075, "tint": Color.WHITE, "delivery": "melee"},
	&"basic_hidden": {"sheet": "res://art/battle_vfx/basic_weapon_v1/vfx_basic_hidden_4frame_v1.png", "size": Vector2(240, 240), "frame_seconds": 0.070, "tint": Color.WHITE, "delivery": "projectile"},
}

const UNIQUE_EFFECT_ROOT := "res://art/battle_vfx/skill_unique_v1"
const UNIQUE_EFFECT_IDS: Array[StringName] = [
	&"basic_attack", &"bamboo_rain_piercing_shot", &"canglong_three_turns", &"canghai_zhenyue_palms", &"defend", &"examiner_staff_sweep",
	&"huilan_redirecting_art", &"jingang_tempered_meridians",
	&"gufeng_fuhu", &"gufeng_jingang_buhuai", &"gufeng_jingang_li", &"gufeng_kaishan_yidao", &"gufeng_liedi",
	&"heavy_swing", &"huashan_jianduan_qianshan", &"huashan_poyun", &"huashan_yijian",
	&"huashan_zixia_ninggang", &"huashan_zixia_shengong",
	&"lingyue_hanshuang_wan_zhen", &"lingyue_hanshuang_zhen", &"lingyue_lingbo_yizhi",
	&"lingyue_tayue_lingbo", &"lingyue_yuehua_yin", &"linxi_basic_sword_one", &"linxi_basic_sword_two",
	&"linxi_inner_breath", &"mingwu_mingwu_bu", &"mingwu_saofeng", &"mingwu_wuyin_sanshi",
	&"mingwu_yinying_duoming", &"mingwu_yinying_jue", &"palm_strike", &"qinghe_jade_guard",
	&"qinghe_returning_breath", &"qinghe_swallow_sword", &"rolling_cloud_staff_storm", &"tang_staff_breaker", &"tang_staff_sweep",
	&"toxic_needle", &"wanxiang_breaking_sword", &"wudang_mianzhang", &"wudang_taiji_chushi", &"wudang_taiji_liangyi", &"wudang_taiji_sixiang",
	&"wudang_xuanwu_ge", &"wudang_xuanwu_xinjing", &"zhao_black_wind_sweep", &"zhao_broken_gate_strike",
	&"zhuwei_bamboo_guard_art", &"snow_pass_returning_blade", &"cold_ridge_guard_breath",
	&"blood_shadow_scattering_darts", &"circling_breath_palm", &"heaven_pillar_staff", &"herbal_breathing_guide",
	&"linxi_guarded_breath", &"luoshui_returning_origin", &"shadow_swallow_piercing_sword", &"xuanshuang_hidden_current",
]
const UNIQUE_PROJECTILE_IDS: Array[StringName] = [
	&"bamboo_rain_piercing_shot", &"mingwu_yinying_duoming", &"toxic_needle",
	&"blood_shadow_scattering_darts", &"circling_breath_palm",
]
const UNIQUE_SELF_IDS: Array[StringName] = [
	&"defend", &"gufeng_jingang_buhuai", &"gufeng_jingang_li", &"huashan_zixia_ninggang",
	&"huashan_zixia_shengong", &"huilan_redirecting_art", &"jingang_tempered_meridians", &"lingyue_tayue_lingbo", &"lingyue_yuehua_yin", &"linxi_inner_breath",
	&"mingwu_mingwu_bu", &"mingwu_yinying_jue", &"qinghe_jade_guard", &"qinghe_returning_breath",
	&"wudang_xuanwu_ge", &"wudang_xuanwu_xinjing", &"zhuwei_bamboo_guard_art",
	&"cold_ridge_guard_breath",
	&"herbal_breathing_guide", &"linxi_guarded_breath", &"luoshui_returning_origin", &"xuanshuang_hidden_current",
]
const UNIQUE_LARGE_IDS: Array[StringName] = [
	&"canglong_three_turns", &"canghai_zhenyue_palms", &"gufeng_liedi", &"huashan_jianduan_qianshan", &"lingyue_hanshuang_wan_zhen",
	&"mingwu_wuyin_sanshi", &"mingwu_yinying_duoming", &"wudang_taiji_liangyi", &"wudang_taiji_sixiang",
	&"rolling_cloud_staff_storm", &"wanxiang_breaking_sword", &"zhao_black_wind_sweep", &"zhao_broken_gate_strike",
	&"heaven_pillar_staff", &"shadow_swallow_piercing_sword",
]


static func has_effect(animation_id: StringName) -> bool:
	return EFFECTS.has(animation_id) or animation_id in UNIQUE_EFFECT_IDS

static func has_dragon_wave(animation_id: StringName) -> bool:
	return animation_id == &"canghai_zhenyue_palms" and ResourceLoader.exists(DRAGON_SHEET)


static func get_effect_config(animation_id: StringName) -> Dictionary:
	if EFFECTS.has(animation_id):
		return EFFECTS[animation_id]
	if animation_id not in UNIQUE_EFFECT_IDS:
		return {}
	var delivery := "melee"
	if animation_id in UNIQUE_PROJECTILE_IDS:
		delivery = "projectile"
	elif animation_id in UNIQUE_SELF_IDS:
		delivery = "self"
	return {
		"sheet": "%s/vfx_%s_4frame_v1.png" % [UNIQUE_EFFECT_ROOT, animation_id],
		"size": Vector2(460, 460) if animation_id in UNIQUE_LARGE_IDS else Vector2(380, 380),
		"frame_seconds": 0.105 if animation_id in UNIQUE_LARGE_IDS else 0.09,
		"tint": Color.WHITE,
		"delivery": delivery,
	}


func play_for_skill(animation_id: StringName, target: Control, source: Control = null) -> void:
	if target == null:
		return
	if has_dragon_wave(animation_id) and source != null and await _play_dragon_wave([target], source):
		return
	var config: Dictionary = get_effect_config(animation_id)
	if config.is_empty():
		push_warning("[BattleVfx] unknown animation id: %s" % animation_id)
		return
	var sheet_path: String = str(config["sheet"])
	if not ResourceLoader.exists(sheet_path):
		push_warning("[BattleVfx] missing effect sheet: %s" % sheet_path)
		return
	var sheet: Texture2D = load(sheet_path) as Texture2D
	if sheet == null:
		push_warning("[BattleVfx] could not load effect sheet: %s" % sheet_path)
		return
	var effect_size: Vector2 = config["size"]
	var frame_seconds: float = float(config["frame_seconds"])
	var frame_size: Vector2 = Vector2(sheet.get_width() * 0.5, sheet.get_height() * 0.5)
	# target is a child of FormationView while this layer is its sibling.
	# Convert the target's canvas-space center so the impact stays on the unit
	# even when formations or camera offsets change.
	var target_center_global: Vector2 = target.get_global_rect().get_center()
	var source_center_global: Vector2 = source.get_global_rect().get_center() if source != null else target_center_global
	var direction: float = signf(target_center_global.x - source_center_global.x)
	if is_zero_approx(direction):
		direction = 1.0
	var impact_global: Vector2 = target_center_global + Vector2(direction * minf(target.get_global_rect().size.x * 0.10, 22.0), -target.get_global_rect().size.y * 0.05)
	var center: Vector2 = get_global_transform_with_canvas().affine_inverse() * impact_global
	var tint: Color = config.get("tint", Color.WHITE)
	if str(config.get("delivery", "melee")) == "projectile" and source != null and source != target:
		await _play_projectile(sheet, effect_size * 0.30, source_center_global, impact_global, tint)
	var glow := _create_layer(sheet, effect_size * 1.24, center, Color(tint.r, tint.g, tint.b, 0.24))
	var effect := _create_layer(sheet, effect_size, center, tint)
	var impact := _create_impact_flash(center, effect_size)
	var pulse := create_tween()
	pulse.set_parallel(true)
	pulse.tween_property(glow, "modulate:a", 0.0, frame_seconds * 4.0)
	pulse.tween_property(effect, "scale", Vector2(1.12, 1.12), frame_seconds * 1.5)
	pulse.tween_property(effect, "scale", Vector2.ONE, frame_seconds * 2.5)
	pulse.tween_property(impact, "modulate:a", 0.0, frame_seconds * 1.8)
	add_child(effect)
	add_child(glow)
	add_child(impact)
	for frame_index in range(4):
		var frame: AtlasTexture = AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(
			float(frame_index % 2) * frame_size.x,
			float(frame_index / 2) * frame_size.y,
			frame_size.x,
			frame_size.y
		)
		effect.texture = frame
		glow.texture = frame
		await get_tree().create_timer(frame_seconds).timeout
	if is_instance_valid(effect): effect.queue_free()
	if is_instance_valid(glow): glow.queue_free()
	if is_instance_valid(impact): impact.queue_free()


func play_for_skill_group(animation_id: StringName, targets: Array[Control], source: Control = null) -> void:
	## One shared four-frame clock drives every target. This guarantees that AOE
	## impacts begin, advance and clear together instead of awaiting each unit.
	var valid_targets: Array[Control] = []
	for target: Control in targets:
		if target != null and is_instance_valid(target):
			valid_targets.append(target)
	if valid_targets.is_empty():
		return
	if has_dragon_wave(animation_id) and source != null and await _play_dragon_wave(valid_targets, source):
		return
	var config: Dictionary = get_effect_config(animation_id)
	if config.is_empty():
		push_warning("[BattleVfx] unknown group animation id: %s" % animation_id)
		return
	var sheet_path := String(config.get("sheet", ""))
	if not ResourceLoader.exists(sheet_path):
		push_warning("[BattleVfx] missing group effect sheet: %s" % sheet_path)
		return
	var sheet := load(sheet_path) as Texture2D
	if sheet == null:
		return
	var effect_size: Vector2 = config["size"]
	var frame_seconds := float(config["frame_seconds"])
	var frame_size := Vector2(sheet.get_width() * 0.5, sheet.get_height() * 0.5)
	var tint: Color = config.get("tint", Color.WHITE)
	var source_center_global := source.get_global_rect().get_center() if source != null else valid_targets[0].get_global_rect().get_center()
	var target_contexts: Array[Dictionary] = []
	var projectiles: Array[TextureRect] = []
	for target: Control in valid_targets:
		var target_rect := target.get_global_rect()
		var target_center_global := target_rect.get_center()
		var direction := signf(target_center_global.x - source_center_global.x)
		if is_zero_approx(direction):
			direction = 1.0
		var impact_global := target_center_global + Vector2(direction * minf(target_rect.size.x * 0.10, 22.0), -target_rect.size.y * 0.05)
		var center := get_global_transform_with_canvas().affine_inverse() * impact_global
		if String(config.get("delivery", "melee")) == "projectile" and source != null and source != target:
			var start := get_global_transform_with_canvas().affine_inverse() * source_center_global
			var projectile := _create_layer(sheet, effect_size * 0.30, start, Color(tint.r, tint.g, tint.b, 0.90))
			add_child(projectile)
			var flight := projectile.create_tween().set_parallel(true)
			flight.tween_property(projectile, "position", center - projectile.size * 0.5, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			flight.tween_property(projectile, "rotation", 0.28, 0.16)
			projectiles.append(projectile)
		var glow := _create_layer(sheet, effect_size * 1.24, center, Color(tint.r, tint.g, tint.b, 0.24))
		var effect := _create_layer(sheet, effect_size, center, tint)
		var impact := _create_impact_flash(center, effect_size)
		add_child(glow)
		add_child(effect)
		add_child(impact)
		var pulse := effect.create_tween().set_parallel(true)
		pulse.tween_property(glow, "modulate:a", 0.0, frame_seconds * 4.0)
		pulse.tween_property(effect, "scale", Vector2(1.12, 1.12), frame_seconds * 1.5)
		pulse.tween_property(effect, "scale", Vector2.ONE, frame_seconds * 2.5)
		pulse.tween_property(impact, "modulate:a", 0.0, frame_seconds * 1.8)
		target_contexts.append({"effect": effect, "glow": glow, "impact": impact})
	if not projectiles.is_empty():
		await get_tree().create_timer(0.16).timeout
		for projectile: TextureRect in projectiles:
			if is_instance_valid(projectile):
				projectile.queue_free()
	for frame_index in range(4):
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(float(frame_index % 2) * frame_size.x, float(frame_index / 2) * frame_size.y, frame_size.x, frame_size.y)
		for context: Dictionary in target_contexts:
			(context["effect"] as TextureRect).texture = frame
			(context["glow"] as TextureRect).texture = frame
		await get_tree().create_timer(frame_seconds).timeout
	for context: Dictionary in target_contexts:
		for key in ["effect", "glow", "impact"]:
			var node := context.get(key) as CanvasItem
			if node != null and is_instance_valid(node):
				node.queue_free()


func _play_dragon_wave(targets: Array[Control], source: Control) -> bool:
	var sheet := load(DRAGON_SHEET) as Texture2D
	if sheet == null or sheet.get_size() != Vector2(1536, 1024):
		return false
	var center := Vector2.ZERO
	for target in targets:
		center += target.get_global_rect().get_center()
	center /= float(targets.size())
	var source_center := source.get_global_rect().get_center()
	var facing := -1.0 if center.x < source_center.x else 1.0
	var canvas := get_global_transform_with_canvas().affine_inverse()
	var start := canvas * (source_center + Vector2(facing * 112.0, -10.0))
	var finish := canvas * (center + Vector2(-facing * 92.0, -20.0))
	var dragon := _create_layer(sheet, Vector2(800, 512), start, Color.WHITE)
	dragon.name = "DragonPalmWave"
	dragon.flip_h = facing < 0.0
	dragon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var material := ShaderMaterial.new()
	material.shader = DRAGON_EDGE
	material.set_shader_parameter("layer_size", dragon.size)
	dragon.material = material
	dragon.pivot_offset = dragon.size * 0.5
	dragon.scale = Vector2.ONE * 0.54
	add_child(dragon)
	var travel := dragon.create_tween().set_parallel(true)
	travel.tween_property(dragon, "position", finish - dragon.size * 0.5, 0.40).set_trans(Tween.TRANS_SINE)
	travel.tween_property(dragon, "scale", Vector2.ONE, 0.36)
	for index in DRAGON_FRAMES.size():
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = DRAGON_FRAMES[index]
		frame.filter_clip = true
		dragon.texture = frame
		if index == DRAGON_FRAMES.size() - 1:
			dragon.create_tween().tween_property(dragon, "modulate:a", 0.0, 0.16)
		await get_tree().create_timer(0.16 if index == 3 else 0.115).timeout
	dragon.queue_free()
	return true


func _play_projectile(sheet: Texture2D, projectile_size: Vector2, source_global: Vector2, target_global: Vector2, tint: Color) -> void:
	var start := get_global_transform_with_canvas().affine_inverse() * source_global
	var finish := get_global_transform_with_canvas().affine_inverse() * target_global
	var projectile := _create_layer(sheet, projectile_size, start, Color(tint.r, tint.g, tint.b, 0.90))
	add_child(projectile)
	var flight := create_tween()
	flight.set_parallel(true)
	flight.tween_property(projectile, "position", finish - projectile_size * 0.5, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flight.tween_property(projectile, "rotation", 0.28, 0.16)
	await flight.finished
	if is_instance_valid(projectile):
		projectile.queue_free()


func _create_layer(sheet: Texture2D, layer_size: Vector2, center: Vector2, tint: Color) -> TextureRect:
	var layer := TextureRect.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.size = layer_size
	layer.position = center - layer_size * 0.5
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.modulate = tint
	return layer


func _create_impact_flash(center: Vector2, effect_size: Vector2) -> ColorRect:
	var flash := ColorRect.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(1.0, 1.0, 1.0, 0.42)
	flash.size = effect_size * 0.42
	flash.position = center - flash.size * 0.5
	return flash
