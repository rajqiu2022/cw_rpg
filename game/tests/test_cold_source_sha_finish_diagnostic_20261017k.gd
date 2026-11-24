extends "res://tests/helpers/cold_sha_qa_20261017k.gd"
## Read existing failed-run fixtures only. Diagnose return/operator value domains.
const OLD_DIR="res://build/luoyang_cold_source_sha_qa_20261017k/FIXTURES_ONLY_30S/52648_1617"
const HELPER="res://build/luoyang_cold_source_sha_20261017k_source01/parallel_source_hash.gd"
var diagnostic_paths: Array=[]

func describe(value: Variant) -> Dictionary:
	var result: Dictionary={"typeof":typeof(value),"type_name":type_string(typeof(value)),"var_to_str":var_to_str(value) if not value is Dictionary else "Dictionary size="+str(value.size())}
	if value is Dictionary:
		result["count"]=value.size()
		if not value.is_empty():
			var key: Variant=value.keys()[0]
			result["first_key"]=str(key);result["first_value_type"]=typeof(value[key]);result["first_leaf"]=var_to_str(value[key])
	elif value is Object and is_instance_valid(value): result["object_class"]=value.get_class();result["object_id"]=value.get_instance_id()
	return result

func exercise() -> bool:
	var result: Dictionary=await run_job(diagnostic_paths,2)
	records.append({"kind":"ASYNC_JOB_RETURN","value":describe(result),"debug":result.get("debug",{})})
	return result.get("ok",false)

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+15000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_cold_source_finish_diagnostic_20261017k/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	if not track("res://tests/helpers/cold_sha_qa_20261017k.gd","a70f39d1ca8c84399b9963352901765c9d41b5343a08613a74fe06734b150a75") or not track(HELPER,"80b9b63ec0262524c3cf49fa181520a53c83498a39d2088498f9043bca78095b"): quit(1);return
	helper_script=load(HELPER) as Script
	for name: String in DirAccess.get_files_at(OLD_DIR):
		if not name.ends_with(".bin"): continue
		var path: String=OLD_DIR.path_join(name)
		diagnostic_paths.append(path);source_before[path]=fact(path)
	var before_control: Dictionary=source_before.duplicate(true)
	var before_compare: Variant=source_before==before_control
	var raw_complete: Variant=await exercise()
	var source_after: Dictionary={}
	for path: String in source_before: source_after[path]=fact(path)
	var players_after: Dictionary=saves()
	var source_comparison: Variant=source_before==source_after
	var player_comparison: Variant=players_before==players_after
	var scalar_control: Variant=3==3
	var output: Dictionary={"scope":"READ_ONLY_FINISH_VALUE_DIAGNOSTIC_NOT_FIXTURE_ACCEPTANCE","elapsed_ms":Time.get_ticks_msec()-began,"old_fixture_count":diagnostic_paths.size(),"exercise_return":describe(raw_complete),"before_await_dictionary_comparison":describe(before_compare),"source_comparison":describe(source_comparison),"players_comparison":describe(player_comparison),"scalar_control":describe(scalar_control),"source_before_descriptor":describe(source_before),"source_after_descriptor":describe(source_after),"source_before":source_before,"source_after":source_after,"players_before":players_before,"players_after":players_after,"records":records}
	var file:=FileAccess.open(folder.path_join("result.json"),FileAccess.WRITE)
	if file==null: quit(1);return
	file.store_string(JSON.stringify(output,"\t"));file.close()
	print("COLD_SHA_FINISH_DIAGNOSTIC=",folder,"/result.json")
	print("EXERCISE=",describe(raw_complete)," SOURCE_COMPARE=",describe(source_comparison)," PLAYERS_COMPARE=",describe(player_comparison))
	quit(0)
