extends SceneTree
## NEW read-only REAL RELEASE adapter whole-review API units. Never run the
## phase, Field, publisher, generator or approval writer. Only check collection
## and the single output evidence sink are substituted, plus explicit in-memory
## adversarial review fixtures. No mutated file is persisted.
const ADAPTER_PATH := "res://tests/helpers/joint_v15_release_world_prepared_phase.gd"
## Exact source-only narrow reader repair; root schedules all execution.
const ADAPTER_SHA := "3fc824e313664deaa6d3765b4d7f7614a1fa6ef7f9ca12dda8f2ddfe9046cde6"
const PINS := {
	"res://tests/helpers/joint_v15_v9e_source_context_oracle.gd":"52ade58531971527afe8b9cd6cb899b0325c42f3f41fa7f09426835231b9c4bc",
	"res://data/maps/world_map_v15_complete_v9c_source.json":"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
	"res://art/maps/world_map_v15_complete_v9c/art_contract.json":"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
	"res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json":"cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851",
	"res://data/maps/world_map_v15_complete_v9c_visual_review.json":"59418b6e68d2e4f5613893b4a72946e47c0bee8e8a361e3eb7b1fc4ad241929d",
	"res://data/maps/world_map_v15_complete_v5_landmark_footprints_candidate.json":"72c942db3430e2ae58326b3acd330643d8c90e0cadf073d3ba731582f902f242",
	"res://tests/helpers/joint_v15_v9c_derived_geometry_probe.gd":"9cf95257e91c26571d87661aed3986cd037f35803e4b0bab9d723d4156697095",
	"res://tests/helpers/joint_v15_v9c_world_prepared_phase.gd":"16a66f74eba277c9dcf7c1a6801bb5183d0fedf363a3e6fc3805bc41e7474970",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd":"74a7757a43c7ff4e339fa297bf29a0ec7860cf6a70f7508ebd80a418ce18e233",
	"res://scripts/dev/build_world_map_v15_complete_v5_full_draft.gd":"2e5efff6bf27f478bea3f6a1131c2919cdd502c6fa37f7969d60067a8c4d2f85"
}

class ReviewHarness:
	extends "res://tests/helpers/joint_v15_release_world_prepared_phase.gd"
	var captured_errors: Array[String] = []
	var output_sink: Dictionary = {}
	var review_fixture: Dictionary = {}
	func _check(ok: bool, label: String) -> void:
		checks += 1
		if not ok:
			failures += 1
			captured_errors.append(label)
	func _json(path: String) -> Dictionary:
		if path == REVIEW_PATH and not review_fixture.is_empty():
			return review_fixture.duplicate(true)
		return super._json(path)
	func _write_json(name: String, value: Dictionary) -> bool:
		if name != "independent_visual_review_binding.json" or not output_sink.is_empty():
			return false
		output_sink[name] = value.duplicate(true)
		return true

var checks := 0
var errors: Array[String] = []
var pins: Dictionary = PINS.duplicate()
var whole_negative_calls := 0
var whole_checks := 0
var full_summary: Dictionary = {}
var positive_door_summaries: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func _read(path: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary: return {}
	return parser.data

func _neighbor(value: float, direction: int) -> float:
	var bytes := PackedFloat64Array([value]).to_byte_array()
	bytes.encode_s64(0,bytes.decode_s64(0)+direction)
	return bytes.decode_double(0)

func _contains_prefix(messages: Array[String], prefix: String) -> bool:
	for message: String in messages:
		if message.begins_with(prefix): return true
	return false

func _whole(source: Dictionary, manifest: Dictionary, review_fixture: Dictionary = {}) -> ReviewHarness:
	var phase := ReviewHarness.new()
	phase.source = source
	phase.manifest = manifest
	phase.review_fixture = review_fixture
	phase._read_independent_door_review()
	whole_checks += phase.checks
	return phase

func _negative(source: Dictionary, manifest: Dictionary, review: Dictionary, portal_index: int, compound_index: int, field: String, wrong: Variant, change_approval: bool, label: String) -> void:
	var mutated_source := source.duplicate()
	var mutated_review: Dictionary = {}
	var portal: Dictionary = source.portals[portal_index]
	var id: String = portal.id
	if field == "source_doorstep_uv":
		mutated_source["portals"] = source.portals.duplicate()
		var changed: Dictionary = portal.duplicate(true)
		changed[field] = wrong
		mutated_source.portals[portal_index] = changed
		if change_approval:
			mutated_review = review.duplicate(true)
			mutated_review.doors[id][field] = wrong
	else:
		mutated_source["objects"] = source.objects.duplicate()
		var changed: Dictionary = source.objects[compound_index].duplicate(true)
		changed[field] = wrong
		mutated_source.objects[compound_index] = changed
	var phase := _whole(mutated_source,manifest,mutated_review)
	whole_negative_calls += 1
	var prefix: String = "review door belongs to current actual rendered compound "
	if field == "source_doorstep_uv":
		prefix = "negative footprint independently binds original PNG/compound/source doorway UV " if change_approval else "review exact compound/source UV/actual projected foot, never source XZ "
	_check(phase.failures > 0 and _contains_prefix(phase.captured_errors,prefix+id), "real whole-review API rejects "+field+"/"+label+"/"+id)
	_check(phase.reviewed_doors.is_empty() and phase.visual_review_evidence.get("binding_valid")==false, "failed whole review never promotes reviewed doors: "+id)
	_check(phase.output_sink.size()==1 and phase.output_sink.has("independent_visual_review_binding.json"), "whole method reaches explicit memory-only evidence sink after refusal: "+id)

func _run() -> void:
	pins[ADAPTER_PATH] = ADAPTER_SHA
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower()==String(pins[path]).to_lower(), "actual source before: "+path)
	var source := _read(ReviewHarness.SOURCE_PATH)
	var manifest := _read(ReviewHarness.MANIFEST_PATH)
	var review := _read(ReviewHarness.REVIEW_PATH)
	var footprints := _read(ReviewHarness.REVIEW_FOOTPRINTS)
	_check(not source.is_empty() and not manifest.is_empty() and not review.is_empty() and not footprints.is_empty(), "actual frozen S/M/review/footprint dictionaries")
	if errors.is_empty():
		var catalog: Dictionary = manifest.asset_sha256
		var phase := _whole(source,manifest)
		_check(phase.failures==0 and phase.reviewed_doors.size()==16 and phase.visual_review_evidence.get("binding_valid")==true, "actual full independent RELEASE adapter review passes all original checks")
		full_summary = {"checks":phase.checks,"failures":phase.failures,"errors":phase.captured_errors.duplicate(),"binding_valid":phase.visual_review_evidence.get("binding_valid")}
		_check(source.portals.size()==16 and review.doors.size()==16, "all sixteen actual independently reviewed doors")
		var seen: Dictionary = {}
		for portal_index in source.portals.size():
			var portal: Dictionary = source.portals[portal_index]
			var id: String = portal.id
			_check(ReviewHarness.DESTINATIONS.has(id) and not seen.has(id), "exact unique portal: "+id)
			seen[id] = true
			for path: String in [portal.source,portal.doorstep_review_image_path]:
				_check(catalog.has(path) and FileAccess.get_sha256(path).to_lower()==String(catalog[path]).to_lower(),"actual consumed image catalog binding: "+path)
				if catalog.has(path): pins[path]=catalog[path]
			var direct := ReviewHarness.new()
			direct._review_negative_probes(portal,review.doors[id],catalog,footprints,id)
			_check(direct.failures==0 and direct.checks>=17,"all three actual negative-probe mechanisms continue without typed-array exception: "+id)
			positive_door_summaries.append({"id":id,"checks":direct.checks,"failures":direct.failures,"errors":direct.captured_errors.duplicate()})
			var compound_index := -1
			for index in source.objects.size():
				if source.objects[index].get("id")==portal.compound_id:
					compound_index=index
					break
			_check(compound_index>=0,"actual unique rendered compound found: "+id)
			if compound_index<0: continue
			for field: String in ["source_doorstep_uv","foot_uv"]:
				var saved: Array = portal.source_doorstep_uv if field=="source_doorstep_uv" else source.objects[compound_index].foot_uv
				for axis in 2:
					for direction: int in [-1,1]:
						var wrong: Array = saved.duplicate()
						wrong[axis] = _neighbor(float(wrong[axis]),direction)
						_check(wrong[axis]!=saved[axis],"saved binary64 ULP is genuinely distinct: "+id+"/"+field)
						_negative(source,manifest,review,portal_index,compound_index,field,wrong,true,"binary64 ULP axis%d direction%d"%[axis,direction])
						if field=="source_doorstep_uv":
							_negative(source,manifest,review,portal_index,compound_index,field,wrong,false,"same-saved-domain approval ULP axis%d direction%d"%[axis,direction])
				for wrong: Variant in [null,true,"UV",[saved[0]],[saved[0],saved[1],0],[str(saved[0]),saved[1]],[true,saved[1]],[NAN,saved[1]],[INF,saved[1]],Vector2(saved[0],saved[1])]:
					_negative(source,manifest,review,portal_index,compound_index,field,wrong,true,"wrong type/shape/nonfinite")
		_check(seen.size()==16 and whole_negative_calls==512, "all16 x both fields x14 corruptions plus64 unchanged-approval ULP cases invoke actual whole-review API")
		var adapter_text := FileAccess.get_file_as_string(ADAPTER_PATH)
		_check(adapter_text.contains("func _portal_runtime_phase() -> void:") and adapter_text.contains("var modes: Array = [\"space\", \"door_mouse\", \"arrow\"] if requested_mode == \"all\" else [requested_mode]"),"source-only array override present; not48 runtime inputs credit")
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower()==String(pins[path]).to_lower(),"consumed source after: "+path)
	print("V9E_RELEASE_ADAPTER_REVIEW_EXACT_UNITS ",JSON.stringify({"scope":"REAL_WHOLE_REVIEW_API_MEMORY_ONLY_ADVERSARIAL_FIXTURES_NOT_RELEASE_FIELD_OR_APPROVAL","checks":checks,"failures":errors.size(),"errors":errors,"whole_review_checks":whole_checks,"actual_full_review":full_summary,"all16_negative_probe_mechanisms":positive_door_summaries,"whole_negative_calls":whole_negative_calls,"consumed_files":pins.size(),"actual_adapter_sha":FileAccess.get_sha256(ADAPTER_PATH),"gate_called":false,"RF_reconstructed":false,"phase_run_called":false,"Field_executed":false,"evidence_file_written":false,"formal_cutover":false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm",.15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
