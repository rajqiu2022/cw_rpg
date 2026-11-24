extends "res://tests/test_luoyang_four_city_key_smoke_20261012.gd"
## NEW finite actual market test. Parent utility methods only; never parent _run.
## One main street, one new-solid stop, one frontage fade, one Space round trip.
const MARKET = preload("res://scripts/city/luoyang_market_enrichment_contract_20261014.gd")
const SIMPLE_RAW = preload("res://tests/helpers/v15_field_raw_oracle.gd")
const MARKET_SOURCE_READY := true
const MARKET_PINS: Dictionary = {
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"4a7f23c2870fe7e0a8c06a283b4f9fd282f59b1b6b4b5abeb5f8fb5632cc9fa3",
	"res://scripts/field/field_walkable_controller.gd":"7c4ec636ef2cf995b428acecb4c4e237901207543fc1b5aeb3b77a4385695c8a",
	"res://scripts/city/luoyang_market_enrichment_contract_20261014.gd":"7782efd9bb88254a00f6d4ad5a52ea6f7cb8f03c33203b7dd766dd0ebf261f39",
	"res://scripts/city/luoyang_market_enrichment_fade_20261014.gd":"30ad295d6f57adcf03d6538de6d8f0800b60641ac1cad2f2327f7dcb42c9f6d0",
	"res://scripts/dev/publish_luoyang_market_enrichment_candidate_20261014.gd":"ba5d53125b20c894e6042291013a71463c2b6b5798dd87736b3b137bcef70908",
	"res://scripts/autoload/loading_manager.gd":"38fce81dd6b397fc171a13f142f8032b7de1c76687654e09fb6fe27738f00e77",
	"res://scripts/autoload/scene_router.gd":"a51f2b769cca1d9541a890c5b31ef75fd240fcb7f70bad1b8e401b117ea0cbff",
	"res://scripts/autoload/platform_bridge.gd":"eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a",
	"res://scripts/autoload/save_manager.gd":"67c06cd14d6a7c0bbfd7467bbaae84f906aad57b19cabc0902baf80eb3aff7d9",
	"res://scripts/field/player.gd":"9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419",
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://tests/helpers/v15_field_raw_oracle.gd":"dc36f4144496477508f9ad8b346f846043db109415760ab87205fa814aad26fb",
	"res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd":"6ad7b6be15fd23ea4f8356c111c5a5a6c54c8e1ec7496083597d01e904711c62",
	"res://tests/test_luoyang_four_city_key_smoke_20261012.gd":"65508b636a699dad0cdd73543aea02a06b9730979666191d570e5fe13cab0ba5",
	"res://art/maps/luoyang_market_enrichment_v2/market_author_config.json":"f6d7f42539d80a14bad63540713f78a827cd1c3b8c26b98ae01ef5f24311a18d",
	"res://art/maps/luoyang_market_enrichment_v2/runtime_manifest.json":"d617289ee22a40223f86e9f2003bdc149e8b2714aef1f83d93d4faf605ee67cd",
	"res://data/scenes/luoyang_market_enrichment_v2_candidates/ch4_s3_luoyang_market.tres":"2df5059ab647d956e7b37c8bb5f7d0d568d575deac7931b3ccadb5451c6fe8f6",
	"res://data/maps/luoyang_market_enrichment_v2_candidates/ch4_s3_luoyang_market_layout.tres":"70eed1b355ec18ac6d2a5d781fd1d98975d032e9961118251127ba0076e33de4",
	"res://art/maps/luoyang_market_enrichment_v2/walk.png":"eafff63dd416959dff357d5d0f06cdc22ca93d648ac76abf9f73d34cba2b2333",
}
const MARKET_ID := "ch4_s3_luoyang_market"
const DOCKS_ID := "ch4_s2_canal_docks"
const FRONTAGE_ID := "market_east_ward_frontage"
var market_record: Dictionary = {}
var market_manifest: Dictionary = {}
var mask: Image
var polygons: Array[PackedVector2Array] = []
var arrival_observations: Array[Dictionary] = []
var fade_observations: Array[Dictionary] = []
var gallery: Array[Dictionary] = []
var expected_npc_ids: Array[String] = []
var weak_fade: WeakRef

func _values(value: Variant) -> Variant:
	if value is Vector2 or value is Vector2i: return [value.x,value.y]
	if value is Color: return [value.r,value.g,value.b,value.a]
	if value is Rect2: return [value.position.x,value.position.y,value.size.x,value.size.y]
	if value is Array or value is PackedVector2Array:
		var result: Array = []
		for item: Variant in value: result.append(_values(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _values(value[key])
		return result
	return value

func _save(name: String, value: Variant) -> bool:
	var file: FileAccess = FileAccess.open(output+name,FileAccess.WRITE)
	if file == null: return _check(false,"finite evidence write "+name)
	file.store_string(JSON.stringify(_values(value),"\t")); file.close()
	return _check(JSON.parse_string(FileAccess.get_file_as_string(output+name)) != null,"finite evidence readback "+name)

func _source_market() -> bool:
	market_manifest = MARKET.runtime_manifest()
	var original_reader: RefCounted = RAW.new()
	var original: Dictionary = original_reader.call("independent_record",StringName(MARKET_ID))
	original_reader.call("release"); original_reader = null
	if not _check(not original.is_empty() and not market_manifest.is_empty(),"independent complete original plus real market publication"): return false
	var packet: Dictionary = MARKET.read_after_original(original)
	if not _check(not packet.has("error") and packet.get("record") is Dictionary,"source/import/geometry/gameplay composition bound"): return false
	market_record = packet.record
	var original_scene: SceneScript = ResourceLoader.load("res://data/scenes/"+MARKET_ID+".tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _check(original_scene != null,"actual original market definition"): return false
	for npc: Dictionary in original_scene.npcs: expected_npc_ids.append(String(npc.npc_id))
	_check(market_record.objects.size() == 26 and original.objects.size() == 16 and original_scene.npcs.size() == 8 and original_scene.map_layout.portals.size() == 4 and original_scene.map_layout.interactions.size() == 4 and market_record.routes == original.routes and market_record.gameplay_slots == original.gameplay_slots,"26 objects and original eight NPC/four portal/four interaction/seven route identities preserved")
	var additions: Array[String] = []
	for object: Dictionary in market_record.objects:
		if object.get("market_enrichment_object",false): additions.append(String(object.id))
	_check(additions == MARKET.ADD_IDS and market_record.routes.size() == 7,"exact ten new object identities, no new gameplay slots")
	rows.append({"kind":"SOURCE_BOUND","objects":26,"add_ids":additions,"NPC_definition_ids":expected_npc_ids,"NPC_live_count_credit":false,"portals":4,"interactions":4,"routes":7,"manifest_sha":MARKET.MANIFEST_SHA,"author_sha":MARKET.AUTHOR_SHA})
	return failures == 0

func _wait_field(id: String) -> bool:
	var started: int = Time.get_ticks_msec()
	var end: int = mini(deadline,started+60000)
	while Time.get_ticks_msec() < end:
		await process_frame
		if bool(root.get_node("LoadingManager").get("_transition_active")): continue
		var pending: Node = current_scene
		if not is_instance_valid(pending) or not pending.is_inside_tree() or pending.is_queued_for_deletion() or pending.scene_file_path != "res://scenes/field_walkable.tscn": continue
		var definition: SceneScript = pending.get("_current_scene") as SceneScript
		var player: Node2D = pending.get("_player") as Node2D
		if definition == null or String(definition.scene_id) != id or not is_instance_valid(player) or not player.is_inside_tree() or player.is_queued_for_deletion() or bool(pending.get("_scene_rebuilding")): continue
		await driver.call("completed_actor_stage")
		if not is_instance_valid(pending) or current_scene != pending or pending.is_queued_for_deletion() or bool(root.get_node("LoadingManager").get("_transition_active")) or bool(pending.get("_scene_rebuilding")) or not is_instance_valid(player) or pending.get("_player") != player: continue
		field = pending
		arrival_observations.append({"scene_id":id,"arrival_wait_ms":Time.get_ticks_msec()-started,"credit":"OBSERVED_WAIT_NOT_COLD_BENCHMARK","field_instance_id":field.get_instance_id(),"physics_frame":Engine.get_physics_frames()})
		_save("arrivals.json",arrival_observations)
		return true
	_save("arrival_failure.json",{"scene_id":id,"wait_ms":Time.get_ticks_msec()-started,"C_errors":C.errors(),"LM_metrics":root.get_node("LoadingManager").call("get_field_preload_metrics")})
	return _check(false,"shared180s/individual60s live Field arrival "+id)

func _bind() -> bool:
	if oracle != null: _check(bool(oracle.call("verify_sources")),"previous independent actual mask stable"); oracle.call("release"); oracle = null
	mask = null; polygons.clear()
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	if not _check(scene != null and scene.map_layout != null,"actual current scene/layout"): return false
	var record: Dictionary
	if String(scene.scene_id) == MARKET_ID:
		record = market_record
		var actual_npcs: Array[String] = []
		for npc: Dictionary in scene.npcs: actual_npcs.append(String(npc.npc_id))
		var runtime: RefCounted = field.get("_v14_modular_overlap") as RefCounted
		if not _check(MARKET.bound(scene) and scene.background_path == record.ground_path and scene.map_layout.visual_objects.size() == 26 and scene.map_layout.portals.size() == 4 and scene.map_layout.interactions.size() == 4 and actual_npcs == expected_npc_ids and runtime != null and runtime.get_script().resource_path == "res://scripts/city/luoyang_market_enrichment_fade_20261014.gd","actual market third layer and native dedicated fade plus original gameplay definitions"): return false
		for id: String in MARKET.ADD_IDS:
			var node: Sprite2D = field.find_child("SceneObject_"+id,true,false) as Sprite2D
			if not _check(node != null and node.texture != null,"actual added sprite "+id): return false
	else:
		if not _check(String(scene.scene_id) == DOCKS_ID,"only unchanged real docks allowed"): return false
		var reader: RefCounted = RAW.new()
		record = reader.call("independent_record",StringName(DOCKS_ID))
		reader.call("release"); reader = null
		if not _check(not record.is_empty() and scene.map_layout.walkable_mask_path == record.walk_path,"independent unchanged docks source"): return false
	var declarations: Array[Dictionary] = []
	for object: Dictionary in record.objects:
		var shapes: Array[PackedVector2Array] = []
		var extent := Vector2(object.collision_size_px[0],object.collision_size_px[1])
		if extent.x > 0 and extent.y > 0:
			var center := Vector2(object.physical_center_px[0],object.physical_center_px[1])
			var rect := Rect2(center-extent*.5,extent)
			shapes.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
		for value: Array in object.solid_polygons_px:
			var polygon := PackedVector2Array()
			for pair: Array in value: polygon.append(Vector2(pair[0],pair[1]))
			if not _check(polygon.size() >= 3 and not Geometry2D.triangulate_polygon(polygon).is_empty(),"independent declared polygon "+String(object.id)): return false
			shapes.append(polygon)
		for shape: PackedVector2Array in shapes: polygons.append(shape)
		if not shapes.is_empty(): declarations.append({"id":object.id,"solid_polygons_px":shapes})
	var owned: Resource = scene.map_layout.duplicate(true)
	owned.set("visual_objects",declarations)
	oracle = SIMPLE_RAW.new()
	var good: bool = bool(oracle.call("configure",owned,"round_world_pixel",0.0))
	owned = null
	mask = Image.load_from_file(record.walk_path)
	return _check(good and mask != null and mask.get_size() == Vector2i(3072,2048),"independent full current objects plus full17/source mask, not old market solids")

func _body_raw(p: Vector2) -> bool:
	if mask == null or not p.is_finite(): return false
	var rect := Rect2(p-Vector2(17,12),Vector2(34,24))
	if rect.position.x < 0 or rect.position.y < 0 or roundi(rect.end.x) >= mask.get_width() or roundi(rect.end.y) >= mask.get_height(): return false
	for y: int in range(roundi(rect.position.y),roundi(rect.end.y)+1):
		for x: int in range(roundi(rect.position.x),roundi(rect.end.x)+1):
			var color: Color = mask.get_pixel(x,y)
			if color.a < .5 or color.r < .5: return false
	var body := PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	for polygon: PackedVector2Array in polygons:
		if not Geometry2D.intersect_polygons(body,polygon).is_empty(): return false
	return true

func _clear(p: Vector2) -> bool:
	return Time.get_ticks_msec() < deadline and _body_raw(p) and oracle != null and bool(oracle.call("clear",p)) and _physical(p)

func _way(points: PackedVector2Array) -> bool:
	var actual: Dictionary = await driver.call("follow",field,points,_clear,_segment)
	rows.append({"kind":"NORMAL_INPUT_PATH","points":points,"receipt":actual})
	_save("movement.json",rows)
	return _check(actual.get("ok") == true,"source-bound normal INPUT complete path")

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = output+name+".png"
	var good: bool = image != null and not image.is_empty() and image.save_png(path) == OK
	_check(good,"real market GPU "+name)
	gallery.append({"path":path,"sha256":FileAccess.get_sha256(path) if good else "","size":image.get_size() if image != null else Vector2i.ZERO})
	_save("gallery.json",gallery)

func _fade(behind: bool) -> bool:
	var held: Node = field
	var player: Node2D = field.get("_player") as Node2D
	var end: int = mini(deadline,Time.get_ticks_msec()+250)
	while Time.get_ticks_msec() < end: await process_frame
	if not _check(is_instance_valid(held) and current_scene == held and held.get("_player") == player and is_instance_valid(player) and _clear(player.position),"same live Field/Player after natural fade interval"): return false
	var sprite: Sprite2D = field.find_child("SceneObject_"+FRONTAGE_ID,true,false) as Sprite2D
	var state: Dictionary = field.call("get_city_building_fade_debug")
	var records: Array = (state.get("buildings",[]) as Array).filter(func(r: Dictionary)->bool: return r.get("id") == FRONTAGE_ID)
	if not _check(sprite != null and records.size() == 1 and state.get("runtime_hooked") == true,"one live added frontage fade target"): return false
	var record: Dictionary = records[0]
	var expected: float = .55 if behind else 1.0
	var native: Color = sprite.self_modulate
	var good: bool = record.hit == behind and record.base_color.a == 1.0 and sprite.modulate.a == 1.0 and var_to_bytes(native) == var_to_bytes(record.display_color) and absf(float(record.factor)-expected) < .000001 and absf(native.a-expected) < .000001
	fade_observations.append({"phase":"behind" if behind else "front_leave","Field_id":field.get_instance_id(),"Player_id":player.get_instance_id(),"sprite_id":sprite.get_instance_id(),"foot":player.position,"hit":record.hit,"eligible":record.eligible,"factor":record.factor,"target":record.target,"native_color":native,"native_bytes":var_to_bytes(native).hex_encode(),"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames()})
	_save("fade.json",fade_observations)
	return _check(good,"new frontage native55 behind/native1 front, no forced refresh")

func _solid_stop() -> bool:
	var forbidden := Vector2(2550,1235)
	var start: Vector2 = (field.get("_player") as Node2D).position
	var denied: bool = not _body_raw(forbidden) and not bool(oracle.call("clear",forbidden)) and not _physical(forbidden)
	var player: Node2D = field.get("_player") as Node2D
	var held: Node = field
	var feet: Array = []
	var all_clear: bool = true
	Input.action_press("move_down",1.0)
	for tick: int in 45:
		await physics_frame
		if not is_instance_valid(held) or current_scene != held or not is_instance_valid(player) or held.get("_player") != player: all_clear = false; break
		feet.append(player.position); all_clear = all_clear and _clear(player.position)
	driver.call("release_movement")
	await driver.call("completed_actor_stage")
	var actual: Vector2 = player.position if is_instance_valid(player) else Vector2(INF,INF)
	var stopped: bool = denied and all_clear and actual.is_finite() and actual.distance_to(forbidden) > 17 and actual.distance_to(start) < 65
	rows.append({"kind":"NEW_FRONTAGE_SOLID_STOP","start":start,"forbidden":forbidden,"source_and_Physics_denied":denied,"action":"move_down","actual_45_physics_feet":feet,"all_full875_17_Physics_clear":all_clear,"end":actual,"stopped":stopped})
	_save("solid_stop.json",rows[-1])
	return _check(stopped,"new frontage ground denies real input, every actual shoe remains clear")

func _trip() -> bool:
	var player: Node2D = field.get("_player") as Node2D
	var source_foot: Vector2 = player.position
	var zone: Node
	for item: Node in field.get("_exit_nodes"):
		if String(item.get("target_scene_id")) == DOCKS_ID:
			if zone != null: return _check(false,"unique authored docks portal")
			zone = item
	if not _check(zone != null and bool(zone.get("_in_range")),"original actual docks portal overlap"): return false
	weak_fade = weakref(field.get("_v14_modular_overlap"))
	await driver.call("key",KEY_SPACE)
	if not await _wait_field(DOCKS_ID) or not _bind(): return false
	_check(weak_fade.get_ref() == null,"old market dedicated fade released on normal portal")
	var reverse: Node
	for item: Node in field.get("_exit_nodes"):
		if String(item.get("target_scene_id")) == MARKET_ID:
			if reverse != null: return _check(false,"unique reverse market portal")
			reverse = item
	if not _check(reverse != null,"real unchanged docks reverse portal"): return false
	var path: PackedVector2Array = driver.call("plan",(field.get("_player") as Node2D).position,reverse.position,field.get("_world_size"),_clear,_segment)
	var driven: Dictionary = await driver.call("follow",field,path,_clear,_segment)
	if not _check(driven.get("ok") == true and bool(reverse.get("_in_range")),"normal docks reverse approach full875/17/Physics"): return false
	await driver.call("key",KEY_SPACE)
	if not await _wait_field(MARKET_ID) or not _bind(): return false
	var returned: Vector2 = (field.get("_player") as Node2D).position
	var good: bool = returned.distance_to(source_foot) < .03 and _clear(returned)
	rows.append({"kind":"NORMAL_SPACE_ROUND_TRIP","source":MARKET_ID,"target":DOCKS_ID,"original_departure":source_foot,"return":returned,"reverse_drive":driven,"router_shortcut_used":false,"return_same_clear_foot":good})
	return _check(good,"normal Space round trip remembers exact market foot")

func _exercise() -> void:
	if not _source_market(): return
	if not _check(bool(root.get_node("SceneRouter").call("go_field_smart",StringName(MARKET_ID),null,"",-1,3)),"public candidate market startup"): return
	if not await _wait_field(MARKET_ID) or not _bind(): return
	var player: Node2D = field.get("_player") as Node2D
	if not _check(player.position.distance_to(Vector2(1536,1860)) < .03 and _clear(player.position),"original market spawn full875/full17/Physics"): return
	rows.append({"kind":"REAL_MARKET_SPAWN","position":player.position,"raw17":oracle.call("foot_evidence",player.position),"raw875":_body_raw(player.position),"Physics":_physical(player.position)})
	if not await _way(PackedVector2Array([player.position,Vector2(1536,1500),Vector2(1536,1050),Vector2(1536,770)])): return
	await _capture("market_main_street")
	if not await _way(PackedVector2Array([(field.get("_player") as Node2D).position,Vector2(1536,1060),Vector2(2090,1060),Vector2(2840,1060),Vector2(2840,1170),Vector2(2550,1170)])): return
	if not await _solid_stop() or not await _fade(true): return
	await _capture("market_new_frontage_behind")
	if not await _way(PackedVector2Array([(field.get("_player") as Node2D).position,Vector2(2550,1060),Vector2(2090,1060),Vector2(2090,1290)])) or not await _fade(false): return
	if not await _way(PackedVector2Array([(field.get("_player") as Node2D).position,Vector2(2090,1060),Vector2(2840,1060)])): return
	await _trip()

func _run() -> void:
	var bridge: Node = root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true,"checkpoint held before first await")
	players_before = _players(); prior_slot = int(root.get_node("SaveManager").get("active_slot"))
	prior_navigation = (root.get_node("SceneRouter").call("get_navigation_state") as Dictionary).duplicate(true)
	deadline = Time.get_ticks_msec()+180000
	output = "res://build/joint_world_luoyang_20261003_qa/market_enrichment_key_%d_%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK,"new finite output")
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_check(MARKET_SOURCE_READY and "--luoyang-market-enrichment-key" in args and MARKET.FLAG in args and "--luoyang-v3-candidate" in args and "--luoyang-enclosure-v11-candidate" in args,"frozen explicit market candidate-only key scope")
	_check(DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0 and FileAccess.get_sha256(OS.get_executable_path()).to_lower() == ENGINE_SHA,"real GPU ordinary clock/frozen GUI engine")
	for path: String in MARKET_PINS:
		source_before[path] = _file(path)
		_check(MARKET_PINS[path].length() == 64 and source_before[path].sha256 == MARKET_PINS[path],"exact frozen source "+path)
	source_before[get_script().resource_path] = _file(get_script().resource_path)
	for path: String in MARKET.source_paths(): source_before[path] = _file(path)
	for id: String in [MARKET_ID,DOCKS_ID]:
		for path: String in ["res://data/scenes/"+id+".tres",C.candidate_path(StringName(id)),C.layout_path(StringName(id)),C.manifest_path(StringName(id)),C.base_manifest_path(StringName(id)),C.ground_manifest_path(StringName(id))]: source_before[path] = _file(path)
	driver = INPUT_DRIVER.new(); driver.call("configure",self)
	if failures == 0:
		for id: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(id).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		await _exercise()
	if oracle != null: _check(bool(oracle.call("verify_sources")),"final independent actual mask stable"); oracle.call("release"); oracle = null
	mask = null; polygons.clear(); market_record.clear(); market_manifest.clear()
	if driver != null: driver.call("release"); driver = null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene = null
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	await process_frame; await process_frame
	root.get_node("SceneRouter").call("restore_navigation_state",prior_navigation,&"world_map_jianghu",&"world_map_jianghu")
	_check(_sources() == source_before and _players() == players_before and root.get_node("SaveManager").get("active_slot") == prior_slot and bridge.call("is_checkpoint_saves_suspended") == true,"source/current15player/slot preserved, checkpoint held through cleanup")
	_check(rows.size() == 8 and gallery.size() == 2 and fade_observations.size() == 2 and arrival_observations.size() == 3,"exact finite receipts, two GPU/fade views and one real round trip")
	var result: Dictionary = {"scope":"MARKET_26_SOURCE_SPAWN_MAIN_STREET_NEW_SOLID_FADE_SPACE_NOT_SIX","complete":failures == 0,"checks":checks,"failures":failures,"records":rows,"gallery":gallery,"fade":fade_observations,"arrivals":arrival_observations,"source_before":source_before,"source_after":_sources(),"players_before":players_before,"players_after":_players(),"actual_audio_driver":AudioServer.get_driver_name(),"audio_credit":false,"live_NPC_8_credit":false,"tasks_battles_full_saves_tested":false,"full_RGBA_occlusion_tested":false,"formal_approved":false,"exactticks_guard":"ROOT_OUTER_REQUIRED"}
	_save("result.json",result)
	print("MARKET_ENRICHMENT_KEY_RESULT="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures == 0 else 1)
