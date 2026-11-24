extends "res://tests/test_inner_courts_modular_1108.gd"

const WUDANG := &"openworld_wudang_gate"
const ASSEMBLY := &"ch3_s1_wulin_assembly"
const TRIAL := &"ch3_s2_trial_ground"
const CAMP := &"ch3_s3_faction_training"
const TOMB := &"ch3_s4_forbidden_tomb"
const SIZE := Vector2(1536,1024)

func _done() -> void:
	print("CH3_MODULAR_MAPS_RESULT ", _checks, "/", _failed)
	quit(0 if _failed == 0 else 1)

func _contract(field: Node, id: StringName) -> void:
	var scene := field.get("_current_scene") as SceneScript
	var old := load("res://data/maps/%s_layout_v1.tres" % id) as WalkableMapLayout
	var layout := scene.map_layout
	_expect(scene.scene_id == id and scene.background_path.is_empty() and layout.resource_path.ends_with("_layout_v2.tres") and layout.visual_objects.size() >= 24, "actual modular map " + String(id))
	_expect(Vector2(field.get("_world_size")) == SIZE, "old logical size " + String(id))
	_expect(layout.schema_version == old.schema_version and layout.walkable_regions == old.walkable_regions, "old bounds and version " + String(id))
	for probe: Dictionary in layout.walkable_probes:
		_expect(bool(field.call("_spawn_has_foot_clearance",scene,probe.pos)), "original path " + String(id))
	for probe: Dictionary in layout.blocked_probes:
		_expect(not bool(field.call("_spawn_has_foot_clearance",scene,probe.pos)), "original blocked perimeter " + String(id))
	for row: Dictionary in scene.hotspots:
		var uv := Vector2(row.pos_x, row.pos_y)
		_expect(bool(field.call("_spawn_has_foot_clearance",scene,uv)), "original interaction spot " + str(row.action))
	for row: Dictionary in layout.blockers:
		_expect(not bool(field.call("_spawn_has_foot_clearance",scene,row.pos)), "solid furniture base " + str(row.id))

func _door(field: Node, target: StringName, uv: Vector2) -> Node:
	await _place(field, uv)
	var zone := _portal(field, target)
	if not _expect(is_instance_valid(zone) and not zone.is_locked and bool(zone.get("_in_range")), "original portal ready " + String(target) + " at " + str(_feet(field))):
		return null
	print("CH3_MODULAR_MAPS_INPUT Space ",target)
	await _press_space()
	return await _ready_field(target)

func _talk(field: Node,id: StringName,uv: Vector2) -> bool:
	await _place(field,uv)
	var area := _area_for_action(field,"dialog:" + String(id))
	if not _expect(is_instance_valid(area) and area.overlaps_body(field.get("_player")), "live story area " + String(id) + " at " + str(_feet(field))):
		return false
	print("CH3_MODULAR_MAPS_INPUT Space ", id)
	await _press_space()
	var dialog := root.get_node("DialogPlayer")
	for i in range(32):
		if bool(dialog.call("is_playing")): break
		await process_frame
	var active := dialog.get("_current_script") as DialogScript
	if not _expect(active != null and active.dialog_id == id, "original dialogue " + String(id) + ", got " + (String(active.dialog_id) if active != null else "none")):
		return false
	for i in range(15):
		if not bool(dialog.call("is_playing")): break
		dialog.call("advance")
		await process_frame
	return true

func _open_from_wudang(field: Node) -> Node:
	if not _expect(await _outside_approach(field,ASSEMBLY,Vector2(1700,3875)), "walkable original Wudang gate to assembly"):
		return null
	print("CH3_MODULAR_MAPS_INPUT Space ", ASSEMBLY)
	await _press_space()
	return await _ready_field(ASSEMBLY)

func _run() -> void:
	if not _expect(_paused_checkpoints, "private saves suspended"): _done(); return
	_router=root.get_node("SceneRouter")
	var flags: Dictionary = root.get_node("GameState").get("flags")
	flags["chapter2_complete"] = true
	flags["seen_ch3_assembly"] = true
	flags["chapter3_started"] = true
	flags["joined_faction"] = true
	flags["joined_wudang"] = true
	flags["defeated_linxi_dojo_senior"] = true
	if not _expect(bool(_router.call("go_field_smart", WUDANG, null, "", -1, 1)), "native Wudang starts"): _done(); return
	var field: Node = await _ready_field(WUDANG)
	if field == null: _done(); return
	field=await _open_from_wudang(field)
	if field == null: _done(); return
	_expect(_feet(field).distance_to(Vector2(.11,.78)*SIZE)<2.0,"original Wudang arrival")
	_contract(field,ASSEMBLY)
	_expect(_portal(field,TRIAL)==null,"qualification door locked before checking evidence")
	_expect(field.get("_npc_nodes").size()==1, "original assembly steward")
	await _place(field,Vector2(.56,.70))
	await _capture(field,"ch3_assembly")
	if not await _talk(field,&"ch3_assembly_token_clue",Vector2(.48,.41)): _done(); return
	_expect(bool(flags.get("assembly_token_checked",false)), "token investigation sets the original flag")
	field=await _ready_field(ASSEMBLY)
	if field == null: _done(); return
	field=await _door(field,WUDANG,Vector2(.205,.75))
	if field == null: _done(); return
	_expect(_feet(field).distance_to(Vector2(1700,3875))<2.0,"assembly returns to exact Wudang feet")
	flags["assembly_evidence_checked"]=true
	flags["assembly_paper_checked"]=true
	flags["assembly_wound_checked"]=true
	field=await _open_from_wudang(field)
	if field == null: _done(); return
	field=await _door(field,TRIAL,Vector2(.82,.72))
	if field == null: _done(); return
	_contract(field,TRIAL)
	var trial := field.get("_current_scene") as SceneScript
	_expect(trial.npcs.size()==7 and field.get("_npc_nodes").size()==5,"trial retains roster and original gating")
	_expect(trial.encounter_groups.size()==2 and is_equal_approx(trial.encounter_chance,0.12),"trial's original encounters")
	await _place(field,Vector2(.51,.72))
	await _capture(field,"ch3_trial")
	field=await _door(field,ASSEMBLY,Vector2(.86,.82))
	if field == null: _done(); return
	_expect(_feet(field).distance_to(Vector2(.82,.72)*SIZE)<2.0,"trial returns to the assembly entry path")
	if not await _talk(field,&"ch3_luoyang_dispatch",Vector2(.60,.34)): _done(); return
	field=await _ready_field(CAMP)
	if field == null: _done(); return
	_contract(field,CAMP)
	var camp := field.get("_current_scene") as SceneScript
	var camp_arrival := _feet(field) / SIZE
	print("CH3_STORY_ARRIVAL ", CAMP, " ", camp_arrival)
	_expect(bool(field.call("_spawn_has_foot_clearance",camp,camp_arrival)), "dispatch arrives on clear camp terrain")
	_expect(camp.encounter_groups.size()==2 and is_equal_approx(camp.encounter_chance,0.18),"joint training's original encounters")
	await _place(field,Vector2(.55,.59))
	await _capture(field,"ch3_camp")
	if not await _talk(field,&"ch3_training_result",Vector2(.52,.42)): _done(); return
	_expect(bool(flags.get("ch3_training_complete",false)), "original recap advances the story")
	field=await _ready_field(TOMB)
	if field == null: _done(); return
	_contract(field,TOMB)
	var tomb_arrival := _feet(field) / SIZE
	print("CH3_STORY_ARRIVAL ", TOMB, " ", tomb_arrival)
	_expect(bool(field.call("_spawn_has_foot_clearance",field.get("_current_scene"),tomb_arrival)), "recap arrives on clear crypt terrain")
	_expect(_area_for_action(field,"dialog:ch3_tomb_battle")!=null and _area_for_action(field,"dialog:ch3_tomb_result")==null,"cargo evidence remains locked behind combat")
	await _place(field,Vector2(.5,.61))
	await _capture(field,"ch3_tomb")
	if not await _talk(field,&"ch3_forbidden_crypt_side",Vector2(.30,.48)): _done(); return
	_expect(bool(flags.get("forbidden_tomb_explored",false)), "original side chamber is playable")
	field=await _ready_field(TOMB)
	if field == null: _done(); return
	field=await _door(field,CAMP,Vector2(.50,.86))
	if field == null: _done(); return
	field=await _door(field,ASSEMBLY,Vector2(.10,.82))
	if field == null: _done(); return
	_expect(_feet(field).distance_to(Vector2(.12,.75)*SIZE)<2.0,"training returns to the original assembly approach")
	_done()
