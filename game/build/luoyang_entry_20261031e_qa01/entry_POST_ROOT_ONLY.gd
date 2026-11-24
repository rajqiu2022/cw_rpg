extends "res://build/world_sects_cities_20261031c_qa01/probe_base_ROOT_ONLY.gd"
## Root-only original World portal -> Gate, one real short move and normal image.
const FIXTURE := "res://build/luoyang_entry_20261031e_qa01/entry_POST_inputs_READY.json"
func _watch() -> void:
	await create_timer(60.0,true,false,true).timeout
	if not done:need(false,"HARD60S_SINGLE_ORIGINAL_ENTRY");finish()
func boot(_domain: String) -> bool:
	directory="res://build/luoyang_entry_20261031e_qa01/entry_post_actual/"+str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"EARLIEST_CHECKPOINT_SUSPEND_NO_REAL_SAVE_API"):return false
	router=root.get_node("SceneRouter")
	cfg=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)) as Dictionary
	for path: String in cfg.pins:
		if not need(FileAccess.get_sha256(path)==String(cfg.pins[path]),"EXPLICIT_POST_PIN:"+path):return false
	return true
func state() -> Dictionary:
	var game: Node=root.get_node("GameState");var player: Resource=game.get("player") as Resource
	var party: Array=[]
	for member: Resource in game.get("party"):party.append(member.get_instance_id())
	return {"player_instance":player.get_instance_id(),"hp":player.get("hp"),"mp":player.get("mp"),"gold":game.get("gold"),"party_instances":party}
func _run() -> void:
	if not await boot("entry_post"):finish();return
	var original: Dictionary=state()
	if not await setup(&"world_map_jianghu",Vector2(4000,2594.4912)/Vector2(12288,8192)):finish();return
	var door: ExitZone;var count := 0
	for item: ExitZone in field.get("_exit_nodes"):
		if item.target_scene_id=="ch4_s0_luoyang_gate":door=item;count+=1
	for tick_index: int in range(3):await tick()
	if not need(count==1 and door!=null and bool(door.call("can_enter")),"ORIGINAL_WORLD_LUOYANG_PORTAL_UNIQUE_REAL_CAN_ENTER"):finish();return
	records.append({"original_world_foot":foot(),"door_target":door.target_scene_id,"door_target_spawn":door.target_spawn_pos,"public_near_setup_not_whole_world_travel":true})
	var began: int=Time.get_ticks_msec()
	if not await enter(&"ch4_s0_luoyang_gate"):finish();return
	var arrival: Vector2=foot()
	if not need(state()==original,"ACTUAL_GATE_SAME_PLAYER_PARTY_HP_MP_GOLD"):finish();return
	if not await walk(arrival+Vector2(32,0),12):finish();return
	records.append({"actual_gate_arrival":arrival,"after_true_short_D_move":foot(),"departure_to_capture_ms":Time.get_ticks_msec()-began,"not_whole_Luoyang_or_loading_target_credit":true})
	await shot("original_world_luoyang_gate_entry_and_short_move")
	need(state()==original,"PLAYER_MEMORY_PRESERVED_AFTER_ENTRY_SHORT_MOVE")
	finish()
func finish() -> void:
	if done:return
	key(KEY_NONE);done=true
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"input_events":inputs,"scope":"one original World can_enter and real Space->Gate/one real32px short walk/one normal image only; old city matrices not repeated","real_save_API_calls":0,"actor_camera_writes":0},"\t"));file.close()
	quit(0 if errors.is_empty() else 1)
