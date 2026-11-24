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
	var resident:=town.get_node("Town/PlazaCraftsman") as Node2D
	var hero:=await position_at(field,resident.global_position+Vector2(-80,30))
	await press_space()
	expect(await wait_for(func():return dialogue.is_playing() and dialogue.get("_current_script").dialog_id==&"lanxi_plaza_craftsman",1500),"normal Lanxi dialogue")
	expect(not town.show_details,"preview card stays hidden")
	await shot("lanxi_dialogue")
	if dialogue.is_playing():dialogue.advance()
	await process_frame
	for y in [1040,1080,1120,1160,1200]:
		var probe:=await position_at(field,Vector2(2875,y))
		var movement:=InputEventKey.new()
		movement.physical_keycode=KEY_D
		movement.pressed=true
		Input.parse_input_event(movement)
		await create_timer(.8).timeout
		movement=movement.duplicate()
		movement.pressed=false
		Input.parse_input_event(movement)
		print("LANE_PROBE ",y," -> ",probe.position)
		for i in range(probe.get_slide_collision_count()):
			print("COLLIDER ",probe.get_slide_collision(i).get_collider().get_path())
	for id in ["HighStilt1"]:
		var house: Node2D=town.get_node("Town/"+id)
		hero=await position_at(field,house.global_position+Vector2(130,160))
		await shot("lane_"+id)
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
			var item: Variant=life.get("_site_nodes").get(pair[0])
			print("GATHER_SITE ",pair[0]," ",item)
			if item is Sprite2D:expect(item.texture.resource_path.ends_with(pair[1]),"distinct herb texture")
	await position_at(field,Vector2(850,2885))
	await shot("road_white_herb")
