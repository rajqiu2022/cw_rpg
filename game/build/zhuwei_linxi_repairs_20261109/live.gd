extends "res://build/inn_ui_cave_20261109/live.gd"

const FOREST := &"ch1_s3_zhuwei_forest"
var progress_events := 0

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
	root.get_node("EventBus").quest_progressed.connect(func(id: StringName):
		if id == MAIN: progress_events += 1
	)
	await smith_and_steps()
	await inquiry()
	await cave_glow()
	finish()

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://"+name+".png")

func npc_by_id(field: Node, id: String) -> NPCNode:
	for npc: NPCNode in field.get("_npc_nodes"):
		if is_instance_valid(npc) and not npc.is_queued_for_deletion() and (npc.npc_id == id or npc.npc_id.begins_with(id+"_")):
			return npc
	return null

func talk(field: Node, npc: NPCNode, id: StringName, choice := -1, approach := Vector2(0,55)) -> bool:
	if not expect(is_instance_valid(npc),"present for "+String(id)): return false
	await position_at(field,npc.global_position + approach)
	await create_timer(0.25).timeout
	print("TALK target=",npc.npc_id," pos=",npc.global_position," in_range=",npc._in_range," all_players=",get_nodes_in_group("player").map(func(p):return p.global_position)," near=",field.get("_npc_nodes").filter(func(n):return n._in_range).map(func(n):return n.npc_id))
	await press_space()
	if not expect(await wait_for(func():return dialogue.is_playing() and dialogue.get("_current_script").dialog_id==id,2500),"real Space "+String(id)):
		var actual := dialogue.get("_current_script") as DialogScript
		print("DIALOG observed=",actual.dialog_id if actual!=null else &"none"," npc resolved=",npc._resolve_dialog_id()," player=",field.get("_player").global_position," npc=",npc.global_position)
		return false
	for i in range(15):
		if not dialogue.is_playing(): break
		if dialogue.get("_current_node").has_choices():
			if choice<0: return true
			dialogue.choose(choice)
		else:
			dialogue.advance()
		await process_frame
	expect(not dialogue.is_playing(),"dialogue closes "+String(id))
	await create_timer(0.20).timeout
	return true

func hold(code: Key, seconds: float) -> void:
	var ev := InputEventKey.new()
	ev.keycode=code
	ev.physical_keycode=code
	ev.pressed=true
	Input.parse_input_event(ev)
	await create_timer(seconds).timeout
	ev=ev.duplicate()
	ev.pressed=false
	Input.parse_input_event(ev)
	await physics_frame

func steps(field: Node, x: float, top: float, label: String) -> void:
	var town: Node2D = field.get("native_town")
	var player:=await position_at(field,Vector2(x,top+205))
	await hold(KEY_W,1.45)
	expect(town.terrain.actor_level==1 and player.global_position.y<top-20.0,label+" ascent "+str(player.global_position))
	await hold(KEY_S,1.45)
	expect(town.terrain.actor_level==0 and player.global_position.y>top+150.0,label+" descent "+str(player.global_position))

func smith_and_steps() -> void:
	var field:=await enter(&"linxi_tutorial")
	if field==null: return
	await settle(field)
	var du:=npc_by_id(field,"duqingshan")
	if not expect(is_instance_valid(du),"Du remains the active NPC"):return
	var town: Node2D=field.get("native_town")
	expect(town.has_node("Town/DuSmithy/Body/Shape") and town.has_node("Town/DuAnvil/Body/Shape"),"forge and anvil have physical feet")
	await position_at(field,du.global_position+Vector2(0,82))
	var swing:=du.get_node_or_null("SmithingAnimation") as Sprite2D
	if expect(swing!=null and swing.visible,"Du uses smithing frames"):
		var previous:=swing.texture
		expect(await wait_for(func():return swing.texture!=previous,1350),"hammer animation advances")
		await shot("linxi_du_smithy")
		await position_at(field,du.global_position + Vector2(0,80))
		await create_timer(0.25).timeout
		await press_space()
		if expect(await wait_for(func():return dialogue.is_playing() and dialogue.get("_current_script").dialog_id==StringName(du.dialog_id),2000),"Du original conversation still plays"):
			await process_frame
			expect(not swing.visible and du.sprite.self_modulate.a==1.0,"smith switches back to conversation pose")
		await settle(field)
	await steps(field,2050+67,1100,"Linxi bedroom stair, near right tread")

func inquiry() -> void:
	state.set_flag(&"master_training_done",true)
	state.set_flag(&"entered_zhuwei_village",true)
	quests.accept(&"q_ch1_main_training")
	quests.complete(&"q_ch1_main_training")
	var village:=await enter(VILLAGE)
	if village==null:return
	await settle(village)
	quests.accept(&"q_ch1_side_08_mountain_patrol")
	await settle(village)
	await steps(village,2800+67,1000,"Zhuwei original east stair")
	await steps(village,3370,1000,"Zhuwei new east footpath")
	await position_at(village,Vector2(3370,1190))
	await shot("zhuwei_east_path")
	var gate:=forest_gate(village)
	expect(gate!=null and gate.is_locked and gate.exit_label.contains("村口守卫"),"locked gate identifies missing source")
	if not await talk(village,npc_by_id(village,"guard"),&"ch1_s2_guard"):return
	if not await talk(village,npc_by_id(village,"patrol_scout"),&"ch1_s2_scout_main_clue",-1,Vector2(-50,20)):return
	expect(state.get_flag(&"zhuwei_scout_clue"),"active side quest does not suppress the missing main clue")
	var inn_field:=await take(village,&"interior_inn_hall")
	if inn_field==null:return
	var before:=progress_events
	if not await talk(inn_field,npc_by_id(inn_field,"innkeeper_inside"),&"ch1_s2_inn_keeper"):return
	expect(progress_events==before+1 and state.get_flag(&"zhuwei_inn_clue"),"first inn talk advances once")
	if not await talk(inn_field,npc_by_id(inn_field,"innkeeper_inside"),&"ch1_s2_inn_keeper_repeat"):return
	expect(progress_events==before+1,"repeat inn talk does not advance again")
	village=await take(inn_field,VILLAGE)
	if village==null:return
	gate=forest_gate(village)
	expect(gate!=null and gate.is_locked and gate.exit_label.contains("汇报"),"all clues collected, report shown")
	if not await talk(village,npc_by_id(village,"guard"),&"ch1_s2_guard_report"):return
	expect(quests.is_completed(MAIN) and state.get_flag(&"zhuwei_village_inquiry_done"),"guard actually completes inquiry")
	var forest:=await take(village,FOREST)
	if forest!=null: await take(forest,VILLAGE)

func forest_gate(field: Node) -> ExitZone:
	for zone: ExitZone in field.get("_exit_nodes"):
		if not zone.is_queued_for_deletion() and zone.destination_name == "前往后山密林":
			return zone
	return null

func cave_glow() -> void:
	state.set_flag(&"rumour_bandit_cave",true)
	quests.accept(CASE)
	var field:=await enter(CAVE)
	if field==null:return
	await settle(field)
	var guard:=npc_by_id(field,"bandit_cave_guard")
	expect(guard!=null and is_equal_approx(guard.sprite_scale*663.0,148.0),"cave bandit scales to 148 at original feet")
	expect(area(field,"bandit_cave_banner")==null,"unavailable cargo does not prompt")
	state.set_flag(&"defeated_bandit_cave_guard",true)
	await settle(field)
	var crate:=area(field,"bandit_cave_banner")
	if not expect(crate!=null,"victory unlocks cargo"):return
	await position_at(field,crate.global_position)
	var prop:=crate.get_meta("highlight_node",null) as Sprite2D
	expect(prop!=null and prop.name==&"SceneObject_banner_and_goods" and prop.material is ShaderMaterial and not crate.has_node("EvidencePrompt"),"physical prop glows without a label")
	if prop!=null and prop.material is ShaderMaterial:
		expect(await wait_for(func():
			return is_instance_valid(prop) and prop.material is ShaderMaterial and is_equal_approx(float(prop.material.get_shader_parameter("pulse")),1.0)
		,1200),"nearby prop uses the full pulse")
	await shot("bandit_cave_cargo")
	await play_at(field,"bandit_cave_banner",&"interior_bandit_cave_banner",[])
	await settle(field)
	expect(state.get_flag(&"clue_bandit_cave_mist_mark") and area(field,"bandit_cave_banner")==null,"cargo used once")
