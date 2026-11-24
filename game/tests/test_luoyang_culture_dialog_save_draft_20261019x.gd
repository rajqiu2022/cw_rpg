extends "res://tests/test_luoyang_culture_source_admission_draft_20261019x.gd"
## Every record is CONTROLLED_OWNER_NOT_REAL_MAP. No C setup, travel or pickup credit.
const CONTROLLED_READY := true
const CONTROL_CLOSURE := "res://build/luoyang_culture_integration_20261019x_source01/frozen_source_closure_retry3b_bool_notice_false.json"
const CONTROL_CLOSURE_SHA := "0508fa53b1ef79d339d8a0822a51db9859b93c3221a013d9480781f188694301"
const X := "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd"
const FIELD_PATH := "res://scripts/field/field_walkable_controller.gd"
const FIXED := {
	"res://scripts/autoload/dialog_player.gd": "b2738778617e1dc64577f5ad24f1c5b34de3750c899caa7a467bca06a7cb8964",
	"res://scripts/autoload/quest_manager.gd": "c6ebd067f9b2e0660aa105e90c6ec7c777da895c19fcd701e438a2811405a03c",
	"res://scripts/autoload/game_state.gd": "9120f2c11c78eed304896bb6c9aa365b9db525711a7e1b17a43d13205bf94c4e",
	"res://scripts/autoload/inventory.gd": "727a2742aff63569f2a4d91ff5b69ac28191d5e146f600084e29e1f9dd76f276",
	"res://scripts/autoload/event_bus.gd": "c42bdb64161dfec0aa7e65e6027b0b335dee358f84558068abb54ccd26785db8",
	"res://scripts/autoload/scene_router.gd": "15665b17fde4aad37a9609fc46f441dad3893ce1b3ba3f02f530f44e916d6759",
	"res://scenes/field_walkable.tscn": "d605d74a12f297b1472ae613cbb38d567672808c44c0a11d0d01279a6c240058",
	"res://scenes/npc_node.tscn": "fd497082cbb1c7e2028cb6063074aeb066f81d4c8505d35f5428bb0607ca4191",
	"res://scenes/player.tscn": "db2ecb970904c4c7242b44cbdb1a7befe5d7ad5c2af6f4fc561a0a04edbc55b8",
	"res://scripts/field/player.gd": "9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419",
	"res://scripts/field/npc_node.gd": "67c0f3deafef65445918b5815f4acdcb4cc577206248f20cd67a998930d00bea",
}
const ACTOR_NAMES := {"district_life_yamen_petitioner": "候见乡民", "district_life_yamen_clerk": "书办", "harbour_life_gate_supply_attendant": "货担主人", "luoyang_paper_scholar": "南市书生", "harbour_life_docks_booking_attendant": "记货伙计", "district_life_market_buyer": "采买妇人"}
var api: Script
var ready: Dictionary = {}
var coordinator: RefCounted
var fixture: Node
var layer: Node2D
var player: Player
var dp: Node
var gs: Node
var qm: Node
var router: Node
var original: Dictionary = {}
var last_finish: Dictionary = {}
var last_action_finish: Dictionary = {}
var letter_setup_parts: Dictionary = {}
var notice_count := 0

func precheck_controlled() -> bool:
	if not check(CONTROLLED_READY, "NOTREADY until exact final x closure and controlled owner reviewed"): return false
	if not track(CONTROL_CLOSURE, CONTROL_CLOSURE_SHA): return false
	var frozen := json(CONTROL_CLOSURE)
	if not check(frozen.get("count") == 53 and frozen.get("bad", []).is_empty() and frozen.get("source_sha256", {}).size() == 53, "Exact fifty-three-leaf pre-activation candidate closure"): return false
	var expected: Dictionary = frozen.source_sha256.duplicate(true)
	if not check(expected.has(X) and expected.has(FIELD_PATH), "Explicit frozen coordinator and exact Field authority"): return false
	for path: String in expected:
		if not track(path, expected[path]): return false
		if path.ends_with(".gd"):
			var script: Script = load(path) as Script
			if not check(script is GDScript and script.can_instantiate(), "Every non-entry candidate API actually compiles and can instantiate " + path): return false
	for path: String in FIXED:
		if not track(path, FIXED[path]): return false
	if not track(get_script().resource_path, FileAccess.get_sha256(get_script().resource_path)): return false
	if not track("res://tests/test_luoyang_culture_source_admission_draft_20261019x.gd", FileAccess.get_sha256("res://tests/test_luoyang_culture_source_admission_draft_20261019x.gd")): return false
	api = load(X)
	if not check(api is GDScript and api.can_instantiate(), "Actual coordinator compiled and instantiable before any constant/API access"): return false
	var args: Array = OS.get_cmdline_user_args()
	if not check(args == [api.FLAG], "Exactly the one explicit culture-integration candidate flag, not default Field credit"): return false
	ready = api.readiness()
	if not check(ready.get("ok") == true, "Actual final coordinator readiness", ready): return false
	var actual: Dictionary = api.source_paths()
	for path: String in actual:
		if not check(expected.has(path), "Whole coordinator runtime leaf is independently authorized " + path): return false
		if not track(path, expected[path]): return false
	return check(api.enabled() == true, "Actual integration enabled without any guard bypass")

func _snapshot() -> Dictionary:
	return {"flags": gs.get("flags").duplicate(true), "quests": qm.call("to_dict").duplicate(true), "gold": gs.get("gold"), "inventory": root.get_node("Inventory").call("to_dict").duplicate(true), "training_total": gs.get("training_points_total"), "training_available": gs.get("training_points_available"), "reputation": gs.get("reputation")}

func _make_owner() -> bool:
	dp = root.get_node("DialogPlayer"); gs = root.get_node("GameState"); qm = root.get_node("QuestManager"); router = root.get_node("SceneRouter")
	original = {"snapshot": _snapshot(), "qm_states": qm.get("states").duplicate(true), "tracked": qm.get("tracked_side_quest_id"), "router_field": router.get("_current_field_id"), "current_scene": current_scene}
	var packed: PackedScene = load("res://scenes/field_walkable.tscn")
	fixture = packed.instantiate()
	var real_script: Script = fixture.get_script()
	fixture.set_script(null)
	root.add_child(fixture)
	fixture.set_script(real_script)
	fixture.process_mode = Node.PROCESS_MODE_DISABLED
	layer = Node2D.new(); fixture.add_child(layer)
	fixture.set("world_container", layer); fixture.set("_actor_layer", layer)
	player = (load("res://scenes/player.tscn") as PackedScene).instantiate() as Player
	var body: CollisionShape2D = player.get_node("CollisionShape2D")
	var rect := RectangleShape2D.new(); rect.size = Vector2(34, 24); body.shape = rect; body.position = Vector2.ZERO
	layer.add_child(player)
	fixture.set("_player", player)
	fixture.set("_field_loading_complete", true); fixture.set("_field_loading_failed", false)
	fixture.set("_scene_rebuilding", false); fixture.set("_resident_parked", false)
	current_scene = fixture
	coordinator = api.new(); coordinator.attach(fixture)
	dp.text_displayed.connect(_observe)
	root.get_node("EventBus").dialog_ended.connect(_ended)
	root.get_node("EventBus").flag_set.connect(_flag_notice)
	return check(fixture.get_script().resource_path == FIELD_PATH and fixture.is_inside_tree() and player.is_inside_tree(), "CONTROLLED_OWNER_NOT_REAL_MAP: same real Field script after native-ready, actual Player body; no Field._ready/setup/C")

func _observe(_speaker: String, _text: String, _has_choices: bool, _portrait: String) -> void:
	var before: Dictionary = coordinator.debug_state()
	coordinator.observe_node()
	var script: DialogScript = dp.get("_current_script") as DialogScript
	var node: DialogNode = dp.get("_current_node") as DialogNode
	records.append({"scope": "CONTROLLED_OWNER_NOT_REAL_MAP", "kind": "ACTUAL_DP_NODE_OBSERVATION", "script_id": String(script.dialog_id) if script != null else "", "node_id": String(node.node_id) if node != null else "", "before": before, "after": coordinator.debug_state()})
func _ended(id: StringName) -> void:
	var before: Dictionary = coordinator.debug_state()
	var prior_notices := notice_count
	last_finish = coordinator.finish(id)
	check(notice_count - prior_notices == (1 if last_finish.get("committed") == true else 0), "Exactly one safe boolean notification per actual committed state and none for decline/error/feedback")
	var plain: Dictionary = last_finish.duplicate(true)
	if plain.get("feedback") is DialogScript:
		plain["feedback_dialog_id"] = String(plain.feedback.dialog_id)
		plain.erase("feedback")
	if plain.get("matched") == true or plain.get("ok") == false: last_action_finish = plain.duplicate(true)
	records.append({"scope": "CONTROLLED_OWNER_NOT_REAL_MAP", "kind": "ACTUAL_EVENTBUS_DIALOG_END_RECEIPT", "dialog_id": String(id), "selected_and_session_before": before, "finish": plain, "after": coordinator.debug_state(), "actual_flags_and_QM": {"flags": gs.get("flags").duplicate(true), "quests": qm.call("to_dict").duplicate(true)}})
	if last_finish.get("feedback") is DialogScript: dp.call("play", last_finish.feedback)

func _flag_notice(flag: StringName, value: Variant) -> void:
	if not String(flag).begins_with("luoyang_culture_x_"): return
	check(flag == &"luoyang_culture_x_progress_changed" and typeof(value) == TYPE_BOOL and value == true, "Existing global flag listeners receive only the dedicated bool true notice, never Dictionary or JSON text", {"flag": String(flag), "value": value, "type": typeof(value)})
	notice_count += 1

func _context(scene_id: String, npc_id: String) -> bool:
	if not check(not dp.call("is_playing"), "Context change only outside an actual dialogue"): return false
	coordinator.abort("controlled_context_switch")
	for npc: NPCNode in fixture.get("_npc_nodes"):
		layer.remove_child(npc); npc.free()
	var scene := SceneScript.new(); scene.scene_id = StringName(scene_id)
	fixture.set("_current_scene", scene); router.set("_current_field_id", scene.scene_id)
	var npc: NPCNode = (load("res://scenes/npc_node.tscn") as PackedScene).instantiate() as NPCNode
	npc.npc_id = npc_id; npc.npc_name = ACTOR_NAMES[npc_id]; npc.position = Vector2(100, 100)
	npc.dialog_id = "luoyang_city_tasks_20261016/paper_offer" if npc_id == "luoyang_paper_scholar" else "controlled_original_primary"
	layer.add_child(npc)
	var actors: Array[NPCNode] = [npc]
	fixture.set("_npc_nodes", actors)
	player.position = Vector2(100, 160)
	var configured: Dictionary = coordinator.configure_actors()
	return check(configured.get("ok") == true and coordinator.handles(npc_id), "CONTROLLED_OWNER_NOT_REAL_MAP exact native actor/body/current Router identity " + npc_id)

func _choose(label: String) -> bool:
	var node: DialogNode = dp.get("_current_node") as DialogNode
	if not check(dp.call("is_playing") and node != null and node.has_choices(), "Actual DialogPlayer choice node before selection " + label): return false
	var matching: Array[int] = []
	for i: int in node.choices.size():
		if node.choices[i].text == label: matching.append(i)
	if not check(matching.size() == 1, "One exact visible dialogue choice " + label, node.choices): return false
	dp.call("choose", matching[0])
	return true

func _drain() -> bool:
	for i: int in 16:
		if not dp.call("is_playing"): return true
		var node: DialogNode = dp.get("_current_node") as DialogNode
		if not check(Time.get_ticks_msec() - began < BUDGET_MS and node != null and not node.has_choices(), "Bounded normal DP advance, never auto-choose menus"): return false
		dp.call("advance")
	return check(false, "Actual dialogue did not finish within sixteen native nodes")

func _topic(qid: String, actor: Dictionary) -> bool:
	if not _context(actor.scene_id, actor.npc_id): return false
	last_finish = {}
	var opened: Dictionary = coordinator.open(actor.npc_id)
	if not check(opened.get("ok") == true and opened.get("script") is DialogScript, "Actual coordinator builds independent topic menu"): return false
	dp.call("play", opened.script)
	return _choose(ready.text.common.culture_topics) and _choose(ready.text_by_id[qid].topic_label)

func _saved_state(qid: String) -> Dictionary:
	var result: Dictionary = api.read_state(qid, gs.get("flags"), qm.get("states"))
	check(result.get("ok") == true, "Actual durable GS/QM state agrees " + qid, result)
	return result.get("state", {})

func _save_roundtrip(qid: String) -> bool:
	var before: Dictionary = _saved_state(qid)
	var key: String = api.state_key(qid)
	var stored: Variant = gs.get("flags").get(key)
	if not check(stored is String, "Existing flags slot persists structured cultural state as JSON String, not raw Dictionary", {"qid": qid, "type": typeof(stored)}): return false
	var decoded: Variant = JSON.parse_string(stored)
	if not check(decoded is Dictionary and decoded.size() == 6, "Exactly six fields decoded from persisted JSON String", {"decoded_type": typeof(decoded), "decoded": decoded}): return false
	var canonical: Dictionary = decoded.duplicate(true)
	var numeric_types: Dictionary = {}
	for numeric: String in ["schema_version", "report_count"]:
		var value: Variant = decoded.get(numeric)
		numeric_types[numeric] = {"decoded_type": typeof(value), "normalized_type": typeof(before.get(numeric)), "value": value}
		if not check(typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == floor(float(value)) and (float(value) == 1.0 if numeric == "schema_version" else float(value) >= 0.0 and float(value) <= 1.0), "JSON numeric field must independently be finite exact integral and in the original discrete domain " + numeric, numeric_types[numeric]): return false
		canonical[numeric] = int(value)
	if not check(canonical == before, "All six reducer fields equal after only exact legal integer canonicalization, never epsilon or field omission", {"decoded": decoded, "canonical": canonical, "before": before, "numeric_types": numeric_types}): return false
	for bad: Variant in [null, decoded.duplicate(true), true, 1, .5, [], "{", "[]", "null", "true"]:
		var bad_flags: Dictionary = gs.get("flags").duplicate(true)
		bad_flags[key] = bad
		var refused: Dictionary = api.read_state(qid, bad_flags, qm.get("states"))
		var expected_error := "CULTURE_X_STATE_JSON_NOT_DICTIONARY" if bad is String else "CULTURE_X_STATE_NOT_JSON_STRING"
		if not check(refused.get("ok") == false and refused.get("error") == expected_error, "Raw Dictionary/nonString or malformed/nonDictionary JSON is strictly refused without actual-state mutation", {"value": bad, "result": refused}): return false
	var invalid: Dictionary = decoded.duplicate(true); invalid.report_count = .5
	var invalid_flags: Dictionary = gs.get("flags").duplicate(true); invalid_flags[key] = JSON.stringify(invalid)
	if not check(api.read_state(qid, invalid_flags, qm.get("states")).get("error") == "CULTURE_X_SAVED_STATE_INVALID", "Decoded nonintegral structured state remains invalid; string encoding is not a permissive bypass"): return false
	var parts: Dictionary = {"flags": gs.get("flags").duplicate(true), "quests": qm.call("to_dict").duplicate(true)}
	var parsed: Variant = JSON.parse_string(JSON.stringify(parts))
	if not check(parsed is Dictionary, "Actual SaveManager-compatible flags/quests JSON parts, no disk slots"): return false
	gs.set("flags", parsed.flags.duplicate(true)); qm.call("from_dict", parsed.quests.duplicate(true))
	return check(_saved_state(qid) == before, "QM.from_dict and existing GS flags storage retain cultural phase/clues/answer/report exactly")

func _missing_option(label: String) -> bool:
	var node: DialogNode = dp.get("_current_node") as DialogNode
	if not check(node != null, "Actual node exists for refusal observation"): return false
	for choice: Dictionary in node.choices:
		if choice.text == label: return check(false, "Unauthorized topic action unexpectedly visible " + label)
	return check(true, "No unauthorized visible action " + label)

func _close_without_action() -> bool:
	coordinator.abort("controlled_cancel_no_action")
	dp.call("_end_dialog")
	return check(not dp.call("is_playing"), "Cancelled controlled session cannot consume an event")

func _negative_sessions(qid: String, issuer: Dictionary) -> bool:
	var text: Dictionary = ready.text_by_id[qid]
	var before := _snapshot()
	if not _topic(qid, issuer) or not _choose(text.accept_choice): return false
	var early: Dictionary = coordinator.finish(dp.get("_current_script").dialog_id)
	check(early.get("ok") == false and early.get("error") == "CULTURE_X_NOT_NORMAL_SESSION_END" and _snapshot() == before, "Direct finish before real DP end cannot commit")
	player.position += Vector2(500, 0)
	if not _drain(): return false
	check(_snapshot() == before and last_finish.get("ok") == false, "Far-away actor after terminal selection cannot accept or mutate progress")
	if not _topic(qid, issuer) or not _choose(text.accept_choice): return false
	fixture.set("_resident_parked", true)
	if not _drain(): return false
	check(_snapshot() == before and last_finish.get("ok") == false, "Parked/stale Field cannot commit selected action")
	fixture.set("_resident_parked", false)
	if not _topic(qid, issuer) or not _choose(text.accept_choice): return false
	var actor: NPCNode = fixture.get("_npc_nodes")[0]
	actor.npc_id = "harbour_life_gate_supply_attendant"
	if not _drain(): return false
	check(_snapshot() == before and last_finish.get("ok") == false, "Actual live but wrong issuer cannot consume selected acceptance")
	if not _topic(qid, issuer) or not _choose(text.accept_choice): return false
	var changed_scene := SceneScript.new(); changed_scene.scene_id = StringName(issuer.scene_id)
	fixture.set("_current_scene", changed_scene)
	if not _drain(): return false
	check(_snapshot() == before and last_finish.get("ok") == false, "Same-name replacement Scene instance cannot reuse the conversation lease")
	if not _topic(qid, issuer) or not _choose(text.accept_choice): return false
	coordinator.abort("controlled_explicit_abort_before_end")
	if not _drain(): return false
	return check(_snapshot() == before, "Explicit cancellation of selected action never accepts task")

func _primary_contract() -> bool:
	var scholar: Dictionary = {"scene_id": "ch4_s3_luoyang_market", "npc_id": "luoyang_paper_scholar"}
	if not _context(scholar.scene_id, scholar.npc_id): return false
	var before := _snapshot()
	var opened: Dictionary = coordinator.open(scholar.npc_id)
	if not check(opened.get("ok") == true, "Original primary has actual top-level menu entry"): return false
	dp.call("play", opened.script)
	if not _choose(ready.text.primary_option_labels[scholar.npc_id]) or not _drain(): return false
	return check(last_finish.get("primary", {}).get("dialog_id") == "luoyang_city_tasks_20261016/paper_offer" and _snapshot() == before, "Controlled primary dispatch preserves exact existing task ID without consuming culture action")

func exercise_controlled() -> bool:
	if not _make_owner(): return false
	for qid: String in ready.quests:
		var absent: Dictionary = api.read_state(qid, {}, {})
		if not check(absent.get("ok") == true and absent.get("state", {}).get("status") == "not_started", "Genuinely absent state with unaccepted QM remains a legal blank"): return false
		var explicit_null: Dictionary = {}; explicit_null[api.state_key(qid)] = null
		if not check(api.read_state(qid, explicit_null, {}).get("error") == "CULTURE_X_STATE_NOT_JSON_STRING", "Explicit null is malformed storage, distinct from absent even before accepting"): return false
	if not _primary_contract(): return false
	var reward_before: Dictionary = _snapshot()
	for qid: String in ready.quests:
		var row: Dictionary = ready.quests[qid]
		var text: Dictionary = ready.text_by_id[qid]
		var issuer: Dictionary = api.ISSUERS[qid]
		var solver: Dictionary = api.SOLVERS[qid]
		if qid == "q_ch4_side_08_qiangxiang_receipt" and not _negative_sessions(qid, issuer): return false
		# Witnesses cannot accept another actor's commission.
		for actor: Dictionary in row.actors:
			if actor == issuer: continue
			if not _topic(qid, actor) or not _missing_option(text.accept_choice) or not _close_without_action(): return false
		if not _topic(qid, issuer) or not _choose("暂时不接") or not _drain(): return false
		var decline_debug: Dictionary = coordinator.debug_state()
		if not check(last_action_finish.get("ok") == true and last_action_finish.get("matched") == true and last_action_finish.get("committed") == false and decline_debug.get("last_receipt", {}).get("accepted") == false and decline_debug.get("last_receipt", {}).get("event") == "decline", "Real DP decline is an authorized successful reducer event, not an error that happens to leave state unchanged", {"last_action_finish": last_action_finish, "coordinator": decline_debug}): return false
		check(qm.call("get_status", StringName(qid)) == 0 and _saved_state(qid).status == "not_started", "Real DP decline leaves task untouched")
		if not _topic(qid, issuer) or not _choose(text.accept_choice) or not _drain(): return false
		check(qm.call("get_status", StringName(qid)) == 1 and _saved_state(qid).status == "active", "Real DP explicit acceptance is active, never completed", {"last_finish": last_action_finish, "coordinator": coordinator.debug_state(), "durable_state": _saved_state(qid), "actual_QM": qm.call("to_dict")})
		if not _save_roundtrip(qid): return false
		for clue: Dictionary in row.clues:
			if not _topic(qid, {"scene_id": clue.scene_id, "npc_id": clue.npc_id}): return false
			if not _missing_option("说说我的判断"): return false
			if not _choose("核对：" + clue.label) or not _drain(): return false
			check(qm.call("get_status", StringName(qid)) == 1, "Actual clue recording cannot complete task")
			if not _save_roundtrip(qid): return false
		if not _topic(qid, solver) or not _choose("说说我的判断"): return false
		var wrong := ""; var correct := ""
		for choice: Dictionary in row.choices:
			if choice.correct: correct = choice.id
			else: wrong = choice.id
		var with_clues := _saved_state(qid).duplicate(true)
		if not _choose(text.choice_labels[wrong]) or not _drain(): return false
		check(_saved_state(qid) == with_clues and qm.call("get_status", StringName(qid)) == 1, "Actual wrong DP answer preserves all clues and allows retry")
		if not _topic(qid, solver) or not _choose("说说我的判断") or not _choose(text.choice_labels[correct]) or not _drain(): return false
		check(_saved_state(qid).status == "solved" and qm.call("get_status", StringName(qid)) == 1, "Correct actual answer only solves; explicit separate report required")
		if not _save_roundtrip(qid): return false
		if qid == api.LETTER:
			if not _topic(qid, row.reporter) or not _missing_option(text.report_choice) or not _close_without_action(): return false
			letter_setup_parts = {"flags": gs.get("flags").duplicate(true), "quests": qm.call("to_dict").duplicate(true)}
			records.append({"scope": "CONTROLLED_OWNER_NOT_REAL_MAP", "kind": "LETTER_SOLVED_PREREQUISITES_FOR_SEPARATE_REAL_FIELD", "save_parts": letter_setup_parts.duplicate(true), "actual_pickup_or_Field_credit": false})
			continue
		if not _topic(qid, row.reporter) or not _choose(text.report_choice) or not _drain(): return false
		check(_saved_state(qid).status == "reported" and _saved_state(qid).report_count == 1 and qm.call("get_status", StringName(qid)) == 2, "Actual QM completion only after explicit DP report once")
		if not _save_roundtrip(qid): return false
		if not _topic(qid, row.reporter): return false
		check(not qm.call("complete", StringName(qid)), "QuestManager refuses duplicate completion")
		if not _drain(): return false
		records.append({"scope": "CONTROLLED_OWNER_NOT_REAL_MAP", "kind": "ACTUAL_DP_QM_COMPLETE_ONCE", "qid": qid, "state": _saved_state(qid), "numeric_reward": 0, "actual_city_travel": false})
	var reward_after := _snapshot()
	for key: String in ["gold", "inventory", "training_total", "training_available", "reputation"]:
		check(reward_before[key] == reward_after[key], "All approved zero-reward channels unchanged " + key)
	return failures == 0

func _cleanup_controlled() -> void:
	if coordinator != null: coordinator.abort("controlled_cleanup")
	if dp != null:
		if dp.call("is_playing"): dp.call("_end_dialog")
		if dp.text_displayed.is_connected(_observe): dp.text_displayed.disconnect(_observe)
		if root.get_node("EventBus").dialog_ended.is_connected(_ended): root.get_node("EventBus").dialog_ended.disconnect(_ended)
		if root.get_node("EventBus").flag_set.is_connected(_flag_notice): root.get_node("EventBus").flag_set.disconnect(_flag_notice)
	if not original.is_empty():
		current_scene = original.current_scene
		router.set("_current_field_id", original.router_field)
		gs.set("flags", original.snapshot.flags.duplicate(true))
		qm.set("states", original.qm_states.duplicate(true)); qm.set("tracked_side_quest_id", original.tracked)
	if is_instance_valid(fixture):
		fixture.set_script(null); fixture.queue_free(); fixture = null
	coordinator = null

func _run() -> void:
	began = Time.get_ticks_msec()
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true); players_before = saves()
	var complete := false
	if precheck_controlled(): complete = exercise_controlled()
	_cleanup_controlled()
	await process_frame; await process_frame
	var source_after: Dictionary = {}
	for path: String in source_before: source_after[path] = fact(path)
	var players_after := saves()
	check(source_before == source_after and players_before == players_after and players_before.size() == 15, "Whole controlled source and fifteen save facts unchanged")
	if not original.is_empty(): check(_snapshot() == original.snapshot, "Controlled memory parts restored exactly; no user slots written")
	check(Time.get_ticks_msec() - began < BUDGET_MS, "Predeclared sixty-second controlled protocol only")
	var folder := "res://build/luoyang_culture_dialog_save_20261019x/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join("result.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"scope": "CONTROLLED_OWNER_NOT_REAL_MAP", "complete": complete and failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "budget_ms": BUDGET_MS, "source_before": source_before, "source_after": source_after, "players_before": players_before, "players_after": players_after, "records": records, "letter_setup_parts": letter_setup_parts, "actual_C_Field_setup_or_pickup_or_travel_credit": false}, "\t")); file.close()
	print(JSON.stringify({"report_path": path, "checks": checks, "failures": failures, "complete": complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)
