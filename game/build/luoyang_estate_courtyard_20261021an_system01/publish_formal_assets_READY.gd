extends SceneTree
## ROOT-only, after final wall geometry and the one isolated five-PNG import.
## INPUT must be frozen with exact receipt hashes before this key can run.
const E=preload("res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd")
const N=preload("res://build/luoyang_estate_courtyard_20261021an_system01/publish_runtime_native_candidate.gd")
const R=preload("res://build/luoyang_estate_courtyard_20261021an_system01/publish_mansion_return_candidate.gd")
const INPUT="res://build/luoyang_estate_courtyard_20261021an_system01/formal_publication_input_READY.json"
const INPUT_SHA="f4a3b782ee06de2cba00543daf81e8906472a70adc843300115d0bea55d93038"
const HERE="res://build/luoyang_estate_courtyard_20261021an_system01/"
var first: Dictionary={}
var error: String=""
func _initialize() -> void: call_deferred("_run")
func track(path: String,sha: String) -> bool:
	if not path.begins_with("res://") or ".." in path or sha.length()!=64 or FileAccess.get_sha256(path)!=sha:
		error="EXACT_PUBLICATION_SOURCE:"+path;return false
	if first.has(path) and first[path]!=sha: error="SOURCE_COLLISION:"+path;return false
	first[path]=sha;return true
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	if not OS.get_cmdline_user_args().is_empty() or not track(INPUT,INPUT_SHA): quit(1);return
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): quit(1);return
	var spec: Dictionary=E.json(INPUT)
	if spec.get("status")!="ROOT_APPROVED_AN_FINAL_GEOMETRY_MEDIA_AND_ONE_ROOM_PUBLICATION" or not spec.get("program_sources") is Dictionary or not spec.get("runtime_native") is Dictionary: quit(1);return
	for path: String in spec.program_sources:
		if not track(path,spec.program_sources[path]): quit(1);return
	var began: int=Time.get_ticks_msec();var native: Dictionary=N.publish(spec.runtime_native,track)
	if not native.get("ok",false): push_error(JSON.stringify(native));quit(1);return
	var room: Dictionary=R.publish(track)
	if not room.get("ok",false): push_error(JSON.stringify(room));quit(1);return
	var final: Dictionary={}
	for path: String in first:
		final[path]=FileAccess.get_sha256(path)
		if final[path]!=first[path]: error="SOURCE_FINAL_CHANGED:"+path
	var dir: String=HERE+"formal_publication/"+str(OS.get_process_id())+"/"
	if DirAccess.dir_exists_absolute(dir) or DirAccess.make_dir_recursive_absolute(dir)!=OK: quit(1);return
	var result: Dictionary={"passed":error.is_empty(),"error":error,"scope":"AN_NEW_NATIVE_PATH_REBIND_AND_ONE_ROOM_RETURN_ONLY_NOT_DEPLOYED_OR_FIELD","source_first":first,"source_final":final,"runtime_native":native,"mansion_return":room,"geometry_rerun":false,"elapsed_ms":Time.get_ticks_msec()-began}
	var file:=FileAccess.open(dir+"result.json",FileAccess.WRITE)
	if file==null: quit(1);return
	file.store_string(JSON.stringify(result,"\t",true,true));file.close();print(JSON.stringify({"passed":result.passed,"path":dir+"result.json"}));quit(0 if result.passed else 1)
