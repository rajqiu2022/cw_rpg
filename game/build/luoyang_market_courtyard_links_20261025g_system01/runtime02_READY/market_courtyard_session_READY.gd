extends RefCounted
## 25g finite descendant of immutable24e37->43, with independent45 lease.
const READY = true
const SELF = "res://build/luoyang_market_courtyard_links_20261025g_system01/runtime02_READY/market_courtyard_session_READY.gd"
const BIND = "res://build/luoyang_market_courtyard_links_20261025g_system01/runtime02_READY/binding_READY.json"
const BIND_SHA = "3e316674ce6f72bb434618fbf8ce3c4551c74a230ecbb097cf55ecc499c08c04"
const PARENT = "res://build/luoyang_city_revision_20261024e_source01/runtime_ready03/market_block_session_READY.gd"
const PARENT_SHA = "d29602487f69e0dd5a82dcdb2bf76fb9928f64319e0bae0c0d06cc806f4775ea"
const ID = &"ch4_s3_luoyang_market"
const C_PATH = "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
static var _parent_handle: Variant = null
static var _pure: Variant = null
static var _config: Dictionary = {}
static var _author: Dictionary = {}
static var _states: Dictionary = {}
static func _parent() -> Variant:
	if _parent_handle!=null:
		return _parent_handle
	if FileAccess.get_sha256(PARENT)!=PARENT_SHA:
		return null
	var script: Variant = load(PARENT)
	if not script is GDScript or script.resource_path!=PARENT:
		return null
	_parent_handle=script
	return script
static func _json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
static func _sha(bytes: PackedByteArray) -> String:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(bytes)
	return h.finish().hex_encode()
static func _hash(raw: Variant) -> bool:
	if not raw is String or raw.length()!=64:
		return false
	for ch: int in raw.to_ascii_buffer():
		if not ch in range(48,58) and not ch in range(97,103):
			return false
	return true
static func requested(scene: SceneScript) -> bool:
	return scene!=null and scene.scene_id==ID
static func binding() -> Dictionary:
	if not READY or not _hash(BIND_SHA):
		return {}
	if not _config.is_empty():
		return _config
	if FileAccess.get_sha256(BIND)!=BIND_SHA:
		return {}
	var b: Dictionary = _json(BIND)
	var parent: Variant = _parent()
	if parent==null or parent.binding().is_empty() or b.get("ready")!=true or b.get("scene_id")!=String(ID) or b.get("status")!="MARKET25G_COURTYARD_LINKS_SOURCE_BOUND_READY":
		return {}
	if b.get("parent_runtime",{}).get("path")!=PARENT or b.parent_runtime.get("sha256")!=PARENT_SHA or b.get("parent37_child43_whole_validation_retained")!=true or b.get("room_geometry_unchanged")!=true:
		return {}
	var pins: Dictionary = b.get("required_source_sha256",{})
	if pins.is_empty() or pins.has(SELF) or pins.has(BIND):
		return {}
	for path: String in pins:
		if not path.begins_with("res://") or ".." in path or not _hash(pins[path]):
			return {}
	for key: String in ["parent_runtime","author","pure","publication_header","local_art"]:
		var row: Dictionary = b.get(key,{})
		if not row.get("path") is String or not _hash(row.get("sha256")) or pins.get(row.path)!=row.sha256:
			return {}
	if b.local_art.get("admitted")!=true or b.local_art.get("scope")!="SOURCE_ASSET_AND_AUTHORED_LAYOUT_FIELD_TRIAL_ONLY":
		return {}
	for key: String in ["path","import_path","compiled_path"]:
		if not b.mask.get(key) is String or not pins.has(b.mask[key]):
			return {}
	if b.mask.import_path!=String(b.mask.path)+".import" or not _hash(b.mask.get("RGBA_sha256")):
		return {}
	if FileAccess.get_sha256(b.author.path)!=b.author.sha256 or FileAccess.get_sha256(b.pure.path)!=b.pure.sha256:
		return {}
	_author=_json(b.author.path)
	_pure=load(b.pure.path)
	if not _pure is GDScript or _pure.resource_path!=b.pure.path or _author.get("scene_id")!=String(ID) or _author.get("parent_count")!=43 or _author.get("child_count")!=45:
		return {}
	_config=b
	return b
static func source_paths_for(id: StringName) -> Dictionary:
	var parent: Variant = _parent()
	if id!=ID or binding().is_empty() or parent==null:
		return {}
	var out: Dictionary = parent.source_paths_for(id).duplicate()
	if out.is_empty():
		return {}
	out[SELF]=true
	out[BIND]=true
	for path: String in _config.required_source_sha256:
		out[path]=true
	return out
static func room_source_paths() -> Dictionary:
	var parent: Variant = _parent()
	if binding().is_empty() or parent==null:
		return {}
	var out: Dictionary = parent.room_source_paths().duplicate()
	out[SELF]=true
	out[BIND]=true
	out[_config.author.path]=true
	out[_config.pure.path]=true
	return out
static func _valid(scene: SceneScript) -> Dictionary:
	var parent: Variant = _parent()
	if not requested(scene) or parent==null or scene.map_layout==null:
		return {}
	var value: Dictionary = _states.get(scene.get_instance_id(),{})
	if value.is_empty() or value.scene.get_ref()!=scene or value.layout.get_ref()!=scene.map_layout:
		return {}
	var original: Dictionary = parent._valid(scene)
	if original.is_empty() or int(original.token)!=value.token:
		return {}
	if value.attached:
		if not original.attached or value.field.get_ref()!=original.field.get_ref() or value.district.get_ref()!=original.district.get_ref():
			return {}
	return value
static func ensure(scene: SceneScript) -> Dictionary:
	if not requested(scene):
		return {}
	var existing: Dictionary = _valid(scene)
	if not existing.is_empty():
		return existing
	if _states.has(scene.get_instance_id()):
		return {}
	var b: Dictionary = binding()
	var parent: Variant = _parent()
	if b.is_empty() or parent==null:
		return {}
	# Original immutable37->43 FIRST/native whole/packet/source checks execute first.
	var original: Dictionary = parent.ensure(scene)
	if original.is_empty() or original.projection.render.size()!=43:
		return {}
	var sources: Dictionary = original.sources
	if sources.get(BIND)!=BIND_SHA or not _hash(sources.get(SELF)):
		return {}
	for path: String in b.required_source_sha256:
		if sources.get(path)!=b.required_source_sha256[path]:
			return {}
	var header: Dictionary = _json(b.publication_header.path)
	if header.get("parent_count")!=43 or header.get("child_count")!=45 or header.get("author")!=b.author or header.get("pure")!=b.pure or header.get("walk_RGBA_sha256")!=b.mask.RGBA_sha256 or header.get("finite",{}).get("ok")!=true:
		return {}
	for name: String in ["projection.bin","geometry.bin","pixel_inverse.bin","finite_proof.bin","walk_overlay.png"]:
		var row: Dictionary = header.get("artifacts",{}).get(name,{})
		if b.required_source_sha256.get(row.get("path",""))!=row.get("sha256"):
			return {}
	if header.artifacts["walk_overlay.png"].path!=b.mask.path:
		return {}
	var projection: Variant = bytes_to_var(FileAccess.get_file_as_bytes(header.artifacts["projection.bin"].path))
	var geometry: Variant = bytes_to_var(FileAccess.get_file_as_bytes(header.artifacts["geometry.bin"].path))
	if not projection is Dictionary or projection.get("ok")!=true or projection.get("render",[]).size()!=45 or not geometry is Array:
		return {}
	var fresh: Dictionary = _pure.project(_author,original.projection.render)
	if fresh.is_empty() or var_to_bytes(fresh)!=var_to_bytes(projection) or var_to_bytes(_pure.restore(projection))!=var_to_bytes(original.projection.render) or var_to_bytes(_pure.primitives(projection.render))!=var_to_bytes(geometry):
		return {}
	var texture: Texture2D = ResourceLoader.load(b.mask.path) as Texture2D
	var mask: Image = texture.get_image() if texture!=null else null
	if mask==null or mask.get_size()!=Vector2i(3072,2048) or mask.has_mipmaps() or mask.get_format() not in [Image.FORMAT_RGB8,Image.FORMAT_RGBA8]:
		return {}
	var original_format: int = mask.get_format()
	if original_format==Image.FORMAT_RGB8:
		mask.convert(Image.FORMAT_RGBA8)
	if _sha(mask.get_data())!=b.mask.RGBA_sha256:
		return {}
	var ground: Array[PackedVector2Array] = []
	for row: Dictionary in geometry:
		var shape: PackedVector2Array = _pure.poly(row.points_px)
		if shape.size()<3 or Geometry2D.triangulate_polygon(shape).is_empty():
			return {}
		ground.append(shape)
	for key: int in _states.keys():
		if _states[key].scene.get_ref()==null:
			_states.erase(key)
	var value: Dictionary = {"scene":weakref(scene),"layout":weakref(scene.map_layout),"token":int(original.token),"projection":projection,"solids":ground,"mask":mask,"attached":false,"finalized":false,"mask_format_before":original_format,"projection_sha":_sha(var_to_bytes(projection)),"solids_sha":_sha(var_to_bytes(ground)),"boundary_checks":0}
	_states[scene.get_instance_id()]=value
	return value
static func acquire(scene: SceneScript,field: Node,district: RefCounted,owner: Callable,sources: Dictionary,proof: Dictionary,before: Array) -> Dictionary:
	var value: Dictionary = ensure(scene)
	var parent: Variant = _parent()
	if value.is_empty() or value.attached or parent==null:
		return {"ok":false,"error":"MARKET25G_NO_SOURCE_FIRST45"}
	var original: Dictionary = parent.acquire(scene,field,district,owner,sources,proof,before)
	if original.get("ok")!=true:
		return original
	value.field=weakref(field)
	value.district=weakref(district)
	value.attached=true
	return state(scene)
static func render(scene: SceneScript,before: Array) -> Array:
	var value: Dictionary = _valid(scene)
	var parent: Variant = _parent()
	if value.is_empty() or not value.attached or parent==null:
		return []
	var original: Array = parent.render(scene,before)
	if var_to_bytes(original)!=var_to_bytes(_pure.restore(value.projection)):
		return []
	return value.projection.render.duplicate(true)
static func render_with_ground(scene: SceneScript,before: Array,old_ground: Array) -> Array:
	var parent: Variant = _parent()
	if parent==null:
		return []
	var original: Array = parent.render_with_ground(scene,before,old_ground)
	var out: Array = render(scene,before)
	if original.size()!=44 or out.size()!=45 or var_to_bytes(original.slice(0,43))!=var_to_bytes(_pure.restore(_valid(scene).projection)):
		return []
	out.append(original[43].duplicate(true))
	return out
static func effective_mask(scene: SceneScript) -> Image:
	var value: Dictionary = _valid(scene)
	return value.mask if not value.is_empty() and value.attached else null
static func solids(scene: SceneScript) -> Array[PackedVector2Array]:
	var value: Dictionary = _valid(scene)
	var empty: Array[PackedVector2Array] = []
	return value.solids if not value.is_empty() and value.attached else empty
static func safe_body_for_receipt(id: StringName,foot: Vector2,proof: Dictionary) -> Dictionary:
	if id!=ID:
		return {"matched":false}
	if not proof.get("scene") is SceneScript:
		return {"matched":true,"safe":false}
	var value: Dictionary = ensure(proof.scene)
	if value.is_empty() or int(proof.get("token",0))!=value.token or not foot.is_finite():
		return {"matched":true,"safe":false}
	var contract: Variant = load(C_PATH)
	return {"matched":true,"safe":contract._safe_body_cpu(foot,value.mask,value.solids)}
static func lease_bound(scene: SceneScript,district: RefCounted) -> bool:
	var value: Dictionary = _valid(scene)
	var parent: Variant = _parent()
	return not value.is_empty() and value.attached and value.district.get_ref()==district and parent.lease_bound(scene,district)
static func bound(scene: SceneScript) -> bool:
	var value: Dictionary = _valid(scene)
	return not value.is_empty() and value.attached
static func validate_cached_boundary(scene: SceneScript,district: RefCounted) -> bool:
	var value: Dictionary = _valid(scene)
	var parent: Variant = _parent()
	if value.is_empty() or not lease_bound(scene,district) or not parent.validate_cached_boundary(scene,district):
		return false
	var mask: Image = value.mask
	if mask==null or mask.get_size()!=Vector2i(3072,2048) or mask.get_format()!=Image.FORMAT_RGBA8 or mask.has_mipmaps() or _sha(mask.get_data())!=_config.mask.RGBA_sha256:
		return false
	if _sha(var_to_bytes(value.projection))!=value.projection_sha or _sha(var_to_bytes(value.solids))!=value.solids_sha:
		return false
	value.boundary_checks=int(value.boundary_checks)+1
	return true
static func finalize(scene: SceneScript,district: RefCounted,sources: Dictionary) -> bool:
	var parent: Variant = _parent()
	if parent==null or not parent.finalize(scene,district,sources) or not validate_cached_boundary(scene,district):
		return false
	_valid(scene).finalized=true
	return true
static func release(scene: SceneScript,district: RefCounted) -> void:
	var parent: Variant = _parent()
	if parent!=null:
		parent.release(scene,district)
	if scene==null:
		return
	var value: Dictionary = _states.get(scene.get_instance_id(),{})
	if not value.is_empty() and value.get("attached",false) and value.district.get_ref()==district:
		_states.erase(scene.get_instance_id())
static func state(scene: SceneScript) -> Dictionary:
	var value: Dictionary = _valid(scene)
	if value.is_empty():
		return {"ok":false,"error":"MARKET25G_NO_CURRENT45_LEASE"}
	return {"ok":true,"render_count":45,"parent_render_count":43,"token":value.token,"scene_instance":scene.get_instance_id(),"layout_instance":scene.map_layout.get_instance_id(),"attached":value.attached,"finalized":value.finalized,"mask_path":_config.mask.path,"solid_count":value.solids.size(),"mask_format_before":value.mask_format_before,"mask_format_after":value.mask.get_format(),"boundary_integrity_checks":value.boundary_checks}
static func configure_depth(scene: SceneScript,district: RefCounted,fade: RefCounted) -> bool:
	var value: Dictionary = _valid(scene)
	var parent: Variant = _parent()
	if value.is_empty() or not lease_bound(scene,district) or parent==null or not parent.configure_depth(scene,district,fade):
		return false
	var ids: Variant = fade.get("_ids")
	var fading: Variant = fade.get("_fade_ids")
	if not ids is Array or not fading is Array:
		return false
	for row: Dictionary in value.projection.changed:
		if String(row.id) not in ids:
			return false
		# Changed stall sprites are built from new texture rows after configure;
		# add_prop receives their current sprite/alpha, never old cached awnings.
		fading.erase(String(row.id))
	for row: Dictionary in value.projection.added:
		if String(row.id) in ids or String(row.id) in fading:
			return false
		ids.append(String(row.id))
	return true
static func purpose_binding(scene: SceneScript) -> Dictionary:
	var parent: Variant = _parent()
	return parent.purpose_binding(scene) if bound(scene) and parent!=null else {}
static func owns_room(id: StringName) -> bool:
	var parent: Variant = _parent()
	return parent.owns_room(id) if not binding().is_empty() and parent!=null else false
static func room_binding(id: StringName,original: Dictionary) -> Dictionary:
	var parent: Variant = _parent()
	return parent.room_binding(id,original) if not binding().is_empty() and parent!=null else {}
static func portals(scene: SceneScript,original: Array) -> Dictionary:
	var parent: Variant = _parent()
	return parent.portals(scene,original) if not binding().is_empty() and parent!=null else {"ok":false,"error":"MARKET25G_PARENT_UNAVAILABLE"}
static func author_record(id: StringName,original: Dictionary) -> Dictionary:
	var parent: Variant = _parent()
	return parent.author_record(id,original) if not binding().is_empty() and parent!=null else {}
static func fresh_foot(id: StringName,route_key: String,route: Dictionary,prior: Variant) -> Variant:
	var parent: Variant = _parent()
	return parent.fresh_foot(id,route_key,route,prior) if not binding().is_empty() and parent!=null else null
static func default_spawn(scene: SceneScript,authored: Vector2,override: Variant) -> Vector2:
	var parent: Variant = _parent()
	return parent.default_spawn(scene,authored,override) if not binding().is_empty() and parent!=null else Vector2(INF,INF)
static func authored_default_spawn(scene: SceneScript,authored: Vector2) -> Vector2:
	var parent: Variant = _parent()
	return parent.authored_default_spawn(scene,authored) if not binding().is_empty() and parent!=null else Vector2(INF,INF)
static func project_npcs(scene: SceneScript,original: Array,require_all: bool=true) -> Array:
	var parent: Variant = _parent()
	return parent.project_npcs(scene,original,require_all) if not binding().is_empty() and parent!=null else []
static func project_interactions(scene: SceneScript,original: Array) -> Array:
	var parent: Variant = _parent()
	return parent.project_interactions(scene,original) if not binding().is_empty() and parent!=null else []
static func project_paper_npc(scene: SceneScript,original: Array) -> Array:
	var parent: Variant = _parent()
	return parent.project_paper_npc(scene,original) if not binding().is_empty() and parent!=null else []
static func projected_return_foot(id: StringName,old_foot: Vector2) -> Vector2:
	var parent: Variant = _parent()
	return parent.projected_return_foot(id,old_foot) if not binding().is_empty() and parent!=null else Vector2(INF,INF)
static func pawn_transform(scene: SceneScript) -> Dictionary:
	var parent: Variant = _parent()
	return parent.pawn_transform(scene) if not binding().is_empty() and parent!=null else {}
