extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Parse only: no candidate instances, methods, Field, geometry or collector.
const PINNED := {
	"res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/yamen_loading_perf04/Bundle_same_call_bound_READY.gd":"77dfc4987f21fa280c526cf62cb6c94316a40c4236fb1005761408859a0b8c16",
	"res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/yamen_loading_perf04/District_scalar_timings_READY.gd":"39242c343d2e4981c2773b39fd79d84a451aab923a173a099eb8fb9b290acbe2",
	"res://build/luoyang_city_full_rollout_20261022ap_system01/hash_lanes8_epoch02/parallel_source_hash_lanes8_CANDIDATE.gd":"85a7b0b86ca201679b227b1f39c7315bb7196b4d0943befa5397ce569fe650e1",
	"res://scripts/city/luoyang_precomputed_bundle_20261018r.gd":"84d230215701757a5e52f6afadc9156df206e87375cbf71534248839366f19bc",
	"res://scripts/city/luoyang_district_life_20261016f.gd":"185b51ff7b9256657424ba0681660d6d335f890f6c919260b3f467384d03ac16",
	"res://scripts/city/luoyang_parallel_source_hash_20261017k.gd":"80261e1bf9b34400c6aa99959d98502b648589fccf2138231f3907d9826d8b0b",
	"res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd":"a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895",
	"res://build/luoyang_city_full_rollout_20261022ap_root01/performance04_candidate_admission_READY.json":"35a64923799596fc799a45d8c04c58ef14608dc7df242cadf1b0d7b60de595a6"
}
const CANDIDATES := [
	"res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/yamen_loading_perf04/Bundle_same_call_bound_READY.gd",
	"res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/yamen_loading_perf04/District_scalar_timings_READY.gd",
	"res://build/luoyang_city_full_rollout_20261022ap_system01/hash_lanes8_epoch02/parallel_source_hash_lanes8_CANDIDATE.gd"
]

func precheck() -> bool:
	if not check(OS.get_cmdline_user_args().is_empty() and DisplayServer.get_name()=="headless","Headless parse only, no CLI candidate activation"): return false
	for path: String in PINNED:
		if not track(path,PINNED[path]): return false
	return true

func exercise_cpu() -> bool:
	for path: String in CANDIDATES:
		var script: GDScript=ResourceLoader.load(path,"GDScript",ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		if not check(script!=null and script.resource_path==path and script.can_instantiate(),"Candidate parses and can instantiate without instantiating: "+path): return false
		var methods: Array=script.get_script_method_list()
		if path==CANDIDATES[0]:
			var count: int=0
			for method: Dictionary in methods:
				if method.name=="_finite_yamen_child_state_from_bound": count+=1
			if not check(count==1,"Exactly one private same-call helper declaration"): return false
		elif path==CANDIDATES[1]:
			var count: int=0
			for method: Dictionary in methods:
				if method.name=="loading_timing_state": count+=1
			if not check(count==1,"Exactly one independent timing getter declaration"): return false
		else:
			var constants: Dictionary=script.get_script_constant_map()
			if not check(constants.get("DEFAULT_WORKER_LIMIT")==8 and constants.get("ALLOWED_WORKER_LIMITS")==[1,2,4,8],"Parsed bounded8 constants"): return false
	return check(current_scene==null,"No Field or current Scene instantiated")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+15000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=false
	if precheck(): complete=exercise_cpu()
	finish("res://build/luoyang_city_full_rollout_20261022ap_root01/performance04_parse/%d_%d"%[OS.get_process_id(),began],began,complete,"THREE_CANDIDATES_PARSE_DECLARATIONS_ONLY_NO_INSTANCES_METHODS_FIELD_GEOMETRY_COLLECTOR")
