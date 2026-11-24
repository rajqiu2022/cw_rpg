extends "res://build/layered_actor_adoption_20261106/game_qa.gd"

const CHECK_DIR := "res://build/blade_glow_20261109/"
const BLADES: Array[StringName] = [
	&"jinhe_duanyue_blade", &"seven_star_sword", &"yuanming_sword",
	&"tiger_roar_blade", &"zhouju_bronze_sword",
]

func finish() -> void:
	print("BLADE_GLOW ",checks.size()," checks / ",failures," failures")
	quit(0 if failures==0 else 1)

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(CHECK_DIR+name+".png")

func verify_coverage(pose: Node2D, caption: String) -> void:
	var span: Vector2=pose.enchantment.get_shader_parameter("blade_span")
	if not check(span.x < .06 and span.y > .53 and span.length() < 1.0, caption+" span "+str(span)):return
	check(pose.star_particles.motes.filter(func(mote: Sprite2D):return mote.visible).size()==6,caption+" sparse motes")
	var vp:=SubViewport.new()
	vp.size=Vector2i(pose.weapon.texture.get_size())
	vp.transparent_bg=true
	vp.disable_3d=true
	vp.world_2d=World2D.new()
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var art := Sprite2D.new()
	art.centered=false
	art.texture=pose.weapon.texture
	art.material=pose.enchantment.duplicate()
	vp.add_child(art)
	await process_frame
	await RenderingServer.frame_post_draw
	var lit:=vp.get_texture().get_image()
	art.material=null
	await process_frame
	await RenderingServer.frame_post_draw
	var base:=vp.get_texture().get_image()
	vp.queue_free()
	for fraction: float in [.12,.34,.56,.81,.93]:
		var y:=roundi(lerpf(span.x,span.y,fraction)*float(lit.get_height()))
		var left:=lit.get_width()
		var right:=-1
		for x in lit.get_width():
			if base.get_pixel(x,y).a > .75:
				left=mini(left,x)
				right=x
		if not check(right>=left,caption+" existing art at "+str(fraction)):continue
		var exterior: Array[float]=[0.0,0.0]
		for x in range(maxi(0,left-36),left):
			exterior[0]=maxf(exterior[0],lit.get_pixel(x,y).a-base.get_pixel(x,y).a)
		for x in range(right+1,mini(lit.get_width(),right+37)):
			exterior[1]=maxf(exterior[1],lit.get_pixel(x,y).a-base.get_pixel(x,y).a)
		check(minf(exterior[0],exterior[1])>.035 and maxf(exterior[0],exterior[1])<.36,caption+" subtle two-sided halo "+str(fraction)+" "+str(exterior))
	var handle_y:=roundi(lerpf(span.y,1.0,.21)*lit.get_height())
	var handle_delta:=0.0
	for x in lit.get_width():
		handle_delta=maxf(handle_delta,lit.get_pixel(x,handle_y).a-base.get_pixel(x,handle_y).a)
	check(handle_delta<.012,caption+" no halo on handle")

func run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var state:=root.get_node("GameState")
	var inv:=root.get_node("Inventory")
	var router:=root.get_node("SceneRouter")
	var runtime:=root.get_node("LayeredAppearanceRuntime")
	state.reset_for_new_game()
	inv.reset_for_new_game()
	router.reset_for_new_game()
	state.player.hp=1000
	state.player.max_hp=1000
	state.player.speed=1000
	var misc: Array[StringName]=[&"iron_sword",&"golden_hoop_staff"]
	for id: StringName in BLADES+misc:
		check(inv.add_item(id),"give "+str(id))
	if not check(router.go_field_smart(FIELD,Vector2(.835,.470)),"Linxi route"):
		finish()
		return
	if not check(await until(func():return get_first_node_in_group("player") is Player),"Linxi Player"):
		finish()
		return
	var player:=get_first_node_in_group("player") as Player
	var player_id:=player.get_instance_id()
	if not check(await until(func():return runtime.actors.get(player_id,{}).get("active",false) and player.can_move),"real layered field"):
		finish()
		return
	var pose: Node2D=runtime.actors[player_id].pose
	for id: StringName in BLADES+misc:
		check(inv.equip(id),"equip field "+str(id))
		player.set_walk_direction(Vector2.DOWN,false)
		if not check(await until(func():return pose.current_weapon==("plain_sword" if id==&"iron_sword" else String(id)) and pose.current_clip=="idle_down"),"field pose "+str(id)):continue
		if id==&"iron_sword":
			check(pose.weapon.material==null and not pose.star_particles.visible,"ordinary sword has no aura")
			continue
		if id==&"golden_hoop_staff":
			check(pose.current_back_carried and pose.enchantment.get_shader_parameter("blade_span")==Vector2.ZERO and pose.star_particles.motes.all(func(mote: Sprite2D):return mote.visible),"staff retains original FX")
			continue
		check(pose.current_sheathed,"waist carry "+str(id))
		await verify_coverage(pose,"field "+str(id))
		if id in [&"seven_star_sword",&"jinhe_duanyue_blade"]:
			await shot("field_"+str(id))
			player.set_walk_direction(Vector2.RIGHT,false)
			check(await until(func():return pose.current_clip=="idle" and pose.carry_arm.visible),"side sleeve remains in front")
			await shot("side_"+str(id))
	var return_point: Vector2=player.position/current_scene.get("_world_size")
	router.start_battle("ancient_tomb_guard",FIELD,return_point)
	if not check(await until(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn"),"battle route"):
		finish()
		return
	var controller:=current_scene
	var hero: BattleActor=controller.formation_view.get_actor(&"player")
	if not check(await until(func():return hero!=null and runtime.actors.get(hero.get_instance_id(),{}).get("active",false) and controller._state==1),"battle ready"):
		finish()
		return
	pose=runtime.actors[hero.get_instance_id()].pose
	for id: StringName in BLADES:
		check(inv.equip(id),"equip battle "+str(id))
		if not check(await until(func():return pose.current_weapon==String(id) and pose.current_clip.begins_with("ready_")),"ready pose "+str(id)):continue
		check(not pose.current_sheathed,"weapon drawn "+str(id))
		await verify_coverage(pose,"battle "+str(id))
		if id in [&"seven_star_sword",&"jinhe_duanyue_blade"]:
			await shot("battle_"+str(id))
	check(inv.equip(&"jinhe_duanyue_blade"),"equip Jinhe for strike")
	hero.strike_reached.connect(func():strikes+=1)
	var skills: Array=controller._skills_for_stats(controller._team_active_unit.stats)
	for i in skills.size():
		if skills[i].skill_id==&"basic_attack":
			controller._on_skill_selected(i)
			break
	if check(await until(func():return pose.current_clip=="attack_dao" and pose.current_frame==2,8000),"actual Jinhe strike"):
		await shot("battle_jinhe_attack")
	check(strikes==1,"one normal strike")
	finish()

