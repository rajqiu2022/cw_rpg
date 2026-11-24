extends "res://build/layered_actor_adoption_20261106/game_qa.gd"

const EVIDENCE := "res://build/battle_stances_20261109/"
const CASES := {
	&"iron_sword":"ready_sword", &"seven_star_sword":"ready_sword",
	&"iron_great_blade":"ready_blade", &"jinhe_duanyue_blade":"ready_blade",
	&"wooden_staff":"ready_staff", &"heaven_piercing_staff":"ready_staff",
	&"buddha_subduing_staff":"ready_blade", &"iron_knuckles":"ready_palm",
	&"immortal_gauntlets":"ready_palm",
}

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(EVIDENCE+name+".png")

func finish() -> void:
	FileAccess.open(EVIDENCE+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"strikes":strikes},"\t"))
	print("BATTLE_STANCES ",checks.size()," / ",failures)
	quit(0 if failures==0 else 1)

func run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var state := root.get_node("GameState")
	var inv := root.get_node("Inventory")
	var router := root.get_node("SceneRouter")
	var appearance := root.get_node("LayeredAppearanceRuntime")
	state.reset_for_new_game()
	inv.reset_for_new_game()
	router.reset_for_new_game()
	state.player.max_hp=10000
	state.player.hp=10000
	state.player.max_mp=1000
	state.player.mp=1000
	state.learn_skill(&"palm_strike")
	for id: StringName in CASES:
		check(inv.add_item(id),"grant "+String(id))
	check(router.go_field_smart(FIELD,Vector2(.835,.470)),"enter real Linxi")
	if not check(await until(func():return get_first_node_in_group("player") is Player),"field entered"):
		finish()
		return
	var actor:=get_first_node_in_group("player") as Player
	actor.set_walk_direction(Vector2.RIGHT,false)
	var record_id:=actor.get_instance_id()
	check(await until(func():return appearance.actors.get(record_id,{}).get("active",false) and appearance.actors[record_id].pose.current_clip=="idle"),"map still uses the ordinary idle")
	if not check(await until(func():return not root.get_node("LoadingManager").get("_transition_active") and actor.can_move),"field becomes operable"):
		finish()
		return
	var original_foot:=actor.position
	router.start_battle("ancient_tomb_guard",FIELD,original_foot/current_scene.get("_world_size"))
	if not check(await until(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn"),"battle entered"):
		finish()
		return
	var controller:=current_scene
	var hero: BattleActor=controller.formation_view.get_actor(&"player")
	hero.strike_reached.connect(func(): strikes+=1)
	var hero_id:=hero.get_instance_id()
	if not check(await until(func():return appearance.actors.get(hero_id,{}).get("active",false) and controller._state==1),"battle is ready"):
		finish()
		return
	var view: Dictionary=appearance.actors[hero_id]
	var target: CharacterStats=controller._team_living_enemies()[0].stats
	target.max_hp=10000
	target.hp=10000
	target.attack=1
	target.inner_power=1
	var pose: Node2D=view.pose
	check(pose.current_weapon=="unarmed" and pose.current_clip=="ready_palm","unarmed uses a dedicated battle guard")
	for id: StringName in CASES:
		var expected: String=CASES[id]
		var previous_weapon: String=pose.current_weapon
		check(inv.equip(id),"equip "+String(id))
		if not check(await until(func():return pose.current_clip==expected and pose.current_weapon!=previous_weapon,1600),"dedicated ready "+String(id)):
			continue
		check(pose.current_frame==0 and pose.body.texture.atlas==appearance.textures[expected],"real authored stance "+String(id))
		check(pose.socket.visible==(expected!="ready_palm"),"appropriate weapon visibility "+String(id))
		if expected=="ready_staff":
			check(pose.ready_fingers.visible and pose.far_ready_fingers.visible,"both staff grips draw above weapon")
		if id in [&"seven_star_sword",&"jinhe_duanyue_blade",&"heaven_piercing_staff",&"immortal_gauntlets"]:
			await shot(String(id)+"_ready")
	if is_instance_valid(controller):
		state.player.hp=state.player.max_hp
	for pair in [[&"basic_attack","attack_fist"],[&"palm_strike","attack_palm"]]:
		if not is_instance_valid(controller):
			break
		var skills: Array=controller._skills_for_stats(controller._team_active_unit.stats)
		var action := -1
		for i in skills.size():
			if skills[i].skill_id==pair[0]:
				action=i
				break
		if not check(action>=0,"actual selectable skill "+String(pair[0])):
			continue
		var previous:=strikes
		controller._on_skill_selected(action)
		if check(await until(func():return view.active and pose.current_clip==pair[1] and pose.current_frame==2,6000),"actual impact pose "+String(pair[1])):
			check(not pose.socket.visible and pose.gauntlets.visible and strikes==previous+1,"hands only at the native impact tick")
			await shot(pair[1])
		check(await until(func():return is_instance_valid(controller) and controller._state==1 and pose.current_clip=="ready_palm",12000),"returns to raised-hand guard")
	check(strikes==2,"exactly one native strike per action")
	if not is_instance_valid(controller):
		finish()
		return
	controller._player_action_flee()
	check(await until(func():
		var returned:=get_first_node_in_group("player") as Player
		return returned!=null and returned.get_instance_id()!=record_id and returned.position.distance_to(original_foot)<1.0
	),"battle returns to the original map foot")
	finish()