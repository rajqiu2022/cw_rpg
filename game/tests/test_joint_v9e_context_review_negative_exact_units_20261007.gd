extends SceneTree
## Independent context review-tail units only. No gate, publisher, RF rebuild,
## frozen-input generation, Field input or formal activation is called here.
const CONTEXT = preload("res://tests/helpers/joint_v15_v9e_source_context_oracle.gd")
const CONTEXT_PATH := "res://tests/helpers/joint_v15_v9e_source_context_oracle.gd"
const PINS := {
	CONTEXT_PATH:"52ade58531971527afe8b9cd6cb899b0325c42f3f41fa7f09426835231b9c4bc",
	"res://data/maps/world_map_v15_complete_v9c_source.json":"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
	"res://art/maps/world_map_v15_complete_v9c/art_contract.json":"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
	"res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json":"cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851",
	"res://data/maps/world_map_v15_complete_v9c_visual_review.json":"59418b6e68d2e4f5613893b4a72946e47c0bee8e8a361e3eb7b1fc4ad241929d",
	"res://data/maps/world_map_v15_complete_v5_landmark_footprints_candidate.json":"72c942db3430e2ae58326b3acd330643d8c90e0cadf073d3ba731582f902f242",
	"res://tests/helpers/joint_v15_v9c_derived_geometry_probe.gd":"9cf95257e91c26571d87661aed3986cd037f35803e4b0bab9d723d4156697095"
}
var checks := 0
var errors: Array[String] = []
var pins: Dictionary = PINS.duplicate()
var negative_calls := 0

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
	_check(catalog.has(path) and FileAccess.get_sha256(path).to_lower()==String(catalog[path]).to_lower(), "actual consumed catalog binding: " + path)
	if catalog.has(path): pins[path] = catalog[path]

func _neighbor(value: float, direction: int) -> float:
	var bytes := PackedFloat64Array([value]).to_byte_array()
	bytes.encode_s64(0,bytes.decode_s64(0)+direction)
	return bytes.decode_double(0)

func _negative(portal: Dictionary, approval: Dictionary, catalog: Dictionary, footprints: Dictionary, wrong: Variant, label: String) -> void:
	var mutated := portal.duplicate()
	mutated["source_doorstep_uv"] = wrong
	var context = CONTEXT.new()
	context._review_negative_probes(mutated,approval,catalog,footprints,portal.id)
	negative_calls += 1
	_check(context.errors.size()==1 and context.errors[0]=="negative footprint exact original PNG/compound/source doorway UV " + String(portal.id), "complete independent context UV predicate rejects " + label + ": " + String(portal.id))

func _run() -> void:
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower()==String(pins[path]).to_lower(), "frozen actual source before: " + path)
	var source := _read(CONTEXT.WORLD_SOURCE)
	var manifest := _read(CONTEXT.WORLD_ROOT + "art_contract.json")
	var review := _read(CONTEXT.WORLD_REVIEW)
	var footprints := _read(CONTEXT.WORLD_FOOTPRINTS)
	_check(not source.is_empty() and not manifest.is_empty() and not review.is_empty() and not footprints.is_empty(), "actual frozen S/M/review/footprint dictionaries")
	var full_summary: Dictionary = {}
	var door_summaries: Array[Dictionary] = []
	if errors.is_empty():
		var catalog: Dictionary = manifest.asset_sha256
		var complete_context = CONTEXT.new()
		complete_context._world_visual_review(source,catalog)
		_check(complete_context.errors.is_empty() and complete_context.evidence.independent_visual_review_binding_NOT_FIELD_INPUT_APPROVAL.binding_valid==true, "actual entire independent context world_visual_review passes")
		full_summary = {"checks":complete_context.checks,"errors":complete_context.errors.duplicate(),"binding_valid":complete_context.evidence.independent_visual_review_binding_NOT_FIELD_INPUT_APPROVAL.binding_valid}
		_check(source.portals.size()==16 and review.doors.size()==16, "all sixteen actual independently reviewed doors")
		var seen: Dictionary = {}
		for portal: Dictionary in source.portals:
			var id: String = portal.id
			_check(id in CONTEXT.WORLD_PORTALS and not seen.has(id), "exact unique portal: " + id)
			seen[id] = true
			_bind(portal.source,catalog)
			_bind(portal.doorstep_review_image_path,catalog)
			var approval: Dictionary = review.doors[id]
			var context = CONTEXT.new()
			context._review_negative_probes(portal,approval,catalog,footprints,id)
			_check(context.errors.is_empty(), "all actual three complete negative-probe contracts pass independently: " + id)
			door_summaries.append({"id":id,"checks":context.checks,"errors":context.errors.duplicate()})
			var saved_uv: Array = portal.source_doorstep_uv
			for axis in 2:
				for direction: int in [-1,1]:
					var wrong: Array = saved_uv.duplicate()
					wrong[axis] = _neighbor(float(wrong[axis]),direction)
					_check(not context._review_exact_value(wrong,saved_uv), "saved binary64 ULP really differs, no Float32 cast: " + id)
					_negative(portal,approval,catalog,footprints,wrong,"binary64 ULP axis%d direction%d" % [axis,direction])
			for wrong: Variant in [null,true,"UV",[saved_uv[0]],[saved_uv[0],saved_uv[1],0],[str(saved_uv[0]),saved_uv[1]],[true,saved_uv[1]],[NAN,saved_uv[1]],[INF,saved_uv[1]],Vector2(saved_uv[0],saved_uv[1])]:
				_negative(portal,approval,catalog,footprints,wrong,"wrong type/shape/nonfinite")
		_check(seen.size()==16 and negative_calls==224, "all sixteen doors and224 real complete-predicate UV countercases")
		var exact_context = CONTEXT.new()
		_check(exact_context._review_exact_value({"n":[1.0,{"b":true}]},{"n":[1,{"b":true}]}), "independent recursive exact comparator valid nested values")
		for wrong: Variant in [{"n":[1.0,{"b":1}]},{"n":[1.0,{"b":false}]},{"n":[1.0,{"b":true}],"extra":0},{"n":[NAN,{"b":true}]},{"n":[1.0]}]:
			_check(not exact_context._review_exact_value(wrong,{"n":[1.0,{"b":true}]}), "independent recursive comparator rejects type/value/key/nonfinite/shape")
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower()==String(pins[path]).to_lower(), "consumed frozen source after: " + path)
	print("V9E_CONTEXT_REVIEW_NEGATIVE_EXACT_UNITS ",JSON.stringify({"scope":"INDEPENDENT_COMPLETE_CONTEXT_REVIEW_ONLY_NOT_RELEASE_OR_FIELD_PASS","checks":checks,"failures":errors.size(),"errors":errors,"actual_full_world_visual_review":full_summary,"actual_all16_negative_probes":door_summaries,"actual_negative_calls":negative_calls,"consumed_files":pins.size(),"gate_called":false,"RF_reconstructed":false,"frozen_inputs_generated":false,"Field_executed":false,"formal_cutover":false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm",.15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
