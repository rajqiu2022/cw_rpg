extends SceneTree

## Deterministic full-party pacing audit. It models two late-game emergency pills,
## but intentionally ignores active healing and status damage so it measures the
## basic action economy rather than pretending to replace hands-on playtesting.

const CASES: Array[Dictionary] = [
	{"id": "ch1_forest_pack", "enemy_ids": [&"linxi_wild_beast", &"zhuwei_pack_wolf"], "level": 2, "party": 3, "role": "regular", "min_rounds": 2, "max_rounds": 6},
	{"id": "ch1_outer_guard", "enemy_ids": [&"zhuwei_bandit", &"zhuwei_bandit"], "level": 2, "party": 3, "role": "regular", "min_rounds": 2, "max_rounds": 6},
	{"id": "ch1_alpha_wolf", "enemy_ids": [&"zhuwei_cave_wolf"], "level": 2, "party": 3, "role": "elite", "adaptive": true, "min_rounds": 3, "max_rounds": 9},
	{"id": "ch1_zhao_wuji", "enemy_ids": [&"boss_zhao_wuji"], "level": 3, "party": 3, "role": "boss", "adaptive": true, "min_rounds": 4, "max_rounds": 10},
	{"id": "ch2_forest_ambush", "enemy_ids": [&"masked_killer_minion", &"masked_killer_minion"], "level": 3, "party": 3, "role": "regular", "min_rounds": 2, "max_rounds": 6},
	{"id": "ch2_mine_sentries", "enemy_ids": [&"ch2_mine_sentry", &"ch2_mine_sentry"], "level": 3, "party": 3, "role": "elite", "min_rounds": 3, "max_rounds": 8},
	{"id": "ch2_mine_leader", "enemy_ids": [&"masked_killer_ambush", &"zhuwei_bandit", &"zhuwei_bandit"], "level": 3, "party": 3, "role": "boss", "min_rounds": 4, "max_rounds": 10},
	{"id": "ch2_rescue", "enemy_ids": [&"masked_killer_elite", &"masked_killer_minion", &"masked_killer_minion"], "level": 3, "party": 3, "role": "elite", "min_rounds": 3, "max_rounds": 9},
	{"id": "ch3_trial_group", "enemy_ids": [&"wulin_examiner", &"ch2_tournament_guard"], "level": 4, "party": 3, "role": "elite", "min_rounds": 3, "max_rounds": 8},
	{"id": "ch3_tomb_group", "enemy_ids": [&"mingwu_shadow", &"mingwu_spy", &"mingwu_infiltrator"], "level": 4, "party": 3, "role": "boss", "min_rounds": 4, "max_rounds": 10},
	{"id": "ch4_canal_group", "enemy_ids": [&"luoyang_thug", &"luoyang_thug"], "level": 5, "party": 3, "role": "regular", "min_rounds": 2, "max_rounds": 7},
	{"id": "ch4_fake_assassin", "enemy_ids": [&"fake_liuyun_assassin"], "level": 5, "party": 3, "role": "elite", "adaptive": true, "min_rounds": 3, "max_rounds": 9},
	{"id": "ch4_tunnel_boss", "enemy_ids": [&"fake_liuyun_assassin", &"temple_ambusher", &"temple_ambusher"], "level": 5, "party": 3, "role": "boss", "min_rounds": 4, "max_rounds": 10},
	{"id": "ch5_relief_road", "enemy_ids": [&"ch5_relief_road_raider", &"ch5_relief_road_raider"], "level": 7, "party": 3, "role": "regular", "min_rounds": 3, "max_rounds": 8},
	{"id": "ch5_grain_convoy", "enemy_ids": [&"ch5_relief_road_raider", &"ch5_relief_road_raider", &"ch5_false_liuyun_striker"], "level": 7, "party": 3, "role": "elite", "min_rounds": 3, "max_rounds": 9},
	{"id": "ch5_snow_pass", "enemy_ids": [&"ch5_snow_pass_pursuer", &"ch5_false_liuyun_striker"], "level": 8, "party": 3, "role": "elite", "min_rounds": 3, "max_rounds": 9},
	{"id": "ch5_mine_hunters", "enemy_ids": [&"ch5_mine_tunnel_hunter", &"ch5_false_liuyun_striker"], "level": 8, "party": 3, "role": "elite", "min_rounds": 4, "max_rounds": 10},
	{"id": "ch5_false_banner", "enemy_ids": [&"ch5_false_banner_captain", &"ch5_false_liuyun_striker", &"ch5_false_liuyun_striker"], "level": 9, "party": 3, "role": "boss", "min_rounds": 5, "max_rounds": 13},
	{"id": "ch6_archive", "enemy_ids": [&"ch6_archive_reclaimer", &"ch6_archive_burner"], "level": 10, "party": 3, "role": "elite", "min_rounds": 4, "max_rounds": 10},
	{"id": "ch6_baishui_route", "enemy_ids": [&"ch6_convoy_pursuer", &"ch6_convoy_tracker"], "level": 10, "party": 3, "role": "elite", "min_rounds": 4, "max_rounds": 10},
	{"id": "ch7_lieyun_hardliners", "enemy_ids": [&"ch7_lieyun_hardliner_guard", &"ch7_lieyun_hardliner_tracker"], "level": 11, "party": 3, "role": "elite", "min_rounds": 4, "max_rounds": 11},
	{"id": "ch7_mingwu_records", "enemy_ids": [&"ch7_mingwu_record_guard", &"ch7_mingwu_order_burner"], "level": 12, "party": 3, "role": "elite", "min_rounds": 4, "max_rounds": 11},
	{"id": "ch8_mistwood", "enemy_ids": [&"ch8_mistwood_blockade_guard", &"ch8_mistwood_signal_burner"], "level": 13, "party": 3, "role": "elite", "min_rounds": 4, "max_rounds": 12},
	{"id": "ch8_false_order", "enemy_ids": [&"ch8_false_order_courier", &"ch8_false_order_escort"], "level": 14, "party": 3, "role": "elite", "min_rounds": 4, "max_rounds": 12},
	{"id": "ch8_mechanism", "enemy_ids": [&"ch8_mechanism_warden", &"ch8_mist_valve_keeper"], "level": 14, "party": 3, "role": "elite", "min_rounds": 4, "max_rounds": 12},
	{"id": "ch8_xueying_duel", "enemy_ids": [&"ch8_xueying_last_guard"], "level": 15, "party": 3, "role": "boss", "min_rounds": 5, "max_rounds": 13},
	{"id": "ch8_su_final", "enemy_ids": [&"ch8_su_wusheng_final"], "level": 16, "party": 3, "role": "boss", "min_rounds": 6, "max_rounds": 15},
]

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_enemy_attack_runtime_path()
	_validate_runtime_group_adaptation()
	_validate_late_random_encounters()
	for spec: Dictionary in CASES:
		for party_size: int in [1, 2, 3]:
			var party_spec := spec.duplicate(true)
			party_spec["party"] = party_size
			var result := _simulate_case(party_spec)
			var case_id := "%s/p%d" % [String(spec.get("id", "unknown")), party_size]
			print("[PartyPacing20260909] %-24s result=%s rounds=%d enemy_actions=%d survivors=%d hp=%.2f" % [
				case_id,
				String(result.get("result", "invalid")),
				int(result.get("rounds", 0)),
				int(result.get("enemy_actions", 0)),
				int(result.get("party_survivors", 0)),
				float(result.get("party_hp_ratio", 0.0)),
			])
			var max_rounds := int(spec.get("max_rounds", 10)) + (3 - party_size) * 3
			_check(String(result.get("result", "")) == "victory", "%s：标准队伍可以取胜" % case_id)
			_check(int(result.get("rounds", 0)) >= int(spec.get("min_rounds", 2)), "%s：不会一轮清场" % case_id)
			_check(int(result.get("rounds", 99)) <= max_rounds, "%s：战斗不会过度拖沓" % case_id)
			_check(int(result.get("enemy_actions", 0)) > 0, "%s：敌方至少获得一次行动" % case_id)
	print("[PartyPacing20260909] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[PartyPacing20260909] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_enemy_attack_runtime_path() -> void:
	var packed := load("res://scenes/battle.tscn") as PackedScene
	_check(packed != null, "战斗场景可加载")
	if packed == null:
		return
	var controller := packed.instantiate()
	root.add_child(controller)
	var enemy := BattleCombatant.new()
	var stats := CharacterStats.new()
	stats.attack = 47
	enemy.configure_from_stats(&"runtime_attack_probe", BattleCombatant.Team.ENEMY, stats)
	var actual := int(controller.call("_team_attack_value", enemy, null))
	_check(actual == 47, "编队敌人使用EnemyDef配置攻击，而不是默认筋骨公式")
	var ai_probe := EnemyDef.new()
	ai_probe.enemy_id = &"ai_probe"
	ai_probe.aggression = 1.0
	stats.skills = [&"basic_attack", &"heavy_swing"]
	for _attempt: int in 8:
		_check(StringName(controller.call("_enemy_choose_skill_for", ai_probe, stats)) == &"heavy_swing", "满进攻倾向会稳定选择可用招牌技能")
	ai_probe.aggression = 0.0
	for _attempt: int in 8:
		_check(StringName(controller.call("_enemy_choose_skill_for", ai_probe, stats)) == &"basic_attack", "零进攻倾向会保留普通攻击")
	controller.queue_free()


func _validate_runtime_group_adaptation() -> void:
	var router := root.get_node_or_null("SceneRouter")
	var game_state := root.get_node_or_null("GameState")
	_check(router != null and game_state != null, "队伍适配运行依赖可用")
	if router == null or game_state == null:
		return
	var original_party: Array[CharacterStats] = []
	for member: CharacterStats in game_state.party:
		original_party.append(member)
	var authored: Array[StringName] = [&"fake_liuyun_assassin", &"temple_ambusher", &"temple_ambusher"]
	for party_size: int in [1, 2, 3]:
		var probe_party: Array[CharacterStats] = []
		for member_index: int in party_size:
			var member := CharacterStats.new()
			member.character_id = "probe_%d" % member_index
			probe_party.append(member)
		game_state.party = probe_party
		var resolved: Array[StringName] = router.call("_adapt_authored_group_to_party", authored)
		var expected_count := 2 if party_size == 1 else 3
		_check(resolved.size() == expected_count, "%d人队对应%d名编队敌人" % [party_size, expected_count])
	game_state.party = original_party


func _validate_late_random_encounters() -> void:
	var specs: Array[Dictionary] = [
		{"scene": &"ch5_s1_relief_road", "gate": &"ch5_relief_road_cleared"},
		{"scene": &"ch5_s3_snow_pass", "gate": &"ch5_snow_pass_cleared"},
		{"scene": &"ch5_s4_abandoned_mine", "gate": &"ch5_mine_hunters_defeated"},
		{"scene": &"ch6_s4_baishui_convoy_route", "gate": &"ch6_convoy_pursuers_defeated"},
		{"scene": &"ch7_s3_lieyun_outpost_outer_ward", "gate": &"ch7_lieyun_hardliners_defeated"},
		{"scene": &"ch8_s2_mistwood_blockade", "gate": &"ch8_mistwood_blockade_cleared"},
		{"scene": &"ch8_s4_alliance_mechanism_gallery", "gate": &"ch8_mechanism_guards_defeated"},
	]
	for spec: Dictionary in specs:
		var scene_id := StringName(spec.get("scene", &""))
		var scene := load("res://data/scenes/%s.tres" % String(scene_id)) as SceneScript
		_check(scene != null, "%s：后期危险场景可加载" % scene_id)
		if scene == null:
			continue
		_check(not scene.is_settlement, "%s：随机战只放在非聚落区域" % scene_id)
		_check(scene.encounter_require_flag == StringName(spec.get("gate", &"")), "%s：先完成剧情战再开放残敌遭遇" % scene_id)
		_check(scene.encounter_step_distance >= 700.0 and scene.encounter_chance >= 0.05 and scene.encounter_chance <= 0.12, "%s：遭遇间距与概率保持低打扰" % scene_id)
		var group_sizes: Array[int] = []
		for group: Dictionary in scene.encounter_groups:
			var enemy_ids: Array = group.get("enemy_ids", [])
			group_sizes.append(enemy_ids.size())
			for enemy_id: Variant in enemy_ids:
				var enemy := load("res://data/enemies/%s.tres" % String(enemy_id)) as EnemyDef
				_check(enemy != null and not enemy.is_chapter_boss, "%s：随机编队只使用可重复普通/精英敌人 %s" % [scene_id, enemy_id])
		_check(1 in group_sizes and 2 in group_sizes and 3 in group_sizes, "%s：高级随机遭遇覆盖一至三名敌人" % scene_id)
		_check(scene.encounter_allow_full_group_for_solo, "%s：高级区域单人游历时仍可遭遇完整三敌编队" % scene_id)


func _simulate_case(spec: Dictionary) -> Dictionary:
	var party_size := clampi(int(spec.get("party", 1)), 1, 3)
	var level := maxi(1, int(spec.get("level", 1)))
	var enemies := _make_enemies(spec.get("enemy_ids", []), party_size, bool(spec.get("adaptive", false)))
	var allies := _make_allies(level, party_size)
	if enemies.is_empty() or allies.is_empty():
		return {"result": "invalid"}
	var enemy_actions := 0
	for round_index: int in range(1, 21):
		var turn_order: Array[Dictionary] = []
		for ally_index: int in allies.size():
			turn_order.append({"side": "ally", "index": ally_index, "speed": int(allies[ally_index].get("speed", 0))})
		for enemy_index: int in enemies.size():
			turn_order.append({"side": "enemy", "index": enemy_index, "speed": int(enemies[enemy_index].get("speed", 0))})
		turn_order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("speed", 0)) > int(b.get("speed", 0)))
		for turn: Dictionary in turn_order:
			if _all_dead(enemies):
				return _result("victory", round_index, enemy_actions, allies)
			if _all_dead(allies):
				return _result("defeat", round_index, enemy_actions, allies)
			var side := String(turn.get("side", ""))
			var index := int(turn.get("index", -1))
			if side == "ally":
				if index >= 0 and index < allies.size() and float(allies[index].get("hp", 0.0)) > 0.0:
					if not _try_standard_heal(allies[index]):
						_take_best_attack(allies[index], enemies)
			else:
				if index >= 0 and index < enemies.size() and float(enemies[index].get("hp", 0.0)) > 0.0:
					_take_best_attack(enemies[index], allies)
					enemy_actions += 1
	return _result("timeout", 20, enemy_actions, allies)


func _make_allies(level: int, party_size: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var player := CombatBalanceSimulator.standard_player(level)
	var gear := CombatBalanceSimulator.expected_gear_for_level(level)
	result.append({
		"id": "player",
		"hp": float(int(player.get("max_hp", 1)) + int(gear.get("hp_bonus", 0))),
		"max_hp": float(int(player.get("max_hp", 1)) + int(gear.get("hp_bonus", 0))),
		"mp": 84.0 + float(maxi(0, level - 1) * 14),
		"external_attack": int(player.get("external_attack", 1)) + int(gear.get("attack_bonus", 0)),
		"internal_attack": int(player.get("internal_attack", 1)) + int(gear.get("attack_bonus", 0)),
		"defense": int(player.get("defense", 0)) + int(gear.get("defense_bonus", 0)),
		"speed": int(player.get("speed", 0)) + int(gear.get("speed_bonus", 0)),
		"skills": _standard_player_skills(level),
		"extra_scaling": int(gear.get("skill_scaling_bonus", 0)),
		"heals_remaining": 2 if level >= 7 else 0,
	})
	var companion_ids := [&"tang_xingzhou", &"shen_qinghe"]
	for companion_index: int in mini(party_size - 1, companion_ids.size()):
		var template := load("res://data/companions/%s.tres" % String(companion_ids[companion_index])) as CharacterStats
		if template == null:
			continue
		var stats := template.duplicate(true) as CharacterStats
		var gained := maxi(0, level - stats.level)
		stats.strength += gained
		stats.agility += gained
		stats.inner_power += gained
		stats.insight += gained
		stats.vitality += gained * 2
		stats.inner_pool += gained * 2
		stats.guard += gained
		stats.level += gained
		stats.refresh_derived_stats(true)
		var defense := stats.defense + (6 if &"qinghe_jade_guard" in stats.skills else 0)
		result.append({
			"id": stats.character_id,
			"hp": float(stats.max_hp),
			"max_hp": float(stats.max_hp),
			"mp": float(stats.max_mp),
			"external_attack": BattleFormula.calc_external_attack(stats.strength, 0),
			"internal_attack": BattleFormula.calc_internal_attack(stats.inner_power, 0),
			"defense": defense,
			"speed": stats.speed,
			"skills": stats.skills.duplicate(),
			"extra_scaling": 0,
			"heals_remaining": 0,
		})
	return result


func _try_standard_heal(source: Dictionary) -> bool:
	var remaining := int(source.get("heals_remaining", 0))
	var hp := float(source.get("hp", 0.0))
	var max_hp := float(source.get("max_hp", 1.0))
	if remaining <= 0 or hp <= 0.0 or hp > max_hp * 0.42:
		return false
	source["hp"] = minf(max_hp, hp + 200.0)
	source["heals_remaining"] = remaining - 1
	return true


func _standard_player_skills(level: int) -> Array[StringName]:
	## This is a conservative chapter-clear profile, not a completionist build:
	## a chapter-three hidden-master sword and the chapter-seven open-world staff
	## reward. Faction-only and orange arts are deliberately excluded so terminal
	## fights remain viable for the no-faction route without legendary side quests.
	if level <= 2:
		return [&"linxi_basic_sword_one"]
	if level <= 6:
		return [&"linxi_basic_sword_two"]
	if level <= 9:
		return [&"linxi_basic_sword_two", &"shadow_swallow_piercing_sword"]
	if level <= 12:
		return [&"linxi_basic_sword_two", &"shadow_swallow_piercing_sword"]
	return [&"linxi_basic_sword_two", &"shadow_swallow_piercing_sword", &"heaven_pillar_staff"]


func _make_enemies(raw_ids: Variant, party_size: int, adaptive: bool) -> Array[Dictionary]:
	var ids: Array[StringName] = []
	if raw_ids is Array:
		for raw_id: Variant in raw_ids:
			ids.append(StringName(raw_id))
	if adaptive and ids.size() == 1:
		var leader := load("res://data/enemies/%s.tres" % String(ids[0])) as EnemyDef
		if leader != null:
			var support_index := 0
			while ids.size() < party_size and not leader.party_reinforcement_ids.is_empty():
				ids.append(leader.party_reinforcement_ids[support_index % leader.party_reinforcement_ids.size()])
				support_index += 1
	var max_enemy_count := clampi(party_size + 1, 2, 3)
	if ids.size() > max_enemy_count:
		ids.resize(max_enemy_count)
	var result: Array[Dictionary] = []
	for enemy_id: StringName in ids:
		var enemy_def := load("res://data/enemies/%s.tres" % String(enemy_id)) as EnemyDef
		if enemy_def == null:
			continue
		var stats := enemy_def.to_runtime_stats(party_size - 1)
		result.append({
			"id": String(enemy_id),
			"hp": float(stats.max_hp),
			"max_hp": float(stats.max_hp),
			"mp": float(stats.max_mp),
			"external_attack": stats.attack,
			"internal_attack": stats.attack,
			"defense": stats.defense,
			"speed": stats.speed,
			"skills": stats.skills.duplicate(),
			"aggression": enemy_def.aggression,
			"_aggression_meter": 1.0,
			"_signature_cursor": 0,
			"_target_cursor": 0,
		})
	return result


func _take_best_attack(source: Dictionary, targets: Array[Dictionary]) -> void:
	var living_count := _living_count(targets)
	if living_count <= 0:
		return
	var best_skill: Skill = null
	var allow_signature := true
	if source.has("aggression"):
		var aggression := clampf(float(source.get("aggression", 0.5)), 0.0, 1.0)
		var meter := float(source.get("_aggression_meter", 1.0)) + aggression
		allow_signature = meter >= 1.0
		source["_aggression_meter"] = meter - 1.0 if allow_signature else meter
	var candidates: Array[Skill] = []
	for raw_skill_id: Variant in source.get("skills", []):
		var skill := load("res://data/skills/%s.tres" % String(raw_skill_id)) as Skill
		if skill == null or skill.kind != Skill.Kind.ATTACK or float(source.get("mp", 0.0)) < float(skill.mp_cost):
			continue
		if not allow_signature and skill.skill_id != &"basic_attack":
			continue
		candidates.append(skill)
	if source.has("aggression") and allow_signature:
		var signatures: Array[Skill] = candidates.filter(func(skill: Skill) -> bool: return skill.skill_id != &"basic_attack")
		if not signatures.is_empty():
			var cursor := int(source.get("_signature_cursor", 0))
			best_skill = signatures[cursor % signatures.size()]
			source["_signature_cursor"] = cursor + 1
	if best_skill == null:
		var best_damage := -1.0
		for skill: Skill in candidates:
			var probe_target := _first_living(targets)
			if probe_target.is_empty():
				break
			var damage := _expected_damage(source, skill, probe_target)
			var score := damage * float(living_count if skill.target == Skill.Target.ENEMY_ALL else 1)
			if score > best_damage:
				best_damage = score
				best_skill = skill
	if best_skill == null:
		best_skill = load("res://data/skills/basic_attack.tres") as Skill
	if best_skill == null:
		return
	source["mp"] = maxf(0.0, float(source.get("mp", 0.0)) - float(best_skill.mp_cost))
	if best_skill.target == Skill.Target.ENEMY_ALL:
		for target: Dictionary in targets:
			if float(target.get("hp", 0.0)) > 0.0:
				target["hp"] = maxf(0.0, float(target.get("hp", 0.0)) - _expected_damage(source, best_skill, target))
	else:
		var target := _single_target_for(source, targets)
		if not target.is_empty():
			target["hp"] = maxf(0.0, float(target.get("hp", 0.0)) - _expected_damage(source, best_skill, target))


func _single_target_for(source: Dictionary, targets: Array[Dictionary]) -> Dictionary:
	var living: Array[Dictionary] = []
	for target: Dictionary in targets:
		if float(target.get("hp", 0.0)) > 0.0:
			living.append(target)
	if living.is_empty():
		return {}
	if not source.has("aggression"):
		return living[0]
	## Runtime formation AI picks a random living target. Round-robin gives the
	## deterministic audit the same distributed pressure without flaky RNG.
	var cursor := int(source.get("_target_cursor", 0))
	var selected := living[cursor % living.size()]
	source["_target_cursor"] = cursor + 1
	return selected


func _expected_damage(source: Dictionary, skill: Skill, target: Dictionary) -> float:
	var attack_key := "internal_attack" if skill.damage_type == Skill.DamageType.INTERNAL else "external_attack"
	return CombatBalanceSimulator.expected_damage(
		int(source.get(attack_key, 1)), skill.fixed_damage, skill.get_attack_scaling() + int(source.get("extra_scaling", 0)),
		int(target.get("defense", 0)), skill.base_hit_chance, 0.0, 0.0,
		CombatBalanceSimulator.DEFAULT_CRIT_MULTIPLIER,
		maxi(1, roundi(float(source.get("hp", 1.0)))),
		maxi(1, roundi(float(source.get("max_hp", 1.0))))
	)


func _result(result: String, rounds: int, enemy_actions: int, allies: Array[Dictionary]) -> Dictionary:
	var living := 0
	var hp := 0.0
	var max_hp := 0.0
	for ally: Dictionary in allies:
		max_hp += float(ally.get("max_hp", 0.0))
		hp += maxf(0.0, float(ally.get("hp", 0.0)))
		if float(ally.get("hp", 0.0)) > 0.0:
			living += 1
	return {
		"result": result,
		"rounds": rounds,
		"enemy_actions": enemy_actions,
		"party_survivors": living,
		"party_hp_ratio": hp / maxf(1.0, max_hp),
	}


func _first_living(units: Array[Dictionary]) -> Dictionary:
	for unit: Dictionary in units:
		if float(unit.get("hp", 0.0)) > 0.0:
			return unit
	return {}


func _living_count(units: Array[Dictionary]) -> int:
	var count := 0
	for unit: Dictionary in units:
		if float(unit.get("hp", 0.0)) > 0.0:
			count += 1
	return count


func _all_dead(units: Array[Dictionary]) -> bool:
	return _living_count(units) == 0


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
