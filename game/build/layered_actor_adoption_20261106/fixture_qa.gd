extends SceneTree
var checks: Array=[]
var failures:=0
var runtime: Node
var stage: Node2D
var player: Player
var battle: BattleActor
const OUT="res://build/layered_actor_adoption_20261106/evidence/"
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks.append({"name":label,"pass":ok}); if not ok: failures+=1; print("FAIL "+label)
func settle(count:=3) -> void:
	for i in range(count): await process_frame
func shot(name: String) -> void:
	await settle(); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
func run() -> void:
	await settle()
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	root.size=Vector2i(1280,900)
	root.get_node("GameState").reset_for_new_game(); root.get_node("Inventory").reset_for_new_game()
	runtime=root.get_node_or_null("LayeredAppearanceRuntime")
	if runtime==null:
		runtime=load("res://scripts/appearance/layered_appearance_runtime.gd").new(); root.add_child(runtime)
	stage=Node2D.new(); root.add_child(stage); current_scene=stage
	var bg:=Polygon2D.new(); bg.polygon=PackedVector2Array([Vector2.ZERO,Vector2(1280,0),Vector2(1280,900),Vector2(0,900)]); bg.color=Color("26343b"); bg.z_index=-10; stage.add_child(bg)
	player=load("res://scenes/player.tscn").instantiate(); stage.add_child(player); player.position=Vector2(220,400); player.set_ground_anchored(true); player.set_physics_process(false); player.set_visual_scale_multiplier(2.5)
	var inv=root.get_node("Inventory")
	for id in ["seven_star_sword","jinhe_duanyue_blade"]: check(inv.add_item(StringName(id)),"add "+id)
	check(inv.equip(&"seven_star_sword"),"equip sword")
	await settle(10)
	check(not runtime.load_failed,"verified images loaded")
	var r: Dictionary=runtime.actors[player.get_instance_id()]
	check(r.active,"real Player active")
	check(player.sprite.self_modulate.a==0,"native sprite hidden without replacing source")
	var collision_before: Vector2=player.get_node("CollisionShape2D").position
	for dir in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		player.set_walk_direction(dir,true)
		for f in range(8):
			player.sprite.frame=f; await settle(2)
			check(r.pose.current_frame==f,"walk synced %s %d"%[dir,f])
			if dir in [Vector2.RIGHT,Vector2.LEFT]:
				check(r.pose.carry_arm.visible and r.pose.carry_arm.z_index>r.pose.socket.z_index and r.pose.socket.z_index>r.pose.body.z_index,"arm over sheath over body %s %d"%[dir,f])
		player.set_walk_direction(dir,false); await settle(2)
		check(r.pose.current_clip.begins_with("idle"),"idle direction "+str(dir))
		var facing_label: String = "down" if dir==Vector2.DOWN else ("up" if dir==Vector2.UP else "side")
		var pose_socket: Node2D = r.pose.socket
		if facing_label=="side":
			check(is_equal_approx(rad_to_deg(pose_socket.rotation),-133.0) and is_equal_approx(pose_socket.scale.x,0.49),"side scabbard transform unchanged")
			check(r.pose.carry_arm.visible and r.pose.carry_arm.z_index>pose_socket.z_index,"side idle arm covers scabbard")
		else:
			check(absf(rad_to_deg(pose_socket.rotation))>165.0,"scabbard stays close to body "+facing_label)
			check(pose_socket.z_index==(0 if dir==Vector2.UP else 2),"correct hip occlusion "+facing_label)
	var particles: Node2D = r.pose.star_particles
	var before_mote: Vector2 = particles.get_child(3).position
	await create_timer(0.22).timeout
	check(particles.get_child_count()==22 and particles.get_child(3).position.distance_to(before_mote)>12.0,"live particles move independently of stationary scabbard")
	check(player.get_node("CollisionShape2D").position==collision_before,"collision untouched")
	player.set_walk_direction(Vector2.RIGHT,false)
	battle=load("res://scenes/battle_actor.tscn").instantiate(); stage.add_child(battle); battle.position=Vector2(620,220); battle.unit_id=&"player"
	var sets: Array=[]
	for action in ["ready","move","attack","hit","defeat"]:
		var frames: Array[Texture2D]=[]
		for f in range(4):
			var path:="res://art/sprites/battle/weapon_variants_v4/lengguyun/sword/lengguyun_sword_%s_%02d.png"%[action,f+1]
			frames.append(load(path))
		sets.append(frames)
	battle.configure(sets[0][0],false,true,sets[0],sets[1],sets[2],sets[3],sets[4]); battle.set_process(false)
	await settle(4)
	var b: Dictionary=runtime.actors[battle.get_instance_id()]
	check(b.active,"real BattleActor active")
	check(not b.pose.current_sheathed and b.pose.ready_fingers.visible and not b.pose.carry_arm.visible,"battle idle keeps sword drawn")
	for direction in [-1.0,1.0]:
		battle._visual_direction=direction
		for f in range(4):
			battle.artwork.texture=sets[0][f]
			await settle(2)
			var pose=b.pose
			var fingers: Polygon2D=pose.ready_fingers
			var handle_inside: Vector2=pose.socket.position+Vector2.DOWN.rotated(pose.socket.rotation)*15.0-fingers.position
			check(fingers.visible and not pose.hand.visible and pose.current_facing==int(direction) and Geometry2D.is_point_in_polygon(handle_inside,fingers.polygon),"hilt passes under fingers frame %d facing %s"%[f,direction])
	await shot("grip_fixture_ready")
	for action in range(5):
		for f in range(4):
			battle.artwork.texture=sets[action][f]; await settle(2)
			check(b.active,"battle native frame %d %d"%[action,f])
	battle.artwork.texture=sets[0][0]
	await settle()
	check(b.pose.current_clip=="idle" and not b.pose.current_sheathed and b.pose.ready_fingers.visible,"after an attack, ready frame keeps sword drawn")
	check(inv.equip(&"jinhe_duanyue_blade"),"equip dao")
	await settle(3)
	battle.artwork.texture=sets[2][2]; await settle()
	check(b.pose.current_clip=="attack_dao","dao independent attack")
	check(not particles.visible,"other equipment hides sword particles")
	player.set_building_overlap(true,.42,true)
	await settle()
	check(r.ghost_view.visible and r.ghost.self_modulate.a==0,"layered ghost replaces old baked ghost")
	check(is_equal_approx(r.ghost.modulate.a,.42),"ghost alpha exactly owner .42")
	var wall:=Polygon2D.new(); wall.polygon=PackedVector2Array([Vector2(140,150),Vector2(310,150),Vector2(310,430),Vector2(140,430)]); wall.color=Color("705f4e"); wall.z_index=400; stage.add_child(wall)
	inv.unequip(0); await settle()
	check(r.active and b.active,"unequip retains HD in both consumers")
	check(r.pose.current_weapon=="unarmed" and b.pose.current_weapon=="unarmed","unequip clears equipment from both consumers")
	check(not r.pose.socket.visible and not b.pose.socket.visible,"no orphan weapon or effect")
	var report={"checks":checks,"failures":failures,"state":runtime.debug_state()}
	FileAccess.open(OUT+"grip_fixture_report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LAYERED_FIXTURE ",checks.size()," checks / ",failures," failures")
	quit(0 if failures==0 else 1)
