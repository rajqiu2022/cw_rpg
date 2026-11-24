extends Node
## Independent opt-in family addon, after native NPC._process, before drawing.
## Native movement, textures, flip, conversations and collision stay the owner.
const HOME := "res://build/npc_gait_20261101c_candidate01/"
const SELF := HOME + "npc_gait_runtime.gd"
const MANIFEST := HOME + "source_pins_READY.json"
const RULES := HOME + "gait_rules.json"
const NPC_SCRIPT := "res://scripts/field/npc_node.gd"
const NPC_SHA := "67c0f3deafef65445918b5815f4acdcb4cc577206248f20cd67a998930d00bea"
const META := "npc_gait_runtime31c_owner"
const Phase = preload("res://build/npc_gait_20261101c_candidate01/distance_phase.gd")
const WALK_SOURCES := [
	"res://art/characters/street_expansion_v2/npc_escort_guard_walk_right_8f_v1_runtime.png",
	"res://art/characters/street_expansion_v1/npc_street_merchant_right_walk_8f_v3_runtime.png",
	"res://art/characters/luoyang_city_finish_20261025i/guard_young_bluegrey_walk4_v1_runtime160.png",
	"res://art/characters/luoyang_city_finish_20261025i/guard_veteran_ochre_walk4_v1_runtime160.png"
]
var _pins: Dictionary = {}
var _families: Dictionary = {}
var _walk_families: Dictionary = {}
var _assets: Dictionary = {}
var _bounds_heights: Dictionary = {}
var _leases: Dictionary = {}
var _verified_fields: Dictionary = {}
var _manifest_sha := ""
var _ready_sources := false
var _discovery_clock := 0.0
var _discovery_seconds := 0.25
var _last_error := ""
var _attached_count := 0
var _released_count := 0

static func source_paths() -> Array[String]:
	return [SELF, HOME + "distance_phase.gd", RULES, NPC_SCRIPT,
		WALK_SOURCES[0], WALK_SOURCES[0] + ".import",
		"res://.godot/imported/npc_escort_guard_walk_right_8f_v1_runtime.png-26049427850b181f9b666a67cc0aa828.ctex",
		WALK_SOURCES[1], WALK_SOURCES[1] + ".import",
		"res://.godot/imported/npc_street_merchant_right_walk_8f_v3_runtime.png-35fc077f791e3c458a9bc26919d739dd.ctex",
		WALK_SOURCES[2], WALK_SOURCES[2] + ".import",
		"res://.godot/imported/guard_young_bluegrey_walk4_v1_runtime160.png-33c6cf258dde86fa8b2ee4355fbcd0b6.ctex",
		WALK_SOURCES[3], WALK_SOURCES[3] + ".import",
		"res://.godot/imported/guard_veteran_ochre_walk4_v1_runtime160.png-6a912af0e576bb94f34274c0eb5fea3c.ctex"]

func _ready() -> void:
	process_priority = 100
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not manifest is Dictionary or manifest.get("schema") != "NPC_GAIT_RUNTIME_20261101C_INDEPENDENT_V1" or manifest.get("ready") != true:
		_reject("GAIT31C_ROOT_FREEZE_REQUIRED"); return
	_pins = manifest.get("source_pins", {}).duplicate(true)
	for path: String in source_paths():
		if not _pins.has(path): _reject("GAIT31C_REQUIRED_SOURCE:" + path); return
	if _pins.get(NPC_SCRIPT) != NPC_SHA: _reject("GAIT31C_EXACT_NATIVE_NPC_SOURCE"); return
	_manifest_sha = FileAccess.get_sha256(MANIFEST)
	if not _sources_match(): _reject("GAIT31C_INITIAL_SOURCE_CHANGED"); return
	var rules: Variant = JSON.parse_string(FileAccess.get_file_as_string(RULES))
	if not rules is Dictionary or rules.get("schema") != "NPC_GAIT_DISTANCE_RULES_20261101C_V1" or not rules.get("families") is Dictionary or rules.families.size() != 2:
		_reject("GAIT31C_RULE_SCHEMA"); return
	_families = rules.families.duplicate(true)
	_assets = rules.get("walk_assets", {}).duplicate(true)
	if _assets.size() != WALK_SOURCES.size(): _reject("GAIT31C_COMPLETE_CURRENT_WALK_ASSETS"); return
	_discovery_seconds = float(rules.get("discovery_seconds", 0.25))
	if _discovery_seconds < 0.1 or _discovery_seconds > 1.0: _reject("GAIT31C_BOUNDED_DISCOVERY_INTERVAL"); return
	for family: String in ["guard", "merchant"]:
		var rule: Dictionary = _families.get(family, {})
		if not rule.get("allowed_original_speeds") is Array:
			_reject("GAIT31C_EXACT_FAMILY:" + family); return
		var ratio: float = float(rule.get("cycle_distance_height_ratio", 0))
		var peak: float = float(rule.get("adult_peak_speed_px_s", 0))
		var maximum: float = float(rule.get("maximum_peak_speed_px_s", 0))
		if rule.get("adult_height_px") != 140 or ratio < 0.75 or ratio > 0.9 or peak <= 0.0 or maximum < peak or maximum > 72.0:
			_reject("GAIT31C_FAMILY_SCALE_SPEED_BOUNDS:" + family); return
	for path: String in _assets:
		var asset: Dictionary = _assets[path]
		var family: String = String(asset.get("family", ""))
		var frames: int = int(asset.get("frames", 0))
		if path not in WALK_SOURCES or family not in _families or frames not in [4, 8] or not Phase.table_valid(asset.get("frame_distance_fractions", []), frames):
			_reject("GAIT31C_EXACT_ASSET_AND_DISTANCE_TABLE:" + path); return
		_walk_families[path] = family
	_ready_sources = true

func _sources_match() -> bool:
	if _pins.is_empty() or FileAccess.get_sha256(MANIFEST) != _manifest_sha: return false
	if ProjectSettings.get_setting("autoload/NPCGaitRuntime", "") != "*" + SELF: return false
	for path: String in _pins:
		if not path.begins_with("res://") or ".." in path or String(_pins[path]).length() != 64 or FileAccess.get_sha256(path) != _pins[path]: return false
	return true

func _reject(reason: String) -> void:
	_last_error = reason
	_ready_sources = false
	_release_all()
	set_process(false) # This addon only. Never disable an NPC's processing.
	push_error("[NPCGait31c] " + reason)

func _context_ready() -> bool:
	var field: Node = get_tree().current_scene
	if not is_instance_valid(field) or field.is_queued_for_deletion(): return false
	var has_loading_state := false
	for property: Dictionary in field.get_property_list():
		if property.name == "_field_loading_complete": has_loading_state = true; break
	if not has_loading_state: return false
	if field.get("_field_loading_complete") != true or field.get("_field_loading_failed") == true or field.get("_scene_rebuilding") == true: return false
	var loading: Node = get_node_or_null("/root/LoadingManager")
	return loading == null or (loading.get("_transition_active") != true and loading.get("_external_active") != true)

func _body_snapshot(npc: NPCNode) -> Dictionary:
	var body: StaticBody2D = npc.get("_body_collider") as StaticBody2D
	if body == null or body.get_child_count() != 1: return {}
	var shape: CollisionShape2D = body.get_child(0) as CollisionShape2D
	if shape == null or not shape.shape is RectangleShape2D: return {}
	var rectangle: RectangleShape2D = shape.shape as RectangleShape2D
	return {"body_instance": body.get_instance_id(), "body_position": body.position,
		"collision_layer": body.collision_layer, "collision_mask": body.collision_mask,
		"shape_instance": shape.get_instance_id(), "shape_resource_instance": rectangle.get_instance_id(),
		"shape_position": shape.position, "shape_size": rectangle.size, "shape_disabled": shape.disabled}

func _discover() -> void:
	var field: Node = get_tree().current_scene
	var field_id: int = field.get_instance_id()
	for key: int in _verified_fields.keys():
		if _verified_fields[key].get_ref() == null: _verified_fields.erase(key)
	if not _verified_fields.has(field_id):
		if not _sources_match(): _reject("GAIT31C_NEW_FIELD_SOURCE_CHANGED"); return
		_verified_fields[field_id] = weakref(field)
	for node: Node in get_tree().get_nodes_in_group("npc"):
		if not node is NPCNode or _leases.has(node.get_instance_id()): continue
		var npc: NPCNode = node as NPCNode
		if npc.get_script() == null or npc.get_script().resource_path != NPC_SCRIPT or npc.is_queued_for_deletion() or not npc.is_processing() or npc.has_meta(META): continue
		if not field.is_ancestor_of(npc) or npc.movement_mode != "patrol" or npc.patrol_axis.y != 0.0 or npc.patrol_axis.x == 0.0 or npc.patrol_distance <= 0.0 or not is_finite(npc.patrol_distance): continue
		var walk: Texture2D = npc.get("_walk_texture") as Texture2D
		if walk == null or not _walk_families.has(walk.resource_path) or npc.sprite == null or npc.sprite.texture != walk: continue
		var asset: Dictionary = _assets[walk.resource_path]
		var frames: int = int(asset.frames)
		if npc.sprite.hframes != frames or walk.get_size() != Vector2(frames * 160, 160): continue
		if npc.get("_conversation_active") == true: continue
		var family: String = _walk_families[walk.resource_path]
		var rule: Dictionary = _families[family]
		if npc.patrol_speed not in rule.allowed_original_speeds: continue
		if not _bounds_heights.has(walk.resource_path):
			# Honor the actual source-admitted 25i visible-core calibration, which
			# NPCNode already used. Do not count transparent weak-alpha margins.
			var calibrated: Variant = NPCNode._visible_bounds_cache.get(walk.get_instance_id())
			if calibrated is Rect2i and calibrated.size.y > 0:
				_bounds_heights[walk.resource_path] = calibrated.size.y
			else:
				var image: Image = walk.get_image()
				if image == null: continue
				_bounds_heights[walk.resource_path] = image.get_region(Rect2i(0, 0, 160, 160)).get_used_rect().size.y
		var height: float = float(_bounds_heights[walk.resource_path]) * absf(npc.sprite.scale.y)
		if not is_finite(height) or height <= 0.0: continue
		var peak: float = minf(float(rule.maximum_peak_speed_px_s), float(rule.adult_peak_speed_px_s) * height / 140.0)
		var cycle: float = height * float(rule.cycle_distance_height_ratio)
		var fractions: Array = asset.frame_distance_fractions.duplicate()
		var body: Dictionary = _body_snapshot(npc)
		if body.is_empty(): continue
		var state: Dictionary = {
			"npc": weakref(npc), "field": weakref(field), "id": npc.npc_id, "family": family,
			"original_speed": npc.patrol_speed, "applied_speed": peak, "height_px": height,
			"cycle_distance_px": cycle, "fractions": fractions,
			"distance_px": float(fractions[clampi(npc.sprite.frame, 0, frames - 1)]) * cycle,
			"actual_travel_px": 0.0, "last_position": npc.position, "last_ds": 0.0,
			"axis": npc.patrol_axis, "radius": npc.patrol_distance, "origin": npc.get("_patrol_origin"),
			"walk": walk, "walk_path": walk.resource_path, "frame_count": frames, "frames_sampled": 0, "zero_motion_samples": 0, "conversation_samples": 0,
			"body_initial": body, "idle_path": npc.sprite_path, "original_movement_mode": npc.movement_mode,
			"original_invert_patrol_facing": npc.invert_patrol_facing,
			"frame": npc.sprite.frame, "flip_h": npc.sprite.flip_h, "suspended": ""
		}
		npc.patrol_speed = peak
		npc.set_meta(META, get_instance_id())
		_leases[npc.get_instance_id()] = state
		_attached_count += 1

func _release(key: int, reason: String) -> void:
	if not _leases.has(key): return
	var state: Dictionary = _leases[key]
	var npc: NPCNode = state.npc.get_ref() as NPCNode
	if is_instance_valid(npc) and npc.get_meta(META, 0) == get_instance_id():
		# Never overwrite a foreign story/control system's later speed decision.
		if npc.patrol_speed == float(state.applied_speed): npc.patrol_speed = float(state.original_speed)
		npc.remove_meta(META)
	_leases.erase(key)
	_released_count += 1

func _release_all() -> void:
	for key: int in _leases.keys(): _release(key, "OWNER_RELEASE")

func _process(delta: float) -> void:
	if not _ready_sources: return
	var live: bool = _context_ready()
	_discovery_clock += delta
	if live and _discovery_clock >= _discovery_seconds:
		_discovery_clock = fmod(_discovery_clock, _discovery_seconds)
		_discover()
	for key: int in _leases.keys():
		var state: Dictionary = _leases[key]
		var npc: NPCNode = state.npc.get_ref() as NPCNode
		var field: Node = state.field.get_ref() as Node
		if not is_instance_valid(npc) or not is_instance_valid(field) or field != get_tree().current_scene or npc.is_queued_for_deletion(): _release(key, "FIELD_OR_ACTOR_LEFT"); continue
		if npc.get_script() == null or npc.get_script().resource_path != NPC_SCRIPT or npc.get_meta(META, 0) != get_instance_id() or npc.movement_mode != "patrol" or npc.patrol_axis != state.axis or npc.patrol_distance != state.radius or npc.get("_patrol_origin") != state.origin or npc.get("_walk_texture") != state.walk or npc.patrol_speed != float(state.applied_speed):
			_release(key, "NATIVE_OR_FOREIGN_OWNER_CHANGED"); continue
		var previous: Vector2 = state.last_position
		state.last_position = npc.position
		state.last_ds = 0.0
		if not live or not npc.is_processing(): state.suspended = "FIELD_LOADING_OR_NATIVE_PAUSED"; continue
		if npc.get("_conversation_active") == true or npc.get("_conversation_freeze_frame") == true:
			state.suspended = "NATIVE_CONVERSATION"; state.conversation_samples += 1; continue
		if npc.sprite == null or npc.sprite.texture != state.walk or npc.sprite.hframes != int(state.frame_count):
			state.suspended = "NATIVE_NONWALK_VISUAL"; continue
		var ds: float = absf((npc.position - previous).dot(npc.patrol_axis.normalized()))
		if not is_finite(ds) or ds > maxf(8.0, float(state.applied_speed) * maxf(delta, 0.0) * 2.0 + 2.0):
			state.suspended = "TELEPORT_SAMPLE_NOT_ANIMATED"; continue
		state.suspended = ""
		state.last_ds = ds
		state.actual_travel_px += ds
		state.distance_px += ds
		var frame: int = Phase.frame_for_distance(float(state.distance_px), float(state.cycle_distance_px), state.fractions)
		npc.sprite.frame = frame # Only visual write; no texture/flip/position change.
		state.frame = frame
		state.flip_h = npc.sprite.flip_h
		state.frames_sampled += 1
		if ds == 0.0: state.zero_motion_samples += 1

func _exit_tree() -> void:
	_release_all()

func get_debug_state() -> Dictionary:
	var actors: Array[Dictionary] = []
	for state: Dictionary in _leases.values():
		var copy: Dictionary = state.duplicate(true)
		var npc: NPCNode = state.npc.get_ref() as NPCNode
		if is_instance_valid(npc):
			copy["position"] = npc.position
			copy["body_current"] = _body_snapshot(npc)
			copy["body_typed_identical"] = var_to_bytes(copy.body_current) == var_to_bytes(state.body_initial)
			copy["actual_frame"] = npc.sprite.frame if npc.sprite != null else -1
			copy["actual_flip_h"] = npc.sprite.flip_h if npc.sprite != null else false
			copy["conversation_active"] = npc.get("_conversation_active") == true
		copy.erase("npc"); copy.erase("field"); copy.erase("walk")
		actors.append(copy)
	return {"ready": _ready_sources, "last_error": _last_error, "process_priority": process_priority, "attached_count": _attached_count, "released_count": _released_count, "actors": actors, "native_position_writes": 0, "npc_process_disabled": false, "save_access": false, "initial_stride_table_not_visual_acceptance": true}
