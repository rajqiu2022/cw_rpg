extends SceneTree
## QA: real Router and battle controller, disposable in-memory inventory.
const OUT="res://build/layered_actor_adoption_20261106/evidence/"
const FIELD=&"linxi_village_center"
var failures:=0
var checks: Array[Dictionary]=[]
var strikes:=0
var movement: Dictionary={}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> bool:
	checks.append({"name":label,"pass":ok})
	if not ok:
		failures+=1
		print("FAIL ",label)
	return ok

func until(predicate: Callable, ms:=20000) -> bool:
	var end:=Time.get_ticks_msec()+ms
	while Time.get_ticks_msec()<end:
		await process_frame
		if predicate.call():
			return true
	return false

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")

func finish() -> void:
	FileAccess.open(OUT+"grip_game_report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"strikes":strikes,"movement":movement},"\t"))
	print("LAYERED_GAME ",checks.size()," checks / ",failures," failures")
	quit(0 if failures==0 else 1)

func run() -> void:
	await process_frame
	var game_state=root.get_node("GameState")
	var inv=root.get_node("Inventory")
	var router=root.get_node("SceneRouter")
	var appearance=root.get_node("LayeredAppearanceRuntime")
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	game_state.reset_for_new_game()
	inv.reset_for_new_game()
	router.reset_for_new_game()
	for id in [&"seven_star_sword",&"jinhe_duanyue_blade",&"iron_sword",&"iron_great_blade",&"wooden_staff"]:
		check(inv.add_item(id),"grant existing item in memory "+String(id))
	check(inv.equip(&"seven_star_sword"),"equip named sword")
	check(router.go_field_smart(FIELD,Vector2(.835,.470)),"real Router accepted Linxi")
	if not check(await until(func(): return current_scene!=null and get_first_node_in_group("player") is Player),"real Linxi Player arrived"):
		finish()
		return
	var player:=get_first_node_in_group("player") as Player
	var player_id:=player.get_instance_id()
	if not check(await until(func(): return appearance.actors.get(player_id,{}).get("active",false) and player.can_move),"field sword visible and operable"):
		finish()
		return
	var view: Dictionary=appearance.actors[player_id]
	check(view.pose.current_weapon=="seven_star_sword" and view.pose.current_sheathed and not view.pose.hand.visible,"sword sheath anchored at waist on real map")
	var start:=player.position
	var walk_frames: Dictionary={}
	var down:=InputEventKey.new()
	down.physical_keycode=KEY_S
	down.pressed=true
	Input.parse_input_event(down)
	var deadline:=Time.get_ticks_msec()+1050
	while Time.get_ticks_msec()<deadline:
		await process_frame
		if view.pose.current_clip.begins_with("walk"):
			walk_frames[view.pose.current_frame]=true
	var up:=down.duplicate() as InputEventKey
	up.pressed=false
	Input.parse_input_event(up)
	movement={"from":str(start),"to":str(player.position),"frames":walk_frames.keys()}
	print("WALK ",movement)
	check(player.position.distance_to(start)>20.0 and walk_frames.size()>=3,"WASD moved real Player and advanced gait")
	player.set_walk_direction(Vector2.UP,false)
	check(await until(func(): return view.pose.current_clip=="idle_up" and view.pose.star_particles.visible,2000),"real scene rear stance uses sheath particles")
	player.set_walk_direction(Vector2.RIGHT,false)
	check(await until(func(): return view.pose.current_clip=="idle" and view.pose.carry_arm.visible,2000),"Linxi side view draws arm above sheath")
	var local_height: float = view.view.global_scale.y * 690.0
	check(local_height>=135.0 and local_height<=138.0,"local side idle matches standing adult scale")
	check(absf(view.view.to_global(Vector2(768,1100)).y-player.get_depth_sort_y())<0.01,"size change preserves authored foot anchor")
	print("HERO_VISUAL_HEIGHT ",local_height)
	for npc: NPCNode in current_scene.get("_npc_nodes"):
		if npc.npc_id=="tang_xingzhou_recruit":
			var previous := player.position
			player.position = npc.position + Vector2(-145.0,npc.get_depth_sort_y()-npc.position.y-player.get_depth_sort_y()+player.position.y)
			player.refresh_depth_sort()
			await process_frame
			player.position=previous
			player.refresh_depth_sort()
			break
	inv.unequip(0)
	check(await until(func(): return view.active and view.pose.current_weapon=="unarmed" and not view.pose.socket.visible,3000),"unequip keeps HD unarmed field art")
	for pair in [[&"iron_sword","plain_sword"],[&"iron_great_blade","plain_blade"],[&"wooden_staff","plain_staff"]]:
		check(inv.equip(pair[0]),"equip "+String(pair[0]))
		var style: String=pair[1]
		check(await until(func(): return view.active and view.pose.current_weapon==style and view.pose.weapon.material==null,3000),"ordinary HD appearance "+style)
		if style=="plain_sword":
			check(not view.pose.star_particles.visible,"ordinary sword has no enchantment particles")
	check(inv.equip(&"jinhe_duanyue_blade"),"equip named dao")
	check(await until(func(): return view.active and view.pose.current_weapon=="jinhe_duanyue_blade",3000),"field uses dao immediately")
	var return_position:=player.position
	var return_uv: Vector2=return_position/current_scene.get("_world_size")
	router.start_battle("central_road_raider",FIELD,return_uv)
	if not check(await until(func(): return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn"),"real battle scene arrived"):
		finish()
		return
	var controller=current_scene
	var controller_ref: WeakRef=weakref(controller)
	var hero: BattleActor=controller.formation_view.get_actor(&"player")
	if not check(hero!=null,"real formation protagonist"):
		finish()
		return
	var hero_id:=hero.get_instance_id()
	if not check(await until(func(): return appearance.actors.get(hero_id,{}).get("active",false) and controller._state==1),"battle appearance active on player turn"):
		finish()
		return
	var battle: Dictionary=appearance.actors[hero_id]
	check(battle.pose.current_weapon=="jinhe_duanyue_blade","same dao in battle")
	check(inv.equip(&"seven_star_sword"),"swap to sword through real Inventory during battle")
	check(await until(func(): return battle.active and battle.pose.current_weapon=="seven_star_sword" and not battle.pose.current_sheathed and battle.pose.ready_fingers.visible,3000),"battle ready stance wraps fingers around sword")
	await shot("grip_battle_ready")
	hero.strike_reached.connect(func(): strikes+=1)
	var basic:=-1
	var skills: Array=controller._skills_for_stats(controller._team_active_unit.stats)
	for i in range(skills.size()):
		if skills[i].skill_id==&"basic_attack":
			basic=i
			break
	if not check(basic>=0,"original basic attack available"):
		finish()
		return
	controller._on_skill_selected(basic)
	if check(await until(func(): return battle.active and battle.pose.current_clip=="attack" and battle.pose.current_frame==2 and not battle.pose.current_sheathed and battle.pose.hand.visible,6000),"real attack draws sword at thumb web"):
		check(battle.pose.weapon.material==battle.pose.enchantment,"blade glow shader is attached to drawn sword")
		check(battle.pose.star_particles.visible,"drawn blade has moving particles")
		check(not battle.pose.ready_fingers.visible and not battle.pose.enchantment.get_shader_parameter("compact_ready_wrap"),"attack retains original grip silhouette")
	check(strikes==1,"original strike fires once")
	var settled:=await until(func():
		var live=controller_ref.get_ref()
		return live==null or live._state==1
	,12000)
	if check(settled,"normal combat resolution finished"):
		if is_instance_valid(controller) and controller._state==1:
			check(await until(func(): return battle.pose.current_clip=="idle" and not battle.pose.current_sheathed and battle.pose.ready_fingers.visible,3000),"after the exchange, real battle ready still holds sword")
			controller._player_action_flee()
		elif await until(func(): return current_scene!=null and current_scene.has_method("_on_continue_pressed"),5000):
			current_scene._on_continue_pressed()
	var returned:=await until(func():
		var p:=get_first_node_in_group("player") as Player
		return p!=null and p.get_instance_id()!=player_id and appearance.actors.get(p.get_instance_id(),{}).get("active",false)
	)
	if check(returned,"return to Linxi with layered equipment"):
		var p:=get_first_node_in_group("player") as Player
		check(p.position.distance_to(return_position)<1.0,"return keeps original field foot")
	finish()
