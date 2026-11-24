extends "res://tests/test_world_v15_key_map_smoke_20261012.gd"
## Limited source-passage fixtures plus four genuine doorway input round trips.
## Public world placement is setup, not continuous travel across all 16 cities.
const EXIT = preload("res://scenes/exit_zone.tscn")
const PLAYER = preload("res://scenes/player.tscn")
const ZONE = preload("res://scripts/field/world_v15_exit_zone.gd")
var fixture_count := 0
var trip_count := 0

func _wait_named(id: StringName) -> bool:
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if bool(root.get_node("LoadingManager").get("_transition_active")): continue
		var actual := current_scene
		if not is_instance_valid(actual) or actual.scene_file_path != "res://scenes/field_walkable.tscn" or bool(actual.get("_scene_rebuilding")): continue
		var scene := actual.get("_current_scene") as SceneScript
		var player := actual.get("_player") as Node2D
		if scene == null or scene.scene_id != id or not is_instance_valid(player): continue
		field = actual
		await driver.call("completed_actor_stage")
		return current_scene == actual and is_instance_valid(player)
	return _check(false, "bounded real Field arrival " + String(id))

func _finish_dialogs() -> bool:
	var deadline := Time.get_ticks_msec() + 30000
	while bool(root.get_node("DialogPlayer").call("is_playing")) and Time.get_ticks_msec() < deadline:
		await driver.call("key", KEY_SPACE)
	return _check(not bool(root.get_node("DialogPlayer").call("is_playing")), "normal input finishes any entry dialogue")

func _fixture_passages() -> void:
	var holder := Node2D.new()
	holder.visible = false
	root.add_child(holder)
	var player := PLAYER.instantiate() as Player
	holder.add_child(player)
	for portal: Dictionary in definition.map_layout.portals:
		var zone := EXIT.instantiate() as ExitZone
		zone.set_script(ZONE)
		zone.target_scene_id = String(portal.target_scene)
		holder.add_child(zone)
		zone.position = portal.pos * WORLD.SIZE
		zone.call("configure_doorway", portal.passage_polygon_px, player, func(p: Vector2) -> bool: return oracle.call("clear", p))
		zone.configure_marker(zone.position, WORLD.SIZE, Vector2.ZERO)
		var near: Vector2 = portal.passage_path_px[0]
		player.position = near
		var near_raw: bool = oracle.call("clear", near)
		var near_ready: bool = zone.call("can_enter")
		_check(near_raw and near_ready, "source passage near point ready " + String(portal.id))
		zone.is_locked = true
		var locked_ready: bool = zone.call("can_enter")
		_check(not locked_ready, "locked doorway not ready " + String(portal.id))
		zone.is_locked = false
		player.position = zone.position + Vector2(240, 160)
		var far_ready: bool = zone.call("can_enter")
		_check(not far_ready and not zone.try_interact(), "far point cannot remotely enter " + String(portal.id))
		var refused_nav: bool = false
		player.position = near
		zone.call("configure_doorway", portal.passage_polygon_px, player, func(_p: Vector2) -> bool: return false)
		refused_nav = not bool(zone.call("can_enter"))
		_check(refused_nav, "unsafe-foot callback blocks entrance " + String(portal.id))
		rows.append({"kind": "SOURCE_PASSAGE_FIXTURE_NOT_FIELD_PORTAL", "id": portal.id, "near": near, "near_raw17": near_raw, "near_ready": near_ready, "locked_ready": locked_ready, "far_ready": far_ready, "unsafe_foot_refused": refused_nav})
		fixture_count += 1
		holder.remove_child(zone)
		zone.queue_free()
	holder.queue_free()
	await process_frame
	await process_frame

func _trip(portal: Dictionary, mode: String) -> void:
	var start: Vector2 = portal.passage_path_px[0]
	if not _check(bool(root.get_node("SceneRouter").call("go_field_smart", ID, start / WORLD.SIZE, "", 15)), "public source doorstep setup " + String(portal.id)): return
	if not await _wait_named(ID): return
	var source_field := field
	var player := field.get("_player") as Node2D
	var destination: Vector2 = portal.pos * WORLD.SIZE
	var driven: Dictionary = await driver.call("drive", field, destination, _clear)
	if not _check(driven.get("ok") == true, "real approach input raw17/Physics " + String(portal.id)): return
	var selected: ExitZone
	for zone: ExitZone in field.get("_exit_nodes"):
		if zone.target_scene_id == String(portal.target_scene): selected = zone
	if not _check(selected != null and bool(selected.call("can_enter")), "actual Field entrance ready " + String(portal.id)): return
	await driver.call("completed_actor_stage")
	var glow: ShaderMaterial = selected.marker_visual.material as ShaderMaterial
	_check(glow != null and glow.get_shader_parameter("pulse") == 1.0, "actual ready arrow uses existing outline")
	await _capture(String(portal.id) + "_" + mode + "_ready")
	var actual_input: Dictionary = {}
	if mode == "space": await driver.call("key", KEY_SPACE)
	else: actual_input = await driver.call("pointer", selected.marker_visual.get_global_transform_with_canvas().origin)
	if not await _wait_named(StringName(portal.target_scene)): return
	if not await _finish_dialogs(): return
	var city_scene := field.get("_current_scene") as SceneScript
	var city_player := field.get("_player") as Node2D
	_check(field != source_field and city_scene.scene_id == StringName(portal.target_scene), "original target entered with " + mode)
	_check(_physical(city_player.position), "actual city arrival Physics clear")
	var reverse: ExitZone
	for zone: ExitZone in field.get("_exit_nodes"):
		if zone.action == "world_map" or zone.target_scene_id == String(ID): reverse = zone; break
	if not _check(reverse != null, "original city has live world reverse exit"): return
	# Normal city movement and Physics only; this is not full city RAW875 credit.
	var city_world := field.get("world_container") as Node2D
	var reverse_point := city_world.to_local(reverse.global_position)
	var return_drive: Dictionary = await driver.call("drive", field, reverse_point, _physical)
	if not _check(return_drive.get("ok") == true, "normal city return approach Physics " + mode): return
	await driver.call("completed_actor_stage")
	if mode == "space": await driver.call("key", KEY_SPACE)
	else: await driver.call("pointer", reverse.marker_visual.get_global_transform_with_canvas().origin)
	if not await _wait_named(ID): return
	player = field.get("_player") as Node2D
	_check(_clear(player.position), "actual world return raw17/Physics clear")
	rows.append({"kind": "NORMAL_INPUT_ROUND_TRIP", "id": portal.id, "mode": mode, "setup_is_not_travel_credit": true, "approach": driven, "input": actual_input, "target": String(city_scene.scene_id), "city_raw875_tested": false, "city_return_approach": return_drive, "return_world_position": player.position})
	trip_count += 1

func _run() -> void:
	var platform := root.get_node("PlatformBridge")
	platform.call("set_checkpoint_saves_suspended", true)
	_check(platform.call("is_checkpoint_saves_suspended") == true, "checkpoint suspended before await")
	normal_files = _players()
	slot = int(root.get_node("SaveManager").get("active_slot"))
	_check("--world-doorway-ready-smoke" in OS.get_cmdline_user_args() and not "--world-v15-candidate" in OS.get_cmdline_user_args(), "explicit limited formal test")
	output = "res://build/joint_world_luoyang_20261003_qa/world_doorway_ready_%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique evidence directory")
	for path: String in [get_script().resource_path, "res://tests/test_world_v15_key_map_smoke_20261012.gd", SOURCE, MANIFEST, OVERVIEW, WORLD.LAYOUT_PATH, WORLD.STREAM_PATH, "res://data/scenes/world_map_jianghu.tres", "res://scripts/field/field_walkable_controller.gd", "res://scripts/field/world_v15_exit_zone.gd", "res://scripts/field/exit_zone.gd", "res://shaders/interaction_outline.gdshader", "res://tests/helpers/v15_input_driver.gd", "res://scripts/autoload/scene_router.gd", "res://project.godot"]:
		first[path] = _file(path)
		_check(first[path].exists, "source exists " + path)
	driver = INPUT_DRIVER.new()
	driver.call("configure", self)
	for id: String in ["GameState", "Inventory", "QuestManager", "BountyManager", "InvestigationState", "SceneRouter"]: root.get_node(id).call("reset_for_new_game")
	definition = load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	oracle = RAW.new()
	_check(definition != null and WORLD.is_v15(definition) and definition.map_layout.portals.size() == 16 and bool(oracle.call("configure", definition.map_layout)), "actual current world source and independent oracle")
	if failures == 0:
		await _fixture_passages()
	if failures == 0:
		for id: String in ["qinghe_town", "luoyang"]:
			for portal: Dictionary in definition.map_layout.portals:
				if String(portal.id) != id: continue
				for mode: String in ["space", "pointer"]:
					await _trip(portal, mode)
					if failures != 0: break
			if failures != 0: break
	if oracle != null: oracle.call("release"); oracle = null
	if driver != null: driver.call("release"); driver = null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene = null
	for shape: int in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	await process_frame
	await process_frame
	var last: Dictionary = {}
	for path: String in first: last[path] = _file(path)
	_check(first == last and normal_files == _players() and root.get_node("SaveManager").get("active_slot") == slot, "sources and player15/slot unchanged")
	_check(fixture_count == 16 and trip_count == 4, "16 limited source fixtures and four actual round trips")
	var result := {"scope": "WORLD16_PASSAGE_FIXTURES_TWO_TARGETS_TWO_NORMAL_INPUT_ROUND_TRIPS", "complete": failures == 0, "checks": checks, "failures": failures, "records": rows, "source_before": first, "source_after": last, "players_before": normal_files, "players_after": _players(), "audio_credit": false, "full_world_portal_input_tested": false, "formal_full_approval": false}
	var file := FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result, "\t")); file.close()
	print("WORLD_DOORWAY_READY_RESULT=" + output + "result.json failures=" + str(failures))
	quit(0 if failures == 0 else 1)
