extends SceneTree

const PLAN_PATHS: Array[String] = [
	"res://data/chapters/chapter_2_content_plan.tres",
	"res://data/chapters/chapter_3_content_plan.tres",
	"res://data/chapters/chapter_4_content_plan.tres",
]

var _failures: Array[String] = []
var _enemy_ids: Dictionary = {}
var _dialog_sources: Dictionary = {}
var _dialog_links: Dictionary = {}
var _scene_dialog_roots: Dictionary = {}


func _initialize() -> void:
	_load_enemy_ids()
	_index_dialog_sources()
	_index_scene_dialog_roots()
	_expand_reachable_dialogs()
	for plan_path: String in PLAN_PATHS:
		_validate_plan(plan_path)
	_validate_hidden_legacy_chain()
	print("[ChapterDepthCheck] plans=%d failed=%d" % [PLAN_PATHS.size(), _failures.size()])
	for failure: String in _failures:
		push_error("[ChapterDepthCheck] %s" % failure)
	quit(1 if not _failures.is_empty() else 0)


func _load_enemy_ids() -> void:
	var directory: DirAccess = DirAccess.open("res://data/enemies")
	if directory == null:
		_failures.append("cannot open enemy directory")
		return
	for filename: String in directory.get_files():
		if not filename.ends_with(".tres"):
			continue
		var enemy: Resource = ResourceLoader.load("res://data/enemies/%s" % filename)
		if enemy != null and String(enemy.get("enemy_id")) != "":
			_enemy_ids[String(enemy.get("enemy_id"))] = true


func _validate_plan(plan_path: String) -> void:
	var plan: Resource = ResourceLoader.load(plan_path)
	if plan == null:
		_failures.append("plan failed to load: %s" % plan_path)
		return
	var chapter: int = int(plan.get("chapter"))
	var owner: String = "chapter %d" % chapter
	var main_minutes: int = int(plan.get("estimated_main_minutes"))
	var full_minutes: int = int(plan.get("estimated_completionist_minutes"))
	var main_scenes: Array[StringName] = plan.get("main_scene_ids") as Array[StringName]
	var main_quests: Array[StringName] = plan.get("main_quest_ids") as Array[StringName]
	var side_quests: Array[StringName] = plan.get("side_quest_ids") as Array[StringName]
	var leveling_scenes: Array[StringName] = plan.get("leveling_scene_ids") as Array[StringName]
	var story_groups: Array[Dictionary] = plan.get("story_battle_groups") as Array[Dictionary]

	_expect(main_minutes >= 60, "%s main route is shorter than 60 minutes" % owner)
	_expect(full_minutes >= 120 and full_minutes <= 240, "%s completionist target must be 120-240 minutes" % owner)
	_expect(main_scenes.size() >= 4, "%s needs at least 4 main scenes" % owner)
	_expect(main_quests.size() >= 3, "%s needs at least 3 main quests" % owner)
	_expect(side_quests.size() >= 5, "%s needs at least 5 side quests" % owner)
	_expect(leveling_scenes.size() >= 2, "%s needs at least 2 leveling scenes" % owner)
	_expect(story_groups.size() >= 3, "%s needs at least 3 authored story battles" % owner)

	for scene_id: StringName in main_scenes:
		_expect(ResourceLoader.exists("res://data/scenes/%s.tres" % String(scene_id)), "%s missing main scene %s" % [owner, scene_id])
	for quest_id: StringName in main_quests:
		_expect(ResourceLoader.exists("res://data/quests/%s.tres" % String(quest_id)), "%s missing main quest %s" % [owner, quest_id])
		_validate_quest_playability(quest_id, owner)
	for quest_id: StringName in side_quests:
		_expect(ResourceLoader.exists("res://data/quests/%s.tres" % String(quest_id)), "%s missing side quest %s" % [owner, quest_id])
		_validate_quest_playability(quest_id, owner)

	var story_sizes: Dictionary = {}
	for group: Dictionary in story_groups:
		var enemy_ids: Array = group.get("enemy_ids", []) as Array
		_validate_enemy_group(enemy_ids, "%s story battle %s" % [owner, String(group.get("id", "unnamed"))])
		story_sizes[enemy_ids.size()] = true
	_expect(story_sizes.has(2), "%s needs a two-enemy story battle" % owner)
	_expect(story_sizes.has(3), "%s needs a three-enemy story battle" % owner)

	for scene_id: StringName in leveling_scenes:
		_validate_leveling_scene(scene_id, owner)


func _validate_leveling_scene(scene_id: StringName, owner: String) -> void:
	var path: String = "res://data/scenes/%s.tres" % String(scene_id)
	var scene: Resource = ResourceLoader.load(path)
	if scene == null:
		_failures.append("%s missing leveling scene %s" % [owner, scene_id])
		return
	_expect(bool(scene.get("is_walkable")), "%s leveling scene %s must be walkable" % [owner, scene_id])
	var groups: Array[Dictionary] = scene.get("encounter_groups") as Array[Dictionary]
	var sizes: Dictionary = {}
	for group: Dictionary in groups:
		var enemy_ids: Array = group.get("enemy_ids", []) as Array
		_validate_enemy_group(enemy_ids, "%s leveling scene %s" % [owner, scene_id])
		sizes[enemy_ids.size()] = true
	# The opening tutorial and formal duels own the 1v1 teaching space. Repeatable
	# leveling routes use 2-enemy baselines and lower-weight 3-enemy danger groups.
	for required_size: int in [2, 3]:
		_expect(sizes.has(required_size), "%s leveling scene %s lacks a %d-enemy formation" % [owner, scene_id, required_size])
	_expect(not sizes.has(1), "%s leveling scene %s must not fall back to a lone enemy" % [owner, scene_id])


func _validate_enemy_group(enemy_ids: Array, owner: String) -> void:
	_expect(enemy_ids.size() >= 1 and enemy_ids.size() <= 3, "%s group size must be 1-3" % owner)
	for enemy_id_variant: Variant in enemy_ids:
		var enemy_id: String = String(enemy_id_variant)
		_expect(_enemy_ids.has(enemy_id), "%s references missing enemy %s" % [owner, enemy_id])


func _index_dialog_sources() -> void:
	var directory := DirAccess.open("res://data/dialogs")
	if directory == null:
		_failures.append("cannot open dialog directory")
		return
	for filename: String in directory.get_files():
		if not filename.ends_with(".tres"):
			continue
		var dialog: Resource = ResourceLoader.load("res://data/dialogs/%s" % filename)
		if dialog == null:
			continue
		var dialog_id := String(dialog.get("dialog_id"))
		if dialog_id.is_empty():
			continue
		var record := {"accepts": {}, "completes": {}, "flags": {}}
		var links: Dictionary = {}
		for node_variant: Variant in dialog.get("nodes"):
			var node := node_variant as Resource
			if node == null:
				continue
			var accepted := String(node.get("accept_quest"))
			var completed := String(node.get("complete_quest"))
			if not accepted.is_empty():
				record.accepts[accepted] = true
			if not completed.is_empty():
				record.completes[completed] = true
			for raw_flag: Variant in node.get("set_flags"):
				if raw_flag is Dictionary and (raw_flag as Dictionary).get("value", false):
					record.flags[String((raw_flag as Dictionary).get("key", ""))] = true
			for raw_choice: Variant in node.get("choices"):
				if raw_choice is Dictionary:
					var choice_flag: Variant = (raw_choice as Dictionary).get("set_flag", {})
					if choice_flag is Dictionary:
						for key: Variant in (choice_flag as Dictionary).keys():
							if (choice_flag as Dictionary).get(key, false):
								record.flags[String(key)] = true
			var on_end := String(node.get("on_end"))
			if on_end.begins_with("dialog:"):
				links[on_end.trim_prefix("dialog:")] = true
		_dialog_sources[dialog_id] = record
		_dialog_links[dialog_id] = links


func _index_scene_dialog_roots() -> void:
	var directory := DirAccess.open("res://data/scenes")
	if directory == null:
		_failures.append("cannot open scene directory")
		return
	for filename: String in directory.get_files():
		if not filename.ends_with(".tres"):
			continue
		var scene: Resource = ResourceLoader.load("res://data/scenes/%s" % filename)
		if scene == null:
			continue
		var intro := scene.get("on_enter_dialog") as Resource
		if intro != null:
			_scene_dialog_roots[String(intro.get("dialog_id"))] = true
		for raw_npc: Variant in scene.get("npcs"):
			if not raw_npc is Dictionary:
				continue
			var npc := raw_npc as Dictionary
			_scene_dialog_roots[String(npc.get("dialog_id", ""))] = true
			for raw_variant: Variant in npc.get("dialog_variants", []):
				if raw_variant is Dictionary:
					_scene_dialog_roots[String((raw_variant as Dictionary).get("dialog_id", ""))] = true
		for raw_hotspot: Variant in scene.get("hotspots"):
			if raw_hotspot is Dictionary:
				var action := String((raw_hotspot as Dictionary).get("action", ""))
				if action.begins_with("dialog:"):
					_scene_dialog_roots[action.trim_prefix("dialog:")] = true
		var layout := scene.get("map_layout") as Resource
		if layout != null:
			for raw_interaction: Variant in layout.get("interactions"):
				if raw_interaction is Dictionary:
					var interaction_action := String((raw_interaction as Dictionary).get("action", ""))
					if interaction_action.begins_with("dialog:"):
						_scene_dialog_roots[interaction_action.trim_prefix("dialog:")] = true
	_scene_dialog_roots.erase("")


func _expand_reachable_dialogs() -> void:
	var changed := true
	while changed:
		changed = false
		for dialog_id_variant: Variant in _scene_dialog_roots.keys():
			var dialog_id := String(dialog_id_variant)
			for linked_id_variant: Variant in (_dialog_links.get(dialog_id, {}) as Dictionary).keys():
				var linked_id := String(linked_id_variant)
				if not _scene_dialog_roots.has(linked_id):
					_scene_dialog_roots[linked_id] = true
					changed = true


func _validate_quest_playability(quest_id: StringName, owner: String) -> void:
	var path := "res://data/quests/%s.tres" % String(quest_id)
	var quest := ResourceLoader.load(path)
	if quest == null:
		return
	var accepted := false
	var completed := false
	var trigger_flags: Dictionary = {}
	for raw_trigger: Variant in quest.get("completion_triggers"):
		var trigger := String(raw_trigger)
		if trigger.begins_with("flag_set:"):
			trigger_flags[trigger.trim_prefix("flag_set:")] = true
	for dialog_id_variant: Variant in _scene_dialog_roots.keys():
		var dialog_id := String(dialog_id_variant)
		var record: Dictionary = _dialog_sources.get(dialog_id, {}) as Dictionary
		accepted = accepted or (record.get("accepts", {}) as Dictionary).has(String(quest_id))
		completed = completed or (record.get("completes", {}) as Dictionary).has(String(quest_id))
		for flag_variant: Variant in trigger_flags.keys():
			if (record.get("flags", {}) as Dictionary).has(String(flag_variant)):
				completed = true
	_expect(accepted, "%s quest %s has no scene-reachable accept source" % [owner, quest_id])
	_expect(completed, "%s quest %s has no scene-reachable completion source" % [owner, quest_id])
	_expect(not String(quest.get("tracker_hint")).strip_edges().is_empty(), "%s quest %s lacks a spoiler-free tracker hint" % [owner, quest_id])


func _validate_hidden_legacy_chain() -> void:
	for item_id: String in ["canglong_fragment_upper", "canglong_fragment_middle", "canglong_fragment_lower"]:
		_expect(ResourceLoader.exists("res://data/items/%s.tres" % item_id), "hidden manual is missing %s" % item_id)
	_expect(ResourceLoader.exists("res://data/skills/canglong_three_turns.tres"), "hidden manual reward skill is missing")
	_expect(ResourceLoader.exists("res://data/equipment/hanjia_canal_blade.tres"), "historical mystery weapon is missing")
	_expect(_scene_dialog_roots.has("ch2_canglong_fragment_upper"), "upper manual page is not reachable in chapter 2")
	_expect(_scene_dialog_roots.has("ch3_canglong_fragment_middle"), "middle manual page is not reachable in chapter 3")
	_expect(_scene_dialog_roots.has("ch4_luoyang_paper_turnin"), "lower manual page is not reachable in chapter 4")
	_expect(_scene_dialog_roots.has("ch4_canglong_assemble"), "manual assembly is not reachable in chapter 4")
	_expect(_scene_dialog_roots.has("ch4_hanjia_blade_recover"), "mystery weapon recovery is not reachable")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
