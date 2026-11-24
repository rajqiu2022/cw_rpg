extends SceneTree

const CHAPTER_LEVELS: Dictionary = {1: 1, 2: 2, 3: 3, 4: 4}
const CHAPTER_ENTRIES: Dictionary = {
	1: "linxi_tutorial",
	2: "ch2_s1_zhuwei_market",
	3: "ch3_s1_wulin_assembly",
	4: "ch4_s1_luoyang_yamen",
}
const DEFAULT_SKILL_ID := "linxi_basic_sword_one"
const BOSS_SKILL_ID := "linxi_basic_sword_two"

var _failures: Array[String] = []
var _warnings: Array[String] = []
var _battle_chapters: Dictionary = {}
var _scenes: Dictionary = {}
var _dialogs: Dictionary = {}
var _graph: Dictionary = {}
var _battle_sources: Dictionary = {}


func _initialize() -> void:
	_load_resources("res://data/scenes", "scene_id", _scenes)
	_load_resources("res://data/dialogs", "dialog_id", _dialogs)
	_build_reachability_graph()
	_collect_reachable_battles()
	_collect_chapter_one_plan_battles()
	if _battle_chapters.is_empty():
		_failures.append("no chapter 1-4 battle actions were found")
	for enemy_id_variant in _battle_chapters.keys():
		var enemy_id: String = String(enemy_id_variant)
		var chapter: int = int(_battle_chapters[enemy_id])
		_validate_encounter(enemy_id, chapter)
	if not _battle_chapters.has("thug_lone"):
		_validate_encounter("thug_lone", 1)

	print("[ChapterBalanceCheck] encounters=%d warnings=%d failed=%d" % [
		_battle_chapters.size(), _warnings.size(), _failures.size(),
	])
	for warning in _warnings:
		print("[ChapterBalanceCheck] WARN: %s" % warning)
	for failure in _failures:
		push_error("[ChapterBalanceCheck] %s" % failure)
	quit(1 if not _failures.is_empty() else 0)


func _load_resources(directory: String, id_property: String, output: Dictionary) -> void:
	var dir: DirAccess = DirAccess.open(directory)
	if dir == null:
		_failures.append("cannot open data directory: %s" % directory)
		return
	for filename in dir.get_files():
		if not filename.ends_with(".tres"):
			continue
		var path: String = "%s/%s" % [directory, filename]
		var resource: Resource = ResourceLoader.load(path)
		if resource == null:
			continue
		var resource_id: String = String(resource.get(id_property))
		if resource_id != "":
			output[resource_id] = resource


func _build_reachability_graph() -> void:
	for scene_id_variant in _scenes.keys():
		var scene_id: String = String(scene_id_variant)
		var owner: String = "scene:%s" % scene_id
		var scene: Resource = _scenes[scene_id]
		_ensure_node(owner)
		var enter_dialog: Resource = scene.get("on_enter_dialog")
		if enter_dialog != null:
			_add_edge(owner, "dialog:%s" % String(enter_dialog.get("dialog_id")))
		for hotspot in scene.get("hotspots"):
			_record_action(String(hotspot.get("action", "")), owner)
		for zone in scene.get("trigger_zones"):
			_record_action(String(zone.get("action", "")), owner)
		for exit_def in scene.get("exits"):
			_add_edge(owner, "scene:%s" % String(exit_def.get("target_scene", "")))
		for npc in scene.get("npcs"):
			var dialog_id: String = String(npc.get("dialog_id", ""))
			if dialog_id != "":
				_add_edge(owner, "dialog:%s" % dialog_id)
	for dialog_id_variant in _dialogs.keys():
		var dialog_id: String = String(dialog_id_variant)
		var owner: String = "dialog:%s" % dialog_id
		var dialog: Resource = _dialogs[dialog_id]
		_ensure_node(owner)
		for node in dialog.get("nodes"):
			_record_action(String(node.get("on_end")), owner)
			for choice in node.get("choices"):
				_record_action(String(choice.get("action", "")), owner)


func _collect_reachable_battles() -> void:
	for chapter_variant in CHAPTER_ENTRIES.keys():
		var chapter: int = int(chapter_variant)
		var entry: String = "scene:%s" % String(CHAPTER_ENTRIES[chapter])
		if not _graph.has(entry):
			continue
		var reachable: Dictionary = _reachable_from(entry)
		for enemy_id_variant in _battle_sources.keys():
			var enemy_id: String = String(enemy_id_variant)
			for source in _battle_sources[enemy_id]:
				if reachable.has(source):
					if not _battle_chapters.has(enemy_id) or chapter < int(_battle_chapters[enemy_id]):
						_battle_chapters[enemy_id] = chapter
					break


func _collect_chapter_one_plan_battles() -> void:
	var plan := load("res://data/chapters/chapter_1_content_plan.tres") as ChapterContentPlan
	if plan == null:
		_failures.append("chapter 1 content plan is missing")
		return
	for group: Dictionary in plan.story_battle_groups:
		for raw_enemy_id: Variant in group.get("enemy_ids", []):
			_battle_chapters[String(raw_enemy_id)] = 1


func _record_action(action: String, owner: String) -> void:
	if action == "":
		return
	var parts: PackedStringArray = action.split(":", true)
	if parts.size() < 2:
		return
	var command: String = parts[0]
	var target: String = parts[1]
	if command == "scene" or command == "dialog":
		_add_edge(owner, "%s:%s" % [command, target])
	elif command in ["battle", "battle_solo", "battle_then", "battle_solo_then"] and target != "":
		if not _battle_sources.has(target):
			_battle_sources[target] = [] as Array[String]
		var sources: Array = _battle_sources[target]
		if not sources.has(owner):
			sources.append(owner)
		_battle_sources[target] = sources
	elif command in ["battle_group", "battle_group_then"] and target != "":
		for enemy_id in target.split(",", false):
			var clean_id: String = enemy_id.strip_edges()
			if clean_id == "":
				continue
			if not _battle_sources.has(clean_id):
				_battle_sources[clean_id] = [] as Array[String]
			var sources: Array = _battle_sources[clean_id]
			if not sources.has(owner):
				sources.append(owner)
			_battle_sources[clean_id] = sources


func _validate_encounter(enemy_id: String, chapter: int) -> void:
	var path: String = "res://data/enemies/%s.tres" % enemy_id
	var enemy: Resource = ResourceLoader.load(path)
	if enemy == null:
		_failures.append("chapter %d battle target is missing: %s" % [chapter, enemy_id])
		return
	var is_chapter_one_boss: bool = chapter == 1 and bool(enemy.is_chapter_boss)
	# Zhao Wuji is authored for the expanded route: the player returns to the
	# master, learns the 150% second sword form, equips the iron sword, and can
	# reach level 3 through the dojo, road encounters, and bandit cave.
	var player_level: int = 3 if is_chapter_one_boss else int(CHAPTER_LEVELS.get(chapter, chapter))
	var player_attack: int = 24 + (player_level - 1) * 3
	var skill_id := DEFAULT_SKILL_ID
	var equipment_scaling_bonus := 0
	if is_chapter_one_boss:
		player_attack += 4
		skill_id = BOSS_SKILL_ID
		equipment_scaling_bonus = 10
	var skill: Skill = load("res://data/skills/%s.tres" % skill_id)
	if skill == null:
		_failures.append("missing baseline skill: %s" % skill_id)
		return
	var median_damage: int = BattleFormula.calc_damage_value(
		player_attack, skill.fixed_damage, skill.get_attack_scaling() + equipment_scaling_bonus,
		enemy.defense
	)
	var player_turns: int = int(ceil(float(enemy.max_hp) / float(median_damage)))
	var max_turns: int = _max_target_turns(enemy, enemy_id)
	if player_turns > max_turns:
		_failures.append("chapter %d %s projects %d turns, target <= %d (player Lv%d atk=%d, enemy hp=%d def=%d)" % [
			chapter, enemy_id, player_turns, max_turns, player_level, player_attack, enemy.max_hp, enemy.defense,
		])
	var min_turns: int = _min_target_turns(enemy, enemy_id)
	if player_turns < min_turns:
		_warnings.append("chapter %d %s projects only %d turns, target >= %d" % [chapter, enemy_id, player_turns, min_turns])
	var player_hp: int = 184 + (player_level - 1) * 19
	var player_defense: int = 22 + (player_level - 1) * 3
	var incoming: int = _enemy_average_skill_damage(enemy, player_defense)
	var enemy_turns_to_win: int = int(ceil(float(player_hp) / float(incoming)))
	if enemy_turns_to_win < player_turns - 1:
		_failures.append("chapter %d %s defeats baseline player in %d enemy turns before projected %d-turn victory" % [
			chapter, enemy_id, enemy_turns_to_win, player_turns,
		])
	if incoming == 1 and not enemy_id == "thug_lone" and not enemy_id.begins_with("linxi_dojo_"):
		_warnings.append("chapter %d %s deals minimum chip damage to baseline player; encounter may lack challenge" % [chapter, enemy_id])
	print("[ChapterBalanceCheck] ch%d %-28s player_turns=%d/%d incoming=%d" % [chapter, enemy_id, player_turns, max_turns, incoming])


func _enemy_average_skill_damage(enemy: EnemyDef, player_defense: int) -> int:
	var values: Array[int] = []
	for skill_id: StringName in enemy.skill_ids:
		var skill: Skill = load("res://data/skills/%s.tres" % String(skill_id))
		if skill == null or not (skill.kind == Skill.Kind.ATTACK or skill.kind == Skill.Kind.DEBUFF):
			continue
		values.append(BattleFormula.calc_damage_value(enemy.attack, skill.fixed_damage, skill.get_attack_scaling(), player_defense))
	if values.is_empty():
		return BattleFormula.calc_damage_value(enemy.attack, 2, 100, player_defense)
	var total := 0
	for value: int in values:
		total += value
	return maxi(1, int(round(float(total) / float(values.size()))))


func _max_target_turns(enemy: Resource, enemy_id: String) -> int:
	if enemy_id == "thug_lone":
		return 4
	if enemy_id == "zhuwei_cave_wolf":
		return 9
	if enemy.is_chapter_boss or enemy_id.contains("leader") or enemy_id.begins_with("boss_"):
		return 10
	if enemy_id.contains("elite") or enemy_id.contains("examiner") or enemy_id.contains("ambusher") or enemy_id.contains("assassin"):
		return 7
	return 6


func _min_target_turns(enemy: Resource, enemy_id: String) -> int:
	# Dojo sparring is an authored tutorial/power-feedback exception, not a field encounter.
	if enemy_id.begins_with("linxi_dojo_"):
		return 2
	if enemy_id == "thug_lone":
		return 3
	if enemy_id == "zhuwei_cave_wolf":
		return 7
	if enemy.is_chapter_boss or enemy_id.contains("leader") or enemy_id.begins_with("boss_"):
		return 6
	if enemy_id.contains("elite") or enemy_id.contains("examiner") or enemy_id.contains("ambusher") or enemy_id.contains("assassin"):
		return 5
	return 4


func _ensure_node(node: String) -> void:
	if not _graph.has(node):
		_graph[node] = [] as Array[String]


func _add_edge(source: String, target: String) -> void:
	if target.ends_with(":"):
		return
	_ensure_node(source)
	var edges: Array = _graph[source]
	if not edges.has(target):
		edges.append(target)
	_graph[source] = edges


func _reachable_from(start: String) -> Dictionary:
	var visited: Dictionary = {}
	var pending: Array[String] = [start]
	while not pending.is_empty():
		var current: String = pending.pop_front()
		if visited.has(current):
			continue
		visited[current] = true
		for target in _graph.get(current, []):
			if not visited.has(target):
				pending.append(String(target))
	return visited
