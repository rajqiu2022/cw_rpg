extends "res://tests/test_luoyang_city_life_gpu_key_retry2_20261016f.gd"
## Prepared ordinary-only smoke; correct E825 actual Field teardown is inherited.
const ORDINARY_READY=false
const TRUE_RUNTIME_SHA="PENDING_ROOT_SOLE_BOOL_TRUE_SHA"
const FALSE_SOURCE_BACKUP="PENDING_ROOT_EXACT_FALSE_SOURCE_BACKUP"
const EVIDENCE={
	"gate":["res://build/luoyang_city_life_gpu_20261016f/gate/98148_2458/result.json","40fec6dc40515c1f8584c160f23ac0a1c2d6f8aa05bc8bdbfd9b0fb9a6b8a8be",true],
	"docks":["res://build/luoyang_city_life_gpu_20261016f/docks/83680_2537/result.json","bc8ca55bf6ad5f29aed4de8ee55ec756b0b48074e9f7641c68db61303b101b59",true],
	"yamen":["res://build/luoyang_city_life_gpu_20261016f/yamen/54944_2426/result.json","3fe94b76b54ad01048ae955533e999949f182238f3a92df417e875d32dd6a890",true],
	"market_partial":["res://build/luoyang_city_life_gpu_20261016f/market/110080_2548/result.json","809be9fda30217c687ae17f77a91b77fe1c9a347af46be82e0d54c3ce4bb4f34",false],
	"market_teardown":["PENDING_ACTUAL_MARKET_TEARDOWN_RESULT","PENDING_ACTUAL_MARKET_TEARDOWN_SHA",true]
}
func precheck() -> bool:
	if not check(ORDINARY_READY and R.FORMAL_ENABLED and R.FLAG not in OS.get_cmdline_user_args(),"Ordinary default smoke not enabled until actual candidate accepted"): return false
	if not track("res://tests/test_luoyang_city_life_gpu_key_retry2_20261016f.gd","e8254a46de3e82475b13b8f7fd431e2f57e6dd9b4f753a2951f01df75c84b41c") or not track("res://tests/test_luoyang_city_life_cpu_key_retry2_20261016f.gd","00ed4cd77ede1a470470726bcba60c2b5fe3099c11218e74d1b708ec3b9cef93"): return false
	for key: String in EVIDENCE:
		var expected: Array=EVIDENCE[key]
		if not track(expected[0],expected[1]): return false
		var result: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(expected[0]))
		if not check(result.complete==expected[2] and result.failures==(0 if expected[2] else 10),"Exact limited candidate evidence; partial Market remains FAIL "+key): return false
	if not track(R.SELF,TRUE_RUNTIME_SHA) or not track(FALSE_SOURCE_BACKUP,FINAL_RUNTIME_SHA): return false
	var old:=FileAccess.get_file_as_string(FALSE_SOURCE_BACKUP)
	if not check(old.count("const FORMAL_ENABLED=false")==1 and old.replace("const FORMAL_ENABLED=false","const FORMAL_ENABLED=true")==FileAccess.get_file_as_string(R.SELF),"Exactly one ROOT formal bool, no source exemptions"): return false
	if not track(R.BIND_PATH,FINAL_BIND_SHA): return false
	package=R.binding(); author=R.author(package)
	if not check(R.cpu_proof_valid(package,author),"Unchanged actual full source-bound CPU publication"): return false
	for path: String in package.source_sha256:
		if not track(path,package.source_sha256[path]): return false
	for path: String in R.source_paths():
		if not source_before.has(path) and not track(path,FileAccess.get_sha256(path)): return false
	return track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path))
func _exercise() -> bool:
	var start:=Time.get_ticks_msec()
	var accepted: bool=root.get_node("SceneRouter").call("go_field_smart",StringName(scene_id),null,"",-1,C.VERSION)
	records.append({"kind":"ORDINARY_DEFAULT_BIRTH","accepted":accepted,"public_call_ms":Time.get_ticks_msec()-start,"default_spawn_not_near_setup":true})
	if not check(accepted,"No candidate flag public actual default entry") or not await _wait() or not _bind_actual(): return false
	var player:=field.get("_player") as CharacterBody2D
	var end:=player.position+Vector2(32,0)
	if _segment(player.position,end).get("clear",false) and _clear(end):
		if not await _walk(PackedVector2Array([player.position,end])): return false
	else:
		for i: int in 3:
			await physics_frame
			if not check(_clear(player.position),"Default real nativePhysics; right32 blocked is not falsely called walked"): return false
		records.append({"kind":"BIRTH_PHYSICS_ONLY","normal32_input_not_claimed":true})
	return await _capture("ordinary_"+district+"_default_birth")
