extends "res://tests/test_luoyang_city_life_gpu_key_retry2_20261016f.gd"
## Market cleanup only. Preserve110080 overall FAIL; do not replay its crowd/overview/portal.
const OLD_MARKET_RESULT="res://build/luoyang_city_life_gpu_20261016f/market/110080_2548/result.json"
const OLD_MARKET_SHA="809be9fda30217c687ae17f77a91b77fe1c9a347af46be82e0d54c3ce4bb4f34"
const OLD_STDERR="res://build/luoyang_district_life_20261016f_root01/market_gpu_stderr.log"
const OLD_STDERR_SHA="26af1b403818cab34d0578b4ed1a6cf8431309e425384b6b9299d3606f625b11"
func precheck() -> bool:
	if not super.precheck() or not track(OLD_MARKET_RESULT,OLD_MARKET_SHA) or not track(OLD_STDERR,OLD_STDERR_SHA): return false
	var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OLD_MARKET_RESULT))
	var log:=FileAccess.get_file_as_string(OLD_STDERR)
	if not check(district=="market" and not old.complete and old.failures==10 and log.count("CITY_LIFE_QA_FAIL Actual new crowd released with Field reset")==10 and log.count("CITY_LIFE_QA_FAIL")==10,"Only old teardown assertion failed; original FAIL remains immutable"): return false
	records.append({"kind":"REUSED_MARKET_PARTIAL_NOT_WHOLE_PASS","result":OLD_MARKET_RESULT,"result_sha256":OLD_MARKET_SHA,"original_whole_pass":false,"reuse":"actual ready/new10/4x8walk/Physics/overview/INPUT/portal; no replay"})
	return true
func _exercise() -> bool:
	var start:=Time.get_ticks_msec()
	var accepted: bool=root.get_node("SceneRouter").call("go_field_smart",StringName(scene_id),Vector2(1536,1924)/Vector2(3072,2048),"",-1,C.VERSION)
	if not check(accepted,"One actual Market entry for teardown only") or not await _wait() or not _bind_actual(): return false
	for npc: Node2D in field.get("_npc_nodes"):
		if String(npc.get("npc_id")).begins_with("district_life_"): crowd_refs.append(weakref(npc))
	return check(crowd_refs.size()==10,"Ten actual new children await real Field tree_exit; not dictionary count",{"setup_ms":Time.get_ticks_msec()-start})
