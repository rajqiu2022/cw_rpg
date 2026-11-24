extends "res://tests/test_luoyang_temple_assembly_gpu_key_20261016.gd"
## Preserve16808 station PASS and overall FAIL. Two original exits only, no station replay.
const STATION_RESULT="res://build/luoyang_temple_assembly_gpu_20261016/16808_2451/result.json"
const STATION_SHA="eacdf0232c9ad750768ef4c51601f3a55a25e5a470bffb2503abd1e275acfb60"
func _exercise_exits() -> bool:
	var accepted: bool=root.get_node("SceneRouter").call("go_field_smart",A.ID,null,"",-1,-1)
	if not check(accepted,"One actual public temple entry, no city trips") or not await wait_arrival(): return false
	# These are existing authored corridor waypoints. Exact final positions come
	# only from original immutable portal UV * actual WORLD, as Field computes.
	if not await walk([[650,860],[337.92,860]]): return false
	var original:=A.original_scene()
	var portals: Array=A.legacy_portals(original)
	for target: String in ["ch4_s2_canal_docks","ch4_s3_luoyang_market"]:
		var expected: Dictionary={}
		for item: Dictionary in portals:
			if String(item.target_scene)==target: expected=item
		if not check(not expected.is_empty(),"Immutable canonical portal target exists"): return false
		var uv: Vector2=expected.pos
		var exact: Vector2=uv*WORLD
		if target=="ch4_s3_luoyang_market" and not await walk([[337.92,860],[153.6,860]]): return false
		var player:=field.get("_player") as CharacterBody2D
		var path:=PackedVector2Array([player.position,exact])
		var movement: Dictionary=await driver.follow(field,path,actual_clear,segment)
		if not check(movement.ok,"Actual INPUT to canonical UV-domain native exit; full geometry/Physics",movement): return false
		await driver.completed_actor_stage()
		var found:=false
		for node: Node in (field.get("_portal_layer") as Node).get_children():
			var zone:=node as ExitZone
			if zone==null or zone.target_scene_id!=target: continue
			found=true
			var ready: bool=zone.position==exact and zone.target_spawn_pos==expected.target_pos and not zone.is_locked and not zone.auto_trigger and bool(zone.get("_in_range")) and zone.get_overlapping_bodies().has(player) and actual_clear(player.position)
			rows.append({"kind":"EXACT_CANONICAL_NATIVE_EXIT","target":target,"source_uv":uv,"expected_native_world":exact,"actual_native_world":zone.position,"can_enter_predicate":ready,"normal_input":movement,"no_activation_no_city_trip":true})
			if not check(ready,"Same original UV/native transform exact, actual area + unlocked + Physics"): return false
		if not check(found,"Both original exits remain instantiated") or not await capture("exit_"+target): return false
	return true
func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+60000
	output="res://build/luoyang_temple_assembly_exit_only_20261016/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true); players=saves()
	var complete:=false
	if precheck() and track("res://tests/test_luoyang_temple_assembly_gpu_key_20261016.gd","71df21799e772eb1c4e9c4e7ced7d22a2eba6f353addfb2e9eb5d47eeabde474") and track(CPU_RESULT,CPU_SHA) and track(STATION_RESULT,STATION_SHA) and track("res://tests/helpers/v15_input_driver.gd","a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7"):
		var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(STATION_RESULT))
		var count:=0
		for row: Dictionary in previous.records:
			if row.get("kind")=="ACTUAL_STATION": count+=1
		if check(not previous.complete and previous.failures==2 and count==7,"Original failure preserved; reuse seven actual station rows only, not overall PASS"):
			driver=INPUT.new(); driver.configure(self)
			for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
			complete=await _exercise_exits()
			root.get_node("SceneRouter").call("reset_for_new_game")
			await process_frame; await process_frame
	if driver!=null: driver.release(); driver=null
	field=null; child=null; geometry=null
	rows.append({"kind":"EXIT_ONLY_SCOPE","shared_ms":60000,"arrival_ms":45000,"captures":captures,"native_queries":native_queries,"station_evidence":STATION_RESULT,"original_failure_preserved":true})
	finish("luoyang_temple_assembly_exit_only_20261016",began,complete)
