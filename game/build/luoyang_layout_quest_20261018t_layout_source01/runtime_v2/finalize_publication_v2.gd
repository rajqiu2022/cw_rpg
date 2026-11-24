extends SceneTree
## Second atom: strict source succession + existing native geometry readback.
## NEVER calls raster/room compiler/C.prepare and NEVER overwrites phase1 data.
const B=preload("res://build/luoyang_layout_quest_20261018t_layout_source01/bundle_helper_runtime_v3.gd")
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const ROOT="res://data/maps/luoyang_layout_bundle_20261018t_retry2/"
const ROOMS="res://data/maps/luoyang_layout_rooms_20261018t/"
const ROOM_INDEX="res://scripts/city/luoyang_layout_room_index_20261018t.gd"
const MIGRATION="res://build/luoyang_layout_quest_20261018t_layout_source01/runtime_v2/runtime_source_migration.json"
const IMPORT_AUTHORITY="res://build/luoyang_layout_quest_20261018t_layout_source01/runtime_v2/mask_import_authority.json"
const PHASE1_SHA="1145360fa730b0fd654f69bffe14c7ad02e04d578e37b70c9ef043a1d6fdc8a9"
const PHASE1=ROOT+"geometry_publication.json"
const OLD="res://data/maps/luoyang_precomputed_bundle_20261018r3/"
const IDS=["ch4_s0_luoyang_gate","ch4_s3_luoyang_market","ch4_s2_canal_docks","ch4_s1_luoyang_yamen"]
const LIMIT_MS=60000
const PUBLICATION_ONLY_PATHS=["res://build/luoyang_layout_quest_20261018t_layout_source01/publish_layout_retry2.gd","res://build/luoyang_layout_quest_20261018t_layout_source01/runtime_v2/finalize_publication_v2.gd"]
var _error: String=""
var _started: int=0
var _input: Dictionary={}
var _authority: Dictionary={}
var _migration: Dictionary={}
var _proof: Dictionary={}
var _rows: Dictionary={}
var _runtime_legacy: Dictionary={}
var _runtime_authority: Dictionary={}
var _base_collected: Dictionary={}
var _imports: Dictionary={}
var _room_sources: Dictionary={}
func _initialize() -> void: call_deferred("_run")
func require(ok: bool,message: String) -> bool:
	if not ok and _error.is_empty(): _error=message; push_error("[t finalize] "+message)
	return ok
func json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
func pin(path: String,sha: String="") -> bool:
	if _input.has(path): return require(sha.is_empty() or _input[path]==sha,"Conflicting input pin "+path)
	var actual: String=FileAccess.get_sha256(path)
	if not require(path.begins_with("res://") and ".." not in path and B._hash(actual) and (sha.is_empty() or actual==sha),"Exact current source "+path): return false
	_input[path]=actual; return true
func write(path: String,bytes: PackedByteArray) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_buffer(bytes); file.close()
	return FileAccess.get_file_as_bytes(path)==bytes
func advance(path: String,old_sha: String) -> String:
	if _authority.has(path): return String(_authority[path])
	var row: Dictionary=_migration.get("source_delta",{}).get(path,{})
	var expected: String=old_sha
	if not row.is_empty():
		if not require(old_sha in row.get("historical_sha256",[]) and B._hash(row.get("new_sha256")) and String(row.get("candidate_path","")).begins_with("res://build/luoyang_layout_quest_20261018t_"),"Explicit inverse source delta "+path): return ""
		if not pin(row.candidate_path,row.new_sha256): return ""
		expected=row.new_sha256
	return expected if pin(path,expected) else ""
func room_registry() -> bool:
	var path: String=ROOMS+"registry_geometry.json"
	if not pin(path,_proof.generated_authority_sha256.get(path,"")): return false
	var original: Dictionary=json(path); var current: Dictionary=original.duplicate(true)
	if not require(original.get("rooms",{}).size()==12,"Exact twelve successor rooms"): return false
	for id: String in current.rooms:
		var row: Dictionary=current.rooms[id]
		for source: String in row.source_sha256:
			var next: String=advance(source,row.source_sha256[source])
			if next.is_empty(): return false
			row.source_sha256[source]=next
			_room_sources[source]=next
		var storage_path: String=String(row.storage_path)
		var data: Variant=bytes_to_var(FileAccess.get_file_as_bytes(storage_path))
		var scene:=ResourceLoader.load(row.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		var layout:=ResourceLoader.load(row.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
		if not require(data is Dictionary and B._plain(data) and scene!=null and layout!=null,"Room native storage source "+id): return false
		scene.map_layout=layout
		if not require(B.equal(B.storage(scene),data.scene) and B.equal(B.storage(layout),data.layout),"Whole unchanged room native readback "+id): return false
	current["runtime_source_revision"]={"basis":"EXACT_SOURCE_SUCCESSOR_NOT_RERUN_GEOMETRY","prior_geometry_registry_path":path,"prior_geometry_registry_sha256":FileAccess.get_sha256(path),"source_delta":_migration.source_delta.duplicate(true),"scene_geometry_storage_unchanged":true}
	var new_path: String=ROOMS+"registry.json"
	if not require(write(new_path,JSON.stringify(current,"\t",true,true).to_utf8_buffer()),"Fresh runtime registry output"): return false
	_authority[new_path]=FileAccess.get_sha256(new_path)
	var prior: Dictionary=json(current.history.prior_path)
	for source: String in prior.get("source_sha256",{}):
		if not require(_input.has(source) or _authority.has(source),"Undeclared old room global source "+source): return false
		_room_sources[source]=true
	for old_row: Dictionary in prior.rooms.values():
		for key: String in ["author_path","scene_path","layout_path"]: _room_sources[String(old_row[key])]=true
	for source: String in [new_path,path,current.history.prior_path,"res://scripts/city/luoyang_assembled_interiors_20261016g.gd","res://build/luoyang_layout_quest_20261018t_layout_source01/g_geometry_original.gd"]: _room_sources[source]=true
	var index: String="extends RefCounted\nconst REGISTRY_PATH=\""+new_path+"\"\nconst REGISTRY_SHA=\""+_authority[new_path]+"\"\nstatic func formal_enabled() -> bool: return load(\"res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd\").formal_enabled()\nstatic func registry() -> Dictionary: return {\"path\":REGISTRY_PATH,\"sha256\":REGISTRY_SHA}\n"
	var generated_index: String=ROOT+"room_index_generated.gd"
	if not require(write(generated_index,index.to_utf8_buffer()),"Fresh staged room index, ROOT promotes only after A"): return false
	_authority[ROOM_INDEX]=FileAccess.get_sha256(generated_index)
	_room_sources[ROOM_INDEX]=true
	return true
func import_proofs() -> bool:
	if not pin(IMPORT_AUTHORITY): return false
	_imports=json(IMPORT_AUTHORITY)
	var rows: Dictionary=_imports.get("new_mask_imports",{})
	if not require(rows.size()==2,"Exactly two new native mask imports"): return false
	for id: String in ["ch4_s3_luoyang_market","ch4_s1_luoyang_yamen"]:
		var proof: Dictionary=rows.get(id,{})
		var path: String=ROOT+id+"/walk.png"
		if not require(proof.get("texture")==path and proof.get("import_path")==path+".import" and proof.get("full_rgba_exact")==true and proof.get("params23")==true and proof.get("mipmap_count")==0,"Actual mask import proof contract "+id): return false
		for pair: Array in [[path,proof.get("source_sha256")],[proof.get("import_path"),proof.get("import_sha256")],[proof.get("compiled_path"),proof.get("compiled_sha256")],[proof.get("report_path"),proof.get("report_sha256")],[proof.get("verifier_path"),proof.get("verifier_sha256")]]:
			if not pair[0] is String or not pair[1] is String or not pin(pair[0],pair[1]): return false
		if not pin(proof.prepared_path,proof.prepared_sha256): return false
		var actual_report: Dictionary=json(proof.report_path)
		if not require(actual_report.get("passed")==true and actual_report.get("actual_geometry_result_sha256")==PHASE1_SHA and B.equal(actual_report.get("source_first"),actual_report.get("source_final")),"Immutable actual mask verifier report "+id): return false
		var actual_row: Dictionary={}
		for candidate: Dictionary in actual_report.get("rows",[]):
			if candidate.get("scene_id")==id:
				if not actual_row.is_empty(): return require(false,"Duplicate actual mask proof row")
				actual_row=candidate
		for key: String in ["texture","source_sha256","import_path","import_sha256","compiled_path","compiled_sha256","full_rgba_exact","params23","mipmap_count","packet_path","packet_sha256","packet_walk_bytes_sha256","size_px"]:
			if not require(B.equal(actual_row.get(key),proof.get(key)),"Exact actual mask proof field "+id+":"+key): return false
		if not pin(proof.packet_path,proof.packet_sha256): return false
		var image: Image=Image.load_from_file(path)
		if image!=null: image.convert(Image.FORMAT_RGBA8)
		var packet: Variant=bytes_to_var(FileAccess.get_file_as_bytes(ROOT+id+"/packet.bin"))
		if not require(image!=null and image.get_size()==Vector2i(3072,2048) and packet is Dictionary and image.get_data()==packet.walk_bytes and B.bytes_sha(image.get_data())==packet.mask_sha,"Existing CPU mask versus actual PNG full RGBA "+id): return false
		_authority[path]=FileAccess.get_sha256(path); _authority[proof.import_path]=proof.import_sha256
	return true
func city(id: String) -> bool:
	var record: Dictionary=_proof.rows.get(id,{})
	var manifest: Dictionary=record.get("pending_manifest",{}).duplicate(true)
	if not manifest.is_empty():
		for artifact: String in manifest.artifacts:
			if not pin(artifact,manifest.artifacts[artifact]): return false
	if manifest.is_empty():
		# Unchanged Gate/Docks: safe native re-container, no art/geometry remake.
		var prior_path: String=OLD+id+"/manifest.json"
		if not pin(prior_path,_migration.parent_manifest_sha256.get(id,"")): return false
		var prior: Dictionary=json(prior_path)
		for source: String in prior.artifacts:
			if not pin(source,prior.artifacts[source]): return false
		var packet: Variant=bytes_to_var(FileAccess.get_file_as_bytes(OLD+id+"/packet.bin"))
		if not require(packet is Dictionary and B._plain(packet),"Unchanged native parent safe packet "+id): return false
		packet["geometry_basis"]=B.UNCHANGED_BASIS
		for suffix: String in ["scene.res","layout.res"]:
			if not require(write(ROOT+id+"/"+suffix,FileAccess.get_file_as_bytes(OLD+id+"/"+suffix)),"Unchanged native artifact exact copy "+id): return false
		if not require(write(ROOT+id+"/packet.bin",var_to_bytes(packet)),"Unchanged typed native packet "+id): return false
		manifest={"kind":B.KIND,"scene_id":id,"geometry_proof_basis":B.UNCHANGED_BASIS,"mask_sha256":packet.mask_sha,"layout_proof":{"passed":true,"not_new_geometry":true},"parent_publication":{"path":prior_path,"sha256":FileAccess.get_sha256(prior_path),"complete_immutable_manifest":prior}}
	var artifacts: Dictionary={}
	for suffix: String in ["scene.res","layout.res","packet.bin"]: artifacts[ROOT+id+"/"+suffix]=FileAccess.get_sha256(ROOT+id+"/"+suffix)
	var data: Variant=bytes_to_var(FileAccess.get_file_as_bytes(ROOT+id+"/packet.bin"))
	var scene:=ResourceLoader.load(ROOT+id+"/scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout:=ResourceLoader.load(ROOT+id+"/layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not require(data is Dictionary and B._plain(data) and scene!=null and layout!=null,"Native successor artifacts "+id): return false
	scene.map_layout=layout
	if not require(B.equal(B.storage(scene),data.scene_storage) and B.equal(B.storage(layout),data.layout_storage) and B.bytes_sha(data.walk_bytes)==data.mask_sha and B.equal(C.object_solids(data.record.objects),data.solids),"Whole Scene/layout/record/typed solids/NAV readback "+id): return false
	manifest.artifacts=artifacts; manifest["publication_full_source_finalized"]=true
	manifest["geometry_publication_path"]=PHASE1; manifest["geometry_publication_sha256"]=FileAccess.get_sha256(PHASE1)
	manifest["source_migration"]=_migration.duplicate(true)
	_rows[id]={"manifest":manifest,"artifacts":artifacts}
	return true
func finalize_all() -> bool:
	if not require(B.forced_authoring(),"Explicit force-authoring flag is required only to collect full current source paths"): return false
	if not pin(PHASE1,PHASE1_SHA) or not pin(MIGRATION) or not pin(get_script().resource_path): return false
	_proof=json(PHASE1); _migration=json(MIGRATION)
	if not require(_proof.get("passed")==true and _proof.get("status")=="CPU_GEOMETRY_SUCCESSOR_NOT_RUNTIME_NOT_FORMAL" and B.equal(_proof.get("source_first"),_proof.get("source_final")) and _migration.get("status")=="READY_EXACT_RUNTIME_SOURCE_SUCCESSION","Successful immutable geometry report + exact final source migration"): return false
	for path: String in _proof.generated_authority_sha256:
		if not require(FileAccess.get_sha256(path)==_proof.generated_authority_sha256[path],"Existing geometry artifact changed "+path): return false
		_authority[path]=_proof.generated_authority_sha256[path]
	for path: String in _proof.source_first:
		if advance(path,_proof.source_first[path]).is_empty(): return false
	for path: String in _migration.get("new_input_sha256",{}):
		if not pin(path,_migration.new_input_sha256[path]): return false
	_authority[PHASE1]=PHASE1_SHA
	if not room_registry() or not import_proofs(): return false
	# The authoring flag keeps the real C collector on its original full-source
	# branches. It does NOT mutate an index or fake a runtime collector result.
	for id: String in IDS:
		if not city(id): return false
		var raw:=ResourceLoader.load("res://data/scenes/"+id+".tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		if raw==null: return require(false,"Canonical source absent "+id)
		var paths: Dictionary=C._transition_sources(raw,false)
		if paths.is_empty(): return require(false,"Actual authoring collector refused "+id)
		_base_collected[id]=paths.duplicate(true)
		var prior: Dictionary=json(OLD+id+"/manifest.json")
		var runtime: Dictionary={}
		# Retain each district's actual old runtime closure, not the union1479
		# publication inputs. Historical complete maps remain in the receipt.
		for path: String in prior.legacy_source_sha256:
			var next: String=advance(path,prior.legacy_source_sha256[path])
			if next.is_empty(): return false
			runtime[path]=next
		for path: String in paths:
			if _authority.has(path): continue
			if not require(_input.has(path),"Undeclared actual collector source "+path): return false
			runtime[path]=_input[path]
		if _proof.rows.has(id):
			# The strict District/fade inverse really loads these immutable
			# native parent resources. They belong to cold first/final too.
			for suffix: String in ["scene.res","layout.res"]:
				var parent_path: String=OLD+id+"/"+suffix
				if not require(_input.get(parent_path)==prior.artifacts.get(parent_path),"Exact runtime parent resource "+parent_path): return false
				runtime[parent_path]=_input[parent_path]
		for path: String in _migration.get("runtime_execution_sha256",{}):
			if not pin(path,_migration.runtime_execution_sha256[path]): return false
			runtime[path]=_input[path]
		# Yamen's new hall is projected by Field, unlike old C's two-city room
		# collector. Bind the very same complete twelve-room source set here.
		if id!="ch4_s0_luoyang_gate":
			var interiors: Dictionary=_room_sources
			if not require(not interiors.is_empty(),"Exact room source collector "+id): return false
			for path: String in interiors:
				if _authority.has(path): continue
				if not require(_input.has(path),"Unapproved room collector source "+path): return false
				runtime[path]=_input[path]
		var authority: Dictionary={}
		for path: String in _authority:
			if path==PHASE1 or (id!="ch4_s0_luoyang_gate" and (path.begins_with(ROOMS) or path==ROOM_INDEX)) or path.begins_with(ROOT+id+"/"):
				authority[path]=_authority[path]
		if _imports.new_mask_imports.has(id):
			var mask_proof: Dictionary=_imports.new_mask_imports[id]
			runtime[mask_proof.compiled_path]=mask_proof.compiled_sha256
			for key: String in ["report_path","verifier_path"]:
				runtime[mask_proof[key]]=_input[mask_proof[key]]
		for path: String in authority: runtime.erase(path)
		for path: String in PUBLICATION_ONLY_PATHS:
			if not require(not runtime.has(path),"Compiler input must not become runtime closure "+path): return false
		_runtime_legacy[id]=runtime; _runtime_authority[id]=authority
	# Reobserve all input bytes after complete readback. Generated artifacts are
	# separate exact outputs; they do not pretend to have existed in phase1.
	var final: Dictionary={}
	for path: String in _input: final[path]=FileAccess.get_sha256(path)
	if not require(B.equal(_input,final),"Current full input source-first/final differs"): return false
	var entries: Dictionary={}
	for id: String in IDS:
		var row: Dictionary=_rows[id]; var manifest: Dictionary=row.manifest
		manifest["status"]="READY_PRECOMPUTED_T_LAYOUT_CANDIDATE_NOT_FORMAL"
		manifest["legacy_source_sha256"]=_runtime_legacy[id].duplicate(true)
		manifest["runtime_authority_sha256"]=_runtime_authority[id].duplicate(true)
		manifest["publication_source_first"]=_input.duplicate(true); manifest["publication_source_final"]=final.duplicate(true)
		manifest["actual_authoring_collector_before_generated_bootstrap"]=_base_collected[id].keys()
		manifest["runtime_collector_admission_pending"]=true
		manifest["publication_inputs_are_not_runtime_union"]=true
		manifest["publication_only_paths"]=PUBLICATION_ONLY_PATHS.duplicate()
		manifest["mask_import_proofs"]=_imports.new_mask_imports.duplicate(true)
		var path: String=ROOT+id+"/manifest.json"
		if not require(write(path,JSON.stringify(manifest,"\t",true,true).to_utf8_buffer()),"Fresh final manifest "+id): return false
		entries[id]={"manifest_path":path,"manifest_sha256":FileAccess.get_sha256(path)}
	var index: String="extends RefCounted\nconst FORMAL_ENABLED=false\nconst ENTRIES="+var_to_str(entries)+"\nstatic func entries() -> Dictionary: return ENTRIES.duplicate(true)\nstatic func formal_enabled() -> bool: return FORMAL_ENABLED\n"
	if not require(write(ROOT+"bundle_index_generated.gd",index.to_utf8_buffer()),"Fresh disabled exact index output"): return false
	return require(Time.get_ticks_msec()-_started<LIMIT_MS,"Finite source/readback finalizer60s; actual runtime admission is a separate fresh process")
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	_started=Time.get_ticks_msec()
	var ok: bool=finalize_all()
	var report: Dictionary={"passed":ok,"error":_error,"elapsed_ms":Time.get_ticks_msec()-_started,"source_first":_input,"source_final":{},"runtime_authority_sha256":_authority,"rows":{},"geometry_not_recomputed":true,"formal_enabled":false,"runtime_collector_admission_pending":true,"runtime_closures":_runtime_legacy,"runtime_authorities":_runtime_authority}
	for path: String in _input: report.source_final[path]=FileAccess.get_sha256(path)
	for id: String in _rows: report.rows[id]=_rows[id].artifacts
	var path: String="res://build/luoyang_layout_quest_finalize_20261018t/"+str(OS.get_process_id())+"/result.json"
	if not write(path,JSON.stringify(report,"\t",true,true).to_utf8_buffer()): ok=false
	print(JSON.stringify({"passed":ok,"error":_error,"output":path})); quit(0 if ok else 1)
