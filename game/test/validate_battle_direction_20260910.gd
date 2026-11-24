extends SceneTree

var failures: Array[String] = []
const ACTOR_SCENE := preload("res://scenes/battle_actor.tscn")

func _init() -> void:
	call_deferred("_run")

func _frames(folder: String, prefix: String, state: String) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	for index in range(1, 5):
		result.append(load("%s/%s_%s_%02d.png" % [folder, prefix, state, index]) as Texture2D)
	return result

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func _run() -> void:
	var actor := ACTOR_SCENE.instantiate() as BattleActor
	root.add_child(actor)
	var source := Control.new()
	root.add_child(source)
	actor.position = Vector2(400, 200)
	source.position = Vector2(100, 200)
	actor.size = Vector2(200, 200)
	source.size = Vector2(200, 200)
	var folder := "res://art/sprites/battle/standard_v2/dojo_senior"
	actor.configure(null, false, false, _frames(folder, "dojo_senior", "ready"), _frames(folder, "dojo_senior", "move"), _frames(folder, "dojo_senior", "attack"), _frames(folder, "dojo_senior", "hit"), _frames(folder, "dojo_senior", "defeat"))
	# Let the startup/import-heavy first delta pass before measuring animation.
	await process_frame
	await process_frame
	_check(not actor.artwork.flip_h, "coach ready must keep authored left-facing guard")
	_check(actor.recoil_direction_from(source) > 0, "victim must recoil right even when both actors are left of screen centre")
	actor.start_hit_reaction(1, false, false, source)
	await create_timer(0.06).timeout
	_check(actor.artwork.flip_h, "coach reversed hit sheet must face incoming left-side attack")
	await create_timer(0.43).timeout
	_check(actor.position.x > 400, "hit tween must displace away from left attacker")
	await create_timer(0.30).timeout
	_check(actor.position.is_equal_approx(Vector2(400, 200)), "hit must restore exact home position")
	_check(not actor.artwork.flip_h, "hit must restore normal ready orientation")
	source.position.x = 800
	_check(actor.recoil_direction_from(source) < 0, "dash-through attacker on right must reverse recoil")
	actor.start_hit_reaction(1, false, false, source)
	await create_timer(0.06).timeout
	_check(not actor.artwork.flip_h, "coach hit must face right when attack arrives from behind")
	await create_timer(0.75).timeout
	_check(actor.recoil_direction_from(null) > 0, "DoT fallback must recoil away from facing, not screen midpoint")
	for style: String in ["sword", "dao"]:
		var hero_root := "res://art/sprites/battle/weapon_variants_v4/lengguyun/%s" % style
		for state: String in ["ready", "move", "attack", "hit", "defeat"]:
			for frame: Texture2D in _frames(hero_root, "lengguyun_%s" % style, state):
				_check(frame != null and frame.get_size() == Vector2(512, 384), "%s %s normalized frame" % [style, state])
				_check(BattleSpriteFacing.faces_right(frame, false), "%s %s source direction" % [style, state])
	var corrected := load("res://art/sprites/battle/standard_v2/dojo_disciple/dojo_disciple_hit_01.png") as Texture2D
	var stable := load("res://art/sprites/battle/standard_v2/dojo_disciple/dojo_disciple_hit_02.png") as Texture2D
	_check(BattleSpriteFacing.faces_right(corrected, false), "mixed disciple first hit correction")
	_check(not BattleSpriteFacing.faces_right(stable, false), "disciple recovery must retain left-facing art")
	actor.queue_free()
	source.queue_free()
	await process_frame
	for message in failures:
		push_error(message)
	print("[BattleDirection] %s: source-relative hit/recovery, reversed coach row, mixed disciple row, 40 new weapon frames" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
