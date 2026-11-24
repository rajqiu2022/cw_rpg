extends RefCounted
## One live Field's conversation lease. Native w reducer/resources stay frozen.
## Persistent progress uses existing GameState.flags and QuestManager.states;
## no custom save schema or global action/choice/voice dispatcher is installed.
const W = preload("res://scripts/city/luoyang_cultural_sidequests_candidate_20261019w.gd")
const AP_NPC = preload("res://build/luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd")
const AP_PEOPLE = preload("res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people_execution.gd")
const AP_QUARTERS = ["luoyang_artisan_residential_20261022ap", "luoyang_riverside_garden_20261022ap"]
const SELF := "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd"
const INDEX := "res://scripts/city/luoyang_culture_integration_index_20261019x.gd"
const CONTRACT := "res://data/luoyang_culture_integration_20261019x/runtime_contract.json"
const CONTRACT_SHA := "d258350b1b72377fb4189918178a1323de9506934d015859a4d5823271961b9b"
const FIELD := "res://scripts/field/field_walkable_controller.gd"
const FLAG := "--luoyang-culture-integration-20261019x"
const STATE_PREFIX := "luoyang_culture_x_"
const CHANGED_FLAG := &"luoyang_culture_x_progress_changed"
const LETTER := "q_ch4_side_10_luoshui_letter"
const BUYER := "district_life_market_buyer"
const BOOKING := "harbour_life_docks_booking_attendant"
const MARKET := "ch4_s3_luoyang_market"
const DOCKS := "ch4_s2_canal_docks"
const IDS := ["ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen", DOCKS, MARKET, "luoyang_artisan_residential_20261022ap", "luoyang_riverside_garden_20261022ap"]
const ISSUERS := {
	"q_ch4_side_08_qiangxiang_receipt": {"scene_id": "ch4_s1_luoyang_yamen", "npc_id": "district_life_yamen_petitioner"},
	"q_ch4_side_09_luoshu_numbers": {"scene_id": MARKET, "npc_id": "luoyang_paper_scholar"},
	LETTER: {"scene_id": DOCKS, "npc_id": BOOKING},
}
const SOLVERS := {
	"q_ch4_side_08_qiangxiang_receipt": {"scene_id": "ch4_s1_luoyang_yamen", "npc_id": "district_life_yamen_clerk"},
	"q_ch4_side_09_luoshu_numbers": {"scene_id": MARKET, "npc_id": "luoyang_paper_scholar"},
	LETTER: {"scene_id": DOCKS, "npc_id": BOOKING},
}
var _field_ref: WeakRef
var _serial := 0
var _session: Dictionary = {}
var _last_receipt: Dictionary = {}
var _letter_sprite: Sprite2D
var _handoff_tween: Tween
var _feedback_id := ""

static func enabled() -> bool:
	if FLAG in OS.get_cmdline_user_args(): return true
	var authority: Variant = load(INDEX)
	return authority is GDScript and authority.resource_path == INDEX and authority.formal_enabled() == true

static func requested(scene_id: StringName) -> bool:
	return enabled() and String(scene_id) in IDS

static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error}

static func readiness() -> Dictionary:
	if CONTRACT_SHA.length() != 64 or FileAccess.get_sha256(CONTRACT) != CONTRACT_SHA: return _fail("CULTURE_X_CONTRACT_CHANGED")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
	if not raw is Dictionary or raw.get("schema_version") != 1 or raw.get("status") != "READY_EXACT_RUNTIME_SOURCES" or not raw.get("source_sha256") is Dictionary or raw.source_sha256.is_empty(): return _fail("CULTURE_X_CONTRACT_NOT_READY")
	for path: String in raw.source_sha256:
		if not path.begins_with("res://") or ".." in path or String(raw.source_sha256[path]).length() != 64 or FileAccess.get_sha256(path) != raw.source_sha256[path]: return _fail("CULTURE_X_SOURCE_CHANGED:" + path)
	var ready: Dictionary = W.readiness()
	if ready.get("ok") != true: return ready
	var text: Variant = JSON.parse_string(FileAccess.get_file_as_string(raw.text_path))
	if not text is Dictionary or text.get("schema_version") != 1 or text.get("quests", []).size() != 3: return _fail("CULTURE_X_TEXT_CONTRACT")
	var text_by_id: Dictionary = {}
	for row: Dictionary in text.quests: text_by_id[row.quest_id] = row
	for id: String in ready.quests:
		if not raw.canonical_quests.has(id) or not text_by_id.has(id): return _fail("CULTURE_X_QUEST_SOURCE_SET")
		var def: QuestDef = ResourceLoader.load(raw.canonical_quests[id]) as QuestDef
		if def == null or String(def.quest_id) != id or def.kind != QuestDef.Kind.SIDE or not def.completion_triggers.is_empty() or not def.auto_accept_triggers.is_empty() or def.reward_gold != 0 or def.reward_exp != 0 or not def.reward_items.is_empty() or not def.reward_skills.is_empty() or not def.reward_skills_by_faction.is_empty() or not def.reward_skills_by_flag.is_empty(): return _fail("CULTURE_X_CANONICAL_QUEST_MUST_BE_ZERO_REWARD_NO_AUTOCOMPLETE")
	return {"ok": true, "contract": raw, "quests": ready.quests, "text": text, "text_by_id": text_by_id}

static func source_paths() -> Dictionary:
	var ready := readiness()
	if ready.get("ok") != true: return {}
	var paths: Dictionary = {SELF: true, INDEX: true, CONTRACT: true}
	paths.merge(W.source_paths())
	for path: String in ready.contract.source_sha256: paths[path] = true
	var ap_paths: Dictionary=AP_NPC.source_paths()
	if ap_paths.is_empty(): return {}
	paths.merge(ap_paths)
	var quarter_paths: Dictionary=AP_PEOPLE.source_paths()
	if quarter_paths.is_empty(): return {}
	paths.merge(quarter_paths)
	return paths

static func state_key(qid: String) -> String:
	return STATE_PREFIX + String(W.IDS.get(qid, "unknown"))

static func read_state(qid: String, flags: Dictionary, quests: Dictionary) -> Dictionary:
	var blank := W.new_state(qid)
	if blank.get("ok") != true: return blank
	var raw: Variant = flags.get(state_key(qid), null)
	var status: Variant = quests.get(StringName(qid), quests.get(qid, 0))
	if not W._integer_in(status, 0, 3): return _fail("CULTURE_X_QM_STATE_TYPE")
	if not flags.has(state_key(qid)):
		return blank if status == 0 else _fail("CULTURE_X_QM_PROGRESS_WITHOUT_CULTURE_STATE")
	# Existing global flag listeners coerce values to bool, which cannot accept
	# Dictionary. Persist this tiny structured value as JSON text in the existing
	# flags slot; accept no raw Dictionary or implicit legacy-state conversion.
	if not raw is String: return _fail("CULTURE_X_STATE_NOT_JSON_STRING")
	raw = JSON.parse_string(raw)
	if not raw is Dictionary: return _fail("CULTURE_X_STATE_JSON_NOT_DICTIONARY")
	var ready := W.readiness()
	if ready.get("ok") != true or not W._state_valid(qid, raw, ready.quests[qid]): return _fail("CULTURE_X_SAVED_STATE_INVALID")
	var expected := 0 if raw.status == "not_started" else (2 if raw.status == "reported" else 1)
	if status != expected: return _fail("CULTURE_X_QM_AND_FLAGS_DISAGREE")
	var normalized: Dictionary = raw.duplicate(true)
	normalized.schema_version = 1; normalized.report_count = int(raw.report_count)
	return {"ok": true, "state": normalized}

static func project_rows(scene_id: StringName, original: Array, flags: Dictionary, quests: Dictionary) -> Dictionary:
	if not requested(scene_id): return {"ok": true, "npcs": original.duplicate(true), "matched": false}
	if String(scene_id) in AP_QUARTERS:
		return {"ok":true,"npcs":original.duplicate(true),"matched":true,"culture_quest_projection":false}
	var ready := readiness()
	if ready.get("ok") != true: return ready
	var letter := read_state(LETTER, flags, quests)
	if letter.get("ok") != true: return letter
	var pending: bool = letter.state.status == "solved"
	var out: Array = []
	var buyers := 0
	for row: Dictionary in original:
		if String(row.get("npc_id", "")) == BUYER:
			buyers += 1
			if String(scene_id) == MARKET and pending: continue
		out.append(row.duplicate(true))
	if buyers > 1 or (String(scene_id) == DOCKS and buyers != 0): return _fail("CULTURE_X_DUPLICATE_OR_FOREIGN_BUYER")
	if String(scene_id) == DOCKS and pending:
		var foot := Vector2(ready.contract.pickup.recipient_foot_px[0], ready.contract.pickup.recipient_foot_px[1])
		var city: Variant = load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
		if not city.safe_body(scene_id, foot): return _fail("CULTURE_X_PICKUP_FOOT_NOT_NATIVE_SAFE")
		out.append({"npc_id": BUYER, "npc_name": "采买妇人", "pos": foot / Vector2(3072, 2048), "sprite_path": String(ready.contract.pickup.sprite_path), "portrait_path": String(ready.contract.pickup.portrait_path), "scale": 1.0, "movement_mode": "idle", "dialog_id": "", "interaction_action": "", "district_life_ground_anchored": true, "culture_x_pickup_recipient": true})
	return {"ok": true, "npcs": out, "matched": true, "recipient_waiting_in_docks": pending}

func attach(field: Node) -> void:
	_field_ref = weakref(field)

func _field() -> Variant:
	return _field_ref.get_ref() if _field_ref != null else null

func _actor(field: Variant, id: String) -> NPCNode:
	var found: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if is_instance_valid(npc) and npc.npc_id == id:
			if found != null: return null
			found = npc
	return found

func _live_actor(field: Variant, actor: NPCNode) -> bool:
	if not is_instance_valid(actor) or not actor.is_inside_tree() or not actor.is_visible_in_tree() or actor.get_parent() != field.get("_actor_layer"): return false
	var body: StaticBody2D = actor.get("_body_collider")
	if not is_instance_valid(body) or not body.is_inside_tree() or body.collision_layer != 1 or body.get_child_count() != 1: return false
	var shape: CollisionShape2D = body.get_child(0) as CollisionShape2D
	return shape != null and not shape.disabled and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size.x > 0 and (shape.shape as RectangleShape2D).size.y > 0

func configure_actors() -> Dictionary:
	var field: Variant = _field()
	if not is_instance_valid(field): return _fail("CULTURE_X_FIELD_GONE")
	var scene: SceneScript = field.get("_current_scene")
	if scene == null or not requested(scene.scene_id): return {"ok": true, "matched": false}
	var ready := readiness()
	if ready.get("ok") != true: return ready
	var ap_ready: Dictionary=AP_NPC.readiness()
	if ap_ready.get("ok")!=true: return ap_ready
	var quarter_ready: Dictionary={}
	if String(scene.scene_id) in AP_QUARTERS:
		quarter_ready=AP_PEOPLE.readiness()
		if quarter_ready.get("ok")!=true: return quarter_ready
	for npc: NPCNode in field.get("_npc_nodes"):
		if not is_instance_valid(npc): continue
		if not quarter_ready.is_empty() and AP_PEOPLE.daily_handles_exact(scene.scene_id,npc.npc_id,quarter_ready.data):
			var primary: Dictionary=npc.get_meta("culture_x_primary",{"dialog_id":npc.dialog_id,"interaction_action":npc.interaction_action})
			var identity: Dictionary=AP_PEOPLE.validate_daily_identity_exact(scene.scene_id,{"npc_id":npc.npc_id,"npc_name":npc.npc_name,"dialog_id":primary.get("dialog_id",""),"interaction_action":primary.get("interaction_action",""),"dialog_variants":[]},quarter_ready.data)
			if identity.get("ok")!=true or identity.get("matched")!=true: return _fail("AP_QUARTER_PRIMARY_IDENTITY_REFUSED")
			if not npc.has_meta("culture_x_primary"): npc.set_meta("culture_x_primary",primary.duplicate(true))
			npc.set_meta("ap_quarter_daily_exact_identity",true)
			npc.interaction_action="culture_x_menu"
			npc.interact_area.set_deferred("monitoring",true)
			npc.interact_area.set_deferred("monitorable",true)
			continue
		# Twelve exact ambient identities are disjoint from culture actors. One
		# validated author is reused for the whole loop, not 59 hashes per actor.
		if not AP_NPC.daily_topics_exact(scene.scene_id,npc.npc_id,ap_ready.author).is_empty():
			var primary: Dictionary=npc.get_meta("culture_x_primary",{"dialog_id":npc.dialog_id,"interaction_action":npc.interaction_action})
			var daily: Dictionary=AP_NPC.validate_daily_identity_exact(scene.scene_id,{"npc_id":npc.npc_id,"npc_name":npc.npc_name,"dialog_id":primary.get("dialog_id",""),"interaction_action":primary.get("interaction_action",""),"dialog_variants":[]},ap_ready.author)
			if daily.get("ok")!=true or daily.get("matched")!=true: return _fail("AP_DAILY_PRIMARY_IDENTITY_REFUSED")
			if not npc.has_meta("culture_x_primary"): npc.set_meta("culture_x_primary",primary.duplicate(true))
			npc.set_meta("ap_daily_exact_identity",true)
			npc.interaction_action="culture_x_menu"
			npc.interact_area.set_deferred("monitoring",true)
			npc.interact_area.set_deferred("monitorable",true)
			continue
		var owns := false
		for q: Dictionary in ready.quests.values():
			for actor: Dictionary in q.actors:
				if actor.scene_id == String(scene.scene_id) and actor.npc_id == npc.npc_id: owns = true
		if npc.npc_id == BUYER and String(scene.scene_id) == DOCKS: owns = true
		if not owns: continue
		if not npc.has_meta("culture_x_primary"):
			npc.set_meta("culture_x_primary", {"dialog_id": npc.dialog_id, "interaction_action": npc.interaction_action})
			npc.interaction_action = "culture_x_menu"
		if npc.npc_id == BUYER: npc.portrait_path = String(ready.contract.pickup.portrait_path)
	return {"ok": true, "matched": true}

func _owned() -> bool:
	var field: Variant = _field()
	if not is_instance_valid(field) or not field.is_inside_tree() or field.get_script().resource_path != FIELD or field.get("_resident_parked") or field.get("_scene_rebuilding"): return false
	var scene: SceneScript = field.get("_current_scene")
	var player: Node2D = field.get("_player")
	var loading: Dictionary = field.get_field_loading_state()
	return scene != null and requested(scene.scene_id) and SceneRouter.get_current_field_id() == scene.scene_id and field.get_tree().current_scene == field and loading.get("complete") == true and loading.get("failed") == false and not LoadingManager._transition_active and not LoadingManager._external_active and is_instance_valid(player) and player.is_inside_tree() and player.is_visible_in_tree()

func _guard_session() -> Dictionary:
	if _session.is_empty() or not _owned(): return _fail("CULTURE_X_STALE_FIELD_SESSION")
	var field: Variant = _field()
	var scene: SceneScript = field.get("_current_scene")
	var player: Node2D = field.get("_player")
	var npc: NPCNode = _session.npc_ref.get_ref()
	if field.get_instance_id() != _session.field_id or scene.get_instance_id() != _session.scene_id or player.get_instance_id() != _session.player_id or not _live_actor(field, npc) or npc.get_instance_id() != _session.npc_id or _actor(field, npc.npc_id) != npc: return _fail("CULTURE_X_FIELD_SCENE_ACTOR_IDENTITY_CHANGED")
	if player.global_position.distance_to(npc.global_position) > 118.0: return _fail("CULTURE_X_PLAYER_TOO_FAR")
	if readiness().get("ok") != true: return _fail("CULTURE_X_CURRENT_SOURCE_CHANGED")
	return {"ok": true, "field": field, "scene": scene, "npc": npc, "player": player}

func handles(npc_id: String) -> bool:
	if not _owned(): return false
	var npc := _actor(_field(), npc_id)
	return npc != null and npc.has_meta("culture_x_primary")

func _node(script: DialogScript, text: String, speaker: String, suffix: String) -> DialogNode:
	var node := DialogNode.new()
	node.node_id = StringName("x_%d_%s" % [script.nodes.size(), suffix])
	node.speaker = speaker; node.text = text; node.voice_emotion = "normal"; node.on_end = "end"
	script.nodes.append(node)
	return node

func _terminal(script: DialogScript, text: String, speaker: String, event: Dictionary) -> String:
	var node := _node(script, text, speaker, "terminal")
	if not event.is_empty(): _session.actions[String(node.node_id)] = {"node": node, "event": event.duplicate(true)}
	return String(node.node_id)

func _authored(script: DialogScript, path: String, event: Dictionary) -> String:
	var authored := ResourceLoader.load(path) as DialogScript
	if authored == null or authored.nodes.is_empty(): return ""
	var first := ""; var previous: DialogNode
	for original: DialogNode in authored.nodes:
		var node := _node(script, original.text, original.speaker, "authored")
		node.voice_emotion = original.voice_emotion; node.portrait_path = original.portrait_path
		if first.is_empty(): first = String(node.node_id)
		if previous != null: previous.on_end = "next:" + String(node.node_id)
		previous = node
	if not event.is_empty(): _session.actions[String(previous.node_id)] = {"node": previous, "event": event.duplicate(true)}
	return first

func _topic(script: DialogScript, q: Dictionary, text: Dictionary, scene_id: String, npc: NPCNode, back: String) -> String:
	var saved := read_state(q.id, GameState.flags, QuestManager.states)
	if saved.get("ok") != true: return _terminal(script, "这件事的记录暂时无法核对，请先保留现状。", npc.npc_name, {})
	var state: Dictionary = saved.state
	_session.states[q.id] = state.duplicate(true)
	var base_event: Dictionary = {"qid": q.id}
	if state.status == "not_started":
		var issuer: Dictionary = ISSUERS[q.id]
		var offer := _node(script, text.phase_lines.not_started, npc.npc_name, "offer")
		if issuer.scene_id == scene_id and issuer.npc_id == npc.npc_id:
			var accept := base_event.duplicate(); accept.type = "accept"
			var decline := base_event.duplicate(); decline.type = "decline"
			offer.choices.assign([{"text": text.accept_choice, "next": _terminal(script, String(_session.common.accept_confirmation), npc.npc_name, accept)}, {"text": "暂时不接", "next": _terminal(script, text.decline_reply, npc.npc_name, decline)}, {"text": "返回", "next": back}])
		else:
			offer.text = String(_session.common.non_issuer_not_started)
			offer.choices.assign([{"text": "返回", "next": back}])
		return String(offer.node_id)
	if state.status == "reported":
		var personal_after: bool = npc.npc_id == "district_life_yamen_petitioner" if q.id == "q_ch4_side_08_qiangxiang_receipt" else (q.reporter.scene_id == scene_id and q.reporter.npc_id == npc.npc_id)
		var after: String = String(text.after_reply) if personal_after else String(text.after_other_actor)
		return _terminal(script, after, npc.npc_name, {})
	var line: String = String(text.phase_lines.get(state.status, text.phase_lines.active))
	var page := _node(script, line, npc.npc_name, "topic")
	var options: Array[Dictionary] = []
	if state.status == "active":
		for i: int in q.clues.size():
			var clue: Dictionary = q.clues[i]
			if clue.scene_id != scene_id or clue.npc_id != npc.npc_id: continue
			var event: Dictionary = {}
			if clue.id not in state.clues: event = {"qid": q.id, "type": "discover", "clue_id": clue.id, "scene_id": scene_id, "npc_id": npc.npc_id}
			options.append({"text": ("复看：" if clue.id in state.clues else "核对：") + clue.label, "next": _authored(script, q.dialog_paths["clue_%d" % (i + 1)], event)})
		if state.clues.size() == 3 and SOLVERS[q.id].scene_id == scene_id and SOLVERS[q.id].npc_id == npc.npc_id:
			var solve := _node(script, text.phase_lines.ready_to_solve, npc.npc_name, "solve")
			for choice: Dictionary in q.choices:
				var event: Dictionary = {"qid": q.id, "type": "solve", "choice_id": choice.id}
				solve.choices.append({"text": String(text.choice_labels[choice.id]), "next": _terminal(script, String(_session.common.solve_confirmation), npc.npc_name, event)})
			solve.choices.append({"text": "返回", "next": String(page.node_id)})
			options.append({"text": "说说我的判断", "next": String(solve.node_id)})
	elif state.status == "solved" and q.id == LETTER:
		if scene_id == DOCKS and npc.npc_id == BOOKING:
			options.append({"text": "请按原约由本人亲领", "next": _terminal(script, "请先核对本人、原条与未拆外封，交接完成后再确认。", npc.npc_name, {"qid": q.id, "type": "pickup"})})
		elif scene_id == DOCKS and npc.npc_id == BUYER:
			page.text = "我按约亲自来领。请和原记货伙计一起核对，别代我接信。"
	elif q.reporter.scene_id == scene_id and q.reporter.npc_id == npc.npc_id and (state.status == "solved" or (q.id == LETTER and state.status == "collected")):
		options.append({"text": text.report_choice, "next": _terminal(script, String(_session.common.report_confirmation), npc.npc_name, {"qid": q.id, "type": "report", "scene_id": scene_id, "npc_id": npc.npc_id})})
	options.append({"text": "返回", "next": back})
	page.choices.assign(options)
	return String(page.node_id)

func open(npc_id: String) -> Dictionary:
	if not handles(npc_id) or DialogPlayer.is_playing(): return _fail("CULTURE_X_CANNOT_OPEN_SESSION")
	abort("replaced_session")
	var field: Variant = _field()
	var scene: SceneScript = field.get("_current_scene")
	var player: Node2D = field.get("_player")
	var npc := _actor(field, npc_id)
	if not _live_actor(field, npc) or player.global_position.distance_to(npc.global_position) > 118.0: return _fail("CULTURE_X_PLAYER_TOO_FAR")
	if npc.get_meta("ap_quarter_daily_exact_identity",false)==true:
		var primary: Dictionary=npc.get_meta("culture_x_primary",{})
		if primary.get("dialog_id","")!="" or primary.get("interaction_action","")!="" or npc.interaction_action!="culture_x_menu": return _fail("AP_QUARTER_DAILY_PRIMARY_CHANGED")
		var daily: Dictionary=AP_PEOPLE.build_daily_menu(scene.scene_id,npc.npc_id,npc.npc_name)
		if daily.get("ok")!=true: return daily
		daily.npc=npc
		return daily
	if npc.get_meta("ap_daily_exact_identity",false)==true:
		var primary: Dictionary=npc.get_meta("culture_x_primary",{})
		if primary.get("dialog_id","")!="" or primary.get("interaction_action","")!="" or npc.interaction_action!="culture_x_menu": return _fail("AP_DAILY_PRIMARY_CHANGED")
		var daily: Dictionary=AP_NPC.build_daily_menu(scene.scene_id,npc.npc_id,npc.npc_name)
		if daily.get("ok")!=true: return daily
		daily.npc=npc
		return daily
	var ready := readiness()
	if ready.get("ok") != true: return ready
	_serial += 1
	var script := DialogScript.new()
	script.dialog_id = StringName("luoyang_culture_x_%d_%d" % [field.get_instance_id(), _serial])
	_session = {"serial": _serial, "script": script, "field_id": field.get_instance_id(), "scene_id": scene.get_instance_id(), "scene_name": String(scene.scene_id), "player_id": player.get_instance_id(), "npc_id": npc.get_instance_id(), "npc_ref": weakref(npc), "actions": {}, "states": {}, "selected": {}, "handoff_ready": false, "handoff_running": false}
	_session["common"] = ready.text.common
	var menu := _node(script, ready.text.common.greeting, npc.npc_name, "menu")
	var topics := _node(script, ready.text.common.culture_topics, npc.npc_name, "topics")
	var primary: Dictionary = npc.get_meta("culture_x_primary", {})
	if String(primary.get("dialog_id", "")) != "" or String(primary.get("interaction_action", "")) != "":
		var primary_terminal := _terminal(script, "我们接着原来的话题说。", npc.npc_name, {"type": "primary"})
		menu.choices.append({"text": ready.text.primary_option_labels.get(npc.npc_id, ready.text.common.original_primary), "next": primary_terminal})
	menu.choices.append({"text": ready.text.common.culture_topics, "next": String(topics.node_id)})
	menu.choices.append({"text": ready.text.common.leave, "next": "end"})
	for q: Dictionary in ready.quests.values():
		var matching := false
		for actor: Dictionary in q.actors:
			if actor.scene_id == String(scene.scene_id) and actor.npc_id == npc.npc_id: matching = true
		if q.id == LETTER and String(scene.scene_id) == DOCKS and npc.npc_id == BUYER: matching = true
		if matching: topics.choices.append({"text": ready.text_by_id[q.id].topic_label, "next": _topic(script, q, ready.text_by_id[q.id], String(scene.scene_id), npc, String(topics.node_id))})
	topics.choices.append({"text": ready.text.common.back, "next": String(menu.node_id)})
	script.entry_node_id = menu.node_id
	return {"ok": true, "script": script, "npc": npc}

func observe_node() -> void:
	if _session.is_empty() or DialogPlayer._current_script != _session.script: return
	var node: DialogNode = DialogPlayer._current_node
	if node == null or not _session.actions.has(String(node.node_id)): return
	var action: Dictionary = _session.actions[String(node.node_id)]
	if action.node != node or _guard_session().get("ok") != true: _session["rejected"] = "terminal_owner_or_distance"; return
	_session.selected = action.event.duplicate(true)
	if _session.selected.type == "pickup" and not _session.handoff_running and not _session.handoff_ready:
		_run_handoff(_session.serial)

func _pickup_people() -> Dictionary:
	var guard := _guard_session()
	if guard.get("ok") != true: return guard
	if String(guard.scene.scene_id) != DOCKS or guard.npc.npc_id != BOOKING: return _fail("CULTURE_X_PICKUP_ORIGINAL_CLERK_REQUIRED")
	var buyer := _actor(guard.field, BUYER)
	var clerk := _actor(guard.field, BOOKING)
	if not _live_actor(guard.field, buyer) or not _live_actor(guard.field, clerk) or clerk != guard.npc or not buyer.get_meta("culture_x_actual_recipient", false): return _fail("CULTURE_X_PERSONAL_RECIPIENT_NOT_PRESENT")
	if buyer.global_position.distance_to(clerk.global_position) > 140.0 or guard.player.global_position.distance_to(buyer.global_position) > 118.0: return _fail("CULTURE_X_PICKUP_PEOPLE_TOO_FAR")
	var city: Variant = load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
	for person: Node2D in [buyer, clerk, guard.player]:
		var foot: Vector2 = guard.field.world_container.to_local(person.global_position)
		if not city.safe_body(StringName(DOCKS), foot) or not guard.field._district_position_safe(foot, true): return _fail("CULTURE_X_HANDOFF_NATIVE_CLEARANCE_REFUSED")
	# Check real current PhysicsSpace too, not a caller bool or only a C oracle.
	# Exclude only each holder's own body and the player; another NPC or scenery
	# overlapping either native body remains a refusal.
	for person: NPCNode in [buyer, clerk]:
		var body: StaticBody2D = person.get("_body_collider")
		var shape: CollisionShape2D = body.get_child(0) as CollisionShape2D
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = shape.shape; query.transform = shape.global_transform; query.collision_mask = 1
		query.exclude = [body.get_rid(), guard.player.get_rid()]
		if not guard.field.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty(): return _fail("CULTURE_X_HANDOFF_ACTUAL_PHYSICS_BLOCKED")
	return {"ok": true, "buyer": buyer, "clerk": clerk, "player": guard.player, "field": guard.field}

func _run_handoff(serial: int) -> void:
	var people := _pickup_people()
	if people.get("ok") != true: _session["rejected"] = people.error; return
	_session.handoff_running = true
	var ready := readiness()
	var texture := ResourceLoader.load(ready.contract.pickup.letter_texture) as Texture2D
	if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0: _session["rejected"] = "letter_texture_unavailable"; return
	_letter_sprite = Sprite2D.new(); _letter_sprite.name = "CultureSealedLetter"
	_letter_sprite.texture = texture; _letter_sprite.scale = Vector2.ONE * (34.0 / float(texture.get_width()))
	people.clerk.add_child(_letter_sprite); _letter_sprite.position = Vector2(-24, -72); _letter_sprite.z_index = 20
	people.clerk.set_meta("culture_x_letter_holder", _letter_sprite.get_instance_id())
	var letter_id := _letter_sprite.get_instance_id()
	_handoff_tween = people.field.create_tween()
	_handoff_tween.tween_property(_letter_sprite, "global_position", people.buyer.global_position + Vector2(20, -72), 0.45)
	_handoff_tween.finished.connect(_on_handoff_finished.bind(serial, weakref(_letter_sprite), letter_id), CONNECT_ONE_SHOT)

func _discard_owned_letter(letter: Sprite2D, letter_id: int) -> void:
	if not is_instance_valid(letter) or letter.get_instance_id() != letter_id: return
	var holder: Node = letter.get_parent()
	if is_instance_valid(holder) and holder.get_meta("culture_x_letter_holder", 0) == letter_id: holder.remove_meta("culture_x_letter_holder")
	letter.queue_free()

func _on_handoff_finished(serial: int, letter_ref: WeakRef, letter_id: int) -> void:
	var letter: Sprite2D = letter_ref.get_ref() as Sprite2D
	# A stale tween owns only its old letter. It must never abort a replacement
	# conversation, kill its tween, or clear the replacement's held object.
	if _session.is_empty() or _session.serial != serial or DialogPlayer._current_script != _session.script:
		_discard_owned_letter(letter, letter_id)
		return
	var people := _pickup_people()
	if people.get("ok") != true or not is_instance_valid(letter) or letter != _letter_sprite or letter.get_instance_id() != letter_id:
		_session["rejected"] = "handoff_people_or_letter_lost"
		_discard_owned_letter(letter, letter_id)
		return
	letter.reparent(people.buyer, true)
	people.clerk.remove_meta("culture_x_letter_holder"); people.buyer.set_meta("culture_x_letter_holder", letter_id)
	_session.handoff_ready = true; _session.handoff_running = false
	_session["handoff_letter_id"] = letter_id
	_session["handoff_recipient_id"] = people.buyer.get_instance_id()

func _feedback(text: String, speaker: String) -> DialogScript:
	var script := DialogScript.new()
	script.dialog_id = StringName("culture_x_feedback_%d_%d" % [_field().get_instance_id(), _serial])
	var node := _node(script, text, speaker, "feedback")
	script.entry_node_id = node.node_id
	_feedback_id = String(script.dialog_id)
	return script

func _pickup_feedback(sequence: Array) -> DialogScript:
	var script := DialogScript.new()
	script.dialog_id = StringName("culture_x_feedback_%d_%d" % [_field().get_instance_id(), _serial])
	var previous: DialogNode
	for line: Dictionary in sequence:
		var node := _node(script, String(line.text), String(line.speaker), "handoff_feedback")
		if previous == null: script.entry_node_id = node.node_id
		else: previous.on_end = "next:" + String(node.node_id)
		previous = node
	_feedback_id = String(script.dialog_id)
	return script

func finish(dialog_id: StringName) -> Dictionary:
	if _session.is_empty():
		if String(dialog_id) == _feedback_id:
			_feedback_id = ""; _clear_letter()
		return {"ok": true, "matched": false}
	if String(_session.script.dialog_id) != String(dialog_id) or DialogPlayer.is_playing() or DialogPlayer._current_script != null:
		var stale := _fail("CULTURE_X_NOT_NORMAL_SESSION_END")
		stale["ignore_stale_dialog_end"] = true
		return stale
	var guard := _guard_session()
	if guard.get("ok") != true: abort(guard.error); return guard
	if _session.get("rejected", "") != "":
		var error: String = _session.rejected
		abort(error)
		return _fail(error)
	if _session.selected.is_empty(): abort("closed_without_selection"); return {"ok": true, "matched": true, "committed": false}
	var selected: Dictionary = _session.selected.duplicate(true)
	if selected.type == "primary":
		var primary: Dictionary = guard.npc.get_meta("culture_x_primary", {}).duplicate(true)
		_session.clear()
		return {"ok": true, "matched": true, "committed": false, "primary": primary, "npc_id": guard.npc.npc_id}
	var qid: String = selected.qid
	var current := read_state(qid, GameState.flags, QuestManager.states)
	if current.get("ok") != true or current.state != _session.states.get(qid): abort("progress_changed_during_conversation"); return _fail("CULTURE_X_STALE_PROGRESS_SESSION")
	var ready := readiness()
	var row: Dictionary = ready.quests[qid]
	if selected.type == "accept" or selected.type == "decline":
		if String(guard.scene.scene_id) != ISSUERS[qid].scene_id or guard.npc.npc_id != ISSUERS[qid].npc_id: abort("wrong_issuer"); return _fail("CULTURE_X_WRONG_ISSUER")
	elif selected.type == "solve" or selected.type == "report":
		var authority: Dictionary = SOLVERS[qid] if selected.type == "solve" else row.reporter
		if String(guard.scene.scene_id) != authority.scene_id or guard.npc.npc_id != authority.npc_id:
			abort("wrong_solver_or_reporter")
			return _fail("CULTURE_X_WRONG_SOLVER_OR_REPORTER")
	# Build the reducer's public schema instead of forwarding the adapter's
	# private qid / metadata. Dot-written Dictionary keys may be StringName;
	# the frozen reducer deliberately accepts only exact String-key payloads.
	var event: Dictionary = {"type": String(selected.type)}
	if selected.type == "discover":
		if selected.scene_id != String(guard.scene.scene_id) or selected.npc_id != guard.npc.npc_id: abort("wrong_witness"); return _fail("CULTURE_X_WRONG_WITNESS")
		event = {"type": "discover", "clue_id": String(selected.clue_id), "scene_id": String(selected.scene_id), "npc_id": String(selected.npc_id)}
	elif selected.type == "solve":
		event = {"type": "solve", "choice_id": String(selected.choice_id)}
	elif selected.type == "report":
		event = {"type": "report", "scene_id": String(selected.scene_id), "npc_id": String(selected.npc_id)}
	if selected.type == "pickup":
		var people := _pickup_people()
		if people.get("ok") != true or not _session.handoff_ready or not is_instance_valid(_letter_sprite) or not _letter_sprite.is_visible_in_tree() or _letter_sprite.get_instance_id() != _session.get("handoff_letter_id", 0) or _letter_sprite.get_parent() != people.buyer or people.buyer.get_instance_id() != _session.get("handoff_recipient_id", 0) or people.buyer.get_meta("culture_x_letter_holder", 0) != _letter_sprite.get_instance_id(): abort("personal_handoff_not_finished"); return _fail("CULTURE_X_REAL_PERSONAL_HANDOFF_REQUIRED")
		event = {"type": "pickup", "scene_id": DOCKS, "npc_id": BOOKING, "recipient_npc_id": BUYER, "personal_pickup_confirmed": true}
	var next := W.transition(qid, current.state, event)
	if next.get("ok") != true: abort("reducer_refused"); return next
	var accepted: bool = next.get("accepted", false)
	if accepted:
		if selected.type == "accept" and not QuestManager.accept(StringName(qid)): abort("qm_accept_refused"); return _fail("CULTURE_X_QM_ACCEPT_REFUSED")
		if selected.type == "report" and not QuestManager.complete(StringName(qid)): abort("qm_report_refused"); return _fail("CULTURE_X_QM_REPORT_REFUSED")
		# Structured durable data and boolean change notification are separate:
		# existing global listeners call bool(value), unsafe for Dictionary/String.
		GameState.flags[state_key(qid)] = JSON.stringify(next.state)
		GameState.set_flag(CHANGED_FLAG, true)
	var text: Dictionary = ready.text_by_id[qid]
	var feedback := "记录已核对。"
	match selected.type:
		"accept": feedback = text.phase_lines.active
		"decline": feedback = text.decline_reply
		"discover": feedback = String(text.clue_log_labels[selected.clue_id])
		"solve": feedback = String(text.phase_lines.solved) if accepted else String(text.wrong_feedback[selected.choice_id])
		"pickup": feedback = String(text.pickup_sequence[0].text) + "\n" + String(text.pickup_sequence[1].text)
		"report": feedback = String(text.report_reply)
	_last_receipt = {"ok": true, "qid": qid, "event": selected.type, "accepted": accepted, "state": next.state.duplicate(true), "field_id": guard.field.get_instance_id(), "scene_id": String(guard.scene.scene_id), "npc_id": guard.npc.npc_id, "npc_instance": guard.npc.get_instance_id(), "player_distance": guard.player.global_position.distance_to(guard.npc.global_position), "normal_dialog_end": true, "sealed_letter_node": _letter_sprite.get_instance_id() if is_instance_valid(_letter_sprite) else 0, "actual_handoff": selected.type == "pickup" and accepted, "numeric_reward": 0}
	_session.clear()
	var feedback_script: DialogScript = _pickup_feedback(text.pickup_sequence) if selected.type == "pickup" and accepted else _feedback(feedback, guard.npc.npc_name)
	return {"ok": true, "matched": true, "committed": accepted, "feedback": feedback_script}

func _clear_letter() -> void:
	if is_instance_valid(_handoff_tween): _handoff_tween.kill()
	_handoff_tween = null
	if is_instance_valid(_letter_sprite):
		var holder: Node = _letter_sprite.get_parent()
		if is_instance_valid(holder): holder.remove_meta("culture_x_letter_holder")
		_letter_sprite.queue_free()
	_letter_sprite = null

func abort(reason: String) -> void:
	if not _session.is_empty(): _last_receipt = {"ok": false, "error": reason, "committed": false}
	_session.clear(); _clear_letter()

func debug_state() -> Dictionary:
	var result: Dictionary = {"enabled": enabled(), "session_active": not _session.is_empty(), "last_receipt": _last_receipt.duplicate(true), "feedback_id": _feedback_id}
	if not _session.is_empty():
		result["session"] = {"serial": _session.serial, "dialog_id": String(_session.script.dialog_id), "field_id": _session.field_id, "scene_name": _session.scene_name, "npc_instance": _session.npc_id, "selected": _session.selected.duplicate(true), "handoff_ready": _session.handoff_ready, "handoff_running": _session.handoff_running}
	return result
