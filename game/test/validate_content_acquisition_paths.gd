extends SceneTree

## Every player-facing item, weapon and martial art must have a real acquisition
## path. This catches the recurring failure mode where a .tres exists but can
## never be obtained in a normal playthrough.

const PLAYER_SKILL_EXEMPTIONS: Array[StringName] = [
	&"ch8_su_teapot_meridian_rain",
	&"heavy_swing",
	&"qinghe_jade_guard",
	&"qinghe_returning_breath",
	&"qinghe_swallow_sword",
	&"tang_staff_breaker",
	&"tang_staff_sweep",
	&"zhao_black_wind_sweep",
	&"zhao_broken_gate_strike",
]
const FACTION_SKILLS: Dictionary = {
	"wudang": [&"wudang_xuanwu_ge"],
	"huashan": [&"huashan_yijian"],
	"gufeng": [&"gufeng_kaishan_yidao"],
	"lingyue": [&"lingyue_lingbo_yizhi"],
	"mingwu": [&"mingwu_saofeng"],
	"wanderer": [],
}
const INITIAL_SKILLS: Array[StringName] = [&"basic_attack", &"linxi_basic_sword_one", &"defend"]
const INITIAL_ITEMS: Array[StringName] = [&"linxi_jiu"]

var _failures: Array[String] = []
var _item_defs: Dictionary = {}
var _skill_defs: Dictionary = {}
var _item_paths: Dictionary = {}
var _skill_paths: Dictionary = {}
var _shop_references: Dictionary = {}


func _initialize() -> void:
	_load_definitions()
	for item_id: StringName in INITIAL_ITEMS:
		_add_path(_item_paths, item_id, "initial/tutorial")
	_index_initial_and_faction_skills()
	_index_skill_evolutions()
	_index_shop_references()
	_index_shops()
	_index_quests()
	_index_dialogs()
	_index_readable_discoveries()
	_index_enemies()
	_validate_coverage()

	print("[ContentAcquisitionPaths] items=%d skills=%d failed=%d" % [
		_item_defs.size(), _skill_defs.size(), _failures.size()
	])
	for failure: String in _failures:
		push_error("[ContentAcquisitionPaths] %s" % failure)
	quit(1 if not _failures.is_empty() else 0)


func _load_definitions() -> void:
	for directory: String in ["res://data/items", "res://data/equipment"]:
		for path: String in _resource_paths(directory):
			var item := ResourceLoader.load(path) as Item
			_expect(item != null, "cannot load item resource %s" % path)
			if item == null:
				continue
			_expect(String(item.item_id) == path.get_file().get_basename(),
				"item id/file mismatch: %s => %s" % [path, item.item_id])
			_expect(not _item_defs.has(item.item_id), "duplicate item id %s" % item.item_id)
			_item_defs[item.item_id] = item
	for path: String in _resource_paths("res://data/skills"):
		var skill := ResourceLoader.load(path) as Skill
		_expect(skill != null, "cannot load skill resource %s" % path)
		if skill == null:
			continue
		_expect(String(skill.skill_id) == path.get_file().get_basename(),
			"skill id/file mismatch: %s => %s" % [path, skill.skill_id])
		_expect(not _skill_defs.has(skill.skill_id), "duplicate skill id %s" % skill.skill_id)
		_skill_defs[skill.skill_id] = skill


func _index_initial_and_faction_skills() -> void:
	for skill_id: StringName in INITIAL_SKILLS:
		_add_path(_skill_paths, skill_id, "initial")
	for raw_skills: Variant in FACTION_SKILLS.values():
		if raw_skills is Array:
			for raw_skill_id: Variant in raw_skills:
				_add_path(_skill_paths, StringName(String(raw_skill_id)), "faction")


func _index_skill_evolutions() -> void:
	var game_state_source := FileAccess.get_file_as_string("res://scripts/autoload/game_state.gd")
	var runtime_supports_evolution := (
		game_state_source.contains("_apply_linxi_master_breakthrough")
		and game_state_source.contains("LINXI_EVOLVED_ARTS")
	)
	_expect(runtime_supports_evolution, "GameState is missing the authored skill-evolution path")
	for raw_skill_id: Variant in _skill_defs.keys():
		var base_skill := _skill_defs[raw_skill_id] as Skill
		if base_skill == null or base_skill.evolves_to_skill_id == &"":
			continue
		var evolved_id := base_skill.evolves_to_skill_id
		_expect(_skill_defs.has(evolved_id), "%s evolves to missing skill %s" % [base_skill.skill_id, evolved_id])
		if runtime_supports_evolution and _skill_defs.has(evolved_id):
			_add_path(_skill_paths, evolved_id, "evolution:%s" % String(base_skill.skill_id))


func _index_shops() -> void:
	for path: String in _resource_paths("res://data/shops"):
		var shop := ResourceLoader.load(path) as ShopDef
		_expect(shop != null, "cannot load shop resource %s" % path)
		if shop == null:
			continue
		_expect(String(shop.shop_id) == path.get_file().get_basename(),
			"shop id/file mismatch: %s => %s" % [path, shop.shop_id])
		var reachable: bool = _shop_references.has(shop.shop_id)
		for item_id: StringName in shop.stock:
			_expect(_item_defs.has(item_id), "%s sells missing item %s" % [shop.shop_id, item_id])
			if reachable:
				_add_path(_item_paths, item_id, "shop:%s" % shop.shop_id)
			var item: Item = _item_defs.get(item_id)
			if item != null:
				_expect(item.quality < Item.Quality.LEGENDARY,
					"legendary item %s must not be sold in a normal shop" % item_id)


func _index_shop_references() -> void:
	var matcher := RegEx.new()
	matcher.compile("shop:([A-Za-z0-9_]+)")
	for directory: String in ["res://data/scenes", "res://data/maps", "res://data/dialogs"]:
		for path: String in _resource_paths(directory):
			var source := FileAccess.get_file_as_string(path)
			for match: RegExMatch in matcher.search_all(source):
				_shop_references[StringName(match.get_string(1))] = true


func _index_quests() -> void:
	for path: String in _resource_paths("res://data/quests"):
		var quest := ResourceLoader.load(path) as QuestDef
		_expect(quest != null, "cannot load quest resource %s" % path)
		if quest == null:
			continue
		_expect(String(quest.quest_id) == path.get_file().get_basename(),
			"quest id/file mismatch: %s => %s" % [path, quest.quest_id])
		for entry: Dictionary in quest.reward_items:
			var item_id := StringName(String(entry.get("id", entry.get("item_id", ""))))
			_expect(_item_defs.has(item_id), "%s rewards missing item %s" % [quest.quest_id, item_id])
			_add_path(_item_paths, item_id, "quest:%s" % quest.quest_id)
		for skill_id: StringName in quest.reward_skills:
			_expect(_skill_defs.has(skill_id), "%s rewards missing skill %s" % [quest.quest_id, skill_id])
			_add_path(_skill_paths, skill_id, "quest:%s" % quest.quest_id)
		for faction_id: Variant in quest.reward_skills_by_faction.keys():
			var rewards: Variant = quest.reward_skills_by_faction[faction_id]
			_expect(rewards is Array, "%s faction reward %s is not an Array" % [quest.quest_id, faction_id])
			if not rewards is Array:
				continue
			for raw_skill_id: Variant in rewards:
				var skill_id := StringName(String(raw_skill_id))
				_expect(_skill_defs.has(skill_id), "%s rewards missing skill %s" % [quest.quest_id, skill_id])
				var skill: Skill = _skill_defs.get(skill_id)
				_expect(skill == null or skill.school == String(faction_id),
					"%s gives %s to wrong faction %s" % [quest.quest_id, skill_id, faction_id])
				_add_path(_skill_paths, skill_id, "faction_quest:%s" % quest.quest_id)
		for flag_id: Variant in quest.reward_skills_by_flag.keys():
			var rewards: Variant = quest.reward_skills_by_flag[flag_id]
			_expect(rewards is Array, "%s flag reward %s is not an Array" % [quest.quest_id, flag_id])
			if not rewards is Array:
				continue
			for raw_skill_id: Variant in rewards:
				var skill_id := StringName(String(raw_skill_id))
				_expect(_skill_defs.has(skill_id), "%s rewards missing skill %s" % [quest.quest_id, skill_id])
				_add_path(_skill_paths, skill_id, "flag_quest:%s:%s" % [quest.quest_id, flag_id])


func _index_dialogs() -> void:
	for path: String in _resource_paths("res://data/dialogs"):
		var dialog := ResourceLoader.load(path) as DialogScript
		_expect(dialog != null, "cannot load dialog resource %s" % path)
		if dialog == null:
			continue
		for node: DialogNode in dialog.nodes:
			for entry: Dictionary in node.give_items:
				var item_id := StringName(String(entry.get("id", entry.get("item_id", ""))))
				_expect(_item_defs.has(item_id), "%s gives missing item %s" % [dialog.dialog_id, item_id])
				_add_path(_item_paths, item_id, "dialog:%s" % dialog.dialog_id)
			for skill_id: StringName in node.learn_skills:
				_expect(_skill_defs.has(skill_id), "%s teaches missing skill %s" % [dialog.dialog_id, skill_id])
				_add_path(_skill_paths, skill_id, "dialog:%s" % dialog.dialog_id)


func _index_readable_discoveries() -> void:
	var matcher := RegEx.new()
	matcher.compile("discover_readable:([A-Za-z0-9_]+)")
	for directory: String in ["res://data/scenes", "res://data/maps"]:
		for path: String in _resource_paths(directory):
			var source := FileAccess.get_file_as_string(path)
			for match: RegExMatch in matcher.search_all(source):
				var item_id := StringName(match.get_string(1))
				_expect(_item_defs.has(item_id), "%s discovers missing readable item %s" % [path, item_id])
				_add_path(_item_paths, item_id, "readable_discovery:%s" % path.get_file())


func _index_enemies() -> void:
	for path: String in _resource_paths("res://data/enemies"):
		var enemy := ResourceLoader.load(path) as EnemyDef
		_expect(enemy != null, "cannot load enemy resource %s" % path)
		if enemy == null:
			continue
		_expect(String(enemy.enemy_id) == path.get_file().get_basename(),
			"enemy id/file mismatch: %s => %s" % [path, enemy.enemy_id])
		for item_id: StringName in enemy.drop_items:
			_expect(_item_defs.has(item_id), "%s drops missing item %s" % [enemy.enemy_id, item_id])
			_add_path(_item_paths, item_id, "enemy:%s" % enemy.enemy_id)
		for entry: Dictionary in enemy.drop_random:
			var item_id := StringName(String(entry.get("id", entry.get("item_id", ""))))
			_expect(_item_defs.has(item_id), "%s randomly drops missing item %s" % [enemy.enemy_id, item_id])
			_add_path(_item_paths, item_id, "enemy:%s" % enemy.enemy_id)


func _validate_coverage() -> void:
	for item_id: StringName in _item_defs.keys():
		_expect(_item_paths.has(item_id), "item/equipment has no acquisition path: %s" % item_id)
	for skill_id: StringName in _skill_defs.keys():
		if skill_id in PLAYER_SKILL_EXEMPTIONS:
			continue
		_expect(_skill_paths.has(skill_id), "player skill has no learning path: %s" % skill_id)


func _add_path(index: Dictionary, id: StringName, method: String) -> void:
	if id == &"":
		return
	if not index.has(id):
		index[id] = []
	if method not in index[id]:
		index[id].append(method)


func _resource_paths(directory: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(directory)
	if dir == null:
		_failures.append("cannot open %s" % directory)
		return result
	for filename: String in dir.get_files():
		if filename.ends_with(".tres"):
			result.append("%s/%s" % [directory, filename])
	result.sort()
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
