extends "res://tests/test_luoyang_culture_letter_field_draft_20261019x.gd"
## NEW Market-only continuation. Never re-enters Docks or changes the old FAIL.
const MARKET_READY := true
const MARKET_WHOLE_MS := 90000
const FIELD_PARENT := "res://tests/test_luoyang_culture_letter_field_draft_20261019x.gd"
const FIELD_PARENT_SHA := "7cb17d4e5ad6b182a46782203e749405016d247a4cb5f1c8e46a34aec83aca0e"
const ACTUAL_DOCKS_REPORT := "res://build/luoyang_culture_letter_field_20261019x/102268/result.json"
const ACTUAL_DOCKS_REPORT_SHA := "c4c10fda85cdf396196445e7ddb97172e4712c01f6c8b990a8a8e0d6a55bb4bb"
const BUYER_AUTHOR := "res://data/maps/luoyang_district_life_20261016f/author.json"
const BUYER_MOVES := "res://build/luoyang_layout_quest_20261018t_layout_source01/author_retry2.json"
var reused_docks_receipt: Dictionary = {}

func _market_precheck() -> bool:
	if not check(MARKET_READY, "Frozen NEW Market-only key, not a rerun of the Docks handoff"): return false
	if not track(FIELD_PARENT, FIELD_PARENT_SHA) or not track(ACTUAL_DOCKS_REPORT, ACTUAL_DOCKS_REPORT_SHA) or not _precheck_field(): return false
	var prior := json(ACTUAL_DOCKS_REPORT)
	if not check(prior.get("scope") == "DEFAULT_TWO_FIELD_NATIVE_PERSONAL_HANDOFF_AND_MARKET_REPORT_ONLY" and prior.get("complete") == false and prior.get("failures") == 1 and prior.get("checks") == 2796 and prior.get("native_queries") == 17, "Prior two-Field whole result remains FAIL; only its completed real Docks component is reused"): return false
	if not check(prior.get("source_before", {}).size() == 1759 and prior.source_before == prior.get("source_after") and prior.get("players_before", {}).size() == 15 and prior.players_before == prior.get("players_after"), "Prior real handoff component all1759 source and fifteen save facts unchanged"): return false
	var count := 0
	for record: Dictionary in prior.records:
		if record.get("kind") != "REAL_PERSONAL_HANDOFF": continue
		count += 1
		if not check(record.get("actual_world_presence_verified") == true and record.get("pure_bool_api_used") == false and record.get("letter_node_id", 0) > 0, "Prior native same-Node handoff receipt, not a simulated pickup flag"): return false
		reused_docks_receipt = record.receipt.duplicate(true)
		if not check(reused_docks_receipt.get("ok") == true and reused_docks_receipt.get("accepted") == true and reused_docks_receipt.get("actual_handoff") == true and reused_docks_receipt.get("event") == "pickup" and reused_docks_receipt.get("scene_id") == DOCKS and reused_docks_receipt.get("npc_id") == CLERK and reused_docks_receipt.get("normal_dialog_end") == true and reused_docks_receipt.get("sealed_letter_node") == record.letter_node_id and reused_docks_receipt.get("numeric_reward") == 0, "Every actual original-clerk/letter/end/zero-reward handoff authority retained"): return false
	if not check(count == 1 and reused_docks_receipt.get("state", {}).size() == 6, "One prior completed Docks handoff with exactly six persistent state fields"): return false
	var collected: Dictionary = reused_docks_receipt.state.duplicate(true)
	for key: String in ["schema_version", "report_count"]:
		var number: Variant = collected.get(key)
		if not check(typeof(number) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(number)) and float(number) == floor(float(number)) and float(number) == (1.0 if key == "schema_version" else 0.0), "Prior persisted collected numeric field remains exact legal integral " + key): return false
		collected[key] = int(number)
	if not check(collected.get("quest_id") == LETTER and collected.get("status") == "collected" and collected.get("answer_id") == "verify_consent_deliver" and collected.get("clues") == ["letter_envelope_mark", "recipient_independent_token", "booking_original_entry"], "Actual prior collected state retains the three independent clues/correct answer and no report"): return false
	seeded_parts.flags[api.state_key(LETTER)] = JSON.stringify(collected)
	seeded_parts.quests[LETTER] = 1
	var check_state: Dictionary = api.read_state(LETTER, seeded_parts.flags, seeded_parts.quests)
	if not check(check_state.get("ok") == true and check_state.get("state") == collected, "Restore actual prior handoff as explicit SaveManager-compatible JSON-string flags plus QM1, not a new pickup event"): return false
	for path: String in [BUYER_AUTHOR, BUYER_MOVES]:
		if not check(expected_maps[MARKET].has(path), "Independent buyer placement source belongs to admitted Market closure " + path) or not track(path, expected_maps[MARKET][path]): return false
	var author := json(BUYER_AUTHOR)
	var buyers: Array = []
	for row: Dictionary in author.districts[MARKET].crowd:
		if row.id == "market_buyer": buyers.append(row)
	if not check(buyers.size() == 1 and _v(buyers[0].foot_px) == Vector2(1110, 1240) and buyers[0].distance_px == 0 and buyers[0].name == "采买妇人", "Independent original stationary buyer source is1110,1240;2820,1900 belongs to another resident"): return false
	for move: Dictionary in json(BUYER_MOVES).districts[MARKET].crowd_moves:
		if not check(move.id != "market_buyer", "No approved city-layout successor moved this buyer"): return false
	records.append({"kind": "REUSED_PRIOR_REAL_DOCKS_COMPONENT_NOT_RERUN", "prior_report": ACTUAL_DOCKS_REPORT, "prior_whole_complete": false, "prior_whole_failures": 1, "prior_pid": 102268, "actual_handoff_receipt": reused_docks_receipt, "restored_state": collected, "new_run_pickup_or_Docks_credit": false, "prior_image_does_not_grant_handoff_visual_art_PASS": true})
	return true

func _market_only() -> bool:
	if not await _arrive(MARKET, Vector2(1110, 1350)) or not await _move(Vector2(1110, 1350), Vector2(1110, 1300)): return false
	var buyer := _person(BUYER)
	if buyer == null: return false
	var player := field.get("_player") as CharacterBody2D
	if not check(buyer.position == Vector2(1110, 1240) and buyer.npc_name == "采买妇人" and buyer.portrait_path == ready.contract.pickup.portrait_path and buyer.global_position.distance_to(player.global_position) <= 118.0 and _state().status == "collected", "Actual same-identity Market recipient at independently authored foot and within original native118 range"): return false
	records.append({"kind": "ACTUAL_MARKET_RECIPIENT_BEFORE_SPACE", "npc_id": buyer.npc_id, "npc_instance": buyer.get_instance_id(), "foot": buyer.position, "player": player.position, "distance": buyer.global_position.distance_to(player.global_position), "old_wrong_qa_station_not_reused": true})
	if not await _space_topic(BUYER) or not _choose(ready.text_by_id[LETTER].report_choice) or not await _drain(): return false
	var debug: Dictionary = field.call("get_culture_integration_state")
	if not check(_state().status == "reported" and _state().report_count == 1 and qm.call("get_status", StringName(LETTER)) == 2 and debug.get("last_receipt", {}).get("event") == "report" and debug.get("last_receipt", {}).get("accepted") == true and debug.get("last_receipt", {}).get("numeric_reward") == 0, "Real Market normal Space/explicit report completes exactly once from prior actual collected handoff", debug): return false
	records.append({"kind": "ACTUAL_MARKET_REPORT_ONCE", "receipt": debug.last_receipt.duplicate(true), "state": _state(), "numeric_reward": 0})
	if not await _space_topic(BUYER): return false
	var node := dp.get("_current_node") as DialogNode
	for choice: Dictionary in node.choices:
		if not check(choice.text != ready.text_by_id[LETTER].report_choice, "Completed recipient offers no repeated report action"): return false
	if not await _drain(): return false
	if not check(not dp.call("is_playing") and _state().report_count == 1 and qm.call("get_status", StringName(LETTER)) == 2 and _rewards() == original_rewards and _person(BUYER) != null, "After-dialogue ends normally, recipient remains unique and no duplicate/numeric/inventory reward"): return false
	return await _picture("market_recipient_after_report_dialog_closed")

func _run() -> void:
	began = Time.get_ticks_msec(); deadline = began + MARKET_WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	players_before = saves()
	folder = "res://build/luoyang_culture_letter_market_only_20261019x/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var complete := _market_precheck()
	if complete:
		dp = root.get_node("DialogPlayer"); gs = root.get_node("GameState"); qm = root.get_node("QuestManager")
		original_parts = {"flags": gs.get("flags").duplicate(true), "quests": qm.call("to_dict").duplicate(true)}
		original_rewards = _rewards()
		gs.set("flags", seeded_parts.flags.duplicate(true)); qm.call("from_dict", seeded_parts.quests.duplicate(true))
		complete = check(_state().status == "collected" and qm.call("get_status", StringName(LETTER)) == 1, "Only exact prior actual Docks collected save-parts restored as explicit representative precondition")
		driver = (load(INPUT_PATH) as Script).new(); driver.configure(self)
		if complete: complete = await _market_only()
	if driver != null: driver.release(); driver = null
	if is_instance_valid(current_scene):
		var own := current_scene; var weak: WeakRef = weakref(own)
		current_scene = null; own.queue_free(); field = null; scene = null; own = null
		await process_frame; await process_frame
		check(weak.get_ref() == null, "Own Market Field naturally exited")
	if dp != null and dp.call("is_playing"): dp.call("_end_dialog")
	if not original_parts.is_empty():
		gs.set("flags", original_parts.flags.duplicate(true)); qm.call("from_dict", original_parts.quests.duplicate(true))
		check(gs.get("flags") == original_parts.flags and qm.call("to_dict") == original_parts.quests and _rewards() == original_rewards, "Original process state and zero reward channels restored; no user slot touched")
	oracle = null; mask = null
	var source_after: Dictionary = {}
	for path: String in source_before: source_after[path] = fact(path)
	var players_after := saves()
	check(source_before == source_after and players_before == players_after and players_before.size() == 15, "All current Market/test sources and fifteen existing/absent save facts unchanged")
	check(Time.get_ticks_msec() < deadline, "Fixed ninety-second single-Market continuation, sixty-second arrival unchanged")
	check(pictures.size() == 1 and prior_fields.is_empty(), "Only one Market setup and one dialog-closed picture; no Docks rerun")
	var path := folder.path_join("result.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"scope": "DEFAULT_SINGLE_MARKET_REPORT_AFTER_PRIOR_REAL_DOCKS_COMPONENT_ONLY", "complete": complete and failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "budget_ms": MARKET_WHOLE_MS, "arrival_ms": ARRIVAL_MS, "native_queries": native_queries, "records": records, "pictures": pictures, "players_before": players_before, "players_after": players_after, "source_before": source_before, "source_after": source_after, "prior_two_Field_whole_FAIL_retained": true, "Docks_handoff_rerun": false}, "\t")); file.close()
	print(JSON.stringify({"report_path": path, "checks": checks, "failures": failures, "complete": complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)
