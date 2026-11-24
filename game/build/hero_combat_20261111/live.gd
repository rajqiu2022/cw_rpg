extends "res://build/zhuwei_hunting_market_20261110/live.gd"

var strike_count := 0
var sounds: Array[String] = []
var done := false
var sampled: Array[String] = []
var capture_actions := true

func _run() -> void:
	await process_frame
	capture_actions = "timing" not in OS.get_cmdline_user_args()
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
	state.player.skills.append(&"wanxiang_breaking_sword")
	var inventory:=root.get_node("Inventory")
	inventory.add_item(&"seven_star_sword")
	inventory.equip(&"seven_star_sword")
	var field:=await enter(&"linxi_tutorial")
	if field==null:finish();return
	await settle(field)
	if dialogue.is_playing():dialogue.call("_end_dialog")
	var field_hero: Player=field.get("_player")
	var original_foot:=field_hero.global_position
	var world: Node2D=field.get("world_container")
	var size: Vector2=field.get("_world_size")
	router.start_battle("thug_lone",&"linxi_tutorial",world.to_local(original_foot)/size)
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn" and current_scene.get("_state")==1,15000),"real battle starts"):finish();return
	var battle:=current_scene
	var actor: BattleActor=battle.formation_view.get_actor(&"player")
	var target: BattleActor=battle.formation_view.get_actor(battle._team_enemies[0].unit_id)
	var runtime:=root.get_node("LayeredAppearanceRuntime")
	expect(actor.HERO_COMBAT.available(actor),"all four strict native action sheets loaded")
	actor.strike_reached.connect(func():strike_count+=1)
	root.get_node("EventBus").sfx_requested.connect(func(path: String,_gain: float):sounds.append(path))
	var home:=actor.position
	if not capture_actions:
		# Exact retained legacy path, isolated memory only; no source rollback.
		var leap_clip: Dictionary=runtime.manifest.clips.fast_leap
		runtime.manifest.clips.erase("fast_leap")
		actor.set_action_time_scale(1.12)
		var legacy_start:=Time.get_ticks_msec()
		await actor.play_attack_approach(target,false)
		await actor.play_attack_recover()
		print("LEGACY_PRESENTATION_MS=",Time.get_ticks_msec()-legacy_start)
		runtime.manifest.clips.fast_leap=leap_clip
		actor.set_action_time_scale(0.82)
	for trial in [[&"seven_star_sword","slash"],[&"jinhe_duanyue_blade","blade"],[&"golden_hoop_staff","staff"],[&"","palm"]]:
		if trial[0]==&"":inventory.unequip(Equipment.Slot.WEAPON)
		else:
			inventory.add_item(trial[0])
			inventory.equip(trial[0])
		actor.action_pose="attack_palm" if trial[1]=="palm" else ""
		actor.legendary_choreography=false
		await process_frame
		strike_count=0
		done=false
		sampled.clear()
		var start:=Time.get_ticks_msec()
		perform(actor,target)
		while not done:
			if not actor.combat_clip.is_empty():
				var token:=actor.combat_clip+str(actor.combat_frame)
				if token not in sampled:
					sampled.append(token)
					if capture_actions:await shot(trial[1]+"_"+token)
			await process_frame
		var elapsed:=Time.get_ticks_msec()-start
		print("ACTION_MS ",trial[1],"=",elapsed," capture=",capture_actions," frames=",sampled)
		expect(strike_count==1,trial[1]+" one native strike")
		expect(actor.position.distance_to(home)<0.1,trial[1]+" returns to same formation slot")
		if not capture_actions:expect(elapsed<1300,trial[1]+" does not retain slow walk windup")
		expect(sampled.size()>=3,trial[1]+" displays multiple different source poses")
		# Both formation directions must use the same source and grip.
		var pose: Node2D=runtime.actors[actor.get_instance_id()].pose
		for facing in [-1,1]:
			for i in range(4):
				pose.show_pose("golden_hoop_staff" if trial[1]=="staff" else ("unarmed" if trial[1]=="palm" else ("jinhe_duanyue_blade" if trial[1]=="blade" else "seven_star_sword")),"fast_staff" if trial[1]=="staff" else ("fast_palm" if trial[1]=="palm" else "fast_slash"),i,facing,0.0)
				expect(pose.body.texture!=null and pose.scale.x==facing,"native action frame mirrored "+trial[1]+str(i))
	actor.legendary_choreography=true
	actor.action_pose="attack_palm"
	inventory.unequip(Equipment.Slot.WEAPON)
	strike_count=0
	done=false
	sampled.clear()
	var orange_start:=Time.get_ticks_msec()
	perform(actor,target,true)
	while not done:
		if not actor.combat_clip.is_empty():
			var token:=actor.combat_clip+str(actor.combat_frame)
			if token not in sampled:
				sampled.append(token)
				if capture_actions:await shot("orange_palm_"+token)
		await process_frame
	print("ORANGE_PALM_PRESENTATION_MS=",Time.get_ticks_msec()-orange_start," capture=",capture_actions)
	expect(strike_count==1 and sampled.has("fast_palm3") and (capture_actions or sampled.has("fast_leap2")),"orange tumble and palm finish preserve single strike")
	expect(sounds.has("res://art/audio/free/sfx_staff_whoosh_wuxia_v2.wav") and sounds.has("res://art/audio/free/sfx_palm_burst_wuxia_v2.wav"),"jump and palm sound requests actually fired")
	inventory.equip(&"seven_star_sword")
	actor.action_pose=""
	actor.legendary_choreography=false
	var enemy: BattleCombatant=battle._team_enemies[0]
	enemy.stats.hp=1
	var skills: Array=battle._skills_for_stats(battle._team_active_unit.stats)
	strike_count=0
	var chosen:=-1
	for i in skills.size():
		if skills[i].skill_id==&"wanxiang_breaking_sword":chosen=i
	if expect(chosen>=0,"original orange sword skill available"):
		battle._team_active_unit.stats.mp=battle._team_active_unit.stats.max_mp
		battle._team_player_action_skill_use(chosen,enemy.unit_id)
		if expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/result_victory.tscn",30000),"original orange skill resolves victory"):
			expect(strike_count==1,"complex sword choreography did not multiply damage trigger")
			current_scene.get_node("%BtnContinue").pressed.emit()
			if expect(await wait_for(func():return current_scene!=null and current_scene.has_method("get_field_loading_state") and router.get_current_field_id()==&"linxi_tutorial" and current_scene.get_field_loading_state().get("complete",false),15000),"normal result returns to field"):
				expect((current_scene.get("_player") as Player).global_position.distance_to(original_foot)<1,"original encounter foot retained")
	finish()

func perform(actor: BattleActor,target: BattleActor,skill:=false) -> void:
	await actor.play_attack_approach(target,skill)
	await actor.play_attack_recover()
	done=true
