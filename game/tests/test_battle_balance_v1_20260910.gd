extends SceneTree

var checks := 0
var failed := 0

class QuietActor extends BattleActor:
	func play_stationary_attack(_target: Control, _is_skill: bool) -> void:
		pass
	func play_hit(_damage: int, _is_critical: bool = false, _play_sound: bool = true, _source: Control = null) -> void:
		pass

class QuietVfx extends BattleVfxPlayer:
	func play_for_skill(_animation_id: StringName, _target: Control, _source: Control = null) -> void:
		pass

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error(label)

func run() -> void:
	var weak_hit := BattleFormula.calc_damage_breakdown(18, 2, 100, 23)
	check(weak_hit.final_damage == 4, "20 power / 23 defense yields 4, not 1")
	check(weak_hit.defense_absorption == 16 and weak_hit.max_defense_absorption == 16 and weak_hit.defense_absorption_capped, "absorption trace records real cap")
	check("实际吸收 16" in weak_hit.to_gm_text() and "80%吸收封顶" in weak_hit.to_gm_text(), "GM displays actual absorbed amount")
	check(BattleFormula.calc_damage_value(400, 0, 100, 80) == 320, "uncapped later-game subtraction unchanged")
	check(BattleFormula.calc_damage_value(180, 0, 100, 50) == 130, "uncapped midgame subtraction unchanged")
	var crit := BattleFormula.calc_damage_breakdown(20, 0, 100, 100, 1.0, 1.5)
	check(crit.damage_after_crit == 30 and crit.max_defense_absorption == 24 and crit.final_damage == 6, "cap follows actual critical power")
	for hp in [100, 69, 49, 29, 9, 1]:
		check(BattleFormula.calc_damage_value(60, 0, 100, 20, 1.0, 1.0, false, false, hp, 100) == 40, "no global low-health penalty hp%d" % hp)
	check(BattleFormula.calc_damage_value(60, 0, 100, 20, 1.0, 1.0, false, true, 1, 100) == 28, "explicit weaken still reduces outgoing damage")
	var gs := root.get_node("GameState")
	var inv := root.get_node("Inventory")
	gs.reset_for_new_game()
	inv.reset_for_new_game()
	var controller: Node = load("res://scripts/battle/battle_controller.gd").new()
	var costs := {"linxi_basic_sword_one":4, "linxi_basic_sword_two":8, "gufeng_kaishan_yidao":4, "huashan_yijian":4, "lingyue_lingbo_yizhi":4, "mingwu_saofeng":6, "wudang_taiji_chushi":5}
	for id in costs:
		check(load("res://data/skills/%s.tres" % id).mp_cost == costs[id], "skill cost " + id)
	var one: Skill = load("res://data/skills/linxi_basic_sword_one.tres")
	var two: Skill = load("res://data/skills/linxi_basic_sword_two.tres")
	check(not controller.call("_can_use_skill", one, gs.player) and not controller.call("_can_use_skill", two, gs.player), "both sword forms require real equipped sword")
	inv.add_item(&"linxi_iron_sword", 1)
	inv.equip(&"linxi_iron_sword")
	var bonus: Dictionary = inv.get_equipped_skill_bonus(one.school, one.get_bonus_weapon_style())
	check(bonus.school_scaling == 12 and bonus.weapon_scaling == 6, "first form receives named school and sword bonuses")
	var unit := BattleCombatant.new()
	unit.configure_from_stats(&"protagonist", BattleCombatant.Team.ALLY, gs.player)
	unit.status_effects = {"internal_lock":2, "burst":2, "damage_boost":1, "damage_boost_percent":20}
	controller.set("_team_mode", true)
	controller.set("_team_active_unit", unit)
	var basic: Skill = load("res://data/skills/basic_attack.tres")
	var defend: Skill = load("res://data/skills/defend.tres")
	check(controller.call("_can_use_skill", basic, gs.player) and controller.call("_can_use_skill", defend, gs.player), "sealed actor retains basic attack and defend")
	check(not controller.call("_can_use_skill", one, gs.player), "sealed actor cannot cast paid technique")
	var free_technique := one.duplicate() as Skill
	free_technique.mp_cost = 0
	check(not controller.call("_can_use_skill", free_technique, gs.player), "seal does not whitelist all zero-MP techniques")
	controller.call("_team_apply_action_end_status", unit)
	check(unit.status_effects.internal_lock == 1 and unit.status_effects.burst == 1 and unit.status_effects.damage_boost == 0 and not unit.status_effects.has("damage_boost_percent"), "shared action end preserves status countdown")
	unit.status_effects.clear()
	gs.player.mp = 0
	check(controller.call("_can_use_skill", basic, gs.player) and controller.call("_can_use_skill", defend, gs.player) and not controller.call("_can_use_skill", one, gs.player), "MP exhaustion keeps free fallback but rejects paid skill")
	var pools := {"gufeng_bandit":12, "gufeng_trainee":12, "lingyue_guard":12, "luoyang_patrol":12, "wudang_disciple":15, "mingwu_spy":18, "mingwu_siege_guard":18}
	for id in pools:
		var enemy: EnemyDef = load("res://data/enemies/%s.tres" % id)
		check(enemy.max_mp == pools[id], "three-cast enemy resource pool " + id)
		var stats := enemy.to_runtime_stats()
		stats.mp = 0
		for draw in range(12):
			var selected: StringName = controller.call("_enemy_choose_skill_for", enemy, stats)
			check(load("res://data/skills/%s.tres" % selected).mp_cost == 0, "enemy exhausted selection stays affordable " + id)
	controller.free()
	await check_legacy_action()
	print("[BattleBalanceV1] checks=%d failed=%d" % [checks, failed])
	quit(1 if failed else 0)

func check_legacy_action() -> void:
	# Load only after autoload registration; a SceneTree script's parse-time
	# controller subclass would compile before Inventory/GameState exist.
	var probe = load("res://scenes/battle.tscn").instantiate()
	probe.set_script(load("res://tests/fixtures/legacy_balance_probe_20260910.gd"))
	probe.test_skill = load("res://data/skills/linxi_basic_sword_one.tres").duplicate()
	probe.test_skill.base_hit_chance = 0.0
	probe.test_skill.animation_id = &"basic_attack"
	var enemy := EnemyDef.new()
	enemy.enemy_id = &"mp_probe"
	enemy.max_mp = 4
	enemy.max_hp = 1000
	enemy.skill_ids = [&"linxi_basic_sword_one"]
	probe.set("_enemy_def", enemy)
	probe.set("_enemy", enemy.to_runtime_stats())
	var player := CharacterStats.new()
	player.hp = 1000
	player.max_hp = 1000
	probe.set("_player", player)
	probe.set("_player_defending", true)
	probe.set("_player_redirect_percent", 50)
	probe.set("_complement_reflect_active", true)
	probe.get_node("PlayerActor").set_script(QuietActor)
	probe.get_node("EnemyActor").set_script(QuietActor)
	probe.get_node("%BattleVfxLayer").set_script(QuietVfx)
	root.add_child(probe)
	await probe.call("_do_enemy_turn")
	check(probe.get("_enemy").mp == 0, "legacy real enemy action consumes 4 MP once")
	check(player.hp == 1000 and not probe.last_damage_breakdown.hit, "legacy action respects 0% hit and cannot redirect a miss into damage")
	check(probe.call("_enemy_choose_skill") == &"basic_attack", "legacy chooser falls back after exhausting resource")
	probe.queue_free()
	await process_frame
