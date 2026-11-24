extends "res://scripts/dev/run_luoyang_layered_interior_v1.gd"
## NEW bounded read-only Physics2D cause; original 515/5 source unchanged.
const DRIVER := preload("res://tests/helpers/v15_input_driver.gd")
var failed := 0
var records: Array[Dictionary] = []
var input_driver: RefCounted

func _start() -> void:
	var directory: String = "res://build/luoyang_layered_interior_v1_qa/physics_cause_%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_msec()]
	if DirAccess.dir_exists_absolute(directory) or DirAccess.make_dir_recursive_absolute(directory) != OK:
		quit(1)
		return
	if not await start_preview() or not is_instance_valid(field) or not is_instance_valid(field.get("_player")):
		print("[LuoyangPhysicsCause] real Field/Player unavailable")
		quit(1)
		return
	input_driver = DRIVER.new()
	input_driver.configure(self)
	_snapshot("fresh_ready")
	await input_driver.completed_actor_stage()
	_snapshot("completed_natural_stage")
	# Mimic the original loop's preceding actual cardinal input, not teleport.
	var upper: Dictionary = await input_driver.drive(field, Vector2(1536, 1120), _source_and_physics_clear)
	var west: Dictionary = await input_driver.drive(field, Vector2(1160, 1120), _source_and_physics_clear) if bool(upper.get("ok", false)) else {"ok": false}
	if not bool(upper.get("ok", false)) or not bool(west.get("ok", false)): failed += 1
	_snapshot("original_loop_edge_start")
	await input_driver.completed_actor_stage()
	_snapshot("original_loop_edge_start_after_natural_stage")
	var output: Dictionary = {"scope": "LIMITED_READ_ONLY_PHYSICS_CAUSE_NOT_ACCEPTANCE", "executed_script": get_script().resource_path, "script_sha256": FileAccess.get_sha256(get_script().resource_path), "manifest_sha256": FileAccess.get_sha256(CONTRACT.MANIFEST_PATH), "source_field_sha256": FileAccess.get_sha256(FIELD_PATH), "runner_sha256": FileAccess.get_sha256("res://scripts/dev/run_luoyang_layered_interior_v1.gd"), "engine_pid": OS.get_process_id(), "records": records, "real_input_prefix": [upper, west], "protected_before": before, "protected_after": protected_state(), "art_approved": false, "diagnostic_failures": failed}
	if protected_state() != before or not contract.canonical_unchanged(): failed += 1
	output["protected_unchanged"] = protected_state() == before
	var path: String = directory + "physics_cause.json"
	var encoded: String = JSON.stringify(output, "\t")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failed += 1
	else:
		file.store_string(encoded)
		file.flush()
		if file.get_error() != OK: failed += 1
		file.close()
		if FileAccess.get_file_as_string(path) != encoded or JSON.parse_string(FileAccess.get_file_as_string(path)) != JSON.parse_string(encoded): failed += 1
	restore_preview_state()
	input_driver.release()
	input_driver = null
	current_scene = null
	field.queue_free()
	field = null
	contract = null
	for tick in 8:
		await process_frame
		await physics_frame
	print("[LuoyangPhysicsCause] %d snapshots / %d diagnostic failures; %s" % [records.size(), failed, path])
	quit(0 if failed == 0 else 1)

func _source_and_physics_clear(p: Vector2) -> bool:
	return contract.safe_body(p) and _query(p).is_empty()

func _query(p: Vector2) -> Array[Dictionary]:
	var player: CharacterBody2D = field.get("_player") as CharacterBody2D
	var shape: CollisionShape2D = player.get_node("CollisionShape2D") as CollisionShape2D
	var container: Node2D = field.get("world_container") as Node2D
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape.shape
	params.transform = shape.global_transform
	params.transform.origin += container.to_global(p) - player.global_position
	params.collision_mask = player.collision_mask
	params.exclude = [player.get_rid()]
	params.collide_with_areas = false
	var hits: Array[Dictionary] = []
	for hit: Dictionary in player.get_world_2d().direct_space_state.intersect_shape(params, 32):
		var collider: Node = hit.get("collider") as Node
		var entry: Dictionary = {"collider_path": str(collider.get_path()) if is_instance_valid(collider) else "FREED", "collider_id": hit.get("collider_id"), "rid": str(hit.get("rid")), "shape_index": hit.get("shape"), "query_transform": _transform(params.transform)}
		if collider is Node2D:
			entry["collider_global_transform"] = _transform((collider as Node2D).global_transform)
			entry["physical_children"] = _physical_children(collider)
		hits.append(entry)
	return hits

func _snapshot(label: String) -> void:
	var player: Node2D = field.get("_player") as Node2D
	var shape: CollisionShape2D = player.get_node("CollisionShape2D") as CollisionShape2D
	var container: Node2D = field.get("world_container") as Node2D
	var collision_layer: Node2D = field.get("_collision_layer") as Node2D
	var cases: Array[Dictionary] = []
	for p: Vector2 in [Vector2(876, 1120), Vector2(510.640014648438, 1025.19995117188), Vector2(2395, 874), Vector2(2430, 1080), Vector2(2310, 1080), Vector2(2370, 1140), Vector2(2370, 1020)]:
		cases.append({"world_local_point": [p.x, p.y], "global_query_point": [container.to_global(p).x, container.to_global(p).y], "source_safe_body": contract.safe_body(p), "hits": _query(p)})
	var bodies: Array[Dictionary] = []
	for child: Node in collision_layer.get_children():
		if child is Node2D: bodies.append({"path": str(child.get_path()), "global_transform": _transform(child.global_transform), "children": _physical_children(child)})
	var npc_bodies: Array[Dictionary] = []
	for child: Node in (field.get("_actor_layer") as Node).get_children():
		if child is NPCNode:
			var body: StaticBody2D = child.get("_body_collider") as StaticBody2D
			npc_bodies.append({"id": child.npc_id, "world_local_position": [child.position.x, child.position.y], "global_transform": _transform(child.global_transform), "body_global_transform": _transform(body.global_transform) if body != null else [], "children": _physical_children(body) if body != null else []})
	records.append({"stage": label, "player_position": [player.position.x, player.position.y], "player_global_transform": _transform(player.global_transform), "player_shape_transform": _transform(shape.global_transform), "player_rectangle_size": [shape.shape.size.x, shape.shape.size.y] if shape.shape is RectangleShape2D else [], "container_global_transform": _transform(container.global_transform), "collision_layer_global_transform": _transform(collision_layer.global_transform), "cases": cases, "all_declared_static_bodies": bodies, "normal_npc_bodies": npc_bodies})
	print("[LuoyangPhysicsCause] snapshot " + label)

func _physical_children(node: Node) -> Array[Dictionary]:
	var shapes: Array[Dictionary] = []
	for child: Node in node.get_children():
		if child is CollisionShape2D:
			var item: Dictionary = {"path": str(child.get_path()), "global_transform": _transform(child.global_transform), "local_transform": _transform(child.transform), "disabled": child.disabled, "shape_type": child.shape.get_class() if child.shape != null else "null"}
			if child.shape is RectangleShape2D: item["size"] = [child.shape.size.x, child.shape.size.y]
			shapes.append(item)
		elif child is CollisionPolygon2D:
			var points: Array = []
			for p: Vector2 in child.polygon: points.append([p.x, p.y])
			shapes.append({"path": str(child.get_path()), "global_transform": _transform(child.global_transform), "local_transform": _transform(child.transform), "disabled": child.disabled, "polygon": points})
	return shapes

func _transform(t: Transform2D) -> Array:
	return [t.x.x, t.x.y, t.y.x, t.y.y, t.origin.x, t.origin.y]
