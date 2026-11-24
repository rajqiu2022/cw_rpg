extends SceneTree
## Root-only resource atom. No city helper/scene, DialogPlayer playback or save call.
const FIXTURE := "res://build/luoyang_city_completion_20261021ai_qa01/life_dialog_loader_fixture_minimal_READY.json"
const FIXTURE_SHA := "712d5654406bfdc16a1f2432d0b8e6f12b04fe3872ab90bd0f15429499c0fe65"
const MANIFEST := "res://build/luoyang_city_completion_20261021ai_lore01/manifest.json"
const DOMAIN_SCRIPT := "res://scripts/domain/dialog_script.gd"
const DOMAIN_NODE := "res://scripts/domain/dialog_node.gd"
const CULTURE_MANIFEST := "res://data/luoyang_culture_candidates_20261019w/manifest.json"
const CARRIER_MANIFEST := "res://data/luoyang_docks_roles_20261019ad/manifest.json"
const HARBOUR := "res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd"
const DISTRICT := "res://data/maps/luoyang_district_life_20261016f/author.json"
const BUDGET_MS := 30000
const EMPTY_ARRAY_FIELDS := ["choices", "give_items", "set_flags", "learn_skills", "add_evidence", "verify_evidence", "add_testimonies", "verify_testimonies", "faction_trust_changes", "companion_trust_changes", "bond_events", "city_outcomes", "method_flags"]
var began: int = 0
var checks: int = 0
var failures: int = 0
var finished: bool = false
var records: Array = []
var failure_details: Array = []
var source_before: Dictionary = {}
var saves_before: Dictionary = {}
var state_before: Dictionary = {}
var expected_sources: Dictionary = {}
var loaded_dialog_count: int = 0
var loaded_node_count: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String, detail: Variant = null) -> bool:
	checks += 1
	if not value:
		failures += 1
		failure_details.append({"label":label,"detail":detail})
		printerr("AI_LIFE_RESOURCE_FAIL ", label, " ", detail)
	return value

func fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false,"sha256":"ABSENT","bytes":0,"mtime_seconds_string":"0"}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null: return {"exists":false,"sha256":"OPEN_FAILED","bytes":0,"mtime_seconds_string":"0"}
	var length: int = file.get_length()
	file.close()
	return {"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":length,"mtime_seconds_string":str(FileAccess.get_modified_time(path))}

func snapshot(paths: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for path: String in paths: result[path] = fact(path)
	return result

func saves() -> Dictionary:
	var result: Dictionary = {}
	for slot: int in 5:
		for suffix: String in [".json", ".json.bak", ".json.tmp"]:
			var path: String = "user://save_" + str(slot) + suffix
			result[path] = fact(path)
	return result

func state() -> Dictionary:
	return {"flags":root.get_node("GameState").get("flags").duplicate(true),"quests":root.get_node("QuestManager").call("to_dict").duplicate(true),"inventory":root.get_node("Inventory").call("to_dict").duplicate(true)}

func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not check(parsed is Dictionary, "JSON Dictionary " + path): return {}
	return parsed

func _run() -> void:
	began = Time.get_ticks_msec()
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	saves_before = saves()
	state_before = state()
	create_timer(30.0).timeout.connect(_timeout)
	if not check(FileAccess.get_sha256(FIXTURE) == FIXTURE_SHA, "Root-fixed independent fixture SHA"):
		_finish(false)
		return
	var fixture: Dictionary = _json(FIXTURE)
	if not check(fixture.get("status") == "READY_INDEPENDENT_CANDIDATE_RESOURCE_LOADER_INPUT_NOT_FIELD", "Fixture READY exact atom"):
		_finish(false)
		return
	expected_sources = fixture.get("source_sha256", {}).duplicate(true)
	check(expected_sources.size() == 24, "Exact24 small resource/identity leaf closure; no four-city collectors or room loads")
	var paths: Dictionary = expected_sources.duplicate(true)
	paths[FIXTURE] = true
	var self_path: String = get_script().resource_path
	paths[self_path] = true
	source_before = snapshot(paths)
	for path: String in expected_sources:
		if not check(source_before[path].exists and source_before[path].sha256 == expected_sources[path], "Fixed source SHA " + path):
			_finish(false)
			return
	check(OS.get_cmdline_user_args().is_empty(), "No candidate activation flags")
	var manifest: Dictionary = _json(MANIFEST)
	var expected: Array = fixture.get("expected_identity_rows", [])
	if not check(manifest.get("rows") == expected and expected.size() == 12, "Exact twelve independent NPC/scene/name/dialog identities"):
		_finish(false)
		return
	check(manifest.get("status") == "CANDIDATE_TEXT_ONLY_NOT_BOUND" and manifest.get("formal_enabled") == false, "Candidate only, not formal or hooked")
	var policy: Dictionary = manifest.get("topic_policy", {})
	check(policy.get("kind") == "secondary_daily_life" and policy.get("label") == "聊聊日常" and policy.get("preserve_primary") == true and policy.get("preserve_culture") == true and policy.get("no_runtime_hook") == true and policy.get("priority") == "primary and culture before secondary daily life", "Explicit secondary-only primary/culture preservation policy")
	var excluded: Dictionary = {}
	var culture: Dictionary = _json(CULTURE_MANIFEST)
	for quest: Dictionary in culture.get("quests", []):
		for actor: Dictionary in quest.get("actors", []): excluded[String(actor.npc_id)] = true
	check(excluded.size() == 5, "Current five cultural identities read without coordinator execution")
	var carrier: Dictionary = _json(CARRIER_MANIFEST)
	for row: Dictionary in carrier.get("roles", []): excluded[String(row.npc_id)] = true
	check(excluded.size() == 8, "Culture5 plus existing carrier3 kept outside candidate selection")
	var district: Dictionary = _json(DISTRICT)
	var harbour_text: String = FileAccess.get_file_as_string(HARBOUR)
	var seen_ids: Dictionary = {}
	var seen_paths: Dictionary = {}
	var scene_counts: Dictionary = {}
	for row: Dictionary in expected:
		var id: String = String(row.npc_id)
		var scene_id: String = String(row.scene_id)
		check(not seen_ids.has(id) and not excluded.has(id), "Unique existing nonprimary/nonculture/carrier identity " + id)
		check(not seen_paths.has(String(row.dialog_path)), "Unique resource path " + id)
		seen_ids[id] = true
		seen_paths[String(row.dialog_path)] = true
		scene_counts[scene_id] = int(scene_counts.get(scene_id, 0)) + 1
		if id.begins_with("harbour_life_"):
			var literal: String = "[\"" + id.trim_prefix("harbour_life_") + "\",\"" + String(row.npc_name) + "\","
			check(harbour_text.count(literal) == 1, "Native authored harbour identity/name exact once " + id)
		else:
			var matches: int = 0
			for actor: Dictionary in district.get("districts", {}).get(scene_id, {}).get("crowd", []):
				if "district_life_" + String(actor.get("id", "")) == id and actor.get("name") == row.npc_name: matches += 1
			check(matches == 1, "Native authored district identity/name exact once " + id)
		_test_dialog(row)
	check(scene_counts == {"ch4_s0_luoyang_gate":3,"ch4_s1_luoyang_yamen":2,"ch4_s3_luoyang_market":4,"ch4_s2_canal_docks":3}, "Exact3/2/4/3 authored scope, no extra residents")
	check(loaded_dialog_count == 12 and loaded_node_count == 24, "Twelve actual DialogScript and24 actual DialogNode resources")
	_finish(false)

func _test_dialog(row: Dictionary) -> void:
	var path: String = String(row.dialog_path)
	var value: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not check(value is DialogScript, "Real DialogScript type " + path): return
	var dialog: DialogScript = value as DialogScript
	loaded_dialog_count += 1
	check(dialog.get_script().resource_path == DOMAIN_SCRIPT and dialog.resource_path == path, "Actual domain script and direct build path " + path)
	check(String(dialog.dialog_id) == row.dialog_id and dialog.entry_node_id == &"start" and dialog.nodes.size() == 2, "Internal dialog identity and two-node entry " + path)
	check(dialog.required_story_flag == &"" and dialog.required_completed_quest == &"" and dialog.fallback_dialog_id == &"" and dialog.blocked_story_flag == &"" and dialog.required_free_inventory_slots == 0, "No script story/quest/inventory gates " + path)
	if dialog.nodes.size() != 2: return
	var record: Dictionary = {"npc_id":row.npc_id,"scene_id":row.scene_id,"dialog_path":path,"dialog_id":String(dialog.dialog_id),"nodes":[]}
	for index: int in 2:
		var node: DialogNode = dialog.nodes[index]
		if not check(node is DialogNode and node != null, "Actual DialogNode type " + path + "/" + str(index)): continue
		loaded_node_count += 1
		var node_id: StringName = &"start" if index == 0 else &"reply"
		check(node.get_script().resource_path == DOMAIN_NODE and node.node_id == node_id and dialog.find_node_by_id(node_id) == node, "Real node identity/lookup " + path + "/" + str(index))
		check(node.speaker == row.npc_name and node.text.length() >= 1 and node.text.length() <= 60 and node.portrait_path.is_empty() and node.voice_emotion == "normal", "Exact real speaker, short line, no portrait/voice credit " + path + "/" + str(index))
		check(node.on_end == ("next:reply" if index == 0 else "end"), "Only start→reply→end, no action command " + path + "/" + str(index))
		for field: String in EMPTY_ARRAY_FIELDS:
			var array_value: Variant = node.get(field)
			check(array_value is Array and array_value.is_empty(), "Zero " + field + " " + path + "/" + str(index))
		check(node.give_gold == 0 and node.accept_quest == &"" and node.complete_quest == &"" and node.weather_id == &"" and node.weather_strength == 1.0, "Zero scalar reward/quest/weather effects " + path + "/" + str(index))
		record.nodes.append({"node_id":String(node.node_id),"speaker":node.speaker,"text":node.text,"on_end":node.on_end,"voice_emotion":node.voice_emotion})
	check(dialog.get_entry_node() == dialog.nodes[0] and dialog.nodes[0] != dialog.nodes[1], "Two distinct real resources and entry instance " + path)
	records.append(record)

func _timeout() -> void:
	if not finished: _finish(true)

func _finish(timed_out: bool) -> void:
	if finished: return
	finished = true
	var source_after: Dictionary = snapshot(source_before)
	var saves_after: Dictionary = saves()
	var state_after: Dictionary = state()
	check(source_before.size() == 26 and source_before == source_after, "All24 fixed leaves plusfixture/self first/final SHA/bytes/String seconds facts exact")
	check(saves_before.size() == 15 and saves_before == saves_after, "All15 present or absent save facts exact; no restore or writes")
	check(state_before == state_after, "Actual flags/quests/inventory unchanged")
	check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended") == true, "Checkpoint writes remain suspended through own exit")
	check(not timed_out and Time.get_ticks_msec() - began < BUDGET_MS, "Fixed30s resource-only budget")
	var folder: String = "res://build/luoyang_city_completion_20261021ai_qa01/dialog_loader_%d" % OS.get_process_id()
	var report_path: String = folder.path_join("result.json")
	if FileAccess.file_exists(report_path):
		printerr("PRESERVE_EXISTING_AI_LIFE_RESOURCE_REPORT ", report_path)
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		printerr("AI_LIFE_REPORT_DIRECTORY_FAILED")
		quit(1)
		return
	var report: Dictionary = {"scope":"CANDIDATE_TWELVE_DIALOGSCRIPT_24NODES_IDENTITY_ZERO_EFFECTS_NOT_FIELD_OR_PRIMARY_BINDING","complete":failures == 0,"checks":checks,"failures":failures,"failure_details":failure_details,"elapsed_ms":Time.get_ticks_msec()-began,"budget_ms":BUDGET_MS,"loaded_dialog_count":loaded_dialog_count,"loaded_node_count":loaded_node_count,"source_first":source_before,"source_final":source_after,"saves_first":saves_before,"saves_final":saves_after,"state_first":state_before,"state_final":state_after,"records":records,"checkpoint_suspended":true,"formal_or_Field_or_voice_portrait_credit":false,"primary_culture_credit":"Preservation policy, exact eight exclusions and source/state immutability only; runtime secondary topic integration not tested","mtime_precision":"Godot seconds as String, not Windows exactticks; Root fresh2094 external guard is separate"}
	var file: FileAccess = FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		printerr("AI_LIFE_REPORT_OPEN_FAILED")
		quit(1)
		return
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print(JSON.stringify({"reportpath":report_path,"report_sha256":FileAccess.get_sha256(report_path),"complete":failures == 0,"checkscount":checks,"failures":failures,"dialogs":loaded_dialog_count,"nodes":loaded_node_count}))
	quit(0 if failures == 0 else 1)
