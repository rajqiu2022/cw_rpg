extends "res://tests/test_luoyang_four_city_key_smoke_20261012.gd"
## NEW finite actual Field test; inherited utility methods only, not old _run.
const GATE = preload("res://scripts/city/luoyang_gate_fortification_contract_20261013.gd")
const SIMPLE_RAW = preload("res://tests/helpers/v15_field_raw_oracle.gd")
const SOURCE_READY := true
const CURRENT_PINS: Dictionary = {
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"48ed42a3f53b689b9ab27f825a9605732392f2015a26e8f21e3828af1bce34ca",
	"res://scripts/field/field_walkable_controller.gd":"94d87559b57e79264499f5a6bf387823d707f4f29e78aa9f6e4f180fd054cf8f",
	"res://scripts/city/luoyang_gate_fortification_contract_20261013.gd":"897fe9b8c7cb641c378fda530c067e8045f1da7c825ae263fcbb10dad209dd3b",
	"res://scripts/city/luoyang_gate_moat_runtime_20261013.gd":"c8fff51978af6a60c571d37fd1da98ea92205fdb9b4d874b40a535ec5f61643f",
	"res://scripts/city/luoyang_gate_fortification_fade_20261013.gd":"26fc78af0e48b497da81940b1b64ed336cd12dec489c67c8810ef980aab91ad6",
	"res://scripts/dev/publish_luoyang_gate_fortification_candidate_20261013.gd":"eb20c1980f0cd31d06176506b964d08ab2bef318054740589643e5c40fac12b1",
	"res://art/maps/luoyang_gate_fortification_v1/gate_author_config.json":"44e80d4c0a9688922210e1f930a39e73059cb222bf81284ff97d73a50ba422f4",
	"res://art/maps/luoyang_gate_fortification_v1/runtime_manifest.json":"0aa52f5007756cd514814c2573747574f2ebb0deb75c1214b37aabd025ddf9e7",
	"res://data/scenes/luoyang_gate_fortification_candidates/ch4_s0_luoyang_gate.tres":"c05d6c49c4a2a4041c146dd080c77b065051d6f4fabe479079eb0ae740c464c1",
	"res://data/maps/luoyang_gate_fortification_candidates/ch4_s0_luoyang_gate_layout.tres":"c04f70fb429addcc65da1803f6afb2c81edc42ec17ff1c98ff1a026bbf080167",
	"res://art/maps/luoyang_gate_fortification_v1/floor.png":"adb3a8dd26e7d3ba5ad6301f27a54d9d9d4fcb2ca940163571e2a39e8921b00e",
	"res://art/maps/luoyang_gate_fortification_v1/walk.png":"d9a14f7a604d0dd31e0f250c9b4539920aaf4bdbf5c7eda809457cc266991df0",
	"res://tests/test_luoyang_four_city_key_smoke_20261012.gd":"65508b636a699dad0cdd73543aea02a06b9730979666191d570e5fe13cab0ba5",
	"res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd":"6ad7b6be15fd23ea4f8356c111c5a5a6c54c8e1ec7496083597d01e904711c62",
	"res://tests/helpers/v15_field_raw_oracle.gd":"dc36f4144496477508f9ad8b346f846043db109415760ab87205fa814aad26fb",
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://scripts/field/player.gd":"9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419",
	"res://scripts/autoload/scene_router.gd":"a51f2b769cca1d9541a890c5b31ef75fd240fcb7f70bad1b8e401b117ea0cbff",
	"res://scripts/autoload/platform_bridge.gd":"eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a",
	"res://scripts/autoload/save_manager.gd":"67c06cd14d6a7c0bbfd7467bbaae84f906aad57b19cabc0902baf80eb3aff7d9",
}
const GATE_ID := "ch4_s0_luoyang_gate"
const YAMEN_ID := "ch4_s1_luoyang_yamen"
var packet: Dictionary = {}
var manifest: Dictionary = {}
var polygons: Array[PackedVector2Array] = []
var mask: Image
var expected_rows := 9
var weak_runtime: WeakRef
var viewport_ids: Array[int] = []
var initial_arrival := true

func _wait_field(id: String) -> bool:
	var end: int = mini(deadline,Time.get_ticks_msec()+(90000 if initial_arrival else 30000))
	initial_arrival = false
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
		return true
	return _check(false,"bounded live Field arrival " + id)

func _values(value: Variant) -> Variant:
	if value is Vector2 or value is Vector2i: return [value.x,value.y]
	if value is Rect2: return [value.position.x,value.position.y,value.size.x,value.size.y]
	if value is Transform2D: return [value.x.x,value.x.y,value.y.x,value.y.y,value.origin.x,value.origin.y]
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_values(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _values(value[key])
		return result
	return value

func _sources_gate() -> bool:
	manifest = GATE.runtime_manifest()
	if not _check(not manifest.is_empty(), "actual published manifest, no pending oracle"): return false
	var original_reader: RefCounted = RAW.new()
	var original: Dictionary = original_reader.call("independent_record", StringName(GATE_ID))
	original_reader.call("release")
	if not _check(not original.is_empty(), "independently read complete original V11 record"): return false
	packet = GATE.read_after_original(original)
	if not _check(packet.get("record") is Dictionary and not packet.has("error"), "third-layer exact capture/source/OFF/gameplay composition"): return false
	var record: Dictionary = packet.record
	_check(record.gameplay_slots == manifest.gameplay_slots and record.routes == manifest.routes and record.objects == manifest.objects, "actual publication objects/three routes/original gameplay equal")
	rows.append({"kind":"BOUND_SOURCE", "manifest_sha":GATE.MANIFEST_SHA, "author_sha":GATE.AUTHOR_SHA, "object_count":record.objects.size(), "route_count":record.routes.size(), "slots":record.gameplay_slots})
	return failures == 0

func _bind() -> bool:
	if oracle != null: oracle.call("release")
	polygons.clear(); mask = null
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	if scene == null: return _check(false, "real current SceneScript")
	if String(scene.scene_id) != GATE_ID:
		oracle = RAW.new()
		if not _check(String(scene.scene_id) == YAMEN_ID and bool(oracle.call("configure_city", scene, true)), "unchanged Yamen independent reader"): return false
		mask = Image.load_from_file(scene.map_layout.walkable_mask_path)
		for solid: Dictionary in oracle.get("solids"):
			if solid.kind == "exact_world_polygon": polygons.append(solid.polygon)
			else:
				var rect: Rect2 = solid.rect
				polygons.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
		return _check(mask != null, "Yamen actual mask")
	if not _check(GATE.bound(scene) and scene.background_path == packet.record.ground_path and scene.map_layout.walkable_mask_path == packet.record.walk_path, "actual Gate Field metadata and published paths"): return false
	var declarations: Array[Dictionary] = []
	for object: Dictionary in packet.record.objects:
		var shapes: Array[PackedVector2Array] = []
		var extent := Vector2(object.collision_size_px[0],object.collision_size_px[1])
		if extent.x > 0 and extent.y > 0:
			var center := Vector2(object.physical_center_px[0],object.physical_center_px[1])
			var rect := Rect2(center-extent*.5,extent)
			shapes.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
		for value: Array in object.solid_polygons_px:
			var polygon := PackedVector2Array()
			for pair: Array in value: polygon.append(Vector2(pair[0], pair[1]))
			if not _check(polygon.size() >= 3 and not Geometry2D.triangulate_polygon(polygon).is_empty(), "published finite polygon " + String(object.id)): return false
			shapes.append(polygon)
		for polygon: PackedVector2Array in shapes: polygons.append(polygon)
		if not shapes.is_empty(): declarations.append({"id":object.id,"solid_polygons_px":shapes})
	var owned: Resource = scene.map_layout.duplicate(true)
	owned.set("visual_objects", declarations)
	oracle = SIMPLE_RAW.new()
	var good: bool = bool(oracle.call("configure", owned, "round_world_pixel", 0.0))
	owned = null
	mask = Image.load_from_file(packet.record.walk_path)
	var state: Dictionary = field.call("get_gate_fortification_state")
	return _check(good and mask != null and mask.get_size() == Vector2i(3072,2048) and state.get("configured") == true and state.get("manifest_sha") == GATE.MANIFEST_SHA, "real Gate runtime plus independent polygon/full17 oracle")

func _body_raw(p: Vector2) -> bool:
	if mask == null or not p.is_finite(): return false
	var rect := Rect2(p - Vector2(17,12), Vector2(34,24))
	if rect.position.x < 0 or rect.position.y < 0 or roundi(rect.end.x) >= mask.get_width() or roundi(rect.end.y) >= mask.get_height(): return false
	for y: int in range(roundi(rect.position.y), roundi(rect.end.y)+1):
		for x: int in range(roundi(rect.position.x), roundi(rect.end.x)+1):
			var color: Color = mask.get_pixel(x,y)
			if color.a < .5 or color.r < .5: return false
	var body := PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	for polygon: PackedVector2Array in polygons:
		if not Geometry2D.intersect_polygons(body,polygon).is_empty(): return false
	return true

func _clear(p: Vector2) -> bool:
	return Time.get_ticks_msec() < deadline and _body_raw(p) and oracle != null and bool(oracle.call("clear",p)) and _physical(p)

func _move(p: Vector2) -> Dictionary:
	var path: PackedVector2Array = driver.call("plan", (field.get("_player") as Node2D).position, p, field.get("_world_size"), _clear, _segment)
	return await driver.call("follow",field,path,_clear,_segment)

func _capture_gate(name: String) -> Dictionary:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = output + name + ".png"
	var good: bool = image != null and not image.is_empty() and image.save_png(path) == OK
	_check(good,"actual Field GPU capture " + name)
	return {"path":path,"sha256":FileAccess.get_sha256(path) if good else "", "size":image.get_size() if image != null else Vector2i.ZERO}

func _stop_case(label: String, start: Vector2, forbidden: Vector2, action: String) -> void:
	var approach: Dictionary = await _move(start)
	if not _check(approach.get("ok") == true,"normal input reaches " + label + " safe side"): return
	var bad_raw: bool = not _body_raw(forbidden) and not bool(oracle.call("clear",forbidden))
	var bad_physics: bool = not _physical(forbidden)
	var player: Node2D = field.get("_player") as Node2D
	var held: Node = field
	var feet: Array = []
	var all_clear: bool = true
	Input.action_press(action,1.0)
	for tick: int in 45:
		await physics_frame
		if not is_instance_valid(held) or current_scene != held or not is_instance_valid(player) or held.get("_player") != player:
			all_clear = false; break
		feet.append([player.position.x,player.position.y]); all_clear = all_clear and _clear(player.position)
	driver.call("release_movement")
	await driver.call("completed_actor_stage")
	var end: Vector2 = player.position if is_instance_valid(player) else Vector2(INF,INF)
	var stopped: bool = all_clear and end.is_finite() and end.distance_to(forbidden) > 17 and end.distance_to(start) < 65
	_check(bad_raw and bad_physics and stopped,"actual " + label + " stops while every recorded 875/full17/Physics remains clear")
	rows.append({"kind":label,"approach":approach,"forbidden":forbidden,"raw_denied":bad_raw,"Physics_denied":bad_physics,"normal_input":action,"physics_feet":feet,"all_actual_clear":all_clear,"actual_end":end,"stopped":stopped})

func _trip(mode: String) -> void:
	var departure := Vector2(1536,500)
	var driven: Dictionary = await _move(departure)
	if not _check(driven.get("ok") == true,"normal Gate approach " + mode): return
	var old_runtime: RefCounted = field.get("_gate_moat_runtime") as RefCounted
	weak_runtime = weakref(old_runtime)
	var state: Dictionary = field.call("get_gate_fortification_state")
	viewport_ids = [int(state.reflection_viewport_id),int(state.water_viewport_id)]
	old_runtime = null
	var source_player: Node2D = field.get("_player") as Node2D
	var source_foot: Vector2 = source_player.position
	var zone: Node
	for item: Node in field.get("_exit_nodes"):
		if String(item.get("target_scene_id")) == YAMEN_ID: zone = item
	if not _check(zone != null and bool(zone.get("_in_range")),"real authored enter_luoyang overlap"): return
	if mode == "space": await driver.call("key",KEY_SPACE)
	else: await driver.call("pointer",(field.get("world_container") as Node2D).get_global_transform_with_canvas()*departure)
	if not await _wait_field(YAMEN_ID) or not _bind(): return
	var released: bool = weak_runtime.get_ref() == null and not is_instance_id_valid(viewport_ids[0]) and not is_instance_id_valid(viewport_ids[1])
	_check(released,"old Gate module and both GPU viewports released on real Yamen transition")
	var reverse: Node
	for item: Node in field.get("_exit_nodes"):
		if String(item.get("target_scene_id")) == GATE_ID: reverse = item
	if not _check(reverse != null,"original real Yamen reverse exit"): return
	var target: Vector2 = reverse.position
	var back: Dictionary = await _move(target)
	if not _check(back.get("ok") == true and bool(reverse.get("_in_range")),"normal Yamen reverse approach"): return
	if mode == "space": await driver.call("key",KEY_SPACE)
	else: await driver.call("pointer",(field.get("world_container") as Node2D).get_global_transform_with_canvas()*target)
	if not await _wait_field(GATE_ID) or not _bind(): return
	var returned: Vector2 = (field.get("_player") as Node2D).position
	_check(returned.distance_to(source_foot) < .03 and _clear(returned),"actual remembered Gate departure foot preserved by normal reverse input")
	rows.append({"kind":"NORMAL_INPUT_ROUND_TRIP","mode":mode,"source_foot":source_foot,"approach":driven,"reverse_approach":back,"actual_return":returned,"old_module_released":released,"router_shortcut_used":false})

func _exercise_gate() -> void:
	if not _sources_gate(): return
	if not _check(bool(root.get_node("SceneRouter").call("go_field_smart",StringName(GATE_ID),null,"",-1,3)),"public actual candidate startup"): return
	if not await _wait_field(GATE_ID) or not _bind(): return
	var player: Node2D = field.get("_player") as Node2D
	_check(player.position.distance_to(Vector2(1536,1860)) < .03 and _clear(player.position),"original Gate actual spawn1860 full875/17/Physics")
	rows.append({"kind":"REAL_GATE_SPAWN","position":player.position,"raw17":oracle.call("foot_evidence",player.position),"raw875":_body_raw(player.position),"Physics":_physical(player.position),"runtime":field.call("get_gate_fortification_state")})
	var bridge: Dictionary = await _move(Vector2(1536,560))
	_check(bridge.get("ok") == true,"normal bridge deck INPUT from south to north with fullbody/Physics")
	rows.append({"kind":"BRIDGE_DECK","input":bridge})
	if failures != 0: return
	await _stop_case("WATER_RAIL_STOP",Vector2(1536,760),Vector2(1450,760),"move_left")
	if failures != 0: return
	await _stop_case("WALL_STOP",Vector2(1100,540),Vector2(1100,470),"move_up")
	if failures != 0: return
	var deck: Sprite2D = field.find_child("SceneObject_gate_bridge_deck",true,false) as Sprite2D
	var rails: Array = []
	for index: int in 8:
		var rail: Sprite2D = field.find_child("SceneObject_gate_bridge_rail_%d" % index,true,false) as Sprite2D
		_check(rail != null and rail.texture is AtlasTexture,"actual local bridge rail atlas strip")
		if rail != null: rails.append({"id":index,"z":rail.z_index,"position":rail.position,"atlas_region":(rail.texture as AtlasTexture).region})
	_check(deck != null and deck.z_index == 0 and packet.record.objects.filter(func(o: Dictionary)->bool: return o.id == "gate_bridge_deck" and o.ghost_occlusion == false and o.gate_sort_by_feet == false).size() == 1,"entire bridge deck never ghost/depth-foot960")
	rows.append({"kind":"LOCAL_RAIL_STRIPS_NOT_FULL_ALPHA_PROOF","rails":rails,"deck_z":deck.z_index if deck != null else -999,"full_rgba_or_tie_tested":false})
	for mode: String in ["space","mouse"]:
		await _trip(mode)
		if failures != 0: return
	var module: RefCounted = field.get("_gate_moat_runtime") as RefCounted
	var state: Dictionary = module.call("get_debug_state")
	var water: SubViewport = instance_from_id(int(state.water_viewport_id)) as SubViewport
	var origin_before: Transform2D = (water.get_child(0) as Node2D).global_transform
	var scroll_before: Transform2D = (field.get("world_container") as Node2D).global_transform
	var first_png: Dictionary = await _capture_gate("gate_south")
	var moved: Dictionary = await _move(Vector2(1536,760))
	var scroll_after: Transform2D = (field.get("world_container") as Node2D).global_transform
	var origin_after: Transform2D = (water.get_child(0) as Node2D).global_transform
	_check(moved.get("ok") == true and scroll_after != scroll_before and origin_after == origin_before,"actual Field scroll changes but isolated water world coordinate transform stays exact")
	var second_png: Dictionary = await _capture_gate("gate_bridge")
	weak_runtime = weakref(module); viewport_ids = [int(state.reflection_viewport_id),int(state.water_viewport_id)]; module = null; water = null
	rows.append({"kind":"REAL_SCROLL_WORLD_UV","movement":moved,"world_before":scroll_before,"world_after":scroll_after,"water_before":origin_before,"water_after":origin_after,"captures":[first_png,second_png],"natural_TIME_only":true})

func _run() -> void:
	var platform: Node = root.get_node("PlatformBridge")
	platform.call("set_checkpoint_saves_suspended",true)
	_check(platform.call("is_checkpoint_saves_suspended") == true,"checkpoint held before first await")
	players_before = _players(); prior_slot = int(root.get_node("SaveManager").get("active_slot"))
	prior_navigation = (root.get_node("SceneRouter").call("get_navigation_state") as Dictionary).duplicate(true)
	output = "res://build/joint_world_luoyang_20261003_qa/gate_fortification_field_key_%d_%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK,"new output")
	_check(SOURCE_READY and "--luoyang-gate-field-key" in OS.get_cmdline_user_args() and GATE.FLAG in OS.get_cmdline_user_args() and "--luoyang-v3-candidate" in OS.get_cmdline_user_args() and "--luoyang-enclosure-v11-candidate" in OS.get_cmdline_user_args(),"frozen explicit finite candidate flags")
	for path: String in CURRENT_PINS:
		source_before[path] = _file(path)
		_check(source_before[path].sha256 == CURRENT_PINS[path],"exact executed source " + path)
	source_before[get_script().resource_path] = _file(get_script().resource_path)
	for path: String in GATE.source_paths(): source_before[path] = _file(path)
	driver = INPUT_DRIVER.new(); driver.call("configure",self)
	deadline = Time.get_ticks_msec()+270000
	if failures == 0:
		for id: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(id).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		await _exercise_gate()
	if oracle != null: _check(bool(oracle.call("verify_sources")),"raw source unchanged"); oracle.call("release"); oracle = null
	mask = null; polygons.clear(); packet.clear(); manifest.clear()
	if driver != null: driver.call("release"); driver = null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene = null
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	await process_frame; await process_frame
	if weak_runtime != null: _check(weak_runtime.get_ref() == null and not is_instance_id_valid(viewport_ids[0]) and not is_instance_id_valid(viewport_ids[1]),"final module/viewport release")
	root.get_node("SceneRouter").call("restore_navigation_state",prior_navigation,&"world_map_jianghu",&"world_map_jianghu")
	_check(_sources() == source_before and _players() == players_before and root.get_node("SaveManager").get("active_slot") == prior_slot,"source15/slot unchanged; exactticks outer root")
	_check(rows.size() == expected_rows,"nine limited case receipts, no full-six")
	var result: Dictionary = {"scope":"REAL_GATE_FORTIFICATION_GEOMETRY_TWO_PORTAL_ROUNDTRIPS_NOT_SIX","complete":failures == 0,"checks":checks,"failures":failures,"records":rows,"source_before":source_before,"source_after":_sources(),"players_before":players_before,"players_after":_players(),"audio_driver":AudioServer.get_driver_name(),"audio_credit":false,"NPC_dialogue_tested":false,"full_rgba_occlusion_tested":false,"formal_approved":false}
	var file: FileAccess = FileAccess.open(output+"result.json",FileAccess.WRITE)
	_check(file != null,"write final evidence")
	if file != null: file.store_string(JSON.stringify(_values(result),"\t")); file.close()
	print("GATE_FIELD_KEY_RESULT="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures == 0 else 1)
