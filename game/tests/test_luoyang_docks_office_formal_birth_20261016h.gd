extends "res://tests/test_luoyang_docks_office_field_key_retry2_20261016h.gd"
## Ordinary default entry only; candidate's geometry/27 entries/two native role details are reused.
const FORMAL_HELPER_SHA="627920a95b7352f2913d074df38a9ad6de1afcd9da0ae73d81477f6e03662f6e"
const FALSE_HELPER="res://build/luoyang_docks_office_20261016h_root01/office_helper_before_formal_0AE49505.source"
const CANDIDATE_RESULT="res://build/luoyang_docks_office_actual_field_20261016h/100808_2551/result.json"
const CANDIDATE_RESULT_SHA="f297e026a65cfd18250ef50ea526966ab48980d3c240d83e0ac3af35bb1eed47"
const PARENT_KEY="res://tests/test_luoyang_docks_office_field_key_retry2_20261016h.gd"
const PARENT_KEY_SHA="73609073225bb9944991eccb782a8930db1426e5746d6f5859002917ddaae5e0"
func precheck() -> bool:
	if not check(M.FORMAL_ENABLED and M.FLAG not in OS.get_cmdline_user_args(),"Ordinary entry with no h candidate flag"): return false
	if not track(CANDIDATE_RESULT,CANDIDATE_RESULT_SHA) or not track(PARENT_KEY,PARENT_KEY_SHA) or not track(FALSE_HELPER,FIXED[M.SELF]): return false
	var candidate: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE_RESULT))
	if not check(candidate.complete and candidate.failures==0,"Actual382-check candidate accepted, not failed26584"): return false
	var old: String=FileAccess.get_file_as_string(FALSE_HELPER)
	if not check(old.count("const FORMAL_ENABLED := false")==1 and old.replace("const FORMAL_ENABLED := false","const FORMAL_ENABLED := true")==FileAccess.get_file_as_string(M.SELF),"Exactly ROOT single formal bool edit, complete source comparison"): return false
	for path: String in FIXED:
		if not track(path,FORMAL_HELPER_SHA if path==M.SELF else FIXED[path]): return false
	office_author=M.author()
	if not check(not office_author.is_empty(),"Exact unchanged h author"): return false
	for path: String in office_author.source_sha256:
		if not track(path,office_author.source_sha256[path]): return false
	if not track(R.BIND_PATH,FINAL_BIND_SHA): return false
	package=R.binding();author=R.author(package)
	if not check(R.cpu_proof_valid(package,author),"Existing district publication reused; no full CPU/import rerun"): return false
	for path: String in R.source_paths():
		if not source_before.has(path) and not track(path,FileAccess.get_sha256(path)): return false
	return track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path))
func _office_actual() -> bool:
	var proof: Dictionary=C.resident_receipt(scene)
	var required: Dictionary=office_author.source_sha256.duplicate(true)
	required[M.SELF]=FORMAL_HELPER_SHA;required[M.AUTHOR_PATH]=M.AUTHOR_SHA
	if not check(proof.get("sources_finalized",false),"Actual current owner completed full source first/final validation"): return false
	for path: String in required:
		if not check(proof.get("sources",{}).has(path) and proof.sources[path]==required[path],"Ordinary h finalized complete source closure "+path): return false
	var sprite: Sprite2D=_prop(M.BUILDING)
	if not check(scene.get_meta(M.META,"")==M.AUTHOR_SHA and H.bound(scene) and sprite!=null and sprite.texture.resource_path==office_author.office.texture,"Ordinary actual h metadata and office Texture2D"): return false
	var observed: Dictionary={}
	for npc: Node2D in field.get("_npc_nodes"):
		var id: String=String(npc.get("npc_id"))
		if id not in M.ROLE_IDS: continue
		if not check(not observed.has(id) and npc.get("sprite_path")==office_author.roles[id].texture and (npc.get("sprite") as Sprite2D).texture.resource_path==office_author.roles[id].texture,"Ordinary exact profession node texture "+id): return false
		observed[id]=npc.get_instance_id();crowd_refs.append(weakref(npc))
	records.append({"kind":"ORDINARY_DEFAULT_OFFICE_ROLES_WIRING","office_texture":sprite.texture.resource_path,"npc_instances":observed,"candidate_nativebody_alpha_and27_storage_evidence_reused":CANDIDATE_RESULT})
	return check(observed.size()==2,"Ordinary two unique profession nodes, no repeated local/detail test")
func _exercise() -> bool:
	var start:=Time.get_ticks_msec()
	var accepted: bool=root.get_node("SceneRouter").call("go_field_smart",StringName(scene_id),null,"",-1,C.VERSION)
	records.append({"kind":"ORDINARY_PUBLIC_DEFAULT_DOCKS_BIRTH","accepted":accepted,"public_call_ms":Time.get_ticks_msec()-start,"no_near_spawn_setup":true})
	if not check(accepted,"No candidate flag public default-null entry") or not await _wait() or not _bind_actual() or not _office_actual(): return false
	return await _capture("ordinary_default_docks_office_roles")
func _run() -> void:
	var began:=Time.get_ticks_msec();deadline=began+SHARED_MS;district="docks";scene_id="ch4_s2_canal_docks"
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_docks_office_formal_birth_20261016h/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete:=false
	if precheck():
		driver=INPUT.new();driver.configure(self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		complete=await _exercise()
		if not await _leave_actual_field(): complete=false
		root.get_node("SceneRouter").call("reset_for_new_game");await process_frame;await process_frame
	if driver!=null: driver.release();driver=null
	field=null;scene=null;oracle=null;frame_images.clear()
	for reference: WeakRef in crowd_refs: check(reference.get_ref()==null,"Own ordinary two profession nodes released with Field")
	records.append({"kind":"ORDINARY_SCOPE","shared_ms":SHARED_MS,"arrival_ms":ARRIVAL_MS,"captures":captures,"native_queries":native_queries,"repeated_candidate27_or_roles_detail_or32input":false})
	finish(folder,began,complete,"ORDINARY_H_DEFAULT_BIRTH_ONLY_NOT_WARM_OR_ELEVEN_ROOMS")
