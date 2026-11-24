extends RefCounted
## Independent view only: no compiled/source mutation, NPC script replacement,
## process suppression, dialogue dispatch, physics edit or save access.
const FIELD := "res://build/luoyang_regions_20261027d_source01/region_field.gd"
const NPC_SCRIPT := "res://scripts/field/npc_node.gd"
const ROOM := "yihongyuan27n_interior"
const LOGICAL := "ch4_s3_luoyang_market"
const HOME := "res://build/luoyang_quality_20261101b_seated01/"
const YIHONG_NATIVE_SCRIPT := "res://build/interior_identity_20261107_runtime01/native_actor.gd"
const YIHONG_NATIVE_IDS := ["yihongyuan27n_musician", "yihongyuan27n_singer", "yihongyuan27n_tea_attendant", "yihongyuan27n_receptionist"]
const RECEIPT_META := "quality_20261101b_seated"
const IDS := ["yihongyuan27n_matron", "yihongyuan27n_waiter", "yihongyuan27n_merchant", "yihongyuan27n_scholar", "yihongyuan27n_elder_guest", "yihongyuan27n_woman_guest"]
const POSES := {
	"yihongyuan27n_elder_guest": {
		"source": "res://art/characters/npc_inn_tea_guest_left_seated_idle_down_25d_4f_v2_runtime.png",
		"pose": HOME + "elder_front_pose.tres"
	},
	"yihongyuan27n_woman_guest": {
		"source": "res://art/characters/npc_inn_tea_guest_right_seated_idle_down_25d_4f_v2_runtime.png",
		"pose": HOME + "woman_front_pose.tres"
	}
}

## Root's independent view-source pins must cover these files, not room.sources.
static func source_paths() -> Array[String]:
	var paths: Array[String] = [HOME + "live_seated_view.gd", NPC_SCRIPT, "res://scenes/npc_node.tscn"]
	for id: String in POSES:
		var image: String = POSES[id].source
		paths.append(POSES[id].pose)
		paths.append(image)
		paths.append(image + ".import")
	paths.append("res://.godot/imported/npc_inn_tea_guest_left_seated_idle_down_25d_4f_v2_runtime.png-723e3baae1d49ac51e434aaeb064eb9d.ctex")
	paths.append("res://.godot/imported/npc_inn_tea_guest_right_seated_idle_down_25d_4f_v2_runtime.png-82eb0b48b1f08fdbf9bf2643543c1f80.ctex")
	return paths

static func _fail(reason: String) -> Dictionary:
	return {"ok": false, "applied": false, "error": reason}

static func _body_state(npc: NPCNode) -> Dictionary:
	var body: StaticBody2D = npc.get("_body_collider") as StaticBody2D
	if body == null or body.get_child_count() != 1: return {}
	var shape: CollisionShape2D = body.get_child(0) as CollisionShape2D
	if shape == null or not shape.shape is RectangleShape2D: return {}
	var rectangle: RectangleShape2D = shape.shape as RectangleShape2D
	return {
		"npc_instance": npc.get_instance_id(), "parent_instance": npc.get_parent().get_instance_id(),
		"position": npc.position, "global_position": npc.global_position, "transform": npc.transform,
		"sprite_scale_property": npc.sprite_scale, "sprite_scale": npc.sprite.scale,
		"sprite_position": npc.sprite.position, "sprite_flip_h": npc.sprite.flip_h,
		"body_instance": body.get_instance_id(), "body_transform": body.transform,
		"body_global_transform": body.global_transform, "collision_layer": body.collision_layer,
		"collision_mask": body.collision_mask, "shape_instance": shape.get_instance_id(),
		"shape_transform": shape.transform, "shape_disabled": shape.disabled,
		"shape_resource_instance": shape.shape.get_instance_id(), "shape_size": rectangle.size,
		"process_mode": npc.process_mode, "processing": npc.is_processing(),
		"movement_mode": npc.movement_mode, "npc_id": npc.npc_id, "npc_name": npc.npc_name,
		"dialog_id": npc.dialog_id, "interaction_action": npc.interaction_action,
		"portrait_path": npc.portrait_path, "dialog_variants": npc.dialog_variants.duplicate(true),
		"conversation_base_facing": npc.conversation_base_facing,
		"interaction_area_instance": npc.interact_area.get_instance_id(),
		"interaction_monitoring": npc.interact_area.monitoring,
		"interaction_monitorable": npc.interact_area.monitorable
	}

static func attach(field: Node) -> Dictionary:
	if not is_instance_valid(field) or not field.is_inside_tree() or field.get_script() == null or field.get_script().resource_path != FIELD:
		return _fail("SEATED_EXACT_FIELD")
	if field.get("_field_loading_complete") != true or field.get("_field_loading_failed") == true or field.get("_scene_rebuilding") == true:
		return _fail("SEATED_FIELD_NOT_READY")
	var region: Variant = field.get("_region")
	if not region is Dictionary or region.get("id") != ROOM or not region.get("npcs") is Array:
		return _fail("SEATED_EXACT_ROOM")
	var upgraded: bool = region.get("interior_identity_20261107","") == "YIHONG_NATIVE_ROOM_20261107_V1"
	var expected_count := 10 if upgraded else 6
	if region.npcs.size() != expected_count: return _fail("SEATED_EXACT_ROOM_ROWS")
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	if scene == null or String(scene.scene_id) != ROOM: return _fail("SEATED_EXACT_CURRENT_SCENE")
	var actors: Variant = field.get("_region_actors")
	var live_npcs: Variant = field.get("_npc_nodes")
	if not actors is Dictionary or actors.size() != expected_count or not live_npcs is Array or live_npcs.size() != expected_count:
		return _fail("SEATED_EXACT_LIVE_ACTORS")
	var new_seen: Dictionary = {}
	var by_id: Dictionary = {}
	var all_before: Dictionary = {}
	for row: Dictionary in region.npcs:
		var id: String = String(row.get("data", {}).get("npc_id", ""))
		var key: String = LOGICAL + "/" + id
		if row.get("logical_id") != LOGICAL or row.get("slot_key") != key:
			return _fail("SEATED_SOURCE_IDS_OR_SLOTS")
		if id not in IDS:
			var native: NPCNode = actors.get(key, {}).get("node") as NPCNode
			if not upgraded or id not in YIHONG_NATIVE_IDS or new_seen.has(id) or not is_instance_valid(native) or native not in live_npcs or native.npc_id != id or native.get_script() == null or native.get_script().resource_path != YIHONG_NATIVE_SCRIPT or native.call("native_grid_ready") != true:
				return _fail("SEATED_UNDECLARED_NEW_ACTOR:" + id)
			new_seen[id] = true
			continue
		if by_id.has(id): return _fail("SEATED_DUPLICATE_ORIGINAL_ID")
		var npc: NPCNode = actors.get(key, {}).get("node") as NPCNode
		if not is_instance_valid(npc) or npc not in live_npcs or npc.get_parent() != field.get("_actor_layer") or npc.npc_id != id:
			return _fail("SEATED_SOURCE_TO_LIVE_NODE:" + id)
		if npc.get_script() == null or npc.get_script().resource_path != NPC_SCRIPT:
			return _fail("SEATED_ORIGINAL_NPC_SCRIPT:" + id)
		if npc.get_meta("region27d_logical_id", "") != LOGICAL or npc.get_meta("region27d_slot_key", "") != key or npc.sprite == null:
			return _fail("SEATED_LIVE_IDENTITY_METADATA:" + id)
		var state: Dictionary = _body_state(npc)
		if state.is_empty(): return _fail("SEATED_LIVE_BODY:" + id)
		all_before[id] = state
		by_id[id] = npc
	if by_id.size() != 6 or new_seen.size() != expected_count - 6: return _fail("SEATED_EXACT_ROSTER_PARTITIONS")
	# No source dictionaries, room.sources or the four speaking adults are edited.
	var room_before: PackedByteArray = var_to_bytes(region)
	var pending: Array[Dictionary] = []
	var already: bool = field.has_meta(RECEIPT_META)
	for id: String in POSES:
		var npc: NPCNode = by_id[id] as NPCNode
		var rows: Array = region.npcs.filter(func(row: Dictionary) -> bool: return row.data.npc_id == id)
		var data: Dictionary = rows[0].data
		var paths: Dictionary = POSES[id]
		if data.get("sprite_path") != paths.source or data.get("movement_mode") != "seated" or data.get("conversation_base_facing") != "front":
			return _fail("SEATED_ORIGINAL_SOURCE_ROW:" + id)
		if npc.sprite_path != paths.source or npc.movement_mode != "seated" or npc.conversation_base_facing != "front" or npc.get("_calibrate_adult_body") == true or npc.get("_ground_anchored") != true:
			return _fail("SEATED_EXISTING_AUTHORED_MODE:" + id)
		if not npc.dialog_id.is_empty() or not npc.interaction_action.is_empty() or region.get("yihongyuan_daily", {}).has(id) or npc.get("_conversation_active") == true:
			return _fail("SEATED_AMBIENT_NO_DIALOG_SUPPRESSION:" + id)
		var texture: AtlasTexture = load(paths.pose) as AtlasTexture
		if texture == null or texture.atlas == null or texture.atlas.resource_path != paths.source or texture.region != Rect2(160, 0, 160, 160) or texture.margin != Rect2() or not texture.filter_clip or texture.get_size() != Vector2(160, 160):
			return _fail("SEATED_EXACT_ATLAS_POSE:" + id)
		if already:
			if npc.sprite.texture != texture or npc.get("_idle_texture") != texture or npc.get("_hframes") != 1 or npc.sprite.hframes != 1 or npc.sprite.frame != 0:
				return _fail("SEATED_EXISTING_VIEW_DRIFT:" + id)
		else:
			if npc.sprite.texture == null or npc.sprite.texture.resource_path != paths.source or npc.get("_idle_texture") != npc.sprite.texture or npc.sprite.texture.get_size() != Vector2(640, 160) or npc.sprite.hframes != 4 or npc.sprite.flip_h:
				return _fail("SEATED_ORIGINAL_LIVE_STRIP:" + id)
		pending.append({"id": id, "npc": npc, "texture": texture, "before_texture": npc.sprite.texture})
	if already:
		return {"ok": true, "applied": false, "already_attached": true, "receipt": field.get_meta(RECEIPT_META).duplicate(true)}
	for work: Dictionary in pending:
		(work.npc as NPCNode).apply_runtime_idle_texture(work.texture)
	var all_after: Dictionary = {}
	for id: String in by_id: all_after[id] = _body_state(by_id[id] as NPCNode)
	var unchanged: bool = var_to_bytes(all_before) == var_to_bytes(all_after) and var_to_bytes(region) == room_before
	for work: Dictionary in pending:
		var npc: NPCNode = work.npc as NPCNode
		unchanged = unchanged and npc.sprite.texture == work.texture and npc.get("_idle_texture") == work.texture and npc.get("_hframes") == 1 and npc.sprite.hframes == 1 and npc.sprite.frame == 0
	if not unchanged:
		for work: Dictionary in pending: (work.npc as NPCNode).apply_runtime_idle_texture(work.before_texture)
		return _fail("SEATED_PUBLIC_API_BODY_OR_SOURCE_CHANGED_ROLLED_BACK")
	var receipt: Dictionary = {
		"ok": true, "room_id": ROOM, "field_instance": field.get_instance_id(),
		"changed_actor_ids": POSES.keys(), "frame_region": Rect2(160, 0, 160, 160),
		"before": all_before, "after": all_after, "all_six_bodies_positions_dialogues_identical": true,
		"compiled_room_typed_identical": true, "room_sources_writes": 0,
		"api": "NPCNode.apply_runtime_idle_texture", "new_pngs": 0, "process_suppression": false
	}
	field.set_meta(RECEIPT_META, receipt)
	return {"ok": true, "applied": true, "receipt": receipt.duplicate(true)}
