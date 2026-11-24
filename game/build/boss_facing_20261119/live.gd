extends "res://build/victory_quest_20261108/story_live.gd"

var seen := {}
var facing_errors := {}
var watching := false
var live_actor: BattleActor

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router=root.get_node("SceneRouter")
	state=root.get_node("GameState")
	state.reset_for_new_game()
	router.reset_for_new_game()
	state.add_companion(&"tang_xingzhou")
	state.add_companion(&"shen_qinghe")
	state.player.speed=1000
	state.player.agility=100
	var ids: Array[StringName]=[&"ch7_lieyun_hardliner_guard"]
	router.start_encounter(ids,&"linxi_tutorial")
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn" and current_scene.get("_state")==1,22000),"PC battle ready"):
		finish()
		return
	var battle := current_scene
	var enemy: BattleCombatant=battle.get("_team_enemies")[0]
	live_actor=battle.call("_team_actor",enemy.unit_id)
	var hero: BattleActor=battle.call("_team_actor",battle.get("_team_allies")[0].unit_id)
	watching=true
	process_frame.connect(_sample)
	await create_timer(0.35).timeout
	expect(live_actor.artwork.flip_h,"boss ready faces the hero to the left")
	await shot("ready")
	var strike_count := [0]
	live_actor.strike_reached.connect(func(): strike_count[0]+=1)
	await live_actor.play_attack_approach(hero,false)
	await shot("strike")
	await live_actor.play_attack_recover()
	await shot("recovered")
	expect(strike_count[0]==1,"one normal strike, no duplicated attack")
	expect(live_actor.artwork.flip_h,"boss recovers toward hero")
	await live_actor.play_hit(1,false,false,hero)
	expect(live_actor.artwork.flip_h,"hit reaction restores facing")
	watching=false
	for path: String in seen: print("FACING_FRAME ",path," ",seen[path])
	expect(facing_errors.is_empty(),"all displayed source frames face left "+str(facing_errors))
	expect(seen.has("masked_killer_boss_attack_f02_v2.png"),"actual forward strike frame sampled")
	expect(not BattleSpriteFacing.faces_right(load("res://art/sprites/battle/standard_v2/masked_killer/masked_killer_ready_01.png"),true),"independent standard masked killer remains left-authored")
	live_actor.call("_set_attack_facing",1.0)
	expect(not live_actor.artwork.flip_h,"rightward target uses unmirrored source")
	live_actor.call("_set_attack_facing",-1.0)
	expect(live_actor.artwork.flip_h,"return to leftward target")
	# All definitions sharing this source must obey the same rule.
	var consumers := 0
	for file: String in ResourceLoader.list_directory("res://data/enemies/"):
		if not file.ends_with(".tres"):continue
		var def := load("res://data/enemies/"+file) as EnemyDef
		if def==null or def.battle_actor_path!="res://art/characters/battle_masked_killer_boss_v2.png":continue
		consumers+=1
		for state_name: StringName in [&"ready",&"move",&"attack",&"hit",&"defeat"]:
			var frames: Array[Texture2D]=battle.call("_load_enemy_frames",def,state_name)
			for texture: Texture2D in frames:
				expect(BattleSpriteFacing.faces_right(texture,def.battle_actor_flip_h),"source direction "+String(def.enemy_id)+"/"+state_name+"/"+texture.resource_path.get_file())
	print("FACING_CONSUMERS ",consumers)
	finish()

func _sample() -> void:
	if not watching or not is_instance_valid(live_actor):return
	var texture := live_actor.artwork.texture
	if texture==null:return
	var filename := texture.resource_path.get_file()
	seen[filename]=live_actor.artwork.flip_h
	if not live_actor.artwork.flip_h:facing_errors[filename]=true

func shot(label: String) -> void:
	if not "visual" in OS.get_cmdline_user_args():return
	await RenderingServer.frame_post_draw
	var path := "user://boss-facing-"+label+".png"
	root.get_texture().get_image().save_png(path)
	print("FACING_PNG ",ProjectSettings.globalize_path(path))
