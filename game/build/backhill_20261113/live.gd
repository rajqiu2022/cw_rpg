extends "res://build/victory_quest_20261108/story_live.gd"

const VILLAGE := &"ch1_s2_qingfeng"
const FOREST := &"ch1_s3_zhuwei_forest"
const CAVE_CAMP := &"ch1_s4_zhuwei_beast_cave"
const CAVE_MINE := &"ch1_s4_cave_mine_gallery"
const WATER := &"ch1_s4_cave_waterway"
const DEN := &"ch1_s4_cave_deep_den"
const HUNT := &"adventure_zhuwei_hunting_ground"

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
	scan_field_targets()
	for flag in [&"entered_zhuwei_forest", &"entered_zhuwei_village", &"zhuwei_village_inquiry_done", &"defeated_linxi_wild_beast", &"defeated_zhuwei_cave_wolf"]:
		state.set_flag(flag, true)
	skill_preview()
	var field := await enter(FOREST)
	if field == null:
		finish()
		return
	await settle(field)
	expect(field.find_child("RiversideNaturalGround01", true, false)!=null, "formal forest uses soft-edge ground")
	await screenshot("backhill_forest")
	var previous := FOREST
	for target: StringName in [VILLAGE, FOREST, CAVE_CAMP, CAVE_MINE, DEN, WATER, CAVE_CAMP, WATER, DEN, CAVE_MINE, CAVE_CAMP, FOREST]:
		field = await cross(field, previous, target)
		if field == null:
			break
		previous = target
		if target == CAVE_CAMP and source_art_present(field):
			await screenshot("backhill_cave_camp")
	if field != null:
		await check_hunt(field)
	finish()

func skill_preview() -> void:
	var panel: Node = load("res://scripts/ui/skill_panel.gd").new()
	var result: String = panel._preview_stat_lines(PackedStringArray(["生命 +24", "防御 +2"]), PackedStringArray(["生命 +32", "筋骨 +1", "防御 +2"]), "", "6093b9")
	expect(result.contains("生命 +24  [color=#6093b9]→ +32[/color]"), "next passive uses its own color")
	expect(result.contains("筋骨  [color=#6093b9]→ +1[/color]") and result.ends_with("筋骨  [color=#6093b9]→ +1[/color]"), "new stat matched by name")
	expect("防御 +2\n" in result, "unchanged stat has no preview")
	expect(panel._preview_stat_lines(PackedStringArray(["生命 +24"]), PackedStringArray(), "", "") == "生命 +24", "max level shows no preview")
	panel.free()
	var window: Node = load("res://scenes/ui/skill_panel.tscn").instantiate()
	root.add_child(window)
	var mind: Skill = load("res://data/skills/linxi_inner_breath.tres")
	var technique: Skill = load("res://data/skills/linxi_basic_sword_one.tres")
	window.set("_skills", [mind, technique] as Array[Skill])
	window.set("_runtime_selected_id", mind.skill_id)
	window._runtime_show_selected()
	var detail: RichTextLabel = window.get("_runtime_detail")
	expect("下一级 Lv.2" in detail.text and "→ +24" in detail.text and "→ +8%" in detail.text, "real mind panel shows growth")
	window.set("_runtime_selected_id", technique.skill_id)
	window._runtime_show_selected()
	expect("下一级 Lv.2" in detail.text and "预计伤害" in detail.text and "（系数 " in detail.text, "real technique panel shows damage preview")
	window.free()

func scan_field_targets() -> void:
	var paths := DirAccess.get_files_at("res://data/scenes")
	var pattern := RegEx.create_from_string("\"(?:target_scene|target_scene_id)\"\\s*:\\s*&?\"([^\"]+)\"")
	var fields := 0
	var portals := 0
	var missing := PackedStringArray()
	for file in paths:
		if not file.ends_with(".tres"): continue
		var id := StringName(file.get_basename())
		var path: String = router.field_scene_resource_path(id)
		if not ResourceLoader.exists(path): continue
		var raw := FileAccess.get_file_as_string(path)
		if not raw.contains('script_class="SceneScript"'): continue
		fields += 1
		var layout := RegEx.create_from_string('path="(res://data/maps/[^"]+\\.tres)"').search(raw)
		if layout != null:
			raw += "\n" + FileAccess.get_file_as_string(layout.get_string(1))
		for hit in pattern.search_all(raw):
			portals += 1
			var target := StringName(hit.get_string(1))
			var target_path: String = router.field_scene_resource_path(target)
			if not ResourceLoader.exists(target_path):
				missing.append("%s->%s" % [id,target])
	print("TARGET_SCAN flat_route_sources=", fields, " target_rows=", portals, " missing=", JSON.stringify(missing))

func cross(field: Node, source: StringName, target: StringName) -> Node:
	await settle(field)
	if not expect(is_instance_valid(field) and current_scene == field, "stable host "+String(source)): return null
	var zone := zone_to(field, target)
	if not expect(zone != null, "portal %s -> %s" % [source,target]): return null
	var actor: Player = field.get("_player")
	if source == FOREST and target == VILLAGE:
		if not expect(not zone.call("_can_enter"), "forest arrival outside return trigger"): return null
		Input.action_press("move_down")
		var walked := await wait_for(func(): return zone.call("_can_enter"), 1500)
		Input.action_release("move_down")
		if not expect(walked, "walking south from default spawn reaches actual return area"): return null
	else:
		var position := zone.global_position - Vector2(0, float(actor.call("_visual_foot_offset"))) if zone.has_method("_can_enter") else zone.global_position
		actor = await position_at(field, position)
	if not check_clear(actor, "source feet %s -> %s" % [source,target]): return null
	if zone.has_method("_can_enter"):
		if not expect(zone.call("_can_enter"), "actual feet activate %s -> %s" % [source,target]): return null
	else:
		if not expect(zone.get("_in_range"), "body enters %s -> %s" % [source,target]): return null
	await press_space()
	if not expect(await wait_for(func(): return router.get_current_field_id()==target and current_scene!=null and current_scene.has_method("get_field_loading_state") and current_scene.get_field_loading_state().get("complete",false) and not root.get_node("LoadingManager").get("_transition_active"), 20000), "Space travels %s -> %s" % [source,target]): return null
	check_clear(current_scene.get("_player"), "arrival %s from %s" % [target,source])
	print("LEG ", source, " -> ", target, " feet=", current_scene.call("_outskirts_source_player_foot"))
	return current_scene

func check_hunt(field: Node) -> void:
	await settle(field)
	var actor: Player = field.get("_player")
	var world: Node2D = field.get("world_container")
	var point: Vector2 = world.to_global(Vector2(.314,.423) * (field.get("_world_size") as Vector2))
	await position_at(field, point - Vector2(0, float(actor.call("_visual_foot_offset"))))
	var key := InputEventKey.new()
	key.keycode = KEY_G
	key.physical_keycode = KEY_G
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	var release := key.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	var previous := field.get_instance_id()
	if expect(await wait_for(func(): return router.get_current_field_id()==HUNT and current_scene!=null and current_scene.get_instance_id()!=previous and current_scene.has_method("get_field_loading_state") and current_scene.get_field_loading_state().get("complete",false) and not root.get_node("LoadingManager").get("_transition_active"), 18000), "G enters hunting stairs"):
		await cross(current_scene, HUNT, FOREST)

func source_art_present(field: Node) -> bool:
	return field.find_child("SceneObject_camp_hearth", true, false) != null

func screenshot(filename: String) -> void:
	if DisplayServer.get_name() == "headless" or FileAccess.file_exists("user://"+filename+".png"): return
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png("user://"+filename+".png") == OK, filename+" captured")
