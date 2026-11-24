extends "res://build/world_coast_20261031h_qa01/formal_field32_ROOT_ONLY.gd"
## Field32 actual125824 first true Bailu->Donghai boat PASSED and is inherited.
## Its shore oracle matched target_scene_id, but original town return is an
## action-only ExitZone(action=world_map,target_scene_id=""), not world_v15zone.
func boot(domain: String) -> bool:
	var ok: bool=await super.boot(domain)
	directory="res://build/world_coast_20261031h_qa01/formal_field35_actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	return ok
func shore_return(id: StringName,expected_world: Vector2,image_label: String) -> bool:
	var row: Dictionary=load(LOC).town(id);var exit_foot: Vector2=vec(row.returns.world_map_jianghu)
	if not await setup(id,exit_foot/row.size,3001):return false
	var door: ExitZone;var observed: Array=[]
	for candidate: ExitZone in field.get("_exit_nodes"):
		observed.append({"target":candidate.target_scene_id,"action":candidate.action,"position":candidate.position,"locked":candidate.is_locked,"actor_foot":foot(),"in_range":candidate.get("_in_range"),"overlap":candidate.overlaps_body(actor)})
		if candidate.action=="world_map":door=candidate
	records.append({"original_action_only_world_exits":observed})
	if not need(door!=null and not door.is_locked and bool(door.get("_in_range")) and door.overlaps_body(actor),"ORIGINAL_ACTION_WORLD_MAP_RETURN_REAL_OVERLAP:"+String(id)):return false
	if not await enter(&"world_map_jianghu"):return false
	if not need(foot().distance_to(expected_world)<.02,"ACTUAL_WORLD_SHORE16_EXACT_ORIGINAL_FOOT:"+String(id)):return false
	var scene: Resource=field.get("_current_scene") as Resource
	if not need(router.call("layered_world_contract",scene)==load(CONTRACT) and load(CONTRACT).safe_foot(scene,foot()/SIZE),"ACTUAL_FIELD_BOUND_TO_NEW16_AND_SHORE_SAFE"):return false
	await shot(image_label)
	return true
func shared_map_once() -> bool:
	var expected: String="res://art/maps/world_coast_20261031h/candidate02/overview.png"
	var mini: Control=field.get("_world_travel_minimap") as Control
	if not need(mini!=null and mini.is_visible_in_tree() and (mini.call("get_debug_state") as Dictionary).get("effective_overview_path")==expected,"ACTUAL_WORLD_MINI_BINDS16_SAME_OVERVIEW"):return false
	await tap(KEY_M)
	var panel: Control
	for index: int in range(40):
		await tick();panel=field.get("_world_map_panel") as Control
		if panel!=null and panel.is_visible_in_tree():break
	var image: TextureRect=panel.get("map_texture") as TextureRect if panel!=null else null
	if not need(panel!=null and panel.is_visible_in_tree() and image!=null and image.texture!=null and image.texture.resource_path==expected,"TRUE_M_PANEL_BINDS16_ACTUAL_OVERVIEW_NOT_STATIC15_CACHE"):return false
	records.append({"actual_M_overview":image.texture.resource_path,"actual_minimap_debug":mini.call("get_debug_state")})
	await tap(KEY_ESCAPE)
	for index: int in range(16):
		await tick()
		if not panel.visible and bool(actor.get("can_move")):return true
	return need(false,"M_ESCAPE_RETURNS_ACTOR_MOVEMENT")
func _run() -> void:
	if not await boot("coast35"):finish();return
	base_core=core()
	records.append({"inherited_first_real_boat":"formal_field32_actual/125824/result.json","first_true_Bailu_to_Donghai_not_repeated":true,"original_whole_field32_status":"FAIL_RETAINED_ACTION_ONLY_DOOR_ORACLE"})
	if not await setup(&"openworld_east_sea_port",null):finish();return
	if not await shore_return(&"openworld_east_sea_port",Vector2(11700,3417.3652),"new_island_actual_normal_world"):finish();return
	if not await shared_map_once():finish();return
	var east: Dictionary=portal("east_sea_port")
	if not need(not east.is_empty(),"ORIGINAL_EAST_ISLAND_WORLD_PORTAL"):finish();return
	if not await enter(&"openworld_east_sea_port"):finish();return
	if not await ferry(&"openworld_east_sea_port",&"openworld_bailu_ferry"):finish();return
	if not await shore_return(&"openworld_bailu_ferry",Vector2(9300,4301.3623),"mainland_ferry_actual_normal_world"):finish();return
	if not await setup(&"world_map_jianghu",Vector2(7600,1800)/SIZE):finish();return
	if not await walk(Vector2(7632,1800),12):finish();return
	await shot("bianzhou_offset_approach_and_front_plaza")
	if not await setup(&"world_map_jianghu",Vector2(7600,1556.8779296875)/SIZE):finish();return
	var bian: Dictionary=portal("bianzhou");var bdoor: ExitZone
	for candidate: ExitZone in field.get("_exit_nodes"):
		if candidate.get_meta("portal_id","")=="bianzhou":bdoor=candidate;break
	if not need(not bian.is_empty() and bdoor!=null and bool(bdoor.call("can_enter")),"NEW_BIANZHOU_GATE_REAL_CAN_ENTER"):finish();return
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
