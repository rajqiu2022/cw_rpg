extends "res://build/victory_quest_20261108/story_live.gd"

const CENTER := &"linxi_village_center"
const HERBAL := &"linxi_herbal_home"
const RESTORE = preload("res://build/linxi_building_scale_20261030h_system01/restore.gd")

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
	var size:=Vector2(3600,2800)
	var old_safe:=Vector2(3070,2020)/size
	expect(RESTORE.restore(CENTER,old_safe,3004)==Vector2(2790,2148)/size,"old walkable foot covered by drying porch migrates to door")
	expect(RESTORE.restore(CENTER,Vector2(3150,2020)/size,3004)==Vector2(3150,2020)/size,"old foot beside porch retained")
	expect(RESTORE.restore(CENTER,Vector2(2890,2030)/size,3004)==null,"old solid remains invalid")
	var field:=await enter(CENTER)
	if field==null:
		finish()
		return
	var native: Node=field.get("native_town")
	var art_paths: Dictionary={}
	for id: String in ["HouseB","BackHouse2","HerbHome"]:
		var art:=native.get_node("Town/"+id+"/Art") as Sprite2D
		art_paths[id]=art.texture.resource_path
		expect(is_equal_approx(art.scale.x,art.scale.y),"house kept proportional "+id)
	expect(art_paths.values().size()==3 and art_paths.HouseB.ends_with("stone_hip_roof_home.png") and art_paths.BackHouse2.ends_with("small_cottage.png") and art_paths.HerbHome.ends_with("herbal_drying_home.png"),"three distinct actual sprites")
	await position_at(field,Vector2(2250,2190))
	await create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/linxi_house_variety_20261109/linxi_three_homes.png")
	var zone:=zone_to(field,HERBAL)
	if expect(zone!=null and zone.global_position.distance_to(Vector2(2790,2148))<1,"herbal marker and portal keep original feet"):
		var actor:=await position_at(field,Vector2(2790,2270))
		check_clear(actor,"public approach")
		var key:=InputEventKey.new()
		key.physical_keycode=KEY_W
		key.keycode=KEY_W
		key.pressed=true
		Input.parse_input_event(key)
		expect(await wait_for(func(): return zone.get("_in_range") and actor.global_position.y<2250,2200),"walk from public path into actual door zone")
		key=key.duplicate()
		key.pressed=false
		Input.parse_input_event(key)
		await process_frame
		await press_space()
		if expect(await wait_for(func():
			return router.get_current_field_id()==HERBAL and current_scene!=null and current_scene.get("_current_scene")!=null and current_scene.get("_current_scene").scene_id==HERBAL and not root.get_node("LoadingManager").get("_transition_active")
		),"actual Space enters herbal house"):
			check_clear(current_scene.get("_player"),"safe interior arrival")
			var restored:=await take(current_scene,CENTER)
			if restored!=null: expect(restored.get("_player").global_position.distance_to(Vector2(2790,2148))<1,"returns to same outdoor threshold")
	finish()
