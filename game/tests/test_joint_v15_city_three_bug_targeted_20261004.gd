extends "res://tests/test_joint_v15_city_gameplay_lifecycle_limited_20261004.gd"
## NEW regression entry only. No LIMITED/FULL/category or visual approval credit.
## Root owns all execution. Ordinary input, actual dialogs/Battle and cleanup remain.
const TARGET_PARENT_PATH: String = "res://tests/test_joint_v15_city_gameplay_lifecycle_limited_20261004.gd"
const TARGET_PARENT_SHA: String = "e7f80739c1b6da1ffd8a15b0a8ba49a42fbdfb0dbf7e32581ccad313eca7a4f1"
const TARGET_SCOPE: String = "TARGETED_THREE_BUG_ACTUAL_INPUT_NOT_LIMITED_NOT_JOINT_FULL"
const GATE_ID: String = "ch4_s0_luoyang_gate"
const YAMEN_ID: String = "ch4_s1_luoyang_yamen"
var loop_records: Array[Dictionary] = []
var owned_audio_exit: Dictionary = {}

func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failed += 1
		push_error("[CITY THREE BUG TARGET FAIL] " + label)
	return ok

func _write(name: String, value: Dictionary) -> bool:
	var written: Dictionary = value.duplicate(true)
	if name == "result.json":
		written["scope"] = TARGET_SCOPE
		written["targeted_complete"] = failed == 0 and int(written.get("failed", 1)) == 0
		written["targeted_ids"] = {"interactions":["luoyang_wanted_board", "luoyang_repeatable_bounty_board"], "npc":"spar_yamen_captain", "portal":"enter_luoyang"}
		written["targeted_input_counts"] = {"board_entity_mouse":2, "captain_space_mouse":2, "same_source_loop_portal_space_mouse":2}
		written["actual_loop_portal_observations"] = loop_records.duplicate(true)
		written["owned_audio_exit_after_all_behavior_assertions"] = owned_audio_exit.duplicate(true)
		written["full_complete"] = false
		written["source_complete"] = false
		written["visual_approved"] = false
		written["targeted_parent_path"] = TARGET_PARENT_PATH
		written["targeted_parent_sha256"] = FileAccess.get_sha256(TARGET_PARENT_PATH)
		written["not_run"] = ["LIMITED_CITY_COMPLETE", "JOINT_FULL", "OTHER_14_NPCS", "OTHER_9_INTERACTIONS", "OTHER_9_NONWORLD_PORTALS", "55_INTERACTION_NEGATIVES", "2_BOUNTY_REWARD_BATTLES", "ALL_OBJECT_GEOMETRY", "80_MIGRATION_CASES", "WORLD15", "OUTSKIRTS", "GPU_VISUAL_APPROVAL"]
	return super._write(name, written)

func _source_snapshot(ready: Dictionary) -> Dictionary:
	var result: Dictionary = super._source_snapshot(ready)
	result[TARGET_PARENT_PATH] = FileAccess.get_sha256(TARGET_PARENT_PATH)
	return result

func _run() -> void:
	before_files = _normal_files()
	before_slot = root.get_node("SaveManager").get("active_slot")
	navigation_before = root.get_node("SceneRouter").call("get_navigation_state")
	output = "res://build/joint_world_luoyang_20261003_qa/city_three_bug_targeted_%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(output) == OK, "unique TARGETED evidence directory")
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_check("--joint-city-three-bug-targeted" in args and "--luoyang-v3-candidate" in args, "explicit targeted + candidate flags required")
	for argument: String in args:
		_check(argument in ["--joint-city-three-bug-targeted", "--luoyang-v3-candidate", "--qa-gpu-approved"], "no unknown/bypass argument: " + argument)
	_check(DisplayServer.get_name() == "headless" or "--qa-gpu-approved" in args, "root explicit GPU authorization required")
	_check(FileAccess.get_sha256(TARGET_PARENT_PATH).to_lower() == TARGET_PARENT_SHA, "exact inherited lifecycle wrapper")
	_check(FileAccess.get_sha256(READY_PATH).to_lower() == READY_SHA, "exact unchanged current23 readiness")
	_check(FileAccess.get_sha256(INPUTS_PATH).to_lower() == INPUTS_SHA, "exact four current grey manifest inputs")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(READY_PATH))
	var ready: Dictionary = parsed as Dictionary if parsed is Dictionary else {}
	_check(ready.get("source_count") == 23 and ready.get("sources") is Array and ready.sources.size() == 23, "exact23 typed closure")
	for entry: Dictionary in ready.get("sources", []):
		_check(FileAccess.get_sha256(String(entry.path)).to_lower() == String(entry.sha256), "frozen current source: " + String(entry.path))
	_check(FileAccess.get_sha256(OWN_PHASE_PATH).to_lower() == OWN_PHASE_SHA, "exact own current-parent adapter")
	_check(FileAccess.get_sha256(BGM_OBSERVER_PATH).to_lower() == BGM_OBSERVER_SHA, "exact independent modulo observer")
	_check(FileAccess.get_sha256("res://scripts/field/field_walkable_controller.gd").to_lower() == "b3301d6064e332e519b0fc3b4daed880ec3d77d98f2c744933b5d7077b9eb8ef", "exact root live viewport and interaction-foot source")
	var dependencies: Variant = ready.get("additional_explicit_dependencies")
	_check(dependencies is Array and dependencies.size() == 2, "two explicit supplemental closure dependencies")
	var dependency_ids: Dictionary = {}
	if dependencies is Array:
		for dependency: Dictionary in dependencies:
			var path: String = String(dependency.get("path", ""))
			var expected_sha: String = OWN_PHASE_SHA if path == OWN_PHASE_PATH else BGM_OBSERVER_SHA if path == BGM_OBSERVER_PATH else ""
			_check(not expected_sha.is_empty() and not dependency_ids.has(path) and dependency.get("sha256") == expected_sha and FileAccess.get_sha256(path).to_lower() == expected_sha, "exact extra dependency: " + path)
			dependency_ids[path] = true
	source_before = _source_snapshot(ready)
	_check(not source_before.values().has("MISSING"), "all actually referenced source/art bytes present")
	if failed > 0: await _finish(ready); return
	var oracle_script: GDScript = load(ORACLE_PATH) as GDScript
	if not _check(oracle_script != null and oracle_script.can_instantiate(), "autoload-context independent source oracle"): await _finish(ready); return
	var oracle: RefCounted = oracle_script.new() as RefCounted
	preflight = oracle.call("run", INPUTS_PATH, "city")
	checks += int(preflight.get("checks", 0))
	failed += int(preflight.get("failures", 1))
	_check(_write("four_city_source_preflight.json", preflight), "source preflight checked readback, not Field credit")
	oracle = null
	oracle_script = null
	if failed > 0: await _finish(ready); return
	var adapter: GDScript = load(OWN_PHASE_PATH) as GDScript
	if not _check(adapter != null and adapter.can_instantiate(), "exact current adapter loads"): await _finish(ready); return
	phase = adapter.new() as RefCounted
	adapter = null
	phase.set("tree", self)
	phase.set("candidate", true)
	phase.set("output", output)
	phase.set("before_files", phase.call("_normal_files"))
	phase.set("before_slot", before_slot)
	var input_script: GDScript = load(INPUT_PATH) as GDScript
	if not _check(input_script != null and input_script.can_instantiate(), "normal real input driver loads"): await _finish(ready); return
	var driver: RefCounted = input_script.new() as RefCounted
	driver.call("configure", self)
	phase.set("driver", driver)
	driver = null
	input_script = null
	source_subject = load(SUBJECT_PATH) as Script
	if not _check(source_subject != null and source_subject.can_instantiate(), "immutable actual city identity source"): await _finish(ready); return
	var gate: SceneScript = source_subject.call("legacy_scene", StringName(GATE_ID)) as SceneScript
	var yamen: SceneScript = source_subject.call("legacy_scene", StringName(YAMEN_ID)) as SceneScript
	if not _check(gate != null and yamen != null, "original gate/yamen resources"): await _finish(ready); return
	var clue: Dictionary = _original(gate.map_layout.interactions, "id", "luoyang_wanted_board")
	var board: Dictionary = _original(gate.map_layout.interactions, "id", "luoyang_repeatable_bounty_board")
	var captain: Dictionary = _original(yamen.npcs, "npc_id", "spar_yamen_captain")
	var portal: Dictionary = _original(gate.map_layout.portals, "id", "enter_luoyang")
	_check(clue.get("action") == "dialog:ch4_case_clue" and board.get("action") == "bounty_board:luoyang", "exact original board dialog and real board UI actions")
	_check(String(captain.get("interaction_action", "")).begins_with("spar:yamen_captain:boss_luoyang_captain:"), "exact captain genuine spar source")
	_check(portal.get("target_scene") == YAMEN_ID and gate.bgm_path == yamen.bgm_path, "exact ordinary same-authored-BGM city portal")
	if failed > 0: await _finish(ready); return
	phase.call("_public_fixture", {})
	root.get_node("SceneRouter").call("reset_for_new_game")
	baseline_navigation = root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
	phase.call("_connect_events")
	# Both ordinary board paths: actual DialogBox child and real BountyEntries UI.
	for entry: Dictionary in [clue, board]:
		await phase.call("_normal_action_case", GATE_ID, "interactions", entry, "mouse")
	for mode: String in ["space", "mouse"]:
		await phase.call("_normal_action_case", YAMEN_ID, "npcs", captain, mode)
	for mode: String in ["space", "mouse"]:
		await _loop_portal(portal, mode)
	action_records = (phase.get("records") as Dictionary).duplicate(true)
	_check((action_records.get("interactions", []) as Array).size() == 2 and (action_records.get("npcs", []) as Array).size() == 2 and loop_records.size() == 2, "all six exact targeted input records, not aggregate15/11/10 credit")
	for row: Dictionary in action_records.get("interactions", []):
		var input: Dictionary = row.get("actual_input", {})
		_check(row.get("mode") == "mouse" and row.get("dry_run") == false and float(input.get("alpha", 0)) > .12 and bool((input.get("source_identity_before_input", {}) as Dictionary).get("alpha_sampled_before_input", false)), "board click uses actual strong current alpha frozen BEFORE scene change")
	for row: Dictionary in action_records.get("npcs", []):
		_check(row.get("source_id") == "spar_yamen_captain" and row.get("dry_run") == false and bool((row.get("effects", {}) as Dictionary).get("returned", false)), "captain real result UI exact-foot return in each input mode")
	_check(_write("targeted_actions_and_loop.json", {"scope":TARGET_SCOPE, "actions":action_records, "loop_portals":loop_records}), "all actual targeted evidence persisted without overwrite")
	await _finish(ready)

func _original(entries: Array, key: String, identity: String) -> Dictionary:
	var matches: Array[Dictionary] = []
	for entry: Dictionary in entries:
		if String(entry.get(key, "")) == identity: matches.append(entry)
	_check(matches.size() == 1, "unique original target identity: " + identity)
	return matches[0].duplicate(true) if matches.size() == 1 else {}

func _loop_portal(entry: Dictionary, mode: String) -> void:
	phase.call("_public_fixture", entry)
	if not await phase.call("_open", GATE_ID): return
	var manifest: Dictionary = phase.get("manifest")
	var slot: Dictionary = phase.call("_slot", manifest.gameplay_slots.portals, String(entry.id))
	var point: Vector2 = phase.call("_point", slot.get("foot_px"))
	var probe: RefCounted = phase.get("probe") as RefCounted
	var approach: Dictionary = await probe.call("move_to", point)
	if not _check(bool(approach.get("ok", false)), "actual875/17/Physics input reaches loop portal " + mode): return
	var source_field: Node = phase.get("field") as Node
	var foot: Vector2 = (source_field.get("_player") as Node2D).position
	var zone: Node
	for node: Node in source_field.get("_exit_nodes"):
		if String(node.name) == "Exit_" + String(entry.id) or String(node.get_meta("portal_id", "")) == String(entry.id): zone = node
	# Normal production ExitZone instances have automatic node names and no
	# portal_id metadata. Bind the actual enabled scene action plus its exact
	# authored station; never infer overlap from a source polygon alone.
	if zone == null:
		var matches: Array[Node] = []
		for node: Node in source_field.get("_exit_nodes"):
			if node is Node2D and String(node.get("target_scene_id")) == String(entry.get("target_scene", "")) and not bool(node.get("is_locked")) and (node as Node2D).position.distance_to(point) < .001:
				matches.append(node)
		_check(matches.size() == 1, "unique real enabled target and exact authored portal station")
		if matches.size() == 1: zone = matches[0]
	if not _check(zone != null and bool(zone.get("_in_range")), "real enabled area Physics overlap before timed ordinary input"): return
	var observer_script: GDScript = load(BGM_OBSERVER_PATH) as GDScript
	var observer: RefCounted = observer_script.new() as RefCounted
	var start: Dictionary = observer.call("begin_observation", self, "actual48s_enter_luoyang_" + mode, 65.0)
	var first: Dictionary = start.get("before", {})
	var period: float = float(first.get("loop_period_sec", 0))
	_check(bool(start.get("ok", false)) and period == 48.0 and float(first.get("stream_length_sec", 0)) == 48.0, "actual source WAV length and loop frames are48s, not fabricated metadata")
	# The helper's contract is the transition interval, not a whole idle loop.
	# Preserve the readiness snapshot, disconnect before the natural idle wait,
	# and begin a fresh strict observation immediately before actual input.
	# No audio mutation or tolerance adjustment is made.
	var readiness_start: Dictionary = start.duplicate(true)
	observer.call("release")
	var audio: Node = root.get_node("AudioManager")
	var bgm: AudioStreamPlayer = audio.get("bgm_player") as AudioStreamPlayer
	var limit: int = Time.get_ticks_usec() + 50000000
	var ready: bool = false
	var frames: int = 0
	# Natural real audio elapsed only; no seek/play/stop/timer, no artificial clock.
	while bool(start.get("ok", false)) and period == 48.0 and Time.get_ticks_usec() < limit:
		if not is_instance_valid(source_field) or current_scene != source_field or not is_instance_valid(bgm): break
		var remaining: float = float(first.get("loop_end_sec", 0)) - bgm.get_playback_position()
		if remaining > 0 and remaining <= .5: ready = true; break
		await process_frame
		frames += 1
	_check(ready, "natural playback reaches actual loop_end within0.5s under finite50s preparation")
	if ready:
		start = observer.call("begin_observation", self, "actual48s_enter_luoyang_boundary_" + mode, 40.0)
		_check(bool(start.get("ok", false)), "fresh observation begins at actual transition boundary")
		for key: String in ["path", "player_id", "stream_id", "stream_source_sha256", "request_id"]:
			_check(start.get("before", {}).get(key) == first.get(key), "natural preparation preserved actual audio identity: " + key)
	var before_input: Dictionary = observer.call("_snapshot")
	var actual_input: Dictionary = {"mode":mode}
	var entered: bool = false
	var pre_input_feet: Dictionary = {}
	if ready:
		var actual_foot: Vector2 = (source_field.get("_player") as Node2D).position
		pre_input_feet = {"actual_foot_px":[actual_foot.x, actual_foot.y], "raw875_and17":probe.call("raw_evidence", actual_foot), "actual_physics_clear":probe.call("physical_clear", actual_foot), "zone_in_range":bool(zone.get("_in_range"))}
		_check(actual_foot.distance_to(foot) < .03 and bool(probe.call("clear", actual_foot)) and bool(zone.get("_in_range")), "idle wait still has exact foot/full875/17/actualPhysics and enabled portal")
		var actual_driver: RefCounted = phase.get("driver") as RefCounted
		if mode == "space": await actual_driver.call("key", KEY_SPACE)
		else:
			var container: Node2D = source_field.get("world_container") as Node2D
			actual_input = await actual_driver.call("pointer", container.get_global_transform_with_canvas() * point)
		entered = await phase.call("_wait_field", YAMEN_ID)
		_check(entered, "normal loop-boundary portal arrives exact yamen, no Router shortcut")
	# Require actual wrap through the observed before/after input interval, even
	# when destination became ready before the mixer advanced its final quantum.
	var after_limit: int = Time.get_ticks_usec() + 3000000
	while entered and is_instance_valid(bgm) and Time.get_ticks_usec() < after_limit and bgm.get_playback_position() >= float(before_input.get("position_sec", 0)):
		await process_frame
	var observed: Dictionary = observer.call("finish_observation")
	observer.call("release")
	observer = null
	observer_script = null
	var final_samples: Array = observed.get("samples", [])
	var last: Dictionary = final_samples[-1] if not final_samples.is_empty() else {}
	var wrap: bool = float(before_input.get("position_sec", 0)) > 47.0 and float(last.get("position_sec", 48)) < float(before_input.get("position_sec", 0)) and int((observed.get("whole_observation_progress", {}) as Dictionary).get("inferred_wrap_count", 0)) >= 1
	_check(entered and bool(observed.get("ok", false)) and wrap, "real48s loop spans ordinary portal input with exact identity/event/no-stop and modulo elapsed predicate")
	var back: Dictionary = {"not_run":true}
	if entered:
		await phase.call("_finish_dialogs")
		back = await phase.call("_return_from_target", GATE_ID)
		_check(bool(back.get("returned", false)), "real reverse area input returns gate after loop proof")
		if bool(back.get("returned", false)):
			await phase.call("_finish_dialogs")
			var returned_field: Node = phase.get("field") as Node
			_check((returned_field.get("_player") as Node2D).position.distance_to(foot) < .03, "normal reverse return preserves exact pre-input foot")
			phase.call("_bind_field", GATE_ID)
	await phase.call("_capture", "target_actual48s_loop_" + mode)
	loop_records.append({"mode":mode, "portal_id":String(entry.id), "source":GATE_ID, "target":YAMEN_ID, "dry_run":false, "approach":approach, "source_foot_px":[foot.x, foot.y], "natural_prepare_frames":frames, "natural_preparation_snapshot_not_continuity_credit":readiness_start, "before_input":before_input, "pre_input_feet":pre_input_feet, "actual_input":actual_input, "entered":entered, "bgm_started":start, "bgm_observation":observed, "real_wrap_across_input":wrap, "return":back})

func _finish(ready: Dictionary) -> void:
	# ROOT124 leaked the still-playing ceremony WAV/playback at process exit.
	# Use normal public shutdown ONLY after all gameplay/continuity observations
	# have finished. This does not cancel a production timer or alter any test
	# playhead, and cannot be counted as continuity evidence.
	var audio: Node = root.get_node_or_null("AudioManager")
	var before: Array[Dictionary] = []
	if audio != null:
		for key: String in ["_bgm_player_a", "_bgm_player_b"]:
			var player: AudioStreamPlayer = audio.get(key) as AudioStreamPlayer
			before.append({"key":key, "playing":player != null and player.playing, "stream_path":player.stream.resource_path if player != null and player.stream != null else ""})
		await audio.call("stop_bgm", .15)
		# Allow the real mixer to drain its stopped playback references.
		var drain_until: int = Time.get_ticks_usec() + 250000
		while Time.get_ticks_usec() < drain_until: await process_frame
		var after: Array[Dictionary] = []
		for key: String in ["_bgm_player_a", "_bgm_player_b"]:
			var player: AudioStreamPlayer = audio.get(key) as AudioStreamPlayer
			var released: bool = player != null and not player.playing and player.stream == null
			_check(released, "owned public audio shutdown after all behavior checks releases both BGM streams")
			after.append({"key":key, "playing":player != null and player.playing, "stream_null":player != null and player.stream == null})
		owned_audio_exit = {"scope":"EXIT_LIFECYCLE_ONLY_NOT_CONTINUITY_PROOF", "before":before, "after":after, "public_API":"AudioManager.stop_bgm(.15)", "natural_mix_drain_usec":250000, "production_source_or_timer_changed":false}
	await super._finish(ready)
