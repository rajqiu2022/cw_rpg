extends SceneTree
## NEW delta-only draft. No old city publisher/test inheritance; ROOT alone runs Godot.
const SOURCE_READY=false
const RUNTIME_PATH="PENDING_SYSTEM_RUNTIME_PATH"
const RUNTIME_SHA="PENDING_SYSTEM_RUNTIME_SHA"
const BIND_PATH="PENDING_SYSTEM_BIND_PATH"
const BIND_SHA="PENDING_SYSTEM_BIND_SHA"
const CPU_LIMIT_MS=15000
var checks:=0
var failures:=0
var deadline:=0
var source_before: Dictionary={}
var players_before: Dictionary={}
var records: Array[Dictionary]=[]
var package: Dictionary={}
func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String,detail: Variant=null) -> bool:
	checks+=1
	if not ok: failures+=1; printerr("CITY_LIFE_QA_FAIL ",label," ",detail)
	return ok
func fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false,"sha256":"ABSENT","bytes":0,"mtime":0}
	var file:=FileAccess.open(path,FileAccess.READ)
	var count:=file.get_length(); file.close()
	return {"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":count,"mtime":FileAccess.get_modified_time(path)}
func saves() -> Dictionary:
	var result: Dictionary={}
	for slot: int in 5:
		for suffix: String in [".json",".json.bak",".json.tmp"]:
			var path:="user://save_"+str(slot)+suffix
			result[path]=fact(path)
	return result
func track(path: String,expected: String) -> bool:
	var current:=fact(path)
	if not check(current.exists and expected.length()==64 and current.sha256==expected.to_lower(),"Exact frozen source "+path): return false
	if source_before.has(path): return check(source_before[path]==current,"Duplicate source unchanged "+path)
	source_before[path]=current; return true
func precheck() -> bool:
	if not check(SOURCE_READY,"Draft refuses until SYSTEM freezes schema and source paths"): return false
	if not track(RUNTIME_PATH,RUNTIME_SHA) or not track(BIND_PATH,BIND_SHA): return false
	# Final implementation binds complete declared source closure, including
	# author/newPNG/import/ctex/geometry/C/Field/own QA helper. No proof backfill.
	return check(false,"Frozen API/schema not yet supplied; no inferred harbour receipt")
func exercise_cpu() -> bool:
	# Final scope: only new entity delta/combined polygons, all16 NPC lanes,
	# unchanged original routes/portal and room return approaches, two new
	# raw/import/directCTEX fullRGBA. Existing unchanged semantics are reused.
	# Same-base visual replacements must prove native base equality; otherwise
	# explicit physical delta is required. Never simply reuse old mask clearance.
	return check(false,"Await exact author/combinedgeometry/native transforms")
func finish(folder: String,began: int,complete: bool,scope: String) -> void:
	var source_after: Dictionary={}
	for path: String in source_before: source_after[path]=fact(path)
	var players_after:=saves()
	check(source_before==source_after,"Whole own source facts unchanged")
	check(players_before==players_after and root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"Own15 saves unchanged; no restoring player files")
	check(complete and Time.get_ticks_msec()<deadline,"Predeclared whole finite scope")
	DirAccess.make_dir_recursive_absolute(folder)
	var file:=FileAccess.open(folder.path_join("result.json"),FileAccess.WRITE)
	if file==null: failures+=1
	else:
		file.store_string(JSON.stringify({"scope":scope,"complete":complete and failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"records":records,"source_before":source_before,"source_after":source_after,"players_before":players_before,"players_after":players_after},"\t")); file.close()
	print("CITY_LIFE_QA_RESULT=",folder,"/result.json")
	quit(0 if complete and failures==0 else 1)
func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+CPU_LIMIT_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true); players_before=saves()
	var complete:=false
	if precheck(): complete=await exercise_cpu()
	finish("res://build/luoyang_city_life_cpu_20261016f/%d_%d"%[OS.get_process_id(),began],began,complete,"NEW_DELTA_ONLY_NO_FIELD_CREDIT")
