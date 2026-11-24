extends "res://build/zhuwei_linxi_repairs_20261109/live.gd"

const PORTER := "zhuwei_huilan_porter"
const GATE_LABEL := "后山密林 · 暂时封锁"
const MARKET := &"ch2_s1_zhuwei_market"

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
	state.set_flag(&"master_training_done",true)
	state.set_flag(&"entered_zhuwei_village",true)
	quests.accept(&"q_ch1_main_training")
	quests.complete(&"q_ch1_main_training")
	var village:=await enter(VILLAGE)
	if village==null:
		finish()
		return
	await settle(village)
	await check_seal(village)
	await settle(village)
	await talk(village,npc_by_id(village,"guard"),&"ch1_s2_guard")
	quests.accept(&"q_ch1_side_08_mountain_patrol")
	await settle(village)
	await talk(village,npc_by_id(village,"patrol_scout"),&"ch1_s2_scout_main_clue",-1,Vector2(-50,20))
	var inn:=await take(village,&"interior_inn_hall")
	if inn!=null:
		await talk(inn,npc_by_id(inn,"innkeeper_inside"),&"ch1_s2_inn_keeper")
		village=await take(inn,VILLAGE)
	if village!=null:
		expect(state.get_flag(&"zhuwei_guard_briefed") and state.get_flag(&"zhuwei_scout_clue") and state.get_flag(&"zhuwei_inn_clue"),"three clues gathered by dialogue")
		await check_seal(village)
		await settle(village)
		await talk(village,npc_by_id(village,"guard"),&"ch1_s2_guard_report")
		expect(state.get_flag(&"zhuwei_village_inquiry_done"),"guard grants clearance")
		var forest:=await take(village,FOREST)
		if forest!=null: village=await take(forest,VILLAGE)
	if not is_instance_valid(village):
		finish()
		return
	await inspect_houses(village)
	var porter:=npc_by_id(village,PORTER)
	if expect(porter!=null and porter.sprite.visible and porter.sprite.texture!=null,"porter is visible in the village"):
		expect(area(village,BALANCE)==null,"no second, invisible balance interaction")
		await position_at(village,porter.position+Vector2(-120,65))
		await shot("02-porter")
		if await talk(village,porter,&"huilan_openworld_balance",-1):
			dialogue.choose(0)
			expect(not state.get_flag(&"huilan_balance_understood"),"wrong answer does not record the clue")
			dialogue.advance()
			dialogue.choose(1)
			for i in range(6):
				if not dialogue.is_playing():break
				dialogue.advance()
				await process_frame
			await settle(village)
			expect(state.get_flag(&"huilan_balance_understood") and quests.is_active(QUEST),"correct answer starts the quest and records the clue")
			expect(quests.get_progress_record_texts(QUEST).any(func(line:String):return line.contains("竹尾扁担")),"journal shows the shoulder balance clue")
			expect(area(village,TRIAL)==null,"no finale with only one clue")
			await talk(village,npc_by_id(village,PORTER),&"huilan_openworld_balance_done")
			for flag: StringName in [&"huilan_echo_understood",&"huilan_bell_counterforce_understood",&"huilan_yielding_position_understood",&"huilan_water_rule_understood"]:
				state.set_flag(flag,true)
			await settle(village)
			if await play_at(village,TRIAL,&"huilan_openworld_final_trial",[1,0]):
				expect(quests.is_completed(QUEST),"cart trial closes the quest")
				expect(state.player.skills.has(&"huilan_redirecting_art") or state.pending_skill_unlocks.has(&"huilan_redirecting_art"),"actual skill reward learned or queued")
	state.set_flag(&"chapter1_complete",true)
	state.set_flag(&"seen_ch2_zhuwei_intro",true)
	var market:=await enter(MARKET)
	if market!=null:
		await settle(market)
		porter=npc_by_id(market,PORTER)
		expect(porter!=null and porter.sprite.visible and area(market,BALANCE)==null,"chapter two market retains the visible porter")
		if porter!=null:
			var actor:=await position_at(market,porter.position+Vector2(0,42))
			check_clear(actor,"market porter approach")
			await talk(market,porter,&"huilan_openworld_balance_done",-1,Vector2(0,42))
	finish()

func check_seal(field: Node) -> void:
	var gate:ExitZone
	for zone:ExitZone in field.get("_exit_nodes"):
		if zone.destination_name==GATE_LABEL:
			gate=zone
			break
	if not expect(gate!=null and gate.is_locked and gate.target_scene_id.is_empty(),"closed gate displays generic warning and has no target"):return
	var actor:=await position_at(field,gate.position)
	check_clear(actor,"closed gate approach")
	expect(gate.prompt.visible and gate.prompt.text==GATE_LABEL,"closure visible before pressing Space")
	await press_space()
	await create_timer(.22).timeout
	expect(current_scene==field and not dialogue.is_playing(),"Space at closed gate does not travel or open a dialogue")
	var toast: Label=field.get("_feedback_toast")
	expect(toast!=null and toast.visible and toast.text=="后山有危险，暂时封锁，无法进入。","Space gives generic warning")
	var town:Node=field.get("native_town")
	expect(not town.show_details,"no scenery detail panel on gate interaction")
	town.show_details=false
	await shot("01-sealed-gate")

func inspect_houses(field: Node) -> void:
	var town:Node2D=field.get("native_town")
	for name in ["EastLaneHouse","BackHouse0","WestLaneHouse1","WestLaneHouse2","SouthLaneHouse1"]:
		var house:=town.get_node("Town/"+name) as Node2D
		var art:=house.get_node("Art") as Sprite2D
		var shape:=house.get_node("Body/Shape") as CollisionPolygon2D
		var rect:Rect2=house.get_meta("visual_rect")
		expect(art.scale.x==art.scale.y and rect.size.y>350,"native aspect and usable footprint "+name)
		var actor:=await position_at(field,house.position+Vector2(0,70))
		check_clear(actor,"front lane "+name)
		actor=await position_at(field,shape.to_global(Vector2(0,-24)))
		var registry:Script=load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
		expect(not registry.actor_shape_clear(actor),"solid interior "+name)
	await position_at(field,Vector2(3540,1710))
	await shot("03-east-timber-house")
