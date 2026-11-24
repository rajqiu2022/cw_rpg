extends RefCounted
const V8_ORIGINAL_PARENT_PATH: String = "res://tests/helpers/joint_v15_wall_street_world_parent_parsefix_phase.gd"
const V8_ORIGINAL_PARENT_SHA: String = "3ac990ad2073fe516837cd512e01024f6837b5e79953a4c9fefc27d1307f52d1"
## NEW joint-owned production Field phase, mechanically reuses frozen v15
## input methods. Current new-root bytes are revalidated; no old result reuse.
## run() is only called after the joint frozen-artifact preflight succeeds.
const V8_CONTEXT := preload("res://tests/helpers/joint_v15_v8_source_context_oracle.gd")
const RAW_ORACLE := preload("res://tests/helpers/joint_v15_v8_world_raw_oracle.gd")
const INPUT_DRIVER := preload("res://tests/helpers/v15_input_driver.gd")
const GEOMETRY_ORACLE := preload("res://tests/helpers/v15_geometry_oracle.gd")
const OVERVIEW_PROBE := preload("res://tests/helpers/joint_v15_v8_overview_input_probe.gd")
const BATTLE_PROBE := preload("res://tests/helpers/joint_v15_battle_return_probe.gd")
const NORMAL_NPC_PROBE := preload("res://tests/helpers/joint_v15_normal_npc_depth_probe.gd")
const SAVED_GEOMETRY := preload("res://tests/helpers/joint_v15_v8_world_geometry_phase.gd")
const ALL_OBJECTS := preload("res://tests/helpers/joint_v15_v8_world_object_input_probe.gd")
const SAVED_CONTEXTS := preload("res://tests/helpers/joint_v15_world_saved_context_probe.gd")
const ARTIFACTS := preload("res://tests/helpers/joint_v15_world_artifact_semantics_v8_probe.gd")
const ORDINARY_RAW := preload("res://tests/helpers/joint_v15_wall_v5_ordinary_raw_oracle.gd")
const CITY_IDS: Array[String] = ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
const ISOLATED_SAVES_PATH := "res://tests/helpers/v15_isolated_save_manager.gd"
const MIGRATION_SUBJECT := preload("res://scripts/world/world_map_v15_contract.gd")
const PHASES := ["raw", "portal", "depth", "migration", "full"]
var owner_tree: SceneTree
var result: Dictionary = {}
var root: Window:
	get: return owner_tree.root
var current_scene: Node:
	get: return owner_tree.current_scene
	set(value): owner_tree.current_scene = value
var process_frame: Signal:
	get: return owner_tree.process_frame
var physics_frame: Signal:
	get: return owner_tree.physics_frame
func create_timer(seconds: float) -> SceneTreeTimer:
	return owner_tree.create_timer(seconds)
var execution_sha256: Dictionary = {}
var v8_artifact_sha256: Dictionary = {}
func run(tree: SceneTree, selected_phase: String = "full", candidate: bool = true, frozen_inputs: Dictionary = {}) -> Dictionary:
	var execution_value: Variant = frozen_inputs.get("execution_sha256")
	var final_value: Variant = frozen_inputs.get("v8_artifact_sha256")
	execution_sha256 = execution_value.duplicate(true) if execution_value is Dictionary else {}
	v8_artifact_sha256 = final_value.duplicate(true) if final_value is Dictionary else {}
	owner_tree = tree
	requested_phase = selected_phase
	scene_id = &"world_map_jianghu_v15" if candidate else &"world_map_jianghu"
	scene_path = "res://data/scenes/%s.tres" % scene_id
	await _run()
	return result.duplicate(true)

const SIZE := Vector2(12288, 8192)
const CHUNK_SIZE := Vector2i(1536, 1024)
var scene_path: String = "res://data/scenes/world_map_jianghu_v15.tres"
var scene_id: StringName = &"world_map_jianghu_v15"
const SOURCE_PATH := "res://data/maps/world_map_v15_complete_v8_source.json"
const MANIFEST_PATH := "res://art/maps/world_map_v15_complete_v8/art_contract.json"
const REVIEW_PATH := "res://data/maps/world_map_v15_complete_v8_visual_review.json"
const WHOLE_REPORT_PATH := "res://art/maps/world_map_v15_complete_v8/whole_actual_capture.json"
const WHOLE_PROTOCOL := "COHERENT_WHOLE_FIXED_CAMERA_INTEGER_TEXEL_ROI_V1_FULL"
const REVIEW_FOOTPRINTS := "res://data/maps/world_map_v15_complete_v5_landmark_footprints_candidate.json"
const CORE_IDS := ["huashan", "luoyang", "bianzhou", "gufeng", "wudang", "xiangzhou", "jinling", "lingyue", "mingwu"]
const NEW_SECT_IDS := ["huashan", "gufeng", "wudang", "lingyue"]
const DESTINATIONS := {
	"yanmen_pass": "openworld_yanmen_pass", "huashan": "openworld_huashan_forecourt", "wudang": "openworld_wudang_gate", "gufeng": "ch5_s1_relief_road", "lingyue": "ch2_s4_lingyue_gate",
	"bianzhou": "openworld_bianzhou_city", "linxi_village": "linxi_village_scrollmap", "luoyang": "ch4_s0_luoyang_gate", "xiangzhou": "openworld_xiangzhou_city", "east_sea_port": "openworld_east_sea_port", "bailu_ferry": "openworld_bailu_ferry",
	"zhuwei_village": "ch1_s2_qingfeng", "qinghe_town": "openworld_qinghe_town", "jinling": "openworld_jinling_city", "mingwu": "ch7_s2_mingwu_tea_town", "lieyun_valley": "ch7_s1_lieyun_valley_ferry"}
var checks := 0
var failures := 0
var completed_phases: Array[String] = []
var incomplete_phases: Array[String] = []
var world: SceneScript
var source: Dictionary
var manifest: Dictionary
var oracle: RefCounted
var field: Node
var before_saves: Dictionary
var prior_navigation: Dictionary
var prior_active: StringName
var prior_slot := -1
var output := ""
var route_centers := 0
var portals_by_id: Dictionary = {}
var requested_phase := "full"
var requested_portal := ""
var requested_mode := "all"
var input_driver: RefCounted
var runtime_started := false
var actual_portal_roundtrips: Array[Dictionary] = []
var ordinary_images: Array[Dictionary] = []
var ordinary_blockers: Array[Rect2] = []
var ordinary_size := Vector2.ZERO
var alpha_oracle: RefCounted
var isolated_slots: Node
var isolated_directory := ""
var ordinary_raw: RefCounted
var ordinary_native_city: bool = false
var saved_geometry_report: Dictionary = {}
var all_object_report: Dictionary = {}
var saved_context_report: Dictionary = {}
var artifact_report: Dictionary = {}
var driven_world_routes: Array[Dictionary] = []
var actual_open_seam_crossings: Array[Dictionary] = []
var raw_screenshots: Array[Dictionary] = []
var reviewed_doors: Dictionary = {}
var reviewed_default_spawn: Vector2 = Vector2(INF,INF)
var visual_review_evidence: Dictionary = {}
var default_spawn_evidence: Dictionary = {}

func _world_clear(point: Vector2) -> bool:
	return oracle != null and bool(oracle.call("clear",point)) and _physical_clear(point)

func _world_segment(a: Vector2, b: Vector2) -> Dictionary:
	var count: int = maxi(1,ceili(a.distance_to(b)/4))
	for index in range(count+1):
		var point: Vector2 = a.lerp(b,float(index)/count)
		if not _world_clear(point): return {"clear":false,"point_px":[point.x,point.y],"index":index,"source_reason":oracle.call("foot_evidence",point)}
	return {"clear":true,"centers":count+1,"max_step_px":a.distance_to(b)/count}

func _route_input_phase() -> void:
	var start_failures: int=failures
	_ensure_runtime_fixture()
	for route: Dictionary in world.map_layout.travel_routes:
		var points: PackedVector2Array = PackedVector2Array()
		for point: Variant in route.get("points",[]): points.append(_point(point)*SIZE)
		if not await _open_owned_world_fixture(points[0] if points.size()>=2 else Vector2(INF,INF)): continue
		var record: Dictionary = await input_driver.call("follow",field,points,_world_clear,_world_segment)
		record["id"] = String(route.get("id",""))
		_check(bool(record.get("ok",false)),"all actual route segments driven with complete17 shoes AND actual physical body: "+String(record.id))
		driven_world_routes.append(record)
		await _capture_world("route_"+String(record.id))
	_check(driven_world_routes.size()==world.map_layout.travel_routes.size() and not driven_world_routes.is_empty(),"every authored route actually driven; graph/BFS existence is not completion")
	_check(_write_json("all_route_actual_input.json",{"scope":"ACTUAL_INPUT_ALL_AUTHORED_WORLD_ROUTES","records":driven_world_routes}),"all actual route input evidence checked readback")
	if failures==start_failures and not driven_world_routes.is_empty(): completed_phases.append("all_authored_world_routes_actual_normal_input")

func _actual_open_seam_input_phase() -> void:
	var start_failures: int=failures
	var expected: int = 0
	for seam: Dictionary in source.get("seams",[]):
		if seam.get("classification")!="open": continue
		for witness: Dictionary in seam.get("projected_witnesses",[]):
			expected += 1
			var a: Vector2 = _point(witness.get("from_px"))
			var b: Vector2 = _point(witness.get("to_px"))
			if not await _open_owned_world_fixture(a): continue
			var record: Dictionary = await input_driver.call("follow",field,PackedVector2Array([a,b]),_world_clear,_world_segment)
			record["id"] = String(seam.get("id",""))
			_check(bool(record.get("ok",false)),"real completed physical crossing of authored OPEN boundary: "+String(record.id))
			actual_open_seam_crossings.append(record)
			await _capture_world("seam_"+String(record.id)+"_"+str(actual_open_seam_crossings.size()))
	_check(expected>0 and actual_open_seam_crossings.size()==expected,"all OPEN seam witnesses actually driven; blocked mountain/sea edges not falsely required open")
	_check(_write_json("open_seams_actual_input.json",{"scope":"ALL_DECLARED_OPEN_SEAM_INPUT_NOT_ALL112_OPEN","expected":expected,"records":actual_open_seam_crossings}),"actual cross-edge input evidence persists")
	if failures==start_failures and expected>0 and actual_open_seam_crossings.size()==expected: completed_phases.append("all_authored_open_seam_witnesses_actual_normal_input")

func _capture_world(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	_check("--qa-gpu-approved" in OS.get_cmdline_user_args(),"GPU test execution explicitly authorized, no asset renderer capture")
	if "--qa-gpu-approved" not in OS.get_cmdline_user_args(): return
	if not is_instance_valid(field) or current_scene!=field: return
	await input_driver.call("completed_actor_stage")
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = output+label.replace("--","_")+".png"
	var fresh: bool = not FileAccess.file_exists(path)
	_check(fresh and image!=null and image.get_width()>0 and image.get_height()>0,"actual completed frame is nonempty and new screenshot path")
	if fresh and image!=null:
		_check(image.save_png(path)==OK,"actual Field screenshot saved "+label)
		if FileAccess.file_exists(path): raw_screenshots.append({"path":path,"sha256":FileAccess.get_sha256(path),"size":[image.get_width(),image.get_height()],"scene_id":String((field.get("_current_scene") as SceneScript).scene_id),"actual_player_px":_point(field.get("_player").position),"visual_verdict":"NOT_REVIEWED"})

func _default_phase() -> String:
	return "full"

func _parse_phase() -> bool:
	_check(FileAccess.get_sha256(V8_ORIGINAL_PARENT_PATH).to_lower()==V8_ORIGINAL_PARENT_SHA,"exact preserved parse-fixed parent; V8 retains all normal input categories")
	_check(requested_phase in PHASES, "known explicit joint world phase; no input subset accepted")
	_check(requested_portal.is_empty() and requested_mode == "all", "joint phase never filters sixteen portals/modes")
	return failures == 0
func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[WorldV15 FAIL] " + label)

func _json(path: String) -> Dictionary:
	_check(FileAccess.file_exists(path), "required current v15 JSON exists: " + path)
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	_check(value is Dictionary, "required JSON parses as object: " + path)
	return value as Dictionary if value is Dictionary else {}

func _point(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size() == 2: return Vector2(float(value[0]), float(value[1]))
	return Vector2(INF, INF)

func _actual_saves() -> Dictionary:
	var result: Dictionary = {}
	for slot in 5:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = "user://save_%d.json%s" % [slot, suffix]
			result[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "ABSENT"
	var directory := DirAccess.open("user://")
	_check(directory != null, "normal player save directory is readable without writes")
	if directory != null:
		for filename: String in directory.get_files():
			if filename.begins_with("save"):
				var path: String = "user://" + filename
				result[path] = FileAccess.get_sha256(path)
	return result

func _run() -> void:
	var phase_valid: bool = _parse_phase()
	output = "res://build/joint_world_luoyang_20261003_qa/world_%s_%d/" % [requested_phase if phase_valid else "invalid_request", Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique v15 QA evidence output")
	before_saves = _actual_saves()
	var router := root.get_node("SceneRouter")
	prior_navigation = router.call("get_navigation_state").duplicate(true)
	prior_active = StringName(router.get("_active_world_map_scene"))
	prior_slot = int(root.get_node("SaveManager").get("active_slot"))
	if not phase_valid:
		await _finish()
		return
	manifest = _json(MANIFEST_PATH)
	source = _json(SOURCE_PATH)
	var pins_reader: RefCounted = V8_CONTEXT.new()
	var pins_ok: bool = pins_reader.call("validate_v8_world_pins",execution_sha256,v8_artifact_sha256,manifest)
	_check(pins_ok,"fixed current v7 execution AND final artifact pins before any Field: "+str(pins_reader.get("errors")))
	pins_reader = null
	_check(("--candidate-before-cutover" in OS.get_cmdline_user_args()) == (scene_id == &"world_map_jianghu_v15"), "explicit candidate/canonical stage agrees with exact selected normal resource")
	_check(source.get("status") == "ART_ASSETS_READY" and source.get("schema_version") == 15 and manifest.get("status") in ["ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA","PRODUCTION_APPROVED"], "full same-revision artifacts ready, not macro/local/partial")
	_check(manifest.get("capture_protocol")=="COHERENT_WHOLE_FIXED_CAMERA_INTEGER_TEXEL_ROI_V1_FULL" and manifest.get("source_contract_path")==SOURCE_PATH,"literal whole-v7 FULL capture protocol/source, no v5 local-frustum substitution")
	_check(source.get("pixel_sampling")=="round_world_pixel" and source.get("physical_navigation_margin_px")==0,"explicit direct logical round sampler/margin; independent oracle must not share legacy W-1 offset")
	_read_independent_door_review()
	_check(ResourceLoader.exists(scene_path), "published v15 production candidate exists")
	# Final owner status/compiler schema will be explicitly bound after SOURCE_READY.
	if failures > 0:
		await _finish()
		return
	world = load(scene_path) as SceneScript
	_check(world != null and world.scene_id == scene_id and world.map_layout != null and world.map_layout.schema_version == 15 and world.map_layout.design_size == Vector2i(SIZE), "actual candidate ID/layout/schema/full logical size")
	if failures > 0:
		await _finish()
		return
	oracle = RAW_ORACLE.new()
	_check(oracle.call("configure", world.map_layout), "independent original tile/margin/full17 oracle is complete: " + str(oracle.get("errors")))
	_static_portals_and_spacing()
	if failures > 0:
		await _finish()
		return
	await _default_spawn_actual_field_check()
	if failures > 0:
		await _finish()
		return
	if requested_phase in ["raw", "full"]:
		_route_fullfoot_checks()
		_neighbor_geometry_checks()
		var artifacts: RefCounted=ARTIFACTS.new()
		artifacts.call("configure_final_pins",v8_artifact_sha256)
		artifact_report=artifacts.call("run",self)
		artifacts=null
		if bool(artifact_report.get("complete",false)): completed_phases.append("all64_raw_repeat_SSAA_models_support_and_nine_ecology_regions")
		if failures > 0:
			await _finish()
			return
		await _route_input_phase()
		await _actual_open_seam_input_phase()
	if requested_phase in ["portal", "full"]:
		await _portal_runtime_phase()
		await _door_negative_phase()
	if requested_phase in ["migration", "full"]:
		_migration_prepare_phase()
		await _migration_isolated_save_phase()
		var contexts: RefCounted=SAVED_CONTEXTS.new()
		saved_context_report=await contexts.call("run",self)
		contexts=null
		if bool(saved_context_report.get("complete",false)): completed_phases.append("actual_free_indoor_native15_and_unknown_version_zero_mutation_saves")
		await _gameplay_return_phase()
	if requested_phase in ["depth", "full"]:
		await _depth_runtime_phase()
		await _normal_npc_patrol_phase()
		var all_objects: RefCounted=ALL_OBJECTS.new()
		all_object_report=await all_objects.call("run",self)
		all_objects=null
		if bool(all_object_report.get("complete",false)): completed_phases.append("all_current_objects_source_binding_physical_stop_bypass_actual_current_alpha")
	var unfinished: Array[String] = []
	if requested_phase in ["raw", "full"] and not bool(artifact_report.get("complete",false)): unfinished.append("all64_raw_repeat_SSAA_models_support_and_nine_ecology_regions")
	if requested_phase in ["depth", "full"] and not bool(all_object_report.get("complete",false)): unfinished.append("all_model_current_frame_alpha_and_ordinary_depth_cleanup")
	if requested_phase in ["migration", "full"] and not bool(saved_context_report.get("complete",false)): unfinished.append("actual_nonportal_and_indoor_historic_saved_contexts")
	# Visual approval is an independent producer decision, never an automatic
	# PASS produced by this suite. The GPU run must still actually capture its
	# normal-input paths/current-alpha cases rather than inherit headless images.
	if requested_phase=="full" and DisplayServer.get_name()!="headless":
		_check("--qa-gpu-approved" in OS.get_cmdline_user_args() and not raw_screenshots.is_empty(),"actual separately authorized GPU input capture exists; visual verdict remains NOT_REVIEWED")
	for phase: String in unfinished:
		incomplete_phases.append(phase)
		_check(false, "required actual v15 phase incomplete/failed: " + phase)
	await _finish()

func _static_portals_and_spacing() -> void:
	var portals: Array = world.map_layout.portals
	_check(portals.size() == 16, "exact sixteen existing target entrances preserved")
	for portal: Dictionary in portals:
		var id: String = portal.get("id", "")
		_check(DESTINATIONS.has(id) and not portals_by_id.has(id), "unique unchanged portal ID: " + id)
		_check(String(portal.get("target_scene", "")) == String(DESTINATIONS.get(id, "INVALID")), "actual unchanged destination: " + id)
		var point := _point(portal.get("pos")) * SIZE
		_check(point.is_finite() and point.x >= 0 and point.y >= 0 and point.x < SIZE.x and point.y < SIZE.y, "finite in-domain portal foot: " + id)
		if oracle.get("valid"): _check(oracle.call("clear", point), "independent complete17 portal landing is clear: %s %s" % [id, oracle.call("foot_evidence", point)])
		portals_by_id[id] = portal
	var landmarks: Dictionary = {}
	for object: Dictionary in world.map_layout.visual_objects:
		var id: String = object.get("portal_id", "")
		if id in CORE_IDS:
			_check(not landmarks.has(id), "unique actual central landmark, not arbitrary portal marker: " + id)
			landmarks[id] = object
	for first in CORE_IDS.size():
		var id: String = CORE_IDS[first]
		_check(landmarks.has(id), "core city/sect owns a real runtime landmark: " + id)
		if not landmarks.has(id): continue
		var a := _point(landmarks[id].get("pos")) * SIZE
		for second in range(first + 1, CORE_IDS.size()):
			var other: String = CORE_IDS[second]
			if not landmarks.has(other): continue
			var b := _point(landmarks[other].get("pos")) * SIZE
			_check(a.distance_to(b) >= 3072, "core actual landmark logical spacing >=3072 (not screen pixels): %s/%s actual=%.6f" % [id, other, a.distance_to(b)])
			var first_door: Vector2=_point((portals_by_id.get(id,{}) as Dictionary).get("pos"))*SIZE
			var second_door: Vector2=_point((portals_by_id.get(other,{}) as Dictionary).get("pos"))*SIZE
			_check(first_door.is_finite() and second_door.is_finite() and first_door.distance_to(second_door)>=3072,"all36 actual core DOOR pairs also satisfy3072 independently of compound center: "+id+"/"+other)
	completed_phases.append("static_16_targets_and_9_core_logical_spacing")

func _route_fullfoot_checks() -> void:
	if not oracle.get("valid"): return
	var routes: Array = world.map_layout.travel_routes
	_check(not routes.is_empty(), "actual production candidate owns continuous route contracts")
	for route: Dictionary in routes:
		var points: Variant = route.get("points")
		_check(points is PackedVector2Array or points is Array, "route actual point array: " + String(route.get("id", "")))
		if not (points is PackedVector2Array or points is Array): continue
		_check(points.size() >= 2, "route has endpoints; no unsampled terminal")
		for index in range(1, points.size()):
			var a := _point(points[index - 1]) * SIZE
			var b := _point(points[index]) * SIZE
			var evidence: Dictionary = oracle.call("segment_evidence", a, b)
			_check(bool(evidence.clear), "actual route entire <=4px/17foot segment: %s #%d %s" % [String(route.get("id", "")), index, evidence])
			if evidence.clear: route_centers += int(evidence.centers)
	completed_phases.append("actual_route_entire_4px_full17")

func _neighbor_geometry_checks() -> void:
	if oracle == null or not bool(oracle.get("valid")): return
	var independent: RefCounted = SAVED_GEOMETRY.new()
	saved_geometry_report = independent.call("run",manifest,source,oracle)
	checks += int(saved_geometry_report.get("checks",0))
	for message: String in saved_geometry_report.get("errors",[]):
		failures += 1
		push_error("[JOINT geometry FAIL] "+message)
	_check(_write_json("actual_saved_geometry_112_references.json",saved_geometry_report),"independent saved global mesh/RF/all112 reference evidence persists")
	independent.call("release")
	independent = null
	if int(saved_geometry_report.get("failures",1)) == 0: completed_phases.append("saved_global_mesh_RF_and112_actual_reference_edges")

func _review_pair(value: Variant) -> bool:
	return value is Array and value.size()==2 and typeof(value[0]) in [TYPE_INT,TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value[0])) and is_finite(float(value[1]))

func _review_hash(value: Variant) -> bool:
	if not value is String or value.length()!=64: return false
	for character: String in value.to_lower():
		if character not in "0123456789abcdef": return false
	return true

func _review_bound(path: String, sha: Variant, catalog: Dictionary) -> bool:
	return path.begins_with("res://") and not ".." in path and _review_hash(sha) and catalog.has(path) and _review_hash(catalog[path]) and String(catalog[path]).to_lower()==String(sha).to_lower() and FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==String(sha).to_lower()

func _review_negative_probes(portal: Dictionary, approval: Dictionary, catalog: Dictionary, footprints: Dictionary, id: String) -> void:
	_check(approval.get("negative_source_footprint_path")==REVIEW_FOOTPRINTS and _review_bound(REVIEW_FOOTPRINTS,approval.get("negative_source_footprint_sha256"),catalog),"negative review binds actual original footprint file/current catalog SHA "+id)
	var landmark: Variant=(footprints.get("landmarks",{}) as Dictionary).get(id) if footprints.get("landmarks") is Dictionary else null
	var original: String=String(portal.get("source",""))
	_check(landmark is Dictionary and landmark.get("source")==original and _review_bound(original,landmark.get("source_sha256"),catalog) and landmark.get("compound_id")==portal.get("compound_id") and landmark.get("source_doorstep_uv")==portal.get("source_doorstep_uv"),"negative footprint independently binds original PNG/compound/source doorway UV "+id)
	var probes: Variant=approval.get("input_negative_probes")
	if portal.has("input_negative_probes"):
		_check(approval.get("negative_origin")=="CAPTURED_SOURCE_INPUT_NEGATIVES_EXACT_V1" and portal.get("input_negative_probes") is Array and probes==portal.get("input_negative_probes"),"existing negative source record must match exact, invalid/null key has no fallback "+id)
	else:
		_check(approval.get("negative_origin")=="INDEPENDENT_ROOT_REVIEW_AUTHORED_NEGATIVES_V1","source-absent negatives only from explicit root-authored independent review "+id)
	_check(probes is Array and probes.size()==3,"exact three reviewed negative records per doorway "+id)
	if not probes is Array or probes.size()!=3: return
	var kinds: Dictionary={}
	for probe: Variant in probes:
		_check(probe is Dictionary,"typed independent reviewed negative record "+id)
		if not probe is Dictionary: continue
		var kind: String=String(probe.get("kind",""))
		_check(kind in ["wall_approach","roof_click","wrongside"] and not kinds.has(kind) and probe.get("semantic_review_status")=="APPROVED","distinct approved original semantic negative mechanism "+id+"/"+kind)
		kinds[kind]=true
		var keys: Array[String]=["legal_start_px","blocked_foot_px"] if kind=="wall_approach" else ["legal_stand_px","world_click_px"]
		for key: String in keys:
			var point: Variant=probe.get(key)
			_check(_review_pair(point) and _point(point).x>=0 and _point(point).y>=0 and _point(point).x<SIZE.x and _point(point).y<SIZE.y,"reviewed negative world coordinate finite/in domain "+id+"/"+kind+"/"+key)
		if kind=="roof_click":
			var uv: Variant=probe.get("source_uv")
			_check(_review_pair(uv) and _point(uv).x>=0 and _point(uv).y>=0 and _point(uv).x<1 and _point(uv).y<1,"reviewed roof source UV strict original pixel domain "+id)
	_check(kinds.size()==3,"wall/roof/wrongside mechanism coverage cannot be dropped "+id)

func _read_independent_door_review() -> void:
	# Independent current-bytes reader: do not call the subject publication gate,
	# change captured PENDING statuses, or call visual approval a Field result.
	var start_failures: int=failures
	var review: Dictionary=_json(REVIEW_PATH)
	_check(typeof(review.get("schema_version")) in [TYPE_INT,TYPE_FLOAT] and review.get("schema_version")==1 and typeof(review.get("version")) in [TYPE_INT,TYPE_FLOAT] and review.get("version")==15 and review.get("capture_protocol")==WHOLE_PROTOCOL and review.get("scope")=="ACTUAL_CURRENT_CAPTURE_VISUAL_REVIEW_NOT_FIELD_INPUT_APPROVAL","independent review exact version/protocol/visual-only scope")
	_check(review.get("reviewer_role")=="producer/root" and review.get("review_method")=="actual_png_individual_review" and review.get("reviewer") is String and not String(review.get("reviewer","")).strip_edges().is_empty() and typeof(review.get("visual_approved"))==TYPE_BOOL and review.get("visual_approved")==true,"explicit named root current capture review, not QA self-signed visual verdict")
	for binding: Array in [[SOURCE_PATH,"source_sha256"],[MANIFEST_PATH,"manifest_sha256"],[WHOLE_REPORT_PATH,"whole_capture_report_sha256"]]:
		var path: String=binding[0]
		var sha: Variant=review.get(binding[1])
		_check(_review_hash(sha) and FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==String(sha).to_lower(),"review binds exact current source/manifest/report bytes "+path)
	_check(review.get("whole_capture_report_path")==WHOLE_REPORT_PATH,"review references literal FULL report, not a pilot")
	var catalog_value: Variant=manifest.get("asset_sha256")
	var doors_value: Variant=review.get("doors")
	var assets_value: Variant=review.get("reviewed_assets_sha256")
	_check(catalog_value is Dictionary and doors_value is Dictionary and doors_value.size()==16 and assets_value is Dictionary,"typed current catalog/exact16 approvals/reviewed PNG index")
	if not catalog_value is Dictionary or not doors_value is Dictionary or doors_value.size()!=16 or not assets_value is Dictionary: return
	var catalog: Dictionary=catalog_value
	var doors: Dictionary=doors_value
	var assets: Dictionary=assets_value
	for key: Variant in doors: _check(key is String and DESTINATIONS.has(key),"no unknown separately reviewed door "+str(key))
	var originals: Dictionary={}
	var portals_value: Variant=source.get("portals")
	_check(portals_value is Array and portals_value.size()==16,"exact sixteen captured original source doors")
	if not portals_value is Array: return
	for portal_value: Variant in portals_value:
		_check(portal_value is Dictionary,"typed captured original doorway")
		if not portal_value is Dictionary: continue
		var id: String=String(portal_value.get("id",""))
		_check(DESTINATIONS.has(id) and not originals.has(id),"unique original door identity "+id)
		originals[id]=portal_value
	var compounds: Dictionary={}
	var footprints: Dictionary=_json(REVIEW_FOOTPRINTS)
	var objects_value: Variant=source.get("objects")
	_check(objects_value is Array,"typed source object array for independent doorway review")
	if not objects_value is Array: return
	for object: Variant in objects_value:
		if object is Dictionary:
			var id: String=String(object.get("id",""))
			_check(not compounds.has(id),"unique current object identity for review "+id)
			compounds[id]=object
	for id: String in DESTINATIONS:
		var portal_value: Variant=originals.get(id)
		var approval_value: Variant=doors.get(id)
		_check(portal_value is Dictionary and approval_value is Dictionary,"independent review/source both contain door "+id)
		if not portal_value is Dictionary or not approval_value is Dictionary: continue
		var portal: Dictionary=portal_value
		var approval: Dictionary=approval_value
		var original: String=String(portal.get("source",""))
		var image: String=String(portal.get("doorstep_review_image_path",""))
		var uv: Variant=portal.get("source_doorstep_uv")
		var foot: Variant=portal.get("door_foot_px")
		var compound: Variant=compounds.get(String(portal.get("compound_id","")))
		_check(approval.get("status")=="APPROVED" and approval.get("source")==original and _review_bound(original,portal.get("source_sha256"),catalog) and _review_bound(original,approval.get("source_sha256"),catalog),"review-approved original source PNG exact current SHA "+id)
		_check(_review_pair(uv) and _review_pair(foot) and _point(uv).x>=0 and _point(uv).x<=1 and _point(uv).y>=0 and _point(uv).y<=1 and _point(foot).x>=0 and _point(foot).y>=0 and _point(foot).x<SIZE.x and _point(foot).y<SIZE.y and approval.get("compound_id")==portal.get("compound_id") and approval.get("source_doorstep_uv")==uv and approval.get("door_foot_px")==foot,"review exact compound/source UV/actual projected foot, never source XZ "+id)
		_check(compound is Dictionary and compound.get("source")==original and compound.get("foot_uv")==uv and compound.get("world_foot_px")==foot,"review door belongs to current actual rendered compound "+id)
		_check(approval.get("doorstep_review_image_path")==image and _review_bound(image,portal.get("doorstep_review_image_sha256"),catalog) and _review_bound(image,approval.get("doorstep_review_image_sha256"),catalog) and _review_bound(image,assets.get(image),catalog),"explicit root reviewed exact actual doorway capture PNG "+id)
		_review_negative_probes(portal,approval,catalog,footprints,id)
	if source.has("player_spawn_px"):
		var explicit: Variant=source.get("player_spawn_px")
		_check(_review_pair(explicit),"invalid existing authored spawn rejected without review fallback")
		if _review_pair(explicit): reviewed_default_spawn=_point(explicit)
	else:
		var declaration: Variant=review.get("default_spawn")
		var linxi: Variant=originals.get("linxi_village")
		var valid: bool=declaration is Dictionary and linxi is Dictionary and typeof(declaration.get("approved"))==TYPE_BOOL and declaration.get("approved")==true and declaration.get("policy")=="EXACT_REVIEWED_LINXI_DOOR_V1" and declaration.get("portal_id")=="linxi_village" and _review_pair(declaration.get("foot_px")) and declaration.get("foot_px")==linxi.get("door_foot_px")
		_check(valid,"default absence-only policy selects root-reviewed actual projected Linxi door")
		if valid: reviewed_default_spawn=_point(declaration.foot_px)
	_check(reviewed_default_spawn.is_finite() and reviewed_default_spawn.x>=0 and reviewed_default_spawn.y>=0 and reviewed_default_spawn.x<SIZE.x and reviewed_default_spawn.y<SIZE.y,"independently selected default spawn in logical world domain")
	visual_review_evidence={"path":REVIEW_PATH,"sha256":FileAccess.get_sha256(REVIEW_PATH) if FileAccess.file_exists(REVIEW_PATH) else "","source_sha256":review.get("source_sha256"),"manifest_sha256":review.get("manifest_sha256"),"whole_capture_report_sha256":review.get("whole_capture_report_sha256"),"doors":doors.duplicate(true),"default_spawn_px":[reviewed_default_spawn.x,reviewed_default_spawn.y] if reviewed_default_spawn.is_finite() else [],"scope":"VISUAL_REVIEW_BINDING_NOT_FIELD_INPUT_APPROVAL","binding_valid":failures==start_failures}
	if failures==start_failures: reviewed_doors=doors.duplicate(true)
	_check(_write_json("independent_visual_review_binding.json",visual_review_evidence),"independent review binding evidence checked write/readback")

func _default_spawn_actual_field_check() -> void:
	var start_failures: int=failures
	_ensure_runtime_fixture()
	# Public null spawn on the first new-game Field exercises actual publication
	# default selection; never inject the independently expected point as spawn.
	var accepted: bool=bool(root.get_node("SceneRouter").call("go_field_smart",scene_id,null,"",15))
	_check(accepted,"public first world entry accepts the published default, not a forced source-XZ fixture")
	if not accepted or not await _wait_field(scene_id) or not await _normal_intro(): return
	var player: Node2D=field.get("_player") as Node2D if is_instance_valid(field) else null
	var container: Node2D=field.get("world_container") as Node2D if is_instance_valid(field) else null
	var live: bool=is_instance_valid(field) and field==current_scene and field.is_inside_tree() and is_instance_valid(player) and player.is_inside_tree() and is_instance_valid(container)
	_check(live,"actual first world Field and normal player remain live after completed actor stages")
	if not live: return
	var actual_foot: Vector2=container.to_local(Vector2(player.global_position.x,float(player.call("get_depth_sort_y"))))
	var full17: bool=bool(oracle.call("clear",actual_foot))
	var physical: bool=_physical_clear(player.position)
	_check(actual_foot.distance_to(reviewed_default_spawn)<.02 and full17 and physical,"first actual default Field foot matches review Linxi foot with complete17 raw shoes and genuine Physics")
	default_spawn_evidence={"scope":"ACTUAL_FIRST_DEFAULT_FIELD_NOT_SOURCE_XZ","review_path":REVIEW_PATH,"review_sha256":FileAccess.get_sha256(REVIEW_PATH),"expected_projected_foot_px":[reviewed_default_spawn.x,reviewed_default_spawn.y],"actual_root_px":[player.position.x,player.position.y],"actual_foot_px":[actual_foot.x,actual_foot.y],"full17":full17,"physics_clear":physical,"raw_foot_evidence":oracle.call("foot_evidence",actual_foot),"passed":failures==start_failures}
	_check(_write_json("actual_first_default_spawn.json",default_spawn_evidence),"actual first default foot/Physics evidence checked persistence")
	if failures==start_failures: completed_phases.append("actual_first_default_spawn_reviewed_projected_Linxi_full17_Physics")

func _source_door(id: String) -> Dictionary:
	var found: Dictionary = {}
	var entries: Variant = source.get("portals")
	_check(entries is Array, "current source has actual portal measurements, not an authoring plan")
	if not entries is Array: return found
	for entry: Dictionary in entries:
		if String(entry.get("id", "")) == id:
			_check(found.is_empty(), "source door ID is unique: " + id)
			found = entry
	var foot := _point(found.get("door_foot_px"))
	var uv := _point(found.get("source_doorstep_uv"))
	var approval: Variant=reviewed_doors.get(id)
	var approved: bool=approval is Dictionary and approval.get("status")=="APPROVED" and approval.get("source")==found.get("source") and approval.get("compound_id")==found.get("compound_id") and approval.get("source_doorstep_uv")==found.get("source_doorstep_uv") and approval.get("door_foot_px")==found.get("door_foot_px")
	_check(approved,"doorstep independently approved for exact immutable captured source/UV/projected foot: "+id)
	_check(not found.is_empty() and foot.is_finite() and uv.is_finite() and uv.x >= 0 and uv.y >= 0 and uv.x <= 1 and uv.y <= 1, "measured actual source doorway UV and projected door foot: " + id)
	return found if approved and foot.is_finite() and uv.is_finite() else {}

func _independent_local_repair(point: Vector2) -> Variant:
	if bool(oracle.call("clear", point * SIZE)): return point
	if not point.is_finite(): return null
	var origin: Vector2 = point.clamp(Vector2.ZERO, Vector2.ONE) * SIZE
	for radius in range(4, 197, 4):
		var count: int = maxi(16, ceili(TAU * radius / 6.0))
		for index in count:
			var candidate: Vector2 = origin + Vector2(cos(TAU * index / count), sin(TAU * index / count)) * radius
			if bool(oracle.call("clear", candidate)): return candidate / SIZE
	return null

func _independent_historic_mapping(old: SceneScript, point: Vector2) -> Dictionary:
	# Read immutable old/current gateways, not the production migration's debug
	# claim. Free coordinates must demonstrably retain local geography whenever
	# its <=196px repair domain has complete feet; gateway fallback is separate.
	var anchors: Array[Dictionary] = []
	var old_size := Vector2(old.map_layout.design_size)
	for previous: Dictionary in old.map_layout.portals:
		var id: String = previous.get("id", "")
		if not portals_by_id.has(id): continue
		var old_pos: Vector2 = previous.get("pos", Vector2(INF, INF))
		var new_pos: Vector2 = portals_by_id[id].get("pos", Vector2(INF, INF))
		var distance: float = ((point - old_pos) * old_size).length()
		if distance <= 64: return {"expected": _independent_local_repair(new_pos), "kind": "paired_gateway", "id": id}
		anchors.append({"distance": distance, "delta": new_pos - old_pos, "new_pos": new_pos, "id": id})
	anchors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.distance) < float(b.distance))
	var delta := Vector2.ZERO
	var total := 0.0
	for index in mini(4, anchors.size()):
		var weight: float = 1.0 / maxf(1.0, float(anchors[index].distance) * float(anchors[index].distance))
		delta += (anchors[index].delta as Vector2) * weight
		total += weight
	if total <= 0: return {"expected": null, "kind": "no_source_pairs"}
	var mapped: Vector2 = point + delta / total
	var repaired: Variant = _independent_local_repair(mapped)
	if repaired is Vector2: return {"expected": repaired, "kind": "independent_local_free_mapping", "mapped": mapped}
	for anchor: Dictionary in anchors:
		if bool(oracle.call("clear", (anchor.new_pos as Vector2) * SIZE)):
			return {"expected": anchor.new_pos, "kind": "historic_gateway_fallback", "mapped": mapped, "id": anchor.id}
	return {"expected": null, "kind": "geography_unrepairable", "mapped": mapped}

func _migration_prepare_phase() -> void:
	if not bool(oracle.get("valid")): return
	var router: Node = root.get_node("SceneRouter")
	var navigation_before: Dictionary = router.call("get_navigation_state").duplicate(true)
	var active_before := StringName(router.get("_active_world_map_scene"))
	var evidence: Array[Dictionary] = []
	var old_paths: Dictionary = {12: "res://data/maps/world_map_jianghu_legacy_v12_scene.tres", 13: "res://data/scenes/world_map_jianghu_v13_staging.tres", 14: "res://data/scenes/world_map_jianghu_v14.tres"}
	for version: int in [12, 13, 14]:
		var path: String = old_paths[version]
		_check(ResourceLoader.exists(path), "historic coordinate source is real immutable resource v%d" % version)
		if not ResourceLoader.exists(path): continue
		var old: SceneScript = load(path) as SceneScript
		_check(old != null and old.map_layout != null, "historic map carries actual portal anchor coordinates")
		if old == null or old.map_layout == null: continue
		for previous: Dictionary in old.map_layout.portals:
			var id: String = previous.get("id", "")
			if not portals_by_id.has(id): continue
			var pos: Vector2 = previous.get("pos", Vector2(INF, INF))
			var paired: Dictionary = _independent_historic_mapping(old, pos)
			var target_scene: String = DESTINATIONS.get(id, "")
			var inner := Vector2(.25, .75)
			var data: Dictionary = {"current_field": String(old.scene_id), "current_field_spawn": [pos.x, pos.y], "world_map_version": version, "portal_return_spawns": {target_scene + "->" + String(old.scene_id): [pos.x, pos.y], String(old.scene_id) + "->" + target_scene: [inner.x, inner.y]}}
			var prepared: Dictionary = router.call("prepare_v15_navigation", data, &"", scene_id)
			_check(prepared.get("world_map_version") == 15 and prepared.get("current_field_id") == scene_id, "real pure router migration selects version15 world: v%d/%s" % [version, id])
			_check(prepared.get("current_field_spawn") == paired.get("expected"), "old paired portal migrates to independently matched exact new door")
			var returns: Dictionary = prepared.get("portal_return_spawns", {})
			_check(returns.get(target_scene + "->" + String(scene_id)) == paired.get("expected"), "world-side remembered portal spawn remaps to same ID")
			_check(returns.get(String(scene_id) + "->" + target_scene) == inner, "indoor remembered coordinate only changes route key, never world scaling")
			_check(router.call("get_navigation_state") == navigation_before and StringName(router.get("_active_world_map_scene")) == active_before, "prepare phase cannot mutate managed navigation")
			evidence.append({"source_version": version, "id": id, "source_path": path, "source_sha256": FileAccess.get_sha256(path), "kind": paired.kind, "prepared_spawn": prepared.get("current_field_spawn")})
		var nonportal_positives := 0
		if not _configure_ordinary(old): continue
		for y in range(1, 8):
			for x in range(1, 8):
				var pos := Vector2(float(x) / 8, float(y) / 8)
				if not _ordinary_static_clear(pos * Vector2(old.map_layout.design_size)): continue
				var expected: Dictionary = _independent_historic_mapping(old, pos)
				if expected.kind != "independent_local_free_mapping": continue
				var station: Vector2 = expected.expected
				var nearest: float = INF
				for current: Dictionary in world.map_layout.portals: nearest = minf(nearest, ((station - (current.pos as Vector2)) * SIZE).length())
				if nearest <= 64: continue
				var result: Variant = MIGRATION_SUBJECT.migrate_spawn(pos, version, world)
				_check(result == station and bool(oracle.call("clear", station * SIZE)), "free old coordinate preserves independent local geography and complete feet, not unconditional portal snap: v%d" % version)
				var again: Variant = MIGRATION_SUBJECT.migrate_spawn(station, 15, world)
				_check(again == station, "version15 free-coordinate migration is exact one-time identity")
				evidence.append({"source_version": version, "kind": expected.kind, "old_point": [pos.x, pos.y], "mapped_point": [station.x, station.y], "nearest_portal_distance_px": nearest})
				nonportal_positives += 1
				if nonportal_positives >= 3: break
			if nonportal_positives >= 3: break
		_check(nonportal_positives >= 3, "each old coordinate space has >=3 genuinely free, safe, non-portal migration witnesses")
	for invalid_version: int in [-1, 0, 16, 99]:
		_check(MIGRATION_SUBJECT.migrate_spawn(Vector2(.5, .5), invalid_version, world) == null, "unknown source version refused, never silently interpreted as legacy12")
	_check(router.call("get_navigation_state") == navigation_before and before_saves == _actual_saves(), "pure migration cases and negative versions leave navigation/player files unchanged")
	_check(_write_json("migration_prepare.json", {"scope": "PURE_MIGRATION_NOT_SAVE_LOAD_OR_BATTLE_RETURN", "records": evidence, "actual_source_sha256": FileAccess.get_sha256("res://scripts/world/world_map_v15_contract.gd")}), "independent migration expectation evidence persisted")
	completed_phases.append("pure_12_13_14_paired_free_identity_unknown_version_migration")

func _write_checked_isolated_slot(slot: int, data: Dictionary) -> bool:
	if not is_instance_valid(isolated_slots): return false
	var path: String = isolated_slots.call("slot_path", slot)
	if isolated_directory.is_empty() or not path.begins_with(isolated_directory + "/") or not path.begins_with("user://world_map_v15_qa/"): return false
	if FileAccess.file_exists(path): return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	file = null
	return error == OK and JSON.parse_string(FileAccess.get_file_as_string(path)) == JSON.parse_string(JSON.stringify(data))

func _migration_isolated_save_phase() -> void:
	if not bool(oracle.get("valid")): return
	_ensure_runtime_fixture()
	isolated_directory = "user://world_map_v15_qa/run_%d" % Time.get_ticks_usec()
	# SaveManager references autoload names: parse its inherited script only
	# after the normal SceneTree has registered those real singletons.
	var isolated_script: Script = load(ISOLATED_SAVES_PATH) as Script
	_check(isolated_script != null and isolated_script.can_instantiate(), "real inherited SaveManager loads after singleton registration")
	if isolated_script == null or not isolated_script.can_instantiate(): return
	isolated_slots = isolated_script.new() as Node
	_check(isolated_slots != null, "isolated real SaveManager instance is available")
	if isolated_slots == null: return
	_check(bool(isolated_slots.call("configure_directory", isolated_directory)), "unique real SaveManager primary/bak/tmp paths remain inside test directory")
	if String(isolated_slots.get("isolated_dir")) != isolated_directory: return
	root.add_child(isolated_slots)
	for slot in 5:
		_check(String(isolated_slots.call("slot_path", slot)).begins_with(isolated_directory + "/") and String(isolated_slots.call("slot_backup_path", slot)).begins_with(isolated_directory + "/"), "all five actual slot+backup paths are isolated")
	_check(bool(isolated_slots.call("save_to_slot", 0)), "real current domain/state serialization writes only isolated template slot")
	var template: Dictionary = _json(String(isolated_slots.call("slot_path", 0)))
	if template.is_empty(): return
	var old_paths: Dictionary = {12: "res://data/maps/world_map_jianghu_legacy_v12_scene.tres", 13: "res://data/scenes/world_map_jianghu_v13_staging.tres", 14: "res://data/scenes/world_map_jianghu_v14.tres"}
	var records: Array[Dictionary] = []
	var router: Node = root.get_node("SceneRouter")
	var isolated_run_root: String = isolated_directory
	var expected_cases := 0
	for version: int in [12, 13, 14]:
		var old: SceneScript = load(old_paths[version]) as SceneScript
		if old == null or old.map_layout == null:
			_check(false, "actual historical save source resource available")
			continue
		for previous: Dictionary in old.map_layout.portals:
			var id: String = previous.get("id", "")
			if not portals_by_id.has(id): continue
			expected_cases += 1
			var point: Vector2 = previous.get("pos", Vector2(INF, INF))
			var expected: Dictionary = _independent_historic_mapping(old, point)
			var data: Dictionary = template.duplicate(true)
			data["current_field"] = String(old.scene_id)
			data["navigation"] = {"current_field": String(old.scene_id), "current_field_spawn": [point.x, point.y], "portal_return_spawns": {}}
			# Test missing-version inference independently for candidate IDs; explicit
			# v12 also covers canonical legacy evidence without reading mutated art.
			if version == 12: data.navigation["world_map_version"] = 12
			# Every case gets a NEW directory. Template slot0 and previous cases are
			# immutable evidence; no reuse/overwrite can silently load old content.
			isolated_directory = isolated_run_root + "/case_v%d_%s" % [version,id]
			var isolated_absolute: String = ProjectSettings.globalize_path(isolated_directory).simplify_path()
			var run_absolute: String = ProjectSettings.globalize_path(isolated_run_root).simplify_path()
			var directory_ok: bool = isolated_absolute.begins_with(run_absolute+"/") and not DirAccess.dir_exists_absolute(isolated_absolute) and bool(isolated_slots.call("configure_directory",isolated_directory)) and String(isolated_slots.get("isolated_dir"))==isolated_directory
			_check(directory_ok, "unique exact test-owned case directory, no normal slot or prior case overwrite")
			if not directory_ok: continue
			var persisted: bool = _write_checked_isolated_slot(0, data)
			_check(persisted, "historic coordinate JSON checked persistence in new isolated case slot")
			if not persisted: continue
			var input_slot_sha: String = FileAccess.get_sha256(String(isolated_slots.call("slot_path",0)))
			var input_evidence_saved: bool = _write_json("isolated_case_v%d_%s_input.json"%[version,id],{"isolated_primary_path":isolated_slots.call("slot_path",0),"sha256":input_slot_sha,"actual_input":data})
			_check(input_evidence_saved,"immutable per-case input content/SHA checked evidence before actual load")
			if not input_evidence_saved: continue
			var preview: Variant = isolated_slots.call("get_save_field_id", 0, scene_id)
			_check(preview == scene_id, "actual save preview resolves v15 candidate without applying domain data")
			var loaded: bool = isolated_slots.call("load_from_slot", 0, scene_id)
			_check(loaded, "real SaveManager historic coordinate load succeeds: v%d/%s" % [version, id])
			_check(FileAccess.get_sha256(String(isolated_slots.call("slot_path",0)))==input_slot_sha,"actual load used exactly this case's persisted input bytes")
			if not loaded: continue
			var navigation: Dictionary = router.call("get_navigation_state")
			_check(navigation.get("world_map_version") == 15 and navigation.get("current_field") == String(scene_id), "actual loaded managed navigation is new world15")
			var actual: Vector2 = _point(navigation.get("current_field_spawn"))
			_check(actual == expected.get("expected") and bool(oracle.call("clear", actual * SIZE)), "loaded historic slot exactly matches independent paired geometry/full17")
			router.call("resume_current_field")
			if not await _wait_field(scene_id) or not await _normal_intro(): continue
			var player: Node2D = field.get("_player") as Node2D
			_check(player.position.distance_to(actual * SIZE) < .02 and bool(oracle.call("clear", player.position)), "real production Field receives migrated slot birth, not preview-only success")
			_check(bool(isolated_slots.call("save_to_slot", 1)), "actual upgraded state persists in second isolated slot")
			var saved: Dictionary = _json(String(isolated_slots.call("slot_path", 1)))
			_check(saved.get("version") == 14 and (saved.get("navigation", {}) as Dictionary).get("world_map_version") == 15, "SaveManager schema stays14 while world coordinate space is15")
			_check(bool(isolated_slots.call("load_from_slot", 1, scene_id)), "upgraded isolated slot reads via same real SaveManager")
			var twice: Dictionary = router.call("get_navigation_state")
			_check(_point(twice.get("current_field_spawn")) == _point((saved.get("navigation", {}) as Dictionary).get("current_field_spawn")), "explicit world15 reread does not migrate coordinates a second time")
			records.append({"old_version": version, "id": id, "old_source_path": old_paths[version], "old_source_sha256": FileAccess.get_sha256(old_paths[version]),"case_directory":isolated_directory,"input_slot_sha256":input_slot_sha, "actual_slot_birth": [actual.x, actual.y], "actual_field_birth_px": [player.position.x, player.position.y], "isolated_slot_sha256": FileAccess.get_sha256(String(isolated_slots.call("slot_path", 1)))})
	_check(records.size() == expected_cases and expected_cases == 48, "all3 historic versions x16 gateway slots actually load/spawn and reread")
	_check(before_saves == _actual_saves() and int(root.get_node("SaveManager").get("active_slot")) == prior_slot, "isolated migration does not alter normal manager slot or player files")
	_check(_write_json("isolated_migration_loads.json", {"scope": "ACTUAL48_SAVE_LOAD_FIELD_SPAWN_NOT_BATTLE_OR_MENU_CONTINUE", "isolated_run_root": isolated_run_root, "records": records}), "actual isolation/load/spawn history checked persistence")
	if records.size() == 48: completed_phases.append("actual48_historic_isolated_save_load_Field_birth_and15_reread")

func _open_owned_world_fixture(point: Vector2) -> bool:
	_check(point.is_finite() and bool(oracle.call("clear", point)), "new runtime category begins at independently safe v15 fixture point")
	if not point.is_finite() or not bool(oracle.call("clear", point)): return false
	_ensure_runtime_fixture()
	root.get_node("SceneRouter").call("go_field_smart", scene_id, point / SIZE, "", 15)
	if not await _wait_field(scene_id) or not await _normal_intro(): return false
	_check(root.get_node("SceneRouter").call("get_current_field_id") == scene_id and current_scene == field, "normal authored intro does not leave a stale fixture Field")
	if root.get_node("SceneRouter").call("get_current_field_id") != scene_id or not is_instance_valid(field) or current_scene != field: return false
	var player: Node2D = field.get("_player") as Node2D
	_check(player != null and player.position.distance_to(point) < .02 and bool(oracle.call("clear", player.position)), "actual explicit version15 fixture origin retains exact complete feet")
	return player != null and player.position.distance_to(point) < .02 and bool(oracle.call("clear", player.position))

func _gameplay_return_phase() -> void:
	if not bool(oracle.get("valid")): return
	if not await _open_owned_world_fixture(world.player_spawn * SIZE): return
	var failures_at_start: int = failures
	var overview: RefCounted = OVERVIEW_PROBE.new()
	overview.call("configure", owner_tree, input_driver, _check, Callable(oracle, "clear"))
	var map_record: Dictionary = await overview.call("run", field, world)
	overview.call("release")
	overview = null
	_check(_write_json("actual_M_overview.json", map_record), "actual M input/current v15 preview/labels/marker evidence persists")
	if failures == failures_at_start and bool(map_record.get("opened", false)) and bool(map_record.get("closed", false)):
		completed_phases.append("actual_M_v15_overview_sixteen_labels_and_current_player_marker")
	var battle: RefCounted = BATTLE_PROBE.new()
	battle.call("configure", owner_tree, input_driver, _check, _wait_field, _normal_intro, Callable(oracle, "clear"))
	var records: Array[Dictionary] = []
	var passed := 0
	for mode: String in ["victory", "defeat", "flee"]:
		if not await _open_owned_world_fixture(world.player_spawn * SIZE): break
		var before: int = failures
		var record: Dictionary = await battle.call("run", field, mode)
		record["passed"] = failures == before and bool(record.get("entered", false)) and bool(record.get("returned", false))
		records.append(record)
		if bool(record.passed): passed += 1
		# An unresolved real battle must not be silently replaced by the next
		# fixture. Keep its failed outcome and stop this finite category.
		if not bool(record.get("returned", false)): break
	battle.call("release")
	battle = null
	_check(passed == 3 and records.size() == 3, "actual Victory, Defeat and ordinary confirmed team Flee all complete version15 exact-foot returns")
	_check(before_saves == _actual_saves(), "real gameplay outcomes do not write normal player slots")
	_check(_write_json("actual_battle_version15_returns.json", {"scope": "ACTUAL_UI_OUTCOMES_NOT_LEGACY_RANDOM_FLEE", "records": records, "passed": passed}), "real outcome/accepted-action/payload/full17 evidence persists")
	if passed == 3: completed_phases.append("actual_victory_defeat_confirmed_team_flee_version15_exact_returns")

func _normal_npc_patrol_phase() -> void:
	if not bool(oracle.get("valid")): return
	if not await _open_owned_world_fixture(world.player_spawn * SIZE): return
	if alpha_oracle == null: alpha_oracle = GEOMETRY_ORACLE.new()
	var failures_at_start: int = failures
	var probe: RefCounted = NORMAL_NPC_PROBE.new()
	probe.call("configure", owner_tree, input_driver, alpha_oracle, _check, Callable(oracle, "clear"), _physical_clear, Callable(oracle, "segment_evidence"))
	var evidence: Dictionary = await probe.call("run", field, world)
	probe.call("release")
	probe = null
	_check(_write_json("normal_patrol_same_band_v15.json", evidence), "normal current-frame patrol/physical-body/tie/late-cleanup evidence persists")
	if failures == failures_at_start and int(evidence.get("front_count", 0)) > 0 and int(evidence.get("behind_count", 0)) > 0:
		completed_phases.append("normal_spawned_NPC_south_gt512_same_band_both_directions_four_frames_tie_cleanup")

func _normal_face_down() -> bool:
	# The observation frame follows ordinary movement, never a direct direction,
	# animation/frame setter or test-forced sorting/ghost refresh.
	var player: Node2D = field.get("_player") as Node2D
	if not is_instance_valid(player): return false
	var end: Vector2 = player.position
	var above: Vector2 = end-Vector2(0,4)
	if not bool((_world_segment(end,above) as Dictionary).get("clear",false)): return false
	var record: Dictionary = await input_driver.call("follow",field,PackedVector2Array([end,above,end]),_world_clear,_world_segment)
	return bool(record.get("ok",false))

func _wait_field(id: StringName) -> bool:
	var deadline: int = Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if bool(root.get_node("LoadingManager").get("_transition_active")): continue
		if not is_instance_valid(current_scene): continue
		var definition: Variant = current_scene.get("_current_scene")
		var player: Variant = current_scene.get("_player")
		if definition is SceneScript and player is Node2D and definition.scene_id == id:
			field = current_scene
			for settle in 6: await physics_frame
			await input_driver.call("completed_actor_stage")
			return true
	_check(false, "normal production Field actually enters exact scene through Loading: " + String(id))
	return false

func _runtime_input_ready() -> bool:
	if not is_instance_valid(field) or current_scene != field: return false
	var player: Node2D = field.get("_player") as Node2D
	return is_instance_valid(player) and bool(player.get("can_move")) and not bool(root.get_node("DialogPlayer").call("is_playing")) and not bool(field.get("_system_panel_open")) and not bool(field.get("_encounter_locked"))

func _door_negative_phase() -> void:
	var preflight_failures: int = failures
	# Source or exact independent root-reviewed semantic witnesses are mandatory.
	# Do not infer a roof/wall solely
	# from a large alpha bbox, and never place the actor on those illegal pixels.
	var cases: Array[Dictionary] = []
	for id: String in DESTINATIONS:
		if not requested_portal.is_empty() and requested_portal != id: continue
		var door: Dictionary = _source_door(id)
		var approval: Dictionary=reviewed_doors.get(id,{}) as Dictionary
		var probes: Variant = approval.get("input_negative_probes")
		_check(probes is Array, "door owns independently reviewed wall/roof/wrongside witnesses: " + id)
		if not probes is Array: continue
		var kinds: Dictionary = {}
		for probe: Dictionary in probes:
			var kind: String = probe.get("kind", "")
			_check(kind in ["wall_approach", "roof_click", "wrongside"] and probe.get("semantic_review_status") == "APPROVED", "negative case source semantics explicitly reviewed: %s/%s" % [id, kind])
			_check(not kinds.has(kind), "one unambiguous negative contract per kind")
			kinds[kind] = true
			cases.append({"id": id, "door": door, "probe": probe})
		_check(kinds.size() == 3, "each selected doorway has all three distinct negative mechanisms")
	_check(cases.size()==48,"all sixteen doorways retain exactly48 reviewed negative input cases")
	if failures != preflight_failures or not runtime_started or input_driver == null: return
	var records: Array[Dictionary] = []
	for entry: Dictionary in cases:
		var id: String = entry.id
		var probe: Dictionary = entry.probe
		var kind: String = probe.kind
		var stand: Vector2 = _point(probe.get("legal_start_px" if kind == "wall_approach" else "legal_stand_px"))
		_check(stand.is_finite() and bool(oracle.call("clear", stand)), "negative actor origin is independently full17 legal: %s/%s" % [id, kind])
		if not stand.is_finite() or not bool(oracle.call("clear", stand)): continue
		root.get_node("SceneRouter").call("go_field_smart", scene_id, stand / SIZE, "", 15)
		if not await _wait_field(scene_id) or not await _normal_intro(): continue
		_check(_runtime_input_ready(), "negative input not suppressed by dialog/disabled actor/modal")
		var published: Dictionary = portals_by_id[id]
		var polygon: PackedVector2Array = published.get("interaction_polygon_px", PackedVector2Array())
		var evidence: Dictionary = {"id": id, "kind": kind, "source_review": probe.semantic_review_status, "negative_origin":(reviewed_doors.get(id,{}) as Dictionary).get("negative_origin"),"review_path":REVIEW_PATH,"review_sha256":FileAccess.get_sha256(REVIEW_PATH), "stand_px": [stand.x, stand.y]}
		var zone: Node2D
		for node: Node2D in field.get("_exit_nodes"):
			if String(node.get("target_scene_id")) == String(DESTINATIONS[id]): zone = node
		_check(zone != null, "negative exercises existing exact target ExitZone")
		if zone == null: continue
		if kind == "wall_approach":
			var blocked: Vector2 = _point(probe.get("blocked_foot_px"))
			var reason: Dictionary = oracle.call("foot_evidence", blocked)
			_check(blocked.is_finite() and not bool(reason.clear) and reason.get("kind") == "source_collision", "reviewed wall is independently a physical solid, not arbitrary black terrain")
			if not blocked.is_finite(): continue
			var drive: Dictionary = await input_driver.call("drive", field, blocked, Callable(oracle, "clear"))
			_check(not bool(drive.get("reached", true)) and bool(drive.get("all_recorded_feet_clear", false)), "actual movement stops at wall with no shoe entering forbidden footprint")
			evidence["blocked_source"] = reason
			evidence["drive"] = drive
			var player: Node2D = field.get("_player") as Node2D
			_check(not Geometry2D.is_point_in_polygon(player.position, polygon), "wall stop remains on wrong side of actual doorway")
			await input_driver.call("key", KEY_SPACE)
		elif kind == "roof_click":
			var uv: Vector2 = _point(probe.get("source_uv"))
			var click: Vector2 = _point(probe.get("world_click_px"))
			var prop: Sprite2D = _actual_landmark_sprite(id)
			_check(prop != null and uv.is_finite() and click.is_finite(), "roof click uses reviewed original source UV and exact runtime landmark")
			if prop == null or not uv.is_finite() or not click.is_finite(): continue
			var texture_image: Image = prop.texture.get_image()
			_check(texture_image != null and not texture_image.is_empty(), "actual roof source texture is readable")
			if texture_image == null or texture_image.is_empty(): continue
			var original: Image = texture_image.duplicate() as Image
			if original.is_compressed(): original.decompress()
			var pixel := Vector2i(clampi(floori(uv.x * original.get_width()), 0, original.get_width() - 1), clampi(floori(uv.y * original.get_height()), 0, original.get_height() - 1))
			_check(uv.x >= 0 and uv.y >= 0 and uv.x < 1 and uv.y < 1 and original.get_pixelv(pixel).a > .12, "roof source witness is an actual visible entity pixel, not transparent bbox")
			var rect: Rect2 = prop.get_rect()
			var container: Node2D = field.get("world_container") as Node2D
			var draw_uv: Vector2 = Vector2(1.0 - uv.x if prop.flip_h else uv.x, 1.0 - uv.y if prop.flip_v else uv.y)
			var projected: Vector2 = container.to_local(prop.to_global(rect.position + draw_uv * rect.size))
			_check(projected.distance_to(click) < .01 and not Geometry2D.is_point_in_polygon(click, polygon), "reviewed roof source maps exactly outside doorway polygon")
			# A failing negative may replace Field during normal pointer input.
			# Retain evidence before input instead of dereferencing a freed Sprite.
			var source_texture_sha: String = FileAccess.get_sha256(prop.texture.resource_path)
			evidence["pointer"] = await input_driver.call("pointer", container.get_global_transform_with_canvas() * click)
			evidence["source_uv"] = [uv.x, uv.y]
			evidence["source_texture_sha256"] = source_texture_sha
		else:
			_check(not Geometry2D.is_point_in_polygon(stand, polygon), "wrongside standing point is legal ground but strictly outside doorway")
			await input_driver.call("key", KEY_SPACE)
			var stayed_space: bool = await _stays_world_after_negative()
			_check(stayed_space, "wrongside actual Space cannot trigger exact destination")
			if not stayed_space: continue
			var click: Vector2 = _point(probe.get("world_click_px"))
			var container: Node2D = field.get("world_container") as Node2D
			_check(click.is_finite() and Geometry2D.is_point_in_polygon(click, polygon), "wrongside mouse targets real door while actor remains outside")
			if not click.is_finite(): continue
			evidence["pointer"] = await input_driver.call("pointer", container.get_global_transform_with_canvas() * click)
			var stayed_door: bool = await _stays_world_after_negative()
			_check(stayed_door, "wrongside actual door click cannot trigger exact destination")
			if not stayed_door: continue
			var marker: Sprite2D = zone.get("marker_visual") as Sprite2D
			_check(marker != null and marker.visible, "wrongside negative also clicks actual arrow")
			if marker == null: continue
			evidence["arrow_pointer"] = await input_driver.call("pointer", marker.get_global_transform_with_canvas().origin)
		var stayed: bool = await _stays_world_after_negative()
		_check(stayed, "wall/roof/wrongside real input cannot enter target across solid geometry: %s/%s" % [id, kind])
		evidence["stayed_world"] = stayed
		records.append(evidence)
	_check(records.size() == cases.size(), "all selected semantic negative inputs actually ran, not skipped")
	_check(_write_json("door_input_negatives.json", {"scope": "ACTUAL_DOOR_NEGATIVES_NOT_VISUAL_APPROVAL", "source_sha256": FileAccess.get_sha256(SOURCE_PATH), "records": records}), "negative input evidence checked persistence")
	if requested_portal.is_empty() and records.size() == 48: completed_phases.append("all16_wall_roof_wrongside_actual_input_negatives")

func _actual_landmark_sprite(portal_id: String) -> Sprite2D:
	var object_id := ""
	for entry: Dictionary in world.map_layout.visual_objects:
		if String(entry.get("portal_id", "")) == portal_id: object_id = String(entry.get("id", ""))
	for prop: Sprite2D in field.get("_scene_object_nodes"):
		if String(prop.name) == "SceneObject_" + object_id and prop.texture != null: return prop
	return null

func _stays_world_after_negative() -> bool:
	var original_field: Node = field
	for settle in 12:
		await process_frame
		await physics_frame
		if bool(root.get_node("LoadingManager").get("_transition_active")) or current_scene != original_field: return false
	return is_instance_valid(original_field) and root.get_node("SceneRouter").call("get_current_field_id") == scene_id

func _normal_intro() -> bool:
	var dialog: Node = root.get_node("DialogPlayer")
	for step in 80:
		if not bool(dialog.call("is_playing")): return true
		var node: Resource = dialog.get("_current_node") as Resource
		if node != null and not (node.get("choices") as Array).is_empty(): dialog.call("choose", 0)
		else: dialog.call("advance")
		for settle in 4: await process_frame
	_check(false, "authored introduction finishes without stripping gameplay/dialog resources")
	return false

func _portal_runtime_phase() -> void:
	var preflight_failures: int = failures
	if not bool(oracle.get("valid")): return
	# Preflight ALL selected measurements before any Field load. A pending/null
	# doorstep can never be silently replaced by a sprite bbox or old stone.
	var selected: Array[String] = []
	for id: String in DESTINATIONS:
		if requested_portal.is_empty() or requested_portal == id: selected.append(id)
	var doors: Dictionary = {}
	for id: String in selected:
		var measured: Dictionary = _source_door(id)
		if measured.is_empty(): continue
		var published: Dictionary = portals_by_id.get(id, {})
		var polygon: Variant = published.get("interaction_polygon_px")
		_check(polygon is PackedVector2Array and polygon.size() >= 3, "published doorway uses an independent reviewed pixel polygon: " + id)
		var foot := _point(measured.door_foot_px)
		_check(_point(published.get("pos")) * SIZE == foot, "runtime door is exactly measured projected doorstep, not source XZ: " + id)
		_check(polygon is PackedVector2Array and Geometry2D.is_point_in_polygon(foot, polygon), "actual measured foot lies inside its doorway polygon: " + id)
		_check(bool(oracle.call("clear", foot)), "measured doorway has independent full17 clearance: " + id)
		doors[id] = measured
	if failures != preflight_failures or doors.size() != selected.size(): return
	_ensure_runtime_fixture()
	var modes: Array[String] = ["space", "door_mouse", "arrow"] if requested_mode == "all" else [requested_mode]
	for id: String in selected:
		for mode: String in modes:
			await _portal_roundtrip(id, mode, doors[id])
	var passed := 0
	for record: Dictionary in actual_portal_roundtrips:
		if bool(record.get("passed", false)): passed += 1
	_check(passed == selected.size() * modes.size(), "every requested real mode completes destination AND actual paired return")
	_check(_write_json("portal_roundtrips.json", {"scope": "LIMITED_REAL_PORTAL_INPUT_NOT_FULL_WORLD" if requested_phase != "full" else "FULL_PORTAL_CATEGORY", "door_modes": modes, "selected_ids": selected, "records": actual_portal_roundtrips, "source_sha256": FileAccess.get_sha256(SOURCE_PATH)}), "actual roundtrip input evidence persists with source SHA")
	if passed == 48 and requested_portal.is_empty() and requested_mode == "all": completed_phases.append("all16_space_door_mouse_arrow_actual_returns")

func _ensure_runtime_fixture() -> void:
	if runtime_started: return
	input_driver = INPUT_DRIVER.new()
	input_driver.call("configure", owner_tree)
	# Same public new-game setup as the menu. It is process-local fixture data;
	# no ordinary slot is loaded/written and all authored scene behavior remains.
	for singleton: String in ["GameState", "Inventory", "QuestManager", "BountyManager", "InvestigationState", "WeatherManager", "SceneRouter"]:
		root.get_node(singleton).call("reset_for_new_game")
	prior_navigation = root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
	prior_active = StringName(root.get_node("SceneRouter").get("_active_world_map_scene"))
	_check(before_saves == _actual_saves() and int(root.get_node("SaveManager").get("active_slot")) == prior_slot, "public runtime fixture startup does not touch normal slots/files")
	runtime_started = true
	var gm: Node = root.get_node_or_null("GMConsole")
	if gm != null:
		if gm is CanvasLayer: gm.visible = false
		gm.set_process(false)
		gm.set_process_unhandled_input(false)

func _depth_runtime_phase() -> void:
	if not bool(oracle.get("valid")): return
	_ensure_runtime_fixture()
	alpha_oracle = GEOMETRY_ORACLE.new()
	var records: Array[Dictionary] = []
	var southern_mechanism_pairs := 0
	for entry: Dictionary in world.map_layout.visual_objects:
		if not bool(entry.get("sort_by_feet", false)) or not entry.has("depth_sort_foot_y"): continue
		var foot_y: float = float(entry.depth_sort_foot_y) * SIZE.y
		if foot_y <= 4300: continue
		var anchor: Vector2 = _point(entry.get("pos")) * SIZE
		var origin := Vector2(INF, INF)
		for radius in [64, 128, 192, 256]:
			for index in 16:
				var point: Vector2 = anchor + Vector2(cos(TAU * index / 16), sin(TAU * index / 16)) * radius
				if bool(oracle.call("clear", point)):
					origin = point
					break
			if origin.is_finite(): break
		if not origin.is_finite(): continue
		root.get_node("SceneRouter").call("go_field_smart", scene_id, origin / SIZE, "", 15)
		if not await _wait_field(scene_id) or not await _normal_intro(): continue
		var prop: Sprite2D
		for sprite: Sprite2D in field.get("_scene_object_nodes"):
			if String(sprite.name) == "SceneObject_" + String(entry.get("id", "")): prop = sprite
		if prop == null: continue
		var player: Node2D = field.get("_player") as Node2D
		var actor: Sprite2D = player.get("sprite") as Sprite2D
		var container: Node2D = field.get("world_container") as Node2D
		_check(int(player.get_meta("depth_band_max", -1)) == 1024 and int(field.call("_scene_depth_band_max")) == 1024, "v15 actual normally spawned actor/Field select8192 depth domain")
		_check(absf(container.global_rotation) < .000001 and container.global_scale == Vector2.ONE, "logical foot-depth projection uses actual unscaled/unrotated world container")
		var global_foot: float = container.to_global(Vector2(0, foot_y)).y
		var expected_band: int = clampi(floori(global_foot / 8), 0, 1024)
		_check(prop.z_index == expected_band and prop.z_index > 512, "actual southern object matches independent global-foot band >512, not saturatedv14")
		var bounds: Rect2 = alpha_oracle.call("bounds_in", prop, container)
		if not await _normal_face_down(): continue
		await input_driver.call("completed_actor_stage")
		var actor_offset: float = float(player.call("get_depth_sort_y")) - player.global_position.y
		var stations: Dictionary = {}
		for relation: String in ["behind", "front"]:
			for delta: float in [1.0, 2.0, 3.0]:
				var desired: float = global_foot + (-delta if relation == "behind" else delta)
				if floori(desired / 8) != expected_band: continue
				var y: float = desired - actor_offset - container.global_position.y
				for x in range(floori(bounds.position.x - 100), ceili(bounds.end.x + 100) + 1, 16):
					var point := Vector2(x, y)
					if not _world_clear(point) or not bool((_world_segment(point,point-Vector2(0,4)) as Dictionary).get("clear",false)): continue
					var shift: Vector2 = container.to_global(point) - player.global_position
					var overlap: Dictionary = alpha_oracle.call("strong_intersection", actor, prop, shift)
					if bool(overlap.get("valid", false)) and int(overlap.hits) >= 100:
						stations[relation] = point
						break
				if stations.has(relation): break
		# Missing coarse stations are NOT a negative proof or waiver. Other props
		# may supply the limited mechanism witness; FULL all-prop proof is separate.
		if stations.size() != 2: continue
		var all_ok := true
		for relation: String in ["behind", "front"]:
			var target: Vector2 = stations[relation]
			var path: PackedVector2Array = input_driver.call("plan", player.position, target, SIZE, _world_clear, _world_segment)
			_check(path.size() >= 2, "independent full17 edge path exists to same-band strong alpha station")
			if path.size() < 2:
				all_ok = false
				continue
			var drive: Dictionary = await input_driver.call("follow", field, path, _world_clear, _world_segment)
			_check(bool(drive.get("ok", false)), "actual input reaches same-band depth station without crossing fullXZ")
			var faced: bool = await _normal_face_down()
			_check(faced,"current DOWN observation comes from complete-foot normal input, not a frame/direction setter")
			await input_driver.call("completed_actor_stage")
			var overlap: Dictionary = alpha_oracle.call("strong_intersection", actor, prop)
			var actor_foot: float = float(player.call("get_depth_sort_y"))
			var actor_band: int = clampi(floori(actor_foot / 8), 0, 1024)
			var correct_relation: bool = actor_foot < global_foot if relation == "behind" else actor_foot > global_foot
			var is_front: bool = alpha_oracle.call("actual_in_front", player, prop)
			var debug: Dictionary = field.call("get_v14_modular_overlap_debug")
			var ghost_hits: int = int((debug.get("prop_hits", {}) as Dictionary).get(String(entry.id), 0))
			var valid: bool = faced and bool(drive.get("ok", false)) and bool(oracle.call("clear", player.position)) and _physical_clear(player.position) and correct_relation and player.z_index == actor_band and actor_band == expected_band and actor_band > 512 and int(overlap.get("hits", 0)) >= 100 and is_front == (relation == "front")
			_check(valid, "normal completed idle stage real foot/strong-current-alpha/effective order agrees within same band >512")
			_check(ghost_hits > 0 if relation == "behind" else ghost_hits == 0, "real ghost union includes behind prop only, front actor never ghosts through it")
			all_ok = all_ok and valid
			records.append({"id": entry.id, "relation": relation, "actual_player_px": [player.position.x, player.position.y], "actual_actor_global_foot": actor_foot, "actual_prop_global_foot": global_foot, "actor_band": actor_band, "prop_band": prop.z_index, "actor_sibling": player.get_index(), "prop_sibling": prop.get_index(), "overlap": overlap, "ghost_prop_hits": ghost_hits, "drive": drive})
			await _capture_world("depth_"+String(entry.id)+"_"+relation)
		if all_ok: southern_mechanism_pairs += 1
		if southern_mechanism_pairs >= 3: break
	_check(southern_mechanism_pairs >= 3, ">=3 actual strong southern prop pairs prove expanded and same-band depth mechanism")
	_check(_write_json("expanded_same_band_depth.json", {"scope": "LIMITED_SOUTHERN_CURRENT_FRAME_MECHANISM_NOT_ALL_PROPS_OR_PATROL", "pairs_passed": southern_mechanism_pairs, "records": records}), "actual depth/source/current-frame evidence persisted")
	if southern_mechanism_pairs >= 3: completed_phases.append("three_southern_strong_current_frame_same_band_gt512_pairs")

func _portal_roundtrip(id: String, mode: String, measurement: Dictionary) -> void:
	var failures_at_start: int = failures
	var router: Node = root.get_node("SceneRouter")
	var door: Vector2 = _point(measurement.door_foot_px)
	# Fixture placement is only the first local approach point. The door itself
	# must then be reached by real movement along independently checked edges.
	var approach: PackedVector2Array = PackedVector2Array()
	for route: Dictionary in world.map_layout.travel_routes:
		if String(route.get("id", "")) == "portal_" + id:
			var values: Variant = route.get("points")
			if values is PackedVector2Array or values is Array:
				for value: Variant in values: approach.append(_point(value) * SIZE)
	_check(approach.size() >= 2 and approach[approach.size() - 1].distance_to(door) < .01, "actual approach route terminates at measured doorstep: " + id)
	if approach.size() < 2: return
	if not bool(oracle.call("clear", approach[0])):
		_check(false, "approach fixture first point is not full17 safe: " + id)
		return
	router.call("go_field_smart", scene_id, approach[0] / SIZE, "", 15)
	if not await _wait_field(scene_id): return
	if not await _normal_intro(): return
	_check(field.get("_world_size") == SIZE, "actual production Field uses expanded world canvas")
	var player: Node2D = field.get("_player") as Node2D
	_check(player.position.distance_to(approach[0]) < .02, "explicit version15 fixture origin is preserved exactly")
	var driven: Dictionary = await input_driver.call("follow", field, approach, _world_clear, _world_segment)
	_check(bool(driven.get("ok", false)), "real movement reaches doorstep with every physics foot legal: %s/%s %s" % [id, mode, driven])
	if not bool(driven.get("ok", false)): return
	await _capture_world("portal_"+id+"_"+mode+"_approach")
	var zone: Node2D
	for entry: Node2D in field.get("_exit_nodes"):
		if String(entry.get("target_scene_id")) == String(DESTINATIONS[id]): zone = entry
	_check(zone != null and bool(zone.get("_in_range")), "actual physics overlap reaches doorway, not radius across wall: " + id)
	if zone == null: return
	var input_evidence: Dictionary = {"mode": mode}
	if mode == "space": await input_driver.call("key", KEY_SPACE)
	elif mode == "door_mouse":
		var container: Node2D = field.get("world_container") as Node2D
		_check(container != null, "actual production world canvas transform exists")
		if container == null: return
		input_evidence.merge(await input_driver.call("pointer", container.get_global_transform_with_canvas() * door), true)
	else:
		var marker: Sprite2D = zone.get("marker_visual") as Sprite2D
		_check(marker != null and marker.texture != null and marker.visible, "actual drawn arrow exists and is visible: " + id)
		if marker == null: return
		input_evidence.merge(await input_driver.call("pointer", marker.get_global_transform_with_canvas().origin), true)
	var destination: StringName = StringName(DESTINATIONS[id])
	if not await _wait_field(destination): return
	await _capture_world("portal_"+id+"_"+mode+"_target")
	var definition: SceneScript = field.get("_current_scene") as SceneScript
	var target_ok: bool = definition.resource_path == "res://data/scenes/%s.tres" % destination
	if String(destination) in CITY_IDS:
		target_ok=_configure_ordinary(definition)
	_check(target_ok,"normal unchanged target identity; only current SHA-bound exact candidate city clone allowed: "+id)
	if not target_ok: return
	player = field.get("_player") as Node2D
	_check(int(player.get_meta("depth_band_max", -1)) == 255, "ordinary target restores player depth255 after v15: " + id)
	for npc: Node in field.get("_npc_nodes"):
		if is_instance_valid(npc): _check(int(npc.get_meta("depth_band_max", -1)) == 255, "normally spawned target NPC restores depth255: " + id)
	if not _configure_ordinary(definition): return
	_check(_ordinary_clear(player.position), "actual target arrival full17/raw source/physics legal: " + id)
	if not await _normal_intro(): return
	if not await _actual_return(destination): return
	player = field.get("_player") as Node2D
	_check(player.position.distance_to(door) < .02 and bool(oracle.call("clear", player.position)), "actual paired exit restores exact door with complete feet: " + id)
	var navigation: Dictionary = router.call("get_navigation_state")
	_check(int(navigation.get("world_map_version", -1)) == 15, "paired target roundtrip retains world coordinate version15")
	actual_portal_roundtrips.append({"id": id, "mode": mode, "passed": failures == failures_at_start, "target_scene": String(destination), "target_resource": definition.resource_path, "door_foot_px": [door.x, door.y], "source_doorstep_uv": measurement.source_doorstep_uv, "approach": driven, "input": input_evidence, "actual_return_px": [player.position.x, player.position.y], "world_map_version": navigation.get("world_map_version")})
	await _capture_world("portal_"+id+"_"+mode+"_returned")

func _configure_ordinary(definition: SceneScript) -> bool:
	ordinary_images.clear()
	ordinary_blockers.clear()
	if ordinary_raw != null:
		_check(bool(ordinary_raw.call("verify_sources")),"actual target raw PNG bytes frozen through normal input/return")
		ordinary_raw.call("release")
	ordinary_raw = null
	var layout: Resource = definition.map_layout
	_check(layout != null,"actual target source layout is present")
	if layout == null: return false
	ordinary_size = Vector2(layout.get("design_size"))
	ordinary_native_city = String(definition.scene_id) in CITY_IDS and layout.get("schema_version")==3
	ordinary_raw = ORDINARY_RAW.new()
	var sampling: String = "round_world_pixel" if ordinary_native_city else "normalized_image_round"
	var configured: bool = ordinary_raw.call("configure_city",definition,"--luoyang-v3-candidate" in OS.get_cmdline_user_args()) if ordinary_native_city else ordinary_raw.call("configure",layout,sampling,-1.0)
	_check(configured,"independent actual target original PNG or explicitly legacy polygon navigation: "+str(ordinary_raw.get("errors")))
	if ordinary_native_city:
		_check(ordinary_size == Vector2(3072,2048),"new city ordinary full-body context, not world-circle inheritance")
	return configured

func _ordinary_static_clear(center: Vector2) -> bool:
	if ordinary_raw == null or not bool(ordinary_raw.get("valid")) or not center.is_finite(): return false
	var ground: Vector2 = center
	if is_instance_valid(field) and field.get("_world_size") == ordinary_size:
		var player: Node2D = field.get("_player") as Node2D
		var container: Node2D = field.get("world_container") as Node2D
		if is_instance_valid(player) and container != null:
			ground += container.to_local(Vector2(player.global_position.x,float(player.call("get_depth_sort_y"))))-player.position
	if not bool(ordinary_raw.call("clear",ground)): return false
	if not ordinary_native_city: return true
	var body: Rect2 = Rect2(center-Vector2(17,12),Vector2(34,24))
	if body.position.x<0 or body.position.y<0 or body.end.x>=ordinary_size.x or body.end.y>=ordinary_size.y: return false
	if roundi(body.end.x)>=ordinary_size.x or roundi(body.end.y)>=ordinary_size.y: return false
	for y in range(roundi(body.position.y),roundi(body.end.y)+1):
		for x in range(roundi(body.position.x),roundi(body.end.x)+1):
			var pixel: Dictionary = ordinary_raw.call("pixel_evidence",Vector2(x,y))
			if not bool(pixel.get("clear",false)): return false
	var polygon: PackedVector2Array = PackedVector2Array([body.position,Vector2(body.end.x,body.position.y),body.end,Vector2(body.position.x,body.end.y)])
	for solid: Dictionary in ordinary_raw.get("solids"):
		if solid.kind=="exact_world_polygon":
			if not Geometry2D.intersect_polygons(polygon,solid.polygon).is_empty(): return false
		elif body.intersects(solid.rect): return false
	return true

func _ordinary_clear(center: Vector2) -> bool:
	return _ordinary_static_clear(center) and _physical_clear(center)

func _physical_clear(center: Vector2) -> bool:
	if not is_instance_valid(field): return false
	var player: Node2D = field.get("_player") as Node2D
	var shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var container: Node2D = field.get("world_container") as Node2D
	if shape == null or shape.shape == null or container == null: return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	query.transform = shape.global_transform
	query.transform.origin += container.to_global(center) - player.global_position
	query.collision_mask = int(player.get("collision_mask"))
	query.exclude = [player.call("get_rid")]
	query.collide_with_areas = false
	return player.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _ordinary_segment(a: Vector2, b: Vector2) -> Dictionary:
	var count: int = maxi(1, ceili(a.distance_to(b) / 4))
	for index in range(count + 1):
		var point: Vector2 = a.lerp(b, float(index) / count)
		if not _ordinary_clear(point): return {"clear": false, "index": index, "point": [point.x, point.y]}
	return {"clear": true, "centers": count + 1, "max_step_px": a.distance_to(b) / count}

func _area_contains_actual_foot_and_body(area: Area2D, center: Vector2) -> bool:
	var player: Node2D = field.get("_player") as Node2D
	var container: Node2D = field.get("world_container") as Node2D
	if area==null or not is_instance_valid(player) or container==null: return false
	var actor_shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if actor_shape==null or actor_shape.shape==null: return false
	var ground_offset: Vector2 = container.to_local(Vector2(player.global_position.x,float(player.call("get_depth_sort_y"))))-player.position
	var foot_global: Vector2 = container.to_global(center+ground_offset)
	var contains: bool = false
	for child: Node in area.get_children():
		if child is CollisionPolygon2D and not child.disabled and child.polygon.size()>=3:
			contains=contains or Geometry2D.is_point_in_polygon(child.to_local(foot_global),child.polygon)
		elif child is CollisionShape2D and not child.disabled and child.shape!=null:
			var point: Vector2 = child.to_local(foot_global)
			if child.shape is RectangleShape2D: contains=contains or Rect2(-child.shape.size*.5,child.shape.size).has_point(point)
			elif child.shape is CircleShape2D: contains=contains or point.length_squared()<=child.shape.radius*child.shape.radius
	if not contains: return false
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape=actor_shape.shape
	query.transform=actor_shape.global_transform
	query.transform.origin+=container.to_global(center)-player.global_position
	query.collision_mask=area.collision_layer
	query.collide_with_areas=true
	query.collide_with_bodies=false
	query.exclude=[player.call("get_rid")]
	for hit: Dictionary in player.get_world_2d().direct_space_state.intersect_shape(query,128):
		if hit.get("rid")==area.get_rid(): return true
	return false

func _actual_return(destination: StringName) -> bool:
	var reverse: Node2D
	for zone: Node2D in field.get("_exit_nodes"):
		if String(zone.get("target_scene_id")) in [String(scene_id), "world_map_jianghu"] or String(zone.get("action")) == "world_map":
			reverse = zone
			break
	_check(reverse != null, "actual target has public reverse exit: " + String(destination))
	if reverse == null: return false
	var player: Node2D = field.get("_player") as Node2D
	var path := PackedVector2Array()
	for radius in [0, 16, 32, 48, 64]:
		for direction in 16:
			var point: Vector2 = reverse.position + Vector2(cos(TAU * direction / 16), sin(TAU * direction / 16)) * radius
			if not _ordinary_clear(point): continue
			if not _area_contains_actual_foot_and_body(reverse as Area2D,point): continue
			path = input_driver.call("plan", player.position, point, ordinary_size, _ordinary_clear, _ordinary_segment)
			if path.size() >= 2: break
		if path.size() >= 2: break
	_check(path.size() >= 2, "independent all-edge full17 path exists to actual reverse trigger: " + String(destination))
	if path.size() < 2: return false
	var driven: Dictionary = await input_driver.call("follow", field, path, _ordinary_clear, _ordinary_segment)
	_check(bool(driven.get("ok", false)), "real ordinary target input completes planned reverse path: %s %s" % [destination, driven])
	var reverse_live: bool = is_instance_valid(field) and field.is_inside_tree() and owner_tree.current_scene == field and is_instance_valid(reverse) and reverse.is_inside_tree() and not reverse.is_queued_for_deletion()
	_check(reverse_live, "original target Field and reverse exit stay live during actual return approach")
	if not reverse_live: return false
	_check(bool(reverse.get("_in_range")), "normal physics reaches reverse exit; no direct router return")
	if not bool(driven.get("ok", false)) or not bool(reverse.get("_in_range")): return false
	var marker: Sprite2D = reverse.get("marker_visual") as Sprite2D
	_check(marker != null, "actual target reverse arrow exists")
	if marker == null: return false
	await input_driver.call("pointer", marker.get_global_transform_with_canvas().origin)
	return await _wait_field(scene_id)

func _write_json(name: String, value: Dictionary) -> bool:
	var path: String = output + name
	if FileAccess.file_exists(path): return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(value, "\t"))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	file = null
	return error == OK and JSON.parse_string(FileAccess.get_file_as_string(path)) == JSON.parse_string(JSON.stringify(value))

func _finish() -> void:
	# Only this process's fixture ownership. Runtime baseline was established by
	# the public new-game operation before candidate travel, not a hidden slot.
	if input_driver != null: input_driver.call("release")
	input_driver = null
	if alpha_oracle != null: alpha_oracle.call("release")
	alpha_oracle = null
	if is_instance_valid(isolated_slots):
		var slots_reference: WeakRef = weakref(isolated_slots)
		if isolated_slots.get_parent() != null: isolated_slots.get_parent().remove_child(isolated_slots)
		isolated_slots.queue_free()
		isolated_slots = null
		for settle in 4: await process_frame
		_check(slots_reference.get_ref() == null, "owned isolated SaveManager actually released")
	ordinary_images.clear()
	ordinary_blockers.clear()
	if runtime_started:
		if is_instance_valid(current_scene):
			var owned_scene: Node = current_scene
			var reference: WeakRef = weakref(owned_scene)
			current_scene = null
			owned_scene.queue_free()
			owned_scene = null
			field = null
			for settle in 8: await process_frame
			_check(reference.get_ref() == null, "owned production Field actually freed after natural stages")
		var router: Node = root.get_node("SceneRouter")
		router.call("restore_navigation_state", prior_navigation)
		router.set("_active_world_map_scene", prior_active)
		var audio: Node = root.get_node_or_null("AudioManager")
		if audio != null:
			audio.call("stop_bgm", 0.0)
			audio.call("stop_music_sting")
			audio.call("stop_ambience", 0.0)
			audio.call("stop_all_sfx")
			audio.call("stop_dialog_audio")
		await create_timer(.20).timeout
		for settle in 8: await process_frame
	if oracle != null:
		_check(bool(oracle.call("verify_sources")),"all64 current raw navigation PNG SHA unchanged after actual phase")
		oracle.call("release")
	if ordinary_raw != null:
		_check(bool(ordinary_raw.call("verify_sources")),"actual current target nav remains frozen through final input")
		ordinary_raw.call("release")
	ordinary_raw = null
	oracle = null
	world = null
	_check(before_saves == _actual_saves(), "normal player files unchanged before and after requested phase")
	_check(int(root.get_node("SaveManager").get("active_slot")) == prior_slot, "normal active save slot unchanged")
	_check(root.get_node("SceneRouter").call("get_navigation_state") == prior_navigation, "test cleanup preserves managed fixture baseline without slot I/O or version drift")
	_check(StringName(root.get_node("SceneRouter").get("_active_world_map_scene")) == prior_active, "source-only suite does not change active world")
	var actual_portal_ids: Dictionary={}
	for trip: Dictionary in actual_portal_roundtrips:
		var portal_id: String=String(trip.get("id",trip.get("portal_id","")))
		if not portal_id.is_empty(): actual_portal_ids[portal_id]=true
	var complete: bool=requested_phase=="full" and failures==0 and incomplete_phases.is_empty() and runtime_started and bool(artifact_report.get("complete",false)) and bool(all_object_report.get("complete",false)) and bool(saved_context_report.get("complete",false)) and actual_portal_roundtrips.size()==48 and actual_portal_ids.size()==16 and saved_geometry_report.get("edges",[]).size()==112
	var report: Dictionary = {"schema": 1, "scope": "JOINT_WORLD_ACTUAL_FIELD_PHASE_NOT_JOINT_FULL", "requested_phase": requested_phase, "source_complete": complete, "checks": checks+1, "failures": failures, "completed_phases": completed_phases, "incomplete_phases": incomplete_phases, "route_4px_full17_centers": route_centers, "field_input_executed": runtime_started, "portal_ids":actual_portal_ids.keys(),"core_ids":CORE_IDS,"chunk_count":(artifact_report.get("records",{}) as Dictionary).get("chunks",[]).size(),"seam_count":saved_geometry_report.get("edges",[]).size(),"portal_roundtrips": actual_portal_roundtrips, "GPU_executed": not raw_screenshots.is_empty(), "player_saves_unchanged": before_saves == _actual_saves(), "executing_script_path": get_script().resource_path, "executing_script_sha256": FileAccess.get_sha256(get_script().resource_path),"output":output,"saved_geometry_112":saved_geometry_report.duplicate(true),"artifact_semantics":artifact_report.duplicate(true),"all_current_objects":all_object_report.duplicate(true),"actual_saved_contexts":saved_context_report.duplicate(true),"actual_route_input":driven_world_routes.duplicate(true),"actual_open_seam_input":actual_open_seam_crossings.duplicate(true),"raw_screenshots":raw_screenshots.duplicate(true),"visual_verdict":"NOT_REVIEWED"}
	report["execution_sha256"]=execution_sha256.duplicate(true)
	report["v8_artifact_sha256"]=v8_artifact_sha256.duplicate(true)
	report["independent_visual_review_binding"]=visual_review_evidence.duplicate(true)
	report["actual_first_default_spawn"]=default_spawn_evidence.duplicate(true)
	_check(_write_json("result.json", report), "actual world phase result checked write/readback")
	print("[WorldV15] ACTUAL_PHASE checks=%d failures=%d complete=%s output=%s" % [checks, failures,complete,output])
	result = report.duplicate(true)
	result["checks"] = checks
	result["failures"] = failures
	result["source_complete"]=complete and failures==0
	owner_tree = null

