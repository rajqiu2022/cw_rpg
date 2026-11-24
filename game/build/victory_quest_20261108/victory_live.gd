extends "res://build/quest_map_audit_20261108/huilan_live.gd"

const FIELD := &"linxi_tutorial"
const TRACK := "res://art/audio/bgm/bgm_victory_salute_20261108.wav"

func track_is_playing(audio: Node) -> bool:
	var player:=audio.get_node_or_null("MusicStingPlayer") as AudioStreamPlayer
	return player!=null and player.playing and player.stream!=null and player.stream.resource_path==TRACK

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router=root.get_node("SceneRouter")
	state=root.get_node("GameState")
	state.reset_for_new_game()
	router.reset_for_new_game()
	var inventory:=root.get_node("Inventory")
	inventory.reset_for_new_game()
	var audio:=root.get_node("AudioManager")
	var track:=load(TRACK) as AudioStreamWAV
	expect(track!=null and absf(track.get_length()-3.72)<0.01 and track.stereo and track.loop_mode==AudioStreamWAV.LOOP_DISABLED,"native stereo non-looping fanfare")
	var field:=await enter(FIELD)
	if field==null:
		finish()
		return
	var initial_foot: Vector2=field.get("_player").global_position
	var spawn: Vector2=initial_foot/Vector2(field.get("_world_size"))
	for trial: Array in [[&"seven_star_sword","seven_star_sword"],[&"golden_hoop_staff","golden_hoop_staff"],[&"jinhe_duanyue_blade","jinhe_duanyue_blade"],[&"immortal_gauntlets","immortal_gauntlets"],[&"","unarmed"]]:
		var item: StringName=trial[0]
		if "unarmed" in OS.get_cmdline_user_args() and item!=&"": continue
		if item==&"": inventory.unequip(Equipment.Slot.WEAPON)
		else: expect(inventory.add_item(item) and inventory.equip(item),"equip "+String(item))
		state.player.speed=1000
		state.player.agility=180
		if item==&"":
			router.start_sparring(&"victory_qa", "练习木人", "thug_lone", 2, 0, FIELD, spawn)
		else:
			router.start_battle("thug_lone",FIELD,spawn)
		if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn" and current_scene.get("_state")==1,14000),"battle ready "+trial[1]): break
		var battle:=current_scene
		var actor: BattleActor=battle.formation_view.get_actor(&"player")
		var runtime:=root.get_node("LayeredAppearanceRuntime")
		var entry: Dictionary=runtime.actors.get(actor.get_instance_id(),{})
		if not expect(entry.has("pose"),"formal layered protagonist"): break
		var pose: Node2D=entry.pose
		var enemy: BattleCombatant=battle._team_enemies[0]
		enemy.stats.hp=1
		var skills: Array=battle._skills_for_stats(battle._team_active_unit.stats)
		for index in skills.size():
			if skills[index].skill_id==&"basic_attack":
				battle._on_skill_selected(index)
				break
		if not expect(await wait_for(func():return is_instance_valid(actor) and actor.victory_frame>=0 and pose.current_clip=="victory",9000),"real killing blow starts victory "+trial[1]):
			print("NO_SALUTE ",current_scene.scene_file_path," hp=",enemy.stats.hp," active=",battle._team_active_unit.unit_id if is_instance_valid(battle) else &""," state=",battle._state if is_instance_valid(battle) else -1)
			break
		var foot: Vector2=actor.position
		var request: int=audio.get("_music_sting_request_id")
		expect(track_is_playing(audio),"fanfare starts with salute")
		for frame in range(4):
			if not expect(await wait_for(func():return is_instance_valid(actor) and actor.victory_frame==frame and pose.current_frame==frame,2000),"salute frame "+str(frame)): break
			expect(actor.position.is_equal_approx(foot) and pose.current_weapon==trial[1],"planted feet and current equipment")
			if item in [&"seven_star_sword",&"golden_hoop_staff",&"jinhe_duanyue_blade"]:
				expect(pose.socket.visible and pose.hand.visible and not pose.current_sheathed and not pose.current_back_carried,"weapon drawn in right hand")
			elif item==&"immortal_gauntlets":
				expect(pose.gauntlets.visible and pose.gauntlets.hand_sprites[0].visible and pose.gauntlets.hand_sprites[1].visible,"both gauntlets shown")
			else:
				expect(not pose.socket.visible and not pose.hand.visible,"unarmed salute")
			if frame==2:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://build/victory_quest_20261108/salute_"+trial[1]+".png")
		if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/result_victory.tscn",6000),"normal victory results"): break
		expect(audio.get("_music_sting_request_id")==request and track_is_playing(audio),"result continues original music request")
		expect((router.get_result_payload().get("battle_mode", &"")==&"sparring")== (item==&""),"correct result mode")
		current_scene.get_node("%BtnContinue").pressed.emit()
		if not expect(await wait_for(func():return current_scene!=null and current_scene.has_method("get_field_loading_state") and router.get_current_field_id()==FIELD and current_scene.get_field_loading_state().get("complete",false) and not root.get_node("LoadingManager").get("_transition_active")),"continue returns to Linxi"): break
		expect(current_scene.get("_player").global_position.distance_to(initial_foot)<1.0,"exact original feet")
	finish()

func finish() -> void:
	print("VICTORY_LIVE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
