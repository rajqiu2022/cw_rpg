extends SceneTree
## Direct identity/core units. No Field/input/fade/geometry/six approval credit.
const CORE = preload("res://tests/helpers/luoyang_enclosure_v11_fade_native_npc_band_probe_20261010.gd")
const RUNTIME = preload("res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd")
const SELF_PATH := "res://tests/test_luoyang_fade_current_runtime_bindings_units_20261010.gd"
const CORE_PATH := "res://tests/helpers/luoyang_enclosure_v11_fade_native_npc_band_probe_20261010.gd"
const CORE_SHA := "b3bd2f56637009751c41da215ffa14d330930d6e7c468509b72a82b6820b1b7a"
const ENGINE_SHA := "975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
var checks := 0
var failed := 0
var rows: Array[Dictionary] = []
var sources: Dictionary = {}

static func fixture_sources() -> Array[String]:
	var result: Array[String]=[SELF_PATH,CORE_PATH,"res://project.godot","res://scripts/autoload/platform_bridge.gd","res://scripts/autoload/save_manager.gd","res://data/scenes/world_map_jianghu.tres","res://data/config/outskirts_native_adoption.json"]
	for path: String in CORE.NATIVE_NPC_PINS: result.append(path)
	for id: String in ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]:
		result.append("res://data/scenes/"+id+".tres")
		result.append("res://data/scenes/luoyang_enclosure_v11_candidates/"+id+".tres")
		result.append("res://data/maps/luoyang_enclosure_v11_candidates/"+id+"_layout.tres")
	return result

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failed+=1
		push_error("CURRENT_RUNTIME_BINDING_UNIT_FAIL: "+label)
func _file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false,"bytes":0,"sha256":"ABSENT","mtime":0}
	var file := FileAccess.open(path,FileAccess.READ)
	var count: int=file.get_length() if file!=null else -1
	if file!=null: file.close()
	return {"exists":true,"bytes":count,"sha256":FileAccess.get_sha256(path),"mtime":FileAccess.get_modified_time(path)}
func _track(path: String) -> void:
	if sources.has(path): return
	sources[path]=true
	_check(FileAccess.file_exists(path),"required source exists "+path)
	if not FileAccess.file_exists(path) or path.get_extension()!="gd": return
	var regex := RegEx.new()
	_check(regex.compile("(res://[^\"'\\r\\n]+[.]gd)(?=[\"'\\r\\n])")==OK,"literal script closure")
	for reference: RegExMatch in regex.search_all(FileAccess.get_file_as_string(path)): _track(reference.get_string(1))
func _snapshot() -> Dictionary:
	var result: Dictionary={}
	for path: String in sources: result[path]=_file(path)
	return result
func _players() -> Dictionary:
	var result: Dictionary={}
	for index in 5:
		for suffix: String in ["",".bak",".tmp"]: result["user://save_%d.json%s"%[index,suffix]]=_file("user://save_%d.json%s"%[index,suffix])
	return result
func _case(runtime: Variant,base: Variant,native: Variant,pins: Variant,expect: bool,label: String) -> void:
	var reason: String=CORE.runtime_identity_error(runtime,base,native,pins)
	rows.append({"label":label,"expected":expect,"accepted":reason.is_empty(),"reason":reason})
	_check(reason.is_empty()==expect,label)

func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	_check(bridge!=null and bridge.call("is_checkpoint_saves_suspended")==false,"public checkpoint default false")
	if bridge==null: quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"checkpoint suspended before any await")
	for path: String in fixture_sources(): _track(path)
	_check(FileAccess.get_sha256(CORE_PATH)==CORE_SHA,"NEW direct predicate SHA")
	_check(FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA and AudioServer.get_driver_name()=="WASAPI","actual installed engine/WASAPI")
	var first: Dictionary=_snapshot()
	var players: Dictionary=_players()
	var saver: Node=root.get_node("SaveManager")
	var slot: Variant=saver.get("active_slot")
	var pins: Dictionary={}
	for path: String in CORE.NATIVE_NPC_PINS: pins[path]=FileAccess.get_sha256(path)
	var runtime: Script=RUNTIME
	var base: Script=runtime.get_base_script()
	var native: Script=base.get_base_script()
	_case(runtime,base,native,pins,true,"actual runtime Script/direct base/native base/current source")
	for invalid: Variant in [null,false,1,"runtime",{},[]]:
		_case(invalid,base,native,pins,false,"runtime wrong type "+str(typeof(invalid)))
		_case(runtime,invalid,native,pins,false,"base wrong type "+str(typeof(invalid)))
		_case(runtime,base,invalid,pins,false,"native wrong type "+str(typeof(invalid)))
		_case(runtime,base,native,invalid,false,"source table wrong type "+str(typeof(invalid)))
	_case(native,base,native,pins,false,"old F926 runtime identity")
	_case(base,base,native,pins,false,"preview BB5D is not Field runtime")
	_case(runtime,native,native,pins,false,"wrong direct base identity")
	_case(runtime,base,base,pins,false,"wrong native base identity")
	var owned_script := GDScript.new()
	owned_script.source_code="extends RefCounted\n"
	_case(owned_script,base,native,pins,false,"owned unrelated Script blank path; never changes cached scripts")
	for path: String in CORE.NATIVE_NPC_PINS:
		var bad: Dictionary=pins.duplicate(true)
		bad.erase(path); _case(runtime,base,native,bad,false,"missing source "+path)
		bad=pins.duplicate(true);bad[path]="0".repeat(64);_case(runtime,base,native,bad,false,"wrong source SHA "+path)
		for alias: Variant in [null,true,1,[pins[path]]]:
			bad=pins.duplicate(true);bad[path]=alias;_case(runtime,base,native,bad,false,"typed SHA alias "+path+"/"+str(typeof(alias)))
	var bad: Dictionary=pins.duplicate(true)
	bad["res://scripts/field/field_walkable_controller.gd"]="1eb104fa0e321f7d4c361996639ae882340ec029ce5aed14e17b2d6a711dd740"
	_case(runtime,base,native,bad,false,"old Field source")
	# A separately owned table preserves actual StringName key types.
	var typed_key_bad: Dictionary={}
	for key: String in pins: typed_key_bad[StringName(key)]=pins[key]
	_case(runtime,base,native,typed_key_bad,false,"text-equivalent StringName source keys")
	bad=pins.duplicate(true);bad["unexpected"]="0".repeat(64)
	_case(runtime,base,native,bad,false,"extra source key")
	owned_script=null
	for frame in 2: await process_frame
	_check(first==_snapshot(),"all consumed sources unchanged")
	_check(players==_players() and saver.get("active_slot")==slot,"normal15files/slot unchanged")
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"checkpoint held through quit")
	_check(AudioServer.get_driver_name()=="WASAPI" and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"engine/audio end identity")
	var output: String="res://build/joint_world_luoyang_20261003_qa/fade_current_runtime_binding_units_%d_%d/"%[Time.get_unix_time_from_system(),OS.get_process_id()]
	_check(not DirAccess.dir_exists_absolute(output),"unique unit output")
	_check(DirAccess.make_dir_recursive_absolute(output)==OK,"create unit result")
	var report: Dictionary={"scope":"DIRECT_CURRENT_RUNTIME_SOURCE_BINDINGS_NOT_FIELD_OR_SIX","checks":checks,"failures":failed,"complete":failed==0,"rows":rows,"source_before":first,"source_after":_snapshot(),"players_before":players,"players_after":_players(),"active_slot_before":slot,"active_slot_after":saver.get("active_slot"),"audio_driver":AudioServer.get_driver_name(),"engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"checkpoint_suspended_before_await":true,"Field_tested":false,"geometry_tested":false,"approval":false}
	var file := FileAccess.open(output+"result.json",FileAccess.WRITE)
	_check(file!=null,"write result")
	if file!=null: file.store_string(JSON.stringify(report,"\t",true));file.close()
	var parser := JSON.new()
	_check(parser.parse(FileAccess.get_file_as_string(output+"result.json"))==OK,"result readback")
	print("FADE_CURRENT_BINDING_UNITS ",output," ",checks,"/",failed)
	quit(0 if failed==0 else 1)

