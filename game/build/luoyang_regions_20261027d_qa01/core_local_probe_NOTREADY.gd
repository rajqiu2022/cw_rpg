extends SceneTree
## QA synthetic core probe only. Root must seal hashes and authorize one run.
## No Field/Scene/packet/image/Physics/collector/save calls; no authored layout approval.
const READY := false
const COMPILER_PATH := "res://build/luoyang_regions_20261027d_source01/region_compiler.gd"
const ALIAS_PATH := "res://build/luoyang_regions_20261027d_source01/legacy_alias.gd"
const SOURCE_SHA := {COMPILER_PATH: "PENDING_FINAL_SOURCE_SEAL", ALIAS_PATH: "PENDING_FINAL_SOURCE_SEAL"}
const OUTPUT := "res://build/luoyang_regions_20261027d_qa01/core_local_probe_output/result.json"
var started: int
var checks: int = 0
var failures: Array = []
var observations: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)
	if Time.get_ticks_usec() - started > 15000000:
		failures.append("GLOBAL_15S_DEADLINE"); _finish(); quit(1)

func _finish() -> void:
	var result := {"complete": failures.is_empty(), "checks": checks, "failures": failures, "elapsed_usec": Time.get_ticks_usec()-started, "observations": observations, "limits": "synthetic local core only; no actual region layout, Field, Task, service, continuous Physics or artwork credit"}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result, "\t") + "\n")
	quit(0 if failures.is_empty() and file != null else 1)

func _terminal(id: String) -> Dictionary:
	return {"schema":"27D_SOURCE_TERMINAL_V1", "logical_id":id, "local_size_px":[512,512], "sources":SOURCE_SHA.duplicate(true), "render":[{"id":"building", "owner_id":"building", "texture":"SYNTHETIC_NOT_LOADED", "texture_size_px":Vector2(40,40), "position_px":Vector2(100,100), "foot_px":Vector2(100,120), "scale":Vector2.ONE}], "solids":[{"owner_id":"building", "points_px":PackedVector2Array([Vector2(400,350),Vector2(440,350),Vector2(440,390),Vector2(400,390)])}], "npcs":[], "portals":[], "interactions":[]}

func _district(id: String, x: int) -> Dictionary:
	return {"logical_id":id, "domain":[[x,0],[512,512]], "legacy_size_px":[512,512], "legacy_version":3, "legacy_frame_origin":[x,0], "save_fallback_uv":[0.5,0.25], "plots":[{"id":"lot", "owners":["building"], "source_anchor_px":[0,0], "target_anchor_px":[x,0]}], "actors":{}, "portals":{}, "interactions":{}, "migrations":[], "station_transforms":[], "new_solids":[], "retired_owners":[]}

func _run() -> void:
	started = Time.get_ticks_usec()
	if not READY:
		push_error("QA_PROBE_NOTREADY_NO_RUN_AUTHORIZATION"); quit(1); return
	for path: String in SOURCE_SHA:
		_check(FileAccess.get_sha256(path)==SOURCE_SHA[path], "PIN:"+path)
	if not failures.is_empty(): _finish(); return
	var c: Variant = load(COMPILER_PATH)
	var alias: Variant = load(ALIAS_PATH)
	_check(c is GDScript and alias is GDScript, "CORE_SCRIPTS_LOAD")
	if not failures.is_empty(): _finish(); return
	var region := {"world_size_px":[1024,512], "ground":[{"id":"ground", "rect":[[0,0],[1024,512]]}], "districts":[_district("A",0),_district("B",512)], "routes":[{"id":"cross_logical_boundary", "points_px":[[100,128],[924,128]]}]}
	var author := {"schema":"LUOYANG_REGION_27D_V1", "revision":1, "regions":{"synthetic":region}}
	var compiled: Dictionary = c.compile(author,"synthetic",{"A":_terminal("A"),"B":_terminal("B")})
	_check(compiled.get("ok")==true, "SYNTHETIC_COMPILE")
	if not failures.is_empty(): observations.compile_error=compiled; _finish(); return
	_check(compiled.render.size()==2 and compiled.solids.size()==2, "RENDER_AND_SOLID_OWNER_COUNTS")
	_check(compiled.render[1].position_px==Vector2(612,100), "RENDER_TRANSLATION")
	_check(compiled.solids[1][0]==Vector2(912,350), "SOLID_SAME_TRANSLATION")
	_check(c.safe_body(compiled,Vector2(100,128),Vector2(17,12)), "FULL_BODY_POSITIVE")
	_check(not c.safe_body(compiled,Vector2(420,370),Vector2(17,12)), "SOLID_BODY_NEGATIVE")
	_check(not c.safe_body(compiled,Vector2(16,128),Vector2(17,12)), "WORLD_EDGE_FULL_BODY_NEGATIVE")
	_check(c.safe_segment(compiled,Vector2(100,128),Vector2(924,128),Vector2(17,12)), "CROSS_BOUNDARY_SOURCE_ROUTE")
	_check(not c.safe_segment(compiled,Vector2(380,370),Vector2(460,370),Vector2(17,12)), "SEGMENT_THROUGH_SOLID_NEGATIVE")
	var gap: Dictionary = compiled.duplicate(true)
	gap.floor_rects=[Rect2(0,0,1024,124),Rect2(0,125,1024,387)]
	_check(not c.safe_body(gap,Vector2(100,128),Vector2(17,12)), "RECT_UNION_INTERIOR_GAP_NEGATIVE")
	for row: Array in [["A",Vector2(100,128)],["B",Vector2(612,128)],["A",Vector2(500,128)],["B",Vector2(512,128)]]:
		var nav: Dictionary = alias.navigation(compiled,row[1])
		_check(nav.get("ok")==true and nav.get("current_field")==row[0], "LOGICAL_DOMAIN:"+row[0]+str(row[1]))
		if nav.get("ok")!=true: continue
		var restored: Dictionary = alias.arrive(compiled,row[0],nav.current_field_spawn,nav.local_layout_version,nav.region27d)
		_check(restored.get("ok")==true and restored.get("foot")==row[1], "EXTENSION_EXACT_ROUNDTRIP:"+row[0]+str(row[1]))
	var old: Dictionary = alias.arrive(compiled,"B",Vector2(100.0/512.0,0.25),3)
	_check(old.get("ok")==true and old.get("foot")==Vector2(612,128), "OLD_LOCAL_UV_AFFINE")
	_check(alias.arrive(compiled,"A",Vector2(0.25,0.25),2).get("ok")!=true, "UNKNOWN_LEGACY_VERSION_NEGATIVE")
	_check(alias.arrive(compiled,"A",Vector2(1.2,0.25),3).get("ok")!=true, "OLD_UV_OUT_OF_RANGE_NEGATIVE")
	var wrong: Dictionary = compiled.duplicate(true)
	wrong.districts.A.migrations=[{"old_rect":[[0,0],[512,512]],"target_foot_px":[612,128],"reason":"SYNTHETIC_WRONG_DISTRICT"}]
	_check(alias.arrive(wrong,"A",Vector2(0.25,0.25),3).get("ok")!=true, "MIGRATION_TO_WRONG_LOGICAL_DOMAIN_NEGATIVE")
	observations = {"synthetic_only":true,"body_size_px":[34,24],"source_route_sampling":"one-pixel samples; not proof of continuous Physics", "Task_service_same_Field_checks":"DEFERRED_TO_SOURCE_CONTEXT_AND_REAL_FIELD_CANDIDATE"}
	for path: String in SOURCE_SHA: _check(FileAccess.get_sha256(path)==SOURCE_SHA[path], "FINAL_PIN:"+path)
	_finish()
