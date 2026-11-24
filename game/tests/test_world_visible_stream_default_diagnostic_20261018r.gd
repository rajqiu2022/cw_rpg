extends "res://tests/test_world_visible_stream_default_actual_20261018r.gd"
## Observation only: unchanged default/null spawn, first-draw observer,16px INPUT,
## complete independent world checks, one image and real exit/drain;90s/60s.
const DIAGNOSTIC_CORE="res://tests/fixtures/luoyang_loading_ordinary_final_core_20261018r.json"
const DIAGNOSTIC_CORE_SHA="54f70a6cbf84857d5183a87df5ef7e228fd20b50d6fc67781ca86e260ad46084"
const DIAGNOSTIC_PARENT="res://tests/test_world_visible_stream_default_actual_20261018r.gd"
const DIAGNOSTIC_PARENT_SHA="244d4f769dba6730d26c14416f3f90811d8748d31cb8c2fa1cf9ba4acd7e8e56"
const DIAGNOSTIC_PATCH="res://scripts/world/world_farmland_visual_patch_resolver_20261015.gd"
const DIAGNOSTIC_PATCH_SHA="4980866c5147eb173959dca506f84d9a7bc860a85ed4c7c41c5ba5abe6eba6de"
var diagnostic_patch_api: Variant

func precheck() -> bool:
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and OS.get_cmdline_user_args().is_empty(),"Ordinary default world diagnostic only, no candidate flags"): return false
	for pair: Array in [[DIAGNOSTIC_CORE,DIAGNOSTIC_CORE_SHA],[DIAGNOSTIC_PARENT,DIAGNOSTIC_PARENT_SHA],[DEFAULT_WORLD_BASE,DEFAULT_WORLD_BASE_SHA],[WORLD_TOOL_PATH,WORLD_TOOL_SHA],[DIAGNOSTIC_PATCH,DIAGNOSTIC_PATCH_SHA]]:
		if not track(pair[0],pair[1]): return false
	var core: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIAGNOSTIC_CORE))
	for path: String in core.source_sha256:
		if not track(path,core.source_sha256[path]): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	stream_api=load(STREAM_PATH)
	diagnostic_patch_api=load(DIAGNOSTIC_PATCH)
	return check(stream_api!=null and diagnostic_patch_api!=null,"Exact ordinary B468 index/17D LM closure; no runtime/source changes")

func _world_actual(label: String) -> bool:
	if not super._world_actual(label): return false
	# Only after the original immutable first-draw time AND complete world oracle.
	# These are diagnostic value snapshots, never used to fabricate loading time.
	var lm: Node=root.get_node("LoadingManager")
	var router: Node=root.get_node("SceneRouter")
	records.append({"kind":"WORLD_DEFAULT_POSTDRAW_LOADING_DIAGNOSTIC","label":label,"observed_usec":Time.get_ticks_usec(),"observed_frame":Engine.get_process_frames(),"first_draw_frozen":first_draw.duplicate(true),"LM_field_preload_metrics":lm.call("get_field_preload_metrics"),"Router_public_state":router.call("get_public_city_preparation_state"),"WORLD_VISUAL_PATCH_debug":diagnostic_patch_api.debug_state(),"stream_debug":field.call("get_world_v15_stream_debug"),"after_complete_original_world_oracle":true,"same_firstdraw_instrument":true,"observation_only_no_speedup_claim":true})
	return true
