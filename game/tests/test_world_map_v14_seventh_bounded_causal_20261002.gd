extends "res://tests/test_world_map_v14_sixth_oracle_same_band_20261002.gd"

## Producer-authorized bounded cause evidence, not a complete-map acceptance.
## Observation never forces refresh. Explicit behind ghost verification below
## reproduces the original bounded test's action before normal input movement.
var causal_records: Array = []

func _tree_snapshot(id: String, stage: String, target: Vector2) -> Dictionary:
	var player: Node2D = field.get("_player")
	var prop: Sprite2D = runtime_props[id]
	var meta := _json(ART_DIR + "entities/" + id + ".json")
	var base := _point(meta.get("world_foot")).y
	var container: Node2D = field.get("world_container")
	var row := {"id":id,"stage":stage,"position_px":[player.position.x,player.position.y],"target_px":[target.x,target.y],"distance_to_target":player.position.distance_to(target),"actor_actual_visual_foot":float(player.call("get_depth_sort_y")),"prop_actual_global_foot":container.to_global(Vector2(0,base)).y,"actor_z":player.z_index,"prop_z":prop.z_index,"actor_sibling":player.get_index(),"prop_sibling":prop.get_index(),"raw_foot_reason":_raw_foot_reason(world,player.position / WORLD_SIZE),"physics_collisions":_planning_collisions(player.position).size(),"current_frame_hits":_actual_actor_alpha_intersection(prop),"front_effective_order":_depth_order(player,prop,true),"depth_snapshot":field.call("get_v14_depth_order_debug"),"modular_debug":field.call("get_v14_modular_overlap_debug")}
	# Image/Texture references are not serializable cause evidence.
	row.modular_debug.erase("mask_image")
	row.modular_debug.erase("mask_texture")
	causal_records.append(row)
	print("[SeventhTreeCause] ",JSON.stringify(row))
	return row

func _tree_order_cause(id: String, x: float) -> void:
	var meta := _json(ART_DIR + "entities/" + id + ".json")
	var base := _point(meta.get("world_foot")).y
	var player: Node2D = field.get("_player")
	var container: Node2D = field.get("world_container")
	_set_idle(Vector2.DOWN)
	var offset := container.to_local(Vector2(player.global_position.x,float(player.call("get_depth_sort_y")))).y - player.position.y
	var before := Vector2(x,base - 1 - offset)
	var after := Vector2(x,base + 1 - offset)
	_check(_planner_clear(before) and _planner_clear(after),"original failed same-band pair remains complete-foot and real-body clear: " + id)
	if not await _place_fixture(before): return
	_set_idle(Vector2.DOWN)
	await process_frame
	_tree_snapshot(id,"behind_original_bounded_assert_timing",before)
	await _ghost_mask_check("causal reproduce bounded behind ghost before drive: " + id)
	_tree_snapshot(id,"behind_after_original_ghost_check_action",before)
	_check(await _drive_to(after),"original failed pair is crossed with normal Player input: " + id)
	_set_idle(Vector2.DOWN)
	await process_frame
	_tree_snapshot(id,"front_original_assert_timing",after)
	await physics_frame
	_tree_snapshot(id,"front_next_physics_boundary_without_forced_refresh",after)
	await process_frame
	await process_frame
	var settled := _tree_snapshot(id,"front_after_two_more_normal_process_frames",after)
	_check(settled.distance_to_target <= .3 and float(settled.actor_actual_visual_foot) > float(settled.prop_actual_global_foot) and int(settled.actor_z) == int(settled.prop_z) and int(settled.current_frame_hits) >= 100,"settled front truly crosses same-band footline with strong current alpha: " + id)
	_check(bool(settled.front_effective_order),"actual normal late-process sibling order is front, without test-forced refresh: " + id)

func _gentle_shoe_cause(point: Vector2, expected_gentle: bool = true) -> void:
	# Recover exact saved projected values; printed three-decimal logs are not
	# an independent replacement for the original failed floating-point ray.
	var geometry := _json(ART_DIR+"geometry.json")
	for group: Array in [geometry.get("steep_examples",[]),geometry.get("gentle_examples",[])]:
		for probe: Dictionary in group:
			var exact := _point(probe.get("projected_point"))
			if exact.distance_to(point)<.01: point=exact
	var samples: Array[Vector2] = [point]
	for index in 16:
		var angle := TAU * index / 16.0
		samples.append(point + Vector2(cos(angle) * 10,sin(angle) * 6))
	var shoes: Array = []
	var walk: Image = native_images.walk
	var land: Image = native_images.land
	var selector := _read_image(String(geometry.get("topology_selector_path", "")))
	var raw_walk := _read_image(String(manifest.get("raw_walk_path", "")))
	_check(selector != null and raw_walk != null,"slope cause reads original source selector and pre-support raw walk")
	for index in samples.size():
		var sample := samples[index]
		var pixel := Vector2i(roundi(sample.x / WORLD_SIZE.x * (walk.get_width()-1)),roundi(sample.y / WORLD_SIZE.y * (walk.get_height()-1)))
		var visible := _visible_terrain_triangle(sample)
		var pixel_visible := _visible_terrain_triangle(Vector2(pixel) + Vector2(.5,.5))
		var selected: Dictionary = {}
		if selector != null and not pixel_visible.is_empty():
			var source_point: Vector2 = pixel_visible.source
			var selector_pixel := Vector2i(floori(source_point.x/WORLD_SIZE.x*selector.get_width()),floori(source_point.y/WORLD_SIZE.y*selector.get_height()))
			var selector_source := Vector2(selector_pixel)*WORLD_SIZE/Vector2(selector.get_size())
			var selector_triangle := _actual_terrain_triangle(selector_source)
			selected={"pixel":selector_pixel,"source_px":selector_source,"original_selector_rgba":selector.get_pixelv(selector_pixel),"independent_selected_mesh_triangle":selector_triangle,"source_shader_expected_walk_b":selector.get_pixelv(selector_pixel).b if float(pixel_visible.height)>-.025 else 0.,"nearest_visible_mesh_is_steep":float(pixel_visible.gradient)>.72}
		shoes.append({"sample_index":index,"sample_px":[sample.x,sample.y],"actual_oracle_raw_pixel":[pixel.x,pixel.y],"raw_walk":walk.get_pixelv(pixel).r,"pre_support_raw_walk":raw_walk.get_pixelv(pixel).r if raw_walk!=null else -1.,"raw_land":land.get_pixelv(pixel).r,"sample_nearest_triangle":visible,"raster_pixel_center_nearest_triangle":pixel_visible,"actual_nearest_2px_selector":selected})
	var center := _visible_terrain_triangle(point)
	var row := {"kind":"original_gentle_fullfoot_failure" if expected_gentle else "steep_raw_white_pixel_cause_not_waived","point_px":[point.x,point.y],"center_visible":center,"complete_foot_reason":_raw_foot_reason(world,point/WORLD_SIZE),"seventeen_samples":shoes,"frozen_selector_shader_source":"res://build/world_map_v14_seventh_executed_helper.gd","frozen_selector_shader_sha":FileAccess.get_sha256("res://build/world_map_v14_seventh_executed_helper.gd")}
	causal_records.append(row)
	print("[SeventhGentleShoes] ",JSON.stringify(row))
	_check(not center.is_empty() and ((float(center.get("gradient",INF)) < .72) == expected_gentle),"original center ray property is retained, not substituted for 17 shoe coverage")
	if not expected_gentle:
		var anomaly: Dictionary = shoes[9]
		_check(float(anomaly.raster_pixel_center_nearest_triangle.get("gradient",0))>.72 and float(anomaly.raw_walk)>.5,"original raw-white steep shoe is reproduced as an implementation-risk finding, not acceptance PASS")
	_check(not _foot_clear(point),"original full-foot failure is reproduced rather than removed")

func _npc_pair_alpha(a: Sprite2D, b: Sprite2D) -> int:
	var source := a.texture.get_image()
	var target := b.texture.get_image()
	if source.is_compressed(): source.decompress()
	if target.is_compressed(): target.decompress()
	var frame := _sprite_frame(a,source)
	var hits := 0
	for y in frame.size.y:
		for x in frame.size.x:
			if source.get_pixelv(frame.position + Vector2i(x,y)).a <= .12: continue
			var uv := Vector2(x+.5,y+.5) / Vector2(frame.size)
			if a.flip_h: uv.x = 1-uv.x
			if a.flip_v: uv.y = 1-uv.y
			var local := b.to_local(a.to_global(a.get_rect().position + uv*a.get_rect().size))
			if b.get_rect().has_point(local) and _prop_sample_alpha(b,target,(local-b.get_rect().position)/b.get_rect().size) > .12: hits += 1
	return hits

func _npc_real_body_polygon(npc: NPCNode) -> PackedVector2Array:
	var body: Node = npc.get("_body_collider")
	if not is_instance_valid(body) or not body is StaticBody2D: return PackedVector2Array()
	for child: Node in body.get_children():
		if not child is CollisionShape2D: continue
		var shape := child as CollisionShape2D
		if not shape.shape is RectangleShape2D or shape.disabled: continue
		var half := (shape.shape as RectangleShape2D).size*.5
		return PackedVector2Array([shape.to_global(Vector2(-half.x,-half.y)),shape.to_global(Vector2(half.x,-half.y)),shape.to_global(half),shape.to_global(Vector2(-half.x,half.y))])
	return PackedVector2Array()

func _normal_patrol_cause() -> void:
	var container: Node2D = field.get("world_container")
	var center := Vector2(INF,INF)
	for route: Dictionary in source_contract.get("routes",[]):
		for value: Variant in route.get("points_px",[]):
			var point := _point(value)
			if point.y < 2160 or point.y > 2900: continue
			var global_point := container.to_global(point)
			point = container.to_local(Vector2(global_point.x,floor(global_point.y/8)*8+4))
			var clear := true
			for offset: Vector2 in [Vector2.ZERO,Vector2(20,-3),Vector2(20,1),Vector2(64,0),Vector2(128,0)]:
				if not _planner_clear(point+offset): clear = false
			if clear: center = point; break
		if center.is_finite(): break
	_check(center.is_finite(),"normal NPC patrol fixture owns legal full-foot southern space")
	if not center.is_finite(): return
	_check(await _place_fixture(center+Vector2(128,0)),"real Player stays outside unchanged NPC bodies")
	var entries: Array = []
	for index in 3:
		entries.append({"npc_id":"qa_seventh_causal_npc_%d"%index,"npc_name":"QA隔离角色","sprite_path":"res://art/characters/npc_zhuwei_gate_guard_idle_down_25d_4f_v2_runtime.png","pos":(center+Vector2(20 if index==2 else index*64,-1 if index==2 else 0))/WORLD_SIZE,"scale":.65,"movement_mode":"patrol" if index==2 else "idle","patrol_axis":Vector2.DOWN,"patrol_distance":2.,"patrol_speed":18.})
	field.call("_spawn_npcs",entries)
	await physics_frame
	await process_frame
	var nodes: Dictionary = {}
	for child: Node in field.get("_actor_layer").get_children():
		if child is NPCNode and String(child.npc_id).begins_with("qa_seventh_causal_npc_"): nodes[child.npc_id] = child
	_check(nodes.size()==3,"real normal-spawn idle ties and moving patrol NPC exist")
	if nodes.size()!=3: return
	var idle: NPCNode = nodes.qa_seventh_causal_npc_0
	var tie: NPCNode = nodes.qa_seventh_causal_npc_1
	var patrol: NPCNode = nodes.qa_seventh_causal_npc_2
	var behind := 0
	var front := 0
	var frames: Dictionary = {}
	for tick in 72:
		# SceneTree process_frame resumes BEFORE node processes. The next
		# physics boundary observes completed previous normal process stages.
		await process_frame
		await physics_frame
		var idle_foot := idle.get_depth_sort_y()
		var patrol_foot := patrol.get_depth_sort_y()
		var hits := _npc_pair_alpha(patrol.sprite,idle.sprite)
		frames[patrol.sprite.frame]=true
		var same_band := idle.z_index==patrol.z_index
		var correct := patrol.get_index()>idle.get_index() if patrol_foot>idle_foot else patrol.get_index()<idle.get_index()
		if not same_band: correct = patrol.z_index>idle.z_index if patrol_foot>idle_foot else patrol.z_index<idle.z_index
		var idle_polygon := _npc_real_body_polygon(idle)
		var patrol_polygon := _npc_real_body_polygon(patrol)
		var body_clear := idle_polygon.size()==4 and patrol_polygon.size()==4 and Geometry2D.intersect_polygons(idle_polygon,patrol_polygon).is_empty()
		_check(body_clear,"normal NPC current-body Rectangle footprints do not overlap while visible bodies cross footlines")
		_check(_foot_clear(patrol.position) and int(patrol.get_meta("depth_band_max",-1))==512 and patrol.get("_body_collider") is StaticBody2D,"normal animated patrol retains fullfoot/source depth/real physics")
		_check(idle.get_depth_sort_y()==tie.get_depth_sort_y() and idle.get_index()<tie.get_index(),"unchanged idle exact-foot tie stays stable while another NPC moves")
		if same_band and hits>0 and absf(patrol_foot-idle_foot)>.01:
			_check(correct,"completed normal process stage sorts real current-frame overlapping patrol NPC by exact foot")
			if patrol_foot>idle_foot: front += 1
			else: behind += 1
		causal_records.append({"kind":"normal_patrol","tick":tick,"idle_foot":idle_foot,"patrol_foot":patrol_foot,"same_band":same_band,"idle_index":idle.get_index(),"patrol_index":patrol.get_index(),"current_frame":patrol.sprite.frame,"current_alpha_hits":hits,"correct_order":correct,"body_rectangles_clear":body_clear,"idle_position_px":[idle.position.x,idle.position.y],"patrol_position_px":[patrol.position.x,patrol.position.y]})
	_check(front>0 and behind>0,"normal patrol actually crosses an overlapping same-band actor footline in both directions")
	_check(frames.size()==patrol.sprite.hframes,"all actual current animation cells were observed, not a frozen frame0 patrol substitute")
	for node: Node in nodes.values(): node.queue_free()
	await physics_frame
	await process_frame
	await process_frame

func _ordinary_cleanup_cause() -> void:
	root.get_node("SceneRouter").call("go_field_smart",&"linxi_village_scrollmap")
	_check(await _wait_field(&"linxi_village_scrollmap"),"normal ordinary destination loads after temporary real NPC cleanup")
	await _normal_dialog_finish()
	var player: Node2D = field.get("_player")
	_check(int(player.get_meta("depth_band_max",-1))==255 and field.get("_v14_modular_overlap")==null and not is_instance_valid(field.get("_v14_late_depth_refresh")),"ordinary scene restores255 and owns no v14 late-depth node/helper")
	for node: Node in field.get("_npc_nodes"):
		if is_instance_valid(node): _check(int(node.get_meta("depth_band_max",-1))==255,"normal ordinary NPC does not inherit candidate512")
	await process_frame
	await process_frame

func _run() -> void:
	candidate_stage = true
	active_id = CANDIDATE_ID
	active_path = CANDIDATE_PATH
	qa_scope = "SEVENTH_BOUNDED_CAUSAL_DIAGNOSTIC_NOT_FULL_MAP_NOT_VISUAL"
	phase_output = OUTPUT_DIR + "seventh_causal_" + str(int(Time.get_unix_time_from_system())) + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(phase_output))
	player_saves_before = _actual_player_saves()
	manifest = _json(MANIFEST_PATH)
	source_contract = _json(SOURCE_PATH)
	world = load(active_path) as SceneScript
	_check(DisplayServer.get_name()=="headless" and int(manifest.get("capture_iteration",-1))==7 and world!=null,"bounded causal diagnosis requires frozen completed iteration7 candidate")
	if failed>0 or not _load_actual_geometry_only(): _finish(); return
	for name: String in ["land","walk"]: native_images[name] = _read_image(ART_DIR+name+".png")
	_fixture_new_game()
	if not await _open_world(world.player_spawn): _finish(); return
	_collect_runtime()
	for point: Vector2 in [Vector2(1848,263.6868),Vector2(1680,203.3958),Vector2(1776,202.0491)]: _gentle_shoe_cause(point)
	_gentle_shoe_cause(Vector2(1656,262.8514),false)
	await _tree_order_cause("native_tree_000",691)
	await _tree_order_cause("native_tree_005",1139)
	await _normal_patrol_cause()
	await _ordinary_cleanup_cause()
	var file := FileAccess.open(phase_output+"causal_evidence.json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify({"scope":qa_scope,"capture_iteration":7,"records":causal_records,"actual_helper_sha":FileAccess.get_sha256("res://scripts/world/v14_modular_overlap.gd"),"actual_field_sha":FileAccess.get_sha256("res://scripts/field/field_walkable_controller.gd"),"main_sha":FileAccess.get_sha256("res://tests/test_world_map_v14_production_20261002.gd"),"fixture_sha":FileAccess.get_sha256(get_script().resource_path)},"\t"))
	_finish()
