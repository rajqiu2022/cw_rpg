extends "res://tests/test_luoyang_docks_roles_field_ready_retry1_20261019ad.gd"
## Remaining Space/portrait only. Explicit public station is not default birth or travel.
const SPACE_READY = true
const SPACE_BIND = "res://tests/fixtures/luoyang_docks_roles_space_only_20261019ad.json"
const SPACE_BIND_SHA = "feac61ad3a214ad4e90fa9f7d04235aa278b67bbc815bb8be5463cc3675246ab"
const SPACE_STATION = Vector2(1400,940)
var space_fixture: Dictionary = {}

func ab_preflight() -> bool:
	if not check(SPACE_READY,"Frozen remaining-only actual Space diagnostic"): return false
	if not track(SPACE_BIND,SPACE_BIND_SHA): return false
	space_fixture = json(SPACE_BIND)
	for path: String in space_fixture.source_sha256:
		if not track(path,space_fixture.source_sha256[path]): return false
	if not super.ab_preflight(): return false
	var evidence: Dictionary = space_fixture.prior_whole_failed_report
	if not track(evidence.path,evidence.sha256) or not track(space_fixture.prior_picture.path,space_fixture.prior_picture.sha256): return false
	var prior: Dictionary = json(evidence.path)
	if not check(prior.scope == "AD_ONE_ORDINARY_DOCKS_ROLE_SPRITE_PATROL_SPACE_VISIBLE_PORTRAIT" and prior.complete == false and prior.checks == 1946 and prior.failures == 1 and prior.source_before == prior.source_after and prior.players_before.size() == 15 and prior.players_before == prior.players_after,"Original112652 whole remains FAIL; source/save first-final intact"): return false
	var components: Dictionary = {}
	for row: Dictionary in prior.records:
		if not check(not components.has(row.kind),"Original completed component appears once"): return false
		components[row.kind] = row
	if not check(components.size() == 4 and components.has("ORDINARY_NULL_SPAWN_FIRSTDRAW_OPERABLE") and components.has("AD_ACTUAL_ROLE_ROWS_NATIVE_BODY_AND_MOVEMENT") and components.has("AD_NORMAL_INPUT_TO_ADOPTED_PERSON") and components.has("AD_NEW_WALK_ACTUAL_NATIVE_FACING"),"Only completed default/source,10row/6lane,INPUT and4phase components inherited"): return false
	var prior_source: Dictionary = components["ORDINARY_NULL_SPAWN_FIRSTDRAW_OPERABLE"]
	var rows: Dictionary = components["AD_ACTUAL_ROLE_ROWS_NATIVE_BODY_AND_MOVEMENT"]
	var route: Dictionary = components["AD_NORMAL_INPUT_TO_ADOPTED_PERSON"].result
	var walk: Dictionary = components["AD_NEW_WALK_ACTUAL_NATIVE_FACING"]
	if not check(prior_source.source_proof.sources_finalized == true and prior_source.source_proof.sources == expected_maps[DOCKS] and rows.patrol_count == 6 and rows.adopted_ids.size() == 3 and route.ok == true and route.segments.size() == 7,"Exactly completed prior source/role/route facts, not missing components"): return false
	for segment: Dictionary in route.segments:
		if not check(segment.ok == true and segment.all_recorded_feet_clear == true and segment.physics_samples > 0,"Prior actual route component only, no route rerun"): return false
	var phases: Dictionary = {}
	for value: Variant in walk.natural_frames:
		if not check((typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and float(value) == float(int(value)) and int(value) >= 0 and int(value) <= 3,"Original natural phase exact0..3"): return false
		phases[str(int(value))] = true
	if not check(walk.id == space_fixture.npc_id and walk.hframes == 4 and phases.size() == 4 and walk.cosine_samples.size() == 108 and walk.displacement_samples.size() == 108 and walk.fluid_loop_credit == false,"Actual prior four cells and108 native direction samples, no fluid/8frame credit"): return false
	for sample: Dictionary in walk.cosine_samples:
		if not check(sample.flip_h == (float(sample.cosine) < 0.0),"Prior actual cosine/flip component exact"): return false
	for sample: Dictionary in walk.displacement_samples:
		if not check(sample.flip_h == (float(sample.dx) < 0.0),"Prior actual displacement/flip component exact"): return false
	records.append({"kind":"AD_PRIOR_COMPLETED_COMPONENTS_ONLY_ORIGINAL_WHOLE_FAIL_RETAINED","path":evidence.path,"sha256":evidence.sha256,"original_complete":false,"original_failures":1,"components":["default1499sources","tenrows_sixlanes","normalINPUT","fourphase_108cos_dx"],"remaining_Space_portrait_credit":false})
	return check(Vector2(space_fixture.station_px[0],space_fixture.station_px[1]) == SPACE_STATION,"Independent fixed legal near station, no default21401840 claim")

func ab_arrive() -> bool:
	var start: int = Time.get_ticks_usec()
	if not check(root.get_node("SceneRouter").call("go_field_smart",StringName(DOCKS),SPACE_STATION/WORLD,"",-1,c.VERSION),"One public explicit near-station request; NOT default birth/INPUT travel",root.get_node("SceneRouter").call("get_public_city_preparation_state")): return false
	var until: int = mini(deadline,Time.get_ticks_msec()+60000)
	while Time.get_ticks_msec() < until:
		await process_frame
		var request: Dictionary = root.get_node("SceneRouter").call("get_public_city_preparation_state")
		if request.get("scene_id") == DOCKS and request.get("phase") == "FAILED": return check(false,"Remaining actual request failed",request)
		if not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): continue
		var state: Dictionary = current_scene.call("get_field_loading_state")
		if state.get("failed",false): return check(false,"Remaining actual Field failed",state)
		var candidate: SceneScript = current_scene.get("_current_scene") as SceneScript
		var player: CharacterBody2D = current_scene.get("_player") as CharacterBody2D
		if candidate == null or String(candidate.scene_id) != DOCKS or player == null or not bool(player.get("can_move")) or state.get("complete") != true: continue
		var screen: Node = root.get_node("LoadingManager").get("_screen")
		var panel: Control = screen.get("root") as Control if is_instance_valid(screen) else null
		if panel != null and panel.is_visible_in_tree(): continue
		await RenderingServer.frame_post_draw
		field = current_scene; scene = candidate
		var firstdraw: int = Time.get_ticks_usec()-start
		var hash_start: int = Time.get_ticks_usec()
		var proof: Dictionary = c.resident_receipt(scene)
		if not check(proof.get("sources_finalized") == true and proof.get("sources",{}) == expected_maps[DOCKS],"New actual same-owner complete1499 sources equals independent formal map"): return false
		for path: String in expected_maps[DOCKS]:
			if not track(path,expected_maps[DOCKS][path]): return false
		records.append({"kind":"AD_REMAINING_EXPLICIT_NEAR_STATION_NOT_DEFAULT_TRAVEL","firstdraw_operable_usec":firstdraw,"source_check_usec":Time.get_ticks_usec()-hash_start,"actual_foot":player.position,"source_count":proof.sources.size(),"default_birth_or_INPUT_credit":false})
		if not check(field.get_script().resource_path == FIELD and scene.actor_positions_are_feet and field.get("_world_size") == WORLD and player.position.distance_to(SPACE_STATION) < .03,"Exact explicit native station after public setup, no post-load teleport"): return false
		return _geometry(DOCKS)
	return check(false,"Remaining explicit station hidden/operable within unchanged60s")

func ad_trip() -> bool:
	ad_target = _person(space_fixture.npc_id); ad_target_id = space_fixture.npc_id
	if not check(ad_target != null and ad_adopted.has(ad_target_id),"One real originally adopted nearby actor, no rechecking ten rows/patrol/route"): return false
	return await ad_dialogue()

func ad_dialogue() -> bool:
	await driver.completed_actor_stage()
	if not check(not dp.call("is_playing") and _clear((field.get("_player") as Node2D).position),"Actual87517/native safe near-player before genuine Space"): return false
	ad_seen_text.clear()
	await driver.key(KEY_SPACE)
	await RenderingServer.frame_post_draw
	# Always retain exactly one ordinary-camera diagnostic image before node predicates.
	if not await _picture("ad_remaining_space_actual_ui_before_predicates"): return false
	var active: NPCNode = field.get("_active_dialog_npc") as NPCNode
	var current: DialogScript = dp.get("_current_script") as DialogScript
	var role: Dictionary = ad_adopted[ad_target_id]
	var opened: Dictionary = {"playing":dp.call("is_playing"),"same_original_actor":active == ad_target,"resource_path":current.resource_path if current != null else "NULL","expected_resource":"res://data/dialogs/"+role.ambient_dialog+".tres","conversation_active":ad_target._conversation_active}
	records.append({"kind":"AD_REMAINING_TRUE_SPACE_OPEN_DETAIL","detail":opened})
	if not check(opened.playing and opened.same_original_actor and opened.resource_path == opened.expected_resource and opened.conversation_active,"Real Space selected original actor and exact resource",opened): return false
	var expected: Dictionary = ab_binding.dialogues[current.resource_path]
	if not check(String(current.dialog_id) == expected.internal_dialog_id,"Separate actual internal resource identity"): return false
	var layer: CanvasLayer = dp.get("_box") as CanvasLayer
	var box: Control = layer.get_node_or_null("DialogBox") as Control if layer != null else null
	if not check(box != null and box.get_script() != null and box.get_script().resource_path == "res://scripts/ui/dialog_box.gd","Actual frozen DialogLayer child Control owns portrait/label, not CanvasLayer"): return false
	var portrait: TextureRect = box.get("portrait") as TextureRect
	var label: Label = box.get("speaker_label") as Label
	var stopped: Vector2 = ad_target.position
	var body_id: int = (ad_target.get("_body_collider") as Node).get_instance_id()
	for i: int in 2:
		await RenderingServer.frame_post_draw
		var node: DialogNode = dp.get("_current_node") as DialogNode
		var conditions: Dictionary = {
			"current_node_same_resource":node == current.nodes[i],
			"speaker_exact":node != null and node.speaker == ad_target.npc_name,
			"text_event_exists":not ad_seen_text.is_empty(),
			"event_speaker_exact":not ad_seen_text.is_empty() and ad_seen_text.back().speaker == ad_target.npc_name,
			"event_portrait_exact":not ad_seen_text.is_empty() and ad_seen_text.back().portrait == ad_target.portrait_path,
			"portrait_node_exists":portrait != null,
			"portrait_visible_in_tree":portrait != null and portrait.is_visible_in_tree(),
			"portrait_texture_exists":portrait != null and portrait.texture != null,
			"portrait_texture_exact":portrait != null and portrait.texture != null and portrait.texture.resource_path == ad_target.portrait_path,
			"label_exact":label != null and label.text == ad_target.npc_name,
			"same_stopped_position":ad_target.position == stopped,
			"original_idle_texture_exact":ad_target.sprite.texture.resource_path == ad_target.sprite_path}
		var detail: Dictionary = {"index":i,"conditions":conditions,"node_id":String(node.node_id) if node != null else "NULL","expected_node_id":String(current.nodes[i].node_id),"node_instance":node.get_instance_id() if node != null else 0,"expected_node_instance":current.nodes[i].get_instance_id(),"events":ad_seen_text.duplicate(true),"npc_name":ad_target.npc_name,"npc_portrait":ad_target.portrait_path,"actual_portrait_texture":portrait.texture.resource_path if portrait != null and portrait.texture != null else "NULL","label":label.text if label != null else "NULL","position":ad_target.position,"stopped":stopped,"actual_sprite_texture":ad_target.sprite.texture.resource_path,"expected_idle":ad_target.sprite_path,"conversation_active":ad_target._conversation_active,"player_global":(field.get("_player") as Node2D).global_position,"npc_global":ad_target.global_position}
		records.append({"kind":"AD_REMAINING_SPACE_NODE_ALL_PREDICATES_DETAIL","detail":detail})
		var all_ok: bool = true
		for key: String in conditions: all_ok = all_ok and conditions[key] == true
		if not check(all_ok,"All original node/visible portrait/stopped idle predicates unchanged "+str(i),detail): return false
		await driver.key(KEY_SPACE)
		await process_frame
	if not check(not dp.call("is_playing"),"Both harmless genuine UI Space advances end"): return false
	await driver.completed_actor_stage()
	if not check(_person(ad_target_id) == ad_target and (ad_target.get("_body_collider") as Node).get_instance_id() == body_id and not ad_target._conversation_active and (field.get("_player") as Node).get("can_move") == true,"Same actor/body survives actual talk and original control resumes"): return false
	records.append({"kind":"AD_REMAINING_ACTUAL_SPACE_VISIBLE_SAMEPERSON_PORTRAIT_COMPLETED","id":ad_target_id,"dialog_resource":current.resource_path,"internal_id":current.dialog_id,"portrait":ad_target.portrait_path,"same_actor":true})
	return true

func _run() -> void:
	began = Time.get_ticks_msec(); deadline = began+90000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	players_before = saves(); folder = "res://build/luoyang_docks_roles_20261019ad_qa01/space_only_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool = ab_preflight()
	if complete:
		gs = root.get_node("GameState"); qm = root.get_node("QuestManager"); dp = root.get_node("DialogPlayer")
		original_parts = {"flags":gs.get("flags").duplicate(true),"quests":qm.call("to_dict").duplicate(true)}; original_rewards = _rewards()
		dp.connect("text_displayed",ad_text)
		driver = (load(INPUT_PATH) as Script).new(); driver.configure(self)
		complete = await ab_arrive()
		if complete: complete = await ad_trip()
	if dp != null and dp.is_connected("text_displayed",ad_text): dp.disconnect("text_displayed",ad_text)
	if driver != null: driver.release(); driver = null
	if is_instance_valid(current_scene):
		var own: Node = current_scene; var weak: WeakRef = weakref(own)
		current_scene = null; own.queue_free(); field = null; scene = null; own = null; ad_target = null
		await process_frame; await process_frame
		check(weak.get_ref() == null,"Only own Docks Field released; no other city/room travel")
	if not original_parts.is_empty():
		check(qm.call("to_dict") == original_parts.quests and _rewards() == original_rewards,"Daily dialogue has no quest/reward/inventory changes")
		gs.set("flags",original_parts.flags.duplicate(true)); qm.call("from_dict",original_parts.quests.duplicate(true))
		check(gs.get("flags") == original_parts.flags and qm.call("to_dict") == original_parts.quests,"Only ordinary visit flags restored in memory, no slot writes")
	oracle = null; mask = null; ab_packet.clear(); ab_record.clear()
	var after: Dictionary = {}
	for path: String in source_before: after[path] = fact(path)
	var saved: Dictionary = saves()
	check(source_before == after and players_before == saved and saved.size() == 15,"All complete sources and15save first-final facts unchanged")
	check(pictures.size() <= 1 and Time.get_ticks_msec() < deadline,"Original90s/60s arrival, maximum1 ordinary diagnostic capture")
	var path := folder.path_join("result.json"); var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"scope":"AD_REMAINING_EXPLICIT_STATION_TRUE_SPACE_PORTRAIT_NOT_DEFAULT_TRAVEL_OR_PATROL","complete":complete and failures == 0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"budget_ms":90000,"arrival_ms":60000,"native_queries":native_queries,"records":records,"pictures":pictures,"source_before":source_before,"source_after":after,"players_before":players_before,"players_after":saved,"task_chain_or_AC_geometry_repeated":false,"full_city_art_credit":false},"\t",true,true)); file.close()
	print(JSON.stringify({"report_path":path,"checks":checks,"failures":failures,"complete":complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)
