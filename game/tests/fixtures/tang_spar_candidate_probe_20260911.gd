extends "res://tests/fixtures/runtime_balance_probe_20260910.gd"

## Candidate data is duplicated in memory; player/companion skills are untouched.
var candidate_enemy: EnemyDef
var candidate_skills: Dictionary = {}
var player_damage: Array[int] = []
var enemy_damage: Array[int] = []

func _load_enemy(id: String) -> EnemyDef:
	if candidate_enemy != null and id == String(candidate_enemy.enemy_id): return candidate_enemy
	return super._load_enemy(id)

func _load_skill(id: StringName) -> Skill:
	if _team_active_unit != null and _team_active_unit.team == BattleCombatant.Team.ENEMY and candidate_skills.has(id):
		return candidate_skills[id] as Skill
	return super._load_skill(id)

func initialize_units(ids: Array[StringName], payload: Dictionary = {}) -> void:
	_team_active_unit = null
	player_damage.clear()
	enemy_damage.clear()
	super.initialize_units(ids,payload)

func _calc_team_player_skill_damage(skill: Skill, source: BattleCombatant, target: BattleCombatant) -> int:
	var value := super._calc_team_player_skill_damage(skill,source,target)
	player_damage.append(value)
	return value

func _calc_team_enemy_skill_damage(skill: Skill, source: BattleCombatant, target: BattleCombatant) -> int:
	var value := super._calc_team_enemy_skill_damage(skill,source,target)
	enemy_damage.append(value)
	return value
