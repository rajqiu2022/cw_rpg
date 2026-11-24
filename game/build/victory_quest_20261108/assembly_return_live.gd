extends "res://build/quest_map_audit_20261108/huilan_live.gd"

const WUDANG := &"openworld_wudang_gate"
const ASSEMBLY := &"ch3_s1_wulin_assembly"
const MAIN := &"q_ch3_main_00_assembly_clues"

func finish() -> void:
	print("ASSEMBLY_LIVE checks=",checks," failures=",failures)
	quit(1 if failures else 0)

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
	var field:=await enter(WUDANG)
	if field==null:
		finish()
		return
	var entrance: ExitZone
	for zone: ExitZone in field.get("_exit_nodes"):
		if StringName(zone.target_scene_id)==ASSEMBLY: entrance=zone
	if not expect(entrance!=null and not entrance.is_locked,"assembly arrow without chapter lock"):
		finish()
		return
	var assembly_gate_foot:=entrance.global_position
	var town: Node=field.get("native_town")
	var player: Player=field.get("_player")
	player.global_position=entrance.global_position
	town.terrain.reset_actor(town.terrain.level_at(player.position))
	expect(await wait_for(func(): return entrance.get("_in_range"),2500),"assembly arrow physically in range")
	await press_space()
	if not expect(await wait_for(func():
		return router.get_current_field_id()==ASSEMBLY and current_scene!=null and current_scene.get("_current_scene")!=null and current_scene.get("_current_scene").scene_id==ASSEMBLY and not root.get_node("LoadingManager").get("_transition_active")
	),"real Space arrives at assembly"):
		finish()
		return
	field=current_scene
	expect(not dialogue.is_playing() and not quests.is_active(MAIN) and not state.flags.get("seen_ch3_assembly",false),"early entry leaves chapter three untouched")
	await play_at(field,"legacy_hotspot_3",&"huilan_openworld_board",[1])
	expect(state.flags.get("huilan_yielding_position_understood",false) and quests.is_active(QUEST),"chess progresses open-world quest before chapter three")
	expect(not state.flags.get("chapter3_started",false),"side quest does not start main chapter")
	await create_timer(0.60).timeout
	var back: ExitZone
	var world_exit:=false
	for zone: ExitZone in field.get("_exit_nodes"):
		if StringName(zone.target_scene_id)==WUDANG:back=zone
		if zone.action=="world_map":world_exit=true
	expect(world_exit,"original separate world exit remains")
	if not expect(is_instance_valid(back) and not back.is_locked,"assembly has a matching return"):
		finish()
		return
	player=field.get("_player")
	player.global_position=back.global_position
	expect(await wait_for(func():return back.get("_in_range"),2500),"return arrow reachable")
	await press_space()
	if not expect(await wait_for(func():
		return router.get_current_field_id()==WUDANG and current_scene!=null and current_scene.get("_current_scene")!=null and current_scene.get("_current_scene").scene_id==WUDANG and not root.get_node("LoadingManager").get("_transition_active")
	),"real Space returns to Wudang"):
		finish()
		return
	field=current_scene
	player=field.get("_player")
	expect(player.global_position.distance_to(assembly_gate_foot)<1.0,"same door foot at Wudang")
	state.set_flag(&"chapter2_complete",true)
	await physics_frame
	await physics_frame
	await press_space()
	if not expect(await wait_for(func():
		return router.get_current_field_id()==ASSEMBLY and current_scene!=null and current_scene.get("_current_scene")!=null and current_scene.get("_current_scene").scene_id==ASSEMBLY and not root.get_node("LoadingManager").get("_transition_active")
	),"the same Wudang entrance re-enters assembly"):
		finish()
		return
	field=current_scene
	if field!=null:
		expect(await wait_for(func(): return dialogue.is_playing() and dialogue.get("_current_script").dialog_id==&"ch3_assembly_intro",2000),"later entry still plays main introduction")
		for i in range(12):
			if not dialogue.is_playing():break
			dialogue.advance()
		expect(quests.is_active(MAIN),"chapter three main quest accepted normally")
	finish()
