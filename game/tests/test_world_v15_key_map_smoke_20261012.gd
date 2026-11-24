extends SceneTree
## Map-only key smoke for the user-approved formal playtest. No city, full-world
## object regression, old-save migration, battle, save or audio acceptance.
const WORLD = preload("res://scripts/world/world_map_v15_contract.gd")
const RAW = preload("res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd")
const INPUT_DRIVER = preload("res://tests/helpers/v15_input_driver.gd")
const SOURCE = "res://data/maps/world_map_v15_complete_v9c_source.json"
const MANIFEST = "res://art/maps/world_map_v15_complete_v9c/art_contract.json"
const OVERVIEW = "res://art/maps/world_map_v15_complete_v9c/overview.png"
const ID = &"world_map_jianghu"
var checks := 0
var failures := 0
var field: Node
var definition: SceneScript
var oracle: RefCounted
var driver: RefCounted
var output := ""
var first: Dictionary = {}
var normal_files: Dictionary = {}
var slot: int
var rows: Array[Dictionary] = []

func _init() -> void: call_deferred("_run")

func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: failures += 1; push_error("[WORLD KEY MAP FAIL] " + label)
	return ok

func _file(path: String) -> Dictionary:
	var exists: bool = FileAccess.file_exists(path)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ) if exists else null
	return {"exists": exists, "bytes": file.get_length() if file != null else 0, "sha256": FileAccess.get_sha256(path) if exists else "ABSENT", "mtime_seconds": FileAccess.get_modified_time(path) if exists else 0}

func _players() -> Dictionary:
	var result: Dictionary = {}
	for index in 5:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = "user://save_%d.json%s" % [index, suffix]
			result[path] = _file(path)
	return result

func _audio() -> Dictionary:
	var audio: Node = root.get_node("AudioManager")
	var player: AudioStreamPlayer = audio.get("bgm_player") as AudioStreamPlayer
	return {"actual_driver": AudioServer.get_driver_name(), "selected_bgm_path": audio.call("get_current_bgm"), "playing": player != null and player.playing, "audio_tested": false, "audio_credit": false}

func _wait_world() -> bool:
	var deadline: int = Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if bool(root.get_node("LoadingManager").get("_transition_active")): continue
		var actual: Node = current_scene
		if not is_instance_valid(actual) or actual.scene_file_path != "res://scenes/field_walkable.tscn" or actual.is_queued_for_deletion() or not actual.is_inside_tree(): continue
		var scene: SceneScript = actual.get("_current_scene") as SceneScript
		var player: Node2D = actual.get("_player") as Node2D
		if scene == null or String(scene.scene_id) != String(definition.scene_id) or not WORLD.is_v15(scene) or not is_instance_valid(player) or not player.is_inside_tree() or player.is_queued_for_deletion() or bool(actual.get("_scene_rebuilding")): continue
		await driver.call("completed_actor_stage")
		if not is_instance_valid(actual) or current_scene != actual or actual.is_queued_for_deletion() or bool(root.get_node("LoadingManager").get("_transition_active")) or bool(actual.get("_scene_rebuilding")) or not is_instance_valid(player) or actual.get("_player") != player: continue
		field = actual
		return true
	return _check(false, "bounded actual formal world Field arrival")

func _physical(point: Vector2) -> bool:
	if not is_instance_valid(field) or current_scene != field: return false
	var player: CharacterBody2D = field.get("_player") as CharacterBody2D
	var world: Node2D = field.get("world_container") as Node2D
	var shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D if is_instance_valid(player) else null
	if shape == null or shape.disabled or shape.shape == null or world == null: return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	query.transform = shape.global_transform
	query.transform.origin += world.to_global(point) - player.global_position
	query.exclude = [player.get_rid()]
	query.collision_mask = player.collision_mask
	query.collide_with_areas = false
	return player.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _clear(point: Vector2) -> bool:
	return oracle != null and bool(oracle.call("clear", point)) and _physical(point)

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = output + name + ".png"
	_check(image != null and not image.is_empty() and image.save_png(path) == OK, "GPU screenshot " + name)
	rows.append({"kind": "GPU_CAPTURE", "path": path, "sha256": FileAccess.get_sha256(path)})

func _exercise() -> void:
	definition = load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	if not _check(definition != null and WORLD.is_v15(definition) and WORLD.formal_version() == 15, "canonical formal scene actually selects current world15"): return
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	if not _check(source is Dictionary and source.get("chunks") is Array and source.chunks.size() == 64 and source.get("portals") is Array and source.portals.size() == 16, "frozen current64 chunks/16 source portals"): return
	oracle = RAW.new()
	if not _check(bool(oracle.call("configure", definition.map_layout)), "independent current64 navigation and source solids"): return
	var portals: Array = definition.map_layout.portals
	var connections: Array[Dictionary] = []
	for authored: Dictionary in source.portals:
		var matches: Array[Dictionary] = []
		for actual: Dictionary in portals:
			if String(actual.get("id", "")) == String(authored.id): matches.append(actual)
		var valid: bool = matches.size() == 1 and String(matches[0].get("target_scene", "")) == String(authored.target_scene) and FileAccess.file_exists("res://data/scenes/" + String(authored.target_scene) + ".tres")
		_check(valid, "unique original portal connection metadata " + String(authored.id))
		connections.append({"id": authored.id, "target": authored.target_scene, "metadata_valid": valid, "normal_input_tested": false})
	rows.append({"kind": "PORTAL_CONNECTION_METADATA_ONLY", "connections": connections})
	if failures != 0: return
	if not _check(bool(root.get_node("SceneRouter").call("go_field_smart", ID)), "public formal default world startup"): return
	if not await _wait_world(): return
	var player: Node2D = field.get("_player") as Node2D
	_check(_clear(player.position), "actual default world spawn raw17/Physics clear")
	rows.append({"kind": "DEFAULT_FORMAL_SPAWN", "position": [player.position.x, player.position.y], "raw17": oracle.call("foot_evidence", player.position), "Physics_clear": _physical(player.position), "audio": _audio()})
	await _capture("01_formal_default_spawn")
	var bridge: Dictionary = {}
	for structure: Dictionary in source.structures:
		if structure.get("id") == "bridge_00": bridge = structure
	if not _check(not bridge.is_empty() and bridge.get("projected_passage_px") is Array and bridge.projected_passage_px.size() == 2, "original measured bridge00 passage source"): return
	var a := Vector2(float(bridge.projected_passage_px[0][0]), float(bridge.projected_passage_px[0][1]))
	var b := Vector2(float(bridge.projected_passage_px[1][0]), float(bridge.projected_passage_px[1][1]))
	# Explicit public test setup, NOT credit for travelling from default spawn.
	if not _check(bool(root.get_node("SceneRouter").call("go_field_smart", ID, a / WORLD.SIZE, "", 15)), "public current15 bridge setup only"): return
	if not await _wait_world(): return
	player = field.get("_player") as Node2D
	if not _check(player.position.distance_to(a) < .02 and _clear(player.position), "actual bridge start matches source/setup/raw17/Physics"): return
	var segment: Callable = func(from: Vector2, to: Vector2) -> Dictionary:
		var count: int = maxi(1, ceili(from.distance_to(to) / 4))
		for index in range(count + 1):
			if not _clear(from.lerp(to, float(index) / count)): return {"clear": false, "index": index}
		return {"clear": true, "centers": count + 1}
	var driven: Dictionary = await driver.call("follow", field, PackedVector2Array([a, b]), _clear, segment)
	_check(driven.get("ok") == true, "one original bridge passage normal INPUT/raw17/Physics")
	rows.append({"kind": "BRIDGE00_NORMAL_INPUT", "setup_is_not_input_credit": true, "source_path": SOURCE, "drive": driven, "audio": _audio()})
	await _capture("02_bridge00_actual_field")
	# Frozen full-world ROOT250 asset shown by real GPU, not an all-object Field proof.
	var texture: Texture2D = load(OVERVIEW) as Texture2D
	if not _check(texture != null, "frozen whole64 overview display texture"): return
	var layer := CanvasLayer.new()
	layer.layer = 100
	var view := TextureRect.new()
	view.texture = texture
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.size = root.get_visible_rect().size
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(view)
	root.add_child(layer)
	await _capture("03_root250_whole_asset_gpu_display_not_full_field")
	layer.queue_free()

func _run() -> void:
	var bridge: Node = root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended", true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true, "public checkpoint suspension before first await")
	normal_files = _players()
	slot = int(root.get_node("SaveManager").get("active_slot"))
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_check("--world-key-map-smoke" in args and not "--world-v15-candidate" in args and not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args, "explicit map smoke/formal no candidate flags")
	output = "res://build/joint_world_luoyang_20261003_qa/world_key_map_smoke_%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique map evidence")
	for path: String in [get_script().resource_path, SOURCE, MANIFEST, OVERVIEW, WORLD.LAYOUT_PATH, WORLD.STREAM_PATH, WORLD.CANDIDATE_PATH, "res://data/scenes/world_map_jianghu.tres", "res://scripts/world/world_map_v15_contract.gd", "res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd", "res://tests/helpers/v15_raw_world_oracle.gd", "res://tests/helpers/v15_input_driver.gd", "res://scripts/field/field_walkable_controller.gd", "res://scripts/autoload/scene_router.gd", "res://scripts/autoload/platform_bridge.gd", "res://project.godot"]:
		first[path] = _file(path)
		_check(first[path].exists, "current consumed map source exists " + path)
	_check(first[SOURCE].sha256.to_lower() == "85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f" and first[MANIFEST].sha256.to_lower() == "1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a" and first[OVERVIEW].sha256.to_lower() == "bcfb11f3fb026ad9c1ed5647da7553514a25fdd5a77bc52dc3be25f19a3909b8", "exact ROOT250 current source/manifest/overview binding")
	driver = INPUT_DRIVER.new()
	driver.call("configure", self)
	if failures == 0:
		for id: String in ["GameState", "Inventory", "QuestManager", "BountyManager", "InvestigationState", "SceneRouter"]: root.get_node(id).call("reset_for_new_game")
		await _exercise()
	if oracle != null: oracle.call("release"); oracle = null
	driver.call("release"); driver = null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene = null
	for shape: int in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	await process_frame
	await process_frame
	var last: Dictionary = {}
	for path: String in first: last[path] = _file(path)
	_check(first == last and normal_files == _players() and root.get_node("SaveManager").get("active_slot") == slot and bridge.call("is_checkpoint_saves_suspended") == true, "current source/player15/slot/checkpoint retained")
	var result: Dictionary = {"scope": "FORMAL_WORLD15_MAP_KEY_SMOKE_REST_USER_PLAYTEST", "complete": failures == 0 and rows.size() == 6, "checks": checks, "failures": failures, "records": rows, "source_before": first, "source_after": last, "players_before": normal_files, "players_after": _players(), "audio": _audio(), "city_tested": false, "full_world_objects_tested": false, "audio_tested": false, "audio_credit": false, "historical_compatibility_tested": false, "save_read_tested": false, "formal_full_approval": false, "fresh_outer_import_and_UTC_ticks_guard_required": true, "stderr_requires_root_review_audio_init_failures_retained": true, "output": output}
	_check(rows.size() == 6, "default spawn/bridge/connection metadata/three GPU captures complete")
	result.checks = checks
	result.failures = failures
	var file: FileAccess = FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result, "\t")); file.close()
	_check(file != null and JSON.parse_string(FileAccess.get_file_as_string(output + "result.json")) is Dictionary, "map result read back")
	print("WORLD_KEY_MAP_SMOKE_RESULT=" + output + "result.json failures=" + str(failures))
	quit(0 if failures == 0 else 1)
