extends "res://tests/test_luoyang_docks08_remove_two_cpu_ready_20261019aa.gd"
## Frozen partial3 facing successor; original draft preserved. Never Field/geometry/task replay.
const AD_CPU_READY = true
const AD_BIND = "res://tests/fixtures/luoyang_docks_roles_cpu_ready_20261019ad.json"
const AD_BIND_SHA = "7bc19ab7ddeb13f69f65dfcd998166a20a7831d7315e9c8ff33798f48c10372e"
const AD_API = "res://scripts/city/luoyang_docks_roles_20261019ad.gd"
const AD_NPC_SCENE = "res://scenes/npc_node.tscn"
const AD_DIALOG_ROOT = "res://data/dialogs/luoyang_docks_roles_20261019ad/"
const AD_COLLECTOR = "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
var ad: Script
var ad_spec: Dictionary = {}
var ad_fixture: Dictionary = {}
var ad_parent: Array = []
var ad_rows: Array = []

func ad_evidence() -> bool:
	var art_row: Dictionary = ad_fixture.art_admission
	var import_row: Dictionary = ad_fixture.import_proof
	if not track(art_row.path,art_row.sha256) or not track(import_row.path,import_row.sha256): return false
	var art: Dictionary = json(art_row.path)
	var imported: Dictionary = json(import_row.path)
	if not check(art.status == "CARRIER_THREE_PNG_LIMITED_ART_ACCEPT_NO_RUNTIME_OR_LOOP_CREDIT" and art.admitted_candidate_pngs.size() == 3 and art.mechanical_report.passed == true,"Root-selected carrier-only limited ART admission, not rejected static backgrounds or fluid loop credit"): return false
	if not check(imported.passed == true and imported.failures.is_empty() and imported.scope == "AD_ONLY_NEW_ROLE_PNG_ISOLATED_IMPORT_NOT_MAIN_PROJECT_OR_FIELD" and imported.rows.size() == 3 and imported.source_first.size() == 12 and imported.source_first == imported.source_final and imported.art_same_person_or_walk_credit == false,"Only three NEW PNG actual isolated fullRGBA proof, not main Field or art credit"): return false
	var role_ids: Array = []
	for role: Dictionary in ad_spec.roles: role_ids.append(role.npc_id)
	if not check(role_ids == ad_fixture.expected_role_ids and role_ids == ["harbour_life_docks_rope_carrier","harbour_life_docks_southern_carrier","harbour_life_docks_west_carrier"],"Only frozen partial3carrier adopted, remaining seven full rows unchanged"): return false
	if not check(ad_spec.evidence.art_admission.path == art_row.path and ad_spec.evidence.art_admission.sha256 == art_row.sha256 and ad_spec.evidence.import_proof.path == import_row.path and ad_spec.evidence.import_proof.sha256 == import_row.sha256,"Manifest evidence identities match independent QA fixture, not arbitrary self-report"): return false
	var seen: Dictionary = {}
	for row: Dictionary in imported.rows:
		if not check(ad_fixture.textures.has(row.texture) and not seen.has(row.texture),"Exact independent three imported textures "+row.texture): return false
		var wanted: Dictionary = ad_fixture.textures[row.texture]
		seen[row.texture] = true
		if not check(row.source_sha256 == wanted.source_sha256 and row.rgba_sha256 == wanted.rgba_sha256 and wire_equal(row.size,wanted.size) and row.full_rgba_exact == true and row.params23 == true and row.zero_mipmaps == true and row.detect3d_compress_to == 0 and row.compiled_path == wanted.compiled_path,"Imported RGBA/A1/hiddenRGB, dimensions and all23/mip0/detect0 independently pinned "+row.texture): return false
		if not track(row.texture,wanted.source_sha256) or not track(row.import_path,row.import_sha256) or not track(row.compiled_path,row.compiled_sha256): return false
	records.append({"kind":"AD_THREE_TEXTURE_ROOT_ACTUAL_IMPORT_EVIDENCE","count":3,"same_person_art_credit":"independently viewed limited ART admission","fluid_loop_or_Field_credit":false})
	return check(seen.size() == 3,"No missing or extra partial3 texture proof")

func ad_source_admission() -> bool:
	if not track(ad_fixture.expected_false_map_path,ad_fixture.expected_false_map_sha256): return false
	var expected: Dictionary = json(ad_fixture.expected_false_map_path).source_sha256
	var collector: Script = load(AD_COLLECTOR)
	var scene := ResourceLoader.load("res://data/scenes/ch4_s2_canal_docks.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not check(collector != null and collector.can_instantiate() and scene != null and expected.size() == ad_fixture.expected_false_source_count,"Canonical source input and independent finite false-map count"): return false
	var actual: Dictionary = collector._transition_sources(scene,false)
	var missing: Array[String] = []; var extra: Array[String] = []
	for path: String in expected:
		if not actual.has(path): missing.append(path)
	for path: String in actual:
		if not expected.has(path): extra.append(path)
	if not check(actual.size() == expected.size() and missing.is_empty() and extra.is_empty(),"Only one Docks actual source path set equals independent false map",{"actual_count":actual.size(),"expected_count":expected.size(),"missing":missing,"extra":extra}): return false
	for path: String in expected:
		if not track(path,expected[path]): return false
	records.append({"kind":"AD_ONE_DOCKS_FALSE_SOURCE_COMPONENT_NOT_FIELD","source_count":expected.size(),"other_city_collectors_run":false,"actual_sources":expected.duplicate(true)})
	return true

func ad_parent_plan() -> Array:
	var crowd: Script = load(ad.CROWD)
	var office: Script = load(ad.OFFICE)
	if not check(crowd != null and crowd.can_instantiate() and office != null and office.can_instantiate(),"Real original crowd/office scripts compile"): return []
	var rows: Array = crowd.project(ad.CITY).duplicate(true)
	var author: Dictionary = office.author()
	if not check(rows.size() == 10 and author.roles.size() == 2,"Frozen post-office parent remains ten identities"): return []
	var seen: Dictionary = {}
	for row: Dictionary in rows:
		if author.roles.has(row.npc_id):
			var role: Dictionary = author.roles[row.npc_id]
			if not check(row.sprite_path == role.expected_original_texture and row.npc_name == role.expected_name and vec(row.pos)*Vector2(3072,2048) == vec(role.expected_foot_px),"Independent original h row identity "+row.npc_id): return []
			row.sprite_path = role.texture; seen[row.npc_id] = true
	if not check(seen.size() == 2,"Both existing office professions retained, no fake Scene binding"): return []
	return rows

func ad_dialogs() -> bool:
	var expected: Dictionary = ad_fixture.dialogues
	var active_paths: Dictionary = {}
	for role: Dictionary in ad_spec.roles:
		if not role.ambient_dialog.is_empty(): active_paths["res://data/dialogs/"+role.ambient_dialog+".tres"] = true
	for path: String in active_paths:
		if not check(expected.has(path),"Every actually adopted new dialogue independently pinned "+path): return false
		var row: Dictionary = expected[path]
		if not track(path,row.sha256): return false
		var dialogue := ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as DialogScript
		if not check(dialogue != null and dialogue.resource_path == path and String(dialogue.dialog_id) == row.internal_dialog_id and dialogue.entry_node_id == &"start" and dialogue.nodes.size() == 2,"Real resource path and internal id remain distinct explicit identities "+path): return false
		for i: int in 2:
			var node := dialogue.nodes[i] as DialogNode
			if not check(node != null and String(node.node_id) == ["start","reply"][i] and node.speaker == row.speaker and node.portrait_path.is_empty() and node.voice_emotion == "normal" and not node.text.is_empty() and node.on_end == ["next:reply","end"][i],"Actual same-person speaker and two-node harmless chain "+path+":"+str(i)): return false
			for key: String in ["choices","give_items","set_flags","learn_skills","add_evidence","verify_evidence","add_testimonies","verify_testimonies","faction_trust_changes","companion_trust_changes","bond_events","city_outcomes","method_flags"]:
				if not check(node.get(key).is_empty(),"No new dialogue side effect "+key): return false
			if not check(node.give_gold == 0 and node.accept_quest == &"" and node.complete_quest == &"" and node.weather_id == &"","No quest/reward/weather delta"): return false
	return true

func ad_row_inverse() -> bool:
	var result: Dictionary = ad.compose_exact(ad_parent,ad_parent,ad_spec)
	if not check(result.get("ok") == true and result.npcs.size() == 10 and result.changed_ids.size() == ad_spec.roles.size() and result.geometry_modified == false and result.movement_modified == false,"Pure row projection only, explicitly not native Scene/Field binding"): return false
	ad_rows = result.npcs.duplicate(true)
	var roles: Dictionary = {}
	for role: Dictionary in ad_spec.roles: roles[role.npc_id] = role
	for i: int in ad_parent.size():
		var before: Dictionary = ad_parent[i]
		var after: Dictionary = ad_rows[i]
		if not roles.has(before.npc_id):
			if not check(equal(before,after),"Every non-adopted worker/moving/h row entire unchanged "+before.npc_id): return false
			continue
		var role: Dictionary = roles[before.npc_id]
		var wanted: Dictionary = before.duplicate(true)
		var expected_patch: Dictionary = {
			"sprite_path":"res://art/characters/luoyang_docks_roles_20261019ad/npc_docks_strong_carrier_idle_down_1f_v1_runtime.png",
			"walk_sprite_path":"res://art/characters/luoyang_docks_roles_20261019ad/npc_docks_strong_carrier_walk_right_4f_v1_runtime.png",
			"portrait_path":"res://art/characters/portraits/luoyang_docks_roles_20261019ad/portrait_docks_strong_carrier_v1.png",
			"invert_patrol_facing":false}
		if not check(equal(role.patch,expected_patch) and typeof(role.patch["invert_patrol_facing"]) == TYPE_BOOL and before.invert_patrol_facing == true,"Exact three carrier-only authored right-facing visual bool, original lanes remain unchanged "+before.npc_id): return false
		for key: String in expected_patch: wanted[key] = expected_patch[key]
		if not role.ambient_dialog.is_empty(): wanted.dialog_id = role.ambient_dialog
		if not check(equal(wanted,after),"Independent exact three textures/false mirroring/empty-daily whitelist, all other fields preserved "+before.npc_id): return false
		if before.movement_mode == "patrol" and not check(not after.walk_sprite_path.is_empty() and after.walk_sprite_path != before.walk_sprite_path,"Adopted moving identity requires its same-person new walk, never mismatched old sheet"): return false
	# Focused actual-authority negatives, not a generalized input matrix.
	var wrong_facing: Dictionary = ad_spec.duplicate(true); wrong_facing.roles[0].patch["invert_patrol_facing"] = true
	if not check(not ad.compose_exact(ad_parent,ad_parent,wrong_facing).get("ok",false),"Original merchant left-sheet mirroring cannot be retained for new right-sheet carrier"): return false
	var bad: Dictionary = ad_spec.duplicate(true); bad.roles[0].patch["pos"] = Vector2.ZERO
	if not check(not ad.compose_exact(ad_parent,ad_parent,bad).get("ok",false),"No visual patch may move the NPC"): return false
	bad = ad_spec.duplicate(true); bad.roles.append(bad.roles[0].duplicate(true))
	if not check(not ad.compose_exact(ad_parent,ad_parent,bad).get("ok",false),"Duplicate adopted identity rejected"): return false
	bad = ad_spec.duplicate(true); bad.roles[0].npc_id = "unapproved_docks_person"
	if not check(not ad.compose_exact(ad_parent,ad_parent,bad).get("ok",false),"Unknown identity rejected"): return false
	var primary: Array = ad_parent.duplicate(true)
	for row: Dictionary in primary:
		if row.npc_id == ad_spec.roles[0].npc_id: row.dialog_id = "original_task_primary"
	if not ad_spec.roles[0].ambient_dialog.is_empty() and not check(not ad.compose_exact(primary,primary,ad_spec).get("ok",false),"Daily overlay cannot replace original task primary"): return false
	return true

func ad_local_body() -> bool:
	var packed := load(AD_NPC_SCENE) as PackedScene
	if not check(packed != null,"Real NPC PackedScene, no alternate script"): return false
	var roles: Dictionary = {}
	for role: Dictionary in ad_spec.roles: roles[role.npc_id] = role
	for row: Dictionary in ad_rows:
		if not roles.has(row.npc_id): continue
		var npc := packed.instantiate() as NPCNode
		if not check(npc != null,"Actual native NPCNode instance"): return false
		npc.npc_id = row.npc_id; npc.npc_name = row.npc_name
		npc.sprite_path = row.sprite_path; npc.walk_sprite_path = row.walk_sprite_path
		npc.portrait_path = row.portrait_path; npc.dialog_id = row.dialog_id
		npc.sprite_scale = 1.0; npc._calibrate_adult_body = true
		npc.movement_mode = row.movement_mode; npc.patrol_axis = row.patrol_axis
		npc.patrol_distance = row.patrol_distance; npc.patrol_speed = row.patrol_speed
		npc.invert_patrol_facing = row.invert_patrol_facing; npc.walk_frame_seconds = row.walk_frame_seconds
		root.add_child(npc); npc.set_process(false); npc.set_ground_anchored(true)
		var image := npc.sprite.texture.get_image()
		var bounds := image.get_region(Rect2i(0,0,160,160)).get_used_rect()
		var expected_scale := Vector2.ONE * (140.0 / float(bounds.size.y)) if bounds.size.y > 0 else Vector2.ZERO
		var body := npc.get("_body_collider") as StaticBody2D
		var shape := body.get_child(0) as CollisionShape2D if body != null else null
		var valid: bool = image.get_height() == 160 and npc.sprite.hframes == 1 and npc._calibrate_adult_body and npc._ground_anchored and bounds.size.y > 0 and npc.sprite.scale == expected_scale
		valid = valid and shape != null and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size == Vector2(22.4,28.8) and body.position+shape.position == Vector2.ZERO and body.collision_layer == 1 and body.collision_mask == 0
		valid = valid and npc.sprite.position.y+(bounds.end.y-80.0)*npc.sprite.scale.y == 0.0 and npc.position == Vector2.ZERO and npc.is_in_group("npc")
		records.append({"kind":"LOCAL_NATIVE_NPC_CALIBRATION_NOT_FIELD","id":npc.npc_id,"bounds":bounds,"visible_height":bounds.size.y*npc.sprite.scale.y,"body":(shape.shape as RectangleShape2D).size if shape != null else Vector2.ZERO,"ground_foot":npc.sprite.position.y+(bounds.end.y-80.0)*npc.sprite.scale.y,"actual_patrol_or_Space_credit":false})
		npc.free()
		if not check(valid,"Local original160/140px/22.4x28.8/zero-foot body exact "+row.npc_id): return false
	return true

func _exercise() -> bool:
	if not check(AD_CPU_READY and OS.get_cmdline_user_args().is_empty(),"Frozen AD CPU source/asset/row/local-native component only, no Field credit"): return false
	if not track(AD_BIND,AD_BIND_SHA): return false
	ad_fixture = json(AD_BIND)
	for path: String in ad_fixture.source_sha256:
		if not track(path,ad_fixture.source_sha256[path]): return false
	serial = load(SERIAL); ad = load(AD_API)
	if not check(serial != null and serial.can_instantiate() and ad != null and ad.can_instantiate(),"Actual API compile before constants/readiness"): return false
	var ready: Dictionary = ad.readiness()
	if not check(ready.get("ok") == true,"Actual frozen manifest/source readiness",ready): return false
	ad_spec = ready.spec.duplicate(true)
	if not check(ad_fixture.get("evidence_ready") == true,"Independent ART subset/same-person and newPNG fullRGBA/23params/mip0 proof still required"): return false
	if not ad_evidence(): return false
	if not ad_source_admission(): return false
	ad_parent = ad_parent_plan()
	if ad_parent.is_empty() or not ad_row_inverse() or not ad_dialogs() or not ad_local_body(): return false
	return true

func _run() -> void:
	began = Time.get_ticks_msec(); root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var saves_before: Dictionary = saves(); var state_before: Dictionary = world_state()
	var self_path: String = get_script().resource_path; sources[self_path] = fact(self_path)
	var complete: bool = _exercise()
	var after: Dictionary = {}
	for path: String in sources: after[path] = fact(path)
	var saves_after: Dictionary = saves(); var state_after: Dictionary = world_state()
	check(sources == after and saves_before == saves_after and saves_before.size() == 15 and state_before == state_after,"All finite sources/state/15save first-final unchanged")
	check(Time.get_ticks_msec()-began < 60000,"Original bounded60s AD CPU, no old city/geometry/task suite")
	var folder := "res://build/luoyang_docks_roles_20261019ad_qa01/cpu_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var file := FileAccess.open(folder.path_join("result.json"),FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"scope":"AD_DOCKS_ROLE_PURE_ROW_ASSET_DIALOG_AND_LOCAL_BODY_NOT_FIELD","complete":complete and failures == 0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":60000,"records":records,"source_before":sources,"source_after":after,"players_before":saves_before,"players_after":saves_after,"state_before":state_before,"state_after":state_after,"Field_credit":false,"actual_walk_or_dialog_portrait_credit":false},"\t",true,true)); file.close()
	print(JSON.stringify({"report_path":folder.path_join("result.json"),"checks":checks,"failures":failures,"complete":complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)
