extends SceneTree
## Isolated desktop-only smoke test. Use private AppData and keep the editor.

const ROAD := &"ch5_s1_relief_road"
const CAMP := &"ch5_s2_grain_convoy_camp"
const PASS := &"ch5_s3_snow_pass"
const MINE := &"ch5_s4_abandoned_mine"
const OUTPOST := &"ch5_s5_false_banner_outpost"
var _paused_checkpoints := false
var _failed := 0
var _checks := 0
var _router: Node

func _initialize() -> void:
	root.child_entered_tree.connect(_suspend)
	for child: Node in root.get_children(): _suspend(child)
	_run.call_deferred()

func _suspend(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		_paused_checkpoints = bool(node.call("is_checkpoint_saves_suspended"))

func _expect(ok: bool, message: String) -> bool:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("GUFENG_REGIONS_FAIL ", message)
	return ok

func _done() -> void:
	print("GUFENG_REGIONS_RESULT ", _checks, "/", _failed)
	quit(0 if _failed == 0 else 1)

func _ready_field(id: StringName) -> Node:
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var current := current_scene
		if current == null or not current.has_method("get_field_loading_state"): continue
		if _router.call("get_current_field_id") != id: continue
		var state: Dictionary = current.call("get_field_loading_state")
		var actor := current.get("_player") as Player
		if not bool(state.get("complete", false)) or not is_instance_valid(actor) or not actor.can_move: continue
		if bool(root.get_node("LoadingManager").get("_transition_active")): continue
		await physics_frame
		return current
	_expect(false, "field ready " + String(id))
	return null

func _portal(field: Node, target: StringName) -> ExitZone:
	for zone: ExitZone in field.get("_exit_nodes"):
		if StringName(zone.target_scene_id) == target: return zone
	return null

func _press_space() -> void:
	var press := InputEventKey.new()
	press.keycode = KEY_SPACE
	press.physical_keycode = KEY_SPACE
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := press.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)

func _place(field: Node, uv: Vector2) -> void:
	var actor := field.get("_player") as Player
	var world := field.get("world_container") as Node2D
	actor.global_position = world.to_global(uv * Vector2(field.get("_world_size")))
	field.set("_last_encounter_position", actor.position)
	field.set("_encounter_distance", 0.0)
	await physics_frame
	await physics_frame
	await process_frame
	await process_frame

func _feet(field: Node) -> Vector2:
	var actor := field.get("_player") as Player
	var world := field.get("world_container") as Node2D
	return world.to_local(actor.global_position)

func _capture(field: Node, key: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	field.call("_snap_camera_to_player")
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	_expect(shot != null and shot.save_png("user://gufeng_regions_" + key + ".png") == OK, "normal view " + key)

func _area_for_action(field: Node, action: String) -> Area2D:
	for area: Area2D in field.get("_trigger_areas"):
		var data: Dictionary = area.get_meta("trigger_data", {})
		if String(data.get("action", "")) == action:
			return area
	return null

func _world_exit(field: Node) -> ExitZone:
	for zone: ExitZone in field.get("_exit_nodes"):
		if zone.action == "world_map":
			return zone
	return null

func _flag(flag_name: StringName) -> void:
	root.get_node("GameState").call("set_flag", flag_name, true)
	await create_timer(.45).timeout

func _locked(field: Node, target: StringName, name: String) -> void:
	var found := false
	for zone: ExitZone in field.get("_exit_nodes"):
		if zone.destination_name == name and zone.is_locked:
			found = true
	_expect(found and _portal(field, target) == null, "original lock " + name)

func _approach(field: Node, area: Area2D) -> bool:
	var scene := field.get("_current_scene") as SceneScript
	var actor := field.get("_player") as Player
	var body := actor.get_node("CollisionShape2D") as CollisionShape2D
	var world := field.get("world_container") as Node2D
	var size := Vector2(field.get("_world_size"))
	var center := world.to_local(area.global_position)
	var offset := world.to_local(body.global_position) - _feet(field)
	for y: float in [0.0, -18.0, 22.0, -32.0, 38.0]:
		for x: float in [0.0, 24.0, -24.0, 42.0, -42.0]:
			var uv := (center - offset + Vector2(x,y)) / size
			if not bool(field.call("_spawn_has_foot_clearance", scene, uv)):
				continue
			await _place(field, uv)
			await physics_frame
			if area.overlaps_body(actor) and (not area is ExitZone or bool(area.get("_in_range"))):
				return true
	return false

func _leg(field: Node, target: StringName) -> Node:
	var zone := _portal(field,target)
	if not _expect(zone != null and not zone.is_locked, "open portal " + String(target)):
		return null
	if not _expect(await _approach(field,zone), "physical approach " + String(target)):
		return null
	print("GUFENG_REGIONS_INPUT Space portal ", target)
	await _press_space()
	return await _ready_field(target)

func _inspect(field: Node, id: StringName, flag: String) -> bool:
	var area := _area_for_action(field,"dialog:" + String(id))
	if not _expect(area != null, "actual clue area " + String(id)):
		return false
	if not _expect(await _approach(field,area), "physical clue approach " + String(id)):
		return false
	print("GUFENG_REGIONS_INPUT Space dialogue ", id)
	await _press_space()
	await create_timer(.25).timeout
	var dialog := root.get_node("DialogPlayer")
	var running := dialog.get("_current_script") as DialogScript
	if not _expect(running != null and running.dialog_id == id, "actual original dialogue " + String(id) + " received " + (String(running.dialog_id) if running != null else "<none>") + " at " + str(_feet(field))):
		return false
	for i in range(6):
		if not bool(dialog.call("is_playing")): break
		dialog.call("advance")
		await process_frame
	await create_timer(.45).timeout
	var flags := root.get_node("GameState").get("flags") as Dictionary
	return _expect(bool(flags.get(flag,false)) and not bool(dialog.call("is_playing")), "original dialogue sets " + flag)

func _map(field: Node, id: StringName, spots: Array[Vector2]) -> void:
	var scene := field.get("_current_scene") as SceneScript
	var old := load("res://data/maps/%s_layout_v1.tres" % String(id)) as WalkableMapLayout
	var layout := scene.map_layout
	_expect(scene.scene_id == id and scene.background_path.is_empty() and layout.visual_objects.size() >= 8, "live modular scene " + String(id))
	_expect(layout.resource_path != old.resource_path and layout.schema_version == old.schema_version, "original layout version " + String(id))
	var active := 0
	var expected := 0
	var flags := root.get_node("GameState").get("flags") as Dictionary
	var quests := root.get_node("QuestManager")
	for row: Dictionary in layout.visual_objects:
		var require_flag := String(row.get("require_flag", ""))
		var hide_flag := String(row.get("hide_flag", ""))
		var require_quest := StringName(row.get("require_quest_active", ""))
		if not require_flag.is_empty() and not bool(flags.get(require_flag, false)): continue
		if not hide_flag.is_empty() and bool(flags.get(hide_flag, false)): continue
		if require_quest != &"" and not bool(quests.call("is_active", require_quest)): continue
		expected += 1
		var layer := (field.get("_actor_layer") if row.get("sort_by_feet",false) else field.get("_visual_layer")) as Node
		var node := layer.get_node_or_null("SceneObject_" + String(row.id)) as Sprite2D
		if node != null and node.texture != null and node.visible: active += 1
	_expect(active == expected, "all eligible art mounts " + str([id,active,expected]))
	for uv: Vector2 in spots:
		_expect(bool(field.call("_spawn_has_foot_clearance",scene,uv)), "safe " + str([id,uv]))
	for probe: Dictionary in layout.blocked_probes:
		_expect(not bool(field.call("_spawn_has_foot_clearance",scene,probe.pos)), "blocked " + str([id,probe.id]))

func _run() -> void:
	if not _expect(_paused_checkpoints,"private checkpoints suspended"):
		_done()
		return
	_router = root.get_node("SceneRouter")
	var flags := root.get_node("GameState").get("flags") as Dictionary
	for flag: String in ["chapter4_complete","chapter5_started","ch5_relief_road_cleared","seen_ch5_relief_road_intro","seen_ch5_grain_convoy_intro","seen_ch5_snow_pass_intro","seen_ch5_abandoned_mine_intro","seen_ch5_false_banner_outpost_intro"]:
		flags[flag] = true
	if not _expect(bool(_router.call("go_field_smart",ROAD,Vector2(.89,.11))),"official relief road setup"):
		_done()
		return
	var road: Node = await _ready_field(ROAD)
	if road == null:
		_done()
		return
	var camp: Node = await _leg(road,CAMP)
	if camp == null:
		_done()
		return
	_map(camp,CAMP,[Vector2(.15,.82),Vector2(.56,.53),Vector2(.86,.12)])
	_locked(camp,PASS,"前往雪岭关")
	_expect(_area_for_action(camp,"dialog:ch5_grain_convoy_battle") != null,"camp battle remains before victory")
	await _place(camp,Vector2(.49,.63))
	await _capture(camp,"camp")
	await _flag(&"ch5_grain_convoy_saved")
	if not await _inspect(camp,&"ch5_false_banner_evidence","ch5_false_banner_cloth_found"):
		_done()
		return
	var snowy: Node = await _leg(camp,PASS)
	if snowy == null:
		_done()
		return
	_map(snowy,PASS,[Vector2(.25,.88),Vector2(.52,.51),Vector2(.84,.13)])
	_locked(snowy,MINE,"进入废弃矿道")
	_expect(_area_for_action(snowy,"dialog:ch5_snow_pass_battle") != null,"pass battle remains before victory")
	await _place(snowy,Vector2(.52,.51))
	await _capture(snowy,"snow_pass")
	await _flag(&"ch5_snow_pass_cleared")
	var mine: Node = await _leg(snowy,MINE)
	if mine == null:
		_done()
		return
	_map(mine,MINE,[Vector2(.49,.88),Vector2(.50,.47),Vector2(.82,.18)])
	_locked(mine,OUTPOST,"沿北侧旧索道前往伪旗营地")
	_expect(_area_for_action(mine,"dialog:ch5_mine_hunter_battle") != null,"mine battle remains before victory")
	await _place(mine,Vector2(.50,.51))
	await _capture(mine,"mine")
	await _flag(&"ch5_mine_hunters_defeated")
	if not await _inspect(mine,&"ch5_mine_survivor_testimony","ch5_old_case_survivor_heard"):
		_done()
		return
	root.get_node("QuestManager").call("accept",&"q_ch5_main_05_false_banner_outpost")
	var outpost: Node = await _leg(mine,OUTPOST)
	if outpost == null:
		_done()
		return
	_map(outpost,OUTPOST,[Vector2(.50,.88),Vector2(.50,.56),Vector2(.51,.22)])
	await _place(outpost,Vector2(.48,.61))
	await _capture(outpost,"outpost")
	if not await _inspect(outpost,&"ch5_false_banner_poisoned_weapons","ch5_poisoned_weapon_found"):
		_done()
		return
	var captain := false
	for actor: NPCNode in outpost.get("_npc_nodes"):
		if actor.npc_id == "ch5_false_banner_captain": captain = true
	_expect(captain,"captain appears after the original poisoned-weapon clue")
	mine = await _leg(outpost,MINE)
	if mine == null:
		_done()
		return
	snowy = await _leg(mine,PASS)
	if snowy == null:
		_done()
		return
	camp = await _leg(snowy,CAMP)
	if camp == null:
		_done()
		return
	road = await _leg(camp,ROAD)
	if road != null:
		_expect((_feet(road)/Vector2(road.get("_world_size"))).distance_to(Vector2(.89,.11)) < .003,"returns to paired relief road entrance")
	_done()

