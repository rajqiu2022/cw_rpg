extends "res://tests/test_world_visible_stream_actual_20261018r.gd"
## Default world window, not the already-measured six-prop Gate-near window.
## Inherited90s/60s, same first-draw observer, full world assertions and exit.
const WORLD_DEFAULT_READY=true
const DEFAULT_CORE_PATH="res://tests/fixtures/luoyang_loading_candidate_final_core_20261018r.json"
const DEFAULT_CORE_SHA="f2070988417bc520526031c3bae56efb5f57031ef34c5fc36e4b2bf4a2ddb332"
const DEFAULT_WORLD_BASE="res://tests/test_world_visible_stream_actual_20261018r.gd"
const DEFAULT_WORLD_BASE_SHA="1162b2a744db778409d7f03348037c041582a55f129f237f42b9d5fca4ff579c"

func precheck() -> bool:
	if not check(WORLD_DEFAULT_READY and DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and OS.get_cmdline_user_args().is_empty(),"Ordinary default world only, no bundle/city flags"): return false
	if not track(DEFAULT_CORE_PATH,DEFAULT_CORE_SHA) or not track(DEFAULT_WORLD_BASE,DEFAULT_WORLD_BASE_SHA): return false
	var core: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DEFAULT_CORE_PATH))
	for path: String in core.source_sha256:
		if not track(path,core.source_sha256[path]): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	stream_api=load(STREAM_PATH)
	return check(stream_api!=null,"Actual default streamer/current final source closure, not old CAA5 snapshot")

func _exercise() -> bool:
	var router: Node=root.get_node("SceneRouter")
	_arm_draw(WORLD_ID,"WORLD_STREAM_ONLY_ORIGINAL_DEFAULT_NULL_SPAWN")
	if not check(router.call("go_field_smart",StringName(WORLD_ID),null,"",15),"Normal public world DEFAULT null spawn; no near-Gate substitute") or not await _wait_once(WORLD_ID) or not _world_bind(): return false
	var start: Vector2=field.get("_player").position
	var route:=PackedVector2Array()
	for offset: Vector2 in [Vector2(16,0),Vector2(-16,0),Vector2(0,16),Vector2(0,-16)]:
		var evidence: Dictionary=oracle.segment_evidence(start,start+offset)
		if evidence.get("clear",false): route=PackedVector2Array([start,start+offset]);break
	if not check(route.size()==2,"One finite legal16px cardinal INPUT from actual default spawn; no teleport/Gate-directed long route"): return false
	if not await _walk(route): return false
	records.append({"kind":"WORLD_DEFAULT_FIRST_WINDOW","actual_default_spawn":start,"first_draw":first_draw.duplicate(true),"physical_query_count":native_queries,"near_Gate_previous_evidence_not_reused_for_default_window":true,"same_R_timing_instrument":true})
	return await _capture("ordinary_world_DEFAULT_stream_window_NOT_GATE_NEAR")
