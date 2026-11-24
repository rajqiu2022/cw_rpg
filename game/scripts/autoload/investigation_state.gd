extends Node

## 调查、关系与城市结果的单一运行时状态源。
## 定义文件只描述内容；本节点只保存玩家在当前存档中的发现和选择。

signal state_changed

const EVIDENCE_DIR := "res://data/investigation/evidence/"
const TESTIMONY_DIR := "res://data/investigation/testimonies/"
const TRUST_MIN := -100
const TRUST_MAX := 100

var evidence_states: Dictionary = {}
var testimony_states: Dictionary = {}
var faction_trust: Dictionary = {}
var companion_trust: Dictionary = {}
var bond_events: Dictionary = {}
var city_outcomes: Dictionary = {}
var method_flags: Dictionary = {}

var _evidence_defs: Dictionary = {}
var _testimony_defs: Dictionary = {}


func load_evidence_def(evidence_id: StringName) -> EvidenceDef:
	if _evidence_defs.has(evidence_id):
		return _evidence_defs[evidence_id] as EvidenceDef
	var path: String = "%s%s.tres" % [EVIDENCE_DIR, String(evidence_id)]
	if not ResourceLoader.exists(path):
		push_warning("[InvestigationState] evidence definition missing: %s" % path)
		return null
	var resource: Resource = load(path)
	if resource is EvidenceDef:
		_evidence_defs[evidence_id] = resource
		return resource as EvidenceDef
	return null


func load_testimony_def(testimony_id: StringName) -> TestimonyDef:
	if _testimony_defs.has(testimony_id):
		return _testimony_defs[testimony_id] as TestimonyDef
	var path: String = "%s%s.tres" % [TESTIMONY_DIR, String(testimony_id)]
	if not ResourceLoader.exists(path):
		push_warning("[InvestigationState] testimony definition missing: %s" % path)
		return null
	var resource: Resource = load(path)
	if resource is TestimonyDef:
		_testimony_defs[testimony_id] = resource
		return resource as TestimonyDef
	return null


func acquire_evidence(evidence_id: StringName, source: StringName = &"") -> bool:
	if String(evidence_id).is_empty():
		return false
	if load_evidence_def(evidence_id) == null:
		return false
	var key: String = String(evidence_id)
	if evidence_states.has(key):
		return false
	evidence_states[key] = {
		"verified": false,
		"verifier": "",
		"source": String(source),
		"disclosed": false,
	}
	EventBus.evidence_acquired.emit(evidence_id)
	state_changed.emit()
	return true


func verify_evidence(evidence_id: StringName, verifier: StringName = &"") -> bool:
	if not has_evidence(evidence_id):
		return false
	var key: String = String(evidence_id)
	var state: Dictionary = evidence_states.get(key, {})
	if bool(state.get("verified", false)):
		return false
	state["verified"] = true
	state["verifier"] = String(verifier)
	evidence_states[key] = state
	EventBus.evidence_verified.emit(evidence_id)
	state_changed.emit()
	return true


func disclose_evidence(evidence_id: StringName) -> bool:
	if not has_evidence(evidence_id):
		return false
	var key: String = String(evidence_id)
	var state: Dictionary = evidence_states.get(key, {})
	if bool(state.get("disclosed", false)):
		return false
	state["disclosed"] = true
	evidence_states[key] = state
	state_changed.emit()
	return true


func has_evidence(evidence_id: StringName) -> bool:
	return evidence_states.has(String(evidence_id))


func is_evidence_verified(evidence_id: StringName) -> bool:
	var state: Dictionary = evidence_states.get(String(evidence_id), {})
	return bool(state.get("verified", false))


func hear_testimony(testimony_id: StringName) -> bool:
	if String(testimony_id).is_empty():
		return false
	var definition: TestimonyDef = load_testimony_def(testimony_id)
	if definition == null:
		return false
	var key: String = String(testimony_id)
	if testimony_states.has(key):
		return false
	testimony_states[key] = {
		"verified": false,
		"verifier": "",
		"credibility": definition.initial_credibility,
	}
	EventBus.testimony_heard.emit(testimony_id)
	state_changed.emit()
	return true


func verify_testimony(testimony_id: StringName, verifier: StringName = &"") -> bool:
	if not has_testimony(testimony_id):
		return false
	var key: String = String(testimony_id)
	var state: Dictionary = testimony_states.get(key, {})
	if bool(state.get("verified", false)):
		return false
	state["verified"] = true
	state["verifier"] = String(verifier)
	state["credibility"] = 100
	testimony_states[key] = state
	EventBus.testimony_verified.emit(testimony_id)
	state_changed.emit()
	return true


func has_testimony(testimony_id: StringName) -> bool:
	return testimony_states.has(String(testimony_id))


func adjust_faction_trust(faction_id: StringName, delta: int) -> int:
	var key: String = String(faction_id)
	var next_value: int = clampi(int(faction_trust.get(key, 0)) + delta, TRUST_MIN, TRUST_MAX)
	faction_trust[key] = next_value
	EventBus.faction_trust_changed.emit(faction_id, next_value)
	state_changed.emit()
	return next_value


func adjust_companion_trust(companion_id: StringName, delta: int) -> int:
	var key: String = String(companion_id)
	var next_value: int = clampi(int(companion_trust.get(key, 0)) + delta, TRUST_MIN, TRUST_MAX)
	companion_trust[key] = next_value
	EventBus.companion_trust_changed.emit(companion_id, next_value)
	state_changed.emit()
	return next_value


func add_bond_event(companion_id: StringName, event_id: StringName) -> bool:
	if String(companion_id).is_empty() or String(event_id).is_empty():
		return false
	var key: String = String(companion_id)
	var events: Array = bond_events.get(key, [])
	if String(event_id) in events:
		return false
	events.append(String(event_id))
	bond_events[key] = events
	EventBus.bond_event_added.emit(companion_id, event_id)
	state_changed.emit()
	return true


func has_bond_event(companion_id: StringName, event_id: StringName) -> bool:
	var events: Array = bond_events.get(String(companion_id), [])
	return String(event_id) in events


func get_relationship_epilogue_scores() -> Dictionary:
	## Relationship endings summarize long-term trust and shared events. A late
	## button may accept the strongest earned bond or choose independence, but
	## it must never select an unrelated romance from scratch.
	var result := {}
	for companion_id: String in ["yuewuheng", "zhao_siying", "qi_yunsheng"]:
		var trust := int(companion_trust.get(companion_id, 0))
		var events: Array = bond_events.get(companion_id, [])
		result[companion_id] = trust + events.size() * 4
	# Qi Yunsheng's route predates the generic relationship hooks. Preserve the
	# three concrete long-form story beats so old saves are scored fairly.
	if bool(GameState.flags.get("ch6_qiyun_letter_read", false)):
		result["qi_yunsheng"] = int(result["qi_yunsheng"]) + 3
	if bool(GameState.flags.get("ch7_qi_yunsheng_met", false)):
		result["qi_yunsheng"] = int(result["qi_yunsheng"]) + 3
	if bool(GameState.flags.get("ch7_qi_reform_testimony_heard", false)):
		result["qi_yunsheng"] = int(result["qi_yunsheng"]) + 4
	return result


func resolve_relationship_epilogue() -> StringName:
	var scores := get_relationship_epilogue_scores()
	var highest := -100000
	var winners: Array[String] = []
	for companion_id: String in scores:
		var score := int(scores[companion_id])
		if score > highest:
			highest = score
			winners = [companion_id]
		elif score == highest:
			winners.append(companion_id)
	# A tie or a weak relationship keeps the protagonist independent. This is
	# preferable to silently biasing one heroine when the history is ambiguous.
	if highest < 8 or winners.size() != 1:
		return &"independent"
	return StringName(winners[0])


func set_city_outcome(city_id: StringName, outcome_key: StringName, value: Variant) -> void:
	var city_key: String = String(city_id)
	var outcomes: Dictionary = city_outcomes.get(city_key, {})
	outcomes[String(outcome_key)] = value
	city_outcomes[city_key] = outcomes
	EventBus.city_outcome_changed.emit(city_id, outcome_key, value)
	state_changed.emit()


func get_city_outcome(city_id: StringName, outcome_key: StringName, default_value: Variant = null) -> Variant:
	var outcomes: Dictionary = city_outcomes.get(String(city_id), {})
	return outcomes.get(String(outcome_key), default_value)


func set_method_flag(flag_id: StringName, value: Variant = true) -> void:
	method_flags[String(flag_id)] = value
	EventBus.method_flag_changed.emit(flag_id, value)
	state_changed.emit()


func to_dict() -> Dictionary:
	return {
		"evidence": evidence_states.duplicate(true),
		"testimonies": testimony_states.duplicate(true),
		"faction_trust": faction_trust.duplicate(true),
		"companion_trust": companion_trust.duplicate(true),
		"bond_events": bond_events.duplicate(true),
		"city_outcomes": city_outcomes.duplicate(true),
		"method_flags": method_flags.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	evidence_states = _dictionary_value(data, "evidence")
	testimony_states = _dictionary_value(data, "testimonies")
	faction_trust = _dictionary_value(data, "faction_trust")
	companion_trust = _dictionary_value(data, "companion_trust")
	bond_events = _dictionary_value(data, "bond_events")
	city_outcomes = _dictionary_value(data, "city_outcomes")
	method_flags = _dictionary_value(data, "method_flags")
	state_changed.emit()


func reset_for_new_game() -> void:
	evidence_states.clear()
	testimony_states.clear()
	faction_trust.clear()
	companion_trust.clear()
	bond_events.clear()
	city_outcomes.clear()
	method_flags.clear()
	state_changed.emit()


func _dictionary_value(data: Dictionary, key: String) -> Dictionary:
	var value: Variant = data.get(key, {})
	return value.duplicate(true) if value is Dictionary else {}
