extends "res://tests/test_world_map_v14_production_20261002.gd"

# Producer must separately authorize this real headless Field diagnostic.
# It is neither whole-map QA nor a visual/canonical activation approval.
func _run() -> void:
	qa_scope = "FOCUSED_RETURN_PLANNER_ALPHA_NOT_FULL_MAP"
	active_id = CANDIDATE_ID; active_path = CANDIDATE_PATH; candidate_stage = true
	phase_output = OUTPUT_DIR + "focused_return_planner_alpha_" + str(int(Time.get_unix_time_from_system())) + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(phase_output))
	player_saves_before = _actual_player_saves()
	source_contract = _json(SOURCE_PATH)
	manifest = _json(MANIFEST_PATH)
	world = load(CANDIDATE_PATH) as SceneScript
	_fixture_new_game()
	var portals: Dictionary = {}
	for p: Dictionary in world.map_layout.portals: portals[String(p.id)] = p
	if not await _open_world(portals.bailu_ferry.pos): _finish(); return
	_collect_runtime()
	var bailu_foot := _point(portals.bailu_ferry.pos) * WORLD_SIZE
	_check(_foot_clear(bailu_foot),"Bailu candidate gateway complete-foot fixture")
	var zone: Node2D = runtime_portals.get("openworld_bailu_ferry")
	_check(zone != null and bool(zone.get("_in_range")),"actual Bailu world portal overlap before key input")
	await _key(KEY_SPACE)
	_check(await _wait_field(&"openworld_bailu_ferry"),"real Space enters unchanged ordinary Bailu destination")
	await _normal_dialog_finish()
	var blocked_probe := Vector2(1256,1256)
	for hit: Dictionary in _planning_collisions(blocked_probe):
		var collider := hit.get("collider") as Node2D
		print("[FocusedPhysical] failed_old_waypoint=",blocked_probe," collider=",collider.get_path() if collider != null else hit," global_origin=",collider.global_position if collider != null else Vector2.ZERO)
		if collider != null:
			for child in collider.get_children():
				if child is CollisionShape2D:
					print("[FocusedPhysicalShape] shape=",child.shape," rect=",child.shape.get_rect()," transform=",child.global_transform)
	var returned := await _return_through_actual_exit(&"openworld_bailu_ferry")
	_check(returned,"real complete-foot movement and Mouse exit returns after limited inn fix")
	if not returned:
		print("[FocusedRecovery] restore candidate ONLY to collect remaining independent evidence; return remains FAIL")
		await _open_world(portals.bailu_ferry.pos)
	if await _wait_field(active_id):
		var player: Node2D = field.get("_player")
		if returned: _check(player.position.distance_to(bailu_foot) < .03,"Bailu actual paired return preserves precise current world feet")
		world_pathfinder = _build_pathfinder()
		for id: String in ["zhuwei_village","qinghe_town"]:
			var target := _point(portals[id].pos) * WORLD_SIZE
			var path := _plan_to(target,world_pathfinder)
			var bad := 0
			for point in _dense_polyline(path):
				if not _foot_clear(point): bad += 1
			_check(path.size() >= 2 and bad == 0,"alternate all-edge <=4px complete-foot planner route to "+id)
			print("[FocusedPlanning] id=",id," path_nodes=",path.size()," bad=",bad," rejected_edges=",world_pathfinder.rejected_edges," STATIC_PLAN_NOT_INPUT_COMPLETION")
	_collect_runtime()
	for d: Dictionary in world.map_layout.visual_objects:
		var id := String(d.get("id",""))
		if id not in ["original_grove_11","native_rock_foothill","native_cliff_south"] or not runtime_props.has(id): continue
		var prop: Sprite2D = runtime_props[id]
		for front in [false,true]:
			var station := _prop_alpha_station(d,prop,front)
			print("[FocusedAlphaCause] id=",id," front=",front," station=",station," finite_scan_not_exhaustive_absence_proof")
	_finish()
