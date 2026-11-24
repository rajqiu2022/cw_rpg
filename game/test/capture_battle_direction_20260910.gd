extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var background := TextureRect.new()
	background.texture = load("res://art/backgrounds/bg_battle_river_valley_day_v1.png")
	background.size = Vector2(1280, 720)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	root.add_child(background)
	var hero := load("res://scenes/battle_actor.tscn").instantiate() as BattleActor
	var coach := load("res://scenes/battle_actor.tscn").instantiate() as BattleActor
	root.add_child(hero)
	root.add_child(coach)
	hero.position = Vector2(130, 170)
	coach.position = Vector2(690, 170)
	hero.scale = Vector2.ONE * 0.85
	coach.scale = Vector2.ONE * 0.85
	var hero_root := "res://art/sprites/battle/weapon_variants_v4/lengguyun/sword"
	var coach_root := "res://art/sprites/battle/standard_v2/dojo_senior"
	hero.configure(null, false, true, frames(hero_root, "lengguyun_sword", "ready"), frames(hero_root, "lengguyun_sword", "move"), frames(hero_root, "lengguyun_sword", "attack"), frames(hero_root, "lengguyun_sword", "hit"), frames(hero_root, "lengguyun_sword", "defeat"))
	coach.configure(null, false, false, frames(coach_root, "dojo_senior", "ready"), frames(coach_root, "dojo_senior", "move"), frames(coach_root, "dojo_senior", "attack"), frames(coach_root, "dojo_senior", "hit"), frames(coach_root, "dojo_senior", "defeat"))
	await create_timer(0.3).timeout
	await save_frame("battle_ready.png")
	hero.set_process(false)
	hero._set_artwork_texture(hero.attack_frames[1])
	coach.start_hit_reaction(33, false, false, hero)
	await create_timer(0.12).timeout
	await save_frame("battle_hit.png")
	await create_timer(1.0).timeout
	quit(0)

func frames(folder: String, prefix: String, state: String) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	for i in range(1, 5):
		result.append(load("%s/%s_%s_%02d.png" % [folder, prefix, state, i]))
	return result

func save_frame(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../assets/previews/sprite/battle_direction_20260910/%s" % filename)
	root.get_texture().get_image().save_png(path)
	print("saved ", path)
