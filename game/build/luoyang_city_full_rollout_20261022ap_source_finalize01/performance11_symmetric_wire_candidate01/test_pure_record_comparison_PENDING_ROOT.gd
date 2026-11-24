extends SceneTree
const FIXTURE="res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance11_symmetric_wire_candidate01/pure_record_comparison_fixture_PENDING_ROOT.json"
const FIXTURE_SHA="621ca879dafc115c1f1b7d6029b7543dd5bfe0b2d1816cdf8fc79a7005f63321"
var checks: int=0
var errors: Array=[]
var rows: Array=[]
func check(value: bool,label: String) -> bool:
	checks+=1
	if not value: errors.append(label)
	return value
func _initialize() -> void: call_deferred("_run")
func nested(levels: int) -> Variant:
	var value: Variant="leaf"
	for index: int in levels: value={"next":value}
	return value
func compare_case(old: Variant,candidate: Variant,label: String,left: Variant,right: Variant,strict_expected: bool) -> void:
	var before: int=Time.get_ticks_usec()
	var old_result: bool=old.equal(old._wire(left),old._wire(right))
	var old_usec: int=Time.get_ticks_usec()-before
	before=Time.get_ticks_usec()
	var new_result: bool=candidate._symmetric_record_wire_equal(left,right)
	var new_usec: int=Time.get_ticks_usec()-before
	var strict_result: bool=candidate._strict_record_json_equal(left,right)
	check(new_result==old_result,label+": complete old/new result equality")
	check(strict_result==strict_expected,label+": strict domain/match branch")
	rows.append({"label":label,"old":old_result,"new":new_result,"strict_success":strict_result,"old_wall_usec":old_usec,"new_wall_usec":new_usec})
func finish() -> void:
	var root: String="res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance11_symmetric_wire_candidate01/output/%d_%d"%[OS.get_process_id(),Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(root)
	var file: FileAccess=FileAccess.open(root+"/result.json",FileAccess.WRITE)
	if file==null: quit(1);return
	file.store_string(JSON.stringify({"status":"ONE_PURE_RECORD_OLD_NEW_COMPARISON_NOT_FIELD_OR_LOADING_CREDIT","passed":errors.is_empty(),"checks":checks,"errors":errors,"rows":rows,"Field_requests":0,"collector_calls":0,"geometry_calls":0,"native_decode_calls":0,"order_bias_and_record_only_no_loading_speed_claim":true},"  ",true,true)+"\n")
	file.close()
	print("PURE_RECORD_RESULT "+root+"/result.json")
	quit(0 if errors.is_empty() else 1)
func _run() -> void:
	if not check(FileAccess.get_sha256(FIXTURE)==FIXTURE_SHA,"Exact fixture SHA"): finish();return
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true,"Root frozen ready fixture required"): finish();return
	var fixture: Dictionary=raw
	for path: String in fixture.source_sha256:
		if not check(FileAccess.get_sha256(path)==fixture.source_sha256[path],"Fixed source before "+path): finish();return
	var old: Variant=load(fixture.old_bundle_path)
	var candidate: Variant=load(fixture.candidate_path)
	if not check(old is GDScript and candidate is GDScript,"Two fixed pure scripts loaded"): finish();return
	compare_case(old,candidate,"finite scalar nested exact",{"a":[null,true,"x",4,4.5]},{"a":[null,true,"x",4,4.5]},true)
	compare_case(old,candidate,"strict numeric type mismatch falls back",{"a":4},{"a":4.0},false)
	compare_case(old,candidate,"different value falls back",{"a":4},{"a":5},false)
	compare_case(old,candidate,"Vector2 excluded",{"a":Vector2(1,2)},{"a":Vector2(1,2)},false)
	compare_case(old,candidate,"nonString key excluded",{4:"x"},{4:"x"},false)
	compare_case(old,candidate,"StringName key excluded",{&"x":4},{&"x":4},false)
	compare_case(old,candidate,"nonfinite excluded",{"a":INF},{"a":INF},false)
	compare_case(old,candidate,"packed array excluded",{"a":PackedInt32Array([1,2])},{"a":PackedInt32Array([1,2])},false)
	check(candidate._strict_record_json_equal(nested(63),nested(63)),"63 levels remain in conservative domain")
	check(not candidate._strict_record_json_equal(nested(64),nested(64)),"64 levels fail closed to old fallback")
	var publication: Variant=JSON.parse_string(FileAccess.get_file_as_string(fixture.parent_manifest_path))
	if not check(publication is Dictionary and publication.get("record") is Dictionary,"Fixed Yamen publication record only"): finish();return
	var left: Dictionary=publication.record
	var right: Dictionary=left.duplicate(true)
	compare_case(old,candidate,"one fixed Yamen parent whole record",left,right,true)
	for path: String in fixture.source_sha256:
		check(FileAccess.get_sha256(path)==fixture.source_sha256[path],"Fixed source after "+path)
	finish()
