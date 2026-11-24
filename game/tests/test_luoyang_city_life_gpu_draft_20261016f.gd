extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## ONE parameter-selected district per process/deadline/result, never a four-city loop.
const GPU_READY=false
const SHARED_MS=90000
const ARRIVAL_MS=60000
const OBSERVATION_MS=4000
const INPUT_PATH="res://tests/helpers/v15_input_driver.gd"
const INPUT_SHA="a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7"
const DISTRICTS={"market":"ch4_s3_luoyang_market","yamen":"ch4_s1_luoyang_yamen","docks":"ch4_s2_canal_docks","gate":"ch4_s0_luoyang_gate"}
var district: String=""
var scene_id: String=""
var captures: Array[Dictionary]=[]
func district_argument() -> bool:
	var found:=0
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--district="):
			found+=1; district=argument.trim_prefix("--district=")
	if not check(found==1 and DISTRICTS.has(district),"Exactly one approved district parameter"): return false
	scene_id=String(DISTRICTS[district]); return true
func exercise_district() -> bool:
	# Freeze-specific final implementation must use public current-version3
	# near-foot setup once, then real ready/source-final/Loading hidden/can_move.
	# Overview: QA-only Camera2D center1536,1024/zoom.5, exactly restore camera
	# and follow state before INPUT. Never teleport player or change user options.
	# All new movers share ONE4s window; position/natural walk frames for all,
	# same-frame alpha foot<=12/depth/nativebody for two representatives.
	# Market10(4walk6stationary), Yamen6(2walk4stationary) require their own new
	# package receipt. Gate/Docks original20 ambient are preserved, not recounted
	# as new or falsely accessed through a Market/Yamen harbour receipt.
	# Then32-80px normal INPUT/full34x24/87517/continuous4px/nativePhysics and
	# one original portal native UV*world exact + true Area overlap/unlocked.
	# Do not activate portal, replay task story, enter room or retry after failure.
	return check(false,"Await frozen per-district API, safe authored approach and delta geometry")
func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+SHARED_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true); players_before=saves()
	var complete:=false
	if check(GPU_READY,"GPU draft not executable") and district_argument() and precheck() and track(INPUT_PATH,INPUT_SHA): complete=await exercise_district()
	records.append({"kind":"DECLARED_SCOPE","district":district,"scene_id":scene_id,"shared_ms":SHARED_MS,"arrival_ms":ARRIVAL_MS,"crowd_window_ms":OBSERVATION_MS,"captures":captures,"no_fullsix_temple_room_or_story_replay":true})
	finish("res://build/luoyang_city_life_gpu_20261016f/"+district+"/%d_%d"%[OS.get_process_id(),began],began,complete,"ONE_DISTRICT_ONLY")
