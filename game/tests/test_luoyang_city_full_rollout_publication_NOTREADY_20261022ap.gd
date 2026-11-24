extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## AP NEW publication/native admission only. Root alone executes after final source freeze.
## Does not call C.prepare, quarter compile/audit, old AO/AN geometry, imports, or Field.
const AP_PUBLICATION_READY: bool=false
const CONTRACT: String="res://build/luoyang_city_full_rollout_20261022ap_qa01/runner_contract_v1_NOTREADY.json"
const CONTRACT_SHA: String="PENDING_FINAL_CONTRACT"
const LIMIT_MS: int=30000
const B_PATH: String="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
var ap_plan: Dictionary={}

func precheck() -> bool:
	if not check(AP_PUBLICATION_READY,"NOTREADY: final publication/artifact/source maps not frozen"): return false
	if not check(OS.get_cmdline_user_args().is_empty(),"No undeclared publication suite args") or not track(CONTRACT,CONTRACT_SHA): return false
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
	if not check(value is Dictionary and value.get("ready")==true and value.get("publication_ms")==LIMIT_MS,"Frozen AP publication30s contract"): return false
	ap_plan=value
	for path: String in ap_plan.core_source_sha256:
		if not track(path,ap_plan.core_source_sha256[path]): return false
	if not check(ap_plan.core_source_sha256.has(B_PATH),"Actual storage codec belongs to fixed execution sources"): return false
	var publication: Dictionary=ap_plan.publication
	if not track(publication.report_path,publication.report_sha256): return false
	return check(publication.rows is Array and publication.rows.size()==2 and publication.expected_ids==["luoyang_artisan_residential_20261022ap","luoyang_riverside_garden_20261022ap"],"Only new two-quarter publication, no old geometry suite")

func exercise_cpu() -> bool:
	var b: Variant=load(B_PATH)
	var report: Variant=JSON.parse_string(FileAccess.get_file_as_string(ap_plan.publication.report_path))
	if not check(report is Dictionary and report.get("passed")==true and report.get("source_first") is Dictionary and not report.source_first.is_empty() and b.equal(report.source_first,report.get("source_final")),"Actual publication complete own first/final; not Field credit"): return false
	var seen: Dictionary={}
	for row: Dictionary in ap_plan.publication.rows:
		if not check(row.id in ap_plan.publication.expected_ids and not seen.has(row.id),"Exactly one new native publication row "+row.id): return false
		seen[row.id]=true
		if not check(report.published.has(row.id) and b.equal(report.published[row.id],row.expected_publication_row),"Full publisher row exact, not only pass/count "+row.id): return false
		for path: String in row.artifacts:
			if not track(path,row.artifacts[path]): return false
		var scene: SceneScript=ResourceLoader.load(row.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		var layout: WalkableMapLayout=ResourceLoader.load(row.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
		var decoded: Variant=bytes_to_var(FileAccess.get_file_as_bytes(row.packet_path))
		if not check(scene!=null and layout!=null and decoded is Dictionary and b._plain(decoded) and String(scene.scene_id)==row.id and scene.actor_positions_are_feet and decoded.get("kind")=="AP_SOURCE_BOUND_NEW_ORDINARY_QUARTER" and decoded.get("scene_id")==row.id,"Actual typed native/packet kind/Scene identity "+row.id): return false
		if not check(b.equal(b.storage(scene),decoded.get("scene_storage")) and b.equal(b.storage(layout),decoded.get("layout_storage")) and b.equal(b.storage(scene.map_layout),b.storage(layout)),"Whole storage graphs and native linked layout exact "+row.id): return false
		if not check(decoded.get("walk_bytes") is PackedByteArray and decoded.walk_bytes.size()==3072*2048*4 and b.bytes_sha(decoded.walk_bytes)==row.mask_rgba_sha256 and decoded.get("mask_sha256")==row.mask_rgba_sha256 and b.equal(decoded.get("solids"),row.expected_solids),"Actual complete packet mask and all new transformed solids "+row.id): return false
		# Full affected87517/continuous/raster audit is the pinned publication's
		# one execution. Do not rerun historical geometry or import RGBA here.
		# Published report is the JSON writer domain; native geometry counters are
		# int while JSON reads finite doubles. Do not confuse it with typed storage.
		var geometry_wire: Variant=JSON.parse_string(JSON.stringify(decoded.get("geometry")))
		var body: Variant=row.expected_geometry.get("body")
		if not check(b.equal(geometry_wire,row.expected_geometry) and row.expected_geometry.get("ok")==true and row.expected_geometry.get("full875_plus17")==true and body is Array and body.size()==2 and float(body[0])==34.0 and float(body[1])==24.0,"Pinned actual affected geometry proof in original JSON writer domain, not fresh second audit "+row.id): return false
		records.append({"kind":"AP_NEW_QUARTER_NATIVE_ADMISSION","id":row.id,"geometry_replayed":false,"native_whole_storage":true,"full_packet_mask_bytes":decoded.walk_bytes.size(),"artifacts":row.artifacts})
	return check(seen.size()==2,"Both new quarters admitted; no eight-Field/art proof implied")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+LIMIT_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=false
	if precheck(): complete=exercise_cpu()
	finish("res://build/luoyang_city_full_rollout_20261022ap_qa01/publication/%d_%d"%[OS.get_process_id(),began],began,complete,"AP_TWO_NEW_QUARTERS_PUBLICATION_NO_OLD_GEOMETRY_NO_FIELD_30S_NOTREADY")
