extends "res://build/victory_quest_20261108/story_live.gd"

const WORLD := &"world_map_jianghu_v16"
const RIVERSIDE := &"adventure_luoyang_riverside_route"
const PATROL := &"q_ch1_side_08_mountain_patrol"

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
	var world := await enter(WORLD)
	if world != null:
		await verify_world(world)
	await verify_battle()
	finish()

func verify_world(world: Node) -> void:
	await settle(world)
	var backdrop: Node = world.get("world_container").get_node_or_null("WorldBackgroundChunks")
	expect(backdrop != null and backdrop.has_meta("river_meadow_surface"), "live World uses river and meadow material")
	var links: Node = root.get_node("AdventureRuntime").get_node("AdventureWorldLinks31f")
	var overlay: Node2D = links.get("overlay_root")
	if not expect(is_instance_valid(overlay), "World waypoint overlay is present"):
		return
	for i in 3:
		var body := overlay.get_node_or_null("adventure31f_riverside_NativeFootprint_%d" % i) as StaticBody2D
		if not expect(body != null, "riverside footprint %d exists" % i):
			continue
		var poly: PackedVector2Array = body.get_child(0).polygon
		var center := Vector2.ZERO
		for p in poly: center += p
		var actor := await position_at(world, overlay.to_global(center / poly.size()))
		expect(not links.actor_shape_clear(actor), "riverside footprint %d blocks character" % i)
	await position_at(world, Vector2(8480, 3240))
	await create_timer(0.3).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://world_river_surface.png")
	var zone := zone_to(world, RIVERSIDE)
	if not expect(zone != null, "original riverside portal is present"): return
	var foot := zone.global_position
	await position_at(world, foot + Vector2(0, 35))
	await create_timer(0.25).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://riverside_waypoint.png")
	var local := await take(world, RIVERSIDE)
	if local != null:
		var returned := await take(local, WORLD)
		if returned != null:
			var actor: Player = returned.get("_player")
			expect(actor.global_position.distance_to(foot) <= 100.0, "returns to the same world waypoint")

func verify_battle() -> void:
	var inventory := root.get_node("Inventory")
	expect(state.add_companion(&"tang_xingzhou"), "Tang recruited in isolated party")
	state.player.speed = 1000
	state.player.agility = 1000
	inventory.add_item(&"field_edge_pill", 1)
	state.set_flag(&"defeated_bandit_mountain", true)
	expect(quests.accept(PATROL), "accepted road commission with old flag present")
	expect(not quests.complete(PATROL), "early completion even via stale dialogue is rejected")
	router.start_battle("bandit_mountain", &"ch1_s1_road")
	var loading := root.get_node("LoadingManager")
	if expect(await wait_for(func(): return loading.get("_transition_active"), 2000), "loading starts"):
		var screen: LoadingScreen = loading.get("_screen")
		expect(screen.is_showing() and screen.root.modulate.a == 1.0, "transition takes over with opaque first frame")
		expect(screen.get("_opaque_backdrop").color.a == 1.0, "loading has a full-window solid underlay")
	if not expect(await wait_for(func(): return current_scene != null and current_scene.scene_file_path == "res://scenes/battle.tscn" and current_scene.get("_state") == 1, 17000), "actual bandit battle accepts commands"):
		return
	var battle := current_scene
	var formation: BattleFormationView = battle.get("formation_view")
	var tang := formation.get_actor(&"tang_xingzhou")
	if expect(tang != null and tang.ready_frames.size() == 4, "Tang has four ready frames"):
		var active_frames := {}
		for i in 8:
			active_frames[tang.artwork.texture.resource_path] = true
			await create_timer(0.10).timeout
		expect(active_frames.size() >= 3, "Tang cycles distinct visible frames while waiting")
		expect(not tang.move_frames.is_empty() and not tang.attack_frames.is_empty(), "Tang still has move/attack assets")
	var unit: BattleCombatant = battle.get("_team_active_unit")
	expect(unit.unit_id == &"player", "medicine fixture starts with protagonist turn")
	battle._open_battle_inventory()
	var panel: Control = battle.get("_battle_inventory_panel")
	expect(panel != null and panel._use_item_now(&"field_edge_pill"), "actual battle inventory uses forged medicine")
	expect(inventory.count_of(&"field_edge_pill") == 0 and int(unit.status_effects.get("field_edge", 0)) == 2, "medicine consumed and retains two actions")
	var enemies: Array = battle.get("_team_enemies")
	for enemy: BattleCombatant in enemies:
		enemy.stats.hp = 1
		enemy.stats.agility = 1
	for turn in 7:
		if not await wait_for(func(): return not is_instance_valid(battle) or battle.get("_state") in [1,5], 8500): break
		if not is_instance_valid(battle) or battle.get("_state") == 5: break
		var living: Array = battle._team_living_enemies()
		if living.is_empty(): break
		var active: BattleCombatant = battle.get("_team_active_unit")
		var skills: Array = battle._skills_for_stats(active.stats)
		for i in skills.size():
			if skills[i].skill_id == &"basic_attack":
				battle._team_player_action_skill_use(i, living[0].unit_id)
				break
		await create_timer(0.35).timeout
	if expect(await wait_for(func(): return current_scene != null and current_scene.scene_file_path == "res://scenes/result_victory.tscn", 8500), "actual road battle victory"):
		current_scene.get_node("%BtnContinue").pressed.emit()
		expect(await wait_for(func(): return state.get_flag(&"mountain_patrol_bandits_repelled") == true, 12000), "road victory credits already accepted commission")
		expect(await wait_for(func(): return is_instance_valid(current_scene) and router.get_current_field_id() == &"ch1_s1_road" and current_scene.has_method("get_field_loading_state") and current_scene.get_field_loading_state().get("complete", false) and not loading.get("_transition_active"), 17000), "victory returns to the formal mountain road")
		expect(quests.is_active(PATROL), "winning alone does not complete the quest")
		state.set_flag(&"zhuwei_scout_clue", true)
		var village := await enter(&"ch1_s2_qingfeng")
		if village != null:
			await settle(village)
			for scout: NPCNode in village.get("_npc_nodes"):
				if scout.npc_id != "patrol_scout": continue
				var next_dialog: String = scout._resolve_dialog_id()
				expect(next_dialog == "ch1_s2_patrol_scout_turnin", "formal village scout selects valid turn-in")
				await speak_to(village, "patrol_scout", &"ch1_s2_patrol_scout_turnin")
				expect(quests.is_completed(PATROL), "qualified scout turn-in grants unchanged rewards")
				break
		expect(quests.is_completed(PATROL), "formal village turn-in was exercised")
		var tip: Node = quests.get_node("QuestRewardTip")
		expect(tip != null and quests._row("解毒丹", "×1", Color.WHITE, inventory.load_item_by_id(&"antidote_pill")).has("icon"), "reward supplies actual item icon")
		var card: PanelContainer = tip.get("_panel")
		var box: StyleBoxTexture = card.get_theme_stylebox("panel")
		expect(card.is_visible_in_tree() and is_equal_approx(box.modulate_color.a, 0.78), "shown quest reward uses translucent backing")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://patrol_reward.png")
