class_name BattleCombatant
extends RefCounted

## Runtime wrapper for one unit in a battle party.
## Formula, AI and rewards stay in BattleController; this object only holds
## the unit identity and presentation contract used by BattleView.

enum Team { ALLY, ENEMY }
enum Stance { READY, ATTACKING, CASTING, HIT, DEFEATED, VICTORY }

var unit_id: StringName = &""
var definition_id: StringName = &""
var display_name: String = ""
var team: Team = Team.ALLY
var enemy_definition: EnemyDef
var stats: CharacterStats
var portrait_path: String = ""
var battle_actor_path: String = ""
var actor_scale: float = 1.0
var audio_cues: Dictionary = {}
var stance: Stance = Stance.READY
var alive: bool = true
var status_effects: Dictionary = {}
var action_points: int = 1
var guard_grants_extra_action: bool = false


func configure_from_stats(id: StringName, side: Team, value: CharacterStats) -> void:
	unit_id = id
	definition_id = id
	team = side
	stats = value
	display_name = value.display_name
	portrait_path = value.portrait_path


func set_stance(next_stance: Stance) -> void:
	stance = next_stance
	if stats != null and stats.is_dead():
		alive = false


func get_audio_path(cue: StringName) -> String:
	return str(audio_cues.get(cue, ""))


func status_summary() -> String:
	var parts: Array[String] = []
	for key: Variant in status_effects.keys():
		var turns: int = int(status_effects[key])
		if turns <= 0:
			continue
		var label: String = String(key)
		if label == "guard":
			parts.append("防御")
			continue
		match label:
			"poison": label = "中毒"
			"venom": label = "烈毒"
			"poison_ward": label = "护毒"
			"bleed": label = "流血"
			"internal_injury":
				parts.append("内伤%d/100" % turns)
				continue
			"internal_lock": label = "气脉闭塞"
			"weaken": label = "虚弱"
			"stun": label = "眩晕"
			"freeze": label = "冰冻"
			"burst": label = "爆发"
			"damage_boost": label = "增伤"
			"field_edge": label = "砺锋"
			"clear_sight": label = "明目"
			"armor_break": label = "破甲"
			"armor_break_percent": continue
			"field_focus": label = "凝锋"
			"field_breath": label = "归息"
			"field_guard": label = "固元"
			"vulnerable": label = "易伤"
		parts.append("%s%d" % [label, turns])
	return ", ".join(parts) if not parts.is_empty() else "正常"
