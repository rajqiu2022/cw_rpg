extends RefCounted
## NEW joint sibling from readonly v15_normal_npc_depth_probe.gd; no historical result reuse.
## Test-owned ordinary NPC entries go through unchanged production spawning,
## patrol, animation, physics, depth registration and late idle refresh.
const GUARD := "res://art/characters/npc_zhuwei_gate_guard_idle_down_25d_4f_v2_runtime.png"
const PREFIX := "qa_v15_normal_patrol_"
var tree: SceneTree
var driver: RefCounted
var alpha: RefCounted
var report_check: Callable
var clear_foot: Callable
var clear_body: Callable
var clear_segment: Callable

func configure(owner: SceneTree, input: RefCounted, independent_alpha: RefCounted, check: Callable, independent_fullfoot: Callable, actual_body_clear: Callable, independent_segment: Callable) -> void:
	tree = owner
	driver = input
	alpha = independent_alpha
	report_check = check
	clear_foot = independent_fullfoot
	clear_body = actual_body_clear
	clear_segment = independent_segment

func _check(ok: bool, label: String) -> void:
	if report_check.is_valid(): report_check.call(ok, label)

func _clear(point: Vector2) -> bool:
	return bool(clear_foot.call(point)) and bool(clear_body.call(point))

func run(field: Node, world: SceneScript) -> Dictionary:
	var evidence: Dictionary = {"scope": "NORMAL_SPAWNED_NPC_PATROL_CURRENT_FRAMES_NOT_VISUAL_APPROVAL", "version": 15, "front_count": 0, "behind_count": 0, "records": []}
	_check(is_instance_valid(field) and tree.current_scene == field and world != null and world.scene_id in [&"world_map_jianghu_v15",&"world_map_jianghu"] and world.map_layout != null and world.map_layout.schema_version == 15, "normal NPC depth probe uses live candidate production Field")
	if not is_instance_valid(field) or world == null: return evidence
	var container: Node2D = field.get("world_container") as Node2D
	var player: Node2D = field.get("_player") as Node2D
	var size: Vector2 = field.get("_world_size")
	_check(container != null and player != null and size == Vector2(12288, 8192), "normal NPC fixture has actual new world coordinate domain")
	if container == null or player == null: return evidence
	var anchor := Vector2(INF, INF)
	for route: Dictionary in world.map_layout.travel_routes:
		var points: PackedVector2Array = route.get("points", PackedVector2Array())
		for normalized: Vector2 in points:
			var point: Vector2 = normalized * size
			if point.y < 4352 or point.y > size.y - 192: continue
			var global: Vector2 = container.to_global(point)
			point = container.to_local(Vector2(global.x, floor(global.y / 8) * 8 + 4))
			var legal := true
			for offset: Vector2 in [Vector2.ZERO, Vector2(20, -3), Vector2(20, 1), Vector2(64, 0), Vector2(128, 0)]:
				if not _clear(point + offset): legal = false
			if not bool((clear_segment.call(point + Vector2(20, -3), point + Vector2(20, 1)) as Dictionary).get("clear", false)): legal = false
			if legal:
				anchor = point
				break
		if anchor.is_finite(): break
	_check(anchor.is_finite(), "genuine southern current road has complete patrol domain and real unmodified body clearance")
	if not anchor.is_finite(): return evidence
	var path: PackedVector2Array = driver.call("plan", player.position, anchor + Vector2(128, 0), size, Callable(self, "_clear"), clear_segment)
	_check(path.size() >= 2, "normal player reaches patrol fixture by independently full-foot legal path")
	if path.size() < 2: return evidence
	var moved: Dictionary = await driver.call("follow", field, path, Callable(self, "_clear"), clear_segment)
	_check(bool(moved.get("ok", false)), "actual input parks player outside all unchanged NPC bodies")
	if not bool(moved.get("ok", false)): return evidence
	var entries: Array[Dictionary] = []
	for index in 3:
		entries.append({"npc_id": PREFIX + str(index), "npc_name": "QA隔离角色", "sprite_path": GUARD, "pos": (anchor + Vector2(20 if index == 2 else index * 64, -1 if index == 2 else 0)) / size, "scale": .65, "movement_mode": "patrol" if index == 2 else "idle", "patrol_axis": Vector2.DOWN, "patrol_distance": 2.0, "patrol_speed": 18.0})
	field.call("_spawn_npcs", entries)
	await driver.call("completed_actor_stage")
	var layer: Node = field.get("_actor_layer") as Node
	var nodes: Dictionary = {}
	if layer != null:
		for child: Node in layer.get_children():
			if child is NPCNode and String(child.npc_id).begins_with(PREFIX): nodes[child.npc_id] = child
	_check(nodes.size() == 3, "normal spawning creates all three real NPCs without test depth metadata")
	if nodes.size() != 3:
		for child: Node in nodes.values(): child.queue_free()
		return evidence
	var idle: NPCNode = nodes[PREFIX + "0"]
	var tie: NPCNode = nodes[PREFIX + "1"]
	var patrol: NPCNode = nodes[PREFIX + "2"]
	var front := 0
	var behind := 0
	var frames: Dictionary = {}
	var rows: Array[Dictionary] = []
	for tick in 72:
		await driver.call("completed_actor_stage")
		var idle_y: float = idle.get_depth_sort_y()
		var patrol_y: float = patrol.get_depth_sort_y()
		var hit: Dictionary = alpha.call("strong_intersection", patrol.sprite, idle.sprite)
		frames[patrol.sprite.frame] = true
		var same_band: bool = idle.z_index == patrol.z_index
		var front_relation: bool = patrol_y > idle_y
		var actual_front: bool = alpha.call("actual_in_front", patrol, idle)
		var first: PackedVector2Array = _body_polygon(idle)
		var second: PackedVector2Array = _body_polygon(patrol)
		var disjoint: bool = first.size() == 4 and second.size() == 4 and Geometry2D.intersect_polygons(first, second).is_empty()
		_check(disjoint, "patrol actual Rectangle bodies stay physically disjoint while their actual alpha overlaps")
		_check(bool(clear_foot.call(patrol.position)) and int(patrol.get_meta("depth_band_max", -1)) == 1024, "normal registered patrol retains real 17-foot and1024 depth metadata")
		_check(idle_y == tie.get_depth_sort_y() and idle.get_index() < tie.get_index(), "equal exact-foot NPCs retain normal stable insertion ordinal")
		_check(idle.z_index == clampi(floori(idle_y / 8), 0, 1024) and patrol.z_index == clampi(floori(patrol_y / 8), 0, 1024) and idle.z_index > 512 and patrol.z_index > 512, "each actual southern NPC foot independently determines an unclamped >512 band")
		if same_band and int(hit.get("hits", 0)) > 0 and absf(patrol_y - idle_y) > .01:
			_check(actual_front == front_relation, "completed normal idle stage draws current-frame overlapping patrol by actual feet")
			if front_relation: front += 1
			else: behind += 1
		rows.append({"tick": tick, "idle_foot_y": idle_y, "patrol_foot_y": patrol_y, "idle_band": idle.z_index, "patrol_band": patrol.z_index, "same_band": same_band, "idle_sibling": idle.get_index(), "patrol_sibling": patrol.get_index(), "current_frame": patrol.sprite.frame, "current_frame_alpha": hit, "correct_order": actual_front == front_relation, "bodies_disjoint": disjoint})
	_check(front > 0 and behind > 0, "real normal patrol crosses both directions with current-frame alpha and same-band overlap")
	_check(frames.size() == patrol.sprite.hframes and patrol.sprite.hframes == 4, "all four genuine normal NPC current animation cells observed")
	var references: Array[WeakRef] = []
	for node: Node in nodes.values():
		references.append(weakref(node))
		node.queue_free()
	nodes.clear()
	idle = null
	tie = null
	patrol = null
	for settle in 4: await driver.call("completed_actor_stage")
	for reference: WeakRef in references: _check(reference.get_ref() == null, "test-owned normal NPC is actually freed after natural stages")
	for row: Dictionary in field.call("get_v14_depth_order_debug"):
		_check(not String(row.get("id", "")).begins_with(PREFIX), "real late depth refresh has no freed patrol registration")
	evidence["anchor_px"] = [anchor.x, anchor.y]
	evidence["sprite_path"] = GUARD
	evidence["sprite_sha256"] = FileAccess.get_sha256(GUARD)
	evidence.front_count = front
	evidence.behind_count = behind
	evidence.records = rows
	evidence["frames"] = frames.keys()
	evidence["actual_player_movement"] = moved
	return evidence

func _body_polygon(npc: NPCNode) -> PackedVector2Array:
	var body: Variant = npc.get("_body_collider")
	if not is_instance_valid(body) or not body is StaticBody2D: return PackedVector2Array()
	for child: Node in body.get_children():
		if not child is CollisionShape2D: continue
		var shape: CollisionShape2D = child as CollisionShape2D
		if not shape.shape is RectangleShape2D or shape.disabled: continue
		var half: Vector2 = (shape.shape as RectangleShape2D).size * .5
		return PackedVector2Array([shape.to_global(-half), shape.to_global(Vector2(half.x, -half.y)), shape.to_global(half), shape.to_global(Vector2(-half.x, half.y))])
	return PackedVector2Array()

func release() -> void:
	tree = null
	driver = null
	alpha = null
	report_check = Callable()
	clear_foot = Callable()
	clear_body = Callable()
	clear_segment = Callable()


