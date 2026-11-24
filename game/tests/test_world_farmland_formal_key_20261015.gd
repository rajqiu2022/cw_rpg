extends "res://tests/test_world_v15_key_map_smoke_20261012.gd"
## One ordinary world boot/short input/visible farm seam; no full-world rebuild.
## SOURCE_DRAFT: ROOT must freeze source-pins authorization after actual imports.
const PATCH = preload("res://scripts/world/world_farmland_visual_patch_resolver_20261015.gd")
const CITY = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const MINI = preload("res://scripts/ui/world_travel_minimap.gd")
const SCOPE := "FORMAL_WORLD_FARMLAND12_KEY_ONLY_20261015"
const BUDGET_MS := 180000
const REQUIRED_SOURCE_PATHS := [
	"res://tests/test_world_farmland_formal_key_20261015.gd",
	"res://tests/test_world_v15_key_map_smoke_20261012.gd",
	"res://scripts/world/world_farmland_visual_patch_resolver_20261015.gd",
	"res://scripts/autoload/loading_manager.gd",
	"res://scripts/field/background_chunk_streamer.gd",
	"res://scripts/ui/world_travel_minimap.gd",
	"res://scripts/field/field_walkable_controller.gd",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd",
	"res://scripts/autoload/scene_router.gd",
	"res://scripts/autoload/platform_bridge.gd",
	"res://scripts/autoload/save_manager.gd",
	"res://scripts/world/world_map_v15_contract.gd",
	"res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd",
	"res://tests/helpers/v15_raw_world_oracle.gd",
	"res://tests/helpers/v15_input_driver.gd",
	"res://data/scenes/world_map_jianghu.tres",
	"res://data/maps/world_map_jianghu_layout_v15.tres",
	"res://data/background_sets/world_map_jianghu_v15_streamed.tres"
]
var started: int
var deadline: int
var approved: Dictionary = {}
var mapping: Dictionary = {}
var expected_preload: Dictionary = {}
var seen_new_preload: Dictionary = {}
var seen_old_preload: Dictionary = {}
var evidence: Array[Dictionary] = []
var owned_mini: Control

func _values(value: Variant) -> Variant:
	if value is Vector2 or value is Vector2i: return [value.x, value.y]
	if value is Rect2 or value is Rect2i: return {"position": _values(value.position), "size": _values(value.size)}
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[String(key)] = _values(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(_values(item))
		return result
	return value

func _small_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 262144: return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	return value if value is Dictionary else {}

func _hold(path: String, expected: String = "") -> bool:
	var fact := _file(path)
	if not first.has(path): first[path] = fact
	return _check(fact.exists and (expected.is_empty() or (expected.length() == 64 and fact.sha256 == expected.to_lower())), "Exact held source " + path)

func _authorization() -> bool:
	var path := ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--root-qa-authorization="): path = argument.trim_prefix("--root-qa-authorization=")
	var auth := _small_json(path)
	if not _check(auth.get("approved_by") == "root" and auth.get("approved") == true and auth.get("scope") == SCOPE and auth.get("input_sha256") is Dictionary, "Explicit ROOT frozen key-source authorization"): return false
	_hold(path)
	var pins: Dictionary = auth.input_sha256
	for source: String in REQUIRED_SOURCE_PATHS:
		if not _check(pins.has(source), "ROOT source pin supplied " + source): return false
	for source: String in pins:
		if not _hold(source, String(pins[source])): return false
	if not _check(PATCH.APPROVAL_SHA.length() == 64, "Resolver is finally approved, not PENDING"): return false
	if not _hold(PATCH.APPROVAL_PATH, PATCH.APPROVAL_SHA): return false
	approved = _small_json(PATCH.APPROVAL_PATH)
	return _check(approved.get("approved_by") == "root" and approved.get("approved") == true and approved.get("entries", []).size() == 12, "ROOT approved12 runtime manifest")

func _imports() -> bool:
	var proof_info: Dictionary = approved.get("import_proof", {})
	var proof_path: String = proof_info.get("path", "")
	if not _hold(proof_path, String(proof_info.get("sha256", ""))): return false
	var proof := _small_json(proof_path)
	if not _check(proof.get("passed") == true and proof.get("rows", []).size() == 13 and proof.get("candidate_result_sha256") == PATCH.RESULT_SHA, "Actual13 import proof bound in real game"): return false
	var by_path: Dictionary = {}
	for receipt: Dictionary in proof.rows:
		if not _check(not by_path.has(receipt.get("path", "")), "Unique approved texture receipt"): return false
		by_path[receipt.path] = receipt
	var assets: Array = approved.entries.duplicate(true)
	assets.append(approved.overview)
	for asset: Dictionary in assets:
		var path: String = asset.path
		var receipt: Dictionary = by_path.get(path, {})
		var size := Vector2i(3072, 2048) if path.ends_with("/overview.png") else Vector2i(1536, 1024)
		if not _hold(path, asset.sha256) or not _hold(String(receipt.get("import_path", "")), String(receipt.get("import_sha256", ""))) or not _hold(String(receipt.get("compiled_path", "")), String(receipt.get("compiled_sha256", ""))): return false
		var config := ConfigFile.new()
		if not _check(config.load(path + ".import") == OK and config.get_value("remap", "path", "") == receipt.get("compiled_path") and config.get_value("deps", "source_file", "") == path and receipt.get("full_RGBA_exact") == true and receipt.get("mipmap_count") == 0, "Approved real-game compiled/source import binding"): return false
		var settings_ok: bool = true
		for key: String in receipt.get("params", {}): settings_ok = settings_ok and config.get_value("params", key, null) == receipt.params[key]
		_check(settings_ok, "All proved import parameters retained " + path)
		var original := Image.load_from_file(path)
		var texture := ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		var actual := texture.get_image() if texture != null else null
		var exact: bool = original != null and actual != null and not actual.is_compressed() and original.get_size() == size and actual.get_size() == size and original.get_format() == Image.FORMAT_RGBA8 and actual.get_format() == Image.FORMAT_RGBA8 and original.get_mipmap_count() == 0 and actual.get_mipmap_count() == 0 and original.get_data() == actual.get_data()
		_check(exact, "Actual game ResourceLoader complete RGBA/mip0 " + path)
		evidence.append({"kind": "GAME_IMPORT_RGBA", "path": path, "source_sha256": asset.sha256, "import_sha256": receipt.import_sha256, "compiled_sha256": receipt.compiled_sha256, "size": size, "full_RGBA_exact": exact, "mipmap_count": actual.get_mipmap_count() if actual != null else -1})
		if not _check(Time.get_ticks_msec() < deadline, "Shared180 after actual imported image"): return false
	return failures == 0

func _dispatch() -> bool:
	var stream: StreamedBackgroundSet = definition.streamed_background
	var original: Array[Dictionary] = stream.get_chunks(stream.uses_desktop_variant())
	var effective: Array[Dictionary] = PATCH.effective_chunks(stream, stream.uses_desktop_variant())
	var copy_ok: bool = original.size() == 64 and effective.size() == 64
	var changed := 0
	var unchanged := 0
	for asset: Dictionary in approved.entries: mapping[asset.old_path] = asset.path
	for index in original.size():
		var expected: Dictionary = original[index].duplicate(true)
		var path: String = expected.get("path", "")
		if mapping.has(path): expected.path = mapping[path]; changed += 1
		else: unchanged += 1
		copy_ok = copy_ok and effective[index] == expected and original[index].get("path") == path
	if not effective.is_empty():
		effective[0]["qa_copy_probe"] = true
		copy_ok = copy_ok and not original[0].has("qa_copy_probe")
		effective[0].erase("qa_copy_probe")
	var state: Dictionary = PATCH.debug_state()
	_check(copy_ok and changed == 12 and unchanged == 52 and state.get("active") == true and state.get("replacement_count") == 12 and state.get("NAV_changed") == false and state.get("scene_mutated") == false, "Effective64 copy12 changed52 original with all geometry/scale/position unchanged")
	_check(stream.get_chunks(stream.uses_desktop_variant()) == original and PATCH.overview_path(definition) == approved.overview.path, "Original stream remains unchanged; only overview dispatch changes")
	var nonworld := SceneScript.new()
	nonworld.scene_id = &"ch4_s3_luoyang_market"
	var outsider := StreamedBackgroundSet.new()
	_check(PATCH.overview_path(nonworld) == PATCH.OLD_OVERVIEW and PATCH.effective_chunks(outsider, true).is_empty(), "Nonworld and unrelated stream never inherit world patch")
	var size := Vector2(stream.logical_size)
	var visible_size := root.get_visible_rect().size / maxf(1.0, definition.camera_zoom)
	var half := visible_size * .5
	var center := (definition.player_spawn * size).clamp(half.min(size * .5), (size - half).max(size * .5))
	var load_rect := Rect2(center - half, visible_size).grow(stream.load_padding)
	for entry: Dictionary in effective:
		if mapping.values().has(entry.path) and (entry.logical_rect as Rect2).intersects(load_rect, true): expected_preload[entry.path] = true
	evidence.append({"kind": "RESOLVER_COPY64", "changed": changed, "unchanged": unchanged, "state": state, "expected_visible_new_preload": expected_preload.keys(), "scene_path": definition.resource_path, "stream_path": stream.resource_path})
	return failures == 0

func _observe_preload() -> void:
	var manager: Node = root.get_node("LoadingManager")
	for resource: Resource in manager.get("_field_preloaded"):
		var path: String = resource.resource_path
		if mapping.has(path): seen_old_preload[path] = true
		if mapping.values().has(path): seen_new_preload[path] = true

func _busy() -> bool:
	var manager: Node = root.get_node("LoadingManager")
	if bool(manager.get("_transition_active")) or bool(manager.get("_external_active")): return true
	var state: Dictionary = CITY.transition_validation_state()
	for key: String in ["active", "source_worker_active", "navigation_worker_active", "base_cpu_worker_active", "BASE_live_active"]:
		if state.get(key, false) == true: return true
	var metrics: Dictionary = manager.call("get_field_preload_metrics")
	return int(metrics.get("active_requests", 0)) > 0 or int(metrics.get("draining_requests", 0)) > 0

func _wait_world() -> bool:
	var begin := Time.get_ticks_msec()
	var end := mini(deadline, begin + 60000)
	while Time.get_ticks_msec() < end:
		await process_frame
		_observe_preload()
		if _busy(): continue
		var actual: Node = current_scene
		if not is_instance_valid(actual) or actual.scene_file_path != "res://scenes/field_walkable.tscn" or actual.is_queued_for_deletion(): continue
		var scene: SceneScript = actual.get("_current_scene") as SceneScript
		var player: Node2D = actual.get("_player") as Node2D
		var ready: Dictionary = actual.call("get_field_loading_state")
		if scene != null and scene.scene_id != ID and ready.get("complete") == true: return _check(false, "Idle world startup rolled back/rejected")
		if scene == null or scene.scene_id != ID or ready.get("complete") != true or ready.get("failed") == true or not is_instance_valid(player) or not player.is_inside_tree() or player.is_queued_for_deletion() or bool(actual.get("_scene_rebuilding")): continue
		await driver.call("completed_actor_stage")
		if current_scene != actual or not is_instance_valid(actual) or _busy() or actual.get("_player") != player: continue
		field = actual
		evidence.append({"kind": "ORDINARY_WORLD_ARRIVAL", "arrival_ms": Time.get_ticks_msec() - begin, "total_elapsed_ms": Time.get_ticks_msec() - started, "Field_ready": ready, "C_errors": CITY.errors(), "C_state": CITY.transition_validation_state(), "LM_metrics": root.get_node("LoadingManager").call("get_field_preload_metrics")})
		return true
	return _check(false, "Finite60 arrival/shared180 startup")

func _live_chunks_and_map() -> bool:
	var streamer: Node = field.get("_background_streamer") as Node
	if not _check(is_instance_valid(streamer), "Actual Field uses BackgroundChunkStreamer"): return false
	var expected: Array[Dictionary] = PATCH.effective_chunks(definition.streamed_background, definition.streamed_background.uses_desktop_variant())
	_check(streamer.get("_chunks") == expected, "Actual Field render receives exactly same effective64 list")
	var preload_ok: bool = not expected_preload.is_empty() and seen_old_preload.is_empty()
	for path: String in expected_preload: preload_ok = preload_ok and seen_new_preload.has(path)
	_check(preload_ok, "Actual LM preloaded all visible mapped paths, no superseded old12")
	var loaded: Dictionary = streamer.get("_loaded")
	var rendered: Array[Dictionary] = []
	var seen: Dictionary = {}
	var draw_ok: bool = true
	for path: String in loaded:
		var sprite: Sprite2D = loaded[path] as Sprite2D
		var match_entry: Dictionary = {}
		for entry: Dictionary in expected:
			if entry.path == path: match_entry = entry; break
		draw_ok = draw_ok and not match_entry.is_empty() and is_instance_valid(sprite) and sprite.texture != null and sprite.texture.resource_path == path and sprite.position == match_entry.get("draw_position") and sprite.scale == Vector2.ONE * float(match_entry.get("draw_scale")) and not sprite.centered
		if mapping.values().has(path):
			seen[path] = true
			rendered.append({"path": path, "sprite_position": sprite.position, "sprite_scale": sprite.scale, "texture_path": sprite.texture.resource_path})
	_check(draw_ok and seen.has(PATCH.NEW_ROOT + "r3_c1_visual.png") and seen.has(PATCH.NEW_ROOT + "r3_c2_visual.png"), "Visible native farm/adjacent seam uses two approved textures and exact draw geometry")
	var minimap: Control = field.get_node_or_null("HudCanvasLayer/FieldPrimaryHud/WorldTravelMinimap") as Control
	if not _check(minimap != null, "Actual Field HUD minimap exists"): return false
	minimap.call("update_view")
	var state: Dictionary = minimap.call("get_debug_state")
	var panel: Rect2 = state.panel_rect
	var viewport := root.get_visible_rect()
	var scale_value := clampf(viewport.size.y / 1080.0, .72, 1.0)
	var live_texture: Texture2D = minimap.get("_effective_overview") as Texture2D
	_check(state.get("configured") == true and state.get("visible") == true and state.get("effective_overview_path") == approved.overview.path and live_texture != null and live_texture.resource_path == approved.overview.path and absf(panel.end.x - (viewport.end.x - 16.0 * scale_value)) < .001, "Actual approved overview in actual minimap, scaled16 right edge")
	_check(state.get("portals", []).size() == 16 and state.get("mouse_filter") == Control.MOUSE_FILTER_IGNORE and minimap.focus_mode == Control.FOCUS_NONE, "Original16 portal markers and input passthrough")
	evidence.append({"kind": "ACTUAL_RENDER_PRELOAD_MINIMAP", "rendered_patch": rendered, "seen_new_preload": seen_new_preload.keys(), "seen_old_preload": seen_old_preload.keys(), "minimap": state, "resolver": PATCH.debug_state()})
	owned_mini = MINI.new()
	root.add_child(owned_mini)
	var player: Node2D = field.get("_player") as Node2D
	var camera: Camera2D = field.get("_world_camera") as Camera2D
	var world: Node2D = field.get("world_container") as Node2D
	_check(bool(owned_mini.call("configure", definition, player, camera, world)), "Owned mini world lifecycle setup")
	owned_mini.call("release")
	var released: Dictionary = owned_mini.call("get_debug_state")
	_check(released.configured == false and released.visible == false and released.get("effective_overview_path") == PATCH.OLD_OVERVIEW and not owned_mini.is_processing(), "Release clears mapped overview and hides owned minimap")
	var nonworld := SceneScript.new()
	nonworld.scene_id = &"ch4_s3_luoyang_market"
	_check(not bool(owned_mini.call("configure", nonworld, player, camera, world)) and owned_mini.call("get_debug_state").effective_overview_path == PATCH.OLD_OVERVIEW, "Nonworld minimap never carries the world patch")
	owned_mini.free(); owned_mini = null
	return failures == 0

func _exercise() -> void:
	definition = load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	if not _check(definition != null and WORLD.is_v15(definition) and definition.scene_id == ID and WORLD.formal_version() == 15, "Ordinary canonical world15, no candidate flags"): return
	if not _dispatch() or not _imports(): return
	oracle = RAW.new()
	if not _check(bool(oracle.call("configure", definition.map_layout)), "Independent original64 navigation/raw source solids retained"): return
	var public_begin := Time.get_ticks_msec()
	var accepted: bool = bool(root.get_node("SceneRouter").call("go_field_smart", ID))
	evidence.append({"kind": "NORMAL_PUBLIC_DEFAULT_BOOT", "public_call_ms": Time.get_ticks_msec() - public_begin, "setup_override": false, "loading_speed_approved": false})
	if not _check(accepted, "Normal public default world boot") or not await _wait_world(): return
	var player: Node2D = field.get("_player") as Node2D
	var born: Vector2 = player.position
	_check(born.distance_to(definition.player_spawn * WORLD.SIZE) < .03 and _clear(born), "Actual ordinary birth original17 feet and real Physics clear")
	evidence.append({"kind": "ACTUAL_BIRTH_17_PHYSICS", "foot": born, "raw17": oracle.call("foot_evidence", born), "Physics": _physical(born)})
	var movement: Dictionary = await driver.call("drive", field, born + Vector2(0, 80), _clear)
	_check(movement.get("ok") == true and movement.get("reached") == true and movement.get("all_recorded_feet_clear") == true, "Original normal80px input with original raw17 and actual Physics")
	evidence.append({"kind": "NORMAL_SHORT_INPUT_ONLY", "input": movement, "world_long_walk_credit": false})
	for frame in 3: await process_frame
	if not _live_chunks_and_map(): return
	await _capture("01_actual_formal_farm_seam_minimap")

func _run() -> void:
	started = Time.get_ticks_msec(); deadline = started + BUDGET_MS
	var bridge: Node = root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended", true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true, "Checkpoints held before first await")
	normal_files = _players(); slot = int(root.get_node("SaveManager").get("active_slot"))
	output = "res://build/world_farmland_formal_key_20261015/%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "Unique independent formal key output")
	var args := OS.get_cmdline_user_args()
	_check("--world-farmland-formal-key" in args and not "--world-v15-candidate" in args and not "--world-farmland-visual-patch-phase2" in args and DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0, "GPU key-only normal formal world, no candidate routing")
	root.size = Vector2i(1920, 1080); root.content_scale_size = Vector2i(1920, 1080)
	driver = INPUT_DRIVER.new(); driver.call("configure", self)
	if _authorization() and failures == 0:
		for id: String in ["GameState", "Inventory", "QuestManager", "BountyManager", "InvestigationState", "SceneRouter"]: root.get_node(id).call("reset_for_new_game")
		await _exercise()
	if is_instance_valid(owned_mini): owned_mini.call("release"); owned_mini.free(); owned_mini = null
	if oracle != null: _check(bool(oracle.call("verify_sources")), "Original independent navigation sources unchanged"); oracle.call("release"); oracle = null
	if driver != null: driver.call("release"); driver = null
	var weak_field: WeakRef = weakref(field) if is_instance_valid(field) else null
	var weak_streamer: WeakRef = weakref(field.get("_background_streamer")) if is_instance_valid(field) and is_instance_valid(field.get("_background_streamer")) else null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene = null
	field = null
	for cursor: int in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, cursor)
	await process_frame; await process_frame
	_check(weak_field != null and weak_field.get_ref() == null and weak_streamer != null and weak_streamer.get_ref() == null, "Owned actual Field/background streamer released")
	var last: Dictionary = {}
	for path: String in first: last[path] = _file(path)
	_check(first == last and _players() == normal_files and root.get_node("SaveManager").get("active_slot") == slot and bridge.call("is_checkpoint_saves_suspended") == true, "Actual source/player15/slot/checkpoint guards held; ROOT exactticks remains required")
	_check(Time.get_ticks_msec() < deadline and rows.size() == 1 and evidence.size() >= 19, "Shared180 and single GPU key receipt complete")
	var result := {"scope": SCOPE, "complete": failures == 0, "checks": checks, "failures": failures, "records": evidence, "captures": rows, "source_before": first, "source_after": last, "players_before": normal_files, "players_after": _players(), "elapsed_ms": Time.get_ticks_msec() - started, "budget_ms": BUDGET_MS, "full64_rebuild": false, "full_world_geometry_credit": false, "full_city_or_gameplay_or_audio_credit": false, "fresh_ROOT_exactticks_required": true, "no_actual_nonworld_city_transition_credit": true}
	var file := FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file == null: push_error("Cannot save finite formal key evidence"); quit(1); return
	file.store_string(JSON.stringify(_values(result), "\t")); file.flush(); file.close()
	print("WORLD_FARMLAND_FORMAL_KEY_RESULT=", output + "result.json failures=", failures, " elapsed_ms=", result.elapsed_ms)
	quit(0 if failures == 0 else 1)
