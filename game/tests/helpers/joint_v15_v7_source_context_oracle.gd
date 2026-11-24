extends RefCounted
## Independent READ-ONLY joint preflight. Does not call production clearance,
## validators, publishers, materializers, migration, rewards or scene routing.
const WORLD_ROOT: String = "res://art/maps/world_map_v15_complete_v7/"
const WORLD_SOURCE: String = "res://data/maps/world_map_v15_complete_v7_source.json"
const WORLD_PROTOCOL: String = "COHERENT_WHOLE_FIXED_CAMERA_INTEGER_TEXEL_ROI_V1_FULL"
const WORLD_REVIEW: String = "res://data/maps/world_map_v15_complete_v7_visual_review.json"
const WORLD_FOOTPRINTS: String = "res://data/maps/world_map_v15_complete_v5_landmark_footprints_candidate.json"
const CITY_ROOT: String = "res://art/maps/luoyang_modular_v3_street_detail_proposal/root_material_v1/"
const OUTSKIRTS_ROOT: String = "res://art/maps/world_map_v15_outskirts_complete_v5_retry1/"
const CORE_IDS: Array[String] = ["huashan", "luoyang", "bianzhou", "gufeng", "wudang", "xiangzhou", "jinling", "lingyue", "mingwu"]
const WORLD_PORTALS: Array[String] = ["yanmen_pass", "huashan", "luoyang", "bianzhou", "gufeng", "linxi_village", "qinghe_town", "zhuwei_village", "wudang", "xiangzhou", "jinling", "bailu_ferry", "east_sea_port", "mingwu", "lingyue", "lieyun_valley"]
const CITY_IDS: Array[String] = ["ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen", "ch4_s2_canal_docks", "ch4_s3_luoyang_market"]
const CITY_OLD_SHA: Dictionary = {
	"ch4_s0_luoyang_gate": {"scene":"b967c347e745e6f05d51a8f596fde4744571f5d459279467c706e66d9be24bd1","layout":"1d5cca7d70b14032f116964533cc33b9a1b7937beb85c829a4148dfa5c79cc82"},
	"ch4_s1_luoyang_yamen": {"scene":"7bed5d322d583c9c7bf4e392f3f4c75ffb0577db24bb9e6237a4ae3aa0808b01","layout":"658d7038a28f63aa84c701f604bd04405dcff3a8df6bacc7c533557e2e73ab63"},
	"ch4_s2_canal_docks": {"scene":"81850afd0877bba70e2ed0786fe4e81570faee8e06e827561349988f9c4d41a5","layout":"0cc4afd6ec4583b62a9979e79ea88076e2b573f4fa91fb82dd424fa8dfc8c4a3"},
	"ch4_s3_luoyang_market": {"scene":"5cd76d0c0a0c54358f50b341186c5ea078a7d20657c97dc15ef15027755661ab","layout":"d99c58dc2ad2e8b1bfbcbc1ac69e7a9aa08e2ac7cfffc773d4b5708f6825b60c"},
}
const V7_EXECUTION_PINS: Dictionary = {
 "res://scripts/dev/world_map_v15_complete_v7_ecology_source_proposal.gd":"434aca511887eb06939fcd85cbe815b74e1f3fc3c7b560777fb91e78e91a5d16",
 "res://scripts/dev/world_map_v15_complete_v7_surface_proposal.gd":"0f469cd0bfac24195df18e9667873b926d6bee9875f1ca171ccbddeaff2dd7f8",
 "res://scripts/dev/world_map_v15_complete_v7_billboard_caster_proposal.gd":"d2d3795942aa452a18abc006d45bcde44749ccad276a7ec16e0f897604611290",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd":"74a7757a43c7ff4e339fa297bf29a0ec7860cf6a70f7508ebd80a418ce18e233",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v7_regional_proposal.gd":"fd6dc2a60fd4f0fd6f3e4803b96973d6827b9f781f48a82bed1176ed2fc3c9a8"
}
const V7_FINAL_PATHS: Array[String] = [
 WORLD_SOURCE, WORLD_ROOT+"art_contract.json", WORLD_ROOT+"whole_actual_capture.json",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd",
 WORLD_ROOT+"terrain_height.rf"
]
var execution_sha256: Dictionary = {}
var v7_artifact_sha256: Dictionary = {}
var checks: int = 0
var errors: Array[String] = []
var evidence: Dictionary = {}

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: errors.append(label)
	return ok

func _json(path: String) -> Dictionary:
	if not check(FileAccess.file_exists(path), "required real artifact: " + path): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not check(parsed is Dictionary and not parsed.is_empty(), "actual dictionary JSON: " + path): return {}
	return parsed

func _hash(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for character: String in value.to_lower():
		if character not in "0123456789abcdef": return false
	return true

func _pair(value: Variant) -> bool:
	return value is Array and value.size() == 2 and typeof(value[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value[0])) and is_finite(float(value[1]))

func _number(value: Variant, expected: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == expected

func _v(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

func _png(path: String, expected: Vector2i) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < 24: return false
	if file.get_buffer(8) != PackedByteArray([137,80,78,71,13,10,26,10]): return false
	file.big_endian = true
	return file.get_32() == 13 and file.get_buffer(4).get_string_from_ascii() == "IHDR" and file.get_32() == expected.x and file.get_32() == expected.y

func _catalog(record: Dictionary, label: String) -> Dictionary:
	var raw: Variant = record.get("asset_sha256")
	if not check(raw is Dictionary and not raw.is_empty(), label + " nonempty actual SHA catalog"): return {}
	var catalog: Dictionary = raw
	for key: Variant in catalog:
		if not check(key is String and String(key).begins_with("res://") and not ".." in String(key), label + " canonical res path"): continue
		var path: String = key
		var expected: Variant = catalog[key]
		if not check(_hash(expected) and FileAccess.file_exists(path), label + " valid present SHA asset " + path): continue
		check(FileAccess.get_sha256(path).to_lower() == String(expected).to_lower(), label + " actual source/output bytes " + path)
	for graph_name: String in ["source_graph", "capture_graph"]:
		var raw_graph: Variant = record.get(graph_name)
		if not check(raw_graph is Dictionary and not raw_graph.is_empty(), label + " bound " + graph_name): continue
		var graph: Dictionary = raw_graph
		for key: Variant in graph:
			if not check(key is String, label + " graph key string"): continue
			var path: String = key
			var sha: Variant = graph[key]
			if graph_name == "capture_graph":
				if not check(sha is Dictionary, label + " typed capture record " + path): continue
				path = String(sha.get("path", ""))
				sha = sha.get("sha256")
			check(_hash(sha) and catalog.has(path) and String(catalog[path]).to_lower() == String(sha).to_lower(), label + " graph/catalog actual identity " + path)
	return catalog

func _manifest_paths(selected: String = "all") -> Array[String]:
	var result: Array[String] = []
	if selected in ["all","world"]: result.append_array([WORLD_SOURCE, WORLD_ROOT + "art_contract.json"])
	if selected in ["all","city"]:
		for id: String in CITY_IDS: result.append(CITY_ROOT + id + "/art_contract.json")
	if selected in ["all","outskirts"]:
		for biome: String in ["bamboo", "forest", "marsh"]: result.append(OUTSKIRTS_ROOT + biome + "/art_contract.json")
	return result

func run(frozen_inputs_path: String, selected: String = "all") -> Dictionary:
	if not check(selected in ["all","world","city","outskirts"],"known explicit limited preflight scope; FULL requires all"): return report()
	evidence["selected_preflight_scope"] = selected
	var inputs: Dictionary = _json(frozen_inputs_path)
	var execution_value: Variant = inputs.get("execution_sha256")
	var final_value: Variant = inputs.get("v7_artifact_sha256")
	execution_sha256 = execution_value.duplicate(true) if execution_value is Dictionary else {}
	v7_artifact_sha256 = final_value.duplicate(true) if final_value is Dictionary else {}
	var pins: Variant = inputs.get("artifact_sha256")
	if not check(_number(inputs.get("schema"), 1) and inputs.get("scope") == "JOINT_FROZEN_CANDIDATE_INPUTS" and pins is Dictionary, "explicit frozen QA input schema; no self-selected newest revision"):
		return report()
	var required: Array[String] = _manifest_paths(selected)
	var typed_pins: Dictionary = pins
	if not check(typed_pins.size() == required.size(), "exact required source/manifest pins for declared scope, FULL nine not stale subset"): return report()
	for path: String in required:
		var expected: Variant = typed_pins.get(path)
		check(_hash(expected) and FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower() == String(expected).to_lower(), "producer-frozen actual input " + path)
	if not errors.is_empty(): return report()
	if selected in ["all","world"]: _world()
	if selected in ["all","city"]:
		var totals: Vector3i = Vector3i.ZERO
		for id: String in CITY_IDS: totals += _city(id)
		check(totals == Vector3i(15, 11, 12), "all four legacy city identities total15 NPC /11 interactions /12 portals")
	if selected in ["all","outskirts"]:
		for biome: String in ["bamboo", "forest", "marsh"]: _outskirts(biome)
	return report()

func _world() -> void:
	var source: Dictionary = _json(WORLD_SOURCE)
	var manifest: Dictionary = _json(WORLD_ROOT + "art_contract.json")
	if not check(source.get("status") == "ART_ASSETS_READY" and _number(source.get("schema_version"), 15) and _pair(source.get("world_size")) and _v(source.world_size) == Vector2(12288,8192), "complete VERSION15 ready actual source; authoring plan forbidden"): return
	if not check(source.get("pixel_sampling")=="round_world_pixel" and _number(source.get("physical_navigation_margin_px"),0),"literal new source sampler and zero pixel margin; never normalized W-1"): return
	if not check(manifest.get("version") == "world_v15" and manifest.get("status") in ["ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA","PRODUCTION_APPROVED"], "whole capture ready; partial/local/technical-fail forbidden"): return
	if not validate_v7_world_pins(execution_sha256,v7_artifact_sha256,manifest): return
	var catalog: Dictionary = _catalog(manifest, "world")
	if not check(manifest.get("capture_protocol")==WORLD_PROTOCOL and manifest.get("source_contract_path")==WORLD_SOURCE,"FULL coherent whole protocol and literal new source, never bounded pilot"): return
	var binding: Variant=manifest.get("whole_actual_capture")
	if not check(binding is Dictionary and binding.get("path")==WORLD_ROOT+"whole_actual_capture.json" and catalog.get(String(binding.get("path","")))==binding.get("sha256"),"actual full whole report bound to current catalog"): return
	var whole: Dictionary=_json(WORLD_ROOT+"whole_actual_capture.json")
	_world_visual_review(source, catalog)
	if not check(whole.get("capture_protocol")==WORLD_PROTOCOL and whole.get("scope")=="FULL64_112SEAMS_NEW_PROTOCOL_NOT_FORMAL_APPROVED" and whole.get("status")=="FULL64_112SEAMS_NEW_PROTOCOL_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_REVIEW" and whole.get("worlds") is Dictionary and whole.worlds.size()==2 and whole.get("whole_cpu_image_requested")==false and whole.get("whole_cpu_image_allowed")==false and _number(whole.get("maximum_CPU_ROI_pixels"),8404992),"actual two-world FULL scope and exact bounded CPU cap, no whole CPU Image"): return
	if not check(whole.worlds.get("primary") is Dictionary and whole.worlds.get("reference") is Dictionary and whole.worlds.primary.get("roles") is Dictionary and whole.worlds.reference.get("roles") is Dictionary,"two actual typed whole worlds and role maps, malformed evidence fails closed"): return
	var raw_chunks: Variant = manifest.get("chunks")
	if not check(raw_chunks is Array and raw_chunks.size() == 64, "64 actual captured chunks"): return
	var chunks: Dictionary = {}
	for raw: Variant in raw_chunks:
		if not check(raw is Dictionary, "typed captured chunk"): continue
		var row_value: Variant = raw.get("row")
		var col_value: Variant = raw.get("col")
		if not check(typeof(row_value) in [TYPE_INT,TYPE_FLOAT] and typeof(col_value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(row_value)) and is_finite(float(col_value)) and float(row_value) == floor(float(row_value)) and float(col_value) == floor(float(col_value)), "integer native row/col without truncation"): continue
		var row: int = int(row_value)
		var col: int = int(col_value)
		var id: String = "r%d_c%d" % [row,col]
		if not check(row in range(8) and col in range(8) and raw.get("id") == id and not chunks.has(id), "unique exact native tile identity " + id): continue
		var rect: Variant = raw.get("logical_rect_px")
		var expected_rect: Array = [col*1536,row*1024,1536,1024]
		var rect_exact: bool = rect is Array and rect.size() == 4
		if rect_exact:
			for i in 4: rect_exact = rect_exact and _number(rect[i],expected_rect[i])
		check(rect_exact, "actual global native rectangle " + id)
		for kind: String in ["visual","land","raw_walk","walk"]:
			var path: String = WORLD_ROOT + "chunks/" + id + "_" + kind + ".png"
			check(raw.get(kind+"_path") == path and catalog.has(path) and _png(path,Vector2i(1536,1024)), "same-root native PNG " + path)
		var capture: Variant = raw.get("capture")
		if check(capture is Dictionary, "actual camera/mesh capture present " + id):
			check(capture.get("capture_protocol")==WORLD_PROTOCOL and capture.get("capture_role")=="primary" and capture.get("window_id")==id and _pair(capture.get("actual_native_canvas")) and _v(capture.actual_native_canvas)==Vector2(24576,16384) and _pair(capture.get("actual_logical_canvas")) and _v(capture.actual_logical_canvas)==Vector2(1536,1024),"whole GPU canvas distinct from bounded readback ROI and runtime tile "+id)
			var camera: Variant=capture.get("actual_camera")
			check(camera is Dictionary and _pair(camera.get("whole_logical_canvas")) and _v(camera.whole_logical_canvas)==Vector2(12288,8192) and _pair(camera.get("whole_visual_native_canvas")) and _v(camera.whole_visual_native_canvas)==Vector2(24576,16384) and _number(camera.get("projection"),Camera3D.PROJECTION_ORTHOGONAL) and _number(camera.get("size_m"),80),"actual fixed global camera, not a fabricated local-frustum pose "+id)
			var role_map: Variant=capture.get("roles")
			if check(role_map is Dictionary and role_map.size()==5 and whole.worlds.has("primary"),"five actual native roles and primary whole world present "+id):
				for role: String in ["visual","shadow_off","land","raw_walk","walk"]:
					var native_role: Variant=whole.worlds.primary.get("roles",{}).get(role)
					check(native_role is Dictionary and native_role.get("windows") is Dictionary and role_map.get(role)==native_role.windows.get(id),"role capture is exact current whole-report record "+id+"/"+role)
			check(_number(capture.get("binary_MSAA"),0) and capture.get("binary_resized")==false and capture.get("whole_CPU_Image_requested")==false,"authority binary captures unresized MSAA0 and CPU ROI only "+id)
		chunks[id] = raw
	var neighbors: Array[Dictionary] = []
	for row in 8:
		for col in 8:
			if col < 7: neighbors.append({"a":"r%d_c%d"%[row,col],"b":"r%d_c%d"%[row,col+1],"axis":"x"})
			if row < 7: neighbors.append({"a":"r%d_c%d"%[row,col],"b":"r%d_c%d"%[row+1,col],"axis":"y"})
	check(chunks.size() == 64 and neighbors.size() == 112, "all 64 cells and112 independently enumerated adjacency identities")
	evidence["expected_112_topology_NOT_RUNTIME_SEAM_PASS"] = neighbors
	var portals: Variant = source.get("portals")
	var objects: Variant = source.get("objects")
	var cores: Variant = source.get("core_landmarks")
	if not check(portals is Array and portals.size() == 16 and objects is Array and cores is Array and cores.size() == 9, "16 actual doors / independent objects / nine actual projected cores"): return
	var portal_by_id: Dictionary = {}
	var object_by_id: Dictionary = {}
	for raw: Variant in portals:
		if not check(raw is Dictionary, "typed doorway"): continue
		var id: String = String(raw.get("id",""))
		check(id in WORLD_PORTALS and not portal_by_id.has(id), "known unique actual door " + id)
		check(_pair(raw.get("door_foot_px")) and _pair(raw.get("source_doorstep_uv")), "captured actual projected doorway foot/UV; source review status is immutable " + id)
		portal_by_id[id] = raw
	for raw: Variant in objects:
		if raw is Dictionary: object_by_id[String(raw.get("id",""))] = raw
	var actual_cores: Array[Dictionary] = []
	var seen: Dictionary = {}
	for core: Variant in cores:
		if not check(core is Dictionary, "typed actual core"): continue
		var id: String = String(core.get("id",""))
		if not check(id in CORE_IDS and not seen.has(id) and portal_by_id.has(id) and _pair(core.get("center_px")) and _pair(core.get("door_foot_px")), "known unique projected core " + id): continue
		var portal: Dictionary = portal_by_id[id]
		var compound: Variant = object_by_id.get(String(portal.get("compound_id","")))
		if not check(compound is Dictionary and _pair(compound.get("pos")), "actual rendered compound for core " + id): continue
		var actual_center: Vector2 = _v(compound.pos) * Vector2(12288,8192)
		check(_v(core.center_px).distance_to(actual_center) <= .01 and core.door_foot_px == portal.door_foot_px, "core center/door bound to actual render transform within existing.01px " + id)
		actual_cores.append({"id":id,"center":actual_center,"door":_v(portal.door_foot_px)})
		seen[id] = true
	check(actual_cores.size() == 9, "all nine cores including Mingwu measured")
	var distances: Array[Dictionary] = []
	for i in actual_cores.size():
		for j in range(i+1,actual_cores.size()):
			var center_distance: float = actual_cores[i].center.distance_to(actual_cores[j].center)
			var door_distance: float = actual_cores[i].door.distance_to(actual_cores[j].door)
			check(center_distance >= 3072 and door_distance >= 3072, "actual logical center+door minimum3072 " + actual_cores[i].id + "/" + actual_cores[j].id)
			distances.append({"a":actual_cores[i].id,"b":actual_cores[j].id,"center_distance":center_distance,"door_distance":door_distance})
	evidence["actual_projected_core_pairs"] = distances

func _review_bound(path: String, sha: Variant, catalog: Dictionary) -> bool:
	return path.begins_with("res://") and not ".." in path and _hash(sha) and catalog.has(path) and _hash(catalog[path]) and String(catalog[path]).to_lower()==String(sha).to_lower() and FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==String(sha).to_lower()

func _review_negative_probes(portal: Dictionary, approval: Dictionary, catalog: Dictionary, footprints: Dictionary, id: String) -> void:
	check(approval.get("negative_source_footprint_path")==WORLD_FOOTPRINTS and _review_bound(WORLD_FOOTPRINTS,approval.get("negative_source_footprint_sha256"),catalog),"negative review binds exact current original footprint bytes "+id)
	var landmark: Variant=(footprints.get("landmarks",{}) as Dictionary).get(id) if footprints.get("landmarks") is Dictionary else null
	var original: String=String(portal.get("source",""))
	check(landmark is Dictionary and landmark.get("source")==original and _review_bound(original,landmark.get("source_sha256"),catalog) and landmark.get("compound_id")==portal.get("compound_id") and landmark.get("source_doorstep_uv")==portal.get("source_doorstep_uv"),"negative footprint exact original PNG/compound/source doorway UV "+id)
	var probes: Variant=approval.get("input_negative_probes")
	if portal.has("input_negative_probes"):
		check(approval.get("negative_origin")=="CAPTURED_SOURCE_INPUT_NEGATIVES_EXACT_V1" and portal.get("input_negative_probes") is Array and probes==portal.get("input_negative_probes"),"existing captured negative records retained exact; invalid/null source cannot fallback "+id)
	else:
		check(approval.get("negative_origin")=="INDEPENDENT_ROOT_REVIEW_AUTHORED_NEGATIVES_V1","missing source negatives require explicit independently root-authored origin "+id)
	if not check(probes is Array and probes.size()==3,"exact three reviewed semantic negatives "+id): return
	var kinds: Dictionary={}
	for probe: Variant in probes:
		if not check(probe is Dictionary,"typed reviewed negative record "+id): continue
		var kind: String=String(probe.get("kind",""))
		check(kind in ["wall_approach","roof_click","wrongside"] and not kinds.has(kind) and probe.get("semantic_review_status")=="APPROVED","distinct explicitly reviewed negative mechanism "+id+"/"+kind)
		kinds[kind]=true
		var keys: Array[String]=["legal_start_px","blocked_foot_px"] if kind=="wall_approach" else ["legal_stand_px","world_click_px"]
		for key: String in keys:
			var point: Variant=probe.get(key)
			check(_pair(point) and _v(point).x>=0 and _v(point).y>=0 and _v(point).x<12288 and _v(point).y<8192,"negative authored world coordinate finite/in domain "+id+"/"+kind+"/"+key)
		if kind=="roof_click":
			var uv: Variant=probe.get("source_uv")
			check(_pair(uv) and _v(uv).x>=0 and _v(uv).y>=0 and _v(uv).x<1 and _v(uv).y<1,"reviewed roof original source UV strict pixel domain "+id)
	check(kinds.size()==3,"all wall/roof/wrongside negative mechanisms remain mandatory "+id)

func _world_visual_review(source: Dictionary, catalog: Dictionary) -> void:
	# Independent evidence reader, never calls the publication gate. A separate
	# root signature does not alter captured PENDING bytes or credit Field input.
	var start_errors: int=errors.size()
	var review: Dictionary=_json(WORLD_REVIEW)
	var report_path: String=WORLD_ROOT+"whole_actual_capture.json"
	check(_number(review.get("schema_version"),1) and _number(review.get("version"),15) and review.get("capture_protocol")==WORLD_PROTOCOL and review.get("scope")=="ACTUAL_CURRENT_CAPTURE_VISUAL_REVIEW_NOT_FIELD_INPUT_APPROVAL","independent review exact schema/protocol/scope, never Field approval")
	check(review.get("reviewer_role")=="producer/root" and review.get("review_method")=="actual_png_individual_review" and review.get("reviewer") is String and not String(review.get("reviewer","")).strip_edges().is_empty() and typeof(review.get("visual_approved"))==TYPE_BOOL and review.get("visual_approved")==true,"explicit named root individually reviewed current capture")
	for binding: Array in [[WORLD_SOURCE,"source_sha256"],[WORLD_ROOT+"art_contract.json","manifest_sha256"],[report_path,"whole_capture_report_sha256"]]:
		var path: String=binding[0]
		var sha: Variant=review.get(binding[1])
		check(_hash(sha) and FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==String(sha).to_lower(),"review binds exact current bytes "+path)
	check(review.get("whole_capture_report_path")==report_path,"review binds literal FULL whole capture report path")
	var doors_value: Variant=review.get("doors")
	var assets_value: Variant=review.get("reviewed_assets_sha256")
	if not check(doors_value is Dictionary and doors_value.size()==16 and assets_value is Dictionary,"independent exact16 door dictionary and reviewed PNG index"): return
	var doors: Dictionary=doors_value
	var assets: Dictionary=assets_value
	for key: Variant in doors: check(key is String and key in WORLD_PORTALS,"no unknown independently reviewed doorway "+str(key))
	var originals: Dictionary={}
	var portals_value: Variant=source.get("portals")
	var objects_value: Variant=source.get("objects")
	if not check(portals_value is Array and portals_value.size()==16 and objects_value is Array,"typed sixteen captured original doors and object array for independent review"): return
	for portal: Variant in portals_value:
		if not check(portal is Dictionary,"typed captured original doorway for review"): continue
		var id: String=String(portal.get("id",""))
		check(id in WORLD_PORTALS and not originals.has(id),"exact unique original door review identity "+id)
		originals[id]=portal
	check(originals.size()==16,"all sixteen original source door identities are review-bound")
	var compounds: Dictionary={}
	var footprints: Dictionary=_json(WORLD_FOOTPRINTS)
	for object: Variant in objects_value:
		if object is Dictionary:
			var id: String=String(object.get("id",""))
			check(not compounds.has(id),"source object identity unique for review "+id)
			compounds[id]=object
	for id: String in WORLD_PORTALS:
		var portal_value: Variant=originals.get(id)
		var approval_value: Variant=doors.get(id)
		if not check(portal_value is Dictionary and approval_value is Dictionary,"source and independent review both contain "+id): continue
		var portal: Dictionary=portal_value
		var approval: Dictionary=approval_value
		var original: String=String(portal.get("source",""))
		var image: String=String(portal.get("doorstep_review_image_path",""))
		var compound: Variant=compounds.get(String(portal.get("compound_id","")))
		check(approval.get("status")=="APPROVED" and approval.get("source")==original and _review_bound(original,portal.get("source_sha256"),catalog) and _review_bound(original,approval.get("source_sha256"),catalog),"independent approved original PNG exact SHA "+id)
		var uv: Variant=portal.get("source_doorstep_uv")
		var foot: Variant=portal.get("door_foot_px")
		check(_pair(uv) and _pair(foot) and _v(uv).x>=0 and _v(uv).x<=1 and _v(uv).y>=0 and _v(uv).y<=1 and _v(foot).x>=0 and _v(foot).y>=0 and _v(foot).x<12288 and _v(foot).y<8192 and approval.get("compound_id")==portal.get("compound_id") and approval.get("source_doorstep_uv")==uv and approval.get("door_foot_px")==foot,"independent compound/UV/projected door foot exact "+id)
		# Independently reproduce the actual capture's authored-double UV ->
		# native Vector2 -> default JSON components boundary; authored UV and
		# reviewer/footprint records above still bind their exact original bytes.
		var native_uv: Vector2 = _v(uv) if _pair(uv) else Vector2(INF,INF)
		var saved_native_uv: Variant = JSON.parse_string(JSON.stringify([native_uv.x,native_uv.y],"\t")) if native_uv.is_finite() else null
		check(compound is Dictionary and compound.get("source")==original and compound.get("foot_uv")==saved_native_uv and compound.get("world_foot_px")==foot,"reviewed doorway belongs to actual own rendered compound "+id)
		check(approval.get("doorstep_review_image_path")==image and _review_bound(image,portal.get("doorstep_review_image_sha256"),catalog) and _review_bound(image,approval.get("doorstep_review_image_sha256"),catalog) and _review_bound(image,assets.get(image),catalog),"root reviewed exact current doorway capture PNG "+id)
		_review_negative_probes(portal,approval,catalog,footprints,id)
	var spawn: Vector2=Vector2(INF,INF)
	if source.has("player_spawn_px"):
		var explicit: Variant=source.get("player_spawn_px")
		check(_pair(explicit),"existing authored spawn must be valid, never fallback from malformed value")
		if _pair(explicit): spawn=_v(explicit)
	else:
		var declaration: Variant=review.get("default_spawn")
		var linxi: Variant=originals.get("linxi_village")
		var valid: bool=declaration is Dictionary and linxi is Dictionary and typeof(declaration.get("approved"))==TYPE_BOOL and declaration.get("approved")==true and declaration.get("policy")=="EXACT_REVIEWED_LINXI_DOOR_V1" and declaration.get("portal_id")=="linxi_village" and _pair(declaration.get("foot_px")) and declaration.get("foot_px")==linxi.get("door_foot_px")
		check(valid,"absence-only default is explicitly reviewed exact projected Linxi door, not source XZ")
		if valid: spawn=_v(declaration.foot_px)
	check(spawn.is_finite() and spawn.x>=0 and spawn.y>=0 and spawn.x<12288 and spawn.y<8192,"review-selected default projected spawn in actual world domain")
	evidence["independent_visual_review_binding_NOT_FIELD_INPUT_APPROVAL"]={"path":WORLD_REVIEW,"sha256":FileAccess.get_sha256(WORLD_REVIEW) if FileAccess.file_exists(WORLD_REVIEW) else "","source_sha256":review.get("source_sha256"),"manifest_sha256":review.get("manifest_sha256"),"whole_capture_report_sha256":review.get("whole_capture_report_sha256"),"doors":doors.duplicate(true),"default_spawn_px":[spawn.x,spawn.y] if spawn.is_finite() else [],"binding_valid":errors.size()==start_errors}

func load_legacy_pair(id: String) -> Dictionary:
	if not CITY_OLD_SHA.has(id): return {}
	var prefix: String = "res://data/maps/luoyang_v3_legacy/"
	var scene_path: String = prefix+id+"_scene.tres"
	var layout_path: String = prefix+id+"_layout.tres"
	if FileAccess.get_sha256(scene_path).to_lower() != CITY_OLD_SHA[id].scene or FileAccess.get_sha256(layout_path).to_lower() != CITY_OLD_SHA[id].layout: return {}
	var scene: SceneScript = ResourceLoader.load(scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout: WalkableMapLayout = ResourceLoader.load(layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if scene == null or layout == null: return {}
	return {"id":id,"scene":scene,"layout":layout,"scene_path":scene_path,"layout_path":layout_path}

func legacy_semantics(pair: Dictionary) -> Dictionary:
	var id: String = String(pair.get("id",""))
	var scene: SceneScript = pair.get("scene") as SceneScript
	var layout: WalkableMapLayout = pair.get("layout") as WalkableMapLayout
	if not CITY_OLD_SHA.has(id) or scene == null or layout == null: return {}
	var path: String = "res://data/maps/luoyang_v3_legacy/"+id+"_layout.tres"
	if layout.resource_path != path or FileAccess.get_sha256(path).to_lower() != CITY_OLD_SHA[id].layout: return {}
	# Never obtain old interactions/portals from scene.map_layout: that external
	# canonical context can change. The separately hash-bound backup is authority.
	return {"npcs":scene.npcs.duplicate(true),"interactions":layout.interactions.duplicate(true),"portals":layout.portals.duplicate(true)}

func _city(id: String) -> Vector3i:
	var record: Dictionary = _json(CITY_ROOT+id+"/art_contract.json")
	if not check(record.get("canonical_scene_id") == id and _number(record.get("schema_version"),1) and record.get("status") in ["ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA","PRODUCTION_APPROVED"], "same-revision whole city ready " + id): return Vector3i.ZERO
	check(_pair(record.get("logical_size_px")) and _v(record.logical_size_px) == Vector2(3072,2048) and _pair(record.get("ordinary_actor_body_px")) and _v(record.ordinary_actor_body_px) == Vector2(34,24) and _number(record.get("ordinary_actor_visual_scale"),.91), "normal city scale/body not world circle " + id)
	check(record.get("pixel_sampling") == "round_world_pixel" and _number(record.get("physical_navigation_margin_px"),0), "explicit city native sampling/margin " + id)
	var catalog: Dictionary = _catalog(record,id)
	for key: String in ["ground_path","land_path","raw_walk_path","walk_path"]:
		var path: String = String(record.get(key,""))
		check(path.begins_with(CITY_ROOT+id+"/") and catalog.has(path) and _png(path,Vector2i(3072,2048)), "whole city own PNG " + id+"/"+key)
	var legacy_root: String = "res://data/maps/luoyang_v3_legacy/"
	var scene_path: String = legacy_root+id+"_scene.tres"
	var layout_path: String = legacy_root+id+"_layout.tres"
	if not check(FileAccess.get_sha256(scene_path).to_lower() == CITY_OLD_SHA[id].scene and FileAccess.get_sha256(layout_path).to_lower() == CITY_OLD_SHA[id].layout, "literal immutable gameplay source SHA " + id): return Vector3i.ZERO
	var pair: Dictionary = load_legacy_pair(id)
	var originals: Dictionary = legacy_semantics(pair)
	if not check(not originals.is_empty(), "independent old scene+backup layout, not replaced canonical " + id): return Vector3i.ZERO
	var slots: Variant = record.get("gameplay_slots")
	if not check(slots is Dictionary, "all city gameplay slots typed " + id): return Vector3i.ZERO
	var totals: Vector3i = Vector3i(originals.npcs.size(),originals.interactions.size(),originals.portals.size())
	for kind: String in ["npcs","interactions","portals"]:
		var original: Array = originals[kind]
		var actual: Variant = slots.get(kind)
		if not check(actual is Array and actual.size() == original.size(), "all original slots cardinality " + id+"/"+kind): continue
		var expected_ids: Dictionary = {}
		for entry: Dictionary in original: expected_ids[String(entry.get("npc_id" if kind=="npcs" else "id",""))] = entry.duplicate(true)
		var seen: Dictionary = {}
		for entry: Variant in actual:
			if not check(entry is Dictionary, "typed normal gameplay slot"): continue
			var source_id: String = String(entry.get("source_id",""))
			check(expected_ids.has(source_id) and not seen.has(source_id), "original unique normal gameplay identity " + id+"/"+source_id)
			seen[source_id] = true
		evidence[id+"/"+kind+"/original_semantics"] = expected_ids
	evidence[id+"/normal_gameplay_runtime"] = "NOT_RUN; resource slots do not prove action execution"
	return totals

func _outskirts(biome: String) -> void:
	var prefix: String = OUTSKIRTS_ROOT+biome+"/"
	var record: Dictionary = _json(prefix+"art_contract.json")
	check(_number(record.get("schema_version"),1) and record.get("scene_id") == "openworld_v15_%s_outskirts"%biome and record.get("status") == "ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA", "complete new outskirts contract; old2499 not inherited " + biome)
	check(_pair(record.get("logical_size_px")) and _v(record.logical_size_px) == Vector2(1536,1024) and record.get("pixel_sampling") == "round_world_pixel" and _number(record.get("physical_navigation_margin_px"),0), "new native outskirts dimension/sample/physical context " + biome)
	var catalog: Dictionary = _catalog(record,biome)
	var reeds_path: String="res://scripts/dev/world_v15_outskirts_complete_v5_reeds.gd"
	var graph: Dictionary=record.get("source_graph",{})
	var capture: Variant=(record.get("capture_graph",{}) as Dictionary).get("native_reeds_script")
	check(graph.has(reeds_path) and catalog.has(reeds_path) and capture is Dictionary and capture.get("path")==reeds_path and capture.get("sha256")==catalog.get(reeds_path),"new project-original curved-canopy reeds exact literal source/capture/catalog binding; no CC0 substitution "+biome)
	for key: String in ["ground_path","land_path","raw_walk_path","walk_path"]:
		var path: String = String(record.get(key,""))
		check(path.begins_with(prefix) and catalog.has(path) and _png(path,Vector2i(1536,1024)), "new-root own topology PNG " + biome+"/"+key)

func report() -> Dictionary:
	return {"schema":1,"scope":"JOINT_FROZEN_SOURCE_RAW_PREFLIGHT_NOT_FIELD_OR_VISUAL_PASS","checks":checks,"failures":errors.size(),"errors":errors.duplicate(),"evidence":evidence.duplicate(true),"field_executed":false,"actual_actions_executed":false,"gpu_executed":false,"full_source_complete":false,"not_run":["875_BODY_PHYSICS","17_FEET_RUNTIME","112_ACTUAL_SEAM_CAPTURE","ALL_CURRENT_FRAME_ALPHA","ALL_NORMAL_GAMEPLAY","MIGRATION_SAVE_BATTLE_RETURNS","FULL_GPU_VISUAL"]}


func validate_v7_world_pins(execution: Variant, final_artifacts: Variant, manifest: Dictionary) -> bool:
	# Producer-fixed inputs, never infer latest file/path or self-sign approval.
	var initial_errors: int = errors.size()
	if not check(execution is Dictionary and execution.size()==V7_EXECUTION_PINS.size(), "exact five producer-frozen v7 execution source pins"): return false
	if not check(final_artifacts is Dictionary and final_artifacts.size()==V7_FINAL_PATHS.size(), "exact five final v7 artifact pins; absent/PENDING is not a capture"): return false
	var catalog: Variant = manifest.get("asset_sha256")
	var graph: Variant = manifest.get("source_graph")
	if not check(catalog is Dictionary and graph is Dictionary, "typed independent v7 current source graph/catalog"): return false
	for path: String in V7_EXECUTION_PINS:
		var expected: Variant = execution.get(path)
		var valid: bool = _hash(expected) and String(expected).to_lower()==V7_EXECUTION_PINS[path] and FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==String(expected).to_lower()
		check(valid and _hash(catalog.get(path)) and _hash(graph.get(path)) and String(catalog.get(path,"")).to_lower()==String(expected).to_lower() and String(graph.get(path,"")).to_lower()==String(expected).to_lower(), "current exact executed v7 source pin/catalog/graph "+path)
	for path: String in V7_FINAL_PATHS:
		var expected: Variant = final_artifacts.get(path)
		check(_hash(expected) and FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==String(expected).to_lower(), "explicit final artifact current SHA, never newest-directory inference "+path)
	return errors.size()==initial_errors
