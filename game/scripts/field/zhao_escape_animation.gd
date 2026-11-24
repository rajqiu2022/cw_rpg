extends RefCounted

const BRACED := preload("res://art/characters/story_enemies_20261109/zhao_wuji/escape_01.tres")
const COILED := preload("res://art/characters/story_enemies_20261109/zhao_wuji/escape_02.tres")
const TAKEOFF := preload("res://art/characters/story_enemies_20261109/zhao_wuji/escape_03.tres")
const AIRBORNE := preload("res://art/characters/story_enemies_20261109/zhao_wuji/escape_04.tres")


static func play(field: Node) -> void:
	if not is_instance_valid(field) or SceneRouter.get_current_field_id() != &"ch1_s3_ruin_inner":
		return
	if not GameState.get_flag(&"zhao_wuji_escape_cutscene_pending"):
		return
	var hero := field.get("_player") as Player
	field.call("_prepare_zhao_escape_actor")
	var zhao := field.get("_zhao_escape_actor") as Sprite2D
	if not is_instance_valid(zhao) or not is_instance_valid(hero):
		return
	if zhao.has_meta("qinggong_started"):
		return
	zhao.set_meta("qinggong_started", true)
	hero.set_can_move(false)
	var origin := zhao.position + Vector2(0, 80)
	zhao.scale = Vector2.ONE * 0.32
	var path := zhao.create_tween()
	path.tween_callback(_pose.bind(zhao, BRACED, origin))
	path.tween_interval(0.28)
	var strike := hero.position + Vector2(43, -25)
	path.tween_property(zhao, "position", strike - Vector2(0, 87), 0.20)
	path.tween_callback(_pose.bind(zhao, COILED, strike))
	path.tween_callback(func() -> void: hero.sprite.modulate = Color(1.0, 0.53, 0.46))
	path.parallel().tween_property(hero, "position", hero.position + Vector2(-38, 29), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	path.parallel().tween_property(hero.sprite, "modulate", Color.WHITE, 0.34)
	path.tween_interval(0.12)
	await path.finished
	if not is_instance_valid(zhao) or not is_instance_valid(hero):
		return
	var doorway: Vector2 = field.call("_norm_to_screen", Vector2(0.50, 0.34))
	var leap := zhao.create_tween()
	leap.tween_method(func(t: float) -> void:
		var foot := strike.lerp(doorway, t) - Vector2(0, sin(PI * t) * 102.0)
		_pose(zhao, TAKEOFF if t < 0.35 else AIRBORNE, foot)
		zhao.modulate.a = 1.0 - smoothstep(0.72, 1.0, t)
	, 0.0, 1.0, 0.72)
	await leap.finished
	zhao.queue_free()
	field.set("_zhao_escape_actor", null)
	if GameState.player != null:
		GameState.player.hp = maxi(1, mini(GameState.player.hp, roundi(GameState.player.max_hp * 0.18)))
		GameState.player.mp = maxi(0, mini(GameState.player.mp, roundi(GameState.player.max_mp * 0.35)))
	GameState.set_flag(&"zhao_wuji_wounded_escape", true)
	GameState.set_flag(&"lengguyun_severely_wounded_ch1", true)
	GameState.set_flag(&"zhao_wuji_escape_cutscene_pending", false)
	field.call("_refresh_gold")
	hero.set_can_move(true)
	SceneRouter.resolve_action("dialog:ch1_s3_ruin_after_escape")


static func _pose(sprite: Sprite2D, texture: Texture2D, foot: Vector2) -> void:
	sprite.texture = texture
	sprite.position = foot - Vector2(0, 272.0 * sprite.scale.y)
