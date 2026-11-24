extends RefCounted
## Full-source runtime bundle. Geometry/material proof is made at publication,
## never described as freshly rerun here. No cross-token/session cache.
const SELF="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const INDEX="res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd"
const ROOT="res://data/maps/luoyang_layout_bundle_20261018t/"
const T_META="luoyang_layout_quest_20261018t"
const T_BASIS="PARENT_PUBLISHED_PLUS_T_LAYOUT_PROOF"
const UNCHANGED_BASIS="UNCHANGED_PARENT_NATIVE_ARTIFACT_EXPLICIT_SOURCE_SUCCESSION"
const ROOM_ROOT="res://data/maps/luoyang_layout_rooms_20261018t/"
const ROOM_INDEX="res://scripts/city/luoyang_layout_room_index_20261018t.gd"
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
	if not supported(id) or not FileAccess.file_exists(INDEX): return {}
	var index: Variant=load(INDEX)
	if not index is GDScript or index.resource_path!=INDEX: return {}
	var entry_methods: int=0
	for method: Dictionary in index.get_script_method_list():
		if method.name=="entries": entry_methods+=1
	if entry_methods!=1: return {}
	var entries: Dictionary=index.entries()
	var entry: Dictionary=entries.get(String(id),{})
	if entry.size()!=2 or entry.get("manifest_path")!=ROOT+String(id)+"/manifest.json" or not _hash(entry.get("manifest_sha256")): return {}
	return entry
static func manifest(id: StringName) -> Dictionary:
	var entry: Dictionary=_entry(id)
	if entry.is_empty() or FileAccess.get_sha256(entry.manifest_path)!=entry.manifest_sha256: return {}
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(entry.manifest_path))
	if not raw is Dictionary or raw.get("kind")!=KIND or raw.get("scene_id")!=String(id) or raw.get("publication_full_source_finalized")!=true: return {}
	if raw.get("geometry_proof_basis") not in [T_BASIS,UNCHANGED_BASIS] or not raw.get("legacy_source_sha256") is Dictionary or raw.legacy_source_sha256.is_empty(): return {}
	if raw.get("layout_proof",{}).get("passed")!=true or not raw.get("runtime_authority_sha256") is Dictionary: return {}
	for path: String in raw.runtime_authority_sha256:
		if not (path.begins_with(ROOM_ROOT) or path.begins_with(ROOT) or path==ROOM_INDEX) or ".." in path or not _hash(raw.runtime_authority_sha256[path]): return {}
	var artifacts: Variant=raw.get("artifacts")
	if not artifacts is Dictionary or artifacts.size()!=3: return {}
	for suffix: String in ["scene.res","layout.res","packet.bin"]:
		var path: String=ROOT+String(id)+"/"+suffix
		if not artifacts.has(path) or not _hash(artifacts[path]): return {}
	for path: Variant in raw.legacy_source_sha256:
		if not path is String or not path.begins_with("res://") or ".." in path or not _hash(raw.legacy_source_sha256[path]) or path==INDEX or path.begins_with(ROOT): return {}
	if not raw.legacy_source_sha256.has(SELF) or not raw.legacy_source_sha256.has("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"): return {}
	return raw
static func source_paths(id: StringName) -> Dictionary:
	var paths: Dictionary={SELF:true}
	if id==&"ch4_s1_luoyang_yamen":
		for path: String in RESOURCE_SOURCES: paths[path]=true
	if not requested(id): return paths
	var config: Dictionary=manifest(id)
	if config.is_empty(): return {}
	for path: String in config.legacy_source_sha256: paths[path]=true
	for path: String in config.runtime_authority_sha256: paths[path]=true
	paths[INDEX]=true; paths[ROOT+String(id)+"/manifest.json"]=true
	for path: String in config.artifacts: paths[path]=true
	return paths
static func describe(id: StringName,sources: Dictionary) -> Dictionary:
	var config: Dictionary=manifest(id)
	if config.is_empty(): return {}
	var expected: Dictionary=config.legacy_source_sha256.duplicate(true)
	expected.merge(config.runtime_authority_sha256)
	expected.merge(config.artifacts)
	expected[INDEX]=FileAccess.get_sha256(INDEX)
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
	var path: String=ROOT+String(_id)+"/packet.bin"
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
	if not _plain(data) or bytes_sha(var_to_bytes(data))!=config.artifacts[ROOT+String(id)+"/packet.bin"]: return null
	for suffix: String in ["scene.res","layout.res"]:
		var path: String=ROOT+String(id)+"/"+suffix
		if FileAccess.get_sha256(path)!=config.artifacts[path]: return null
	var layout:=ResourceLoader.load(ROOT+String(id)+"/layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	var scene:=ResourceLoader.load(ROOT+String(id)+"/scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if scene==null or layout==null or scene.scene_id!=id or scene.resource_path!=ROOT+String(id)+"/scene.res" or layout.resource_path!=ROOT+String(id)+"/layout.res": return null
	if scene.get_script().resource_path!=SCENE_SCRIPT or layout.get_script().resource_path!=LAYOUT_SCRIPT: return null
	scene.map_layout=layout
	if not equal(storage(scene),data.scene_storage) or not equal(storage(layout),data.layout_storage): return null
	if data.geometry_basis==T_BASIS:
		if scene.get_meta(T_META,"")!=config.author_sha256 or not data.get("t_parent_record") is Dictionary: return null
		for key: int in _scene_sessions.keys():
			if _scene_sessions[key].scene.get_ref()==null: _scene_sessions.erase(key)
		_scene_sessions[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(layout),"data":data.duplicate(true),"config":config.duplicate(true),"parent":null}
	return scene
static func proof_basis(data: Dictionary) -> String:
	return String(data.get("geometry_basis",""))
static func bound(scene: SceneScript) -> bool:
	if scene==null or scene.map_layout==null: return false
	var session: Dictionary=_scene_sessions.get(scene.get_instance_id(),{})
	return not session.is_empty() and session.scene.get_ref()==scene and session.layout.get_ref()==scene.map_layout and scene.get_meta(T_META,"")==session.config.author_sha256 and scene.map_layout.walkable_mask_path==session.data.record.walk_path
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
	var child: Dictionary=data.record.duplicate(true); var prior: Dictionary=data.t_parent_record.duplicate(true)
	# The existing District prepare explicitly strips exactly these receipts.
	for key: String in ["assembled_runtime_binding_sha","assembled_parent_task_semantics_preserved","annex_runtime_binding_sha","annex_parent_semantics_unchanged"]:
		if not current.has(key): child.erase(key)
		if not expected.has(key): prior.erase(key)
	if not equal(_wire(current),_wire(child)) or not equal(_wire(prior),_wire(expected)): return {}
	return expected.duplicate(true)
