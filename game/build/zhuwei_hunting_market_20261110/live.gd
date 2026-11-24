extends "res://build/victory_quest_20261108/story_live.gd"

const FOREST := &"ch1_s3_zhuwei_forest"
const HUNT := &"adventure_zhuwei_hunting_ground"
const CAVE := &"ch1_s4_zhuwei_beast_cave"
const SHAFT := &"ch1_s4_cave_mine_gallery"
const RUIN := &"ch1_s3_ruin_inner"
const MARKET := &"ch2_s1_zhuwei_market"
const VILLAGE := &"ch1_s2_qingfeng"

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
			"forest": await forest_route()
			"market": await market_route()
			"local": await local_fixes()
			"smith_weapons": await smith_and_weapons()
			"mine_exit": await mine_exit()
	finish()

func feet(field: Node, uv: Vector2) -> Vector2:
	var world: Node2D=field.get("world_container")
	var extent: Vector2=field.get("_world_size")
	return world.to_global(uv*extent)

func clear_uv(field: Node, uv: Vector2, label: String) -> void:
	var actor: Player=await position_at(field,feet(field,uv))
	check_clear(actor,label)
	expect(not actor.movement_constraint.is_valid() or bool(actor.movement_constraint.call(actor.global_position)),label+" inside walkable mask")

func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	var result: Error=root.get_texture().get_image().save_png("user://"+name+".png")
	expect(result==OK,name+" screenshot")

func forest_route() -> void:
	state.set_flag(&"entered_zhuwei_forest",true)
	state.set_flag(&"defeated_linxi_wild_beast",true)
	var field:=await enter(FOREST)
	if field==null:return
	await settle(field)
	await clear_uv(field,Vector2(.314,.423),"stone stair branch")
	await shot("zhuwei_forest_stairs")
	var runtime:=root.get_node("AdventureRuntime")
	var before:=field.get_instance_id()
	var key:=InputEventKey.new()
	key.keycode=KEY_G
	key.physical_keycode=KEY_G
	key.pressed=true
	Input.parse_input_event(key)
	await process_frame
	key=key.duplicate() as InputEventKey
	key.pressed=false
	Input.parse_input_event(key)
	if not expect(await wait_for(func():return current_scene!=null and current_scene.get_instance_id()!=before and router.get_current_field_id()==HUNT and current_scene.has_method("get_field_loading_state") and current_scene.get_field_loading_state().get("complete",false),14000),"stone stair G enters real hunting map"):
		print("FEATURES ",runtime.get("_features"))
		return
	field=current_scene
	await settle(field)
	var actor: Player=field.get("_player")
	expect(actor.z_index>255,"southern player is not capped at depth 255")
	expect(field.find_child("RiversideNaturalGround01",true,false)!=null,"new low-contrast world-UV terrain visible")
	await shot("zhuwei_hunt_south")
	field=await take(field,FOREST)
	if field==null:return
	expect((field.get("_player") as Player).global_position.distance_to(feet(field,Vector2(.371,.506)))<3,"return on same stair approach")
	field=await take(field,CAVE)
	if field==null:return
	field=await take(field,SHAFT)
	if field==null:return
	expect(field.find_child("SceneObject_deep_den_arch",true,false)!=null,"mine runs the independent modular layout")
	await shot("zhuwei_mine_entrance")
	await clear_uv(field,Vector2(.890,.205),"deep den mouth")
	await shot("zhuwei_mine_deep_portal")

func market_route() -> void:
	state.set_flag(&"chapter1_complete",true)
	state.set_flag(&"seen_ch2_zhuwei_intro",true)
	state.set_flag(&"defeated_boss_zhao_wuji",true)
	state.set_flag(&"master_training_done",true)
	var field:=await enter(RUIN)
	if field==null:return
	field=await take(field,MARKET)
	if field==null:return
	var market_scene: SceneScript=field.get("_current_scene")
	expect(market_scene.map_layout.resource_path.ends_with("ch2_s1_zhuwei_market_layout_v3.tres") and (field.get("_world_size") as Vector2).x<4200,"chapter two is no longer the first chapter native village")
	expect((field.get("_player") as Player).global_position.distance_to(feet(field,Vector2(.248,.886)))<3,"ruin arrives in market west alley")
	await shot("zhuwei_market_alley")
	field=await take(field,&"ch2_s1_market_inn")
	if field==null:return
	field=await take(field,MARKET)
	if field==null:return
	expect((field.get("_player") as Player).global_position.distance_to(feet(field,Vector2(.349,.476)))<3,"chapter two inn returns to its own stairs")
	var world_exit: ExitZone
	for zone: ExitZone in field.get("_exit_nodes"):
		if "江湖大地图" in zone.exit_label:world_exit=zone
	if not expect(world_exit!=null and not world_exit.is_locked,"market has an unlocked south world-map portal"):return
	var actor:=await position_at(field,world_exit.global_position)
	check_clear(actor,"market south road")
	expect(await wait_for(func():return world_exit.get("_in_range"),2200),"market south road has physical portal overlap")
	print("MARKET_WORLD_BEFORE ",actor.global_position," ",world_exit.global_position," action=",world_exit.action," target=",world_exit.target_scene_id," move=",actor.can_move," dialog=",dialogue.is_playing()," gateway=",router.get_world_map_position_for_scene(MARKET,router.get_active_world_map_scene()))
	await press_space()
	await create_timer(0.35).timeout
	expect(await wait_for(func():return router.is_world_map_scene(router.get_current_field_id()) and not root.get_node("LoadingManager").get("_transition_active"),24000),"market road reaches the active world map")
	print("MARKET_WORLD_RESULT ",router.get_current_field_id()," active=",router.get_active_world_map_scene())

func local_fixes() -> void:
	state.set_flag(&"entered_west_ruin",true)
	state.set_flag(&"accepted_rescue_husband",true)
	var field:=await enter(&"ch1_s3_west_ruin")
	if field==null:return
	await settle(field)
	var guarded: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id=="bound_man":guarded=npc
	if expect(guarded!=null,"bound villager remains visible before combat"):
		expect(guarded._resolve_dialog_id()=="ch1_s3_bound_man_guarded","guarded dialogue selected without giving rescue credit")
		state.set_flag(&"defeated_zhuwei_bandit",true)
		var ready_after_victory:=await wait_for(func():
			for npc: NPCNode in field.get("_npc_nodes"):
				if is_instance_valid(npc) and npc.is_inside_tree() and not npc.is_queued_for_deletion() and npc.npc_id=="bound_man":
					return npc._resolve_dialog_id()=="ch1_s3_bound_man"
			return false
		,2000)
		expect(ready_after_victory,"same villager can be freed after victory")
	state.set_flag(&"master_training_done",true)
	state.set_flag(&"defeated_boss_zhao_wuji",false)
	field=await enter(RUIN)
	if field!=null:
		await settle(field)
		var found:=false
		for npc: NPCNode in field.get("_npc_nodes"):
			if npc.npc_id=="zhao_wuji":
				found=true
				expect(npc.sprite.hframes==4 and npc.sprite.texture.get_size()==Vector2(2172,724),"four HD Zhao frames")
		expect(found,"Zhao spawned on actual field")
		await shot("zhuwei_zhao_hd")
	field=await enter(VILLAGE)
	if field!=null:
		await roundtrip(field,&"interior_inn_hall",VILLAGE,130.0)
	field=await enter(&"interior_bandit_cave")
	if field!=null:
		await settle(field)
		var bed: Sprite2D=field.find_child("SceneObject_resting_bed",true,false)
		if expect(bed!=null,"resting bed found"):
			var actor: Player=await position_at(field,feet(field,Vector2(.219,.65)))
			actor.refresh_depth_sort()
			await process_frame
			expect(actor.z_index>bed.z_index,"actor south of diagonal bed is in front")
			actor=await position_at(field,feet(field,Vector2(.219,.55)))
			actor.refresh_depth_sort()
			await process_frame
			expect(actor.z_index<bed.z_index,"actor behind bed is occluded")

func mine_exit() -> void:
	state.set_flag(&"defeated_linxi_wild_beast",true)
	var field:=await enter(SHAFT)
	if field==null:return
	await settle(field)
	expect(field.find_child("AnimatedProp_deep_brazier_light",true,false)!=null,"mine lamp has local warm light")
	await shot("zhuwei_mine_final")
	field=await take(field,&"ch1_s4_cave_deep_den")
	if field==null:return
	field=await take(field,SHAFT)
	if field==null:return
	expect((field.get("_player") as Player).global_position.distance_to(feet(field,Vector2(.890,.205)))<120,"deep den returns to original gallery mouth")

func smith_and_weapons() -> void:
	var field:=await enter(&"linxi_tutorial")
	if field==null:return
	await settle(field)
	var smith: NPCNode
	var master: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id.begins_with("duqingshan"):smith=npc
		if npc.npc_id.begins_with("xingfantian"):master=npc
	if not expect(smith!=null and master!=null,"actual smith and master both present"):return
	var forge:=smith.get_node_or_null("SmithingAnimation") as Sprite2D
	if not expect(forge!=null,"smith uses hammer animation"):return
	var master_id: String=master.dialog_id
	dialogue.play(load("res://data/dialogs/"+master_id+".tres") as DialogScript)
	var original: Texture2D=forge.texture
	expect(await wait_for(func():return dialogue.is_playing() and is_instance_valid(forge) and forge.visible and forge.texture!=original,2400),"smith continues hammering during master dialogue")
	for step in range(24):
		if not dialogue.is_playing() or dialogue.get("_current_node").has_choices():break
		dialogue.advance()
		await process_frame
	if dialogue.is_playing():
		dialogue.call("_end_dialog")
		await process_frame
	var inventory:=root.get_node("Inventory")
	inventory.reset_for_new_game()
	expect(inventory.add_item(&"jinhe_duanyue_blade") and inventory.equip(&"jinhe_duanyue_blade"),"equip the real named saber")
	var hero: Player=field.get("_player")
	var runtime:=root.get_node("LayeredAppearanceRuntime")
	hero._direction="down"
	if not expect(await wait_for(func():return runtime.actors.get(hero.get_instance_id(),{}).get("pose")!=null,2800),"real hero layered appearance ready"):return
	var pose: Node2D=runtime.actors[hero.get_instance_id()].pose
	expect(await wait_for(func():return pose.current_sheathed and pose.current_clip=="idle_down" and pose.weapon.texture==pose.front_hilt_textures.get("jinhe_sheath"),1500),"front-facing field pose shows hilt only")
	await shot("linxi_waist_hilt")
	var extent: Vector2=field.get("_world_size")
	var world: Node2D=field.get("world_container")
	router.start_battle("thug_lone",&"linxi_tutorial",world.to_local(hero.global_position)/extent)
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn" and current_scene.get("_state")==1,14000),"real encounter reaches combat"):return
	var battle:=current_scene
	var combat_hero: BattleActor=battle.formation_view.get_actor(&"player")
	if not expect(await wait_for(func():return runtime.actors.get(combat_hero.get_instance_id(),{}).get("pose")!=null,2500),"combat hero has layered pose"):return
	pose=runtime.actors[combat_hero.get_instance_id()].pose
	var material: ShaderMaterial=pose.weapon.material
	expect(material!=null and not material.get_shader_parameter("sheathed") and pose.star_particles.visible,"drawn blade shader and particles active")
	await shot("linxi_drawn_blade")
