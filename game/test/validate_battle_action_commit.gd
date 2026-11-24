extends Node

const PLAYER_TURN_STATE := 1
const TIMEOUT_MS := 20000

var _battle: Node = null
var _battle_ended: bool = false
var _battle_victory: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	EventBus.battle_ended.connect(_on_battle_ended)
	SceneRouter.set("_battle_payload", {
		"enemy_id": "boss_zhao_wuji",
		"return_scene": &"ch1_s3_ruin_inner",
	})
	var packed := load("res://scenes/battle.tscn") as PackedScene
	if packed == null:
		_fail("battle scene cannot load")
		return
	_battle = packed.instantiate()
	add_child(_battle)
	if not await _wait_for_player_turn():
		_fail("boss battle did not reach the player turn")
		return
	var enemies: Array = _battle.get("_team_enemies")
	var active_unit: BattleCombatant = _battle.get("_team_active_unit") as BattleCombatant
	if enemies.is_empty() or active_unit == null:
		_fail("formation combatants were not initialized")
		return
	var boss: BattleCombatant = enemies[0] as BattleCombatant
	boss.stats.hp = 1
	active_unit.action_points = 2
	_battle.call("_team_player_action_skill_use", 0)
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while not _battle_ended and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if not _battle_ended:
		_fail("decisive first action did not end the battle without a second input")
		return
	if not _battle_victory:
		_fail("decisive boss action ended as a defeat")
		return
	print("[BattleActionCommit] decisive boss action ended immediately: PASS")
	get_tree().quit(0)


func _wait_for_player_turn() -> bool:
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if is_instance_valid(_battle) and int(_battle.get("_state")) == PLAYER_TURN_STATE:
			return true
		await get_tree().process_frame
	return false


func _on_battle_ended(victory: bool, _fled: bool) -> void:
	_battle_ended = true
	_battle_victory = victory
	if victory:
		if not GameState.get_flag(&"zhao_wuji_wounded_escape"):
			_fail("Zhao Wuji survival flag was not persisted")
			return
		if not GameState.get_flag(&"lengguyun_severely_wounded_ch1"):
			_fail("Leng Guyun injury flag was not persisted")
			return
		var injury_cap := maxi(1, ceili(float(GameState.player.max_hp) * 0.25))
		if GameState.player.hp > injury_cap:
			_fail("Leng Guyun did not retain the severe-injury HP cap")
			return
		print("[BattleActionCommit] decisive nonlethal boss outcome: PASS")
		get_tree().quit(0)
	else:
		_fail("decisive boss action ended as a defeat")


func _fail(message: String) -> void:
	push_error("[BattleActionCommit] %s" % message)
	get_tree().quit(1)
