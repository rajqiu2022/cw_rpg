extends "res://build/world_coast_20261031h_qa01/formal_field35_ROOT_ONLY.gd"
## Retains Field35 FAIL: its Bianzhou selector asked for portal_id meta which
## original Field _spawn_exits does not assign to regular authored World doors.
## Both shore returns, M/mini, reverse ferry and plaza32px/images are inherited.
func boot(domain: String) -> bool:
	var ok: bool=await super.boot(domain)
	directory="res://build/world_coast_20261031h_qa01/formal_field36_actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	return ok
func _run() -> void:
	if not await boot("coast36"):finish();return
	base_core=core()
	records.append({"inherited_first_boat":"formal_field32_actual/125824/result.json","inherited_shores_reverse_boat_M_mini_plaza_and_three_normal_images":"formal_field35_actual/128136/result.json","original_whole32_and35_status":"FAIL_RETAINED_QA_DOOR_SELECTORS","successful_components_not_repeated":true})
	if not await setup(&"world_map_jianghu",Vector2(7600,1556.8779296875)/SIZE):finish();return
	var row: Dictionary=portal("bianzhou");var door: ExitZone;var observed: Array=[]
	for candidate: ExitZone in field.get("_exit_nodes"):
		if candidate.target_scene_id=="openworld_bianzhou_city":
			door=candidate
			observed.append({"target":candidate.target_scene_id,"action":candidate.action,"position":candidate.position,"actor_foot":foot(),"locked":candidate.is_locked,"script":candidate.get_script().resource_path,"meta_list":candidate.get_meta_list(),"real_can_enter":candidate.call("can_enter")})
	records.append({"actual_bianzhou_exit":observed})
	if not need(not row.is_empty() and door!=null and bool(door.call("can_enter")),"NEW_BIANZHOU_REAL_TARGET_MATCH_AND_CAN_ENTER"):finish();return
	if not await enter(&"openworld_bianzhou_city"):finish();return
	if not need(core()==base_core,"TRUE_BIANZHOU_ENTRY_MEMORY_PRESERVED"):finish();return
	var returning: ExitZone
	for candidate: ExitZone in field.get("_exit_nodes"):
		if candidate.action=="world_map" or candidate.target_scene_id=="world_map_jianghu":returning=candidate;break
	if returning!=null:
		var target: Vector2=world.to_local(returning.global_position)
		records.append({"bianzhou_original_return_target":target,"actual_arrival":foot(),"nearby_optional_true_return":foot().distance_to(target)<=256})
		if foot().distance_to(target)<=256:
			if not await walk(target,64):finish();return
			if not await enter(&"world_map_jianghu"):finish();return
			if not need(foot().distance_to(Vector2(7600,1556.8779296875))<.02,"TRUE_BIANZHOU_RETURN_NEW16_MOVED_GATE"):finish();return
	if not await setup(&"world_map_jianghu",Vector2(4000,2594.4912)/SIZE):finish();return
	var gate: ExitZone
	for candidate: ExitZone in field.get("_exit_nodes"):
		if candidate.target_scene_id=="ch4_s0_luoyang_gate":gate=candidate;break
	if not need(gate!=null and bool(gate.call("can_enter")),"FORMAL16_ORIGINAL_LUOYANG_DOOR_CAN_ENTER"):finish();return
	if not await enter(&"ch4_s0_luoyang_gate"):finish();return
	var arrival: Vector2=foot()
	if not await walk(arrival+Vector2(32,0),12):finish();return
	await shot("formal16_original_luoyang_gate_true_entry")
	need(core()==base_core,"ORIGINAL_PLAYER_PARTY_HP_MP_GOLD_PRESERVED")
	finish()
