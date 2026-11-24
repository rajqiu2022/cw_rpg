extends Node

var failures: Array[String] = []


func _ready() -> void:
	var controller_script: Script = load("res://scripts/battle/battle_controller.gd")
	var controller: Node = controller_script.new()
	var quiet_log := RichTextLabel.new()
	controller.set("battle_log", quiet_log)

	GameState.reset_for_new_game()
	Inventory.from_dict({})
	Inventory.add_item(&"gufeng_diamond_blade", 1)
	_check(Inventory.equip(&"gufeng_diamond_blade"), "real mixed-stat weapon equips")
	var player: CharacterStats = GameState.player
	player.skills = [&"gufeng_kaishan_yidao", &"gufeng_jingang_li"]
	GameState.skill_mastery["gufeng_kaishan_yidao"] = 1
	var skill: Skill = load("res://data/skills/gufeng_kaishan_yidao.tres")
	var gear: Dictionary = Inventory.get_equipped_skill_bonus(skill.school, skill.get_bonus_weapon_style())
	var scaling_without_heart: int = controller.call("_skill_attack_scaling", skill, player, int(gear.get("scaling", 0)))
	_expect("an unequipped heart art does not grant complement or equipment effects", scaling_without_heart, 144)
	_check(GameState.equip_internal_art(&"gufeng_jingang_li"), "learned heart art equips")
	var scaling_with_heart: int = controller.call("_skill_attack_scaling", skill, player, int(gear.get("scaling", 0)))
	_expect("equipped heart complement + blade family apply once to a non-signature move", scaling_with_heart, 169)
	_expect("weapon technique component is visible", int(gear.get("weapon_scaling", 0)), 15)
	_expect("school technique component is visible", int(gear.get("school_scaling", 0)), 22)
	var effective_attack: int = controller.call("_team_effective_attack", player)
	_expect("mixed weapon contributes its attack and strength bonuses once", effective_attack - (player.strength * 2 + player.inner_power), 59)

	# The path-equivalence section deliberately runs without protagonist gear or
	# an equipped heart art, so all four helpers receive identical inputs.
	Inventory.from_dict({})
	GameState.unequip_internal_art()

	var path_skill: Skill = load("res://data/skills/linxi_basic_sword_one.tres")
	var source_stats := CharacterStats.new()
	source_stats.character_id = "test_source"
	source_stats.strength = 10
	source_stats.inner_power = 11
	source_stats.attack = 30 # Equal to this character's external attack (strength * 3).
	source_stats.insight = 0
	source_stats.max_hp = 100
	source_stats.hp = 100
	var target_stats := CharacterStats.new()
	target_stats.character_id = "test_target"
	target_stats.defense = 4
	target_stats.max_hp = 100
	target_stats.hp = 100
	var source_unit := BattleCombatant.new()
	source_unit.configure_from_stats(&"test_source", BattleCombatant.Team.ALLY, source_stats)
	var target_unit := BattleCombatant.new()
	target_unit.configure_from_stats(&"test_target", BattleCombatant.Team.ENEMY, target_stats)
	controller.set("_player", source_stats)
	controller.set("_enemy", target_stats)
	var comparable_attack: int = controller.call("_team_effective_attack", source_stats, path_skill)
	var results: Array[int] = []
	seed(424242)
	results.append(int(controller.call("_calc_damage_ext", comparable_attack, path_skill.fixed_damage, path_skill.get_attack_scaling(), 4, true, 0.0)))
	controller.set("_player", target_stats)
	controller.set("_enemy", source_stats)
	seed(424242)
	results.append(int(controller.call("_calc_damage", comparable_attack, path_skill.fixed_damage, path_skill.get_attack_scaling(), 4, false)))
	seed(424242)
	results.append(int(controller.call("_calc_team_player_skill_damage", path_skill, source_unit, target_unit)))
	source_unit.team = BattleCombatant.Team.ENEMY
	target_unit.team = BattleCombatant.Team.ALLY
	seed(424242)
	results.append(int(controller.call("_calc_team_enemy_skill_damage", path_skill, source_unit, target_unit)))
	_check(results.all(func(value: int) -> bool: return value == results[0]), "four controller paths assemble the same fixed/scaling/defense inputs")
	var poison_skill: Skill = load("res://data/skills/lingyue_hanshuang_wan_zhen.tres")
	controller.call("_team_apply_skill_status_data", source_unit, target_unit, poison_skill)
	_check(not target_unit.status_effects.has("poison") and int(target_unit.status_effects.get("weaken", 0)) == 2, "current staff formation applies authored weaken, not retired poison")
	var guard_skill: Skill = load("res://data/skills/wudang_xuanwu_ge.tres")
	controller.call("_team_apply_player_buff", source_unit, target_unit, guard_skill)
	_check(not target_unit.status_effects.has("weaken") and int(target_unit.status_effects.get("guard", 0)) == 1, "team buffs clear weaken and apply guard")

	print("[BattleDamagePaths] checks=10 failed=%d values=%s" % [failures.size(), str(results)])
	for failure in failures:
		push_error("[BattleDamagePaths] %s" % failure)
	controller.free()
	quiet_log.free()
	get_tree().quit(1 if not failures.is_empty() else 0)


func _expect(label: String, actual: int, expected: int) -> void:
	_check(actual == expected, "%s expected=%d actual=%d" % [label, expected, actual])


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
