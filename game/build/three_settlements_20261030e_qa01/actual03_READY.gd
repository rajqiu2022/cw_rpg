extends "res://build/three_settlements_20261030e_qa01/actual_READY.gd"
## Residual only: Xiangzhou greeting/service/board/return, then first Qinghe/Yanmen legs.
const RESIDUAL_FIXTURE := "res://build/three_settlements_20261030e_qa01/actual03_READY.json"
const FIRST_RESULT := "res://build/three_settlements_20261030e_qa01/actual/77552/result.json"
func _initialize() -> void:
	_watchdog.call_deferred();_run.call_deferred()
func _run() -> void:
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(RESIDUAL_FIXTURE))
	if not need(raw is Dictionary and raw.get("ready")==true,"ROOT_RESIDUAL_FROZEN_FIXTURE"):finish();return
	spec=raw;first_sources=facts(spec.fixed_sources.keys());first_saves=facts(spec.registered_save_paths)
	for path: String in spec.fixed_sources:
		if not need(first_sources[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path):finish();return
	router=root.get_node("SceneRouter");game=root.get_node("GameState");dialog=root.get_node("DialogPlayer")
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	if not need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"RESIDUAL_CHECKPOINT_SUSPENDED"):finish();return
	first_bounties_raw=root.get_node("BountyManager").call("to_dict").duplicate(true);first_state=state()
	var first: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIRST_RESULT))
	if not need(first is Dictionary and first.get("passed")==false and first.get("checks")==170 and first.get("errors")==["ORIGINAL_SERVICE_NO_TASK_OR_ECONOMY_CHANGE:openworld_xiangzhou_city"],"ORIGINAL170_ONEFAIL_RETAINED"):finish();return
	records.append({"inherited":"77552: Xiangzhou actual World entry/32px/arrival+bridge two accepted images and Router admission; not replayed","original_result":FIRST_RESULT,"original_result_sha256":FileAccess.get_sha256(FIRST_RESULT)})
	if not await xiangzhou_service_residual():finish();return
	for leg: Dictionary in spec.legs:
		if not await run_leg(leg):finish();return
	need(state()==first_state,"RESIDUAL_ALL_REAL_HERO_PARTY_STATS_QUESTS_ITEMS_SEMANTICALLY_SAME")
	records.append({"bounty_raw_before":first_bounties_raw,"bounty_raw_after":root.get_node("BountyManager").call("to_dict"),"normalization":"Only two original Xiangzhou IDs exact four-field available/-1/0/0 defaults; unknown/new active/captured/additional fields remain exact"})
	finish()
func key(code: int,ticks: int) -> void:
	if code in [KEY_1,KEY_2] and dialog!=null and dialog.call("is_playing")==true:
		var node: Resource=dialog.get("_current_node") as Resource
		if node!=null and (node.get("choices") as Array).is_empty():
			var speaker: String=String(node.get("speaker"));var hero: Resource=game.get("player") as Resource
			if not need(speaker==String(hero.get("display_name")),"REAL_HERO_GREETING_BEFORE_ORIGINAL_CHOICES"):return
			records.append({"phase":"actual_Hero_greeting","speaker":speaker,"node":String(node.get("node_id")),"dialog":String((dialog.get("_current_script") as Resource).get("dialog_id"))})
			await super.key(KEY_SPACE,1)
			for _frame: int in range(3):await process_frame
		node=dialog.get("_current_node") as Resource
		var box: Node=dialog.get("_box") as Node
		var choices_visible: bool=box!=null and (box.get("choices_container") as Control).visible
		if not need(node!=null and (node.get("choices") as Array).size()>=2 and choices_visible,"ACTUAL_ORIGINAL_NPC_CHOICES_VISIBLE_BEFORE_NUMBER"):return
		records.append({"phase":"actual_NPC_choices","speaker":String(node.get("speaker")),"node":String(node.get("node_id")),"choices":node.get("choices"),"number_key":code-KEY_1+1})
	await super.key(code,ticks)
func capture(label: String) -> bool:
	if label=="openworld_yanmen_pass_arrival":
		# Arrival32px already happened. This is an explicit public new-Field setup,
		# so the first snow image shows the gate rather than repeating an empty road.
		var author: Variant=load("res://build/three_settlements_20261030e_yanmen01/yanmen_author.gd")
		var foot: Vector2=point(spec.yanmen_first_image_foot)
		if not need(router.call("go_field_smart",&"openworld_yanmen_pass",foot/author.SIZE,"",-1,30)==true,"PUBLIC_YANMEN_GATE_IMAGE_SETUP_NOT_CONTINUOUS_WALK"):return false
		var field: Node=await wait_field("openworld_yanmen_pass")
		if field==null:return false
		if not need((field.get("_player") as Node2D).position.distance_to(foot)<=1,"ACTUAL_YANMEN_GATE_IMAGE_FOOT"):return false
		records.append({"phase":"public_nearfoot_image_setup","id":"openworld_yanmen_pass","foot":foot,"not_continuous_from_arrival":true,"camera_assignments":0})
	return await super.capture(label)
func need(ok: bool,label: String) -> bool:
	if label.begins_with("ORIGINAL_SERVICE_NO_TASK_OR_ECONOMY_CHANGE") and game!=null:
		records.append({"phase":label,"dialog_playing":dialog.call("is_playing"),"state_equal":state()==first_state,"before":first_state,"after":state()})
	return super.need(ok,label)
func xiangzhou_service_residual() -> bool:
	var id: StringName=&"openworld_xiangzhou_city";var world_id: StringName=&"world_map_jianghu"
	var author: Variant=load("res://build/three_settlements_20261030e_system01/xiangzhou_author.gd")
	var foot:=Vector2(2470,1740)
	# Begin at the unfinished original service, not the passed World entry/bridge.
	if not need(router.call("go_field_smart",id,foot/author.SIZE,"",-1,30)==true,"PUBLIC_SERVICE_RESIDUAL_NEW_FIELD_SETUP"):return false
	var field: Node=await wait_field(String(id))
	if field==null:return false
	if not need((field.get("_player") as Node2D).position.distance_to(foot)<=1,"EXACT_SERVICE_RESIDUAL_SETUP_FOOT"):return false
	records.append({"phase":"public_nearfoot_service_setup","foot":foot,"not_replayed_World_entry":true,"not_continuous_old_process":true})
	await key(KEY_SPACE,1)
	for _frame: int in range(3):await process_frame
	var script: Resource=dialog.get("_current_script") as Resource
	if not need(dialog.call("is_playing")==true and script!=null and String(script.get("dialog_id"))=="openworld_xiangzhou_guide","REAL_ORIGINAL_GUARD_DIALOG_RESIDUAL"):return false
	await key(KEY_2,1)
	for _frame: int in range(3):await process_frame
	if not need(dialog.call("is_playing")==false,"GUARD_DIALOG_CLOSED_AFTER_REAL_HERO_ADVANCE_AND_CHOICE2"):return false
	records.append({"phase":"guard_dialog_closed","state_equal":state()==first_state,"before":first_state,"after":state()})
	if not need(state()==first_state,"GUARD_DIALOG_REAL_STATE_UNCHANGED"):return false
	# Root-requested new ART domain, same player/camera position; not either old image.
	if not await capture("openworld_xiangzhou_city_service_street"):return false
	if not need(router.call("go_field_smart",id,Vector2(3170,1740)/author.SIZE,"",-1,30)==true,"PUBLIC_ORIGINAL_BOARD_RESIDUAL_APPROACH"):return false
	field=await wait_field(String(id))
	if field==null:return false
	await key(KEY_SPACE,1)
	var board: Node=await wait_ui("res://scenes/bounty_board.tscn")
	var payload: Dictionary=router.call("get_bounty_board_payload")
	if not need(board!=null,"REAL_ORIGINAL_BOARD_UI_OPENED"):return false
	if not need(String(payload.get("city_id"))=="xiangzhou" and String(payload.get("return_scene"))==String(id) and int(payload.get("return_local_layout_version"))==30,"BOARD_ORIGINAL_CITY_AND_RETURN_VERSION"):return false
	await key(KEY_ESCAPE,1);field=await wait_field(String(id))
	if field==null:return false
	records.append({"phase":"board_closed_no_bounty_taken","state_equal":state()==first_state,"bounty_raw":root.get_node("BountyManager").call("to_dict")})
	if not need(state()==first_state,"BOARD_CLOSED_REAL_STATE_UNCHANGED_EXCEPT_KNOWN_DEFAULT_MATERIALIZATION"):return false
	if not need(router.call("go_field_smart",id,author.SOUTH_ARRIVAL/author.SIZE,"",-1,30)==true,"PUBLIC_NEAR_UNFINISHED_ORIGINAL_SOUTH_EXIT"):return false
	field=await wait_field(String(id))
	if field==null:return false
	var expected_gateway: Variant=router.call("get_world_map_position_for_scene",id,world_id)
	if not need(expected_gateway is Vector2,"ORIGINAL_WORLD_GATEWAY_READ_BEFORE_TRUE_EXIT"):return false
	await key(KEY_S,4)
	var exit: Node=null
	for zone: Node in field.get("_exit_nodes"):
		if String(zone.get("action"))=="world_map":exit=zone
	if not need(exit!=null and (bool(exit.call("_can_enter")) if exit.has_method("_can_enter") else bool(exit.get("_in_range"))),"RESIDUAL_SOUTH_EXIT_ACTUALLY_IN_RANGE"):return false
	await key(KEY_SPACE,1)
	var world: Node=await wait_field(String(world_id))
	if world==null:return false
	if not need((world.get("_player") as Node2D).position.distance_to(expected_gateway*point(spec.world_size))<=1,"UNFINISHED_TRUE_SOUTH_EXIT_TO_ORIGINAL_WORLD_GATEWAY"):return false
	if not need(state()==first_state,"XIANGZHOU_RESIDUAL_COMPLETE_REAL_STATE_UNCHANGED"):return false
	records.append({"phase":"xiangzhou_original_south_return","world_alias":String(world_id),"gateway_frozen_before_space":expected_gateway,"original_World_entry_and_two_images_inherited_from_77552":true})
	return true
func finish() -> void:
	if finished:return
	finished=true
	for code: int in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SPACE,KEY_1,KEY_2,KEY_ESCAPE]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false;Input.parse_input_event(event)
	Input.flush_buffered_events()
	if not first_sources.is_empty():need(first_sources==facts(first_sources.keys()),"SOURCE_FIRST_FINAL")
	if not first_saves.is_empty():need(first_saves==facts(first_saves.keys()),"SAVE_HASH_BYTES_SECONDS_SAME_ROOT_EXACTTICKS_SEPARATE")
	var path: String=OUTPUT+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(path):quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir());var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"input_ticks":input_ticks,"save_writes":0,"actor_camera_assignments":0,"old_success_prefix_inherited_from":FIRST_RESULT,"old_success_prefix_replayed":false,"original_whole_run_status":"170/1 FAIL_RETAINED","fixture_sha256":FileAccess.get_sha256(RESIDUAL_FIXTURE)},"\t"));file.close()
	print("SETTLEMENT30E_RESIDUAL_RESULT ",checks," / ",errors.size());quit(0 if errors.is_empty() else 1)
