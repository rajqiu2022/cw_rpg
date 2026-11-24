extends "res://tests/test_inner_courts_modular_1108.gd"

const FORE := &"openworld_huashan_forecourt"
const SWORD := &"openworld_huashan_sword_terrace"
const FALL := &"openworld_huashan_waterfall_terrace"
const MAP_SIZE := Vector2(3072,2048)

func _done() -> void:
	print("HUASHAN_TERRACES_RESULT ",_checks,"/",_failed)
	quit(0 if _failed==0 else 1)

func _original_contract(field: Node,id: StringName,arrival: Vector2) -> void:
	var actual := field.get("_current_scene") as SceneScript
	var old := load("res://data/maps/%s_layout_v1.tres" % id) as WalkableMapLayout
	var layout := actual.map_layout
	_expect(actual.scene_id==id and actual.background_path.is_empty() and Vector2(field.get("_world_size"))==MAP_SIZE,"live modular native size "+String(id))
	_expect(layout.resource_path.ends_with("_v2.tres") and layout.visual_objects.size()>=20 and layout.occluders.is_empty(),"independent environment replaces baked foreground "+String(id))
	_expect(layout.schema_version==old.schema_version and layout.walkable_regions==old.walkable_regions and layout.portals==old.portals,"original nav and route contract "+String(id))
	_expect(_feet(field).distance_to(arrival*MAP_SIZE)<1.0,"exact arrival "+String(id))
	for probe: Dictionary in layout.walkable_probes:
		_expect(bool(field.call("_spawn_has_foot_clearance",actual,probe.pos)),"walkable "+String(probe.id))
	for probe: Dictionary in layout.blocked_probes:
		_expect(not bool(field.call("_spawn_has_foot_clearance",actual,probe.pos)),"blocked "+String(probe.id))

func _travel(from: Node,id: StringName,uv: Vector2) -> Node:
	var zone := _portal(from,id)
	if not _expect(zone!=null and not zone.is_locked,"original portal "+String(id)): return null
	await _place(from,uv)
	if not _expect(bool(zone.get("_in_range")),"reachable portal "+String(id)): return null
	print("HUASHAN_INPUT Space ",id)
	await _press_space()
	return await _ready_field(id)

func _run() -> void:
	_router=root.get_node("SceneRouter")
	var registry := load(REGISTRY) as Script
	if not _expect(_paused_checkpoints and bool(registry.call("source_valid")),"private saves and strict native source gate"): _done(); return
	if not _expect(bool(_router.call("go_field_smart",FORE,null,"",-1,3006)),"load actual mountain gate"): _done(); return
	var outer: Node=await _ready_field(FORE)
	if outer==null: _done(); return
	if not _expect(await _outside_approach(outer,SWORD,Vector2(2700,2500)),"old native gate approach"): _done(); return
	print("HUASHAN_INPUT Space ",SWORD)
	await _press_space()
	var sword: Node=await _ready_field(SWORD)
	if sword==null: _done(); return
	_original_contract(sword,SWORD,Vector2(.5,.885))
	await _place(sword,Vector2(.5,.55))
	await _capture(sword,"huashan_training")
	var top: Node=await _travel(sword,FALL,Vector2(.5,.112))
	if top==null: _done(); return
	_original_contract(top,FALL,Vector2(.44,.86))
	var elder: NPCNode
	for npc: NPCNode in top.get("_npc_nodes"):
		if npc.npc_id=="openworld_you_tianhong": elder=npc
	if not _expect(elder!=null and elder.dialog_id=="openworld_huashan_lanhui_lesson" and elder.movement_mode=="seated","same seated elder and lesson"): _done(); return
	var scene := top.get("_current_scene") as SceneScript
	_expect(not bool(top.call("_spawn_has_foot_clearance",scene,Vector2(.73,.265))),"waterfall pool physically blocked")
	await _place(top,Vector2(.326,.372))
	await _capture(top,"huashan_elder")
	_expect(elder.try_interact(),"nearby elder accepts interaction")
	var dialog := root.get_node("DialogPlayer")
	for i in range(30):
		if dialog.call("is_playing"): break
		await process_frame
	var active := dialog.get("_current_script") as DialogScript
	_expect(active!=null and active.dialog_id==&"openworld_huashan_lanhui_lesson","original lesson opens in the new place")
	if active!=null: dialog.call("_end_dialog")
	await _place(top,Vector2(.60,.393))
	await _capture(top,"huashan_falls")
	sword=await _travel(top,SWORD,Vector2(.44,.915))
	if sword==null: _done(); return
	_expect(_feet(sword).distance_to(Vector2(.5,.105)*MAP_SIZE)<1.0,"exact authored portal anchor on sword terrace: "+str(_feet(sword)))
	outer=await _travel(sword,FORE,Vector2(.5,.92))
	if outer!=null:
		_expect(_feet(outer).distance_to(Vector2(2700,2580))<1.0,"exact native mountain gate reverse foot")
	_done()
