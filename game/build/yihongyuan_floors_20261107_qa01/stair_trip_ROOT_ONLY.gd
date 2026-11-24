extends "res://build/interior_identity_20261106_system01/formal_yihong_trip_ROOT_ONLY.gd"

const EVIDENCE := "res://build/yihongyuan_floors_20261107_qa01/actual/"
const UPPER := "yihongyuan27n_upper"
const UP_ID := "yihong_stairs_up_20261107"
const DOWN_ID := "yihong_stairs_down_20261107"
const TABLE := "res://art/modules/yihongyuan_floors_20261107/tea_table.png"
const STAIRS := "res://art/modules/yihongyuan_floors_20261107/up_stair.png"
const UPPER_ART := "res://art/modules/yihongyuan_floors_20261107/upper_shell.png"
const FLOOR_HELPER := "res://build/yihongyuan_floors_20261107_runtime01/upper_room.gd"
const UP_ARRIVAL := Vector2(768, 832)
const DOWN_ARRIVAL := Vector2(416, 576)

func _run() -> void:
	began = Time.get_ticks_msec()
	output = EVIDENCE + str(OS.get_process_id()) + "/"
	DirAccess.make_dir_recursive_absolute(output)
	router = root.get_node("SceneRouter")
	host = root.get_node_or_null("SceneArtQualityRuntime")
	var bridge := root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended", true)
	if not need(bridge.call("is_checkpoint_saves_suspended") == true and host != null and host.call("get_debug_state").get("ready") == true, "BASE_RUNTIME_AND_SAVE_ISOLATION"): finish(); return
	var prior := current_scene.get_instance_id() if is_instance_valid(current_scene) else 0
	var dispatcher := load(DISPATCH) as GDScript
	var extension := {"region_id":CIVIC, "revision":1, "logical_id":LOGICAL, "global_foot_px":[RETURN.x,RETURN.y]}
	if not need(dispatcher != null and dispatcher.call("start",router,StringName(LOGICAL),Vector2(0.5,0.5),"",-1,extension) == true, "ORIGINAL_CIVIC_NEAR_ROUTE_SETUP"): finish(); return
	var outside: Node = await _wait_field(CIVIC, prior)
	if outside == null: finish(); return
	await _key(KEY_W,12)
	var door := _door(outside,"enter_yihongyuan27n")
	if not need(door != null and door.call("_can_enter") == true, "ORIGINAL_EXTERIOR_DOOR"): finish(); return
	prior = outside.get_instance_id()
	await _key(KEY_SPACE,1)
	var lower: Node = await _wait_field(ROOM,prior)
	if lower == null: finish(); return
	var lower_player: Node2D = lower.get("_player")
	if not need(lower_player.position.distance_to(ENTRY) <= 1.0, "UNCHANGED_LOWER_ARRIVAL"): finish(); return
	if not need(_visual_count(lower,TABLE) == 3 and _visual_count(lower,STAIRS) >= 1 and (lower.get("_region_actors") as Dictionary).size() == 10, "THREE_NEW_TABLES_STAIR_ORIGINAL_TEN_ACTORS"): finish(); return
	var lower_region: Dictionary = lower.get("_region")
	var recovery := load(FLOOR_HELPER) as GDScript
	var mock_old := {"region_id":ROOM,"logical_id":ROOM,"revision":lower_region.revision,"global_foot_px":[390,500]}
	var recovered: Dictionary = recovery.call("recover_lower_stair",lower_region,ROOM,Vector2(0.5,0.5),lower_region.districts[ROOM].legacy_version,mock_old,{"ok":false,"error":"REGION_SAVED_FOOT_BLOCKED"}) if recovery != null else {}
	if not need(recovered.get("foot") == ENTRY and recovered.get("reason") == "yihong_recent_lower_legal_now_stair_blocked","SYNTHETIC_PRIOR_VALID_FOOT_RECOVERY"): finish(); return
	if not await _capture("lower_hall.png"): finish(); return
	await _key(KEY_W,32)
	await _key(KEY_A,44)
	await _key(KEY_W,17)
	evidence["lower_stair_foot"] = str(lower_player.position)
	var up := _door(lower,UP_ID)
	if not need(up != null and up.call("_can_enter") == true, "TRUE_WALK_UP_THE_TREADS"): finish(); return
	if not await _capture("lower_stair_treads.png"): finish(); return
	prior = lower.get_instance_id()
	await _key(KEY_SPACE,1)
	var upper: Node = await _wait_upper(prior)
	if upper == null: finish(); return
	var upper_player: Node2D = upper.get("_player")
	if not need(upper_player.position.distance_to(UP_ARRIVAL) <= 1.0 and _visual_count(upper,UPPER_ART) >= 1 and _visual_count(upper,TABLE) >= 1, "UPPER_FLOOR_HAS_OWN_SHELL_TABLE_AND_ARRIVAL"): finish(); return
	evidence["upper_arrival"] = str(upper_player.position)
	if not await _capture("upper_salon.png"): finish(); return
	await _key(KEY_S,12)
	evidence["upper_stair_foot"] = str(upper_player.position)
	var down := _door(upper,DOWN_ID)
	if not need(down != null and down.call("_can_enter") == true,"TRUE_WALK_TO_UPPER_STAIR_OPENING"): finish(); return
	prior = upper.get_instance_id()
	await _key(KEY_SPACE,1)
	lower = await _wait_field(ROOM,prior)
	if lower == null: finish(); return
	lower_player = lower.get("_player")
	if not need(lower_player.position.distance_to(DOWN_ARRIVAL) <= 1.0, "EXACT_STAIR_RETURN_NOT_MAIN_ENTRANCE"): finish(); return
	evidence["lower_arrival"] = str(lower_player.position)
	await _key(KEY_S,3)
	await _key(KEY_D,44)
	await _key(KEY_S,40)
	var street := _door(lower,"yihongyuan27n_exit")
	if not need(street != null and street.call("_can_enter") == true,"ORIGINAL_STREET_DOOR_STILL_REACHABLE"): finish(); return
	prior = lower.get_instance_id()
	await _key(KEY_SPACE,1)
	outside = await _wait_field(CIVIC,prior)
	if outside == null: finish(); return
	var foot: Vector2 = (outside.get("_player") as Node2D).position
	if not need(foot.distance_to(RETURN) <= 1.0,"ORIGINAL_EXACT_STREET_RETURN"): finish(); return
	evidence["street_return"] = str(foot)
	evidence["gate"] = check_gate_sources()
	need(evidence.gate.passed,"GATE_ACTUAL_C_TO_B_EXACT_SET_NO_TRAVEL")
	finish()

func _visual_count(field: Node, path: String) -> int:
	var count := 0
	for value: Variant in (field.get("_region_visuals") as Dictionary).values():
		if value is Sprite2D and value.texture != null and value.texture.resource_path == path: count += 1
	return count

func _wait_upper(previous: int) -> Node:
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 30000:
		await process_frame
		var field: Node = current_scene
		if not is_instance_valid(field) or field.get_instance_id() == previous or field.get_script() == null or field.get_script().resource_path != FIELD: continue
		var region: Dictionary = field.get("_region")
		if region.get("id") != UPPER: continue
		if field.get("_field_loading_failed") == true: need(false,"UPPER_FIELD_FAILED"); return null
		var loader := root.get_node("LoadingManager")
		if field.get("_field_loading_complete") != true or loader.get("_transition_active") == true or loader.get("_external_active") == true: continue
		var player: Node = field.get("_player")
		var mini: Node = field.get("_world_travel_minimap")
		if player == null or player.get("can_move") != true or mini == null or mini.call("get_debug_state").get("visual_cache_ready") != true: continue
		var owner: RefCounted = field.get("_region_owner")
		var receipt: Dictionary = owner.call("receipt") if owner != null else {}
		if not need(receipt.get("phase") == "LIVE" and receipt.get("source_first") == receipt.get("source_final"), "UPPER_STRICT_SOURCE_OWNER_LIVE"): return null
		await physics_frame
		await RenderingServer.frame_post_draw
		return field
	need(false,"FINITE_UPPER_FIELD")
	return null

func _capture(filename: String) -> bool:
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	if not need(picture != null and picture.get_size() == Vector2i(1920,1080),"NORMAL_1080P_VIEW:"+filename): return false
	var path := output + filename
	if not need(picture.save_png(path) == OK,"EVIDENCE_IMAGE:"+filename): return false
	evidence[filename] = path
	return true
