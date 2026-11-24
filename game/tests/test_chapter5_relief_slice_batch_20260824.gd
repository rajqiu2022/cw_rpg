extends SceneTree

var failures := 0


func _initialize() -> void:
	var road := load("res://data/scenes/ch5_s1_relief_road.tres") as SceneScript
	var camp := load("res://data/scenes/ch5_s2_grain_convoy_camp.tres") as SceneScript
	var q1 := load("res://data/quests/q_ch5_main_01_relief_route.tres") as QuestDef
	var q2 := load("res://data/quests/q_ch5_main_02_grain_convoy.tres") as QuestDef
	var evidence := load("res://data/investigation/evidence/ev_ch5_false_banner_cloth.tres") as EvidenceDef
	_check(road != null and camp != null, "chapter five relief road and convoy camp scenes load")
	_check(q1 != null and q2 != null, "chapter five relief quests load")
	_check(evidence != null and evidence.chapter == 5, "false-banner cloth evidence is authored for chapter five")
	if road != null:
		_check(road.background_path.ends_with("bg_ch5_relief_road_gameplay_v1.png") and FileAccess.file_exists(road.background_path), "relief road uses a project-local gameplay background")
		_check(road.is_walkable and road.map_layout != null and not road.map_layout.walkable_regions.is_empty(), "relief road owns an explicit walkable layout")
		_check(_layout_probes_match(road.map_layout), "relief road walkable and blocked probes match the authored route")
		_check(road.on_enter_require_flag == &"chapter4_complete" and road.on_enter_once_flag == &"seen_ch5_relief_road_intro", "relief main story starts once without blocking early exploration")
		_check(_hotspot_action(road, "迎击劫粮客").contains("dialog:ch5_relief_road_battle"), "relief road starts with authored pre-battle dialogue")
		_check(_exit_targets(road, &"ch5_s2_grain_convoy_camp"), "relief road advances to convoy camp after victory")
	if camp != null:
		_check(camp.background_path.ends_with("bg_ch5_grain_convoy_camp_gameplay_v1.png") and FileAccess.file_exists(camp.background_path), "convoy camp uses a separate project-local gameplay background")
		_check(camp.is_walkable and camp.map_layout != null and not camp.map_layout.walkable_regions.is_empty(), "convoy camp owns an explicit walkable layout")
		_check(_layout_probes_match(camp.map_layout), "convoy camp walkable and blocked probes match the authored clearing")
		_check(_hotspot_action(camp, "守住赈粮车队").contains("dialog:ch5_grain_convoy_battle"), "convoy defense starts with authored pre-battle dialogue")
		_check(_hotspot_action(camp, "查验破损伪旗").contains("dialog:ch5_false_banner_evidence"), "visible torn banner becomes the post-battle evidence interaction")
		_check(not camp.npcs.is_empty(), "convoy camp includes a visible relief-route NPC")
	if q1 != null:
		_check(_quest_has_item(q1, &"battle_helmet"), "first relief quest grants one purple defensive progression item")
		_check("flag_set:ch5_relief_road_cleared" in q1.completion_triggers, "first relief quest closes on its dedicated victory flag")
	if q2 != null:
		_check("evidence_acquired:ev_ch5_false_banner_cloth" in q2.completion_triggers, "convoy quest completes only after inspecting the false banner")
		_check(_progress_record_has(q2, "ev_ch5_false_banner_cloth"), "convoy quest records the false-banner clue in the journal")
	var road_battle := load("res://data/dialogs/ch5_relief_road_battle.tres") as DialogScript
	var camp_battle := load("res://data/dialogs/ch5_grain_convoy_battle.tres") as DialogScript
	_check(_dialog_has_action(road_battle, "battle_group_then:ch5_relief_road_raider,ch5_relief_road_raider:ch5_relief_road_victory"), "road ambush uses the formal two-enemy anchor and victory dialogue")
	_check(_dialog_has_action(camp_battle, "battle_group_then:ch5_relief_road_raider,ch5_relief_road_raider,ch5_false_liuyun_striker:ch5_grain_convoy_victory"), "convoy defense uses the formal three-enemy anchor and victory dialogue")
	var world_layout := load("res://data/maps/world_map_jianghu_layout_v10.tres") as WalkableMapLayout
	var gufeng := _portal_by_id(world_layout, "gufeng")
	_check(String(gufeng.get("target_scene", "")) == "ch5_s1_relief_road", "world-map Ancient Moon Peak portal enters the relief road")
	_check(String(gufeng.get("require_flag", "")) == "", "Ancient Moon Peak stays physically open and uses encounter difficulty as its soft gate")
	print("[Chapter5ReliefSlice20260824] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _hotspot_action(scene: SceneScript, label: String) -> String:
	for hotspot: Dictionary in scene.hotspots:
		if String(hotspot.get("label", "")) == label:
			return String(hotspot.get("action", ""))
	return ""


func _exit_targets(scene: SceneScript, target: StringName) -> bool:
	for exit_data: Dictionary in scene.exits:
		if StringName(String(exit_data.get("target_scene", ""))) == target:
			return true
	return false


func _quest_has_item(quest: QuestDef, item_id: StringName) -> bool:
	for entry: Dictionary in quest.reward_items:
		if StringName(String(entry.get("item_id", entry.get("id", "")))) == item_id:
			return true
	return false


func _progress_record_has(quest: QuestDef, token: String) -> bool:
	for record: Dictionary in quest.progress_records:
		if String(record.get("trigger", "")).contains(token):
			return true
	return false


func _dialog_has_action(dialog: DialogScript, action: String) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if node.on_end == action:
			return true
	return false


func _portal_by_id(layout: WalkableMapLayout, id: String) -> Dictionary:
	if layout == null:
		return {}
	for portal: Dictionary in layout.portals:
		if String(portal.get("id", "")) == id:
			return portal
	return {}


func _layout_probes_match(layout: WalkableMapLayout) -> bool:
	if layout == null:
		return false
	for probe: Dictionary in layout.walkable_probes:
		var point := probe.get("pos", Vector2(-1.0, -1.0)) as Vector2
		if not layout.walkable_regions.any(func(region: PackedVector2Array): return Geometry2D.is_point_in_polygon(point, region)):
			print("[PROBE] expected walkable but blocked: %s @ %s" % [probe.get("id", ""), point])
			return false
	for probe: Dictionary in layout.blocked_probes:
		var point := probe.get("pos", Vector2(-1.0, -1.0)) as Vector2
		var inside_region := layout.walkable_regions.any(func(region: PackedVector2Array): return Geometry2D.is_point_in_polygon(point, region))
		var inside_blocker := layout.blockers.any(func(blocker: Dictionary):
			var center := blocker.get("pos", Vector2.ZERO) as Vector2
			var size := blocker.get("size", Vector2.ZERO) as Vector2
			return Rect2(center - size * 0.5, size).has_point(point)
		)
		if inside_region and not inside_blocker:
			print("[PROBE] expected blocked but walkable: %s @ %s" % [probe.get("id", ""), point])
			return false
	return true


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
