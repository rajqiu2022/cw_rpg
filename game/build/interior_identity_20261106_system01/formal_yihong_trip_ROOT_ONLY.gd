extends SceneTree
## One public near setup on current Civic, real W/Space into the room and
## S/Space return. Real Gate C->B consumer check only, not World travel.
const HOME := "res://build/interior_identity_20261106_system01/"
const DISPATCH := "res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd"
const FIELD := "res://build/luoyang_regions_20261027d_source01/region_field.gd"
const RUNTIME := "res://build/interior_identity_20261107_runtime01/room_runtime.gd"
const NATIVE := "res://build/interior_identity_20261107_runtime01/native_actor.gd"
const BIN := "res://build/interior_identity_20261107_runtime01/yihongyuan27n_interior.bin"
const BIN_SHA := "649075ce491953d63013f9f4ca0fe7d6eb3e6451e28980ff5865e451d9c004d9"
const LOGICAL := "ch4_s3_luoyang_market"
const CIVIC := "luoyang_civic_market_region_27d"
const ROOM := "yihongyuan27n_interior"
const SHELL := "res://art/modules/interior_identity_20261106/yihongyuan_luxury_shell.png"
const RETURN := Vector2(5206.18,4280)
const ENTRY := Vector2(768,850)
const NEW_IDS := ["yihongyuan27n_musician","yihongyuan27n_singer","yihongyuan27n_tea_attendant","yihongyuan27n_receptionist"]
var router: Node
var host: Node
var errors: Array[String] = []
var checks := 0
var input_ticks := 0
var finished := false
var output := ""
var began := 0
var evidence: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()
	_watchdog.call_deferred()

func _watchdog() -> void:
	await create_timer(145.0,true,false,true).timeout
	if not finished:
		need(false,"INDEPENDENT_145S_WATCHDOG")
		finish()

func need(value: bool,label: String) -> bool:
	checks+=1
	if not value: errors.append(label);printerr("YIHONG_FORMAL_QA_FAIL ",label)
	return value

func _business() -> Dictionary:
	# In-memory domain object serialization only. Never call load/save.
	var game: Node = root.get_node("GameState")
	var serializer: Node = root.get_node("SaveManager")
	var hero: Resource = game.get("player")
	return {"hero":serializer.call("_serialize_stats",hero),"gold":game.get("gold"),"flags":game.get("flags").duplicate(true),"quests":root.get_node("QuestManager").call("to_dict"),"inventory":root.get_node("Inventory").call("to_dict")}.duplicate(true)

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
	var before := _business()
	var current_id := current_scene.get_instance_id() if is_instance_valid(current_scene) else 0
	var dispatcher := load(DISPATCH) as GDScript
	var extension := {"region_id":CIVIC,"revision":1,"logical_id":LOGICAL,"global_foot_px":[RETURN.x,RETURN.y]}
	if not need(dispatcher!=null and dispatcher.call("start",router,StringName(LOGICAL),Vector2(0.5,0.5),"",-1,extension)==true,"ORIGINAL_PUBLIC_NEAR_FOOT_SETUP"):finish();return
	var outside: Node = await _wait_field(CIVIC,current_id)
	if outside==null: finish();return
	await _key(KEY_W,12)
	var door := _door(outside,"enter_yihongyuan27n")
	if not need(door!=null and door.call("_can_enter")==true,"TRUE_ORIGINAL_EXTERIOR_DOOR_REACHABLE"):finish();return
	current_id=outside.get_instance_id()
	await _key(KEY_SPACE,1)
	var room: Node = await _wait_field(ROOM,current_id)
	if room==null: finish();return
	var player: Node2D = room.get("_player")
	if not need(player.position.distance_to(ENTRY)<=1.0,"AUTHORED_ORIGINAL_ARRIVAL_FOOT"):finish();return
	var owner: RefCounted = room.get("_region_owner")
	var compiled: Dictionary = room.get("_region")
	var receipt: Dictionary = owner.call("receipt")
	if not need(receipt.get("source_first",{}).get(BIN)==BIN_SHA and receipt.source_first==receipt.source_final and compiled.get("interior_identity_20261107")=="YIHONG_NATIVE_ROOM_20261107_V1","EXACT_LIVE_OWNER_AND_PROFILE"):finish();return
	var mini: Node = room.get("_world_travel_minimap")
	if not need(mini!=null and mini.call("get_debug_state").get("visual_cache_ready")==true and not room.has_meta("quality_20261101b_decor"),"ACTUAL_MINIMAP_AND_NO_OBSOLETE_DECOR_OVERLAY"):finish();return
	var shell: Sprite2D = (room.get("_region_visuals") as Dictionary).get(LOGICAL+"/yihongyuan_identity_native_shell")
	if not need(is_instance_valid(shell) and shell.texture.resource_path==SHELL and shell.position==Vector2(-64,-64) and shell.scale==Vector2.ONE and shell.get_child_count()==7,"NATIVE_SHELL_AND_7_SOURCE_UV_PARTS"):finish();return
	var actors: Dictionary = room.get("_region_actors")
	var seats := _seated(actors)
	if not need(actors.size()==10 and seats.size()==2,"TEN_REAL_NPCS_PLUS_OLD_STABLE_SEAT_EVIDENCE"):finish();return
	var seen_frames: Dictionary = {}
	var feet: Dictionary = {}
	for id: String in NEW_IDS:
		var npc: NPCNode = actors.get(LOGICAL+"/"+id,{}).get("node")
		if not need(is_instance_valid(npc) and npc.get_script().resource_path==NATIVE and npc.call("native_grid_ready")==true and npc.sprite.texture.resource_path==npc.sprite_path,"FORMAL_EXACT_NEW_ACTOR:"+id):finish();return
		feet[id]=npc.position
		seen_frames[id]={}
	var sample_time := Time.get_ticks_msec()
	while Time.get_ticks_msec()-sample_time < 7400:
		for id: String in NEW_IDS:
			var npc: NPCNode = actors[LOGICAL+"/"+id].node
			if not need(npc.position==feet[id] and not npc.sprite.flip_h and npc.call("native_grid_ready")==true,"IDLE_ANCHOR:"+id):finish();return
			seen_frames[id][str(npc.sprite.frame)]=true
		if not need(_seated(actors)==seats,"TWO_ORIGINAL_SEATS_STAY_STILL"):finish();return
		await create_timer(0.24).timeout
	for id: String in NEW_IDS:
		if not need(seen_frames[id].size()==4,"ALL_FOUR_REAL_FRAMES:"+id):finish();return
	evidence["new_idle_frames"]=seen_frames
	evidence["old_seats_stable"]=true
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if not need(image!=null and image.get_size()==Vector2i(1920,1080),"NORMAL_GAME_VIEW_1920_1080"):finish();return
	var image_path := output+"yihongyuan_live_normal.png"
	if not need(image.save_png(image_path)==OK,"WRITE_NEW_EVIDENCE_IMAGE"):finish();return
	evidence["image"]=image_path
	# Talk to the existing attendant via real movement and interaction, no
	# injected graph, no quest/story alteration.
	await _key(KEY_W,25)
	await _key(KEY_D,9)
	await _key(KEY_SPACE,1)
	var dialog := root.get_node("DialogPlayer")
	var script: DialogScript = dialog.get("_current_script")
	if not need(dialog.call("is_playing")==true and script!=null and script.dialog_id==&"yihongyuan_daily_yihongyuan27n_waiter","ORIGINAL_ATTENDANT_DAILY_GRAPH"):finish();return
	dialog.call("advance")
	dialog.call("advance")
	await process_frame; await physics_frame
	if not need(dialog.call("is_playing")==false and player.get("can_move")==true and _business()==before,"OLD_DIALOGUE_FINISH_NO_BUSINESS_CHANGE"):finish();return
	await _key(KEY_A,9)
	await _key(KEY_S,33)
	var exit := _door(room,"yihongyuan27n_exit")
	if not need(exit!=null and exit.call("_can_enter")==true,"TRUE_ORIGINAL_ROOM_EXIT_REACHABLE"):finish();return
	current_id=room.get_instance_id()
	await _key(KEY_SPACE,1)
	outside=await _wait_field(CIVIC,current_id)
	if outside==null: finish();return
	if not need((outside.get("_player") as Node2D).position.distance_to(RETURN)<=1.0 and _business()==before,"TRUE_RETURN_EXACT_CIVIC_FOOT_UNCHANGED_BUSINESS"):finish();return
	var runtime := load(RUNTIME) as GDScript
	var raw := {"region_id":ROOM,"logical_id":ROOM,"revision":compiled.revision,"global_foot_px":[636,482]}
	var recovered: Dictionary = runtime.call("recover_predecessor",compiled,ROOM,Vector2(0.5,0.5),compiled.districts[ROOM].legacy_version,raw,{"ok":false,"error":"REGION_SAVED_FOOT_BLOCKED"})
	if not need(recovered.get("ok")==true and recovered.get("foot")==ENTRY and recovered.get("reason")=="yihong_exact_old_legal_now_obstructed","SYNTHETIC_OLD_LEGAL_BLOCKED_FOOT_ONLY"):finish();return
	evidence["gate"]=check_gate_sources()
	need(evidence.gate.passed,"GATE_ACTUAL_C_TO_B_EXACT_SET")
	finish()

func _seated(actors: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for id: String in ["yihongyuan27n_elder_guest","yihongyuan27n_woman_guest"]:
		var npc: NPCNode = actors.get(LOGICAL+"/"+id,{}).get("node")
		if not is_instance_valid(npc) or npc.movement_mode!="seated" or npc.sprite.hframes!=1 or npc.sprite.frame!=0 or not npc.sprite.texture is AtlasTexture: return {}
		var texture := npc.sprite.texture as AtlasTexture
		if texture.region!=Rect2(160,0,160,160):return {}
		result[id]=[npc.get_instance_id(),npc.position,npc.sprite.position,npc.sprite.flip_h,texture.get_instance_id()]
	return result

func _wait_field(id: String,previous: int) -> Node:
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec()-started<30000:
		await process_frame
		var field: Node = current_scene
		if not is_instance_valid(field) or field.get_instance_id()==previous or field.get_script()==null or field.get_script().resource_path!=FIELD:continue
		var region: Dictionary = field.get("_region")
		if region.get("id")!=id:continue
		if field.get("_field_loading_failed")==true:need(false,"ACTUAL_FIELD_FAILED:"+id);return null
		var loader := root.get_node("LoadingManager")
		if field.get("_field_loading_complete")!=true or loader.get("_transition_active")==true or loader.get("_external_active")==true:continue
		if not String(host.call("get_debug_state").get("last_error","")).is_empty():need(false,"31B_FORMAL_ATTACH_FAILED:"+id);return null
		if field.get_meta("scene_art_quality31b",{}).get("ok")!=true:continue
		var mini: Node = field.get("_world_travel_minimap")
		if mini==null or mini.call("get_debug_state").get("visual_cache_ready")!=true:continue
		var player: Node = field.get("_player")
		if player==null or player.get("can_move")!=true:continue
		await physics_frame; await RenderingServer.frame_post_draw
		return field
	need(false,"FINITE_30S_FIELD:"+id);return null

func _door(field: Node,id: String) -> Node:
	var rows: Dictionary = field.get("_region_portals")
	var found: Array[Node] = []
	for zone: Node in field.get("_exit_nodes"):
		if rows.get(zone.get_instance_id(),{}).get("id")==id:found.append(zone)
	return found[0] if found.size()==1 else null

func _key(code: int,ticks: int) -> void:
	await physics_frame
	_emit_key(code,true)
	for i: int in range(ticks):await physics_frame;input_ticks+=1
	_emit_key(code,false)
	await physics_frame;await process_frame

func _emit_key(code: int,down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code;event.physical_keycode=code;event.pressed=down
	Input.parse_input_event(event);Input.flush_buffered_events()

func check_gate_sources() -> Dictionary:
	var id: StringName = &"ch4_s0_luoyang_gate"
	var path: String = router.call("field_scene_resource_path",id)
	var scene: Resource = load(path)
	var collector := load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd") as GDScript
	var bundle := load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd") as GDScript
	if scene==null or collector==null or bundle==null:return {"passed":false,"reason":"GATE_FIXTURE_SOURCE_LOAD"}
	var actual: Dictionary = collector.call("_transition_sources",scene,true)
	var config: Dictionary = bundle.call("manifest",id)
	var expected: Dictionary = config.get("legacy_source_sha256",{}).duplicate(true)
	expected.merge(config.get("runtime_authority_sha256",{}))
	expected.merge(config.get("artifacts",{}))
	for index: String in [bundle.INDEX,bundle.ESTATE_INDEX,bundle.AO_INDEX,bundle.AP_INDEX,bundle.AP_ENV_INDEX,bundle.AP_EXEC_INDEX,bundle.AP_QUARTER_INDEX]:
		expected[index]=FileAccess.get_sha256(index)
	var entry: Dictionary = bundle.call("_entry",id)
	if not entry.is_empty():expected[entry.manifest_path]=entry.manifest_sha256
	var extra: Dictionary = {}
	var missing: Dictionary = {}
	var different: Dictionary = {}
	for p: String in actual:
		if not expected.has(p):extra[p]=actual[p]
		elif actual[p]!=expected[p]:different[p]={"expected":expected[p],"actual":actual[p]}
	for p: String in expected:
		if not actual.has(p):missing[p]=expected[p]
	var admitted: Dictionary = bundle.call("describe",id,actual)
	return {"scope":"GATE_ACTUAL_C_TO_B_NO_TRAVEL","passed":not config.is_empty() and not admitted.is_empty() and actual==expected,"actual_count":actual.size(),"expected_count":expected.size(),"extra":extra,"missing":missing,"different":different}

func finish() -> void:
	if finished:return
	finished=true
	for code: int in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SPACE]:_emit_key(code,false)
	var report := {"checks":checks,"failures":errors,"input_ticks":input_ticks,"elapsed_ms":Time.get_ticks_msec()-began,"evidence":evidence,"real_yihong_entry_return":evidence.has("gate"),"real_gate_travel":false,"real_save_content_access":false}
	var fd := FileAccess.open(output+"result.json",FileAccess.WRITE)
	if fd!=null:fd.store_string(JSON.stringify(report,"  ")+"\n");fd.close()
	print(JSON.stringify(report))
	quit(0 if errors.is_empty() else 1)
