extends RefCounted
## Docks24e BUILD: immutable native29 plus source-derived DG10, one same-owner overlay lease.
const READY=true
const SELF="res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/runtime02_READY/docks_frontage_session_READY.gd"
const BIND="res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/runtime02_READY/binding_READY.json"
const BIND_SHA="dffded2e8d3bce09b50e3f127e26a060b6b3ab64ee9122c2ff3fb87184fbd012"
const AUTHOR="res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/author02_exact_sack_NOTREADY.json"
const AUTHOR_SHA="7a370e1782fdc4366c2ae73635debe3db3f39b70ef82a71d6d87e480b58c792e"
const PURE="res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/pure_three_record_delta02_NOTREADY.gd"
const PURE_SHA="38ae6a339a2b5c23c6faaa5fd15bb11e9997f9a97af26ad7cea5fb5760b84b71"
const DG_AUTHOR="res://data/maps/luoyang_district_life_20261016f/author.json"
const DG_SHA="d98c65879681b58feea64158a4d0bde33d2ef9fc6b8a25d7d2f33dc961a9c59c"
const C_PATH="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const B_PATH="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const FIELD_PATH="res://scripts/field/field_walkable_controller.gd"
const ID=&"ch4_s2_canal_docks"
const ROOM=&"luoyang_canal_warehouse_interior_20261016"
const SIZE=Vector2(3072,2048)
static var _config: Dictionary={}
static var _author: Dictionary={}
static var _pure: Variant=null
static var _states: Dictionary={}
static func requested(scene: SceneScript) -> bool: return scene!=null and scene.scene_id==ID
static func _sha(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes);return hash.finish().hex_encode()
static func _hash(value: Variant) -> bool:
	if not value is String or value.length()!=64: return false
	for character: int in value.to_ascii_buffer():
		if character not in range(48,58) and character not in range(97,103): return false
	return true
static func _json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
static func _fail(reason: String) -> Dictionary: return {"ok":false,"error":reason}
static func binding() -> Dictionary:
	if not READY or not _hash(BIND_SHA): return {}
	if not _config.is_empty(): return _config
	if FileAccess.get_sha256(BIND)!=BIND_SHA: return {}
	var b:=_json(BIND)
	if b.get("ready")!=true or b.get("status")!="DOCKS24E_SOURCE_BOUND_FRONTAGES_READY" or b.get("scene_id")!=String(ID) or b.get("author_path")!=AUTHOR or b.get("author_sha256")!=AUTHOR_SHA or b.get("pure_path")!=PURE or b.get("pure_sha256")!=PURE_SHA: return {}
	if b.get("no_native_record_mutation")!=true or b.get("room_geometry_unchanged")!=true or not b.get("required_source_sha256") is Dictionary: return {}
	var pins: Dictionary=b.required_source_sha256
	if pins.get(AUTHOR)!=AUTHOR_SHA or pins.get(PURE)!=PURE_SHA or pins.get(DG_AUTHOR)!=DG_SHA or pins.has(SELF) or pins.has(BIND): return {}
	for key: String in ["publication_header","local_art"]:
		var row: Dictionary=b.get(key,{})
		if not row.get("path") is String or not _hash(row.get("sha256")) or pins.get(row.path)!=row.sha256: return {}
	if b.local_art.get("admitted")!=true or b.local_art.get("scope")!="SOURCE_ASSET_AND_AUTHORED_LAYOUT_FIELD_TRIAL_ONLY": return {}
	if not b.get("mask") is Dictionary or b.mask.get("RGBA_sha256")!="0d0a5871dfa2dcd76c12861b238161f23e30f16ddbe71a545b62d2eeb1bb0816": return {}
	for key: String in ["path","import_path","compiled_path"]:
		if not b.mask.get(key) is String or not pins.has(b.mask[key]): return {}
	if b.mask.import_path!=String(b.mask.path)+".import": return {}
	for path: String in pins:
		if not path.begins_with("res://") or ".." in path or not _hash(pins[path]): return {}
	if FileAccess.get_sha256(AUTHOR)!=AUTHOR_SHA or FileAccess.get_sha256(PURE)!=PURE_SHA: return {}
	_author=_json(AUTHOR);_pure=load(PURE)
	if not _pure is GDScript or _pure.resource_path!=PURE or _author.get("scene_id")!=String(ID) or _author.get("changes",[]).size()!=3: return {}
	_config=b;return b
static func source_paths_for(id: StringName) -> Dictionary:
	if id!=ID: return {}
	var b:=binding()
	if b.is_empty(): return {}
	var paths: Dictionary={SELF:true,BIND:true}
	for path: String in b.required_source_sha256: paths[path]=true
	return paths
static func room_source_paths() -> Dictionary:
	# Shared G closure: code/author binding only, not the Docks mask/media/proof payload.
	if binding().is_empty(): return {}
	return {SELF:true,BIND:true,AUTHOR:true,PURE:true}
static func _proof(scene: SceneScript) -> Dictionary:
	var c: Variant=load(C_PATH)
	for proof: Dictionary in [c._transition_validation,c._resident_ready]:
		if proof.get("scene")==scene and proof.get("id")==ID and int(proof.get("token",0))>0: return proof
	return {}
static func _valid(scene: SceneScript) -> Dictionary:
	if not requested(scene) or scene.map_layout==null: return {}
	var value: Dictionary=_states.get(scene.get_instance_id(),{})
	if value.is_empty() or value.get("invalid",false) or value.scene.get_ref()!=scene or value.layout.get_ref()!=scene.map_layout: return {}
	if int(_proof(scene).get("token",0))!=value.token: return {}
	if value.attached:
		var field: Node=value.field.get_ref();var district: RefCounted=value.district.get_ref()
		if not is_instance_valid(field) or district==null or field.get("_current_scene")!=scene or field.get("_district_session")!=district or int(field.get("_city3_motion_revision"))!=value.motion_revision or (not field.is_inside_tree() and field.get("_resident_parked")!=true): return {}
	return value
static func _district_entries(data: Dictionary) -> Array:
	# Independent complete render declaration: identical fixed D98/C320 source formula,
	# NOT DG.project / manifest / live render used to manufacture its own expected.
	var placements: Array=data.get("districts",{}).get(String(ID),{}).get("placements",[])
	if placements.size()!=10: return []
	var result: Array=[];var seen: Dictionary={}
	for placement: Dictionary in placements:
		var id: String=String(placement.get("id",""))
		var asset: Dictionary=data.get("assets",{}).get(String(placement.get("asset_id","")),{})
		if id.is_empty() or seen.has(id) or asset.is_empty() or not String(placement.get("replaces","")).is_empty(): return []
		seen[id]=true
		var foot: Vector2=_pure.v(placement.get("foot_px"));var size: Vector2=_pure.v(asset.get("size_px"));var anchor: Vector2=_pure.v(asset.get("source_ground_anchor_px"));var scale: float=float(placement.get("scale",0))
		if not foot.is_finite() or not size.is_finite() or not anchor.is_finite() or not is_finite(scale) or scale<=0: return []
		var shapes: Array=[]
		for raw: Variant in asset.get("ground_solid_polygons_px",[]):
			var source: PackedVector2Array=_pure.polygon(raw);var shape: Array=[]
			if source.size()<3: return []
			for point: Vector2 in source: shape.append(_pure.xy(foot+(point-anchor)*scale))
			shapes.append(shape)
		if shapes.is_empty(): return []
		result.append({"id":id,"texture":String(asset.texture),"pos":(foot+(size*.5-anchor)*scale)/SIZE,"render_size_px":size*scale,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y,"world_foot_px":_pure.xy(foot),"physical_center_px":_pure.xy(foot),"collision_size_px":[0.0,0.0],"city_v3_solid_polygons_px":shapes,"blocking":true,"district_life_asset_id":placement.asset_id,"district_life_fade":placement.get("fade",false)})
	return result
static func _render_projection(native_render: Array,projection: Dictionary,additions: Array) -> Dictionary:
	if native_render.size()!=29 or additions.size()!=10: return {}
	var before: Array=native_render.duplicate(true);before.append_array(additions.duplicate(true))
	var after: Array=before.duplicate(true)
	for id: String in projection.changed_ids:
		var original: Dictionary=_pure.find(projection.originals,id)
		var target: Dictionary=_pure.find(projection.child.objects,id)
		var current: Dictionary=_pure.find(after,id)
		if original.is_empty() or target.is_empty() or current.is_empty() or current.get("texture")!=original.get("texture") or _pure.v(current.get("world_foot_px"))!=_pure.v(original.get("world_foot_px")) or _pure.v(current.get("render_size_px"))!=_pure.v(original.get("render_size_px")) or _pure.v(current.get("collision_size_px"))!=Vector2.ZERO or not _pure.exact_solids(current.get("city_v3_solid_polygons_px"),original.solid_polygons_px): return {}
		var foot: Vector2=_pure.v(target.world_foot_px);var size: Vector2=_pure.v(target.render_size_px)
		current.pos=(foot+(Vector2(.5,.5)-_pure.v(target.foot_uv))*size)/SIZE
		current.render_size_px=size;current.world_foot_px=target.world_foot_px.duplicate();current.physical_center_px=target.physical_center_px.duplicate()
		current.depth_sort_foot_y=foot.y/SIZE.y;current.city_v3_solid_polygons_px=target.solid_polygons_px.duplicate(true)
		for key: String in ["depth_foot_y","world_origin_px","harbour_transform"]:
			if target.has(key): current[key]=target[key].duplicate(true) if target[key] is Dictionary or target[key] is Array else target[key]
	return {"before":before,"after":after}
static func ensure(scene: SceneScript) -> Dictionary:
	if not requested(scene): return {}
	var existing:=_valid(scene)
	if not existing.is_empty(): return existing
	if _states.has(scene.get_instance_id()): return {}
	var b:=binding();var proof:=_proof(scene)
	var bundle: Variant=load(B_PATH);var city: Variant=load(C_PATH)
	if b.is_empty() or proof.is_empty() or not bundle.whole_bound(scene): return {}
	var sources: Dictionary=proof.get("sources",{})
	if sources.get(BIND)!=BIND_SHA or not _hash(sources.get(SELF)): return {}
	for path: String in b.required_source_sha256:
		if sources.get(path)!=b.required_source_sha256[path]: return {}
	if sources.get(_author.fixed_parent_packet.path)!=_author.fixed_parent_packet.sha256: return {}
	var header:=_json(b.publication_header.path)
	if header.get("status")!="DOCKS_THREE_FRONTAGES_CPU_OVERLAY_BUILD_ONLY" or header.get("author_path")!=AUTHOR or header.get("author_sha256")!=AUTHOR_SHA or header.get("native_parent29_unchanged")!=_author.fixed_parent_packet.path or header.get("combined_visual_count")!=39 or header.get("full_parent_record_inverse")!=true or header.get("local_geometry_ok")!=true or header.get("full_RGBA_inverse")!=true or header.get("walk_RGBA_sha256")!=b.mask.RGBA_sha256 or header.get("changed_pixels")!=206555 or header.get("union_visited_pixels")!=311432: return {}
	var artifacts: Dictionary=header.get("artifacts",{})
	for key: String in ["projection.bin","geometry.bin","walk_overlay.png","pixel_inverse.bin","finite_proof.bin"]:
		var row: Dictionary=artifacts.get(key,{})
		if b.required_source_sha256.get(row.get("path",""))!=row.get("sha256"): return {}
	if artifacts["walk_overlay.png"].path!=b.mask.path: return {}
	var projection: Variant=bytes_to_var(FileAccess.get_file_as_bytes(artifacts["projection.bin"].path))
	var primitives: Variant=bytes_to_var(FileAccess.get_file_as_bytes(artifacts["geometry.bin"].path))
	if not projection is Dictionary or not primitives is Array or projection.get("native_count")!=29 or projection.get("changed_ids")!=_pure.IDS or projection.get("new_room_count")!=0: return {}
	var original: Dictionary=_pure.restore(projection)
	if original.is_empty() or not bundle.equal(original,city._records.get(String(ID),{})): return {}
	var donors: Dictionary={}
	for key: String in _author.fixed_source_manifests:
		donors[key]=_json(_author.fixed_source_manifests[key].path)
	var repeated: Dictionary=_pure.project(original,_author,donors)
	if repeated.is_empty() or var_to_bytes(repeated)!=var_to_bytes(projection): return {}
	var dg_data:=_json(DG_AUTHOR);var additions: Array=_district_entries(dg_data)
	var extra: Dictionary=_pure.district10(dg_data)
	if additions.size()!=10 or extra.is_empty(): return {}
	var expected_primitives: Array=_pure.native_primitives(projection.child.objects)
	expected_primitives.append_array(extra.primitives)
	if var_to_bytes(expected_primitives)!=var_to_bytes(primitives): return {}
	var native_render: Array=scene.map_layout.visual_objects
	var render_pair: Dictionary=_render_projection(native_render,projection,additions)
	if render_pair.is_empty(): return {}
	var texture:=ResourceLoader.load(b.mask.path) as Texture2D
	var mask: Image=texture.get_image() if texture!=null else null
	if mask==null or mask.get_size()!=Vector2i(3072,2048) or mask.has_mipmaps() or mask.get_format() not in [Image.FORMAT_RGB8,Image.FORMAT_RGBA8]: return {}
	var format_before: int=mask.get_format()
	if format_before==Image.FORMAT_RGB8: mask.convert(Image.FORMAT_RGBA8)
	if _sha(mask.get_data())!=b.mask.RGBA_sha256: return {}
	var solids: Array[PackedVector2Array]=[]
	for row: Dictionary in primitives:
		var shape: PackedVector2Array=_pure.polygon(row.get("points_px"))
		if shape.size()<3 or Geometry2D.triangulate_polygon(shape).is_empty(): return {}
		solids.append(shape)
	for key: int in _states.keys():
		if _states[key].scene.get_ref()==null: _states.erase(key)
	var value: Dictionary={"scene":weakref(scene),"layout":weakref(scene.map_layout),"token":int(proof.token),"sources":sources.duplicate(),"projection":projection,"render_before":render_pair.before,"render_after":render_pair.after,"solids":solids,"mask":mask,"attached":false,"finalized":false,"format_before":format_before,"boundary_integrity_checks":0,"projection_sha":_sha(var_to_bytes(projection)),"before_sha":_sha(var_to_bytes(render_pair.before)),"after_sha":_sha(var_to_bytes(render_pair.after)),"solids_sha":_sha(var_to_bytes(solids))}
	_states[scene.get_instance_id()]=value;return value
static func acquire(scene: SceneScript,field: Node,district: RefCounted,owner: Callable,sources: Dictionary,proof: Dictionary,before: Array) -> Dictionary:
	var value:=ensure(scene)
	if value.is_empty() or value.attached or not is_instance_valid(field) or not field.is_inside_tree() or field.get_script().resource_path!=FIELD_PATH or field.get("_current_scene")!=scene or field.get("_district_session")!=district or not owner.is_valid() or not owner.call() or int(proof.get("token",0))!=value.token or sources!=value.sources: return _fail("DOCKS24E_SOURCE_FIRST_FIELD_OWNER")
	if var_to_bytes(before)!=var_to_bytes(value.render_before): return _fail("DOCKS24E_COMPLETE_ACTUAL_NATIVE29_AND_DG10_RENDER")
	value.field=weakref(field);value.district=weakref(district);value.motion_revision=int(field.get("_city3_motion_revision"));value.attached=true
	return state(scene)
static func render(scene: SceneScript,before: Array) -> Array:
	var value:=_valid(scene)
	if value.is_empty() or not value.attached or var_to_bytes(before)!=var_to_bytes(value.render_before): return []
	return value.render_after.duplicate(true)
static func render_visual(scene: SceneScript,before: Array) -> Array:
	# Existing Field CITY_TASKS producer owns nonblocking evidence visibility.
	# Navigation was separately admitted as all39. Only these three unchanged
	# target IDs are full-row checked here; all non-target task rows pass through.
	var value:=_valid(scene)
	if value.is_empty() or not value.attached: return []
	var result:=before.duplicate(true)
	for id: String in value.projection.changed_ids:
		var current: Dictionary=_pure.find(result,id)
		var parent: Dictionary=_pure.find(value.render_before,id)
		var child: Dictionary=_pure.find(value.render_after,id)
		if current.is_empty() or parent.is_empty() or child.is_empty() or var_to_bytes(current)!=var_to_bytes(parent): return []
		for i: int in range(result.size()):
			if result[i].get("id")==id: result[i]=child.duplicate(true)
	return result
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
	return {"matched":true,"safe":bool(load(C_PATH)._safe_body_cpu(foot,value.mask,value.solids))}
static func validate_cached_boundary(scene: SceneScript,district: RefCounted) -> bool:
	# FINAL and warm resume only; never 875-query/per-frame/file-hash work.
	var value:=_valid(scene)
	if value.is_empty() or not lease_bound(scene,district) or not load(B_PATH).whole_bound(scene): return false
	var mask: Image=value.mask
	if mask==null or mask.get_size()!=Vector2i(3072,2048) or mask.get_format()!=Image.FORMAT_RGBA8 or mask.has_mipmaps() or _sha(mask.get_data())!=_config.mask.RGBA_sha256: return false
	if _sha(var_to_bytes(value.projection))!=value.projection_sha or _sha(var_to_bytes(value.render_before))!=value.before_sha or _sha(var_to_bytes(value.render_after))!=value.after_sha or _sha(var_to_bytes(value.solids))!=value.solids_sha: return false
	value.boundary_integrity_checks=int(value.boundary_integrity_checks)+1;return true
static func finalize(scene: SceneScript,district: RefCounted,sources: Dictionary) -> bool:
	var value:=_valid(scene);var proof:=_proof(scene)
	if value.is_empty() or not lease_bound(scene,district) or proof.get("sources")!=sources or (proof.get("live_scope",false) and proof.get("sources_finalized")!=true) or not validate_cached_boundary(scene,district): return false
	value.finalized=true;return true
static func release(scene: SceneScript,district: RefCounted) -> void:
	if scene==null: return
	var value: Dictionary=_states.get(scene.get_instance_id(),{})
	if not value.is_empty() and value.get("attached",false) and value.district.get_ref()==district: _states.erase(scene.get_instance_id())
static func state(scene: SceneScript) -> Dictionary:
	var value:=_valid(scene)
	return {"ok":true,"token":value.token,"scene_instance":scene.get_instance_id(),"layout_instance":scene.map_layout.get_instance_id(),"attached":value.attached,"finalized":value.finalized,"native_count":29,"render_count":39,"solid_count":value.solids.size(),"mask_path":_config.mask.path,"mask_format_before":value.format_before,"mask_format_after":value.mask.get_format(),"boundary_integrity_checks":value.boundary_integrity_checks} if not value.is_empty() else _fail("DOCKS24E_NO_CURRENT_LEASE")
static func room_return_binding(id: StringName,original: Dictionary) -> Dictionary:
	if id!=ROOM: return original
	if binding().is_empty() or original.get("city_id")!=String(ID) or original.get("building_id")!="north_canal_warehouse" or _pure.v(original.get("return_foot_px"))!=Vector2(754,610): return {}
	var result:=original.duplicate(true);result.return_foot_px=[638.0,610.0];return result
static func portals(scene: SceneScript,original: Array) -> Dictionary:
	if scene==null or scene.scene_id not in [ID,ROOM]: return {"ok":true,"portals":original}
	if binding().is_empty() or (requested(scene) and ensure(scene).is_empty()): return _fail("DOCKS24E_PORTAL_SOURCE_AUTHORITY")
	var result:=original.duplicate(true);var count: int=0
	for portal: Dictionary in result:
		if String(portal.get("target_scene",""))!=String(ROOM if scene.scene_id==ID else ID): continue
		count+=1
		if scene.scene_id==ID:
			if portal.get("pos")!=Vector2(754,610)/SIZE or portal.get("size")!=Vector2(40,32)/SIZE or portal.get("auto_trigger")!=false: return _fail("DOCKS24E_WAREHOUSE_DOOR_IDENTITY")
			var expected:=PackedVector2Array([Vector2(734,594),Vector2(774,594),Vector2(774,626),Vector2(734,626)])
			if portal.get("interaction_polygon_px")!=expected: return _fail("DOCKS24E_WAREHOUSE_ACTIVE_DOOR_POLYGON")
			portal.pos=Vector2(638,610)/SIZE
			portal.interaction_polygon_px=PackedVector2Array([Vector2(618,594),Vector2(658,594),Vector2(658,626),Vector2(618,626)])
		else:
			if portal.get("target_pos")!=Vector2(754,610)/SIZE: return _fail("DOCKS24E_WAREHOUSE_ROOM_RETURN_IDENTITY")
			portal.target_pos=Vector2(638,610)/SIZE
	return {"ok":true,"portals":result} if count==1 else _fail("DOCKS24E_UNIQUE_WAREHOUSE_PORTAL")
