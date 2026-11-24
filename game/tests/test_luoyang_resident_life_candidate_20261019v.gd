extends SceneTree
## QA-only CPU candidate atom. No Field, UI, game reset, resource override or save write.
const API_PATH := "res://scripts/city/luoyang_resident_life_candidate_20261019v.gd"
const MANIFEST := "res://data/luoyang_residents_20261019v/manifest.json"
const BUDGET_MS := 30000
var checks := 0
var failures := 0
var began := 0
var records: Array = []
var source_before: Dictionary = {}
var players_before: Dictionary = {}
var dependency_before: Dictionary = {}
var state_before: Dictionary = {}
var finished := false
var api: Script

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String, detail: Variant = null) -> bool:
	checks += 1
	if not value:
		failures += 1
		printerr("RESIDENT_LIFE_QA_FAIL ", label, " ", detail)
	return value

func fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"exists": false, "sha256": "ABSENT", "bytes": 0, "mtime_seconds_string": "0"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"exists": false, "sha256": "OPEN_FAILED", "bytes": 0, "mtime_seconds_string": "0"}
	var length := file.get_length()
	file.close()
	return {"exists": true, "sha256": FileAccess.get_sha256(path), "bytes": length, "mtime_seconds_string": str(FileAccess.get_modified_time(path))}

func snapshot(paths: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for path: String in paths:
		result[path] = fact(path)
	return result

func saves() -> Dictionary:
	var result: Dictionary = {}
	for slot: int in 5:
		for suffix: String in [".json", ".json.bak", ".json.tmp"]:
			var path := "user://save_" + str(slot) + suffix
			result[path] = fact(path)
	return result

func state() -> Dictionary:
	return {"flags": root.get_node("GameState").get("flags").duplicate(true), "quests": root.get_node("QuestManager").call("to_dict").duplicate(true), "inventory": root.get_node("Inventory").call("to_dict").duplicate(true)}

func reject(result: Dictionary, error: String, label: String) -> void:
	check(result.get("ok") == false and result.get("error") == error, label, result)

func _run() -> void:
	began = Time.get_ticks_msec()
	create_timer(30.0).timeout.connect(_timeout)
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	players_before = saves()
	state_before = state()
	dependency_before = snapshot({get_script().resource_path: true, "res://scripts/domain/dialog_script.gd": true, "res://scripts/domain/dialog_node.gd": true})
	api = load(API_PATH)
	if check(api != null, "Actual candidate Script loads"):
		var ready: Dictionary = api.readiness()
		if check(ready.get("ok") == true, "Actual pinned manifest readiness", ready):
			var paths: Dictionary = api.source_paths()
			check(paths.size() == 14 and paths.has(API_PATH) and paths.has(MANIFEST), "Exact fourteen candidate source leaves")
			source_before = snapshot(paths)
			check(api.FORMAL_ENABLED == false and not api.enabled() and OS.get_cmdline_user_args().is_empty(), "Candidate disabled without flags; no formal authority")
			check(ready.residents.size() == 4 and ready.source_sha256.size() == 12, "Four identities and twelve authored dialogues")
			for path: String in ready.source_sha256:
				check(source_before[path].exists and source_before[path].sha256 == ready.source_sha256[path], "Independent exact dialogue SHA " + path)
			_test_dialogues(ready)
			_test_stages(ready)
			_test_projection(ready)
	_finish(false)

func _test_dialogues(ready: Dictionary) -> void:
	var total_nodes := 0
	var seen_dialogs: Dictionary = {}
	for id: String in ready.residents:
		var row: Dictionary = ready.residents[id]
		for phase: String in ["daily", "uncertain", "after"]:
			var path: String = row.dialogs[phase]
			var resource: Resource = load(path)
			if not check(resource != null and resource.get_script().resource_path == "res://scripts/domain/dialog_script.gd", "Actual DialogScript resource " + path):
				continue
			var expected_id := path.get_file().get_basename()
			check(String(resource.dialog_id) == expected_id and not seen_dialogs.has(expected_id), "Unique actual dialog_id equals file stem " + expected_id)
			seen_dialogs[expected_id] = true
			check(resource.nodes.size() == 2 and resource.entry_node_id == &"start", "Exactly two authored native nodes " + expected_id)
			var expected_story_flag: String = "" if phase == "daily" else String(row.progress.active_flags[0] if phase == "uncertain" else row.progress.completed_flags[0])
			var expected_completed_quest: String = String(row.progress.quest_id) if phase == "after" else ""
			check(String(resource.required_story_flag) == expected_story_flag and String(resource.required_completed_quest) == expected_completed_quest and resource.fallback_dialog_id == &"" and resource.blocked_story_flag == &"" and resource.required_free_inventory_slots == 0, "Exact authored phase gates; no extra gating " + expected_id)
			var node_ids: Dictionary = {}
			for node: Resource in resource.nodes:
				total_nodes += 1
				check(node.get_script().resource_path == "res://scripts/domain/dialog_node.gd", "Actual native DialogNode " + expected_id)
				check(not node_ids.has(node.node_id), "Unique node id " + expected_id)
				node_ids[node.node_id] = true
				check(node.speaker == row.name and not node.text.strip_edges().is_empty(), "Identity speaker and nonempty local-life text " + expected_id)
				var expected_emotion: String = "concerned" if phase == "uncertain" else "normal"
				check(node.portrait_path == "" and node.voice_emotion == expected_emotion, "Exact phase voice emotion; unapproved portrait not attached " + expected_id)
				for field: String in ["choices", "give_items", "set_flags", "learn_skills", "add_evidence", "verify_evidence", "add_testimonies", "verify_testimonies", "faction_trust_changes", "companion_trust_changes", "bond_events", "city_outcomes", "method_flags"]:
					check(node.get(field).is_empty(), "No side-effect array " + expected_id + "/" + field)
				check(node.give_gold == 0 and node.accept_quest == &"" and node.complete_quest == &"" and node.weather_id == &"", "No rewards, quest transitions or weather " + expected_id)
			check(node_ids.size() == 2 and node_ids.has(&"start") and node_ids.has(&"reply"), "Exact two-node graph " + expected_id)
			var start: Resource = resource.call("get_entry_node")
			var reply: Resource = resource.call("find_node_by_id", &"reply")
			check(start != null and reply != null and start.on_end == "next:reply" and reply.on_end == "end", "Actual entry and terminal chain " + expected_id)
	check(total_nodes == 24 and seen_dialogs.size() == 12, "Twelve native dialogues and twenty-four native nodes")
	records.append({"kind": "NATIVE_DIALOGUES", "dialogs": seen_dialogs.size(), "nodes": total_nodes, "side_effects": false, "portrait_audio_credit": false})

func _test_stages(ready: Dictionary) -> void:
	for id: String in ready.residents:
		var row: Dictionary = ready.residents[id]
		var progress: Dictionary = row.progress
		var active: Dictionary = {}
		var completed: Dictionary = {}
		for key: String in progress.active_flags: active[key] = true
		for key: String in progress.completed_flags: completed[key] = true
		var scenarios: Array = [
			[{}, {}, "daily"], [active, {progress.quest_id: 1}, "uncertain"], [completed, {progress.quest_id: 2}, "after"],
			[completed, {}, "daily"], [completed, {progress.quest_id: 0}, "daily"], [{}, {progress.quest_id: 2}, "daily"],
			[{}, {progress.quest_id: 1}, "daily"], [active, {progress.quest_id: 3}, "daily"]]
		for scenario: Array in scenarios:
			var flags: Dictionary = scenario[0].duplicate(true)
			var quests: Dictionary = scenario[1].duplicate(true)
			var flags_before := flags.duplicate(true)
			var quests_before := quests.duplicate(true)
			var selected: Dictionary = api.stage(id, flags, quests)
			check(selected.get("ok") == true and selected.stage == scenario[2] and selected.dialog_path == row.dialogs[scenario[2]], "Exact guarded phase " + id + "/" + str(scenario[2]), selected)
			check(flags == flags_before and quests == quests_before, "Selector input has no mutations " + id)
			check(api.dialog_for(id, flags, quests) == selected, "dialog_for delegates exact stage " + id)
			var choices: Dictionary = api.choices_for(id, flags, quests)
			check(choices.get("ok") == true and choices.choices.size() == 1 and choices.choices[0].dialog_id == selected.dialog_id and choices.requires_separate_conversation_menu == (id == "luoyang_paper_artisan_20261016"), "Separate paper-task menu plan, not Field integration " + id)
		for invalid: Variant in [true, "1", 1.0, -1, 4, null]:
			reject(api.stage(id, {}, {progress.quest_id: invalid}), "RESIDENT_QUEST_STATE_NOT_ENUM_INT", "Reject malformed quest enum " + id + "/" + str(invalid))
		for group: String in ["active_flags", "completed_flags"]:
			for invalid: Variant in ["true", 1, null]:
				var flags: Dictionary = {progress[group][0]: invalid}
				reject(api.stage(id, flags, {}), "RESIDENT_FLAG_NOT_BOOL:" + progress[group][0], "Reject malformed flag " + id + "/" + group)
	reject(api.stage("unregistered_resident", {}, {}), "RESIDENT_UNKNOWN_ID", "Unknown resident rejected")

func _source_rows(scene_id: String, ready: Dictionary) -> Array:
	var rows: Array = [{"npc_id": "unrelated_existing_npc", "dialog_id": "old_dialog", "source_pos": Vector2(123, 456), "keep_nested": {"a": [1, 2]}}]
	for id: String in ready.residents:
		if ready.residents[id].scene_id != scene_id: continue
		var row: Dictionary = {"npc_id": id, "name": ready.residents[id].name, "pos": Vector2(0.4, 0.6), "body": Vector2(34, 30), "scale": 1.0, "patrol": [Vector2(1, 2), Vector2(3, 4)], "portrait": "existing_portrait", "dialog_variants": []}
		if id == "luoyang_paper_artisan_20261016":
			row["dialog_id"] = "luoyang_city_tasks_20261016/paper_hint"
			row["interaction_action"] = ""
		rows.append(row)
	return rows

func _test_projection(ready: Dictionary) -> void:
	for scene_id: String in ["ch4_s3_luoyang_market", "ch4_s2_canal_docks", "ch4_s0_luoyang_gate"]:
		var original := _source_rows(scene_id, ready)
		var unchanged := original.duplicate(true)
		var projected: Dictionary = api.project_copy(StringName(scene_id), original, {}, {})
		if not check(projected.get("ok") == true, "Actual pure scene projection " + scene_id, projected): continue
		check(projected.production_hook_present == false and projected.candidate_only == true and projected.formal_enabled == false, "Projection refuses formal/Field credit " + scene_id)
		check(original == unchanged and projected.npcs.size() == original.size(), "Original input rows are never mutated " + scene_id)
		check(projected.conversation_choice_plans.size() == original.size() - 1, "Every existing candidate identity has one plan " + scene_id)
		for i: int in original.size():
			var before: Dictionary = original[i]
			var after: Dictionary = projected.npcs[i]
			if before.npc_id == "luoyang_paper_artisan_20261016" or before.npc_id == "unrelated_existing_npc":
				check(after == before, "Existing task-primary and unrelated NPC stay exact " + String(before.npc_id))
			else:
				var restored := after.duplicate(true)
				if before.has("dialog_id"): restored.dialog_id = before.dialog_id
				else: restored.erase("dialog_id")
				check(restored == before and String(after.dialog_id).begins_with("ch4_resident_v_"), "Only dialog_id changes; geometry, identity, patrol and portrait exact " + String(before.npc_id))
		var duplicate := original.duplicate(true)
		duplicate.append(original[1].duplicate(true))
		reject(api.project_copy(StringName(scene_id), duplicate, {}, {}), "RESIDENT_DUPLICATE_SOURCE_ID", "Duplicate identity rejected " + scene_id)
		var missing := original.duplicate(true)
		missing.remove_at(1)
		reject(api.project_copy(StringName(scene_id), missing, {}, {}), "RESIDENT_EXPECTED_SOURCE_NPC_MISSING", "Missing identity rejected " + scene_id)
		var wrong := original.duplicate(true)
		wrong.append("not-a-row")
		reject(api.project_copy(StringName(scene_id), wrong, {}, {}), "RESIDENT_NPC_ROW_NOT_DICTIONARY", "Malformed NPC row rejected " + scene_id)
		for key: String in ["dialog_id", "interaction_action", "dialog_variants"]:
			var collision := original.duplicate(true)
			var index := 2 if scene_id == "ch4_s3_luoyang_market" else 1
			# Select an ordinary resident rather than assuming Dictionary iteration order.
			for i: int in collision.size():
				if collision[i].npc_id != "unrelated_existing_npc" and collision[i].npc_id != "luoyang_paper_artisan_20261016": index = i
			collision[index][key] = ["existing"] if key == "dialog_variants" else "existing"
			reject(api.project_copy(StringName(scene_id), collision, {}, {}), "RESIDENT_WOULD_OVERWRITE_EXISTING_CONVERSATION", "Never overwrite old conversation " + scene_id + "/" + key)
	reject(api.project_copy(&"unsupported_scene", [], {}, {}), "RESIDENT_UNSUPPORTED_SCENE", "Unsupported scene rejected")
	var paper := _source_rows("ch4_s3_luoyang_market", ready)
	for row: Dictionary in paper:
		if row.npc_id == "luoyang_paper_artisan_20261016": row.dialog_id = "unrelated_task"
	reject(api.project_copy(&"ch4_s3_luoyang_market", paper, {}, {}), "RESIDENT_PAPER_PRIMARY_SOURCE_CHANGED", "Paper task primary identity protected")

func _timeout() -> void:
	if not finished: _finish(true)

func _finish(timed_out: bool) -> void:
	if finished: return
	finished = true
	var source_after := snapshot(source_before)
	var dependency_after := snapshot(dependency_before)
	var players_after := saves()
	check(source_before.size() == 14 and source_before == source_after, "All fourteen candidate source facts first/final exact")
	check(dependency_before == dependency_after, "QA key and native domain source facts first/final exact")
	check(players_before.size() == 15 and players_before == players_after, "All fifteen existing OR missing real save facts first/final exact; no restore")
	check(state_before == state(), "Whole actual flags, quest and inventory state unchanged")
	check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended") == true, "Checkpoint save protection remains active")
	check(not timed_out and Time.get_ticks_msec() - began < BUDGET_MS, "Fixed thirty-second CPU-only atom")
	var folder := "res://build/luoyang_resident_life_candidate_20261019v/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join("result.json")
	var report := {"scope": "CANDIDATE_SELECTOR_AND_TWELVE_NATIVE_DIALOGUES_ONLY", "complete": failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "budget_ms": BUDGET_MS, "source_before": source_before, "source_after": source_after, "dependency_before": dependency_before, "dependency_after": dependency_after, "players_before": players_before, "players_after": players_after, "state_before": state_before, "state_after": state(), "records": records, "Field_GPU_UI_audio_portrait_credit": false, "formal_credit": false, "mtime_precision": "Godot seconds encoded as strings, not Windows exact UTC ticks"}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print(JSON.stringify({"resident_life_qa_result": path, "complete": failures == 0, "checks": checks, "failures": failures}))
	quit(0 if failures == 0 else 1)
