extends "res://build/layered_actor_adoption_20261106/game_qa.gd"

const KNIFE := &"jinhe_duanyue_blade"

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("user://duanyue_" + name + ".png")==OK,"capture "+name)

func finish() -> void:
	print("DUANYUE_OUTWARD_RESULT ",checks.size(),"/",failures)
	quit(0 if failures==0 else 1)

func _blade_pose(pose: Node2D, face: int) -> bool:
	var socket: Node2D=pose.socket
	var angle: float=22.0 if pose.current_clip=="idle" else float(pose.data.clips[pose.current_clip].frames[pose.current_frame].angle)
	var along := Vector2.UP.rotated(deg_to_rad(angle))
	var edge := Vector2.RIGHT.rotated(deg_to_rad(angle))
	var local := socket.transform
	var data: Dictionary=pose.data.clips[pose.current_clip].frames[pose.current_frame]
	var foot:=Vector2(data.foot[0],data.foot[1])
	var authored:=Vector2(data.grip[0],data.grip[1])
	if pose.current_clip=="idle":
		authored=pose.Carry.READY_SWORD_GRIPS[int(data.cell_index)].web
	return local.origin.is_equal_approx(authored-foot) and local.determinant()<0.0 \
		and (-local.y).normalized().is_equal_approx(along) and local.x.normalized().is_equal_approx(-edge) \
		and pose.scale.x*face>0.0 and pose.star_particles.get_parent()==socket and pose.effects[0].get_parent()==socket

func run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var inv:=root.get_node("Inventory")
	var router:=root.get_node("SceneRouter")
	var runtime:=root.get_node("LayeredAppearanceRuntime")
	inv.reset_for_new_game()
	check(inv.add_item(KNIFE) and inv.equip(KNIFE),"equip actual Duanyue")
	check(router.go_field_smart(FIELD,Vector2(.835,.470)),"Linxi setup")
	if not check(await until(func(): return get_first_node_in_group("player") is Player),"Linxi live"):
		finish(); return
	var player:=get_first_node_in_group("player") as Player
	var field_id:=player.get_instance_id()
	if not check(await until(func(): return runtime.actors.get(field_id,{}).get("active",false) and player.can_move and not root.get_node("LoadingManager").get("_transition_active")),"waist pose active and field operable"):
		finish(); return
	var field_pose: Node2D=runtime.actors[field_id].pose
	check(field_pose.current_sheathed and field_pose.socket.transform.determinant()>0.0,"field sheath is not mirrored")
	router.start_battle("ancient_tomb_guard",FIELD,player.position/current_scene.get("_world_size"))
	if not check(await until(func(): return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn"),"real battle"):
		finish(); return
	var controller:=current_scene
	var actor: BattleActor=controller.formation_view.get_actor(&"player")
	actor.strike_reached.connect(func(): strikes+=1)
	var actor_id:=actor.get_instance_id()
	if not check(await until(func(): return runtime.actors.get(actor_id,{}).get("active",false) and controller._state==1),"battle ready"):
		finish(); return
	var pose: Node2D=runtime.actors[actor_id].pose
	check(pose.current_clip=="idle" and pose.ready_fingers.visible and _blade_pose(pose,pose.current_facing),"live ready grip and outward edge")
	await shot("ready")
	for clip: String in ["idle","attack_dao"]:
		for face: int in [1,-1]:
			for frame: int in range(runtime.manifest.clips[clip].frames.size()):
				pose.show_pose(String(KNIFE),clip,frame,face,0.7)
				check(_blade_pose(pose,face),"all drawn grips %s %d %d" % [clip,face,frame])
	await process_frame
	var skills: Array=controller._skills_for_stats(controller._team_active_unit.stats)
	for i: int in range(skills.size()):
		if skills[i].skill_id!=&"basic_attack": continue
		controller._on_skill_selected(i)
		if check(await until(func(): return pose.current_clip=="attack_dao" and pose.current_frame==2,7000),"real basic attack reaches swing"):
			check(_blade_pose(pose,pose.current_facing) and pose.star_particles.visible,"real strike retains edge and embers")
			await shot("strike")
		break
	check(strikes==1,"exactly one hit signal")
	finish()
