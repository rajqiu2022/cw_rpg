extends "res://build/zhuwei_hunting_market_20261110/live.gd"

const BLADES := [&"seven_star_sword", &"jinhe_duanyue_blade", &"yuanming_sword", &"tiger_roar_blade", &"zhouju_bronze_sword"]
const STAVES := [&"buddha_subduing_staff", &"heaven_piercing_staff", &"golden_hoop_staff"]
const LINXI := &"linxi_tutorial"

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
	state.player.speed=1000
	state.player.agility=180
	var inv:=root.get_node("Inventory")
	var runtime:=root.get_node("LayeredAppearanceRuntime")
	var field:=await enter(LINXI)
	if field==null:finish();return
	await settle(field)
	if dialogue.is_playing():dialogue.call("_end_dialog")
	var player: Player=field.get("_player")
	if not expect(await wait_for(func():return runtime.actors.get(player.get_instance_id(),{}).get("active",false)),"formal field layered actor"):finish();return
	var pose: Node2D=runtime.actors[player.get_instance_id()].pose
	for id: StringName in BLADES+STAVES+[&"immortal_gauntlets",&"suwusheng_teapot",&"iron_sword"]:
		expect(inv.add_item(id) and inv.equip(id),"equip "+String(id))
		for direction: Vector2 in [Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
			player.set_walk_direction(direction,false)
			await create_timer(0.07).timeout
			if id in BLADES:
				var hilt: bool=direction==Vector2.DOWN
				var expected: Vector2=pose.enchantment.get_shader_parameter("hilt_span")
				expect(pose.current_weapon==String(id) and pose.socket.visible and pose.current_sheathed and pose.star_particles.visible and pose.weapon.material==pose.enchantment and (expected.y>expected.x)==hilt,"sheath/hilt glow "+String(id)+str(direction))
				if id==&"jinhe_duanyue_blade" and direction!=Vector2.UP:
					await shot("jinhe_front" if hilt else "jinhe_side")
					await assert_rendered_fx(runtime,pose,"front" if hilt else "side")
			elif id in STAVES:
				expect(pose.current_weapon==String(id) and pose.current_back_carried and pose.star_particles.visible and (direction!=Vector2.LEFT or not pose.star_particles.motes[4].visible),"staff carry glow "+String(id)+str(direction))
			elif id==&"immortal_gauntlets":
				expect(pose.gauntlets!=null and pose.gauntlets.visible and not pose.star_particles.visible,"gauntlet hand glow")
			elif id==&"suwusheng_teapot":
				expect(not pose.socket.visible and not pose.star_particles.visible,"hidden weapon remains hidden in field")
			else:
				expect(pose.weapon.material==null and not pose.star_particles.visible and not pose.gauntlets.visible,"ordinary sword does not inherit effects")
	var foot:=player.global_position
	var world: Node2D=field.get("world_container")
	var extent: Vector2=field.get("_world_size")
	router.start_battle("thug_lone",LINXI,world.to_local(foot)/extent)
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn" and current_scene.get("_state")==1),"formal battle starts"):finish();return
	var battle:=current_scene
	var actor: BattleActor=battle.formation_view.get_actor(&"player")
	var target: BattleActor=battle.formation_view.get_actor(battle._team_enemies[0].unit_id)
	var combat: Node2D=runtime.actors[actor.get_instance_id()].pose
	for id: StringName in [&"jinhe_duanyue_blade",&"golden_hoop_staff",&"suwusheng_teapot"]:
		expect(inv.equip(id),"combat equip "+String(id))
		await create_timer(0.08).timeout
		var hidden:=id==&"suwusheng_teapot"
		var clip: String="attack" if hidden else ("fast_staff" if id in STAVES else "fast_slash")
		expect(combat.socket.visible!=hidden and combat.star_particles.visible!=hidden,"ready visibility "+String(id))
		actor.play_attack_approach(target,false)
		if expect(await wait_for(func():return combat.current_clip==clip and combat.socket.visible and combat.star_particles.visible,2500),"real approach/action reveals FX "+String(id)) and id!=&"golden_hoop_staff":
			await shot("strike_"+String(id))
		await create_timer(1.15).timeout
		await actor.play_attack_recover()
		await process_frame
		if hidden:expect(not combat.socket.visible and not combat.star_particles.visible,"concealed FX hide on recovery")
	var battle_id:=battle.get_instance_id()
	battle._player_action_flee()
	expect(await wait_for(func():return current_scene!=null and current_scene.get_instance_id()!=battle_id and router.get_current_field_id()==LINXI and current_scene.has_method("get_field_loading_state") and current_scene.get_field_loading_state().get("complete",false)),"retreat to original field")
	finish()

func assert_rendered_fx(runtime: Node, pose: Node2D, label: String) -> void:
	var canvas:=pose.get_viewport()
	runtime.set_process(false)
	await RenderingServer.frame_post_draw
	var lit:=canvas.get_texture().get_image()
	pose.weapon.material=null
	pose.star_particles.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var unlit:=canvas.get_texture().get_image()
	var altered:=0
	for y in range(650,1080,2):
		for x in range(570,970,2):
			var a:=lit.get_pixel(x,y)
			var b:=unlit.get_pixel(x,y)
			if a.a>0.12 and (absf(a.a-b.a)>0.12 or absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.23):
				altered+=1
	print("JINHE_RENDERED_EFFECT_SAMPLES ",label,"=",altered)
	expect(altered>30,"visible rendered weapon glow "+label)
	runtime.set_process(true)
