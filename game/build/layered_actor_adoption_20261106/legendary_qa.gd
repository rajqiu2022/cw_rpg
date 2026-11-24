extends "res://build/layered_actor_adoption_20261106/game_qa.gd"

const IDS: Array[StringName] = [&"yuanming_sword",&"tiger_roar_blade",&"buddha_subduing_staff"]
const BATCH02: Array[StringName] = [
	&"heaven_piercing_staff",&"golden_hoop_staff",&"immortal_gauntlets",
	&"zhouju_bronze_sword",&"suwusheng_teapot",
]
const DATA = preload("res://scripts/appearance/legendary_weapon_data.gd")
const PICKER = preload("res://scripts/appearance/legendary_gm_picker.gd")
var batch02 := false

func finish() -> void:
	var report_name := "legendary_batch02_report.json" if batch02 else "legendary_report.json"
	FileAccess.open(OUT+report_name,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"strikes":strikes},"\t"))
	print("LEGENDARY_GAME ",checks.size()," checks / ",failures," failures")
	quit(0 if failures==0 else 1)

func run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var game_state=root.get_node("GameState")
	var inv=root.get_node("Inventory")
	var router=root.get_node("SceneRouter")
	var appearance=root.get_node("LayeredAppearanceRuntime")
	batch02="batch02" in OS.get_cmdline_user_args()
	var selected_ids: Array[StringName]=BATCH02 if batch02 else IDS
	game_state.reset_for_new_game()
	inv.reset_for_new_game()
	router.reset_for_new_game()
	# Longer survival for appearance checks in one real encounter, memory only.
	game_state.player.max_hp=1000
	game_state.player.hp=1000
	if batch02:
		if not await _check_gm(inv):
			finish()
			return
	else:
		for id in selected_ids:
			check(inv.add_item(id),"add existing "+String(id))
	check(router.go_field_smart(FIELD,Vector2(.835,.470)),"enter real Linxi")
	if not check(await until(func(): return current_scene!=null and get_first_node_in_group("player") is Player),"Linxi field arrived"):
		finish()
		return
	var player:=get_first_node_in_group("player") as Player
	var player_id:=player.get_instance_id()
	if not check(await until(func(): return appearance.actors.get(player_id,{}).get("active",false)),"HD field runtime active"):
		finish()
		return
	var view: Dictionary=appearance.actors[player_id]
	for id in selected_ids:
		var key:=String(id)
		check(inv.equip(id),"equip field "+key)
		var sheathed:=not DATA.sheath_for(key).is_empty()
		var concealed: bool=DATA.WEAPONS.get(key,{}).get("concealed",false)
		for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
			player.set_walk_direction(direction,false)
			var clip: String="idle_up" if direction==Vector2.UP else ("idle_down" if direction==Vector2.DOWN else "idle")
			var facing: int=-1 if direction==Vector2.LEFT else 1
			check(await until(func():
				return view.pose.current_weapon==key and view.pose.current_clip==clip and view.pose.current_facing==facing
			,2500),"real field facing "+key+" "+str(direction))
			var effects_visible: bool=view.pose.gauntlets.visible if key=="immortal_gauntlets" else view.pose.star_particles.visible
			check(view.pose.current_sheathed==sheathed and effects_visible!=concealed,"carry and FX "+key)
			if concealed:
				check(not view.pose.socket.visible,"concealed weapon hidden in field "+str(direction))
			if key=="immortal_gauntlets":
				check(view.pose.gauntlets.hand_sprites[0].visible and view.pose.gauntlets.hand_sprites[1].visible and not view.pose.socket.visible,"both gauntlets replace empty hands "+str(direction))
				if direction==Vector2.DOWN:
					await shot("legendary_field_front_"+key)
			if direction==Vector2.RIGHT:
				check(view.pose.carry_arm.visible==sheathed,"correct near arm layering "+key)
				await shot("legendary_field_"+key)
	var return_position:=player.position
	var return_uv: Vector2=return_position/current_scene.get("_world_size")
	router.start_battle("ancient_tomb_guard",FIELD,return_uv)
	if not check(await until(func(): return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn"),"real encounter loaded"):
		finish()
		return
	var controller=current_scene
	var hero: BattleActor=controller.formation_view.get_actor(&"player")
	if not check(hero!=null,"real formation hero"):
		finish()
		return
	hero.strike_reached.connect(func(): strikes+=1)
	var hero_id:=hero.get_instance_id()
	if not check(await until(func(): return appearance.actors.get(hero_id,{}).get("active",false) and controller._state==1),"battle hero can act"):
		finish()
		return
	var battle: Dictionary=appearance.actors[hero_id]
	var target_stats: CharacterStats=controller._team_living_enemies()[0].stats
	target_stats.max_hp=1500
	target_stats.hp=1500
	for id in selected_ids:
		var key:=String(id)
		var concealed: bool=DATA.WEAPONS.get(key,{}).get("concealed",false)
		if inv.get_equipped_id(0)!=id:
			check(inv.equip(id),"equip battle "+key)
		if not check(await until(func():
			return battle.active and battle.pose.current_weapon==key and battle.pose.current_clip=="idle"
		,3000),"real ready grip "+key):
			finish()
			return
		check(not battle.pose.current_sheathed,"battle pose is unsheathed "+key)
		if key=="immortal_gauntlets":
			check(battle.pose.gauntlets.visible and battle.pose.gauntlets.emitters[0].visible and battle.pose.gauntlets.emitters[1].visible and battle.pose.gauntlets.emitters[0].position.distance_to(battle.pose.gauntlets.emitters[1].position)>20.0,"two separate battle hand emitters")
		elif concealed:
			check(not battle.pose.socket.visible and not battle.pose.ready_fingers.visible,"hidden through battle ready "+key)
		else:
			check(battle.pose.ready_fingers.visible and battle.pose.star_particles.visible and battle.pose.weapon.material==battle.pose.enchantment,"ready grip and battle FX "+key)
			var palette: Color=DATA.WEAPONS[key].tint
			var mote: Sprite2D=battle.pose.star_particles.motes[0]
			check(Vector3(mote.modulate.r,mote.modulate.g,mote.modulate.b).is_equal_approx(Vector3(palette.r,palette.g,palette.b)),"distinct palette "+key)
		await shot("legendary_ready_"+key)
		var basic:=-1
		var skills: Array=controller._skills_for_stats(controller._team_active_unit.stats)
		for i in range(skills.size()):
			if skills[i].skill_id==&"basic_attack":
				basic=i
				break
		if not check(basic>=0,"normal attack exists "+key):
			finish()
			return
		var expected: String="attack_dao" if DATA.WEAPONS.get(key,{}).get("heavy",false) else "attack"
		var previous_strikes:=strikes
		controller._on_skill_selected(basic)
		if check(await until(func(): return battle.active and battle.pose.current_clip==expected and battle.pose.current_frame==2,7000),"real strike pose "+key):
			if key=="immortal_gauntlets":
				check(battle.pose.gauntlets.emitters[0].position.x>160.0 and battle.pose.gauntlets.emitters[1].position.x<0.0,"both gauntlet sparks follow separate fists at strike")
			if concealed:
				check(battle.pose.socket.visible and battle.pose.star_particles.visible and battle.pose.weapon.material==battle.pose.enchantment,"concealed weapon appears with enchantment at strike")
			await shot("legendary_attack_"+key)
		check(strikes==previous_strikes+1,"one native strike "+key)
		if not check(await until(func(): return current_scene==controller and controller._state==1,13000),"action returns to next player turn "+key):
			finish()
			return
	controller._player_action_flee()
	check(await until(func():
		var p:=get_first_node_in_group("player") as Player
		return p!=null and p.get_instance_id()!=player_id and p.position.distance_to(return_position)<1.0
	),"retreat returns to original field foot")
	finish()

func _check_gm(inv: Node) -> bool:
	var gm:=root.get_node("GMConsole")
	var search: LineEdit=gm.get("_item_search")
	var options: OptionButton=gm.get("_item_select")
	var shortcut:=search.get_parent().get_node_or_null("LegendaryAppearanceFilter") as Button
	if not check(shortcut!=null,"real GM shortcut attached"):
		return false
	gm.call("_toggle_panel")
	await process_frame
	shortcut.pressed.emit()
	var listed: Dictionary={}
	for i in range(options.item_count):
		listed[StringName(options.get_item_metadata(i))]=i
	for id in PICKER.FEATURED:
		if not check(listed.has(id),"GM list includes "+String(id)):
			return false
	for id in PICKER.FEATURED:
		options.select(listed[id])
		gm.call("_give_selected_item")
		if not check(inv.has_item(id),"GM grants "+String(id)):
			return false
	search.text="金箍棒"
	search.text_changed.emit(search.text)
	check(options.item_count==1 and options.get_item_metadata(0)==&"golden_hoop_staff","GM alias finds golden hoop staff")
	search.text="渊冥古剑"
	search.text_changed.emit(search.text)
	check(options.item_count==1 and options.get_item_metadata(0)==&"yuanming_sword","normal GM search finds first batch")
	shortcut.pressed.emit()
	var panel: Control=gm.get("_panel")
	for button: Button in panel.find_children("*","Button",true,false):
		if button.text=="刷新数据":
			button.pressed.emit()
			await process_frame
			check(options.item_count==PICKER.FEATURED.size(),"GM refresh preserves legendary filter")
			break
	await shot("legendary_batch02_gm")
	gm.call("_toggle_panel")
	return true
