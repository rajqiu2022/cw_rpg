extends "res://tests/test_luoyang_docks_workyard_field_ready_retry1_20261019ac.gd"
## AE Market first ground cluster only. No doorway travel, NPC/dialogue or geometry suite.
const MARKET_AE_READY = true
const MARKET_AE_BIND = "res://tests/fixtures/luoyang_market_ground_field_ready_20261020ae.json"
const MARKET_AE_BIND_SHA = "52d5d3420ec73d674fb0b10a5238946603b28d55d8dba04d537769c3f129552a"
const MARKET_AE_API = "res://scripts/city/luoyang_market_ground_20261020ae.gd"
const MARKET_AE_PACKET = "res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s3_luoyang_market/packet.bin"
const MARKET_AE_PACKET_SHA = "5463a36c5130ebee9c9a75a53ca23e35dbf7e3dcf697859c51f29b2d890bf826"
var market_fixture: Dictionary = {}
var market_api: Script
var market_expected36: Array = []
var market_projection: Dictionary = {}
var market_ground_nodes: Array[Sprite2D] = []
var market_player_colors: Array = []

func ab_preflight() -> bool:
	if not check(MARKET_AE_READY and DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0 and OS.get_cmdline_user_args().is_empty(),"Market AE NOTREADY until exact ART/import/source freeze; one ordinary noargs Field"): return false
	if not track(MARKET_AE_BIND,MARKET_AE_BIND_SHA): return false
	market_fixture = json(MARKET_AE_BIND)
	for path: String in market_fixture.test_dependencies:
		if not track(path,market_fixture.test_dependencies[path]): return false
	if not track(market_fixture.formal_map.path,market_fixture.formal_map.sha256): return false
	expected_maps[MARKET] = json(market_fixture.formal_map.path).source_sha256.duplicate(true)
	if not check(expected_maps[MARKET].size() == market_fixture.formal_map.count,"Independent original Market1242 plus explicit AE source successor"): return false
	var cpu_row: Dictionary = market_fixture.cpu_report
	if not track(cpu_row.path,cpu_row.sha256): return false
	var cpu: Dictionary = json(cpu_row.path)
	if not check(cpu.scope == "AE_RESIDUAL_TWO_DOMAIN_SOURCE_NATIVE_MARKET36_PRIOR_IMPORT_COMPONENT_ONLY_NOT_FIELD" and cpu.complete == true and cpu.failures == 0 and cpu.original118004_whole_FAIL_preserved == true and cpu.import_texture_raster_Field_replayed == false and cpu.source_before == cpu.source_after and cpu.players_before.size() == 15 and cpu.players_before == cpu.players_after and cpu.state_before == cpu.state_after,"Actual residual source/native component, original118004 wholeFAIL preserved and imports not rerun"): return false
	if not market_cpu_source_successor(cpu): return false
	b = load(B_PATH); c = load(C_PATH); market_api = load(MARKET_AE_API)
	if not check(b != null and b.can_instantiate() and c != null and c.can_instantiate() and market_api != null and market_api.can_instantiate(),"Actual canonical APIs compile before access"): return false
	var ready: Dictionary = market_api.readiness()
	if not check(ready.get("ok") == true and b.equal(ready.spec.overlays,market_fixture.authored_overlays) and ready.spec.textures.size() == 1,"Independent first-cluster whole-PNG placement values, not actual backfill"): return false
	if not track(MARKET_AE_PACKET,MARKET_AE_PACKET_SHA): return false
	ab_packet = bytes_to_var(FileAccess.get_file_as_bytes(MARKET_AE_PACKET))
	var original: SceneScript = ResourceLoader.load(market_fixture.native_scene.path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not track(market_fixture.native_scene.path,market_fixture.native_scene.sha256): return false
	if not check(original != null and original.map_layout != null and original.map_layout.visual_objects.size() == 24 and ab_packet.record.objects.size() == 24,"Frozen native24 Scene/typed packet, not crowd10 or old30"): return false
	var district: Script = load("res://scripts/city/luoyang_district_life_20261016f.gd")
	var transform: Script = load("res://build/luoyang_layout_quest_20261018t_layout_source01/layout_transform_retry2.gd")
	if not check(district != null and district.can_instantiate() and transform != null and transform.can_instantiate(),"Original DG/T pure value projection only"): return false
	var district_author: Dictionary = json(market_fixture.district_author.path)
	var t_author: Dictionary = json(market_fixture.t_author.path)
	market_projection = transform.district_projection(district.G.project(district_author,StringName(MARKET)),StringName(MARKET),t_author)
	if not check(not market_projection.is_empty() and market_projection.replacements.size() == 1 and market_projection.additions.size() == 12 and market_projection.spec.crowd.size() == 10,"13 DG placements=1replacement+12adds, crowd10 separate unchanged domain"): return false
	market_expected36 = district.G.apply_render(original.map_layout.visual_objects,market_projection)
	if not check(market_expected36.size() == 36,"Independent frozen native24 + old DG delta yields exact36 before new ground"): return false
	var self_path: String = get_script().resource_path
	return track(self_path,FileAccess.get_sha256(self_path))

func market_cpu_source_successor(cpu: Dictionary) -> bool:
	if not track(market_fixture.cpu_false_map.path,market_fixture.cpu_false_map.sha256): return false
	var prior: Dictionary = json(market_fixture.cpu_false_map.path).source_sha256.duplicate(true)
	var matched: Array = []
	for row: Dictionary in cpu.records:
		if row.get("kind") == "AE_EXACT_SOURCE_IMMUTABLE_NATIVE_COMPONENT" and row.get("scene_id") == MARKET: matched.append(row)
	if not check(matched.size() == 1 and matched[0].source_count == prior.size() and matched[0].sources == prior,"Actual unique CPU Market source component equals frozen false map"): return false
	var index: Dictionary = market_fixture.formal_index
	if not check(prior.get(index.path) == index.false_sha256 and expected_maps[MARKET].get(index.path) == index.true_sha256,"Explicit sole Market bool source successor"): return false
	prior[index.path] = index.true_sha256
	return check(prior == expected_maps[MARKET],"Every non-index source identical from actual CPU component to formal Market map")

func _geometry(id: String) -> bool:
	ab_record = c._records.get(id,{}).duplicate(true)
	if not check(id == MARKET and b.whole_bound(scene) and b.equal(ab_record,ab_packet.record),"Actual same-owner original24 complete record remains exact old packet"): return false
	mask = Image.load_from_file(String(ab_record.walk_path))
	var actual_mask: Image = c._masks.get(MARKET)
	if not check(mask != null and actual_mask != null and mask.get_data() == ab_packet.walk_bytes and actual_mask.get_data() == ab_packet.walk_bytes and c._equal_value(c._solids.get(MARKET),c.object_solids(ab_record.objects)),"Original whole mask/native24 solids unchanged, no reraster"): return false
	var solids: Array = []
	for object: Dictionary in ab_packet.record.objects:
		var n: int = 0
		for poly: Array in object.get("solid_polygons_px",[]):
			solids.append({"id":String(object.id)+"_poly_"+str(n),"points_px":poly}); n += 1
		var extent: Vector2 = _v(object.collision_size_px)
		if extent.x > 0 and extent.y > 0:
			var low: Vector2 = _v(object.physical_center_px)-extent*.5; var high: Vector2 = low+extent
			solids.append({"id":String(object.id)+"_box","points_px":[low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)]})
	var index: int = 0
	for entry: Dictionary in market_projection.additions+market_projection.replacements:
		for poly: Array in entry.city_v3_solid_polygons_px:
			solids.append({"id":"old_DG_"+str(index),"points_px":poly}); index += 1
	oracle = (load(RAW_PATH) as Script).new()
	return check(oracle.configure([[[0,0],[3072,0],[3072,2048],[0,2048]]],solids,WORLD,WORLD) and _clear((field.get("_player") as Node2D).position),"Independent unchanged24+DG static foot oracle and actual native34x24/87517 birth")

func ab_arrive() -> bool:
	var start: int = Time.get_ticks_usec()
	if not check(root.get_node("SceneRouter").call("go_field_smart",StringName(MARKET),null,"",-1,-1),"One ordinary default-null Market, no candidate/near-spawn/room trip"): return false
	var until: int = mini(deadline,Time.get_ticks_msec()+60000)
	while Time.get_ticks_msec() < until:
		await process_frame
		var request: Dictionary = root.get_node("SceneRouter").call("get_public_city_preparation_state")
		if request.get("scene_id") == MARKET and request.get("phase") == "FAILED": return check(false,"Market actual request failed",request)
		if not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): continue
		var state: Dictionary = current_scene.call("get_field_loading_state")
		if state.get("failed",false): return check(false,"Market actual Field failed",state)
		var candidate: SceneScript = current_scene.get("_current_scene") as SceneScript
		var player: CharacterBody2D = current_scene.get("_player") as CharacterBody2D
		if candidate == null or String(candidate.scene_id) != MARKET or player == null or not bool(player.get("can_move")) or state.get("complete") != true: continue
		var screen: Node = root.get_node("LoadingManager").get("_screen")
		var panel: Control = screen.get("root") as Control if is_instance_valid(screen) else null
		if panel != null and panel.is_visible_in_tree(): continue
		await RenderingServer.frame_post_draw
		field = current_scene; scene = candidate
		var firstdraw: int = Time.get_ticks_usec()-start; var hash_start: int = Time.get_ticks_usec()
		var proof: Dictionary = c.resident_receipt(scene)
		if not check(proof.get("sources_finalized") == true and proof.get("sources",{}) == expected_maps[MARKET],"Actual complete independent formal Market source map"): return false
		for path: String in expected_maps[MARKET]:
			if not track(path,expected_maps[MARKET][path]): return false
		records.append({"kind":"AE_MARKET_ORDINARY_FIRSTDRAW","firstdraw_operable_usec":firstdraw,"source_check_usec":Time.get_ticks_usec()-hash_start,"source_count":proof.sources.size(),"actual_foot":player.position,"performance_promise":false})
		if not check(field.get_script().resource_path == FIELD and scene.actor_positions_are_feet and player.position.distance_to(_v(ab_packet.record.entry_foot_px)) < .03,"Frozen published Market entry, never infer it from current actual result"): return false
		return _geometry(MARKET)
	return check(false,"Market original60s arrival budget")

func market_ground() -> bool:
	var district: RefCounted = field.get("_district_session")
	if not check(district != null and district.get("parent_render").size() == 24 and b.equal(district.get("projected"),market_projection),"Actual prepared District owner preserves old24 parent and independent13-placement projection"): return false
	var navigation: Array = district.call("navigation_objects",district.get("parent_render"))
	var rendered: Array = district.call("render_objects",district.get("parent_render"))
	var session: Dictionary = district.get("_market_ground")
	if not check(b.equal(navigation,market_expected36) and b.equal(rendered.slice(0,36),market_expected36) and session.get("ok") == true and session.get("enabled") == true and b.equal(session.get("parent_render"),market_expected36) and rendered.size() == 36+market_fixture.authored_overlays.size(),"Original navigation36/prefix36 exact; only source-bound ground suffix appended"): return false
	var overlap: RefCounted = field.get("_v14_modular_overlap")
	for row: Dictionary in market_fixture.authored_overlays:
		var found: Array[Sprite2D] = []
		for node: Node in field.get("_scene_object_nodes"):
			if node is Sprite2D and String(node.name) == "SceneObject_"+String(row.id): found.append(node as Sprite2D)
		if not check(found.size() == 1,"Exactly one new Market ground Sprite "+row.id): return false
		var sprite: Sprite2D = found[0]
		var normalized: Vector2 = _v(row.center_px)/WORLD
		var expected_position: Vector2 = Vector2(normalized.x*WORLD.x,normalized.y*WORLD.y)
		if not check(sprite.get_parent() == field.get("_visual_layer") and sprite.get_child_count() == 0 and sprite.get_script() == null and sprite.texture.resource_path == row.texture and not sprite.region_enabled and sprite.centered and sprite.position == expected_position and sprite.scale == _v(row.render_size_px)/sprite.texture.get_size() and sprite.z_index == -998 and sprite.modulate == Color(1,1,1,float(row.opacity)),"Whole-PNG exact ground transform/modulate/VisualLayer,z-998 without actor depth "+row.id): return false
		if not check(field.find_child("CityV3Physical_"+String(row.id),true,false) == null,"New ground has no native physics body "+row.id): return false
		for prop: Dictionary in overlap.get("_props"):
			if not check(prop.sprite != sprite,"New ground never a ghost contributor"): return false
		for entry: Dictionary in overlap.get("_depth_entries"):
			if not check(entry.node != sprite,"New ground never on actor depth ladder"): return false
		market_ground_nodes.append(sprite)
	var player_sprite: Sprite2D = (field.get("_player") as Node).get("sprite") as Sprite2D
	market_player_colors = [player_sprite.modulate,player_sprite.self_modulate]
	records.append({"kind":"AE_MARKET_EXACT36_PREFIX_VISUAL_SUFFIX_NO_NAV_CHANGE","native_count":24,"old_DG_placement_count":13,"old_prefix_count":36,"suffix_count":market_ground_nodes.size(),"NPC_or_room_replay":false})
	return true

func market_trip() -> bool:
	var route := PackedVector2Array()
	for p: Array in market_fixture.short_route_px: route.append(_v(p))
	if not check(route.size() >= 2 and route[0] == _v(ab_packet.record.entry_foot_px),"Authoritative short mainstreet/stall-front route, no new coordinates backfill"): return false
	var result: Dictionary = await driver.follow(field,route,_clear,_segment)
	records.append({"kind":"AE_MARKET_SHORT_NORMAL_MAINSTREET_INPUT","result":result})
	if not check(result.get("ok") == true,"Representative actual mainstreet/stall-front native34x24/87517",result): return false
	for p: Array in market_fixture.protected_static_feet_px:
		var foot: Vector2 = _v(p)
		# Paper artisan can occupy its own foot: this checks static geometry only.
		if not check(oracle.clear(foot) and _mask_clear(foot),"Paper/package/approach unchanged static87517/continuous34x24, not NPC self-collision "+str(p)): return false
	var player_sprite: Sprite2D = (field.get("_player") as Node).get("sprite") as Sprite2D
	if not check(market_player_colors == [player_sprite.modulate,player_sprite.self_modulate],"Ground does not tint the player"): return false
	return await _picture("ae_market_first_cluster_ground_ordinary")

func _run() -> void:
	began = Time.get_ticks_msec(); deadline = began+90000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	players_before = saves(); folder = "res://build/luoyang_shore_market_20261020ae_qa01/market_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool = ab_preflight()
	if complete:
		gs = root.get_node("GameState"); qm = root.get_node("QuestManager")
		original_parts = {"flags":gs.get("flags").duplicate(true),"quests":qm.call("to_dict").duplicate(true)}; original_rewards = _rewards()
		driver = (load(INPUT_PATH) as Script).new(); driver.configure(self)
		complete = await ab_arrive()
		if complete: complete = market_ground()
		if complete: complete = await market_trip()
	if driver != null: driver.release(); driver = null
	var layer_weaks: Array[WeakRef] = []
	for sprite: Sprite2D in market_ground_nodes:
		if is_instance_valid(sprite): layer_weaks.append(weakref(sprite))
	market_ground_nodes.clear()
	if is_instance_valid(current_scene):
		var own: Node = current_scene; var own_weak: WeakRef = weakref(own)
		current_scene = null; own.queue_free(); field = null; scene = null; own = null
		await process_frame; await process_frame
		check(own_weak.get_ref() == null,"Only own Market Field released")
	for weak: WeakRef in layer_weaks: check(weak.get_ref() == null,"Market ground suffix has no lifetime outside Field")
	if not original_parts.is_empty():
		check(qm.call("to_dict") == original_parts.quests and _rewards() == original_rewards,"Ground cannot change quests/rewards/inventory")
		gs.set("flags",original_parts.flags.duplicate(true)); qm.call("from_dict",original_parts.quests.duplicate(true))
		check(gs.get("flags") == original_parts.flags and qm.call("to_dict") == original_parts.quests,"Only ordinary visit flags restored in memory, no slot writes")
	oracle = null; mask = null; ab_packet.clear(); ab_record.clear()
	var after: Dictionary = {}
	for path: String in source_before: after[path] = fact(path)
	var saved: Dictionary = saves()
	check(source_before == after and players_before == saved and saved.size() == 15,"Market complete sources/15save first-final unchanged")
	check(pictures.size() <= 1 and Time.get_ticks_msec() < deadline,"One Market capture, unchanged90/60; no doors/AD/x chains")
	var path: String = folder.path_join("result.json"); var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"scope":"AE_MARKET_FIRST_GROUND_CLUSTER_EXACT36_PREFIX_SHORT_INPUT_NOT_ROOMS_NPC","complete":complete and failures == 0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"budget_ms":90000,"arrival_ms":60000,"native_queries":native_queries,"records":records,"pictures":pictures,"source_before":source_before,"source_after":after,"players_before":players_before,"players_after":saved,"room_NPC_or_task_replay":false,"full_Market_redesign_or_loading_promise":false},"\t",true,true)); file.close()
	print(JSON.stringify({"report_path":path,"checks":checks,"failures":failures,"complete":complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)


