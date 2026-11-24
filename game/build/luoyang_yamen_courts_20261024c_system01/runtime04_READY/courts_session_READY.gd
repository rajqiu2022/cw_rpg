extends RefCounted
## One source-FIRST lease per exact Field/Scene/layout/district owner. No record mutation.
const READY=true
const SELF="res://build/luoyang_yamen_courts_20261024c_system01/runtime04_READY/courts_session_READY.gd"
const BIND="res://build/luoyang_yamen_courts_20261024c_system01/runtime04_READY/binding_READY.json"
const BIND_SHA="60c3a2d949599ca269df1e22dd85d3d620f04e6d1d3ccacb48d27f5373e4676a"
const PURE="res://build/luoyang_yamen_courts_20261024c_system01/retired_order02/courts_projection_CANDIDATE.gd"
const PURE_SHA="2e7799040e0a29abda1f485e901f0b2df0615b58cd7fae4fe1280eedb1f23897"
const AUTHOR="res://build/luoyang_yamen_courts_20261024c_system01/author_courts_NOTREADY.json"
const AUTHOR_SHA="51582b8d281876b08989acef6d16e9216022bad34640cb7bf1c872f0cc2cf429"
const C_PATH="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const FIELD_PATH="res://scripts/field/field_walkable_controller.gd"
const ID=&"ch4_s1_luoyang_yamen"
const SIZE=Vector2(3072,2048)
static var _leases: Dictionary={}
static var _error: String=""
static var _c_handle: Variant=null
static func _c() -> Variant:
	if _c_handle==null: _c_handle=load(C_PATH)
	return _c_handle
static func requested(scene: SceneScript) -> bool: return scene!=null and scene.scene_id==ID
static func _sha(value: Variant) -> bool:
	if not value is String or value.length()!=64: return false
	for character: int in value.to_ascii_buffer():
		if not character in range(48,58) and not character in range(97,103): return false
	return true
static func _json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
static func binding() -> Dictionary:
	if not READY or not _sha(BIND_SHA) or FileAccess.get_sha256(BIND)!=BIND_SHA: return {}
	var b:=_json(BIND)
	if b.get("ready")!=true or b.get("status")!="YAMEN_COURTS_SOURCE_BOUND_OVERLAY_READY" or b.get("scene_id")!=String(ID) or b.get("author_path")!=AUTHOR or b.get("author_sha256")!=AUTHOR_SHA or b.get("pure_path")!=PURE or b.get("pure_sha256")!=PURE_SHA or not b.get("required_source_sha256") is Dictionary: return {}
	var pins: Dictionary=b.required_source_sha256
	if pins.get(AUTHOR)!=AUTHOR_SHA or pins.get(PURE)!=PURE_SHA or pins.has(SELF) or pins.has(BIND): return {}
	if not b.get("mask") is Dictionary or not b.get("local_geometry_proof") is Dictionary or not b.get("local_art") is Dictionary or b.local_art.get("admitted")!=true: return {}
	for row: Dictionary in [b.local_geometry_proof,b.local_art]:
		if not row.get("path") is String or not _sha(row.get("sha256")) or pins.get(row.path)!=row.sha256: return {}
	var mask: Dictionary=b.mask
	for key: String in ["path","import_path","compiled_path"]:
		if not mask.get(key) is String or not pins.has(mask[key]): return {}
	if mask.import_path!=String(mask.path)+".import" or not _sha(mask.get("RGBA_sha256")): return {}
	for path: String in pins:
		if not path.begins_with("res://") or ".." in path or not _sha(pins[path]): return {}
	return b
static func source_paths_for(id: StringName) -> Dictionary:
	if id!=ID: return {}
	var b:=binding()
	if b.is_empty(): return {}
	var paths: Dictionary={SELF:true,BIND:true}
	for path: String in b.required_source_sha256: paths[path]=true
	return paths
static func _proof(scene: SceneScript,token: int) -> Dictionary:
	var c: Variant=_c()
	for proof: Dictionary in [c._transition_validation,c._resident_ready]:
		if proof.get("scene")==scene and proof.get("id")==ID and int(proof.get("token",0))==token: return proof
	return {}
static func _invalidate(key: int,lease: Dictionary,reason: String) -> void:
	# Release image/geometry buffers; retain only a tiny fail-closed tombstone.
	_leases[key]={"scene":lease.scene,"district":lease.district,"token":lease.token,"invalid":true,"reason":reason}
static func _valid(scene: SceneScript) -> Dictionary:
	if not requested(scene) or not _leases.has(scene.get_instance_id()): return {}
	var key: int=scene.get_instance_id();var lease: Dictionary=_leases[key]
	if lease.get("invalid",false): return {}
	var field: Node=lease.field.get_ref();var district: RefCounted=lease.district.get_ref()
	if lease.scene.get_ref()!=scene or scene.map_layout==null or lease.layout.get_ref()!=scene.map_layout or not is_instance_valid(field) or district==null or field.get("_current_scene")!=scene or field.get("_district_session")!=district or int(field.get("_city3_motion_revision"))!=lease.motion_revision or (not field.is_inside_tree() and field.get("_resident_parked")!=true) or _proof(scene,lease.token).is_empty():
		_invalidate(key,lease,"OWNER_SCENE_LAYOUT_OR_TOKEN_CHANGED");return {}
	return lease
static func acquire(scene: SceneScript,field: Node,district: RefCounted,setup_owner: Callable,sources: Dictionary,proof: Dictionary,yamen_state: Dictionary,old_render: Array) -> Dictionary:
	_error=""
	if not requested(scene) or scene.map_layout==null or not is_instance_valid(field) or not field.is_inside_tree() or field.get_script().resource_path!=FIELD_PATH or field.get("_current_scene")!=scene or field.get("_district_session")!=district or district==null or not setup_owner.is_valid() or not setup_owner.call(): return _refuse("YAMEN_COURTS_SETUP_OWNER")
	var token: int=int(proof.get("token",0))
	if token<=0 or proof.get("scene")!=scene or proof.get("id")!=ID or _proof(scene,token).is_empty() or proof.get("sources")!=sources or yamen_state.get("requested")!=true or yamen_state.get("ok")!=true or int(yamen_state.get("token",0))!=token or int(yamen_state.get("scene_instance",0))!=scene.get_instance_id() or int(yamen_state.get("layout_instance",0))!=scene.map_layout.get_instance_id(): return _refuse("YAMEN_COURTS_SOURCE_FIRST_PARENT_TOKEN")
	var b:=binding()
	if b.is_empty() or sources.get(BIND)!=BIND_SHA or not _sha(sources.get(SELF)): return _refuse("YAMEN_COURTS_BINDING_NOT_READY")
	for path: String in b.required_source_sha256:
		if sources.get(path)!=b.required_source_sha256[path]: return _refuse("YAMEN_COURTS_NOT_IN_SOURCE_FIRST:"+path)
	var local_geometry:=_json(b.local_geometry_proof.path)
	if local_geometry.get("status")!="YAMEN_GROUND_OVERLAY_BUILD_NATIVE4_UNCHANGED_RUNTIME_PENDING" or local_geometry.get("author_path")!=AUTHOR or local_geometry.get("author_sha256")!=AUTHOR_SHA or local_geometry.get("full_RGBA_inverse")!=true or local_geometry.get("geometry",{}).get("ok")!=true or local_geometry.get("walk_path")!=b.mask.path or local_geometry.get("walk_RGBA_sha256")!=b.mask.RGBA_sha256: return _refuse("YAMEN_COURTS_PUBLISHED_LOCAL_GEOMETRY_MASK_IDENTITY")
	var author:=_json(AUTHOR)
	if String(yamen_state.get("packet_sha256",""))!=String(author.get("parent_native",{}).get("artifacts",{}).get("packet.bin","")): return _refuse("YAMEN_COURTS_EXACT_NATIVE_PARENT_PACKET")
	for name: String in author.parent_native.artifacts:
		if sources.get(String(author.parent_native.root)+name)!=author.parent_native.artifacts[name]: return _refuse("YAMEN_COURTS_NATIVE_PARENT_NOT_IN_FIRST:"+name)
	var pure: Variant=load(PURE)
	if not pure is GDScript or pure.resource_path!=PURE: return _refuse("YAMEN_COURTS_PURE_HELPER")
	var projection: Dictionary=pure.project_render(author,old_render)
	if projection.get("ok")!=true or var_to_bytes(pure.restore_render(projection))!=var_to_bytes(old_render): return _refuse("YAMEN_COURTS_EXACT_TWO_RENDER_ROWS_AND_INVERSE")
	var mask_texture:=ResourceLoader.load(b.mask.path) as Texture2D
	var mask: Image=mask_texture.get_image() if mask_texture!=null else null
	if mask==null or mask.get_size()!=Vector2i(3072,2048) or mask.has_mipmaps() or mask.get_format() not in [Image.FORMAT_RGB8,Image.FORMAT_RGBA8]: return _refuse("YAMEN_COURTS_IMPORTED_RGB8_OR_RGBA8_MASK")
	var mask_format_before: int=mask.get_format()
	var mask_converted: bool=mask_format_before!=Image.FORMAT_RGBA8
	if mask_converted: mask.convert(Image.FORMAT_RGBA8) # In-memory only; complete expected RGBA hash below remains mandatory.
	var hashing:=HashingContext.new();hashing.start(HashingContext.HASH_SHA256);hashing.update(mask.get_data())
	if hashing.finish().hex_encode()!=b.mask.RGBA_sha256: return _refuse("YAMEN_COURTS_COMPLETE_IMPORTED_RGBA_SHA")
	var solids: Array[PackedVector2Array]=[];var areas: Array[Rect2]=[];var dg: Array[PackedVector2Array]=[]
	for row: Dictionary in projection.geometry.combined:
		var poly: PackedVector2Array=pure.poly(row.points_px)
		if poly.size()<3 or Geometry2D.triangulate_polygon(poly).is_empty(): return _refuse("YAMEN_COURTS_COMPILED_PHYSICAL_POLYGON")
		solids.append(poly)
		var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
		for point: Vector2 in poly: low=low.min(point);high=high.max(point)
		areas.append(Rect2(low,high-low))
		if row.kind=="ADDITIVE_NATIVE_BASE" or row.kind=="SOURCE_PROJECTED_OFFICIAL_BASE": dg.append(poly)
	if solids.size()!=40 or dg.size()!=10 or not setup_owner.call(): return _refuse("YAMEN_COURTS_FINAL_SETUP_OWNER_OR_COUNTS")
	for key: int in _leases.keys():
		if _leases[key].scene.get_ref()==null: _leases.erase(key)
	var key: int=scene.get_instance_id()
	if _leases.has(key): return _refuse("YAMEN_COURTS_DUPLICATE_SCENE_LEASE")
	_leases[key]={"scene":weakref(scene),"layout":weakref(scene.map_layout),"field":weakref(field),"district":weakref(district),"motion_revision":int(field.get("_city3_motion_revision")),"token":token,"mask":mask,"mask_path":b.mask.path,"mask_format_before":mask_format_before,"mask_format_after":mask.get_format(),"mask_converted":mask_converted,"solids":solids,"bounds":areas,"district_solids":dg,"old_rows":projection.old_rows,"new_rows":projection.new_rows,"render_count":old_render.size(),"finalized":false,"source_count":sources.size(),"binding_sha256":BIND_SHA}
	return {"ok":true,"token":token,"scene_instance":key,"mask_path":b.mask.path,"geometry42_to40":true}
static func _refuse(message: String) -> Dictionary:
	_error=message;return {"ok":false,"error":message}
static func apply_cached_render(scene: SceneScript,base: Array) -> Array:
	var lease:=_valid(scene)
	if lease.is_empty() or base.size()!=lease.render_count: return []
	for index: int in range(2):
		var count: int=0
		for ordinal: int in range(base.size()):
			if String(base[ordinal].get("id",""))!=String(lease.old_rows[index].id): continue
			if var_to_bytes(base[ordinal])!=var_to_bytes(lease.old_rows[index]): return []
			base[ordinal]=lease.new_rows[index].duplicate(true);count+=1
		if count!=1: return []
	return base
static func effective_mask(scene: SceneScript) -> Image:
	var lease:=_valid(scene)
	return lease.mask if not lease.is_empty() else null
static func district_solids(scene: SceneScript) -> Array[PackedVector2Array]:
	var lease:=_valid(scene)
	var empty: Array[PackedVector2Array]=[]
	return lease.district_solids if not lease.is_empty() else empty
static func lease_bound(scene: SceneScript,district: RefCounted) -> bool:
	var lease:=_valid(scene)
	return not lease.is_empty() and lease.district.get_ref()==district
static func _cross(a: Vector2,b: Vector2,p: Vector2) -> float: return (float(b.x)-a.x)*(float(p.y)-a.y)-(float(b.y)-a.y)*(float(p.x)-a.x)
static func _on(a: Vector2,b: Vector2,p: Vector2) -> bool: return _cross(a,b,p)==0.0 and p.x>=minf(a.x,b.x) and p.x<=maxf(a.x,b.x) and p.y>=minf(a.y,b.y) and p.y<=maxf(a.y,b.y)
static func _touch(a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> bool: return _cross(a,b,c)*_cross(a,b,d)<0.0 and _cross(c,d,a)*_cross(c,d,b)<0.0 or _on(a,b,c) or _on(a,b,d) or _on(c,d,a) or _on(c,d,b)
static func safe_body_for_receipt(id: StringName,foot: Vector2,proof: Dictionary) -> Dictionary:
	if id!=ID or not proof.get("scene") is SceneScript: return {"matched":false}
	var scene: SceneScript=proof.scene;var key: int=scene.get_instance_id()
	if not _leases.has(key): return {"matched":false}
	var cached: Dictionary=_leases[key]
	if cached.scene.get_ref()!=scene: return {"matched":false}
	if int(proof.get("token",0))!=int(cached.token): return {"matched":true,"safe":false}
	var lease:=_valid(scene)
	if lease.is_empty() or not foot.is_finite(): return {"matched":true,"safe":false}
	var area:=Rect2(foot-Vector2(17,12),Vector2(34,24));var mask: Image=lease.mask
	if area.position.x<0 or area.position.y<0 or roundi(area.end.x)>=3072 or roundi(area.end.y)>=2048: return {"matched":true,"safe":false}
	for y: int in range(roundi(area.position.y),roundi(area.end.y)+1):
		for x: int in range(roundi(area.position.x),roundi(area.end.x)+1):
			var color:=mask.get_pixel(x,y)
			if color.a<.5 or color.r<.5: return {"matched":true,"safe":false}
	var body:=PackedVector2Array([area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)])
	for index: int in range(lease.solids.size()):
		if not area.intersects(lease.bounds[index],true): continue
		var shape: PackedVector2Array=lease.solids[index]
		if not Geometry2D.intersect_polygons(body,shape).is_empty(): return {"matched":true,"safe":false}
		for point: Vector2 in body:
			if Geometry2D.is_point_in_polygon(point,shape): return {"matched":true,"safe":false}
		for point: Vector2 in shape:
			if point.x>=area.position.x and point.x<=area.end.x and point.y>=area.position.y and point.y<=area.end.y: return {"matched":true,"safe":false}
		for i: int in range(body.size()):
			for j: int in range(shape.size()):
				if _touch(body[i],body[(i+1)%body.size()],shape[j],shape[(j+1)%shape.size()]): return {"matched":true,"safe":false}
	return {"matched":true,"safe":true}
static func finalize(scene: SceneScript,district: RefCounted,sources: Dictionary) -> bool:
	var lease:=_valid(scene)
	if lease.is_empty() or lease.district.get_ref()!=district: return false
	var proof:=_proof(scene,lease.token)
	if proof.is_empty() or proof.get("sources")!=sources or proof.get("live_scope",false) and proof.get("sources_finalized")!=true: return false
	lease.finalized=true;return true
static func release(scene: SceneScript,district: RefCounted) -> void:
	if scene==null: return
	var key: int=scene.get_instance_id()
	if _leases.has(key) and not _leases[key].get("invalid",false) and _leases[key].district.get_ref()==district: _leases.erase(key)
	elif _leases.has(key) and _leases[key].get("invalid",false) and _leases[key].district.get_ref()==district: _leases.erase(key)
static func state(scene: SceneScript) -> Dictionary:
	var lease:=_valid(scene)
	return {"ok":true,"scene_instance":scene.get_instance_id(),"layout_instance":scene.map_layout.get_instance_id(),"token":lease.token,"finalized":lease.finalized,"source_count":lease.source_count,"solid_count":40,"district_solid_count":10,"mask_path":lease.mask_path,"mask_instance":lease.mask.get_instance_id(),"mask_format_before":lease.mask_format_before,"mask_format_after":lease.mask_format_after,"mask_converted":lease.mask_converted,"one_time_geometry_and_RGBA_validation":true} if not lease.is_empty() else {"ok":false,"error":_error}
