extends RefCounted
## Independent, finite mechanism evidence. No production clearance or refresh.
const INPUT := preload("res://tests/helpers/v15_input_driver.gd")
const GEOMETRY := preload("res://tests/helpers/v15_geometry_oracle.gd")
const SIZE := Vector2(3072, 2048)
const BODY := Vector2(34, 24)
var owner: SceneTree
var field: Control
var driver: RefCounted = INPUT.new()
var alpha: RefCounted = GEOMETRY.new()
var report: Callable
var capture: Callable
var manifest: Dictionary
var walk: Image
var solids: Dictionary = {}
var data: Dictionary = {"routes": [], "objects": [], "actions": [], "npcs": []}
var raw_cache: Dictionary = {}

func configure(tree: SceneTree, actual_field: Control, original: Dictionary, checker: Callable, screenshot: Callable) -> bool:
	owner = tree
	field = actual_field
	manifest = original.duplicate(true)
	report = checker
	capture = screenshot
	driver.configure(tree)
	walk = Image.load_from_file(String(manifest.get("walk_path", "")))
	if walk == null or walk.get_size() != Vector2i(SIZE): return false
	walk.convert(Image.FORMAT_RGBA8)
	for object: Dictionary in manifest.get("objects", []):
		var polygons: Array[PackedVector2Array] = []
		for original_polygon: Array in object.get("solid_polygons_px", []):
			var polygon := PackedVector2Array()
			for p: Variant in original_polygon: polygon.append(point(p))
			if polygon.size() < 3 or Geometry2D.triangulate_polygon(polygon).is_empty(): return false
			polygons.append(polygon)
		var size: Vector2 = point(object.get("collision_size_px", [0, 0]))
		if size.x > 0 and size.y > 0: polygons.append(rect_polygon(Rect2(point(object.physical_center_px) - size * .5, size)))
		if polygons.is_empty(): return false
		solids[String(object.id)] = polygons
	return solids.size() == 10

func point(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size() == 2: return Vector2(float(value[0]), float(value[1]))
	return Vector2(INF, INF)

func _check(ok: bool, label: String) -> void:
	report.call(ok, label)

func rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)])

func raw_evidence(p: Vector2) -> Dictionary:
	if not p.is_finite() or p.x < 17 or p.y < 12 or p.x + 17 >= SIZE.x or p.y + 12 >= SIZE.y: return {"clear": false, "kind": "body_out_of_domain"}
	# Complete inclusive ordinary-body pixel footprint, independently read PNG.
	for y in range(roundi(p.y - 12), roundi(p.y + 12) + 1):
		for x in range(roundi(p.x - 17), roundi(p.x + 17) + 1):
			var c: Color = walk.get_pixel(x, y)
			if c.r < .5 or c.a < .5: return {"clear": false, "kind": "body_raw_nav", "pixel": [x, y], "rgba": [c.r, c.g, c.b, c.a]}
	var body: PackedVector2Array = rect_polygon(Rect2(p - BODY * .5, BODY))
	for id: String in solids:
		for solid: PackedVector2Array in solids[id]:
			if not Geometry2D.intersect_polygons(body, solid).is_empty(): return {"clear": false, "kind": "source_solid", "id": id}
	for index in 17:
		var q: Vector2 = p if index == 0 else p + Vector2(cos(TAU * (index - 1) / 16) * 10, sin(TAU * (index - 1) / 16) * 6)
		if q.x < 0 or q.y < 0 or q.x >= SIZE.x or q.y >= SIZE.y: return {"clear": false, "kind": "shoe_out_of_domain"}
		var pixel := Vector2i(clampi(roundi(q.x), 0, 3071), clampi(roundi(q.y), 0, 2047))
		var c: Color = walk.get_pixelv(pixel)
		if c.r < .5 or c.a < .5: return {"clear": false, "kind": "shoe_raw_nav", "shoe": index, "pixel": [pixel.x, pixel.y]}
		for id: String in solids:
			for solid: PackedVector2Array in solids[id]:
				if Geometry2D.is_point_in_polygon(q, solid): return {"clear": false, "kind": "shoe_source_solid", "shoe": index, "id": id}
	return {"clear": true, "body_pixels": 875, "shoe_samples": 17, "margin_px": 0}

func raw_clear(p: Vector2) -> bool:
	if not raw_cache.has(p): raw_cache[p] = raw_evidence(p)
	return bool((raw_cache[p] as Dictionary).get("clear", false))

func physical_clear(p: Vector2) -> bool:
	var player: Node2D = field.get("_player") as Node2D
	var shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var container: Node2D = field.get("world_container") as Node2D
	if shape == null or not shape.shape is RectangleShape2D: return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	query.transform = shape.global_transform
	query.transform.origin += container.to_global(p) - player.global_position
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	query.collide_with_areas = false
	return player.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func clear(p: Vector2) -> bool:
	return raw_clear(p) and physical_clear(p)

func segment(a: Vector2, b: Vector2) -> Dictionary:
	var n: int = maxi(1, ceili(a.distance_to(b) / 4))
	for i in range(n + 1):
		var p: Vector2 = a.lerp(b, float(i) / n)
		if not clear(p): return {"clear": false, "point": [p.x, p.y], "raw": raw_evidence(p), "physical_clear": physical_clear(p), "index": i}
	return {"clear": true, "centers": n + 1, "max_step_px": a.distance_to(b) / n}

func move_to(p: Vector2) -> Dictionary:
	var player: Node2D = field.get("_player") as Node2D
	var path: PackedVector2Array = driver.plan(player.position, p, SIZE, clear, segment)
	if path.size() < 2: return {"ok": false, "reason": "no_finite_legal_input_path", "target": [p.x, p.y], "raw": raw_evidence(p), "physical_clear": physical_clear(p)}
	return await driver.follow(field, path, clear, segment)

func prop(id: String) -> Sprite2D:
	for node: Sprite2D in field.get("_scene_object_nodes"):
		if String(node.name) == "SceneObject_" + id: return node
	return null

func run_routes() -> void:
	_check(manifest.routes.size() == 5, "five authored routes, not old city storyline completion")
	for route: Dictionary in manifest.routes:
		var points := PackedVector2Array()
		for p: Variant in route.points_px: points.append(point(p))
		var entry: Dictionary = await move_to(points[0])
		_check(bool(entry.get("ok", false)), "normal input reaches route start: " + String(route.id))
		var driven: Dictionary = await driver.follow(field, points, clear, segment) if bool(entry.get("ok", false)) else {"ok": false, "not_run": true}
		_check(bool(driven.get("ok", false)), "entire authored route actual input/full17/34x24/physics: " + String(route.id))
		data.routes.append({"id": route.id, "approach": entry, "drive": driven})
		await capture.call("route_" + String(route.id))

func run_objects() -> void:
	var player: Node2D = field.get("_player") as Node2D
	var actor: Sprite2D = player.get("sprite") as Sprite2D
	var shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_check(shape != null and shape.shape is RectangleShape2D and shape.shape.size == BODY and shape.position == Vector2.ZERO, "ordinary actor keeps real centered 34x24 Rectangle, never travel circle")
	_check(absf(actor.scale.y - .945 * .91) < .000001 and absf(float(player.call("get_depth_sort_y")) - player.global_position.y) < .01, "normal adult .91 visual scale and grounded foot; no tiny-world identity")
	var source: Image = alpha.image_for(actor)
	var current: Rect2i = alpha.frame(actor, source)
	var top := current.size.y
	var bottom := -1
	for y in current.size.y:
		for x in current.size.x:
			if source.get_pixelv(current.position + Vector2i(x, y)).a > .12:
				top = mini(top, y)
				bottom = maxi(bottom, y)
	_check(bottom >= top and absf((bottom - top + 1) * actor.scale.y - float(manifest.ordinary_actor_effective_height_px)) < 1, "adult effective current-frame alpha height agrees with independently measured 113.5px reference")
	for object: Dictionary in manifest.objects:
		var id: String = String(object.id)
		var sprite: Sprite2D = prop(id)
		_check(sprite != null and sprite.texture.resource_path == String(object.texture), "independent runtime PNG binding: " + id)
		if sprite == null: continue
		_check((sprite.get_rect().size * sprite.scale.abs()).distance_to(point(object.render_size_px)) < .01 and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "actual rendered dimensions/filter: " + id)
		_check(_physical_binding(id), "actual StaticBody geometry exactly matches original world solids: " + id)
		var record: Dictionary = {"id": id, "collision": await _collision_trial(id), "alpha": await _alpha_trial(object)}
		data.objects.append(record)
	_check(data.objects.size() == 10, "all ten distinct entities tested, no first-success early exit")
	for npc: Node in (field.get("_actor_layer") as Node).get_children():
		if not npc is NPCNode: continue
		var rows: Array = []
		for tick in 8:
			await driver.completed_actor_stage()
			var foot: float = npc.get_depth_sort_y()
			_check(npc.z_index == clampi(floori(foot / 8), 0, 255), "normally spawned original NPC ordinary foot band: " + String(npc.npc_id))
			rows.append({"foot": foot, "band": npc.z_index, "frame": npc.sprite.frame})
		data.npcs.append({"id": npc.npc_id, "rows": rows})
	_check(data.npcs.size() == 3, "all three original NPCs exist normally; no forced world-depth metadata")

func _physical_binding(id: String) -> bool:
	var parent: Node2D = field.get("_collision_layer") as Node2D
	var container: Node2D = field.get("world_container") as Node2D
	if parent == null or container == null or parent.global_transform != container.global_transform: return false
	var body: StaticBody2D = parent.get_node_or_null("LabPhysical_" + id) as StaticBody2D
	if body == null or body.transform != Transform2D.IDENTITY or body.collision_layer != 1: return false
	var actual: Array[PackedVector2Array] = []
	for node: Node in body.get_children():
		if node is CollisionPolygon2D:
			if node.transform != Transform2D.IDENTITY: return false
			actual.append(node.polygon)
		elif node is CollisionShape2D and node.shape is RectangleShape2D:
			actual.append(rect_polygon(Rect2(node.position - node.shape.size * .5, node.shape.size)))
	return actual == solids[id]

func _collision_trial(id: String) -> Dictionary:
	var polygon: PackedVector2Array = (solids[id] as Array)[0]
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for vertex: Vector2 in polygon: bounds = bounds.expand(vertex)
	var inside: Vector2 = bounds.get_center()
	_check(not raw_clear(inside) and not physical_clear(inside), "independent source footprint and actual Physics2D reject interior: " + id)
	var start := Vector2(inside.x, bounds.end.y + 30)
	var approach: Dictionary = await move_to(start)
	_check(bool(approach.get("ok", false)), "normal input reaches exterior front-stop witness: " + id)
	var stop: Dictionary = {"not_run": true}
	if bool(approach.get("ok", false)):
		var player: Node2D = field.get("_player") as Node2D
		var initial: Vector2 = player.position
		var all_clear := true
		for tick in 30:
			driver.release_movement()
			Input.action_press("move_up")
			await owner.physics_frame
			all_clear = all_clear and clear(player.position)
			driver.observed_positions.append(player.position)
		driver.release_movement()
		await driver.completed_actor_stage()
		stop = {"start": [initial.x, initial.y], "end": [player.position.x, player.position.y], "all_clear": all_clear, "physics_ticks": 30}
		_check(all_clear and player.position.y >= bounds.end.y + 12 and player.position.y < initial.y - 1, "real ordinary input advances then stops outside full body solid: " + id)
	var bypass_points := PackedVector2Array([Vector2(bounds.position.x - 40, bounds.end.y + 30), Vector2(bounds.position.x - 40, bounds.position.y - 30), Vector2(bounds.end.x + 40, bounds.position.y - 30), Vector2(bounds.end.x + 40, bounds.end.y + 30)])
	var bypass: Array = []
	for target: Vector2 in bypass_points:
		var drive: Dictionary = await move_to(target)
		bypass.append(drive)
		_check(bool(drive.get("ok", false)), "actual continuous exterior bypass / independent full-body path: " + id)
		if not bool(drive.get("ok", false)): break
	await capture.call("solid_" + id)
	return {"interior": [inside.x, inside.y], "raw_interior": raw_evidence(inside), "stop": stop, "bypass": bypass, "bypass_is_finite_trial_not_complete_domain": true}

func _alpha_trial(object: Dictionary) -> Dictionary:
	var player: Node2D = field.get("_player") as Node2D
	var sprite: Sprite2D = player.get("sprite") as Sprite2D
	var container: Node2D = field.get("world_container") as Node2D
	var target_prop: Sprite2D = prop(String(object.id))
	var bounds: Rect2 = alpha.bounds_in(target_prop, container)
	var stations: Dictionary = {}
	var trials: Array = []
	var considered := 0
	# Bounded station discovery only. Failure does NOT prove alpha absence.
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var orientation: Dictionary = await move_to(player.position + direction * 2)
		await driver.completed_actor_stage()
		if not bool(orientation.get("ok", false)): continue
		var xs: Array[float] = [bounds.position.x - 20, bounds.position.x + 20, bounds.get_center().x, bounds.end.x - 20, bounds.end.x + 20]
		var ys: Array[float] = []
		for d: float in [-256.0, -128.0, -64.0, -32.0, -16.0, -8.0, -2.0, 2.0, 8.0, 16.0, 32.0, 64.0]: ys.append(float(object.depth_foot_y) + d)
		for y in range(maxi(16, floori(bounds.position.y)), mini(2032, ceili(bounds.end.y) + 116), 16): ys.append(float(y))
		for y: float in ys:
			for x: float in xs:
				considered += 1
				var p := Vector2(x, y)
				if not clear(p) or not bool(segment(p - direction * 2, p).get("clear", false)): continue
				var actor_foot: float = float(player.call("get_depth_sort_y")) + container.to_global(p).y - player.global_position.y
				var prop_foot: float = container.to_global(point(object.world_foot_px)).y
				if absf(actor_foot - prop_foot) <= .01: continue
				var relation: String = "front" if actor_foot > prop_foot else "behind"
				if stations.has(relation): continue
				var hits: Dictionary = alpha.strong_intersection(sprite, target_prop, container.to_global(p) - player.global_position)
				if int(hits.get("hits", 0)) > 0: stations[relation] = {"point": p, "direction": direction, "current_search_frame": hits}
			if stations.size() == 2: break
		if stations.size() == 2: break
	for relation: String in ["behind", "front"]:
		_check(stations.has(relation), "finite actual-facing legal strong-alpha station discovered (empty = NOT_PROVEN, never waived): " + String(object.id) + " " + relation)
		if not stations.has(relation): continue
		var station: Dictionary = stations[relation]
		var target: Vector2 = station.point
		var direction: Vector2 = station.direction
		var approach: Dictionary = await move_to(target - direction * 2)
		var leg: Dictionary = await driver.drive(field, target, clear) if bool(approach.get("ok", false)) else {"ok": false}
		await driver.completed_actor_stage()
		var hits: Dictionary = alpha.strong_intersection(sprite, target_prop)
		var actor_front: bool = alpha.actual_in_front(player, target_prop)
		var feet_relation: bool = float(player.call("get_depth_sort_y")) > container.to_global(point(object.world_foot_px)).y
		var debug: Dictionary = field.call("get_v14_modular_overlap_debug")
		_check(bool(approach.get("ok", false)) and bool(leg.get("ok", false)), "normal input and actual-facing final leg reach alpha witness: " + String(object.id) + " " + relation)
		_check(raw_clear(player.position) and physical_clear(player.position) and int(hits.get("hits", 0)) > 0, "real current-frame strong alpha with full17/34x24 and Physics2D clearance: " + String(object.id) + " " + relation)
		_check(feet_relation == (relation == "front") and actor_front == feet_relation, "completed normal node stage actual feet/order incl same-band siblings: " + String(object.id) + " " + relation)
		var hit_count: int = int((debug.get("prop_hits", {}) as Dictionary).get(String(object.id), 0))
		_check(hit_count > 0 if relation == "behind" else hit_count == 0, "only genuinely covered pixels ghost; player in front is not faded: " + String(object.id) + " " + relation)
		_check(exact_union(debug), "independent current-frame LINEAR union byteexact, not rectangular whole-person fade: " + String(object.id) + " " + relation)
		trials.append({"relation": relation, "actual_point": [player.position.x, player.position.y], "actual_alpha": hits, "raw": raw_evidence(player.position), "physical_clear": physical_clear(player.position), "actor_front": actor_front, "actor_band": player.z_index, "prop_band": target_prop.z_index, "actor_index": player.get_index(), "prop_index": target_prop.get_index(), "approach": approach, "final_leg": leg, "ghost_target_pixels": hit_count, "union_pixels": debug.get("pixels", 0)})
		await capture.call(String(object.id) + "_" + relation)
	return {"discovery_is_not_absence_proof": true, "considered": considered, "records": trials, "scope": "actual_current_idle_frame_only", "missing_relation_is_fail": trials.size() != 2}

func exact_union(debug: Dictionary) -> bool:
	var player: Node2D = field.get("_player") as Node2D
	var actor: Sprite2D = player.get("sprite") as Sprite2D
	var image: Image = alpha.image_for(actor)
	var frame: Rect2i = alpha.frame(actor, image)
	if frame.size.x <= 0: return false
	var expected := Image.create(frame.size.x, frame.size.y, false, Image.FORMAT_RGBA8)
	expected.fill(Color(0, 0, 0, 0))
	var container: Node2D = field.get("world_container") as Node2D
	var pixels := 0
	for y in frame.size.y:
		for x in frame.size.x:
			if image.get_pixelv(frame.position + Vector2i(x, y)).a <= 0: continue
			var uv := Vector2((x + .5) / frame.size.x, (y + .5) / frame.size.y)
			if actor.flip_h: uv.x = 1 - uv.x
			if actor.flip_v: uv.y = 1 - uv.y
			var world: Vector2 = actor.to_global(actor.get_rect().position + uv * actor.get_rect().size)
			var remainder := 1.0
			for object: Dictionary in manifest.objects:
				var sprite: Sprite2D = prop(String(object.id))
				if sprite == null or container.to_global(point(object.world_foot_px)).y <= float(player.call("get_depth_sort_y")) or not alpha.actual_in_front(sprite, player): continue
				remainder *= 1 - float(alpha.alpha_at(sprite, world))
			var value: float = 1 - remainder
			if value > 0:
				expected.set_pixel(x, y, Color(1, 1, 1, value))
				pixels += 1
	if pixels == 0: return not bool(debug.get("active", false)) and int(debug.get("pixels", -1)) == 0
	var actual: Image = debug.get("mask_image") as Image
	return debug.get("space") == "actor_frame" and bool(debug.get("active", false)) and actual != null and actual.get_size() == frame.size and actual.get_data() == expected.get_data()

func click_entity(sprite: Sprite2D) -> Dictionary:
	var player: Node2D = field.get("_player") as Node2D
	var image: Image = alpha.image_for(sprite)
	var current: Rect2i = alpha.frame(sprite, image)
	var best := Vector2(INF, INF)
	var distance := INF
	for y in current.size.y:
		for x in current.size.x:
			if image.get_pixelv(current.position + Vector2i(x, y)).a <= .12: continue
			var world: Vector2 = sprite.to_global(sprite.get_rect().position + Vector2((x + .5) / current.size.x, (y + .5) / current.size.y) * sprite.get_rect().size)
			var d: float = world.distance_squared_to(player.global_position)
			if d < distance:
				distance = d
				best = world
	if not best.is_finite(): return {"ok": false, "reason": "no_actual_source_alpha_click"}
	var record: Dictionary = await driver.pointer(sprite.get_canvas_transform() * best)
	record["ok"] = true
	record["alpha"] = alpha.alpha_at(sprite, best)
	record["world"] = [best.x, best.y]
	return record

func release() -> void:
	driver.release()
	alpha.release()
	walk = null
	raw_cache.clear()
	solids.clear()
	manifest.clear()
	field = null
	owner = null
	report = Callable()
	capture = Callable()
