extends RefCounted
## Full-source runtime bundle. Geometry/material proof is made at publication,
## never described as freshly rerun here. No cross-token/session cache.
const SELF="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const INDEX="res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd"
const ROOT="res://data/maps/luoyang_layout_bundle_20261018t_retry2/"
const T_META="luoyang_layout_quest_20261018t"
const T_BASIS="PARENT_PUBLISHED_PLUS_T_LAYOUT_PROOF"
const UNCHANGED_BASIS="UNCHANGED_PARENT_NATIVE_ARTIFACT_EXPLICIT_SOURCE_SUCCESSION"
const ROOM_ROOT="res://data/maps/luoyang_layout_rooms_20261018t/"
const ROOM_INDEX="res://scripts/city/luoyang_layout_room_index_20261018t.gd"
const AA_PACKET_SHA="69da39b21c56d4598dd4e5e8d3b9cfd9912823ee4c8c8c3cc0ad99f77e03aa1e"
const AD_INDEX="res://scripts/city/luoyang_docks_roles_index_20261019ad.gd"
const AE_INDEX="res://scripts/city/luoyang_docks_shore_index_20261020ae.gd"
const MG_INDEX="res://scripts/city/luoyang_market_ground_index_20261020ae.gd"
const ESTATE_INDEX="res://scripts/city/luoyang_estate_index_20261021am.gd"
const AO_INDEX="res://scripts/city/luoyang_market_two_shops_index_20261021ao.gd"
const AO_ROOT="res://data/maps/luoyang_market_two_shops_20261021ao/runtime/"
const AO_PACKET_SHA="3d4d0b327ca8aeed9e020738a9d59540e3ad82e47331ab4e3d465cf2822f60ba"
const AP_INDEX="res://scripts/city/luoyang_full_city_index_20261022ap.gd"
const AP_ENV_INDEX="res://scripts/city/luoyang_environment_index_20261022ap.gd"
const AP_EXEC_INDEX="res://scripts/city/luoyang_execution_index_20261022ap.gd"
const AP_QUARTER_INDEX="res://scripts/city/luoyang_quarters_index_20261022ap.gd"
const AP_ROOT="res://data/maps/luoyang_full_city_20261022ap/market/"
static func _ap() -> Variant: return load("res://build/luoyang_city_full_rollout_20261022ap_system01/market_execution_retry3/market_transform.gd")
static func _ap_requested(id: StringName) -> bool:
	return id==&"ch4_s3_luoyang_market" and FileAccess.file_exists(AP_INDEX) and load(AP_INDEX).formal_enabled()==true
static func _ap_entry(id: StringName) -> Dictionary:
	if not _ap_requested(id): return {}
	var entry: Dictionary=load(AP_INDEX).market_entry()
	return entry if entry.size()==2 and entry.get("manifest_path")==AP_ROOT+String(id)+"/manifest.json" and _hash(entry.get("manifest_sha256")) else {}
static func _ao(id: StringName) -> Variant:
	return load("res://build/luoyang_market_two_shops_20261021ao_system01/two_shops_READY.gd") if id==&"ch4_s3_luoyang_market" else null
static func _ao_requested(id: StringName) -> bool:
	if id!=&"ch4_s3_luoyang_market" or OS.has_feature("web") or forced_authoring() or not FileAccess.file_exists(AO_INDEX): return false
	var authority: Variant=load(AO_INDEX)
	return authority is GDScript and authority.resource_path==AO_INDEX and authority.formal_enabled()==true
static func _ao_entry(id: StringName) -> Dictionary:
	if not _ao_requested(id): return {}
	var authority: Variant=load(AO_INDEX)
	var value: Dictionary=authority.entry()
	return value if value.size()==2 and value.get("manifest_path")==AO_ROOT+String(id)+"/manifest.json" and _hash(value.get("manifest_sha256")) else {}
static func _estate() -> Variant: return load("res://scripts/city/luoyang_estate_family_20261021am.gd")
static func _ae(id: StringName) -> Variant:
	return load("res://scripts/city/luoyang_docks_shore_20261020ae.gd") if id==&"ch4_s2_canal_docks" else null
static func _market_ground(id: StringName) -> Variant:
	return load("res://scripts/city/luoyang_market_ground_20261020ae.gd") if id==&"ch4_s3_luoyang_market" else null
static func _ad(id: StringName) -> Variant:
	return load("res://scripts/city/luoyang_docks_roles_20261019ad.gd") if id==&"ch4_s2_canal_docks" else null
const AC_INDEX="res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd"
const AC_ROOT="res://data/maps/luoyang_docks_workyard_20261019ac/runtime/"
const AC_FLAG="--luoyang-docks-workyard-20261019ac"
const AC_PACKET_SHA="1cb6bbf9825d538c982fcdf1171c5f3e268854be54796c3684c91502da14f221"
static func _ac(id: StringName) -> Variant:
	return load("res://scripts/city/luoyang_docks_workyard_20261019ac.gd") if id==&"ch4_s2_canal_docks" else null
static func _ac_requested(id: StringName) -> bool:
	if id!=&"ch4_s2_canal_docks" or OS.has_feature("web") or forced_authoring(): return false
	if AC_FLAG in OS.get_cmdline_user_args(): return true
	var authority: Variant=load(AC_INDEX)
	return authority is GDScript and authority.resource_path==AC_INDEX and authority.formal_enabled()==true
static func _ac_entry(id: StringName) -> Dictionary:
	if not _ac_requested(id): return {}
	var authority: Variant=load(AC_INDEX)
	if not authority is GDScript or authority.resource_path!=AC_INDEX: return {}
	var value: Dictionary=authority.entry()
	return value if value.size()==2 and value.get("manifest_path")==AC_ROOT+String(id)+"/manifest.json" and _hash(value.get("manifest_sha256")) else {}
static func _aa(id: StringName) -> Variant:
	return load("res://scripts/city/luoyang_docks_district08_20261019aa.gd") if id==&"ch4_s2_canal_docks" else null
static func _aa_requested(id: StringName) -> bool:
	return id==&"ch4_s2_canal_docks" and _aa(id).requested(id)
static func _root(id: StringName) -> String:
	if _ap_requested(id): return AP_ROOT
	return AO_ROOT if _ao_requested(id) else (AC_ROOT if _ac_requested(id) else (String(_aa(id).ROOT) if _aa_requested(id) else ROOT))
static var _scene_sessions: Dictionary={}
const KIND="PRECOMPUTED_PUBLISHED_FULL_SOURCE_V1"
const FLAG="--luoyang-precomputed-bundle-20261018r"
const FORCE_AUTHORING="--luoyang-force-authoring-20261018r"
const FORMAL_ENABLED=false
const IDS=[&"ch4_s0_luoyang_gate",&"ch4_s3_luoyang_market",&"ch4_s2_canal_docks",&"ch4_s1_luoyang_yamen"]
const SIZE=Vector2i(3072,2048)
const SCENE_SCRIPT="res://scripts/domain/scene_script.gd"
const LAYOUT_SCRIPT="res://scripts/domain/walkable_map_layout.gd"
const DIALOG_SCRIPT="res://scripts/domain/dialog_script.gd"
const DIALOG_NODE_SCRIPT="res://scripts/domain/dialog_node.gd"
const YAMEN_DIALOG="res://data/dialogs/ch4_yamen_intro.tres"
const RESOURCE_SOURCES=[YAMEN_DIALOG,DIALOG_SCRIPT,DIALOG_NODE_SCRIPT]
const MAX_PACKET_BYTES=128*1024*1024
var _token: int=0
var _id: StringName=&""
var _manifest: Dictionary={}
var _data: Dictionary={}
var _error: String=""
var _cancelled: bool=false
var _joined: bool=false
var _mutex:=Mutex.new()
static func supported(id: StringName) -> bool: return id in IDS
static func forced_authoring() -> bool: return FORCE_AUTHORING in OS.get_cmdline_user_args()
static func requested(id: StringName) -> bool:
	if not supported(id) or OS.has_feature("web") or forced_authoring(): return false
	if FLAG in OS.get_cmdline_user_args(): return true
	# The compiler freezes this helper in legacy input sources. Formal activation
	# therefore lives in the NEW generated code-authority leaf, not a helper flip.
	if not FileAccess.file_exists(INDEX): return false
	var index: Variant=load(INDEX)
	if not index is GDScript or index.resource_path!=INDEX: return false
	for method: Dictionary in index.get_script_method_list():
		if method.name=="formal_enabled": return index.formal_enabled()==true
	return false
static func _hash(value: Variant) -> bool:
	if not value is String or value.length()!=64: return false
	for c: String in value:
		if c not in "0123456789abcdef": return false
	return true
static func _plain(value: Variant) -> bool:
	if value is Object: return false
	if value is Dictionary:
		for key: Variant in value:
			if not _plain(key) or not _plain(value[key]): return false
	elif value is Array:
		for item: Variant in value:
			if not _plain(item): return false
	return true
static func equal(left: Variant,right: Variant) -> bool:
	if typeof(left)!=typeof(right): return false
	if left is Dictionary:
		if left.size()!=right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not equal(left[key],right[key]): return false
		return true
	if left is Array:
		if left.size()!=right.size(): return false
		for i: int in left.size():
			if not equal(left[i],right[i]): return false
		return true
	return left==right
static func bytes_sha(bytes: PackedByteArray) -> String:
	var digest:=HashingContext.new(); digest.start(HashingContext.HASH_SHA256); digest.update(bytes)
	return digest.finish().hex_encode()
static func storage(resource: Resource) -> Dictionary:
	# Root path/layout are independently bound by materialize. Every nested
	# Dialog Resource retains its real path, fixed script, class and full storage.
	# This is a comparison snapshot, never instructions to construct Objects.
	if resource==null: return {}
	var graph: Dictionary={"seen":{},"resources":[],"invalid":null}
	var script_path: String=_storage_script(resource)
	if script_path not in [SCENE_SCRIPT,LAYOUT_SCRIPT,DIALOG_SCRIPT,DIALOG_NODE_SCRIPT]: return {"unsupported":resource}
	var fields: Dictionary=_storage_fields(resource,graph,true)
	if graph.invalid!=null: return {"unsupported":graph.invalid}
	return {"schema":"FIXED_DIALOG_STORAGE_GRAPH_V1","root_class":resource.get_class(),"root_script":script_path,"fields":fields,"resources":graph.resources}
static func _storage_script(resource: Resource) -> String:
	var script: Variant=resource.get_script()
	return script.resource_path if script is GDScript else ""
static func _storage_shape(value: Dictionary,script_path: String) -> bool:
	return value.size()==5 and value.get("schema")=="FIXED_DIALOG_STORAGE_GRAPH_V1" and value.get("root_class")=="Resource" and value.get("root_script")==script_path and value.get("fields") is Dictionary and value.get("resources") is Array
static func _storage_fields(resource: Resource,graph: Dictionary,root: bool) -> Dictionary:
	var fields: Dictionary={}
	for property: Dictionary in resource.get_property_list():
		var key: String=String(property.name)
		if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or key=="script" or (root and key=="map_layout"): continue
		fields[key]=_storage_value(resource.get(key),graph)
	return fields
static func _storage_value(value: Variant,graph: Dictionary) -> Variant:
	if value is Resource:
		var script_path: String=_storage_script(value)
		if script_path not in [DIALOG_SCRIPT,DIALOG_NODE_SCRIPT]:
			graph.invalid=value; return null
		var identity: int=value.get_instance_id()
		if graph.seen.has(identity): return {"resource_ref":graph.seen[identity]}
		var ordinal: int=graph.resources.size()
		graph.seen[identity]=ordinal
		graph.resources.append({})
		var fields: Dictionary=_storage_fields(value,graph,false)
		graph.resources[ordinal]={"class":value.get_class(),"script_path":script_path,"resource_path":value.resource_path,"fields":fields}
		return {"resource_ref":ordinal}
	if value is Object:
		graph.invalid=value; return null
	if value is Array:
		var typed_script: Variant=value.get_typed_script()
		var script_path: String=""
		if typed_script!=null:
			if not typed_script is GDScript or typed_script.resource_path not in [DIALOG_SCRIPT,DIALOG_NODE_SCRIPT]:
				graph.invalid=typed_script; return null
			script_path=typed_script.resource_path
		var elements: Array=[]
		for element: Variant in value: elements.append(_storage_value(element,graph))
		return {"array_values":elements,"typed_builtin":value.get_typed_builtin(),"typed_class_name":value.get_typed_class_name(),"typed_script_path":script_path}
	if value is Dictionary:
		var result: Dictionary={}
		for key: Variant in value:
			if not _plain(key): graph.invalid=key; return {}
			result[key]=_storage_value(value[key],graph)
		return result
	return value
static func _entry(id: StringName) -> Dictionary:
	if not supported(id): return {}
	if _ap_requested(id): return _ap_entry(id)
	if _ao_requested(id): return _ao_entry(id)
	if _ac_requested(id): return _ac_entry(id)
	if _aa_requested(id): return _aa(id).entry()
	if not FileAccess.file_exists(INDEX): return {}
	var index: Variant=load(INDEX)
	if not index is GDScript or index.resource_path!=INDEX: return {}
	var entry_methods: int=0
	for method: Dictionary in index.get_script_method_list():
		if method.name=="entries": entry_methods+=1
	if entry_methods!=1: return {}
	var entries: Dictionary=index.entries()
	var entry: Dictionary=entries.get(String(id),{})
	if entry.size()!=2 or entry.get("manifest_path")!=_root(id)+String(id)+"/manifest.json" or not _hash(entry.get("manifest_sha256")): return {}
	return entry
static func manifest(id: StringName) -> Dictionary:
	var entry: Dictionary=_entry(id)
	if entry.is_empty() or FileAccess.get_sha256(entry.manifest_path)!=entry.manifest_sha256: return {}
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(entry.manifest_path))
	if id==&"ch4_s2_canal_docks" and _aa(id).author().is_empty(): return {}
	if not raw is Dictionary or raw.get("kind")!=KIND or raw.get("scene_id")!=String(id) or raw.get("publication_full_source_finalized")!=true: return {}
	var aa_basis: bool=_aa_requested(id) and raw.get("geometry_proof_basis")==_aa(id).BASIS
	var ac_basis: bool=_ac_requested(id) and raw.get("geometry_proof_basis")==_ac(id).BASIS
	var ao_basis: bool=_ao_requested(id) and raw.get("geometry_proof_basis")==_ao(id).BASIS
	var ap_basis: bool=_ap_requested(id) and raw.get("geometry_proof_basis")==_ap().BASIS
	if ap_basis:
		if raw.get("author_path")!=_ap().AUTHOR or raw.get("author_sha256")!=FileAccess.get_sha256(_ap().AUTHOR) or _ap().author().is_empty() or raw.get("ap_two_whole_frontages_and_three_room_relocations")!=true: return {}
	elif ao_basis:
		var ao: Variant=_ao(id)
		if raw.get("author_path")!=ao.AUTHOR or raw.get("author_sha256")!=ao.AUTHOR_SHA or ao.author().is_empty() or raw.get("ao_exact_two_for_two")!=true: return {}
	elif ac_basis:
		var ac: Variant=_ac(id)
		if not raw.get("author_path") is String or not raw.get("author_sha256") is String or raw.author_path!=ac.AUTHOR or raw.author_sha256!=ac.AUTHOR_SHA or ac.author().is_empty() or raw.get("ac_exact_add_four")!=true: return {}
	elif aa_basis:
		var aa: Variant=_aa(id)
		if raw.get("author_path")!=aa.AUTHOR or raw.get("author_sha256")!=aa.AUTHOR_SHA or aa.author().is_empty() or raw.get("aa_exact_remove_two",false)!=true: return {}
	elif raw.get("geometry_proof_basis") not in [T_BASIS,UNCHANGED_BASIS]: return {}
	if not raw.get("legacy_source_sha256") is Dictionary or raw.legacy_source_sha256.is_empty(): return {}
	if raw.get("layout_proof",{}).get("passed")!=true or not raw.get("runtime_authority_sha256") is Dictionary: return {}
	for path: String in raw.runtime_authority_sha256:
		if path in [AP_INDEX,AP_ENV_INDEX,AP_EXEC_INDEX,AP_QUARTER_INDEX]: return {}
		if (id==&"ch4_s2_canal_docks" and path==AE_INDEX) or (id==&"ch4_s3_luoyang_market" and path==MG_INDEX): return {}
		if path==AO_INDEX or path==AO_INDEX or path==ESTATE_INDEX or path==INDEX or path==AC_INDEX or (id==&"ch4_s2_canal_docks" and path==AD_INDEX) or (id==&"ch4_s2_canal_docks" and path==_aa(id).INDEX): return {}
		if not (path.begins_with(ROOM_ROOT) or path.begins_with(ROOT) or ((aa_basis or ac_basis) and path.begins_with(_aa(id).ROOT)) or (ac_basis and path.begins_with(AC_ROOT)) or (ao_basis and path.begins_with(AO_ROOT)) or (ap_basis and path.begins_with(AP_ROOT)) or path==ROOM_INDEX) or ".." in path or not _hash(raw.runtime_authority_sha256[path]): return {}
	var artifacts: Variant=raw.get("artifacts")
	if not artifacts is Dictionary or artifacts.size()!=3: return {}
	for suffix: String in ["scene.res","layout.res","packet.bin"]:
		var path: String=_root(id)+String(id)+"/"+suffix
		if not artifacts.has(path) or not _hash(artifacts[path]): return {}
	for path: Variant in raw.legacy_source_sha256:
		if path in [AP_INDEX,AP_ENV_INDEX,AP_EXEC_INDEX,AP_QUARTER_INDEX]: return {}
		if (id==&"ch4_s2_canal_docks" and path==AE_INDEX) or (id==&"ch4_s3_luoyang_market" and path==MG_INDEX): return {}
		if not path is String or not path.begins_with("res://") or ".." in path or not _hash(raw.legacy_source_sha256[path]) or path==ESTATE_INDEX or path==INDEX or path==AC_INDEX or (id==&"ch4_s2_canal_docks" and path==AD_INDEX) or (id==&"ch4_s2_canal_docks" and path==_aa(id).INDEX) or path.begins_with(ROOT): return {}
	if not raw.legacy_source_sha256.has(SELF) or not raw.legacy_source_sha256.has("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"): return {}
	return raw
static func source_paths(id: StringName) -> Dictionary:
	var paths: Dictionary={SELF:true}
	var env: Variant=load("res://scripts/city/luoyang_environment_layer_20261022ap.gd")
	var executable: Variant=load("res://scripts/city/luoyang_execution_authority_20261022ap.gd")
	var npc: Variant=load("res://build/luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd")
	var people: Variant=load("res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people_execution.gd")
	var env_paths: Dictionary=env.source_paths_for(id);var execution_paths: Dictionary=executable.source_paths();var npc_paths: Dictionary=npc.source_paths()
	var people_paths: Dictionary=people.source_paths()
	if env_paths.is_empty() or execution_paths.is_empty() or npc_paths.is_empty() or people_paths.is_empty(): return {}
	paths.merge(env_paths);paths.merge(execution_paths);paths.merge(npc_paths);paths.merge(people_paths)
	for index_path: String in [AP_INDEX,AP_ENV_INDEX,AP_EXEC_INDEX,AP_QUARTER_INDEX]: paths[index_path]=true
	if id==&"ch4_s2_canal_docks":
		paths.merge(_aa(id).source_paths());paths.merge(_ac(id).source_paths());paths[AC_INDEX]=true
		paths.merge(_ad(id).source_paths());paths[AD_INDEX]=true
		paths.merge(_ae(id).source_paths());paths[AE_INDEX]=true
	if id==&"ch4_s3_luoyang_market":
		paths.merge(_market_ground(id).source_paths());paths[MG_INDEX]=true
	if id==&"ch4_s1_luoyang_yamen":
		for path: String in RESOURCE_SOURCES: paths[path]=true
	# Collection is not runtime activation: an admitted disabled manifest still
	# owns its complete source closure. Missing disabled/authoring manifests
	# retain only the original base collector, never authorize bundle parsing.
	var config: Dictionary=manifest(id)
	if config.is_empty(): return paths if not requested(id) else {}
	for path: String in config.legacy_source_sha256: paths[path]=true
	for path: String in config.runtime_authority_sha256: paths[path]=true
	# G already owns shared room sources; keep its new family index outside
	# pinned manifests. Lazy load avoids B/family preload recursion.
	if id==&"ch4_s3_luoyang_market":
		paths.merge(_estate().source_paths())
		var quarters: Variant=load("res://scripts/city/luoyang_quarters_family_20261022ap.gd")
		var quarter_paths: Dictionary=quarters.source_paths()
		if quarter_paths.is_empty(): return {}
		paths.merge(quarter_paths)
	paths[ESTATE_INDEX]=true;paths[AO_INDEX]=true
	paths[INDEX]=true; paths[_root(id)+String(id)+"/manifest.json"]=true
	for path: String in config.artifacts: paths[path]=true
	return paths
static func describe(id: StringName,sources: Dictionary) -> Dictionary:
	var config: Dictionary=manifest(id)
	if config.is_empty(): return {}
	var expected: Dictionary=config.legacy_source_sha256.duplicate(true)
	expected.merge(config.runtime_authority_sha256)
	expected.merge(config.artifacts)
	expected[INDEX]=FileAccess.get_sha256(INDEX)
	expected[ESTATE_INDEX]=FileAccess.get_sha256(ESTATE_INDEX)
	expected[AO_INDEX]=FileAccess.get_sha256(AO_INDEX)
	for index_path: String in [AP_INDEX,AP_ENV_INDEX,AP_EXEC_INDEX,AP_QUARTER_INDEX]: expected[index_path]=FileAccess.get_sha256(index_path)
	if id==&"ch4_s2_canal_docks":
		expected[_aa(id).INDEX]=FileAccess.get_sha256(_aa(id).INDEX);expected[AC_INDEX]=FileAccess.get_sha256(AC_INDEX)
		expected[AD_INDEX]=FileAccess.get_sha256(AD_INDEX)
		expected[AE_INDEX]=FileAccess.get_sha256(AE_INDEX)
	if id==&"ch4_s3_luoyang_market": expected[MG_INDEX]=FileAccess.get_sha256(MG_INDEX)
	var entry: Dictionary=_entry(id)
	expected[entry.manifest_path]=entry.manifest_sha256
	return config if equal(sources,expected) else {}
func configure(token: int,id: StringName,sources: Dictionary) -> bool:
	if token<=0 or _token!=0 or get_script().resource_path!=SELF or not requested(id): return false
	_manifest=describe(id,sources)
	if _manifest.is_empty(): _error="Bundle manifest/artifact/current complete legacy source set differs"; return false
	_token=token; _id=id; return true
func request_cancel() -> void:
	_mutex.lock(); _cancelled=true; _mutex.unlock()
func _is_cancelled() -> bool:
	_mutex.lock(); var value: bool=_cancelled; _mutex.unlock(); return value
func _reject(message: String) -> void: _error=message; _data.clear()
func run() -> void:
	var path: String=_root(_id)+String(_id)+"/packet.bin"
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null: _reject("Bundle native packet unavailable"); return
	var length: int=file.get_length()
	if length<=0 or length>MAX_PACKET_BYTES: file.close(); _reject("Bundle packet size outside fixed bound"); return
	var bytes:=PackedByteArray(); var digest:=HashingContext.new(); digest.start(HashingContext.HASH_SHA256)
	while file.get_position()<length:
		if _is_cancelled(): file.close(); _reject("Bundle packet cancelled"); return
		var count: int=mini(1024*1024,length-file.get_position())
		var chunk: PackedByteArray=file.get_buffer(count)
		if chunk.size()!=count or file.get_error() not in [OK,ERR_FILE_EOF]: file.close(); _reject("Bundle packet short/error read"); return
		digest.update(chunk); bytes.append_array(chunk)
	var stable: bool=file.get_length()==length and file.get_position()==length
	file.close()
	if _is_cancelled() or not stable or digest.finish().hex_encode()!=_manifest.artifacts[path]: _reject("Bundle packet bytes changed/cancelled"); return
	var parsed: Variant=bytes_to_var(bytes) # Object decoding deliberately disabled.
	bytes.clear()
	if _is_cancelled() or not parsed is Dictionary or not _plain(parsed): _reject("Bundle native packet malformed/cancelled"); return
	var data: Dictionary=parsed
	if data.get("geometry_basis")!=_manifest.get("geometry_proof_basis"): _reject("Successor geometry basis differs"); return
	if data.get("kind")!=KIND or data.get("scene_id")!=String(_id) or not data.get("record") is Dictionary or data.record.get("canonical_scene_id")!=String(_id): _reject("Bundle native packet city identity differs"); return
	if data.get("size")!=SIZE or not data.get("walk_bytes") is PackedByteArray or data.walk_bytes.size()!=SIZE.x*SIZE.y*4 or bytes_sha(data.walk_bytes)!=data.get("mask_sha"): _reject("Bundle mask size/full RGBA bytes differ"); return
	if not data.get("solids") is Array or not data.get("scene_storage") is Dictionary or not data.get("layout_storage") is Dictionary or not data.get("input_storage") is Dictionary or not data.get("input_layout_storage") is Dictionary: _reject("Bundle complete native storage missing"); return
	if not _storage_shape(data.scene_storage,SCENE_SCRIPT) or not _storage_shape(data.input_storage,SCENE_SCRIPT) or not _storage_shape(data.layout_storage,LAYOUT_SCRIPT) or not _storage_shape(data.input_layout_storage,LAYOUT_SCRIPT): _reject("Bundle safe storage graph identity differs"); return
	if data.get("scene_script")!=SCENE_SCRIPT or data.get("layout_script")!=LAYOUT_SCRIPT or data.layout_storage.fields.get("schema_version")!=3 or data.layout_storage.fields.get("walkable_mask_path")!=data.record.get("walk_path"): _reject("Bundle native scripts/layout/walk identity differs"); return
	if not _hash(data.get("mask_sha")) or data.mask_sha!=_manifest.get("mask_sha256") or _is_cancelled(): _reject("Bundle manifest mask identity differs/cancelled"); return
	_data=data
func mark_joined(token: int,id: StringName) -> bool:
	_joined=token==_token and id==_id and not _is_cancelled() and _error.is_empty() and not _data.is_empty()
	return _joined
func packet(token: int,id: StringName) -> Dictionary:
	return _data if _joined and token==_token and id==_id and not _is_cancelled() else {}
func error() -> String:
	return _error if not _error.is_empty() else ("Bundle packet cancelled" if _is_cancelled() else "Bundle packet not ready")
func release() -> void:
	_data={}; _manifest={}; _joined=false; _token=0; _id=&""
static func materialize(raw: SceneScript,id: StringName,data: Dictionary,sources: Dictionary) -> SceneScript:
	if raw==null or raw.scene_id!=id or raw.resource_path!="res://data/scenes/%s.tres"%String(id) or describe(id,sources).is_empty(): return null
	if not equal(storage(raw),data.get("input_storage")) or not equal(storage(raw.map_layout),data.get("input_layout_storage")): return null
	var config: Dictionary=manifest(id)
	# Bind all native packet values, not just the rendering snapshots, to the
	# approved artifact bytes before C may install record/NAV/typed solids.
	if not _plain(data) or bytes_sha(var_to_bytes(data))!=config.artifacts[_root(id)+String(id)+"/packet.bin"]: return null
	for suffix: String in ["scene.res","layout.res"]:
		var path: String=_root(id)+String(id)+"/"+suffix
		if FileAccess.get_sha256(path)!=config.artifacts[path]: return null
	var layout:=ResourceLoader.load(_root(id)+String(id)+"/layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	var scene:=ResourceLoader.load(_root(id)+String(id)+"/scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if scene==null or layout==null or scene.scene_id!=id or scene.resource_path!=_root(id)+String(id)+"/scene.res" or layout.resource_path!=_root(id)+String(id)+"/layout.res": return null
	if scene.get_script().resource_path!=SCENE_SCRIPT or layout.get_script().resource_path!=LAYOUT_SCRIPT: return null
	scene.map_layout=layout
	if not equal(storage(scene),data.scene_storage) or not equal(storage(layout),data.layout_storage): return null
	if _ap_requested(id) and data.geometry_basis==_ap().BASIS:
		if scene.get_meta(_ap().META,"")!=config.author_sha256 or not ap_packet_valid(data): return null
		prune_sessions()
		_scene_sessions[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(layout),"data":data.duplicate(true),"config":config.duplicate(true),"parent":null}
	elif _ao_requested(id) and data.geometry_basis==_ao(id).BASIS:
		var ao: Variant=_ao(id)
		if scene.get_meta(ao.META,"")!=ao.AUTHOR_SHA or not ao_packet_valid(data): return null
		prune_sessions()
		_scene_sessions[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(layout),"data":data.duplicate(true),"config":config.duplicate(true),"parent":null}
	elif _ac_requested(id) and data.geometry_basis==_ac(id).BASIS:
		var ac: Variant=_ac(id)
		if scene.get_meta(ac.META,"")!=ac.AUTHOR_SHA or scene.get_meta(ac.AA_META,"")!=ac.AA_AUTHOR_SHA or scene.has_meta(_aa(id).OLD_META) or not ac_packet_valid(data): return null
		prune_sessions()
		_scene_sessions[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(layout),"data":data.duplicate(true),"config":config.duplicate(true),"parent":null}
	elif _aa_requested(id) and data.geometry_basis==_aa(id).BASIS:
		var aa: Variant=_aa(id)
		if scene.get_meta(aa.META,"")!=aa.AUTHOR_SHA or scene.has_meta(aa.OLD_META) or not aa_packet_valid(data): return null
		prune_sessions()
		_scene_sessions[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(layout),"data":data.duplicate(true),"config":config.duplicate(true),"parent":null}
	elif data.geometry_basis==T_BASIS:
		if scene.get_meta(T_META,"")!=config.author_sha256 or not data.get("t_parent_record") is Dictionary: return null
		for key: int in _scene_sessions.keys():
			if _scene_sessions[key].scene.get_ref()==null: _scene_sessions.erase(key)
		_scene_sessions[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(layout),"data":data.duplicate(true),"config":config.duplicate(true),"parent":null}
	return scene
static func ap_packet_valid(data: Dictionary) -> bool:
	if not _plain(data) or not _ap_requested(&"ch4_s3_luoyang_market"): return false
	var config: Dictionary=manifest(&"ch4_s3_luoyang_market");var spec: Dictionary=_ap().author()
	if config.is_empty() or spec.is_empty() or bytes_sha(var_to_bytes(data))!=config.artifacts.get(AP_ROOT+"ch4_s3_luoyang_market/packet.bin") or data.get("geometry_basis")!=_ap().BASIS or data.get("ap_author_sha256")!=config.author_sha256 or data.get("ap_parent_packet_sha256")!=spec.parent_packet_sha256 or FileAccess.get_sha256(spec.parent_packet_path)!=spec.parent_packet_sha256: return false
	var old: Variant=bytes_to_var(FileAccess.get_file_as_bytes(spec.parent_packet_path))
	if not old is Dictionary or not ao_packet_valid(old) or not equal(data.get("ap_parent_record"),old.get("record")) or not equal(_ap().inverse_record(data.record,old.record,spec),old.record): return false
	var inverse: Dictionary=data.duplicate(true)
	for key: String in ["geometry_basis","record","solids","walk_bytes","mask_sha","scene_storage","layout_storage"]: inverse[key]=old[key]
	for key: String in ["ap_parent_record","ap_parent_packet_sha256","ap_author_sha256"]: inverse.erase(key)
	return equal(inverse,old)
static func ao_packet_valid(data: Dictionary) -> bool:
	if not _plain(data) or bytes_sha(var_to_bytes(data))!=AO_PACKET_SHA: return false
	var ao: Variant=_ao(&"ch4_s3_luoyang_market");var spec: Dictionary=ao.author()
	if spec.is_empty() or data.get("geometry_basis")!=ao.BASIS or data.get("ao_author_sha256")!=ao.AUTHOR_SHA or data.get("ao_parent_packet_sha256")!=spec.parent_packet_sha256 or FileAccess.get_sha256(spec.parent_packet_path)!=spec.parent_packet_sha256: return false
	var old: Variant=bytes_to_var(FileAccess.get_file_as_bytes(spec.parent_packet_path))
	if not old is Dictionary or not _plain(old) or not equal(data.get("ao_parent_record"),old.get("record")): return false
	if not equal(_wire(ao.compose(old.record,spec,String(data.record.walk_path))),_wire(data.record)): return false
	var inverse: Dictionary=data.duplicate(true)
	for key: String in ["geometry_basis","record","solids","walk_bytes","mask_sha","scene_storage","layout_storage"]: inverse[key]=old[key]
	for key: String in ["ao_parent_record","ao_parent_packet_sha256","ao_author_sha256"]: inverse.erase(key)
	return equal(inverse,old)
static func ao_retired_visual_id(scene: SceneScript,id: String) -> bool:
	if id!="v13_market_east_plot_wall" or scene==null or scene.scene_id!=&"ch4_s3_luoyang_market" or not _ao_requested(scene.scene_id) or not whole_bound(scene): return false
	var data: Dictionary=_scene_sessions[scene.get_instance_id()].data
	if not (ap_packet_valid(data) if _ap_requested(scene.scene_id) else ao_packet_valid(data)): return false
	var old_count: int=0;var record_count: int=0;var render_count: int=0
	for row: Dictionary in data.ao_parent_record.objects:
		if row.get("id")==id: old_count+=1
	for row: Dictionary in data.record.objects:
		if row.get("id")==id: record_count+=1
	for row: Dictionary in scene.map_layout.visual_objects:
		if row.get("id")==id: render_count+=1
	return old_count==1 and record_count==0 and render_count==0
static func ao_fade_source_matches(scene: SceneScript,proof: Dictionary,path: String,prior_sha: String) -> bool:
	# This source successor is global across four District consumers; the
	# retired visual permission above is separately Market/exact-id only.
	var fade: String="res://scripts/city/luoyang_district_life_fade_20261016f.gd"
	var first: String="f359a43a88470ff220fa095cbd7f73ea04637c55c2faadd0a3b5f325e4b7a244"
	var previous: String="bc2958cc8f9a60ac9952891c30037441a62e289d8fee2fa235e6b864abf3a1bf"
	var next: String="3f2d43276f89341a450579fa07a0dd0bb2369d059ad928e7187fb35df59f1ac7"
	var candidate: String="res://build/luoyang_market_two_shops_20261021ao_system01/District_fade_READY.gd"
	if path!=fade or prior_sha!=first or scene==null or scene.scene_id not in IDS or proof.get("scene")!=scene or proof.get("id")!=scene.scene_id or int(proof.get("token",0))<=0 or proof.get("proof_kind")!=KIND or proof.get("sources",{}).get(path)!=next or FileAccess.get_sha256(path)!=next or FileAccess.get_sha256(candidate)!=next: return false
	var config: Dictionary=describe(scene.scene_id,proof.sources)
	if config.is_empty(): return false
	var delta: Dictionary=config.get("source_migration",{}).get("source_delta",{}).get(path,{})
	var history: Variant=delta.get("historical_sha256",[])
	return history is Array and first in history and previous in history and delta.get("current_before_sha256")==previous and delta.get("new_sha256")==next and delta.get("candidate_path")==candidate and config.legacy_source_sha256.get(path)==next
static func aa_packet_valid(data: Dictionary) -> bool:
	# A public pure validation boundary for negative clones, not an owner bypass.
	# Fixed hash is from immutable CPU111516, never from the caller/current disk.
	if not _plain(data) or bytes_sha(var_to_bytes(data))!=AA_PACKET_SHA: return false
	var aa: Variant=_aa(&"ch4_s2_canal_docks")
	var author: Dictionary=aa.author()
	if author.is_empty() or data.get("geometry_basis")!=aa.BASIS or data.get("aa_author_sha256")!=aa.AUTHOR_SHA: return false
	var parent_path: String=String(author.parent_bundle_root)+"packet.bin"
	var parent_sha: String=String(author.source_sha256.get(parent_path,""))
	if data.get("aa_parent_packet_sha256")!=parent_sha or FileAccess.get_sha256(parent_path)!=parent_sha: return false
	var old: Variant=bytes_to_var(FileAccess.get_file_as_bytes(parent_path))
	if not old is Dictionary or not _plain(old) or not equal(data.get("aa_parent_record"),old.get("record")): return false
	var spacing: Variant=JSON.parse_string(FileAccess.get_file_as_string(author.old_spacing_manifest))
	if not spacing is Dictionary or not equal(_wire(data.get("aa_district_parent_record")),_wire(spacing.get("parent_record"))): return false
	if not equal(_wire(aa.compose(data.aa_parent_record,String(data.record.walk_path))),_wire(data.record)): return false
	# Whole typed inverse: all non-delta values remain the actual original packet.
	var inverse: Dictionary=data.duplicate(true)
	for key: String in ["geometry_basis","record","solids","walk_bytes","mask_sha","scene_storage","layout_storage"]: inverse[key]=old[key]
	for key: String in ["aa_author_sha256","aa_parent_record","aa_district_parent_record","aa_parent_packet_sha256"]: inverse.erase(key)
	return equal(inverse,old)
static func ac_packet_valid(data: Dictionary) -> bool:
	# Fixed native output from actual CPU114284. No caller-set hash authority.
	if not _plain(data) or bytes_sha(var_to_bytes(data))!=AC_PACKET_SHA: return false
	var ac: Variant=_ac(&"ch4_s2_canal_docks");var spec: Dictionary=ac.author()
	if spec.is_empty() or data.get("geometry_basis")!=ac.BASIS or data.get("ac_author_sha256")!=ac.AUTHOR_SHA: return false
	var parent_path: String=String(spec.parent_bundle_root)+"packet.bin"
	if data.get("ac_parent_packet_sha256")!=AA_PACKET_SHA or FileAccess.get_sha256(parent_path)!=AA_PACKET_SHA: return false
	var old: Variant=bytes_to_var(FileAccess.get_file_as_bytes(parent_path))
	if not old is Dictionary or not _plain(old) or not equal(data.get("ac_parent_record"),old.get("record")): return false
	if not equal(_wire(ac.compose(old.record,String(data.record.walk_path))),_wire(data.record)): return false
	if not equal(data.get("aa_district_parent_record"),old.get("aa_district_parent_record")): return false
	var inverse: Dictionary=data.duplicate(true)
	for key: String in ["geometry_basis","record","solids","walk_bytes","mask_sha","scene_storage","layout_storage"]: inverse[key]=old[key]
	for key: String in ["ac_author_sha256","ac_parent_record","ac_parent_packet_sha256"]: inverse.erase(key)
	return equal(inverse,old)
static func prune_sessions() -> int:
	var removed: int=0
	for key: int in _scene_sessions.keys():
		var session: Dictionary=_scene_sessions[key]
		if session.scene.get_ref()==null or session.layout.get_ref()==null:
			_scene_sessions.erase(key); removed+=1
	return removed
static func session_count() -> int:
	prune_sessions()
	return _scene_sessions.size()
static func layout_author(scene: SceneScript) -> Dictionary:
	if not whole_bound(scene): return {}
	var config: Dictionary=_scene_sessions[scene.get_instance_id()].config
	var path: String=String(config.get("author_path",""))
	if _ap_requested(scene.scene_id):
		var spec: Dictionary=_ap().author()
		if spec.is_empty() or FileAccess.get_sha256(spec.district_t_author_path)!=spec.district_t_author_sha256: return {}
		var parent_author: Variant=JSON.parse_string(FileAccess.get_file_as_string(spec.district_t_author_path))
		return parent_author if parent_author is Dictionary else {}
	if _ao_requested(scene.scene_id):
		var spec: Dictionary=_ao(scene.scene_id).author()
		if spec.is_empty(): return {}
		path=String(spec.district_t_author_path)
		if FileAccess.get_sha256(path)!=spec.district_t_author_sha256: return {}
		var parent_author: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
		return parent_author if parent_author is Dictionary else {}
	if path!="res://build/luoyang_layout_quest_20261018t_layout_source01/author_retry2.json" or FileAccess.get_sha256(path)!=config.get("author_sha256"): return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
static func proof_basis(data: Dictionary) -> String:
	return String(data.get("geometry_basis",""))
static func bound(scene: SceneScript) -> bool:
	if scene==null or scene.map_layout==null: return false
	var session: Dictionary=_scene_sessions.get(scene.get_instance_id(),{})
	if session.is_empty() or session.scene.get_ref()!=scene or session.layout.get_ref()!=scene.map_layout or scene.map_layout.walkable_mask_path!=session.data.record.walk_path: return false
	if _ap_requested(scene.scene_id) and session.data.get("geometry_basis")==_ap().BASIS: return scene.get_meta(_ap().META,"")==session.config.get("author_sha256") and session.config.get("author_sha256")==FileAccess.get_sha256(_ap().AUTHOR)
	if _ao_requested(scene.scene_id) and session.data.get("geometry_basis")==_ao(scene.scene_id).BASIS:
		var ao: Variant=_ao(scene.scene_id)
		return scene.get_meta(ao.META,"")==ao.AUTHOR_SHA and session.config.get("author_sha256")==ao.AUTHOR_SHA
	if _ac_requested(scene.scene_id) and session.data.get("geometry_basis")==_ac(scene.scene_id).BASIS:
		var ac: Variant=_ac(scene.scene_id)
		return scene.get_meta(ac.META,"")==ac.AUTHOR_SHA and scene.get_meta(ac.AA_META,"")==ac.AA_AUTHOR_SHA and not scene.has_meta(_aa(scene.scene_id).OLD_META) and session.config.get("author_sha256")==ac.AUTHOR_SHA
	if _aa_requested(scene.scene_id) and session.data.get("geometry_basis")==_aa(scene.scene_id).BASIS:
		var aa: Variant=_aa(scene.scene_id)
		# No aa.bound call here: its public bound delegates to whole_bound.
		return scene.get_meta(aa.META,"")==aa.AUTHOR_SHA and not scene.has_meta(aa.OLD_META) and session.config.get("author_sha256")==aa.AUTHOR_SHA
	return scene.get_meta(T_META,"")==session.config.author_sha256
static func whole_bound(scene: SceneScript) -> bool:
	if not bound(scene): return false
	var data: Dictionary=_scene_sessions[scene.get_instance_id()].data
	return equal(storage(scene),data.scene_storage) and equal(storage(scene.map_layout),data.layout_storage)
static func parent_scene(scene: SceneScript) -> SceneScript:
	if not whole_bound(scene): return null
	var session: Dictionary=_scene_sessions[scene.get_instance_id()]
	if session.parent!=null: return session.parent
	var id: String=String(scene.scene_id)
	var root: String="res://data/maps/luoyang_precomputed_bundle_20261018r3/"+id+"/"
	var prior: Dictionary=session.config.parent_publication.complete_immutable_manifest
	for suffix: String in ["scene.res","layout.res"]:
		if FileAccess.get_sha256(root+suffix)!=prior.artifacts.get(root+suffix): return null
	var original:=ResourceLoader.load(root+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout:=ResourceLoader.load(root+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if original==null or layout==null: return null
	original.map_layout=layout
	if not equal(storage(original),session.data.t_parent_scene_storage) or not equal(storage(layout),session.data.t_parent_layout_storage): return null
	session.parent=original; return original
static func _wire(value: Variant) -> Variant: return JSON.parse_string(JSON.stringify(value,"\t",true,true))
static func restore_parent_record(scene: SceneScript,current: Dictionary,expected: Dictionary) -> Dictionary:
	if not whole_bound(scene): return {}
	var data: Dictionary=_scene_sessions[scene.get_instance_id()].data
	if _ac_requested(scene.scene_id) and data.get("geometry_basis")==_ac(scene.scene_id).BASIS:
		var ac_child: Dictionary=data.record.duplicate(true)
		for key: String in ["harbour_runtime_binding_sha","harbour_parent_task_semantics_preserved"]:
			if not current.has(key): ac_child.erase(key)
		return expected.duplicate(true) if equal(_wire(current),_wire(ac_child)) and equal(_wire(expected),_wire(data.get("aa_district_parent_record"))) else {}
	if _aa_requested(scene.scene_id) and data.get("geometry_basis")==_aa(scene.scene_id).BASIS:
		return _aa(scene.scene_id).restore_parent_record(scene,current,expected,data)
	var child: Dictionary=data.record.duplicate(true); var prior: Dictionary=data.t_parent_record.duplicate(true)
	if _ap_requested(scene.scene_id) and data.get("geometry_basis")==_ap().BASIS:
		var spec: Dictionary=_ap().author()
		if spec.is_empty() or not equal(_ap().inverse_record(child,data.ap_parent_record,spec),data.ap_parent_record): return {}
		var ao_spec: Dictionary=_ao(scene.scene_id).author()
		if ao_spec.is_empty() or not equal(_ao(scene.scene_id).inverse_record(data.ap_parent_record,data.ao_parent_record,ao_spec),data.ao_parent_record): return {}
	if _ao_requested(scene.scene_id) and data.get("geometry_basis")==_ao(scene.scene_id).BASIS:
		var ao: Variant=_ao(scene.scene_id);var spec: Dictionary=ao.author()
		if spec.is_empty() or not equal(ao.inverse_record(child,data.ao_parent_record,spec),data.ao_parent_record): return {}
		# AO's complete parent is T's published record; its preserved T parent
		# is District's immutable authored basis. Compare both layers exactly.
	# The existing District prepare explicitly strips exactly these receipts.
	for key: String in ["assembled_runtime_binding_sha","assembled_parent_task_semantics_preserved","annex_runtime_binding_sha","annex_parent_semantics_unchanged"]:
		if not current.has(key): child.erase(key)
		if not expected.has(key): prior.erase(key)
	if not equal(_wire(current),_wire(child)) or not equal(_wire(prior),_wire(expected)): return {}
	return expected.duplicate(true)

static func ap_district_projection(scene: SceneScript,original: Dictionary) -> Dictionary:
	if scene==null or scene.scene_id!=&"ch4_s3_luoyang_market" or not scene.has_meta(_ap().META) or not whole_bound(scene): return {}
	var spec: Dictionary=_ap().author()
	if spec.is_empty() or scene.get_meta(_ap().META)!=FileAccess.get_sha256(_ap().AUTHOR): return {}
	return _ap().project_district(original,spec)
