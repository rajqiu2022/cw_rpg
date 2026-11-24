extends "res://build/victory_quest_20261108/story_live.gd"

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
			"lanxi": await lanxi()
			"tang": await tang()
			"road": await road()
	finish()

func shot(key: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/user_fixes_20261109/"+key+".png")

func lanxi() -> void:
	var field:=await enter(&"openworld_lanxi_zhai")
	if field==null:return
	var town: Node=field.get("native_town")
	var hero: Player
	for id in ["PlazaCraftsman","WestWeaver","DyeWorker","CreekVendor","ClothVendor","UpperResident","Farmer","LaneWorker"]:
		var resident:=town.get_node("Town/"+id) as Node2D
		hero=await position_at(field,resident.global_position)
		if id=="PlazaCraftsman":
			var art:=resident.get_node("Art") as Sprite2D
			var click:=InputEventMouseButton.new()
			click.button_index=MOUSE_BUTTON_LEFT
			click.pressed=true
			click.position=art.get_global_transform_with_canvas()*art.get_rect().get_center()
			Input.parse_input_event(click)
			click=click.duplicate()
			click.pressed=false
			Input.parse_input_event(click)
		else:
			await press_space()
		var target_id:=StringName("lanxi_"+String(id).to_snake_case())
		expect(await wait_for(func():return dialogue.is_playing() and dialogue.get("_current_script").dialog_id==target_id,1500),"normal Lanxi dialogue "+id)
		expect(not town.show_details,"preview card stays hidden")
		if id=="PlazaCraftsman":await shot("lanxi_dialogue")
		if dialogue.is_playing():dialogue.advance()
		await process_frame
	var terrain: Node=town.get("terrain")
	hero=await position_at(field,Vector2(2750,1110))
	check_clear(hero,"western lane approach")
	await hold_key(KEY_D,0.91)
	expect(hero.position.x>2990 and absf(hero.position.y-1110)<6 and terrain.actor_level==1,"walk east through former block on the same terrace")
	check_clear(hero,"lane east end")
	await shot("lanxi_lane_after")
	await hold_key(KEY_A,0.84)
	expect(hero.position.x<2820 and absf(hero.position.y-1110)<6 and terrain.actor_level==1,"walk back west through the lane")
	for id in ["RaisedMarket3","RaisedMarket4"]:
		var bridge: Node2D=town.get_node("Town/"+id)
		expect(bridge.has_node("FrontRailArt") and bridge.has_node("FrontRail/Outline"),"visible and physical front rail")
		hero=await position_at(field,bridge.global_position)
		var y:=hero.position.y
		var event:=InputEventKey.new()
		event.physical_keycode=KEY_S
		event.pressed=true
		Input.parse_input_event(event)
		await create_timer(.45).timeout
		event=event.duplicate()
		event.pressed=false
		Input.parse_input_event(event)
		expect(hero.position.y<y+21.0,"cannot walk off the boardwalk")
		await shot("rail_"+id)

	for approach in [Vector2(0,35),Vector2(-65,45),Vector2(60,45),Vector2(0,-60)]:
		if town.in_hall:break
		await position_at(field,town.DOOR+approach)
		print("WEAVING DOOR ",town.DOOR," foot ",hero.global_position," floor ",terrain.actor_level)
		await press_space()
		await wait_for(func():return town.in_hall,450)
	if expect(town.in_hall,"existing weaving hall door still opens"):
		var keeper:=town.hall.get_node("Sort/Keeper") as Node2D
		hero.global_position=keeper.global_position+Vector2(-75,45)
		await create_timer(.2).timeout
		print("KEEPER PROBE ",keeper.global_position," foot ",hero.global_position," blocked ",dialogue.is_playing())
		await press_space()
		expect(await wait_for(func():return dialogue.is_playing() and dialogue.get("_current_script").dialog_id==&"lanxi_keeper",1500),"normal indoor dialogue")
		if dialogue.is_playing():dialogue.advance()
		await process_frame
		hero.global_position=town.hall.get_node("Exit").global_position+Vector2(0,-35)
		await create_timer(.2).timeout
		print("EXIT PROBE ",town.hall.get_node("Exit").global_position," foot ",hero.global_position," blocked ",dialogue.is_playing())
		await press_space()
		expect(await wait_for(func():return not town.in_hall,1200),"existing weaving hall return still opens")

func hold_key(key: int, duration: float) -> void:
	var movement:=InputEventKey.new()
	movement.keycode=key
	movement.physical_keycode=key
	movement.pressed=true
	Input.parse_input_event(movement)
	await create_timer(duration).timeout
	movement=movement.duplicate()
	movement.pressed=false
	Input.parse_input_event(movement)

func tang() -> void:
	var field:=await enter(&"linxi_village_center")
	if field==null:return
	var npc: NPCNode
	for item: NPCNode in field.get("_npc_nodes"):
		if item.npc_id=="tang_xingzhou_recruit":npc=item
	if not expect(is_instance_valid(npc),"Tang exists"):return
	var post:=npc.get_node_or_null("ConversationPracticePost") as Sprite2D
	if not expect(post!=null and not post.visible,"one post in practice frame"):return
	await position_at(field,npc.global_position+Vector2(-62,18))
	await press_space()
	expect(await wait_for(func():return dialogue.is_playing() and post.visible,2000),"post remains through actual dialogue")
	await shot("tang_dialogue")

func road() -> void:
	state.set_flag(&"master_training_done",true)
	quests.accept(&"q_ch1_side_02_cliff_herb")
	var field:=await enter(&"ch1_s1_road")
	if field==null:return
	await settle(field)
	var actor: Player=await position_at(field,Vector2(895,1820))
	await shot("road_ridge_front")
	var sprites: Array=field.get("_road_static")
	var ridge: Sprite2D
	for sprite: Sprite2D in sprites:
		if sprite.name=="RoadNative_granite_ridge_00":ridge=sprite
	expect(ridge!=null and actor.z_index>=ridge.z_index,"front player draws over western rock")
	var life:=root.get_node("LifeSkills")
	if expect(await wait_for(func():return life.get("_site_nodes").size()>=3,3000),"ordinary gathering nodes present"):
		for pair in [["life_road_herb_01","white_flowering_herb.png"],["life_road_herb_02","lobed_leaf_herb.png"]]:
			var item: Node2D=life.get("_site_nodes").get(pair[0])
			var plant:=item.get_child(0) as Sprite2D
			expect(plant!=null and plant.texture.resource_path.ends_with(pair[1]),"distinct herb texture")
			await position_at(field,item.global_position+Vector2(-51,20))
			await shot("road_"+String(pair[0]))
			expect(await wait_for(func():return life.get("_nearest")==pair[0],1000),"visible herb can be targeted")
			await hold_key(KEY_F,0.1)
			expect(await wait_for(func():return not item.visible,4200),"F harvest consumes this herb")
	var vine: Sprite2D
	for sprite: Sprite2D in field.get("_scene_object_nodes"):
		if sprite.name=="SceneObject_road_cliff_herb_visual":vine=sprite
	if expect(vine!=null and vine.texture.resource_path.ends_with("cliff_creeping_vine.png"),"quest herb uses the rock-creeping vine"):
		var area: Area2D
		for candidate: Area2D in field.get("_trigger_areas"):
			if candidate.name=="ObjectInteraction_road_cliff_herb_visual":area=candidate
		if not expect(area!=null,"quest herb interaction area exists"):return
		await position_at(field,area.global_position+Vector2(0,5))
		await shot("road_cliff_herb")
		await wait_for(func():return area.overlaps_body(actor),1000)
		print("HERB_PROBE ",area.global_position," foot ",actor.global_position," overlap ",area.overlaps_body(actor)," coll ",actor.collision_layer," area ",area.monitoring,"/",area.collision_mask," shape ",area.get_child(0).shape.size," active ",quests.is_active(&"q_ch1_side_02_cliff_herb"))
		await press_space()
		expect(await wait_for(func():return dialogue.is_playing() and dialogue.get("_current_script").dialog_id==&"ch1_cliff_herb_collect",1800),"original herb quest interaction opens")

