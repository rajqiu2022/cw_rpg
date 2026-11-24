extends SceneTree

const REQUIRED_EVIDENCE: Array[StringName] = [
	&"ev_ch2_missing_notices",
	&"ev_ch2_split_tracks",
	&"ev_ch2_fresh_lieyun_token",
	&"ev_ch2_courier_fragment",
	&"ev_ch2_forgery_ledger",
]
const REQUIRED_TESTIMONIES: Array[StringName] = [
	&"ts_ch2_hawker_north_route",
	&"ts_ch2_apothecary_bound_buyer",
	&"ts_ch2_gatekeeper_charcoal_cart",
	&"ts_ch2_yue_attackers_method",
	&"ts_ch2_rescued_villager",
]

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_definitions()
	_validate_market_testimonies()
	_validate_method_branch()
	_validate_lingyue_relationship_event()

	for failure: String in _failures:
		push_error("[Chapter2Investigation] %s" % failure)
	print("[Chapter2Investigation] evidence=%d testimonies=%d failed=%d" % [
		REQUIRED_EVIDENCE.size(), REQUIRED_TESTIMONIES.size(), _failures.size(),
	])
	quit(1 if not _failures.is_empty() else 0)


func _validate_definitions() -> void:
	for evidence_id: StringName in REQUIRED_EVIDENCE:
		var path: String = "res://data/investigation/evidence/%s.tres" % String(evidence_id)
		var definition: Resource = ResourceLoader.load(path)
		_expect(definition is EvidenceDef, "missing evidence definition: %s" % evidence_id)
		if definition is EvidenceDef:
			_expect((definition as EvidenceDef).chapter == 2, "evidence has wrong chapter: %s" % evidence_id)
	for testimony_id: StringName in REQUIRED_TESTIMONIES:
		var path: String = "res://data/investigation/testimonies/%s.tres" % String(testimony_id)
		var definition: Resource = ResourceLoader.load(path)
		_expect(definition is TestimonyDef, "missing testimony definition: %s" % testimony_id)
		if definition is TestimonyDef:
			_expect((definition as TestimonyDef).chapter == 2, "testimony has wrong chapter: %s" % testimony_id)


func _validate_market_testimonies() -> void:
	var heard: Dictionary = {}
	for dialog_id: String in ["ch2_market_hawker", "ch2_market_apothecary", "ch2_market_gatekeeper_followup"]:
		var dialog: DialogScript = load("res://data/dialogs/%s.tres" % dialog_id) as DialogScript
		_expect(dialog != null, "market testimony dialog does not load: %s" % dialog_id)
		if dialog == null:
			continue
		for node: DialogNode in dialog.nodes:
			_expect(String(node.complete_quest) == "", "%s must not explicitly complete the investigation" % dialog_id)
			for testimony_id: StringName in node.add_testimonies:
				heard[String(testimony_id)] = true
	for required_id: String in [
		"ts_ch2_hawker_north_route",
		"ts_ch2_apothecary_bound_buyer",
		"ts_ch2_gatekeeper_charcoal_cart",
	]:
		_expect(heard.has(required_id), "market does not record testimony: %s" % required_id)
	var scene := load("res://data/scenes/ch2_s1_zhuwei_market.tres") as SceneScript
	_expect(scene != null and scene.on_enter_dialog != null, "chapter 2 market must play its intro on entry")
	if scene != null:
		var npc_ids: Dictionary = {}
		for raw_npc: Variant in scene.npcs:
			var npc: Dictionary = raw_npc
			npc_ids[String(npc.get("npc_id", ""))] = true
		for required_npc: String in ["zhuwei_gatekeeper_ch2", "zhuwei_hawker_ch2", "zhuwei_apothecary_ch2"]:
			_expect(npc_ids.has(required_npc), "market has no visible investigation NPC: %s" % required_npc)


func _validate_method_branch() -> void:
	var dialog: DialogScript = load("res://data/dialogs/ch2_rescue_victory.tres") as DialogScript
	_expect(dialog != null, "rescue victory dialog does not load")
	if dialog == null:
		return
	var choice_node: DialogNode = dialog.find_node_by_id(&"n4")
	_expect(choice_node != null, "rescue victory choice node is missing")
	if choice_node == null:
		return
	_expect(choice_node.choices.size() == 2, "rescue victory must offer exactly two method choices")
	var method_keys: Dictionary = {}
	for choice: Dictionary in choice_node.choices:
		var next_id: StringName = StringName(String(choice.get("next", "")))
		var branch_node: DialogNode = dialog.find_node_by_id(next_id)
		_expect(branch_node != null, "method choice points to missing branch: %s" % next_id)
		if branch_node != null:
			_expect(branch_node.on_end == "next:finish", "method branch must rejoin finish: %s" % next_id)
		var flags: Variant = choice.get("method_flags", [])
		_expect(flags is Array and not (flags as Array).is_empty(), "method choice has no persistent method flag")
		if flags is Array and not (flags as Array).is_empty():
			var first_flag: Variant = (flags as Array)[0]
			if first_flag is Dictionary:
				method_keys[String((first_flag as Dictionary).get("key", ""))] = true
		var trust_changes: Variant = choice.get("companion_trust_changes", [])
		_expect(trust_changes is Array and not (trust_changes as Array).is_empty(), "method choice does not affect Yue trust")
		var bond_events: Variant = choice.get("bond_events", [])
		_expect(bond_events is Array and not (bond_events as Array).is_empty(), "method choice does not record a Yue bond event")
		var outcomes: Variant = choice.get("city_outcomes", [])
		_expect(outcomes is Array and not (outcomes as Array).is_empty(), "method choice does not persist a Zhuwei outcome")
	_expect(method_keys.has("ch2_rescue_first"), "rescue-first method flag is missing")
	_expect(method_keys.has("ch2_pursue_courier_first"), "courier-first method flag is missing")
	var finish: DialogNode = dialog.find_node_by_id(&"finish")
	var spoils: DialogNode = dialog.find_node_by_id(&"spoils")
	_expect(finish != null and finish.on_end == "next:spoils", "method branches do not rejoin the reviewed spoils node")
	_expect(spoils != null and String(spoils.complete_quest) == "q_ch2_main_02_rescue_yue", "reviewed spoils node does not complete the rescue quest")
	_expect(spoils != null and _sets_flag(spoils, "ch2_rescue_complete"), "reviewed spoils node does not persist the rescue completion flag")


func _validate_lingyue_relationship_event() -> void:
	var dialog: DialogScript = load("res://data/dialogs/ch2_lingyue_arrival.tres") as DialogScript
	_expect(dialog != null, "Lingyue arrival dialog does not load")
	if dialog == null:
		return
	var ending: DialogNode = dialog.find_node_by_id(&"n3")
	_expect(ending != null, "Lingyue arrival ending node is missing")
	if ending == null:
		return
	_expect(not ending.companion_trust_changes.is_empty(), "chapter 2 ending does not change Yue trust")
	_expect(not ending.bond_events.is_empty(), "chapter 2 ending does not record joint verification bond")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _sets_flag(node: DialogNode, key: String) -> bool:
	if node == null:
		return false
	for entry: Dictionary in node.set_flags:
		if String(entry.get("key", "")) == key and bool(entry.get("value", false)):
			return true
	return false
