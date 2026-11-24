extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var plan := load("res://data/chapters/chapter_7_content_plan.tres") as ChapterContentPlan
	var lieyun_outer := load("res://data/scenes/ch7_s3_lieyun_outpost_outer_ward.tres") as SceneScript
	var mingwu_outer := load("res://data/scenes/ch7_s4_mingwu_manor_outer_court.tres") as SceneScript
	var hall := load("res://data/scenes/ch7_s5_lieyun_assembly_hall.tres") as SceneScript
	var inner := load("res://data/scenes/ch7_s6_mingwu_inner_court.tres") as SceneScript
	var quest := load("res://data/quests/q_ch7_main_04_reform_and_witness.tres") as QuestDef
	_check(plan != null and plan.main_scene_ids.size() >= 6 and plan.main_quest_ids.size() >= 4, "chapter seven retains the six witness-route scenes and their four opening quests")
	_check(plan != null and plan.story_battle_groups.size() == 1, "witness batch does not add a purposeless second battle")
	_check(_portal_target(lieyun_outer.map_layout, "enter_lieyun_assembly_hall") == &"ch7_s5_lieyun_assembly_hall", "Lieyun outer ward opens the assembly hall")
	_check(_portal_gate(lieyun_outer.map_layout, "enter_lieyun_assembly_hall") == "ch7_inner_routes_opened", "Lieyun inner gate uses the shared witness-route flag")
	_check(_portal_target(mingwu_outer.map_layout, "enter_mingwu_inner_court") == &"ch7_s6_mingwu_inner_court", "Mingwu outer court opens the inner court")
	_check(_portal_gate(mingwu_outer.map_layout, "enter_mingwu_inner_court") == "ch7_inner_routes_opened", "Mingwu inner gate uses the shared witness-route flag")
	_check(_scene_contract_ok(hall, "bg_ch7_lieyun_assembly_hall_gameplay_v1.png"), "Lieyun assembly hall uses a formal reachable 1536x1024 background")
	_check(_scene_contract_ok(inner, "bg_ch7_mingwu_inner_court_gameplay_v1.png"), "Mingwu inner court uses a formal reachable 1536x1024 background")
	_check(_portal_target(hall.map_layout, "return_to_lieyun_outer_ward") == &"ch7_s3_lieyun_outpost_outer_ward", "assembly hall returns to the Lieyun outer ward")
	_check(_portal_target(inner.map_layout, "return_to_mingwu_outer_court") == &"ch7_s4_mingwu_manor_outer_court", "inner court returns to the Mingwu outer court")
	var portrait_path := "res://art/characters/portraits/portrait_qi_yunsheng_ch7_v1.png"
	var sprite_path := "res://art/characters/npc_qi_yunsheng_idle_down_4f_v1_runtime.png"
	_check(_image_has_alpha(portrait_path, Vector2i(1024,1536)), "Qi Yunsheng owns a canonical transparent dialogue portrait")
	_check(_image_has_alpha(sprite_path, Vector2i(640,160)), "Qi Yunsheng owns a keyed-and-processed four-frame Field idle")
	_check(_npc_uses_identity(hall, "ch7_qi_yunsheng", portrait_path, sprite_path), "assembly hall uses Qi Yunsheng's own portrait and Field identity")
	var meeting := load("res://data/dialogs/ch7_qi_yunsheng_meeting.tres") as DialogScript
	var admit := meeting.find_node_by_id(&"admit") if meeting != null else null
	var record := meeting.find_node_by_id(&"record") if meeting != null else null
	_check(admit != null and admit.text.contains("不能替我免责"), "Qi Yunsheng explicitly owns the cost of delaying disclosure")
	_check(record != null and &"ts_ch7_qi_yunsheng_open_record" in record.add_testimonies, "Qi Yunsheng meeting records a signed reform testimony")
	var qi_testimony := load("res://data/investigation/testimonies/ts_ch7_qi_yunsheng_open_record.tres") as TestimonyDef
	var clerk_testimony := load("res://data/investigation/testimonies/ts_ch7_mingwu_dead_disciple_code.tres") as TestimonyDef
	_check(qi_testimony != null and qi_testimony.initial_credibility == 72 and &"ev_ch7_lieyun_quarantine_formula" in qi_testimony.related_evidence_ids, "Qi testimony remains tied to the self-incriminating medicine record")
	_check(clerk_testimony != null and clerk_testimony.initial_credibility == 58 and clerk_testimony.statement.contains("无法确认身份"), "Mingwu witness proves dead credentials without naming the user")
	var direct := load("res://data/dialogs/ch7_mingwu_clerk_witness_direct.tres") as DialogScript
	var alerted := load("res://data/dialogs/ch7_mingwu_clerk_witness_alerted.tres") as DialogScript
	_check(_dialog_adds_testimony(direct, &"ts_ch7_mingwu_dead_disciple_code") and _dialog_adds_testimony(alerted, &"ts_ch7_mingwu_dead_disciple_code"), "both investigation orders preserve the same limited witness fact")
	_check(_dialog_sets_flag(alerted, "ch7_mingwu_witness_at_risk") and _dialog_has_method(alerted, "ch7_protect_mingwu_witness"), "Lieyun-first order records the witness-protection consequence")
	var open_dialog := load("res://data/dialogs/ch7_inner_routes_open.tres") as DialogScript
	var open_node := open_dialog.find_node_by_id(&"open") if open_dialog != null else null
	_check(open_node != null and open_node.accept_quest == &"q_ch7_main_04_reform_and_witness" and _node_sets_flag(open_node, "ch7_inner_routes_opened"), "outer-wards completion explicitly accepts and unlocks both witness routes")
	_check(quest != null and quest.require_all_completion_triggers and quest.completion_triggers.size() == 2, "reform-and-witness quest requires both limited testimonies")
	await _check_runtime_chain(true)
	await _check_runtime_chain(false)
	print("[Chapter7ReformWitness20260830] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check_runtime_chain(qi_first: bool) -> void:
	var game_state := root.get_node("GameState")
	var quests := root.get_node("QuestManager")
	var investigation := root.get_node("InvestigationState")
	game_state.call("reset_for_new_game")
	quests.call("reset_for_new_game")
	investigation.call("reset_for_new_game")
	_check(bool(quests.call("accept", &"q_ch7_main_04_reform_and_witness")), "%s order can accept the internal-witness quest" % ("Qi-first" if qi_first else "Mingwu-first"))
	investigation.call("hear_testimony", &"ts_ch7_qi_yunsheng_open_record" if qi_first else &"ts_ch7_mingwu_dead_disciple_code")
	await process_frame
	_check(not bool(quests.call("is_completed", &"q_ch7_main_04_reform_and_witness")), "one limited testimony never completes the internal-witness quest")
	investigation.call("hear_testimony", &"ts_ch7_mingwu_dead_disciple_code" if qi_first else &"ts_ch7_qi_yunsheng_open_record")
	await process_frame
	_check(bool(quests.call("is_completed", &"q_ch7_main_04_reform_and_witness")), "%s order completes only after both testimonies" % ("Qi-first" if qi_first else "Mingwu-first"))


func _scene_contract_ok(scene: SceneScript, expected_file: String) -> bool:
	if scene == null or scene.map_layout == null or not scene.background_path.ends_with(expected_file) or not FileAccess.file_exists(scene.background_path):
		return false
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(scene.background_path)) != OK or image.get_size() != Vector2i(1536,1024):
		return false
	return _layout_probes_match(scene.map_layout)


func _layout_probes_match(layout: WalkableMapLayout) -> bool:
	for probe: Dictionary in layout.walkable_probes:
		var point := probe.get("pos", Vector2(-1.0,-1.0)) as Vector2
		if not layout.walkable_regions.any(func(region: PackedVector2Array): return Geometry2D.is_point_in_polygon(point, region)):
			return false
	for probe: Dictionary in layout.blocked_probes:
		var point := probe.get("pos", Vector2(-1.0,-1.0)) as Vector2
		var inside_region := layout.walkable_regions.any(func(region: PackedVector2Array): return Geometry2D.is_point_in_polygon(point, region))
		var inside_blocker := layout.blockers.any(func(blocker: Dictionary):
			var center := blocker.get("pos", Vector2.ZERO) as Vector2
			var size := blocker.get("size", Vector2.ZERO) as Vector2
			return Rect2(center - size * 0.5, size).has_point(point)
		)
		if inside_region and not inside_blocker:
			return false
	return true


func _portal_target(layout: WalkableMapLayout, portal_id: String) -> StringName:
	for portal: Dictionary in layout.portals:
		if String(portal.get("id", "")) == portal_id:
			return StringName(String(portal.get("target_scene", "")))
	return &""


func _portal_gate(layout: WalkableMapLayout, portal_id: String) -> String:
	for portal: Dictionary in layout.portals:
		if String(portal.get("id", "")) == portal_id:
			return String(portal.get("require_flag", ""))
	return ""


func _image_has_alpha(path: String, expected_size: Vector2i) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK or image.get_size() != expected_size or image.get_format() not in [Image.FORMAT_RGBA8, Image.FORMAT_RGBAF, Image.FORMAT_RGBAH]:
		return false
	return image.detect_alpha() != Image.ALPHA_NONE


func _npc_uses_identity(scene: SceneScript, npc_id: String, portrait_path: String, sprite_path: String) -> bool:
	for npc: Dictionary in scene.npcs:
		if String(npc.get("npc_id", "")) == npc_id:
			return String(npc.get("portrait_path", "")) == portrait_path and String(npc.get("sprite_path", "")) == sprite_path
	return false


func _dialog_adds_testimony(dialog: DialogScript, testimony_id: StringName) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if testimony_id in node.add_testimonies:
			return true
	return false


func _dialog_sets_flag(dialog: DialogScript, flag_name: String) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if _node_sets_flag(node, flag_name):
			return true
	return false


func _dialog_has_method(dialog: DialogScript, method_name: String) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		for entry: Dictionary in node.method_flags:
			if String(entry.get("key", "")) == method_name and bool(entry.get("value", false)):
				return true
	return false


func _node_sets_flag(node: DialogNode, flag_name: String) -> bool:
	for entry: Dictionary in node.set_flags:
		if String(entry.get("key", "")) == flag_name and bool(entry.get("value", false)):
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
