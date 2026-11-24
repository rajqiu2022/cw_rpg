extends "res://scripts/battle/battle_controller.gd"

## QA presentation adapter. Damage, affordability, enemy AI, state application,
## end-of-action expiry and action-point/victory rules remain production code.
class QuietActor extends BattleActor:
	func play_stationary_attack(_target: Control, _is_skill: bool) -> void: pass
	func play_attack_approach(_target: Control, _is_skill: bool) -> void: pass
	func play_shadow_dash_through(_target: Control, _is_skill: bool) -> void: pass
	func play_shadow_flurry(_target: Control, _is_skill: bool, _use_attack_frames: bool = false) -> void: pass
	func play_boss_windup(_target: Control, _advancing: bool) -> void: pass
	func play_boss_pounce(_target: Control) -> void: pass
	func play_attack_recover() -> void: pass
	func play_cast() -> void: pass
	func play_defend() -> void: pass
	func play_defeat() -> void: pass
	func play_dodge(_source: Control = null) -> void: pass
	func play_player_victory() -> void: pass
	func play_hit(_damage: int, _is_critical: bool = false, _play_sound: bool = true, _source: Control = null) -> void: pass
	func start_hit_reaction(_damage: int, _is_critical: bool = false, _play_sound: bool = true, _source: Control = null) -> float: return 0.0
	func start_defeat_reaction() -> float: return 0.0

class QuietVfx extends BattleVfxPlayer:
	func play_for_skill(_animation_id: StringName, _target: Control, _source: Control = null) -> void: pass
	func play_for_skill_group(_animation_id: StringName, _targets: Array[Control], _source: Control = null) -> void: pass

class QuietFormation extends BattleFormationView:
	var actors: Dictionary = {}
	func clear_target_selection() -> void: pass
	func clear_active_unit() -> void: pass
	func set_active_unit(_unit_id: StringName) -> void: pass
	func get_actor(id: StringName) -> BattleActor: return actors.get(id) as BattleActor

var finished := false
var won := false
var ended_actions := 0
var damage_samples: Array[int] = []
var chosen_enemy_skills: Dictionary = {}

func _ready() -> void:
	set_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	formation_view = QuietFormation.new()
	battle_vfx_layer = QuietVfx.new()
	legendary_cinematic = null

func release_fakes() -> void:
	for actor in formation_view.actors.values(): actor.free()
	formation_view.free()
	battle_vfx_layer.free()

func initialize_units(ids: Array[StringName], payload: Dictionary = {}) -> void:
	for actor in formation_view.actors.values(): actor.free()
	formation_view.actors.clear()
	_player = GameState.player
	_team_mode = true
	finished = false
	won = false
	ended_actions = 0
	damage_samples.clear()
	chosen_enemy_skills.clear()
	var party_entries := _build_player_party_payload(payload)
	_setup_team_runtime(ids, party_entries, maxi(0, party_entries.size() - 1))
	for unit: BattleCombatant in _team_allies + _team_enemies:
		unit.alive = unit.stats.hp > 0
		var actor := QuietActor.new()
		actor.unit_id = unit.unit_id
		formation_view.actors[unit.unit_id] = actor

func _refresh_hud() -> void: pass
func _set_buttons_enabled(_enabled: bool) -> void: pass
func _sync_team_health() -> void: pass
func _log(_line: String) -> void: pass
func _play_skill_sfx(_path: String) -> void: pass
func _play_skill_approach(_actor: BattleActor, _target: BattleActor, _skill: Skill) -> void: pass
func _update_action_point_label(_points: int) -> void: pass
func _action_frames_for(_animation_id: StringName, _fallback_frames: Array[Texture2D], _is_player: bool = true) -> Array[Texture2D]: return []

func _team_after_action() -> void:
	_team_apply_action_end_status(_team_active_unit)
	ended_actions += 1

func _team_finish(victory: bool) -> void:
	_state = State.ENDED
	finished = true
	won = victory
	# No SceneRouter transition, autosave, loot, or narrative mutation here.

func settle_real(victory: bool) -> void:
	await super._team_finish(victory)

func _calc_team_player_skill_damage(skill: Skill, source: BattleCombatant, target: BattleCombatant) -> int:
	var result := super._calc_team_player_skill_damage(skill, source, target)
	damage_samples.append(result)
	return result

func _calc_team_enemy_skill_damage(skill: Skill, source: BattleCombatant, target: BattleCombatant) -> int:
	var result := super._calc_team_enemy_skill_damage(skill, source, target)
	damage_samples.append(result)
	return result

func _enemy_choose_skill_for(def: EnemyDef, stats: CharacterStats) -> StringName:
	var result := super._enemy_choose_skill_for(def, stats)
	chosen_enemy_skills[String(result)] = int(chosen_enemy_skills.get(String(result), 0)) + 1
	return result
