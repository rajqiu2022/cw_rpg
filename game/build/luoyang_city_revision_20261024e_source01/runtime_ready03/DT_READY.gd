extends RefCounted
const MARKET_BLOCK_PATH="res://build/luoyang_city_revision_20261024e_source01/runtime_ready03/market_block_session_READY.gd"
const MARKET_BLOCK_SHA="d29602487f69e0dd5a82dcdb2bf76fb9928f64319e0bae0c0d06cc806f4775ea"
static var _market_block_handle: Variant=null
static func _market_block_runtime() -> Variant:
	if _market_block_handle!=null: return _market_block_handle
	if FileAccess.get_sha256(MARKET_BLOCK_PATH)!=MARKET_BLOCK_SHA: return null
	var value: Variant=load(MARKET_BLOCK_PATH)
	if not value is GDScript or value.resource_path!=MARKET_BLOCK_PATH: return null
	_market_block_handle=value;return value
const YAMEN_COURTS_PATH="res://build/luoyang_yamen_courts_20261024c_system01/runtime04_READY/courts_session_READY.gd"
const YAMEN_COURTS_SHA="791ae73e97623e71c0a0445f7a60cd14b6bf8f17453e7fa77dd9d0a89a873c4a"
static var _yamen_courts_handle: Variant=null
static func _yamen_courts_runtime() -> Variant:
	if _yamen_courts_handle!=null: return _yamen_courts_handle
	if FileAccess.get_sha256(YAMEN_COURTS_PATH)!=YAMEN_COURTS_SHA: return null
	var value: Variant=load(YAMEN_COURTS_PATH)
	if not value is GDScript or value.resource_path!=YAMEN_COURTS_PATH: return null
	_yamen_courts_handle=value;return value
const FINITE_ADAPTER_PATH := "res://build/luoyang_city_space_20261024b_source01/worker_facts03/adapter_CANDIDATE.gd"
const FINITE_ADAPTER_SHA := "86cf9d3b73e01436c4459701bad15fb51f09e17cea037fca8c208f4606b7cf29"
static var _finite_adapter_handle: Variant=null
static func _finite_native_adapter() -> Variant:
	if _finite_adapter_handle!=null: return _finite_adapter_handle
	if FileAccess.get_sha256(FINITE_ADAPTER_PATH)!=FINITE_ADAPTER_SHA: return null
	var value: Variant=load(FINITE_ADAPTER_PATH)
	if not value is GDScript or value.resource_path!=FINITE_ADAPTER_PATH: return null
	_finite_adapter_handle=value;return value
## One Field-owned additive lease. No Scene/record/nav alias or cross-field cache.
const MARKET_SPACE_PATH="res://build/luoyang_city_space_20261024b_source01/worker_facts03/runtime_CANDIDATE.gd"
const MARKET_SPACE_SHA="08ca68dded03ba7da17d824d626cf83c59e927ecf9f87526ef2a1a4995d376aa"
static var _market_space_handle: Variant=null
static func _market_space_runtime() -> Variant:
	if _market_space_handle!=null: return _market_space_handle
	if FileAccess.get_sha256(MARKET_SPACE_PATH)!=MARKET_SPACE_SHA: return null
	var value: Variant=load(MARKET_SPACE_PATH)
	if not value is GDScript or value.resource_path!=MARKET_SPACE_PATH: return null
	_market_space_handle=value;return value
const AP_NPC=preload("res://build/luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd")
const G=preload("res://scripts/city/luoyang_district_life_geometry_20261016f.gd")
const CROWD=preload("res://scripts/city/luoyang_district_life_crowd_20261016f.gd")
const SPACING=preload("res://scripts/city/luoyang_building_spacing_20261017p.gd")
const FLAG="--luoyang-district-life-20261016f"
const FORMAL_ENABLED=true
const SELF="res://scripts/city/luoyang_district_life_20261016f.gd"
const AUTHOR_PATH="res://data/maps/luoyang_district_life_20261016f/author.json"
const BIND_PATH="res://data/maps/luoyang_district_life_20261016f/binding.json"
const BIND_SHA="8bce718d3bfb363d15b9845aeedd113e02ff7cf7ef107ca94d3983363f33b668"
const IDS=[&"ch4_s0_luoyang_gate",&"ch4_s1_luoyang_yamen",&"ch4_s2_canal_docks",&"ch4_s3_luoyang_market"]
var projected: Dictionary={}
var parent_render: Array=[]
var _solids: Array[PackedVector2Array]=[]
var _bounds: Array[Rect2]=[]
var _scene: SceneScript
var _sources: Dictionary={}
var _textures: Dictionary={}
var _market_ground: Dictionary={}
var _yamen_courts: Dictionary={}
var _market_blocks: Dictionary={}
var _config: Dictionary={}
var _receipt: Dictionary={"matched":false,"finalized":false}
var error: String=""
var _loading_timings: Dictionary={}
func _loading_clock() -> Dictionary:
	return {"usec":Time.get_ticks_usec(),"process_frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames()}
func _loading_span(label: String,started: Dictionary,details: Dictionary={}) -> void:
	# Measurement only. Preserve the first setup invocation, not later refreshes.
	if _loading_timings.is_empty() or _loading_timings.spans.has(label): return
	var finished: Dictionary=_loading_clock()
	_loading_timings.spans[label]={"started_usec":started.usec,"finished_usec":finished.usec,"wall_usec":finished.usec-started.usec,"process_frames":finished.process_frame-started.process_frame,"physics_frames":finished.physics_frame-started.physics_frame,"includes_existing_awaits":true,"details":details.duplicate(true)}
	_loading_timings.order.append(label)
func loading_timing_state() -> Dictionary:
	var result: Dictionary=_loading_timings.duplicate(true)
	if result.is_empty(): return result
	result["setup_identity_current"]=_scene!=null and result.get("scene_instance")==_scene.get_instance_id() and _scene.map_layout!=null and result.get("layout_instance")==_scene.map_layout.get_instance_id()
	result["fresh_source_validation_credit"]=false
	return result
static func enabled() -> bool: return FORMAL_ENABLED or FLAG in OS.get_cmdline_user_args()
static func requested(id: StringName) -> bool: return enabled() and id in IDS
static func binding() -> Dictionary:
	if BIND_SHA.length()!=64 or FileAccess.get_sha256(BIND_PATH)!=BIND_SHA: return {}
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(BIND_PATH))
	return raw if raw is Dictionary and raw.get("status")=="READY_SOURCE_BOUND_DISTRICT_LIFE" and not raw.get("source_sha256",{}).is_empty() else {}
static func author(config: Dictionary) -> Dictionary:
	if config.is_empty() or FileAccess.get_sha256(AUTHOR_PATH)!=config.get("author_sha256",""): return {}
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR_PATH))
	return raw if raw is Dictionary and raw.get("status")=="READY_AUTHORED_DISTRICT_LIFE" and raw.get("districts",{}).size()==4 else {}
static func cpu_proof_valid(config: Dictionary,data: Dictionary) -> bool:
	var path: String=String(config.get("cpu_proof_path","")); var sha: String=String(config.get("cpu_proof_sha256",""))
	if not path.begins_with("res://build/luoyang_district_life_publication_20261016f/") or ".." in path or sha.length()!=64 or config.get("source_sha256",{}).get(path)!=sha or FileAccess.get_sha256(path)!=sha: return false
	var proof: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not proof is Dictionary or proof.get("passed")!=true or proof.get("status")!="BOUNDED_CPU_NEW_DELTA_PROOF_NOT_RUNTIME" or proof.get("old_nav_unchanged")!=true or proof.get("author_sha256")!=config.author_sha256 or not G._c()._equal_value(proof.get("rows"),config.get("cpu_audit")): return false
	if proof.get("source_sha256",{}).is_empty() or proof.get("rows",{}).size()!=4: return false
	for source: String in proof.source_sha256:
		if config.source_sha256.get(source)!=proof.source_sha256[source]: return false
	var seen: Dictionary={}; var proofs: Dictionary=config.get("texture_proofs",{})
	if proofs.size()!=6 or data.assets.size()!=6: return false
	for asset: Dictionary in data.assets.values():
		var texture: String=String(asset.texture); var row: Dictionary=proofs.get(texture,{})
		if seen.has(texture) or row.get("full_rgba_exact")!=true or row.get("params23")!=true or G.v(row.get("size_px"))!=G.v(asset.size_px) or row.get("import_path")!=texture+".import": return false
		for pair: Array in [[texture,row.get("source_sha256")],[row.get("import_path"),row.get("import_sha256")],[row.get("compiled_path"),row.get("compiled_sha256")]]:
			if not pair[0] is String or not pair[1] is String or pair[1].length()!=64 or config.source_sha256.get(pair[0])!=pair[1]: return false
		seen[texture]=true
	return true
static func source_paths() -> Dictionary:
	var config:=binding()
	if config.is_empty(): return {}
	var out: Dictionary={SELF:true,BIND_PATH:true,AUTHOR_PATH:true,"res://build/luoyang_layout_quest_20261018t_layout_source01/layout_transform_retry2.gd":true,"res://build/luoyang_layout_quest_20261018t_layout_source01/author_retry2.json":true,"res://scripts/city/luoyang_district_life_geometry_20261016f.gd":true,"res://scripts/city/luoyang_district_life_fade_20261016f.gd":true}
	out.merge(CROWD.source_paths())
	for path: String in config.source_sha256:
		if not path.begins_with("res://") or ".." in path: return {}
		out[path]=true
	return out
static func _proof(scene: SceneScript) -> Dictionary:
	var c: Variant=G._c()
	for proof: Dictionary in [c._transition_validation,c._resident_ready]:
		if proof.get("scene")==scene and proof.get("record")==c._records.get(String(scene.scene_id)): return proof
	return {}
static func _same_wire(left: Variant,right: Variant) -> bool:
	return G._c()._equal_value(JSON.parse_string(JSON.stringify(left,"\t",true,true)),right)
static func _published_source_matches(scene: SceneScript,proof: Dictionary,path: String,prior_sha: String) -> bool:
	var actual: String=String(proof.get("sources",{}).get(path,""))
	if actual==prior_sha: return true
	if load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd").ao_fade_source_matches(scene,proof,path,prior_sha): return true
	# One explicit executable successor, NOT a current-file SHA fallback. Keep
	# the original CPU proof/config immutable and admit the published mapping.
	var fade: String="res://scripts/city/luoyang_district_life_fade_20261016f.gd"
	var old_sha: String="f359a43a88470ff220fa095cbd7f73ea04637c55c2faadd0a3b5f325e4b7a244"
	var new_sha: String="bc2958cc8f9a60ac9952891c30037441a62e289d8fee2fa235e6b864abf3a1bf"
	var candidate: String="res://build/luoyang_layout_quest_20261018t_layout_source01/District_fade_candidate.gd"
	if path!=fade or prior_sha!=old_sha or actual!=new_sha: return false
	var bundle: Variant=load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
	if scene==null or proof.get("scene")!=scene or proof.get("id")!=scene.scene_id or int(proof.get("token",0))<=0 or proof.get("proof_kind")!=bundle.KIND: return false
	var config: Dictionary=bundle.describe(scene.scene_id,proof.get("sources",{}))
	if config.is_empty() or config.get("scene_id")!=String(scene.scene_id): return false
	# Only transformed scenes have a bundle session. Gate/Docks UNCHANGED
	# retain the existing parent-bound check plus the actual C proof above.
	if scene.has_meta("luoyang_layout_quest_20261018t") and not bundle.whole_bound(scene): return false
	var delta: Dictionary=config.get("source_migration",{}).get("source_delta",{}).get(path,{})
	var history: Variant=delta.get("historical_sha256",[])
	return history is Array and old_sha in history and delta.get("new_sha256")==new_sha and delta.get("candidate_path")==candidate and config.get("legacy_source_sha256",{}).get(path)==new_sha and FileAccess.get_sha256(path)==new_sha and FileAccess.get_sha256(candidate)==new_sha
static func _parent_bound(scene: SceneScript) -> bool:
	if scene!=null and scene.scene_id==&"ch4_s2_canal_docks" and scene.has_meta("luoyang_docks_district08_20261019aa"):
		return load("res://scripts/city/luoyang_docks_district08_20261019aa.gd").bound(scene)
	if scene!=null and scene.has_meta("luoyang_layout_quest_20261018t"): return load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd").whole_bound(scene)
	if scene==null or not G._c().is_v3(scene): return false
	var id: String=String(scene.scene_id)
	if id=="ch4_s3_luoyang_market": return load("res://scripts/city/luoyang_city_assembled_runtime_20261016b.gd").bound(scene)
	if id=="ch4_s1_luoyang_yamen": return load("res://scripts/city/luoyang_yamen_annex_runtime_20261016.gd").bound(scene)
	return id in ["ch4_s0_luoyang_gate","ch4_s2_canal_docks"] and load("res://scripts/city/luoyang_harbour_life_runtime_20261016.gd").bound(scene)
func prepare(scene: SceneScript,original_render: Array,owner: Callable,field: Node=null) -> bool:
	_loading_timings={"profile_origin":"DISTRICT_SETUP_NOT_WARM_RESUME","scene_id":String(scene.scene_id) if scene!=null else "","scene_instance":scene.get_instance_id() if scene!=null else 0,"layout_instance":scene.map_layout.get_instance_id() if scene!=null and scene.map_layout!=null else 0,"transition_token":0,"fresh_source_validation_credit":false,"order":[],"spans":{}}
	var loading_started: Dictionary=_loading_clock()
	if not owner.is_valid() or not owner.call() or not requested(scene.scene_id) or not _parent_bound(scene): return _reject("DISTRICT_PARENT_OR_OWNER")
	_loading_span("owner_and_parent_bound",loading_started)
	loading_started=_loading_clock()
	_config=binding(); var data:=author(_config)
	if data.is_empty() or not cpu_proof_valid(_config,data): return _reject("DISTRICT_BINDING_OR_CPU_PROOF_PENDING_OR_CHANGED")
	_loading_span("binding_author_and_cpu_proof",loading_started)
	loading_started=_loading_clock()
	var proof:=_proof(scene)
	if proof.is_empty(): return _reject("DISTRICT_ORIGINAL_CITY_RECEIPT_MISSING")
	_loading_timings.transition_token=int(proof.get("token",0))
	for path: String in _config.source_sha256:
		if not _published_source_matches(scene,proof,path,_config.source_sha256[path]): return _reject("DISTRICT_SOURCE_NOT_IN_CITY_FIRST:"+path)
	for path: String in source_paths():
		if not proof.sources.has(path): return _reject("DISTRICT_INCOMPLETE_SOURCE_SET:"+path)
	_sources=proof.sources.duplicate(true); _scene=scene
	_loading_span("complete_source_identity_and_paths",loading_started)
	loading_started=_loading_clock()
	var projection_detail_started: Dictionary=_loading_clock()
	projected=G.project(data,scene.scene_id)
	_loading_span("projection_detail.g_project",projection_detail_started)
	if scene.has_meta("luoyang_layout_quest_20261018t"):
		projection_detail_started=_loading_clock()
		var t_author: Dictionary=load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd").layout_author(scene)
		_loading_span("projection_detail.layout_author",projection_detail_started)
		if t_author.is_empty(): return _reject("T_AUTHOR_ABSENT")
		projection_detail_started=_loading_clock()
		projected=load("res://build/luoyang_layout_quest_20261018t_layout_source01/layout_transform_retry2.gd").district_projection(projected,scene.scene_id,t_author)
		_loading_span("projection_detail.t_transform",projection_detail_started)
	if scene.has_meta("luoyang_market_full_rollout_20261022ap"):
		projection_detail_started=_loading_clock()
		projected=load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd").ap_district_projection(scene,projected)
		_loading_span("projection_detail.ap_project",projection_detail_started)
	if projected.is_empty(): return _reject("DISTRICT_AUTHOR_PROJECT_REFUSED")
	projection_detail_started=_loading_clock()
	var expected: Dictionary=projected.parent.duplicate(true)
	var current: Dictionary=G._c()._records.get(String(scene.scene_id),{}).duplicate(true)
	# Only these already-published parent's runtime receipts are outside its
	# frozen JSON record. Their values remain explicitly bound, not ignored.
	var receipts: Dictionary={}
	if scene.scene_id==&"ch4_s3_luoyang_market": receipts={"assembled_runtime_binding_sha":load("res://scripts/city/luoyang_city_assembled_runtime_20261016b.gd").BIND_SHA,"assembled_parent_task_semantics_preserved":true}
	elif scene.scene_id==&"ch4_s1_luoyang_yamen": receipts={"annex_runtime_binding_sha":load("res://scripts/city/luoyang_yamen_annex_runtime_20261016.gd").BIND_SHA,"annex_parent_semantics_unchanged":true}
	else: receipts={"harbour_runtime_binding_sha":load("res://scripts/city/luoyang_harbour_life_runtime_20261016.gd").BIND_SHA,"harbour_parent_task_semantics_preserved":true}
	for key: String in receipts:
		if current.get(key)!=receipts[key]: return _reject("DISTRICT_PARENT_RUNTIME_RECEIPT:"+key)
		current.erase(key)
	_loading_span("projection_detail.parent_clones_and_receipts",projection_detail_started)
	if scene.scene_id==&"ch4_s2_canal_docks" and scene.has_meta("luoyang_docks_district08_20261019aa"):
		projection_detail_started=_loading_clock()
		current=load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd").restore_parent_record(scene,current,expected)
		_loading_span("projection_detail.b_restore_aa",projection_detail_started)
		if current.is_empty(): return _reject("AA_COMPLETE_REMOVE_TWO_PARENT_MAPPING")
	if scene.has_meta(SPACING.META):
		current=SPACING.restore_parent_record(current,expected,scene)
		if current.is_empty(): return _reject("DISTRICT_SPACING_EXACT_REMOVE_ONE_PARENT_MAPPING")
	if scene.has_meta("luoyang_layout_quest_20261018t"):
		projection_detail_started=_loading_clock()
		current=load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd").restore_parent_record(scene,current,expected)
		_loading_span("projection_detail.b_restore_t",projection_detail_started)
		if current.is_empty(): return _reject("T_COMPLETE_REVERSIBLE_PARENT_RECORD")
	projection_detail_started=_loading_clock()
	if not _same_wire(current,expected): return _reject("DISTRICT_COMPLETE_PARENT_RECORD_CHANGED")
	_loading_span("projection_detail.same_wire",projection_detail_started)
	if not _config.get("cpu_audit",{}).get(String(scene.scene_id),{}).get("passed",false): return _reject("DISTRICT_CPU_AUDIT_NOT_PASSED")
	if scene.scene_id==&"ch4_s3_luoyang_market":
		var space_runtime: Variant=_market_space_runtime()
		if space_runtime==null: return _reject("MARKET_SPACE_RUNTIME_SOURCE_CHANGED")
		if space_runtime.requested(scene):
			projected=space_runtime.project_district(scene,projected,_sources,owner)
			if projected.is_empty(): return _reject("MARKET_SPACE_EXACT_DISTRICT_PROJECTION_REFUSED")
	_loading_span("projection_and_whole_parent_inverse",loading_started)
	loading_started=_loading_clock()
	parent_render=original_render.duplicate(true); _solids=G.delta_solids(projected)
	for poly: PackedVector2Array in _solids:
		var low: Vector2=poly[0]; var high: Vector2=poly[0]
		for point: Vector2 in poly: low=low.min(point); high=high.max(point)
		_bounds.append(Rect2(low,high-low))
	var assets: Dictionary=data.assets; var used: Dictionary={}
	for item: Dictionary in projected.additions+projected.replacements: used[String(assets[item.district_life_asset_id].texture)]=true
	_loading_span("physical_delta_and_texture_list",loading_started,{"used_texture_count":used.size()})
	for path: String in used:
		var texture_started: Dictionary=_loading_clock()
		if not owner.call(): return _reject("DISTRICT_TEXTURE_OWNER_CHANGED")
		var row: Dictionary=_config.get("texture_proofs",{}).get(path,{})
		var texture:=ResourceLoader.load(path) as Texture2D
		var image: Image=texture.get_image() if texture!=null else null
		if row.is_empty() or image==null or image.get_size()!=Vector2i(row.size_px[0],row.size_px[1]): return _reject("DISTRICT_TEXTURE_SIZE:"+path)
		_loading_span("texture_readback:"+path,texture_started,{"texture_path":path,"width_px":int(row.size_px[0]),"height_px":int(row.size_px[1])})
		texture_started=_loading_clock()
		image.convert(Image.FORMAT_RGBA8)
		if G._c()._transition_bytes_sha(image.get_data())!=row.get("rgba_sha256",""): return _reject("DISTRICT_ACTUAL_RGBA:"+path)
		_textures[path]=texture; image=null
		_loading_span("texture_convert_and_full_rgba_hash:"+path,texture_started,{"texture_path":path})
		texture_started=_loading_clock()
		await (Engine.get_main_loop() as SceneTree).process_frame
		_loading_span("texture_existing_frame_await:"+path,texture_started,{"texture_path":path})
	loading_started=_loading_clock()
	var yamen_state: Dictionary=load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd").finite_yamen_child_state(scene)
	if yamen_state.get("requested",false):
		if yamen_state.get("ok")!=true: return _reject("YAMEN_FINITE_SESSION_REFUSED")
		var yamen_adapter: Variant=_finite_native_adapter()
		if yamen_adapter==null or not yamen_adapter.prepare_npc_overlay(scene,_sources,projected,owner,yamen_state): return _reject("YAMEN_FINITE_NPC_OVERLAY_REFUSED")
	if scene.scene_id==&"ch4_s1_luoyang_yamen":
		var courts: Variant=_yamen_courts_runtime()
		if courts==null: return _reject("YAMEN_COURTS_RUNTIME_SOURCE_CHANGED")
		_yamen_courts=courts.acquire(scene,field,self,owner,_sources,proof,yamen_state,G.apply_render(parent_render,projected))
		if _yamen_courts.get("ok")!=true: return _reject(String(_yamen_courts.get("error","YAMEN_COURTS_LEASE_REFUSED")))
		_solids.assign(courts.district_solids(scene));_bounds.clear()
		for poly: PackedVector2Array in _solids:
			var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
			for point: Vector2 in poly: low=low.min(point);high=high.max(point)
			_bounds.append(Rect2(low,high-low))
	_loading_span("finite_session_and_npc_overlay_prepare",loading_started)
	loading_started=_loading_clock()
	var npcs:=CROWD.project(projected.spec.crowd)
	if scene.scene_id==&"ch4_s3_luoyang_market" and scene.has_meta("luoyang_layout_quest_20261018t"):
		var ground: Variant=load("res://scripts/city/luoyang_market_ground_20261020ae.gd")
		_market_ground=ground.prepare(scene,_sources,G.apply_render(parent_render,projected),owner)
		if _market_ground.get("ok")!=true: return _reject(String(_market_ground.get("error","MARKET_GROUND_REFUSED")))
		for path: String in _market_ground.textures:
			if _textures.has(path): return _reject("MARKET_GROUND_PARENT_TEXTURE_COLLISION")
			_textures[path]=_market_ground.textures[path]
	if scene.scene_id==&"ch4_s3_luoyang_market":
		var blocks: Variant=_market_block_runtime()
		if blocks==null: return _reject("MARKET24E_RUNTIME_SOURCE")
		_market_blocks=blocks.acquire(scene,field,self,owner,_sources,proof,G.apply_render(parent_render,projected))
		if _market_blocks.get("ok")!=true: return _reject(String(_market_blocks.get("error","MARKET24E_ACQUIRE")))
		_solids.assign(blocks.solids(scene));_bounds.clear()
		for shape: PackedVector2Array in _solids:
			var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
			for point: Vector2 in shape: low=low.min(point);high=high.max(point)
			_bounds.append(Rect2(low,high-low))
	if npcs.size()!=projected.spec.crowd.size(): return _reject("DISTRICT_CROWD_AUTHOR")
	_receipt={"matched":true,"finalized":false,"scene_id":String(scene.scene_id),"scene_instance":scene.get_instance_id(),"binding_sha256":BIND_SHA,"author_sha256":_config.author_sha256,"source_first_in_city_receipt":true,"source_count":_sources.size(),"texture_verified":used.size(),"physical_delta_count":_solids.size(),"new_object_ids":[],"replacement_ids":[],"new_npc_ids":[],"owner_token":int(proof.get("token",0)),"old_nav_unchanged":true}
	if not _yamen_courts.is_empty():
		_receipt.old_nav_unchanged=false;_receipt["native_artifacts_unchanged"]=true
		_receipt["yamen_courts"]=_yamen_courts_runtime().state(scene)
	if not _market_blocks.is_empty():
		_receipt.old_nav_unchanged=false;_receipt["native_artifacts_unchanged"]=true
		_receipt["market_blocks"]=_market_block_runtime().state(scene)
		_receipt["full_combined_physical_overlay"]=true
	for item: Dictionary in projected.additions: _receipt.new_object_ids.append(String(item.id))
	for item: Dictionary in projected.replacements: _receipt.replacement_ids.append(String(item.id))
	for npc: Dictionary in npcs: _receipt.new_npc_ids.append(npc.npc_id)
	_loading_span("crowd_ground_and_receipt",loading_started)
	return true if owner.call() else _reject("DISTRICT_PREPARE_OWNER_CHANGED")
func render_objects(original: Array) -> Array:
	var started: Dictionary=_loading_clock()
	var result: Array=_render_objects_for_loading(original)
	_loading_span("visual_render_projection",started)
	return result
func _render_objects_for_loading(original: Array) -> Array:
	if _scene==null: return []
	var result: Array=G.apply_render(original,projected)
	if not _yamen_courts.is_empty(): return _yamen_courts_runtime().apply_cached_render(_scene,result)
	if _scene.scene_id==&"ch4_s3_luoyang_market" and not _market_ground.is_empty():
		var original_ground: Array=load("res://scripts/city/luoyang_market_ground_20261020ae.gd").render(result,_market_ground)
		if not _market_blocks.is_empty(): return _market_block_runtime().render_with_ground(_scene,result,original_ground)
		return original_ground
	return result
func navigation_objects(original: Array) -> Array:
	var started: Dictionary=_loading_clock()
	var result: Array=G.apply_render(original,projected) if _scene!=null else []
	if not _yamen_courts.is_empty(): result=_yamen_courts_runtime().apply_cached_render(_scene,result)
	if not _market_blocks.is_empty(): result=_market_block_runtime().render(_scene,result)
	_loading_span("navigation_render_projection",started)
	return result
func npcs() -> Array:
	var started: Dictionary=_loading_clock()
	var result: Array=_npcs_for_loading()
	_loading_span("npc_presentation_and_finite_projection",started)
	return result
func _npcs_for_loading() -> Array:
	if _scene==null: return []
	var result: Dictionary=AP_NPC.project(_scene.scene_id,CROWD.project(projected.spec.crowd))
	if result.get("ok")!=true: return []
	var yamen_state: Dictionary=load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd").finite_yamen_child_state(_scene)
	if yamen_state.get("requested",false):
		if yamen_state.get("ok")!=true: return []
		var yamen_adapter: Variant=_finite_native_adapter()
		if yamen_adapter==null: return []
		var moved: Dictionary=yamen_adapter.project_bound_npcs(_scene,result.npcs,_sources,_receipt,yamen_state)
		return moved.npcs if moved.get("ok")==true else []
	return result.npcs
func safe_foot(foot: Vector2,full: bool=false) -> bool:
	if _scene==null or not foot.is_finite(): return false
	if not _yamen_courts.is_empty() and not _yamen_courts_runtime().lease_bound(_scene,self): return false
	if not _market_blocks.is_empty() and not _market_block_runtime().lease_bound(_scene,self): return false
	# Geometry is compiled once per Field. Per-frame queries do not read files,
	# rebuild author polygons, scan875 pixels, or allocate offscreen polygons.
	var body:=Rect2(foot-Vector2(17,12),Vector2(34,24))
	var near: Array[PackedVector2Array]=[]
	for i: int in _bounds.size():
		if body.intersects(_bounds[i],true): near.append(_solids[i])
	return G.safe_foot(near,foot,Vector2(17,12),full)
func texture_matches(path: String,texture: Texture2D) -> bool: return not _textures.has(path) or _textures[path]==texture
func finalize(scene: SceneScript) -> bool:
	var proof:=_proof(scene)
	if scene!=_scene or proof.is_empty() or not G._c()._equal_value(_sources,proof.sources) or (proof.get("live_scope",false) and proof.get("sources_finalized")!=true): return _reject("DISTRICT_FINAL_CITY_OWNER_OR_SOURCE")
	if not _yamen_courts.is_empty():
		if not _yamen_courts_runtime().finalize(scene,self,_sources): return _reject("YAMEN_COURTS_FINAL_SOURCE_OR_OWNER")
		_receipt.yamen_courts=_yamen_courts_runtime().state(scene)
	if not _market_blocks.is_empty():
		if not _market_block_runtime().finalize(scene,self,_sources): return _reject("MARKET24E_FINAL_SOURCE_OR_OWNER")
		_receipt.market_blocks=_market_block_runtime().state(scene)
	_receipt.finalized=true; return true
func state() -> Dictionary: return _receipt.duplicate(true)
func effective_mask(scene: SceneScript) -> Image:
	if scene==_scene and not _market_blocks.is_empty(): return _market_block_runtime().effective_mask(scene)
	if scene!=_scene or _yamen_courts.is_empty(): return null
	return _yamen_courts_runtime().effective_mask(scene)
func release() -> void:
	if not _market_blocks.is_empty() and _market_block_handle!=null: _market_block_handle.release(_scene,self)
	_market_blocks.clear()
	if not _yamen_courts.is_empty() and _yamen_courts_handle!=null: _yamen_courts_handle.release(_scene,self)
	_yamen_courts.clear()
	_market_ground.clear()
	_scene=null; _textures.clear(); _solids.clear(); _bounds.clear(); projected.clear(); parent_render.clear(); _sources.clear(); _config.clear()
	_receipt["released"]=true
func _reject(message: String) -> bool:
	error=message; _receipt["error"]=message; _receipt["finalized"]=false; release(); return false

