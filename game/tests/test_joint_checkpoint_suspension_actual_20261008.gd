extends SceneTree
## LIMITED actual public checkpoint suspension + notification + isolated manual
## SaveManager test. Never writes an enabled checkpoint to any normal player slot.
## No Field, historic compatibility, geometry, uninterrupted BGM or release credit.
const BUILD_ROOT := "res://build/joint_world_luoyang_20261003_qa/"
const BRIDGE := "res://scripts/autoload/platform_bridge.gd"
const ISOLATED := "res://tests/helpers/v15_isolated_save_manager.gd"
const BGM := "res://art/audio/bgm/bgm_mountain_path_v4.wav"
const ENGINE_SHA := "975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
const PINS := {
	BRIDGE:"eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a",
	ISOLATED:"dab23dd87ee942ed9cd60e97f9cd9441dc8f76aa1f6b310203636a257903e9c6",
	"res://scripts/autoload/save_manager.gd":"67c06cd14d6a7c0bbfd7467bbaae84f906aad57b19cabc0902baf80eb3aff7d9",
	"res://scripts/autoload/audio_manager.gd":"23f8fe91c0b526eb38722b08969dc40b5e47d1f1cfc99497ce8536b6743d3a5c",
	"res://scripts/autoload/scene_router.gd":"f3ead7459632188350e1e3383ee915c83b71c1b86d36dadf718bd338a4324eca"
}
var check_count := 0
var fail_count := 0
var output := ""
var normal_before: Dictionary = {}
var sources_before: Dictionary = {}
var slot_before: Variant
var bridge: Node
var audio: Node
var slots: Node
var paused_events := 0
var resumed_events := 0
var observations: Array[Dictionary] = []
var manual: Dictionary = {}
var default_suspended: Variant

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
	check_count += 1
	if not ok:
		fail_count += 1
		push_error("[CHECKPOINT SUSPENSION FAIL] " + label)
	return ok

func _file(path: String) -> Dictionary:
	var result := {"exists":FileAccess.file_exists(path)}
	if result.exists:
		var file := FileAccess.open(path,FileAccess.READ)
		result["readable"] = file != null
		result["bytes"] = file.get_length() if file != null else -1
		if file != null: file.close()
		result["sha256"] = FileAccess.get_sha256(path)
		result["mtime_seconds"] = FileAccess.get_modified_time(path)
	return result

func _normal_files() -> Dictionary:
	var result := {}
	for index in 5:
		for suffix: String in ["",".bak",".tmp"]:
			var path := "user://save_%d.json%s" % [index,suffix]
			result[ProjectSettings.globalize_path(path)] = _file(path)
	return result

func _collect(directory: String,extension: String,paths: Dictionary) -> void:
	var dir := DirAccess.open(directory)
	if dir == null: paths[directory + "/MISSING"] = true; return
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if not name.begins_with("."):
			var path := directory.path_join(name)
			if dir.current_is_dir(): _collect(path,extension,paths)
			elif name.get_extension() == extension: paths[path] = true
		name = dir.get_next()
	dir.list_dir_end()

func _sources() -> Dictionary:
	# Fresh first/last unique-path reads; no endpoint cache or inherited old SHA.
	var paths := {"res://project.godot":true,BGM:true,ISOLATED:true,get_script().resource_path:true}
	_collect("res://scripts","gd",paths)
	_collect("res://data","tres",paths)
	var result := {}
	for path: String in paths: result[path] = _file(path)
	return result

func _audio_state() -> Dictionary:
	var player: AudioStreamPlayer = audio.get("bgm_player") as AudioStreamPlayer
	return {"player_id":str(player.get_instance_id()) if player != null else "", "stream_id":str(player.stream.get_instance_id()) if player != null and player.stream != null else "", "playing":player.playing if player != null else false,"stream_paused":player.stream_paused if player != null else false,"platform_paused":audio.get("_platform_paused"),"path":player.stream.resource_path if player != null and player.stream != null else ""}

func _on_paused() -> void:
	paused_events += 1

func _on_resumed() -> void:
	resumed_events += 1

func _run() -> void:
	# Suspension is established before any await or process fixture.
	bridge = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		push_error("[CHECKPOINT SUSPENSION FAIL] public contract unavailable")
		quit(1)
		return
	default_suspended = bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended",true)
	normal_before = _normal_files()
	slot_before = root.get_node("SaveManager").get("active_slot")
	sources_before = _sources()
	output = BUILD_ROOT + "checkpoint_suspension_%d_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	_check(not DirAccess.dir_exists_absolute(output) and DirAccess.make_dir_recursive_absolute(output) == OK,"unique owned evidence domain")
	_check(typeof(default_suspended) == TYPE_BOOL and not default_suspended,"default getter is false; no enabled checkpoint write exercised")
	_check(bridge.call("is_checkpoint_saves_suspended") == true,"public setter/getter established suspension")
	_check(OS.get_cmdline_user_args() == PackedStringArray(["--checkpoint-suspension-actual"]),"one explicit LIMITED scope argument")
	_check(AudioServer.get_driver_name() == "WASAPI" and FileAccess.get_sha256(OS.get_executable_path()).to_lower() == ENGINE_SHA,"actual WASAPI/executable identity at start")
	for path: String in PINS: _check(FileAccess.get_sha256(path).to_lower() == PINS[path],"exact execution pin " + path)
	for path: String in sources_before: _check(bool(sources_before[path].exists) and bool(sources_before[path].get("readable",false)),"fresh consumed source readable " + path)
	if fail_count > 0: await _finish(); return
	var isolated_script := load(ISOLATED) as GDScript
	if not _check(isolated_script != null and isolated_script.can_instantiate(),"isolated real SaveManager compiles"):
		await _finish(); return
	for id: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","WeatherManager","SceneRouter"]:
		root.get_node(id).call("reset_for_new_game")
	# Public current-format navigation fixture only; no Field is instantiated.
	# reset_for_new_game intentionally leaves current_field empty, so establish
	# eligibility through the real public restore API, never a private field write.
	var router: Node = root.get_node("SceneRouter")
	var current_navigation: Dictionary = router.call("get_navigation_state")
	current_navigation["current_field"] = "ch1_s1_road"
	router.call("restore_navigation_state",current_navigation,&"ch1_s1_road")
	_check(is_instance_valid(root.get_node("GameState").get("player")) and not String(root.get_node("SceneRouter").call("get_current_field_id")).is_empty(),"real public fixture has valid player and nonempty current field")
	_check(bridge.call("request_checkpoint_save") == false,"suspended checkpoint refuses despite otherwise eligible real fixture")
	_check(_normal_files() == normal_before,"direct refused checkpoint preserves all15 player paths")
	audio = root.get_node("AudioManager")
	bridge.connect("application_paused",_on_paused)
	bridge.connect("application_resumed",_on_resumed)
	audio.call("play_bgm",BGM,0.,"checkpoint_suspension_limited")
	for frame in 4: await process_frame
	_check(bool(_audio_state().playing) and not bool(_audio_state().stream_paused),"real BGM playback ready for lifecycle observation")
	for pair: Array in [[Node.NOTIFICATION_APPLICATION_PAUSED,Node.NOTIFICATION_APPLICATION_RESUMED],[Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT,Node.NOTIFICATION_WM_WINDOW_FOCUS_IN]]:
		var before := _audio_state()
		var pauses := paused_events
		var resumes := resumed_events
		bridge.notification(int(pair[0]))
		var paused := _audio_state()
		_check(paused_events == pauses + 1 and bool(paused.platform_paused) and bool(paused.stream_paused),"real notification preserves pause signal/audio while checkpoint suspended")
		_check(paused.player_id == before.player_id and paused.stream_id == before.stream_id,"pause does not replace real player/stream")
		bridge.notification(int(pair[1]))
		var resumed := _audio_state()
		_check(resumed_events == resumes + 1 and not bool(resumed.platform_paused) and not bool(resumed.stream_paused) and bool(resumed.playing),"real resume/focus-in signal and audio resume preserved")
		_check(resumed.player_id == before.player_id and resumed.stream_id == before.stream_id,"resume retains player/stream identity")
		_check(bridge.call("is_checkpoint_saves_suspended") == true and _normal_files() == normal_before,"lifecycle never re-enables checkpoint or writes player slots")
		observations.append({"notification_pause":pair[0],"notification_resume":pair[1],"before":before,"paused":paused,"resumed":resumed,"paused_signal_delta":paused_events-pauses,"resumed_signal_delta":resumed_events-resumes})
	# Explicit manual saving remains real production SaveManager implementation;
	# only the existing test-owned path override differs. Never replace autoload.
	slots = isolated_script.new() as Node
	isolated_script = null
	root.add_child(slots)
	var isolated_dir := "user://world_map_v15_qa/checkpoint_suspension_%d_%d_%d" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	var configured: bool = not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(isolated_dir)) and bool(slots.call("configure_directory",isolated_dir))
	_check(configured,"unique existing-isolated-manager manual save domain")
	if configured:
		var state := root.get_node("GameState")
		var expected_gold: int = int(state.get("gold"))
		var expected_navigation: Dictionary = root.get_node("SceneRouter").call("get_navigation_state")
		var saved: bool = slots.call("save_to_slot",0)
		var path: String = slots.call("slot_path",0)
		var saved_file := _file(path)
		_check(saved and bool(saved_file.exists) and bool(saved_file.get("readable",false)),"manual real SaveManager writes isolated owned slot while checkpoint suspended")
		state.call("add_gold",7)
		var loaded: bool = slots.call("load_from_slot",0)
		var loaded_navigation: Dictionary = root.get_node("SceneRouter").call("get_navigation_state")
		var expected_json: Variant = JSON.parse_string(JSON.stringify(expected_navigation))
		var loaded_json: Variant = JSON.parse_string(JSON.stringify(loaded_navigation))
		_check(loaded and int(state.get("gold")) == expected_gold and loaded_json == expected_json,"manual real load restores saved gold/navigation, not global save disable")
		_check(_file(path) == saved_file,"manual load does not rewrite isolated input")
		manual = {"isolated_directory":ProjectSettings.globalize_path(isolated_dir),"input_path":ProjectSettings.globalize_path(path),"input_file":saved_file,"actual_save":saved,"actual_load":loaded,"saved_navigation":expected_json,"loaded_navigation":loaded_json,"autoload_SaveManager_replaced":false}
	await _finish()

func _finish() -> void:
	# Keep suspension true for the remaining fixture lifetime, including shutdown.
	if is_instance_valid(bridge):
		_check(bridge.call("is_checkpoint_saves_suspended") == true,"automatic checkpoints remain suspended until process exit")
		if bridge.is_connected("application_paused",_on_paused): bridge.disconnect("application_paused",_on_paused)
		if bridge.is_connected("application_resumed",_on_resumed): bridge.disconnect("application_resumed",_on_resumed)
	if is_instance_valid(slots): slots.queue_free()
	slots = null
	if is_instance_valid(audio): audio.call("stop_bgm",.15)
	var start := Time.get_ticks_usec()
	while Time.get_ticks_usec() - start < 300000: await process_frame
	for shape: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	var normal_after := _normal_files()
	var sources_after := _sources()
	_check(normal_before == normal_after and root.get_node("SaveManager").get("active_slot") == slot_before,"all15 normal player files and original active slot unchanged")
	_check(sources_before == sources_after,"all consumed source bytes/SHA/mtime unchanged")
	_check(AudioServer.get_driver_name() == "WASAPI" and FileAccess.get_sha256(OS.get_executable_path()).to_lower() == ENGINE_SHA,"actual WASAPI/executable identity at finish")
	var result := {"scope":"LIMITED_CHECKPOINT_SUSPENSION_REAL_NOTIFICATIONS_AND_ISOLATED_MANUAL_SAVE_LOAD","checks":check_count,"failures":fail_count,"full_complete":false,"Field_executed":false,"historical_compatibility_tested":false,"automatic_checkpoint_saves_tested":false,"automatic_checkpoint_saves_restored_before_exit":false,"default_suspended":default_suspended,"suspended_at_finish":bridge.call("is_checkpoint_saves_suspended") if is_instance_valid(bridge) else false,"observations":observations,"manual":manual,"normal_files_before":normal_before,"normal_files_after":normal_after,"active_slot_before":slot_before,"active_slot_after":root.get_node("SaveManager").get("active_slot"),"source_before":sources_before,"source_after":sources_after,"actual_audio_driver":AudioServer.get_driver_name(),"engine_executable_sha256":FileAccess.get_sha256(OS.get_executable_path()),"ticks_finish":Time.get_ticks_usec(),"stderr_and_precise_UTC_ticks":"ROOT_WRAPPER_REQUIRED"}
	var path := output + "result.json"
	var file := FileAccess.open(path,FileAccess.WRITE) if not output.is_empty() and not FileAccess.file_exists(path) else null
	if file == null: _check(false,"unique result writable")
	else:
		var encoded := JSON.stringify(result,"\t")
		file.store_string(encoded)
		file.flush()
		var error := file.get_error()
		file.close()
		_check(error == OK and JSON.parse_string(FileAccess.get_file_as_string(path)) == JSON.parse_string(encoded),"result checked readback")
	print("CHECKPOINT_SUSPENSION_LIMITED: %d/%d output=%s" % [check_count,fail_count,output])
	quit(0 if fail_count == 0 else 1)
