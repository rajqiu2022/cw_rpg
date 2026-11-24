extends RefCounted
## Exact two-annex child. Same existing exclusive worker/owner, no proof cache.
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const A=preload("res://scripts/city/luoyang_yamen_annex_revision_20261016.gd")
const SERIAL=preload("res://scripts/city/luoyang_city_assembled_serialized_20261016b.gd")
const FLAG="--luoyang-yamen-annex-20261016"
const FORMAL_ENABLED=true
const META="yamen_annex_runtime_binding_sha_20261016"
const SELF="res://scripts/city/luoyang_yamen_annex_runtime_20261016.gd"
const BIND_PATH="res://data/maps/luoyang_yamen_annex_20261016/runtime_bindings.json"
const BIND_SHA="740a1ba50b3d3c32c716272fc7db5ca11aa3d73e8767f4137d9ff3223307014e"
var _token: int=0
var _original: Dictionary={}
var _packet: Dictionary={}
var _error: String=""
var _mutex:=Mutex.new()
var _cancelled: bool=false
var _joined: bool=false
var elapsed_ms: int=0
static func enabled() -> bool: return FORMAL_ENABLED or FLAG in OS.get_cmdline_user_args()
static func requested(id: StringName) -> bool: return enabled() and id==A.ID
static func _bindings() -> Dictionary:
	if BIND_SHA.length()!=64 or FileAccess.get_sha256(BIND_PATH)!=BIND_SHA: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(BIND_PATH))
	return value if value is Dictionary and value.get("status")=="YAMEN_TWO_ANNEX_IMPORTED_CANDIDATE_NOT_FORMAL" and value.get("author_sha256")==FileAccess.get_sha256(A.SELF) else {}
static func bound(scene: SceneScript) -> bool:
	if scene==null or not requested(scene.scene_id) or scene.map_layout==null or scene.get_meta(META,"")!=BIND_SHA: return false
	var config:=_bindings()
	return not config.is_empty() and scene.get_meta(A.META,"")==config.author_sha256 and scene.get_meta("yamen_annex_manifest_sha","")==config.manifest_sha256 and scene.map_layout.walkable_mask_path==config.walk_path and scene.map_layout.schema_version==C.VERSION and scene.get_meta(A.OLD.META,"")==A.OLD.BIND_SHA and scene.get_meta("city_enclosure_manifest_sha","")==C.manifest_sha(A.ID) and scene.get_meta("city_ground_manifest_sha","")==C.ground_manifest_sha(A.ID)
static func source_paths() -> Dictionary:
	var config:=_bindings()
	if config.is_empty(): return {}
	var result: Dictionary={SELF:true,BIND_PATH:true,"res://scripts/city/luoyang_yamen_annex_fade_20261016.gd":true}
	result.merge(A.source_paths())
	for path: String in config.source_sha256: result[path]=true
	return result
static func serialized_equal(a: SceneScript,b: SceneScript) -> bool: return bound(a) and bound(b) and SERIAL.equal(a,b)
static func _sources(config: Dictionary,cancel: Callable=Callable()) -> bool:
	if config.get("source_sha256",{}).is_empty(): return false
	for path: String in config.source_sha256:
		if cancel.is_valid() and cancel.call(): return false
		if not path.begins_with("res://") or ".." in path or FileAccess.get_sha256(path)!=config.source_sha256[path]: return false
	return true
func configure(token: int,id: StringName,original: Dictionary) -> bool:
	if token<0 or not requested(id) or not _original.is_empty() or _bindings().is_empty(): return false
	_token=token; _original=original.duplicate(true); return true
func request_cancel() -> void:
	_mutex.lock(); _cancelled=true; _mutex.unlock()
func _is_cancelled() -> bool:
	_mutex.lock(); var value: bool=_cancelled; _mutex.unlock(); return value
func mark_joined(token: int,id: StringName) -> bool:
	_joined=token==_token and id==A.ID and not _is_cancelled(); return _joined
func packet(token: int,id: StringName) -> Dictionary: return _packet if _joined and token==_token and id==A.ID and not _is_cancelled() else {}
func error() -> String: return _error
func release() -> void: _original.clear(); _packet.clear(); _token=0; _joined=false
func _reject(message: String) -> void: _error=message; _packet.clear()
func run() -> void:
	var started: int=Time.get_ticks_msec(); var config:=_bindings()
	if not _sources(config,_is_cancelled): _reject("Annex source closure changed/cancelled"); return
	var manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(config.manifest_path))
	if not manifest is Dictionary or manifest.get("status")!="YAMEN_TWO_ANNEX_CPU_NOT_IMPORTED_NOT_FORMAL" or manifest.get("author_sha256")!=config.author_sha256: _reject("Annex publication identity missing"); return
	if not A.OLD.publication_record_equal(_original,manifest.parent_record): _reject("Annex complete current parent differs in original writer domain"); return
	var record:=A.compose(_original)
	if record.is_empty(): _reject("Annex exact source composition refused"); return
	record.walk_path=config.walk_path
	if not A.OLD.publication_record_equal(record,manifest.record): _reject("Annex complete published record differs in original writer domain"); return
	var raw:=Image.load_from_file(String(record.raw_walk_path)); var mask:=Image.load_from_file(String(config.walk_path))
	if raw==null or mask==null or raw.get_size()!=Vector2i(C.SIZE) or mask.get_size()!=Vector2i(C.SIZE): _reject("Annex raw/navigation missing"); return
	raw.convert(Image.FORMAT_RGBA8); mask.convert(Image.FORMAT_RGBA8)
	var raster:=C._raster_walk_cpu(raw,record.objects,_is_cancelled)
	if _is_cancelled(): return
	if raster==null or raster.get_data()!=mask.get_data(): _reject("Annex navigation not exact RAW minus new solids"); return
	var solids: Array[PackedVector2Array]=C.object_solids(record.objects)
	var routes: Dictionary=A.routes_audit(record,mask,solids,_is_cancelled)
	if routes.get("passed")!=true or not C._all_gameplay_safe_cpu(record,mask,solids,_is_cancelled): _reject("Annex full87517/all old and new routes refused"); return
	if _is_cancelled(): return
	_packet={"record":record,"solids":solids,"walk_bytes":mask.get_data(),"bytes":mask.get_data(),"size":mask.get_size(),"path":config.walk_path,"config":config,"routes":routes}
	elapsed_ms=Time.get_ticks_msec()-started
static func materialize_after_parent(parent: SceneScript,data: Dictionary) -> SceneScript:
	if parent==null or data.is_empty(): return null
	var config: Dictionary=data.config
	var expected:=A.apply_scene(parent,data.record,String(config.walk_path))
	var published:=ResourceLoader.load(config.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if expected==null or published==null or not SERIAL.equal(expected,published): return null
	if not C._equal_value(parent.npcs,expected.npcs) or not C._equal_value(parent.map_layout.portals,expected.map_layout.portals) or not C._equal_value(parent.map_layout.interactions,expected.map_layout.interactions): return null
	expected.set_meta(META,BIND_SHA); expected.set_meta("yamen_annex_manifest_sha",config.manifest_sha256)
	expected.set_meta("yamen_annex_published_scene_path",config.scene_path)
	data.record["annex_runtime_binding_sha"]=BIND_SHA; data.record["annex_parent_semantics_unchanged"]=true
	return expected
static func apply_sync_after_parent(parent: SceneScript,raw: SceneScript) -> SceneScript:
	if parent==null: return null
	var sources: Dictionary=C._transition_sources(raw)
	if sources.is_empty(): C._fail("Annex source closure unavailable"); return null
	var job: RefCounted=load(SELF).new()
	if not job.configure(0,A.ID,C._records[String(A.ID)]): job.release(); C._fail("Annex parent packet missing"); return null
	job.run()
	if not job.mark_joined(0,A.ID): job.release(); C._fail("Annex CPU cancelled"); return null
	var data: Dictionary=job.packet(0,A.ID)
	if data.is_empty():
		var message: String=job.error(); job.release(); C._fail(message); return null
	if not C.MODULE_CPU.imported_same(data): job.release(); C._fail("Annex imported navigation fullRGBA differs"); return null
	var result:=materialize_after_parent(parent,data)
	if result==null or not C._transition_sources_match(sources): job.release(); C._fail("Annex complete Scene/source differs"); return null
	C._revision_commit(A.ID,data); job.release(); return result
static func apply_live_after_parent(parent: SceneScript,token: int) -> SceneScript:
	if parent==null or C._live_source_token!=token or C._live_revision_task>=0 or C._live_revision_job!=null: return null
	var job: RefCounted=load(SELF).new()
	if not job.configure(token,A.ID,C._records[String(A.ID)]): job.release(); C._fail("Annex live parent missing"); return null
	C._live_revision_job=job
	var task: int=WorkerThreadPool.add_task(job.run,false,"Yamen two annexes exact source/raster/routes")
	if task<0: C._live_revision_job=null; job.release(); C._fail("Annex worker unavailable"); return null
	C._live_revision_task=task
	while C._live_source_token==token and C._live_revision_job==job and not WorkerThreadPool.is_task_completed(task):
		C._report_live_progress(token,.69,"正在核验厢房与侧巷通路……")
		await (Engine.get_main_loop() as SceneTree).process_frame
	if C._live_source_token!=token or C._live_revision_job!=job: return null
	WorkerThreadPool.wait_for_task_completion(task); C._live_revision_task=-1
	if not job.mark_joined(token,A.ID): C._fail("Annex completion owner changed"); return null
	var data: Dictionary=job.packet(token,A.ID)
	if data.is_empty(): C._fail("Annex CPU refused: "+job.error()); return null
	await (Engine.get_main_loop() as SceneTree).process_frame
	if C._live_source_token!=token or C._live_revision_job!=job: return null
	if not C.MODULE_CPU.imported_same(data): C._fail("Annex imported full navigation RGBA differs"); return null
	var result:=materialize_after_parent(parent,data)
	if result==null: C._fail("Annex complete expected Scene differs"); return null
	C._revision_commit(A.ID,data); C._live_phase_msec["annex_cpu_worker"]=job.elapsed_ms
	job.release(); C._live_revision_job=null; return result
