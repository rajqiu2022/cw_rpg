extends SceneTree

const REQUIRED_EVIDENCE: Array[StringName] = [
	&"ev_ch3_old_official_paper",
	&"ev_ch3_reversed_footprints",
	&"ev_ch3_reversed_moon_stitch",
	&"ev_ch3_mismatched_copper_button",
	&"ev_ch3_composite_technique_marks",
	&"ev_ch3_luoyang_cargo_mark",
]
const REQUIRED_TESTIMONIES: Array[StringName] = [
	&"ts_ch3_wudang_archive_revision",
	&"ts_ch3_huashan_two_edges",
	&"ts_ch3_gufeng_crate_witness",
	&"ts_ch3_lingyue_stitch_order",
	&"ts_ch3_mingwu_common_artisan",
	&"ts_ch3_wanderer_crosscheck",
]
const FACTION_BRANCHES: Array[Dictionary] = [
	{"id": "wudang", "access": "ch3_access_wudang_archive", "dialog": "ch3_wudang_complete", "testimony": "ts_ch3_wudang_archive_revision"},
	{"id": "huashan", "access": "ch3_access_huashan_wound_records", "dialog": "ch3_huashan_complete", "testimony": "ts_ch3_huashan_two_edges"},
	{"id": "gufeng", "access": "ch3_access_gufeng_porters", "dialog": "ch3_gufeng_complete", "testimony": "ts_ch3_gufeng_crate_witness"},
	{"id": "lingyue", "access": "ch3_access_lingyue_relics", "dialog": "ch3_lingyue_complete", "testimony": "ts_ch3_lingyue_stitch_order"},
	{"id": "mingwu", "access": "ch3_access_mingwu_shadow_corridor", "dialog": "ch3_mingwu_complete", "testimony": "ts_ch3_mingwu_common_artisan"},
	{"id": "wanderer", "access": "ch3_access_wanderer_records", "dialog": "ch3_wanderer_complete", "testimony": "ts_ch3_wanderer_crosscheck"},
]

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_definitions()
	_validate_shared_opening_clue()
	_validate_faction_choices()
	_validate_faction_testimonies_rejoin()
	_validate_shared_investigation_tail()

	for failure: String in _failures:
		push_error("[Chapter3FactionInvestigation] %s" % failure)
	print("[Chapter3FactionInvestigation] factions=%d evidence=%d testimonies=%d failed=%d" % [
		FACTION_BRANCHES.size(), REQUIRED_EVIDENCE.size(), REQUIRED_TESTIMONIES.size(), _failures.size(),
	])
	quit(1 if not _failures.is_empty() else 0)


func _validate_definitions() -> void:
	for evidence_id: StringName in REQUIRED_EVIDENCE:
		var path: String = "res://data/investigation/evidence/%s.tres" % String(evidence_id)
		var definition: Resource = ResourceLoader.load(path)
		_expect(definition is EvidenceDef, "missing evidence definition: %s" % evidence_id)
		if definition is EvidenceDef:
			_expect((definition as EvidenceDef).chapter == 3, "evidence has wrong chapter: %s" % evidence_id)
	for testimony_id: StringName in REQUIRED_TESTIMONIES:
		var path: String = "res://data/investigation/testimonies/%s.tres" % String(testimony_id)
		var definition: Resource = ResourceLoader.load(path)
		_expect(definition is TestimonyDef, "missing testimony definition: %s" % testimony_id)
		if definition is TestimonyDef:
			_expect((definition as TestimonyDef).chapter == 3, "testimony has wrong chapter: %s" % testimony_id)


func _validate_shared_opening_clue() -> void:
	var dialog: DialogScript = load("res://data/dialogs/ch3_assembly_review.tres") as DialogScript
	_expect(dialog != null, "assembly review does not load")
	if dialog == null:
		return
	var node: DialogNode = dialog.find_node_by_id(&"end")
	_expect(node != null, "assembly review evidence node is missing")
	if node != null:
		_expect(&"ev_ch3_old_official_paper" in node.add_evidence, "assembly review does not grant the shared official-paper clue")
		_expect(String(node.complete_quest) == "q_ch3_main_00_assembly_clues", "assembly review does not complete the shared clue stage")


func _validate_faction_choices() -> void:
	var dialog: DialogScript = load("res://data/dialogs/ch3_faction_choice.tres") as DialogScript
	_expect(dialog != null, "faction choice dialog does not load")
	if dialog == null:
		return
	var start: DialogNode = dialog.find_node_by_id(&"start")
	_expect(start != null, "faction choice start node is missing")
	if start == null:
		return
	_expect(start.choices.size() == FACTION_BRANCHES.size(), "road choice must expose five factions plus no-faction")
	for branch: Dictionary in FACTION_BRANCHES:
		var faction_id: String = String(branch.get("id", ""))
		var node: DialogNode = dialog.find_node_by_id(StringName(faction_id))
		_expect(node != null, "missing faction branch node: %s" % faction_id)
		if node == null:
			continue
		_expect(node.on_end == "join_faction:%s" % faction_id, "faction branch does not join expected faction: %s" % faction_id)
		if faction_id != "wanderer":
			_expect(_has_trust_change(node.faction_trust_changes, faction_id), "faction branch has no positive trust change: %s" % faction_id)
		_expect(_has_method_flag(node.method_flags, String(branch.get("access", ""))), "faction branch has no persistent investigation access: %s" % faction_id)


func _validate_faction_testimonies_rejoin() -> void:
	for branch: Dictionary in FACTION_BRANCHES:
		var dialog_id: String = String(branch.get("dialog", ""))
		var path: String = "res://data/dialogs/%s.tres" % dialog_id
		var dialog: DialogScript = load(path) as DialogScript
		_expect(dialog != null, "faction completion dialog does not load: %s" % dialog_id)
		if dialog == null:
			continue
		var heard: bool = false
		var rejoins_assembly: bool = false
		var marks_joined: bool = false
		for node: DialogNode in dialog.nodes:
			if StringName(String(branch.get("testimony", ""))) in node.add_testimonies:
				heard = true
			if node.on_end == "scene:ch3_s1_wulin_assembly":
				rejoins_assembly = true
			for flag_entry: Dictionary in node.set_flags:
				if String(flag_entry.get("key", "")) == "joined_faction" and bool(flag_entry.get("value", false)):
					marks_joined = true
		_expect(heard, "faction completion records no biased testimony: %s" % dialog_id)
		_expect(rejoins_assembly, "faction completion does not rejoin shared assembly flow: %s" % dialog_id)
		_expect(marks_joined, "faction completion does not unlock shared dispatch: %s" % dialog_id)


func _validate_shared_investigation_tail() -> void:
	var training: DialogScript = load("res://data/dialogs/ch3_training_result.tres") as DialogScript
	_expect(training != null, "training result does not load")
	if training != null:
		var opening: DialogNode = training.find_node_by_id(&"start")
		var conclusion: DialogNode = training.find_node_by_id(&"b")
		_expect(opening != null and &"ev_ch3_composite_technique_marks" in opening.add_evidence, "training does not acquire composite-technique evidence")
		_expect(conclusion != null and &"ev_ch3_composite_technique_marks" in conclusion.verify_evidence, "training does not verify composite-technique evidence")

	var tomb: DialogScript = load("res://data/dialogs/ch3_tomb_result.tres") as DialogScript
	_expect(tomb != null, "tomb result does not load")
	if tomb != null:
		var opening: DialogNode = tomb.find_node_by_id(&"start")
		var conclusion: DialogNode = tomb.find_node_by_id(&"b")
		_expect(opening != null and &"ev_ch3_luoyang_cargo_mark" in opening.add_evidence, "tomb does not acquire Luoyang cargo evidence")
		_expect(conclusion != null and &"ev_ch3_old_official_paper" in conclusion.verify_evidence, "tomb does not verify the shared official-paper clue")
		_expect(conclusion != null and &"ev_ch3_luoyang_cargo_mark" in conclusion.verify_evidence, "tomb does not verify Luoyang cargo evidence")


func _has_trust_change(entries: Array[Dictionary], faction_id: String) -> bool:
	for entry: Dictionary in entries:
		if String(entry.get("id", "")) == faction_id and int(entry.get("delta", 0)) > 0:
			return true
	return false


func _has_method_flag(entries: Array[Dictionary], flag_id: String) -> bool:
	for entry: Dictionary in entries:
		if String(entry.get("key", "")) == flag_id and bool(entry.get("value", false)):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
