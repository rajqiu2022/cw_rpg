extends SceneTree
## Read-only actual review-tail diagnostic, NOT publisher or Field acceptance.
## Expected UV replays one unchanged default JSON writer boundary on the original
## measured Double array. Saved values are never rounded or cast to Vector2.
const GATE = preload("res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd")
const SOURCE := "res://data/maps/world_map_v15_complete_v9c_source.json"
const MANIFEST := "res://art/maps/world_map_v15_complete_v9c/art_contract.json"
const EXPECTED_MISMATCHES := ["huashan","bianzhou","gufeng","qinghe_town","zhuwei_village","wudang","xiangzhou","jinling","mingwu","lingyue","lieyun_valley"]
const PINS := {
	"res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd":"460fb5d0dad60917429a169e4be502894a156a1ac4ed88fbdfb50153ef3376c2",
	SOURCE:"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
	MANIFEST:"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
	"res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json":"cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851",
	"res://data/maps/world_map_v15_complete_v5_landmark_footprints_candidate.json":"72c942db3430e2ae58326b3acd330643d8c90e0cadf073d3ba731582f902f242",
	"res://data/maps/world_map_v15_complete_v9c_visual_review.json":"59418b6e68d2e4f5613893b4a72946e47c0bee8e8a361e3eb7b1fc4ad241929d",
	"res://scripts/dev/build_world_map_v15_complete_v5_full_draft.gd":"2e5efff6bf27f478bea3f6a1131c2919cdd502c6fa37f7969d60067a8c4d2f85",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd":"74a7757a43c7ff4e339fa297bf29a0ec7860cf6a70f7508ebd80a418ce18e233",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v9e_full_proposal.gd":"dcda6d3227cad5fd646b6fa3390cae5c4f71354fec1adf15552a12188a8d0121"
}
var checks := 0
var errors: Array[String] = []
var pins: Dictionary = PINS.duplicate()

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func _read(path: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary: return {}
	return parser.data

func _bind(path: String, catalog: Dictionary) -> void:
	_check(GATE._bound(catalog,path) and GATE._same_hash(catalog.get(path),FileAccess.get_sha256(path)), "actual consumed catalog SHA: " + path)
	if GATE._bound(catalog,path): pins[path] = catalog[path]

func _neighbor(value: float, direction: int) -> float:
	# Actual positive finite UVs: one native binary64 successor/predecessor.
	var bytes := PackedFloat64Array([value]).to_byte_array()
	bytes.encode_s64(0, bytes.decode_s64(0) + direction)
	return bytes.decode_double(0)

func _finite_writer_exact(saved: Variant, measured: Variant) -> bool:
	# Exercise the actual existing strict predicates, not a tolerant comparator.
	return GATE._pair(saved) and GATE._pair(measured) and GATE._json_native_exact(saved,measured)

func _run() -> void:
	pins[GATE.BASE_PATH] = GATE.BASE_SHA
	for path: String in pins: _check(GATE._same_hash(pins[path],FileAccess.get_sha256(path)), "frozen source before: " + path)
	var source := _read(SOURCE)
	var manifest := _read(MANIFEST)
	var review := _read(GATE.REVIEW)
	var footprints := _read(GATE.NEGATIVE_FOOTPRINTS)
	_check(not source.is_empty() and not manifest.is_empty() and not review.is_empty() and not footprints.is_empty(), "all actual frozen dictionaries parsed")
	var rows: Array[Dictionary] = []
	var mismatches: Array[String] = []
	var negative_errors: Dictionary = {}
	var door_errors: Dictionary = {}
	var full_review_error := "NOT_RUN"
	if errors.is_empty():
		var catalog: Dictionary = manifest.asset_sha256
		_bind(GATE.NEGATIVE_FOOTPRINTS,catalog)
		_bind(GATE.ROOT + "landmark_semantics.json",catalog)
		var semantics := _read(GATE.ROOT + "landmark_semantics.json")
		_check(source.portals.size() == 16 and review.doors.size() == 16 and footprints.landmarks.size() == 16, "all actual sixteen reviewed footprints/portals")
		var seen: Dictionary = {}
		for portal: Dictionary in source.portals:
			var id: String = portal.id
			_check(id in GATE.C.PORTAL_IDS and not seen.has(id), "exact unique current portal: " + id)
			seen[id] = true
			var measured: Dictionary = footprints.landmarks[id]
			var approval: Dictionary = review.doors[id]
			var raw_uv: Variant = measured.source_doorstep_uv
			var saved_uv: Variant = portal.source_doorstep_uv
			_bind(portal.source,catalog)
			_bind(portal.doorstep_review_image_path,catalog)
			_check(measured.source == portal.source and measured.compound_id == portal.compound_id and GATE._same_hash(measured.source_sha256,portal.source_sha256), "unchanged source/hash/compound association: " + id)
			var parser := JSON.new()
			var encoded: String = JSON.stringify({"source_doorstep_uv":raw_uv},"\t")
			_check(parser.parse(encoded) == OK and parser.data is Dictionary, "independent original writer default JSON decode: " + id)
			var expected: Variant = parser.data.source_doorstep_uv
			_check(GATE._equal_exact_value(saved_uv,expected) and _finite_writer_exact(saved_uv,raw_uv), "actual saved array exact once-writer measured Double array: " + id)
			_check(GATE._equal_exact_value(saved_uv,semantics.landmarks[id].source_doorstep_uv) and GATE._equal_exact_value(saved_uv,approval.source_doorstep_uv), "captured semantics/portal/independent review share exact stored UV: " + id)
			var direct: bool = GATE._same_pair_values(raw_uv,saved_uv)
			if not direct: mismatches.append(id)
			negative_errors[id] = GATE._negative_review_error(portal,approval,catalog)
			door_errors[id] = GATE.door_review_error(portal,review,catalog)
			_check(negative_errors[id] == ("" if direct else "Negative footprint/source/compound/door UV differs " + id), "actual complete negative review reaches exact original UV failure or passes: " + id)
			_check(door_errors[id] == negative_errors[id], "actual complete door review has no earlier refusal: " + id)
			for axis in 2:
				for direction: int in [-1,1]:
					var wrong: Array = saved_uv.duplicate()
					wrong[axis] = _neighbor(float(wrong[axis]),direction)
					_check(not GATE._equal_exact_value(wrong,saved_uv) and not _finite_writer_exact(wrong,raw_uv), "saved exact binary64 one-ULP rejection axis%d direction%d: %s" % [axis,direction,id])
			for wrong: Variant in [null, true, "0.5,0.9", [saved_uv[0]], [saved_uv[0],saved_uv[1],0], [str(saved_uv[0]),saved_uv[1]], [true,saved_uv[1]], [NAN,saved_uv[1]], [INF,saved_uv[1]], Vector2(float(saved_uv[0]),float(saved_uv[1]))]:
				_check(not _finite_writer_exact(wrong,raw_uv), "saved wrong type/shape/nonfinite refused without rounding: " + id)
			rows.append({"id":id,"measured_double_uv":raw_uv,"saved_uv":saved_uv,"once_writer_uv":expected,"measured_binary64":PackedFloat64Array(raw_uv).to_byte_array().hex_encode(),"saved_binary64":PackedFloat64Array(saved_uv).to_byte_array().hex_encode(),"direct_equal":direct,"actual_negative_error":negative_errors[id],"actual_door_error":door_errors[id]})
		_check(mismatches == EXPECTED_MISMATCHES and seen.size() == 16, "all actual eleven codec mismatches and sixteen exact IDs")
		full_review_error = GATE._review(source,manifest,catalog)
		_check(full_review_error == "Negative footprint/source/compound/door UV differs huashan", "actual full review preserves ROOT298 refusal")
	for path: String in pins: _check(GATE._same_hash(pins[path],FileAccess.get_sha256(path)), "frozen consumed source after: " + path)
	print("V9E_NEGATIVE_DOOR_UV_READONLY_DIAGNOSTIC ",JSON.stringify({"scope":"READ_ONLY_REVIEW_TAIL_DIAGNOSTIC_NOT_PUBLISH_PASS","checks":checks,"failures":errors.size(),"errors":errors,"rows":rows,"mismatches":mismatches,"actual_full_review_error":full_review_error,"negative_errors":negative_errors,"door_errors":door_errors,"consumed_files":pins.size(),"gate_or_review_changed":false,"Field_executed":false,"publisher_executed":false,"formal_cutover":false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm",.15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
