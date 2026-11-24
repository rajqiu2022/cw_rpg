extends RefCounted
## Market24e source-FIRST authority, then one same-Scene/Field lease. No native mutation.
const READY=true
const SELF="res://build/luoyang_city_revision_20261024e_source01/runtime_ready01/market_block_session_READY.gd"
const BIND="res://build/luoyang_city_revision_20261024e_source01/runtime_ready01/binding_READY.json"
const BIND_SHA="55e1db14ddfb5bbec7b9ad0096e9e9a53af250ed4c8dc6cb83e5ddbc9202b6fb"
const AUTHOR="res://build/luoyang_city_blocks_20261024e_system01/author_market_block07_paper_foot_NOTREADY.json"
const AUTHOR_SHA="de1911cceb5fb10e6b3b1aba1fa6d9d34057358841febdd285d25a1a1eb65e95"
const PURE="res://build/luoyang_city_blocks_20261024e_system01/market_block_projection05_NOTREADY.gd"
const PURE_SHA="60ae6c66f0357798f7fbca5b790a27c00c993fca43886759430b5e0717fafa32"
const C_PATH="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const B_PATH="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const FIELD_PATH="res://scripts/field/field_walkable_controller.gd"
const ID=&"ch4_s3_luoyang_market"
const SIZE=Vector2(3072,2048)
static var _states: Dictionary={}
static var _config: Dictionary={}
static var _author: Dictionary={}
static var _pure: Variant=null
static func requested(scene: SceneScript) -> bool: return scene!=null and scene.scene_id==ID
static func _hash(value: Variant) -> bool:
	if not value is String or value.length()!=64: return false
	for character: int in value.to_ascii_buffer():
		if not character in range(48,58) and not character in range(97,103): return false
	return true
static func _json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
static func _sha(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes);return hash.finish().hex_encode()
static func binding() -> Dictionary:
	if not READY or not _hash(BIND_SHA): return {}
	if not _config.is_empty(): return _config
	if FileAccess.get_sha256(BIND)!=BIND_SHA: return {}
	var b:=_json(BIND)
	if b.get("ready")!=true or b.get("status")!="MARKET24E_SOURCE_BOUND_BLOCK_OVERLAY_READY" or b.get("scene_id")!=String(ID) or b.get("author_path")!=AUTHOR or b.get("author_sha256")!=AUTHOR_SHA or b.get("pure_path")!=PURE or b.get("pure_sha256")!=PURE_SHA or not b.get("required_source_sha256") is Dictionary: return {}
	var pins: Dictionary=b.required_source_sha256
	if pins.get(AUTHOR)!=AUTHOR_SHA or pins.get(PURE)!=PURE_SHA or pins.has(SELF) or pins.has(BIND) or b.get("no_native_record_mutation")!=true or b.get("room_geometry_unchanged")!=true: return {}
	for key: String in ["publication_header","local_art"]:
		var row: Dictionary=b.get(key,{})
		if not row.get("path") is String or not _hash(row.get("sha256")) or pins.get(row.path)!=row.sha256: return {}
	if b.local_art.get("admitted")!=true or not b.get("mask") is Dictionary or not _hash(b.mask.get("RGBA_sha256")): return {}
	for key: String in ["path","import_path","compiled_path"]:
		if not b.mask.get(key) is String or not pins.has(b.mask[key]): return {}
	if b.mask.import_path!=String(b.mask.path)+".import": return {}
	for path: String in pins:
		if not path.begins_with("res://") or ".." in path or not _hash(pins[path]): return {}
	if FileAccess.get_sha256(AUTHOR)!=AUTHOR_SHA or FileAccess.get_sha256(PURE)!=PURE_SHA: return {}
	_author=_json(AUTHOR);_pure=load(PURE)
	if _author.get("scene_id")!=String(ID) or not _pure is GDScript or _pure.resource_path!=PURE or _author.get("room_migrations",[]).size()!=6 or _author.get("external_portal_migrations",[]).size()!=2: return {}
	_config=b;return b
static func source_paths_for(id: StringName) -> Dictionary:
	if id!=ID: return {}
	var b:=binding()
	if b.is_empty(): return {}
	var out: Dictionary={SELF:true,BIND:true}
	for path: String in b.required_source_sha256: out[path]=true
	return out
static func room_source_paths() -> Dictionary:
	# Same six existing room consumers need exact return-author/code, not city media.
	if binding().is_empty(): return {}
	return {SELF:true,BIND:true,AUTHOR:true,PURE:true}
static func _proof(scene: SceneScript) -> Dictionary:
	var c: Variant=load(C_PATH)
	for proof: Dictionary in [c._transition_validation,c._resident_ready]:
		if proof.get("scene")==scene and proof.get("id")==ID and int(proof.get("token",0))>0: return proof
	return {}
static func _fail(reason: String) -> Dictionary: return {"ok":false,"error":reason}
static func _valid(scene: SceneScript) -> Dictionary:
	if not requested(scene) or scene.map_layout==null: return {}
	var value: Dictionary=_states.get(scene.get_instance_id(),{})
	if value.is_empty() or value.get("invalid",false) or value.scene.get_ref()!=scene or value.layout.get_ref()!=scene.map_layout: return {}
	var proof:=_proof(scene)
	if int(proof.get("token",0))!=value.token: return {} # B whole storage verified once at acquire authority; original C FIRST/FINAL + same Scene/layout/token stay mandatory.
	if value.get("attached",false):
		var field: Node=value.field.get_ref();var district: RefCounted=value.district.get_ref()
		if not is_instance_valid(field) or district==null or field.get("_current_scene")!=scene or field.get("_district_session")!=district or int(field.get("_city3_motion_revision"))!=value.motion_revision or (not field.is_inside_tree() and field.get("_resident_parked")!=true): return {}
	return value
static func ensure(scene: SceneScript) -> Dictionary:
	if not requested(scene): return {}
	var existing:=_valid(scene)
	if not existing.is_empty(): return existing
	if _states.has(scene.get_instance_id()): return {} # No token rebinding of a prior lease.
	var b:=binding();var proof:=_proof(scene)
	if b.is_empty() or proof.is_empty() or not load(B_PATH).whole_bound(scene): return {}
	var sources: Dictionary=proof.get("sources",{})
	if sources.get(BIND)!=BIND_SHA or not _hash(sources.get(SELF)): return {}
	for path: String in b.required_source_sha256:
		if sources.get(path)!=b.required_source_sha256[path]: return {}
	for name: String in _author.parent.artifacts:
		var old_artifact: Dictionary=_author.parent.artifacts[name]
		if sources.get(old_artifact.path)!=old_artifact.sha256: return {}
	if sources.get(_author.parent.current_runtime)!=_author.parent.current_runtime_sha256 or sources.get(_author.parent.author_path)!=_author.parent.author_sha256: return {}
	for asset: Dictionary in _author.assets.values():
		if sources.get(asset.texture)!=asset.source_sha256: return {}
	var header:=_json(b.publication_header.path)
	if header.get("status")!="MARKET24E_BLOCK_OVERLAY_BUILD_ONLY" or header.get("author_path")!=AUTHOR or header.get("author_sha256")!=AUTHOR_SHA or header.get("combined_visuals_before")!=37 or header.get("combined_visuals_after")!=43 or header.get("full_render_inverse")!=true or header.get("full_RGBA_inverse")!=true or header.get("route_proof",{}).get("ok")!=true or header.get("walk_path")!=b.mask.path or header.get("walk_RGBA_sha256")!=b.mask.RGBA_sha256: return {}
	if header.get("parent_native4_unchanged")!=_author.parent.artifacts: return {}
	for key: String in ["render_projection","geometry","pixel_inverse"]:
		var artifact: Dictionary=header.get(key,{})
		if b.required_source_sha256.get(artifact.get("path",""))!=artifact.get("sha256"): return {}
	var projection: Variant=bytes_to_var(FileAccess.get_file_as_bytes(header.render_projection.path))
	var primitives: Variant=bytes_to_var(FileAccess.get_file_as_bytes(header.geometry.path))
	if not projection is Dictionary or projection.get("ok")!=true or projection.get("render",[]).size()!=43 or not primitives is Array or primitives.is_empty() or _pure.restore(projection).size()!=37 or var_to_bytes(_pure.primitives(projection.render))!=var_to_bytes(primitives): return {}
	var texture:=ResourceLoader.load(b.mask.path) as Texture2D
	var mask: Image=texture.get_image() if texture!=null else null
	if mask==null or mask.get_size()!=Vector2i(3072,2048) or mask.has_mipmaps() or mask.get_format() not in [Image.FORMAT_RGB8,Image.FORMAT_RGBA8]: return {}
	var original_format: int=mask.get_format()
	if original_format==Image.FORMAT_RGB8: mask.convert(Image.FORMAT_RGBA8)
	if _sha(mask.get_data())!=b.mask.RGBA_sha256: return {}
	var solids: Array[PackedVector2Array]=[];var areas: Array[Rect2]=[]
	for row: Dictionary in primitives:
		var shape: PackedVector2Array=_pure.poly(row.points_px)
		if shape.size()<3 or Geometry2D.triangulate_polygon(shape).is_empty(): return {}
		solids.append(shape);areas.append(_pure.bounds(shape))
	for key: int in _states.keys():
		if _states[key].scene.get_ref()==null: _states.erase(key)
	var value: Dictionary={"scene":weakref(scene),"layout":weakref(scene.map_layout),"token":int(proof.token),"sources":sources.duplicate(),"projection":projection,"projection_value_fingerprint":_sha(var_to_bytes(projection)),"render43_value_fingerprint":_sha(var_to_bytes(projection.render)),"solid_value_fingerprint":_sha(var_to_bytes(solids)),"boundary_integrity_checks":0,"mask":mask,"solids":solids,"bounds":areas,"attached":false,"finalized":false,"mask_format_before":original_format}
	_states[scene.get_instance_id()]=value;return value
static func acquire(scene: SceneScript,field: Node,district: RefCounted,owner: Callable,sources: Dictionary,proof: Dictionary,before: Array) -> Dictionary:
	var value:=ensure(scene)
	if value.is_empty() or value.attached or not is_instance_valid(field) or not field.is_inside_tree() or field.get_script().resource_path!=FIELD_PATH or field.get("_current_scene")!=scene or field.get("_district_session")!=district or not owner.is_valid() or not owner.call() or int(proof.get("token",0))!=value.token or sources!=value.sources: return _fail("MARKET24E_SOURCE_FIRST_FIELD_OWNER")
	var fresh: Dictionary=_pure.project(_author,before)
	if fresh.get("ok")!=true or var_to_bytes(_pure.restore(value.projection))!=var_to_bytes(before) or var_to_bytes(fresh)!=var_to_bytes(value.projection): return _fail("MARKET24E_FULL_ACTUAL_PARENT37_AND_CHILD43")
	value.field=weakref(field);value.district=weakref(district);value.motion_revision=int(field.get("_city3_motion_revision"));value.attached=true
	return state(scene)
static func render(scene: SceneScript,before: Array) -> Array:
	var value:=_valid(scene)
	if value.is_empty() or not value.attached or var_to_bytes(before)!=var_to_bytes(_pure.restore(value.projection)): return []
	return value.projection.render.duplicate(true)
static func effective_mask(scene: SceneScript) -> Image:
	var value:=_valid(scene);return value.mask if not value.is_empty() and value.attached else null
static func solids(scene: SceneScript) -> Array[PackedVector2Array]:
	var value:=_valid(scene);var empty: Array[PackedVector2Array]=[]
	return value.solids if not value.is_empty() and value.attached else empty
static func lease_bound(scene: SceneScript,district: RefCounted) -> bool:
	var value:=_valid(scene);return not value.is_empty() and value.attached and value.district.get_ref()==district
static func safe_body_for_receipt(id: StringName,foot: Vector2,proof: Dictionary) -> Dictionary:
	if id!=ID: return {"matched":false}
	if not proof.get("scene") is SceneScript: return {"matched":true,"safe":false}
	var value:=ensure(proof.scene)
	if value.is_empty() or int(proof.get("token",0))!=value.token or not foot.is_finite(): return {"matched":true,"safe":false}
	# Original complete 875-pixel + closed polygon/body semantics; no hot IO.
	var clear: bool=load(C_PATH)._safe_body_cpu(foot,value.mask,value.solids)
	return {"matched":true,"safe":clear}
static func finalize(scene: SceneScript,district: RefCounted,sources: Dictionary) -> bool:
	var value:=_valid(scene);var proof:=_proof(scene)
	if value.is_empty() or not lease_bound(scene,district) or proof.get("sources")!=sources or proof.get("live_scope",false) and proof.get("sources_finalized")!=true: return false
	if not validate_cached_boundary(scene,district): return false
	value.finalized=true;return true
static func release(scene: SceneScript,district: RefCounted) -> void:
	if scene==null: return
	var value: Dictionary=_states.get(scene.get_instance_id(),{})
	if not value.is_empty() and value.get("attached",false) and value.district.get_ref()==district: _states.erase(scene.get_instance_id())
static func state(scene: SceneScript) -> Dictionary:
	var value:=_valid(scene)
	return {"ok":true,"token":value.token,"scene_instance":scene.get_instance_id(),"layout_instance":scene.map_layout.get_instance_id(),"attached":value.attached,"finalized":value.finalized,"render_count":43,"solid_count":value.solids.size(),"mask_path":_config.mask.path,"mask_format_before":value.mask_format_before,"mask_format_after":value.mask.get_format(),"one_time_RGBA_and_geometry":true} if not value.is_empty() else _fail("MARKET24E_NO_CURRENT_LEASE")
static func _room(id: StringName) -> Dictionary:
	if binding().is_empty(): return {}
	for row: Dictionary in _author.room_migrations:
		if row.room_id==String(id): return row
	return {}
static func owns_room(id: StringName) -> bool: return not _room(id).is_empty()
static func room_binding(id: StringName,original: Dictionary) -> Dictionary:
	var row:=_room(id)
	if row.is_empty(): return original.duplicate(true)
	if original.get("city_id")!=String(ID) or original.get("building_id")!=row.building_id or _pure.v(original.get("return_foot_px"))!=_pure.v(row.old_return_foot_px): return {}
	var out:=original.duplicate(true);out.return_foot_px=row.return_foot_px.duplicate(true);return out
static func portals(scene: SceneScript,original: Array) -> Dictionary:
	if scene==null: return _fail("MARKET24E_NULL_PORTAL_SCENE")
	if not requested(scene) and not owns_room(scene.scene_id): return {"ok":true,"portals":original}
	if binding().is_empty() or requested(scene) and ensure(scene).is_empty(): return _fail("MARKET24E_PORTAL_SOURCE_AUTHORITY")
	var out:=original.duplicate(true)
	if owns_room(scene.scene_id):
		var row:=_room(scene.scene_id);var count: int=0
		for portal: Dictionary in out:
			if String(portal.get("target_scene",""))!=String(ID): continue
			count+=1
			if portal.get("target_pos")!=_pure.v(row.old_return_foot_px)/SIZE: return _fail("MARKET24E_ORIGINAL_ROOM_RETURN")
			portal.target_pos=_pure.v(row.return_foot_px)/SIZE
		return {"ok":true,"portals":out} if count==1 else _fail("MARKET24E_ROOM_RETURN_COUNT")
	for row: Dictionary in _author.room_migrations:
		var count: int=0
		for portal: Dictionary in out:
			if String(portal.get("target_scene",""))!=row.room_id: continue
			count+=1
			var old_foot: Vector2=_pure.v(row.old_return_foot_px)
			# Existing24b drug/book native thresholds are distinct from returns.
			if row.building_id=="market_northeast_rear_frontage": old_foot=Vector2(1690,1596)
			elif row.building_id=="market_east_ward_frontage": old_foot=Vector2(2610,1596)
			if portal.get("pos")!=old_foot/SIZE or portal.get("size")!=Vector2(40,32)/SIZE or portal.get("auto_trigger")!=false: return _fail("MARKET24E_ORIGINAL_CITY_DOOR:"+row.room_id)
			var foot: Vector2=_pure.v(row.threshold_px) if row.building_id in ["market_northeast_rear_frontage","market_east_ward_frontage"] else _pure.v(row.return_foot_px)
			portal.pos=foot/SIZE;portal.interaction_polygon_px=PackedVector2Array([foot+Vector2(-20,-16),foot+Vector2(20,-16),foot+Vector2(20,16),foot+Vector2(-20,16)])
		if count!=1: return _fail("MARKET24E_CITY_DOOR_COUNT:"+row.room_id)
	for row: Dictionary in _author.external_portal_migrations:
		var count: int=0
		for portal: Dictionary in out:
			if portal.get("id")!=row.id: continue
			count+=1
			if portal.get("pos")!=_pure.v(row.old_foot_px)/SIZE: return _fail("MARKET24E_ORIGINAL_EXTERNAL_DOOR:"+row.id)
			var foot: Vector2=_pure.v(row.foot_px);portal.pos=foot/SIZE
			if portal.has("interaction_polygon_px"):
				var points: PackedVector2Array=_pure.poly(portal.interaction_polygon_px);var delta: Vector2=foot-_pure.v(row.old_foot_px)
				for index: int in range(points.size()): points[index]+=delta
				portal.interaction_polygon_px=points
		if count!=1: return _fail("MARKET24E_EXTERNAL_DOOR_COUNT:"+row.id)
	return {"ok":true,"portals":out}
static func author_record(id: StringName,original: Dictionary) -> Dictionary:
	if id!=ID: return original
	if binding().is_empty(): return {}
	var out:=original.duplicate(true)
	for change: Dictionary in _author.external_portal_migrations:
		var count: int=0
		for row: Dictionary in out.get("gameplay_slots",{}).get("portals",[]):
			if row.get("source_id")!=change.id: continue
			count+=1
			if _pure.v(row.get("arrival_foot_px"))!=_pure.v(change.old_foot_px): return {}
			row.arrival_foot_px=change.foot_px.duplicate(true)
		if count!=1: return {}
	return out
static func fresh_foot(id: StringName,route_key: String,route: Dictionary,prior: Variant) -> Variant:
	if id!=ID: return prior
	if binding().is_empty(): return null
	for row: Dictionary in _author.external_portal_migrations:
		var expected: String="ch4_s4_ancient_temple->"+String(ID) if row.id=="to_ancient_temple" else "ch4_s2_canal_docks->"+String(ID)
		if route_key==expected:
			if route.get("slot")!=row.id or not prior is Vector2 or prior!=_pure.v(row.old_foot_px): return null
			return _pure.v(row.foot_px)
	return prior
static func default_spawn(scene: SceneScript,authored: Vector2,override: Variant) -> Vector2:
	if not requested(scene): return authored
	if binding().is_empty() or ensure(scene).is_empty() or authored!=_pure.v(_author.default_spawn.old_foot_px)/SIZE: return Vector2(INF,INF)
	return _pure.v(_author.default_spawn.foot_px)/SIZE if not override is Vector2 else authored
static func project_npcs(scene: SceneScript,original: Array,require_all: bool=true) -> Array:
	if not requested(scene): return original
	if ensure(scene).is_empty(): return []
	var out:=original.duplicate(true)
	for row: Dictionary in _author.npc_migrations:
		if row.id=="luoyang_paper_artisan_20261016": continue # Applied only at the final post-Coordinator/Culture consumer below.
		var count: int=0
		for npc: Dictionary in out:
			var expected_id: String=String(row.id) if row.id in ["luoyang_armorer","luoyang_paper_artisan_20261016"] else "district_life_"+String(row.id)
			if String(npc.get("npc_id",""))!=expected_id: continue
			count+=1
			if npc.get("pos")!=_pure.v(row.old_foot_px)/SIZE or (row.has("distance_px") and float(npc.get("patrol_distance",-1))!=float(row.distance_px)): return []
			npc.pos=_pure.v(row.foot_px)/SIZE
		if count>1 or (count!=1 and (require_all or row.id in ["luoyang_armorer","luoyang_paper_artisan_20261016"])): return []
	return out
static func project_interactions(scene: SceneScript,original: Array) -> Array:
	if not requested(scene): return original
	if ensure(scene).is_empty(): return []
	var out:=original.duplicate(true)
	for change: Dictionary in _author.interaction_migrations:
		var count: int=0
		for row: Dictionary in out:
			if String(row.get("id",""))!=change.id: continue
			count+=1
			if row.get("pos")!=_pure.v(change.old_foot_px)/SIZE: return []
			row.pos=_pure.v(change.foot_px)/SIZE
		if count!=1: return []
	return out

static func render_with_ground(scene: SceneScript,before: Array,old_ground: Array) -> Array:
	# Old ground.prepare/render gates execute first on their exact original37.
	if before.size()!=37 or old_ground.size()!=38 or var_to_bytes(old_ground.slice(0,37))!=var_to_bytes(before): return []
	var out:=render(scene,before)
	if out.size()!=43: return []
	var stamp: Dictionary=old_ground[37].duplicate(true)
	if stamp.get("id")!="market_ground_ae_cross_street_wear_v1" or stamp.get("texture")!="res://art/modules/luoyang_shore_market_20261020ae/decal_market_cross_street_stall_wear_patch_v1.png" or stamp.get("pos")!=Vector2(1530,1196)/SIZE or stamp.get("render_size_px")!=Vector2(958.5997425997426,368) or stamp.get("blocking")!=false or stamp.get("sort_by_feet")!=false or stamp.get("z_index")!=-998 or stamp.get("modulate")!=Color(1,1,1,.38): return []
	# Same complete PNG / opacity / purpose; move and uniformly resize to the
	# real southern service cross-street, not beneath the relocated rear house.
	stamp.pos=Vector2(2197,1486)/SIZE
	stamp.render_size_px=Vector2(2024,777)*(580.0/2024.0)
	out.append(stamp);return out
static func purpose_binding(scene: SceneScript) -> Dictionary:
	var value:=_valid(scene)
	return {"ok":true,"ready":true,"author_path":AUTHOR,"author_sha256":AUTHOR_SHA,"source_FIRST_token":value.token,"render_parent37_child43_verified":value.attached} if not value.is_empty() and value.attached else {}

static func projected_return_foot(id: StringName,old_foot: Vector2) -> Vector2:
	var row:=_room(id)
	if row.is_empty(): return old_foot
	return _pure.v(row.return_foot_px) if old_foot==_pure.v(row.old_return_foot_px) else Vector2(INF,INF)
static func configure_depth(scene: SceneScript,district: RefCounted,fade: RefCounted) -> bool:
	var value:=_valid(scene)
	if value.is_empty() or not lease_bound(scene,district) or fade==null: return false
	var ids: Variant=fade.get("_ids");var fading: Variant=fade.get("_fade_ids")
	if not ids is Array or not fading is Array: return false
	# Original configure_district has already admitted every old parent/DG ID.
	for row: Dictionary in _pure.restore(value.projection):
		if row.get("sort_by_feet",false) and String(row.id) not in ids: return false
	var added: Array=[]
	for row: Dictionary in value.projection.added:
		if String(row.id) in ids or String(row.id) in fading or String(row.id) in added or row.get("sort_by_feet")!=true: return false
		added.append(String(row.id))
	if added.size()!=6: return false
	ids.append_array(added) # Only exact source-bound new6; opaque actor-local ghost, not whole-prop fade.
	return true

static func bound(scene: SceneScript) -> bool:
	var value:=_valid(scene);return not value.is_empty() and value.attached
static func pawn_transform(scene: SceneScript) -> Dictionary:
	var value:=_valid(scene)
	if value.is_empty() or not value.attached: return {}
	var row: Dictionary=_pure.find(value.projection.render,"market_west_ward_frontage")
	return {"ok":true,"scale":_pure.v(row.render_size_px)/Vector2(1039,696),"center":_pure.v(row.pos)*SIZE} if not row.is_empty() else {}

static func authored_default_spawn(scene: SceneScript,authored: Vector2) -> Vector2:
	if not requested(scene): return authored
	if binding().is_empty() or ensure(scene).is_empty() or authored!=_pure.v(_author.default_spawn.old_foot_px)/SIZE: return Vector2(INF,INF)
	var next: Vector2=_pure.v(_author.default_spawn.foot_px)/SIZE
	return next if safe_body_for_receipt(ID,next*SIZE,_proof(scene)).get("safe",false)==true else Vector2(INF,INF)

static func project_paper_npc(scene: SceneScript,original: Array) -> Array:
	if not requested(scene): return original
	if ensure(scene).is_empty(): return []
	var declaration: Dictionary={}
	for row: Dictionary in _author.npc_migrations:
		if row.id=="luoyang_paper_artisan_20261016": declaration=row
	if declaration.is_empty() or _pure.v(declaration.old_foot_px)!=Vector2(880,1340) or _pure.v(declaration.foot_px)!=Vector2(888,1340): return []
	var out:=original.duplicate(true);var count: int=0
	for npc: Dictionary in out:
		if npc.get("npc_id")!="luoyang_paper_artisan_20261016": continue
		count+=1
		if npc.get("pos")!=Vector2(880,1340)/SIZE: return []
		npc.pos=Vector2(888,1340)/SIZE
	return out if count==1 else []

static func validate_cached_boundary(scene: SceneScript,district: RefCounted) -> bool:
	# Cold FINAL and warm-resume only. Never called from C.safe_body or frames.
	var value:=_valid(scene)
	if value.is_empty() or not value.attached or value.district.get_ref()!=district: return false
	var mask: Image=value.mask
	if mask==null or mask.get_size()!=Vector2i(3072,2048) or mask.get_format()!=Image.FORMAT_RGBA8 or mask.has_mipmaps() or _sha(mask.get_data())!=_config.mask.RGBA_sha256: return false
	# Value fingerprints are captured only after the fixed artifact decode and
	# source-FIRST checks. geometry.bin is row dictionaries; cached solids are
	# PackedVector2Array values, so deliberately do NOT compare unlike encodings.
	if _sha(var_to_bytes(value.projection))!=value.projection_value_fingerprint or _sha(var_to_bytes(value.projection.render))!=value.render43_value_fingerprint or _sha(var_to_bytes(value.solids))!=value.solid_value_fingerprint: return false
	value.boundary_integrity_checks=int(value.boundary_integrity_checks)+1
	return true
