extends SceneTree

const ACTOR_SCENE := preload("res://scenes/battle_actor.tscn")

var _checks := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Control.new()
	stage.size = Vector2(1400, 720)
	root.add_child(stage)
	var actor := ACTOR_SCENE.instantiate() as BattleActor
	var target := ACTOR_SCENE.instantiate() as BattleActor
	stage.add_child(actor)
	stage.add_child(target)
	actor.position = Vector2(80, 80)
	target.position = Vector2(760, 80)
	var texture := load("res://art/battle_vfx/vfx_shadow_4frame_v1.png") as Texture2D
	_check(texture != null, "motion test texture loads")
	actor.configure(texture, false, true)
	target.configure(texture, true, false)
	await process_frame
	var home := actor.position
	await actor.play_shadow_dash_through(target, true)
	_check(actor.position != home, "dash crosses away from home")
	await actor.play_attack_recover()
	_check(actor.position.is_equal_approx(home), "dash recovers home")
	_check(actor.modulate.is_equal_approx(Color.WHITE), "dash restores modulation")
	await actor.play_shadow_flurry(target, true)
	_check(actor.position != home, "flurry crosses away from home")
	await actor.play_attack_recover()
	_check(actor.position.is_equal_approx(home), "flurry recovers home")
	_check(actor.rotation == 0.0, "flurry restores rotation")
	await create_timer(0.30).timeout
	_check(stage.get_child_count() == 2, "afterimages clean themselves up")
	print("[BattleActorMotion] checks=%d failed=%d" % [_checks, _failed])
	quit(1 if _failed else 0)


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
		push_error("[BattleActorMotion] FAIL: %s" % label)
