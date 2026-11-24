extends "res://build/world_sects_cities_20261031c_qa01/probe_base_ROOT_ONLY.gd"
## Root-only three additive portals; no encounters, collection or old city tour.
const FIXTURE: String="res://build/adventure_world_20261031f_qa01/three_world_doors_inputs_READY.json"
const LINKS_PATH: String="res://build/adventure_world_20261031f_system01/world_links.gd"
const WORLD_SIZE:=Vector2(12288,8192)
const UNLOCK: String="zhuwei_village_inquiry_done"
const ORIGIN: String="adventure_world_origin_v1"
var links: Node
var original_flags: Dictionary
var original_core: Dictionary
func _watch() -> void:
	await create_timer(90.0,true,false,true).timeout
	if not done:need(false,"HARD90S_THREE_NEW_WORLD_LINKS");finish()
func boot(_domain: String) -> bool:
	directory="res://build/adventure_world_20261031f_qa01/three_doors02_actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"EARLIEST_CHECKPOINT_SUSPEND_NO_REAL_SAVE_API"):return false
	router=root.get_node("SceneRouter")
	cfg=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)) as Dictionary
	for path: String in cfg.pins:
		if not need(FileAccess.get_sha256(path)==String(cfg.pins[path]),"EXPLICIT_CURRENT_PIN:"+path):return false
	links=root.get_node_or_null("AdventureRuntime/AdventureWorldLinks31f")
	return need(is_instance_valid(links),"NEW_ADDITIVE_HELPER_ATTACHED")
func core() -> Dictionary:
	var game: Node=root.get_node("GameState");var player: Resource=game.get("player") as Resource;var party: Array=[]
	for member: Resource in game.get("party"):party.append(member.get_instance_id())
	var flags: Dictionary=(game.get("flags") as Dictionary).duplicate(true);flags.erase(UNLOCK);flags.erase(ORIGIN)
	return {"player_instance":player.get_instance_id(),"hp":player.get("hp"),"mp":player.get("mp"),"gold":game.get("gold"),"party_instances":party,"other_flags":flags}
func wait_world_links() -> bool:
	for index: int in range(75):
		var debug: Dictionary=links.call("get_debug_state")
		if debug.get("owner")==field and int(debug.get("added_door_count",0))==3:return true
		await tick()
	return need(false,"NEW_WORLD_OVERLAY_ATTACH_TIMEOUT")
func wait_return_binding() -> ExitZone:
	for index: int in range(75):
		var debug: Dictionary=links.call("get_debug_state");var zone: ExitZone=debug.get("return_zone") as ExitZone
		if is_instance_valid(zone) and field.is_ancestor_of(zone):return zone
		await tick()
	need(false,"ORIGINAL_ADVENTURE_RETURN_ZONE_NOT_BOUND");return null
func wait_origin_clear() -> bool:
	for index: int in range(75):
		var debug: Dictionary=links.call("get_debug_state")
		if not bool(debug.get("return_pending",false)) and (links.call("validated_origin") as Dictionary).is_empty():return true
		await tick()
	return need(false,"ORIGIN_NOT_CONSUMED_AFTER_TRUE_RETURN")
func world_ui_and_landmark(row: Dictionary) -> bool:
	var mini: Control=field.get("_world_travel_minimap") as Control
	var pip: Node=mini.get_node_or_null("AdventureWorldPips31f") if is_instance_valid(mini) else null
	for index: int in range(20):
		if pip!=null:break
		await tick();pip=mini.get_node_or_null("AdventureWorldPips31f") if is_instance_valid(mini) else null
	if not need(is_instance_valid(mini) and mini.is_visible_in_tree() and pip!=null and (pip.call("get_debug_state") as Dictionary).get("added_count")==3,"WORLD_MINIMAP_VISIBLE_WITH_THREE_ADDED_PIPS"):return false
	var overlay: Node=world.get_node_or_null("AdventureWorldLinks31f")
	var landmark: Sprite2D=overlay.get_node_or_null(String(row.id)+"_WholeLandmark") as Sprite2D if overlay!=null else null
	if not need(is_instance_valid(landmark) and landmark.visible and landmark.texture!=null and not landmark.texture is AtlasTexture and landmark.get_meta("whole_existing_asset","")==row.art,"WHOLE_EXISTING_LANDMARK_NO_CROP"):return false
	records.append({"normal_world_landmark":row.id,"whole_texture_path":landmark.texture.resource_path,"sprite_scale":landmark.scale,"minimap_added_pips":3})
	await shot("world_new_forest_landmark_and_three_pips")
	return true
func shared_map(row: Dictionary,source: Vector2) -> bool:
	key(KEY_M);await tick();key(KEY_NONE)
	var panel: Variant
	for index: int in range(40):
		await tick();panel=field.get("_world_map_panel")
		if panel!=null and panel.visible:
			var count:=0
			for child: Node in panel.map_rect.get_children():
				if child.has_meta("adventure31f_map_id") and not child.is_queued_for_deletion():count+=1
			if count==3:break
	if not need(panel!=null and panel.is_visible_in_tree(),"TRUE_M_PANEL_OPEN"):return false
	var ids: Array[String]=[];var marker: Sprite2D
	for child: Node in panel.map_rect.get_children():
		if child is Label and child.has_meta("adventure31f_map_id") and not child.is_queued_for_deletion():ids.append(String(child.get_meta("adventure31f_map_id")))
		if child is Sprite2D and child.get_meta("adventure31f_origin_marker","")==row.id:marker=child
	ids.sort();var expected: Array[String]=[]
	for candidate: Dictionary in cfg.rows:expected.append(String(candidate.id))
	expected.sort()
	if not need(ids==expected,"M_THREE_DISTINCT_NEW_LOCATION_LABELS"):return false
	if not need(marker!=null and marker.position.distance_to(source/WORLD_SIZE*panel.map_rect.size+Vector2(0,-29))<.01,"M_HERO_MARKER_AT_ACTUAL_WORLD_ORIGIN"):return false
	await shot("shared_M_map_three_new_locations_actual_origin")
	key(KEY_ESCAPE);await tick();key(KEY_NONE)
	for index: int in range(20):
		await tick()
		if not panel.visible and actor.can_move:return true
	return need(false,"TRUE_ESCAPE_MAP_CLOSE")
func local_mine_G_representative() -> bool:
	var source_id:=&"openworld_xiangzhou_mine_valley"
	if not await setup(source_id,Vector2(1000,1500)/Vector2(3072,2048)):return false
	var runtime: Node=root.get_node("AdventureRuntime");var expected: String="entry_adventure_xiangzhou_deep_mine"
	for index: int in range(40):
		await tick()
		if String(runtime.get("_near"))==expected:break
	if not need(String(runtime.get("_near"))==expected and (links.call("validated_origin") as Dictionary).is_empty(),"ORIGINAL_LOCAL_G_CONNECTOR_READY_NO_FORGED_WORLD_ORIGIN"):return false
	var before: Dictionary=core();var old: int=field.get_instance_id()
	key(KEY_G);await tick();key(KEY_NONE)
	if not await ready_field(&"adventure_xiangzhou_deep_mine",old):return false
	for index: int in range(20):await tick()
	var debug: Dictionary=links.call("get_debug_state")
	if not need((links.call("validated_origin") as Dictionary).is_empty() and not bool(debug.get("local_pending",false)),"ACTUAL_LOCAL_G_ACCEPTED_TARGET_REMAINS_LOCAL_PROVENANCE"):return false
	var zone: ExitZone
	for candidate: ExitZone in field.get("_exit_nodes"):
		if candidate.target_scene_id==String(source_id):zone=candidate;break
	if not need(zone!=null and zone.exit_label!="返回江湖大地图","ORIGINAL_LOCAL_RETURN_ARROW_RESTORED"):return false
	if not await walk(vec(cfg.return_foot),24):return false
	if not need(bool(zone.call("can_enter")),"ORIGINAL_LOCAL_RETURN_ARROW_TRUE_OVERLAP"):return false
	if not await enter(source_id):return false
	if not need(core()==before and (links.call("validated_origin") as Dictionary).is_empty(),"TRUE_ORIGINAL_LOCAL_G_AND_SPACE_RETURN_PRESERVED"):return false
	records.append({"representative_original_G":source_id,"old_mine_no_walk_or_random_encounter":true,"actual_local_return_foot":foot(),"original_connector_basis":Vector2(3072,2048),"original_connector_foot":Vector2(1000,1500),"no_fake_positive_world_origin":true})
	return true
func _run() -> void:
	if not await boot("three_doors"):finish();return
	var game: Node=root.get_node("GameState");original_flags=(game.get("flags") as Dictionary).duplicate(true);original_core=core()
	if not need(not original_flags.has(ORIGIN),"FRESH_MEMORY_HAS_NO_FABRICATED_WORLD_PROVENANCE"):finish();return
	for index: int in range(cfg.rows.size()):
		var row: Dictionary=cfg.rows[index];var source: Vector2=vec(row.world_foot)
		if not await setup(&"world_map_jianghu",source/WORLD_SIZE):finish();return
		if not await wait_world_links():finish();return
		if not need(foot().distance_to(source)<.01,"ACTUAL_WORLD_SOURCE_NOT_REPAIRED:"+String(row.id)):finish();return
		var door: ExitZone;var count:=0
		for zone: ExitZone in field.get("_exit_nodes"):
			if zone.get_meta("portal_id","")==row.id:door=zone;count+=1
		if not need(count==1 and door!=null and door.target_scene_id==row.target_scene,"UNIQUE_NEW_EXITZONE:"+String(row.id)):finish();return
		if index==0:
			## Prefix locked refusal passed in121152; unlock only to reach residual M/return.
			(game.get("flags") as Dictionary)[UNLOCK]=true
			for update_index: int in range(12):await tick()
		var stream: Variant=field.get("_world_v15_stream");var contract: Variant=router.call("layered_world_contract",field.get("_current_scene"))
		if not need(contract.safe_foot(field.get("_current_scene"),foot()/WORLD_SIZE) and stream.visual_ready_for_motion(foot()) and load(LINKS_PATH).actor_shape_clear(actor) and bool(door.call("can_enter")),"SOURCE_CONTRACT_STREAM_READY_REAL_ACTOR_SHAPE_AND_DOOR_SAFE:"+String(row.id)):finish();return
		## Prefix World landmark/minimap image already captured in121152; no duplicate image.
		if not await enter(StringName(row.target_scene)):finish();return
		var origin: Dictionary=links.call("validated_origin",String(row.target_scene))
		if not need(not origin.is_empty() and origin.row.id==row.id and origin.foot.distance_to(source)<.01,"ACTUAL_WORLD_ORIGIN_FIXED_ROW_EXACT_FOOT:"+String(row.id)):finish();return
		var returning: ExitZone=await wait_return_binding()
		if returning==null:finish();return
		if not need(returning.target_scene_id=="world_map_jianghu" and returning.target_spawn_pos.distance_to(source/WORLD_SIZE)<.00001,"ORIGINAL_RETURN_ARROW_REBOUND_ONLY_WITH_TRUSTED_ORIGIN:"+String(row.id)):finish();return
		if index==0 and not await shared_map(row,source):finish();return
		var target: Vector2=vec(cfg.return_foot)
		if not await walk(target,24):finish();return
		if not need(bool(returning.call("can_enter")) and load(LINKS_PATH).actor_shape_clear(actor),"ORIGINAL_RETURN_ARROW_REAL_OVERLAP_SHAPE_CLEAR:"+String(row.id)):finish();return
		if not await enter(&"world_map_jianghu"):finish();return
		if not await wait_origin_clear():finish();return
		if not need(foot().distance_to(source)<.01 and core()==original_core,"TRUE_WORLD_RETURN_EXACT_FOOT_AND_MEMORY_PRESERVED:"+String(row.id)):finish();return
		records.append({"true_world_entry_and_return":row.id,"actual_return_foot":foot(),"only_local_public_setup_not_cross_world_travel":true})
	if not await local_mine_G_representative():finish();return
	## Cleanup isolated QA memory only, no storyline or origin fabrication.
	game.set("flags",original_flags.duplicate(true))
	need((game.get("flags") as Dictionary)==original_flags,"ALL_MEMORY_FLAGS_RESTORED_AFTER_TEMPORARY_QA_UNLOCK")
	finish()
func finish() -> void:
	if done:return
	key(KEY_NONE);done=true
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"input_events":inputs,"scope":"three new World doors true Space and original adventure arrows true direct World return; residual shared M only; original normal landmark image inherited from121152; no combat/gather/craft/old city travel","real_save_API_calls":0,"actor_camera_writes":0},"\t"));file.close()
	quit(0 if errors.is_empty() else 1)
