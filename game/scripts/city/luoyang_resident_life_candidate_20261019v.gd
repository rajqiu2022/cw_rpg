extends RefCounted
## Pure candidate selector/projection. No Field hook, save write, reward, scene
## mutation, catalog override or authority to activate a formal city bundle.
const FORMAL_ENABLED := false
const FLAG := "--luoyang-resident-life-candidate-20261019v"
const SELF := "res://scripts/city/luoyang_resident_life_candidate_20261019v.gd"
const MANIFEST := "res://data/luoyang_residents_20261019v/manifest.json"
const MANIFEST_SHA := "e0b4bce63ad9b628eaa6d63c57a918dd026705da181d90f4e9c0801e40601baf"
const PREFIX := "res://data/dialogs/ch4_resident_v_"
const STAGES := ["daily", "uncertain", "after"]
const IDS := {
	"luoyang_paper_artisan_20261016": "ch4_s3_luoyang_market",
	"district_life_market_buyer": "ch4_s3_luoyang_market",
	"harbour_life_docks_loading_attendant": "ch4_s2_canal_docks",
	"harbour_life_gate_supply_attendant": "ch4_s0_luoyang_gate",
}

static func enabled() -> bool:
	return FORMAL_ENABLED or FLAG in OS.get_cmdline_user_args()

static func _failure(error: String) -> Dictionary:
	return {"ok": false, "error": error, "candidate_only": true, "formal_enabled": false}

static func readiness() -> Dictionary:
	if MANIFEST_SHA.length() != 64 or FileAccess.get_sha256(MANIFEST) != MANIFEST_SHA:
		return _failure("RESIDENT_MANIFEST_MISSING_OR_CHANGED")
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not data is Dictionary or data.get("schema_version") != 1 or data.get("status") != "CANDIDATE_NOT_FORMAL":
		return _failure("RESIDENT_MANIFEST_SCHEMA_OR_STATUS")
	var residents: Variant = data.get("residents")
	var sources: Variant = data.get("source_sha256")
	if not residents is Array or residents.size() != IDS.size() or not sources is Dictionary or sources.size() != 12:
		return _failure("RESIDENT_MANIFEST_COMPLETE_SET")
	var by_id: Dictionary = {}
	var used: Dictionary = {}
	for raw: Variant in residents:
		if not raw is Dictionary:
			return _failure("RESIDENT_ROW_TYPE")
		var id: Variant = raw.get("npc_id")
		if not id is String or not IDS.has(id) or by_id.has(id) or raw.get("scene_id") != IDS[id]:
			return _failure("RESIDENT_ID_OR_SCENE")
		if not raw.get("name") is String or String(raw.name).is_empty():
			return _failure("RESIDENT_NAME")
		var dialogs: Variant = raw.get("dialogs")
		var progress: Variant = raw.get("progress")
		if not dialogs is Dictionary or dialogs.size() != 3 or not progress is Dictionary:
			return _failure("RESIDENT_DIALOG_OR_PROGRESS_TYPE")
		if not progress.get("quest_id") is String or String(progress.quest_id).is_empty():
			return _failure("RESIDENT_QUEST_ID")
		for key: String in ["active_flags", "completed_flags"]:
			var flags: Variant = progress.get(key)
			if not flags is Array or flags.is_empty():
				return _failure("RESIDENT_PROGRESS_FLAGS")
			var distinct: Dictionary = {}
			for flag: Variant in flags:
				if not flag is String or String(flag).is_empty() or distinct.has(flag):
					return _failure("RESIDENT_PROGRESS_FLAG_TYPE_OR_DUPLICATE")
				distinct[flag] = true
		for key: String in STAGES:
			var path: Variant = dialogs.get(key)
			if not path is String or not String(path).begins_with(PREFIX) or not String(path).ends_with(".tres") or ".." in String(path) or used.has(path):
				return _failure("RESIDENT_DIALOG_PATH")
			var sha: Variant = sources.get(path)
			if not sha is String or String(sha).length() != 64 or FileAccess.get_sha256(path) != sha:
				return _failure("RESIDENT_DIALOG_SOURCE_CHANGED:" + String(path))
			# Dynamic dialogue audio uses DialogScript.dialog_id, not its filename.
			# Keep that key identical to the authoritative authored resource path.
			var text: String = FileAccess.get_file_as_string(path)
			var expression := RegEx.new()
			if expression.compile('(?m)^dialog_id\\s*=\\s*&?"([^"\\r\\n]+)"\\s*$') != OK:
				return _failure("RESIDENT_DIALOG_ID_PATTERN")
			var matches: Array[RegExMatch] = expression.search_all(text)
			if matches.size() != 1 or matches[0].get_string(1) != String(path).get_file().get_basename():
				return _failure("RESIDENT_DIALOG_ID_MISMATCH:" + String(path))
			used[path] = true
		by_id[id] = raw.duplicate(true)
	for path: Variant in sources:
		if not path is String or not used.has(path):
			return _failure("RESIDENT_SOURCE_EXTRA_OR_WRONG_TYPE")
	return {"ok": true, "residents": by_id, "source_sha256": sources.duplicate(true), "candidate_only": true, "formal_enabled": false}

static func source_paths() -> Dictionary:
	var ready := readiness()
	if ready.get("ok") != true:
		return {}
	var paths: Dictionary = {SELF: true, MANIFEST: true}
	for path: String in ready.source_sha256:
		paths[path] = true
	return paths

static func _all_flags(required: Array, flags: Dictionary) -> Dictionary:
	var all_true := true
	for key: String in required:
		var value: Variant = flags.get(key, false)
		if not value is bool:
			return _failure("RESIDENT_FLAG_NOT_BOOL:" + key)
		if not value:
			all_true = false
	return {"ok": true, "all_true": all_true}

static func _stage_row(row: Dictionary, flags: Dictionary, quests: Dictionary) -> Dictionary:
	var progress: Dictionary = row.progress
	var state: Variant = quests.get(progress.quest_id, 0)
	if not state is int or int(state) < 0 or int(state) > 3:
		return _failure("RESIDENT_QUEST_STATE_NOT_ENUM_INT")
	var active := _all_flags(progress.active_flags, flags)
	var completed := _all_flags(progress.completed_flags, flags)
	if active.get("ok") != true:
		return active
	if completed.get("ok") != true:
		return completed
	var selected := "daily"
	# A legacy solved flag on its own is NOT a completed quest. Never accept a
	# string/bool/float as an enum or create a reward/quest state here.
	if state == 2 and completed.all_true:
		selected = "after"
	elif state == 1 and active.all_true:
		selected = "uncertain"
	return {"ok": true, "npc_id": row.npc_id, "stage": selected, "dialog_path": row.dialogs[selected], "dialog_id": String(row.dialogs[selected]).get_file().get_basename(), "candidate_only": true, "formal_enabled": false}

static func stage(npc_id: String, flags: Dictionary, quests: Dictionary) -> Dictionary:
	var ready := readiness()
	if ready.get("ok") != true:
		return ready
	if not ready.residents.has(npc_id):
		return _failure("RESIDENT_UNKNOWN_ID")
	return _stage_row(ready.residents[npc_id], flags, quests)

static func dialog_for(npc_id: String, flags: Dictionary, quests: Dictionary) -> Dictionary:
	return stage(npc_id, flags, quests)

static func choices_for(npc_id: String, flags: Dictionary, quests: Dictionary) -> Dictionary:
	var selected := stage(npc_id, flags, quests)
	if selected.get("ok") != true:
		return selected
	selected["choices"] = [{"id": "resident_life", "text": "聊聊近日城中生活", "dialog_id": selected.dialog_id}]
	selected["requires_separate_conversation_menu"] = npc_id == "luoyang_paper_artisan_20261016"
	return selected

static func project_copy(scene_id: StringName, original: Array, flags: Dictionary, quests: Dictionary) -> Dictionary:
	var ready := readiness()
	if ready.get("ok") != true:
		return ready
	var expected: Dictionary = {}
	for id: String in IDS:
		if IDS[id] == String(scene_id):
			expected[id] = true
	if expected.is_empty():
		return _failure("RESIDENT_UNSUPPORTED_SCENE")
	var result: Array = original.duplicate(true)
	var seen: Dictionary = {}
	var plans: Array = []
	for i: int in result.size():
		if not result[i] is Dictionary:
			return _failure("RESIDENT_NPC_ROW_NOT_DICTIONARY")
		var row: Dictionary = result[i]
		var id: String = String(row.get("npc_id", ""))
		if not expected.has(id):
			continue
		if seen.has(id):
			return _failure("RESIDENT_DUPLICATE_SOURCE_ID")
		seen[id] = true
		var selected := _stage_row(ready.residents[id], flags, quests)
		if selected.get("ok") != true:
			return selected
		selected["primary_dialog_id"] = String(row.get("dialog_id", ""))
		selected["primary_interaction_action"] = String(row.get("interaction_action", ""))
		selected["requires_separate_conversation_menu"] = id == "luoyang_paper_artisan_20261016"
		if id == "luoyang_paper_artisan_20261016":
			# Existing paper hint/progress/report remains authoritative and reachable.
			# Field does not yet consume this extra menu; never claim it is hooked.
			if not selected.primary_dialog_id.begins_with("luoyang_city_tasks_20261016/") or selected.primary_interaction_action != "":
				return _failure("RESIDENT_PAPER_PRIMARY_SOURCE_CHANGED")
		else:
			var variants: Variant = row.get("dialog_variants", [])
			if not variants is Array or selected.primary_dialog_id != "" or selected.primary_interaction_action != "" or not variants.is_empty():
				return _failure("RESIDENT_WOULD_OVERWRITE_EXISTING_CONVERSATION")
			row["dialog_id"] = selected.dialog_id
			# Assert the sole field delta; patrol/feet/body/scale/portrait stay exact.
			var restored: Dictionary = row.duplicate(true)
			if original[i].has("dialog_id"):
				restored["dialog_id"] = original[i].dialog_id
			else:
				restored.erase("dialog_id")
			if restored != original[i]:
				return _failure("RESIDENT_NON_DIALOG_SOURCE_MUTATION")
		plans.append(selected)
	if seen.size() != expected.size():
		return _failure("RESIDENT_EXPECTED_SOURCE_NPC_MISSING")
	return {"ok": true, "npcs": result, "conversation_choice_plans": plans, "candidate_only": true, "formal_enabled": false, "production_hook_present": false, "unchanged_geometry_and_task_primary": true}
