extends RefCounted
## Exactly two-domain child; no cross-transition proof cache, no old asset edit.
const AP_NPC=preload("res://build/luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd")
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const A=preload("res://scripts/city/luoyang_harbour_life_author_retry3_20261016.gd")
const G=preload("res://scripts/city/luoyang_harbour_life_geometry_retry3_20261016.gd")
const CROWD=preload("res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd")
const SERIAL=preload("res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd")
const WATER=preload("res://scripts/city/luoyang_harbour_water_patch_20261016.gd")
const SPACING=preload("res://scripts/city/luoyang_building_spacing_20261017p.gd")
const FLAG="--luoyang-harbour-life-20261016"
const FORMAL_ENABLED=true
const META="city_harbour_life_runtime_binding_sha_20261016"
const BIND_PATH="res://data/maps/luoyang_harbour_life_20261016/runtime_bindings.json"
const BIND_SHA="4a2e9a4985c0548672f00e8fee46c33588da5f27d0c803a345d32a2f86704bca"
const CITIES={"ch4_s0_luoyang_gate":{"author_sha256":"3a0eba1052f64f0664dff19a322c7c783f74459ffc862c0be125c7c7d6201f3e","manifest_path":"res://build/luoyang_harbour_life_publication_20261016/93032_1727/ch4_s0_luoyang_gate/manifest.json","manifest_sha256":"f43386ce51fae8c2c9b1b29a45f63f1e1bd5c3270e828fa61147e19ba398aedc","walk_path":"res://build/luoyang_harbour_life_publication_20261016/93032_1727/ch4_s0_luoyang_gate/walk.png","scene_path":"res://build/luoyang_harbour_life_publication_20261016/93032_1727/ch4_s0_luoyang_gate/scene.tres","layout_path":"res://build/luoyang_harbour_life_publication_20261016/93032_1727/ch4_s0_luoyang_gate/layout.tres","parent_canonical_path":"res://data/scenes/ch4_s0_luoyang_gate.tres","parent_canonical_sha256":"00d0867a56efec29aa509b4366546c8dfbcc2f4d9a73d062acfa756a2252a581"},"ch4_s2_canal_docks":{"author_sha256":"3a0eba1052f64f0664dff19a322c7c783f74459ffc862c0be125c7c7d6201f3e","manifest_path":"res://build/luoyang_harbour_life_publication_20261016/93032_1727/ch4_s2_canal_docks/manifest.json","manifest_sha256":"0470e79beeb5e71842fb3d9fc9b3db44fe356a6c8c5ad7d7e00c585cc8ece5af","walk_path":"res://build/luoyang_harbour_life_publication_20261016/93032_1727/ch4_s2_canal_docks/walk.png","scene_path":"res://build/luoyang_harbour_life_publication_20261016/93032_1727/ch4_s2_canal_docks/scene.tres","layout_path":"res://build/luoyang_harbour_life_publication_20261016/93032_1727/ch4_s2_canal_docks/layout.tres","parent_canonical_path":"res://data/scenes/ch4_s2_canal_docks.tres","parent_canonical_sha256":"51527c472d4c4ce33e00f1a07754411cc433f770c5882614187f165a7834b34d"}}
var _token: int=0
var _id: StringName=&""
var _original: Dictionary={}
var _packet: Dictionary={}
var _error: String=""
var _mutex: Mutex=Mutex.new()
var _cancelled: bool=false
var _joined: bool=false
var elapsed_ms: int=0
static func enabled() -> bool: return FORMAL_ENABLED or FLAG in OS.get_cmdline_user_args()
static func _office() -> Variant: return load("res://scripts/city/luoyang_docks_office_roles_20261016h.gd")
static func requested(id: StringName) -> bool: return enabled() and id in A.IDS
static func bound(scene: SceneScript) -> bool:
	if scene!=null and scene.scene_id==&"ch4_s2_canal_docks" and scene.has_meta("luoyang_docks_district08_20261019aa"):
		return load("res://scripts/city/luoyang_docks_district08_20261019aa.gd").bound(scene)
	if scene==null or not requested(scene.scene_id) or not CITIES.has(String(scene.scene_id)) or scene.map_layout==null: return false
	var city: Dictionary=CITIES[String(scene.scene_id)]
	if _office().requested(scene.scene_id) and scene.get_meta(_office().META,"")!=_office().AUTHOR_SHA: return false
	var walk_bound: bool=scene.map_layout.walkable_mask_path==city.walk_path
	if scene.has_meta(SPACING.META): walk_bound=SPACING.bound(scene)
	elif SPACING.requested(scene.scene_id): return false
	return scene.get_meta(META,"")==BIND_SHA and scene.get_meta(A.META,"")==city.author_sha256 and scene.get_meta("city_harbour_life_manifest_sha","")==city.manifest_sha256 and walk_bound and scene.map_layout.schema_version==C.VERSION and scene.get_meta("city_enclosure_manifest_sha","")==C.manifest_sha(scene.scene_id) and scene.get_meta("city_ground_manifest_sha","")==C.ground_manifest_sha(scene.scene_id)
static func _bindings() -> Dictionary:
	if BIND_SHA.length()!=64 or FileAccess.get_sha256(BIND_PATH)!=BIND_SHA: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(BIND_PATH))
	return value if value is Dictionary and value.get("status")=="HARBOUR_APPROVED_IMPORT_CANDIDATE_NOT_FORMAL" and value.get("author_sha256")==A.author_sha() and value.get("cities")==CITIES else {}
static func _sources(config: Dictionary,cancel: Callable=Callable()) -> bool:
	if config.get("source_sha256",{}).is_empty(): return false
	for path: String in config.source_sha256:
		if cancel.is_valid() and cancel.call(): return false
		if not path.begins_with("res://") or ".." in path or not AP_NPC._source_matches(path, String(config.source_sha256[path])): return false
	return true
static func source_paths() -> Dictionary:
	var config:=_bindings()
	if config.is_empty(): return {}
	var result: Dictionary={BIND_PATH:true,"res://scripts/city/luoyang_harbour_life_runtime_20261016.gd":true,"res://scripts/city/luoyang_harbour_life_fade_20261016.gd":true}
	for path: String in config.source_sha256: result[path]=true
	result.merge(WATER.source_paths())
	result.merge(_office().source_paths())
	result.merge(SPACING.source_paths())
	return result
static func publication_record_equal(native: Dictionary,published: Dictionary) -> bool:
	var wire: Variant=JSON.parse_string(JSON.stringify(native,"\t",true,true))
	return wire is Dictionary and C._equal_value(wire,published)
static func serialized_equal(left: SceneScript,right: SceneScript) -> bool:
	return bound(left) and bound(right) and SERIAL.serialized_equal(left,right)
func configure(token: int,id: StringName,original: Dictionary) -> bool:
	if token<0 or not requested(id) or not _original.is_empty() or original.get("canonical_scene_id")!=String(id) or _bindings().is_empty(): return false
	_token=token; _id=id; _original=original.duplicate(true); return true
func request_cancel() -> void:
	_mutex.lock(); _cancelled=true; _mutex.unlock()
func _is_cancelled() -> bool:
	_mutex.lock(); var value: bool=_cancelled; _mutex.unlock(); return value
func mark_joined(token: int,id: StringName) -> bool:
	_joined=token==_token and id==_id and not _is_cancelled(); return _joined
func packet(token: int,id: StringName) -> Dictionary: return _packet if _joined and token==_token and id==_id and not _is_cancelled() else {}
func error() -> String: return _error
func release() -> void:
	_original.clear(); _packet.clear(); _token=0; _joined=false
func _reject(message: String) -> void: _error=message; _packet.clear()
func run() -> void:
	var started:=Time.get_ticks_msec(); var config:=_bindings()
	if not _sources(config,_is_cancelled) or not A.sources_valid(_is_cancelled): _reject("Harbour complete source closure changed/cancelled"); return
	var city: Dictionary=CITIES.get(String(_id),{})
	var manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(String(city.get("manifest_path",""))))
	if not manifest is Dictionary or manifest.get("status")!="HARBOUR_CPU_CANDIDATE_NOT_IMPORTED_NOT_RUNTIME_NOT_FORMAL" or manifest.get("author_sha256")!=A.author_sha(): _reject("Harbour publication missing"); return
	if not publication_record_equal(_original,manifest.parent_record): _reject("Harbour complete original parent differs in original writer domain"); return
	var record:=A.compose(_original,_id)
	if record.is_empty(): _reject("Harbour exact parent composition refused"); return
	record.walk_path=city.walk_path
	if not publication_record_equal(record,manifest.record): _reject("Harbour complete published record differs in exact writer domain"); return
	var raw:=Image.load_from_file(String(record.raw_walk_path)); var mask:=Image.load_from_file(String(city.walk_path))
	if raw==null or mask==null or raw.get_size()!=Vector2i(C.SIZE) or mask.get_size()!=Vector2i(C.SIZE): _reject("Harbour original raw/new navigation unavailable"); return
	raw.convert(Image.FORMAT_RGBA8); mask.convert(Image.FORMAT_RGBA8)
	var raster:=C._raster_walk_cpu(raw,record.objects,_is_cancelled)
	if _is_cancelled(): return
	if raster==null or raster.get_data()!=mask.get_data(): _reject("Harbour navigation not exact raw minus solids"); return
	var solids:=C.object_solids(record.objects)
	var geometry:=G.audit(record,mask,_is_cancelled)
	if geometry.get("passed")!=true or not C._all_gameplay_safe_cpu(record,mask,solids,_is_cancelled): _reject("Harbour full87517/routes/crowd continuous body refused"); return
	var office_packet: Dictionary={}
	if _office().requested(_id):
		office_packet=_office().prepare_packet(record,_is_cancelled)
		if office_packet.is_empty(): _reject("Docks office/roles exact source, imported RGBA or existing-base containment refused"); return
	var water_packet: Dictionary={}
	if _id==&"ch4_s2_canal_docks":
		water_packet=WATER.prepare_packet(_is_cancelled)
		if water_packet.is_empty(): _reject("Harbour same-capture water source/pixels changed or cancelled"); return
	if _is_cancelled(): return
	_packet={"record":record,"solids":solids,"walk_bytes":mask.get_data(),"bytes":mask.get_data(),"size":mask.get_size(),"path":city.walk_path,"city":city,"geometry":geometry,"parent_record":_original.duplicate(true)}
	_packet["water_patch"]=water_packet
	_packet["office_roles"]=office_packet
	if SPACING.requested(_id):
		var spacing: Dictionary=SPACING.prepare_packet(record,mask,_is_cancelled)
		if spacing.is_empty(): _reject("Spacing exact remove-one record/source/raster/full-body proof refused"); return
		_packet["spacing"]=spacing
	elapsed_ms=Time.get_ticks_msec()-started
static func materialize_after_original(parent: SceneScript,packet_data: Dictionary) -> SceneScript:
	if parent==null or packet_data.is_empty(): return null
	var city: Dictionary=packet_data.city
	var expected:=A.apply_scene(parent,packet_data.record,String(city.walk_path))
	var published:=ResourceLoader.load(city.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if expected==null or published==null or not SERIAL.serialized_equal(expected,published): return null
	if not C._equal_value(parent.npcs,expected.npcs) or not C._equal_value(parent.map_layout.interactions,expected.map_layout.interactions) or not C._equal_value(parent.map_layout.portals,expected.map_layout.portals): return null
	if _office().requested(expected.scene_id):
		expected=_office().materialize(expected,packet_data.get("office_roles",{}))
		if expected==null: return null
	if expected.scene_id==&"ch4_s2_canal_docks":
		if not WATER.packet_valid(packet_data.get("water_patch")): return null
		# Added only AFTER complete original publication storage equality. Subsequent
		# C snapshots / serialized_equal include this exact Scene-owned byte packet.
		expected.set_meta(WATER.META,packet_data.water_patch.duplicate(true))
	expected.set_meta(META,BIND_SHA); expected.set_meta("city_harbour_life_manifest_sha",city.manifest_sha256)
	expected.set_meta("city_harbour_life_published_scene_path",city.scene_path)
	packet_data.record["harbour_runtime_binding_sha"]=BIND_SHA
	packet_data.record["harbour_parent_task_semantics_preserved"]=true
	if SPACING.requested(expected.scene_id):
		expected=SPACING.install_packet(expected,packet_data,packet_data.get("spacing",{}))
		if expected==null: return null
	return expected
static func gate_visual_parent(scene: SceneScript) -> SceneScript:
	# Only the old visual moat module consumes this exact canonical parent.
	# C/Field navigation and physical solids always remain the new child.
	if not bound(scene) or scene.scene_id!=A.IDS[0]: return null
	var city: Dictionary=CITIES[String(scene.scene_id)]
	if FileAccess.get_sha256(city.parent_canonical_path)!=city.parent_canonical_sha256: return null
	var parent:=ResourceLoader.load(city.parent_canonical_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	return parent if parent!=null and C.GATE_FORTIFICATION.bound(parent) else null
static func crowd(scene: SceneScript) -> Dictionary:
	if not bound(scene): return {"ok":false,"error":"Harbour crowd Scene identity missing"}
	var record: Dictionary=C._records.get(String(scene.scene_id),{})
	if record.get("harbour_runtime_binding_sha")!=BIND_SHA or record.get("harbour_parent_task_semantics_preserved")!=true: return {"ok":false,"error":"Harbour crowd original/current navigation proof missing"}
	var rows:=CROWD.project(scene.scene_id)
	if _office().requested(scene.scene_id):
		var roles: Dictionary=_office().project_npcs(scene,rows)
		if roles.get("ok")!=true: return {"ok":false,"error":roles.get("error","Docks office role source changed")}
		rows=roles.npcs
	if scene.scene_id==&"ch4_s2_canal_docks":
		var presentation: Variant=load("res://scripts/city/luoyang_docks_roles_20261019ad.gd")
		var displayed: Dictionary=presentation.project(scene,rows)
		if displayed.get("ok")!=true: return {"ok":false,"error":String(displayed.get("error","Docks role presentation refused"))}
		rows=displayed.npcs
	var ap: Dictionary=AP_NPC.project(scene.scene_id,rows)
	if ap.get("ok")!=true: return ap
	rows=ap.npcs
	return {"ok":rows.size()==10,"npcs":rows,"receipt":{"source_scene_id":String(scene.scene_id),"binding_sha256":BIND_SHA,"author_sha256":scene.get_meta(A.META),"count":10,"moving":6,"stationary":4,"patrol":"native_horizontal_sinusoidal_not_pathfinding","native_body_envelope_px":[34,30]}}
static func apply_sync_after_parent(parent: SceneScript,raw: SceneScript) -> SceneScript:
	if parent==null: return null
	var id:=parent.scene_id; var sources:=C._transition_sources(raw)
	if sources.is_empty(): C._fail("Harbour complete source identity unavailable"); return null
	var job: RefCounted=load("res://scripts/city/luoyang_harbour_life_runtime_20261016.gd").new()
	if not job.configure(0,id,C._records[String(id)]): job.release(); C._fail("Harbour original CPU packet unbound"); return null
	job.run()
	if not job.mark_joined(0,id): job.release(); C._fail("Harbour synchronous CPU cancelled"); return null
	var data: Dictionary=job.packet(0,id)
	if data.is_empty():
		var message: String=job.error(); job.release(); C._fail(message); return null
	if not C.MODULE_CPU.imported_same(data): job.release(); C._fail("Harbour imported full navigation RGBA differs"); return null
	var result:=materialize_after_original(parent,data)
	if result==null or not C._transition_sources_match(sources): job.release(); C._fail("Harbour complete serialized Scene/source differs"); return null
	C._revision_commit(id,data); job.release(); return result
static func apply_live_after_parent(parent: SceneScript,token: int) -> SceneScript:
	if parent==null or C._live_source_token!=token or C._live_revision_task>=0 or C._live_revision_job!=null: return null
	var id:=parent.scene_id
	var job: RefCounted=load("res://scripts/city/luoyang_harbour_life_runtime_20261016.gd").new()
	if not job.configure(token,id,C._records[String(id)]): job.release(); C._fail("Harbour live original CPU packet unbound"); return null
	C._live_revision_job=job
	var task:=WorkerThreadPool.add_task(job.run,false,"Luoyang harbour exact source/raster/87517 and crowd")
	if task<0: C._live_revision_job=null; job.release(); C._fail("Harbour worker unavailable"); return null
	C._live_revision_task=task
	var frames:=0
	while C._live_source_token==token and C._live_revision_job==job and not WorkerThreadPool.is_task_completed(task):
		C._report_live_progress(token,.66,"正在核验码头建筑与商旅行道……")
		frames+=1
		await (Engine.get_main_loop() as SceneTree).process_frame
	if C._live_source_token!=token or C._live_revision_job!=job: return null
	WorkerThreadPool.wait_for_task_completion(task); C._live_revision_task=-1
	if not job.mark_joined(token,id): C._fail("Harbour completion owner changed"); return null
	var data: Dictionary=job.packet(token,id)
	if data.is_empty(): C._fail("Harbour CPU rejected: "+job.error()); return null
	await (Engine.get_main_loop() as SceneTree).process_frame
	if C._live_source_token!=token or C._live_revision_job!=job: return null
	var tail_started_usec: int=Time.get_ticks_usec()
	var tail_started_frame: int=Engine.get_process_frames()
	var tail_import_same: bool=C.MODULE_CPU.imported_same(data)
	C._record_live_tail_stage(token,id,"tail.harbour.import_readback",tail_started_usec,tail_started_frame)
	if not tail_import_same: C._fail("Harbour imported full navigation RGBA differs"); return null
	await (Engine.get_main_loop() as SceneTree).process_frame
	if C._live_source_token!=token or C._live_revision_job!=job: return null
	tail_started_usec=Time.get_ticks_usec(); tail_started_frame=Engine.get_process_frames()
	var result:=materialize_after_original(parent,data)
	C._record_live_tail_stage(token,id,"tail.harbour.materialize_serialized",tail_started_usec,tail_started_frame)
	if result==null: C._fail("Harbour complete published Scene differs"); return null
	C._revision_commit(id,data)
	C._live_phase_msec["harbour_cpu_worker"]=job.elapsed_ms
	C._live_phase_msec["harbour_wait_frames"]=frames
	job.release(); C._live_revision_job=null
	C._report_live_progress(token,.68,"码头与商旅行道已核验，正在入场……")
	return result
