extends "res://build/interior_identity_20261106_system01/formal_yihong_trip_ROOT_ONLY.gd"
## Keep the previous full trace unchanged. Repeat only the required near setup,
## original door, one dialogue and true return. Inherit the accepted visual.
const PRIOR := HOME+"formal_actual/64804/"
const PRIOR_RESULT_SHA := "6c06c22da95c20dfab531ab21cad8c64c8e02232ae235a8dc012ddd4fb7c70e0"
const PRIOR_IMAGE_SHA := "23f62925e5819d2e3288aac5611ac6a05b3d52c3400c94c12ba3f3da563bc808"

func _run() -> void:
	began=Time.get_ticks_msec()
	output=HOME+"formal_actual/"+str(OS.get_process_id())+"/"
	DirAccess.make_dir_recursive_absolute(output)
	router=root.get_node("SceneRouter")
	host=root.get_node_or_null("SceneArtQualityRuntime")
	if not need(host!=null and host.call("get_debug_state").get("ready")==true,"FORMAL_31B_SUCCESSOR_ACTIVE"):finish();return
	var bridge := root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	if not need(bridge.call("is_checkpoint_saves_suspended")==true and FileAccess.get_sha256(BIN)==BIN_SHA,"SUSPEND_CHECKPOINTS_AND_EXACT_FORMAL_BIN"):finish();return
	if not need(FileAccess.get_sha256(PRIOR+"result.json")==PRIOR_RESULT_SHA and FileAccess.get_sha256(PRIOR+"yihongyuan_live_normal.png")==PRIOR_IMAGE_SHA,"EXACT_PRIOR_FOUR_ACTOR_AND_SEAT_VISUAL_EVIDENCE"):finish();return
	var prior: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PRIOR+"result.json"))
	if not need(prior.evidence.new_idle_frames.size()==4 and prior.evidence.old_seats_stable==true,"PRIOR_VISUAL_PREFIX_NOT_RETESTED"):finish();return
	evidence["inherited_visual_prefix"]={"pid":64804,"image_sha256":PRIOR_IMAGE_SHA,"result_sha256":PRIOR_RESULT_SHA}
	var current_id := current_scene.get_instance_id() if is_instance_valid(current_scene) else 0
	var dispatcher := load(DISPATCH) as GDScript
	var extension := {"region_id":CIVIC,"revision":1,"logical_id":LOGICAL,"global_foot_px":[RETURN.x,RETURN.y]}
	if not need(dispatcher!=null and dispatcher.call("start",router,StringName(LOGICAL),Vector2(0.5,0.5),"",-1,extension)==true,"ORIGINAL_PUBLIC_NEAR_FOOT_SETUP"):finish();return
	var outside: Node = await _wait_field(CIVIC,current_id)
	if outside==null:finish();return
	await _key(KEY_W,12)
	var door := _door(outside,"enter_yihongyuan27n")
	if not need(door!=null and door.call("_can_enter")==true,"TRUE_ORIGINAL_EXTERIOR_DOOR_REACHABLE"):finish();return
	current_id=outside.get_instance_id()
	await _key(KEY_SPACE,1)
	var room: Node = await _wait_field(ROOM,current_id)
	if room==null:finish();return
	var player: Node2D = room.get("_player")
	var compiled: Dictionary = room.get("_region")
	if not need(player.position.distance_to(ENTRY)<=1.0 and compiled.get("interior_identity_20261107")=="YIHONG_NATIVE_ROOM_20261107_V1","TRUE_ROOM_ENTRY_AND_PROFILE"):finish();return
	await _key(KEY_W,25)
	await _key(KEY_D,9)
	var before_dialog := _business()
	await _key(KEY_SPACE,1)
	var dialog := root.get_node("DialogPlayer")
	var script: DialogScript = dialog.get("_current_script")
	if not need(dialog.call("is_playing")==true and script!=null and script.dialog_id==&"yihongyuan_daily_yihongyuan27n_waiter","ORIGINAL_ATTENDANT_DAILY_GRAPH"):finish();return
	var hero: DialogNode = dialog.get("_current_node")
	if not need(hero!=null and hero.node_id==&"hero" and hero.portrait_path==root.get_node("GameState").get("player").portrait_path,"ORIGINAL_HERO_OPENS_WITH_HERO_PORTRAIT"):finish();return
	dialog.call("advance")
	var npc_line: DialogNode = dialog.get("_current_node")
	if not need(npc_line!=null and npc_line.node_id==&"npc_0" and npc_line.on_end=="end","ORIGINAL_SINGLE_ATTENDANT_REPLY"):finish();return
	dialog.call("advance")
	for frame: int in range(8):
		if dialog.call("is_playing")==false and player.get("can_move")==true:break
		await process_frame
	var after_dialog := _business()
	var changed := _changed(before_dialog,after_dialog)
	evidence["dialog_end"]={"playing":dialog.call("is_playing"),"can_move":player.get("can_move"),"changed_domains":changed,"changed_flags":_changed(before_dialog.flags,after_dialog.flags),"player_foot":str(player.position)}
	if not need(dialog.call("is_playing")==false and player.get("can_move")==true and changed.is_empty(),"OLD_DIALOGUE_FINISHED_UNCHANGED_SAME_ROOM_BUSINESS"):finish();return
	await _key(KEY_A,9)
	await _key(KEY_S,33)
	var exit := _door(room,"yihongyuan27n_exit")
	if not need(exit!=null and exit.call("_can_enter")==true,"TRUE_ORIGINAL_ROOM_EXIT_REACHABLE"):finish();return
	current_id=room.get_instance_id()
	await _key(KEY_SPACE,1)
	outside=await _wait_field(CIVIC,current_id)
	if outside==null:finish();return
	var return_position: Vector2 = (outside.get("_player") as Node2D).position
	if not need(return_position.distance_to(RETURN)<=1.0,"TRUE_RETURN_EXACT_CIVIC_FOOT"):finish();return
	evidence["true_return_foot"]=str(return_position)
	var after_return := _business()
	evidence["return_business_changed_domains"]=_changed(after_dialog,after_return)
	evidence["return_changed_flags"]=_changed(after_dialog.flags,after_return.flags)
	if not need(after_return.hero==after_dialog.hero and after_return.gold==after_dialog.gold and after_return.inventory==after_dialog.inventory and after_return.quests==after_dialog.quests,"TRUE_RETURN_PRESERVES_HERO_GOLD_INVENTORY_QUESTS"):finish();return
	var runtime := load(RUNTIME) as GDScript
	var raw := {"region_id":ROOM,"logical_id":ROOM,"revision":compiled.revision,"global_foot_px":[636,482]}
	var recovered: Dictionary = runtime.call("recover_predecessor",compiled,ROOM,Vector2(0.5,0.5),compiled.districts[ROOM].legacy_version,raw,{"ok":false,"error":"REGION_SAVED_FOOT_BLOCKED"})
	evidence["synthetic_recovery"]=recovered
	if not need(recovered.get("ok")==true and recovered.get("foot")==ENTRY and recovered.get("reason")=="yihong_exact_old_legal_now_obstructed","SYNTHETIC_OLD_LEGAL_BLOCKED_FOOT_ONLY"):finish();return
	evidence["gate"]=check_gate_sources()
	need(evidence.gate.passed,"GATE_ACTUAL_C_TO_B_EXACT_SET")
	finish()

func _changed(before: Dictionary,after: Dictionary) -> Array[String]:
	var changed: Array[String] = []
	for key: Variant in before:
		if not after.has(key) or after[key]!=before[key]:changed.append(String(key))
	for key: Variant in after:
		if not before.has(key):changed.append(String(key))
	changed.sort()
	return changed
