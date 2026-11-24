extends SceneTree
## Static-core units only. Never instantiate the activator or call cutover.
const CORE = preload("res://scripts/dev/activate_luoyang_enclosure_v11_city_only_retry2.gd")
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const SELF_PATH := "res://tests/test_luoyang_city_only_prepared_buffer_binding_units_20261010.gd"
const CORE_PATH := "res://scripts/dev/activate_luoyang_enclosure_v11_city_only_retry2.gd"
const PINS := {
	CORE_PATH:"87244459c8fca5c990742eaf10f69e7f32ea54979ae73ce316232f576958874b",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"558a3edfaa368ff52b67ff0eaade7505191011928c2a724897efc727e43887f6",
	"res://scripts/autoload/platform_bridge.gd":"eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a"
}
const ENGINE_SHA := "975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
const IDS: Array[String] = ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
var checks := 0
var failures := 0
var paths: Dictionary = {}
var records: Array[Dictionary] = []
var output := ""

static func fixture_sources() -> Array[String]:
	var result: Array[String] = [SELF_PATH,CORE_PATH,"res://project.godot","res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd","res://scripts/autoload/platform_bridge.gd","res://scripts/autoload/save_manager.gd","res://data/scenes/world_map_jianghu.tres","res://data/config/outskirts_native_adoption.json","res://build/luoyang_enclosure_v11_city_only_approval.json"]
	for id: String in IDS:
		result.append("res://data/scenes/"+id+".tres")
		result.append(C.candidate_path(StringName(id)))
		result.append(C.layout_path(StringName(id)))
	return result

func _initialize() -> void:
	call_deferred("_run_units")

func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("PREPARED_BUFFER_UNIT_FAIL: "+label)
	return ok

func _track(path: String) -> void:
	if paths.has(path): return
	paths[path] = true
	# The approval may legitimately not exist while its literal pin is PENDING.
	if not FileAccess.file_exists(path):
		_check(path=="res://build/luoyang_enclosure_v11_city_only_approval.json","required input exists: "+path)
		return
	if path.get_extension() != "gd": return
	var pattern := RegEx.new()
	_check(pattern.compile("(res://[^\"'\\r\\n]+[.]gd)(?=[\"'\\r\\n])")==OK,"bounded literal script closure regex")
	for reference_match: RegExMatch in pattern.search_all(FileAccess.get_file_as_string(path)):
		_track(reference_match.get_string(1))

func _snapshot() -> Dictionary:
	var result: Dictionary = {}
	for path: String in paths:
		result[path] = _file(path)
	return result

func _file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false,"bytes":0,"sha256":"ABSENT","modified_time":0}
	var file := FileAccess.open(path,FileAccess.READ)
	if not _check(file!=null,"read protected file "+path): return {"read_error":true}
	var size: int = file.get_length()
	file.close()
	return {"exists":true,"bytes":size,"sha256":FileAccess.get_sha256(path),"modified_time":FileAccess.get_modified_time(path)}

func _players() -> Dictionary:
	var result: Dictionary = {}
	for index: int in 5:
		for suffix: String in ["",".bak",".tmp"]:
			var path := "user://save_%d.json%s"%[index,suffix]
			result[path] = _file(path)
	return result

func _write_owned(path: String, bytes: PackedByteArray) -> bool:
	if not path.begins_with(output) or ".." in path or bytes.is_empty(): return false
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_buffer(bytes)
	file.flush()
	var ok: bool = file.get_error()==OK
	file.close()
	return ok and FileAccess.get_file_as_bytes(path)==bytes

func _call_case(id: String, entry: Variant, proof: Variant, values: Array, expected: bool, label: String) -> void:
	var reason: String = CORE._prepared_binding_error(id,entry,proof,values[0],values[1],values[2])
	records.append({"id":id,"case":label,"expected_accept":expected,"actual_accept":reason.is_empty(),"reason":reason})
	_check(reason.is_empty()==expected,label+": "+id)

func _mutate_sha(index: int, value: Variant, entry: Dictionary, proof: Dictionary, values: Array, candidate: String, layout: String) -> void:
	if index<3: values[index]=value
	elif index==3: entry.activated_sha256=value
	elif index==4: entry.required_layout_sha256=value
	elif index==5: proof.candidate_sha256[candidate]=value
	else: proof.layout_sha256[layout]=value

func _one_city(id: String) -> void:
	var candidate: String = C.candidate_path(StringName(id))
	var layout: String = C.layout_path(StringName(id))
	var captured: PackedByteArray = FileAccess.get_file_as_bytes(candidate)
	var layout_buffer: PackedByteArray = FileAccess.get_file_as_bytes(layout)
	var candidate_sha: String = FileAccess.get_sha256(candidate)
	var layout_sha: String = FileAccess.get_sha256(layout)
	if not _check(not captured.is_empty() and not layout_buffer.is_empty() and CORE._bytes_sha256(captured)==candidate_sha and CORE._bytes_sha256(layout_buffer)==layout_sha,"actual candidate/layout buffers equal independent FileAccess SHA: "+id): return
	var entry: Dictionary = {"activated_sha256":candidate_sha,"required_layout_path":layout,"required_layout_sha256":layout_sha}
	var proof: Dictionary = {"candidate_sha256":{},"layout_sha256":{}}
	proof.candidate_sha256[candidate]=candidate_sha
	proof.layout_sha256[layout]=layout_sha
	var values: Array = [candidate_sha,candidate_sha,layout_sha]
	_call_case(id,entry,proof,values,true,"real current candidate/layout seven-SHA binding")
	for index: int in 7:
		for invalid: Variant in [null,false,3,3.0,[],{},"","not-a-sha","0".repeat(63),"0".repeat(65),"g".repeat(64)]:
			var bad_entry: Dictionary=entry.duplicate(true)
			var bad_proof: Dictionary=proof.duplicate(true)
			var bad_values: Array=values.duplicate(true)
			_mutate_sha(index,invalid,bad_entry,bad_proof,bad_values,candidate,layout)
			_call_case(id,bad_entry,bad_proof,bad_values,false,"SHA field%d malformed/type%d"%[index,typeof(invalid)])
		var changed_entry: Dictionary=entry.duplicate(true)
		var changed_proof: Dictionary=proof.duplicate(true)
		var changed_values: Array=values.duplicate(true)
		_mutate_sha(index,"0".repeat(64),changed_entry,changed_proof,changed_values,candidate,layout)
		_call_case(id,changed_entry,changed_proof,changed_values,false,"SHA field%d well-formed mismatch"%index)
	for key: String in ["candidate_sha256","layout_sha256"]:
		var missing: Dictionary=proof.duplicate(true)
		missing.erase(key)
		_call_case(id,entry,missing,values,false,"approval table missing "+key)
		for invalid: Variant in [null,"",[],7]:
			var wrong: Dictionary=proof.duplicate(true)
			wrong[key]=invalid
			_call_case(id,entry,wrong,values,false,"approval table wrong type "+key)
	var missing_candidate: Dictionary=proof.duplicate(true)
	missing_candidate.candidate_sha256.erase(candidate)
	_call_case(id,entry,missing_candidate,values,false,"exact candidate table key absent")
	var missing_layout: Dictionary=proof.duplicate(true)
	missing_layout.layout_sha256.erase(layout)
	_call_case(id,entry,missing_layout,values,false,"exact layout table key absent")
	for key: String in ["activated_sha256","required_layout_sha256","required_layout_path"]:
		var missing: Dictionary=entry.duplicate(true)
		missing.erase(key)
		_call_case(id,missing,proof,values,false,"entry field missing "+key)
	var wrong_path: Dictionary=entry.duplicate(true)
	wrong_path.required_layout_path=layout+".other"
	_call_case(id,wrong_path,proof,values,false,"wrong exact layout path")
	_call_case("unknown_city",entry,proof,values,false,"unknown id")
	_call_case(id,null,proof,values,false,"entry not Dictionary")
	_call_case(id,entry,null,values,false,"proof not Dictionary")
	# Stage pathname changes are simulated ONLY inside this unique owned directory.
	# A captured approved buffer remains the input; later stage reread is rejected.
	var stage_path: String=output+"owned_stage_"+id+".bin"
	_check(not FileAccess.file_exists(stage_path) and _write_owned(stage_path,captured),"owned staging fixture first write")
	var retained: PackedByteArray=FileAccess.get_file_as_bytes(stage_path)
	var mutated: PackedByteArray=retained.duplicate()
	mutated[0]=mutated[0]^1
	_check(_write_owned(stage_path,mutated),"owned stage pathname mutated after capture")
	var fresh_stage_sha: String=FileAccess.get_sha256(stage_path)
	_check(fresh_stage_sha!=candidate_sha and retained==captured,"real owned stage changed, captured buffer unchanged")
	_call_case(id,entry,proof,[CORE._bytes_sha256(retained),candidate_sha,layout_sha],true,"captured buffer remains approved after owned stage change")
	_call_case(id,entry,proof,[fresh_stage_sha,candidate_sha,layout_sha],false,"reread mutated stage buffer rejected")
	_check(_write_owned(stage_path,retained) and FileAccess.get_file_as_bytes(stage_path)==captured,"restore only owned staging fixture")
	for kind: String in ["candidate","layout"]:
		var original: PackedByteArray=captured if kind=="candidate" else layout_buffer
		var owned: String=output+"owned_current_"+kind+"_"+id+".bin"
		_check(not original.is_empty() and not FileAccess.file_exists(owned) and _write_owned(owned,original),"unique owned current "+kind+" fixture")
		var changed: PackedByteArray=original.duplicate()
		changed[0]=changed[0]^1
		_check(_write_owned(owned,changed),"mutate only owned current "+kind+" bytes")
		var changed_sha: String=FileAccess.get_sha256(owned)
		var changed_values: Array=values.duplicate(true)
		changed_values[1 if kind=="candidate" else 2]=changed_sha
		_call_case(id,entry,proof,changed_values,false,"fresh owned current "+kind+" mutation SHA rejected")
		_check(_write_owned(owned,original) and FileAccess.get_file_as_bytes(owned)==original,"restore only owned current "+kind+" fixture")

func _source_write_binding() -> void:
	var text: String=FileAccess.get_file_as_string(CORE_PATH)
	var capture_at: int=text.find("var captured: PackedByteArray = FileAccess.get_file_as_bytes(entry.staged_path)")
	var store_at: int=text.find("staged_bytes[target] = captured",capture_at)
	var prepared_at: int=text.find('"state":"PREPARED"',store_at)
	var write_at: int=text.find("_write(target,staged_bytes[target])",prepared_at)
	_check(capture_at>=0 and store_at>capture_at and prepared_at>store_at and write_at>prepared_at,"actual frozen source captures before PREPARED and writes the same buffer")
	if write_at>prepared_at and prepared_at>=0:
		var activation_tail: String=text.substr(prepared_at,text.find("func _approval()")-prepared_at)
		_check(not activation_tail.contains("entry.staged_path") and not activation_tail.contains("FileAccess.get_file_as_bytes(candidate)"),"no staged/candidate reread in actual canonical-write body")
	_check(text.contains('const APPROVAL_SHA := "PENDING_ROOT_CITY_ONLY_FRESH_ACTUAL_APPROVAL"'),"production approval remains PENDING; no activation authorized")

func _run_units() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		_check(false,"public checkpoint API available")
		quit(1)
		return
	var default: Variant=bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended",true)
	var checkpoint: Dictionary={"default_suspended":default,"before_any_await":bridge.call("is_checkpoint_saves_suspended"),"restored_before_exit":false}
	_check(typeof(default)==TYPE_BOOL and not default and checkpoint.before_any_await==true,"checkpoint suspended before all awaits and retained through quit")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	_check(args.size()==2 and "--luoyang-prepared-buffer-binding-units" in args and "--fresh-start-only" in args,"only explicit static-unit arguments; no activation/candidate flags")
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"installed engine/WASAPI/ordinary clock")
	output="res://build/joint_world_luoyang_20261003_qa/prepared_buffer_binding_units_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique BUILD-only result directory"):
		quit(1)
		return
	for path: String in fixture_sources(): _track(path)
	for path: String in PINS: _check(FileAccess.get_sha256(path)==PINS[path],"frozen pure core/source "+path)
	var first: Dictionary=_snapshot()
	var before_players: Dictionary=_players()
	var saver: Node=root.get_node_or_null("SaveManager")
	var before_slot: Variant=saver.get("active_slot") if saver!=null else null
	_check(saver!=null and typeof(before_slot)==TYPE_INT,"actual normal SaveManager active slot observed")
	if failures==0:
		_check(CORE._bytes_sha256(PackedByteArray()).is_empty(),"empty captured buffer has no approved hash")
		for id: String in IDS: _one_city(id)
		_check(records.size()==432,"all four cities execute all108 real static binding cases")
		_source_write_binding()
	for frame: int in 8: await process_frame
	var last: Dictionary=_snapshot()
	var after_players: Dictionary=_players()
	_check(first==last,"all protected sources/candidates/layouts/canonical/approval first-last unchanged")
	_check(before_players==after_players and saver!=null and saver.get("active_slot")==before_slot,"all15 normal player files and active slot unchanged; outer exact ticks required")
	_check(bridge.call("is_checkpoint_saves_suspended")==true and AudioServer.get_driver_name()=="WASAPI" and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"checkpoint/audio/engine through final await")
	var report: Dictionary={"scope":"LUOYANG_PREPARED_CAPTURED_BUFFER_STATIC_CORE_UNITS_NOT_CUTOVER_APPROVAL","complete":failures==0,"checks":checks+1,"failures":failures,"records":records,"source_before":first,"source_after":last,"players_before":before_players,"players_after":after_players,"active_slot_before":before_slot,"active_slot_after":saver.get("active_slot") if saver!=null else null,"checkpoint":checkpoint,"actual_audio_driver":AudioServer.get_driver_name(),"engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"canonical_write_executed":false,"activator_instantiated":false,"approval_created_or_signed":false,"Field_tested":false,"six_approval_credit":false,"native_source_modified_time_resolution":"Godot whole seconds; outer prelaunch/final precise UTC ticks mandatory"}
	var result_path: String=output+"result.json"
	var encoded: PackedByteArray=(JSON.stringify(report,"\t",true)+"\n").to_utf8_buffer()
	var persisted: bool=_write_owned(result_path,encoded)
	var readback: Variant=JSON.parse_string(FileAccess.get_file_as_string(result_path)) if persisted else null
	_check(persisted and readback is Dictionary and readback==report,"unique result write and readback")
	print("PREPARED_BUFFER_BINDING_UNIT_RESULT "+result_path+" checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures==0 else 1)
