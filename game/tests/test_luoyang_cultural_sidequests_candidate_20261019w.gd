extends SceneTree
## QA candidate CPU atom only. No Field, UI, game reset, saves, rewards or catalog injection.
const READY := true
const API_PATH := "res://scripts/city/luoyang_cultural_sidequests_candidate_20261019w.gd"
const API_SHA := "f1ab01d8d8ca1b31ffba178b1b1fa8fca661e598741ce5c84f37b029cc9614ac"
const MANIFEST_PATH := "res://data/luoyang_culture_candidates_20261019w/manifest.json"
const MANIFEST_SHA := "7fa69f44d8e176832ba5a2c177565905a335753654761dda575459a0c64bdf35"
const BUDGET_MS := 30000
const SPEAKERS := ["候见乡民", "书办", "货担主人", "南市书生", "记货伙计", "采买妇人"]
var checks := 0
var failures := 0
var began := 0
var records: Array = []
var source_before: Dictionary = {}
var dependency_before: Dictionary = {}
var players_before: Dictionary = {}
var state_before: Dictionary = {}
var finished := false
var api: Script

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String, detail: Variant = null) -> bool:
	checks += 1
	if not value:
		failures += 1
		printerr("CULTURAL_SIDEQUEST_QA_FAIL ", label, " ", detail)
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
	for path: String in paths: result[path] = fact(path)
	return result

func saves() -> Dictionary:
	var result: Dictionary = {}
	for slot: int in 5:
		for suffix: String in [".json", ".json.bak", ".json.tmp"]:
			var path := "user://save_" + str(slot) + suffix
			result[path] = fact(path)
	return result

func game_state() -> Dictionary:
	return {"flags": root.get_node("GameState").get("flags").duplicate(true), "quests": root.get_node("QuestManager").call("to_dict").duplicate(true), "inventory": root.get_node("Inventory").call("to_dict").duplicate(true)}

func _run() -> void:
	began = Time.get_ticks_msec()
	create_timer(30.0).timeout.connect(_timeout)
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	players_before = saves()
	state_before = game_state()
	dependency_before = snapshot({get_script().resource_path: true, "res://scripts/domain/quest_def.gd": true, "res://scripts/domain/dialog_script.gd": true, "res://scripts/domain/dialog_node.gd": true})
	if check(READY and OS.get_cmdline_user_args().is_empty(), "Frozen candidate CPU atom only; no user flags"):
		if not check(FileAccess.get_sha256(API_PATH) == API_SHA and FileAccess.get_sha256(MANIFEST_PATH) == MANIFEST_SHA, "Exact approved module and final manifest freeze"):
			_finish(false)
			return
		api = load(API_PATH)
		if check(api != null, "Actual pure candidate reducer loads"):
			var ready: Dictionary = api.readiness()
			if check(ready.get("ok") == true, "Pinned full candidate readiness", ready):
				var paths: Dictionary = api.source_paths()
				source_before = snapshot(paths)
				check(paths.size() == 26 and paths.has(API_PATH) and paths.has(MANIFEST_PATH), "Exact twenty-six runtime leaves, not an incomplete subset")
				_test_resources(paths)
				_test_state_machine(ready)
	_finish(false)

func _test_resources(paths: Dictionary) -> void:
	var quests := 0
	var dialogs := 0
	var nodes := 0
	var dialog_ids: Dictionary = {}
	var quest_ids: Dictionary = {}
	for path: String in paths:
		if not path.ends_with(".tres"): continue
		var resource: Resource = load(path)
		if not check(resource != null, "Actual native authored resource " + path): continue
		if path.begins_with("res://data/quests/luoyang_culture_candidates_20261019w/"):
			quests += 1
			check(resource.get_script().resource_path == "res://scripts/domain/quest_def.gd" and not quest_ids.has(resource.quest_id), "Unique native QuestDef " + path)
			quest_ids[resource.quest_id] = true
			check(resource.completion_triggers.is_empty() and resource.auto_accept_triggers.is_empty() and resource.progress_records.is_empty(), "No automatic accept, progress or completion trigger " + path)
			check(resource.reward_gold == 0 and resource.reward_exp == 0 and resource.reward_items.is_empty() and resource.reward_skills.is_empty() and resource.reward_skills_by_faction.is_empty() and resource.reward_skills_by_flag.is_empty(), "All QuestDef reward channels zero pending balance approval " + path)
			check(resource.get_meta("culture_candidate_status", "") == "CANDIDATE_NOT_FORMAL" and resource.get_meta("culture_reward_status", "") == "ZERO_PENDING_BALANCE_APPROVAL", "QuestDef candidacy and unapproved rewards explicit " + path)
		elif path.begins_with("res://data/dialogs/luoyang_culture_candidates_20261019w/"):
			dialogs += 1
			check(resource.get_script().resource_path == "res://scripts/domain/dialog_script.gd" and not dialog_ids.has(resource.dialog_id), "Unique native DialogScript " + path)
			dialog_ids[resource.dialog_id] = true
			check(resource.get_meta("culture_candidate_status", "") == "CANDIDATE_NOT_FORMAL", "Dialogue candidacy explicit " + path)
			check(resource.required_story_flag == &"" and resource.required_completed_quest == &"" and resource.fallback_dialog_id == &"" and resource.blocked_story_flag == &"" and resource.required_free_inventory_slots == 0, "Dialogue resources have no hidden gating side channels " + path)
			var by_id: Dictionary = {}
			for node: Resource in resource.nodes:
				nodes += 1
				check(node.get_script().resource_path == "res://scripts/domain/dialog_node.gd" and not by_id.has(String(node.node_id)), "Unique actual native dialogue node " + path)
				by_id[String(node.node_id)] = node
				check(node.speaker in SPEAKERS and not node.text.strip_edges().is_empty(), "Real local-resident speaker and nonempty line " + path)
				check(node.portrait_path == "" and _explicit_emotion_valid(node), "No unapproved portrait; explicit author emotion belongs to native DialogNode enum " + path)
				for field: String in ["choices", "give_items", "set_flags", "learn_skills", "add_evidence", "verify_evidence", "add_testimonies", "verify_testimonies", "faction_trust_changes", "companion_trust_changes", "bond_events", "city_outcomes", "method_flags"]:
					check(node.get(field).is_empty(), "No node side effect " + path + "/" + field)
				check(node.give_gold == 0 and node.accept_quest == &"" and node.complete_quest == &"" and node.weather_id == &"", "No rewards, accept, completion or weather " + path)
			var reached: Dictionary = {}
			var next_id := String(resource.entry_node_id)
			while by_id.has(next_id) and not reached.has(next_id):
				reached[next_id] = true
				var node: Resource = by_id[next_id]
				if node.on_end == "end":
					next_id = ""
					break
				if not check(node.on_end.begins_with("next:"), "Only local node transitions " + path): break
				next_id = node.on_end.trim_prefix("next:")
			check(next_id == "" and reached.size() == by_id.size() and reached.size() == resource.nodes.size(), "Actual complete acyclic native node chain " + path)
		else:
			check(false, "Runtime resources stay only within candidate subdirectories", path)
	check(quests == 3 and dialogs == 21 and nodes == 31, "All three native QuestDefs, twenty-one DialogScripts and thirty-one nodes loaded")
	records.append({"kind": "NATIVE_RESOURCES", "quests": quests, "dialogs": dialogs, "nodes": nodes, "all_effects_zero": true, "media_Field_formal_credit": false})

func _explicit_emotion_valid(node: Resource) -> bool:
	if typeof(node.voice_emotion) != TYPE_STRING or node.voice_emotion == "auto": return false
	for property: Dictionary in node.get_property_list():
		if property.name == "voice_emotion":
			return property.type == TYPE_STRING and property.hint == PROPERTY_HINT_ENUM and node.voice_emotion in String(property.hint_string).split(",")
	return false

func _roundtrip(value: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(value))
	check(parsed is Dictionary, "Every state step survives actual JSON serialization")
	return parsed if parsed is Dictionary else {}

func _event(qid: String, current: Dictionary, event: Dictionary, expected_error: String = "") -> Dictionary:
	var incoming := _roundtrip(current)
	var before := JSON.stringify(incoming)
	var event_before := JSON.stringify(event)
	var result: Dictionary = api.transition(qid, incoming, event)
	check(JSON.stringify(incoming) == before and JSON.stringify(event) == event_before, "Reducer never mutates caller state or event " + qid + "/" + str(event.get("type")))
	check(result.get("candidate_only") == true and result.get("formal_enabled") == false and result.get("actual_reward_granted") == false, "Every outcome explicitly has no formal or actual reward authority")
	if expected_error != "":
		check(result.get("ok") == false and result.get("error") == expected_error, "Exact refusal " + expected_error, result)
	else:
		check(result.get("ok") == true and result.get("state") is Dictionary, "Legal JSON-roundtripped state transition " + qid + "/" + str(event.get("type")), result)
		check(result.get("actual_world_presence_verified") == false, "Plain candidate event does not prove actual recipient presence")
		if result.get("state") is Dictionary:
			result["state"] = _roundtrip(result.state)
	return result

func _discover_event(clue: Dictionary) -> Dictionary:
	return {"type": "discover", "clue_id": clue.id, "scene_id": clue.scene_id, "npc_id": clue.npc_id}

func _report_event(row: Dictionary) -> Dictionary:
	return {"type": "report", "scene_id": row.reporter.scene_id, "npc_id": row.reporter.npc_id}

func _pickup_event() -> Dictionary:
	return {"type": "pickup", "scene_id": "ch4_s2_canal_docks", "npc_id": "harbour_life_docks_booking_attendant", "recipient_npc_id": "district_life_market_buyer", "personal_pickup_confirmed": true}

func _test_state_machine(ready: Dictionary) -> void:
	check(api.FORMAL_ENABLED == false and api.enabled() == false and ready.quests.size() == 3 and ready.sources.size() == 24, "Reducer remains disabled; full three-quest, twenty-four-resource readiness")
	for path: String in ready.sources:
		check(source_before.has(path) and source_before[path].exists and source_before[path].sha256 == ready.sources[path], "Independent full frozen resource SHA " + path)
	for qid: String in ready.quests:
		var row: Dictionary = ready.quests[qid]
		var is_letter: bool = qid == "q_ch4_side_10_luoshui_letter"
		var report_error: String = "CULTURE_REPORT_REQUIRES_PERSONAL_PICKUP_ONCE_ONLY" if is_letter else "CULTURE_REPORT_REQUIRES_SOLVED_ONCE_ONLY"
		var definition: Resource = load(row.quest_path)
		check(String(definition.quest_id) == qid and definition.title == row.title, "Native QuestDef exact authored quest identity " + qid)
		for phase: String in ["offer", "clue_1", "clue_2", "clue_3", "solve", "report", "after"]:
			var dialogue: Resource = load(row.dialog_paths[phase])
			check(String(dialogue.dialog_id) == "ch4_culture_w_" + row.key + "_" + phase, "Native dialogue identity exactly matches quest and phase " + qid + "/" + phase)
		var start: Dictionary = api.new_state(qid)
		if not check(start.get("ok") == true and start.get("actual_reward_granted") == false and start.state.status == "not_started" and start.state.clues.is_empty() and start.state.answer_id == "" and start.state.report_count == 0, "New candidate state is never active/solved/reported " + qid): continue
		var initial := _roundtrip(start.state)
		var correct := ""
		var wrong := ""
		for choice: Dictionary in row.choices:
			if choice.correct: correct = choice.id
			else: wrong = choice.id
		check(not correct.is_empty() and not wrong.is_empty(), "Authored answer and retry alternative exist " + qid)
		if row.key == "luoshu_numbers": _test_nine_numbers(correct)
		var declined := _event(qid, initial, {"type": "decline"})
		check(declined.get("accepted") == false and declined.get("state") == initial and declined.get("outcome") == "declined_no_changes", "Decline preserves untouched candidate state " + qid)
		_event(qid, initial, _discover_event(row.clues[0]), "CULTURE_DISCOVERY_REQUIRES_ACTIVE")
		_event(qid, initial, {"type": "solve", "choice_id": correct}, "CULTURE_SOLVE_REQUIRES_ALL_THREE_CLUES")
		_event(qid, initial, _report_event(row), report_error)
		_event(qid, initial, _pickup_event(), "CULTURE_PICKUP_REQUIRES_SOLVED_ONCE_ONLY" if is_letter else "CULTURE_PICKUP_ONLY_FOR_LETTER")
		var accepted := _event(qid, initial, {"type": "accept"})
		if not check(accepted.get("accepted") == true and accepted.state.status == "active" and accepted.state.clues.is_empty() and accepted.state.answer_id == "" and accepted.state.report_count == 0 and accepted.outcome == "accepted_no_reward", "Acceptance only activates, does not solve/report/reward " + qid): continue
		var current: Dictionary = accepted.state
		_event(qid, current, {"type": "accept"}, "CULTURE_ALREADY_ACCEPTED_OR_FINISHED")
		_event(qid, current, _report_event(row), report_error)
		_event(qid, current, _pickup_event(), "CULTURE_PICKUP_REQUIRES_SOLVED_ONCE_ONLY" if is_letter else "CULTURE_PICKUP_ONLY_FOR_LETTER")
		for missing: int in 3:
			var partial := current.duplicate(true)
			for index: int in 3:
				if index == missing: continue
				var found := _event(qid, partial, _discover_event(row.clues[index]))
				partial = found.get("state", partial)
			check(partial.clues.size() == 2, "Each distinct one-of-three missing clue scenario constructed " + qid + "/" + str(missing))
			_event(qid, partial, {"type": "solve", "choice_id": correct}, "CULTURE_SOLVE_REQUIRES_ALL_THREE_CLUES")
		for clue: Dictionary in row.clues:
			var wrong_scene := _discover_event(clue)
			wrong_scene.scene_id = "wrong_scene"
			_event(qid, current, wrong_scene, "CULTURE_CLUE_WRONG_PERSON_OR_PLACE")
			var wrong_person := _discover_event(clue)
			wrong_person.npc_id = "wrong_npc"
			_event(qid, current, wrong_person, "CULTURE_CLUE_WRONG_PERSON_OR_PLACE")
			var found := _event(qid, current, _discover_event(clue))
			current = found.get("state", current)
			var duplicate := _event(qid, current, _discover_event(clue))
			check(duplicate.get("accepted") == false and duplicate.get("state") == current and duplicate.get("outcome") == "clue_already_known", "Repeated clue is idempotent, never extra progress " + qid)
		check(current.status == "active" and current.clues.size() == 3 and current.report_count == 0, "All clues still require explicit solve and report " + qid)
		var retry := _event(qid, current, {"type": "solve", "choice_id": wrong})
		check(retry.get("accepted") == false and retry.get("state") == current and retry.get("outcome") == "wrong_answer_retry", "Wrong answer retains all clues and remains retryable " + qid)
		_event(qid, current, {"type": "solve", "choice_id": "unknown_choice"}, "CULTURE_UNKNOWN_CHOICE")
		var solved := _event(qid, current, {"type": "solve", "choice_id": correct})
		var solve_outcome: String = "solved_personal_pickup_required_no_reward" if is_letter else "solved_return_to_reporter_no_reward"
		if not check(solved.get("accepted") == true and solved.state.status == "solved" and solved.state.answer_id == correct and solved.state.report_count == 0 and solved.outcome == solve_outcome, "Correct answer solves without report or reward " + qid): continue
		current = solved.state
		if is_letter:
			_event(qid, current, _report_event(row), report_error)
			for field: String in ["scene_id", "npc_id", "recipient_npc_id"]:
				var wrong_pickup := _pickup_event()
				wrong_pickup[field] = "wrong_person_or_place"
				_event(qid, current, wrong_pickup, "CULTURE_PICKUP_WRONG_PERSON_OR_PLACE")
			for value: Variant in [false, "true", 1, null]:
				var unconfirmed := _pickup_event()
				unconfirmed.personal_pickup_confirmed = value
				_event(qid, current, unconfirmed, "CULTURE_PICKUP_REQUIRES_EXPLICIT_PERSONAL_CONFIRMATION")
			var collected := _event(qid, current, _pickup_event())
			check(collected.get("accepted") == true and collected.state.status == "collected" and collected.state.clues == current.clues and collected.state.answer_id == current.answer_id and collected.state.report_count == 0 and collected.outcome == "candidate_personal_pickup_recorded_world_presence_not_verified", "Explicit original-docks recipient-confirmed candidate pickup is a distinct zero-reward stage")
			current = collected.state
			_event(qid, current, _pickup_event(), "CULTURE_PICKUP_REQUIRES_SOLVED_ONCE_ONLY")
			records.append({"kind": "LETTER_CANDIDATE_PICKUP_ONLY", "collected_roundtripped": current.duplicate(true), "actual_recipient_presence_or_world_handoff_verified": false})
		else:
			_event(qid, current, _pickup_event(), "CULTURE_PICKUP_ONLY_FOR_LETTER")
		var wrong_report := _report_event(row)
		wrong_report.scene_id = "wrong_scene"
		_event(qid, current, wrong_report, "CULTURE_REPORT_WRONG_PERSON_OR_PLACE")
		wrong_report = _report_event(row)
		wrong_report.npc_id = "wrong_npc"
		_event(qid, current, wrong_report, "CULTURE_REPORT_WRONG_PERSON_OR_PLACE")
		var reported := _event(qid, current, _report_event(row))
		check(reported.get("accepted") == true and reported.state.status == "reported" and reported.state.report_count == 1 and reported.outcome == row.outcome, "Only explicit correct report records one zero-reward narrative outcome " + qid)
		_event(qid, reported.state, _report_event(row), report_error)
		_event(qid, reported.state, _pickup_event(), "CULTURE_PICKUP_REQUIRES_SOLVED_ONCE_ONLY" if is_letter else "CULTURE_PICKUP_ONLY_FOR_LETTER")
		_event(qid, reported.state, {"type": "accept"}, "CULTURE_ALREADY_ACCEPTED_OR_FINISHED")
		_test_invalid_states(qid, initial, current, row)
		records.append({"kind": "ROUNDTRIPPED_QUEST", "quest_id": qid, "initial": initial, "reported": reported.state, "actual_reward_granted": false, "registered_in_QuestManager": false})
	var unknown: Dictionary = api.new_state("q_unknown")
	check(unknown.get("ok") == false and unknown.get("error") == "CULTURE_UNKNOWN_QUEST", "Unknown new quest rejected")
	_event("q_unknown", {}, {"type": "accept"}, "CULTURE_UNKNOWN_QUEST")

func _test_invalid_states(qid: String, initial: Dictionary, solved: Dictionary, row: Dictionary) -> void:
	for field: String in ["schema_version", "report_count"]:
		for bad: Variant in [true, "1", 0.5, 1.25, null, -1, 2]:
			var broken := initial.duplicate(true)
			broken[field] = bad
			_event(qid, broken, {"type": "accept"}, "CULTURE_INVALID_STATE")
	var injected := initial.duplicate(true)
	injected["old_solved_flag"] = true
	_event(qid, injected, _report_event(row), "CULTURE_INVALID_STATE")
	injected = initial.duplicate(true)
	injected.status = "solved"
	_event(qid, injected, _report_event(row), "CULTURE_INVALID_STATE")
	injected = initial.duplicate(true)
	injected.status = "collected"
	_event(qid, injected, _report_event(row), "CULTURE_INVALID_STATE")
	injected = solved.duplicate(true)
	injected.status = "collected"
	injected.clues.remove_at(0)
	_event(qid, injected, _report_event(row), "CULTURE_INVALID_STATE")
	injected = solved.duplicate(true)
	injected.status = "collected"
	injected.answer_id = "wrong_or_unknown_answer"
	_event(qid, injected, _report_event(row), "CULTURE_INVALID_STATE")
	injected = solved.duplicate(true)
	injected.status = "collected"
	injected.report_count = 1
	_event(qid, injected, _report_event(row), "CULTURE_INVALID_STATE")
	if qid != "q_ch4_side_10_luoshui_letter":
		injected = solved.duplicate(true)
		injected.status = "collected"
		_event(qid, injected, _report_event(row), "CULTURE_INVALID_STATE")
	injected = solved.duplicate(true)
	injected.clues.append(solved.clues[0])
	_event(qid, injected, _report_event(row), "CULTURE_INVALID_STATE")
	injected = solved.duplicate(true)
	injected.clues[0] = "unknown_clue"
	_event(qid, injected, _report_event(row), "CULTURE_INVALID_STATE")
	_event(qid, initial, {"type": true}, "CULTURE_EVENT_TYPE")
	_event(qid, initial, {"type": "unknown_event"}, "CULTURE_UNKNOWN_EVENT")
	_event(qid, initial, {"type": "accept", "solved": true}, "CULTURE_EVENT_FIELDS")
	var exact_float := initial.duplicate(true)
	exact_float.schema_version = 1.0
	exact_float.report_count = 0.0
	var accepted := _event(qid, exact_float, {"type": "accept"})
	check(accepted.get("accepted") == true and accepted.state.status == "active", "Exact integral JSON floats are legal, not rejected as scalar type drift " + qid)

func _math_board_valid(board: Array, fixed_north: bool) -> bool:
	if board.size() != 9: return false
	var unique: Dictionary = {}
	for value: Variant in board:
		if typeof(value) != TYPE_INT or value < 1 or value > 9 or unique.has(value): return false
		unique[value] = true
	if unique.size() != 9 or board[4] != 5: return false
	for pair: Array in [[0, 8], [1, 7], [2, 6], [3, 5]]:
		if board[pair[0]] + board[pair[1]] != 10: return false
	for line: Array in [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]:
		if board[line[0]] + board[line[1]] + board[line[2]] != 15: return false
	return not fixed_north or (board[0] == 4 and board[5] == 7)

func _test_nine_numbers(correct_choice_id: String) -> void:
	var digits := correct_choice_id.get_slice("_", correct_choice_id.get_slice_count("_") - 1)
	var board: Array = []
	check(digits.length() == 9 and digits.is_valid_int(), "Authored accepted nine-number choice carries a nine-digit board")
	for character: String in digits:
		board.append(int(character))
	check(_math_board_valid(board, true), "Independent one-to-nine uniqueness, centre5, opposite10, eight sums15 AND north NW4/E7")
	check(not _math_board_valid([5, 5, 5, 5, 5, 5, 5, 5, 5], true), "Eight sums alone cannot validate repeated digits")
	check(not _math_board_valid([1, 2, 3, 4, 5, 6, 7, 8, 9], true), "Correct digit set alone cannot validate sums")
	var rotated: Array = [8, 3, 4, 1, 5, 9, 6, 7, 2]
	check(_math_board_valid(rotated, false) and not _math_board_valid(rotated, true), "Valid rotated magic square rejected solely by explicit north orientation")
	var sums: Array = []
	for line: Array in [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]:
		sums.append(board[line[0]] + board[line[1]] + board[line[2]])
	records.append({"kind": "INDEPENDENT_NINE_NUMBER_MATH", "board": board, "eight_sums": sums, "north_is_fixed": true, "north_west": board[0], "east_middle": board[5]})

func _timeout() -> void:
	if not finished: _finish(true)

func _finish(timed_out: bool) -> void:
	if finished: return
	finished = true
	var source_after := snapshot(source_before)
	var dependency_after := snapshot(dependency_before)
	var players_after := saves()
	check(source_before.size() == 26 and source_before == source_after, "Whole twenty-six runtime leaf source facts first/final exact")
	check(dependency_before == dependency_after, "QA key and three native domain dependencies first/final exact")
	check(players_before.size() == 15 and players_before == players_after, "All fifteen existing or absent save facts first/final exact; never restored")
	check(state_before == game_state(), "Actual game flags, quests and inventory remain unchanged")
	check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended") == true, "Checkpoint save protection remains active")
	check(not timed_out and Time.get_ticks_msec() - began < BUDGET_MS, "Fixed thirty-second CPU-only atom")
	var folder := "res://build/luoyang_cultural_sidequests_candidate_20261019w/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join("result.json")
	var report := {"scope": "CANDIDATE_CULTURAL_QUEST_REDUCER_AND_NATIVE_RESOURCES_ONLY", "complete": failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "budget_ms": BUDGET_MS, "source_before": source_before, "source_after": source_after, "dependency_before": dependency_before, "dependency_after": dependency_after, "players_before": players_before, "players_after": players_after, "state_before": state_before, "state_after": game_state(), "records": records, "Field_GPU_UI_audio_portrait_credit": false, "formal_credit": false, "mtime_precision": "Godot seconds encoded as strings, not Windows exact UTC ticks"}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print(JSON.stringify({"cultural_sidequests_qa_result": path, "complete": failures == 0, "checks": checks, "failures": failures}))
	quit(0 if failures == 0 else 1)
