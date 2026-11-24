extends "res://tests/test_luoyang_city_life_gpu_prepared_20261016f.gd"
## Draft ordinary-only smoke; final child switches to frozen actual GPU utility.
const ORDINARY_READY=false
const TRUE_RUNTIME_SHA="PENDING_ROOT_SOLE_BOOL_TRUE_SHA"
const FALSE_SOURCE_BACKUP="PENDING_ROOT_EXACT_FALSE_SOURCE_BACKUP"
func precheck() -> bool:
	if not check(ORDINARY_READY and R.FORMAL_ENABLED and R.FLAG not in OS.get_cmdline_user_args(),"Ordinary default smoke not enabled until actual candidate accepted"): return false
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
