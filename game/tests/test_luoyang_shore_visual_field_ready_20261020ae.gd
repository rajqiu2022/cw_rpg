extends "res://tests/test_luoyang_docks_workyard_field_ready_retry1_20261019ac.gd"
## AE visual-only remaining layer. Does not call AC trip, AD patrol/Space or tasks.
const AE_FIELD_READY = true
const AE_BIND = "res://tests/fixtures/luoyang_shore_visual_field_ready_20261020ae.json"
const AE_BIND_SHA = "3d9f0554a4f409857111ef4ba10a14951df73b3ca96a9e71c20c880bad684e98"
const AE_API = "res://scripts/city/luoyang_docks_shore_20261020ae.gd"
const AE_WATER_API = "res://scripts/city/luoyang_harbour_water_patch_20261016.gd"
var ae_api: Script
var ae_water_api: Script
var ae_fixture: Dictionary = {}
var ae_water: Sprite2D
var ae_root: Node2D
var ae_actor_colors: Array = []

func ab_preflight() -> bool:
	if not check(AE_FIELD_READY and DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0 and OS.get_cmdline_user_args().is_empty(),"AE NOTREADY until ART/source/import freeze; one ordinary noargs Docks only"): return false
	if not track(AE_BIND,AE_BIND_SHA): return false
	ae_fixture = json(AE_BIND)
	for path: String in ae_fixture.test_dependencies:
		if not track(path,ae_fixture.test_dependencies[path]): return false
	if not track(ae_fixture.formal_map.path,ae_fixture.formal_map.sha256): return false
	expected_maps[DOCKS] = json(ae_fixture.formal_map.path).source_sha256.duplicate(true)
	if not check(expected_maps[DOCKS].size() == ae_fixture.formal_map.count,"Independent AD1499 plus authored AE source successor, never actual backfill"): return false
	var cpu_row: Dictionary = ae_fixture.cpu_report
	if not track(cpu_row.path,cpu_row.sha256): return false
	var cpu: Dictionary = json(cpu_row.path)
	if not check(cpu.scope == "AE_RESIDUAL_TWO_DOMAIN_SOURCE_NATIVE_MARKET36_PRIOR_IMPORT_COMPONENT_ONLY_NOT_FIELD" and cpu.complete == true and cpu.failures == 0 and cpu.original118004_whole_FAIL_preserved == true and cpu.import_texture_raster_Field_replayed == false and cpu.source_before == cpu.source_after and cpu.players_before.size() == 15 and cpu.players_before == cpu.players_after and cpu.state_before == cpu.state_after,"Actual remaining dual source/native component with prior import-only credit; original118004 wholeFAIL remains"): return false
	if not ae_cpu_source_successor(cpu): return false
	b = load(B_PATH); c = load(C_PATH); ac_api = load(AC_MODULE)
	ae_api = load(AE_API); ae_water_api = load(AE_WATER_API)
	if not check(b != null and b.can_instantiate() and c != null and c.can_instantiate() and ac_api != null and ac_api.can_instantiate() and ae_api != null and ae_api.can_instantiate() and ae_water_api != null and ae_water_api.can_instantiate(),"Actual canonical APIs compile before access"): return false
	var ready: Dictionary = ae_api.readiness()
	if not check(ready.get("ok") == true and b.equal(ready.spec.overlays,ae_fixture.authored_overlays),"Independent exact ART overlay values before actual Field"): return false
	ab_packet = bytes_to_var(FileAccess.get_file_as_bytes(AC_PACKET))
	if not check(b.ac_packet_valid(ab_packet) and ab_packet.record.objects.size() == 29 and _v(ab_packet.record.entry_foot_px) == AB_DEFAULT_FOOT,"Original exact29 packet/native/21401840 preserved"): return false
	var self_path: String = get_script().resource_path
	return track(self_path,FileAccess.get_sha256(self_path))

func ae_cpu_source_successor(cpu: Dictionary) -> bool:
	if not track(ae_fixture.cpu_false_map.path,ae_fixture.cpu_false_map.sha256): return false
	var prior: Dictionary = json(ae_fixture.cpu_false_map.path).source_sha256.duplicate(true)
	var matched: Array = []
	for row: Dictionary in cpu.records:
		if row.get("kind") == "AE_EXACT_SOURCE_IMMUTABLE_NATIVE_COMPONENT" and row.get("scene_id") == DOCKS: matched.append(row)
	if not check(matched.size() == 1 and matched[0].source_count == prior.size() and matched[0].sources == prior,"Actual unique CPU Docks source component equals frozen false map, not merely report complete"): return false
	var index: Dictionary = ae_fixture.formal_index
	if not check(prior.get(index.path) == index.false_sha256 and expected_maps[DOCKS].get(index.path) == index.true_sha256,"Explicit sole Docks bool source successor"): return false
	prior[index.path] = index.true_sha256
	return check(prior == expected_maps[DOCKS],"Every non-index source identical from actual CPU component to formal Docks map")

func ab_arrive() -> bool:
	var start: int = Time.get_ticks_usec()
	if not check(root.get_node("SceneRouter").call("go_field_smart",StringName(DOCKS),null,"",-1,-1),"One ordinary default-null public Docks; not near-spawn or candidate flag"): return false
	var until: int = mini(deadline,Time.get_ticks_msec()+60000)
	while Time.get_ticks_msec() < until:
		await process_frame
		var request: Dictionary = root.get_node("SceneRouter").call("get_public_city_preparation_state")
		if request.get("scene_id") == DOCKS and request.get("phase") == "FAILED": return check(false,"AE request failed rather than returning world",request)
		if not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): continue
		var state: Dictionary = current_scene.call("get_field_loading_state")
		if state.get("failed",false): return check(false,"Actual AE Field failed",state)
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
		if not check(proof.get("sources_finalized") == true and proof.get("sources",{}) == expected_maps[DOCKS],"Actual same-owner complete finalized sources equal independent AE formal map"): return false
		for path: String in expected_maps[DOCKS]:
			if not track(path,expected_maps[DOCKS][path]): return false
		records.append({"kind":"AE_ORDINARY_DEFAULT_FIRSTDRAW_SOURCE_COMPONENT","firstdraw_operable_usec":firstdraw,"source_check_usec":Time.get_ticks_usec()-hash_start,"source_count":proof.sources.size(),"actual_foot":player.position,"performance_promise":false})
		if not check(field.get_script().resource_path == FIELD and scene.actor_positions_are_feet and field.get("_world_size") == WORLD and player.position.distance_to(AB_DEFAULT_FOOT) < .03,"Actual ordinary21401840, no injected foot or old340 expectation"): return false
		return _geometry(DOCKS)
	return check(false,"Original fixed60s hidden/operable arrival")

func ae_tree() -> bool:
	var visual: Node2D = field.get("_visual_layer") as Node2D
	ae_water = visual.get_node_or_null("HarbourSameCaptureWaterPatch") as Sprite2D
	if not check(ae_water != null and ae_water.get_parent() == visual and ae_water.position == Vector2(2500,1292) and ae_water.scale == Vector2.ONE and not ae_water.centered and ae_water.z_index == -999 and ae_water.texture is ImageTexture,"Original WATER Sprite2D parent CORE/scale/z/texture domain intact"): return false
	var packet: Variant = scene.get_meta(ae_water_api.META,null)
	if not check(ae_water_api.packet_valid(packet),"Original DC4B source-bound water packet unchanged"): return false
	var image: Image = ae_water.texture.get_image()
	if not check(image != null and image.get_size() == Vector2i(200,280),"Actual original water ImageTexture size"): return false
	for p: Vector2i in [Vector2i(0,0),Vector2i(199,0),Vector2i(100,140),Vector2i(0,279),Vector2i(199,279)]:
		var i: int = (p.y*200+p.x)*4
		var expected: Color = Color8(packet.bytes[i],packet.bytes[i+1],packet.bytes[i+2],packet.bytes[i+3])
		if not check(image.get_pixelv(p) == expected,"One-time original water fixed RGBA sample "+str(p)): return false
	ae_root = ae_water.get_node_or_null("DocksShoreVisualOnlyAE") as Node2D
	if not check(ae_root != null and ae_root.get_parent() == ae_water and ae_root.position == -ae_water.position and ae_root.z_index == 1 and ae_root.z_as_relative and ae_root.get_script() == null and ae_root.get_meta("ae_visual_only",false) == true and ae_root.get_child_count() == ae_fixture.authored_overlays.size(),"Actual single pure visual child root, effectivez-998 and original world coordinates"): return false
	var expected_ids: Dictionary = {}
	for row: Dictionary in ae_fixture.authored_overlays:
		expected_ids[row.id] = true
		var sprite: Sprite2D = ae_root.get_node_or_null(NodePath(row.id)) as Sprite2D
		var expected_color: Color = Color(.38,.48,.52,float(row.opacity)) if String(row.id).begins_with("shore_ae_wet_") else Color(1,1,1,float(row.opacity))
		if not check(sprite != null and sprite.get_child_count() == 0 and sprite.get_script() == null and sprite.get_parent() == ae_root and sprite.texture.resource_path == row.texture and sprite.region_enabled and sprite.region_rect == Rect2(_v(row.region_origin_px),_v(row.region_size_px)) and sprite.position == _v(row.center_px) and sprite.scale == _v(row.render_size_px)/_v(row.region_size_px) and sprite.self_modulate == expected_color and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR,"Independent actual atlas/transform/opacity and fixed wet-only RGB class; leaf Sprite2D only "+row.id): return false
		var mooring: bool = String(row.id).begins_with("shore_ae_mooring_")
		var local_z: int = 997 if mooring else 0
		if not check(sprite.z_as_relative and sprite.z_index == local_z,"Fixed source class depth, never arbitrary manifest z: mooring effective-1 above wharf-2; ground effective-998 "+row.id): return false
	for child: Node in ae_root.get_children():
		if not check(child is Sprite2D and expected_ids.has(String(child.name)) and child.get_child_count() == 0,"No Area/Body/Collision/unknown descendant or interaction support"): return false
	var overlap: RefCounted = field.get("_v14_modular_overlap")
	if not check(overlap != null,"Actual original modular overlap exists"): return false
	for prop: Dictionary in overlap.get("_props"):
		if is_instance_valid(prop.sprite) and not check(not ae_root.is_ancestor_of(prop.sprite),"No new ground overlay registered as ghost occluder"): return false
	for entry: Dictionary in overlap.get("_depth_entries"):
		if is_instance_valid(entry.node) and not check(entry.node != ae_root and not ae_root.is_ancestor_of(entry.node),"No new ground overlay registered on actor depth ladder"): return false
	var player_sprite: Sprite2D = (field.get("_player") as Node).get("sprite") as Sprite2D
	ae_actor_colors = [player_sprite.modulate,player_sprite.self_modulate]
	records.append({"kind":"AE_ACTUAL_PURE_VISUAL_SUBTREE_NOT_NEW_NATIVE_GEOMETRY","overlay_count":expected_ids.size(),"effective_z_index":-998,"mooring_effective_z_index":-1,"physics_or_area_added":0,"ghost_or_actor_depth_registered":false,"original_water_fixed_samples":5,"old29_record_mask_solids_exact":true})
	return true

func ae_trip() -> bool:
	var player: CharacterBody2D = field.get("_player") as CharacterBody2D
	var camera: Camera2D = field.get("_world_camera") as Camera2D
	if not check(camera != null and camera.get_parent() == player and camera.position == Vector2.ZERO and camera.is_current(),"Original player-child ordinary camera retained for default rope/ship capture"): return false
	if not await _picture("ae_mooring_ship_ordinary_default_before_input"): return false
	var route := PackedVector2Array()
	for p: Array in ae_fixture.short_route_px: route.append(_v(p))
	if not check(route.size() == 2 and route[0] == AB_DEFAULT_FOOT and route[1] == AB_DEFAULT_FOOT+Vector2(32,0),"Only original32px birth INPUT; no implied route or player travel to cart"): return false
	var moved: Dictionary = await driver.follow(field,route,_clear,_segment)
	records.append({"kind":"AE_SHORT_NORMAL_INPUT_NATIVE87517","result":moved})
	if not check(moved.get("ok") == true,"Only short real INPUT over unchanged mask/native34x24",moved): return false
	for p: Array in ae_fixture.clear_shore_probes_px:
		if not check(_clear(_v(p)),"Representative shore original87517/continuous34x24/native clear "+str(p)): return false
	var player_sprite: Sprite2D = (field.get("_player") as Node).get("sprite") as Sprite2D
	if not check(ae_actor_colors == [player_sprite.modulate,player_sprite.self_modulate],"New ground never tints player main sprite"): return false
	return await ae_inspection_picture()

func ae_inspection_picture() -> bool:
	# The second capture inspects the new ruts/cart delta only. No player teleport,
	# new-route proof, or claim that the ordinary birth camera can show the cart.
	var player: CharacterBody2D = field.get("_player") as CharacterBody2D
	var camera: Camera2D = field.get("_world_camera") as Camera2D
	var center: Vector2 = _v(ae_fixture.inspection_camera_center_px)
	if not check(center == Vector2(900,1620) and camera != null and camera.get_parent() == player and camera.is_current(),"Root-authorized inspection-camera center only, not an actor destination"): return false
	var old_position: Vector2 = camera.position
	var old_zoom: Vector2 = camera.zoom
	var old_limits: Array = [camera.limit_left,camera.limit_top,camera.limit_right,camera.limit_bottom]
	var old_foot: Vector2 = player.position
	camera.position = center-player.position
	camera.reset_smoothing(); camera.force_update_scroll()
	await process_frame
	await RenderingServer.frame_post_draw
	var viewport_rect: Rect2 = root.get_visible_rect()
	var world: Node2D = player.get_parent() as Node2D
	var visible_points: Array = []
	var framed: bool = true
	for p: Vector2 in [Vector2(620,1501),Vector2(1120,1608),Vector2(820,1590),Vector2(1030,1530)]:
		var screen_point: Vector2 = world.get_global_transform_with_canvas()*p
		visible_points.append({"world":p,"screen":screen_point})
		framed = framed and viewport_rect.has_point(screen_point)
	var path: String = folder.path_join("ae_ruts_cart_inspection_camera_not_player_travel.png")
	var image: Image = root.get_texture().get_image()
	var saved: bool = image != null and image.save_png(path) == OK
	if saved:
		pictures.append({"path":path,"sha256":FileAccess.get_sha256(path),"qa_camera_modified":true,"inspection_only":true,"requested_center_px":center,"actual_screen_center_px":camera.get_screen_center_position(),"player_foot_before":old_foot,"player_foot_during":player.position,"INPUT_to_cart_credit":false,"screen_points":visible_points})
	camera.position = old_position
	camera.reset_smoothing(); camera.force_update_scroll()
	await process_frame
	if not check(saved and framed,"Second actual inspection capture contains authored ruts bounds and original cart/crate anchor; not travel credit",{"saved":saved,"framed":framed,"points":visible_points}): return false
	if not check(player.position == old_foot and camera.position == old_position and camera.zoom == old_zoom and [camera.limit_left,camera.limit_top,camera.limit_right,camera.limit_bottom] == old_limits and camera.is_current(),"Inspection never moves player or changes zoom/limits/current identity; original camera offset restored"): return false
	records.append({"kind":"AE_INSPECTION_CAMERA_ONLY_RUTS_CART","player_foot":old_foot,"requested_center_px":center,"INPUT_to_cart_credit":false,"restored":true})
	return true

func _run() -> void:
	began = Time.get_ticks_msec(); deadline = began+90000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	players_before = saves(); folder = "res://build/luoyang_shore_market_20261020ae_qa01/field_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool = ab_preflight()
	if complete:
		gs = root.get_node("GameState"); qm = root.get_node("QuestManager")
		original_parts = {"flags":gs.get("flags").duplicate(true),"quests":qm.call("to_dict").duplicate(true)}; original_rewards = _rewards()
		driver = (load(INPUT_PATH) as Script).new(); driver.configure(self)
		complete = await ab_arrive()
		if complete: complete = ae_tree()
		if complete: complete = await ae_trip()
	if driver != null: driver.release(); driver = null
	var root_weak: WeakRef = weakref(ae_root) if is_instance_valid(ae_root) else null
	var water_weak: WeakRef = weakref(ae_water) if is_instance_valid(ae_water) else null
	if is_instance_valid(current_scene):
		var own: Node = current_scene; var own_weak: WeakRef = weakref(own)
		current_scene = null; own.queue_free(); field = null; scene = null; own = null; ae_root = null; ae_water = null
		await process_frame; await process_frame
		check(own_weak.get_ref() == null and (root_weak == null or root_weak.get_ref() == null) and (water_weak == null or water_weak.get_ref() == null),"Own Field/oldwater/newvisual child all released; no AE global lifetime")
	if not original_parts.is_empty():
		check(qm.call("to_dict") == original_parts.quests and _rewards() == original_rewards,"Visual-only shore cannot affect quest/reward/inventory")
		gs.set("flags",original_parts.flags.duplicate(true)); qm.call("from_dict",original_parts.quests.duplicate(true))
		check(gs.get("flags") == original_parts.flags and qm.call("to_dict") == original_parts.quests,"Only normal visit flags restored in memory; no slots written")
	oracle = null; mask = null; ab_packet.clear(); ab_record.clear()
	var after: Dictionary = {}
	for path: String in source_before: after[path] = fact(path)
	var saved: Dictionary = saves()
	check(source_before == after and players_before == saved and saved.size() == 15,"Every complete source and15save first-final unchanged")
	check(pictures.size() <= 2 and (not complete or pictures.size() == 2) and Time.get_ticks_msec() < deadline,"Fixed90s/60s: default ordinary rope/ship plus explicit camera-only ruts/cart capture; no AD or market replay")
	var path: String = folder.path_join("result.json"); var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"scope":"AE_ONE_ORDINARY_DOCKS_VISUAL_LAYER_SHORT_INPUT_NOT_NPC_OR_NEW_GEOMETRY","complete":complete and failures == 0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"budget_ms":90000,"arrival_ms":60000,"native_queries":native_queries,"records":records,"pictures":pictures,"source_before":source_before,"source_after":after,"players_before":players_before,"players_after":saved,"AD_or_task_or_market_replayed":false,"whole_city_art_or_loading_promise":false},"\t",true,true)); file.close()
	print(JSON.stringify({"report_path":path,"checks":checks,"failures":failures,"complete":complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)


