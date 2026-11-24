extends "res://build/victory_quest_20261108/story_live.gd"

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
	var inventory := root.get_node("Inventory")
	var adventure := root.get_node("AdventureRuntime")
	var gather := load("res://scripts/life_skills/gathering_service.gd")
	var craft := load("res://scripts/life_skills/crafting_service.gd")
	var templ := load("res://scripts/life_skills/weapon_tempering.gd")
	for flag in [&"seen_ch1_road_intro", &"entered_zhuwei_village", &"zhuwei_village_inquiry_done", &"entered_zhuwei_forest", &"defeated_linxi_wild_beast", &"defeated_zhuwei_cave_wolf", &"got_sword"]:
		state.set_flag(flag, true)
	var targets := {
		"ch1_s1_road": ["ch1_cache_stone_guard"],
		"ch1_s3_zhuwei_forest": ["ch1_cache_bamboo_page"],
		"ch1_s4_zhuwei_beast_cave": ["ch1_cache_cave_blade", "ch1_cache_lamp_page"],
	}
	for scene_id: String in targets:
		var field := await enter(StringName(scene_id))
		if not expect(field != null, "formal field " + scene_id):
			continue
		await settle(field)
		for id: String in targets[scene_id]:
			var features: Dictionary = adventure.get("_features")
			if not expect(features.has(id), "feature " + id):
				continue
			var feature: Dictionary = features[id]
			var point: Node2D = feature.node
			var item_id := StringName(feature.item_id)
			expect(not feature.glow.visible, "distant glow hidden for " + id)
			var foot_actor := await position_at(field, point.global_position)
			foot_actor.force_update_transform()
			await create_timer(0.20).timeout
			if not expect(await wait_for(func(): return adventure.get("_near") == id, 1800), "nearby fully legal foot and glow " + id):
				continue
			await press_space()
			await process_frame
			if expect(adventure.get_adventure_state().modal_open, "Space opens cache " + id):
				adventure.get("_dialog").call("_accept")
				expect(inventory.count_of(item_id) == 1 and not features.has(id), "cache grants and disappears " + id)
				expect(not adventure.interact(id), "already discovered " + id)
			else:
				print("CACHE_INPUT ", id, " script=", dialogue.is_playing(), " active=", root.get_node("LoadingManager").get("_transition_active"), " current=", router.get_current_field_id(), " battle=", router.get("_battle_in_progress"))
				await wait_for(func(): return not root.get_node("LoadingManager").get("_transition_active"), 12000)
		if scene_id == "ch1_s4_zhuwei_beast_cave":
			var life := root.get_node("LifeSkills")
			var ore: Node2D = life.get("_site_nodes").get("life_ch1_cave_ore_01")
			if expect(is_instance_valid(ore), "third physical ore point"):
				await position_at(field, ore.global_position)
				if expect(await wait_for(func(): return life.get("_nearest") == "life_ch1_cave_ore_01", 1400), "cave ore reachable"):
					await press_space()
					expect(await wait_for(func(): return inventory.count_of(&"iron_ore") == 3, 5000), "cave ore actual Space harvest")
			life.call("_open_panel", "medicine", [], field)
			var medicine: Control = life.get("_panel")
			if expect(is_instance_valid(medicine), "field opens travel pharmacy"):
				var headings := []
				for child: Control in medicine.rows.get_children():
					if child is Label: headings.append(child.text)
				expect(headings == ["临战药方 · 店铺不出售", "常备药方 · 恢复与解毒"], "battle and recovery recipes visibly grouped")
				medicine.call("close_panel")
	for id in ["life_road_ore_01", "life_forest_ore_01"]:
		expect(gather.collect(id).ok, "starting recipe ore " + id)
	expect(inventory.count_of(&"iron_ore") == 9, "three once-harvested veins suffice for +3")
	var manual: Item = inventory.load_item_by_id(&"ch1_lamplit_fragment")
	expect(manual.study_skill_id == &"ch1_hide_edge_breath" and manual.study_requires_item == &"ch1_woodland_fragment", "manual fields")
	var reader: Control = load("res://scenes/ui/reading_panel.tscn").instantiate()
	root.add_child(reader)
	if inventory.remove_item(&"ch1_woodland_fragment"):
		reader.open_item(manual)
		reader.call("_on_study_pressed")
		expect(reader.get("_study_button").disabled and not state.player.skills.has(manual.study_skill_id), "missing fragment blocks study")
		inventory.add_item(&"ch1_woodland_fragment")
		state.player.insight = maxi(state.player.insight, 6)
		reader.open_item(manual)
		reader.get("_study_button").pressed.emit()
		expect(state.player.skills.has(manual.study_skill_id), "actual reading window learns from both fragments")
	reader.free()
	var sword_id := &"ch1_mine_ward_blade"
	if inventory.count_of(sword_id) == 0:
		inventory.add_item(sword_id, 1) # Keep system checks independent of map assertion failures.
	inventory.add_item(sword_id, 1)
	state.gold = 65
	var copies: Array[String] = []
	for dict: Dictionary in inventory.slots:
		if dict.item.item_id == sword_id:
			copies.append(String(dict.instance_id))
	var instance := copies.front() as String
	expect(inventory.equip_instance(instance), "equip exact copy")
	expect(not craft.temper(instance, "medicine", 1).ok, "wrong station rejected")
	expect(not craft.temper(instance, "blacksmith", 2).ok, "stale confirm rejected")
	dialogue.play(preload("res://data/dialogs/ch1_tutorial_duqingshan_after_sword.tres"))
	dialogue.choose(1)
	expect(dialogue.get("_current_node").node_id == &"road_hint", "optional dialogue offers an environmental hint")
	dialogue.advance()
	dialogue.choose(0)
	var millis := Time.get_ticks_msec()
	while not is_instance_valid(current_scene) or current_scene.scene_file_path != "res://scenes/shop.tscn":
		if Time.get_ticks_msec() - millis > 12000:
			break
		await process_frame
	var smith: Button
	if is_instance_valid(current_scene):
		await create_timer(0.5).timeout
		smith = current_scene.get_node_or_null("Panel/LifeSmithButton") as Button
	if expect(is_instance_valid(smith), "Linxi actual shop attaches upgrade button"):
		smith.pressed.emit()
		var life := root.get_node("LifeSkills")
		var crafting: Control = life.get("_panel")
		if expect(is_instance_valid(crafting), "actual crafting panel opens"):
			for rank in [1, 2, 3]:
				crafting.call("_ask_temper", instance)
				crafting.get("_confirm").call("_accept")
				var weapon := inventory.get_equipped(Equipment.Slot.WEAPON) as Equipment
				expect(weapon.forge_rank == rank, "UI temperature rank %d" % rank)
			crafting.call("close_panel")
	else:
		for rank in [1, 2, 3]:
			expect(craft.temper(instance, "blacksmith", rank).ok, "headless upgrade rank %d" % rank)
	var weapon := inventory.get_equipped(Equipment.Slot.WEAPON) as Equipment
	expect(weapon.forge_rank == 3 and weapon.atk_bonus == 20 and weapon.quality == Item.Quality.LEGENDARY, "stats and quality")
	expect(weapon.forge_affixes.size() in [1, 2] and (weapon.forge_affixes.size() == 1 or weapon.forge_affixes[0] != weapon.forge_affixes[1]), "one or two distinct affixes")
	expect(inventory.find_slot_by_instance(copies[1]).item.forge_rank == 0, "same-ID other copy untouched")
	expect(not craft.temper(instance, "blacksmith", 4).ok and state.gold == 0 and inventory.count_of(&"iron_ore") == 0, "cap and complete payment")
	var orange: Equipment = templ.make_weapon(weapon, 3, ["crit_damage"])
	expect(orange.quality == Item.Quality.LEGENDARY, "no quality over orange")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1647
	var outcomes := {}
	var effects := {}
	for n: int in range(128):
		var rolled: Array[String] = templ.roll_affixes(inventory.load_item_by_id(sword_id), rng)
		outcomes[rolled.size()] = true
		for effect: String in rolled: effects[effect] = true
	expect(outcomes.has(1) and outcomes.has(2) and effects.has_all(["bleed", "poison", "crit_damage"]), "random pool can generate both lengths and all three effects")
	var snapshot: Dictionary = inventory.to_dict()
	var affix_copy := weapon.forge_affixes.duplicate()
	inventory.from_dict(snapshot)
	weapon = inventory.get_equipped(Equipment.Slot.WEAPON)
	expect(weapon.forge_rank == 3 and weapon.forge_affixes == affix_copy and inventory.get_equipped_instance_id(Equipment.Slot.WEAPON) == instance, "save roundtrip uses in-memory fixture")
	expect(inventory.count_of(sword_id, false) == 1 and inventory.remove_item(sword_id, 1, false) and not inventory.remove_item(sword_id, 1, false) and inventory.get_equipped_instance_id(Equipment.Slot.WEAPON) == instance, "retail grouping cannot sell the upgraded copy by accident")
	for id in ["life_road_herb_02", "adventure_forest_herb_02", "life_forest_herb_02", "life_forest_herb_01", "adventure_forest_herb_01"]:
		expect(gather.collect(id).ok, "chapter 1 real herb catalog supplies " + id)
	for recipe in ["field_edge_pill", "field_focus_pill", "field_guard_powder"]:
		var result: Dictionary = craft.craft(recipe, 1, "medicine")
		expect(result.ok, "craft " + recipe + " " + String(result.message))
	expect(not inventory.use_item(&"field_focus_pill"), "cannot use combat pill as recovery on field")
	await verify_battle(inventory, instance)
	finish()

func verify_battle(inventory: Node, instance: String) -> void:
	# Affix fixture changes in-memory data only; random generation was checked above.
	var snapshot: Dictionary = inventory.to_dict()
	for entry: Dictionary in snapshot.slots:
		if String(entry.get("instance_id", "")) == instance:
			entry.forge_affixes = ["crit_damage", "poison"]
	inventory.from_dict(snapshot)
	state.player.speed = 1000
	state.player.agility = 180
	router.start_battle("zhuwei_cave_wolf", &"ch1_s4_zhuwei_beast_cave", Vector2(0.5, 0.82))
	if not expect(await wait_for(func(): return current_scene != null and current_scene.scene_file_path == "res://scenes/battle.tscn" and current_scene.get("_state") == 1, 18000), "real wolf king fight starts"):
		return
	var battle := current_scene
	var actor: BattleCombatant = battle._team_active_unit
	var enemy: BattleCombatant = battle._team_enemies[0]
	var skill: Skill
	for candidate: Skill in battle._skills_for_stats(actor.stats):
		if candidate.skill_id == &"basic_attack": skill = candidate
	if not expect(skill != null, "real battle skill available"):
		return
	var base_chance := 0.0
	for i: int in range(24):
		battle._calc_team_player_skill_damage(skill, actor, enemy)
		if battle.last_damage_breakdown.hit:
			base_chance = battle.last_damage_breakdown.crit_chance
			break
	expect(battle.apply_field_medicine("field_guard_powder") and battle._field_medicine_defense(actor) == 8, "guard powder feeds the battle defense path")
	expect(battle.apply_field_medicine("field_edge_pill"), "edge pill feeds attack modifiers")
	battle._calc_team_player_skill_damage(skill, actor, enemy)
	expect(is_equal_approx(battle.last_damage_breakdown.outgoing_multiplier, 1.15), "edge pill gives +15% damage")
	actor.status_effects.erase("field_edge")
	actor.status_effects.erase("field_guard")
	battle._open_battle_inventory()
	var panel: Control = battle.get("_battle_inventory_panel")
	expect(panel.call("_use_item_now", &"field_focus_pill"), "battle inventory consumes actual pill")
	expect(inventory.count_of(&"field_focus_pill") == 0 and int(actor.status_effects.get("field_focus", 0)) == 2, "after consuming turn, two rounds remain")
	var crit_seen := false
	var boosted := 0.0
	for i: int in range(100):
		battle._calc_team_player_skill_damage(skill, actor, enemy)
		if battle.last_damage_breakdown.hit:
			boosted = battle.last_damage_breakdown.crit_chance
		if battle.last_damage_breakdown.was_critical:
			crit_seen = is_equal_approx(battle.last_damage_breakdown.requested_crit_multiplier, BattleFormula.CRIT_MULT + 0.20)
			break
	expect(is_equal_approx(boosted - base_chance, 0.15) and crit_seen, "damage breakdown sees 15pp potion and +0.20 weapon crit multiplier")
	for i: int in range(100):
		battle._team_apply_weapon_special(actor, enemy)
		if enemy.status_effects.has("poison"): break
	expect(int(enemy.status_effects.get("poison", 0)) == 2, "forged poison lands for two rounds")
	battle._team_apply_action_end_status(actor)
	battle._team_apply_action_end_status(actor)
	expect(int(actor.status_effects.get("field_focus", 0)) == 0, "focus expires on schedule")
