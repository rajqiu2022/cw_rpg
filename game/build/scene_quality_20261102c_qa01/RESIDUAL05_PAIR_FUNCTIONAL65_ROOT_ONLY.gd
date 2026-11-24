extends "res://build/scene_quality_20261102c_qa01/RESIDUAL03_PAIR_ROOT_ONLY.gd"
## Functional diagnostic only after genuine cold readiness exceeded 35 seconds.
## Original 99776 / 34956 failures are retained; this cannot grant performance PASS.
## Original two real legs, exact feet, sources, loading/input/minimap guards stay.
var performance_limit_failed := false
var readiness_timings: Array[Dictionary] = []

func wait_field(id: String) -> Node:
	var started := Time.get_ticks_msec()
	var until := started + 65000
	var recorded_limit := false
	while Time.get_ticks_msec() < until and not done:
		await process_frame
		var elapsed: int = Time.get_ticks_msec() - started
		if elapsed > 35000 and not recorded_limit:
			recorded_limit = true
			performance_limit_failed = true
			records.append({"performance_limit_failed":true,"original_limit_ms":35000,"elapsed_ms":elapsed,"id":id,"actual_at_35s":diagnostic(),"functional_diagnostic_budget_only_ms":65000})
		var field: Node = current_scene
		var actual_id: String = physical(field)
		if (not actual_id.begins_with("world_map_jianghu") if id == "WORLD" else actual_id != id) or not field.has_method("get_field_loading_state"): continue
		var state: Dictionary = field.call("get_field_loading_state")
		if state.get("failed") == true:
			need(false, "FIELD_FAILED:" + id)
			return null
		var actor: Node = prop(field, "_player") as Node
		var screen: Node = loader.get("_screen") as Node
		if state.get("complete") != true or loader.get("_transition_active") == true or loader.get("_external_active") == true or (screen != null and screen.call("is_showing")) or actor == null or actor.get("can_move") != true: continue
		if id in pairs.call("area_ids"):
			var debug: Dictionary = nav.call("get_debug_state")
			if debug.get("attached_scene") != id or debug.get("mini_ok") != true or not debug.get("pending", {}).is_empty(): continue
		var ui: Dictionary = icons.call("get_debug_state")
		if ui.get("overlay", {}).get("markers", []).is_empty(): continue
		if id == "WORLD" and ui.get("overlay", {}).get("kind") != "WORLD": continue
		readiness_timings.append({"id":id,"elapsed_ms":Time.get_ticks_msec()-started,"original35s_limit_exceeded":recorded_limit})
		return field
	readiness_timings.append({"id":id,"elapsed_ms":Time.get_ticks_msec()-started,"functional65s_timeout":true,"original35s_limit_exceeded":recorded_limit})
	need(false, "65S_FUNCTIONAL_READY_ORIGINAL35S_PERFORMANCE_NOT_PASSED:" + id)
	return null

func finish() -> void:
	if done: return
	done = true
	for code: int in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE]:
		if Input.is_physical_key_pressed(code): key(code, false)
	var output: String = HOME + "actual/%d/" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(output)
	var file := FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"passed":errors.is_empty(),"functional_passed":errors.is_empty(),"performance_passed":false,"performance_limit_failed":performance_limit_failed,"performance_original_failures_retained":[34956,99776],"functional_readiness_budget_ms":65000,"original_readiness_budget_ms":35000,"readiness_timings":readiness_timings,"checks":checks,"errors":errors,"records":records,"input_events":inputs,"normal_images":images,"scope":"MOVED_DOCKS_GARDEN_PAIR_TWO_TRUE_LEGS_FUNCTIONAL65_ONLY_NOT_PERFORMANCE_ACCEPTANCE","public_near_not_continuous_world_travel":true,"private_actor_or_camera_writes":false,"real_save_contents_read":false,"save_API_calls":0,"old20_pair_directions_retested":false},"\t")+"\n")
		file.close()
	print("SCENE_QUALITY02C_PAIR_FUNCTIONAL65_RESULT ",checks," / ",errors.size()," performance_limit_failed=",performance_limit_failed," ",output)
	quit(0 if errors.is_empty() else 1)
