extends "res://build/layered_actor_adoption_20261106/game_qa.gd"

const WEAPONS := {
	&"jinhe_duanyue_blade":"jinhe_duanyue_blade",
	&"iron_sword":"plain_sword",
	&"iron_great_blade":"plain_blade",
	&"seven_star_sword":"seven_star_sword",
	&"wooden_staff":"plain_staff",
	&"buddha_subduing_staff":"buddha_subduing_staff",
	&"heaven_piercing_staff":"heaven_piercing_staff",
	&"golden_hoop_staff":"golden_hoop_staff",
}
const STAFF := ["plain_staff","buddha_subduing_staff","heaven_piercing_staff","golden_hoop_staff"]
var staff_side_only := false

func finish() -> void:
	var report_name := "staff_side_report.json" if staff_side_only else "field_carry_report.json"
	FileAccess.open(OUT+report_name,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"strikes":strikes},"\t"))
	print("FIELD_CARRY ",checks.size()," checks / ",failures," failures")
	quit(0 if failures==0 else 1)

func run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var game_state:=root.get_node("GameState")
	var inv:=root.get_node("Inventory")
	var router:=root.get_node("SceneRouter")
	var runtime:=root.get_node("LayeredAppearanceRuntime")
	game_state.reset_for_new_game()
	inv.reset_for_new_game()
	router.reset_for_new_game()
	game_state.player.max_hp=1000
	game_state.player.hp=1000
	staff_side_only="staff-side" in OS.get_cmdline_user_args()
	var items: Array=WEAPONS.keys()
	if staff_side_only:
		items=items.filter(func(item): return WEAPONS[item] in STAFF)
	for item: StringName in items:
		check(inv.add_item(item),"grant "+String(item))
	check(router.go_field_smart(FIELD,Vector2(.835,.470)),"enter Linxi")
	if not check(await until(func(): return get_first_node_in_group("player") is Player),"Linxi Player exists"):
		finish()
		return
	var player:=get_first_node_in_group("player") as Player
	var player_id:=player.get_instance_id()
	if not check(await until(func(): return runtime.actors.get(player_id,{}).get("active",false)),"layered Player active"):
		finish()
		return
	var pose: Node2D=runtime.actors[player_id].pose
	for item: StringName in items:
		var appearance: String=WEAPONS[item]
		var back:=appearance in STAFF
		check(inv.equip(item),"equip "+appearance)
		for direction: Vector2 in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
			player.set_walk_direction(direction,false)
			var clip: String="idle_up" if direction==Vector2.UP else ("idle_down" if direction==Vector2.DOWN else "idle")
			var facing: int=-1 if direction==Vector2.LEFT else 1
			if not check(await until(func(): return pose.current_weapon==appearance and pose.current_clip==clip and pose.current_facing==facing,2500),"field facing "+appearance+" "+str(direction)):
				continue
			check(pose.current_sheathed!=back and pose.current_back_carried==back and not pose.hand.visible and not pose.ready_fingers.visible,"free hands and correct carry "+appearance+" "+clip)
			if back:
				check((pose.socket.z_index>pose.body.z_index)==(direction==Vector2.UP),"staff occlusion "+appearance+" "+clip)
			if staff_side_only:
				var expected: float=0.0 if clip=="idle" else (-33.0 if clip=="idle_up" else 33.0)
				check(is_equal_approx(pose.socket.rotation_degrees,expected),"staff projected angle "+appearance+" "+str(direction))
				if appearance!="plain_staff":
					check(pose.star_particles.visible==(clip!="idle"),"particles respect view "+appearance+" "+str(direction))
				if appearance=="golden_hoop_staff":
					var facing_name: String={Vector2.LEFT:"left",Vector2.RIGHT:"right",Vector2.UP:"rear",Vector2.DOWN:"front"}[direction]
					await shot("staff_side_"+facing_name)
				continue
			if appearance=="jinhe_duanyue_blade":
				check(pose.star_particles.visible and pose.enchantment.get_shader_parameter("sheath_throat")>0.0,"Jinhe embers at throat")
			if (appearance in ["jinhe_duanyue_blade","plain_sword"] and direction==Vector2.RIGHT) or (appearance=="golden_hoop_staff" and direction in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN]):
				await shot("carry_fix_"+appearance+"_"+str(direction))
	if staff_side_only:
		for keycode: int in [KEY_A,KEY_D]:
			var start:=player.position
			var event:=InputEventKey.new()
			event.physical_keycode=keycode
			event.pressed=true
			Input.parse_input_event(event)
			var facing: int=-1 if keycode==KEY_A else 1
			check(await until(func(): return player.position.distance_to(start)>20.0 and pose.current_clip=="walk" and pose.current_facing==facing and pose.current_back_carried and is_zero_approx(pose.socket.rotation) and not pose.star_particles.visible,2800),"side gait "+str(facing))
			await shot("staff_side_walk_left" if facing<0 else "staff_side_walk_right")
			var release:=event.duplicate() as InputEventKey
			release.pressed=false
			Input.parse_input_event(release)
			await process_frame
		finish()
		return
	var initial:=player.position
	var key:=InputEventKey.new()
	key.physical_keycode=KEY_S
	key.pressed=true
	Input.parse_input_event(key)
	check(await until(func(): return pose.current_clip=="walk_down" and pose.current_back_carried and player.position.distance_to(initial)>20.0,2800),"real S movement retains back carry")
	var released:=key.duplicate() as InputEventKey
	released.pressed=false
	Input.parse_input_event(released)
	await process_frame
	var return_position:=player.position
	var return_uv: Vector2=return_position/current_scene.get("_world_size")
	router.start_battle("ancient_tomb_guard",FIELD,return_uv)
	if not check(await until(func(): return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn"),"battle arrived"):
		finish()
		return
	var controller:=current_scene
	var actor: BattleActor=controller.formation_view.get_actor(&"player")
	actor.strike_reached.connect(func(): strikes+=1)
	var actor_id:=actor.get_instance_id()
	if not check(await until(func(): return runtime.actors.get(actor_id,{}).get("active",false) and controller._state==1),"battle ready"):
		finish()
		return
	var battle_pose: Node2D=runtime.actors[actor_id].pose
	for item: StringName in [&"iron_sword",&"golden_hoop_staff",&"jinhe_duanyue_blade"]:
		var appearance: String=WEAPONS[item]
		check(inv.equip(item),"equip in battle "+appearance)
		check(await until(func(): return battle_pose.current_weapon==appearance and battle_pose.current_clip=="idle" and battle_pose.ready_fingers.visible and not battle_pose.current_sheathed and not battle_pose.current_back_carried,3000),"battle holds weapon "+appearance)
	check(battle_pose.star_particles.visible and battle_pose.weapon.material==battle_pose.enchantment and battle_pose.enchantment.get_shader_parameter("intensity")>1.0,"Jinhe drawn glow and particles")
	await shot("carry_fix_jinhe_ready")
	var basic:=-1
	var skills: Array=controller._skills_for_stats(controller._team_active_unit.stats)
	for i in range(skills.size()):
		if skills[i].skill_id==&"basic_attack":
			basic=i
			break
	if check(basic>=0,"ordinary attack available"):
		controller._on_skill_selected(basic)
		if check(await until(func(): return battle_pose.current_clip=="attack_dao" and battle_pose.current_frame==2 and battle_pose.star_particles.visible,7000),"Jinhe strike with embers"):
			await shot("carry_fix_jinhe_strike")
		check(strikes==1,"one native strike")
	if check(await until(func(): return current_scene==controller and controller._state==1,13000),"next combat turn"):
		controller._player_action_flee()
		check(await until(func():
			var p:=get_first_node_in_group("player") as Player
			return p!=null and p.get_instance_id()!=player_id and p.position.distance_to(return_position)<1.0 and runtime.actors.get(p.get_instance_id(),{}).get("active",false) and runtime.actors[p.get_instance_id()].pose.current_sheathed
		),"retreat restores waist carry at original field foot")
	finish()
