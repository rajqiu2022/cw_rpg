extends RefCounted
## Full-source runtime bundle. Geometry/material proof is made at publication,
## never described as freshly rerun here. No cross-token/session cache.
const SELF="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const INDEX="res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd"
const ROOT="res://data/maps/luoyang_precomputed_bundle_20261018r/"
const KIND="PRECOMPUTED_PUBLISHED_FULL_SOURCE_V1"
const FLAG="--luoyang-precomputed-bundle-20261018r"
const FORCE_AUTHORING="--luoyang-force-authoring-20261018r"
const FORMAL_ENABLED=false
const IDS=[&"ch4_s0_luoyang_gate",&"ch4_s3_luoyang_market"]
const SIZE=Vector2i(3072,2048)
const SCENE_SCRIPT="res://scripts/domain/scene_script.gd"
const LAYOUT_SCRIPT="res://scripts/domain/walkable_map_layout.gd"
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
	# All storage except the separately fixed script and explicit layout edge.
	var result: Dictionary={}
	if resource==null: return result
	for property: Dictionary in resource.get_property_list():
		var key: String=String(property.name)
		if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or key in ["script","map_layout"]: continue
		var value: Variant=resource.get(key)
		result[key]=value.duplicate(true) if value is Array or value is Dictionary else value
	return result
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
	if raw.get("geometry_proof_basis")!="FULL_ORIGINAL_PIPELINE_AT_PUBLICATION_NOT_RERUN_AT_RUNTIME" or not raw.get("legacy_source_sha256") is Dictionary or raw.legacy_source_sha256.is_empty(): return {}
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
	if not requested(id): return paths
	var config: Dictionary=manifest(id)
	if config.is_empty(): return {}
	paths[INDEX]=true; paths[ROOT+String(id)+"/manifest.json"]=true
	for path: String in config.artifacts: paths[path]=true
	return paths
static func describe(id: StringName,sources: Dictionary) -> Dictionary:
	var config: Dictionary=manifest(id)
	if config.is_empty(): return {}
	var paths: Dictionary=source_paths(id)
	if paths.is_empty() or sources.get(INDEX)!=FileAccess.get_sha256(INDEX): return {}
	var entry: Dictionary=_entry(id)
	if sources.get(entry.manifest_path)!=entry.manifest_sha256: return {}
	var legacy: Dictionary=sources.duplicate()
	for path: String in paths:
		if path==SELF: continue # Helper was frozen before compilation, so is legacy.
		if not sources.has(path): return {}
		legacy.erase(path)
	for path: String in config.artifacts:
		if sources.get(path)!=config.artifacts[path]: return {}
	if not equal(legacy,config.legacy_source_sha256): return {}
	return config
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
	if data.get("kind")!=KIND or data.get("scene_id")!=String(_id) or not data.get("record") is Dictionary or data.record.get("canonical_scene_id")!=String(_id): _reject("Bundle native packet city identity differs"); return
	if data.get("size")!=SIZE or not data.get("walk_bytes") is PackedByteArray or data.walk_bytes.size()!=SIZE.x*SIZE.y*4 or bytes_sha(data.walk_bytes)!=data.get("mask_sha"): _reject("Bundle mask size/full RGBA bytes differ"); return
	if not data.get("solids") is Array or not data.get("scene_storage") is Dictionary or not data.get("layout_storage") is Dictionary or not data.get("input_storage") is Dictionary or not data.get("input_layout_storage") is Dictionary: _reject("Bundle complete native storage missing"); return
	if data.get("scene_script")!=SCENE_SCRIPT or data.get("layout_script")!=LAYOUT_SCRIPT or data.layout_storage.get("schema_version")!=3 or data.layout_storage.get("walkable_mask_path")!=data.record.get("walk_path"): _reject("Bundle native scripts/layout/walk identity differs"); return
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
	return scene if equal(storage(scene),data.scene_storage) and equal(storage(layout),data.layout_storage) else null
