extends SceneTree

const UI_LAYER_POLICY := preload("res://scripts/ui/ui_layer_policy.gd")

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	var scene := load("res://scenes/battle.tscn") as PackedScene
	_check(scene != null, "battle scene loads")
	if scene == null:
		_finish()
		return
	var battle := scene.instantiate()
	root.add_child(battle)
	var canvas := battle.get_node_or_null("LegendaryCinematicLayer") as CanvasLayer
	_check(canvas != null and canvas.layer == UI_LAYER_POLICY.CINEMATIC_LAYER, "legendary cinematic renders above HUD and system UI")
	var cinematic := battle.get_node_or_null("LegendaryCinematicLayer/LegendarySkillCinematic") as LegendarySkillCinematic
	_check(cinematic != null, "legendary cinematic controller exists")
	_check(cinematic != null and cinematic.has_fullscreen_effect(&"canghai_zhenyue_palms"), "canghai palms owns a fullscreen impact")

	for frame_index in range(1, 5):
		var path := "res://art/battle_vfx/legendary_cinematics/canghai_zhenyue_fullscreen_hd_v2/canghai_zhenyue_fullscreen_f%02d_v2.png" % frame_index
		_check(ResourceLoader.exists(path), "fullscreen HD frame %d exists" % frame_index)
		var texture := load(path) as Texture2D
		_check(texture != null and texture.get_width() >= 1600 and texture.get_height() >= 900, "fullscreen HD frame %d avoids low-resolution upscale" % frame_index)
	var intro_path := "res://art/battle_vfx/legendary_cinematics/canghai_zhenyue_fullscreen_hd_v2/canghai_zhenyue_intro_palm_4frame_v2.png"
	_check(ResourceLoader.exists(intro_path), "palm-release intro atlas exists")
	var intro_texture := load(intro_path) as Texture2D
	_check(intro_texture != null and intro_texture.get_width() >= 1200, "palm-release intro has enough source detail")
	var skill := load("res://data/skills/canghai_zhenyue_palms.tres") as Skill
	_check(skill != null and skill.quality == Skill.Quality.LEGENDARY, "prototype is orange-tier legendary")
	_check(skill != null and skill.target == Skill.Target.ENEMY_ALL, "prototype is a true global attack")

	var controller_source := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	_check(controller_source.contains("play_intro(skill)"), "battle invokes the legendary title intro")
	_check(controller_source.count("await legendary_cinematic.reveal_battlefield()") == 2, "team and legacy paths both clear the title mask before actor action")
	_check(controller_source.contains("play_fullscreen_effect(skill.skill_id)"), "battle invokes one fullscreen group impact")
	_check(controller_source.contains("if not use_fullscreen_impact"), "group impact does not replay a single-target VFX on every enemy")
	_check(controller_source.contains("if use_legendary_cinematic:\n\t\tawait legendary_cinematic.finish()\n\tawait _team_finish_player_action()"), "team action ends only after the legendary mask fades")
	_check(controller_source.contains("if use_legendary_cinematic:\n\t\tawait legendary_cinematic.finish()\n\tawait _post_action()"), "legacy action ends only after the legendary mask fades")
	var cinematic_source := FileAccess.get_file_as_string("res://scripts/battle/legendary_skill_cinematic.gd")
	_check(cinematic_source.contains("传 世 绝 学"), "intro contains the legendary tier caption")
	_check(cinematic_source.contains("LXGWWenKaiLite-Regular.ttf"), "legendary title uses manuscript-style Chinese calligraphy")
	_check(cinematic_source.contains("view_size, 5"), "legendary title avoids the previous heavy modern outline")
	_check(cinematic_source.contains("Vector2(0.18, 0.18)"), "legendary title starts visibly small")
	_check(cinematic_source.contains('"scale", Vector2.ONE, 0.92'), "legendary title grows slowly to full size")
	_check(cinematic_source.contains('"frame_seconds": 0.28'), "fullscreen legendary frames have a readable duration")
	_check(cinematic_source.contains("func reveal_battlefield()"), "cinematic exposes an explicit pre-attack battlefield reveal")
	_check(cinematic_source.contains('reveal.tween_property(_mask, "color:a", 0.0'), "pre-attack reveal fully removes the fullscreen mask")
	var actor_source := FileAccess.get_file_as_string("res://scripts/battle/battle_actor.gd")
	_check(actor_source.contains("func play_legendary_cast"), "legendary skills own an extended actor windup")
	_check(cinematic_source.contains("BLEND_MODE_ADD"), "black-backed VFX uses additive blending")
	_check(cinematic_source.contains("FullscreenDimMask"), "intro owns a fullscreen dim mask")
	battle.queue_free()
	await process_frame
	_finish()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _finish() -> void:
	print("[LegendaryCinematic20260817] checks=%d failed=%d" % [checks, failures.size()])
	for failure in failures:
		push_error("[LegendaryCinematic20260817] %s" % failure)
	quit(1 if not failures.is_empty() else 0)
