extends Node

const PLAYER_TURN_STATE := 1
const EXECUTE_STATE := 2
const TIMEOUT_MS := 15000

var battle: Node = null


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SceneRouter.set("_battle_payload", {"enemy_id": "thug_lone", "return_scene": &"ch1_s1_road"})
	var packed := load("res://scenes/battle.tscn") as PackedScene
	if packed == null:
		_fail("battle scene cannot load")
		return
	battle = packed.instantiate()
	add_child(battle)
	if not await _wait_for_player_turn():
		_fail("battle did not reach player turn")
		return
	var active := battle.get("_team_active_unit") as BattleCombatant
	var enemies: Array = battle.get("_team_enemies")
	if active == null or enemies.is_empty():
		_fail("formation combatants missing")
		return
	active.action_points = 2
	battle.call("_on_battle_inventory_closed")
	if int(battle.get("_state")) != EXECUTE_STATE or active.action_points != 0:
		_fail("closing inventory did not immediately consume the whole operation")
		return

	var palm := load("res://data/skills/canglong_three_turns.tres") as Skill
	var enemy := enemies[0] as BattleCombatant
	if palm == null or enemy == null:
		_fail("internal skill or target missing")
		return
	for _i in 4:
		battle.call("_team_apply_internal_injury", enemy, palm)
	if int(enemy.status_effects.get("internal_lock", 0)) != 2:
		_fail("100 internal injury did not trigger two-turn skill lock")
		return
	if int(enemy.status_effects.get("internal_injury", -1)) != 0:
		_fail("internal injury gauge did not reset after triggering")
		return
	print("PASS validate_battle_inventory_and_internal_injury")
	get_tree().quit(0)


func _wait_for_player_turn() -> bool:
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if is_instance_valid(battle) and int(battle.get("_state")) == PLAYER_TURN_STATE:
			return true
		await get_tree().process_frame
	return false


func _fail(message: String) -> void:
	push_error("[BattleInventoryInternalInjury] %s" % message)
	get_tree().quit(1)
