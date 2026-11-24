extends RefCounted
## Real finite implementation, deliberately non-admitting pending Root ART,
## source closure, exact native imports and consumer review. No geometry replay.
const READY := true
const ART_ADMISSION_PATH := "res://build/luoyang_city_full_rollout_20261022ap_root01/wall_yamen_finite_visual_admission_READY.json"
const ART_ADMISSION_SHA := "aacbc800e4c770d4aa62ff32aa71bf64060ecf347b42a8aea5cde315b49e2cae"
const BINDING := "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/adapter_binding_READY.json"
const BINDING_SHA := "dc21bb2a5e8d4e1af6944d6a6fe6c864caf29702e4b17b44063ed2369f53ecff"
const SELF := "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/finite_adapter_READY.gd"
const MARKET := &"ch4_s3_luoyang_market"
const YAMEN := &"ch4_s1_luoyang_yamen"
const WEST_WALL := "v13_market_west_plot_wall"
const YAMEN_IDS := ["ap_yamen_waiting_bench_north", "ap_yamen_waiting_bench_south", "ap_yamen_petition_writing_desk"]
const ROW_HELPER_PATH := "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/yamen_consumer_preparation01/clerk_row_projection_PREPARATION_ONLY.gd"
static var _binding: Dictionary = {}
static var _verified_token: int = 0
static var _parents: Dictionary = {}
static var _packets: Dictionary = {}
static var _sessions: Dictionary = {}
static var _npc_sessions: Dictionary = {}
static var _report: Dictionary = {}
static var _self_sha_cached: String = ""
static var _frozen_ap_spec: Dictionary = {}
static var _art_validated: bool = false
static var _native_data_cache: Dictionary = {} # Worker-only, exact immutable SHA.
static var _receipt_facts: Dictionary = {}
static var _row_helper_handle: Variant = null
static var _ap_code_handle: Variant = null
static var _ao_code_handle: Variant = null
const AP_INDEX := "res://scripts/city/luoyang_full_city_index_20261022ap.gd"

static func _same(a: Variant,b: Variant) -> bool:
	if typeof(a)!=typeof(b): return false
	if a is Dictionary:
		if a.size()!=b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _same(a[key],b[key]): return false
		return true
	if a is Array:
		if a.size()!=b.size(): return false
		for i: int in a.size():
			if not _same(a[i],b[i]): return false
		return true
	return a==b
static func _sha(bytes: PackedByteArray) -> String:
	var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(bytes);return h.finish().hex_encode()
static func _b() -> Variant: return load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
static func _c() -> Variant: return load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
static func _domain(id: StringName) -> String:
	return "market" if id==MARKET else ("yamen" if id==YAMEN else "")
static func _load_binding() -> Dictionary:
	if not _binding.is_empty(): return _binding
	var bytes:=FileAccess.get_file_as_bytes(BINDING)
	if _sha(bytes)!=BINDING_SHA: return {}
	var value: Variant=JSON.parse_string(bytes.get_string_from_utf8())
	if not value is Dictionary or value.get("status")!="FIXED_ACTUAL89216_FINITE_ADAPTER_DATA_ROOT_ART_BOUND_SOURCE_CLOSURE_PENDING": return {}
	_binding=value;return _binding
static func _ready() -> bool:
	# Closing this gate requires a NEW Root-reviewed successor, never a CLI flag.
	if not READY or ART_ADMISSION_PATH.is_empty() or ART_ADMISSION_SHA.length()!=64: return false
	var spec:=_load_binding()
	if spec.is_empty() or spec.get("source_closure_ready")!=true: return false
	if not _art_validated:
		var bytes:=FileAccess.get_file_as_bytes(ART_ADMISSION_PATH)
		if _sha(bytes)!=ART_ADMISSION_SHA: return false
		var art: Variant=JSON.parse_string(bytes.get_string_from_utf8())
		if not art is Dictionary or art.get("status")!="ROOT_FINITE_TWO_LOCAL_VISUALS_ADMITTED_NOT_WHOLE_CITY_OR_RUNTIME" or art.get("approved_by_root")!=true or art.get("CPU_report",{}).get("path")!=spec.actual_report_path or art.get("CPU_report",{}).get("sha256")!=spec.fixed_source_sha256.get(spec.actual_report_path): return false
		_art_validated=true
	var index: Variant=load(AP_INDEX)
	if not index is GDScript: return false
	var method_count: int=0
	for method: Dictionary in index.get_script_method_list():
		if method.name=="finite_geometry_enabled": method_count+=1
	return method_count==1 and index.finite_geometry_enabled()==true
static func _fixed_bytes(path: String) -> PackedByteArray:
	var spec:=_load_binding()
	if not spec.get("fixed_source_sha256",{}).has(path): return PackedByteArray()
	var bytes:=FileAccess.get_file_as_bytes(path)
	return bytes if _sha(bytes)==spec.fixed_source_sha256[path] else PackedByteArray()
static func _fixed_json(path: String) -> Dictionary:
	var bytes:=_fixed_bytes(path)
	if bytes.is_empty(): return {}
	var value: Variant=JSON.parse_string(bytes.get_string_from_utf8())
	return value if value is Dictionary else {}
static func _fixed_packet(path: String,context: Dictionary) -> Dictionary:
	# Called only in the already-existing B packet worker. Fresh complete SHA
	# evidence comes from this exact C attempt, never a current-disk fallback.
	var expected: String=String(context.facts.get(path,""))
	if expected.length()!=64 or _binding.fixed_source_sha256.get(path)!=expected: return {}
	var old: Dictionary=_native_data_cache.get(path,{})
	if old.get("sha256")==expected: return old.data
	var bytes:=FileAccess.get_file_as_bytes(path)
	if _sha(bytes)!=expected: return {}
	var value: Variant=bytes_to_var(bytes)
	if not value is Dictionary or not _b()._plain(value): return {}
	_native_data_cache[path]={"sha256":expected,"data":value};return value
static func _packet_inverse(child: Dictionary,parent: Dictionary) -> bool:
	var inverse:=child.duplicate(true)
	for key: String in ["record","solids","walk_bytes","mask_sha","scene_storage","layout_storage","geometry_basis"]:
		if parent.has(key): inverse[key]=parent[key]
		else: inverse.erase(key)
	for key: String in ["finite_delta_parent_packet_sha256","finite_delta_input_sha256","finite_delta_domain_id"]: inverse.erase(key)
	return _same(inverse,parent)
static func _record_inverse(domain: String,child: Dictionary,parent: Dictionary) -> bool:
	var spec: Dictionary=_binding.domains[domain]
	var inverse:=child.duplicate(true)
	if child.get("walk_path")!=spec.artifacts["walk.png"].path: return false
	if domain=="market":
		if inverse.objects.size()!=23: return false
		for row: Dictionary in inverse.objects:
			if row.get("id")==WEST_WALL: return false
		var ordinal: int=int(spec.removed_record_ordinal)
		if ordinal<0 or ordinal>=parent.objects.size() or parent.objects[ordinal].get("id")!=WEST_WALL: return false
		inverse.objects.insert(ordinal,parent.objects[ordinal].duplicate(true))
	else:
		if inverse.objects.size()!=27 or parent.objects.size()!=24: return false
		for i: int in 3:
			if inverse.objects[24+i].get("id")!=YAMEN_IDS[i]: return false
		for i: int in 3: inverse.objects.pop_back()
		for delta: Dictionary in spec.route_changes:
			var route_index: int=int(delta.route_index_in_immutable_manifest)
			var point: int=int(delta.point_ordinal)
			if inverse.routes[route_index].get("id")!=delta.route_id or not _same(inverse.routes[route_index].points_px[point],delta.after): return false
			inverse.routes[route_index].points_px[point]=parent.routes[route_index].points_px[point].duplicate()
	inverse.walk_path=parent.walk_path
	return _same(inverse,parent)
static func _layout_inverse(domain: String,child: Dictionary,parent: Dictionary) -> bool:
	if not _same(child.scene_storage,parent.scene_storage): return false
	var inverse: Dictionary=child.layout_storage.duplicate(true)
	var wrapped: Variant=inverse.fields.get("visual_objects")
	var old_wrapped: Variant=parent.layout_storage.fields.get("visual_objects")
	if not wrapped is Dictionary or not old_wrapped is Dictionary or not wrapped.get("array_values") is Array or not old_wrapped.get("array_values") is Array: return false
	var rows: Array=wrapped.array_values
	var old_rows: Array=old_wrapped.array_values
	if domain=="market":
		var ordinal: int=int(_binding.domains.market.removed_visual_ordinal)
		if rows.size()!=23 or old_rows.size()!=24 or old_rows[ordinal].get("id")!=WEST_WALL: return false
		for row: Dictionary in rows:
			if row.get("id")==WEST_WALL: return false
		rows.insert(ordinal,old_rows[ordinal].duplicate(true))
	else:
		if rows.size()!=27 or old_rows.size()!=24: return false
		for i: int in 3:
			if rows[24+i].get("id")!=YAMEN_IDS[i]: return false
		for i: int in 3: rows.pop_back()
	inverse.fields.walkable_mask_path=parent.layout_storage.fields.walkable_mask_path
	return _same(inverse,parent.layout_storage)
static func _mask_inverse(domain: String,child: Dictionary,parent: Dictionary,report: Dictionary) -> bool:
	if not child.get("walk_bytes") is PackedByteArray or not parent.get("walk_bytes") is PackedByteArray or child.walk_bytes.size()!=3072*2048*4: return false
	if _sha(child.walk_bytes)!=child.mask_sha or _sha(parent.walk_bytes)!=parent.mask_sha: return false
	var changes: Array=report[domain].finite_proof.mask_delta.changed
	var inverse: PackedByteArray=child.walk_bytes.duplicate();var seen: Dictionary={}
	for row: Dictionary in changes:
		var x: int=int(row.x);var y: int=int(row.y);var offset: int=(y*3072+x)*4
		if x<0 or x>=3072 or y<0 or y>=2048 or seen.has(offset): return false
		seen[offset]=true
		for channel: int in 4:
			if child.walk_bytes[offset+channel]!=int(row.new_RGBA[channel]) or parent.walk_bytes[offset+channel]!=int(row.old_RGBA[channel]): return false
			inverse[offset+channel]=parent.walk_bytes[offset+channel]
	return inverse==parent.walk_bytes
static func _frozen_market_chain(old_ap: Dictionary,context: Dictionary) -> bool:
	# Main prepared the fixed source-derived two small specs before submitting
	# this CPU job; worker uses only plain dictionaries and cached static code.
	var d: Dictionary=_binding.domains.market
	var frozen_config: Dictionary=d.frozen_parent_config
	var ap_spec: Dictionary=context.ap_spec;var ao_spec: Dictionary=context.ao_spec
	if ap_spec.is_empty() or ao_spec.is_empty() or frozen_config.artifacts.get(d.parent_packet_path)!=d.parent_packet_sha256: return false
	if old_ap.get("geometry_basis")!=_ap_code_handle.BASIS or old_ap.get("ap_author_sha256")!=frozen_config.author_sha256 or old_ap.get("ap_parent_packet_sha256")!=ap_spec.parent_packet_sha256: return false
	var old_ao:=_fixed_packet(ap_spec.parent_packet_path,context)
	if old_ao.is_empty() or not _same(old_ap.ap_parent_record,old_ao.record) or not _same(_ap_code_handle.inverse_record(old_ap.record,old_ao.record,ap_spec),old_ao.record): return false
	var inv:=old_ap.duplicate(true)
	for key: String in ["geometry_basis","record","solids","walk_bytes","mask_sha","scene_storage","layout_storage"]: inv[key]=old_ao[key]
	for key: String in ["ap_parent_record","ap_parent_packet_sha256","ap_author_sha256"]: inv.erase(key)
	if not _same(inv,old_ao) or old_ao.get("geometry_basis")!=_ao_code_handle.BASIS or old_ao.get("ao_parent_packet_sha256")!=ao_spec.parent_packet_sha256: return false
	var old_t:=_fixed_packet(ao_spec.parent_packet_path,context)
	if old_t.is_empty() or not _same(old_ao.ao_parent_record,old_t.record) or not _same(_ao_code_handle.inverse_record(old_ao.record,old_t.record,ao_spec),old_t.record): return false
	inv=old_ao.duplicate(true)
	for key: String in ["geometry_basis","record","solids","walk_bytes","mask_sha","scene_storage","layout_storage"]: inv[key]=old_t[key]
	for key: String in ["ao_parent_record","ao_parent_packet_sha256","ao_author_sha256"]: inv.erase(key)
	return _same(inv,old_t) and _same(old_ap.t_parent_record,old_t.t_parent_record) and _same(old_ap.t_parent_scene_storage,old_t.t_parent_scene_storage) and _same(old_ap.t_parent_layout_storage,old_t.t_parent_layout_storage)
static func prepare_packet_context(token: int,id: StringName,sources: Dictionary,config: Dictionary,self_sha: String) -> Dictionary:
	if not root_requested(id): return {"requested":false}
	var domain:=_domain(id)
	if token<=0 or int(_c()._live_source_token)!=token or not _manifest_valid(id,config,domain): return {"requested":true,"ok":false}
	var expected: Dictionary=_binding.shared_source_sha256.duplicate(true)
	expected.merge(_binding.domains[domain].source_sha256)
	expected[SELF]=self_sha;expected[BINDING]=BINDING_SHA
	var entry_now:=entry(id)
	if entry_now.is_empty(): return {"requested":true,"ok":false}
	expected[entry_now.manifest_path]=entry_now.manifest_sha256
	var index_sha: Variant=sources.get(AP_INDEX)
	if not index_sha is String or index_sha.length()!=64: return {"requested":true,"ok":false}
	expected[AP_INDEX]=index_sha
	for source_path: String in expected:
		if sources.get(source_path)!=expected[source_path]: return {"requested":true,"ok":false}
	var ap_spec: Dictionary={};var ao_spec: Dictionary={}
	if domain=="market":
		_ap_code_handle=load(_binding.ap_helper_path);_ao_code_handle=load(_binding.ao_helper_path)
		if not _ap_code_handle is GDScript or not _ao_code_handle is GDScript: return {"requested":true,"ok":false}
		ap_spec=_ap_code_handle.project_spec(_binding.frozen_ap_author)
		ao_spec=_ao_code_handle.project_spec(_binding.frozen_ao_author)
		if ap_spec.is_empty() or ao_spec.is_empty(): return {"requested":true,"ok":false}
	else:
		_row_helper_handle=load(ROW_HELPER_PATH)
		if not _row_helper_handle is GDScript or _row_helper_handle.resource_path!=ROW_HELPER_PATH: return {"requested":true,"ok":false}
	return {"requested":true,"ok":true,"token":token,"id":String(id),"domain":domain,"facts":expected,"ap_spec":ap_spec,"ao_spec":ao_spec,"binding_sha256":BINDING_SHA,"self_sha256":self_sha}
static func validate_packet_worker(context: Dictionary,child: Dictionary,stream_verified_sha: String) -> Dictionary:
	# Existing B.run already streamed/hash-checked child bytes against its exact
	# config. Never reread child, scan all source files, PNG-decode or touch Scene.
	if context.get("ok")!=true or context.get("binding_sha256")!=BINDING_SHA: return {}
	var domain: String=context.domain;var d: Dictionary=_binding.domains[domain]
	if stream_verified_sha!=d.artifacts["packet.bin"].sha256 or context.facts.get(d.artifacts["packet.bin"].path)!=stream_verified_sha: return {}
	var parent:=_fixed_packet(d.parent_packet_path,context)
	if parent.is_empty() or child.get("geometry_basis")!=d.basis or child.get("finite_delta_domain_id")!=domain or child.get("finite_delta_input_sha256")!=_binding.actual_input_sha256 or child.get("finite_delta_parent_packet_sha256")!=d.parent_packet_sha256: return {}
	var proof_report: Dictionary={domain:{"finite_proof":{"mask_delta":d.mask_delta}}}
	if not _packet_inverse(child,parent) or not _record_inverse(domain,child.record,parent.record) or not _layout_inverse(domain,child,parent) or not _mask_inverse(domain,child,parent,proof_report): return {}
	if domain=="market" and not _frozen_market_chain(parent,context): return {}
	return {"ok":true,"token":context.token,"id":context.id,"domain":domain,"facts":context.facts.duplicate(true),"child":child,"parent":parent,"ap_spec":context.ap_spec,"self_sha256":context.self_sha256,"packet_sha256":stream_verified_sha,"binding_sha256":BINDING_SHA}
static func accept_joined_native(token: int,id: StringName,context: Dictionary,result: Dictionary) -> bool:
	# Called only by joined main-thread B.mark_joined after its original cancel
	# and token checks. A cancelled worker may never publish runtime state.
	if not _ready() or int(_c()._live_source_token)!=token or result.get("ok")!=true or result.get("token")!=token or result.get("id")!=String(id) or context.get("token")!=token or not _same(result.get("facts"),context.get("facts")) or result.get("binding_sha256")!=BINDING_SHA: return false
	var domain:=_domain(id)
	if result.get("domain")!=domain or result.get("packet_sha256")!=_binding.domains[domain].artifacts["packet.bin"].sha256: return false
	if _verified_token!=token:
		_parents.clear();_packets.clear();_sessions.clear();_npc_sessions.clear();_receipt_facts.clear();_frozen_ap_spec.clear()
	_verified_token=token;_self_sha_cached=result.self_sha256
	_parents[domain]=result.parent;_packets[domain]=result.child;_receipt_facts[domain]=result.facts
	if domain=="market": _frozen_ap_spec=result.ap_spec
	return true
static func root_requested(id: StringName) -> bool: return _ready() and not _domain(id).is_empty()
static func root_for(id: StringName) -> String:
	var d:=_domain(id);return _binding.domains[d].root if root_requested(id) else ""
static func entry(id: StringName) -> Dictionary:
	if not root_requested(id): return {}
	var index: Variant=load(AP_INDEX)
	if not index is GDScript: return {}
	var method_count: int=0
	for method: Dictionary in index.get_script_method_list():
		if method.name=="finite_geometry_entries": method_count+=1
	if method_count!=1: return {}
	var entries: Variant=index.finite_geometry_entries()
	if not entries is Dictionary: return {}
	var row: Variant=entries.get(String(id),{})
	if not row is Dictionary or row.size()!=2 or row.get("manifest_path")!=_binding.domains[_domain(id)].runtime_manifest_path or not row.get("manifest_sha256") is String or row.manifest_sha256.length()!=64: return {}
	return row.duplicate(true)
static func artifact_path(id: StringName,suffix: String) -> String:
	if not root_requested(id) or suffix not in ["scene.res","layout.res","packet.bin","walk.png","manifest.json"]: return ""
	var d: Dictionary=_binding.domains[_domain(id)]
	return d.runtime_manifest_path if suffix=="manifest.json" else String(d.artifacts[suffix].path)
static func _manifest_requested(id: StringName,raw: Dictionary,domain: String) -> bool:
	return _ready() and _domain(id)==domain and raw.get("geometry_proof_basis")==_binding.domains[domain].basis
static func _manifest_valid(id: StringName,raw: Dictionary,domain: String) -> bool:
	if not _manifest_requested(id,raw,domain): return false
	var immutable: Dictionary=_binding.domains[domain].manifest_immutable
	for key: String in immutable:
		if not raw.has(key) or not _same(raw[key],immutable[key]): return false
	return raw.get("publication_full_source_finalized")==true and raw.get("finite_source_closure_pending")==false and raw.get("formal_enabled")==true and raw.get("finite_art_admitted")==true
static func market_manifest_requested(id: StringName,raw: Dictionary) -> bool: return _manifest_requested(id,raw,"market")
static func market_manifest_valid(id: StringName,raw: Dictionary) -> bool: return _manifest_valid(id,raw,"market")
static func finite_yamen_manifest_requested(id: StringName,raw: Dictionary) -> bool: return _manifest_requested(id,raw,"yamen")
static func finite_yamen_manifest_valid(id: StringName,raw: Dictionary) -> bool: return _manifest_valid(id,raw,"yamen")
static func _authority_path(raw: Dictionary,path: String,domain: String) -> bool:
	return _manifest_valid(StringName(_binding.domains[domain].scene_id),raw,domain) and _binding.domains[domain].runtime_authority_paths.has(path)
static func market_runtime_authority_path_allowed(raw: Dictionary,path: String) -> bool: return _ready() and _authority_path(raw,path,"market")
static func finite_yamen_runtime_authority_path_allowed(raw: Dictionary,path: String) -> bool: return _ready() and _authority_path(raw,path,"yamen")
static func _packet_requested(id: StringName,config: Dictionary,data: Dictionary,domain: String) -> bool:
	return _manifest_requested(id,config,domain) and data.get("geometry_basis")==_binding.domains[domain].basis and data.get("scene_id")==String(id)
static func yamen_packet_requested(id: StringName,config: Dictionary,data: Dictionary) -> bool: return _packet_requested(id,config,data,"yamen")
static func market_packet_requested(id: StringName,config: Dictionary,data: Dictionary) -> bool: return _packet_requested(id,config,data,"market")
static func _native_packet_valid(id: StringName,data: Dictionary,config: Dictionary,scene: SceneScript,domain: String) -> bool:
	if not _packet_requested(id,config,data,domain) or not _manifest_valid(id,config,domain): return false
	var token: int=int(_c()._live_source_token)
	if token!=_verified_token or not _packets.has(domain) or not _same(data,_packets[domain]) or scene==null or scene.scene_id!=id or scene.map_layout==null: return false
	var d: Dictionary=_binding.domains[domain]
	if scene.resource_path!=d.artifacts["scene.res"].path or scene.map_layout.resource_path!=d.artifacts["layout.res"].path or not _same(_b().storage(scene),data.scene_storage) or not _same(_b().storage(scene.map_layout),data.layout_storage): return false
	_sessions[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(scene.map_layout),"domain":domain,"token":token}
	return true
static func yamen_native_packet_valid(id: StringName,data: Dictionary,config: Dictionary,scene: SceneScript) -> bool: return _native_packet_valid(id,data,config,scene,"yamen")
static func market_native_packet_valid(id: StringName,data: Dictionary,config: Dictionary,scene: SceneScript) -> bool: return _native_packet_valid(id,data,config,scene,"market")
static func _session_bound(scene: SceneScript,data: Dictionary,config: Dictionary,domain: String) -> bool:
	if not _ready() or scene==null or _domain(scene.scene_id)!=domain or scene.map_layout==null: return false
	var s: Dictionary=_sessions.get(scene.get_instance_id(),{})
	if s.is_empty() or s.domain!=domain or s.scene.get_ref()!=scene or s.layout.get_ref()!=scene.map_layout or s.token!=_verified_token: return false
	# B retains its private native data/config and checks full storage itself.
	# No B.bound/whole_bound/query recursion and no per-frame file/packet hash.
	return data.get("geometry_basis")==_binding.domains[domain].basis and config.get("geometry_proof_basis")==data.geometry_basis and scene.map_layout.walkable_mask_path==_binding.domains[domain].artifacts["walk.png"].path
static func yamen_session_bound(scene: SceneScript,data: Dictionary,config: Dictionary) -> bool: return _session_bound(scene,data,config,"yamen")
static func market_session_bound(scene: SceneScript,data: Dictionary,config: Dictionary) -> bool: return _session_bound(scene,data,config,"market")
static func _public_proof(scene: SceneScript,data: Dictionary,config: Dictionary,domain: String) -> Dictionary:
	if not _session_bound(scene,data,config,domain): return {}
	var proof: Dictionary=_c()._transition_validation
	var session: Dictionary=_sessions[scene.get_instance_id()]
	if proof.get("scene")!=scene or proof.get("id")!=scene.scene_id or int(proof.get("token",0))!=session.token or proof.get("record")!=_c()._records.get(String(scene.scene_id)) or not proof.get("sources") is Dictionary: return {}
	# This is source-FIRST, before DT.finalize. Never require resident/final here.
	for path: String in _receipt_facts[domain]:
		if proof.sources.get(path)!=_receipt_facts[domain][path]: return {}
	if proof.sources.get(SELF)!=_self_sha_cached or proof.sources.get(BINDING)!=BINDING_SHA: return {}
	return {"ok":true,"token":session.token,"packet_sha256":_binding.domains[domain].artifacts["packet.bin"].sha256,"binding_sha256":BINDING_SHA,"source_first_in_city_receipt":true}
static func yamen_public_session_proof(scene: SceneScript,data: Dictionary,config: Dictionary) -> Dictionary: return _public_proof(scene,data,config,"yamen")
static func market_public_session_proof(scene: SceneScript,data: Dictionary,config: Dictionary) -> Dictionary: return _public_proof(scene,data,config,"market")
static func market_packet_and_frozen_ap_ao_t_chain_valid(data: Dictionary,config: Dictionary) -> bool:
	return market_packet_requested(MARKET,config,data) and _packets.has("market") and _verified_token>0 and _same(data,_packets.market)
static func market_ap_ao_t_chain_proven(scene: SceneScript,data: Dictionary,state: Dictionary) -> bool:
	return _state_matches(scene,state,"market") and _same(data,_packets.market)
static func _state_matches(scene: SceneScript,state: Dictionary,domain: String) -> bool:
	if not _ready() or scene==null or state.get("ok")!=true or state.get("scene_instance")!=scene.get_instance_id() or scene.map_layout==null or state.get("layout_instance")!=scene.map_layout.get_instance_id(): return false
	var s: Dictionary=_sessions.get(scene.get_instance_id(),{})
	return not s.is_empty() and s.domain==domain and s.scene.get_ref()==scene and s.layout.get_ref()==scene.map_layout and state.get("token")==s.token and s.token==_verified_token and state.get("packet_sha256")==_binding.domains[domain].artifacts["packet.bin"].sha256 and state.get("binding_sha256")==BINDING_SHA
static func _copy_parent_pair(parent: Dictionary,domain: String) -> Dictionary:
	# Internal exact-domain schema: preserve TWO independent deep copies.
	# No source/session credit here; _map_parent calls only after all gates.
	if domain=="yamen":
		return {"ok":true,"current_t_record":parent.duplicate(true),"frozen_t_record":parent.duplicate(true)}
	if domain=="market":
		return {"ok":true,"current_ap_record":parent.duplicate(true),"frozen_ap_record":parent.duplicate(true)}
	return {}
static func _map_parent(scene: SceneScript,current: Dictionary,data: Dictionary,state: Dictionary,domain: String) -> Dictionary:
	if domain not in ["yamen","market"]: return {}
	if not _state_matches(scene,state,domain) or not _same(data,_packets[domain]): return {}
	var child: Dictionary=data.record.duplicate(true)
	for key: String in ["assembled_runtime_binding_sha","assembled_parent_task_semantics_preserved","annex_runtime_binding_sha","annex_parent_semantics_unchanged"]:
		if not current.has(key): child.erase(key)
	if not _same(current,child): return {}
	var parent: Dictionary=_parents[domain].record.duplicate(true)
	for key: String in ["assembled_runtime_binding_sha","assembled_parent_task_semantics_preserved","annex_runtime_binding_sha","annex_parent_semantics_unchanged"]:
		if not current.has(key): parent.erase(key)
	return _copy_parent_pair(parent,domain)
static func map_child_to_frozen_t(scene: SceneScript,current: Dictionary,data: Dictionary,state: Dictionary) -> Dictionary: return _map_parent(scene,current,data,state,"yamen")
static func market_map_child_to_frozen_ap(scene: SceneScript,current: Dictionary,data: Dictionary,state: Dictionary) -> Dictionary: return _map_parent(scene,current,data,state,"market")
static func yamen_layout_author(scene: SceneScript,state: Dictionary) -> Dictionary:
	return _binding.frozen_t_author.duplicate(true) if _state_matches(scene,state,"yamen") else {}
static func market_district_parent_matches(original: Dictionary,spec: Dictionary,state: Dictionary) -> bool:
	if not _ready() or state.get("binding_sha256")!=BINDING_SHA or state.get("token")!=_verified_token or state.get("packet_sha256")!=_binding.domains.market.artifacts["packet.bin"].sha256: return false
	var expected: Dictionary=load(_binding.geometry_helper_path).project(_binding.frozen_district_author,MARKET)
	expected=load(_binding.t_transform_path).district_projection(expected,MARKET,_binding.frozen_t_author)
	return not expected.is_empty() and _same(original,expected) and _same(spec,_frozen_ap_spec)
static func _render_storage(rows: Array) -> Dictionary:
	var graph: Dictionary={"seen":{},"resources":[],"invalid":null}
	var encoded: Variant=_b()._storage_value(rows,graph)
	return encoded if graph.invalid==null and graph.resources.is_empty() and encoded is Dictionary else {}
static func finite_parent_visual_admission(scene: SceneScript,parent_objects: Array,state: Dictionary) -> Dictionary:
	if not _state_matches(scene,state,"yamen") or not _same(_render_storage(parent_objects),_packets.yamen.layout_storage.fields.visual_objects): return {}
	return {"ok":true,"ids":YAMEN_IDS.duplicate()}
static func market_retired_entry_proven(scene: SceneScript,id: String,parent_objects: Array,state: Dictionary) -> bool:
	return id==WEST_WALL and _state_matches(scene,state,"market") and _same(_render_storage(parent_objects),_packets.market.layout_storage.fields.visual_objects)
static func native_low_prop_role_valid(id: StringName,object: Dictionary) -> bool:
	if not _ready() or id!=YAMEN or not _packets.has("yamen") or object.get("id") not in YAMEN_IDS: return false
	for row: Dictionary in _packets.yamen.record.objects:
		if row.get("id")==object.id:
			return _same(row,object) and object.get("role")=="yamen_low_prop" and object.get("blocking")==true and object.get("ghost_occlusion")==false and object.get("height_behavior")=="LOW_OPAQUE_ACTOR_LOCAL_GHOST" and object.get("walk_support")==false and object.get("collision_size_px")==Vector2.ZERO and object.get("sort_by_feet")==true and object.get("solid_polygons_px",[]).size()==1
	return false
static func prepare_npc_overlay(scene: SceneScript,sources: Dictionary,projected: Dictionary,owner: Callable,state: Dictionary) -> bool:
	if not owner.is_valid() or not owner.call() or not _state_matches(scene,state,"yamen"): return false
	var overlay: Dictionary=_binding.clerk_overlay
	if not _same(projected.spec.crowd,overlay.old_spec.crowd): return false
	for path: String in _receipt_facts.yamen:
		if sources.get(path)!=_receipt_facts.yamen[path]: return false
	var original: Dictionary=_binding.frozen_district_author.districts[String(YAMEN)]
	if not _same(overlay.old_spec,original) or overlay.new_spec.crowd.size()!=6: return false
	var inverse: Dictionary=overlay.new_spec.duplicate(true)
	if inverse.crowd[3].get("id")!="yamen_clerk" or inverse.crowd[3].get("name")!="书办" or inverse.crowd[3].get("family")!="merchant": return false
	if _row_helper_handle.same_typed(inverse.crowd[3].foot_px,overlay.after)!=true: return false
	inverse.crowd[3].foot_px=overlay.before.duplicate()
	if not _same(inverse,overlay.old_spec) or not owner.call(): return false
	_npc_sessions[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(scene.map_layout),"token":state.token,"owner":owner}
	return true
static func project_bound_npcs(scene: SceneScript,rows: Array,_sources: Dictionary,receipt: Dictionary,state: Dictionary) -> Dictionary:
	if not _state_matches(scene,state,"yamen"): return {}
	var s: Dictionary=_npc_sessions.get(scene.get_instance_id(),{})
	if s.is_empty() or s.scene.get_ref()!=scene or s.layout.get_ref()!=scene.map_layout or s.token!=state.token or receipt.get("owner_token")!=state.token or not s.owner.is_valid() or not s.owner.call(): return {}
	return _row_helper_handle.compose_preparation_only(YAMEN,rows)
static func control_source_paths() -> Dictionary:
	return {SELF:true,BINDING:true,AP_INDEX:true}
static func source_paths_for(id: StringName) -> Dictionary:
	if not root_requested(id): return {}
	var paths:=control_source_paths()
	for path: String in _binding.shared_source_sha256: paths[path]=true
	for path: String in _binding.domains[_domain(id)].source_sha256: paths[path]=true
	return paths