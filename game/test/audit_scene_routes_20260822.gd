extends SceneTree

const RETIRED_SCENES := {
	"ch1_s0_linxi_main_walkable": true,
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var edges: Dictionary = {}
	var physical_edges: Dictionary = {}
	var dir := DirAccess.open("res://data/scenes")
	for file_name: String in dir.get_files() if dir != null else []:
		if not file_name.ends_with(".tres"):
			continue
		var scene := load("res://data/scenes/%s" % file_name) as SceneScript
		if scene == null:
			continue
		if RETIRED_SCENES.has(String(scene.scene_id)):
			continue
		var targets: Dictionary = {}
		var physical_targets: Dictionary = {}
		var dialog_ids: Dictionary = {}
		if scene.on_enter_dialog != null:
			dialog_ids[String(scene.on_enter_dialog.dialog_id)] = true
		if scene.map_layout != null:
			for portal: Dictionary in scene.map_layout.portals:
				var target := String(portal.get("target_scene", ""))
				if not target.is_empty():
					targets[target] = true
					physical_targets[target] = true
				_collect_action(String(portal.get("action", "")), targets, dialog_ids, physical_targets, true)
			for interaction: Dictionary in scene.map_layout.interactions:
				_collect_action(String(interaction.get("action", "")), targets, dialog_ids, physical_targets, true)
		for hotspot: Dictionary in scene.hotspots:
			_collect_action(String(hotspot.get("action", "")), targets, dialog_ids, physical_targets, true)
		for exit_def: Dictionary in scene.exits:
			var target := String(exit_def.get("target_scene", ""))
			if not target.is_empty():
				targets[target] = true
				physical_targets[target] = true
			_collect_action(String(exit_def.get("action", "")), targets, dialog_ids, physical_targets, true)
		for npc: Dictionary in scene.npcs:
			var dialog_id := String(npc.get("dialog_id", ""))
			if not dialog_id.is_empty(): dialog_ids[dialog_id] = true
			_collect_action(String(npc.get("interaction_action", "")), targets, dialog_ids)
			for variant: Dictionary in npc.get("dialog_variants", []):
				var variant_id := String(variant.get("dialog_id", ""))
				if not variant_id.is_empty(): dialog_ids[variant_id] = true
		var visited_dialogs: Dictionary = {}
		for dialog_id: String in dialog_ids.keys():
			_collect_dialog_targets(dialog_id, targets, visited_dialogs)
		edges[String(scene.scene_id)] = targets
		physical_edges[String(scene.scene_id)] = physical_targets
	var missing: Array[String] = []
	var deferred: Array[String] = []
	for source: String in physical_edges:
		for target: String in physical_edges[source]:
			if target == source or not edges.has(target):
				continue
			if not (edges[target] as Dictionary).has(source):
				var edge := "%s -> %s" % [source, target]
				if _is_trial_scope(source):
					missing.append(edge)
				else:
					deferred.append(edge)
	missing.sort()
	deferred.sort()
	print("[SceneRouteAudit20260822] trial_missing_reverse=%d later_chapter_warnings=%d" % [missing.size(), deferred.size()])
	for edge: String in missing:
		print(edge)
	for edge: String in deferred:
		print("WARN later chapter: %s" % edge)
	quit(1 if not missing.is_empty() else 0)


func _is_trial_scope(scene_id: String) -> bool:
	return scene_id.begins_with("ch1_") or scene_id.begins_with("ch2_") or scene_id.begins_with("ch3_") \
		or scene_id.begins_with("linxi_") or scene_id == "world_map_jianghu" \
		or scene_id in ["interior_inn_hall", "interior_martial_hall", "interior_bandit_cave"]


func _collect_dialog_targets(dialog_id: String, targets: Dictionary, visited: Dictionary) -> void:
	if dialog_id.is_empty() or visited.has(dialog_id):
		return
	visited[dialog_id] = true
	var path := "res://data/dialogs/%s.tres" % dialog_id
	if not ResourceLoader.exists(path):
		return
	var dialog := load(path) as DialogScript
	if dialog == null:
		return
	var nested_dialogs: Dictionary = {}
	for node: DialogNode in dialog.nodes:
		_collect_action(node.on_end, targets, nested_dialogs)
		for choice: Dictionary in node.choices:
			_collect_action(String(choice.get("action", "")), targets, nested_dialogs)
	for nested_id: String in nested_dialogs.keys():
		_collect_dialog_targets(nested_id, targets, visited)


func _collect_action(action: String, targets: Dictionary, dialog_ids: Dictionary, physical_targets: Dictionary = {}, mark_physical: bool = false) -> void:
	if action.is_empty():
		return
	if action == "world_map":
		targets["world_map_jianghu"] = true
		if mark_physical: physical_targets["world_map_jianghu"] = true
		return
	var parts := action.split(":", true)
	match parts[0]:
		"scene":
			if parts.size() > 1 and not parts[1].is_empty():
				targets[parts[1]] = true
				if mark_physical: physical_targets[parts[1]] = true
		"dialog":
			if parts.size() > 1 and not parts[1].is_empty(): dialog_ids[parts[1]] = true
		"battle_then", "battle_group_then":
			if parts.size() > 2 and not parts[2].is_empty(): dialog_ids[parts[2]] = true
