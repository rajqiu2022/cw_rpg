extends "res://scripts/dev/build_luoyang_modular_v3_wall_v5_capture_candidate.gd"
## Exact parent capture inherited; only the source factory and explicit market spatial revision are new.
## NO automatic overwrite/archive/move. ROOT separately releases the verified old market directory.
const NOTE_SOURCE := preload("res://scripts/dev/luoyang_modular_v3_wall_v5_note_source.gd")
const NOTE_FACTORY_PATH := "res://scripts/dev/luoyang_modular_v3_wall_v5_note_source.gd"
const NOTE_PINS := {
	NOTE_FACTORY_PATH:"87cc012222bf218a26943164f40868af104f7e1ac1f1417e3378a4ce3fb77667",
	"res://scripts/dev/build_luoyang_modular_v3_wall_v5_capture_candidate.gd":"0aac9b827b72d8cedf1ab94808fba8d2a84b43c2d0efd503400170326a28c423",
	NOTE_SOURCE.NOTE_MEASUREMENT:NOTE_SOURCE.NOTE_MEASUREMENT_SHA,
	NOTE_SOURCE.NOTE_OLD_MANIFEST:NOTE_SOURCE.NOTE_OLD_MANIFEST_SHA,
	NOTE_SOURCE.NOTE_SOURCE:NOTE_SOURCE.NOTE_SHA,
}
func _run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	for required: String in ["--luoyang-v3-wall-v5-note-capture","--luoyang-modular-v3-capture"]:
		if required not in args:
			error="Isolated street detail requires all explicit capture flags; no default export."
			await _roof_refuse()
			return
	if DisplayServer.get_name()=="headless" or "--luoyang-v3-source-plan" in args:
		error="This proposal requires an actual serial GPU capture, not headless or plan-only."
		await _roof_refuse()
		return
	var pins: Dictionary=WALL_ADAPTER.PINS.duplicate()
	for dependency: String in NOTE_PINS: pins[dependency]=NOTE_PINS[dependency]
	for dependency: String in WALL_ADAPTER.V5_EXTRA_PINS:
		pins[dependency]=WALL_ADAPTER.V5_EXTRA_PINS[dependency]
	pins[V5_ORIGIN_CAPTURE]=V5_ORIGIN_CAPTURE_SHA
	pins[WALL_ADAPTER_PATH]=WALL_ADAPTER_SHA
	pins[WALL_SURFACE_PATH]=WALL_SURFACE_SHA
	pins[ROOF_TRIAL_PATH]=ROOF_TRIAL_SHA
	pins[STREET_PARENT_PATH]=STREET_PARENT_SHA
	pins[DETAIL_ADAPTER_PATH]=DETAIL_ADAPTER_SHA
	pins[DETAIL_SURFACE_PATH]=DETAIL_SURFACE_SHA
	for path: String in pins:
		if FileAccess.get_sha256(path).to_lower()!=String(pins[path]):
			error="Frozen street-detail dependency changed: "+path
			await _roof_refuse()
			return
	var chosen := "ch4_s3_luoyang_market"
	var run_tag := ""
	for arg: String in args:
		if arg.begins_with("--city-region="): chosen=arg.trim_prefix("--city-region=")
		if arg.begins_with("--wall-v5-run-tag="): run_tag=arg.trim_prefix("--wall-v5-run-tag=")
	if run_tag!="root_wall_v5":
		error="Independent V5 sample requires root_wall_v5; previous evidence cannot be overwritten."
		await _roof_refuse()
		return
	var tag_rule:=RegEx.new()
	if tag_rule.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$")!=OK or tag_rule.search(run_tag)==null or chosen not in SOURCE.REGIONS:
		error="Explicit safe unique run tag and exact canonical city region required."
		await _roof_refuse()
		return
	if chosen != NOTE_SOURCE.NOTE_REGION:
		error="Independent note capture is strictly market only; other three manifests stay exact."
		await _roof_refuse()
		return
	if FileAccess.get_sha256(V5_PREVIOUS_ROOT+chosen+"/art_contract.json").to_lower()!=V5_PREVIOUS_MANIFESTS[chosen]:
		error="Immutable current V4 comparison manifest changed."
		await _roof_refuse()
		return
	OUT=WALL_ART_ROOT+run_tag+"/"+chosen+"/"
	detail_audit="res://build/luoyang_modular_v3_wall_v5_note_revision/"+run_tag+"/"+chosen+"/"
	if FileAccess.get_sha256(BASELINE_ROOT+chosen+"/art_contract.json").to_lower()!=String(BASELINE_MANIFEST_SHA[chosen]):
		error="Current immutable street-detail baseline manifest changed."
		await _roof_refuse()
		return
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(OUT)) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(detail_audit)):
		error="Proposal refuses overwrite, including failed output; choose a fresh run tag."
		await _roof_refuse()
		return
	source=NOTE_SOURCE.new()
	source.prepare(chosen)
	if source.preparation_error!="":
		error=source.preparation_error
		await _roof_refuse()
		return
	# Only the output locator changes, never routes, solids, actors or functions.
	source.region_out=OUT
	detail_baseline_navigation=_detail_navigation_identity()
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(detail_audit))!=OK or DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+"entities/"))!=OK:
		error="Cannot create new isolated output/audit directories."
		await _finish(false)
		return
	var forecast: Dictionary=source.forecast()
	if not _json(detail_audit+"source_forecast.json",forecast) or not bool(forecast.get("passed",false)):
		error="Unchanged city full17/Rectangle34x24 source forecast failed; no visual fallback."
		await _finish(false)
		return
	if not _json(OUT+"art_contract.json",{"schema_version":1,"status":"BUILD_IN_PROGRESS","production_approved":false,"scope":WALL_IDENTITY}):
		await _finish(false)
		return
	detail_adapter=WALL_ADAPTER.new()
	if not detail_adapter.prepare(source.snapshot()):
		error=detail_adapter.error
		await _finish(false)
		return
	# Parent _capture_city calls these instance methods for its actual paving and
	# shoulder materials. Static SURFACE.plain/environment/water geometry remain.
	surface=detail_adapter.detail
	if not _measure_buildings() or not _stage_generated_textures():
		await _finish(false)
		return
	var needed: Array[String]=[]
	for object: Dictionary in source.objects:
		var kind: String=object["prototype"]
		if kind!="" and kind not in needed: needed.append(kind)
	for kind: String in needed:
		if not await _prototype(kind):
			await _finish(false)
			return
	if not await _capture_city():
		await _finish(false)
		return
	await _finish(true)

func _source_graph() -> Dictionary:
	var graph: Dictionary=super._source_graph()
	for path: String in NOTE_PINS: graph[path]=FileAccess.get_sha256(path)
	return graph

func _json(path: String,data: Dictionary) -> bool:
	var destination: String=path
	if path.begins_with(AUDIT): destination=detail_audit+path.trim_prefix(AUDIT)
	if detail_audit=="" or not (destination.begins_with(OUT) or destination.begins_with(detail_audit)) or not OUT.begins_with(WALL_ART_ROOT):
		error="New wall/street writer refused path outside isolated output."
		return false
	if destination==OUT+"material_binding.json" and not _detail_measure_paving_binding(): return false
	var measured: Dictionary=data.duplicate(true)
	if destination==OUT+"material_binding.json" or measured.has("material_binding_evidence"):
		var binding: Dictionary=measured if destination==OUT+"material_binding.json" else measured["material_binding_evidence"]
		binding["stone_albedo_used_in_fragment"]="Actual unchanged stone UV ALBEDO plus continuous route polish/apron/wet-quay owner finishes; no checker palette, new terrain vertices, nav painting or fake cast."
		binding["actual_surface_script"]={"path":WALL_SURFACE_PATH,"sha256":FileAccess.get_sha256(WALL_SURFACE_PATH)}
		binding["native_detail_material_records"]=detail_adapter.detail.material_records.duplicate(true)
		binding["native_geometry_owner_uniforms"]=detail_paving_binding.duplicate(true)
		binding["actual_zone_material_records"]=(surface as V5_ZONE_SURFACE).zone_material_records.duplicate(true)
	if destination==OUT+"art_contract.json" and measured.get("status","")=="ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA":
		if surface==null or surface.get_script().resource_path!=WALL_SURFACE_PATH or surface!=detail_adapter.detail:
			error="Final new contract actual surface binding mismatch."
			return false
		measured["scope"]="ISOLATED_V5_VERTICAL_UPPER_AND_ZONE_SAMPLE_NOT_FIELD_OR_FORMAL_APPROVED"
		measured["capture_surface_binding"]={"path":WALL_SURFACE_PATH,"sha256":FileAccess.get_sha256(WALL_SURFACE_PATH),"actual_instance_equals_prepared_adapter_surface":true}
		measured["upper_wall_street_revision"]={"identity":WALL_IDENTITY,"scope":"NEW_UPPER_GEOMETRY_AND_ALPHA_NOT_MATERIAL_ONLY","baseline_manifest_path":BASELINE_ROOT+source.region+"/art_contract.json","baseline_manifest_sha256":BASELINE_MANIFEST_SHA[source.region],"parent_builder":{"path":STREET_PARENT_PATH,"sha256":STREET_PARENT_SHA},"executed_builder":{"path":get_script().resource_path,"sha256":FileAccess.get_sha256(get_script().resource_path)},"adapter_script":{"path":WALL_ADAPTER_PATH,"sha256":FileAccess.get_sha256(WALL_ADAPTER_PATH)},"surface_script":{"path":WALL_SURFACE_PATH,"sha256":FileAccess.get_sha256(WALL_SURFACE_PATH)},"actual_wall_comparisons":detail_wall_comparisons.duplicate(true),"ground_native_clone_evidence":detail_adapter.evidence.duplicate(true),"source_navigation_identity_sha256":detail_adapter._hash(var_to_bytes(detail_baseline_navigation)),"unchanged_scope":["source3072camera","groundRF/paving/support arrays","worldfoot/solids/ordinary34x24+17","15NPC/11actions/12portals/route coordinates","original generated source PNG bytes"],"changed_scope":["vertical upper shoulder/eave arrays14+16 only","horizontal geometry unchanged/currentV4 exact","actual vertical body alpha/bbox/crop/footUV","Zone continuous registered-material finishes"],"production_approved":false}
		measured["v5_scope"]={"origin_capture":{"path":V5_ORIGIN_CAPTURE,"sha256":V5_ORIGIN_CAPTURE_SHA},"current_v4_manifest":{"path":V5_PREVIOUS_ROOT+source.region+"/art_contract.json","sha256":V5_PREVIOUS_MANIFESTS[source.region]},"actual_current_v4_wall_comparisons":v5_wall_comparisons.duplicate(true),"geometry_not_material_only":true,"field_executed":false,"visual_approved":false,"production_approved":false}
		measured["asset_sha256"][V5_PREVIOUS_ROOT+source.region+"/art_contract.json"]=V5_PREVIOUS_MANIFESTS[source.region]
		for comparison: Dictionary in v5_wall_comparisons.values():
			measured["asset_sha256"][comparison["previous_mesh_path"]]=comparison["previous_mesh_sha256"]
		measured["capture_graph"]["surface_script"]={"path":WALL_SURFACE_PATH,"sha256":FileAccess.get_sha256(WALL_SURFACE_PATH)}
		measured["capture_graph"]["material_adapter_script"]={"path":WALL_ADAPTER_PATH,"sha256":FileAccess.get_sha256(WALL_ADAPTER_PATH)}
		measured["capture_graph"]["paving_material"]={"path":OUT+"paving_material.res","sha256":FileAccess.get_sha256(OUT+"paving_material.res")}
		measured["asset_sha256"][OUT+"paving_material.res"]=FileAccess.get_sha256(OUT+"paving_material.res")
		measured["asset_sha256"][OUT+"material_binding.json"]=FileAccess.get_sha256(OUT+"material_binding.json")
		measured["asset_sha256"][BASELINE_ROOT+source.region+"/art_contract.json"]=BASELINE_MANIFEST_SHA[source.region]
		for kind: String in detail_wall_comparisons:
			var old_path: String=detail_wall_comparisons[kind]["original_mesh_path"]
			measured["asset_sha256"][old_path]=FileAccess.get_sha256(old_path)
	if destination==OUT+"art_contract.json" and measured.get("status")=="ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA":
		if source==null or source.get_script().resource_path!=NOTE_FACTORY_PATH or source.region!=NOTE_SOURCE.NOTE_REGION:
			error="Actual note factory missing; no old source relabel"
			return false
		measured["note_placement_revision"]=(source as NOTE_SOURCE).note_revision.duplicate(true)
		measured["capture_graph"]["source_script"]={"path":NOTE_FACTORY_PATH,"sha256":FileAccess.get_sha256(NOTE_FACTORY_PATH)}
		for dependency: String in NOTE_PINS:
			measured["asset_sha256"][dependency]=FileAccess.get_sha256(dependency)
			measured["source_graph"][dependency]=FileAccess.get_sha256(dependency)
		measured["asset_sha256"][get_script().resource_path]=FileAccess.get_sha256(get_script().resource_path)
		measured["upper_wall_street_revision"]["unchanged_scope"]=["source3072camera","groundRF/paving/support arrays","all original object worldfoot/solids/ordinary34x24+17","all15NPC feet/all11 action identities/all12 portal coordinates/original routes","original generated source PNG bytes"]
		measured["upper_wall_street_revision"]["changed_scope"].append("Only xuantong_note stand/object binding plus one measured independent low scroll; no action/onceflag change")
	var file:=FileAccess.open(destination,FileAccess.WRITE)
	if file==null:
		error="New isolated checked JSON open failed: "+destination
		return false
	var text: String=JSON.stringify(measured,"\t")
	file.store_string(text)
	file.flush()
	var code: int=file.get_error()
	file.close()
	if code!=OK or FileAccess.get_file_as_string(destination)!=text or not JSON.parse_string(text) is Dictionary:
		error="New isolated exact JSON write/readback failed."
		return false
	return true

