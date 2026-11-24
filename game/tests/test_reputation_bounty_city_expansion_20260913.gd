extends SceneTree

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state := root.get_node("GameState")
	var inventory := root.get_node("Inventory")
	var bounties := root.get_node("BountyManager")
	state.reset_for_new_game()
	inventory.reset_for_new_game()
	bounties.reset_for_new_game()

	_check(state.reputation == 0, "new game reputation starts at zero")
	_check(state.REPUTATION_TITLES.size() == 10, "reputation has exactly ten title tiers")
	var previous_threshold := -1
	for tier: Dictionary in state.REPUTATION_TITLES:
		_check(int(tier.threshold) > previous_threshold, "reputation thresholds are strictly ascending")
		previous_threshold = int(tier.threshold)
	_check(state.get_reputation_title(0) == "无名之辈", "zero-reputation title")
	_check(state.get_reputation_title(600) == "天下闻名", "highest reputation title")

	for city_id: StringName in [&"luoyang", &"bianzhou", &"xiangzhou", &"jinling"]:
		var entries: Array[Dictionary] = bounties.get_board_entries(city_id)
		_check(entries.size() >= 2, "%s has several wanted notices" % city_id)
		for entry: Dictionary in entries:
			_check(not String(entry.level_text).is_empty(), "wanted notice displays recommended level")
			_check(String(entry.reward_text).contains("声望"), "wanted notice displays detailed rewards")
			var def := bounties.get_definition(StringName(entry.bounty_id)) as BountyDef
			_check(def != null and def.locations.size() >= 2, "wanted criminal has at least two relocation candidates")
			for enemy_id: StringName in def.enemy_ids:
				_check(ResourceLoader.exists("res://data/enemies/%s.tres" % String(enemy_id)), "wanted formation enemy exists: %s" % enemy_id)
			for reward: Dictionary in def.reward_items:
				var reward_id := String(reward.get("item_id", ""))
				_check(ResourceLoader.exists("res://data/items/%s.tres" % reward_id) or ResourceLoader.exists("res://data/equipment/%s.tres" % reward_id), "wanted reward exists: %s" % reward_id)
			for location: Dictionary in def.locations:
				var hideout_id := StringName(location.get("scene_id", &""))
				var hideout := load("res://data/scenes/%s.tres" % hideout_id) as SceneScript
				_check(hideout != null and hideout.is_walkable and hideout.map_layout != null, "hideout is a walkable scene: %s" % hideout_id)
				if hideout != null and hideout.map_layout != null:
					_check(_inside_layout(hideout.map_layout, location.get("pos", Vector2.ZERO)), "wanted spawn stands on walkable ground: %s" % location.get("label", hideout_id))

	var accepted: Dictionary = bounties.accept_bounty(&"bianzhou_flying_rope")
	_check(bool(accepted.get("ok", false)), "available bounty can be accepted")
	var save_before: Dictionary = bounties.to_dict()
	var first_state: Dictionary = (save_before.states as Dictionary).bianzhou_flying_rope
	var first_def := bounties.get_definition(&"bianzhou_flying_rope") as BountyDef
	var first_location: Dictionary = first_def.locations[int(first_state.location_index)]
	var target_npcs: Array[Dictionary] = bounties.get_scene_npcs(StringName(first_location.scene_id))
	_check(target_npcs.size() == 1, "accepted criminal appears only at active hideout")
	_check(String(target_npcs[0].interaction_action).begins_with("bounty_battle:"), "target interaction starts bounty battle")
	var escaped: Dictionary = bounties.record_defeat(&"bianzhou_flying_rope")
	var second_state: Dictionary = ((bounties.to_dict().states as Dictionary).bianzhou_flying_rope as Dictionary)
	_check(int(second_state.location_index) != int(first_state.location_index), "defeat moves criminal to a different hideout")
	_check(String(escaped.get("message", "")).contains("转移"), "defeat gives relocation feedback")
	var resolved: Dictionary = bounties.resolve_victory(&"bianzhou_flying_rope")
	_check(not resolved.is_empty(), "active bounty resolves on victory")
	_check(state.reputation == 10, "capture grants reputation")
	_check(state.training_points_total == 18, "capture grants training points")
	_check(bounties.get_scene_npcs(StringName(first_location.scene_id)).is_empty(), "captured criminal is removed from field")

	state.reset_for_new_game()
	inventory.reset_for_new_game()
	_check(not state.select_faction(&"wudang"), "sect application rejects insufficient reputation")
	state.add_reputation(10)
	inventory.add_item(&"iron_ore", 2)
	inventory.add_item(&"timber_bundle", 2)
	_check(state.select_faction(&"wudang"), "sect application accepts reputation and construction materials")
	_check(not bool(state.flags.get("joined_faction", false)), "application does not count as formal initiation")
	_check(&"wudang_xuanwu_ge" not in state.player.skills, "sect skill is not granted before initiation trial")
	_check(inventory.count_of(&"iron_ore") == 0 and inventory.count_of(&"timber_bundle") == 0, "construction materials are delivered on application")
	state.set_flag(&"joined_faction", true)
	_check(&"wudang_xuanwu_ge" in state.player.skills, "sect foundation skill is granted after trial completion")

	var backgrounds: Dictionary = {}
	for scene_id: StringName in [&"openworld_bianzhou_city", &"openworld_xiangzhou_city", &"openworld_jinling_city"]:
		var scene_def := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		_check(scene_def != null and scene_def.is_settlement, "%s loads as a safe city" % scene_id)
		_check(scene_def != null and scene_def.map_layout != null, "%s owns walkable layout" % scene_id)
		if scene_def != null:
			backgrounds[scene_def.background_path] = true
	_check(backgrounds.size() == 3, "each new city uses independent artwork")

	for scene_id: StringName in [&"openworld_bianzhou_old_post", &"openworld_xiangzhou_mine_valley", &"openworld_jinling_reed_marsh"]:
		var grind := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		_check(grind != null and not grind.is_settlement, "%s is a combat zone" % scene_id)
		var sizes: Dictionary = {}
		for group: Dictionary in grind.encounter_groups:
			sizes[(group.enemy_ids as Array).size()] = true
		_check(sizes.has(1) and sizes.has(2) and sizes.has(3), "%s supports 1/2/3-enemy encounters" % scene_id)

	for scene_id: StringName in [
		&"openworld_bianzhou_city",
		&"openworld_xiangzhou_city",
		&"openworld_jinling_city",
		&"openworld_bianzhou_old_post",
		&"openworld_xiangzhou_mine_valley",
		&"openworld_jinling_reed_marsh",
	]:
		var scene_def := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		var layout := scene_def.map_layout as WalkableMapLayout
		for probe: Dictionary in layout.walkable_probes:
			_check(_inside_layout(layout, probe.get("pos", Vector2.ZERO)), "%s walkable probe %s" % [scene_id, probe.get("id", "")])
		for probe: Dictionary in layout.blocked_probes:
			_check(not _inside_layout(layout, probe.get("pos", Vector2.ZERO)), "%s blocked probe %s" % [scene_id, probe.get("id", "")])
		for portal: Dictionary in layout.portals:
			_check(_inside_layout(layout, portal.get("pos", Vector2.ZERO)), "%s portal %s is reachable" % [scene_id, portal.get("id", "")])

	var world := load("res://data/maps/world_map_jianghu_layout_v11.tres") as WalkableMapLayout
	var portal_ids: Dictionary = {}
	for portal: Dictionary in world.portals:
		portal_ids[String(portal.id)] = true
	_check(portal_ids.has("bianzhou") and portal_ids.has("xiangzhou") and portal_ids.has("jinling"), "world map exposes all three cities")

	print("[ReputationBountyCityExpansion] checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)


func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[ReputationBountyCityExpansion] " + description)


func _inside_layout(layout: WalkableMapLayout, point: Vector2) -> bool:
	if not layout.walkable_mask_path.is_empty():
		var image := Image.load_from_file(ProjectSettings.globalize_path(layout.walkable_mask_path))
		if image != null and not image.is_empty():
			var x := clampi(roundi(point.x * float(image.get_width() - 1)), 0, image.get_width() - 1)
			var y := clampi(roundi(point.y * float(image.get_height() - 1)), 0, image.get_height() - 1)
			return image.get_pixel(x, y).r > 0.5
	var inside := false
	for region: PackedVector2Array in layout.walkable_regions:
		if Geometry2D.is_point_in_polygon(point, region):
			inside = true
			break
	if not inside:
		return false
	for blocker: Dictionary in layout.blockers:
		var region: PackedVector2Array = blocker.get("region", PackedVector2Array())
		if region.size() >= 3 and Geometry2D.is_point_in_polygon(point, region):
			return false
		var center: Vector2 = blocker.get("pos", Vector2(-10, -10))
		var size: Vector2 = blocker.get("size", Vector2.ZERO)
		if size.x > 0.0 and size.y > 0.0 and Rect2(center - size * 0.5, size).has_point(point):
			return false
	return true
