extends SceneTree

const PLAN_PATH := "res://data/chapters/chapter_5_content_plan.tres"
const EXPECTED_ENEMIES := [
	&"ch5_relief_road_raider",
	&"ch5_false_liuyun_striker",
	&"ch5_snow_pass_pursuer",
	&"ch5_mine_tunnel_hunter",
	&"ch5_false_banner_captain",
]

var failures := 0


func _initialize() -> void:
	var plan := load(PLAN_PATH) as ChapterContentPlan
	_check(plan != null, "chapter five content plan loads")
	if plan != null:
		_check(plan.chapter == 5 and plan.title == "古峰残雪", "chapter five plan follows the revised canon")
		_check(plan.story_battle_groups.size() == 5, "chapter five owns five formal story battle anchors")
		_check(_group_sizes_cover(plan.story_battle_groups, [2, 3]), "chapter five anchors cover two- and three-enemy formations")
		_check(_plan_enemies_resolve(plan.story_battle_groups), "every chapter five battle group resolves to authored enemies")
		_check(not _plan_contains(plan.story_battle_groups, &"mingwu_assassin_squad"), "retired unresolved squad id is absent from the formal plan")
	for enemy_id: StringName in EXPECTED_ENEMIES:
		var enemy := load("res://data/enemies/%s.tres" % String(enemy_id)) as EnemyDef
		_check(enemy != null, "chapter five enemy loads: %s" % enemy_id)
		if enemy != null:
			_check(enemy.level >= 7 and enemy.level <= 9, "%s stays in the Lv7-9 chapter band" % enemy_id)
			_check(enemy.max_hp >= 260 and enemy.attack >= 68 and enemy.defense >= 12, "%s has production anchor stats rather than old placeholder values" % enemy_id)
			_check(not enemy.skill_ids.is_empty(), "%s owns an actionable skill roster" % enemy_id)
	var specs := CombatBalanceSimulator.get_encounter_specs()
	var chapter_five_specs := specs.filter(func(spec: Dictionary): return int(spec.get("chapter", 0)) == 5)
	_check(specs.size() == 40 and chapter_five_specs.size() == 5, "standard simulator includes all five chapter five anchors")
	_check(_specs_cover_level_band(chapter_five_specs), "chapter five simulator spans recommended levels 7 through 9")
	var storyline := JSON.parse_string(FileAccess.get_file_as_string("res://../docs/storyline-data.json")) as Dictionary
	_check(_chapter_five_is_implemented(storyline), "chapter five is runtime-complete after all five anchors are linked")
	print("[Chapter5BattleAnchors20260824] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _group_sizes_cover(groups: Array[Dictionary], sizes: Array[int]) -> bool:
	var found: Dictionary = {}
	for group: Dictionary in groups:
		found[(group.get("enemy_ids", []) as Array).size()] = true
	return sizes.all(func(size: int): return found.has(size))


func _plan_enemies_resolve(groups: Array[Dictionary]) -> bool:
	for group: Dictionary in groups:
		for enemy_id: StringName in group.get("enemy_ids", []):
			if load("res://data/enemies/%s.tres" % String(enemy_id)) as EnemyDef == null:
				return false
	return true


func _plan_contains(groups: Array[Dictionary], enemy_id: StringName) -> bool:
	for group: Dictionary in groups:
		if enemy_id in group.get("enemy_ids", []):
			return true
	return false


func _specs_cover_level_band(specs: Array) -> bool:
	var levels: Array[int] = []
	for spec: Dictionary in specs:
		levels.append(int(spec.get("player_level", 0)))
	return 7 in levels and 8 in levels and 9 in levels


func _chapter_five_is_implemented(storyline: Dictionary) -> bool:
	for raw: Variant in storyline.get("chapters", []):
		var chapter := raw as Dictionary
		if int(chapter.get("number", 0)) == 5:
			return String(chapter.get("implementation", "")) == "implemented"
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
