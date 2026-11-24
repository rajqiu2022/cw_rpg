extends "res://tests/test_ch1_balance_runtime_20260910.gd"

## CLI (after --): --seeds=64 --hp=160 --attack=20 --defense=6 --mp=24
## --speed=14 --aggression=0.7 --skill-ids=basic_attack,tang_staff_sweep
## --skill=tang_staff_sweep:fixed_damage:10 (repeatable; enemy-only duplicate)
## Each fixture uses authored starting gear, no wine/potions, normal learning.
## The printed rates describe a deterministic bot policy, not human win rates.
var enemy_edits: Dictionary = {}
var skill_edits: Dictionary = {}
var ids_edit: Array[StringName] = []
var spar_parts: PackedStringArray
var original_enemy_text: String
var original_skill_texts: Dictionary = {}
var original_skill_values: Dictionary = {}

func run() -> void:
	gs = root.get_node("GameState")
	inv = root.get_node("Inventory")
	router = root.get_node("SceneRouter")
	router.set_script(load("res://tests/fixtures/quiet_settlement_router_20260910.gd"))
	parse_options()
	var dialog: DialogScript = load("res://data/dialogs/linxi_companion_tang_xingzhou.tres")
	for node: DialogNode in dialog.nodes:
		if node.on_end.begins_with("spar_then:"): spar_parts = node.on_end.split(":")
	check(spar_parts.size() == 7, "actual Tang dialogue provides complete spar_then payload")
	if failed: quit(1); return
	var enemy_path := "res://data/enemies/%s.tres" % spar_parts[2]
	original_enemy_text = FileAccess.get_file_as_string(enemy_path)
	var template: EnemyDef = load(enemy_path)
	var template_values: Dictionary = {}
	for key in enemy_edits: template_values[key] = template.get(key)
	var original_skill_ids: Array[StringName] = template.skill_ids.duplicate()
	var candidate := template.duplicate(true) as EnemyDef
	for key in enemy_edits: candidate.set(key,enemy_edits[key])
	if not ids_edit.is_empty(): candidate.skill_ids = ids_edit.duplicate()
	probe = load("res://scenes/battle.tscn").instantiate()
	probe.set_script(load("res://tests/fixtures/tang_spar_candidate_probe_20260911.gd"))
	probe.candidate_enemy = candidate
	for id in skill_edits:
		var path := "res://data/skills/%s.tres" % id
		check(ResourceLoader.exists(path), "candidate skill exists: " + id)
		if not ResourceLoader.exists(path): continue
		original_skill_texts[path] = FileAccess.get_file_as_string(path)
		var skill: Skill = load(path).duplicate(true)
		original_skill_values[path] = {}
		for key in skill_edits[id]: original_skill_values[path][key] = load(path).get(key)
		for key in skill_edits[id]: skill.set(key,skill_edits[id][key])
		probe.candidate_skills[StringName(id)] = skill
	for id in candidate.skill_ids: check(ResourceLoader.exists("res://data/skills/%s.tres" % id), "candidate enemy skill cannot silently fall back")
	check(candidate.max_hp > 0 and candidate.attack >= 0 and candidate.defense >= 0 and candidate.max_mp >= 0 and candidate.aggression >= 0.0 and candidate.aggression <= 1.0, "candidate parameters are valid")
	root.add_child(probe)
	if failed:
		probe.release_fakes()
		probe.queue_free()
		quit(1)
		return
	print("TANG_CONFIG ",JSON.stringify({"enemy":spar_parts[2],"hp":candidate.max_hp,"attack":candidate.attack,"defense":candidate.defense,"speed":candidate.speed,"mp":candidate.max_mp,"aggression":candidate.aggression,"skills":candidate.skill_ids,"enemy_only_skill_edits":skill_edits,"seeds":seed_count,"player_gear":["linxi_iron_sword","hemp_shirt","straw_sandals"],"potions":false,"wine":false}))
	for level in [1,2,3]:
		for basic_only in [true,false]:
			var sample := {"trained":level>1,"level":level,"basic":basic_only}
			var rows: Array[Dictionary] = []
			var player_hits: Array[int] = []
			var enemy_hits: Array[int] = []
			var enemy_mp_sum := 0
			var chosen: Dictionary = {}
			for i in seed_count:
				setup_player(sample)
				# A second persistent ally verifies the actual sparring solo filter
				# and whole-party recovery, without changing battle participants.
				check(gs.add_companion(&"shen_qinghe"), "snapshot witness companion joins")
				gs.get_party_member(&"shen_qinghe").hp -= 23
				gs.get_party_member(&"shen_qinghe").mp -= 11
				begin_tang_spar()
				var snapshots: Array = router.get_battle_payload().spar_party_snapshot.duplicate(true)
				probe.initialize_units([StringName(spar_parts[2])] as Array[StringName],router.get_battle_payload())
				check(probe._team_allies.size() == 1 and probe._team_enemies.size() == 1, "formal Tang spar is one versus one")
				for id in probe.candidate_skills:
					probe._team_active_unit = probe._team_allies[0]
					check(probe._load_skill(id) != probe.candidate_skills[id],"player action cannot see enemy-only skill override")
					probe._team_active_unit = probe._team_enemies[0]
					check(probe._load_skill(id) == probe.candidate_skills[id],"enemy action sees duplicated candidate skill")
				probe._team_active_unit = null
				seed(20260911+i)
				var row := await fight(sample)
				rows.append(row)
				player_hits.append_array(probe.player_damage)
				enemy_hits.append_array(probe.enemy_damage)
				enemy_mp_sum += candidate.max_mp - probe._team_enemies[0].stats.mp
				for id in probe.chosen_enemy_skills: chosen[id] = int(chosen.get(id,0)) + int(probe.chosen_enemy_skills[id])
				await probe.settle_real(row.win)
				check_snapshot(snapshots)
			var report := summarize("L%d_%s_%s" % [level,"trained" if level>1 else "untrained","basic" if basic_only else "best_attack"],rows)
			report["player_damage_per_attempt"] = damage_summary(player_hits)
			report["enemy_damage_per_attempt"] = damage_summary(enemy_hits)
			report["enemy_mp_used_mean"] = float(enemy_mp_sum)/seed_count
			report["enemy_skill_counts"] = chosen
			print("TANG_SAMPLE ",JSON.stringify(report))
	await verify_reward_idempotence()
	check(FileAccess.get_file_as_string(enemy_path) == original_enemy_text, "candidate evaluation never writes official enemy resource")
	for path in original_skill_texts: check(FileAccess.get_file_as_string(path) == original_skill_texts[path], "candidate evaluation never writes official skill resource")
	for key in template_values: check(template.get(key) == template_values[key], "shared cached enemy template remains unmodified: "+key)
	check(template.skill_ids == original_skill_ids,"candidate skill list never mutates shared EnemyDef")
	for path in original_skill_values:
		for key in original_skill_values[path]: check(load(path).get(key) == original_skill_values[path][key], "shared cached skill template remains unmodified: "+path+":"+key)
	probe.release_fakes()
	probe.queue_free()
	await process_frame
	await process_frame
	print("[TangSparRuntime] checks=%d failed=%d seeds=%d; synthetic fixed-policy rates, not human win rates" % [checks,failed,seed_count])
	quit(1 if failed else 0)

func begin_tang_spar() -> void:
	router.start_sparring(StringName(spar_parts[1]),spar_parts[3],spar_parts[2],int(spar_parts[4]),int(spar_parts[5]),&"linxi_village_center",Vector2(0.5,0.6),"dialog:"+spar_parts[6])

func check_snapshot(snapshots: Array) -> void:
	for row in snapshots:
		var member: CharacterStats = gs.get_party_member(StringName(row.character_id))
		check(member.hp == row.hp and member.mp == row.mp,"real spar restores exact prebattle HP/MP: "+row.character_id)

func verify_reward_idempotence() -> void:
	setup_player({"trained":true,"level":2})
	gs.add_companion(&"shen_qinghe")
	var initial_training: int = gs.training_points_total
	var initial_gold: int = gs.gold
	var defeats: Array[StringName] = []
	var listener := func(id: StringName) -> void: defeats.append(id)
	root.get_node("EventBus").enemy_defeated.connect(listener)
	var outcomes := [false,false,true,true,false]
	var rewards := [int(spar_parts[5]),0,int(spar_parts[4]),0,0]
	for i in outcomes.size():
		begin_tang_spar()
		var snapshots: Array = router.get_battle_payload().spar_party_snapshot.duplicate(true)
		probe.initialize_units([StringName(spar_parts[2])] as Array[StringName],router.get_battle_payload())
		gs.player.hp = 1 if outcomes[i] else 0
		gs.player.mp = 0
		await probe.settle_real(outcomes[i])
		check_snapshot(snapshots)
		check(router.get_result_payload().training == rewards[i],"Tang stable spar ID reward matrix loss-loss-win-win-loss")
	check(gs.training_points_total-initial_training == int(spar_parts[4])+int(spar_parts[5]) and gs.gold == initial_gold and defeats.is_empty(),"first-win idempotence; no ordinary loot/kill events")
	root.get_node("EventBus").enemy_defeated.disconnect(listener)

func damage_summary(values: Array[int]) -> Dictionary:
	if values.is_empty(): return {"attempts":0,"mean":0.0,"min":0,"max":0,"hit_mean":0.0}
	var total := 0
	var hits := 0
	for value in values:
		total += value
		if value>0: hits += 1
	return {"attempts":values.size(),"mean":float(total)/values.size(),"min":values.min(),"max":values.max(),"hit_mean":float(total)/maxi(1,hits)}

func parse_options() -> void:
	var keys := {"hp":"max_hp","attack":"attack","defense":"defense","speed":"speed","mp":"max_mp","aggression":"aggression"}
	var allowed_skill := ["fixed_damage","attack_scaling","mp_cost","base_hit_chance","status_chance","status_duration","effect_value"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): seed_count = maxi(1,int(arg.trim_prefix("--seeds="))); continue
		if arg.begins_with("--skill-ids="):
			for id in arg.trim_prefix("--skill-ids=").split(",",false): ids_edit.append(StringName(id))
			continue
		if arg.begins_with("--skill="):
			var parts := arg.trim_prefix("--skill=").split(":")
			check(parts.size()==3 and parts[1] in allowed_skill,"skill override uses ID:allowed_field:number")
			if parts.size()!=3 or parts[1] not in allowed_skill: continue
			if not skill_edits.has(parts[0]): skill_edits[parts[0]] = {}
			skill_edits[parts[0]][parts[1]] = float(parts[2]) if parts[1] in ["base_hit_chance","status_chance"] else int(parts[2])
			continue
		var parts := arg.trim_prefix("--").split("=",true,1)
		check(parts.size()==2 and keys.has(parts[0]),"unknown CLI option: "+arg)
		if parts.size()==2 and keys.has(parts[0]): enemy_edits[keys[parts[0]]] = float(parts[1]) if parts[0]=="aggression" else int(parts[1])
