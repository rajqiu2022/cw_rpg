extends SceneTree

const CHAPTER_ENTRIES: Dictionary = {
	1: "linxi_tutorial",
	2: "ch2_s1_zhuwei_market",
	3: "ch3_s1_wulin_assembly",
	4: "ch4_s1_luoyang_yamen",
}
const MAIN_QUESTS: Dictionary = {
	1: ["q_ch1_main_get_sword", "q_ch1_main_road", "q_ch1_main_return_master", "q_ch1_main_training", "q_ch1_main_zhuwei", "q_ch1_main_village_inquiry", "q_ch1_main_zhuwei_wilds", "q_ch1_main_west_ruin_trace", "q_ch1_main_west_ruin"],
	2: ["q_ch2_main_01_investigate", "q_ch2_main_02_rescue_yue", "q_ch2_main_03_trace_hideout", "q_ch2_main_04_report_lingyue"],
	3: ["q_ch3_main_00_assembly_clues", "q_ch3_main_01_join_faction", "q_ch3_main_02_faction_training", "q_ch3_main_03_token_conspiracy"],
	4: ["q_ch4_main_01_luoyang_case", "q_ch4_main_02_ancient_temple", "q_ch4_main_03_canal_witness", "q_ch4_main_04_tunnel_mastermind"],
}
const FACTIONS: Array[String] = ["wudang", "huashan", "gufeng", "lingyue", "mingwu", "wanderer"]
const VALID_ACTIONS: Array[String] = [
	"end", "next", "dialog", "battle", "battle_solo", "battle_then", "battle_solo_then", "battle_group", "battle_group_then", "spar", "scene", "shop", "give_item", "read_item", "discover_readable", "give_gold",
	"set_flag", "accept_quest", "complete_quest", "open_inventory", "open_equipment",
	"open_skills", "open_quest_log", "chapter_end", "play_bgm", "play_sfx", "stop_bgm",
	"field_cutscene",
	"world_map", "world_map_return",
	"join_faction", "add_evidence", "verify_evidence", "add_testimony", "verify_testimony",
	"faction_trust", "companion_trust", "add_bond", "city_outcome", "method_flag",
]

var _failures: Array[String] = []
var _warnings: Array[String] = []
var _scenes: Dictionary = {}
var _dialogs: Dictionary = {}
var _quests: Dictionary = {}
var _graph: Dictionary = {}
var _quest_accept_sources: Dictionary = {}
var _quest_complete_sources: Dictionary = {}
var _flag_sources: Dictionary = {}
var _battle_sources: Dictionary = {}
var _item_sources: Dictionary = {}
var _npc_sources: Dictionary = {}


func _initialize() -> void:
	_load_resources("res://data/scenes", "scene_id", _scenes)
	_load_resources("res://data/dialogs", "dialog_id", _dialogs)
	_load_resources("res://data/quests", "quest_id", _quests)
	_validate_scene_resources()
	_validate_dialog_resources()
	_validate_quest_resources()
	_validate_chapter_chain()
	_validate_faction_exclusivity()

	print("[ChapterFlowCheck] scenes=%d dialogs=%d quests=%d warnings=%d failed=%d" % [
		_scenes.size(), _dialogs.size(), _quests.size(), _warnings.size(), _failures.size(),
	])
	for warning in _warnings:
		print("[ChapterFlowCheck] WARN: %s" % warning)
	for failure in _failures:
		push_error("[ChapterFlowCheck] %s" % failure)
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
			if _is_chapter_resource(filename):
				_failures.append("resource failed to load: %s" % path)
			continue
		var resource_id: String = String(resource.get(id_property))
		if resource_id != "":
			output[resource_id] = resource


func _validate_scene_resources() -> void:
	for scene_id_variant in _scenes.keys():
		var scene_id: String = String(scene_id_variant)
		if not _is_chapter_scene(scene_id):
			continue
		var scene: Resource = _scenes[scene_id]
		var owner: String = "scene:%s" % scene_id
		_ensure_graph_node(owner)
		if String(scene.scene_id) != scene_id:
			_failures.append("scene id/path mismatch: %s" % scene.resource_path)
		if scene.on_enter_dialog != null:
			var dialog_id: String = String(scene.on_enter_dialog.dialog_id)
			_add_edge(owner, "dialog:%s" % dialog_id)
			_validate_target("dialog", dialog_id, "%s on_enter_dialog" % owner)
		for hotspot in scene.hotspots:
			_validate_action(String(hotspot.get("action", "")), owner, "hotspot")
		for zone in scene.trigger_zones:
			_validate_action(String(zone.get("action", "")), owner, "trigger_zone")
		for exit_def in scene.exits:
			var target: String = String(exit_def.get("target_scene", ""))
			var action: String = String(exit_def.get("action", ""))
			if target == "" and action == "":
				_failures.append("%s exit has neither target_scene nor action" % owner)
			elif target != "":
				_validate_target("scene", target, "%s exit" % owner)
				_add_edge(owner, "scene:%s" % target)
			else:
				_validate_action(action, owner, "exit")
		for npc in scene.npcs:
			var npc_id: String = String(npc.get("npc_id", ""))
			if npc_id != "":
				_append_source(_npc_sources, npc_id, owner)
			var dialog_id: String = String(npc.get("dialog_id", ""))
			if dialog_id != "":
				_validate_target("dialog", dialog_id, "%s npc:%s" % [owner, npc_id])
				_add_edge(owner, "dialog:%s" % dialog_id)
			_validate_action(String(npc.get("interaction_action", "")), owner, "%s npc:%s action" % [owner, npc_id])
			for raw_variant: Variant in npc.get("dialog_variants", []):
				if not raw_variant is Dictionary:
					continue
				var variant: Dictionary = raw_variant
				var variant_dialog_id: String = String(variant.get("dialog_id", ""))
				if variant_dialog_id == "":
					continue
				_validate_target("dialog", variant_dialog_id, "%s npc:%s variant" % [owner, npc_id])
				_add_edge(owner, "dialog:%s" % variant_dialog_id)
		# Walkable maps carry the live scene graph. Ignoring their portals and
		# interaction actions makes a release validator follow retired hotspot data
		# instead of the route the player can actually take in game.
		if scene.map_layout != null:
			for object_entry in scene.map_layout.visual_objects:
				var object_data: Dictionary = object_entry
				_validate_action(String(object_data.get("interaction_action", "")), owner, "map visual object")
			for interaction_entry in scene.map_layout.interactions:
				var interaction_data: Dictionary = interaction_entry
				_validate_action(String(interaction_data.get("action", "")), owner, "map interaction")
			for portal_entry in scene.map_layout.portals:
				var portal_data: Dictionary = portal_entry
				var portal_scene: String = String(portal_data.get("target_scene", ""))
				var portal_action: String = String(portal_data.get("action", ""))
				if portal_scene != "":
					_validate_target("scene", portal_scene, "%s map portal" % owner)
					_add_edge(owner, "scene:%s" % portal_scene)
				elif portal_action != "":
					_validate_action(portal_action, owner, "map portal")
				else:
					_failures.append("%s map portal has neither target_scene nor action" % owner)


func _validate_dialog_resources() -> void:
	for dialog_id_variant in _dialogs.keys():
		var dialog_id: String = String(dialog_id_variant)
		if not _is_chapter_dialog(dialog_id):
			continue
		var dialog: Resource = _dialogs[dialog_id]
		var owner: String = "dialog:%s" % dialog_id
		_ensure_graph_node(owner)
		var node_ids: Dictionary = {}
		for node in dialog.nodes:
			var node_id: String = String(node.node_id)
			if node_id == "":
				_failures.append("%s contains empty node_id" % owner)
			elif node_ids.has(node_id):
				_failures.append("%s contains duplicate node_id: %s" % [owner, node_id])
			node_ids[node_id] = true
		if not node_ids.has(String(dialog.entry_node_id)):
			_failures.append("%s entry node does not exist: %s" % [owner, dialog.entry_node_id])
		for node in dialog.nodes:
			_validate_dialog_node(dialog, node, node_ids, owner)


func _validate_dialog_node(_dialog: Resource, node: Resource, node_ids: Dictionary, owner: String) -> void:
	var context: String = "%s node:%s" % [owner, node.node_id]
	_validate_action(node.on_end, owner, context, node_ids)
	if String(node.accept_quest) != "":
		_validate_target("quest", String(node.accept_quest), context)
		_append_source(_quest_accept_sources, String(node.accept_quest), owner)
	if String(node.complete_quest) != "":
		_validate_target("quest", String(node.complete_quest), context)
		_append_source(_quest_complete_sources, String(node.complete_quest), owner)
	for item in node.give_items:
		var item_id: String = String(item.get("id", item.get("item_id", "")))
		_validate_target("item", item_id, context)
		_append_source(_item_sources, item_id, owner)
	for flag_def in node.set_flags:
		_record_flag_write(flag_def, owner, context)
	for evidence_id in node.add_evidence:
		_validate_target("evidence", String(evidence_id), context)
	for evidence_id in node.verify_evidence:
		_validate_target("evidence", String(evidence_id), context)
	for testimony_id in node.add_testimonies:
		_validate_target("testimony", String(testimony_id), context)
	for testimony_id in node.verify_testimonies:
		_validate_target("testimony", String(testimony_id), context)
	_validate_no_multiple_factions(node.set_flags, context)
	for choice in node.choices:
		var next_id: String = String(choice.get("next", ""))
		if next_id != "" and next_id != "end":
			if next_id.begins_with("next:"):
				next_id = next_id.trim_prefix("next:")
			if not node_ids.has(next_id):
				_failures.append("%s choice points to missing node: %s" % [context, next_id])
		var choice_action: String = String(choice.get("action", ""))
		if choice_action != "":
			_validate_action(choice_action, owner, "%s choice" % context, node_ids)
		var choice_flags: Array[Dictionary] = _choice_flags(choice)
		for flag_def in choice_flags:
			_record_flag_write(flag_def, owner, "%s choice" % context)
		_validate_no_multiple_factions(choice_flags, "%s choice" % context)
		_validate_choice_investigation_ids(choice, "%s choice" % context)


func _validate_choice_investigation_ids(choice: Dictionary, context: String) -> void:
	for evidence_id: Variant in choice.get("add_evidence", []):
		_validate_target("evidence", String(evidence_id), context)
	for evidence_id: Variant in choice.get("verify_evidence", []):
		_validate_target("evidence", String(evidence_id), context)
	for testimony_id: Variant in choice.get("add_testimonies", []):
		_validate_target("testimony", String(testimony_id), context)
	for testimony_id: Variant in choice.get("verify_testimonies", []):
		_validate_target("testimony", String(testimony_id), context)


func _validate_quest_resources() -> void:
	for chapter in MAIN_QUESTS.keys():
		for quest_id_variant in MAIN_QUESTS[chapter]:
			var quest_id: String = String(quest_id_variant)
			if not _quests.has(quest_id):
				_failures.append("chapter %d main quest missing: %s" % [chapter, quest_id])
				continue
			var quest: Resource = _quests[quest_id]
			if int(quest.kind) != 0:
				_failures.append("main quest has non-main kind: %s" % quest_id)
			if quest.completion_triggers.is_empty() and not _quest_complete_sources.has(quest_id):
				_failures.append("main quest has no completion path: %s" % quest_id)
			for trigger in quest.completion_triggers:
				_validate_trigger(quest_id, trigger)
			for reward in quest.reward_items:
				var item_id: String = String(reward.get("id", reward.get("item_id", "")))
				_validate_target("item", item_id, "quest:%s reward" % quest_id)


func _validate_trigger(quest_id: String, trigger: String) -> void:
	var parts: PackedStringArray = trigger.split(":", true, 1)
	if parts.size() != 2 or parts[1] == "":
		_failures.append("quest:%s has malformed trigger: %s" % [quest_id, trigger])
		return
	var event_name: String = parts[0]
	var target: String = parts[1]
	match event_name:
		"flag_set":
			if not _flag_sources.has(target):
				_failures.append("quest:%s trigger has no flag producer: %s" % [quest_id, trigger])
		"enemy_defeated", "defeated":
			_validate_target("battle", target, "quest:%s trigger" % quest_id)
			if not _battle_sources.has(target):
				_failures.append("quest:%s enemy is never referenced by a chapter action: %s" % [quest_id, target])
		"scene_entered":
			_validate_target("scene", target, "quest:%s trigger" % quest_id)
		"item_picked_up":
			_validate_target("item", target, "quest:%s trigger" % quest_id)
			if not _item_sources.has(target):
				_warnings.append("quest:%s item trigger has no static give source: %s" % [quest_id, target])
		"npc_talked_to":
			if not _npc_sources.has(target):
				_failures.append("quest:%s npc trigger has no NPC producer: %s" % [quest_id, target])
		"evidence_acquired", "evidence_verified":
			_validate_target("evidence", target, "quest:%s trigger" % quest_id)
		"testimony_heard", "testimony_verified":
			_validate_target("testimony", target, "quest:%s trigger" % quest_id)
		_:
			_failures.append("quest:%s uses unsupported trigger: %s" % [quest_id, trigger])


func _validate_chapter_chain() -> void:
	for chapter_variant in CHAPTER_ENTRIES.keys():
		var chapter: int = int(chapter_variant)
		var entry_id: String = String(CHAPTER_ENTRIES[chapter])
		if not _scenes.has(entry_id):
			_failures.append("chapter %d entry scene missing: %s" % [chapter, entry_id])
			continue
		var reachable: Dictionary = _reachable_from("scene:%s" % entry_id)
		var terminal: String = "chapter_end:%d" % chapter
		if not reachable.has(terminal):
			_failures.append("chapter %d entry cannot reach %s" % [chapter, terminal])
		for quest_id_variant in MAIN_QUESTS[chapter]:
			var quest_id: String = String(quest_id_variant)
			if not _has_reachable_source(_quest_accept_sources, quest_id, reachable):
				_failures.append("chapter %d main quest cannot be accepted from entry: %s" % [chapter, quest_id])
			var has_explicit_complete: bool = _has_reachable_source(_quest_complete_sources, quest_id, reachable)
			var has_reachable_trigger: bool = _quest_has_reachable_trigger(quest_id, reachable)
			if not has_explicit_complete and not has_reachable_trigger:
				_failures.append("chapter %d main quest cannot complete from reachable content: %s" % [chapter, quest_id])


func _quest_has_reachable_trigger(quest_id: String, reachable: Dictionary) -> bool:
	if not _quests.has(quest_id):
		return false
	var quest: Resource = _quests[quest_id]
	for trigger in quest.completion_triggers:
		var parts: PackedStringArray = trigger.split(":", true, 1)
		if parts.size() != 2:
			continue
		var sources: Dictionary = {}
		match parts[0]:
			"flag_set": sources = _flag_sources
			"enemy_defeated", "defeated": sources = _battle_sources
			"item_picked_up": sources = _item_sources
			"npc_talked_to": sources = _npc_sources
			"scene_entered":
				if reachable.has("scene:%s" % parts[1]):
					return true
			"evidence_acquired", "evidence_verified", "testimony_heard", "testimony_verified":
				# 调查状态可在此前对话或自由探索中取得；静态图只校验定义存在。
				return true
		if _has_reachable_source(sources, parts[1], reachable):
			return true
	return false


func _validate_faction_exclusivity() -> void:
	for faction in FACTIONS:
		if not _flag_sources.has("joined_%s" % faction):
			_failures.append("faction has no joined flag producer: %s" % faction)
	var source_path: String = "res://scripts/autoload/game_state.gd"
	var source_file: FileAccess = FileAccess.open(source_path, FileAccess.READ)
	if source_file == null:
		_failures.append("cannot read GameState faction contract: %s" % source_path)
		return
	var source: String = source_file.get_as_text()
	if not source.contains("player_faction"):
		_failures.append("GameState is missing persistent player_faction state")
	var faction_method: String = ""
	for candidate in ["select_faction", "choose_faction", "set_player_faction"]:
		if source.contains("func %s(" % candidate):
			faction_method = candidate
			break
	if faction_method == "":
		_failures.append("missing exclusive faction selection API on GameState")
		return
	var method_start: int = source.find("func %s(" % faction_method)
	var method_end: int = source.find("\nfunc ", method_start + 1)
	if method_end < 0:
		method_end = source.length()
	var method_body: String = source.substr(method_start, method_end - method_start)
	var checks_existing: bool = method_body.contains("player_faction !=") or method_body.contains("player_faction == &\"\"") or method_body.contains("player_faction.is_empty()")
	if not checks_existing or not method_body.contains("return false"):
		_failures.append("GameState.%s does not reject a second faction selection" % faction_method)


func _validate_action(action: String, owner: String, context: String, local_nodes: Dictionary = {}) -> void:
	if action == "":
		return
	var parts: PackedStringArray = action.split(":", true)
	var command: String = parts[0]
	if not VALID_ACTIONS.has(command):
		_failures.append("%s uses unknown action: %s" % [context, action])
		return
	if command in ["end", "world_map", "world_map_return"] or command.begins_with("open_") or command == "stop_bgm":
		return
	var target: String = parts[1] if parts.size() > 1 else ""
	match command:
		"next":
			if target == "" or not local_nodes.has(target):
				_failures.append("%s points to missing local node: %s" % [context, target])
		"dialog", "scene", "battle", "battle_solo", "shop":
			var target_kind := "battle" if command == "battle_solo" else command
			_validate_target(target_kind, target, context)
			_add_edge(owner, "%s:%s" % [target_kind, target])
			if target_kind == "battle":
				_append_source(_battle_sources, target, owner)
		"battle_then", "battle_solo_then":
			_validate_target("battle", target, context)
			_append_source(_battle_sources, target, owner)
			if parts.size() > 2 and parts[2] != "":
				_validate_target("dialog", parts[2], context)
				_add_edge(owner, "dialog:%s" % parts[2])
		"battle_group":
			var enemy_ids: PackedStringArray = target.split(",", false)
			if enemy_ids.is_empty() or enemy_ids.size() > 3:
				_failures.append("%s uses invalid battle group size: %s" % [context, action])
			for enemy_id in enemy_ids:
				var clean_id: String = enemy_id.strip_edges()
				_validate_target("battle", clean_id, context)
				_append_source(_battle_sources, clean_id, owner)
		"battle_group_then":
			var enemy_ids: PackedStringArray = target.split(",", false)
			if enemy_ids.is_empty() or enemy_ids.size() > 3 or parts.size() < 3:
				_failures.append("%s uses invalid battle_group_then action: %s" % [context, action])
			for enemy_id in enemy_ids:
				var clean_id: String = enemy_id.strip_edges()
				_validate_target("battle", clean_id, context)
				_append_source(_battle_sources, clean_id, owner)
			if parts.size() > 2 and parts[2] != "":
				_validate_target("dialog", parts[2], context)
				_add_edge(owner, "dialog:%s" % parts[2])
		"spar":
			if parts.size() < 6:
				_failures.append("%s has incomplete spar action: %s" % [context, action])
			else:
				_validate_target("battle", parts[2], context)
				_append_source(_battle_sources, parts[2], owner)
				if not parts[4].is_valid_int() or not parts[5].is_valid_int() or int(parts[4]) <= int(parts[5]):
					_failures.append("%s spar rewards must be integer win > loss: %s" % [context, action])
		"give_item":
			_validate_target("item", target, context)
			_append_source(_item_sources, target, owner)
		"read_item", "discover_readable":
			_validate_target("item", target, context)
			_append_source(_item_sources, target, owner)
		"accept_quest":
			_validate_target("quest", target, context)
			_append_source(_quest_accept_sources, target, owner)
		"complete_quest":
			_validate_target("quest", target, context)
			_append_source(_quest_complete_sources, target, owner)
		"set_flag":
			if target == "":
				_failures.append("%s has empty flag action" % context)
			else:
				_append_source(_flag_sources, target, owner)
		"add_evidence", "verify_evidence":
			_validate_target("evidence", target, context)
		"add_testimony", "verify_testimony":
			_validate_target("testimony", target, context)
		"join_faction":
			if target not in FACTIONS:
				_failures.append("%s selects unknown faction: %s" % [context, target])
			else:
				_append_source(_flag_sources, "joined_%s" % target, owner)
		"chapter_end":
			if target == "" or not target.is_valid_int():
				_failures.append("%s has invalid chapter_end action: %s" % [context, action])
			else:
				_add_edge(owner, "chapter_end:%s" % target)
		"field_cutscene":
			if target == "":
				_failures.append("%s has empty field cutscene target" % context)
			elif target == "zhao_wounded_escape":
				# This runtime cutscene always hands control to the post-escape
				# dialog and then returns to the same field, where the visible
				# orders object advances the chapter. Model both reviewed edges.
				_validate_target("dialog", "ch1_s3_ruin_after_escape", context)
				_add_edge(owner, "dialog:ch1_s3_ruin_after_escape")
				_validate_target("dialog", "ch1_s3_ruin_orders", context)
				_add_edge(owner, "dialog:ch1_s3_ruin_orders")
		"play_bgm", "play_sfx":
			if target == "" or not ResourceLoader.exists(target):
				_failures.append("%s references missing audio: %s" % [context, target])


func _validate_target(kind: String, target: String, context: String) -> void:
	if target == "":
		_failures.append("%s has empty %s target" % [context, kind])
		return
	var exists: bool = false
	match kind:
		"dialog": exists = ResourceLoader.exists("res://data/dialogs/%s.tres" % target)
		"scene": exists = ResourceLoader.exists("res://data/scenes/%s.tres" % target)
		"battle": exists = ResourceLoader.exists("res://data/enemies/%s.tres" % target)
		"quest": exists = ResourceLoader.exists("res://data/quests/%s.tres" % target)
		"shop": exists = ResourceLoader.exists("res://data/shops/%s.tres" % target)
		"item":
			exists = ResourceLoader.exists("res://data/items/%s.tres" % target) or ResourceLoader.exists("res://data/equipment/%s.tres" % target)
		"evidence": exists = ResourceLoader.exists("res://data/investigation/evidence/%s.tres" % target)
		"testimony": exists = ResourceLoader.exists("res://data/investigation/testimonies/%s.tres" % target)
	if not exists:
		_failures.append("%s references missing %s target: %s" % [context, kind, target])


func _record_flag_write(flag_def: Dictionary, owner: String, context: String) -> void:
	var key: String = String(flag_def.get("key", ""))
	if key == "":
		return
	var value: Variant = flag_def.get("value", true)
	if typeof(value) == TYPE_BOOL and not value:
		return
	_append_source(_flag_sources, key, owner)


func _choice_flags(choice: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var single: Variant = choice.get("set_flag", null)
	if single is Dictionary and not single.is_empty():
		result.append(single)
	var multiple: Variant = choice.get("set_flags", [])
	if multiple is Array:
		for flag_def in multiple:
			if flag_def is Dictionary:
				result.append(flag_def)
	return result


func _validate_no_multiple_factions(flags: Array[Dictionary], context: String) -> void:
	var selected: Array[String] = []
	for flag_def in flags:
		var key: String = String(flag_def.get("key", ""))
		if key.begins_with("joined_") and flag_def.get("value", true) != false:
			selected.append(key.trim_prefix("joined_"))
	if selected.size() > 1:
		_failures.append("%s selects multiple factions: %s" % [context, ", ".join(selected)])


func _ensure_graph_node(node: String) -> void:
	if not _graph.has(node):
		_graph[node] = [] as Array[String]


func _add_edge(source: String, target: String) -> void:
	_ensure_graph_node(source)
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


func _append_source(index: Dictionary, key: String, source: String) -> void:
	if key == "":
		return
	if not index.has(key):
		index[key] = [] as Array[String]
	var sources: Array = index[key]
	if not sources.has(source):
		sources.append(source)
	index[key] = sources


func _has_reachable_source(index: Dictionary, key: String, reachable: Dictionary) -> bool:
	if not index.has(key):
		return false
	for source in index[key]:
		if reachable.has(source):
			return true
	return false


func _is_chapter_resource(filename: String) -> bool:
	return _is_chapter_scene(filename.get_basename()) or _is_chapter_dialog(filename.get_basename()) or filename.begins_with("q_ch1_") or filename.begins_with("q_ch2_") or filename.begins_with("q_ch3_") or filename.begins_with("q_ch4_")


func _is_chapter_scene(scene_id: String) -> bool:
	return scene_id.begins_with("linxi_") or scene_id.begins_with("ch1_") or scene_id.begins_with("ch2_") or scene_id.begins_with("ch3_") or scene_id.begins_with("ch4_")


func _is_chapter_dialog(dialog_id: String) -> bool:
	return dialog_id.begins_with("ch1_") or dialog_id.begins_with("ch2_") or dialog_id.begins_with("ch3_") or dialog_id.begins_with("ch4_")
