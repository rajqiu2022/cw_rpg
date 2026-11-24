extends "res://build/inn_ui_cave_20261109/live.gd"

const YANMEN := &"openworld_yanmen_hidden_cave"

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router=root.get_node("SceneRouter")
	state=root.get_node("GameState")
	quests=root.get_node("QuestManager")
	dialogue=root.get_node("DialogPlayer")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	router.reset_for_new_game()
	for stage in OS.get_cmdline_user_args():
		match stage:
			"cave": await cave()
			"yanmen": await yanmen()
			"relief": await relief()
	finish()

func finish() -> void:
	print("STORY_ENEMIES_LIVE checks=",checks," failures=",failures)
	quit(1 if failures else 0)

func shot(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/story_enemies_20261109/"+id+".png")

func check_field_animation(npc: NPCNode) -> bool:
	if not expect(is_instance_valid(npc) and npc.sprite.hframes == 4 and npc.sprite.texture.resource_path.contains(npc.npc_id+"/ready.png"),"four frame unique field sprite"): return false
	var seen: Dictionary = {}
	return expect(await wait_for(func():
		if not is_instance_valid(npc): return false
		seen[npc.sprite.frame] = true
		return seen.size()==4
	,1600),"real field idle plays all four frames")

func check_battle_art(battle: Node, ids: Array) -> void:
	var units: Array=battle.get("_team_enemies")
	var formation: BattleFormationView = battle.get("formation_view")
	expect(units.size()==ids.size(),"expected enemy team size")
	for i in mini(units.size(),ids.size()):
		var actor := formation.get_actor(units[i].unit_id)
		if not expect(is_instance_valid(actor),"battle actor exists for "+ids[i]):continue
		for action in ["ready", "move", "attack", "hit", "defeat"]:
			var frames: Array = actor.get(action+"_frames")
			expect(frames.size()==4 and frames.all(func(f):return f is AtlasTexture and f.atlas.resource_path.contains(ids[i]+"/")),"dedicated "+ids[i]+" "+action)
		var art: TextureRect = actor.get("artwork")
		var first := art.texture
		expect(await wait_for(func():return is_instance_valid(art) and art.texture!=first,1600),"actual ready texture changes for "+ids[i])
		var image: Image = actor.ready_frames[0].get_image()
		print("FRAME ",ids[i]," texture ",actor.ready_frames[0].get_size()," image ",image.get_size()," used ",image.get_used_rect())
		var player: BattleCombatant = battle.get("_team_allies")[0]
		var target := formation.get_actor(player.unit_id)
		var seen: Dictionary = {}
		var captured := false
		var ticks := Time.get_ticks_msec() + 1850
		actor.play_stationary_attack.call_deferred(target,true)
		while Time.get_ticks_msec() < ticks:
			var pose := actor.attack_frames.find(art.texture)
			if pose >= 0:
				seen[pose] = true
			if pose == 2 and not captured:
				captured = true
				await shot("strike_"+ids[i])
			if seen.size()==4 and actor.ready_frames.has(art.texture): break
			await process_frame
		expect(seen.size()==4 and actor.ready_frames.has(art.texture),"attack plays four frames and returns to ready for "+ids[i])

func authored_guard_line(enemy: String) -> bool:
	for step in 4:
		var node: DialogNode = dialogue.get("_current_node")
		if not is_instance_valid(node): break
		if node.portrait_path.ends_with(enemy+"/portrait.png"):
			await shot("portrait_"+enemy)
			return expect(true, "matching portrait shown for "+enemy)
		if node.has_choices(): break
		dialogue.advance()
		await process_frame
	return expect(false, "matching portrait shown for "+enemy)

func yanmen() -> void:
	var field := await enter(YANMEN)
	if field==null: return
	await settle(field)
	var guard: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id=="openworld_yanmen_cave_guard":guard=npc
	if not await check_field_animation(guard): return
	await position_at(field,guard.global_position+Vector2(0,47))
	await shot("04_yanmen")
	state.player.speed=1000
	state.player.agility=180
	await press_space()
	if not expect(await wait_for(func():return dialogue.is_playing() and dialogue.get("_current_script").dialog_id==YANMEN_GUARD,3500),"Yanmen guard is interactable"):return
	if not await authored_guard_line("openworld_yanmen_cave_guard"):return
	dialogue.advance()
	if not await wait_battle(): return
	await check_battle_art(current_scene, ["openworld_yanmen_cave_guard", "openworld_snow_raider"])
	await shot("05_yanmen_battle")

const YANMEN_GUARD := &"openworld_yanmen_cave_guard"

func wait_battle() -> bool:
	return expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn" and current_scene.get("_state")==1),"battle reaches actual turn menu")

func relief() -> void:
	state.player.speed=1000
	state.player.agility=180
	var enemies: Array[StringName] = [&"ch5_relief_road_raider"]
	router.start_encounter(enemies,&"ch5_s1_relief_road")
	if not await wait_battle(): return
	await check_battle_art(current_scene, ["ch5_relief_road_raider"])
	await shot("06_relief_battle")

func cave() -> void:
	state.set_flag(&"master_training_done",true)
	state.set_flag(&"defeated_bandit_mountain",true)
	state.set_flag(&"rumour_bandit_cave",true)
	quests.accept(CASE)
	var road:=await enter(&"ch1_s1_road")
	if road==null:return
	var field:=await take(road,CAVE)
	if field==null:return
	expect(area(field,"bandit_cave_banner")==null,"road victory does not unlock cave goods")
	var guard: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id=="bandit_cave_guard":guard=npc
	if not expect(is_instance_valid(guard),"actual cave guard present"):return
	if not await check_field_animation(guard): return
	var world: Node2D = field.get("world_container")
	var size: Vector2 = field.get("_screen_size")
	var probe := await position_at(field, world.to_global(Vector2(.337,.645)*size))
	check_clear(probe, "open passage beside adult bed")
	var bed: StaticBody2D
	for body: StaticBody2D in field.get("_collision_bodies"):
		if body.name == &"Collision_bed_end_footprint": bed=body
	if not expect(is_instance_valid(bed), "real bed body exists"):return
	expect(not field._is_inside_walkable_screen(bed.global_position), "bed navigation rejects the footprint")
	probe = await position_at(field,world.to_global(Vector2(.355,.624)*size))
	Input.action_press(&"move_left")
	await create_timer(.70).timeout
	Input.action_release(&"move_left")
	var blocked_x := world.to_local(probe.global_position).x / size.x
	expect(blocked_x >= .309 and blocked_x < .355, "held movement stops at the visible bed end: "+str(blocked_x))
	probe = await position_at(field,world.to_global(Vector2(.355,.710)*size))
	Input.action_press(&"move_left")
	await create_timer(.72).timeout
	Input.action_release(&"move_left")
	var clear_x := world.to_local(probe.global_position).x / size.x
	expect(clear_x < .29, "held movement walks around the bed: "+str(clear_x))
	await position_at(field, world.to_global(Vector2(.341,.684)*size))
	await shot("01_cave")
	var actor:=await position_at(field,guard.global_position+Vector2(0,47))
	check_clear(actor,"guard approach")
	var foot:=actor.global_position
	state.player.speed=1000
	state.player.agility=180
	await press_space()
	if not expect(await wait_for(func():return dialogue.is_playing() and dialogue.get("_current_script").dialog_id==&"interior_bandit_cave_guard",3500),"guard conversation opens with Space"):return
	await authored_guard_line("bandit_cave_guard")
	for _i in range(4):
		if not dialogue.is_playing() or dialogue.get("_current_node").has_choices():break
		dialogue.advance()
		await process_frame
	expect(dialogue.is_playing() and dialogue.get("_current_node").has_choices(),"guard offers explicit choice")
	dialogue.choose(1)
	expect(await wait_for(func():return not dialogue.is_playing() and current_scene==field,1600),"declining challenge leaves the party in cave")
	await check_field_animation(guard)
	await press_space()
	if not await wait_for(func():return dialogue.is_playing(),2000):return
	for _i in range(4):
		if not dialogue.is_playing() or dialogue.get("_current_node").has_choices():break
		dialogue.advance()
		await process_frame
	dialogue.choose(0)
	await process_frame
	dialogue.advance()
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn" and current_scene.get("_state")==1),"real cave fight"):return
	var battle:=current_scene
	var units: Array=battle.get("_team_enemies")
	if not expect(units.size()==1,"one cave guard in battle"):return
	await check_battle_art(battle, ["bandit_cave_guard"])
	await shot("02_cave_battle")
	units[0].stats.hp=1
	var acting: BattleCombatant=battle._team_active_unit
	var skills: Array=battle._skills_for_stats(acting.stats)
	for i in skills.size():
		if skills[i].skill_id==&"basic_attack":
			battle._team_player_action_skill_use(i,units[0].unit_id)
			break
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/result_victory.tscn",16000),"genuine battle victory screen"):return
	current_scene.get_node("%BtnContinue").pressed.emit()
	if not expect(await wait_for(func():return current_scene!=null and current_scene.has_method("get_field_loading_state") and router.get_current_field_id()==CAVE and current_scene.get_field_loading_state().get("complete",false) and not root.get_node("LoadingManager").get("_transition_active"),16000),"victory returns to cave"):return
	field=current_scene
	actor=field.get("_player")
	expect(actor.global_position.distance_to(foot)<1.0,"victory restores encounter feet")
	expect(state.flags.get("defeated_bandit_cave_guard",false),"cave-specific win flag")
	await settle(field)
	var again := false
	for npc: NPCNode in field.get("_npc_nodes"):
		again = again or npc.npc_id=="bandit_cave_guard"
	expect(not again,"no repeat story battle")
	var crate:=area(field,"bandit_cave_banner")
	if crate!=null:
		await position_at(field,crate.global_position)
		expect(await wait_for(func():
			var current := area(field,"bandit_cave_banner")
			if not is_instance_valid(current):return false
			var marker := current.get_node_or_null("EvidencePrompt") as Label
			return marker!=null and marker.visible
		,1800),"evidence shows the contextual prompt at the reachable foot")
		await shot("03_evidence")
	await play_at(field,"bandit_cave_banner",&"interior_bandit_cave_banner",[])
	expect(state.flags.get("clue_bandit_cave_mist_mark",false) and quests.is_completed(CASE),"crate evidence completes the actual quest")
	await take(field,&"ch1_s1_road")
