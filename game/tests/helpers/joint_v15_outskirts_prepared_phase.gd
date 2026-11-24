extends RefCounted
## NEW complete-v5 joint phase. Original local test bytes/results are unchanged.
const SUBJECT := preload("res://scripts/world/outskirts_native_contract.gd")
const ART_ROOT: String = "res://art/maps/world_map_v15_outskirts_complete_v5_retry1/"
const SAVED_GEOMETRY := preload("res://tests/helpers/joint_v15_outskirts_saved_geometry_probe.gd")
var owner_tree: SceneTree
var result: Dictionary={}
var candidate: bool=false
var root: Window:
	get: return owner_tree.root
var current_scene: Node:
	get: return owner_tree.current_scene
	set(value): owner_tree.current_scene=value
var process_frame: Signal:
	get: return owner_tree.process_frame
var physics_frame: Signal:
	get: return owner_tree.physics_frame
func create_timer(seconds: float) -> SceneTreeTimer:
	return owner_tree.create_timer(seconds)
func run(tree: SceneTree,before_cutover: bool) -> Dictionary:
	owner_tree=tree
	candidate=before_cutover
	requested_phase="full"
	await _run()
	return result.duplicate(true)
## NEW three-field acceptance entry. No v14 implementation/tests inheritance.
## Owner manifest is required; this WIP never treats missing resources or
## preflight-only success as ordinary Field/gameplay/GPU acceptance.
const RAW := preload("res://tests/helpers/v15_field_raw_oracle.gd")
const INPUT := preload("res://tests/helpers/v15_input_driver.gd")
const ALPHA := preload("res://tests/helpers/v15_geometry_oracle.gd")
const ENCOUNTER_PROBE := preload("res://tests/helpers/joint_v15_outskirts_encounter_probe.gd")
const FIELD_PROBE := preload("res://tests/helpers/joint_v15_outskirts_field_probe.gd")
const MATERIAL_PROBE := preload("res://tests/helpers/joint_v15_outskirts_material_probe.gd")
const FIELD_IDS := {"bamboo": "openworld_v15_bamboo_outskirts", "forest": "openworld_v15_forest_outskirts", "marsh": "openworld_v15_marsh_outskirts"}
const SOURCE_ENTRIES := {"bamboo": {"id": "linxi_village_scrollmap", "pos": Vector2(.55, .53)}, "forest": {"id": "openworld_xiangzhou_mine_valley", "pos": Vector2(.80, .62)}, "marsh": {"id": "openworld_jinling_reed_marsh", "pos": Vector2(.72, .58)}}
const PHASES := ["preflight", "field", "links", "full"]
var checks := 0
var failures := 0
var requested_phase := "preflight"
var manifest_path := ""
var output := ""
var before_files: Dictionary
var after_files: Dictionary
var original_slot := -1
var catalog: Dictionary
var entries: Array[Dictionary] = []
var owned_oracles: Dictionary = {}
var evidence: Array[Dictionary] = []
var runtime_started := false
var actual_inputs := 0
var actual_battle_returns := 0
var screenshots: Array[Dictionary] = []
var input_driver: RefCounted
var field_probe: RefCounted
var encounter_probe: RefCounted
var material_probe: RefCounted
var prior_navigation: Dictionary
var phase_records: Array[Dictionary] = []
var isolated_slots: Node
var exit_audio_evidence: Dictionary = {}

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[V15 outskirts FAIL] " + label)

func _run() -> void:
	_check(SUBJECT.active_root()==ART_ROOT,"current complete-v5 exact root; no old local assets/adoption fallback")
	_check(candidate==("--outskirts-candidate-preview" in OS.get_cmdline_user_args()) and candidate==("--outskirts-complete-v5" in OS.get_cmdline_user_args()),"explicit double candidate flags only before cutover; no preview flag on canonical")
	_check(DisplayServer.get_name() == "headless" or "--qa-gpu-approved" in OS.get_cmdline_user_args(), "actual GPU requires producer's explicit serial window")
	output = "res://build/joint_world_luoyang_20261003_qa/outskirts_%d/" % Time.get_ticks_usec()
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "new non-overwriting evidence directory")
	before_files = _snapshot_normal_files()
	original_slot = int(root.get_node("SaveManager").get("active_slot"))
	if failures > 0:
		await _finish()
		return
	var rows: Array[Dictionary] = []
	for ecology: String in FIELD_IDS:
		var art_path: String = ART_ROOT+ecology+"/art_contract.json"
		var data: Dictionary = _read_object(art_path)
		_check(int(data.get("schema_version", 0)) == 1 and data.get("status") in ["ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA", "APPROVED_LOCAL_FIELD"], "actual source contract ready for honest candidate QA; authoring/partial refused")
		_check(data.get("scene_id") == FIELD_IDS[ecology] and _point(data.get("logical_size_px")) == Vector2(1536, 1024), "actual each owner field schema identity/native size")
		_check(data.get("pixel_sampling") == "round_world_pixel" and float(data.get("physical_navigation_margin_px", -1)) == 0, "explicit actual native pixel/margin contract, never applied to legacy ordinary scenes")
		var hashes: Variant = data.get("asset_sha256")
		_check(hashes is Dictionary and not hashes.is_empty(), "actual source assets are bound by captured hashes")
		if hashes is Dictionary:
			for asset: String in hashes:
				_check(String(hashes[asset]).length() == 64 and FileAccess.file_exists(asset) and FileAccess.get_sha256(asset).to_lower() == String(hashes[asset]).to_lower(), "actual original asset current bytes equal captured source: " + asset)
		var saved_geometry: RefCounted=SAVED_GEOMETRY.new()
		var saved_geometry_record: Dictionary=saved_geometry.call("run",data)
		checks+=int(saved_geometry_record.get("checks",0))
		for message: String in saved_geometry_record.get("errors",[]): _check(false,ecology+" independent saved mesh/RF: "+message)
		_check(_write_checked(ecology+"_actual_saved_mesh_RF.json",saved_geometry_record),"independent actual 4px mesh/RF proof saved with exact readback")
		saved_geometry=null
		rows.append({"ecology": ecology, "scene_id": FIELD_IDS[ecology], "scene_path": "res://data/scenes/%s.tres" % FIELD_IDS[ecology], "art": data, "art_path": art_path, "source_scene_id": SOURCE_ENTRIES[ecology].id, "source_pos": SOURCE_ENTRIES[ecology].pos})
	if failures > 0:
		await _finish()
		return
	var names: Dictionary = {}
	var bases: Dictionary = {}
	var layouts: Dictionary = {}
	var topology_fingerprints: Dictionary = {}
	for row: Variant in rows:
		_check(row is Dictionary, "field entry is typed object")
		if not row is Dictionary: continue
		var entry: Dictionary = row
		var ecology: String = entry.get("ecology", "")
		var id: String = entry.get("scene_id", "")
		var path: String = entry.get("scene_path", "")
		_check(FIELD_IDS.has(ecology) and not names.has(ecology), "distinct real bamboo/forest/marsh, no invented desert license")
		_check(id == FIELD_IDS.get(ecology, "INVALID") and path == "res://data/scenes/%s.tres" % id, "exact new owner ordinary scene resource, not old v14 replacement")
		_check(ResourceLoader.exists(path), "new actual scene resource exists: " + path)
		names[ecology] = true
		if not ResourceLoader.exists(path): continue
		var definition: SceneScript = load(path) as SceneScript
		_check(definition != null and String(definition.scene_id) == id and definition.map_layout != null, "actual source Field SceneScript and independent layout")
		if definition == null or definition.map_layout == null: continue
		_check(not layouts.has(definition.map_layout.resource_path) and not definition.map_layout.resource_path.is_empty(), "three original layouts are actual different resources")
		_check(definition.map_layout.resource_path == "res://data/maps/%s_layout_v1.tres" % id and definition.map_layout.design_size == Vector2i(1536, 1024), "actual published ordinary layout matches measured new 1536x1024 source canvas")
		layouts[definition.map_layout.resource_path] = true
		var materialized: SceneScript=SUBJECT.materialize(definition)
		_check(materialized!=null,"normal complete-v5 contract materializes exact new assets; missing/frozen mismatch refuses")
		if materialized==null: continue
		definition=materialized
		var bg: String = definition.background_path
		_check(not bg.is_empty() and "v15" in bg and FileAccess.file_exists(bg), "field owns a new actual original ground base")
		var image: Image = Image.load_from_file(bg) if FileAccess.file_exists(bg) else null
		_check(image != null and not image.is_empty(), "new ground PNG independently decodes")
		var raw_sha: String = FileAccess.get_sha256(bg) if FileAccess.file_exists(bg) else ""
		_check(not raw_sha.is_empty() and not bases.has(raw_sha), "three ground bases differ in actual bytes, not labels")
		bases[raw_sha] = true
		var expected_layout: Resource = _independent_layout(definition.map_layout, entry.art)
		var oracle: RefCounted = RAW.new()
		_check(bool(oracle.call("configure", expected_layout, String(entry.art.pixel_sampling), float(entry.art.physical_navigation_margin_px))), "complete original raw navigation and physical source: " + str(oracle.get("errors")))
		_check(bool(oracle.call("clear", _point(entry.art.get("return_foot_px")))), "source measured ordinary-field spawn has full17 original source clearance")
		owned_oracles[id] = oracle
		var native_walk: String = ART_ROOT+ecology+"/walk.png"
		_check(definition.map_layout.walkable_mask_path == native_walk and definition.map_layout.walkable_mask_tiles.is_empty(), "ordinary navigation directly binds original own new native walk PNG")
		var physical_distribution: Array[Dictionary] = []
		for object: Dictionary in entry.art.get("objects", []): physical_distribution.append({"foot": object.get("world_foot_px"), "size": object.get("render_size_px"), "blocking": object.get("blocking"), "physical_center": object.get("physical_center_px"), "physical_size": object.get("collision_size_px")})
		var route_shapes: Array = []
		for route: Dictionary in entry.art.get("routes", []): route_shapes.append(route.get("points_px"))
		var shape: Dictionary = {"raw_navigation_sha256": FileAccess.get_sha256(native_walk) if FileAccess.file_exists(native_walk) else "MISSING", "land_sha256": FileAccess.get_sha256(entry.art.get("land_path", "")), "routes": route_shapes, "independent_physical_distribution": physical_distribution}
		# This falsifies copied topology, not an aesthetic/ecology verdict. Scene
		# IDs/background filenames are deliberately excluded from the fingerprint.
		var shape_sha: String = JSON.stringify(shape).sha256_text()
		_check(not topology_fingerprints.has(shape_sha), "actual navigation/road/physical-object distribution is independently different, not only background bytes")
		topology_fingerprints[shape_sha] = true
		entry["actual_scene"] = definition
		entries.append(entry)
		evidence.append({"scene_id": id, "ecology": ecology, "scene_path": path, "scene_sha256": FileAccess.get_sha256(path), "layout_path": definition.map_layout.resource_path, "layout_sha256": FileAccess.get_sha256(definition.map_layout.resource_path), "ground_path": bg, "ground_sha256": raw_sha, "ground_size": [image.get_width(), image.get_height()] if image != null else [], "topology_layout_fingerprint": shape_sha, "topology_fingerprint_is_not_ecology_visual_approval": true})
	_check(entries.size() == 3 and bases.size() == 3 and layouts.size() == 3, "all three actual independent grounds/layouts are present")
	if requested_phase != "preflight" and failures == 0:
		_check(SUBJECT.active_root()==ART_ROOT,"runtime binds complete-v5 current candidate/adopted root only")
		if failures == 0: await _runtime_phase()
	await _finish()

func _point(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size() == 2: return Vector2(float(value[0]), float(value[1]))
	return Vector2(INF, INF)

func _independent_layout(original: Resource, data: Dictionary) -> Resource:
	var layout: Resource = original.duplicate(true)
	var objects: Array[Dictionary] = []
	for object: Dictionary in data.get("objects", []):
		var foot: Vector2 = _point(object.get("world_foot_px"))
		var extent: Vector2 = _point(object.get("render_size_px"))
		var uv: Vector2 = _point(object.get("foot_uv"))
		var center: Vector2 = foot - (uv - Vector2(.5, .5)) * extent
		_check(foot.is_finite() and extent.is_finite() and uv.is_finite() and extent.x > 0 and extent.y > 0, "independent original sourcebody has finite actual foot/size/UV")
		var entry: Dictionary = {"id": object.get("id"), "pos": center / Vector2(1536, 1024), "render_size_px": extent}
		if bool(object.get("blocking", false)):
			entry["collision_size"] = _point(object.get("collision_size_px")) / Vector2(1536, 1024)
			entry["collision_offset"] = (_point(object.get("physical_center_px")) - center) / Vector2(1536, 1024)
		objects.append(entry)
	layout.set("visual_objects", objects)
	return layout

func _runtime_phase() -> void:
	var router: Node = root.get_node("SceneRouter")
	var state: Node = root.get_node("GameState")
	# Managed public new-game fixture avoids cold12->formal14 cleanup migration;
	# none of these calls writes a player slot or changes authored enemies.
	router.call("reset_for_new_game")
	prior_navigation = router.call("get_navigation_state")
	if candidate:
		var native: Dictionary=prior_navigation.duplicate(true)
		native["world_map_version"]=15
		router.call("restore_navigation_state",native,&"",&"world_map_jianghu_v15")
		_check(int((router.call("get_navigation_state") as Dictionary).get("world_map_version",-1))==15,"actual public candidate world-version15 context before ordinary returns")
	state.call("reset_for_new_game")
	root.get_node("Inventory").call("reset_for_new_game")
	root.get_node("QuestManager").call("reset_for_new_game")
	var stats: Resource = state.get("player") as Resource
	_check(stats != null, "ordinary encounter uses actual legal player stats fixture")
	if stats == null: return
	stats.call("gain_exp", 250)
	stats.set("hp", stats.get("max_hp"))
	# Lazy actual SaveManager subclass compilation occurs after autoloads exist.
	# Only its path methods/atomic guard differ from production SaveManager.
	var slots_script: Script = load("res://tests/helpers/v15_isolated_save_manager.gd") as Script
	_check(slots_script != null and slots_script.can_instantiate(), "actual owned SaveManager dependency compiles after registered autoloads")
	if slots_script == null or not slots_script.can_instantiate(): return
	isolated_slots = slots_script.new() as Node
	root.add_child(isolated_slots)
	_check(bool(isolated_slots.call("configure_directory", "user://world_map_v15_qa/outskirts_%d" % Time.get_ticks_usec())), "all actual save/load I/O confined to fresh owned user directory")
	input_driver = INPUT.new()
	input_driver.call("configure", owner_tree)
	field_probe = FIELD_PROBE.new()
	field_probe.call("configure", owner_tree, input_driver, _check, _wait_field, _normal_intro, _capture)
	runtime_started = true
	for entry: Dictionary in entries:
		var actual: Dictionary = await field_probe.call("run", entry)
		phase_records.append(actual)
		for route: Dictionary in actual.get("routes", []):
			for driven: Dictionary in (route.get("actual", {}) as Dictionary).get("segments", []): actual_inputs += int(driven.get("physics_samples", 0))
		_check(_write_checked(String(entry.ecology) + "_ordinary_field.json", actual), "actual loop/negatives/current-alpha evidence checked persistence")
		var live_definition: Variant = current_scene.get("_current_scene") if is_instance_valid(current_scene) else null
		if live_definition is SceneScript and live_definition.scene_id == StringName(entry.scene_id):
			var saved_navigation: Dictionary = router.call("get_navigation_state")
			_check(bool(isolated_slots.call("save_to_slot", 0)), "actual ordinary scenery navigation saves only to owned slot")
			_check(bool(isolated_slots.call("load_from_slot", 0)), "actual inherited normal SaveManager loads owned ordinary-field save")
			var restored: Dictionary = router.call("get_navigation_state")
			_check(restored.get("current_field") == saved_navigation.get("current_field") and _point(restored.get("current_field_spawn")).distance_to(_point(saved_navigation.get("current_field_spawn"))) < .00001 and restored.get("world_map_version") == saved_navigation.get("world_map_version"), "owned actual load preserves ordinary field/spawn and source world-side version")
		if requested_phase in ["links", "full"]:
			var links: Dictionary = await field_probe.call("run_links", entry)
			phase_records.append(links)
			actual_inputs += (links.get("cases", []) as Array).size() * 2
			_check(_write_checked(String(entry.ecology) + "_source_roundtrip.json", links), "actual Space/mouse source-return records checked persistence")
			material_probe = MATERIAL_PROBE.new()
			material_probe.call("configure", owner_tree, input_driver, field_probe, isolated_slots, _check, _wait_field, _normal_intro, _capture)
			var materials: Dictionary = await material_probe.call("run", entry)
			phase_records.append(materials)
			for driven: Dictionary in (materials.get("movement", {}) as Dictionary).get("segments", []): actual_inputs += int(driven.get("physics_samples", 0))
			_check(_write_checked(String(entry.ecology) + "_material_once_only.json", materials), "normal entity/material/capacity/public replay/real isolated-load evidence persisted")
			material_probe.call("release")
			material_probe = null
	# Load a fresh authored bamboo fixture: chance/distance/enemies unmodified.
	var bamboo: Dictionary = entries[0]
	for entry: Dictionary in entries:
		if entry.ecology == "bamboo": bamboo = entry
	router.call("go_field_smart", StringName(bamboo.scene_id), _point(bamboo.art.return_foot_px) / Vector2(1536, 1024))
	if await _wait_field(StringName(bamboo.scene_id)) and await _normal_intro() and bool(field_probe.call("bind_current", StringName(bamboo.scene_id))):
		var route := PackedVector2Array()
		for point: Variant in bamboo.art.routes[0].points_px: route.append(_point(point))
		encounter_probe = ENCOUNTER_PROBE.new()
		encounter_probe.call("configure", owner_tree, input_driver, _check, Callable(owned_oracles[bamboo.scene_id], "clear"), Callable(owned_oracles[bamboo.scene_id], "segment"), _wait_field, _normal_intro)
		var battle: Dictionary = await encounter_probe.call("run", current_scene, route, 151003)
		if bool(battle.get("returned", false)): actual_battle_returns += 1
		_check(_write_checked("bamboo_natural_encounter.json", battle), "normal natural Encounter/victory/rewards/exact-return evidence persisted")
		await _capture("bamboo_after_real_victory")
		encounter_probe.call("release")
		encounter_probe = null
	_check(actual_battle_returns >= 1, "at least one ordinary distance/chance Encounter genuinely wins/rewards/resumes original feet")

func _wait_field(id: StringName) -> bool:
	var deadline: int = Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if bool(root.get_node("LoadingManager").get("_transition_active")) or not is_instance_valid(current_scene): continue
		var definition: Variant = current_scene.get("_current_scene")
		if definition is SceneScript and definition.scene_id == id and current_scene.get("_player") is Node2D:
			for settle in 6: await physics_frame
			await input_driver.call("completed_actor_stage")
			return true
	_check(false, "actual normal Field transition reaches exact identity: " + String(id))
	return false

func _normal_intro() -> bool:
	var dialog: Node = root.get_node("DialogPlayer")
	for step in 80:
		if not bool(dialog.call("is_playing")): return true
		var node: Resource = dialog.get("_current_node") as Resource
		var box: Control=dialog.get("_box") as Control
		var choices: Variant=box.get("_choice_rects") if box!=null else null
		if node!=null and not (node.get("choices") as Array).is_empty() and choices is Array and not choices.is_empty():
			await input_driver.call("pointer",(choices[0] as Rect2).get_center())
		else: await input_driver.call("key",KEY_SPACE)
		for settle in 4: await process_frame
	_check(false, "authored ordinary introduction completes, not suppressed")
	return false

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	_check("--qa-gpu-approved" in OS.get_cmdline_user_args(), "actual screenshot uses serial approved GPU window")
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = output + label + ".png"
	_check(image != null and image.get_size() == Vector2i(1920, 1080), "actual GPU screenshot is full1920x1080, not synthetic preview")
	if image == null: return
	_check(not FileAccess.file_exists(path) and image.save_png(path) == OK, "actual raw screenshot saved to unique evidence path")
	screenshots.append({"path": path, "sha256": FileAccess.get_sha256(path), "visual_verdict": "ROOT_REVIEW_REQUIRED"})

func _read_object(path: String) -> Dictionary:
	_check(FileAccess.file_exists(path), "actual source JSON exists: " + path)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	_check(raw is Dictionary, "actual source JSON parses as object")
	return raw as Dictionary if raw is Dictionary else {}

func _snapshot_normal_files() -> Dictionary:
	# Fresh at actual process startup, never historical fixed six-file hashes.
	# A concurrent player's save is reported as an observed change, not falsely
	# blamed on QA or hidden as unchanged. This test does not call normal saves.
	var paths: Dictionary = {}
	var directory: DirAccess = DirAccess.open("user://")
	_check(directory != null, "normal player directory can be read without any writes")
	if directory != null:
		for name: String in directory.get_files():
			if name.begins_with("save"):
				var path: String = "user://" + name
				paths[path] = {"sha256": FileAccess.get_sha256(path), "mtime_unix": FileAccess.get_modified_time(path)}
	return {"observed_utc": Time.get_datetime_string_from_system(true), "unix": Time.get_unix_time_from_system(), "files": paths}

func _write_checked(name: String, value: Dictionary) -> bool:
	var path: String = output + name
	if FileAccess.file_exists(path): return false
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(value, "\t"))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	file = null
	return error == OK and JSON.parse_string(FileAccess.get_file_as_string(path)) == JSON.parse_string(JSON.stringify(value))

func _finish() -> void:
	if material_probe != null: material_probe.call("release")
	material_probe = null
	if encounter_probe != null: encounter_probe.call("release")
	encounter_probe = null
	if field_probe != null: field_probe.call("release")
	field_probe = null
	if input_driver != null: input_driver.call("release")
	input_driver = null
	if is_instance_valid(isolated_slots):
		var slot_reference: WeakRef = weakref(isolated_slots)
		isolated_slots.queue_free()
		isolated_slots = null
		for settle in 4: await process_frame
		_check(slot_reference.get_ref() == null, "actual owned SaveManager released without touching autoload manager")
	if runtime_started:
		if is_instance_valid(current_scene):
			var owned: Node = current_scene
			var reference: WeakRef = weakref(owned)
			current_scene = null
			owned.queue_free()
			owned = null
			for settle in 8: await process_frame
			_check(reference.get_ref() == null, "actual owned ordinary Field/actors released by normal lifecycle")
		root.get_node("SceneRouter").call("restore_navigation_state", prior_navigation)
		_check(root.get_node("SceneRouter").call("get_navigation_state") == prior_navigation, "managed ordinary navigation restored without slot I/O")
		var audio: Node = root.get_node("AudioManager")
		# A public stop clears the player, not the local WAV held by the real
		# play_music_sting coroutine awaiting its natural <=8-second timer.
		# Observe the existing cached resource, drop our own strong reference,
		# then let normal server/timer frames release it; do not clear caches.
		var audio_script: Script = audio.get_script() as Script
		var victory_path: String = String(audio_script.get_script_constant_map().get("DEFAULT_VICTORY_MUSIC", ""))
		var victory_reference: WeakRef = null
		var victory_cached: bool = not victory_path.is_empty() and ResourceLoader.has_cached(victory_path)
		if victory_cached:
			var existing_sting: Resource = ResourceLoader.load(victory_path, "", ResourceLoader.CACHE_MODE_REUSE)
			if existing_sting != null: victory_reference = weakref(existing_sting)
			existing_sting = null
		var before_stop_alive: bool = victory_reference != null and victory_reference.get_ref() != null
		var audio_stop_started: int = Time.get_ticks_msec()
		for operation: String in ["stop_music_sting", "stop_all_sfx", "stop_dialog_audio"]: audio.call(operation)
		audio.call("stop_bgm", 0.0)
		audio.call("stop_ambience", 0.0)
		await create_timer(.20).timeout
		for settle in 8: await process_frame
		var release_deadline: int = audio_stop_started + 9000
		while victory_reference != null and victory_reference.get_ref() != null and Time.get_ticks_msec() < release_deadline:
			await create_timer(.05).timeout
			await process_frame
		var after_wait_alive: bool = victory_reference != null and victory_reference.get_ref() != null
		exit_audio_evidence = {"source_path": audio_script.resource_path, "source_sha256": FileAccess.get_sha256(audio_script.resource_path), "victory_path": victory_path, "cached_before_public_stops": victory_cached, "weakref_before_stop_alive": before_stop_alive, "weakref_after_natural_wait_alive": after_wait_alive, "elapsed_msec": Time.get_ticks_msec() - audio_stop_started, "deadline_msec": 9000, "public_stop_apis_only": true, "resource_cache_cleared": false}
		_check(not after_wait_alive, "test-exit public audio stops plus <=9sec natural timer frames actually release victory WAV")
	for oracle: RefCounted in owned_oracles.values():
		_check(bool(oracle.call("verify_sources")), "actual source PNG SHA unchanged throughout phase")
		oracle.call("release")
	owned_oracles.clear()
	for entry: Dictionary in entries: entry.erase("actual_scene")
	entries.clear()
	after_files = _snapshot_normal_files()
	var unchanged: bool = before_files.get("files", {}) == after_files.get("files", {})
	_check(unchanged, "fresh normal player save SHA+mtime unchanged; concurrent change must remain explicit evidence")
	_check(int(root.get_node("SaveManager").get("active_slot")) == original_slot, "normal active slot not changed by test")
	result = {"schema": 1, "scope": "JOINT_OUTSKIRTS3_ACTUAL_NORMAL_FIELD_GAMEPLAY_NOT_JOINT_FULL", "requested_phase": requested_phase, "source_complete": failures==0 and runtime_started and actual_battle_returns>=1, "scene_ids":FIELD_IDS.values(), "normal_encounter_rewards_returns":failures==0 and actual_battle_returns>=1, "checks": checks + 1, "failures": failures, "ordinary_Field_executed": runtime_started, "actual_input_count": actual_inputs, "actual_battle_returns": actual_battle_returns, "GPU_screenshots": screenshots, "before_normal_saves": before_files, "after_normal_saves": after_files, "player_saves_unchanged": unchanged, "concurrent_player_updates_not_attributed_to_QA": true, "process_exit_audio": exit_audio_evidence, "resources": evidence, "phase_records": phase_records, "executing_script_path": get_script().resource_path, "executing_script_sha256": FileAccess.get_sha256(get_script().resource_path)}
	_check(_write_checked("result.json", result), "checked honest WIP/preflight result persistence")
	print("V15_OUTSKIRTS_%s: %d checks / %d failures; NO FULL ACCEPTANCE; output=%s" % [requested_phase.to_upper(), checks, failures, output])
	result["checks"]=checks
	result["failures"]=failures
	owner_tree=null
