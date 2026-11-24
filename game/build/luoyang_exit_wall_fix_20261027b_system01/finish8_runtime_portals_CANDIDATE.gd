extends RefCounted
## Exact eight terminal overlay leases. Original Scene/Layout/storage are never mutated.
## Root publication/import/independent prior and original producer FIRST/FINAL are prerequisites.
const FORMAL_READY := true
const SELF := "res://build/luoyang_city_finish_20261025i_source01/seven_fields_layout_repair01/closure_READY01/finish8_runtime_READY.gd"
const BIND := "res://build/luoyang_city_finish_20261025i_source01/seven_fields_layout_repair01/closure_READY01/finish8_binding_READY.json"
const BIND_SHA := "81e0dadde05836848e85740a689eb7907d1bc72cf65f730e464a1941a96c9759"
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
		if row.trial.get("admitted") != true or row.trial.get("permission_kind") != "TRIAL_PERMISSION_NOT_RESULT": return {}
		for artifact: String in ["payload","publication_completion","independent_prior","trial"]:
			if not row[artifact].get("path") is String or not _hash(row[artifact].get("sha256")) or row.required_source_sha256.get(row[artifact].path) != row[artifact].sha256: return {}
		if id == "ch4_s4_ancient_temple":
			if row.mask.get("kind") != "SOURCE_POLYGON_ONLY": return {}
		else:
			if row.mask.get("kind") != "IMPORTED_RGBA8" or not row.mask.get("path") is String or not _hash(row.mask.get("sha256")) or row.required_source_sha256.get(row.mask.path) != row.mask.sha256: return {}
			for media: String in ["import_path","compiled_path"]:
				if not row.mask.get(media) is String or not row.required_source_sha256.has(row.mask[media]): return {}
			if not _hash(row.mask.get("RGBA_sha256")): return {}
		if not row.get("world_size_px") is Array or row.world_size_px.size() != 2: return {}
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

static func discard_unfinalized_original(scene: SceneScript,layout: Resource,kind: String,original: Dictionary) -> bool:
	# Failure recovery only: never clear a live/FINAL lease or manufacture original proof.
	if scene==null or layout==null or scene.map_layout!=layout: return false
	if kind=="QUARTER_ORIGINAL":
		if scene.scene_id not in [&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"]: return false
	elif kind=="ESTATE_ORIGINAL":
		if scene.scene_id!=&"luoyang_estate_riverside_20261021ai": return false
	else: return false
	if original.get("finalized")==true or typeof(original.get("serial"))!=TYPE_INT or int(original.serial)<=0 or not original.get("key") is String or String(original.key).is_empty() or not original.get("source_first") is Dictionary or original.source_first.is_empty(): return false
	if not _states.has(scene.get_instance_id()): return true
	var pending: Dictionary=_states[scene.get_instance_id()]
	if not pending.get("scene") is WeakRef or not pending.get("layout") is WeakRef or pending.scene.get_ref()!=scene or pending.layout.get_ref()!=layout: return false
	if pending.get("owner_kind")!=kind or pending.get("owner_key")!=original.key or pending.get("token")!=original.serial or var_to_bytes(pending.get("first"))!=var_to_bytes(original.source_first): return false
	if pending.get("field")!=null or pending.get("finalized")!=false or pending.get("released")!=false: return false
	_states.erase(scene.get_instance_id())
	return true

static func _receipt(scene: SceneScript,receipt: Dictionary,final: bool = false) -> bool:
	if scene == null or scene.map_layout == null or receipt.get("cold_storage_validated") != true or receipt.get("scene_instance") != scene.get_instance_id() or receipt.get("layout_instance") != scene.map_layout.get_instance_id(): return false
	if not receipt.get("owner_kind") is String or receipt.owner_kind.is_empty() or not receipt.get("owner_key") is String or receipt.owner_key.is_empty() or typeof(receipt.get("token")) != TYPE_INT or (receipt.token == 0 if scene.scene_id == &"ch4_s4_ancient_temple" and receipt.owner_kind == "TEMPLE_OWN_FIELD_ORIGINAL" else receipt.token <= 0): return false
	if not receipt.get("source_first") is Dictionary or receipt.source_first.is_empty(): return false
	return not final or (receipt.get("finalized") == true and receipt.get("source_final") is Dictionary and receipt.source_final == receipt.source_first)

static func _original_arrays(scene: SceneScript,native_rows: Array,blockers: Array,original: Dictionary) -> bool:
	return _receipt(scene,original) and original.get("original_native_navigation") is Array and original.get("original_parent_blockers") is Array and var_to_bytes(native_rows) == var_to_bytes(original.original_native_navigation) and var_to_bytes(blockers) == var_to_bytes(original.original_parent_blockers)

static func _payload_valid(payload: Dictionary,row: Dictionary,id: String,parent_native: Array,parent_blockers: Array) -> bool:
	if payload.get("scene_id") != id or payload.get("world_size_px") != Vector2(float(row.world_size_px[0]),float(row.world_size_px[1])): return false
	var arrays: Array = ["parent_native_navigation","parent_navigation","effective_navigation","parent_solids","effective_solids","visual_patches","visual_additions","visual_retired","portal_before","portal_after","interaction_patches","npc_migrations","new_NPCs","effective_walkable_polygons","new_route_contracts"]
	for key: String in arrays:
		if not payload.get(key) is Array: return false
	if var_to_bytes(payload.parent_native_navigation) != var_to_bytes(parent_native): return false
	if id in ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]:
		# This reference names the original fully validated proof, never observed-current fill.
		if payload.get("parent_blockers_ref") != {"kind":"ORIGINAL_COMPLETE_RECEIPT_LAYOUT_BLOCKERS"} or payload.has("parent_blockers"): return false
		arrays.append("parent_blockers_ref")
	else:
		if not payload.get("parent_blockers") is Array or var_to_bytes(payload.parent_blockers) != var_to_bytes(parent_blockers) or payload.has("parent_blockers_ref"): return false
		arrays.append("parent_blockers")
	if payload.parent_navigation.is_empty() or payload.effective_navigation.is_empty() or payload.effective_solids.is_empty(): return false
	for points: Variant in payload.effective_solids:
		if not points is PackedVector2Array or points.size() < 3: return false
		for point: Vector2 in points:
			if not point.is_finite(): return false
	for key: String in arrays:
		if not _hash(row.fingerprints.get(key)) or _fingerprint(payload[key]) != row.fingerprints[key]: return false
	return payload.get("restore_contract") is Dictionary and payload.restore_contract.get("whole_typed_inverse_verified") == true

static func ensure(scene: SceneScript,parent_native: Array,parent_blockers: Array,original: Dictionary) -> bool:
	if not FORMAL_READY or scene == null or not requested(scene.scene_id) or not _original_arrays(scene,parent_native,parent_blockers,original): return false
	var config: Dictionary = _binding()
	if config.is_empty(): return false
	var row: Dictionary = config.scenes[String(scene.scene_id)]
	for path: String in row.required_original_source_sha256:
		if original.source_first.get(path) != row.required_original_source_sha256[path]: return false
	var previous: Dictionary = _current(scene)
	if not previous.is_empty():
		return previous.owner_key == original.owner_key and previous.token == original.token and previous.first == original.source_first and var_to_bytes(previous.payload.parent_native_navigation) == var_to_bytes(parent_native) and var_to_bytes(previous.parent_blockers) == var_to_bytes(parent_blockers)
	for key: int in _states.keys():
		var cached_field: WeakRef = _states[key].field
		if _states[key].scene.get_ref() == null or _states[key].layout.get_ref() == null or (cached_field != null and not is_instance_valid(cached_field.get_ref())): _states.erase(key)
	if _states.size() >= 8: return false
	var captured: Dictionary = {}
	for path: String in row.required_source_sha256:
		captured[path] = FileAccess.get_sha256(path)
		if captured[path] != row.required_source_sha256[path]: return false
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(row.payload.path)
	if bytes.size() != int(row.payload.get("bytes",-1)) or _sha(bytes) != row.payload.sha256: return false
	var raw: Variant = bytes_to_var(bytes)
	if not raw is Dictionary or not _payload_valid(raw,row,String(scene.scene_id),parent_native,parent_blockers): return false
	var texture: Texture2D
	var mask: Image
	var mask_sha: String = "SOURCE_POLYGON_ONLY"
	if String(scene.scene_id) == "ch4_s4_ancient_temple":
		if raw.effective_walkable_polygons.is_empty(): return false
		for floor: Variant in raw.effective_walkable_polygons:
			if not floor is PackedVector2Array or floor.size() < 3: return false
	else:
		texture = load(String(row.mask.path)) as Texture2D
		mask = texture.get_image() if texture != null else null
		var expected_size := Vector2i(int(row.world_size_px[0]),int(row.world_size_px[1]))
		if texture == null or texture.resource_path != row.mask.path or mask == null or mask.is_empty() or mask.get_size() != expected_size or mask.has_mipmaps() or mask.get_format() not in [Image.FORMAT_RGB8,Image.FORMAT_RGBA8]: return false
		if mask.get_format() == Image.FORMAT_RGB8: mask.convert(Image.FORMAT_RGBA8)
		mask_sha = String(row.mask.RGBA_sha256)
		if _sha(mask.get_data()) != mask_sha: return false
	var prepared: Array = []
	for points: PackedVector2Array in raw.effective_solids:
		var low: Vector2 = points[0];var high: Vector2 = low
		for p: Vector2 in points: low = low.min(p);high = high.max(p)
		prepared.append({"points":points,"bounds":Rect2(low,high-low)})
	_states[scene.get_instance_id()] = {"scene":weakref(scene),"layout":weakref(scene.map_layout),"owner_kind":original.owner_kind,"owner_key":original.owner_key,"token":original.token,"first":original.source_first.duplicate(true),"captured":captured,"binding_sha":BIND_SHA,"payload":raw,"payload_sha":_fingerprint(raw),"parent_blockers":original.original_parent_blockers.duplicate(true),"parent_blockers_sha":_fingerprint(original.original_parent_blockers),"mask":mask,"texture":texture,"mask_sha":mask_sha,"prepared":prepared,"textures":{},"field":null,"finalized":false,"released":false,"boundary_checks":0}
	var staged: Dictionary = _states[scene.get_instance_id()]
	for object: Dictionary in raw.effective_navigation:
		var path: String = String(object.get("texture",""))
		if path.is_empty(): continue
		if not captured.has(path) and not original.source_first.has(path):
			_states.erase(scene.get_instance_id());return false
		var object_texture: Texture2D = load(path) as Texture2D
		if object_texture == null or object_texture.resource_path != path:
			_states.erase(scene.get_instance_id());return false
		staged.textures[path] = object_texture
	return true

func acquire(field: Node,scene: SceneScript,parent_nav: Array,parent_blockers: Array) -> bool:
	if not is_instance_valid(field) or field.get_script().resource_path != FIELD or field.scene_file_path != "res://scenes/field_walkable.tscn" or field.get("_current_scene") != scene or field.get("_scene_rebuilding") != true: return _reject("FIELD_ACQUIRE_OWNER")
	var state: Dictionary = _current(scene)
	if state.is_empty() or var_to_bytes(state.payload.parent_navigation) != var_to_bytes(parent_nav) or var_to_bytes(state.parent_blockers) != var_to_bytes(parent_blockers): return _reject("FIELD_ACQUIRE_COLD_PARENT")
	var existing: WeakRef = state.field
	if existing != null and is_instance_valid(existing.get_ref()) and existing.get_ref() != field: return _reject("FIELD_ACQUIRE_ALREADY_OWNED")
	if scene.scene_id == &"ch4_s4_ancient_temple":
		var temple: RefCounted = field.get("_temple_session")
		if temple == null or temple.get_instance_id() != int(state.token): return _reject("TEMPLE_REAL_PREPARED_INSTANCE_OWNER")
		state["temple_ref"] = weakref(temple)
	_field_ref = weakref(field);_state = state;_revision = int(field.get("_city3_motion_revision"));state.field = _field_ref
	return _owned(true,true)

func _owned(setup: bool = false,park: bool = false) -> bool:
	var field: Node = _field_ref.get_ref() if _field_ref != null else null
	if _state.is_empty() or not is_instance_valid(field) or _state.get("released",true) or not field.is_inside_tree() or field.get_script().resource_path != FIELD or int(field.get("_city3_motion_revision")) != _revision: return false
	var scene: SceneScript = _state.scene.get_ref()
	if scene == null or field.get("_current_scene") != scene or scene.map_layout != _state.layout.get_ref() or not is_same(_current(scene),_state) or _state.field != _field_ref: return false
	if field.get("_field_loading_failed") == true: return false
	if scene.scene_id == &"ch4_s4_ancient_temple":
		var temple_ref: WeakRef = _state.get("temple_ref")
		if temple_ref == null or temple_ref.get_ref() == null or field.get("_temple_session") != temple_ref.get_ref(): return false
	if field.get("_resident_parked") == true: return park and _state.finalized
	var current: Node = field.get_tree().current_scene
	if current == field:
		if setup and field.get("_scene_rebuilding") == true: return true
		return field.get("_scene_rebuilding") == false and _state.finalized and SceneRouter.get_current_field_id() == scene.scene_id and not LoadingManager._transition_active and not LoadingManager._external_active
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
	if not _owned(true,true): return []
	# Publication contains exact target rows, not unrelated G/task portal additions.
	var old_targets: Dictionary = {}
	var new_targets: Dictionary = {}
	for row: Dictionary in _state.payload.portal_before:
		var id: String = String(row.get("id",""))
		if id.is_empty() or old_targets.has(id): return []
		old_targets[id] = row
	for row: Dictionary in _state.payload.portal_after:
		var id: String = String(row.get("id",""))
		if id.is_empty() or new_targets.has(id): return []
		new_targets[id] = row
	for id: String in old_targets:
		if not new_targets.has(id): return []
	var out: Array = []
	var seen: Dictionary = {}
	for row: Dictionary in before:
		var id: String = String(row.get("id",""))
		if id.is_empty() or seen.has(id): return []
		seen[id] = true
		if old_targets.has(id):
			if var_to_bytes(row) != var_to_bytes(old_targets[id]): return []
			out.append(new_targets[id])
		else:
			if new_targets.has(id): return []
			out.append(row)
	for id: String in old_targets:
		if not seen.has(id): return []
	for row: Dictionary in _state.payload.portal_after:
		if not old_targets.has(String(row.id)): out.append(row)
	return out

func project_interactions(before: Array) -> Dictionary:
	if not _owned(true,true): return {"ok":false}
	var out: Array = before.duplicate(true)
	for patch: Dictionary in _state.payload.interaction_patches:
		var count: int = 0
		for i: int in range(out.size()):
			if String(out[i].get("id","")) != String(patch.id): continue
			if var_to_bytes(out[i]) != var_to_bytes(patch.before): return {"ok":false}
			out[i] = patch.after;count += 1
		if count != 1: return {"ok":false}
	return {"ok":true,"rows":out}

func project_npcs(before: Array,preserved: Array = []) -> Dictionary:
	if not _owned(true,true): return {"ok":false}
	var out: Array = before.duplicate(true)
	var size: Vector2 = _state.payload.world_size_px
	for move: Dictionary in _state.payload.npc_migrations:
		var count: int = 0
		for row: Dictionary in out:
			if String(row.get("npc_id","")) != String(move.npc_id): continue
			if not row.get("pos") is Vector2 or row.pos != Vector2(float(move.old_source_origin_px[0]),float(move.old_source_origin_px[1]))/size: return {"ok":false}
			row.pos = Vector2(float(move.new_source_origin_px[0]),float(move.new_source_origin_px[1]))/size;count += 1
		if count == 0:
			for actor: NPCNode in preserved:
				if not is_instance_valid(actor) or actor.npc_id != String(move.npc_id): continue
				if actor not in (_field_ref.get_ref() as Node).get("_npc_nodes") or actor.get_parent() != (_field_ref.get_ref() as Node).get("_actor_layer") or actor.position != Vector2(float(move.new_source_origin_px[0]),float(move.new_source_origin_px[1]))/size*size: return {"ok":false}
				count += 1
		if count != 1: return {"ok":false}
	for row: Dictionary in _state.payload.new_NPCs:
		for existing: Dictionary in out:
			if existing.get("npc_id") == row.get("npc_id"): return {"ok":false}
		out.append(row.duplicate(true))
	return {"ok":true,"rows":out}

func texture_matches(path: String,texture: Texture2D) -> bool:
	return _owned(true,true) and texture != null and _state.textures.get(path) == texture

func admit_depth(helper: RefCounted) -> bool:
	if not _owned(true,true) or helper == null: return false
	var properties: Dictionary = {}
	for property: Dictionary in helper.get_property_list(): properties[String(property.name)] = true
	var ids_key: String = "_temple_ids" if properties.has("_temple_ids") else ("_ids" if properties.has("_ids") else "")
	# Generic AP overlap has no whitelist. Existing exact configure already ran in Field.
	if ids_key.is_empty(): return true
	var ids: Variant = helper.get(ids_key)
	if not ids is Array: return false
	var next: Array = ids.duplicate()
	var fade_key: String = "_temple_fade_ids" if ids_key == "_temple_ids" else "_fade_ids"
	var fades: Variant = helper.get(fade_key) if properties.has(fade_key) else []
	if not fades is Array: return false
	var next_fades: Array = fades.duplicate()
	for old: Dictionary in _state.payload.visual_retired:
		next.erase(String(old.id));next_fades.erase(String(old.id))
	var admitted: Array = _state.payload.visual_additions.duplicate()
	for patch: Dictionary in _state.payload.visual_patches: admitted.append(patch.after)
	for row: Dictionary in admitted:
		var id: String = String(row.get("id",""))
		if id.is_empty(): return false
		if not next.has(id): next.append(id)
		if row.get("district_life_fade",false) == false: next_fades.erase(id)
	helper.set(ids_key,next)
	if properties.has(fade_key): helper.set(fade_key,next_fades)
	return true

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

static func _cross(a: Vector2,b: Vector2,c: Vector2) -> float:
	return (float(b.x)-a.x)*(float(c.y)-a.y)-(float(b.y)-a.y)*(float(c.x)-a.x)

static func _on(a: Vector2,b: Vector2,p: Vector2) -> bool:
	return _cross(a,b,p) == 0.0 and p.x >= minf(a.x,b.x) and p.x <= maxf(a.x,b.x) and p.y >= minf(a.y,b.y) and p.y <= maxf(a.y,b.y)

static func _touch(a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> bool:
	return (_cross(a,b,c)*_cross(a,b,d) < 0.0 and _cross(c,d,a)*_cross(c,d,b) < 0.0) or _on(a,b,c) or _on(a,b,d) or _on(c,d,a) or _on(c,d,b)

static func _safe(state: Dictionary,foot: Vector2,half: Vector2) -> bool:
	var mask: Image = state.mask
	var world_size: Vector2 = state.payload.world_size_px
	if not half.is_finite() or half.x <= 0.0 or half.y <= 0.0 or not foot.is_finite() or foot.x < half.x or foot.y < half.y or roundi(foot.x+half.x) >= world_size.x or roundi(foot.y+half.y) >= world_size.y: return false
	var rect := Rect2(foot-half,half*2)
	var body := PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	if mask == null:
		var supported: bool = false
		for floor: PackedVector2Array in state.payload.effective_walkable_polygons:
			var all_inside: bool = true
			for point: Vector2 in body:
				if not Geometry2D.is_point_in_polygon(point,floor): all_inside = false;break
			if all_inside: supported = true;break
		if not supported: return false
	for row: Dictionary in state.prepared:
		if not row.bounds.intersects(rect,true): continue
		if not Geometry2D.intersect_polygons(body,row.points).is_empty(): return false
		for point: Vector2 in body:
			if Geometry2D.is_point_in_polygon(point,row.points): return false
		for point: Vector2 in row.points:
			if point.x >= rect.position.x and point.x <= rect.end.x and point.y >= rect.position.y and point.y <= rect.end.y: return false
		for i: int in range(body.size()):
			for j: int in range(row.points.size()):
				if _touch(body[i],body[(i+1)%body.size()],row.points[j],row.points[(j+1)%row.points.size()]): return false
	if mask == null: return true
	for y: int in range(roundi(rect.position.y),roundi(rect.end.y)+1):
		for x: int in range(roundi(rect.position.x),roundi(rect.end.x)+1):
			var color: Color = mask.get_pixel(x,y)
			if color.r < .5 or color.a < .5: return false
	return true

static func safe_body(scene: SceneScript,foot: Vector2,half: Vector2 = Vector2(17,12)) -> bool:
	var state: Dictionary = _current(scene)
	if state.is_empty(): return false
	var field_ref: WeakRef = state.field
	if field_ref != null:
		var field: Node = field_ref.get_ref()
		if not is_instance_valid(field) or field.get("_current_scene") != scene or field.get("_field_loading_failed") == true: return false
		if not state.finalized and field.get("_scene_rebuilding") != true: return false
	return _safe(state,foot,half)

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
	if _state.binding_sha != BIND_SHA or (_state.mask != null and _sha((_state.mask as Image).get_data()) != _state.mask_sha) or _fingerprint(_state.payload) != _state.payload_sha or _fingerprint(_state.parent_blockers) != _state.parent_blockers_sha: return _reject("CACHED_EFFECTIVE_GEOMETRY_OR_MASK_DRIFT")
	_state.boundary_checks += 1
	return true

func finalize(scene: SceneScript,original: Dictionary) -> bool:
	if not _owned(true) or not _receipt(scene,original,true) or original.owner_key != _state.owner_key or original.token != _state.token or original.source_first != _state.first or not _original_arrays(scene,_state.payload.parent_native_navigation,_state.parent_blockers,original): return _reject("ORIGINAL_FINAL_OWNER_OR_SOURCE_CHANGED")
	if not revalidate_boundary(): return false
	var row: Dictionary = _config.scenes[String(scene.scene_id)]
	for path: String in _state.captured:
		if FileAccess.get_sha256(path) != _state.captured[path] or _state.captured[path] != row.required_source_sha256[path]: return _reject("NEW_OVERLAY_FINAL_SOURCE_CHANGED")
	_state.finalized = true
	return true

func state() -> Dictionary:
	return {} if _state.is_empty() or _state.scene.get_ref() == null else {"scene_instance":(_state.scene.get_ref() as SceneScript).get_instance_id(),"owner_kind":_state.owner_kind,"owner_key":_state.owner_key,"token":_state.token,"finalized":_state.finalized,"binding_sha":_state.binding_sha,"solid_count":_state.payload.effective_solids.size(),"mask":_state.mask,"boundary_checks":_state.boundary_checks}


static func _arrival_contract(source: StringName,target: StringName) -> Dictionary:
	if source == &"ch4_s1_luoyang_yamen" and target == &"luoyang_artisan_residential_20261022ap":
		return {"portal":"finish_i_yamen_to_artisan","source_foot":Vector2(120,700),"target_foot":Vector2(128,1300),"uv":Vector2(128,1300)/Vector2(3072,2048),"kind":"ORIGINAL_FIRST_COLD_LEASE"}
	if source == &"luoyang_artisan_residential_20261022ap" and target == &"ch4_s1_luoyang_yamen":
		return {"portal":"finish_i_artisan_to_yamen","source_foot":Vector2(128,1300),"target_foot":Vector2(120,700),"uv":Vector2(120,700)/Vector2(3072,2048),"kind":"ORIGINAL_FIRST_COLD_LEASE"}
	if source == &"ch4_s3_luoyang_market" and target == &"ch4_s4_ancient_temple":
		var market_uv: Vector2 = Vector2(170,926)/Vector2(1536,1024)
		return {"portal":"to_ancient_temple","source_foot":Vector2(1170,1600),"target_foot":market_uv*Vector2(1920,1280),"uv":market_uv,"kind":"TEMPLE_DEFERRED_ORIGINAL_PREPARE"}
	if source == &"ch4_s2_canal_docks" and target == &"ch4_s4_ancient_temple":
		var docks_uv: Vector2 = Vector2(1380,926)/Vector2(1536,1024)
		return {"portal":"canal_world_ferry","source_foot":Vector2(2140,1840),"target_foot":docks_uv*Vector2(1920,1280),"uv":docks_uv,"kind":"TEMPLE_DEFERRED_ORIGINAL_PREPARE"}
	return {}

static func _arrival_states(id: StringName) -> Array:
	var out: Array = []
	for value: Dictionary in _states.values():
		var scene: SceneScript = value.scene.get_ref()
		if scene != null and scene.scene_id == id and is_same(_current(scene),value): out.append(value)
	return out

static func authored_arrival(source: StringName,target: StringName,normalized: Vector2) -> Dictionary:
	var fixed: Dictionary = _arrival_contract(source,target)
	if fixed.is_empty(): return {"matched":false}
	var refused: Dictionary = {"matched":true,"ok":false,"error":"FINISH25I_EXACT_NEW_PAIR_OWNER_OR_AUTHORED_TARGET"}
	if not FORMAL_READY or not normalized.is_finite() or normalized != fixed.uv: return refused
	var candidates: Array = _arrival_states(source)
	if candidates.size() != 1: return refused
	var owner: Dictionary = candidates[0]
	var scene: SceneScript = owner.scene.get_ref()
	var field_ref: WeakRef = owner.field
	var field: Node = field_ref.get_ref() if field_ref != null else null
	if not owner.finalized or not is_instance_valid(field) or field.get_script().resource_path != FIELD or field.get("_current_scene") != scene or field.get("_field_loading_failed") == true or field.get("_scene_rebuilding") != false: return refused
	var session: RefCounted = field.get("_finish25i")
	if session == null or not is_same(session.get("_state"),owner) or int(field.get("_city3_motion_revision")) != int(session.get("_revision")): return refused
	var parked: bool = field.get("_resident_parked") == true
	if not parked and (not field.is_inside_tree() or field.get_tree().current_scene != field or SceneRouter.get_current_field_id() != source): return refused
	if owner.binding_sha != BIND_SHA or _fingerprint(owner.payload) != owner.payload_sha or _fingerprint(owner.parent_blockers) != owner.parent_blockers_sha: return refused
	var route: Dictionary = {}
	var routes: int = 0
	for row: Dictionary in owner.payload.new_route_contracts:
		if String(row.get("source_scene_id","")) == String(source) and String(row.get("target_scene_id","")) == String(target):
			route = row;routes += 1
	if routes != 1 or route.get("source_portal_id") != fixed.portal or route.get("source_foot_px") != fixed.source_foot or route.get("target_foot_px") != fixed.target_foot or route.get("expected_normalized") != normalized or route.get("source_target_pos") != normalized or route.get("kind") != fixed.kind or not route.get("source_portal_row") is Dictionary: return refused
	var portals: int = 0
	for portal: Dictionary in owner.payload.portal_after:
		if String(portal.get("id","")) != fixed.portal: continue
		if var_to_bytes(portal) != var_to_bytes(route.source_portal_row) or String(portal.get("target_scene","")) != String(target) or portal.get("target_pos") != normalized or portal.get("source_spawn_pos",portal.get("pos")) != fixed.source_foot/owner.payload.world_size_px: return refused
		portals += 1
	if portals != 1: return refused
	if fixed.kind == "TEMPLE_DEFERRED_ORIGINAL_PREPARE":
		# No target receipt/token is manufactured. Field still requires real T.prepare,
		# original FINAL, lease FINAL and complete newgeometry arrival before Player.
		return {"matched":true,"ok":true,"kind":fixed.kind,"spawn":normalized,"target_foot_px":fixed.target_foot,"source_owner_key":owner.owner_key,"source_token":owner.token,"target_original_FIRST":false,"requires_Field_original_FINAL_and_effective_arrival":true}
	var destinations: Array = _arrival_states(target)
	if destinations.size() != 1: return refused
	var destination: Dictionary = destinations[0]
	var destination_scene: SceneScript = destination.scene.get_ref()
	if destination_scene == null or destination.owner_key == "" or int(destination.token) <= 0 or destination.first.is_empty() or destination.binding_sha != BIND_SHA or _fingerprint(destination.payload) != destination.payload_sha or _fingerprint(destination.parent_blockers) != destination.parent_blockers_sha: return refused
	if normalized*destination.payload.world_size_px != fixed.target_foot or not safe_body(destination_scene,fixed.target_foot): return refused
	return {"matched":true,"ok":true,"kind":fixed.kind,"spawn":normalized,"target_foot_px":fixed.target_foot,"source_owner_key":owner.owner_key,"source_token":owner.token,"target_owner_key":destination.owner_key,"target_token":destination.token}

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
		if scene != null and is_same(_states.get(scene.get_instance_id()),_state): _states.erase(scene.get_instance_id())
	_state = {};_field_ref = null
