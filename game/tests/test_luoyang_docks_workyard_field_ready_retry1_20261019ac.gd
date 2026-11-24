extends "res://tests/test_luoyang_docks08_formal_field_ready_retry1_20261019ab.gd"
## Frozen AC-only ordinary Field. No old city/task/room/geometry suite replay.
const AC_FIELD_READY = true
const AC_BIND = "res://tests/fixtures/luoyang_docks_workyard_field_20261019ac.json"
const AC_BIND_SHA = "ba8c4090bfcd7267553870a8cc3139c13e8468b75d52ab6bc1c0c5b01a9f6a70"
const AC_PACKET = "res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/packet.bin"
const AC_MODULE = "res://scripts/city/luoyang_docks_workyard_20261019ac.gd"
const AC_INDEX = "res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd"
const AC_TARGET = "workyard_ac_north_tally_crate"
var ac_api: Script
var ac_actors_before: Dictionary = {}
var ac_identity: Dictionary = {}

func ab_preflight() -> bool:
	if not check(AC_FIELD_READY and DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0 and OS.get_cmdline_user_args().is_empty(),"Frozen one ordinary AC Docks, no flags or controlled actors"): return false
	if not track(AC_BIND,AC_BIND_SHA): return false
	ab_binding = json(AC_BIND)
	if not check(ab_binding.expected_from_actual_collector == false and ab_binding.phase == "AC_FORMAL_TRUE", "Independent ab1466 plus finite authored AC source delta"): return false
	for path: String in ab_binding.test_dependencies:
		if not track(path,ab_binding.test_dependencies[path]): return false
	for path: String in ab_binding.fixed_current_sources:
		if not track(path,ab_binding.fixed_current_sources[path]): return false
	if not track(ab_binding.expected_map_path,ab_binding.expected_map_sha256): return false
	expected_maps[DOCKS] = json(ab_binding.expected_map_path).source_sha256.duplicate(true)
	if not check(expected_maps[DOCKS].size() == ab_binding.expected_source_count,"Independent complete AC source map count"): return false
	var component: Dictionary = ab_binding.delta_cpu
	if not track(component.path,component.sha256): return false
	var result: Dictionary = json(component.path)
	if not check(result.complete == true and result.failures == 0 and result.scope == "INDEPENDENT_ADD_FOUR_NATIVE_PACKET_LOCAL_RASTER_NOT_FIELD" and result.source_before == result.source_after and result.players_before.size() == 15 and result.players_before == result.players_after and result.state_before == result.state_after,"Actual independent append4/native/raster component, no old Field PASS reuse"): return false
	var admission: Dictionary = ab_binding.source_admission
	if not track(admission.path,admission.sha256): return false
	var admitted: Dictionary = json(admission.path)
	if not check(admitted.complete == true and admitted.failures == 0 and admitted.scope == "ONE_AC_FLAG_FALSE_INDEX_DOCKS_SOURCE_NATIVE_OWNER_ADMISSION_NOT_FIELD" and admitted.source_before == admitted.source_after and admitted.players_before.size() == 15 and admitted.players_before == admitted.players_after and admitted.state_before == admitted.state_after,"Actual candidate whole-source/native admission, not a prior failed attempt"): return false
	if not track(ab_binding.candidate_map_path,ab_binding.candidate_map_sha256): return false
	var candidate_map: Dictionary = json(ab_binding.candidate_map_path).source_sha256.duplicate(true)
	var source_records: Array = []
	for row: Dictionary in admitted.records:
		if row.get("kind") == "ONE_AC_DOCKS_ACTUAL_COMPLETE_SOURCE_COLLECTOR": source_records.append(row)
	if not check(source_records.size() == 1 and source_records[0].count == 1481 and source_records[0].sources == candidate_map,"Exactly one prior actual full collector component equals the independent candidate map"): return false
	if not check(candidate_map.get(AC_INDEX) == "2f8bbb1dcf5c9e8351e9f4688480cec9f7f69a597d6d8567471d14cb0e0194d7" and expected_maps[DOCKS].get(AC_INDEX) == "aae3e942acab88f372ca3dbeaab902fdfabecb4058e3a053ddf12b5fc33a3372","Only explicit index false-to-true successor authorized"): return false
	candidate_map[AC_INDEX] = expected_maps[DOCKS][AC_INDEX]
	if not check(candidate_map == expected_maps[DOCKS],"Whole candidate-source map inherits sole boolean authority change, no rerun full collector before actual Field"): return false
	b = load(B_PATH); c = load(C_PATH); ac_api = load(AC_MODULE)
	var index: Script = load(AC_INDEX)
	if not check(b is GDScript and b.can_instantiate() and c is GDScript and c.can_instantiate() and ac_api is GDScript and ac_api.can_instantiate() and index is GDScript and index.can_instantiate(),"Actual APIs compile before access"): return false
	if not check(index.FORMAL_ENABLED == true and b.requested(StringName(DOCKS)),"Sole AC formal default index, no test flag"): return false
	ab_packet = bytes_to_var(FileAccess.get_file_as_bytes(AC_PACKET))
	if not check(b.ac_packet_valid(ab_packet) and ab_packet.record.objects.size() == 29 and _v(ab_packet.record.entry_foot_px) == Vector2(2140,1840),"Frozen29 packet retains independently published default21401840"): return false
	var self_path: String = get_script().resource_path
	return track(self_path,FileAccess.get_sha256(self_path))

func _geometry(id: String) -> bool:
	ab_record = c._records.get(id,{}).duplicate(true)
	if not check(id == DOCKS and b.whole_bound(scene) and b.equal(ab_record,ab_packet.record) and ab_record.objects.size() == 29 and scene.get_meta(ac_api.META,"") == ac_api.AUTHOR_SHA,"Actual complete29 record/Scene AC and inherited AA session, no fake projection"): return false
	mask = Image.load_from_file(String(ab_record.walk_path))
	var current_mask: Image = c._masks.get(DOCKS)
	if not check(mask != null and current_mask != null and mask.get_data() == ab_packet.walk_bytes and current_mask.get_data() == ab_packet.walk_bytes and c._equal_value(c._solids.get(DOCKS),c.object_solids(ab_record.objects)),"Actual committed mask/native solids exactly packet29"): return false
	var solids: Array = []
	for object: Dictionary in ab_packet.record.objects:
		var poly_index := 0
		for poly: Array in object.get("solid_polygons_px",[]):
			solids.append({"id":String(object.id)+"_poly_"+str(poly_index),"points_px":poly}); poly_index += 1
		var extent := _v(object.collision_size_px)
		if extent.x > 0 and extent.y > 0:
			var low := _v(object.physical_center_px)-extent*.5; var high := low+extent
			solids.append({"id":String(object.id)+"_box","points_px":[low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)]})
	var author: Dictionary = json(AB_DISTRICT_AUTHOR)
	for placement: Dictionary in author.districts[DOCKS].placements:
		var asset: Dictionary = author.assets[placement.asset_id]
		var poly_index := 0
		for poly: Array in asset.ground_solid_polygons_px:
			var points: Array = []
			for point: Array in poly: points.append(_v(placement.foot_px)+(_v(point)-_v(asset.source_ground_anchor_px))*float(placement.scale))
			solids.append({"id":String(placement.id)+"_delta_"+str(poly_index),"points_px":points}); poly_index += 1
	oracle = (load(RAW_PATH) as Script).new()
	return check(oracle.configure([[[0,0],[3072,0],[3072,2048],[0,2048]]],solids,WORLD,WORLD) and _clear(field.get("_player").position),"Independent29 plus unchanged District continuous34x24/87517/native at actual birth; water governed separately by exact dry mask")

func ab_arrive() -> bool:
	var start := Time.get_ticks_usec()
	if not check(root.get_node("SceneRouter").call("go_field_smart", StringName(DOCKS), null, "", -1, -1), "Exactly one ordinary public default-null Docks request, no special spawn or candidate flag"): return false
	var until := mini(deadline, Time.get_ticks_msec() + AB_FIELD_ARRIVAL_MS)
	while Time.get_ticks_msec() < until:
		await process_frame
		var request: Dictionary = root.get_node("SceneRouter").call("get_public_city_preparation_state")
		if request.get("scene_id") == DOCKS and request.get("phase") == "FAILED": return check(false, "Actual request failed rather than loading back to world", request)
		if not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): continue
		var state: Dictionary = current_scene.call("get_field_loading_state")
		if state.get("failed", false): return check(false, "Actual Field preparation failed", state)
		var candidate := current_scene.get("_current_scene") as SceneScript
		var player := current_scene.get("_player") as CharacterBody2D
		if candidate == null or String(candidate.scene_id) != DOCKS or player == null or not bool(player.get("can_move")) or state.get("complete") != true: continue
		var screen: Node = root.get_node("LoadingManager").get("_screen")
		var panel := screen.get("root") as Control if is_instance_valid(screen) else null
		if panel != null and panel.is_visible_in_tree(): continue
		await RenderingServer.frame_post_draw
		field = current_scene; scene = candidate
		var first_draw_operable_usec: int = Time.get_ticks_usec() - start
		var source_check_start_usec: int = Time.get_ticks_usec()
		var proof: Dictionary = c.resident_receipt(scene)
		if not check(proof.get("sources_finalized") == true and proof.get("sources", {}) == expected_maps[DOCKS], "Actual same-owner finalized complete AC sources exactly equal independent formaltrue map", {"actual_count": proof.get("sources", {}).size()}): return false
		for path: String in expected_maps[DOCKS]:
			if not track(path, expected_maps[DOCKS][path]): return false
		records.append({"kind": "ORDINARY_NULL_SPAWN_FIRSTDRAW_OPERABLE", "elapsed_usec": first_draw_operable_usec, "source_check_elapsed_usec": Time.get_ticks_usec() - source_check_start_usec, "travel_credit": false, "performance_promise": false, "actual_foot": player.position, "source_proof": proof.duplicate(true)})
		if not check(field.get_script().resource_path == FIELD and scene.actor_positions_are_feet and field.get("_world_size") == WORLD and player.position.distance_to(AB_DEFAULT_FOOT) < .03, "Unmodified actual Field/native feet and published default21401840 birth, not injected test foot"): return false
		return _geometry(DOCKS)
	return check(false, "Hidden Loading/first draw/operable within original fixed60s arrival")


func ac_node_identity() -> Dictionary:
	var player := field.get("_player") as CharacterBody2D
	var shape := player.get_node("CollisionShape2D") as CollisionShape2D
	return {"field":field.get_instance_id(),"scene":scene.get_instance_id(),"player":player.get_instance_id(),"rid":str(player.get_rid()),"body":shape.get_instance_id(),"offset":shape.position,"size":(shape.shape as RectangleShape2D).size,"groups":player.get_groups()}

func ac_new_objects() -> bool:
	var solid_feet := [Vector2(760,950),Vector2(1005,1148),Vector2(760,1545),Vector2(1035,1518)]
	var safe_feet := [Vector2(650,910),Vector2(935,1100),Vector2(620,1450),Vector2(1105,1560)]
	var index := 0
	for object: Dictionary in ab_packet.record.objects.slice(25):
		var id: String = object.id
		var sprite := ab_sprite(id)
		var body := field.find_child("CityV3Physical_"+id,true,false) as StaticBody2D
		if not check(sprite != null and sprite.texture != null and sprite.texture.resource_path == object.texture and sprite.is_visible_in_tree() and sprite.modulate.a == 1.0 and sprite.self_modulate.a == 1.0 and body != null and body.is_inside_tree() and body.collision_layer == 1,"Each NEW static low prop opaque/source-exact with actual native body "+id): return false
		var normalized: Vector2 = (_v(object.world_foot_px)+(Vector2(.5,.5)-_v(object.foot_uv))*_v(object.render_size_px))/WORLD
		var expected_position := Vector2(normalized.x*WORLD.x,normalized.y*WORLD.y)
		var expected_scale := _v(object.render_size_px)/Vector2(sprite.texture.get_size())
		if not check(sprite.get_parent() == field.get("_actor_layer") and sprite.centered and sprite.position == expected_position and sprite.scale == expected_scale and sprite.rotation == 0.0 and not sprite.flip_h and not sprite.flip_v and not sprite.region_enabled and sprite.hframes == 1 and sprite.vframes == 1 and body.position == Vector2.ZERO and body.rotation == 0.0 and body.scale == Vector2.ONE and body.collision_mask == 0,"NEW original source scale/anchor/orientation and world native transform exact "+id): return false
		var polygons: Array[PackedVector2Array] = []
		for child: Node in body.get_children():
			if child is CollisionPolygon2D: polygons.append(child.polygon)
		if not check(polygons.size() == 1 and polygons[0] == c._polygon(object.solid_polygons_px[0]),"NEW ground polygon exactly source, not visual box "+id): return false
		var query := PhysicsPointQueryParameters2D.new()
		query.position = (field.get("world_container") as Node2D).to_global(solid_feet[index]); query.collision_mask = 1; query.collide_with_areas = false
		var hits: Array[Dictionary] = (field.get("_player") as CharacterBody2D).get_world_2d().direct_space_state.intersect_point(query,16)
		native_queries += 1
		var owns_hit := false
		for hit: Dictionary in hits:
			if hit.collider == body and hit.rid == body.get_rid(): owns_hit = true
		if not check(owns_hit and not oracle.clear(solid_feet[index]) and not _mask_clear(solid_feet[index]) and not _native(solid_feet[index]) and _clear(safe_feet[index]),"NEW inside exact native RID blocked and authored perimeter full87517 clear "+id): return false
		index += 1
	ac_identity = ac_node_identity()
	for npc: Node in field.get("_npc_nodes"):
		var sprite: Sprite2D = npc.get("sprite")
		if sprite != null: ac_actors_before[npc.get_instance_id()] = [sprite.modulate,sprite.self_modulate]
	records.append({"kind":"FOUR_NEW_OPAQUE_PROPS_EXACT_NATIVE_RID_MASK_POLYGONS","new_count":4,"old25_unchanged_credit":"independent CPU full inverse, not replayed","old_NPC_portal_suite_replayed":false})
	return true

func ac_ghost_frame(label: String,behind: bool) -> bool:
	var player := field.get("_player") as CharacterBody2D
	var actor: Sprite2D = player.get("sprite")
	var ghost := player.get("_overlap_ghost") as Sprite2D
	var prop := ab_sprite(AC_TARGET)
	var debug: Dictionary = field.call("get_v14_modular_overlap_debug")
	var fade: Dictionary = field.call("get_city_building_fade_debug")
	if not check(prop != null and ghost != null and ac_identity == ac_node_identity() and _clear(player.position),"Same actual34x24/RID identity/current full87517 "+label): return false
	var prop_first: bool = prop.z_index < player.z_index or (prop.z_index == player.z_index and prop.get_index() < player.get_index())
	var valid: bool = prop_first == not behind and prop.modulate.a == 1.0 and prop.self_modulate.a == 1.0 and actor.modulate.a == 1.0 and actor.self_modulate.a == 1.0
	for building: Dictionary in fade.get("buildings",[]):
		if String(building.id).begins_with("workyard_ac_"): valid = false
	var rgba_equal: bool = not behind
	var mask_pixels := 0
	if behind:
		var texture := debug.get("mask_texture") as Texture2D
		var material := ghost.material as ShaderMaterial
		if texture == null or material == null: return check(false,"Actual same-frame ghost texture/material "+label)
		var image := texture.get_image()
		if image.is_compressed(): image.decompress()
		var cpu_mask := debug.get("mask_image") as Image
		rgba_equal = cpu_mask != null and cpu_mask.get_size() == image.get_size() and cpu_mask.get_format() == image.get_format() and cpu_mask.get_data() == image.get_data()
		for y: int in image.get_height():
			for x: int in image.get_width():
				if image.get_pixel(x,y).a > 0: mask_pixels += 1
		valid = valid and rgba_equal and ghost.is_visible_in_tree() and debug.get("active") == true and int(debug.get("pixels",0)) > 0 and mask_pixels > 0 and int(debug.get("prop_hits",{}).get(AC_TARGET,0)) > 0
		valid = valid and absf(ghost.modulate.a-.46) < .000001 and absf(float(material.get_shader_parameter("ghost_alpha"))-.46) < .000001 and material.get_shader_parameter("frame_mask") == texture
		valid = valid and ghost.texture == actor.texture and ghost.frame == actor.frame and ghost.hframes == actor.hframes and ghost.vframes == actor.vframes and ghost.position == actor.position and ghost.scale == actor.scale and ghost.flip_h == actor.flip_h and ghost.flip_v == actor.flip_v and ghost.region_rect == actor.region_rect and ghost.region_enabled == actor.region_enabled and ghost.get_parent() == player and ghost.get_class() == "Sprite2D" and ghost.get_groups().is_empty()
	else: valid = valid and not ghost.visible and debug.get("active") == false and int(debug.get("pixels",0)) == 0
	for npc: Node in field.get("_npc_nodes"):
		var sprite: Sprite2D = npc.get("sprite")
		if sprite != null and ac_actors_before.has(npc.get_instance_id()): valid = valid and [sprite.modulate,sprite.self_modulate] == ac_actors_before[npc.get_instance_id()]
	records.append({"kind":"ACTUAL_LOW_PROP_CURRENT_FRAME_GHOST","label":label,"foot":player.position,"engine_frame":Engine.get_process_frames(),"actor_frame":actor.frame,"prop_hits":debug.get("prop_hits",{}),"prop_first":prop_first,"prop_alpha":prop.self_modulate.a,"main_alpha":actor.modulate.a,"ghost_visible":ghost.visible,"mask_pixels":mask_pixels,"cpu_gpu_RGBA_exact":rgba_equal,"identity":ac_identity})
	return check(valid,"Opaque crate and exact source-alpha masked actor only, same frame, unchanged NPC alpha "+label)

func ac_station(label: String,behind: bool,capture: bool) -> bool:
	var until := mini(deadline,Time.get_ticks_msec()+3500)
	var seen: Dictionary = {}
	while Time.get_ticks_msec() < until and seen.size() < 4:
		await RenderingServer.frame_post_draw
		var sprite: Sprite2D = (field.get("_player") as Node).get("sprite")
		var key := str(sprite.texture.get_instance_id())+":"+str(sprite.frame)
		if seen.has(key): continue
		seen[key] = true
		if not ac_ghost_frame(label+"_natural"+str(seen.size()),behind): return false
	if not check(seen.size() == 4,"Four naturally displayed actor frames "+label): return false
	return await _picture(label) if capture else true

func ac_trip() -> bool:
	var points := PackedVector2Array([Vector2(2140,1840),Vector2(2172,1840),Vector2(1200,1840),Vector2(1200,1600),Vector2(1200,1250),Vector2(1000,1190)])
	var movement: Dictionary = await driver.follow(field,points,_clear,_segment)
	records.append({"kind":"NORMAL_INPUT_ORIGINAL_FREIGHT_SPINE_TO_NEW_PROP","result":movement})
	if not check(movement.get("ok") == true,"Normal INPUT default32px then authored freight route, never teleport",movement): return false
	if not await ac_station("workyard_crate_front",false,true): return false
	var bypass: Dictionary = await driver.follow(field,PackedVector2Array([Vector2(1000,1190),Vector2(935,1190),Vector2(935,1100),Vector2(1000,1110)]),_clear,_segment)
	records.append({"kind":"NORMAL_INPUT_NEW_CRATE_NATIVE_BYPASS","result":bypass})
	if not check(bypass.get("ok") == true,"Actual left bypass to behind low crate",bypass) or not await ac_station("workyard_crate_behind",true,true): return false
	var back: Dictionary = await driver.follow(field,PackedVector2Array([Vector2(1000,1110),Vector2(935,1100),Vector2(935,1190),Vector2(1000,1190)]),_clear,_segment)
	if not check(back.get("ok") == true,"Real reverse bypass restores player in front",back): return false
	return await ac_station("front_restored_no_extra_capture",false,false)

func _run() -> void:
	began = Time.get_ticks_msec(); deadline = began+90000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	players_before = saves(); folder = "res://build/luoyang_docks_workyard_20261019ac_qa01/field_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var complete := ab_preflight()
	if complete:
		gs = root.get_node("GameState"); qm = root.get_node("QuestManager"); dp = root.get_node("DialogPlayer")
		original_parts = {"flags":gs.get("flags").duplicate(true),"quests":qm.call("to_dict").duplicate(true)}; original_rewards = _rewards()
		driver = (load(INPUT_PATH) as Script).new(); driver.configure(self)
		complete = await ab_arrive()
		if complete: complete = ac_new_objects()
		if complete: complete = await ac_trip()
	if driver != null: driver.release(); driver = null
	if is_instance_valid(current_scene):
		var own: Node = current_scene; var weak: WeakRef = weakref(own)
		current_scene = null; own.queue_free(); field = null; scene = null; own = null
		await process_frame; await process_frame
		check(weak.get_ref() == null,"Own only Docks naturally released, no retained ghost")
	if not original_parts.is_empty():
		check(qm.call("to_dict") == original_parts.quests and _rewards() == original_rewards,"No task/reward/inventory mutation during low-prop check")
		gs.set("flags",original_parts.flags.duplicate(true)); qm.call("from_dict",original_parts.quests.duplicate(true))
		check(gs.get("flags") == original_parts.flags and qm.call("to_dict") == original_parts.quests,"Only visit flags restored in memory, never writes saves")
	oracle = null; mask = null; ab_packet.clear(); ab_record.clear()
	var source_after: Dictionary = {}
	for path: String in source_before: source_after[path] = fact(path)
	var players_after: Dictionary = saves()
	check(source_before == source_after and players_before == players_after and players_before.size() == 15,"Complete current sources and15save facts unchanged")
	check(pictures.size() <= 2 and Time.get_ticks_msec() < deadline,"Original90s whole/60s arrival, maximum2 ordinary captures")
	var path := folder.path_join("result.json"); var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"scope":"ONE_ORDINARY_DOCKS_NEW_FOUR_LOW_PROPS_NATIVE_PHYSICS_CURRENT_FRAME_GHOST","complete":complete and failures == 0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"budget_ms":90000,"arrival_ms":60000,"native_queries":native_queries,"records":records,"pictures":pictures,"source_before":source_before,"source_after":source_after,"players_before":players_before,"players_after":players_after,"old_geometry_or_city_or_task_suite_repeated":false,"room_trip":false,"full_district08_art_credit":false},"\t",true,true)); file.close()
	print(JSON.stringify({"report_path":path,"checks":checks,"failures":failures,"complete":complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)




