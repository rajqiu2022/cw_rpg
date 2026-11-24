extends "res://build/quest_map_audit_20261108/huilan_live.gd"

const WEST := &"openworld_east_sea_port"
const BAILU := &"openworld_bailu_ferry"
const PORT := &"east_tidegate_port"
const REGION := &"east_mainland_overworld"
const TOWNS := [&"east_cangpu_city", &"east_salt_bay_village", &"east_tea_ridge_village"]


func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router = root.get_node("SceneRouter")
	state = root.get_node("GameState")
	quests = root.get_node("QuestManager")
	dialogue = root.get_node("DialogPlayer")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	router.reset_for_new_game()
	var field := await enter(BAILU)
	if field == null:
		finish()
		return
	if not await boat(field, "openworld_bailu_ferry_boatman", "openworld_bailu_ferry_boat", WEST, 0):
		finish()
		return
	if not await boat(current_scene, "openworld_east_sea_port_boatman", "openworld_east_sea_port_boat", PORT, 2):
		finish()
		return
	field = current_scene
	expect(field.get("_visual_layer").has_node("EastTerrain"), "Tidegate has rendered terrain")
	await picture("01_tidegate.png")
	check_minimap(field, PORT)
	if not await cross(field, "east_road_return", REGION):
		finish()
		return
	field = current_scene
	expect(field.get("_visual_layer").has_node("EastTerrain"), "overworld terrain rendered")
	expect(not field.call("_is_inside_walkable_screen", Vector2(950, 4050)), "outer sea rejects travel")
	expect(field.call("_is_inside_walkable_screen", Vector2(4480, 3590)), "land road junction is walkable")
	for i in 4:
		expect(field.get("_visual_layer").has_node("TravelRoute_east_road_" + str(i)), "road displayed " + str(i))
	await picture("02_east_overworld.png")
	check_minimap(field, REGION)
	field.call("_open_world_map_panel")
	await process_frame
	await process_frame
	var panel := field.get("_world_map_panel") as Control
	if panel != null:
		var tab := panel.get_node_or_null("Frame/EastAtlasTab") as Button
		var chart := panel.get("map_rect").get_node_or_null("UnifiedTravelChart") as Control
		expect(tab != null and chart != null and chart.visible and not panel.get("map_texture").visible, "unified atlas opens on east region")
		await picture("03_east_atlas.png")
		if chart != null:
			var markers: Dictionary = chart.get("_marker_state")
			expect(markers.get(PORT, false) and markers.has(TOWNS[0]) and not markers[TOWNS[0]], "visited port and undiscovered city")
			expect(chart.get("_marker_point").is_finite(), "current position shown on unified atlas")
		if tab != null:
			tab.pressed.emit()
			expect(panel.get("map_texture").visible, "west atlas still available")
			tab.pressed.emit()
			expect(not panel.get("map_texture").visible, "switch back to east atlas")
		panel.call("close")
	else:
		expect(false, "regional atlas missing")
	for id in TOWNS:
		if not await cross(current_scene, str(id) + "_entry", id):
			finish()
			return
		await picture(str(id) + ".png")
		check_minimap(current_scene, id)
		if not await cross(current_scene, "east_road_return", REGION):
			finish()
			return
	if await cross(current_scene, "east_tidegate_port_entry", PORT):
		if await boat(current_scene, "tidegate_captain", "east_tidegate_sail", WEST, 0):
			if await boat(current_scene, "openworld_east_sea_port_boatman", "openworld_east_sea_port_boat", BAILU, 0):
				await check_overview_from_west(current_scene)
	finish()


func check_minimap(field: Node, id: StringName) -> void:
	var hud: Control = field.get("_primary_hud")
	var mini := hud.get_node_or_null("EastMainlandMinimap") as Control
	expect(mini != null and mini.visible, "minimap visible " + str(id))
	if mini != null:
		expect(root.get_visible_rect().encloses(mini.get_global_rect()), "minimap stays in viewport " + str(id))
		expect(mini.get("_marker_point").is_finite() and mini.get("_portrait").visible, "minimap avatar " + str(id))
	if id != REGION:
		expect(state.get_flag(StringName("east_chart_visited_" + str(id))) == true, "visit recorded " + str(id))


func check_overview_from_west(field: Node) -> void:
	field.call("_open_world_map_panel")
	await process_frame
	await process_frame
	var panel := field.get("_world_map_panel") as Control
	var chart := panel.get("map_rect").get_node_or_null("UnifiedTravelChart") as Control
	expect(chart != null and chart.visible, "unified overview also opens from Bailu")
	await picture("04_atlas_from_bailu.png")
	if chart != null:
		var markers: Dictionary = chart.get("_marker_state")
		for id in TOWNS:
			expect(markers.get(id, false), "visited east town visible from west " + str(id))
		expect(chart.get("_marker_point").is_finite(), "Bailu current position shown")
	panel.call("close")


func boat(field: Node, npc: String, id: String, target: StringName, option: int) -> bool:
	field.call("_on_npc_primary_dialog", npc, id)
	for i in 5:
		await process_frame
		if dialogue.is_playing() and dialogue.get("_current_node").has_choices():
			break
		await press_space()
	if not expect(dialogue.is_playing() and dialogue.get("_current_node").has_choices(), "boatman offers choices " + id):
		return false
	var key := InputEventKey.new()
	key.keycode = KEY_1 + option
	key.pressed = true
	root.push_input(key, true)
	return expect(await arrival(target), "boat arrives " + str(target))


func cross(field: Node, key: String, target: StringName) -> bool:
	var map := field.get("_current_scene") as SceneScript
	for entry: Dictionary in map.map_layout.portals:
		if entry.id != key:
			continue
		var player := field.get("_player") as Node2D
		player.position = Vector2(entry.pos) * Vector2(field.get("_world_size"))
		var ready := await wait_for(func():
			for zone in field.get("_exit_nodes"):
				if zone.target_scene_id == String(target) and zone.overlaps_body(player):
					return player.can_move
			return false
		, 2000)
		if not expect(ready, "door reachable " + key):
			print("door diagnostic: ", field.get("_world_size"), " player ", player.position, " target ", target)
			return false
		await press_space()
		var arrived := await arrival(target)
		if not arrived:
			print("arrival diagnostic: current=", router.get_current_field_id(), " requested=", target)
		return expect(arrived, "Space " + key)
	return expect(false, "portal missing " + key)


func arrival(target: StringName) -> bool:
	return await wait_for(func():
		var field := current_scene
		return field != null and router.get_current_field_id() == target and field.has_method("get_field_loading_state") and field.get_field_loading_state().get("complete", false) and not root.get_node("LoadingManager").get("_transition_active")
	, 9000)


func picture(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png("user://" + filename) == OK, "screenshot " + filename)
