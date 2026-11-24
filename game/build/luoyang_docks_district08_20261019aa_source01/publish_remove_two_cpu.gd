extends SceneTree
## ROOT-only NEW single-Docks publication. No C.prepare, four-city or room replay.
const API="res://scripts/city/luoyang_docks_district08_20261019aa.gd"
const BUNDLE="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const OUTPUT="res://data/maps/luoyang_docks_district08_20261019aa/runtime/ch4_s2_canal_docks/"
const LIMIT_MS=60000
var _started: int=0
var _error: String=""
var _sources: Dictionary={}
var _report: Dictionary={}
var _run_root: String=""
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,message: String) -> bool:
	if not ok and _error.is_empty(): _error=message; push_error("[Docks08 aa] "+message)
	return ok
func track(path: String,expected: String="") -> bool:
	var actual: String=FileAccess.get_sha256(path)
	if not need(path.begins_with("res://") and ".." not in path and actual.length()==64 and (expected.is_empty() or actual==expected) and (not _sources.has(path) or _sources[path]==actual),"Exact source "+path): return false
	_sources[path]=actual; return true
func write(path: String,bytes: PackedByteArray) -> bool:
	if not need((path.begins_with(OUTPUT) or path.begins_with(_run_root)) and not FileAccess.file_exists(path),"NEW output only "+path): return false
	if not need(DirAccess.make_dir_recursive_absolute(path.get_base_dir())==OK,"Output directory"): return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if not need(file!=null,"Output open"): return false
	file.store_buffer(bytes); file.close()
	return need(FileAccess.get_file_as_bytes(path)==bytes,"Exact byte output readback")
func json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
func publish() -> bool:
	var a: Variant=load(API); var b: Variant=load(BUNDLE)
	if not need(a is GDScript and a.can_instantiate() and b is GDScript and b.can_instantiate(),"Real API compile/instantiate"): return false
	var author: Dictionary=a.author()
	if not need(not author.is_empty(),"Frozen explicit aa author"): return false
	for path: String in author.source_sha256:
		if not track(path,author.source_sha256[path]): return false
	for path: String in author.cpu_live_source_sha256:
		if not track(path,author.cpu_live_source_sha256[path]): return false
	for path: String in [API,a.INDEX,a.AUTHOR,get_script().resource_path]:
		if not track(path): return false
	var root_path: String=String(author.parent_bundle_root)
	var manifest: Dictionary=json(author.parent_manifest_path)
	if not need(manifest.get("scene_id")==String(a.ID) and manifest.get("geometry_proof_basis")==b.UNCHANGED_BASIS and manifest.get("publication_full_source_finalized")==true,"Current explicit old Docks basis"): return false
	for path: String in manifest.artifacts:
		if not track(path,manifest.artifacts[path]): return false
	var old: Variant=bytes_to_var(FileAccess.get_file_as_bytes(root_path+"packet.bin"))
	var scene:=ResourceLoader.load(root_path+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout:=ResourceLoader.load(root_path+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(old is Dictionary and b._plain(old) and scene!=null and layout!=null and old.geometry_basis==b.UNCHANGED_BASIS,"Old complete native packet/resources"): return false
	scene.map_layout=layout
	if not need(b.equal(b.storage(scene),old.scene_storage) and b.equal(b.storage(layout),old.layout_storage) and b.equal(a.c().object_solids(old.record.objects),old.solids) and b.bytes_sha(old.walk_bytes)==old.mask_sha,"Whole old native storage/typed solids/fullRGBA"): return false
	var raw: Image=Image.load_from_file(author.raw_walk_path)
	var old_mask:=Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,old.walk_bytes)
	var raster: Image=a.c().raster_walk(raw,old.record.objects) if raw!=null else null
	if not need(raster!=null and raster.get_data()==old.walk_bytes,"Exact current parent raw-minus-solids fullRGBA"): return false
	var walk: String=OUTPUT+"walk.png"
	var record: Dictionary=a.compose(old.record,walk)
	if not need(not record.is_empty(),"Exactly two known complete records removed, whole inverse"): return false
	var mask: Image=a.c().raster_walk(raw,record.objects)
	if not need(mask!=null,"New raw-minus-retained-25 raster"): return false
	var audit: Dictionary=a.geometry(record,mask,old.record,old_mask)
	_report.geometry=audit
	if not need(audit.get("passed")==true,"NEW local mask/full87517/NPC/District audit: "+JSON.stringify(audit)): return false
	var next: SceneScript=a.materialize(scene,record,walk)
	if not need(next!=null,"Whole Scene/layout remove-two inverse, all gameplay/portals/NPC storage retained"): return false
	var old_spacing: Dictionary=json(author.old_spacing_manifest)
	if not need(old_spacing.get("status")=="SPACING_REMOVE_ONE_CPU_NOT_IMPORTED_NOT_RUNTIME" and old_spacing.get("parent_record",{}).get("objects",[]).size()==28 and old_spacing.get("record",{}).get("objects",[]).size()==27,"Immutable old 28-to-27 history retained, not recomputed"): return false
	if not need(Time.get_ticks_msec()-_started<LIMIT_MS,"Original finite60s budget"): return false
	for suffix: String in ["walk.png","layout.res","scene.res","packet.bin"]:
		if not need(not FileAccess.file_exists(OUTPUT+suffix),"Entire NEW artifact set absent before first write: "+suffix): return false
	if not need(DirAccess.make_dir_recursive_absolute(OUTPUT)==OK,"NEW artifact output directory before PNG"): return false
	if not need(not FileAccess.file_exists(walk) and mask.save_png(walk)==OK,"New walk PNG no overwrite"): return false
	var reread: Image=Image.load_from_file(walk)
	if reread!=null: reread.convert(Image.FORMAT_RGBA8)
	if not need(reread!=null and reread.get_data()==mask.get_data(),"New PNG fullRGBA readback"): return false
	if not need(not FileAccess.file_exists(OUTPUT+"layout.res") and ResourceSaver.save(next.map_layout,OUTPUT+"layout.res")==OK,"NEW native layout"): return false
	next.map_layout=ResourceLoader.load(OUTPUT+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(not FileAccess.file_exists(OUTPUT+"scene.res") and ResourceSaver.save(next,OUTPUT+"scene.res")==OK,"NEW native Scene"): return false
	var loaded:=ResourceLoader.load(OUTPUT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(loaded!=null and loaded.map_layout!=null and b.equal(b.storage(next),b.storage(loaded)) and b.equal(b.storage(next.map_layout),b.storage(loaded.map_layout)),"Whole saved native storage"): return false
	var packet: Dictionary=old.duplicate(true)
	packet.geometry_basis=a.BASIS; packet.record=record; packet.solids=a.c().object_solids(record.objects)
	packet.walk_bytes=mask.get_data(); packet.mask_sha=b.bytes_sha(packet.walk_bytes)
	packet.scene_storage=b.storage(loaded); packet.layout_storage=b.storage(loaded.map_layout)
	packet["aa_author_sha256"]=a.AUTHOR_SHA
	packet["aa_parent_record"]=old.record.duplicate(true)
	packet["aa_district_parent_record"]=old_spacing.parent_record.duplicate(true)
	packet["aa_parent_packet_sha256"]=manifest.artifacts[root_path+"packet.bin"]
	if not write(OUTPUT+"packet.bin",var_to_bytes(packet)): return false
	var stored: Variant=bytes_to_var(FileAccess.get_file_as_bytes(OUTPUT+"packet.bin"))
	if not need(stored is Dictionary and b._plain(stored) and b.equal(stored,packet),"Whole typed packet readback"): return false
	var artifacts: Dictionary={}
	for suffix: String in ["scene.res","layout.res","packet.bin"]: artifacts[OUTPUT+suffix]=FileAccess.get_sha256(OUTPUT+suffix)
	_report.merge({"status":"AA_LOCAL_GEOMETRY_NATIVE_CANDIDATE_NOT_IMPORTED_NOT_RUNTIME","scene_id":String(a.ID),"geometry_basis":a.BASIS,"author_path":a.AUTHOR,"author_sha256":a.AUTHOR_SHA,"parent_manifest_path":author.parent_manifest_path,"parent_manifest_sha256":author.source_sha256[author.parent_manifest_path],"parent_complete_immutable_manifest":manifest,"artifact_root":OUTPUT,"artifacts":artifacts,"walk_path":walk,"walk_sha256":FileAccess.get_sha256(walk),"mask_sha256":packet.mask_sha,"parent_count":27,"child_count":25,"all_npcs_portals_returns_routes_exact":true,"ground_image_unchanged":true,"new_room_count":0,"native_Physics_not_run":true,"import_pending":true,"not_formal":true})
	return true
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	_started=Time.get_ticks_msec()
	_run_root="res://build/luoyang_docks_district08_20261019aa_cpu/"+str(OS.get_process_id())+"/"
	var ok: bool=publish()
	var final_sources: Dictionary={}
	for path: String in _sources:
		final_sources[path]=FileAccess.get_sha256(path)
		if not need(final_sources[path]==_sources[path],"Final immutable source changed "+path): ok=false
	if not need(Time.get_ticks_msec()-_started<LIMIT_MS,"Fixed60s publication budget"): ok=false
	_report.merge({"passed":ok,"error":_error,"elapsed_ms":Time.get_ticks_msec()-_started,"limit_ms":LIMIT_MS,"source_first":_sources,"source_final":final_sources,"geometry_not_Field_credit":true})
	var saved: bool=write(_run_root+"result.json",JSON.stringify(_report,"\t",true,true).to_utf8_buffer())
	print(JSON.stringify({"passed":ok and saved,"output":_run_root,"error":_error}))
	quit(0 if ok and saved else 1)
