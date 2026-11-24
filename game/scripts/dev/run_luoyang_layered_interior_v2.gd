extends SceneTree
## Explicit preview only. No save or production activation path.
const CONTRACT := preload("res://scripts/dev/luoyang_layered_interior_v2_contract.gd")
const FIELD_PATH := "res://scripts/dev/luoyang_layered_interior_v2_field.gd"
var field: Control
var contract: RefCounted
var before: Dictionary = {}
var _gm_before: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_start")

func _start() -> void:
	if "--luoyang-layered-v2-source-check" in OS.get_cmdline_user_args():
		var ok: bool = source_check()
		quit(0 if ok else 1)
		return
	if not await start_preview():
		restore_preview_state()
		quit(1)

func source_check() -> bool:
	contract = CONTRACT.new()
	if not contract.prepare():
		push_error("Luoyang trial refused: " + str(contract.errors))
		return false
	var script: Script = load(FIELD_PATH) as Script
	if script == null or not script.can_instantiate():
		push_error("Luoyang trial Field script is not instantiable")
		return false
	var scene: SceneScript = contract.make_scene()
	if scene == null or not contract.materialization_valid(scene) or not contract.canonical_unchanged():
		push_error("Luoyang trial materialization rejected: " + str(contract.errors))
		return false
	var original: SceneScript = load("res://data/scenes/ch4_s0_luoyang_gate.tres") as SceneScript
	if is_same(scene.map_layout, original.map_layout):
		push_error("Luoyang trial layout aliases canonical source")
		return false
	for property: Dictionary in original.map_layout.get_property_list():
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0: continue
		var value: Variant = original.map_layout.get(property.name)
		if value is Array and is_same(value, scene.map_layout.get(property.name)):
			push_error("Luoyang trial Array aliases canonical source: " + String(property.name))
			return false
	print("[LuoyangLayeredTrialV2] typed-array clear evidence: " + JSON.stringify(contract.materialization_diagnostics))
	print("[LuoyangLayeredTrialV2] source/materialization PASS; Field/physics/input/GPU NOT_RUN; art NOT_APPROVED")
	return true

func start_preview() -> bool:
	if not source_check(): return false
	before = protected_state()
	root.size = Vector2i(1920, 1080)
	set_auto_accept_quit(false)
	root.close_requested.connect(func(): restore_preview_state(); quit())
	var gm: Node = root.get_node_or_null("GMConsole")
	if gm != null:
		_gm_before.append({"node": gm, "process_mode": gm.process_mode})
		gm.process_mode = Node.PROCESS_MODE_DISABLED
		for node: Node in [gm] + gm.get_children():
			if node is CanvasLayer:
				_gm_before.append({"node": node, "visible": node.visible})
				node.visible = false
	var packed: PackedScene = load("res://scenes/field_walkable.tscn") as PackedScene
	field = packed.instantiate() as Control
	field.set_script(load(FIELD_PATH))
	field.set("lab_contract", contract)
	field.set("definition", contract.make_scene())
	root.add_child(field)
	current_scene = field
	for tick in range(10): await process_frame
	if not runtime_entities_ready():
		push_error("V2 setup refused: real Player/body/NPCs or declared visual/physical entity set was not materialized")
		return false
	if protected_state() != before or not contract.canonical_unchanged():
		push_error("Trial setup changed protected state")
		return false
	print("[LuoyangLayeredTrialV2] limited dev Field ready; actions DRY_RUN_ONLY, no production routes/rewards/saves")
	return true

func runtime_entities_ready() -> bool:
	if not is_instance_valid(field): return false
	var definition: Variant = field.get("definition")
	if not definition is SceneScript or not contract.materialization_valid(definition): return false
	var collisions: Node = field.get("_collision_layer") as Node
	if collisions == null: return false
	var allowed_bodies: Dictionary = {"MapBounds": true}
	for id: String in contract.blocking_ids: allowed_bodies["LabPhysical_" + id] = true
	if collisions.get_child_count() != allowed_bodies.size(): return false
	for collision_body: Node in collisions.get_children():
		if not collision_body is StaticBody2D or not allowed_bodies.has(String(collision_body.name)): return false
		var actual_body: StaticBody2D = collision_body as StaticBody2D
		if String(collision_body.name) == "MapBounds":
			if collision_body.get_child_count() != 4: return false
			for shape: Node in collision_body.get_children():
				if not shape is CollisionShape2D or shape.disabled or not shape.shape is RectangleShape2D: return false
		else:
			if not collision_body.has_meta("authoring_id") or "LabPhysical_" + String(collision_body.get_meta("authoring_id")) != String(collision_body.name): return false
			var authoring_id: String = String(collision_body.get_meta("authoring_id"))
			var authored: Dictionary = {}
			for object: Dictionary in contract.manifest.objects:
				if String(object.id) == authoring_id: authored = object
			if authored.is_empty() or not bool(authored.blocking): return false
			var raw_polygons: Array = authored.solid_polygons_px
			var has_box: bool = contract.vec(authored.collision_size_px).x > 0
			if actual_body.position != Vector2.ZERO or collision_body.get_child_count() != raw_polygons.size() + (1 if has_box else 0): return false
			for index in range(raw_polygons.size()):
				var polygon: CollisionPolygon2D = collision_body.get_child(index) as CollisionPolygon2D
				if polygon == null or polygon.disabled or polygon.position != Vector2.ZERO or polygon.polygon != contract.polygon_from(raw_polygons[index]): return false
			if has_box:
				var box: CollisionShape2D = collision_body.get_child(0) as CollisionShape2D
				if box == null or box.disabled or not box.shape is RectangleShape2D or box.shape.size != contract.vec(authored.collision_size_px) or box.position != contract.vec(authored.physical_center_px): return false
	var actor: Variant = field.get("_player")
	if not is_instance_valid(actor) or not actor is CharacterBody2D or not actor.is_inside_tree(): return false
	var actor_script: Script = actor.get_script() as Script
	if actor_script == null or actor_script.resource_path != "res://scripts/field/player.gd": return false
	if not actor.is_in_group("player") or not actor.has_method("get_depth_sort_y"): return false
	var body: CollisionShape2D = actor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body == null or body.disabled or not body.shape is RectangleShape2D: return false
	if body.shape.size != CONTRACT.BODY_SIZE or body.position != Vector2.ZERO: return false
	var actor_sprite: Sprite2D = actor.get_node_or_null("Sprite2D") as Sprite2D
	if actor_sprite == null or actor_sprite.texture == null: return false
	if not is_equal_approx(float(actor.get("_visual_scale_multiplier")), .91): return false
	var npcs: Variant = field.get("_npc_nodes")
	if not npcs is Array or npcs.size() != 3: return false
	var npc_ids: Dictionary = {}
	for npc: Variant in npcs:
		if not is_instance_valid(npc) or not npc is Node2D or not npc.is_inside_tree(): return false
		var npc_script: Script = npc.get_script() as Script
		if npc_script == null or npc_script.resource_path != "res://scripts/field/npc_node.gd": return false
		var sprite: Sprite2D = npc.get_node_or_null("Sprite2D") as Sprite2D
		if sprite == null or sprite.texture == null: return false
		# Normal NPC feet physics is kept in ActorLayer, not rejected as an
		# unexpected layout blocker. Its actual inherited body must still exist.
		var npc_body: Variant = npc.get("_body_collider")
		if not is_instance_valid(npc_body) or not npc_body is StaticBody2D or npc_body.get_child_count() != 1: return false
		var npc_shape: CollisionShape2D = npc_body.get_child(0) as CollisionShape2D
		if npc_shape == null or npc_shape.disabled or not npc_shape.shape is RectangleShape2D: return false
		npc_ids[String(npc.get("npc_id"))] = true
	for id: String in ["luoyang_gate_sergeant", "spar_luoyang_patrol", "luoyang_armorer"]:
		if not npc_ids.has(id): return false
	var props: Variant = field.get("_scene_object_nodes")
	if not props is Array: return false
	var prop_ids: Dictionary = {}
	for prop: Variant in props:
		if not is_instance_valid(prop) or not prop is Sprite2D or not prop.is_inside_tree() or prop.texture == null: return false
		if String(prop.name).begins_with("SceneObject_"): prop_ids[String(prop.name).trim_prefix("SceneObject_")] = true
	if prop_ids.size() != contract.object_ids.size(): return false
	for object: Dictionary in contract.manifest.objects:
		if not prop_ids.has(String(object.id)): return false
	return true

func protected_state() -> Dictionary:
	var game: Node = root.get_node("GameState")
	var saves: Dictionary = {}
	for slot in range(5):
		for suffix: String in [".json", ".json.bak"]:
			var path: String = "user://save_%d%s" % [slot, suffix]
			saves[path] = {"exists": FileAccess.file_exists(path), "sha256": FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "", "mtime": FileAccess.get_modified_time(path) if FileAccess.file_exists(path) else 0}
	var session: Dictionary = {}
	for key: String in ["current_chapter", "player_faction", "skill_mastery", "pending_skill_unlocks", "training_points_total", "training_points_available", "reputation", "sparring_records", "last_faction_join_error"]:
		session[key] = contract.snapshot_value(game.get(key))
	var party: Array = []
	for member: Resource in game.get("party"): party.append(contract.storage_snapshot(member))
	var router: Node = root.get_node("SceneRouter")
	var router_session: Dictionary = {}
	for key: String in ["_battle_payload", "_field_payload", "_shop_payload", "_bounty_board_payload", "_result_payload", "_current_field_id", "_current_field_spawn", "_world_map_return_scene", "_active_world_map_scene", "_world_map_version", "_portal_return_spawns"]:
		router_session[key] = contract.snapshot_value(router.get(key))
	return {"navigation": root.get_node("SceneRouter").get_navigation_state(),
		"router_session": router_session,
		"flags": game.get("flags").duplicate(true), "gold": game.get("gold"),
		"session": session, "party": party,
		"player": contract.storage_snapshot(game.get("player")) if game.get("player") != null else {},
		"inventory": root.get_node("Inventory").to_dict(), "quests": root.get_node("QuestManager").to_dict(),
		"bounties": root.get_node("BountyManager").to_dict(), "saves": saves}

func get_probe_state() -> Dictionary:
	return {"manifest": CONTRACT.MANIFEST_PATH, "manifest_sha256": CONTRACT.MANIFEST_SHA,
		"object_ids": contract.object_ids.keys() if contract != null else [],
		"blocking_ids": contract.blocking_ids.keys() if contract != null else [],
		"interaction_anchors": contract.anchors.duplicate(true) if contract != null else {},
		"gate_foot_px": contract.gate_foot if contract != null else Vector2(INF, INF),
		"inner_foot_px": contract.inner_foot if contract != null else Vector2(INF, INF),
		"protected_unchanged": before.is_empty() or protected_state() == before,
		"canonical_unchanged": contract != null and contract.canonical_unchanged(),
		"art_approved": false, "production_route_executed": false,
		"actions": field.get("observed_actions").duplicate(true) if is_instance_valid(field) else [],
		"return_state": field.call("get_preview_return_state") if is_instance_valid(field) else {}}

func restore_preview_state() -> void:
	# Never restore gameplay/Inventory/flags to hide a failure: only the transient
	# setup Navigation write is scoped above; all other state must remain equal.
	if not before.is_empty() and protected_state() != before: push_error("Trial altered protected gameplay or save state")
	if contract != null and not contract.canonical_unchanged(): push_error("Trial altered canonical resource STORAGE")
	for saved: Dictionary in _gm_before:
		if not is_instance_valid(saved.node): continue
		if saved.has("process_mode"): saved.node.process_mode = saved.process_mode
		if saved.has("visible"): saved.node.visible = saved.visible
	_gm_before.clear()
