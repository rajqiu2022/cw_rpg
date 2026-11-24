extends "res://build/victory_quest_20261108/story_live.gd"
## Fresh main-menu run. No story flags, forced victories, warp, free items or direct harvest.
const LINXI_ROAD := &"ch1_s1_road"
const FOREST := &"ch1_s3_zhuwei_forest"
const CAVE := &"ch1_s4_zhuwei_beast_cave"
const VILLAGE := &"ch1_s2_qingfeng"
const CENTER := &"linxi_village_center"
const TUTORIAL := &"linxi_tutorial"
const RUIN := &"ch1_s3_west_ruin"
var step := "bootstrap"
var halted := false
var battles: Array[String] = []
var completed_results: Dictionary = {}
var focus_used := false
var harvest: Dictionary = {}
var cues: Dictionary = {}
var inventory: Node
var loading: Node
var gathering: Script
var walk_px := 0.0
var road_walk_px := 0.0
var road_fights: Array[float] = []
var visual_run := false
var screen_trial := false
var screen_motion_epoch := 0
var held: Dictionary = {}

func _run() -> void:
	await process_frame
	set_meta("skip_chapter_end_autosave", true)
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router = root.get_node("SceneRouter")
	state = root.get_node("GameState")
	quests = root.get_node("QuestManager")
	dialogue = root.get_node("DialogPlayer")
	inventory = root.get_node("Inventory")
	loading = root.get_node("LoadingManager")
	gathering = load("res://scripts/life_skills/gathering_service.gd")
	root.get_node("EventBus").item_picked_up.connect(_pickup)
	seed(20261118)
	var ore_trial := OS.get_cmdline_user_args().has("--screen-ore")
	screen_trial = (ore_trial or OS.get_cmdline_user_args().has("--screen-walk")) and DisplayServer.get_name() != "headless"
	visual_run = (screen_trial or OS.get_cmdline_user_args().has("--visual-review")) and DisplayServer.get_name() != "headless"
	if visual_run: root.title = "云影侠传 · 第一章实走 QA" if not screen_trial else "云影侠传 · 画面寻路 QA"
	Engine.time_scale = 3.0
	Engine.physics_ticks_per_second = 180
	if OS.get_cmdline_user_args().has("--portal-probe"):
		router.go_field_smart(&"ch1_s4_cave_mine_gallery")
		if not await want_field(&"ch1_s4_cave_mine_gallery"): return
		probe_portals(current_scene)
		_report()
		return
	change_scene_to_file("res://scenes/loading_bootstrap.tscn")
	if not await wait_for(func(): return _scene_path() == "res://scenes/main_menu.tscn" and not loading.get("_transition_active"), 16000): return fail("main menu")
	var button: Button = current_scene.get_node("%BtnNewGame")
	await click(button.get_global_rect().get_center())
	if not await want_field(TUTORIAL): return
	if not await npc("xingfantian"): return
	if not await npc("duqingshan_ready"): return
	if not expect(state.get_flag(&"got_sword"), "Du grants earned sword"): return fail("sword not granted")
	equip_if_owned(&"linxi_iron_sword")
	if not await npc("duqingshan_after_sword", 1): return
	if not await gate(CENTER): return
	if not await gate(LINXI_ROAD): return
	if screen_trial:
		# A separate viewport-only review begins on the visible road shoulder.
		if ore_trial:
			if not await area_action("ch1_road_corpse", true): return
			if not await walk_point(Vector2(3270, 2110), 70.0): return fail("ore approach checkpoint")
		Engine.time_scale = 1.0
		Engine.physics_ticks_per_second = 60
		root.window_input.connect(_screen_trial_key)
		await visual_checkpoint("screen-only-start")
		print("SCREEN_ONLY_READY F6=left F7=up F8=down F9=right F10=finish")
		return
	# Follow the route before any QA lookup of a cache coordinate.
	await walk_point(Vector2(1120, 2670), 90.0)
	await walk_point(Vector2(1260, 2605), 27.0, true) # Follow Du's clue around the road tablet.
	await harvest_glow_cache()
	if not await area_action("ch1_road_corpse", true): return
	if not await wait_for(func(): return state.get_flag(&"defeated_thug_lone"), 3000): return fail("road ambush not won")
	equip_if_owned(&"cloth_armor")
	equip_if_owned(&"ch1_wayfarer_bracers")
	if not await gate(CENTER): return
	if not await gate(TUTORIAL): return
	if not await npc("xingfantian_return"): return
	if not expect(state.get_flag(&"master_training_done"), "original training gate"): return fail("master has not taught")
	if not await gate(CENTER): return
	if not await gate(LINXI_ROAD): return
	if not cues.has("ch1_cache_stone_guard"): await search_field_caches()
	for id: String in ["life_road_herb_02", "life_road_ore_01"]:
		if not await gather_site(id): return
	if not await gate(VILLAGE, "ch1_road_to_zhuwei"): return
	if not await npc("guard"): return
	if not await npc("patrol_scout"): return
	if not await gate(&"interior_inn_hall"): return
	if not await npc("", -1, "ch1_s2_inn_keeper"): return
	if not await gate(VILLAGE): return
	if not await npc("guard"): return
	if not await gate(FOREST): return
	await search_field_caches()
	for id: String in ["life_forest_herb_01", "life_forest_herb_02", "life_forest_ore_01"]:
		if not await gather_site(id): return
	if not await gate(&"adventure_zhuwei_hunting_ground"): return
	for id: String in ["adventure_forest_herb_01", "adventure_forest_herb_02"]:
		if not await gather_site(id): return
	if not await gate(FOREST): return
	if not await area_action("ch1_forest_beast_pack_encounter", true): return
	if not await gate(CAVE): return
	await search_field_caches()
	read_found_art()
	if not await gather_site("life_ch1_cave_ore_01"): return
	if not craft_medicine(): return
	if not await gate(&"ch1_s4_cave_mine_gallery"): return
	if not await gate(&"ch1_s4_cave_deep_den"): return
	if not await area_action("ch1_zhuwei_cave_wolf_encounter", true): return
	if not await area_action("ch1_zhuwei_cave_clue"): return
	if not await gate(&"ch1_s4_cave_mine_gallery"): return
	if not await gate(CAVE): return
	if not await gate(FOREST): return
	if not await gate(VILLAGE): return
	if not await temper_in_zhuwei(): return
	if not await gate(RUIN): return
	if not await npc("ruin_outer_guard"): return
	for action in ["ch1_s3_ruin_shipping_marks", "ch1_s3_ruin_watch_roster"]:
		if not await area_action(action): return
	if not await gate(&"ch1_s3_ruin_inner"): return
	if not await npc("zhao_wuji"): return
	if not await area_action("ch1_s3_ruin_orders"): return
	expect(state.get_flag(&"chapter1_complete") and state.get_flag(&"chapter2_river_lead"), "chapter 1 settled")
	expect(_scene_path() == "res://scenes/chapter_end.tscn", "actual chapter completion screen")
	expect(cues.size() == 4, "all four hidden items found by walking landmark approaches")
	await visual_checkpoint("09-chapter-end")
	_report()

func _scene_path() -> String:
	return current_scene.scene_file_path if is_instance_valid(current_scene) else ""

func field_ready(id: StringName = &"") -> bool:
	return is_instance_valid(current_scene) and current_scene.has_method("get_field_loading_state") and current_scene.get_field_loading_state().get("complete", false) and not loading.get("_transition_active") and not loading.get("_external_active") and (id == &"" or router.get_current_field_id() == id)

func want_field(id: StringName) -> bool:
	if not await pump(func(): return field_ready(id), 22000):
		fail("field not reached " + String(id))
		return false
	await settle_live()
	print("ROUTE FIELD ", id, " foot=", current_scene.get("_player").global_position if field_ready(id) else Vector2.ZERO, " gold=", state.gold)
	return not halted

func set_step(value: String) -> void:
	step = value
	print("ROUTE STEP ", step, " field=", router.get_current_field_id())

func fail(message: String) -> void:
	if halted: return
	halted = true
	expect(false, message + " at " + step + " scene=" + _scene_path())
	if field_ready():
		print("ROUTE STATE foot=", current_scene.get("_player").global_position)
		for n: NPCNode in current_scene.get("_npc_nodes"): print("ROUTE NPC ", n.npc_id, " ", n.dialog_id, " ", n.global_position)
		for z: ExitZone in current_scene.get("_exit_nodes"): print("ROUTE GATE ", z.target_scene_id, " ", z.action, " locked=", z.is_locked, " ", z.global_position)
		for a: Area2D in current_scene.get("_trigger_areas"): print("ROUTE AREA ", a.get_meta("trigger_data", {}).get("action", ""), " ", a.global_position)
	_report()

func _report() -> void:
	print("ROAD_PACING px=", roundi(road_walk_px), " random_fights_at=", road_fights)
	print("ROUTE TOTAL battle=", battles, " harvest=", harvest, " cues=", cues, " walk_px=", roundi(walk_px), " gold=", state.gold, " completed=", state.get_flag(&"chapter1_complete"), " scene=", _scene_path())
	finish()

func _pickup(id: StringName, count: int) -> void:
	print("ROUTE ITEM ", router.get_current_field_id(), " ", id, " +", count, " now=", inventory.count_of(id))

func _screen_trial_key(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_F10:
		call_deferred("_report")
		return
	var direction := {KEY_F6: Vector2.LEFT, KEY_F7: Vector2.UP, KEY_F8: Vector2.DOWN, KEY_F9: Vector2.RIGHT}.get(event.keycode, Vector2.ZERO) as Vector2
	if direction == Vector2.ZERO: return
	_screen_step.call_deferred(direction, 0.22 if event.shift_pressed else 0.50)

func _screen_step(direction: Vector2, seconds: float) -> void:
	screen_motion_epoch += 1
	var token := screen_motion_epoch
	set_direction(direction)
	await create_timer(seconds).timeout
	if token == screen_motion_epoch: set_direction(Vector2.ZERO)

func click(point: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = point
	root.push_input(m, true)
	await process_frame
	for pressed: bool in [true, false]:
		var e := InputEventMouseButton.new()
		e.position = point
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		root.push_input(e, true)
		await process_frame

func pump(done: Callable, ms: int, choice: int = -1) -> bool:
	var end := Time.get_ticks_msec() + ms
	var last_battle := 0
	var last_turn := 0
	while not halted and Time.get_ticks_msec() < end:
		if done.call(): return true
		if dialogue.is_playing():
			var node: DialogNode = dialogue.get("_current_node")
			if node != null:
				var ds: DialogScript = dialogue.get("_current_script")
				print("ROUTE SAY ", ds.dialog_id, " ", node.node_id)
				if node.has_choices() or dialogue.get("_pending_side_offer_id") != &"":
					var selected := choice if choice >= 0 else 0
					if choice < 0:
						for i: int in range(node.choices.size()):
							var label := String(node.choices[i].get("text", ""))
							if "暂不接" in label or "稍后" in label or "先不" in label or "先做别的事" in label or label == "告辞": selected = i
					choice = -1
					dialogue.choose(selected)
				else:
					dialogue.advance()
				await create_timer(0.075).timeout
		elif _scene_path() == "res://scenes/battle.tscn":
			if current_scene.get_instance_id() != last_battle:
				last_battle = current_scene.get_instance_id()
				last_turn = 0
				if router.get_current_field_id() == LINXI_ROAD and not battles.is_empty() and (road_fights.is_empty() or not is_equal_approx(road_fights.back(), road_walk_px)):
					road_fights.append(road_walk_px)
			if current_scene.get("_state") == 1 and Time.get_ticks_msec() - last_turn > 110:
				last_turn = Time.get_ticks_msec()
				battle_action(current_scene)
		elif _scene_path() == "res://scenes/result_victory.tscn":
			var result_id := current_scene.get_instance_id()
			if not completed_results.has(result_id):
				completed_results[result_id] = true
				var result: Dictionary = router.get_result_payload()
				battles.append(String(result.get("enemy_name", step)))
				print("ROUTE VICTORY ", step, " gold=", state.gold, " lv=", state.player.level)
				current_scene.call("_on_continue_pressed")
		elif _scene_path() == "res://scenes/result_defeat.tscn":
			fail("real battle lost"); return false
		await process_frame
	return false

func settle_live(choice: int = -1) -> void:
	await create_timer(0.32).timeout
	var settled := await pump(func():
		if _scene_path() == "res://scenes/chapter_end.tscn": return true
		if not field_ready() or dialogue.is_playing(): return false
		var actor: Player = current_scene.get("_player")
		return is_instance_valid(actor) and actor.can_move and not current_scene.get("_scene_rebuilding")
	, 60000 if visual_run else 18000, choice)
	if not settled and _scene_path() == "res://scenes/battle.tscn":
		var active: BattleCombatant = current_scene.get("_team_active_unit")
		print("PC_BATTLE_WAIT state=", current_scene.get("_state"), " actor=", active.unit_id if active != null else &"", " hp=", active.stats.hp if active != null else -1)
	await create_timer(0.32).timeout

func battle_action(b: Node) -> void:
	var unit: BattleCombatant = b.get("_team_active_unit")
	if unit == null or unit.stats == null: return
	if not focus_used and "wolf_encounter" in step and inventory.has_item(&"field_focus_pill"):
		b.call("_open_battle_inventory")
		if b.get("_battle_inventory_panel").call("_use_item_now", &"field_focus_pill"):
			focus_used = true
			print("ROUTE USED focus pill in alpha wolf fight")
			return
	if unit.stats.hp * 100 < unit.stats.max_hp * 51 and inventory.has_item(&"healing_pill_minor"):
		b.call("_open_battle_inventory")
		if b.get("_battle_inventory_panel").call("_use_item_now", &"healing_pill_minor"): return
	var enemies: Array = b.call("_team_living_enemies")
	if enemies.is_empty(): return
	var skills: Array = b.call("_skills_for_stats", unit.stats)
	var index := -1
	var best := -1
	for i: int in range(skills.size()):
		var sk := skills[i] as Skill
		if sk == null or not bool(b.call("_can_use_skill", sk, unit.stats)): continue
		if int(sk.target) not in [0, 1]: continue
		var strength := sk.fixed_damage + sk.get_attack_scaling()
		if strength > best: best = strength; index = i
	if index >= 0:
		var target: BattleCombatant = enemies[0]
		for enemy: BattleCombatant in enemies:
			if enemy.stats.hp < target.stats.hp: target = enemy
		b.call("_team_player_action_skill_use", index, &"" if (skills[index] as Skill).target == Skill.Target.ENEMY_ALL else target.unit_id)

func equip_if_owned(id: StringName) -> void:
	if inventory.has_item(id): inventory.equip(id)

func npc(id: String, choice: int = -1, dialog_id: String = "") -> bool:
	set_step("npc " + (id if not id.is_empty() else dialog_id))
	if not field_ready(): return bad("NPC outside field")
	var target: NPCNode
	for n: NPCNode in current_scene.get("_npc_nodes"):
		if (not id.is_empty() and n.npc_id == id) or (not dialog_id.is_empty() and n.dialog_id == dialog_id): target = n; break
	if target == null: return bad("NPC not spawned")
	if not await walk_point(target.global_position, 83): return bad("NPC inaccessible")
	await press_space()
	if not await wait_for(func(): return dialogue.is_playing() or _scene_path() == "res://scenes/battle.tscn", 1800): return bad("Space did not start NPC")
	await settle_live(choice)
	return not halted

func gate(id: StringName, action_contains: String = "") -> bool:
	set_step("gate " + String(id))
	var source: StringName = router.get_current_field_id()
	for attempt: int in range(5):
		if not field_ready(): return bad("gate outside field")
		var portal: ExitZone
		for z: ExitZone in current_scene.get("_exit_nodes"):
			if (z.target_scene_id == String(id) or (not action_contains.is_empty() and action_contains in z.action)) and not z.is_locked:
				portal = z; break
		if portal == null: return bad("gate not spawned or locked")
		var from := current_scene.get_instance_id()
		var foot_goal := portal.global_position
		var range_px := 28.0
		if portal.has_method("_can_enter"):
			var approaches := portal_approaches(current_scene, portal)
			if approaches.is_empty(): return bad("portal has no clear feet inside its rectangle")
			foot_goal = approaches[mini(attempt * 2, approaches.size() - 1)]
			range_px = 14.0
		if not await walk_point(foot_goal, range_px, id == &"adventure_zhuwei_hunting_ground"):
			if field_ready(source) and current_scene.get_instance_id() == from: continue
		await create_timer(0.36).timeout
		if field_ready() and current_scene.get_instance_id() == from and not dialogue.is_playing() and current_scene.get("_player").can_move:
			if is_instance_valid(portal) and portal.has_method("_can_enter") and not portal.call("_can_enter"):
				print("ROUTE GATE FEET ", foot_goal, " foot=", current_scene.get("_player").global_position, " rect=", portal.get("_feet_rect"))
				continue
			await press_space()
		if not await pump(func(): return field_ready(id) or (field_ready(source) and current_scene.get_instance_id() != from), 42000 if visual_run else 16000): break
		if field_ready(id): return await want_field(id)
		await settle_live()
	return bad("gate did not reach " + String(id))

func portal_approaches(field: Node, portal: ExitZone) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var rect: Rect2 = portal.get("_feet_rect")
	var extent: Vector2 = field.get("_world_size")
	var actor: Player = field.get("_player")
	var offset := Vector2(0, float(actor.call("_visual_foot_offset")))
	var world: Node2D = field.get("world_container")
	var clearance: Callable = portal.get("_feet_clearance")
	for iy: int in range(1, 8):
		for ix: int in range(1, 8):
			var u := rect.position + rect.size * Vector2(ix, iy) / 8.0
			if not clearance.call(u): continue
			var p := world.to_global(u * extent) - offset
			if actor.movement_constraint.is_valid() and not actor.movement_constraint.call(p): continue
			points.append(p)
	points.sort_custom(func(a: Vector2, b: Vector2): return a.distance_squared_to(actor.global_position) < b.distance_squared_to(actor.global_position))
	return points

func probe_portals(field: Node) -> void:
	var extent: Vector2 = field.get("_world_size")
	var sc: SceneScript = field.get("_current_scene")
	var pw: Player = field.get("_player")
	print("ROUTE PROBE extent=", extent, " layout=", sc.map_layout.resource_path, " mask=", sc.map_layout.walkable_mask_path, " world=", field.world_container.global_position, " offset=", pw.call("_visual_foot_offset"), " rows=",sc.map_layout.portals)
	for portal: ExitZone in field.get("_exit_nodes"):
		if not portal.has_method("_can_enter"): continue
		var rect: Rect2 = portal.get("_feet_rect")
		var clearance: Callable = portal.get("_feet_clearance")
		var row: Array[Vector2] = []
		for iy: int in range(-5,13):
			for ix: int in range(-5,13):
				var uv := rect.position + rect.size * Vector2(ix,iy)/8.0
				if clearance.call(uv): row.append(uv)
		print("ROUTE PROBE gate=", portal.target_scene_id, " rect=", rect, " center=", portal.position, " candidates=", portal_approaches(field,portal).size(), " nearby_clear_samples=", row.size())

func area_action(part: String, must_battle: bool = false) -> bool:
	set_step("area " + part)
	if not field_ready(): return bad("area outside field")
	var target: Area2D
	for a: Area2D in current_scene.get("_trigger_areas"):
		if part in String(a.get_meta("trigger_data", {}).get("action", "")): target = a; break
	if target == null: return bad("interaction area not spawned")
	var wins := battles.size()
	if not await walk_point(target.global_position, 26, part == "ch1_road_corpse"): return bad("interaction area inaccessible")
	await create_timer(0.30).timeout
	if field_ready() and not dialogue.is_playing(): await press_space()
	await settle_live()
	return not halted and (not must_battle or battles.size() > wins or bad("fight did not start"))

func bad(message: String) -> bool:
	fail(message)
	return false

func harvest_glow_cache() -> bool:
	var adv := root.get_node("AdventureRuntime")
	var near := String(adv.get("_near"))
	if not near.begins_with("ch1_cache_"): return false
	var row: Dictionary = adv.get("_features")[near]
	if not row.glow.is_visible_in_tree(): return false
	var was: int = inventory.count_of(StringName(row.item_id))
	if visual_run:
		set_direction(Vector2.ZERO)
		await visual_checkpoint("cue-" + near)
	await press_space()
	if not await wait_for(func(): return adv.get_adventure_state().modal_open, 750): return false
	print("ROUTE CUE ", near, " at foot=", current_scene.get("_player").global_position, " label=", row.label)
	adv.get("_dialog").call("_accept")
	if inventory.count_of(StringName(row.item_id)) <= was: return false
	cues[near] = "glow found while walking"
	return true

func read_found_art() -> void:
	if not inventory.has_item(&"ch1_lamplit_fragment") or not inventory.has_item(&"ch1_woodland_fragment"): return
	var reader: Control = load("res://scenes/ui/reading_panel.tscn").instantiate()
	root.add_child(reader)
	reader.open_item(inventory.load_item_by_id(&"ch1_lamplit_fragment"))
	if not reader.get("_study_button").disabled:
		reader.get("_study_button").pressed.emit()
	print("ROUTE STUDY insight=", state.get_effective_insight(), " learned=", state.player.skills.has(&"ch1_hide_edge_breath"))
	reader.queue_free()

func search_field_caches() -> void:
	var id: StringName = router.get_current_field_id()
	var waypoints: Array[Vector2] = []
	match id:
		LINXI_ROAD: waypoints.assign([Vector2(1120, 2670), Vector2(1650, 2360), Vector2(1910, 2140), Vector2(2230, 2350)])
		FOREST: waypoints.assign([Vector2(850, 970), Vector2(795, 750)]) # Hunting spur, not cache coordinates.
		CAVE: waypoints.assign([Vector2(1550, 880), Vector2(1550, 760), Vector2(1630, 664), Vector2(1710, 561)])
	for p: Vector2 in waypoints:
		await walk_point(p, 45.0, true)
		await harvest_glow_cache()

func gather_site(id: String) -> bool:
	set_step("gather " + id)
	var ls := root.get_node("LifeSkills")
	var reached := false
	for attempt: int in range(8):
		if not field_ready() or not current_scene.get("_player").can_move:
			await settle_live()
			if halted: return false
		if not await wait_for(func(): return ls.get("_site_nodes").has(id), 1200): return bad("harvest node missing")
		var site: Node2D = ls.get("_site_nodes")[id]
		var position := site.global_position
		if not await walk_point(position, 46.0):
			if not field_ready() or not current_scene.get("_player").can_move: continue
			return bad("cannot walk to harvest")
		if await wait_for(func(): return ls.get("_nearest") == id, 650):
			reached = true
			break
		await settle_live()
	if not reached: return bad("no harvest ring at walking distance")
	var before: Dictionary = gathering.preview(id)
	if not before.ok: return bad(String(before.message))
	var item := StringName(before.item_id)
	var owned: int = inventory.count_of(item)
	if id in ["life_road_herb_02", "life_road_ore_01", "adventure_forest_herb_02", "life_ch1_cave_ore_01"]:
		await visual_checkpoint("collect-" + id)
	await press_space()
	if not await wait_for(func(): return inventory.count_of(item) > owned, 6500): return bad("Space did not harvest")
	harvest[id] = {"id": String(item), "count": inventory.count_of(item) - owned}
	return true

func visual_checkpoint(label: String) -> void:
	if not visual_run: return
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	if frame != null and not frame.is_empty():
		var path := ProjectSettings.globalize_path("user://" + label + ".png")
		if frame.save_png(path) == OK: print("PC_FRAME ", path)

func craft_medicine() -> bool:
	set_step("compare chapter-one materials")
	var ls := root.get_node("LifeSkills")
	ls.call("_open_panel", "medicine", [], current_scene)
	var panel: Control = ls.get("_panel")
	if panel == null: return bad("medicine panel did not open")
	for id: String in ["field_edge_pill", "field_focus_pill", "field_guard_powder"]:
		var owned: int = inventory.count_of(StringName(id))
		panel.call("_ask", id)
		panel.get("_confirm").call("_accept")
		if inventory.count_of(StringName(id)) <= owned: return bad("recipe insufficient: " + id + " " + panel.status.text)
	panel.call("close_panel")
	print("ROUTE BUDGET after three potions ore=", inventory.count_of(&"iron_ore"), " gold=", state.gold)
	return true

func temper_in_zhuwei() -> bool:
	set_step("Zhuwei smith counter")
	var ls := root.get_node("LifeSkills")
	var smith: NPCNode
	for n: NPCNode in current_scene.get("_npc_nodes"):
		if n.npc_id == "merchant": smith = n; break
	if smith == null or not await walk_point(smith.global_position, 70.0): return bad("merchant unavailable for upgrading")
	await press_space()
	if not await pump(func(): return _scene_path() == "res://scenes/shop.tscn" and current_scene.has_node("Panel/LifeSmithButton") and not loading.get("_transition_active"), 12000): return bad("Zhuwei counter did not open")
	current_scene.get_node("Panel/LifeSmithButton").pressed.emit()
	var panel: Control = ls.get("_panel")
	if panel == null: return bad("smith panel did not open")
	# Keep the earned sword so training and forging complement each other.
	equip_if_owned(&"linxi_iron_sword")
	var instance: String = inventory.get_equipped_instance_id(Equipment.Slot.WEAPON)
	if instance.is_empty(): return bad("no equipped weapon")
	for rank: int in [1, 2, 3]:
		panel.call("_ask_temper", instance)
		panel.get("_confirm").call("_accept")
		var w := inventory.get_equipped(Equipment.Slot.WEAPON) as Equipment
		if w.forge_rank != rank: return bad("upgrade materials short at +%d: %s" % [rank, panel.status.text])
		print("ROUTE FORGE ", w.display_name, " ore=", inventory.count_of(&"iron_ore"), " gold=", state.gold, " affixes=", w.forge_affixes)
	panel.call("close_panel")
	current_scene.call("_on_close")
	return await want_field(VILLAGE)

func walk_point(goal: Vector2, tolerance: float, look_for_cache: bool = false) -> bool:
	for attempt: int in range(3):
		if not field_ready(): return false
		var field := current_scene
		var actor: Player = field.get("_player")
		if actor.global_position.distance_to(goal) <= tolerance: return true
		var path := await get_path(actor, field, goal, tolerance)
		if path.is_empty(): return false
		if walk_px == 0: print("ROUTE START PATH ", path.slice(0, 5), " enabled=", actor.is_physics_processing(), " constraint=", actor.movement_constraint.is_valid())
		var stuck := false
		for point: Vector2 in path:
			var last := actor.global_position
			var stalled := 0
			for tick: int in range(120):
				if not is_instance_valid(actor) or not field_ready() or current_scene != field or not actor.can_move or dialogue.is_playing():
					set_direction(Vector2.ZERO); return true
				if look_for_cache and await harvest_glow_cache():
					set_direction(Vector2.ZERO)
					await create_timer(0.23).timeout
				var here := actor.global_position
				if here.distance_to(goal) <= tolerance:
					set_direction(Vector2.ZERO); return true
				var diff := point - here
				if diff.length() < 11.0: break
				set_direction(Vector2(0.0 if absf(diff.x) < 7 else signf(diff.x), 0.0 if absf(diff.y) < 7 else signf(diff.y)))
				await physics_frame
				var d := last.distance_to(actor.global_position)
				walk_px += d
				if router.get_current_field_id() == LINXI_ROAD: road_walk_px += d
				stalled = stalled + 1 if d < 0.1 else 0
				last = actor.global_position
				if stalled > 10:
					if walk_px == 0: print("ROUTE START STALL goal=", point, " direction=", held, " vector=", Input.get_vector("move_left", "move_right", "move_up", "move_down"), " velocity=", actor.velocity, " shape=", actor.global_position)
					stuck = true; break
			if stuck: break
		set_direction(Vector2.ZERO)
		if not stuck and actor.global_position.distance_to(goal) <= tolerance + 5.0: return true
	print("ROUTE WALK BLOCK ", goal, " from=", current_scene.get("_player").global_position if field_ready() else Vector2.ZERO)
	return false

func set_direction(value: Vector2) -> void:
	var wanted := {KEY_A: value.x < 0, KEY_D: value.x > 0, KEY_W: value.y < 0, KEY_S: value.y > 0}
	for code: Key in wanted:
		var pressed: bool = wanted[code]
		if bool(held.get(code, false)) == pressed: continue
		held[code] = pressed
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)

func get_path(actor: Player, field: Node, goal: Vector2, tolerance: float) -> PackedVector2Array:
	await physics_frame
	var grid := AStarGrid2D.new()
	const CELL := Vector2(38.0, 38.0)
	var start := actor.global_position
	var world: Node2D = field.get("world_container")
	var extent: Vector2 = field.get("_world_size")
	grid.region = Rect2i(Vector2i.ZERO, Vector2i((extent / CELL).ceil()))
	grid.cell_size = CELL
	grid.offset = world.global_position + CELL / 2.0
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var shape := actor.get_node("CollisionShape2D") as CollisionShape2D
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	query.collision_mask = actor.collision_mask
	query.exclude = [actor.get_rid()]
	var space := actor.get_world_2d().direct_space_state
	var starts: Array[Vector2i] = []
	var ends: Array[Vector2i] = []
	for y: int in range(grid.region.size.y):
		for x: int in range(grid.region.size.x):
			var cell := Vector2i(x, y)
			var p := grid.get_point_position(cell)
			query.transform = shape.global_transform.translated(p - start)
			var legal := (not actor.movement_constraint.is_valid() or bool(actor.movement_constraint.call(p))) and space.intersect_shape(query, 1).is_empty()
			grid.set_point_solid(cell, not legal)
			if legal and p.distance_to(start) <= 81.0: starts.append(cell)
			if legal and p.distance_to(goal) <= maxf(28.0, tolerance - 2.0): ends.append(cell)
	if starts.is_empty() or ends.is_empty():
		print("ROUTE GRID ", start, " -> ", goal, " start=", starts.size(), " end=", ends.size())
		return PackedVector2Array()
	starts.sort_custom(func(a: Vector2i, b: Vector2i): return grid.get_point_position(a).distance_squared_to(start) < grid.get_point_position(b).distance_squared_to(start))
	ends.sort_custom(func(a: Vector2i, b: Vector2i): return grid.get_point_position(a).distance_squared_to(goal) < grid.get_point_position(b).distance_squared_to(goal))
	for a: Vector2i in starts:
		for b: Vector2i in ends:
			var path := grid.get_point_path(a, b)
			if not path.is_empty():
				path.append(goal)
				return path
	return PackedVector2Array()
