extends SceneTree

var failures := 0


func _initialize() -> void:
	await process_frame
	await _check_reading_panel()
	_check_inventory_contract()
	_check_navigation_contract()
	_check_status_contract()
	print("[ReadableNavigationStatusBatch] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check_reading_panel() -> void:
	var panel := preload("res://scenes/ui/reading_panel.tscn").instantiate() as ReadingPanel
	root.add_child(panel)
	await process_frame
	var item := load("res://data/items/qingming_sword_record.tres") as Item
	_check(panel.open_item(item), "formal reader opens Qingming fragment")
	var art := panel.get_node_or_null("ReadablePanelArt") as TextureRect
	_check(art != null and art.texture != null, "reader uses generated formal raster panel")
	_check(panel.get_node_or_null("ReadablePanelArt/CloseReader") is Button, "reader uses formal reusable close control")
	panel.queue_free()


func _check_inventory_contract() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/inventory_panel.gd")
	_check(source.contains("_compact_slot_name"), "readable slot names use compact catalogue form")
	_check(source.contains("if item.is_readable():\n\t\tlines.append"), "readable detail title omits quality wording")


func _check_navigation_contract() -> void:
	var market := load("res://data/maps/ch2_s1_zhuwei_market_layout_v2.tres") as WalkableMapLayout
	var mine := load("res://data/maps/ch1_s4_cave_mine_gallery_layout_v1.tres") as WalkableMapLayout
	var village := load("res://data/maps/ch1_s2_qingfeng_layout_v2.tres") as WalkableMapLayout
	_check(market != null and not market.walkable_mask_path.is_empty(), "morning market migrated to pixel navigation mask")
	_check(mine != null and mine.walkable_probes.size() >= 7, "mine lower corridor and room have reviewed probes")
	var target := Vector2.ZERO
	for portal in village.portals:
		if String(portal.get("id", "")) == "return_to_mountain_road":
			target = portal.get("target_pos", Vector2.ZERO)
	_check(target.distance_to(Vector2(0.82, 0.22)) < 0.001, "Zhuwei lower-left exit returns to the matching mountain-road side")


func _check_status_contract() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/battle/battle_formation_view.gd")
	_check(source.contains("status_icons.position = Vector2(116, -22)"), "debuff badges sit lower at the right of the resource bars")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
