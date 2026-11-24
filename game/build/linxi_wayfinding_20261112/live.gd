extends "res://build/zhuwei_hunting_market_20261110/live.gd"

const CENTER := &"linxi_village_center"
const MOUNTAIN := &"ch1_s1_road"
const SOUTH := &"linxi_village_scrollmap"
const ORE := "life_road_ore_01"

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
	state.set_flag(&"got_sword",true)
	state.player.speed=1000
	state.player.agility=180
	var inv:=root.get_node("Inventory")
	expect(inv.add_item(&"immortal_gauntlets") and inv.equip(&"immortal_gauntlets"),"equip named gauntlets")
	var center:=await enter(CENTER)
	if center==null:finish();return
	await settle(center)
	var zone:=zone_to(center,MOUNTAIN)
	var world: Node2D=center.get("world_container")
	expect(zone!=null and zone.position.distance_to(Vector2(3070,400))<0.5,"northeast portal position preserved")
	if zone!=null:
		print("LINXI_MARKER side=",zone.destination_label_side," angle=",zone.marker_visual.rotation_degrees)
		expect(zone.destination_label_side<0 and cos(zone.marker_visual.rotation)<-0.99 and zone.prompt.position.x<zone.marker_visual.position.x,"north arrow and label on clear side")
	expect(zone_to(center,SOUTH)!=null,"south remains open")
	expect(world.has_node("LinxiMountainWayfinding"),"northbound sign at village fork")
	var player:=await position_at(center,world.to_global(Vector2(2385,1660)))
	await shot("village_fork")
	player.set_walk_direction(Vector2.LEFT,false)
	await create_timer(0.18).timeout
	await verify_glow(player,"field")
	await shot("field_gauntlets")
	if zone!=null:
		await position_at(center,zone.global_position+Vector2(-34,64))
		await shot("mountain_mouth")
	var road:=await take(center,MOUNTAIN)
	if road==null:finish();return
	var gathering:=root.get_node("LifeSkills")
	if not expect(await wait_for(func():return gathering.get("_active_sites").has(ORE),2500),"ore spawned in formal field"):finish();return
	var ore: Node2D=gathering.get("_site_nodes")[ORE]
	expect(ore.position.distance_to(Vector2(3680,2054))<1,"ore at granite base and away from old main road")
	expect((ore.get_child(1) as Label).z_index==4096,"cliff does not cover ore label")
	player=await position_at(road,ore.global_position+Vector2(-54,0))
	check_clear(player,"ore approach outside cliff")
	if expect(await wait_for(func():return gathering.get("_nearest")==ORE,1600),"ore reachable from west side"):
		await shot("ore_at_cliff")
		var key:=InputEventKey.new()
		key.keycode=KEY_F
		key.physical_keycode=KEY_F
		key.pressed=true
		Input.parse_input_event(key)
		await process_frame
		var release:=key.duplicate() as InputEventKey
		release.pressed=false
		Input.parse_input_event(release)
		expect(await wait_for(func():return not ore.visible,6000),"F gathers ore and depleted node hides")
	center=await take(road,CENTER)
	if center==null:finish();return
	player=center.get("_player")
	expect(player.global_position.distance_to(Vector2(3070,400))<1,"return to the same mountain mouth")
	router.start_battle("thug_lone",CENTER,player.global_position/Vector2(3600,2800))
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn" and current_scene.get("_state")==1),"real battle ready"):finish();return
	var actor: BattleActor=current_scene.formation_view.get_actor(&"player")
	await verify_glow(actor,"battle")
	await shot("battle_gauntlets")
	finish()

func verify_glow(actor: Node, label: String) -> void:
	var runtime:=root.get_node("LayeredAppearanceRuntime")
	var actor_id:=actor.get_instance_id()
	if not expect(await wait_for(func():return runtime.actors.get(actor_id,{}).get("active",false),2000),label+" layered actor ready"):return
	var pose: Node2D=runtime.actors[actor_id].pose
	if not expect(is_instance_valid(pose.gauntlets) and pose.gauntlets.visible and pose.gauntlets.emitters[0].z_index>pose.body.z_index,label+" gauntlets use foreground sparks"):return
	runtime.set_process(false)
	await RenderingServer.frame_post_draw
	var lit:=pose.get_viewport().get_texture().get_image()
	pose.gauntlets.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var bare:=pose.get_viewport().get_texture().get_image()
	var changed:=0
	for i in pose.gauntlets.emitters.size():
		var emitter: Node2D=pose.gauntlets.emitters[i]
		if not emitter.visible:continue
		var center_px:=Vector2i(emitter.global_position)
		for y in range(center_px.y-52,center_px.y+52,3):
			for x in range(center_px.x-52,center_px.x+52,3):
				var a:=lit.get_pixel(x,y)
				var b:=bare.get_pixel(x,y)
				if a.a>0.25 and (a.r-b.r+a.g-b.g>0.22 or a.a-b.a>0.22):changed+=1
	print("GAUNTLET_RENDERED_SAMPLES ",label,"=",changed)
	expect(changed>25,label+" gauntlets change rendered hand pixels")
	runtime.set_process(true)
