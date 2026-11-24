extends SceneTree
## ROOT-only bounded NEW resource construction. Never loads a C city/catalog.
const T=preload("res://scripts/city/luoyang_temple_assembly_20261016.gd")
const AUTHOR="res://data/maps/luoyang_temple_assembly_20261016/author.json"
const IMPORT="res://data/maps/luoyang_temple_assembly_20261016/import_approval.json"
const ENV_IMPORT="res://data/maps/luoyang_temple_assembly_20261016/environment_import_approval.json"
const ENV_SOURCE="res://art/modules/ancient_temple_assembled_20261016/environment_provenance.json"
const SERIAL="res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd"
const LIMIT_MSEC=15000
var _started: int=0
var _failure: String=""
var _checks: int=0
var _samples: int=0
var _sources: Dictionary={}
func _initialize() -> void: call_deferred("_run")
func _require(ok: bool,label: String) -> bool:
	_checks+=1
	if not ok and _failure.is_empty(): _failure=label
	if Time.get_ticks_msec()-_started>LIMIT_MSEC and _failure.is_empty(): _failure="15s temple candidate CPU scope exceeded"
	return _failure.is_empty()
func _json(path: String) -> Dictionary:
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(path)); return data if data is Dictionary else {}
func _hash(paths: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for path: String in paths:
		if not _require(FileAccess.file_exists(path),"Source missing: "+path): return {}
		result[path]=FileAccess.get_sha256(path)
	return result
func _write(path: String,value: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file:=FileAccess.open(path,FileAccess.WRITE)
	# Evidence must remain writable after an earlier assertion/deadline fails.
	if file==null:
		if _failure.is_empty(): _failure="NEW JSON write refused: "+path
		return false
	file.store_string(JSON.stringify(value,"\t",true,true)); file.close(); return true
func _publish() -> bool:
	if not _require(not FileAccess.file_exists(T.SCENE_PATH) and not FileAccess.file_exists(T.LAYOUT_PATH),"Do not overwrite any published temple resource"): return false
	var pending: Dictionary=_json(T.BIND_PATH)
	if not _require(String(pending.get("status","")).begins_with("PENDING"),"Only replace the original explicitly PENDING binding"): return false
	var authored: Dictionary=_json(AUTHOR); var approval: Dictionary=_json(IMPORT); var environment: Dictionary=_json(ENV_IMPORT); var provenance: Dictionary=_json(ENV_SOURCE)
	if not _require(authored.get("status")=="READY_SOURCE_FEET_TEMPLE" and authored.get("texture_count")==9 and approval.get("copy_exact_verified")==true and approval.get("rows",[]).size()==6 and environment.get("copy_exact_verified")==true and environment.get("rows",[]).size()==3 and not provenance.get("source_sha256",{}).is_empty(),"Author/nine-texture import/environment readiness"): return false
	var texture_proofs: Array=approval.rows.duplicate(true); texture_proofs.append_array(environment.rows)
	_sources={AUTHOR:true,IMPORT:true,ENV_IMPORT:true,ENV_SOURCE:true,T.SELF:true,T.ORIGINAL:true,T.ORIGINAL_LAYOUT:true,SERIAL:true,
		"res://art/modules/ancient_temple_assembled_20261016/generated_manifest.json":true,
		"res://art/modules/ancient_temple_assembled_20261016/original_geometry_proposals.json":true,
		"res://scripts/dev/publish_luoyang_temple_assembly_20261016.gd":true,
		"res://scripts/city/luoyang_temple_task_adapter_20261016.gd":true,
		"res://scripts/city/luoyang_temple_fade_20261016.gd":true,
		"res://scripts/city/luoyang_functional_interiors_20261016.gd":true,
		"res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd":true,
		"res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd":true,
		"res://scripts/city/luoyang_enclosure_building_fade_preview_20261010.gd":true,
		"res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd":true,
		"res://scripts/domain/scene_script.gd":true,"res://scripts/domain/walkable_map_layout.gd":true,
		"res://scripts/autoload/scene_router.gd":true,"res://scripts/field/field_walkable_controller.gd":true,
		"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":true}
	var task: Variant=load("res://scripts/city/luoyang_city_tasks_20261016.gd")
	var task_paths: Dictionary=task.source_paths()
	if not _require(not task_paths.is_empty(),"Original TASK complete closure refused"): return false
	_sources.merge(task_paths)
	for record: Dictionary in [approval,environment]:
		for proof: String in [String(record.report_path),String(record.verifier_path)]: _sources[proof]=true
		if not _require(FileAccess.get_sha256(record.report_path)==record.report_sha256 and FileAccess.get_sha256(record.verifier_path)==record.verifier_sha256,"ROOT exact import evidence changed"): return false
		if record.has("prepared_path"):
			if not _require(FileAccess.get_sha256(record.prepared_path)==record.prepared_sha256,"Exact environment preparation evidence changed"): return false
			_sources[String(record.prepared_path)]=true
	for row: Dictionary in texture_proofs:
		for pair: Array in [[row.texture,row.source_sha256],[row.import_path,row.import_sha256],[row.compiled_path,row.compiled_sha256]]:
			if not _require(FileAccess.get_sha256(pair[0])==pair[1],"Approved new import/source changed: "+String(pair[0])): return false
			_sources[pair[0]]=true
	for path: String in provenance.source_sha256:
		if not _require(path.begins_with("res://") and ".." not in path and FileAccess.get_sha256(path)==provenance.source_sha256[path],"Native environment provenance changed: "+path): return false
		_sources[path]=true
	var before: Dictionary=_hash(_sources)
	if before.is_empty(): return false
	var original: SceneScript=T.original_scene()
	var scene: SceneScript=T.build_scene(original,authored)
	if not _require(scene!=null and scene.actor_positions_are_feet and scene.map_layout.visual_objects.size()==authored.placements.size() and authored.placements.size()==21,"Real canonical -> nine-source/21-component child construction"): return false
	var size:=Vector2(1920,1280)
	var geometry: Dictionary=T.GEOMETRY.compile_geometry(authored.geometry,size)
	if not _require(T.anchors_clear(geometry,authored,size),"Six relocated full-body approaches, original two exits/default blocked"): return false
	for route: Dictionary in authored.required_routes:
		var points: Array=route.points_px
		if not _require(points.size()>=2,"Route has no complete path"): return false
		for i: int in range(1,points.size()):
			var a: Vector2=T._v(points[i-1])*size/T.SOURCE_SIZE; var b: Vector2=T._v(points[i])*size/T.SOURCE_SIZE
			var steps: int=maxi(1,ceili(a.distance_to(b)/4.0))
			for k: int in range(steps+1):
				_samples+=1
				if not _require(T.safe_foot(geometry,a.lerp(b,float(k)/steps),size,true),"Full875/17/continuous route rejected: "+String(route.id)+" segment "+str(i)+" sample "+str(k)): return false
	for point: Dictionary in authored.negative_points:
		if not _require(not T.safe_foot(geometry,T._v(point.foot_px)*size/T.SOURCE_SIZE,size,true),"Solid negative unexpectedly clear: "+String(point.id)): return false
	for point: Dictionary in authored.validation_stations:
		if not _require(T.safe_foot(geometry,T._v(point.foot_px)*size/T.SOURCE_SIZE,size,true),"Validation station blocked: "+String(point.id)): return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(T.LAYOUT_PATH.get_base_dir()))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(T.SCENE_PATH.get_base_dir()))
	if not _require(ResourceSaver.save(scene.map_layout,T.LAYOUT_PATH)==OK,"NEW layout write refused"): return false
	scene.map_layout=ResourceLoader.load(T.LAYOUT_PATH,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not _require(scene.map_layout!=null and ResourceSaver.save(scene,T.SCENE_PATH)==OK,"NEW Scene write refused"): return false
	var loaded:=ResourceLoader.load(T.SCENE_PATH,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var expected: SceneScript=T.build_scene(original,authored)
	if not _require(load(SERIAL).serialized_equal(loaded,expected),"NEW full all-storage TRES readback differs"): return false
	var after: Dictionary=_hash(_sources)
	if not _require(load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")._equal_value(before,after),"Candidate source changed during bounded CPU"): return false
	var fixed: Dictionary=before.duplicate(true)
	# SELF carries the fixed BIND_SHA and the sole future formal bool. It is
	# still in runtime first/final SHA, never self-pinned into a hash cycle.
	fixed.erase(T.SELF)
	fixed[T.SCENE_PATH]=FileAccess.get_sha256(T.SCENE_PATH); fixed[T.LAYOUT_PATH]=FileAccess.get_sha256(T.LAYOUT_PATH)
	var bind: Dictionary={"status":"READY_IMPORTED_TEMPLE_CANDIDATE","assets_ready":true,"author_path":AUTHOR,"author_sha256":FileAccess.get_sha256(AUTHOR),"texture_proofs":texture_proofs,"source_sha256":fixed,"cpu_scope":{"budget_msec":LIMIT_MSEC,"routes":authored.required_routes.size(),"samples":_samples,"body_world_px":[34,24],"full875":true,"perimeter17":true,"max_world_step":4,"native_physics_run":false},"source_first":before,"source_final":after,"no_c_city_receipt":true,"not_formal":true}
	if not _require(T.structure_valid(bind,authored),"Complete unique nine-texture/source/remap structure rejected"): return false
	return _write(T.BIND_PATH,bind)
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	_started=Time.get_ticks_msec()
	var passed: bool=_publish()
	var output: String="res://build/luoyang_temple_assembly_publication_20261016/"+str(OS.get_process_id())+"_"+str(_started)+"/result.json"
	_write(output,{"passed":passed,"error":_failure,"checks":_checks,"samples":_samples,"elapsed_msec":Time.get_ticks_msec()-_started,"binding":T.BIND_PATH,"binding_sha256":FileAccess.get_sha256(T.BIND_PATH),"scene":T.SCENE_PATH,"layout":T.LAYOUT_PATH,"native_physics_run":false,"not_formal":true})
	print(JSON.stringify({"passed":passed,"error":_failure,"checks":_checks,"samples":_samples,"result":output}))
	quit(0 if passed else 1)
