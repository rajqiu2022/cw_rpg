extends SceneTree
## User-narrowed key smoke, reusable with paired candidate flags or neither.
## No six-slot/full gameplay, old-save migration, battle or audio-continuity credit.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const RAW = preload("res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd")
const INPUT_DRIVER = preload("res://tests/helpers/v15_input_driver.gd")
const ISOLATED_SAVE = "res://tests/helpers/v15_isolated_save_manager.gd"
const IDS: Array[String] = ["ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen", "ch4_s2_canal_docks", "ch4_s3_luoyang_market"]
const FIELD_PATH = "res://scripts/field/field_walkable_controller.gd"
const PINNED = {
	FIELD_PATH: "e545834700715e23540a5036ffaeb01e2ba412b62e14f81c5abd7b28a08ee1ed",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd": "cfe8a05491311705d600a607a0de586890d17ac6b5a378afea67065573e51c8a",
	"res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd": "b0c4dbedb0e8f48668a7d191049c5fbd9ae7b2866ea389e1ac2797ae3a0f9e7f",
	"res://scripts/field/player.gd": "9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419",
	"res://scripts/autoload/platform_bridge.gd": "eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a",
	"res://scripts/autoload/scene_router.gd": "f3ead7459632188350e1e3383ee915c83b71c1b86d36dadf718bd338a4324eca",
	"res://scripts/autoload/save_manager.gd": "67c06cd14d6a7c0bbfd7467bbaae84f906aad57b19cabc0902baf80eb3aff7d9",
	"res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd": "6ad7b6be15fd23ea4f8356c111c5a5a6c54c8e1ec7496083597d01e904711c62",
	"res://tests/helpers/v15_input_driver.gd": "a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://tests/helpers/v15_isolated_save_manager.gd": "dab23dd87ee942ed9cd60e97f9cd9441dc8f76aa1f6b310203636a257903e9c6",
}
const ENGINE_SHA = "975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
var checks := 0
var failures := 0
var candidate := false
var boot_only := false
var boot_resources: Array[Dictionary] = []
var output := ""
var field: Node
var oracle: RefCounted
var driver: RefCounted
var slots: Node
var source_before: Dictionary = {}
var players_before: Dictionary = {}
var prior_slot: int
var prior_navigation: Dictionary = {}
var rows: Array[Dictionary] = []
var deadline: int

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> bool:
	checks += 1
	if not value:
		failures += 1
		push_error("[LUOYANG KEY SMOKE FAIL] " + label)
	return value

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

func _write() -> bool:
	var result: Dictionary = {"scope": "LUOYANG_FORMAL_BOOT_ONLY_REST_USER_PLAYTEST" if boot_only else "LUOYANG_FOUR_CITY_KEY_SMOKE_NOT_FULL_SIX", "candidate": candidate, "complete": failures == 0 and rows.size() == (1 if boot_only else 7), "formal_resource_checks": boot_resources, "current_save_read_tested": not boot_only and rows.size() == 7, "checks": checks, "failures": failures, "records": rows, "source_before": source_before, "source_after": _sources(), "players_before": players_before, "players_after": _players(), "active_slot_before": prior_slot, "active_slot_after": root.get_node("SaveManager").get("active_slot"), "checkpoint_held_to_quit": root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"), "actual_audio_driver": AudioServer.get_driver_name(), "audio_continuity_tested": false, "formal_approved": false, "world_full_tested": false, "historical_compatibility_tested": false, "exact_ticks_guard": "ROOT_FRESH_OUTER_REQUIRED", "stderr_acceptance": "ROOT_COMPLETE_ERROR_SCRIPT_AND_EXIT_REVIEW_REQUIRED", "output": output}
	var file: FileAccess = FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	return JSON.parse_string(FileAccess.get_file_as_string(output + "result.json")) is Dictionary

func _sources() -> Dictionary:
	var result: Dictionary = {}
	for path: String in source_before: result[path] = _file(path)
	return result

func _audio() -> Dictionary:
	var manager: Node = root.get_node("AudioManager")
	var player: AudioStreamPlayer = manager.get("bgm_player") as AudioStreamPlayer
	return {"driver": AudioServer.get_driver_name(), "selected_path": manager.call("get_current_bgm"), "playing": player != null and player.playing, "paused": player.stream_paused if player != null else true, "stream_path": player.stream.resource_path if player != null and player.stream != null else ""}

func _wait_field(id: String) -> bool:
	var end: int = mini(deadline, Time.get_ticks_msec() + 30000)
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
	return _check(false, "bounded live Field arrival " + id)

func _physical(p: Vector2) -> bool:
	if not is_instance_valid(field) or field != current_scene: return false
	var player: CharacterBody2D = field.get("_player") as CharacterBody2D
	var world: Node2D = field.get("world_container") as Node2D
	var shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D if is_instance_valid(player) else null
	if shape == null or shape.disabled or shape.shape == null or world == null: return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	query.transform = shape.global_transform
	query.transform.origin += world.to_global(p) - player.global_position
	query.exclude = [player.get_rid()]
	query.collision_mask = player.collision_mask
	query.collide_with_areas = false
	return player.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _clear(p: Vector2) -> bool:
	return Time.get_ticks_msec() < deadline and oracle != null and bool(oracle.call("clear", p)) and _physical(p)

func _segment(a: Vector2, b: Vector2) -> Dictionary:
	var count: int = maxi(1, ceili(a.distance_to(b) / 4))
	for index in range(count + 1):
		if not _clear(a.lerp(b, float(index) / count)): return {"clear": false, "index": index}
	return {"clear": true, "centers": count + 1}

func _bind() -> bool:
	if oracle != null: oracle.call("release")
	oracle = RAW.new()
	var definition: SceneScript = field.get("_current_scene") as SceneScript
	var fade: Dictionary = field.call("get_city_building_fade_debug")
	var runtime: RefCounted = field.get("_v14_modular_overlap") as RefCounted
	var good: bool = field.get_script().resource_path == FIELD_PATH and definition != null and C.is_v3(definition) and definition.has_meta("city_enclosure_manifest_sha") and bool(oracle.call("configure_city", definition, candidate)) and runtime != null and runtime.get_script().resource_path == "res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd" and fade.get("runtime_hooked") == true
	return _check(good, "exact current city runtime/source/independent navigation " + String(definition.scene_id) if definition != null else "missing definition")

func _spawn_row(label: String, capture: bool) -> bool:
	if not _bind(): return false
	var player: Node2D = field.get("_player") as Node2D
	var definition: SceneScript = field.get("_current_scene") as SceneScript
	var audio: Dictionary = _audio()
	var good: bool = _clear(player.position) and audio.driver == "WASAPI" and audio.playing and not audio.paused
	_check(good, "actual spawn 17-shoe/Physics/WASAPI " + label)
	var row: Dictionary = {"kind": label, "scene_id": String(definition.scene_id), "actual_scene_path": definition.resource_path, "layout_path": definition.map_layout.resource_path, "position": [player.position.x, player.position.y], "raw17": oracle.call("foot_evidence", player.position), "Physics_clear": _physical(player.position), "audio": audio, "passed": good}
	if capture:
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		var path: String = output + String(definition.scene_id) + ".png"
		_check(image != null and not image.is_empty() and image.save_png(path) == OK, "actual GPU city screenshot")
		row["capture_path"] = path
		row["capture_sha256"] = FileAccess.get_sha256(path)
	rows.append(row)
	return good

func _portal(target_id: String) -> bool:
	var definition: SceneScript = field.get("_current_scene") as SceneScript
	var source_id: String = String(definition.scene_id)
	var zone: Node
	for item: Node in field.get("_exit_nodes"):
		if String(item.get("target_scene_id")) == target_id and not bool(item.get("is_locked")):
			if zone != null: return _check(false, "unique authored portal")
			zone = item
	if not _check(zone != null, "original live connecting portal " + source_id + " -> " + target_id): return false
	var target: Vector2 = zone.position
	var path: PackedVector2Array = driver.call("plan", (field.get("_player") as Node2D).position, target, field.get("_world_size"), _clear, _segment)
	var driven: Dictionary = await driver.call("follow", field, path, _clear, _segment)
	var zone_path: String = str(zone.get_path()) if is_instance_valid(zone) else "FREED"
	if not _check(driven.get("ok") == true and is_instance_valid(zone) and bool(zone.get("_in_range")), "normal INPUT portal approach raw17/Physics"): return false
	await driver.call("key", KEY_SPACE)
	if not await _wait_field(target_id) or not _bind(): return false
	var player: Node2D = field.get("_player") as Node2D
	var clear: bool = _clear(player.position)
	_check(clear, "normal portal actual target spawn")
	rows.append({"kind": "NORMAL_SPACE_PORTAL", "source": source_id, "target": target_id, "zone_path": zone_path, "drive": driven, "arrival": [player.position.x, player.position.y], "spawn_clear": clear, "router_shortcut_used": false, "passed": clear})
	return clear

func _exercise() -> void:
	if boot_only:
		for id: String in IDS:
			var canonical: String = "res://data/scenes/" + id + ".tres"
			var layout: String = C.layout_path(StringName(id))
			var scene: SceneScript = ResourceLoader.load(canonical, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
			var bound: bool = scene != null and String(scene.scene_id) == id and C.is_v3(scene) and scene.has_meta("city_enclosure_manifest_sha") and FileAccess.get_sha256(canonical) == FileAccess.get_sha256(C.candidate_path(StringName(id))) and FileAccess.get_file_as_string(canonical).contains('path="' + layout + '"') and _file(layout) == source_before[layout]
			boot_resources.append({"id": id, "canonical_path": canonical, "canonical_sha256": FileAccess.get_sha256(canonical), "candidate_sha256": FileAccess.get_sha256(C.candidate_path(StringName(id))), "layout_path": layout, "layout_sha256": FileAccess.get_sha256(layout), "passed": bound})
			if not _check(bound, "formal four resource ID/enclosure/layout/frozen candidate bytes " + id): return
		var selected: bool = bool(root.get_node("SceneRouter").call("go_field_smart", StringName(IDS[0]), null, "", -1, 3))
		if not selected:
			print("LUOYANG_FORMAL_BOOT_REJECTION=" + JSON.stringify({"scene_id": IDS[0], "C_errors": C.errors(), "BASE_errors": C.BASE.errors()}))
		if not _check(selected, "public formal Gate boot"): return
		if await _wait_field(IDS[0]): await _spawn_row("FORMAL_GATE_BOOT_ONLY", true)
		return
	for id: String in IDS:
		if not _check(bool(root.get_node("SceneRouter").call("go_field_smart", StringName(id), null, "", -1, 3)), "public startup selection " + id): return
		if not await _wait_field(id) or not await _spawn_row("PUBLIC_STARTUP_NOT_PORTAL", true): return
	# Only remaining key links; Gate/world normal inputs are separate ROOT522 evidence.
	if not bool(root.get_node("SceneRouter").call("go_field_smart", StringName(IDS[1]), null, "", -1, 3)) or not await _wait_field(IDS[1]) or not _bind(): return
	if not await _portal(IDS[3]) or not await _portal(IDS[2]): return
	var router: Node = root.get_node("SceneRouter")
	var player: Node2D = field.get("_player") as Node2D
	var position: Vector2 = player.position
	var audio_before: Dictionary = _audio()
	router.call("set_field_return_spawn", position / Vector2(field.get("_world_size")))
	var navigation: Dictionary = (router.call("get_navigation_state") as Dictionary).duplicate(true)
	var save_script: Script = load(ISOLATED_SAVE) as Script
	if not _check(save_script != null and save_script.can_instantiate(), "isolated save runtime load after autoload registration"): return
	slots = save_script.new()
	root.add_child(slots)
	var directory: String = "user://world_map_v15_qa/luoyang_key_smoke_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	if not _check(bool(slots.call("configure_directory", directory)), "unique isolated save paths"): return
	if not _check(bool(slots.call("save_to_slot", 0)), "real isolated current save"): return
	var save_path: String = slots.call("slot_path", 0)
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not _check(saved is Dictionary and saved.get("version") == 14 and saved.get("current_field") == IDS[2] and saved.get("navigation") == JSON.parse_string(JSON.stringify(navigation)), "current schema14 actual Docks navigation"): return
	var save_sha: String = FileAccess.get_sha256(save_path)
	if not bool(router.call("go_field_smart", StringName(IDS[0]), null, "", -1, 3)) or not await _wait_field(IDS[0]): return
	if not _check(bool(slots.call("load_from_slot", 0, &"world_map_jianghu")), "real isolated load current format"): return
	router.call("resume_current_field")
	if not await _wait_field(IDS[2]) or not _bind(): return
	player = field.get("_player") as Node2D
	var audio_after: Dictionary = _audio()
	var good: bool = player.position.distance_to(position) < .02 and _clear(player.position) and FileAccess.get_sha256(save_path) == save_sha and audio_after.driver == "WASAPI" and audio_after.playing and not audio_after.paused
	_check(good, "isolated real Field birth restores scene/position and keeps source save")
	rows.append({"kind": "ISOLATED_CURRENT_SAVE_READ", "scene_id": IDS[2], "save_path": save_path, "save_sha256": save_sha, "before": [position.x, position.y], "after": [player.position.x, player.position.y], "spawn_clear": _clear(player.position), "audio_before": audio_before, "audio_after": audio_after, "passed": good})

func _run() -> void:
	var bridge: Node = root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended", true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true, "public checkpoint held before first await")
	players_before = _players()
	prior_slot = int(root.get_node("SaveManager").get("active_slot"))
	prior_navigation = (root.get_node("SceneRouter").call("get_navigation_state") as Dictionary).duplicate(true)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	boot_only = "--luoyang-formal-boot-only" in args
	candidate = "--luoyang-v3-candidate" in args and "--luoyang-enclosure-v11-candidate" in args
	_check("--luoyang-key-smoke" in args and (candidate or (not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args)), "explicit smoke and paired candidate/neither formal flags")
	_check(not boot_only or (not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args), "formal boot forbids either candidate flag")
	_check(AudioServer.get_driver_name() == "WASAPI" and Engine.time_scale == 1.0 and FileAccess.get_sha256(OS.get_executable_path()).to_lower() == ENGINE_SHA, "actual installed GPU engine/WASAPI/ordinary clock")
	output = "res://build/joint_world_luoyang_20261003_qa/luoyang_key_smoke_%d_%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec(), OS.get_process_id()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique smoke evidence")
	for path: String in PINNED:
		_check(PINNED[path].length() == 64 and FileAccess.get_sha256(path).to_lower() == PINNED[path], "current source pin " + path)
		source_before[path] = _file(path)
	source_before[get_script().resource_path] = _file(get_script().resource_path)
	source_before["res://project.godot"] = _file("res://project.godot")
	for id: String in IDS:
		for path: String in ["res://data/scenes/" + id + ".tres", C.candidate_path(StringName(id)), C.layout_path(StringName(id)), C.manifest_path(StringName(id)), C.base_manifest_path(StringName(id)), C.ground_manifest_path(StringName(id))]:
			source_before[path] = _file(path)
			_check(source_before[path].exists, "fresh current city resource " + path)
	driver = INPUT_DRIVER.new()
	driver.call("configure", self)
	deadline = Time.get_ticks_msec() + 570000
	if failures == 0:
		for id: String in ["GameState", "Inventory", "QuestManager", "BountyManager", "InvestigationState", "SceneRouter"]: root.get_node(id).call("reset_for_new_game")
		for flag: String in ["chapter3_complete", "seen_ch4_yamen", "chapter4_started"]: root.get_node("GameState").call("set_flag", StringName(flag), true)
		root.get_node("GameState").set("current_chapter", 4)
		await _exercise()
	if oracle != null:
		_check(bool(oracle.call("verify_sources")), "current independent nav source unchanged")
		oracle.call("release")
		oracle = null
	if driver != null: driver.call("release"); driver = null
	if is_instance_valid(slots): slots.queue_free(); slots = null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene = null
	for shape: int in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	await process_frame
	await process_frame
	root.get_node("SceneRouter").call("restore_navigation_state", prior_navigation, &"world_map_jianghu", &"world_map_jianghu")
	_check(_sources() == source_before and _players() == players_before and root.get_node("SaveManager").get("active_slot") == prior_slot, "source/current15player/active-slot preserved")
	_check(AudioServer.get_driver_name() == "WASAPI" and bridge.call("is_checkpoint_saves_suspended") == true, "WASAPI/checkpoint held through cleanup")
	_check(rows.size() == (1 if boot_only else 7), "formal Gate boot only complete" if boot_only else "four starts/two normal portals/one isolated read complete")
	_check(_write(), "smoke final result written/read back")
	print("LUOYANG_KEY_SMOKE_RESULT=" + output + "result.json checks=" + str(checks) + " failures=" + str(failures))
	quit(0 if failures == 0 else 1)
