extends SceneTree

var checks := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error("[ReportedPolish] " + label)


func _run() -> void:
	_check_south_school_reach()
	_check_duan_field_sprite()
	_check_contact_depth()
	_check_victory_member_rows()
	_check_yanmen_route_and_manual()
	_check_music_variation()
	await process_frame
	await process_frame
	print("[ReportedPolish] checks=%d failed=%d" % [checks, failed])
	quit(1 if failed else 0)


func _check_south_school_reach() -> void:
	var layout := load("res://data/maps/linxi_village_scrollmap_layout_v1.tres") as WalkableMapLayout
	var found := false
	for portal: Dictionary in layout.portals:
		if portal.get("id", "") != "enter_south_scholar_house":
			continue
		found = true
		var size: Vector2 = portal.get("size", Vector2.ZERO)
		var pos: Vector2 = portal.get("pos", Vector2.ZERO)
		check(size.x >= 0.10 and size.y >= 0.09 and pos.y >= 0.38, "south school entrance is anchored on the visible threshold instead of inside the house")
		check(portal.get("target_scene", "") == "linxi_south_scholar_house", "extended school hit area retains the real destination")
	check(found, "south school entrance exists")


func _check_duan_field_sprite() -> void:
	var scene := load("res://data/scenes/openworld_bailu_ferry.tres") as SceneScript
	var path := ""
	for npc: Dictionary in scene.npcs:
		if npc.get("npc_id", "") == "duan_changfeng":
			path = String(npc.get("sprite_path", ""))
	check(path.ends_with("npc_duan_changfeng_idle_down_4f_v2_stable.png"), "Duan Changfeng uses his normalized dedicated Field strip")
	var texture := load(path) as Texture2D
	check(texture != null and texture.get_size() == Vector2(640, 160), "Duan Field art is a four-frame 160px strip, not a battle still")
	if texture != null:
		var image := texture.get_image()
		check(image.detect_alpha() != Image.ALPHA_NONE, "Duan Field strip has real transparency")


func _check_contact_depth() -> void:
	var actor_scene := load("res://scenes/battle_actor.tscn") as PackedScene
	var upper := actor_scene.instantiate() as BattleActor
	var lower := actor_scene.instantiate() as BattleActor
	root.add_child(upper)
	root.add_child(lower)
	upper.home_position = Vector2(600, 220)
	lower.home_position = Vector2(850, 430)
	upper.set_meta("formation_depth_z", 4)
	lower.set_meta("formation_depth_z", 8)
	upper.z_index = 4
	lower.z_index = 8
	upper.call("_adopt_contact_depth", lower)
	check(upper.z_index == 7 and upper.z_index < lower.z_index, "upper-row attacker stays behind a lower-row target at contact")
	upper.call("_restore_formation_depth")
	check(upper.z_index == 4, "attacker restores authored formation depth after recovery")
	lower.call("_adopt_contact_depth", upper)
	check(lower.z_index == 5 and lower.z_index > upper.z_index, "lower-row attacker remains in front when crossing upward")
	upper.queue_free()
	lower.queue_free()


func _check_victory_member_rows() -> void:
	var battle_logic: Node = load("res://scripts/battle/battle_controller.gd").new()
	var hero := CharacterStats.new()
	hero.character_id = &"player"
	hero.display_name = "冷孤云"
	hero.level = 1
	hero.exp = 75
	var ally := CharacterStats.new()
	ally.character_id = &"shen_qinghe"
	ally.display_name = "沈青禾"
	ally.level = 2
	ally.exp = 0
	var rows: Array[Dictionary] = battle_logic.call("_grant_battle_exp", [hero, ally], 10)
	check(rows.size() == 2 and int(rows[0].exp_gained) == 10 and int(rows[1].exp_gained) == 10, "victory records EXP for every participating member")
	check(int(rows[0].level_before) == 1 and int(rows[0].level_after) == 2, "victory record captures level-up transition")
	var result_view: Node = load("res://scripts/ui/result_victory.gd").new()
	var text: String = result_view.call("_build_party_reward_text", 10, rows)
	check(text.begins_with("获得经验\n") and not "参战成员经验" in text, "victory uses the EXP section heading")
	check("冷孤云  经验 +10" in text and "沈青禾  经验 +10" in text, "victory page lists each member and exact EXP")
	check("Lv.1 → Lv.2  等级提升" in text, "victory page names the member's level increase")
	battle_logic.free()
	result_view.free()


func _check_yanmen_route_and_manual() -> void:
	var scene := load("res://data/scenes/openworld_yanmen_pass.tres") as SceneScript
	var snow_types: Array[String] = []
	for prop: Dictionary in scene.animated_props:
		snow_types.append(String(prop.get("type", "")))
	check("snow_drift" in snow_types, "Yanmen pass has an authored drifting-snow layer")
	var cave_portal: Dictionary = {}
	for portal: Dictionary in scene.map_layout.portals:
		if portal.get("id", "") == "snow_hidden_cave":
			cave_portal = portal
	check(not cave_portal.is_empty() and cave_portal.get("require_flag", "") == "" and cave_portal.get("locked_label", "") == "", "Yanmen cave is freely enterable and communicates danger without a hard lock")
	check(ResourceLoader.exists("res://data/scenes/openworld_yanmen_hidden_cave.tres"), "Yanmen hidden cave is a real walkable scene")
	var guard_dialog := load("res://data/dialogs/openworld_yanmen_cave_guard.tres") as DialogScript
	check(guard_dialog.nodes[0].on_end == "battle_group_then:openworld_yanmen_cave_guard,openworld_snow_raider:openworld_yanmen_cave_guard_victory", "cave cache requires a two-enemy authored fight")
	var treasure := load("res://data/dialogs/openworld_snow_treasure.tres") as DialogScript
	var gifts: Array[StringName] = []
	for gift: Dictionary in treasure.nodes[0].give_items:
		gifts.append(StringName(gift.get("id", "")))
	check(&"heavy_iron_sword" in gifts and &"cold_ridge_guard_breath_manual" in gifts, "cave cache grants weapon and manual together")
	check(treasure.nodes[0].learn_skills.is_empty(), "cave cache never directly learns the internal art")
	var manual := load("res://data/items/cold_ridge_guard_breath_manual.tres") as Item
	var skill := load("res://data/skills/cold_ridge_guard_breath.tres") as Skill
	check(manual.is_readable() and manual.study_skill_id == &"cold_ridge_guard_breath", "manual is readable and links to the correct skill")
	check(skill.get_required_insight() == 8, "advanced internal-art manual requires eight insight")
	var gs := root.get_node("GameState")
	var router := root.get_node("SceneRouter")
	gs.flags.clear()
	router.set("_battle_payload", {"return_scene": &"openworld_yanmen_pass"})
	var route_logic: Node = load("res://scripts/battle/battle_controller.gd").new()
	route_logic.call("_record_openworld_route_progress", false, true)
	check(int(gs.get_flag(&"openworld_yanmen_route_progress", 0)) == 1 and not bool(gs.get_flag(&"openworld_yanmen_cave_unlocked", false)), "legacy route mastery still records the first successful withdrawal")
	route_logic.call("_record_openworld_route_progress", true, false)
	check(int(gs.get_flag(&"openworld_yanmen_route_progress", 0)) == 2 and bool(gs.get_flag(&"openworld_yanmen_cave_unlocked", false)), "legacy route mastery still records two successful outcomes without controlling cave entry")
	var source := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	var retreat_start := source.find("func _finish_retreat()")
	var retreat_end := source.find("\nfunc ", retreat_start + 6)
	var retreat_body := source.substr(retreat_start, retreat_end - retreat_start)
	check("play_defeat" not in retreat_body and "go_defeat" not in retreat_body, "successful team retreat has no defeat pose or defeat result route")
	route_logic.free()


func _check_music_variation() -> void:
	var audio := root.get_node("AudioManager")
	var stream := load("res://art/audio/bgm/bgm_village_day_v4.wav") as AudioStream
	var entries: Dictionary = {}
	for context in ["linxi_center", "linxi_south", "zhuwei_inn", "hero_room", "school", "apothecary", "market", "master_hall"]:
		entries[float(audio.call("_contextual_start_position", stream, context))] = true
	check(entries.size() >= 3, "shared approved field theme enters at at least three stable phrase seams")
	var battle_logic: Node = load("res://scripts/battle/battle_controller.gd").new()
	var battle_tracks: Dictionary = {}
	for arena in [&"bamboo_platforms", &"river_skirmish", &"village_square", &"snow_peak", &"mingwu_sanctum"]:
		battle_tracks[String(battle_logic.call("_battle_bgm_for_payload", {"battle_arena": arena}))] = true
	check(battle_tracks.size() >= 4, "spar, river, village/snow and boss encounters select distinct battle tracks")
	battle_logic.free()
