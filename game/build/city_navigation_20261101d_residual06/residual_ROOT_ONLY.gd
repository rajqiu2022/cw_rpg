extends "res://build/city_navigation_20261101d_residual04/residual_ROOT_ONLY.gd"
## Four unfinished true directions plus only the rejected hall normal-image
## residual. Exact Root-approved one-art-leaf successor, never a general rebase.
const R6 := "res://build/city_navigation_20261101d_residual06/"
const R6_INPUTS := R6 + "residual_inputs_ROOT_READY.json"
const V5_INPUTS_PATH := "res://build/city_navigation_20261101d_visual05/visual_inputs_ROOT_READY.json"
const OLD_ART_SHA := "e261426562db34f3edeb400b1c85e05e5a496ffb09995dd0e25bd2922a05f394"
const OLD_MANIFEST_SHA := "64b80a6d4c930aec98fb214084ba6dd838cebfa5ff13d498c88c6999262c21e4"
const DOCKS_APPLY_SHA := "3cb1b0163d1f508a055ea14bda399b9ba314bb5eaad3e2deb01af21752e40491"
const DOCKS03_APPLY_SHA := "307cbe8086bc715f20722f6b25b285f74aa8319421d6416231e471fefcc08b0f"
const DOCKS03_CLOSURE_SHA := "8f31c3ea81b4b82a06a9eb99c88478ba3277d3ad2747ce2c36e72adf41af2de4"
const DOCKS03_AFTER := {"res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json":"fa97dc9f9902ee9c9733d6431edc50845e550f34988ec4789cada42d0c700e8c", "res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd":"459ba3bd569520b79ecb2c62c3a1ba1e209894114607e185299bd810cd85ae88"}
var r6: Dictionary = {}
var inherited_visual05 := false

func _merge_exact_extra(values: Dictionary, label: String) -> bool:
	for path: String in values:
		var expected: String = String(values[path])
		if not need(path.begins_with("res://") and not ".." in path and expected.length() == 64 and (not pins.has(path) or pins[path] == expected),label+":"+path): return false
		pins[path] = expected
	return true

func _approved_one_leaf() -> bool:
	var a: Dictionary = r6.get("approved_art_successor",{})
	var m: Dictionary = r6.get("approved_manifest_successor",{})
	if not need(a.get("root_approved") == true and m.get("root_approved") == true and a.get("path") == ART and m.get("path") == MANIFEST and a.get("before_sha256") == OLD_ART_SHA and m.get("before_sha256") == OLD_MANIFEST_SHA and String(a.get("after_sha256","")).length() == 64 and String(m.get("after_sha256","")).length() == 64,"ROOT_EXPLICIT_ART_SINGLE_LEAF_AND_MANIFEST_SUCCESSOR"): return false
	if not need(FileAccess.get_sha256(m.before_archive_path) == OLD_MANIFEST_SHA and FileAccess.get_sha256(MANIFEST) == m.after_sha256,"ORIGINAL96_ARCHIVE_AND_APPROVED_AFTER_MANIFEST_EXACT"): return false
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(m.before_archive_path)) as Dictionary
	var newer: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)) as Dictionary
	var before: Dictionary = old.get("source_pins",{}); var after: Dictionary = newer.get("source_pins",{})
	if not need(old.get("ready") == true and newer.get("ready") == true and before.size() == 96 and after.size() == 96 and before.get(ART) == OLD_ART_SHA and after.get(ART) == a.after_sha256,"EXACT_SAME96_DOMAIN_WITH_ONE_APPROVED_ART_VALUE"): return false
	var differences: Array[String] = []
	for path: String in before:
		if not need(after.has(path),"NO96_LEAF_REMOVED_OR_REPLACED:"+path): return false
		if before[path] != after[path]: differences.append(path)
	if not need(differences == [ART] and pins.get(ART) == OLD_ART_SHA and pins.get(MANIFEST) == OLD_MANIFEST_SHA,"ONLY_ART_RUNTIME_LEAF_OVERRIDE_NOT_GENERAL_EXPECTATION_REBASE"): return false
	pins[ART] = a.after_sha256; pins[MANIFEST] = m.after_sha256
	pins[m.before_archive_path] = OLD_MANIFEST_SHA
	records.append({"Root_approved_single_runtime_leaf_successor":a,"manifest_container_successor":m,"runtime_leaf_keyset_96_exact":true,"changed_runtime_leaves":differences,"other95_leaf_values_unchanged":true})
	return true

func _approved_docks_extra() -> bool:
	if not need(r6.docks_apply_receipt_sha256 == DOCKS_APPLY_SHA and FileAccess.get_sha256(r6.docks_apply_receipt) == DOCKS_APPLY_SHA,"ROOT_AUTHORIZED_EXACT21_DOCKS_APPLY_RECEIPT"): return false
	var receipt: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(r6.docks_apply_receipt)) as Dictionary
	var targets: Array = receipt.get("actual_targets",[])
	var after: Dictionary = r6.get("docks_after_source_pins",{})
	var runtime: Dictionary = r6.get("docks_new_runtime_pins",{})
	if not need(receipt.get("applied_successfully") == true and targets.size() == 21 and after.size() == 21 and runtime.size() == 3 and receipt.get("changed_frozen96_targets",[]).is_empty() and receipt.get("changed_original113_targets",[]).is_empty(),"FINITE21_AFTER_PLUS3_NEW_LEAVES_OUTSIDE96_AND113"): return false
	for row: Dictionary in targets:
		if not need(after.get(String(row.res_path)) == row.actual_after_sha256 and row.actual_after_sha256 == row.after_sha256 and not pins.has(String(row.res_path)),"ROOT_PIN_MATCHES_APPROVED21_AFTER_NOT_OTHER_SOURCE:"+String(row.res_path)): return false
	if not need(runtime == receipt.get("new_runtime_sources",{}),"EXACT_THREE_AUTHORIZED_DOCKS_RUNTIME_LEAVES"): return false
	if not _merge_exact_extra(after,"EXPLICIT_DOCKS21_AFTER") or not _merge_exact_extra(runtime,"EXPLICIT_DOCKS3_NEW_RUNTIME"): return false
	pins[r6.docks_apply_receipt] = DOCKS_APPLY_SHA
	records.append({"additional_QA_only_docks_after_pins":21,"additional_QA_only_docks_new_runtime_pins":3,"apply_receipt":r6.docks_apply_receipt,"apply_sha256":DOCKS_APPLY_SHA,"no_expansion_of_96_manifest":true})
	return true

func _approved_docks_stage03() -> bool:
	# Stage02 remains the exact21 before/after authority above. Only these two
	# explicitly approved stage03 successors replace its final expected values.
	var approval: Dictionary = r6.get("docks_stage03_approval",{})
	if not need(approval.get("root_approved") == true and approval.get("receipt_sha256") == DOCKS03_APPLY_SHA and approval.get("closure_sha256") == DOCKS03_CLOSURE_SHA and FileAccess.get_sha256(approval.receipt_path) == DOCKS03_APPLY_SHA and FileAccess.get_sha256(approval.closure_path) == DOCKS03_CLOSURE_SHA,"ROOT_EXPLICIT_DOCKS03_RECEIPT_AND_CLOSURE_EXACT"): return false
	var receipt: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(approval.receipt_path)) as Dictionary
	var overrides: Dictionary = approval.get("source_overrides",{})
	var targets: Array = receipt.get("actual_targets",[])
	if not need(receipt.get("applied_successfully") == true and receipt.get("original21_apply_receipt_sha256") == DOCKS_APPLY_SHA and receipt.get("candidate_closure_sha256") == DOCKS03_CLOSURE_SHA and targets.size() == 2 and overrides.size() == 2 and receipt.get("new_runtime_sources",{}).is_empty(),"ONLY_TWO_STAGE03_TARGETS_NO_NEW_RUNTIME_DOMAIN"): return false
	var changed: Array[String] = []
	for row: Dictionary in targets:
		var path: String = String(row.res_path)
		var expected: Dictionary = overrides.get(path,{})
		if not need(DOCKS03_AFTER.has(path) and expected.get("before_sha256") == row.before_sha256 and expected.get("before_sha256") == r6.docks_after_source_pins.get(path) and pins.get(path) == expected.get("before_sha256") and expected.get("after_sha256") == DOCKS03_AFTER[path] and row.actual_after_sha256 == DOCKS03_AFTER[path] and row.after_sha256 == DOCKS03_AFTER[path] and row.get("stage2_after_equals_stage3_before") == true and row.get("stage3_complete_forward_inverse") == true,"EXACT_STAGE02_AFTER_TO_APPROVED_STAGE03_ONLY:"+path): return false
		pins[path] = expected.after_sha256; changed.append(path)
	pins[approval.receipt_path] = DOCKS03_APPLY_SHA; pins[approval.closure_path] = DOCKS03_CLOSURE_SHA
	records.append({"Root_explicit_Docks_stage03_two_source_overrides":overrides,"stage02_exact21_receipt_still_preserved":DOCKS_APPLY_SHA,"stage03_receipt":approval.receipt_path,"stage03_receipt_sha256":DOCKS03_APPLY_SHA,"stage03_closure_sha256":DOCKS03_CLOSURE_SHA,"other19_stage02_after_pins_unchanged":true,"three_runtime_pins_unchanged":true,"no_96_leaf_override_from_Docks03":true,"changed_docks_expected_sources":changed})
	return true

func run() -> void:
	directory = R6 + "actual/" + str(OS.get_process_id()); DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"RESIDUAL06_EARLIEST_CHECKPOINT_SUSPEND"): finish(); return
	r6 = JSON.parse_string(FileAccess.get_file_as_string(R6_INPUTS)) as Dictionary
	if not need(r6.get("schema") == "CITY_NAVIGATION_20261101D_RESIDUAL06_QA_V1" and r6.get("ready") == true,"ROOT_EXPLICIT_RESIDUAL06_FREEZE"): finish(); return
	if not need(FileAccess.get_sha256(INPUTS) == r6.base_inputs_sha256 and FileAccess.get_sha256(RESIDUAL_INPUTS) == r6.parent_inputs_sha256 and FileAccess.get_sha256(R3_INPUTS) == r6.parent03_inputs_sha256 and FileAccess.get_sha256(V5_INPUTS_PATH) == r6.visual05_inputs_sha256,"UNCHANGED_OLD_QA_CONFIGURATIONS_NOT_REWRITTEN"): finish(); return
	cfg = JSON.parse_string(FileAccess.get_file_as_string(INPUTS)) as Dictionary
	residual = JSON.parse_string(FileAccess.get_file_as_string(RESIDUAL_INPUTS)) as Dictionary
	r3 = JSON.parse_string(FileAccess.get_file_as_string(R3_INPUTS)) as Dictionary
	var visual: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(V5_INPUTS_PATH)) as Dictionary
	pins = cfg.get("source_pins",{}).duplicate(true)
	for previous: Dictionary in [residual,r3,visual]:
		if not _merge_exact_extra(previous.get("source_pins",{}),"OLD_QA_FROZEN_EXPECTATIONS_COHERENT"): finish(); return
	if not _approved_one_leaf() or not _approved_docks_extra() or not _approved_docks_stage03(): finish(); return
	for path: String in r6.required_source_paths:
		if not need(r6.get("source_pins",{}).has(path),"ROOT_EXPLICIT_RESIDUAL06_EXTRA_PIN:"+path): finish(); return
	if not _merge_exact_extra(r6.get("source_pins",{}),"NO_OTHER_SOURCE_OVERRIDE_ALLOWED") or not _merge_exact_extra(r6.get("inherited_image_source_pins",{}),"ORIGINAL91216_IMAGES_PRESERVED"): finish(); return
	pins[INPUTS] = r6.base_inputs_sha256; pins[RESIDUAL_INPUTS] = r6.parent_inputs_sha256
	pins[R3_INPUTS] = r6.parent03_inputs_sha256; pins[V5_INPUTS_PATH] = r6.visual05_inputs_sha256
	pins[R6_INPUTS] = FileAccess.get_sha256(R6_INPUTS) # Root launch also exact-pins this JSON.
	first = facts()
	for path: String in pins:
		if not need(first[path].sha256 == pins[path],"RESIDUAL06_SOURCE_FIRST:"+path): finish(); return
	router = root.get_node("SceneRouter"); host = root.get_node_or_null("CityNavigationRuntime")
	if not need(host != null and host.get_script().resource_path == HOST and ProjectSettings.get_setting("autoload/CityNavigationRuntime","") == "*"+HOST,"ACTUAL_APPROVED_CITYNAV_HOST"): finish(); return
	pair_data = load(PAIRS) as GDScript; r4 = r6
	var until := Time.get_ticks_msec()+3000
	while Time.get_ticks_msec() < until and host.call("get_debug_state").get("ready") != true: await process_frame
	if not _inherit_prefix() or not _inherit_market_artisan() or not _inherit_market_temple() or not _inherit_visual(): finish(); return
	for id: String in ["docks_temple","temple_riverside"]:
		var pair: Dictionary = _pair(id)
		var a: Dictionary = _endpoint(pair,"a"); var b: Dictionary = _endpoint(pair,"b")
		if not await _near(a,a.arrival) or not await _cross(a) or not await _cross(b): finish(); return
	var temple: Dictionary = _endpoint(_pair("temple_riverside"),"a")
	var hall_foot := Vector2(cfg.temple_hall_foot[0],cfg.temple_hall_foot[1])
	if not await _near(temple,hall_foot): finish(); return
	var dimensions_ok: bool = _hall_check()
	var depth_ok: bool = _front_hall_depth()
	records.append({"retested_hall_dimensions_physics_mini":dimensions_ok,"retested_front_people_depth":depth_ok,"prior_adult_and_two_accepted_images_not_retested":true})
	if not await _capture("temple_scripture_hall_front_people_normal"): finish(); return
	finish()

func _inherit_visual() -> bool:
	if not need(FileAccess.get_sha256(r6.visual05_report) == r6.visual05_report_sha256,"ORIGINAL91216_REPORT_NUMERIC_PASS_AND_ART_REJECTION_RETAINED"): return false
	var prior: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(r6.visual05_report)) as Dictionary
	if not need(prior.get("passed") == true and prior.get("checks") == 193 and prior.get("errors",[]).is_empty() and prior.get("input_events") == 0 and prior.get("normal_images") == 3,"EXACT91216_NUMERIC_REPORT_SCOPE_NOT_WHOLE_ART_CLAIM"): return false
	var adults: Array = prior.get("records",[]).filter(func(row: Dictionary) -> bool: return row.has("civic_six_adult_current_residents_measured"))
	var minis: Array = prior.get("records",[]).filter(func(row: Dictionary) -> bool: return row.has("civic_actual_mini"))
	if not need(adults.size() == 1 and minis.size() == 1,"INHERIT_ACTUAL_CIVIC_ADULT_AND_MINI_EVIDENCE"): return false
	var blades: Array = adults[0].civic_six_adult_current_residents_measured.filter(func(row: Dictionary) -> bool: return row.get("id") == "spar_luoyang_blademaster" and row.get("resident") == true)
	if not need(blades.size() == 1 and absf(float(blades[0].actual_visible_core_height)-132.0) <= .1 and blades[0].get("whole_core_on_screen") == true and blades[0].get("original_body_action_unchanged") == true,"INHERIT_OBSERVED132_ADULT_ORIGINAL_BODY_ACTION_NOT_RERUN"): return false
	inherited_visual05=true
	records.append({"inherited_accepted_91216_only":["Civic adult132 and services mini normal","Temple south roadmouth mini normal"],"report":r6.visual05_report,"report_sha256":r6.visual05_report_sha256,"prior_numeric_passed":true,"prior_third_hall_image_ART_rejected":true,"old_all_three_image_bytes_pinned_preserved":true,"new_hall_normal_required":true,"new_input_travel_not_inherited_from_visual_only":true})
	return true

func _effective_depth(item: CanvasItem) -> int:
	var depth: int = item.z_index
	var cursor: CanvasItem = item
	while cursor.z_as_relative:
		var parent: Node = cursor.get_parent()
		while parent != null and not parent is CanvasItem: parent=parent.get_parent()
		if parent == null: break
		cursor=parent as CanvasItem; depth+=cursor.z_index
	return depth

func _front_hall_depth() -> bool:
	var quad: Polygon2D = field.get("_visual_layer").get_node_or_null("Quality20261101dEastScriptureHall") as Polygon2D
	var player: Player = field.get("_player") as Player
	if not need(quad != null and player != null and player.sprite != null,"ACTUAL_NEW_HALL_AND_LIVE_PLAYER_DEPTH"): return false
	var house_depth: int = _effective_depth(quad)
	var hero_depth: int = _effective_depth(player.sprite)
	var front_people: Array[Dictionary] = []
	for npc: NPCNode in field.get("_npc_nodes"):
		if not is_instance_valid(npc) or npc.sprite == null or not npc.is_visible_in_tree(): continue
		if npc.position.x < 1799 or npc.position.x > 2642 or npc.position.y < 2921 or npc.position.y > 3100: continue
		var actor_depth: int = _effective_depth(npc.sprite)
		front_people.append({"id":npc.npc_id,"foot":npc.position,"actual_effective_depth":actor_depth,"in_front_of_opaque_hall":actor_depth > house_depth})
		need(actor_depth > house_depth,"VISIBLE_FRONT_NPC_NOT_UNDER_HALL:"+npc.npc_id)
	var owner: Node = field.get_node_or_null("Quality20261101dArtView")
	var receipt: Dictionary = owner.call("receipt") if owner != null else {}
	records.append({"actual_parent_relative_hall_depth":house_depth,"hall_local_z":quad.z_index,"hall_z_as_relative":quad.z_as_relative,"world_parent_z":field.get("world_container").z_index,"actual_hero_effective_depth":hero_depth,"actual_hero_foot":player.position,"front_people":front_people,"architecture_modulate_alpha":quad.modulate.a,"architecture_self_alpha":quad.self_modulate.a,"preserved_overlap_receipt":receipt,"behind_masked_ghost_alpha_preserved_not_new_behind_travel":receipt.get("new_quad_ghost_alpha")})
	return need(quad.z_as_relative and house_depth == 265 and hero_depth > house_depth and quad.modulate.a == 1.0 and quad.self_modulate.a == 1.0 and receipt.get("new_quad_ghost_alpha") == .42,"OPAQUE_HALL_EFFECTIVE265_BELOW_FRONT_HERO_AND_NPC_NO_CAMERA_OR_ACTOR_Z_WRITE")

func finish() -> void:
	if done: return
	done=true
	var final_sources: Dictionary = facts() if not pins.is_empty() else {}
	if not first.is_empty(): need(var_to_bytes(first) == var_to_bytes(final_sources),"RESIDUAL06_SOURCE_FIRST_FINAL_EXACT")
	var executed: int = records.filter(func(row: Dictionary) -> bool: return row.get("true_space_crossing") == true).size()
	records.append({"scope":"FOUR_REMAINING_TRUE_DIRECTIONS_ONE_HALL_NORMAL_ONLY","inherited_true_directions":4 if inherited_temple else 0,"executed_true_directions":executed,"inherited_visual05_adult_and_two_images":inherited_visual05,"old_hall_ART_rejection_retained":true,"single_art_runtime_leaf_override_only":true,"no_camera_or_player_writes":true,"save_metadata_samples":0})
	var result: Dictionary = {"passed":errors.is_empty(),"checks":checks,"errors":errors,"input_events":inputs,"normal_images":images,"inherited_true_directions":4 if inherited_temple else 0,"executed_true_directions":executed,"records":records,"source_first":first,"source_final":final_sources,"checkpoint_suspended":suspended,"root_only":true}
	var file := FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result,"\t")+"\n")
	print("CITYNAV31D_RESIDUAL06 ",JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"inputs":inputs,"images":images,"executed":executed,"result":directory+"/result.json"}))
	quit(0 if errors.is_empty() else 1)
