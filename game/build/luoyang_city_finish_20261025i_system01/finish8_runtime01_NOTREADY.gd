extends RefCounted
## Exact eight terminal overlay leases. Original Scene/Layout/storage are never mutated.
## Root publication/import/independent prior and original producer FIRST/FINAL are prerequisites.
const FORMAL_READY := false
const SELF := "res://build/luoyang_city_finish_20261025i_system01/finish8_runtime01_NOTREADY.gd"
const BIND := "res://build/luoyang_city_finish_20261025i_system01/finish8_binding01_NOTREADY.json"
const BIND_SHA := "PENDING_ROOT_FINAL_BINDING_SHA"
const FIELD := "res://scripts/field/field_walkable_controller.gd"
const IDS := ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market","ch4_s4_ancient_temple","luoyang_estate_riverside_20261021ai","luoyang_artisan_residential_20261022ap","luoyang_riverside_garden_20261022ap"]
static var _states: Dictionary = {}
static var _config: Dictionary = {}
var _state: Dictionary = {}
var _field_ref: WeakRef
var _revision: int = -1
var error: String = ""

static func requested(id: StringName) -> bool:
	return String(id) in IDS

static func _sha(bytes: PackedByteArray) -> String:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256);h.update(bytes)
	return h.finish().hex_encode()

static func _fingerprint(value: Variant) -> String:
	return _sha(var_to_bytes(value))

static func _hash(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for c: String in value:
		if c not in "0123456789abcdef": return false
	return true

static func _binding() -> Dictionary:
	if not FORMAL_READY or not _hash(BIND_SHA) or FileAccess.get_sha256(BIND) != BIND_SHA: return {}
	if not _config.is_empty(): return _config
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(BIND))
	if not raw is Dictionary or raw.get("ready") != true or raw.get("schema") != "LUOYANG_FINISH25I_FULL_EFFECTIVE_OVERLAY_V1" or not raw.get("scenes") is Dictionary or raw.scenes.size() != 8: return {}
	for id: String in IDS:
		var row: Variant = raw.scenes.get(id)
		if not row is Dictionary: return {}
		for key: String in ["payload","mask","publication_completion","independent_prior","trial","fingerprints","required_source_sha256","required_original_source_sha256"]:
			if not row.get(key) is Dictionary or row[key].is_empty(): return {}
		if row.trial.get("admitted") != true: return {}
		for artifact: String in ["payload","mask","publication_completion","independent_prior","trial"]:
			if not row[artifact].get("path") is String or not _hash(row[artifact].get("sha256")) or row.required_source_sha256.get(row[artifact].path) != row[artifact].sha256: return {}
		for media: String in ["import_path","compiled_path"]:
			if not row.mask.get(media) is String or not row.required_source_sha256.has(row.mask[media]): return {}
		if not _hash(row.mask.get("RGBA_sha256")) or not row.get("world_size_px") is Array or row.world_size_px.size() != 2: return {}
		for path: String in row.required_source_sha256:
			if not path.begins_with("res://") or ".." in path or not _hash(row.required_source_sha256[path]): return {}
	_config = raw
	return _config

static func source_paths_for(id: StringName) -> Dictionary:
	var config: Dictionary = _binding()
	if not requested(id) or config.is_empty(): return {}
	var out: Dictionary = {SELF:true,BIND:true}
	for path: String in config.scenes[String(id)].required_source_sha256: out[path] = true
	return out

static func _current(scene: SceneScript) -> Dictionary:
	if scene == null or scene.map_layout == null: return {}
	var state: Dictionary = _states.get(scene.get_instance_id(),{})
	if state.is_empty() or state.scene.get_ref() != scene or state.layout.get_ref() != scene.map_layout or state.get("released",true): return {}
	return state

static func _receipt(scene: SceneScript,receipt: Dictionary,final: bool = false) -> bool:
	if scene == null or scene.map_layout == null or receipt.get("cold_storage_validated") != true or receipt.get("scene_instance") != scene.get_instance_id() or receipt.get("layout_instance") != scene.map_layout.get_instance_id(): return false
	if not receipt.get("owner_kind") is String or receipt.owner_kind.is_empty() or not receipt.get("owner_key") is String or receipt.owner_key.is_empty() or typeof(receipt.get("token")) != TYPE_INT or receipt.token <= 0: return false
	if not receipt.get("source_first") is Dictionary or receipt.source_first.is_empty(): return false
	return not final or (receipt.get("finalized") == true and receipt.get("source_final") is Dictionary and receipt.source_final == receipt.source_first)

static func _payload_valid(payload: Dictionary,row: Dictionary,id: String,parent_nav: Array,parent_blockers: Array) -> bool:
	if payload.get("scene_id") != id or payload.get("world_size_px") != Vector2(float(row.world_size_px[0]),float(row.world_size_px[1])): return false
	for key: String in ["parent_navigation","parent_blockers","effective_navigation","parent_solids","effective_solids","visual_patches","visual_additions","visual_retired","portal_before","portal_after","interaction_patches","npc_migrations","new_NPCs"]:
		if not payload.get(key) is Array: return false
	if var_to_bytes(payload.parent_navigation) != var_to_bytes(parent_nav) or var_to_bytes(payload.parent_blockers) != var_to_bytes(parent_blockers): return false
	if payload.effective_navigation.is_empty() or payload.effective_solids.is_empty(): return false
	for points: Variant in payload.effective_solids:
		if not points is PackedVector2Array or points.size() < 3: return false
		for point: Vector2 in points:
			if not point.is_finite(): return false
	for key: String in ["parent_navigation","parent_blockers","effective_navigation","parent_solids","effective_solids","visual_patches","visual_additions","visual_retired","portal_before","portal_after","interaction_patches","npc_migrations","new_NPCs"]:
		if not _hash(row.fingerprints.get(key)) or _fingerprint(payload[key]) != row.fingerprints[key]: return false
	return payload.get("restore_contract") is Dictionary and payload.restore_contract.get("whole_typed_inverse_verified") == true

static func ensure(scene: SceneScript,parent_nav: Array,parent_blockers: Array,original: Dictionary) -> bool:
	if not FORMAL_READY or not requested(scene.scene_id) or not _receipt(scene,original): return false
	var config: Dictionary = _binding()
	if config.is_empty(): return false
	var row: Dictionary = config.scenes[String(scene.scene_id)]
	for path: String in row.required_original_source_sha256:
		if original.source_first.get(path) != row.required_original_source_sha256[path]: return false
	var previous: Dictionary = _current(scene)
	if not previous.is_empty():
		return previous.owner_key == original.owner_key and previous.token == original.token and previous.first == original.source_first and var_to_bytes(previous.payload.parent_navigation) == var_to_bytes(parent_nav) and var_to_bytes(previous.payload.parent_blockers) == var_to_bytes(parent_blockers)
	for key: int in _states.keys():
		if _states[key].scene.get_ref() == null or _states[key].layout.get_ref() == null: _states.erase(key)
	if _states.size() >= 8: return false
	var captured: Dictionary = {}
	for path: String in row.required_source_sha256:
		captured[path] = FileAccess.get_sha256(path)
		if captured[path] != row.required_source_sha256[path]: return false
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(row.payload.path)
	if bytes.size() != int(row.payload.get("bytes",-1)) or _sha(bytes) != row.payload.sha256: return false
	var raw: Variant = bytes_to_var(bytes,false)
	if not raw is Dictionary or not _payload_valid(raw,row,String(scene.scene_id),parent_nav,parent_blockers): return false
	var texture: Texture2D = load(String(row.mask.path)) as Texture2D
	var mask: Image = texture.get_image() if texture != null else null
	var expected_size := Vector2i(int(row.world_size_px[0]),int(row.world_size_px[1]))
	if texture == null or texture.resource_path != row.mask.path or mask == null or mask.is_empty() or mask.get_size() != expected_size or mask.has_mipmaps() or mask.get_format() not in [Image.FORMAT_RGB8,Image.FORMAT_RGBA8]: return false
	if mask.get_format() == Image.FORMAT_RGB8: mask.convert(Image.FORMAT_RGBA8)
	if _sha(mask.get_data()) != row.mask.RGBA_sha256: return false
	var prepared: Array = []
	for points: PackedVector2Array in raw.effective_solids:
		var low: Vector2 = points[0];var high: Vector2 = low
		for p: Vector2 in points: low = low.min(p);high = high.max(p)
		prepared.append({"points":points,"bounds":Rect2(low,high-low)})
	_states[scene.get_instance_id()] = {"scene":weakref(scene),"layout":weakref(scene.map_layout),"owner_kind":original.owner_kind,"owner_key":original.owner_key,"token":original.token,"first":original.source_first.duplicate(true),"captured":captured,"binding_sha":BIND_SHA,"payload":raw,"payload_sha":_fingerprint(raw),"mask":mask,"texture":texture,"mask_sha":row.mask.RGBA_sha256,"prepared":prepared,"field":null,"finalized":false,"released":false,"boundary_checks":0}
	return true

func acquire(field: Node,scene: SceneScript,parent_nav: Array,parent_blockers: Array) -> bool:
	if not is_instance_valid(field) or field.get_script().resource_path != FIELD or field.scene_file_path != "res://scenes/field_walkable.tscn" or field.get("_current_scene") != scene or field.get("_scene_rebuilding") != true: return _reject("FIELD_ACQUIRE_OWNER")
	var state: Dictionary = _current(scene)
	if state.is_empty() or var_to_bytes(state.payload.parent_navigation) != var_to_bytes(parent_nav) or var_to_bytes(state.payload.parent_blockers) != var_to_bytes(parent_blockers): return _reject("FIELD_ACQUIRE_COLD_PARENT")
	var existing: WeakRef = state.field
	if existing != null and is_instance_valid(existing.get_ref()) and existing.get_ref() != field: return _reject("FIELD_ACQUIRE_ALREADY_OWNED")
	_field_ref = weakref(field);_state = state;_revision = int(field.get("_city3_motion_revision"));state.field = _field_ref
	return _owned(true,true)

func _owned(setup: bool = false,park: bool = false) -> bool:
	var field: Node = _field_ref.get_ref() if _field_ref != null else null
	if _state.is_empty() or not is_instance_valid(field) or _state.get("released",true) or not field.is_inside_tree() or field.get_script().resource_path != FIELD or int(field.get("_city3_motion_revision")) != _revision: return false
	var scene: SceneScript = _state.scene.get_ref()
	if scene == null or field.get("_current_scene") != scene or scene.map_layout != _state.layout.get_ref() or _current(scene) != _state or _state.field != _field_ref: return false
	if field.get("_field_loading_failed") == true: return false
	if field.get("_resident_parked") == true: return park and _state.finalized
	var current: Node = field.get_tree().current_scene
	if current == field: return (setup and field.get("_scene_rebuilding") == true) or (field.get("_scene_rebuilding") == false and _state.finalized)
	return setup and current == null and field.get_parent() == field.get_tree().root and field.get("_scene_rebuilding") == true and SceneRouter.get_current_field_id() == scene.scene_id

func project_render(before: Array) -> Array:
	if not _owned(true): return []
	var payload: Dictionary = _state.payload
	var out: Array = []
	var seen: Dictionary = {}
	var changed: Dictionary = {}
	var retired: Dictionary = {}
	for patch: Dictionary in payload.visual_patches:
		if changed.has(String(patch.id)) or not patch.get("before") is Dictionary or not patch.get("after") is Dictionary or String(patch.before.get("id","")) != String(patch.id) or String(patch.after.get("id","")) != String(patch.id): return []
		changed[String(patch.id)] = patch
	for old: Dictionary in payload.visual_retired:
		if retired.has(String(old.id)) or changed.has(String(old.id)): return []
		retired[String(old.id)] = old.before
	for row: Dictionary in before:
		var id: String = String(row.get("id",""))
		if id.is_empty() or seen.has(id): return []
		seen[id] = true
		if retired.has(id):
			if var_to_bytes(row) != var_to_bytes(retired[id]): return []
			continue
		if changed.has(id):
			if var_to_bytes(row) != var_to_bytes(changed[id].before): return []
			out.append(changed[id].after)
		else: out.append(row)
	# Existing task-visible absence is preserved; no forced count or creation of an absent target.
	for row: Dictionary in payload.visual_additions:
		var id: String = String(row.get("id",""))
		if id.is_empty() or seen.has(id): return []
		seen[id] = true;out.append(row)
	return out

func navigation() -> Array:
	return _state.payload.effective_navigation if _owned(true) else []

func effective_mask() -> Image:
	return _state.mask if _owned(true,true) else null

func project_portals(before: Array) -> Array:
	if not _owned(true) or var_to_bytes(before) != var_to_bytes(_state.payload.portal_before): return []
	return _state.payload.portal_after

func project_interactions(before: Array) -> Dictionary:
	if not _owned(true): return {"ok":false}
	var out: Array = before.duplicate(true)
	for patch: Dictionary in _state.payload.interaction_patches:
		var count: int = 0
		for i: int in range(out.size()):
			if String(out[i].get("id","")) != String(patch.id): continue
			if var_to_bytes(out[i]) != var_to_bytes(patch.before): return {"ok":false}
			out[i] = patch.after;count += 1
		if count != 1: return {"ok":false}
	return {"ok":true,"rows":out}

func project_npcs(before: Array) -> Dictionary:
	if not _owned(true,true): return {"ok":false}
	var out: Array = before.duplicate(true)
	var size: Vector2 = _state.payload.world_size_px
	for move: Dictionary in _state.payload.npc_migrations:
		var count: int = 0
		for row: Dictionary in out:
			if String(row.get("npc_id","")) != String(move.npc_id): continue
			if not row.get("pos") is Vector2 or row.pos != Vector2(float(move.old_source_origin_px[0]),float(move.old_source_origin_px[1]))/size: return {"ok":false}
			row.pos = Vector2(float(move.new_source_origin_px[0]),float(move.new_source_origin_px[1]))/size;count += 1
		if count != 1: return {"ok":false}
	for row: Dictionary in _state.payload.new_NPCs:
		for existing: Dictionary in out:
			if existing.get("npc_id") == row.get("npc_id"): return {"ok":false}
		out.append(row.duplicate(true))
	return {"ok":true,"rows":out}

func install_static(parent: Node2D) -> Dictionary:
	if not _owned(true) or not is_instance_valid(parent) or parent.get_parent() != (_field_ref.get_ref() as Node).get("world_container") or parent.transform != Transform2D.IDENTITY: return {"ok":false}
	var bodies: Array = []
	var ordinal: int = 0
	for points: PackedVector2Array in _state.payload.effective_solids:
		var body := StaticBody2D.new()
		body.name = "Finish25iStatic_"+str(ordinal);body.collision_layer = 1;body.collision_mask = 0
		body.set_meta("finish25i_source_ordinal",ordinal)
		var collision := CollisionPolygon2D.new()
		collision.polygon = points
		body.add_child(collision);parent.add_child(body);bodies.append(body);ordinal += 1
	return {"ok":true,"bodies":bodies}

static func _safe(state: Dictionary,foot: Vector2,half: Vector2) -> bool:
	var mask: Image = state.mask
	if not foot.is_finite() or foot.x < half.x or foot.y < half.y or roundi(foot.x+half.x) >= mask.get_width() or roundi(foot.y+half.y) >= mask.get_height(): return false
	var rect := Rect2(foot-half,half*2)
	var body := PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	for row: Dictionary in state.prepared:
		if not row.bounds.intersects(rect,true): continue
		if not Geometry2D.intersect_polygons(body,row.points).is_empty(): return false
		for point: Vector2 in body:
			if Geometry2D.is_point_in_polygon(point,row.points): return false
		for point: Vector2 in row.points:
			if point.x >= rect.position.x and point.x <= rect.end.x and point.y >= rect.position.y and point.y <= rect.end.y: return false
	for y: int in range(roundi(rect.position.y),roundi(rect.end.y)+1):
		for x: int in range(roundi(rect.position.x),roundi(rect.end.x)+1):
			var color: Color = mask.get_pixel(x,y)
			if color.r < .5 or color.a < .5: return false
	return true

static func safe_body(scene: SceneScript,foot: Vector2,half: Vector2 = Vector2(17,12)) -> bool:
	var state: Dictionary = _current(scene)
	return not state.is_empty() and _safe(state,foot,half)

func safe_foot(foot: Vector2,full: bool = true) -> bool:
	return _owned(true,true) and _safe(_state,foot,Vector2(17,12))

func safe_motion(from: Vector2,to: Vector2) -> bool:
	if not _owned(true,true): return false
	var steps: int = maxi(1,ceili(from.distance_to(to)/4.0))
	for i: int in range(steps+1):
		if not _safe(_state,from.lerp(to,float(i)/float(steps)),Vector2(17,12)): return false
	return true

func revalidate_boundary() -> bool:
	if not _owned(true,true): return false
	if _state.binding_sha != BIND_SHA or _sha((_state.mask as Image).get_data()) != _state.mask_sha or _fingerprint(_state.payload) != _state.payload_sha: return _reject("CACHED_EFFECTIVE_GEOMETRY_OR_MASK_DRIFT")
	_state.boundary_checks += 1
	return true

func finalize(scene: SceneScript,original: Dictionary) -> bool:
	if not _owned(true) or not _receipt(scene,original,true) or original.owner_key != _state.owner_key or original.token != _state.token or original.source_first != _state.first: return _reject("ORIGINAL_FINAL_OWNER_OR_SOURCE_CHANGED")
	if not revalidate_boundary(): return false
	var row: Dictionary = _config.scenes[String(scene.scene_id)]
	for path: String in _state.captured:
		if FileAccess.get_sha256(path) != _state.captured[path] or _state.captured[path] != row.required_source_sha256[path]: return _reject("NEW_OVERLAY_FINAL_SOURCE_CHANGED")
	_state.finalized = true
	return true

func state() -> Dictionary:
	return {} if _state.is_empty() else {"scene_instance":(_state.scene.get_ref() as SceneScript).get_instance_id(),"owner_kind":_state.owner_kind,"owner_key":_state.owner_key,"token":_state.token,"finalized":_state.finalized,"binding_sha":_state.binding_sha,"solid_count":_state.payload.effective_solids.size(),"mask":_state.mask,"boundary_checks":_state.boundary_checks}

static func state_for(scene: SceneScript) -> Dictionary:
	var value: Dictionary = _current(scene)
	return {} if value.is_empty() else {"owner_key":value.owner_key,"token":value.token,"finalized":value.finalized,"scene_instance":scene.get_instance_id(),"layout_instance":scene.map_layout.get_instance_id()}

func _reject(reason: String) -> bool:
	error = reason
	return false

func release() -> void:
	if not _state.is_empty():
		_state.released = true
		var scene: SceneScript = _state.scene.get_ref()
		if scene != null: _states.erase(scene.get_instance_id())
	_state = {};_field_ref = null
