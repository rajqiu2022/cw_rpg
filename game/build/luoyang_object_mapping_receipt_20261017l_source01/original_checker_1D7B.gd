extends RefCounted
const CPU_WORKSPACE = preload("res://scripts/city/luoyang_base_cold_cpu_workspace_20261013.gd")
## NEW independent stored-resource oracle. Read-only; never executes a builder,
## material adapter or capture. Recipe controls below are project specifications,
## not metadata-derived geometry. PENDING pins refuse every candidate.
const OLD_ROOT := "res://art/maps/luoyang_modular_v3_street_detail_proposal/root_material_v1/"
const NEW_ROOT := "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/"
const OLD_MANIFEST_SHAS := {
	"ch4_s0_luoyang_gate":"54e963a515bdc057a85491e082cbf705e48c9c68e718e896fe2dac01375ca704",
	"ch4_s1_luoyang_yamen":"c50902972d08575f1aafd2e08644467981bb55de97392cf70234ef3c77c4fe49",
	"ch4_s2_canal_docks":"f6fae4d241fa076a1ee30ff53618007d260be6d1941a3bb75d5ed8485a424cc9",
	"ch4_s3_luoyang_market":"183f19e16d22ad451e44293682e66f8250f4215fdae2031f7170f9d0fff998ac"}
const GEOMETRY_ID := "PROJECT_CITY_SAME_FOOT_VERTICAL_BATTERED_SHOULDER_ZONE_FINISH_V5_CANDIDATE"
const PARENT_GEOMETRY_ID := "PROJECT_CITY_RETAINED_FOOT_FINER_UPPER_MASONRY_CURVED_TILE_V1"
const V4_ROOT := "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v4/"
const V4_MANIFEST_SHAS := {
	"ch4_s0_luoyang_gate":"eee86daaf99af0c79841d40e542094e8a97ea8d99b347f22f263f77edd65be30",
	"ch4_s1_luoyang_yamen":"160fdba2690f3954e420abdb15b5ba0ff995e0d19a53e684bb5b479edc1ff34b",
	"ch4_s2_canal_docks":"01048fbd06f2a6aaddf1b06834cb1f2bea13558a7f171c2e3805f83366aaf029",
	"ch4_s3_luoyang_market":"97552eb72af1c7d8524fbcd93ee84406f990e32724f0725f3027170b58ea5345"}
const MATERIAL_ID := "PROJECT_SOFT_AVENUE_APRON_COURT_QUAY_FINISH_CANDIDATE_V1"
const EXECUTOR := "res://scripts/dev/build_luoyang_modular_v3_wall_v5_capture_candidate.gd"
const SURFACE := "res://scripts/dev/luoyang_modular_v3_zone_finish_candidate.gd"
const ADAPTER := "res://scripts/dev/build_luoyang_modular_v3_wall_v5_adapter_candidate.gd"
const PINS := {
	EXECUTOR:"0aac9b827b72d8cedf1ab94808fba8d2a84b43c2d0efd503400170326a28c423",
	SURFACE:"26299495f76c3236d622f899efedf6fe27605b8e6783ea9c345f61030820b5be",
	ADAPTER:"6400245fb519d8df8ebf4eb55d1fe8aac4d523acd2a8673ebe2dfd317f643b06",
	"res://scripts/dev/build_luoyang_modular_v3_wall_street_capture_proposal.gd":"8282794a079f9118c6a4e5fbba482d682b092676882a74df6972ce6bfa64b771",
	"res://scripts/dev/luoyang_modular_v3_wall_street_surface_proposal.gd":"7ccbb9f4a27234de3da4d41076e5374d7702d276a01c13e968c5790f537153eb",
	"res://scripts/dev/build_luoyang_modular_v3_wall_street_adapter_proposal.gd":"531bfcee9eababe944fd366904355fab57a74b47104eaba2598c6224f3d69f2c"}
const OLD_STREET_SURFACE := "res://scripts/dev/luoyang_modular_v3_street_detail_surface_proposal.gd"
const OLD_STREET_SURFACE_SHA := "5f6a3f901645bdaed5e8a544c617375e2e2e02f5f2730b42d43895cf129c4dfa"
const RETAINED := [0,1,2,3,4,5,6,7,41,43,45,47,49,51]
const TEXTURES := {
	"original_stone":"res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png",
	"registered_normal":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_nor_gl_2k.jpg",
	"registered_arm":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_arm_2k.jpg"}
const ALPHA_ID := "RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1"
const ALPHA_EPSILON := .00001
const TEXTURE_SHAS := {
	"res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png":"7e9c7d892f86ced04ad3b8ad293208e05d87a01afffc2729804e4469f87deb7d",
	"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_diff_2k.jpg":"fe9013368539b5604602e64bfa48bef1a2a4c452fcb6894868fb556d0b14501c",
	"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_nor_gl_2k.jpg":"70427a2c81f85c0e1ee4a147e273d028c3d0188bad2583f2509d6df9a3d55b89",
	"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_arm_2k.jpg":"a954de58336738e6f963466f1453202ef7e186bd6492106c3b989c39f0d2e23c"}

static func validate(record: Dictionary,catalog: Dictionary,id: StringName,cpu_context: RefCounted=null) -> String:
	var state: Dictionary={"record":record,"catalog":catalog,"id":id,"cpu_context":cpu_context}
	var error: String=_validation_begin(state)
	if error!="": return error
	for file: String in state.geometry_files:
		error=_validation_geometry(state,file)
		if error!="": return error
	error=_ground_repeat_error(state.prefix,catalog,cpu_context)
	if error!="": return error
	error=_paving_error(record,catalog,state.prefix,state.old_prefix)
	if error!="": return error
	error=_validation_objects_begin(state)
	if error!="": return error
	for item: Variant in state.objects:
		error=_validation_object(state,item)
		if error!="": return error
		if state.object_skip: continue
		if state.object_wall:
			error=_wall_error(state.object_metadata,state.object_old_metadata,catalog,state.object_stem,state.object_old_stem,String(id),cpu_context)
		else:
			error=_validation_unaffected(state)
		if error!="": return error
	return ""

static func validate_live(record: Dictionary,catalog: Dictionary,id: StringName,token: int,cpu_context: RefCounted,owner_check: Callable) -> String:
	if not _owner_valid(owner_check): return "LIVE_OWNER_CANCELLED"
	var state: Dictionary={"record":record,"catalog":catalog,"id":id,"cpu_context":cpu_context}
	var started: int
	var error: String
	started=Time.get_ticks_usec(); error=_validation_begin(state)
	_observe(cpu_context,id,"capture.source",started)
	if not _owner_valid(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
	if error!="": state.clear(); return error
	for file: String in state.geometry_files:
		if not await yield_owner(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
		started=Time.get_ticks_usec(); error=_validation_geometry(state,file)
		_observe(cpu_context,id,"capture.mesh",started)
		if not _owner_valid(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
		if error!="": state.clear(); return error
	if not await yield_owner(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
	started=Time.get_ticks_usec(); error=_ground_repeat_error(state.prefix,catalog,cpu_context)
	_observe(cpu_context,id,"capture.ground_pixels",started)
	if not _owner_valid(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
	if error!="": state.clear(); return error
	if not await yield_owner(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
	started=Time.get_ticks_usec(); error=_paving_error(record,catalog,state.prefix,state.old_prefix)
	_observe(cpu_context,id,"capture.paving",started)
	if not _owner_valid(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
	if error!="": state.clear(); return error
	error=_validation_objects_begin(state)
	if error!="": state.clear(); return error
	for item: Variant in state.objects:
		if not await yield_owner(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
		started=Time.get_ticks_usec(); error=_validation_object(state,item)
		_observe(cpu_context,id,"capture.object_mapping",started)
		if not _owner_valid(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
		if error!="": state.clear(); return error
		if state.object_skip: continue
		if state.object_wall:
			error=await _wall_error_live(state.object_metadata,state.object_old_metadata,catalog,state.object_stem,state.object_old_stem,String(id),cpu_context,owner_check)
		else:
			error=await _validation_unaffected_live(state,cpu_context,id,owner_check)
		if not _owner_valid(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
		if error!="": state.clear(); return error
	state.clear()
	return ""

static func _owner_valid(owner_check: Callable) -> bool:
	if not owner_check.is_valid(): return false
	var value: Variant=owner_check.call()
	return typeof(value)==TYPE_BOOL and value==true

static func yield_owner(owner_check: Callable) -> bool:
	if not _owner_valid(owner_check): return false
	await (Engine.get_main_loop() as SceneTree).process_frame
	return _owner_valid(owner_check)

static func _observe(cpu_context: RefCounted,id: StringName,label: String,started: int) -> void:
	if cpu_context!=null: cpu_context.record_main_stage(id,label,Time.get_ticks_usec()-started)

static func _validation_begin(state: Dictionary) -> String:
	var record: Dictionary=state.record
	var catalog: Dictionary=state.catalog
	var id: StringName=state.id
	var cpu_context: RefCounted=state.cpu_context
	var region: String=String(id)
	if cpu_context != null and (cpu_context.get_script() != CPU_WORKSPACE or not cpu_context.matches_input(id,NEW_ROOT+region+"/",record,catalog)): return "Unbound/cancelled BASE CPU workspace"
	if not OLD_MANIFEST_SHAS.has(region): return "Unknown new wall/street city region"
	for path: String in PINS:
		if not _hash(PINS[path]) or FileAccess.get_sha256(path).to_lower()!=PINS[path]: return "New wall/street executed source PENDING/missing/changed: "+path
	var old_prefix: String=OLD_ROOT+region+"/"
	var prefix: String=NEW_ROOT+region+"/"
	var old_path: String=old_prefix+"art_contract.json"
	if FileAccess.get_sha256(old_path).to_lower()!=OLD_MANIFEST_SHAS[region]: return "Frozen current street-detail baseline manifest changed"
	var old_value: Variant=JSON.parse_string(FileAccess.get_file_as_string(old_path))
	if not old_value is Dictionary or not old_value.get("asset_sha256") is Dictionary: return "Frozen street-detail baseline malformed"
	var old: Dictionary=old_value
	for path: Variant in old.asset_sha256:
		if not path is String or not _hash(old.asset_sha256[path]) or (FileAccess.get_sha256(path) if cpu_context == null else cpu_context.source_sha(id,path)).to_lower()!=String(old.asset_sha256[path]).to_lower(): return "Frozen street-detail catalog changed: "+str(path)
	for path: Variant in catalog:
		if not path is String or not String(path).begins_with("res://") or ".." in String(path) or not _hash(catalog[path]) or (FileAccess.get_sha256(path) if cpu_context == null else cpu_context.source_sha(id,path)).to_lower()!=String(catalog[path]).to_lower(): return "New wall/street catalog missing/changed: "+str(path)
	var revision: Variant=record.get("upper_wall_street_revision")
	if record.get("scope")!="ISOLATED_V5_VERTICAL_UPPER_AND_ZONE_SAMPLE_NOT_FIELD_OR_FORMAL_APPROVED" or not revision is Dictionary or revision.get("identity")!=GEOMETRY_ID or revision.get("scope")!="NEW_UPPER_GEOMETRY_AND_ALPHA_NOT_MATERIAL_ONLY" or revision.get("production_approved")!=false or revision.get("baseline_manifest_path")!=old_path or String(revision.get("baseline_manifest_sha256","")).to_lower()!=OLD_MANIFEST_SHAS[region]: return "Missing honest changed-upper-geometry baseline/scope"
	var v4_error: String=_v5_manifest_error(record,catalog,region,cpu_context)
	if v4_error!="": return v4_error
	var graph: Variant=record.get("capture_graph")
	if not graph is Dictionary: return "New wall/street actual capture graph absent"
	for pair: Array in [["builder_script",EXECUTOR],["surface_script",SURFACE],["material_adapter_script",ADAPTER]]:
		var node: Variant=graph.get(pair[0])
		if not node is Dictionary or node.get("path")!=pair[1] or String(node.get("sha256","")).to_lower()!=PINS[pair[1]] or not catalog.has(pair[1]) or String(catalog[pair[1]]).to_lower()!=PINS[pair[1]]: return "New exact source graph mismatch: "+str(pair[0])
	var surface_binding: Variant=record.get("capture_surface_binding")
	if not surface_binding is Dictionary or surface_binding.get("path")!=SURFACE or String(surface_binding.get("sha256","")).to_lower()!=PINS[SURFACE] or surface_binding.get("actual_instance_equals_prepared_adapter_surface")!=true: return "Actual new surface instance not bound"
	for key: String in ["canonical_scene_id","logical_size_px","pixel_sampling","physical_navigation_margin_px","ordinary_actor_body_px","ordinary_actor_visual_scale","entry_foot_px","return_foot_px","gameplay_slots","routes","npc_stations","interaction_anchors","height_grid","capture_camera","authority_camera"]:
		if not _equal(old.get(key),record.get(key)): return "Upper-wall proposal changed protected city semantics/camera: "+key
	for file: String in ["land.png","raw_walk.png","walk.png","terrain_height.rf","capture_camera.json","authority_camera.json"]:
		if not _catalog_file(catalog,prefix+file) or FileAccess.get_sha256(old_prefix+file)=="" or FileAccess.get_sha256(old_prefix+file)!=FileAccess.get_sha256(prefix+file): return "Upper-wall proposal changed protected authority/camera bytes: "+file
	var geometry_files: Array[String]=["paving_mesh.res","support_plane.res"]
	if region=="ch4_s2_canal_docks": geometry_files.append_array(["canal_bed_mesh.res","water_plane.res","quay_wall_mesh.res"])
	state.old=old; state.prefix=prefix; state.old_prefix=old_prefix; state.geometry_files=geometry_files
	return ""

static func _validation_geometry(state: Dictionary,file: String) -> String:
	var catalog: Dictionary=state.catalog
	var prefix: String=state.prefix
	var old_prefix: String=state.old_prefix
	if not _catalog_file(catalog,prefix+file): return "Actual protected ground mesh not in current catalog: "+file
	var error: String=_meshes_error(old_prefix+file,prefix+file,file)
	if error!="": return error
	return ""

static func _validation_objects_begin(state: Dictionary) -> String:
	var record: Dictionary=state.record
	var catalog: Dictionary=state.catalog
	var id: StringName=state.id
	var cpu_context: RefCounted=state.cpu_context
	var region: String=String(id)
	var old: Dictionary=state.old
	var before_objects: Variant=old.get("objects")
	var objects: Variant=record.get("objects")
	if not before_objects is Array or not objects is Array or before_objects.size()!=objects.size(): return "Upper-wall proposal changed full object set"
	var previous: Dictionary={}
	for item: Variant in before_objects:
		if not item is Dictionary or previous.has(item.get("id")): return "Malformed frozen baseline object IDs"
		previous[item.id]=item
	var seen: Dictionary={}
	var prototypes: Dictionary={}
	state.objects=objects; state.previous=previous; state.seen=seen; state.prototypes=prototypes
	return ""

static func _validation_object(state: Dictionary,item: Variant) -> String:
	var record: Dictionary=state.record
	var catalog: Dictionary=state.catalog
	var id: StringName=state.id
	var cpu_context: RefCounted=state.cpu_context
	var region: String=String(id)
	var prefix: String=state.prefix
	var old_prefix: String=state.old_prefix
	var previous: Dictionary=state.previous
	var seen: Dictionary=state.seen
	var prototypes: Dictionary=state.prototypes
	state.object_skip=false
	if not item is Dictionary or not previous.has(item.get("id")) or seen.has(item.get("id")): return "Upper-wall proposal changed object identity"
	seen[item.id]=true
	var before: Dictionary=previous[item.id]
	for key: String in ["id","prototype","world_foot_px","depth_foot_y","physical_center_px","collision_size_px","solid_polygons_px","blocking","z_index","sort_by_feet","ghost_occlusion","walk_support","role"]:
		if not _equal(before.get(key),item.get(key)): return "Upper-wall proposal changed physical/feet identity: "+str(item.id)+"/"+key
	var kind: String=String(item.get("prototype",""))
	var wall: bool=kind in ["wall_horizontal","wall_vertical"]
	if not wall:
		for key: String in ["render_size_px","foot_uv","source_size_px"]:
			if not _equal(before.get(key),item.get(key)): return "Unaffected object draw mapping changed: "+str(item.id)+"/"+key
		if FileAccess.get_sha256(String(before.get("texture","")))=="" or FileAccess.get_sha256(String(before.texture))!=FileAccess.get_sha256(String(item.get("texture",""))): return "Unaffected source/body PNG changed: "+str(item.id)
	if kind=="": state.object_skip=true; return ""
	var stem: String=prefix+"entities/native_"+kind
	var old_stem: String=old_prefix+"entities/native_"+kind
	var metadata_value: Variant=JSON.parse_string(FileAccess.get_file_as_string(stem+".json"))
	var old_metadata: Variant=JSON.parse_string(FileAccess.get_file_as_string(old_stem+".json"))
	if not metadata_value is Dictionary or not old_metadata is Dictionary: return "Actual native prototype metadata missing: "+kind
	var metadata: Dictionary=metadata_value
	for key: String in ["render_size_px","foot_uv","source_size_px"]:
		if not _equal(item.get(key),metadata.get(key)): return "Instance differs from current actual prototype mapping: "+str(item.id)+"/"+key
	if String(item.get("texture",""))!=stem+".png": return "Native instance texture not exact current prototype: "+str(item.id)
	var transform_error: String=_caster_error(item,metadata)
	if transform_error!="": return transform_error
	if prototypes.has(kind): state.object_skip=true; return ""
	prototypes[kind]=true
	for suffix: String in [".res",".json",".png","_raw.png","_raw_repeat.png"]:
		if not _catalog_file(catalog,stem+suffix): return "Incomplete actual native catalog: "+kind+suffix
	state.object_wall=wall; state.object_metadata=metadata; state.object_old_metadata=old_metadata; state.object_stem=stem; state.object_old_stem=old_stem; state.object_kind=kind
	return ""

static func _validation_unaffected(state: Dictionary) -> String:
	var local: Dictionary=_unaffected_state(state)
	var error: String=_unaffected_mesh(local)
	if error!="": local.clear(); return error
	error=_unaffected_mapping_bytes(local)
	if error!="": local.clear(); return error
	_unaffected_load(local)
	var a: Mesh=local.mesh_a
	for index in range(a.get_surface_count()):
		error=_unaffected_material(local,index)
		if error!="": local.clear(); return error
	local.clear()
	return ""

static func _validation_unaffected_live(state: Dictionary,cpu_context: RefCounted,id: StringName,owner_check: Callable) -> String:
	# Mapping has finished; yield before any native prototype work.
	var local: Dictionary=_unaffected_state(state)
	var label: String="capture.prototype/"+local.kind
	if not await yield_owner(owner_check): local.clear(); return "LIVE_OWNER_CANCELLED"
	var started: int=Time.get_ticks_usec()
	var error: String=_unaffected_mesh(local)
	_observe(cpu_context,id,label+".mesh",started)
	if not _owner_valid(owner_check): local.clear(); return "LIVE_OWNER_CANCELLED"
	if error!="": local.clear(); return error
	if not await yield_owner(owner_check): local.clear(); return "LIVE_OWNER_CANCELLED"
	started=Time.get_ticks_usec(); error=_unaffected_mapping_bytes(local)
	_observe(cpu_context,id,label+".mapping_bytes",started)
	if not _owner_valid(owner_check): local.clear(); return "LIVE_OWNER_CANCELLED"
	if error!="": local.clear(); return error
	if not await yield_owner(owner_check): local.clear(); return "LIVE_OWNER_CANCELLED"
	started=Time.get_ticks_usec(); _unaffected_load(local)
	_observe(cpu_context,id,label+".load",started)
	if not _owner_valid(owner_check): local.clear(); return "LIVE_OWNER_CANCELLED"
	var surface_count: int=local.mesh_a.get_surface_count()
	for index in range(surface_count):
		if not await yield_owner(owner_check): local.clear(); return "LIVE_OWNER_CANCELLED"
		started=Time.get_ticks_usec(); error=_unaffected_material(local,index)
		_observe(cpu_context,id,label+".material",started)
		if not _owner_valid(owner_check): local.clear(); return "LIVE_OWNER_CANCELLED"
		if error!="": local.clear(); return error
	local.clear()
	return ""

static func _unaffected_state(state: Dictionary) -> Dictionary:
	return {"old_stem":state.object_old_stem,"stem":state.object_stem,"kind":state.object_kind,"metadata":state.object_metadata,"old_metadata":state.object_old_metadata}

static func _unaffected_mesh(state: Dictionary) -> String:
	var old_stem: String=state.old_stem
	var stem: String=state.stem
	var kind: String=state.kind
	var error: String=_meshes_error(old_stem+".res",stem+".res",kind)
	if error!="": return error
	return ""

static func _unaffected_mapping_bytes(state: Dictionary) -> String:
	var old_stem: String=state.old_stem
	var stem: String=state.stem
	var kind: String=state.kind
	var metadata: Dictionary=state.metadata
	var old_metadata: Variant=state.old_metadata
	for key: String in ["kind","support_m","draw_basis_columns","used_bounds_m","actual_used_vertices","scale","source_min_vertex_ground_delta_m","crop_rect_px","source_size_px","render_size_px","foot_uv","raw_camera","alpha_resampling_algorithm"]:
		if not _equal(old_metadata.get(key),metadata.get(key)): return "Unaffected native geometry/body mapping changed: "+kind+"/"+key
	for suffix: String in [".png","_raw.png","_raw_repeat.png"]:
		if FileAccess.get_sha256(old_stem+suffix)!=FileAccess.get_sha256(stem+suffix): return "Unaffected native rendered bytes changed: "+kind+suffix
	return ""

static func _unaffected_load(state: Dictionary) -> void:
	# Retain the original second CACHE_MODE_IGNORE load, after the byte gates.
	var old_stem: String=state.old_stem
	var stem: String=state.stem
	var a: Mesh=ResourceLoader.load(old_stem+".res","",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	var b: Mesh=ResourceLoader.load(stem+".res","",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	state.mesh_a=a; state.mesh_b=b

static func _unaffected_material(state: Dictionary,index: int) -> String:
	var a: Mesh=state.mesh_a
	var b: Mesh=state.mesh_b
	var kind: String=state.kind
	var problem: String=_material_equal_error(a.surface_get_material(index),b.surface_get_material(index))
	if problem!="": return "Unaffected native actual material changed: "+kind+"/"+problem
	return ""

static func _wall_error(metadata: Dictionary,old_metadata: Dictionary,catalog: Dictionary,stem: String,old_stem: String,region: String,cpu_context: RefCounted=null) -> String:
	var state: Dictionary={"metadata":metadata,"old_metadata":old_metadata,"catalog":catalog,"stem":stem,"old_stem":old_stem,"region":region,"cpu_context":cpu_context}
	var error: String=_wall_geometry(state)
	if error!="": state.clear(); return error
	for index in range(18):
		error=_wall_material(state,index)
		if error!="": state.clear(); return error
	error=_body_error(metadata,catalog,stem,cpu_context)
	state.clear()
	return error

static func _wall_error_live(metadata: Dictionary,old_metadata: Dictionary,catalog: Dictionary,stem: String,old_stem: String,region: String,cpu_context: RefCounted,owner_check: Callable) -> String:
	var state: Dictionary={"metadata":metadata,"old_metadata":old_metadata,"catalog":catalog,"stem":stem,"old_stem":old_stem,"region":region,"cpu_context":cpu_context}
	if not await yield_owner(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
	var started: int=Time.get_ticks_usec()
	var error: String=_wall_geometry(state)
	_observe(cpu_context,StringName(region),"wall.geometry",started)
	if not _owner_valid(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
	if error!="": state.clear(); return error
	for index in range(18):
		if not await yield_owner(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
		started=Time.get_ticks_usec(); error=_wall_material(state,index)
		_observe(cpu_context,StringName(region),"wall.material",started)
		if not _owner_valid(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
		if error!="": state.clear(); return error
	if not await yield_owner(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
	started=Time.get_ticks_usec(); error=_body_error(metadata,catalog,stem,cpu_context)
	_observe(cpu_context,StringName(region),"wall.body_camera",started)
	if not _owner_valid(owner_check): state.clear(); return "LIVE_OWNER_CANCELLED"
	state.clear()
	return error

static func _wall_geometry(state: Dictionary) -> String:
	var metadata: Dictionary=state.metadata
	var old_metadata: Dictionary=state.old_metadata
	var catalog: Dictionary=state.catalog
	var stem: String=state.stem
	var old_stem: String=state.old_stem
	var region: String=state.region
	var cpu_context: RefCounted=state.cpu_context
	var kind: String=String(metadata.get("kind",""))
	var horizontal: bool=kind=="wall_horizontal"
	if kind not in ["wall_horizontal","wall_vertical"]: return "Unknown upper-wall geometry role"
	var a: ArrayMesh=ResourceLoader.load(old_stem+".res","",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var b: ArrayMesh=ResourceLoader.load(stem+".res","",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if a==null or b==null or a.get_surface_count()!=54 or b.get_surface_count()!=18: return "Actual upper-wall surface set is not old54/new18"
	var revision: Variant=metadata.get("upper_wall_geometry_revision")
	if not revision is Dictionary or revision.get("algorithm_identity")!=(PARENT_GEOMETRY_ID if horizontal else GEOMETRY_ID) or revision.get("identity")!=GEOMETRY_ID or revision.get("not_material_only")!=true or revision.get("scope")!="NEW_UPPER_GEOMETRY_AND_ALPHA; NOT_MATERIAL_ONLY; unchanged foot/support/physical layout/navigation.": return "Actual new wall geometry identity missing"
	if revision.get("original_mesh_path")!=old_stem+".res" or revision.get("original_mesh_sha256")!=FileAccess.get_sha256(old_stem+".res"): return "New wall baseline original saved mesh unbound"
	if revision.get("actual_mesh_path")!=stem+".res" or revision.get("actual_mesh_sha256")!=catalog[stem+".res"] or metadata.get("geometry_change_scope")!="NEW_UPPER_WALL_GEOMETRY_AND_ALPHA_NOT_MATERIAL_ONLY": return "Actual revised wall is not bound to its current stored geometry"
	if not _json_exact(revision.get("old_surface_count"),54) or not _json_exact(revision.get("new_surface_count"),18) or not _json_exact(revision.get("new_surface_range"),[14,17]): return "Upper-wall declared surface partition differs"
	var recipe_value: Variant=revision.get("new_surface_recipe")
	if not recipe_value is Dictionary or not recipe_value.get("upper_bricks") is Dictionary: return "Actual merged-brick recipe absent"
	var bricks: Dictionary=recipe_value.upper_bricks
	var expected_brick_recipe: Dictionary={"first_surface":14,"rows":12,"columns":20,"merged_source_brick_surface_count":240}
	for key: String in expected_brick_recipe:
		if not _num(bricks.get(key),float(expected_brick_recipe[key])): return "Actual complete merged-brick recipe identity differs: "+key
	if bricks.get("merged_surface")!=true: return "Actual upper brick surface is not the complete merged native geometry"
	for pair: Array in [["cornice",15],["curved_tiles",16],["ridge",17]]:
		var part: Variant=recipe_value.get(pair[0])
		if not part is Dictionary or not _num(part.get("surface_index"),float(pair[1])): return "Actual upper surface recipe mapping differs"
	var roof_recipe: Dictionary=recipe_value.curved_tiles
	var expected_roof: Dictionary={"column_count":32,"course_count_per_wing":2,"wings":2,"along_sections":4,"column_pitch_m":.15625,"column_gap_m":.018,"course_gap_fraction":.012}
	for key: String in expected_roof:
		if not _num(roof_recipe.get(key),float(expected_roof[key])): return "Actual revised curved-tile recipe differs: "+key
	if roof_recipe.get("peak_formula")!="y=1.94-.21*abs(across)/half+.035*sin(PI*t)*(1-abs(across)/half*.35)": return "Actual revised curved-tile mathematical identity differs"
	var mapping: Variant=revision.get("retained_surface_map")
	if not mapping is Array or mapping.size()!=RETAINED.size(): return "Retained support surface map incomplete"
	var removed: Array[int]=[]
	for index in range(54):
		if not index in RETAINED: removed.append(index)
	if not _json_exact(revision.get("replaced_original_surface_indices"),removed): return "Unexpected removed upper-wall original surfaces"
	for index in range(RETAINED.size()):
		var old_index: int=RETAINED[index]
		var row: Variant=mapping[index]
		if not row is Dictionary or not _num(row.get("old_index"),old_index) or not _num(row.get("new_index"),index) or not _num(row.get("primitive"),a.surface_get_primitive_type(old_index)): return "Retained surface identity differs"
		var error: String=_surface_error(a,old_index,b,index,"retained")
		if error!="": return error
		var slots: Variant=row.get("slots")
		if not slots is Array or slots.size()!=Mesh.ARRAY_MAX: return "Retained surface full slot evidence incomplete"
		var actual: Array=b.surface_get_arrays(index)
		for slot in range(Mesh.ARRAY_MAX):
			var entry: Variant=slots[slot]
			var sha: String=_sha(var_to_bytes(actual[slot]))
			if not entry is Dictionary or not _num(entry.get("slot"),slot) or entry.get("old_sha256")!=sha or entry.get("new_sha256")!=sha or entry.get("byte_exact")!=true: return "Retained support slot record differs from actual bytes"
	var current_error: String=_v5_current_wall_error(revision,catalog,stem,region,horizontal,b)
	if current_error!="": return current_error
	var control: ArrayMesh=_upper_control(horizontal)
	if control==null or control.get_surface_count()!=4: return "Independent upper-wall mathematical control failed"
	for index in range(control.get_surface_count()):
		var error: String=_surface_error(control,index,b,index+14,"independent finer-brick/cornice/curved-tile/ridge")
		if error!="": return error
	var curved: Dictionary=_curved_geometry_evidence(b,16)
	if curved.is_empty() or curved.triangle_count!=1024 or curved.clockwise_up_faces!=1024 or curved.degenerate_faces!=0 or curved.actual_normal_y_min<=0.0 or not _json_exact(revision.get("actual_curved_roof_winding_normal_evidence"),curved): return "Actual curved tile winding/normals differ from independent stored triangles"
	for flag: String in ["actual_saved_arrays_byte_exact_to_captured_mesh","actual_saved_materials_exact_to_captured_mesh","actual_support_vector_count_minY_byte_exact"]:
		if revision.get(flag)!=true: return "Actual wall capture/stored/support evidence incomplete: "+flag
	var all_slots: Variant=revision.get("actual_all_surface_slots")
	if not all_slots is Array or all_slots.size()!=18: return "Complete actual new-wall array evidence missing"
	for index in range(18):
		var row: Variant=all_slots[index]
		if not row is Dictionary or not _num(row.get("surface_index"),index) or not _num(row.get("primitive"),b.surface_get_primitive_type(index)) or not row.get("slots") is Array or row.slots.size()!=Mesh.ARRAY_MAX: return "Actual new-wall surface primitive/slots evidence malformed"
		var arrays: Array=b.surface_get_arrays(index)
		for slot in range(Mesh.ARRAY_MAX):
			var entry: Variant=row.slots[slot]
			if not entry is Dictionary or not _num(entry.get("slot"),slot) or not _num(entry.get("variant_type"),typeof(arrays[slot])) or entry.get("sha256")!=_sha(var_to_bytes(arrays[slot])): return "Actual new-wall slot metadata disagrees with stored .res"
	var old_bounds: Dictionary=_used_bounds(a)
	var bounds: Dictionary=_used_bounds(b)
	if old_bounds.is_empty() or bounds.is_empty(): return "Invalid actual used-index bounds"
	for key: String in ["support","support_count"]:
		if var_to_bytes(old_bounds[key])!=var_to_bytes(bounds[key]): return "New full-mesh minimum2% changed actual original support: "+key
	if old_bounds.minimum.y!=bounds.minimum.y: return "New upper wall changed lowest actual vertex"
	for pair: Array in [["support_old",old_bounds],["support_new",bounds]]:
		var measured: Dictionary=pair[1]
		var expected: Dictionary={"valid":true,"minimum_m":_v3(measured.minimum),"maximum_m":_v3(measured.maximum),"support_m":_v3(measured.support),"support_count":measured.support_count,"actual_used_vertices":measured.actual_used_vertices}
		if not _json_exact(revision.get(pair[0]),expected): return "Actual old/new complete used-index support evidence differs"
	if not _json_exact(metadata.get("support_m"),_v3(bounds.support)) or not _json_exact(metadata.get("used_bounds_m"),{"minimum":_v3(bounds.minimum),"maximum":_v3(bounds.maximum)}) or not _json_exact(metadata.get("actual_used_vertices"),bounds.actual_used_vertices): return "Current wall metadata differs from independently measured stored native bounds/support"
	for key: String in ["draw_basis_columns","raw_camera","scale","support_m","source_min_vertex_ground_delta_m"]:
		if not _equal(old_metadata.get(key),metadata.get(key)): return "New wall changed retained capture basis/camera/support: "+key
	if not _json_exact(metadata.get("draw_basis_columns"),[_v3(Vector3.RIGHT),_v3(Vector3.UP),_v3(Vector3.BACK)]) or not _num(metadata.get("scale"),1): return "New wall draw basis is not actual identity"
	var rows: Variant=revision.get("actual_surface_materials")
	if not rows is Array or rows.size()!=18: return "Actual new wall saved material evidence incomplete"
	var source_material: ShaderMaterial=a.surface_get_material(0) as ShaderMaterial
	if source_material==null or source_material.shader==null: return "Frozen actual masonry material unavailable"
	var checked: Dictionary={}
	state.b=b; state.rows=rows; state.source_material=source_material; state.checked=checked
	return ""

static func _wall_material(state: Dictionary,index: int) -> String:
	var rows: Array=state.rows
	var b: ArrayMesh=state.b
	var source_material: ShaderMaterial=state.source_material
	var region: String=state.region
	var catalog: Dictionary=state.catalog
	var checked: Dictionary=state.checked
	var row: Variant=rows[index]
	var material: ShaderMaterial=b.surface_get_material(index) as ShaderMaterial
	if not row is Dictionary or material==null or material.shader==null or not _num(row.get("surface_index"),index): return "Actual stored new wall surface/material identity missing"
	var curve: bool=index in [16,17]
	var expected_code: String=_masonry_code(source_material.shader.code,curve)
	if material.shader.code!=expected_code: return "Actual saved wall shader differs from independent frozen-code recipe: "+str(index)
	var tint:=Vector3(.99,.99,.97) if curve else (Vector3(.88,.88,.875) if index==15 else Vector3(.95,.95,.95))
	var parameters: Dictionary={"masonry_tint":tint,"masonry_profile":1.0 if region=="ch4_s1_luoyang_yamen" else 0.0}
	if curve: parameters["actual_curved_tile_geometry_identity"]=1.0
	var error: String=_uniform_error(row,material,parameters,catalog,checked)
	if error!="": return "Stored wall "+str(index)+": "+error
	return ""

static func _upper_control(horizontal: bool) -> ArrayMesh:
	# No adapter/builder call. Fixed dimensions and construction order separately
	# reproduce real native packing; every ARRAY_MAX slot remains byte-exact.
	var mesh:=ArrayMesh.new()
	var individual_bricks:=ArrayMesh.new()
	var thickness: float=22.0/32.0 if horizontal else 26.0/64.0
	for course in range(12):
		for brick in range(20):
			var left: float=-2.5+float(brick)*.25+(.125 if course%2==1 else 0.0)
			var right: float=minf(left+.25,2.5)
			if course%2==1 and brick==0: left=-2.5
			var middle: float=(left+right)*.5
			var dimensions:=Vector3(right-left-.007,.114,thickness) if horizontal else Vector3(thickness,.114,right-left-.007)
			var center:=Vector3(middle,.303+float(course)*.122,0) if horizontal else Vector3(0,.303+float(course)*.122,middle)
			_control_box(individual_bricks,dimensions,center)
	# First native-pack each independent BoxMesh, then concatenate its actual
	# stored attributes and offset only indices. All 240 boxes remain present;
	# this changes surface organization, not geometry or support precision.
	var joined: Array=_control_brick_union(individual_bricks)
	if joined.is_empty(): return null
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,joined)
	_control_box(mesh,Vector3(5,.04,thickness+.035) if horizontal else Vector3(thickness+.035,.04,5),Vector3(0,1.685,0))
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_span: float=(thickness+.10)*.5
	for wing: float in [-1.0,1.0]:
		for course in range(2):
			var inner: float=wing*half_span*(float(course)/2.0+.006)
			var outer: float=wing*half_span*((float(course)+1.0)/2.0-.006)
			for tile in range(32):
				var start: float=-2.5+float(tile)*.15625+.009
				var width: float=.15625-.018
				for section in range(4):
					var t0: float=float(section)/4.0
					var t1: float=float(section+1)/4.0
					var a: Vector3=_roof_point(horizontal,half_span,start+width*t0,inner,t0)
					var b: Vector3=_roof_point(horizontal,half_span,start+width*t1,inner,t1)
					var c: Vector3=_roof_point(horizontal,half_span,start+width*t0,outer,t0)
					var d: Vector3=_roof_point(horizontal,half_span,start+width*t1,outer,t1)
					if (b-a).cross(c-a).y>0.0:
						_control_triangle(tool,a,c,b,horizontal)
						_control_triangle(tool,b,c,d,horizontal)
					else:
						_control_triangle(tool,a,b,c,horizontal)
						_control_triangle(tool,b,d,c,horizontal)
	var roof: ArrayMesh=tool.commit()
	if roof==null: return null
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,roof.surface_get_arrays(0))
	_control_box(mesh,Vector3(5,.025,.065) if horizontal else Vector3(.065,.025,5),Vector3(0,1.9675,0))
	if not horizontal:
		var relocated:=ArrayMesh.new()
		for surface in range(4):
			var arrays: Array=mesh.surface_get_arrays(surface)
			if surface in [0,2] and not _v5_control_relocate(arrays,surface): return null
			relocated.add_surface_from_arrays(mesh.surface_get_primitive_type(surface),arrays)
		return relocated
	return mesh

static func _control_brick_union(bricks: ArrayMesh) -> Array:
	if bricks.get_surface_count()!=240: return []
	var vertices:=PackedVector3Array()
	var normals:=PackedVector3Array()
	var tangents:=PackedFloat32Array()
	var uv:=PackedVector2Array()
	var indices:=PackedInt32Array()
	for surface in range(240):
		if bricks.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES: return []
		var arrays: Array=bricks.surface_get_arrays(surface)
		if arrays.size()!=Mesh.ARRAY_MAX or not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array or not arrays[Mesh.ARRAY_NORMAL] is PackedVector3Array or not arrays[Mesh.ARRAY_TANGENT] is PackedFloat32Array or not arrays[Mesh.ARRAY_TEX_UV] is PackedVector2Array or not arrays[Mesh.ARRAY_INDEX] is PackedInt32Array: return []
		var offset: int=vertices.size()
		vertices.append_array(arrays[Mesh.ARRAY_VERTEX])
		normals.append_array(arrays[Mesh.ARRAY_NORMAL])
		tangents.append_array(arrays[Mesh.ARRAY_TANGENT])
		uv.append_array(arrays[Mesh.ARRAY_TEX_UV])
		for index: int in arrays[Mesh.ARRAY_INDEX]: indices.append(offset+index)
		for slot in range(Mesh.ARRAY_MAX):
			if slot not in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_INDEX] and arrays[slot]!=null: return []
	var result: Array=[]
	result.resize(Mesh.ARRAY_MAX)
	result[Mesh.ARRAY_VERTEX]=vertices
	result[Mesh.ARRAY_NORMAL]=normals
	result[Mesh.ARRAY_TANGENT]=tangents
	result[Mesh.ARRAY_TEX_UV]=uv
	result[Mesh.ARRAY_INDEX]=indices
	return result

static func _control_box(mesh: ArrayMesh,dimensions: Vector3,center: Vector3) -> void:
	var primitive:=BoxMesh.new()
	primitive.size=dimensions
	var arrays: Array=primitive.get_mesh_arrays()
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	for index in range(vertices.size()): vertices[index]+=center
	arrays[Mesh.ARRAY_VERTEX]=vertices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)

static func _curved_geometry_evidence(mesh: ArrayMesh,surface: int) -> Dictionary:
	var arrays: Array=mesh.surface_get_arrays(surface)
	if arrays.size()!=Mesh.ARRAY_MAX or not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array or not arrays[Mesh.ARRAY_NORMAL] is PackedVector3Array: return {}
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var indices:=PackedInt32Array()
	if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array: indices=arrays[Mesh.ARRAY_INDEX]
	elif arrays[Mesh.ARRAY_INDEX]!=null: return {}
	var draw:=PackedVector3Array()
	if indices.is_empty(): draw=vertices
	else:
		for index: int in indices:
			if index<0 or index>=vertices.size(): return {}
			draw.append(vertices[index])
	if draw.is_empty() or draw.size()%3!=0 or normals.is_empty(): return {}
	var minimum: float=INF
	var maximum: float=-INF
	for normal: Vector3 in normals:
		if not normal.is_finite(): return {}
		minimum=minf(minimum,normal.y)
		maximum=maxf(maximum,normal.y)
	var clockwise: int=0
	var degenerate: int=0
	for offset in range(0,draw.size(),3):
		var cross: Vector3=(draw[offset+1]-draw[offset]).cross(draw[offset+2]-draw[offset])
		if cross.length_squared()==0.0: degenerate+=1
		if cross.y<0.0: clockwise+=1
	var slots: Array[Dictionary]=[]
	for slot in range(Mesh.ARRAY_MAX): slots.append({"slot":slot,"variant_type":typeof(arrays[slot]),"sha256":_sha(var_to_bytes(arrays[slot]))})
	return {"surface_index":surface,"primitive_type":mesh.surface_get_primitive_type(surface),"vertex_count":vertices.size(),"normal_count":normals.size(),"index_count":indices.size(),"actual_draw_vertex_count":draw.size(),"triangle_count":int(draw.size()/3),"actual_normal_y_min":minimum,"actual_normal_y_max":maximum,"clockwise_up_faces":clockwise,"degenerate_faces":degenerate,"normal_sha256":_sha(var_to_bytes(normals)),"all_actual_surface_array_slots":slots}

static func _roof_point(horizontal: bool,half: float,along: float,across: float,t: float) -> Vector3:
	var height: float=1.94-.21*absf(across)/half+.035*sin(PI*t)*(1.0-absf(across)/half*.35)
	return Vector3(along,height,across) if horizontal else Vector3(across,height,along)

static func _control_triangle(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,horizontal: bool) -> void:
	var normal: Vector3=-(b-a).cross(c-a).normalized()
	for point: Vector3 in [a,b,c]:
		tool.set_normal(normal)
		tool.set_uv(Vector2(point.x,absf(point.z))/1.5 if horizontal else Vector2(point.z,absf(point.x))/1.5)
		tool.add_vertex(point)

static func _used_bounds(mesh: ArrayMesh) -> Dictionary:
	var points:=PackedVector3Array()
	var minimum:=Vector3(INF,INF,INF)
	var maximum:=Vector3(-INF,-INF,-INF)
	for surface in range(mesh.get_surface_count()):
		if mesh.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES: return {}
		var arrays: Array=mesh.surface_get_arrays(surface)
		if arrays.size()!=Mesh.ARRAY_MAX or not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array: return {}
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices:=PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array: indices=arrays[Mesh.ARRAY_INDEX]
		elif arrays[Mesh.ARRAY_INDEX]!=null: return {}
		if indices.is_empty():
			for index in range(vertices.size()): indices.append(index)
		if indices.is_empty() or indices.size()%3!=0: return {}
		var seen: Dictionary={}
		for index: int in indices:
			if index<0 or index>=vertices.size() or not vertices[index].is_finite(): return {}
			if seen.has(index): continue
			seen[index]=true
			minimum=minimum.min(vertices[index])
			maximum=maximum.max(vertices[index])
			points.append(vertices[index])
	if points.is_empty(): return {}
	var sum: float=0.0
	var front: float=-INF
	var count: int=0
	for point: Vector3 in points:
		if point.y<=minimum.y+(maximum.y-minimum.y)*.02:
			sum+=point.x
			front=maxf(front,point.z)
			count+=1
	if count==0: return {}
	return {"minimum":minimum,"maximum":maximum,"support":Vector3(sum/count,minimum.y,front),"support_count":count,"actual_used_vertices":points.size()}

static func _surface_error(a: Mesh,ai: int,b: Mesh,bi: int,label: String) -> String:
	if not a is ArrayMesh or not b is ArrayMesh: return "Unknown array representation: "+label
	var aa_mesh: ArrayMesh=a as ArrayMesh
	var bb_mesh: ArrayMesh=b as ArrayMesh
	if aa_mesh.surface_get_primitive_type(ai)!=bb_mesh.surface_get_primitive_type(bi): return "Stored primitive changed: "+label
	var aa: Array=a.surface_get_arrays(ai)
	var bb: Array=b.surface_get_arrays(bi)
	if aa.size()!=Mesh.ARRAY_MAX or bb.size()!=Mesh.ARRAY_MAX: return "Incomplete native surface: "+label
	for slot in range(Mesh.ARRAY_MAX):
		if var_to_bytes(aa[slot])!=var_to_bytes(bb[slot]): return "Stored native slot mismatch: "+label+"/"+str(ai)+"→"+str(bi)+"/"+str(slot)
	return ""

static func _meshes_error(old_path: String,new_path: String,label: String) -> String:
	var a: Mesh=ResourceLoader.load(old_path,"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	var b: Mesh=ResourceLoader.load(new_path,"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	if a==null or b==null or a.get_class()!=b.get_class() or a.get_surface_count()<=0 or a.get_surface_count()!=b.get_surface_count(): return "Protected mesh representation/count changed: "+label
	for index in range(a.get_surface_count()):
		if a is ArrayMesh:
			var error: String=_surface_error(a,index,b,index,label)
			if error!="": return error
		elif a is PrimitiveMesh and b is PrimitiveMesh:
			var aa: Array=a.surface_get_arrays(index)
			var bb: Array=b.surface_get_arrays(index)
			if aa.size()!=Mesh.ARRAY_MAX or bb.size()!=Mesh.ARRAY_MAX: return "Incomplete primitive array set: "+label
			for slot in range(Mesh.ARRAY_MAX):
				if var_to_bytes(aa[slot])!=var_to_bytes(bb[slot]): return "Protected primitive slot changed: "+label
		else: return "Unknown protected mesh representation: "+label
	if a is PrimitiveMesh:
		if a.get_faces().is_empty() or a.get_faces().to_byte_array()!=b.get_faces().to_byte_array(): return "Protected primitive triangles changed: "+label
		for property: Dictionary in a.get_property_list():
			var name: String=property.name
			if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or name in ["material","resource_path","resource_name","resource_local_to_scene","script"]: continue
			if var_to_bytes(a.get(name))!=var_to_bytes(b.get(name)): return "Protected primitive geometry parameter changed: "+label+"/"+name
	return ""

static func _masonry_code(baseline: String,curve: bool) -> String:
	# Exact root_wall_v4 recipe. Keep independent reconstruction and complete
	# shader equality; do not accept a saved code hash as its own specification.
	var code: String=baseline.replace("cap=smoothstep(1.22,1.28,p.y)","cap=smoothstep(1.66,1.70,p.y)")
	code=code.replace("vec3 brick=vec3(.355,.37,.38)*(.79+luma*.36)+(stone-vec3(luma))*.05;","vec3 brick=vec3(.34,.355,.365)*(.58+luma*.85)+(stone-vec3(luma))*.13;")
	code=code.replace("vec3 lime=vec3(.675,.675,.65)*(.95+luma*.07);","vec3 lime=vec3(.70,.695,.665)*(.87+luma*.20);")
	code=code.replace("face*=.975+(age-.5)*.035;","face*=.965+(age-.5)*.075;")
	code=code.replace("tangent*d.x*.032+bitangent*d.y*.032","tangent*d.x*.075+bitangent*d.y*.075")
	code=code.replace("vec3 brick=vec3(.34,.355,.365)*(.58+luma*.85)+(stone-vec3(luma))*.13;","vec3 brick=vec3(.365,.36,.345)*(.58+luma*.85)+(stone-vec3(luma))*.13;")
	if curve:
		code=code.replace("uniform vec3 masonry_tint=vec3(1.);","uniform float actual_curved_tile_geometry_identity=1.;\nuniform vec3 masonry_tint=vec3(1.);")
		code=code.replace("vec3 face=masonry_profile>.5?lime:brick;","vec3 face=vec3(.265,.28,.29)*(.79+luma*.35)+(stone-vec3(luma))*.055;")
		code=code.replace("face=mix(face,vec3(.25,.27,.285)*(.83+luma*.28),base);","// Real narrow curved tile vertices, not material-only barrel illusion.")
		code=code.replace("face=mix(face,vec3(.25,.265,.275)*(.86+luma*.23),cap);","face*=actual_curved_tile_geometry_identity;")
	return code

static func _uniform_error(row: Dictionary,material: ShaderMaterial,parameters: Dictionary,catalog: Dictionary,checked: Dictionary) -> String:
	var expected: Dictionary={"original_stone":TYPE_OBJECT,"registered_normal":TYPE_OBJECT,"registered_arm":TYPE_OBJECT}
	for name: String in parameters: expected[name]=typeof(parameters[name])
	var names: Array[String]=[]
	for uniform: Dictionary in material.shader.get_shader_uniform_list():
		var name: String=String(uniform.get("name",""))
		if names.has(name) or not expected.has(name) or uniform.get("type")!=expected[name] or (expected[name]==TYPE_OBJECT and uniform.get("hint_string")!="Texture2D"): return "Actual shader complete reflection/type differs: "+name
		names.append(name)
	var recorded: Variant=row.get("actual_parameters")
	var registered: Variant=row.get("registered_sampler_evidence")
	if names.size()!=expected.size() or not _equal(names,row.get("actual_uniform_schema")) or not recorded is Dictionary or recorded.size()!=expected.size() or not registered is Array or row.get("actual_sampler_objects_equal_registered_textures")!=true or row.get("actual_shader_code_sha256")!=_sha(material.shader.code.to_utf8_buffer()): return "Actual saved shader schema/code/evidence incomplete"
	var texture_keys: Dictionary={"original_stone":"stone","registered_normal":"nor_gl","registered_arm":"arm"}
	for name: String in names:
		var actual: Variant=material.get_shader_parameter(name)
		var evidence: Variant=recorded.get(name)
		if typeof(actual)!=expected[name] or not evidence is Dictionary or not _num(evidence.get("type"),expected[name]): return "Actual saved shader parameter type differs: "+name
		if expected[name]==TYPE_OBJECT:
			var texture: Texture2D=actual as Texture2D
			var path: String=TEXTURES[name]
			if texture==null or evidence.get("registered_texture_key")!=texture_keys[name] or evidence.get("same_actual_registered_object")!=true or not _json_exact(evidence.get("actual_size_px"),[texture.get_width(),texture.get_height()]): return "Stored registered sampler identity/size changed: "+name
			var error: String=_sampler_error(texture,path,registered,catalog,checked)
			if error!="": return error
		else:
			if var_to_bytes(actual)!=var_to_bytes(parameters[name]) or evidence.get("variant_sha256")!=_sha(var_to_bytes(actual)): return "Actual shader parameter differs from independent constant recipe: "+name
			var value: Variant=_v3(actual) if actual is Vector3 else actual
			if not _json_exact(evidence.get("value"),value): return "Saved shader parameter numeric evidence differs: "+name
	return ""

static func _body_error(metadata: Dictionary,catalog: Dictionary,stem: String,cpu_context: RefCounted=null) -> String:
	for pair: Array in [["texture",".png"],["metadata_path",".json"],["native_mesh_path",".res"],["sourcebody_raw","_raw.png"],["sourcebody_raw_repeat","_raw_repeat.png"]]:
		if metadata.get(pair[0])!=stem+pair[1] or not _catalog_file(catalog,stem+pair[1]): return "Actual current wall render role points at unrelated evidence"
	if metadata.get("alpha_resampling_algorithm")!=ALPHA_ID or not _num(metadata.get("alpha_unpremultiply_epsilon"),ALPHA_EPSILON) or metadata.get("repeat_byte_exact")!=true or metadata.get("sourcebody_and_ground_caster_same_mesh_material_basis_support")!=true: return "Unknown exact wall alpha/repeat/caster contract"
	if cpu_context != null and (cpu_context.get_script() != CPU_WORKSPACE or not cpu_context.matches_body(stem,metadata,catalog)): return "Unbound/cancelled actual wall CPU pixels"
	var raw: Image=Image.load_from_file(stem+"_raw.png") if cpu_context == null else cpu_context.image(stem+"_raw.png")
	var repeat: Image=Image.load_from_file(stem+"_raw_repeat.png") if cpu_context == null else cpu_context.image(stem+"_raw_repeat.png")
	var image: Image=Image.load_from_file(stem+".png") if cpu_context == null else cpu_context.image(stem+".png")
	if raw==null or repeat==null or image==null or raw.get_size()!=Vector2i(1536,1536) or raw.get_format()!=Image.FORMAT_RGBA8 or repeat.get_size()!=raw.get_size() or repeat.get_format()!=raw.get_format() or raw.get_data()!=repeat.get_data() or catalog[stem+"_raw.png"]!=catalog[stem+"_raw_repeat.png"]: return "Actual wall raw repeat/canvas/format not byte exact"
	var logical: Image=_alpha_reconstruct(raw,Vector2i(768,768)) if cpu_context == null else cpu_context.logical(stem)
	if logical == null: return "Actual wall CPU alpha reconstruction unavailable"
	var used: Rect2i=logical.get_used_rect()
	if used.size.x<=0 or used.position.x<4 or used.position.y<4 or used.end.x>764 or used.end.y>764: return "Actual new wall alpha capture is empty/touches edge"
	var crop:=Rect2i(used.position-Vector2i(4,4),used.size+Vector2i(8,8))
	if not _json_exact(metadata.get("crop_rect_px"),[crop.position.x,crop.position.y,crop.size.x,crop.size.y]) or not _json_exact(metadata.get("source_size_px"),[crop.size.x,crop.size.y]) or not _equal(metadata.get("source_size_px"),metadata.get("render_size_px")): return "Actual wall fresh tight alpha crop differs"
	var expected: Image=logical.get_region(crop)
	if image.get_size()!=expected.get_size() or image.get_format()!=expected.get_format() or image.get_data()!=expected.get_data(): return "Independent alpha-aware logical wall crop differs byte-for-byte"
	var camera_value: Variant=metadata.get("raw_camera")
	if not camera_value is Dictionary: return "Actual wall camera unavailable"
	var camera: Dictionary=camera_value
	if not _json_exact(camera.get("raw_canvas_px"),[1536,1536]) or not _json_exact(camera.get("logical_canvas_px"),[768,768]) or not _num(camera.get("raw_to_logical_factor"),2) or not _num(camera.get("msaa"),0) or not _num(camera.get("projection"),Camera3D.PROJECTION_ORTHOGONAL) or not _num(camera.get("orthographic_size_m"),12): return "Actual wall raw/logical camera contract differs"
	var pixel: Vector2=_actual_camera_foot(camera)
	if not pixel.is_finite(): return "Independent bound Camera3D projection unavailable"
	var foot: Vector2=pixel/2.0-Vector2(crop.position)
	if not _json_exact(metadata.get("foot_uv"),[foot.x/image.get_width(),foot.y/image.get_height()]): return "New actual wall foot UV does not reconstruct current camera/crop"
	return ""

static func _alpha_reconstruct(raw: Image,size: Vector2i,cpu_cancel: RefCounted=null) -> Image:
	# Independent packed-float implementation, not an executor call. Epsilon is
	# the fixed named algorithm's zero rule, never an alpha/geometry tolerance.
	var converted: Image=raw.duplicate() as Image
	converted.convert(Image.FORMAT_RGBAF)
	# Replay conversion before multiplication: the source channels are native
	# float32 before Color multiplication, not double byte/255 intermediates.
	var floats: PackedFloat32Array=converted.get_data().to_float32_array()
	for index in range(0,floats.size(),4):
		if cpu_cancel != null and index % 4096 == 0 and cpu_cancel.is_cancelled(): return null
		var alpha: float=floats[index+3]
		floats[index]*=alpha
		floats[index+1]*=alpha
		floats[index+2]*=alpha
	var result: Image=Image.create_from_data(raw.get_width(),raw.get_height(),false,Image.FORMAT_RGBAF,floats.to_byte_array())
	result.resize(size.x,size.y,Image.INTERPOLATE_LANCZOS)
	if cpu_cancel != null and cpu_cancel.is_cancelled(): return null
	var values: PackedFloat32Array=result.get_data().to_float32_array()
	for index in range(0,values.size(),4):
		if cpu_cancel != null and index % 4096 == 0 and cpu_cancel.is_cancelled(): return null
		var alpha: float=values[index+3]
		if alpha>ALPHA_EPSILON:
			values[index]/=alpha
			values[index+1]/=alpha
			values[index+2]/=alpha
		else:
			for channel in range(4): values[index+channel]=0.0
	result=Image.create_from_data(size.x,size.y,false,Image.FORMAT_RGBAF,values.to_byte_array())
	result.convert(Image.FORMAT_RGBA8)
	return result

static func _actual_camera_foot(data: Dictionary) -> Vector2:
	var tree: SceneTree=Engine.get_main_loop() as SceneTree
	var columns: Variant=data.get("basis_columns")
	if tree==null or not columns is Array or columns.size()!=3: return Vector2(INF,INF)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(1536,1536)
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	viewport.own_world_3d=true
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=12.0
	camera.near=float(data.get("near",NAN))
	camera.far=float(data.get("far",NAN))
	camera.transform=Transform3D(Basis(_vector3(columns[0]),_vector3(columns[1]),_vector3(columns[2])),_vector3(data.get("position_m")))
	if not camera.position.is_finite() or not camera.basis.is_finite() or not is_finite(camera.near) or not is_finite(camera.far):
		camera.free()
		viewport.free()
		return Vector2(INF,INF)
	tree.root.add_child(viewport)
	viewport.add_child(camera)
	camera.make_current()
	var projected: Vector2=camera.unproject_position(Vector3.ZERO)
	viewport.free()
	return projected

static func _ground_repeat_error(prefix: String,catalog: Dictionary,cpu_context: RefCounted=null) -> String:
	var on: Image=null
	for role: String in ["on","off"]:
		var path: String=prefix+"ground_"+role+"_raw.png"
		var repeat_path: String=prefix+"ground_"+role+"_raw_repeat.png"
		if not _catalog_file(catalog,path) or not _catalog_file(catalog,repeat_path) or catalog[path]!=catalog[repeat_path]: return "Actual ground caster ON/OFF raw repeats unbound/different: "+role
		var image: Image=Image.load_from_file(path) if cpu_context == null else cpu_context.image(path)
		var repeat: Image=Image.load_from_file(repeat_path) if cpu_context == null else cpu_context.image(repeat_path)
		if image==null or repeat==null or image.get_size()!=Vector2i(6144,4096) or image.get_format()!=Image.FORMAT_RGBA8 or repeat.get_size()!=image.get_size() or repeat.get_format()!=image.get_format() or repeat.get_data()!=image.get_data(): return "Actual ground caster ON/OFF raw pixels differ: "+role
		if role=="on": on=image
	if not _catalog_file(catalog,prefix+"floor.png"): return "Actual derived floor not catalog-bound"
	var floor: Image=Image.load_from_file(prefix+"floor.png") if cpu_context == null else cpu_context.image(prefix+"floor.png")
	if floor==null or floor.get_format()!=Image.FORMAT_RGBA8: return "Actual derived floor PNG unavailable"
	var derived: Image
	if cpu_context == null:
		derived=on.duplicate() as Image
		derived.resize(3072,2048,Image.INTERPOLATE_LANCZOS)
	else:
		derived=cpu_context.ground(prefix,catalog)
		if derived == null: return "Actual ground CPU reconstruction unavailable"
	if floor.get_size()!=derived.get_size() or floor.get_data()!=derived.get_data(): return "Independent ground ON→logical floor byte reconstruction differs"
	return ""

static func _paving_error(record: Dictionary,catalog: Dictionary,prefix: String,old_prefix: String) -> String:
	# A live material_override must be saved independently; a self-reported hash
	# in material_binding.json alone cannot prove the actual stored sampler.
	var graph: Dictionary=record.capture_graph
	var value: Variant=graph.get("paving_material")
	if not value is Dictionary or value.get("path")!=prefix+"paving_material.res" or not _catalog_file(catalog,prefix+"paving_material.res") or value.get("sha256")!=catalog[prefix+"paving_material.res"]: return "Actual paving material_override has no bound saved resource"
	var material: ShaderMaterial=ResourceLoader.load(prefix+"paving_material.res","",ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
	if material==null or material.shader==null: return "Actual saved paving shader unavailable"
	if FileAccess.get_sha256(OLD_STREET_SURFACE).to_lower()!=OLD_STREET_SURFACE_SHA or not _catalog_file(catalog,OLD_STREET_SURFACE): return "Frozen paving shader source provenance changed"
	# Read the frozen literal shader, never instantiate/call the production
	# surface. Apply only the approved textual recipe to its exact code.
	var text: String=FileAccess.get_file_as_string(OLD_STREET_SURFACE).replace("\r\n","\n")
	var function_start: int=text.find("func paving() -> ShaderMaterial:")
	var begin: int=text.find("shader.code=\"\"\"",function_start)
	if function_start<0 or begin<0: return "Frozen original paving literal unavailable"
	begin+="shader.code=\"\"\"".length()
	var end: int=text.find("\"\"\"",begin)
	if end<0: return "Frozen original paving literal malformed"
	var expected_code: String=_paving_code(text.substr(begin,end-begin))
	if expected_code=="" or material.shader.code!=expected_code: return "Saved actual paving shader differs from independent frozen-literal recipe"
	var control_shader:=Shader.new()
	control_shader.code=expected_code
	if var_to_bytes(material.shader.get_shader_uniform_list())!=var_to_bytes(control_shader.get_shader_uniform_list()): return "Saved actual paving complete reflected schema differs"
	var binding_value: Variant=JSON.parse_string(FileAccess.get_file_as_string(prefix+"material_binding.json"))
	if not _catalog_file(catalog,prefix+"material_binding.json") or not binding_value is Dictionary or not _equal(binding_value,record.get("material_binding_evidence")): return "Saved actual paving JSON differs from final manifest evidence"
	var binding: Dictionary=binding_value
	var owner_value: Variant=binding.get("native_geometry_owner_uniforms")
	if not owner_value is Dictionary: return "Saved actual paving geometry-owner evidence absent"
	var owner: Dictionary=owner_value
	if owner.get("actual_material_override_path")!=prefix+"paving_material.res" or owner.get("actual_material_override_sha256")!=catalog[prefix+"paving_material.res"] or owner.get("actual_shader_code_sha256")!=_sha(expected_code.to_utf8_buffer()): return "Actual saved paving node/override/code binding differs"
	var arrays: Dictionary=_owner_arrays(record)
	if arrays.is_empty(): return "Independent route/contact/apron owner construction failed"
	var expected_counts: Dictionary={"route_count":arrays.route_segments.size(),"contact_count":arrays.contact_segments.size(),"apron_count":arrays.apron_rects.size()}
	if not _json_exact(owner.get("actual_counts"),expected_counts): return "Actual paving owner counts differ from independent unchanged source"
	var parameters_value: Variant=owner.get("actual_parameters")
	if not parameters_value is Dictionary: return "Saved paving all parameter evidence missing"
	var parameters: Dictionary=parameters_value
	var names: Array[String]=[]
	for entry: Dictionary in control_shader.get_shader_uniform_list(): names.append(String(entry.name))
	if parameters.size()!=names.size() or not _equal(names,owner.get("uniforms")) or not _equal(names,binding.get("reflected_uniforms")): return "Actual paving complete parameter/name set differs"
	var constants: Dictionary={"native_flagstone_identity":1.0,"quay_wet_profile":1.0 if record.canonical_scene_id=="ch4_s2_canal_docks" else 0.0,"wall_street_finish_identity":1.0,"zone_finish_identity":1.0,"zone_court_profile":1.0 if record.canonical_scene_id=="ch4_s1_luoyang_yamen" else 0.0,"zone_avenue_bounds":Vector4(-2.75,-16.375,2.75,28.625),"zone_court_bounds":Vector4(-8.375,-8.875,8.34375,19.25)}
	for name: String in expected_counts: constants[name]=int(expected_counts[name])
	var sampler_paths: Dictionary={"stone_albedo":TEXTURES.original_stone,"rock_diff":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_diff_2k.jpg","rock_normal":TEXTURES.registered_normal,"rock_arm":TEXTURES.registered_arm}
	var sampler_keys: Dictionary={"stone_albedo":"stone","rock_diff":"diff","rock_normal":"nor_gl","rock_arm":"arm"}
	var checked: Dictionary={}
	for name: String in names:
		var actual: Variant=material.get_shader_parameter(name)
		var evidence: Variant=parameters.get(name)
		if not evidence is Dictionary or not _num(evidence.get("type"),typeof(actual)): return "Actual saved paving parameter/evidence type differs: "+name
		if sampler_paths.has(name):
			var texture: Texture2D=actual as Texture2D
			if texture==null or evidence.get("registered_texture_key")!=sampler_keys[name] or evidence.get("same_actual_registered_object")!=true or not _json_exact(evidence.get("actual_size_px"),[texture.get_width(),texture.get_height()]): return "Actual saved paving sampler/key/size differs: "+name
			var error: String=_sampler_error(texture,sampler_paths[name],owner.get("actual_sampler_sources_and_mips"),catalog,checked)
			if error!="": return error
		elif constants.has(name):
			if var_to_bytes(actual)!=var_to_bytes(constants[name]) or evidence.get("variant_sha256")!=_sha(var_to_bytes(actual)) or not _json_exact(evidence.get("value"),actual): return "Actual saved paving scalar differs: "+name
		elif arrays.has(name):
			var limit: int=32 if name=="apron_rects" else 128
			# Explicit untyped Array is the declared saved-resource construction,
			# not a post-readback coercion. Each original Vector4 remains exact.
			var expected: Array=arrays[name]
			while expected.size()<limit: expected.append(Vector4.ZERO)
			if not actual is Array or actual.size()!=limit: return "Actual saved paving owner array representation/count differs: "+name
			var current_array: Array=actual
			if current_array.is_typed() or expected.is_typed() or var_to_bytes(current_array)!=var_to_bytes(expected): return "Actual saved paving complete untyped owner array bytes differ: "+name
			for index in range(limit):
				if not actual[index] is Vector4 or var_to_bytes(actual[index])!=var_to_bytes(expected[index]): return "Actual saved paving world-metre owner vector differs: "+name+"/"+str(index)
			if evidence.get("variant_sha256")!=_sha(var_to_bytes(actual)) or not _json_exact(evidence.get("value"),actual): return "Actual saved paving array evidence differs from stored native values: "+name
		else: return "Unknown saved paving uniform: "+name
	# The physical ground geometry was independently compared above; this
	# shader check is finish-only, not an assertion of new wall arrays unchanged.
	if not _catalog_file(catalog,old_prefix+"art_contract.json"): return "Frozen paving baseline provenance absent from new catalog"
	return _zone_records_error(binding,expected_code,record.canonical_scene_id,old_prefix,record.objects)

static func _v4_paving_code(base: String) -> String:
	var code: String=base.replace("uniform float native_flagstone_identity=1.;","uniform float native_flagstone_identity=1.;\nuniform float quay_wet_profile=0.;\nuniform float wall_street_finish_identity=1.;")
	code=code.replace("float traffic=1.-smoothstep(.65,1.65,route_d);","float traffic=1.-smoothstep(.90,2.10,route_d);")
	code=code.replace("float verge=smoothstep(2.2,4.5,route_d)*(1.-apron);","float verge=smoothstep(2.8,5.8,route_d)*(1.-apron);\n float wet=quay_wet_profile*(1.-smoothstep(.45,4.2,abs(p.x-10.84375)));")
	code=code.replace("vec3 finish=mix(vec3(.81,.815,.80),vec3(.89,.885,.85),traffic);","vec3 finish=mix(vec3(.76,.765,.755),vec3(.92,.91,.865),traffic);")
	code=code.replace("finish=mix(finish,vec3(.87,.86,.82),apron*.48);","finish=mix(finish,vec3(.94,.925,.87),apron*.72);\n finish=mix(finish,vec3(.56,.60,.60),wet*.42);")
	code=code.replace("finish*=.985+(broad-.5)*.045;","finish*=.97+(broad-.5)*.11;")
	code=code.replace("verge*.18+contact*.055","verge*.24+contact*.10")
	code=code.replace("ROUGHNESS=clamp(.88-traffic*.15+verge*.035+(arm.g-.5)*.035,.69,.96);","ROUGHNESS=clamp(.91-traffic*.21-wet*.17+verge*.025+(arm.g-.5)*.035,.62,.97);")
	return code

static func _owner_arrays(record: Dictionary) -> Dictionary:
	var routes: Array=[]
	var contacts: Array=[]
	var aprons: Array=[]
	for route: Variant in record.get("routes",[]):
		if not route is Dictionary or not route.get("points_px") is Array: return {}
		var points: Array=route.points_px
		for index in range(points.size()-1):
			var a: Vector2=_world_m(points[index])
			var b: Vector2=_world_m(points[index+1])
			if not a.is_finite() or not b.is_finite(): return {}
			routes.append(Vector4(a.x,a.y,b.x,b.y))
	for object: Dictionary in record.objects:
		if not bool(object.get("blocking",false)): continue
		var polygons: Array=object.get("solid_polygons_px",[]).duplicate(true)
		if polygons.is_empty():
			var dimensions: Variant=object.get("collision_size_px")
			var midpoint: Variant=object.get("physical_center_px")
			if not dimensions is Array or dimensions.size()!=2 or not midpoint is Array or midpoint.size()!=2: return {}
			if float(dimensions[0])>0.0 and float(dimensions[1])>0.0:
				var x0: float=float(midpoint[0])-float(dimensions[0])*.5
				var x1: float=float(midpoint[0])+float(dimensions[0])*.5
				var y0: float=float(midpoint[1])-float(dimensions[1])*.5
				var y1: float=float(midpoint[1])+float(dimensions[1])*.5
				polygons.append([[x0,y0],[x1,y0],[x1,y1],[x0,y1]])
		for polygon: Variant in polygons:
			if not polygon is Array or polygon.size()<3: return {}
			var low:=Vector2(INF,INF)
			var high:=Vector2(-INF,-INF)
			for index in range(polygon.size()):
				var a: Vector2=_world_m(polygon[index])
				var b: Vector2=_world_m(polygon[(index+1)%polygon.size()])
				if not a.is_finite() or not b.is_finite(): return {}
				contacts.append(Vector4(a.x,a.y,b.x,b.y))
				low=low.min(a)
				high=high.max(a)
			var id: String=String(object.get("id",""))
			if "front" in id or id in ["inn","shop","north_canal_warehouse"]: aprons.append(Vector4(low.x,high.y,high.x,high.y+3.2))
	if routes.is_empty() or routes.size()>128 or contacts.size()>128 or aprons.size()>32: return {}
	return {"route_segments":routes,"contact_segments":contacts,"apron_rects":aprons}

static func _world_m(point: Variant) -> Vector2:
	if not point is Array or point.size()!=2: return Vector2(INF,INF)
	for component: Variant in point:
		if not typeof(component) in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(component)): return Vector2(INF,INF)
	return Vector2((float(point[0])-1536.0)/64.0,(float(point[1])-1024.0)/32.0)

static func _sampler_error(texture: Texture2D,path: String,registered: Variant,catalog: Dictionary,checked: Dictionary) -> String:
	if not registered is Array or not TEXTURE_SHAS.has(path) or not _catalog_file(catalog,path) or String(catalog[path]).to_lower()!=TEXTURE_SHAS[path]: return "Actual registered literal sampler source SHA changed: "+path
	var entry: Dictionary={}
	for row: Variant in registered:
		if not row is Dictionary: return "Registered material source evidence malformed"
		if row.get("path")==path:
			if not entry.is_empty(): return "Duplicate registered sampler source evidence"
			entry=row
	if entry.is_empty() or String(entry.get("sha256","")).to_lower()!=TEXTURE_SHAS[path] or not _catalog_file(catalog,String(entry.get("source_path",""))) or entry.get("source_sha256")!=catalog[entry.source_path]: return "Actual registered sampler provenance absent/changed"
	var key: String=path+"|"+str(texture.get_instance_id())
	if checked.has(key): return ""
	var original: Image=Image.load_from_file(path)
	var stored: Image=texture.get_image()
	if original==null or stored==null or original.generate_mipmaps()!=OK: return "Independent sampler decode/mipmap failed: "+path
	if stored.get_size()!=original.get_size() or stored.get_format()!=original.get_format() or stored.has_mipmaps()!=original.has_mipmaps() or stored.get_mipmap_count()!=original.get_mipmap_count() or stored.get_data()!=original.get_data() or not _num(entry.get("actual_mip_count"),original.get_mipmap_count()): return "Actual saved sampler complete bytes/mips differ from original: "+path
	checked[key]=true
	return ""

static func _caster_error(object: Dictionary,metadata: Dictionary) -> String:
	var transform: Variant=object.get("native_transform")
	var foot_value: Variant=object.get("world_foot_px")
	var support: Vector3=_vector3(metadata.get("support_m"))
	if not transform is Dictionary or not foot_value is Array or foot_value.size()!=2 or not support.is_finite(): return "Actual native caster transform/source feet unavailable"
	var foot:=Vector2(float(foot_value[0]),float(foot_value[1]))
	if not foot.is_finite(): return "Nonfinite actual native caster feet"
	var anchor:=Vector3((foot.x-1536.0)/64.0,0.0,(foot.y-1024.0)/32.0)
	if not _equal(transform.get("basis_columns"),metadata.get("draw_basis_columns")) or not _json_exact(transform.get("origin"),_v3(anchor-support)): return "Actual native caster pose does not reconstruct own feet/basis/support: "+str(object.get("id"))
	if String(metadata.get("kind","")) in ["wall_horizontal","wall_vertical"]:
		var body: Variant=metadata.get("actual_body_mesh_binding")
		var path: String=String(metadata.get("native_mesh_path",""))
		if not body is Dictionary or body.get("native_mesh_path")!=path or body.get("native_mesh_sha256")!=FileAccess.get_sha256(path) or not _equal(body.get("basis_columns"),metadata.get("draw_basis_columns")) or not _json_exact(body.get("origin_m"),_v3(-support)) or body.get("actual_node_mesh_equals_saved_checked_mesh")!=true: return "Actual body/caster native mesh/basis/support not exact bound stored resource"
	return ""

static func _material_equal_error(a: Material,b: Material) -> String:
	if a==null or b==null or a.get_class()!=b.get_class(): return "Actual material representation missing/changed"
	if a is ShaderMaterial:
		var aa: ShaderMaterial=a as ShaderMaterial
		var bb: ShaderMaterial=b as ShaderMaterial
		if aa.shader==null or bb.shader==null or aa.shader.code!=bb.shader.code or not _equal(aa.shader.get_shader_uniform_list(),bb.shader.get_shader_uniform_list()): return "Actual shader code/schema changed"
		for uniform: Dictionary in aa.shader.get_shader_uniform_list():
			var name: String=uniform.name
			var error: String=_value_error(aa.get_shader_parameter(name),bb.get_shader_parameter(name))
			if error!="": return name+"/"+error
		return ""
	for property: Dictionary in a.get_property_list():
		var name: String=property.name
		if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or name in ["resource_path","resource_name","resource_local_to_scene","script"]: continue
		var error: String=_value_error(a.get(name),b.get(name))
		if error!="": return name+"/"+error
	return ""

static func _value_error(a: Variant,b: Variant) -> String:
	if typeof(a)!=typeof(b): return "Variant type changed"
	if a is Texture2D:
		if not b is Texture2D: return "Texture representation changed"
		var x: Image=a.get_image()
		var y: Image=b.get_image()
		if x==null or y==null or x.get_size()!=y.get_size() or x.get_format()!=y.get_format() or x.has_mipmaps()!=y.has_mipmaps() or x.get_mipmap_count()!=y.get_mipmap_count() or x.get_data()!=y.get_data(): return "Actual sampler full pixels/mips changed"
	elif a is Resource or b is Resource:
		if a==null or b==null: return "Nested resource presence changed"
		return "Unsupported nested material Resource; must explicitly bind it"
	elif var_to_bytes(a)!=var_to_bytes(b): return "Actual value bytes changed"
	return ""

static func _vector3(value: Variant) -> Vector3:
	if not value is Array or value.size()!=3: return Vector3(INF,INF,INF)
	for component: Variant in value:
		if not typeof(component) in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(component)): return Vector3(INF,INF,INF)
	return Vector3(float(value[0]),float(value[1]),float(value[2]))

static func _v3(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

static func _json_exact(saved: Variant,native: Variant) -> bool:
	# Only explicit native→metadata representation. No epsilon/rounding of
	# actual resource arrays or source bytes; parsed records compare recursively.
	return _equal(saved,JSON.parse_string(JSON.stringify(native)))

static func _equal(a: Variant,b: Variant) -> bool:
	if typeof(a)!=typeof(b): return false
	if a is Array:
		if a.size()!=b.size(): return false
		for index in range(a.size()):
			if not _equal(a[index],b[index]): return false
		return true
	if a is Dictionary:
		if a.size()!=b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _equal(a[key],b[key]): return false
		return true
	return a==b

static func _num(value: Variant,expected: float) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value)==expected

static func _catalog_file(catalog: Dictionary,path: String) -> bool:
	return catalog.has(path) and _hash(catalog[path]) and FileAccess.get_sha256(path).to_lower()==String(catalog[path]).to_lower()

static func _hash(value: Variant) -> bool:
	if not value is String or value.length()!=64: return false
	for character: String in value.to_lower():
		if not character in "0123456789abcdef": return false
	return true

static func _sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	if context.start(HashingContext.HASH_SHA256)!=OK: return ""
	if not bytes.is_empty() and context.update(bytes)!=OK: return ""
	return context.finish().hex_encode()

static func _v5_manifest_error(record: Dictionary,catalog: Dictionary,region: String,cpu_context: RefCounted=null) -> String:
	var path: String=V4_ROOT+region+"/art_contract.json"
	if not _catalog_file(catalog,path) or String(catalog[path]).to_lower()!=V4_MANIFEST_SHAS[region]: return "V5 current V4 manifest is not the frozen baseline"
	var previous: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not previous is Dictionary or not previous.get("asset_sha256") is Dictionary: return "Malformed immutable V4 catalog"
	for asset: Variant in previous.asset_sha256:
		if not asset is String or not _hash(previous.asset_sha256[asset]) or (FileAccess.get_sha256(asset) if cpu_context == null else cpu_context.source_sha(StringName(region),asset)).to_lower()!=String(previous.asset_sha256[asset]).to_lower(): return "Immutable V4 asset changed: "+str(asset)
	var scope: Variant=record.get("v5_scope")
	if not scope is Dictionary or not scope.get("origin_capture") is Dictionary or not scope.get("current_v4_manifest") is Dictionary or not scope.get("actual_current_v4_wall_comparisons") is Dictionary: return "Missing explicit V5 current-baseline scope"
	var origin: String="res://scripts/dev/build_luoyang_modular_v3_wall_street_capture_proposal.gd"
	if scope.origin_capture.get("path")!=origin or scope.origin_capture.get("sha256")!=PINS[origin] or scope.current_v4_manifest.get("path")!=path or scope.current_v4_manifest.get("sha256")!=V4_MANIFEST_SHAS[region]: return "V5 origin/current baseline identity mismatch"
	for key: String in ["field_executed","visual_approved","production_approved"]:
		if typeof(scope.get(key))!=TYPE_BOOL or scope[key]!=false: return "Capture cannot grant Field/formal approval"
	if scope.get("geometry_not_material_only")!=true: return "V5 actual upper geometry declaration missing"
	var sources: Variant=record.get("source_graph")
	if not sources is Dictionary: return "V5 exact source closure missing"
	for asset: String in PINS:
		if not _catalog_file(catalog,asset) or String(catalog[asset]).to_lower()!=PINS[asset] or sources.get(asset)!=PINS[asset]: return "V5 actual frozen source closure differs: "+asset
	var wall_kinds: Dictionary={}
	if not record.get("objects") is Array: return "V5 actual objects missing"
	for object: Variant in record.objects:
		if not object is Dictionary: return "V5 actual object malformed"
		if object.get("prototype") in ["wall_horizontal","wall_vertical"]: wall_kinds[object.prototype]=true
	if scope.actual_current_v4_wall_comparisons.size()!=wall_kinds.size(): return "V5 current wall evidence set differs from actual objects"
	for kind: String in wall_kinds:
		var metadata_path: String=NEW_ROOT+region+"/entities/native_"+kind+".json"
		var metadata: Variant=JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
		if not _catalog_file(catalog,metadata_path) or not metadata is Dictionary or not metadata.get("upper_wall_geometry_revision") is Dictionary or not _equal(scope.actual_current_v4_wall_comparisons.get(kind),metadata.upper_wall_geometry_revision.get("current_v4_comparison")): return "V5 manifest/prototype current V4 comparison disagrees"
	return ""

static func _v5_current_wall_error(revision: Dictionary,catalog: Dictionary,stem: String,region: String,horizontal: bool,mesh: ArrayMesh) -> String:
	var kind: String="wall_horizontal" if horizontal else "wall_vertical"
	var path: String=V4_ROOT+region+"/entities/native_"+kind+".res"
	var previous_manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(V4_ROOT+region+"/art_contract.json"))
	if not previous_manifest is Dictionary or not previous_manifest.get("asset_sha256") is Dictionary or not previous_manifest.asset_sha256.has(path) or not _catalog_file(catalog,path) or catalog[path]!=previous_manifest.asset_sha256[path]: return "V5 current18 wall is not exact bound V4 source"
	var previous: ArrayMesh=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if previous==null or previous.get_surface_count()!=18 or mesh.get_surface_count()!=18: return "V5 current18 baseline missing"
	var measured: Variant=revision.get("current_v4_comparison")
	if not measured is Dictionary or measured.get("previous_manifest_path")!=V4_ROOT+region+"/art_contract.json" or measured.get("previous_manifest_sha256")!=V4_MANIFEST_SHAS[region] or measured.get("previous_mesh_path")!=path or measured.get("previous_mesh_sha256")!=catalog[path] or measured.get("actual_same_full_used_index_support_count_minY")!=true or measured.get("actual_all_vertex_y_z_unchanged")!=true or measured.get("horizontal_all_arrays_byte_exact")!=horizontal: return "V5 current baseline evidence incomplete"
	var rows: Variant=measured.get("actual_all_surface_comparisons")
	if not rows is Array or rows.size()!=18: return "V5 current all18 slot comparison missing"
	var detail: Variant=revision.get("v5_revision")
	if not detail is Dictionary or detail.get("identity")!=GEOMETRY_ID or detail.get("horizontal_geometry_changed")!=false or detail.get("vertical_geometry_changed")!=(not horizontal): return "V5 exact changed-surface identity missing"
	if not horizontal:
		if detail.get("not_material_only")!=true or not _json_exact(detail.get("modified_surface_indices"),[14,16]) or not _json_exact(detail.get("retained_support_surface_indices"),RETAINED) or detail.get("parent_upper_recipe_retained_as_input")!=true or detail.get("visual_approved")!=false or detail.get("production_approved")!=false: return "V5 vertical recipe scope differs"
		var shoulder: Variant=detail.get("upper_brick_shoulder")
		var eave: Variant=detail.get("curved_tile_eave")
		if not shoulder is Dictionary or not eave is Dictionary: return "V5 shoulder/eave recipe absent"
		for key: String in {"original_half_thickness_m":26.0/64.0/2.0,"maximum_outward_each_side_m":.12,"start_y_m":.90,"peak_y_m":1.38,"end_y_m":1.665}:
			var expected: Dictionary={"original_half_thickness_m":26.0/64.0/2.0,"maximum_outward_each_side_m":.12,"start_y_m":.90,"peak_y_m":1.38,"end_y_m":1.665}
			if not _num(shoulder.get(key),expected[key]): return "V5 exact shoulder parameter differs: "+key
		if not _num(eave.get("x_scale"),1.10) or eave.get("y_z_unchanged")!=true or eave.get("peak_height_unchanged")!=true: return "V5 exact eave parameter differs"
		var parent_rows: Variant=detail.get("actual_all_surface_slot_comparisons")
		if not parent_rows is Array or parent_rows.size()!=18: return "V5 adapter all18 comparison missing"
	for surface in range(18):
		var a: Array=previous.surface_get_arrays(surface)
		var b: Array=mesh.surface_get_arrays(surface)
		var row: Variant=rows[surface]
		if not row is Dictionary or not _num(row.get("surface_index"),surface) or not row.get("slots") is Array or row.slots.size()!=Mesh.ARRAY_MAX or previous.surface_get_primitive_type(surface)!=mesh.surface_get_primitive_type(surface) or not a[Mesh.ARRAY_VERTEX] is PackedVector3Array or not b[Mesh.ARRAY_VERTEX] is PackedVector3Array or a[Mesh.ARRAY_VERTEX].size()!=b[Mesh.ARRAY_VERTEX].size(): return "V5 current primitive/vertex domain changed"
		for slot in range(Mesh.ARRAY_MAX):
			var exact: bool=var_to_bytes(a[slot])==var_to_bytes(b[slot])
			if not exact and (horizontal or surface not in [14,16] or slot not in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT]): return "V5 altered forbidden current V4 slot"
			var evidence: Variant=row.slots[slot]
			if not evidence is Dictionary or not _num(evidence.get("slot"),slot) or evidence.get("previous_sha256")!=_sha(var_to_bytes(a[slot])) or evidence.get("actual_sha256")!=_sha(var_to_bytes(b[slot])) or evidence.get("byte_exact")!=exact: return "V5 current slot evidence differs from stored bytes"
			if not horizontal:
				var parent: Variant=detail.actual_all_surface_slot_comparisons[surface]
				if not parent is Dictionary or not _num(parent.get("surface_index"),surface) or parent.get("same_primitive")!=true or not _num(parent.get("parent_vertex_count"),a[Mesh.ARRAY_VERTEX].size()) or not _num(parent.get("actual_vertex_count"),b[Mesh.ARRAY_VERTEX].size()) or not parent.get("slots") is Array or parent.slots.size()!=Mesh.ARRAY_MAX: return "V5 adapter current surface evidence malformed"
				var cell: Variant=parent.slots[slot]
				if not cell is Dictionary or not _num(cell.get("slot"),slot) or cell.get("parent_sha256")!=_sha(var_to_bytes(a[slot])) or cell.get("actual_sha256")!=_sha(var_to_bytes(b[slot])) or cell.get("byte_exact")!=exact: return "V5 adapter comparison is not actual current V4"
		var av: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
		var bv: PackedVector3Array=b[Mesh.ARRAY_VERTEX]
		for vertex in range(av.size()):
			if av[vertex].y!=bv[vertex].y or av[vertex].z!=bv[vertex].z: return "V5 changed height/along-axis"
	var old_bounds: Dictionary=_used_bounds(previous)
	var bounds: Dictionary=_used_bounds(mesh)
	if old_bounds.is_empty() or bounds.is_empty(): return "V5 current used-index bounds unavailable"
	for key: String in ["support","support_count","actual_used_vertices"]:
		if var_to_bytes(old_bounds[key])!=var_to_bytes(bounds[key]): return "V5 current full used-index support/count changed"
	if old_bounds.minimum.y!=bounds.minimum.y or old_bounds.maximum.y!=bounds.maximum.y: return "V5 current height extrema changed"
	return ""

static func _v5_control_relocate(arrays: Array, surface: int) -> bool:
	# Independent mathematical oracle, operating on native-packed V4 controls.
	# No call to the V5 adapter/capture. INDEX/UV/colour and tangent.w are retained.
	if not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array or not arrays[Mesh.ARRAY_NORMAL] is PackedVector3Array: return false
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var draw:=PackedInt32Array()
	if arrays[Mesh.ARRAY_INDEX]==null:
		for vertex in range(vertices.size()): draw.append(vertex)
	elif arrays[Mesh.ARRAY_INDEX] is PackedInt32Array: draw=arrays[Mesh.ARRAY_INDEX]
	else: return false
	if draw.is_empty() or draw.size()%3!=0: return false
	for vertex in range(vertices.size()):
		var point: Vector3=vertices[vertex]
		if not point.is_finite() or point.y<=.246: return false
		if surface==0: point.x+=signf(point.x)*.12*smoothstep(.90,1.38,point.y)*(1.0-smoothstep(1.38,1.665,point.y))
		elif surface==2: point.x*=1.10
		else: return false
		vertices[vertex]=point
	var normals:=PackedVector3Array()
	normals.resize(vertices.size())
	for offset in range(0,draw.size(),3):
		var a: int=draw[offset]
		var b: int=draw[offset+1]
		var c: int=draw[offset+2]
		if mini(a,mini(b,c))<0 or maxi(a,maxi(b,c))>=vertices.size(): return false
		var normal: Vector3=-(vertices[b]-vertices[a]).cross(vertices[c]-vertices[a])
		if not normal.is_finite() or normal.length_squared()<=.000000000001: return false
		normals[a]+=normal; normals[b]+=normal; normals[c]+=normal
	for vertex in range(normals.size()):
		if not normals[vertex].is_finite() or normals[vertex].length_squared()<=.000000000001: return false
		normals[vertex]=normals[vertex].normalized()
	if arrays[Mesh.ARRAY_TANGENT]!=null:
		if not arrays[Mesh.ARRAY_TANGENT] is PackedFloat32Array: return false
		var tangents: PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT]
		if tangents.size()!=vertices.size()*4: return false
		for vertex in range(vertices.size()):
			var tangent:=Vector3(tangents[vertex*4],tangents[vertex*4+1],tangents[vertex*4+2])
			tangent-=normals[vertex]*tangent.dot(normals[vertex])
			if not tangent.is_finite() or tangent.length_squared()<=.000000000001: return false
			tangent=tangent.normalized()
			tangents[vertex*4]=tangent.x; tangents[vertex*4+1]=tangent.y; tangents[vertex*4+2]=tangent.z
		arrays[Mesh.ARRAY_TANGENT]=tangents
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	return true

static func _zone_paving_replacements() -> Array:
	var declaration: String="""uniform float zone_finish_identity=1.;
uniform float zone_court_profile=0.;
uniform vec4 zone_avenue_bounds=vec4(-2.75,-16.375,2.75,28.625);
uniform vec4 zone_court_bounds=vec4(-8.375,-8.875,8.34375,19.25);
float zone_soft_rect(vec2 q,vec4 bounds,float feather){
 float edge=min(min(q.x-bounds.x,bounds.z-q.x),min(q.y-bounds.y,bounds.w-q.y));
 return smoothstep(-feather,feather,edge);
}
void fragment(){"""
	return [
		["void fragment(){",declaration],
		["float traffic=1.-smoothstep(.90,2.10,route_d);","float traffic=1.-smoothstep(.90,2.10,route_d);\n float avenue=zone_soft_rect(p.xz,zone_avenue_bounds,.90);\n float court=zone_court_profile*zone_soft_rect(p.xz,zone_court_bounds,1.20);"],
		["vec3 finish=mix(vec3(.76,.765,.755),vec3(.92,.91,.865),traffic);","vec3 finish=mix(vec3(.745,.75,.735),vec3(.985,.975,.925),traffic);\n finish=mix(finish,vec3(1.015,1.005,.955),avenue*.40);\n finish=mix(finish,vec3(.975,.975,.95),court*.68);"],
		["finish=mix(finish,vec3(.94,.925,.87),apron*.72);","finish=mix(finish,vec3(1.005,.965,.875),apron*.78*(1.-court*.65));"],
		["finish=mix(finish,vec3(.56,.60,.60),wet*.42);","finish=mix(finish,vec3(.49,.555,.545),wet*.50);"],
		["finish*=.97+(broad-.5)*.11;","finish*=.98+(broad-.5)*mix(.09,.035,court);"],
		["face=mix(face,dust,verge*.24+contact*.10);","face=mix(face,dust,(verge*.24*(1.-court*.72)+contact*.10)*(1.-avenue*.28));"],
		["ALBEDO=face*COLOR.rgb*native_flagstone_identity;","ALBEDO=face*COLOR.rgb*native_flagstone_identity*zone_finish_identity;"],
		["ROUGHNESS=clamp(.91-traffic*.21-wet*.17+verge*.025+(arm.g-.5)*.035,.62,.97);","ROUGHNESS=clamp(.92-traffic*.23-avenue*.055-court*.035-wet*.19+verge*.025+(arm.g-.5)*.035,.60,.97);"]]

static func _paving_code(base: String) -> String:
	var code: String=_v4_paving_code(base)
	for pair: Array in _zone_paving_replacements():
		if code.count(String(pair[0]))!=1: return ""
		code=code.replace(String(pair[0]),String(pair[1]))
	return code

static func _zone_records_error(binding: Dictionary,final_code: String,region: String,old_prefix: String,objects: Array) -> String:
	var records: Variant=binding.get("actual_zone_material_records")
	if not records is Array or records.is_empty(): return "V5 final Zone material records absent"
	var wall_kinds: Dictionary={}
	for object: Variant in objects:
		if not object is Dictionary: return "V5 final material object identity malformed"
		if object.get("prototype") in ["wall_horizontal","wall_vertical"]: wall_kinds[object.prototype]=true
	var final_masonry: String=""
	if not wall_kinds.is_empty():
		var first_kind: String=String(wall_kinds.keys()[0])
		var old_wall: ArrayMesh=ResourceLoader.load(old_prefix+"entities/native_"+first_kind+".res","",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
		if old_wall==null: return "V5 independent original masonry unavailable"
		var old_material: ShaderMaterial=old_wall.surface_get_material(0) as ShaderMaterial
		if old_material==null or old_material.shader==null: return "V5 independent original masonry shader unavailable"
		final_masonry=_masonry_code(old_material.shader.code,false)
	var original_masonry: String=final_masonry.replace("vec3 brick=vec3(.365,.36,.345)*(.58+luma*.85)+(stone-vec3(luma))*.13;","vec3 brick=vec3(.34,.355,.365)*(.58+luma*.85)+(stone-vec3(luma))*.13;")
	var parent_paving: String=final_code
	# Reconstruct parent code by reversing exactly the independently fixed edits.
	var pairs: Array=_zone_paving_replacements()
	for offset in range(pairs.size()-1,-1,-1): parent_paving=parent_paving.replace(String(pairs[offset][1]),String(pairs[offset][0]))
	var expected_pins: Dictionary={
		"res://scripts/dev/luoyang_modular_v3_wall_street_surface_proposal.gd":PINS["res://scripts/dev/luoyang_modular_v3_wall_street_surface_proposal.gd"],
		OLD_STREET_SURFACE:OLD_STREET_SURFACE_SHA,
		"res://scripts/dev/luoyang_modular_v3_source.gd":"3a6f96cd823eb5e3f6d3b4fb1801d5e90342ed020ab293d3a578ccac048dbad5",
		"res://scripts/dev/build_luoyang_modular_v3.gd":"3a7fa038d977c3671eeeda1dabaf8cd6c5e20807964b89eaee09ae0091950a30"}
	var expected_ownership: Dictionary={"main_street_px":[1360,500,1712,1940],"yamen_court_px":[1000,740,2070,1640],"soft_edges_m":[.90,1.20],"apron_and_contact":"unchanged parent actual polygons/route segments","quay_x_px":2230,"court_enabled":region=="ch4_s1_luoyang_yamen","COLOR_a_palette_used":false}
	var found: Dictionary={}
	for row: Variant in records:
		if not row is Dictionary or row.get("material_identity")!=MATERIAL_ID or not row.get("candidate_script") is Dictionary or row.candidate_script.get("path")!=SURFACE or row.candidate_script.get("sha256")!=PINS[SURFACE] or not _json_exact(row.get("exact_source_pins"),expected_pins) or not _json_exact(row.get("ownership"),expected_ownership) or row.get("visual_approved")!=false or row.get("production_approved")!=false: return "V5 final Zone source/ownership/scope differs"
		var paving: bool=row.get("role")=="continuous_avenue_apron_court_quay_material_only"
		if not paving and (row.get("role")!="warm_grey_brick_same_white_lime_dark_base_cap" or wall_kinds.is_empty()): return "Unknown/unowned V5 Zone patch role"
		var expected: Array=pairs if paving else [["vec3 brick=vec3(.34,.355,.365)*(.58+luma*.85)+(stone-vec3(luma))*.13;"]]
		var patch: Variant=row.get("patch_evidence")
		if not patch is Dictionary or patch.get("passed")!=true or patch.get("inherited_parameters_and_actual_sampler_objects_unchanged")!=true or not _num(patch.get("retained_uniform_count"),13 if paving else 5) or patch.get("parent_shader_code_sha256")!=_sha((parent_paving if paving else original_masonry).to_utf8_buffer()) or row.get("actual_final_shader_code_sha256")!=_sha((final_code if paving else final_masonry).to_utf8_buffer()): return "V5 final Zone code/retained sampler evidence differs"
		var anchors: Variant=patch.get("anchors")
		if not anchors is Array or anchors.size()!=expected.size(): return "V5 Zone complete unique-anchor proof missing"
		for index in range(expected.size()):
			var cell: Variant=anchors[index]
			if not cell is Dictionary or cell.get("anchor")!=expected[index][0] or not _num(cell.get("actual_count"),1) or not _num(cell.get("required_count"),1): return "V5 Zone exact unique anchor differs"
		found[row.role]=true
	return "" if found.has("continuous_avenue_apron_court_quay_material_only") and (wall_kinds.is_empty() or found.has("warm_grey_brick_same_white_lime_dark_base_cap")) else "V5 final paving/actual-wall patch role missing"

