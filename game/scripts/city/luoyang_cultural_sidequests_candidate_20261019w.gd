extends RefCounted
## Candidate-only, plain-data state machine. No autoload/resource mutation,
## event emission, rewards, save access, Field hook or runtime walk proof.
const FORMAL_ENABLED := false
const SELF := "res://scripts/city/luoyang_cultural_sidequests_candidate_20261019w.gd"
const MANIFEST := "res://data/luoyang_culture_candidates_20261019w/manifest.json"
const MANIFEST_SHA := "7fa69f44d8e176832ba5a2c177565905a335753654761dda575459a0c64bdf35"
const ROOT_QUEST := "res://data/quests/luoyang_culture_candidates_20261019w/"
const ROOT_DIALOG := "res://data/dialogs/luoyang_culture_candidates_20261019w/"
const IDS := {
	"q_ch4_side_08_qiangxiang_receipt": "qiangxiang_receipt",
	"q_ch4_side_09_luoshu_numbers": "luoshu_numbers",
	"q_ch4_side_10_luoshui_letter": "luoshui_letter",
}
const DIALOG_KEYS := ["offer", "clue_1", "clue_2", "clue_3", "solve", "report", "after"]
const LETTER := "q_ch4_side_10_luoshui_letter"
const PICKUP_SCENE := "ch4_s2_canal_docks"
const PICKUP_NPC := "harbour_life_docks_booking_attendant"
const RECIPIENT_NPC := "district_life_market_buyer"
const STATUS := ["not_started", "active", "solved", "collected", "reported"]
const STATE_KEYS := ["schema_version", "quest_id", "status", "clues", "answer_id", "report_count"]

static func enabled() -> bool:
	return FORMAL_ENABLED

static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error, "candidate_only": true, "actual_reward_granted": false, "formal_enabled": false}

static func _exact_keys(data: Dictionary, expected: Array) -> bool:
	if data.size() != expected.size(): return false
	for key: Variant in data:
		if not key is String or key not in expected: return false
	return true

static func _integer_in(value: Variant, low: int, high: int) -> bool:
	# JSON parsers may decode 1 as 1.0. Only finite exact integral values in the
	# tiny declared range qualify; bool, strings and fractional values do not.
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT: return false
	var number := float(value)
	return is_finite(number) and number >= low and number <= high and number == floor(number)

static func _actor(actor: Variant) -> bool:
	return actor is Dictionary and _exact_keys(actor, ["scene_id", "npc_id"]) and actor.scene_id is String and actor.npc_id is String and not String(actor.scene_id).is_empty() and not String(actor.npc_id).is_empty()

static func readiness() -> Dictionary:
	if MANIFEST_SHA.length() != 64 or FileAccess.get_sha256(MANIFEST) != MANIFEST_SHA:
		return _fail("CULTURE_MANIFEST_MISSING_OR_CHANGED")
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not data is Dictionary or not _integer_in(data.get("schema_version"), 1, 1) or data.get("status") != "CANDIDATE_NOT_FORMAL" or data.get("formal_enabled") != false or data.get("runtime_hook_present") != false:
		return _fail("CULTURE_MANIFEST_SCHEMA")
	var rows: Variant = data.get("quests")
	var sources: Variant = data.get("source_sha256")
	if not rows is Array or rows.size() != IDS.size() or not sources is Dictionary or sources.size() != 24 or data.get("source_freeze_status") != "FROZEN_24_RESOURCES":
		return _fail("CULTURE_COMPLETE_SOURCE_SET")
	var quests: Dictionary = {}; var used: Dictionary = {}
	for raw: Variant in rows:
		if not raw is Dictionary: return _fail("CULTURE_QUEST_ROW_TYPE")
		var id: Variant = raw.get("id")
		if not id is String or not IDS.has(id) or quests.has(id) or raw.get("key") != IDS[id] or not raw.get("title") is String:
			return _fail("CULTURE_QUEST_ID_OR_TITLE")
		var quest_path: String = ROOT_QUEST + IDS[id] + ".tres"
		if raw.get("quest_path") != quest_path: return _fail("CULTURE_QUEST_PATH")
		used[quest_path] = true
		var dialogs: Variant = raw.get("dialog_paths")
		if not dialogs is Dictionary or not _exact_keys(dialogs, DIALOG_KEYS): return _fail("CULTURE_DIALOG_KEYS")
		for key: String in DIALOG_KEYS:
			var path: String = ROOT_DIALOG + IDS[id] + "_" + key + ".tres"
			if dialogs[key] != path or used.has(path): return _fail("CULTURE_DIALOG_PATH")
			used[path] = true
		var actors: Variant = raw.get("actors")
		var clues: Variant = raw.get("clues")
		var choices: Variant = raw.get("choices")
		if not actors is Array or actors.size() < 2 or not clues is Array or clues.size() != 3 or not choices is Array or choices.size() < 2:
			return _fail("CULTURE_CLUE_ACTOR_CHOICE_COUNT")
		var actor_pairs: Dictionary = {}; var scenes: Dictionary = {}; var npcs: Dictionary = {}; var clue_ids: Dictionary = {}; var choice_ids: Dictionary = {}; var correct := 0
		for actor: Variant in actors:
			if not _actor(actor): return _fail("CULTURE_ACTOR_TYPE")
			var pair: String = actor.scene_id + ":" + actor.npc_id
			if actor_pairs.has(pair): return _fail("CULTURE_ACTOR_DUPLICATE")
			actor_pairs[pair] = true
		for clue: Variant in clues:
			if not clue is Dictionary or not _exact_keys(clue, ["id", "scene_id", "npc_id", "label"]): return _fail("CULTURE_CLUE_TYPE")
			for key: String in ["id", "scene_id", "npc_id", "label"]:
				if not clue[key] is String or String(clue[key]).is_empty(): return _fail("CULTURE_CLUE_FIELD")
			if clue_ids.has(clue.id) or not actor_pairs.has(clue.scene_id + ":" + clue.npc_id): return _fail("CULTURE_CLUE_BINDING")
			clue_ids[clue.id] = true; scenes[clue.scene_id] = true; npcs[clue.npc_id] = true
		if scenes.size() < 2 or npcs.size() < 2: return _fail("CULTURE_NEEDS_DISTINCT_PLACES_AND_PEOPLE")
		for choice: Variant in choices:
			if not choice is Dictionary or not _exact_keys(choice, ["id", "text", "correct"]) or not choice.id is String or String(choice.id).is_empty() or not choice.text is String or not choice.correct is bool or choice_ids.has(choice.id): return _fail("CULTURE_CHOICE_TYPE")
			choice_ids[choice.id] = true
			if choice.correct: correct += 1
		if correct != 1 or not _actor(raw.get("reporter")) or not actor_pairs.has(raw.reporter.scene_id + ":" + raw.reporter.npc_id) or not raw.get("outcome") is String:
			return _fail("CULTURE_ANSWER_OR_REPORTER")
		if id == LETTER:
			var pickup: Variant = raw.get("pickup")
			if not pickup is Dictionary or not _exact_keys(pickup, ["scene_id", "npc_id", "recipient_npc_id", "mode", "required_state", "next_state", "event_is_candidate_logic_only", "future_coordinator_must_verify_actual_recipient_presence_and_authorization"]): return _fail("CULTURE_PERSONAL_PICKUP_CONTRACT")
			if pickup.scene_id != PICKUP_SCENE or pickup.npc_id != PICKUP_NPC or pickup.recipient_npc_id != RECIPIENT_NPC or pickup.mode != "personal_only" or pickup.required_state != "solved" or pickup.next_state != "collected" or pickup.event_is_candidate_logic_only != true or pickup.future_coordinator_must_verify_actual_recipient_presence_and_authorization != true: return _fail("CULTURE_PERSONAL_PICKUP_CONTRACT")
		elif raw.has("pickup"):
			return _fail("CULTURE_PICKUP_ONLY_FOR_LETTER")
		if not raw.get("source_references") is Array or raw.source_references.is_empty(): return _fail("CULTURE_REFERENCES_MISSING")
		quests[id] = raw.duplicate(true)
	if used.size() != 24: return _fail("CULTURE_RESOURCE_COUNT")
	for path: Variant in sources:
		if not path is String or not used.has(path) or not sources[path] is String or String(sources[path]).length() != 64 or FileAccess.get_sha256(path) != sources[path]: return _fail("CULTURE_RESOURCE_SOURCE_CHANGED:" + str(path))
	return {"ok": true, "quests": quests, "sources": sources.duplicate(true), "candidate_only": true, "formal_enabled": false}

static func source_paths() -> Dictionary:
	var ready := readiness()
	if ready.get("ok") != true: return {}
	var paths: Dictionary = {SELF: true, MANIFEST: true}
	for path: String in ready.sources: paths[path] = true
	return paths

static func _result(state: Dictionary, accepted: bool, outcome: String) -> Dictionary:
	return {"ok": true, "accepted": accepted, "state": state.duplicate(true), "outcome": outcome, "candidate_only": true, "actual_reward_granted": false, "actual_world_presence_verified": false, "formal_enabled": false}

static func new_state(qid: String) -> Dictionary:
	var ready := readiness()
	if ready.get("ok") != true: return ready
	if not ready.quests.has(qid): return _fail("CULTURE_UNKNOWN_QUEST")
	return _result({"schema_version": 1, "quest_id": qid, "status": "not_started", "clues": [], "answer_id": "", "report_count": 0}, true, "new_candidate_state")

static func _choice(row: Dictionary, id: String) -> Dictionary:
	for choice: Dictionary in row.choices:
		if choice.id == id: return choice
	return {}

static func _state_valid(qid: String, state: Dictionary, row: Dictionary) -> bool:
	if not _exact_keys(state, STATE_KEYS) or not _integer_in(state.schema_version, 1, 1) or state.quest_id != qid or not state.status is String or state.status not in STATUS or not state.clues is Array or not state.answer_id is String or not _integer_in(state.report_count, 0, 1): return false
	var known: Dictionary = {}; var used: Dictionary = {}
	for clue: Dictionary in row.clues: known[clue.id] = true
	for id: Variant in state.clues:
		if not id is String or not known.has(id) or used.has(id): return false
		used[id] = true
	if state.status == "not_started": return used.is_empty() and state.answer_id == "" and state.report_count == 0
	if state.status == "active": return state.answer_id == "" and state.report_count == 0
	if state.status == "collected" and qid != LETTER: return false
	var answer := _choice(row, state.answer_id)
	if used.size() != row.clues.size() or answer.get("correct") != true: return false
	return state.report_count == (1 if state.status == "reported" else 0)

static func transition(qid: String, state: Dictionary, event: Dictionary) -> Dictionary:
	var ready := readiness()
	if ready.get("ok") != true: return ready
	if not ready.quests.has(qid): return _fail("CULTURE_UNKNOWN_QUEST")
	var row: Dictionary = ready.quests[qid]
	if not _state_valid(qid, state, row): return _fail("CULTURE_INVALID_STATE")
	var type: Variant = event.get("type")
	if not type is String: return _fail("CULTURE_EVENT_TYPE")
	var next: Dictionary = state.duplicate(true)
	next.schema_version = 1; next.report_count = int(state.report_count)
	match type:
		"accept", "decline":
			if not _exact_keys(event, ["type"]): return _fail("CULTURE_EVENT_FIELDS")
			if state.status != "not_started": return _fail("CULTURE_ALREADY_ACCEPTED_OR_FINISHED")
			if type == "decline": return _result(next, false, "declined_no_changes")
			next.status = "active"
			return _result(next, true, "accepted_no_reward")
		"discover":
			if not _exact_keys(event, ["type", "clue_id", "scene_id", "npc_id"]): return _fail("CULTURE_EVENT_FIELDS")
			for key: String in ["clue_id", "scene_id", "npc_id"]:
				if not event[key] is String: return _fail("CULTURE_EVENT_ID_TYPE")
			if state.status != "active": return _fail("CULTURE_DISCOVERY_REQUIRES_ACTIVE")
			var found: Dictionary = {}
			for clue: Dictionary in row.clues:
				if clue.id == event.clue_id: found = clue
			if found.is_empty(): return _fail("CULTURE_UNKNOWN_CLUE")
			if event.scene_id != found.scene_id or event.npc_id != found.npc_id: return _fail("CULTURE_CLUE_WRONG_PERSON_OR_PLACE")
			if event.clue_id in next.clues: return _result(next, false, "clue_already_known")
			next.clues.append(event.clue_id)
			return _result(next, true, "clue_recorded_candidate_only")
		"solve":
			if not _exact_keys(event, ["type", "choice_id"]) or not event.choice_id is String: return _fail("CULTURE_EVENT_FIELDS")
			if state.status != "active" or state.clues.size() != row.clues.size(): return _fail("CULTURE_SOLVE_REQUIRES_ALL_THREE_CLUES")
			var choice := _choice(row, event.choice_id)
			if choice.is_empty(): return _fail("CULTURE_UNKNOWN_CHOICE")
			if not choice.correct: return _result(next, false, "wrong_answer_retry")
			next.status = "solved"; next.answer_id = event.choice_id
			return _result(next, true, "solved_personal_pickup_required_no_reward" if qid == LETTER else "solved_return_to_reporter_no_reward")
		"pickup":
			if qid != LETTER: return _fail("CULTURE_PICKUP_ONLY_FOR_LETTER")
			if not _exact_keys(event, ["type", "scene_id", "npc_id", "recipient_npc_id", "personal_pickup_confirmed"]): return _fail("CULTURE_EVENT_FIELDS")
			for key: String in ["scene_id", "npc_id", "recipient_npc_id"]:
				if not event[key] is String: return _fail("CULTURE_EVENT_ID_TYPE")
			if not event.personal_pickup_confirmed is bool or event.personal_pickup_confirmed != true: return _fail("CULTURE_PICKUP_REQUIRES_EXPLICIT_PERSONAL_CONFIRMATION")
			if state.status != "solved": return _fail("CULTURE_PICKUP_REQUIRES_SOLVED_ONCE_ONLY")
			if event.scene_id != PICKUP_SCENE or event.npc_id != PICKUP_NPC or event.recipient_npc_id != RECIPIENT_NPC: return _fail("CULTURE_PICKUP_WRONG_PERSON_OR_PLACE")
			# This is a candidate caller declaration, NOT evidence that the woman
			# moved to the docks. A future Coordinator must prove actual identity,
			# consent/presence and delivery authorization before issuing this event.
			next.status = "collected"
			return _result(next, true, "candidate_personal_pickup_recorded_world_presence_not_verified")
		"report":
			if not _exact_keys(event, ["type", "scene_id", "npc_id"]) or not event.scene_id is String or not event.npc_id is String: return _fail("CULTURE_EVENT_FIELDS")
			if qid == LETTER and state.status != "collected": return _fail("CULTURE_REPORT_REQUIRES_PERSONAL_PICKUP_ONCE_ONLY")
			if qid != LETTER and state.status != "solved": return _fail("CULTURE_REPORT_REQUIRES_SOLVED_ONCE_ONLY")
			if event.scene_id != row.reporter.scene_id or event.npc_id != row.reporter.npc_id: return _fail("CULTURE_REPORT_WRONG_PERSON_OR_PLACE")
			next.status = "reported"; next.report_count = 1
			return _result(next, true, row.outcome)
	return _fail("CULTURE_UNKNOWN_EVENT")
