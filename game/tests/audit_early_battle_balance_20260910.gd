extends SceneTree

# Read-only runtime audit: resets only in-memory game state; no saves or data edits.
var gs: Node
var inv: Node
var controller: Node
const ENEMIES := ["linxi_dojo_disciple", "linxi_dojo_senior", "bandit_mountain", "thug_lone", "zhuwei_bandit", "linxi_wild_beast", "zhuwei_cave_wolf", "boss_zhao_wuji"]

func _init() -> void:
	call_deferred("run")

func run() -> void:
	gs = root.get_node("GameState")
	inv = root.get_node("Inventory")
	controller = load("res://scripts/battle/battle_controller.gd").new()
	for variant in ["bare", "starter_equipment", "starter_plus_wine", "starter_plus_breath", "breath_then_wine"]:
		gs.reset_for_new_game()
		inv.reset_for_new_game()
		if variant != "bare":
			for id in [&"linxi_iron_sword", &"hemp_shirt", &"straw_sandals"]:
				inv.add_item(id, 1)
				inv.equip(id)
		if "breath" in variant:
			gs.learn_skill(&"linxi_inner_breath")
			gs.equip_internal_art(&"linxi_inner_breath")
		if "wine" in variant:
			inv.add_item(&"linxi_jiu", 1)
			inv.use_item(&"linxi_jiu")
		var player: CharacterStats = gs.player
		controller.set("_player", player)
		var atk: int = controller.call("_team_effective_attack", player)
		var defense: int = controller.call("_team_effective_defense", player)
		print("VARIANT ", variant, " HP=", player.hp, "/", player.max_hp, " MP=", player.mp, "/", player.max_mp, " atk=", atk, " def=", defense, " speed=", player.speed + inv.get_speed_bonus(), " crit=", BattleFormula.calc_crit_chance(false, inv.get_crit_chance_bonus()))
		for sid in [&"basic_attack", &"linxi_basic_sword_one", &"linxi_basic_sword_two"]:
			var skill := load("res://data/skills/%s.tres" % sid) as Skill
			var gear: Dictionary = inv.get_equipped_skill_bonus_for(&"protagonist", skill.school, skill.get_bonus_weapon_style())
			var scale: int = controller.call("_skill_attack_scaling", skill, player, int(gear.scaling))
			print("SKILL ", sid, " cost=", skill.mp_cost, " fixed=", skill.fixed_damage, " scaling=", scale, " school=", skill.school, " gear=", gear, " usable_gate=", controller.call("_can_use_skill", skill, player), " learned=", sid in player.skills)
		for id in ENEMIES:
			var def := load("res://data/enemies/%s.tres" % id) as EnemyDef
			var enemy := def.to_runtime_stats()
			var damages := []
			var maximum := 0
			for sid: StringName in enemy.skills:
				var skill := load("res://data/skills/%s.tres" % sid) as Skill
				var value := BattleFormula.calc_damage_value(enemy.attack, skill.fixed_damage, skill.attack_scaling, defense)
				var low := BattleFormula.calc_damage_value(enemy.attack, skill.fixed_damage, skill.attack_scaling, defense, 0.95)
				var high := BattleFormula.calc_damage_value(enemy.attack, skill.fixed_damage, skill.attack_scaling, defense, 1.05)
				damages.append("%s:%d[%d-%d] mp%d/%d" % [sid, value, low, high, skill.mp_cost, enemy.mp])
				if skill.mp_cost <= enemy.mp:
					maximum = maxi(maximum, value)
			var outgoing := []
			for sid in [&"basic_attack", &"linxi_basic_sword_one", &"linxi_basic_sword_two"]:
				var skill := load("res://data/skills/%s.tres" % sid) as Skill
				var gear: Dictionary = inv.get_equipped_skill_bonus_for(&"protagonist", skill.school, skill.get_bonus_weapon_style())
				var scale: int = controller.call("_skill_attack_scaling", skill, player, int(gear.scaling))
				var damage := BattleFormula.calc_damage_value(atk, skill.fixed_damage, scale, enemy.defense)
				outgoing.append("%s:%d/TTK%d" % [sid, damage, ceili(float(enemy.hp)/damage)])
			print("ROW ", variant, "|", id, "|L", enemy.level, " HP", enemy.hp, " A", enemy.attack, " D", enemy.defense, "|IN ", damages, "|HITS_TO_DIE_BEST=", ceili(float(player.hp)/maxi(maximum,1)), "|OUT ", outgoing)
	# Prove wine permanence across actual normal stat recomputation paths.
	gs.reset_for_new_game()
	inv.reset_for_new_game()
	inv.add_item(&"linxi_jiu", 1)
	inv.use_item(&"linxi_jiu")
	print("WINE BEFORE LEARN ", gs.player.max_hp, "/", gs.player.max_mp)
	gs.learn_skill(&"linxi_inner_breath")
	print("WINE AFTER LEARN ", gs.player.max_hp, "/", gs.player.max_mp)
	gs.reset_for_new_game()
	inv.reset_for_new_game()
	inv.add_item(&"linxi_jiu", 1)
	inv.use_item(&"linxi_jiu")
	gs.player.gain_exp(80)
	print("WINE AFTER LEVELUP ", gs.player.max_hp, "/", gs.player.max_mp)
	print("ZERO_MP_ACTIVE_ATTACKS (exclude passive/internal art/enemy-only via owner report):")
	for file in DirAccess.get_files_at("res://data/skills"):
		if not file.ends_with(".tres"):
			continue
		var skill := load("res://data/skills/" + file) as Skill
		if skill != null and skill.mp_cost == 0 and not skill.is_passive and not skill.is_internal_art and skill.kind in [Skill.Kind.ATTACK, Skill.Kind.DEBUFF]:
			print("ZERO_MP ", skill.skill_id, " ", skill.display_name)
	gs.reset_for_new_game()
	inv.reset_for_new_game()
	for id in [&"linxi_iron_sword", &"hemp_shirt", &"straw_sandals"]:
		inv.add_item(id, 1)
		inv.equip(id)
	gs.learn_skill(&"linxi_inner_breath")
	gs.equip_internal_art(&"linxi_inner_breath")
	for level in range(1,5):
		gs.player.hp = gs.player.max_hp
		gs.player.mp = gs.player.max_mp
		print("LEVEL ", level, " HP=", gs.player.max_hp, " MP=", gs.player.max_mp, " atk=", controller.call("_team_effective_attack", gs.player), " def=", controller.call("_team_effective_defense", gs.player))
		gs.player.gain_exp(gs.player.exp_required_for_next_level())
	print("ENEMY BASIC_DAMAGE<=1 against starter defense23:")
	for file in DirAccess.get_files_at("res://data/enemies"):
		if not file.ends_with(".tres"):
			continue
		var enemy := load("res://data/enemies/" + file) as EnemyDef
		if BattleFormula.calc_damage_value(enemy.attack, 2, 100, 23) <= 1:
			print("FLOORED ", enemy.enemy_id, " atk=", enemy.attack)
	controller.free()
	quit()
