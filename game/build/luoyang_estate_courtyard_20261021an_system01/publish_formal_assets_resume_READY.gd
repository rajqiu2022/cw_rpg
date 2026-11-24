extends SceneTree
## ROOT-only residual publication. Existing Estate3 files are verified, never
## rewritten. Only the one-room return/source successor is newly published.
const E=preload("res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd")
const N=preload("res://build/luoyang_estate_courtyard_20261021an_system01/verify_existing_runtime_native_resume.gd")
const R=preload("res://build/luoyang_estate_courtyard_20261021an_system01/publish_mansion_return_dependency_successor.gd")
const HERE="res://build/luoyang_estate_courtyard_20261021an_system01/"
const INPUT=HERE+"formal_publication_input_resume_READY.json"
const INPUT_SHA="673337b70b8fee9faf7390e92329aae8927d1dd1bac1491371a928fa5df0eef0"
var first: Dictionary={}
var error: String=""
func _initialize() -> void: call_deferred("_run")
func track(path: String,sha: String) -> bool:
	if not path.begins_with("res://") or ".." in path or sha.length()!=64 or FileAccess.get_sha256(path)!=sha:
		error="EXACT_RESUME_SOURCE:"+path;return false
	if first.has(path) and first[path]!=sha: error="SOURCE_COLLISION:"+path;return false
	first[path]=sha;return true
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var began: int=Time.get_ticks_msec();var native: Dictionary={};var room: Dictionary={}
	if not OS.get_cmdline_user_args().is_empty(): error="NO_ARGUMENTS"
	if error.is_empty() and track(INPUT,INPUT_SHA) and track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)):
		var spec: Dictionary=E.json(INPUT)
		if spec.get("status")!="ROOT_APPROVED_AN_FINAL_GEOMETRY_MEDIA_AND_ONE_ROOM_PUBLICATION" or not spec.get("program_sources") is Dictionary or not spec.get("runtime_native") is Dictionary: error="EXACT_APPROVED_RESUME_INPUT"
		if error.is_empty():
			for path: String in spec.program_sources:
				if not track(path,spec.program_sources[path]): break
		if error.is_empty():
			native=N.publish(spec.runtime_native,track)
			if native.get("ok")!=true: error=String(native.get("error","NATIVE_VERIFY_FAILED"))
		if error.is_empty():
			room=R.publish(track)
			if room.get("ok")!=true: error=String(room.get("error","ROOM_SUCCESSOR_FAILED"))
	var final: Dictionary={}
	for path: String in first:
		final[path]=FileAccess.get_sha256(path)
		if final[path]!=first[path]: error="SOURCE_FINAL_CHANGED:"+path
	if Time.get_ticks_msec()-began>=60000: error="FIXED60S"
	var dir: String=HERE+"formal_publication_resume/"+str(OS.get_process_id())+"/"
	if DirAccess.dir_exists_absolute(dir) or DirAccess.make_dir_recursive_absolute(dir)!=OK: quit(1);return
	var result: Dictionary={"passed":error.is_empty() and native.get("ok")==true and room.get("ok")==true,"error":error,"scope":"AN_RESIDUAL_ONE_ROOM_PUBLICATION_WITH_EXACT_EXISTING_ESTATE_NATIVE_REUSE_NOT_DEPLOYED_OR_FIELD","source_first":first,"source_final":final,"runtime_native":native,"mansion_return":room,"native_republication":false,"geometry_rerun":false,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":60000}
	var file:=FileAccess.open(dir+"result.json",FileAccess.WRITE)
	if file==null: quit(1);return
	file.store_string(JSON.stringify(result,"\t",true,true));file.close();print(JSON.stringify({"passed":result.passed,"path":dir+"result.json","error":error}));quit(0 if result.passed else 1)
