extends "res://build/quest_map_audit_20261108/huilan_live.gd"

const VANISH := "res://art/audio/battle/sfx_enemy_vanish_20261111.wav"
var heard: Array[String] = []
var played := 0

func _hear(path: String, _db: float) -> void:
	heard.append(path)
	if path == VANISH:
		var audio := root.get_node("AudioManager")
		var pool: Array = audio.get("_sfx_pool")
		var last: AudioStreamPlayer = pool[posmod(audio.get("_sfx_index") - 1, pool.size())]
		if last.playing and last.stream.resource_path == VANISH:
			played += 1

func _begin(ids: Array[StringName]) -> Node:
	var party: Array[Dictionary] = []
	var old_id := current_scene.get_instance_id() if current_scene != null else 0
	router.start_party_encounter(party, ids, &"linxi_tutorial", Vector2(.5,.72))
	if not expect(await wait_for(func(): return current_scene != null and current_scene.get_instance_id() != old_id and current_scene.scene_file_path == "res://scenes/battle.tscn" and current_scene.get("_state") == 1, 25000), "battle ready " + str(ids)):
		return null
	heard.clear()
	played = 0
	return current_scene

func _kill(battle: Node, skill_id: StringName) -> void:
	var battle_id := battle.get_instance_id()
	var skills: Array = battle._skills_for_stats(battle._team_active_unit.stats)
	var idx := -1
	for i in skills.size():
		if skills[i].skill_id == skill_id:
			idx = i
	if not expect(idx >= 0, "usable skill " + String(skill_id)):
		return
	for attempt in 4:
		battle._on_skill_selected(idx)
		if not expect(await wait_for(func(): return current_scene != null and (current_scene.scene_file_path == "res://scenes/result_victory.tscn" or (current_scene.get_instance_id() == battle_id and current_scene.get("_state") == 1)), 25000), "attack resolves"):
			return
		if current_scene.get_instance_id() != battle_id:
			break
	expect(current_scene != null and current_scene.scene_file_path == "res://scenes/result_victory.tscn", "victory result")

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router = root.get_node("SceneRouter")
	state = root.get_node("GameState")
	state.reset_for_new_game()
	router.reset_for_new_game()
	root.get_node("Inventory").reset_for_new_game()
	root.get_node("EventBus").sfx_requested.connect(_hear)
	var stream := load(VANISH) as AudioStreamWAV
	expect(stream != null and is_equal_approx(stream.get_length(), .88), "0.88s WAV loads")
	expect(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "nonlooping")
	state.player.speed = 1000
	state.player.agility = 180
	state.player.attack = 500
	state.player.max_hp = 3000
	state.player.hp = 3000
	state.player.max_mp = 300
	state.player.mp = 300
	var wolf_ids: Array[StringName] = [&"training_wolf_young_lv2"]
	var battle := await _begin(wolf_ids)
	if battle == null:
		_finish()
		return
	expect(not heard.has(VANISH), "no death sound on entry")
	var wolf: BattleCombatant = battle._team_enemies[0]
	wolf.stats.hp = 1
	await _kill(battle, &"basic_attack")
	expect(heard.count(VANISH) == 1 and played == 1, "single actual wolf kill plays vanish once")
	var old_defeat: String = root.get_node("AudioManager").DEFAULT_DEFEAT_SFX
	expect(not heard.has(old_defeat), "enemy death does not use party defeat sting")
	if current_scene != null and current_scene.scene_file_path == "res://scenes/result_victory.tscn":
		current_scene.get_node("%BtnContinue").pressed.emit()
		expect(await wait_for(func(): return current_scene != null and current_scene.has_method("get_field_loading_state") and current_scene.get_field_loading_state().get("complete",false) and not root.get_node("LoadingManager").get("_transition_active"),25000), "return from victory")
	state.debug_force_learn_skill(&"tang_staff_sweep")
	var inv := root.get_node("Inventory")
	expect(inv.add_item(&"golden_hoop_staff") and inv.equip(&"golden_hoop_staff"), "equip staff for group attack")
	var group_ids: Array[StringName] = [&"training_wolf_young_lv2", &"thug_lone", &"zhuwei_pack_wolf"]
	battle = await _begin(group_ids)
	if battle == null:
		_finish()
		return
	for enemy: BattleCombatant in battle._team_enemies:
		enemy.stats.hp = 1
	await _kill(battle,&"tang_staff_sweep")
	expect(heard.count(VANISH) == 1 and played == 1, "three mixed enemy simultaneous kills coalesce once")
	battle = await _begin(wolf_ids)
	if battle == null:
		_finish()
		return
	var victim: BattleCombatant = battle._team_enemies[0]
	victim.stats.hp = 1
	victim.status_effects["poison"] = 1
	expect(await battle._team_apply_turn_start_status(victim), "poison kills at turn start")
	expect(not victim.alive and heard.count(VANISH) == 1 and played == 1, "poison disappearance sound")
	heard.clear()
	var ally: BattleActor = battle._team_actor(&"player")
	await ally.play_defeat()
	expect(heard.has(old_defeat) and not heard.has(VANISH), "party defeat keeps own sound")
	heard.clear()
	# Exercise the compatibility handler without replacing the active team mode.
	battle._on_actor_sound_requested(&"defeat",true)
	expect(heard.count(VANISH) == 1, "legacy enemy death uses same sound")
	heard.clear()
	var payload: Dictionary = router.get_battle_payload()
	payload["battle_mode"] = &"sparring"
	battle._last_enemy_vanish_sfx_ms = -1000
	battle._on_team_actor_sound_requested(&"defeat",battle._team_actor(victim.unit_id),true)
	expect(not heard.has(VANISH), "sparring does not play death disappearance")
	payload.erase("battle_mode")
	battle._enemy_def = load("res://data/enemies/boss_zhao_wuji.tres")
	battle._on_actor_sound_requested(&"defeat",true)
	expect(not heard.has(VANISH), "nonlethal story boss does not play death sound")
	_finish()

func _finish() -> void:
	print("ENEMY_VANISH ",checks," checks / ",failures," failures")
	quit(int(failures > 0))
