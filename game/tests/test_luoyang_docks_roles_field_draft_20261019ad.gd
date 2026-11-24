extends "res://tests/test_luoyang_docks_workyard_field_ready_retry1_20261019ac.gd"
## AD-only skeleton. Never calls AC new-object/ghost trip or old task suites.
const AD_FIELD_READY = false
const AD_BINDING = "PENDING_AD_FORMAL_SOURCE_AND_ASSET_FIXTURE"
const AD_BINDING_SHA = "PENDING"
const AD_API = "res://scripts/city/luoyang_docks_roles_20261019ad.gd"
var ad_api: Script
var ad_ready: Dictionary = {}
var ad_expected_rows: Array = []
var ad_adopted: Dictionary = {}
var ad_target: NPCNode
var ad_target_id: String = ""
var ad_seen_text: Array = []

func ab_preflight() -> bool:
	if not check(AD_FIELD_READY and DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0 and OS.get_cmdline_user_args().is_empty(),"AD one ordinary Docks, final noargs source/assets required, NOTREADY"): return false
	if not track(AD_BINDING,AD_BINDING_SHA): return false
	ab_binding = json(AD_BINDING)
	for path: String in ab_binding.source_sha256:
		if not track(path,ab_binding.source_sha256[path]): return false
	if not track(ab_binding.expected_map_path,ab_binding.expected_map_sha256): return false
	expected_maps[DOCKS] = json(ab_binding.expected_map_path).source_sha256.duplicate(true)
	if not check(expected_maps[DOCKS].size() == ab_binding.expected_source_count,"Independent AC1481 plus finite AD authored source successor, never actual backfill"): return false
	var cpu: Dictionary = json(ab_binding.cpu_report.path)
	if not track(ab_binding.cpu_report.path,ab_binding.cpu_report.sha256): return false
	if not check(cpu.complete == true and cpu.failures == 0 and cpu.scope == "AD_DOCKS_ROLE_PURE_ROW_ASSET_DIALOG_AND_LOCAL_BODY_NOT_FIELD" and cpu.source_before == cpu.source_after and cpu.players_before.size() == 15 and cpu.players_before == cpu.players_after and cpu.state_before == cpu.state_after,"Actual AD CPU partial/adopted rows and evidence, no borrowed AC role credit"): return false
	b = load(B_PATH); c = load(C_PATH); ac_api = load(AC_MODULE); ad_api = load(AD_API)
	if not check(b != null and b.can_instantiate() and c != null and c.can_instantiate() and ac_api != null and ac_api.can_instantiate() and ad_api != null and ad_api.can_instantiate() and ad_api.requested(StringName(DOCKS)),"Real canonical APIs and default AD activation, no candidate flag"): return false
	ad_ready = ad_api.readiness()
	if not check(ad_ready.get("ok") == true,"Real frozen AD readiness",ad_ready): return false
	ab_packet = bytes_to_var(FileAccess.get_file_as_bytes(AC_PACKET))
	if not check(b.ac_packet_valid(ab_packet) and _v(ab_packet.record.entry_foot_px) == AB_DEFAULT_FOOT,"Unchanged29 native geometry/default21401840, no new AC geometry replay"): return false
	var crowd: Script = load(ad_api.CROWD); var office: Script = load(ad_api.OFFICE)
	var parent: Array = crowd.project(StringName(DOCKS)).duplicate(true)
	var office_author: Dictionary = office.author()
	for row: Dictionary in parent:
		if office_author.roles.has(row.npc_id): row.sprite_path = office_author.roles[row.npc_id].texture
	var projected: Dictionary = ad_api.compose_exact(parent,parent,ad_ready.spec)
	if not check(projected.get("ok") == true,"Independent pure expected ten-row plan; not fake native ownership"): return false
	ad_expected_rows = projected.npcs.duplicate(true)
	for role: Dictionary in ad_ready.spec.roles: ad_adopted[role.npc_id] = role
	ad_target_id = "harbour_life_docks_rope_carrier" if ad_adopted.has("harbour_life_docks_rope_carrier") else "harbour_life_docks_store_attendant"
	if not check(ad_adopted.has(ad_target_id),"Representative selected only from the actually approved subset"): return false
	var self_path: String = get_script().resource_path
	return track(self_path,FileAccess.get_sha256(self_path))

func ad_actual_rows() -> bool:
	var moving := 0
	for row: Dictionary in ad_expected_rows:
		var npc := _person(row.npc_id)
		if npc == null: return false
		var foot := Vector2(row.pos.x*WORLD.x,row.pos.y*WORLD.y)
		var original: Vector2 = npc.get("_patrol_origin")
		if not check(npc.npc_name == row.npc_name and npc.sprite_path == row.sprite_path and npc.walk_sprite_path == row.walk_sprite_path and npc.dialog_id == row.dialog_id and npc.interaction_action == row.interaction_action and npc.movement_mode == row.movement_mode and npc.patrol_axis == row.patrol_axis and npc.patrol_distance == row.patrol_distance and npc.patrol_speed == row.patrol_speed and npc.invert_patrol_facing == row.invert_patrol_facing and npc.walk_frame_seconds == row.walk_frame_seconds and original == foot and npc._calibrate_adult_body and npc._ground_anchored,"Actual original ID/name/foot/primary/sixlane config, only approved appearance differs "+row.npc_id): return false
		if row.movement_mode == "patrol": moving += 1
		else:
			if not check(npc.position == foot,"Static role exact original foot "+row.npc_id): return false
		var body := npc.get("_body_collider") as StaticBody2D
		var shape := body.get_child(0) as CollisionShape2D
		if not check((shape.shape as RectangleShape2D).size == Vector2(22.4,28.8) and body.position+shape.position == Vector2.ZERO,"Original native ground body independent of new visual calibration "+row.npc_id): return false
		if ad_adopted.has(row.npc_id):
			if not check(npc.portrait_path == row.portrait_path and (npc.get("_idle_texture") as Texture2D).resource_path == row.sprite_path,"Actual adopted same-person idle/portrait identity "+row.npc_id): return false
			if row.npc_id == ad_target_id: ad_target = npc
	records.append({"kind":"AD_ACTUAL_ROLE_ROWS_NATIVE_BODY_AND_MOVEMENT","adopted_ids":ad_adopted.keys(),"patrol_count":moving,"original_h_jobs_chief_culture_preserved":"strict row/full native inverse; no task replay"})
	return check(moving == 6 and ad_target != null,"Six real existing patrols retained and adopted representative exists")

func ad_text(speaker: String,text: String,choices: bool,portrait: String) -> void:
	ad_seen_text.append({"speaker":speaker,"text":text,"choices":choices,"portrait":portrait})

func ad_patrol_observe() -> bool:
	var actor := _person("harbour_life_docks_rope_carrier")
	if actor == null: return false
	var frames: Dictionary = {}; var first := actor.position; var last := first
	var until := mini(deadline,Time.get_ticks_msec()+1800)
	while Time.get_ticks_msec() < until:
		await RenderingServer.frame_post_draw
		if not check(not actor._conversation_active and actor.sprite.texture == actor._walk_texture and actor.sprite.texture.resource_path == actor.walk_sprite_path and actor.position.y == actor._patrol_origin.y and absf(actor.position.x-actor._patrol_origin.x) <= actor.patrol_distance,"Actual native patrol movement uses own walk, no synthetic translation"): return false
		frames[actor.sprite.frame] = true; last = actor.position
	var adopted: bool = ad_adopted.has(actor.npc_id)
	if not check(first != last and frames.size() >= 4 and actor.sprite.hframes == (4 if adopted else 8),"Natural real four walk frames/displacement, unchanged old animation if carrier edit was deferred",{"frames":frames.keys(),"adopted":adopted}): return false
	records.append({"kind":"AD_NEW_WALK_ACTUAL" if adopted else "OLD_UNCHANGED_WALK_NOT_NEW_ART","id":actor.npc_id,"hframes":actor.sprite.hframes,"natural_frames":frames.keys(),"start":first,"end":last})
	return true

func ad_dialogue() -> bool:
	await driver.completed_actor_stage()
	if not check(not dp.call("is_playing") and _clear((field.get("_player") as Node2D).position),"Normal safe player foot before actual Space"): return false
	ad_seen_text.clear()
	await driver.key(KEY_SPACE)
	await RenderingServer.frame_post_draw
	var active := field.get("_active_dialog_npc") as NPCNode
	var current := dp.get("_current_script") as DialogScript
	var role: Dictionary = ad_adopted[ad_target_id]
	if not check(dp.call("is_playing") and active == ad_target and current != null and current.resource_path == "res://data/dialogs/"+role.ambient_dialog+".tres" and ad_target._conversation_active,"Space actually selected intended original actor and resource, not direct DP.play"): return false
	var expected: Dictionary = ab_binding.dialogues[current.resource_path]
	if not check(String(current.dialog_id) == expected.internal_dialog_id,"Resource location and internal dialog id checked in their distinct domains"): return false
	var portrait := (dp.get("_box") as Node).get("portrait") as TextureRect
	var label := (dp.get("_box") as Node).get("speaker_label") as Label
	var stopped := ad_target.position; var body_id := (ad_target.get("_body_collider") as Node).get_instance_id()
	for i: int in 2:
		await RenderingServer.frame_post_draw
		var node := dp.get("_current_node") as DialogNode
		if not check(node == current.nodes[i] and node.speaker == ad_target.npc_name and not ad_seen_text.is_empty() and ad_seen_text.back().speaker == ad_target.npc_name and ad_seen_text.back().portrait == ad_target.portrait_path and portrait != null and portrait.is_visible_in_tree() and portrait.texture != null and portrait.texture.resource_path == ad_target.portrait_path and label.text == ad_target.npc_name and ad_target.position == stopped and ad_target.sprite.texture.resource_path == ad_target.sprite_path,"Actual stopped same-person NPC, emitted portrait and visible DialogBox texture/speaker exact "+str(i)): return false
		if i == 0 and not await _picture("ad_role_actual_space_same_person_portrait"): return false
		await driver.key(KEY_SPACE)
		await process_frame
	if not check(not dp.call("is_playing"),"Two harmless actual UI Space advances finish without choosing a quest"): return false
	await driver.completed_actor_stage()
	if not check(_person(ad_target_id) == ad_target and (ad_target.get("_body_collider") as Node).get_instance_id() == body_id and not ad_target._conversation_active and (field.get("_player") as Node).get("can_move") == true,"Conversation ends with same NPC/body present, resumes ordinary control"): return false
	records.append({"kind":"AD_ACTUAL_SPACE_SAMEPERSON_VISIBLE_PORTRAIT","id":ad_target_id,"dialog_resource":current.resource_path,"internal_dialog_id":current.dialog_id,"portrait":ad_target.portrait_path,"speaker":ad_target.npc_name,"actual_text_events":ad_seen_text.duplicate(true),"same_actor_retained":true})
	return true

func ad_trip() -> bool:
	var points := PackedVector2Array([Vector2(2140,1840),Vector2(2172,1840),Vector2(1200,1840),Vector2(1200,1600),Vector2(1200,1250)])
	if ad_target_id == "harbour_life_docks_rope_carrier": points.append_array(PackedVector2Array([Vector2(1430,1250),Vector2(1430,1000),Vector2(1400,940)]))
	else: points.append_array(PackedVector2Array([Vector2(1170,1080),Vector2(1110,800),Vector2(1050,1030)]))
	var moved: Dictionary = await driver.follow(field,points,_clear,_segment)
	records.append({"kind":"AD_NORMAL_INPUT_TO_ADOPTED_PERSON","result":moved})
	if not check(moved.get("ok") == true,"True original route/body/NAV INPUT, not injected station",moved): return false
	if not await ad_patrol_observe() or not await _picture("ad_role_cast_before_talk"): return false
	return await ad_dialogue()

func _run() -> void:
	began = Time.get_ticks_msec(); deadline = began+90000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	players_before = saves(); folder = "res://build/luoyang_docks_roles_20261019ad_qa01/field_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool = ab_preflight()
	if complete:
		gs = root.get_node("GameState"); qm = root.get_node("QuestManager"); dp = root.get_node("DialogPlayer")
		original_parts = {"flags":gs.get("flags").duplicate(true),"quests":qm.call("to_dict").duplicate(true)}; original_rewards = _rewards()
		dp.connect("text_displayed",ad_text)
		driver = (load(INPUT_PATH) as Script).new(); driver.configure(self)
		complete = await ab_arrive()
		if complete: complete = ad_actual_rows()
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
	check(pictures.size() <= 2 and Time.get_ticks_msec() < deadline,"Original90s/60s arrival, maximum2 ordinary captures")
	var path := folder.path_join("result.json"); var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"scope":"AD_ONE_ORDINARY_DOCKS_ROLE_SPRITE_PATROL_SPACE_VISIBLE_PORTRAIT","complete":complete and failures == 0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"budget_ms":90000,"arrival_ms":60000,"native_queries":native_queries,"records":records,"pictures":pictures,"source_before":source_before,"source_after":after,"players_before":players_before,"players_after":saved,"task_chain_or_AC_geometry_repeated":false,"full_city_art_credit":false},"\t",true,true)); file.close()
	print(JSON.stringify({"report_path":path,"checks":checks,"failures":failures,"complete":complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)
