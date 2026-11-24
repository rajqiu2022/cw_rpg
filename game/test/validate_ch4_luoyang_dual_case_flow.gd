extends SceneTree

const REQUIRED_EVIDENCE: Array[StringName] = [
	&"ev_ch4_forged_death_time",
	&"ev_ch4_recent_compound_powder",
	&"ev_ch4_canal_original_manifest",
	&"ev_ch4_courier_complete_fragment",
	&"ev_ch4_forgery_workshop",
	&"ev_ch4_eighteen_year_roster",
]
const REQUIRED_TESTIMONIES: Array[StringName] = [
	&"ts_ch4_zhao_autopsy",
	&"ts_ch4_canal_witness_night_transfer",
	&"ts_ch4_captured_courier_orders",
	&"ts_ch4_fake_leader_partial_confession",
]

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_definitions()
	_validate_medical_verification()
	_validate_dual_case_branch()
	_validate_temple_convergence()

	for failure: String in _failures:
		push_error("[Chapter4LuoyangDualCase] %s" % failure)
	print("[Chapter4LuoyangDualCase] evidence=%d testimonies=%d branches=2 failed=%d" % [
		REQUIRED_EVIDENCE.size(), REQUIRED_TESTIMONIES.size(), _failures.size(),
	])
	quit(1 if not _failures.is_empty() else 0)


func _validate_definitions() -> void:
	for evidence_id: StringName in REQUIRED_EVIDENCE:
		var path: String = "res://data/investigation/evidence/%s.tres" % String(evidence_id)
		var definition: Resource = ResourceLoader.load(path)
		_expect(definition is EvidenceDef, "missing evidence definition: %s" % evidence_id)
		if definition is EvidenceDef:
			_expect((definition as EvidenceDef).chapter == 4, "evidence has wrong chapter: %s" % evidence_id)
	for testimony_id: StringName in REQUIRED_TESTIMONIES:
		var path: String = "res://data/investigation/testimonies/%s.tres" % String(testimony_id)
		var definition: Resource = ResourceLoader.load(path)
		_expect(definition is TestimonyDef, "missing testimony definition: %s" % testimony_id)
		if definition is TestimonyDef:
			_expect((definition as TestimonyDef).chapter == 4, "testimony has wrong chapter: %s" % testimony_id)


func _validate_medical_verification() -> void:
	var dialog: DialogScript = load("res://data/dialogs/ch4_case_clue.tres") as DialogScript
	_expect(dialog != null, "case clue dialog does not load")
	if dialog == null:
		return
	var finding: DialogNode = dialog.find_node_by_id(&"start")
	var conclusion: DialogNode = dialog.find_node_by_id(&"b")
	_expect(finding != null and &"ev_ch4_forged_death_time" in finding.add_evidence, "case clue does not acquire forged death-time evidence")
	_expect(finding != null and &"ev_ch4_recent_compound_powder" in finding.add_evidence, "case clue does not acquire recent powder evidence")
	_expect(finding != null and &"ts_ch4_zhao_autopsy" in finding.add_testimonies, "case clue does not record Zhao testimony")
	_expect(conclusion != null and &"ev_ch4_forged_death_time" in conclusion.verify_evidence, "Zhao does not verify forged death-time evidence")
	_expect(conclusion != null and not conclusion.companion_trust_changes.is_empty(), "joint autopsy does not affect Zhao trust")
	_expect(conclusion != null and not conclusion.bond_events.is_empty(), "joint autopsy does not record a Zhao bond event")


func _validate_dual_case_branch() -> void:
	var dialog: DialogScript = load("res://data/dialogs/ch4_canal_result.tres") as DialogScript
	_expect(dialog != null, "canal result dialog does not load")
	if dialog == null:
		return
	var opening: DialogNode = dialog.find_node_by_id(&"start")
	_expect(opening != null and &"ev_ch4_canal_original_manifest" in opening.add_evidence, "canal result does not acquire original manifest")
	var choice_node: DialogNode = dialog.find_node_by_id(&"b")
	_expect(choice_node != null, "canal dual-case choice node is missing")
	if choice_node == null:
		return
	_expect(choice_node.choices.size() == 2, "canal decision must expose exactly two methods")
	var method_keys: Dictionary = {}
	var branch_payloads: Dictionary = {}
	for choice: Dictionary in choice_node.choices:
		var next_id: StringName = StringName(String(choice.get("next", "")))
		var branch_node: DialogNode = dialog.find_node_by_id(next_id)
		_expect(branch_node != null, "canal choice points to missing branch: %s" % next_id)
		if branch_node != null:
			_expect(branch_node.on_end == "next:finish", "canal branch does not rejoin finish: %s" % next_id)
		var methods: Variant = choice.get("method_flags", [])
		_expect(methods is Array and not (methods as Array).is_empty(), "canal choice has no persistent method flag")
		if methods is Array and not (methods as Array).is_empty():
			var method_entry: Variant = (methods as Array)[0]
			if method_entry is Dictionary:
				method_keys[String((method_entry as Dictionary).get("key", ""))] = true
		var trust: Variant = choice.get("companion_trust_changes", [])
		var bonds: Variant = choice.get("bond_events", [])
		var outcomes: Variant = choice.get("city_outcomes", [])
		_expect(trust is Array and not (trust as Array).is_empty(), "canal choice does not affect Zhao trust")
		_expect(bonds is Array and not (bonds as Array).is_empty(), "canal choice does not record a Zhao bond event")
		_expect(outcomes is Array and not (outcomes as Array).is_empty(), "canal choice does not persist a Luoyang outcome")
		branch_payloads[String(next_id)] = {
			"evidence": choice.get("add_evidence", []),
			"testimonies": choice.get("add_testimonies", []),
		}
	_expect(method_keys.has("ch4_rescue_witness_first"), "rescue-witness method flag is missing")
	_expect(method_keys.has("ch4_pursue_courier_first"), "pursue-courier method flag is missing")
	var rescue_payload: Dictionary = branch_payloads.get("rescue_first", {})
	var pursuit_payload: Dictionary = branch_payloads.get("pursue_first", {})
	_expect("ts_ch4_canal_witness_night_transfer" in rescue_payload.get("testimonies", []), "rescue route does not preserve living testimony")
	_expect("ev_ch4_courier_complete_fragment" in pursuit_payload.get("evidence", []), "pursuit route does not recover complete fragment")
	var finish: DialogNode = dialog.find_node_by_id(&"finish")
	_expect(finish != null and finish.on_end == "scene:ch4_s4_ancient_temple", "dual-case branches do not converge on ancient temple")
	_expect(finish != null and String(finish.complete_quest) == "q_ch4_main_03_canal_witness", "dual-case branches do not complete canal quest")


func _validate_temple_convergence() -> void:
	var dialog: DialogScript = load("res://data/dialogs/ch4_tunnel_result.tres") as DialogScript
	_expect(dialog != null, "tunnel result dialog does not load")
	if dialog == null:
		return
	var finding: DialogNode = dialog.find_node_by_id(&"start")
	var conclusion: DialogNode = dialog.find_node_by_id(&"b")
	_expect(finding != null and &"ev_ch4_forgery_workshop" in finding.add_evidence, "tunnel does not acquire forgery workshop evidence")
	_expect(finding != null and &"ev_ch4_eighteen_year_roster" in finding.add_evidence, "tunnel does not acquire eighteen-year roster")
	_expect(finding != null and &"ts_ch4_fake_leader_partial_confession" in finding.add_testimonies, "tunnel does not record partial confession")
	_expect(conclusion != null and &"ev_ch4_forgery_workshop" in conclusion.verify_evidence, "tunnel does not verify forgery workshop")
	_expect(conclusion != null and not conclusion.city_outcomes.is_empty(), "chapter ending does not persist Luoyang outcome")
	_expect(conclusion != null and not conclusion.bond_events.is_empty(), "chapter ending does not record Zhao truth-preservation event")
	_expect(conclusion != null and conclusion.on_end == "chapter_end:4", "chapter 4 does not reach chapter ending")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
