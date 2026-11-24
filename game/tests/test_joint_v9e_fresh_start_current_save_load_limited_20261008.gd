extends SceneTree
## LIMITED actual current-format scope only. No artifact preflight, full RELEASE,
## visual approval, production cutover or historical compatibility credit.
const CURRENT = preload("res://tests/helpers/joint_v15_current_save_load_20261008.gd")
const GATE = preload("res://scripts/dev/joint_world_city_v15_release_acceptance.gd")
const FLAGS: Array[String]=["--fresh-start-only","--candidate-before-cutover","--luoyang-v3-candidate","--outskirts-candidate-preview","--outskirts-complete-v5"]
var checks: int=0
var failures: int=0
var output: String=""
var source_before: Dictionary={}
var player_before: Dictionary={}
var slot_before: Variant
var new_game: Dictionary={}
var current_saves: Dictionary={}

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures+=1; push_error("[FRESH CURRENT LIMITED] "+label)
	return ok

func _file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false}
	var file: FileAccess=FileAccess.open(path,FileAccess.READ)
	var size: int=file.get_length() if file!=null else -1
	if file!=null: file.close()
	return {"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":size,"mtime_seconds":FileAccess.get_modified_time(path)}

func _players() -> Dictionary:
	var result: Dictionary={}
	for slot in 5:
		for suffix: String in ["",".bak",".tmp"]:
			var path: String="user://save_%d.json%s"%[slot,suffix]
			result[path]=_file(path)
	return result

func _sources() -> Dictionary:
	# Read-only complete current closure, not an approval or artifact predicate.
	# GATE uses unique path keys; no repeated hashing for duplicate text matches.
	var result: Dictionary=GATE.snapshot()
	if result.is_empty(): return {}
	for path: String in [get_script().resource_path,"res://tests/helpers/joint_v15_current_save_load_20261008.gd"]:
		if not FileAccess.file_exists(path): return {}
		result[path]=FileAccess.get_sha256(path)
	return result

func _write(name: String,value: Dictionary) -> bool:
	var path: String=output+name
	if FileAccess.file_exists(path): return false
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	var text_value: String=JSON.stringify(value,"\t",true)
	file.store_string(text_value); file.flush()
	var error: Error=file.get_error(); file.close()
	return error==OK and FileAccess.get_file_as_string(path)==text_value and JSON.parse_string(FileAccess.get_file_as_string(path))==JSON.parse_string(text_value)

func _run() -> void:
	player_before=_players()
	slot_before=root.get_node("SaveManager").get("active_slot")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	_check(args.size()==FLAGS.size(),"only five explicit fresh/candidate scene flags")
	for flag: String in FLAGS: _check(args.count(flag)==1,"single required limited flag: "+flag)
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==CURRENT.CURRENT_ENGINE_SHA,"actual ordinary1x/frozen executable/WASAPI before limited run")
	output="res://build/joint_world_luoyang_20261003_qa/fresh_current_limited_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	_check(not DirAccess.dir_exists_absolute(output) and DirAccess.make_dir_recursive_absolute(output)==OK,"unique limited evidence directory")
	if failures==0:
		source_before=_sources()
		_check(not source_before.is_empty() and _write("sources_before.json",source_before),"complete current source closure captured before actual input")
	if failures==0:
		var menu_probe: RefCounted=CURRENT.new()
		new_game=await menu_probe.call("run_new_game",self,true)
		menu_probe=null
		checks+=int(new_game.get("checks",0)); failures+=int(new_game.get("failures",1))
		_check(new_game.get("complete")==true and new_game.get("normal_button_input")==true,"real MainMenu NewGame normal pointer and start Field complete")
		_check(_write("new_game_actual.json",new_game),"actual NewGame evidence persisted")
	if failures==0:
		var save_probe: RefCounted=CURRENT.new()
		current_saves=await save_probe.call("run_current",self,true)
		save_probe=null
		checks+=int(current_saves.get("checks",0)); failures+=int(current_saves.get("failures",1))
		_check(CURRENT.current_report_matches(current_saves,true),"all11 actual scenes/two births and26 actual unsupported zero-mutation loads")
		_check(_write("current_save_load_actual.json",current_saves),"actual current-format evidence persisted")
	root.get_node("AudioManager").call("stop_bgm",0.0)
	Input.set_custom_mouse_cursor(null)
	for frame in 8: await process_frame
	var source_after: Dictionary=_sources() if not source_before.is_empty() else {}
	_check(not source_before.is_empty() and source_after==source_before,"all current source/art/contract SHA unchanged through limited scope")
	_check(_write("sources_after.json",source_after),"source closure final snapshot persisted")
	_check(player_before==_players() and root.get_node("SaveManager").get("active_slot")==slot_before,"all15 player files and ordinary active slot unchanged")
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==CURRENT.CURRENT_ENGINE_SHA,"actual frozen executable/WASAPI1x after cleanup")
	var result: Dictionary={"scope":"LIMITED_FRESH_START_CURRENT_FORMAT_SAVE_LOAD_ACTUAL_NOT_RELEASE","complete":failures==0,"release_complete":false,"full_artifact_preflight_executed":false,"checks":checks+1,"failures":failures,"new_game":new_game,"current_save_load":current_saves,"sources_before":source_before,"sources_after":source_after,"players_before":player_before,"players_after":_players(),"actual_audio_driver":AudioServer.get_driver_name(),"engine_executable_sha256":FileAccess.get_sha256(OS.get_executable_path()),"output":output}
	result.merge(CURRENT.mode_metadata(),true)
	_check(_write("result.json",result),"limited final result checked readback, never RELEASE approval")
	print("FRESH_CURRENT_LIMITED checks=",checks," failures=",failures," complete=",failures==0," release_complete=false output=",output)
	quit(0 if failures==0 else 1)
