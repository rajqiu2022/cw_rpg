extends "res://tests/test_world_v15_key_map_smoke_20261012.gd"
## Finite HUD/input check, not a repeat of world geometry or audio acceptance.
const MINIMAP_TEST = preload("res://scripts/ui/world_travel_minimap.gd")
var owned_minimap: Control

func fixture_sources() -> Array[String]:
	var paths: Array[String] = [get_script().resource_path, "res://tests/test_world_v15_key_map_smoke_20261012.gd", "res://scripts/ui/world_travel_minimap.gd", "res://scripts/field/field_walkable_controller.gd", "res://scripts/ui/field_primary_hud.gd", "res://scenes/ui/field_primary_hud.tscn", "res://scripts/world/world_map_v15_contract.gd", "res://scripts/autoload/scene_router.gd", "res://scripts/autoload/platform_bridge.gd", "res://scripts/autoload/audio_manager.gd", "res://scripts/domain/scene_script.gd", "res://scripts/domain/walkable_map_layout.gd", "res://scripts/field/player.gd", "res://scenes/player.tscn", "res://scenes/field_walkable.tscn", "res://tests/helpers/v15_input_driver.gd", "res://project.godot", "res://data/scenes/world_map_jianghu.tres", WORLD.LAYOUT_PATH, WORLD.STREAM_PATH, MINIMAP_TEST.OVERVIEW_PATH, MINIMAP_TEST.FRAME_PATH]
	# Import sidecars and their actual compiled destinations, not a world graph scan.
	for asset: String in [MINIMAP_TEST.OVERVIEW_PATH, MINIMAP_TEST.FRAME_PATH]:
		paths.append(asset + ".import")
		var config := ConfigFile.new()
		if config.load(asset + ".import") != OK: continue
		if config.has_section_key("remap", "path"):
			var path: Variant = config.get_value("remap", "path")
			if path is String and not path.is_empty() and not paths.has(path): paths.append(path)
		if config.has_section_key("deps", "dest_files"):
			for path: String in config.get_value("deps", "dest_files"):
				if not paths.has(path): paths.append(path)
	return paths

func _values(value: Variant) -> Variant:
	if value is Vector2: return [value.x, value.y]
	if value is Rect2: return {"position": _values(value.position), "size": _values(value.size)}
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _values(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_values(item))
		return result
	return value

func _settle() -> void:
	for index in 4: await process_frame
	await RenderingServer.frame_post_draw

func _live_map() -> Control:
	return field.get_node_or_null("HudCanvasLayer/FieldPrimaryHud/WorldTravelMinimap") as Control if is_instance_valid(field) else null

func _map_check(label: String) -> Dictionary:
	var minimap: Control = _live_map()
	if not _check(minimap != null and minimap.get_script().resource_path == "res://scripts/ui/world_travel_minimap.gd", label + " actual HUD module"): return {}
	var state: Dictionary = minimap.call("get_debug_state")
	var panel: Rect2 = state.panel_rect
	var map_rect: Rect2 = state.map_rect
	var viewport: Rect2 = root.get_visible_rect()
	_check(state.configured == true and state.visible == true and state.scene_id == String(definition.scene_id), label + " visible formal world binding")
	_check(state.mouse_filter == Control.MOUSE_FILTER_IGNORE and minimap.mouse_filter == Control.MOUSE_FILTER_IGNORE and minimap.focus_mode == Control.FOCUS_NONE, label + " ignores mouse and keyboard focus")
	_check(panel.size.x > 0 and panel.size.y > 0 and viewport.encloses(panel) and panel.encloses(map_rect), label + " panel/image stay inside actual viewport")
	var dimensions := Vector2(definition.map_layout.design_size)
	_check(state.world_size == dimensions and absf(map_rect.size.x / map_rect.size.y - dimensions.x / dimensions.y) < .00001, label + " aspect-fit does not distort map")
	var seen: Dictionary = {}
	for marker: Dictionary in state.portals:
		var matches: Array[Dictionary] = []
		for portal: Dictionary in definition.map_layout.portals:
			if String(portal.id) == marker.id: matches.append(portal)
		var valid: bool = matches.size() == 1 and not seen.has(marker.id)
		if valid:
			var authored: Dictionary = matches[0]
			var expected: Vector2 = map_rect.position + authored.pos * map_rect.size
			valid = marker.uv == authored.pos and marker.target_scene == String(authored.target_scene) and marker.marker.distance_to(expected) < .001
		_check(valid, label + " independent portal mapping " + String(marker.id))
		seen[marker.id] = true
	_check(state.portals.size() == 16 and seen.size() == 16, label + " original sixteen markers exactly once")
	var player: Node2D = field.get("_player") as Node2D
	var world: Node2D = field.get("world_container") as Node2D
	var foot: Vector2 = player.global_position
	foot.y = float(player.call("get_depth_sort_y"))
	var expected_world: Vector2 = world.to_local(foot)
	var expected_marker: Vector2 = map_rect.position + expected_world / dimensions * map_rect.size
	_check(state.player_world.distance_to(expected_world) < .001 and state.player_marker.distance_to(expected_marker) < .001 and state.direction == String(player.get("_direction")), label + " actual player foot/direction follows map")
	var view: Rect2 = state.view_rect
	_check(view.size.x > 0 and view.size.y > 0 and map_rect.grow(.001).encloses(view), label + " camera view remains within map")
	rows.append({"kind": "MINIMAP_STATE", "label": label, "viewport": _values(viewport), "state": _values(state)})
	return state

func _exercise() -> void:
	definition = load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	if not _check(definition != null and WORLD.is_v15(definition) and WORLD.formal_version() == 15, "formal current world15 no candidate selection"): return
	if not _check(bool(root.get_node("SceneRouter").call("go_field_smart", ID)), "public default world startup"): return
	if not await _wait_world(): return
	await _settle()
	var before: Dictionary = _map_check("1080_default")
	var player: Node2D = field.get("_player") as Node2D
	var start: Vector2 = player.position
	var target: Vector2 = start + Vector2(0, 80)
	var driven: Dictionary = await driver.call("drive", field, target, _physical)
	_check(driven.get("ok") == true and driven.get("reached") == true and driven.get("all_recorded_feet_clear") == true, "eighty pixels downward original normal INPUT/actual body Physics")
	rows.append({"kind": "NORMAL_INPUT", "drive": driven, "nav_geometry_regression_credit": false})
	await _settle()
	var after: Dictionary = _map_check("1080_after_input")
	_check(not before.is_empty() and not after.is_empty() and after.player_marker.y > before.player_marker.y and after.direction == "down", "natural movement changes actual map marker")
	await _capture("01_minimap_1920x1080")
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	await _settle()
	if not await _wait_world(): return
	await _settle()
	_check(root.get_visible_rect().size == Vector2(1280, 720), "actual root content is 1280x720")
	_map_check("720_resize")
	await _capture("02_minimap_1280x720")
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = Vector2i(1920, 1080)
	await _settle()
	if not await _wait_world(): return
	await _settle()
	_check(root.get_visible_rect().size == Vector2(1920, 1080), "restored actual root content 1080p")
	_map_check("1080_restored")
	# Independent owned HUD only; never reconfigure/refresh the production HUD.
	owned_minimap = MINIMAP_TEST.new()
	root.add_child(owned_minimap)
	player = field.get("_player") as Node2D
	var camera: Camera2D = field.get("_world_camera") as Camera2D
	var world: Node2D = field.get("world_container") as Node2D
	_check(bool(owned_minimap.call("configure", definition, player, camera, world)), "owned lifecycle world configure")
	_check(bool(owned_minimap.call("configure", definition, player, camera, world)) and owned_minimap.call("get_debug_state").portals.size() == 16, "owned repeat configure does not accumulate markers")
	var city := SceneScript.new()
	city.scene_id = &"ch4_s0_luoyang_gate"
	_check(not bool(owned_minimap.call("configure", city, player, camera, world)), "nonworld rejected")
	var hidden: Dictionary = owned_minimap.call("get_debug_state")
	_check(hidden.configured == false and hidden.visible == false and hidden.portals.is_empty(), "nonworld hides and clears owned HUD")
	_check(bool(owned_minimap.call("configure", definition, player, camera, world)), "owned world reconfigure after nonworld")
	owned_minimap.call("release")
	var released: Dictionary = owned_minimap.call("get_debug_state")
	_check(released.configured == false and released.visible == false and released.portals.is_empty() and not owned_minimap.is_processing(), "owned release hides/clears/stops lifecycle")
	rows.append({"kind": "OWNED_LIFECYCLE", "nonworld": _values(hidden), "released": _values(released), "actual_field_lifecycle_transition_tested": false})
	owned_minimap.free()
	owned_minimap = null

func _run() -> void:
	var bridge: Node = root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended", true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true, "public checkpoint suspended before first await")
	normal_files = _players()
	slot = int(root.get_node("SaveManager").get("active_slot"))
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_check("--world-minimap-smoke" in args and not "--world-v15-candidate" in args and not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args, "explicit formal minimap scope")
	output = "res://build/joint_world_luoyang_20261003_qa/world_travel_minimap_%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique minimap evidence")
	for path: String in fixture_sources():
		first[path] = _file(path)
		_check(first[path].exists, "used HUD source/import exists " + path)
	_check(first["res://scripts/ui/world_travel_minimap.gd"].sha256.to_upper() == "1D4EA7A1A1EBEA46C09F2A3E980C05C75E32C46621B5AA3DD43EC3E5E9F1621D" and first["res://scripts/field/field_walkable_controller.gd"].sha256.to_upper() == "5716BB1467E4811FC8932BE87D05AE815C69B14303C7AA3E42EC0ECF60613488", "frozen minimap module and actual Field hookup")
	driver = INPUT_DRIVER.new()
	driver.call("configure", self)
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	if failures == 0:
		for id: String in ["GameState", "Inventory", "QuestManager", "BountyManager", "InvestigationState", "SceneRouter"]: root.get_node(id).call("reset_for_new_game")
		await _exercise()
	if is_instance_valid(owned_minimap): owned_minimap.call("release"); owned_minimap.free(); owned_minimap = null
	driver.call("release")
	driver = null
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene = null
	for shape: int in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	await process_frame
	await process_frame
	var last: Dictionary = {}
	for path: String in first: last[path] = _file(path)
	_check(first == last and normal_files == _players() and root.get_node("SaveManager").get("active_slot") == slot and bridge.call("is_checkpoint_saves_suspended") == true, "source/player15/slot/checkpoint retained through quit")
	_check(rows.size() == 8, "four map observations/input/two screenshots/owned lifecycle complete")
	var result: Dictionary = {"scope": "WORLD_TRAVEL_MINIMAP_UI_AND_SHORT_INPUT_ONLY", "complete": failures == 0 and rows.size() == 8, "checks": checks, "failures": failures, "records": rows, "audio": _audio(), "audio_tested": false, "approval": false, "full_world_geometry_tested": false, "source_before": first, "source_after": last, "players_before": normal_files, "players_after": _players(), "fresh_outer_exact_UTC_ticks_guard_required": true}
	var file := FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result, "\t")); file.close()
	_check(file != null and JSON.parse_string(FileAccess.get_file_as_string(output + "result.json")) is Dictionary, "minimap result read back")
	print("WORLD_TRAVEL_MINIMAP_RESULT=" + output + "result.json failures=" + str(failures))
	quit(0 if failures == 0 else 1)
