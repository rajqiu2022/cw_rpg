extends RefCounted
## New ordinary Field/input acceptance, not an implementation contract wrapper.
## Source JSON/PNG and actual Physics2D are independent of runtime clearance.
const RAW := preload("res://tests/helpers/v15_field_raw_oracle.gd")
const ALPHA := preload("res://tests/helpers/v15_geometry_oracle.gd")
var tree: SceneTree
var driver: RefCounted
var check: Callable
var wait_field: Callable
var finish_intro: Callable
var capture: Callable
var field: Node
var oracle: RefCounted
var geometry: RefCounted = ALPHA.new()
var evidence: Dictionary = {}

func configure(owner: SceneTree, input: RefCounted, reporter: Callable, waiter: Callable, intro: Callable, screenshot: Callable) -> void:
	tree = owner
	driver = input
	check = reporter
	wait_field = waiter
	finish_intro = intro
	capture = screenshot

func _check(ok: bool, label: String) -> void:
	check.call(ok, label)

func _point(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size() == 2: return Vector2(float(value[0]), float(value[1]))
	return Vector2(INF, INF)

func _physical_clear(center: Vector2) -> bool:
	if not is_instance_valid(field) or tree.current_scene != field: return false
	var actor: Node2D = field.get("_player") as Node2D
	var container: Node2D = field.get("world_container") as Node2D
	var shape: CollisionShape2D = actor.get_node_or_null("CollisionShape2D") as CollisionShape2D if actor != null else null
	if shape == null or shape.shape == null or container == null: return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	query.transform = shape.global_transform
	query.transform.origin += container.to_global(center) - actor.global_position
	query.collision_mask = int(actor.get("collision_mask"))
	query.exclude = [actor.call("get_rid")]
	query.collide_with_areas = false
	return actor.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func clear(center: Vector2) -> bool:
	return oracle != null and bool(oracle.call("clear", center + _visual_foot_delta())) and _physical_clear(center)

func _visual_foot_delta() -> Vector2:
	var definition: SceneScript = field.get("_current_scene") as SceneScript if is_instance_valid(field) else null
	if definition == null or definition.actor_positions_are_feet: return Vector2.ZERO
	var actor: Node2D = field.get("_player") as Node2D
	var sprite: Sprite2D = actor.get("sprite") as Sprite2D if actor != null else null
	if sprite == null or sprite.texture == null: return Vector2(INF, INF)
	# Actual normal Player visual contract, independently from texture and live
	# sprite transform. Never apply South-village's offset to feet=true fields.
	return Vector2(0, sprite.position.y + sprite.texture.get_height() * sprite.scale.y * .45)

func segment(a: Vector2, b: Vector2) -> Dictionary:
	var steps: int = maxi(1, ceili(a.distance_to(b) / 4.0))
	for index in range(steps + 1):
		var p: Vector2 = a.lerp(b, float(index) / steps)
		if not clear(p): return {"clear": false, "index": index, "point_px": [p.x, p.y], "raw": oracle.call("foot_evidence", p), "physical_clear": _physical_clear(p)}
	return {"clear": true, "centers": steps + 1, "max_step_px": a.distance_to(b) / steps}

func bind_current(expected: StringName) -> bool:
	field = tree.current_scene
	var definition: SceneScript = field.get("_current_scene") as SceneScript if is_instance_valid(field) else null
	_check(definition != null and definition.scene_id == expected, "actual current ordinary Field identity: " + String(expected))
	if definition == null or definition.scene_id != expected: return false
	if oracle != null: oracle.call("release")
	oracle = RAW.new()
	var native: bool = String(expected).begins_with("openworld_v15_") and String(expected).ends_with("_outskirts")
	var configured: bool = oracle.call("configure", definition.map_layout, "round_world_pixel" if native else "normalized_image_round", 0.0 if native else -1.0)
	_check(configured, "actual materialized ordinary layout has independent raw PNG/solids oracle: " + str(oracle.get("errors")))
	return configured

func run_links(entry: Dictionary) -> Dictionary:
	var result: Dictionary = {"scope": "ACTUAL_ORDINARY_SOURCE_SPACE_MOUSE_PAIRED_RETURN", "scene_id": entry.scene_id, "cases": []}
	var id := StringName(entry.scene_id)
	var source_id := StringName(entry.source_scene_id)
	var source_definition: SceneScript = load("res://data/scenes/%s.tres" % source_id) as SceneScript
	_check(source_definition != null and source_definition.map_layout != null, "actual original source scene for new ordinary route exists")
	if source_definition == null or source_definition.map_layout == null: return result
	var source_size := Vector2(source_definition.map_layout.design_size)
	var source_foot: Vector2 = _point(entry.source_pos) * source_size
	for mode: String in ["space", "mouse_post", "mouse_arrow"]:
		# Bootstrap loads the real normal player solely to measure its actual
		# visual foot offset; this grants no entrance/return credit.
		tree.root.get_node("SceneRouter").call("go_field_smart", source_id)
		if not await wait_field.call(source_id) or not await finish_intro.call() or not bind_current(source_id): continue
		var offset: Vector2 = _visual_foot_delta()
		var source_spawn: Vector2 = source_foot - offset
		tree.root.get_node("SceneRouter").call("go_field_smart", source_id, source_spawn / source_size)
		if not await wait_field.call(source_id) or not await finish_intro.call() or not bind_current(source_id): continue
		var source: SceneScript = field.get("_current_scene") as SceneScript
		var chance: float = source.encounter_chance
		source.encounter_chance = 0.0
		var actor: Node2D = field.get("_player") as Node2D
		var original: Vector2 = actor.position
		_check(original.distance_to(source_spawn) < .03 and (original + _visual_foot_delta()).distance_to(source_foot) < .03 and clear(original), "source entrance root and independently measured visible ground foot agree; no hidden spawn repair")
		var enter: Node2D = _exit_to(id)
		_check(enter != null, "source really registers public new-field entrance, not direct Router substitute")
		if enter == null: continue
		var runtime_portal: Dictionary = {}
		for portal: Dictionary in source.map_layout.portals:
			if portal.get("target_scene") == String(id): runtime_portal = portal
		_check(_point(runtime_portal.get("source_foot_pos")) * source_size == source_foot and (_point(runtime_portal.get("source_spawn_pos")) * source_size).distance_to(source_spawn) < .03, "actual new source overlay explicitly separates ground threshold from actor-origin return")
		await driver.call("completed_actor_stage")
		var entry_size: Vector2 = _point(runtime_portal.get("size")) * source_size
		_check(Rect2(enter.position - entry_size * .5, entry_size).has_point(original + _visual_foot_delta()) and clear(original) and bool(actor.get("can_move")), "independent actual visible-foot threshold/input is enabled; legacy body-origin range is not the new gate contract")
		await capture.call(String(id) + "_source_" + mode)
		if mode == "space": await driver.call("key", KEY_SPACE)
		elif mode == "mouse_arrow":
			var marker: Sprite2D = enter.get("marker_visual") as Sprite2D
			_check(marker != null and marker.is_visible_in_tree(), "real source entry arrow provides actual mouse hit")
			if marker != null: await driver.call("pointer", marker.get_global_transform_with_canvas().origin)
		else:
			var post: Sprite2D = _prop("outskirts_%s_routepost" % entry.ecology)
			_check(post != null and post.texture != null, "actual new routepost sprite is registered in source, not only an arrow")
			if post != null:
				var image: Image = geometry.call("image_for", post)
				var current: Rect2i = geometry.call("frame", post, image)
				var point := Vector2(INF, INF)
				for y in current.size.y:
					for x in current.size.x:
						if image.get_pixelv(current.position + Vector2i(x, y)).a > .12:
							point = post.to_global(post.get_rect().position + Vector2((x + .5) / current.size.x, (y + .5) / current.size.y) * post.get_rect().size)
							break
						if point.is_finite(): break
				_check(point.is_finite(), "entity routepost mouse click hits actual source alpha, not transparent rectangle")
				if point.is_finite(): await driver.call("pointer", (post.get_canvas_transform() * point))
		if not await wait_field.call(id) or not await finish_intro.call() or not bind_current(id): continue
		var destination: SceneScript = field.get("_current_scene") as SceneScript
		var destination_chance: float = destination.encounter_chance
		destination.encounter_chance = 0.0
		actor = field.get("_player") as Node2D
		_check(actor.position.distance_to(_point(entry.art.return_foot_px)) < .03 and clear(actor.position), "normal entry reaches measured new field complete-foot threshold")
		var exit: Node2D = _exit_to(source_id)
		_check(exit != null, "ordinary new field owns actual public reverse exit to original source, not world map")
		if exit == null: continue
		var path: PackedVector2Array = driver.call("plan", actor.position, exit.position, Vector2(1536, 1024), clear, segment)
		_check(path.size() >= 2, "reverse threshold has actual complete-foot legal path")
		if path.size() < 2: continue
		var driven: Dictionary = await driver.call("follow", field, path, clear, segment)
		_check(bool(driven.get("ok", false)) and bool(exit.get("_in_range")), "actual input reaches reverse exit under normal physics")
		await capture.call(String(id) + "_return_" + mode)
		destination.encounter_chance = destination_chance
		if mode == "space": await driver.call("key", KEY_SPACE)
		else:
			var marker: Sprite2D = exit.get("marker_visual") as Sprite2D
			_check(marker != null, "actual reverse arrow mouse target exists")
			if marker != null: await driver.call("pointer", marker.get_global_transform_with_canvas().origin)
		if not await wait_field.call(source_id) or not await finish_intro.call() or not bind_current(source_id): continue
		actor = field.get("_player") as Node2D
		var returned: bool = actor.position.distance_to(original) < .03 and (actor.position + _visual_foot_delta()).distance_to(source_foot) < .03 and clear(actor.position)
		_check(returned, "normal paired return preserves exact original ordinary source full17 feet")
		(field.get("_current_scene") as SceneScript).encounter_chance = chance
		result.cases.append({"mode": mode, "returned": returned, "original_source_root_px": [original.x, original.y], "original_ground_foot_px": [source_foot.x, source_foot.y], "actual_return_root_px": [actor.position.x, actor.position.y], "actual_return_ground_foot_px": [actor.position.x + _visual_foot_delta().x, actor.position.y + _visual_foot_delta().y], "reverse_drive": driven})
	_check(result.cases.size() == 3, "actual Space, entity-post mouse and arrow mouse complete entry and paired reverse flow")
	return result

func _exit_to(id: StringName) -> Node2D:
	for node: Node2D in field.get("_exit_nodes"):
		if StringName(node.get("target_scene_id")) == id: return node
	return null

func run(entry: Dictionary) -> Dictionary:
	var data: Dictionary = entry.art
	var id: StringName = StringName(entry.scene_id)
	evidence = {"scope": "ACTUAL_THREE_FIELD_INPUT_NOT_WORLD64", "scene_id": id, "routes": [], "negatives": [], "alpha_pairs": []}
	var return_foot: Vector2 = _point(data.get("return_foot_px"))
	# Fixture establishes an ordinary scene only. It earns no portal credit.
	tree.root.get_node("SceneRouter").call("go_field_smart", id, return_foot / Vector2(1536, 1024))
	if not await wait_field.call(id) or not await finish_intro.call() or not bind_current(id): return evidence
	var definition: SceneScript = field.get("_current_scene") as SceneScript
	var actor: Node2D = field.get("_player") as Node2D
	_check(actor.position.distance_to(return_foot) < .03 and clear(actor.position), "actual materialized spawn is measured full17 return threshold")
	# Only this process's duplicated runtime fixture disables random interruption
	# during deterministic route/negative/depth checks. Restore before encounter.
	var original_chance: float = definition.encounter_chance
	definition.encounter_chance = 0.0
	for object: Dictionary in data.get("objects", []):
		var actual: Sprite2D = _prop(String(object.get("id", "")))
		_check(actual != null and actual.texture != null and actual.texture.resource_path == object.get("texture"), "independent live prop really binds its original PNG: " + String(object.get("id", "")))
		if actual == null: continue
		var bounds_size: Vector2 = actual.get_rect().size * actual.scale.abs()
		_check(bounds_size.distance_to(_point(object.get("render_size_px"))) < .01 and actual.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "actual new ordinary prop size/LINEAR filter comes from own sourcebody")
		var foot: Vector2 = _point(object.get("world_foot_px"))
		var expected_band: int = clampi(floori((field.get("world_container") as Node2D).to_global(foot).y / 8), 0, 255)
		_check(actual.z_index == expected_band, "ordinary independent prop retains actual foot depth and 255 range")
	for route: Dictionary in data.get("routes", []):
		var points := PackedVector2Array()
		for p: Variant in route.get("points_px", []): points.append(_point(p))
		_check(points.size() >= 2, "actual loop/branch path has original measured vertices")
		if points.size() < 2: continue
		var approach: PackedVector2Array = driver.call("plan", actor.position, points[0], Vector2(1536, 1024), clear, segment)
		_check(approach.size() >= 2, "route start has independent complete-foot alternate path")
		if approach.size() < 2: continue
		var to_start: Dictionary = await driver.call("follow", field, approach, clear, segment)
		_check(bool(to_start.get("ok", false)), "normal input actually reaches route start")
		var actual: Dictionary = await driver.call("follow", field, points, clear, segment)
		_check(bool(actual.get("ok", false)), "actual complete route/branch input covers <=4px/full17: " + String(route.get("id", "")))
		evidence.routes.append({"id": route.get("id"), "approach": to_start, "actual": actual})
		await capture.call(String(id) + "_" + String(route.get("id", "route")))
	for probe: Dictionary in data.get("blocked_probes", []):
		var point: Vector2 = _point(probe.get("point_px"))
		var raw: Dictionary = oracle.call("foot_evidence", point)
		var physical: bool = _physical_clear(point)
		var kind: String = probe.get("kind", "")
		_check(not bool(raw.get("clear", true)), "original source full17 rejects authored water/trunk/root: " + String(probe.get("id", "")))
		if kind == "water":
			_check(not bool((oracle.call("pixel_evidence", point) as Dictionary).get("clear", true)) and float(probe.get("actual_bed_m", INF)) < -.025, "natural wet negative has actual raw nav black and negative bed, not trunk-only deny")
		elif kind == "independent_trunk_or_stem":
			_check(not physical and raw.get("kind") == "source_collision", "real independent stem/trunk Physics2D blocks its original footprint")
		else: _check(false, "unknown negative kind refused, not silently omitted")
		evidence.negatives.append({"source": probe, "raw": raw, "physical_clear": physical})
	var wet_count := 0
	for probe: Dictionary in data.get("blocked_probes", []):
		if probe.get("kind") == "water": wet_count += 1
	_check(wet_count >= 1, "each authored scene with real pond/marsh supplies an actual water negative, not substituted by roots")
	await _alpha_checks(data)
	await _npc_checks(data)
	_check(bool(oracle.call("verify_sources")), "actual original navigation unchanged across input/depth phases")
	if is_instance_valid(field) and tree.current_scene == field: definition.encounter_chance = original_chance
	return evidence

func _npc_checks(data: Dictionary) -> void:
	var actor: Node2D = field.get("_player") as Node2D
	var container: Node2D = field.get("world_container") as Node2D
	var size: Vector2 = field.get("_world_size")
	var anchor := Vector2(INF, INF)
	for route: Dictionary in data.get("routes", []):
		for candidate: Variant in route.get("points_px", []):
			var p: Vector2 = _point(candidate)
			var global: Vector2 = container.to_global(p)
			p = container.to_local(Vector2(global.x, floor(global.y / 8) * 8 + 4))
			var legal := true
			for offset: Vector2 in [Vector2.ZERO, Vector2(20, -3), Vector2(20, 1), Vector2(64, 0), Vector2(128, 0)]:
				if not clear(p + offset): legal = false
			if legal and bool(segment(p + Vector2(20, -3), p + Vector2(20, 1)).get("clear", false)):
				anchor = p
				break
		if anchor.is_finite(): break
	_check(anchor.is_finite(), "ordinary loop has real legal NPC patrol body/feet domain")
	if not anchor.is_finite(): return
	var path: PackedVector2Array = driver.call("plan", actor.position, anchor + Vector2(128, 0), size, clear, segment)
	_check(path.size() >= 2, "normal player has fullfoot input route outside unchanged NPC bodies")
	if path.size() < 2: return
	var driven: Dictionary = await driver.call("follow", field, path, clear, segment)
	_check(bool(driven.get("ok", false)), "normal player really parks outside NPC fixture")
	var prefix := "qa_outskirts_normal_"
	var entries: Array[Dictionary] = []
	for index in 3:
		entries.append({"npc_id": prefix + str(index), "npc_name": "QA隔离角色", "sprite_path": "res://art/characters/npc_zhuwei_gate_guard_idle_down_25d_4f_v2_runtime.png", "pos": (anchor + Vector2(20 if index == 2 else index * 64, -1 if index == 2 else 0)) / size, "scale": .65, "movement_mode": "patrol" if index == 2 else "idle", "patrol_axis": Vector2.DOWN, "patrol_distance": 2.0, "patrol_speed": 18.0})
	field.call("_spawn_npcs", entries)
	await driver.call("completed_actor_stage")
	var nodes: Dictionary = {}
	for node: Node in (field.get("_actor_layer") as Node).get_children():
		if node is NPCNode and String(node.npc_id).begins_with(prefix): nodes[node.npc_id] = node
	_check(nodes.size() == 3, "actual normal spawning creates all three ordinary NPCs without forced metadata")
	if nodes.size() != 3:
		for node: Node in nodes.values(): node.queue_free()
		return
	var idle: NPCNode = nodes[prefix + "0"]
	var tie: NPCNode = nodes[prefix + "1"]
	var patrol: NPCNode = nodes[prefix + "2"]
	var front := 0
	var behind := 0
	var frames: Dictionary = {}
	var rows: Array[Dictionary] = []
	for tick in 72:
		await driver.call("completed_actor_stage")
		var a: float = idle.get_depth_sort_y()
		var b: float = patrol.get_depth_sort_y()
		var hits: Dictionary = geometry.call("strong_intersection", patrol.sprite, idle.sprite)
		var correct: bool = bool(geometry.call("actual_in_front", patrol, idle)) == (b > a)
		frames[patrol.sprite.frame] = true
		_check(bool(oracle.call("clear", patrol.position)) and Geometry2D.intersect_polygons(_npc_body(idle), _npc_body(patrol)).is_empty(), "actual normal patrol has complete raw17 feet and unchanged disjoint body rectangles")
		_check(int(patrol.get_meta("depth_band_max", -1)) == 255 and idle.z_index == clampi(floori(a / 8), 0, 255) and patrol.z_index == clampi(floori(b / 8), 0, 255), "normal new ordinary NPCs use actual feet/255, not world1024 metadata")
		_check(idle.get_depth_sort_y() == tie.get_depth_sort_y() and idle.get_index() < tie.get_index(), "ordinary exact-foot ties retain stable normal insertion order")
		if idle.z_index == patrol.z_index and int(hits.get("hits", 0)) > 0 and absf(a - b) > .01:
			_check(correct, "completed normal patrol stage orders actual overlapping current-frame alpha by real feet")
			if b > a: front += 1
			else: behind += 1
		rows.append({"tick": tick, "idle_foot": a, "patrol_foot": b, "frame": patrol.sprite.frame, "overlap": hits, "correct_order": correct})
		if tick == 20 or tick == 45: await capture.call(String(data.scene_id) + "_normal_npc_" + str(tick))
	_check(front > 0 and behind > 0 and frames.size() == 4, "ordinary normal NPC patrol proves both same-band alpha directions and all four current animation cells")
	var references: Array[WeakRef] = []
	for node: Node in nodes.values():
		references.append(weakref(node))
		node.queue_free()
	nodes.clear()
	idle = null
	tie = null
	patrol = null
	for settle in 4: await driver.call("completed_actor_stage")
	for reference: WeakRef in references: _check(reference.get_ref() == null, "ordinary test-owned NPC released naturally, not left as depth cache node")
	evidence["normal_NPC_patrol"] = {"anchor_px": [anchor.x, anchor.y], "front": front, "behind": behind, "frames": frames.keys(), "records": rows}

func _npc_body(npc: NPCNode) -> PackedVector2Array:
	var body: StaticBody2D = npc.get("_body_collider") as StaticBody2D
	var polygon := PackedVector2Array()
	if body == null: return polygon
	for child: Node in body.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var half: Vector2 = child.shape.size * .5
			for corner: Vector2 in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)]: polygon.append(child.to_global(corner))
			break
	_check(polygon.size() == 4, "NPC physics evidence uses actual RectangleShape2D, not guessed radius")
	return polygon

func _prop(id: String) -> Sprite2D:
	for node: Node in field.get("_scene_object_nodes"):
		if node is Sprite2D and String(node.name) == "SceneObject_" + id: return node as Sprite2D
	return null

func _input_facing(direction: Vector2) -> Dictionary:
	# The only orientation change is a real, collision-checked final input leg.
	# Never assign Player.direction, Sprite.frame or the animation texture.
	var actor: Node2D = field.get("_player") as Node2D
	for offset: Vector2 in [Vector2.ZERO, Vector2(8, 0), Vector2(-8, 0), Vector2(0, 8), Vector2(0, -8)]:
		var start: Vector2 = actor.position + offset
		var end: Vector2 = start + direction * 2.0
		if not bool(segment(start, end).get("clear", false)): continue
		var path: PackedVector2Array = driver.call("plan", actor.position, start, Vector2(1536, 1024), clear, segment)
		if path.size() < 2: continue
		var approach: Dictionary = await driver.call("follow", field, path, clear, segment)
		if not bool(approach.get("ok", false)): continue
		var leg: Dictionary = await driver.call("drive", field, end, clear)
		await driver.call("completed_actor_stage")
		if bool(leg.get("ok", false)): return {"ok": true, "direction": [direction.x, direction.y], "approach": approach, "final_input_leg": leg}
	return {"ok": false, "direction": [direction.x, direction.y], "reason": "no_legal_two_pixel_input_leg"}

func _alpha_checks(data: Dictionary) -> void:
	var actor: Node2D = field.get("_player") as Node2D
	var actor_sprite: Sprite2D = actor.get_node_or_null("Sprite2D") as Sprite2D
	if actor_sprite == null: actor_sprite = actor.get("sprite") as Sprite2D
	_check(actor_sprite != null, "ordinary player exposes actual current frame, not full animation-strip alpha")
	if actor_sprite == null: return
	var container: Node2D = field.get("world_container") as Node2D
	var pairs := 0
	for object: Dictionary in data.get("objects", []):
		if not bool(object.get("blocking", false)): continue
		var prop: Sprite2D = _prop(String(object.id))
		if prop == null: continue
		var bounds: Rect2 = geometry.call("bounds_in", prop, container)
		var depth: float = float(object.get("depth_foot_y", INF))
		var stations: Dictionary = {}
		var facing_search: Array[Dictionary] = []
		# Finite source-domain search is a discovery mechanism only, not a proof
		# that an empty legal domain is impossible. Empty remains an actual FAIL.
		for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			var orientation: Dictionary = await _input_facing(direction)
			orientation["actual_texture_path"] = actor_sprite.texture.resource_path if actor_sprite.texture != null else ""
			orientation["actual_frame"] = actor_sprite.frame
			facing_search.append(orientation)
			if not bool(orientation.get("ok", false)): continue
			for y in range(maxi(12, floori(bounds.position.y) - 80), mini(1012, ceili(bounds.end.y) + 110), 4):
				for x in range(maxi(18, floori(bounds.position.x) - 40), mini(1518, ceili(bounds.end.x) + 40), 4):
					var point := Vector2(x, y)
					var final_start: Vector2 = point - direction * 2.0
					if not bool(segment(final_start, point).get("clear", false)): continue
					var actor_foot: float = float(actor.call("get_depth_sort_y")) + container.to_global(point).y - actor.global_position.y
					var prop_foot: float = container.to_global(Vector2(0, depth)).y
					var relation: String = "front" if actor_foot > prop_foot else "behind"
					if stations.has(relation) or actor_foot == prop_foot: continue
					var intersection: Dictionary = geometry.call("strong_intersection", actor_sprite, prop, container.to_global(point) - actor.global_position)
					if int(intersection.get("hits", 0)) > 0:
						stations[relation] = {"point": point, "direction": direction, "search_overlap": intersection}
					if stations.size() == 2: break
				if stations.size() == 2: break
		if stations.size() != 2: continue
		var records: Array = []
		for relation: String in ["behind", "front"]:
			var station: Dictionary = stations[relation]
			var target: Vector2 = station.point
			var direction: Vector2 = station.direction
			var path: PackedVector2Array = driver.call("plan", actor.position, target - direction * 2.0, Vector2(1536, 1024), clear, segment)
			_check(path.size() >= 2, "actual alpha station has full17/Physics2D path; no teleport through trunk")
			if path.size() < 2: continue
			var drive: Dictionary = await driver.call("follow", field, path, clear, segment)
			var final_leg: Dictionary = await driver.call("drive", field, target, clear)
			await driver.call("completed_actor_stage")
			var overlap: Dictionary = geometry.call("strong_intersection", actor_sprite, prop)
			var actual_front: bool = geometry.call("actual_in_front", actor, prop)
			var full17: bool = bool(oracle.call("clear", actor.position + _visual_foot_delta()))
			var physics_clear: bool = _physical_clear(actor.position)
			var actual_drive: bool = bool(drive.get("ok", false)) and bool(final_leg.get("ok", false))
			_check(actual_drive, "ordinary alpha station completes planned path and real final orientation input: " + relation)
			_check(full17, "ordinary alpha station actual complete17 shoes remain legal: " + relation)
			_check(physics_clear, "ordinary alpha station actual Physics2D shape remains disjoint: " + relation)
			_check(int(overlap.get("hits", 0)) > 0, "ordinary alpha station actual current-frame strong alpha >.12: " + relation)
			_check(actual_front == (relation == "front"), "ordinary prop genuine normal-stage foot order: " + relation)
			var debug: Dictionary = field.call("get_v14_modular_overlap_debug")
			_check(int((debug.get("prop_hits", {}) as Dictionary).get(String(object.id), 0)) > 0 if relation == "behind" else int((debug.get("prop_hits", {}) as Dictionary).get(String(object.id), 0)) == 0, "behind-alpha-only ghost; foreground actor never made transparent")
			_check(_exact_union(actor_sprite, debug), "ordinary local ghost is exact current-frame pixel union, not whole rectangular actor fade")
			records.append({"relation": relation, "point_px": [actor.position.x, actor.position.y], "direction_input": [direction.x, direction.y], "drive": drive, "final_input_leg": final_leg, "full17_clear": full17, "physical_clear": physics_clear, "actual_front": actual_front, "search_overlap": station.search_overlap, "overlap": overlap, "actor_band": actor.z_index, "prop_band": prop.z_index, "actor_index": actor.get_index(), "prop_index": prop.get_index(), "ghost_pixels": debug.get("pixels", 0)})
			await capture.call(String(data.scene_id) + "_prop_" + relation)
		evidence.alpha_pairs.append({"id": object.id, "facing_search": facing_search, "records": records})
		if records.size() == 2: pairs += 1
		if pairs >= 1: break
	_check(pairs >= 1, "each ordinary ecology field proves >=1 real legal current-frame alpha front/behind pair; unknown empty domains not waived")

func _exact_union(actor: Sprite2D, debug: Dictionary) -> bool:
	var image: Image = geometry.call("image_for", actor)
	var frame: Rect2i = geometry.call("frame", actor, image)
	var mask: Image = debug.get("mask_image") as Image
	if image == null or frame.size.x <= 0: return false
	var expected := Image.create(frame.size.x, frame.size.y, false, Image.FORMAT_RGBA8)
	expected.fill(Color(0, 0, 0, 0))
	var owner: Node2D = field.get("_player") as Node2D
	var actor_y: float = owner.call("get_depth_sort_y")
	var actual_layout: Resource = (field.get("_current_scene") as SceneScript).map_layout
	var depth_by_id: Dictionary = {}
	for object: Dictionary in actual_layout.get("visual_objects"):
		if bool(object.get("sort_by_feet", false)): depth_by_id[String(object.get("id", ""))] = float(object.get("depth_sort_foot_y", INF)) * (oracle.get("size") as Vector2).y
	var container: Node2D = field.get("world_container") as Node2D
	var pixels := 0
	for y in frame.size.y:
		for x in frame.size.x:
			if image.get_pixelv(frame.position + Vector2i(x, y)).a <= 0: continue
			var uv := Vector2((x + .5) / frame.size.x, (y + .5) / frame.size.y)
			if actor.flip_h: uv.x = 1 - uv.x
			if actor.flip_v: uv.y = 1 - uv.y
			var point: Vector2 = actor.to_global(actor.get_rect().position + uv * actor.get_rect().size)
			var remaining := 1.0
			for id: String in depth_by_id:
				var prop: Sprite2D = _prop(id)
				if prop == null or container.to_global(Vector2(0, depth_by_id[id])).y <= actor_y or not bool(geometry.call("actual_in_front", prop, owner)): continue
				remaining *= 1 - float(geometry.call("alpha_at", prop, point))
			var alpha: float = 1 - remaining
			if alpha > 0:
				expected.set_pixel(x, y, Color(1, 1, 1, alpha))
				pixels += 1
	if pixels == 0: return not bool(debug.get("active", false)) and int(debug.get("pixels", 0)) == 0
	return debug.get("space") == "actor_frame" and bool(debug.get("active", false)) and mask != null and mask.get_size() == frame.size and mask.get_data() == expected.get_data()

func release() -> void:
	if oracle != null: oracle.call("release")
	oracle = null
	geometry.call("release")
	field = null
	tree = null
	driver = null
	check = Callable()
	wait_field = Callable()
	finish_intro = Callable()
	capture = Callable()
