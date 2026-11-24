extends "res://tests/test_luoyang_city_life_gpu_key_retry2_20261016f.gd"
## Exactly one real world entrance -> Gate. Not direct isolated city birth or warm lease.
const ENTRY_READY=false
const ENTRY_WHOLE_MS=120000
const ENTRY_ARRIVAL_MS=60000
const WORLD_ID="world_map_jianghu"
const WORLD_RAW=preload("res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd")
const GATE=preload("res://scripts/city/luoyang_gate_fortification_contract_20261013.gd")
const FINAL_SOURCE_PINS={}
var arrival_observations: Array[Dictionary]=[]
func precheck() -> bool:
	if not check(ENTRY_READY and not FINAL_SOURCE_PINS.is_empty(),"Draft refuses until exact approved import/strict helper/consumer sources frozen"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0,"Real GPU/native clock"): return false
	for argument: String in OS.get_cmdline_user_args():
		if not check(not argument.contains("candidate") and argument!="--luoyang-live-city-lease-20261016g","No candidate or warm flags"): return false
	for path: String in FINAL_SOURCE_PINS:
		if not track(path,FINAL_SOURCE_PINS[path]): return false
	if not track(R.BIND_PATH,FINAL_BIND_SHA): return false
	package=R.binding();author=R.author(package)
	if not check(R.cpu_proof_valid(package,author),"Existing district CPU geometry reused; no old city rebuild"): return false
	for path: String in R.source_paths():
		if not source_before.has(path) and not track(path,FileAccess.get_sha256(path)): return false
	for path: String in [get_script().resource_path,"res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd","res://data/scenes/world_map_jianghu.tres"]:
		if not track(path,FileAccess.get_sha256(path)): return false
	return true
func _segment(a: Vector2,b: Vector2) -> Dictionary:
	if scene!=null and String(scene.scene_id)==WORLD_ID: return oracle.segment_evidence(a,b)
	return super._segment(a,b)
func _walk(points: PackedVector2Array) -> bool:
	var result: Dictionary=await driver.follow(field,points,_clear,_segment)
	records.append({"kind":"NORMAL_INPUT","source_scene_id":String(scene.scene_id),"result":result})
	return check(result.ok,"Normal INPUT with actual world radius5/17 or Gate34x24/87517 and nativePhysics",result)
func _busy() -> bool:
	var lm: Node=root.get_node("LoadingManager");var state: Dictionary=C.transition_validation_state()
	if lm.get("_transition_active")==true or lm.get("_external_active")==true or root.get_node("SceneRouter").get("_portal_preparing")==true: return true
	for key: String in ["active","source_worker_active","navigation_worker_active","base_cpu_worker_active","module_worker_active","revision_worker_active","BASE_live_active"]:
		if state.get(key,false)==true: return true
	var metrics: Dictionary=lm.call("get_field_preload_metrics")
	return int(metrics.get("active_requests",0))>0 or int(metrics.get("draining_requests",0))>0
func _observe(target: String,label: String,started: int) -> void:
	var lm: Node=root.get_node("LoadingManager")
	var current: SceneScript=current_scene.get("_current_scene") as SceneScript if is_instance_valid(current_scene) and current_scene.has_method("get_field_loading_state") else null
	arrival_observations.append({"target":target,"label":label,"elapsed_ms":Time.get_ticks_msec()-started,"process_frame":Engine.get_process_frames(),"actual_scene_id":String(current.scene_id) if current!=null else "NONE","actual_Field_id":current_scene.get_instance_id() if is_instance_valid(current_scene) else 0,"C_errors":C.errors(),"C_state":C.transition_validation_state(),"Loading_external_active":lm.get("_external_active"),"Loading_transition_active":lm.get("_transition_active"),"Loading_owner_token":lm.get("_external_token"),"Loading_metrics":lm.call("get_field_preload_metrics"),"portal_preparing":root.get_node("SceneRouter").get("_portal_preparing"),"Field_ready":current_scene.call("get_field_loading_state") if current!=null else {}})
	var output:=FileAccess.open(folder.path_join("arrival_observations.json"),FileAccess.WRITE)
	if output!=null: output.store_string(JSON.stringify(arrival_observations,"\t"));output.close()
func _wait_once(target: String,source_id: String="") -> bool:
	var started:=Time.get_ticks_msec();var until:=mini(deadline,started+ENTRY_ARRIVAL_MS)
	var seen_busy:=false;var previous: String=""
	while Time.get_ticks_msec()<until:
		await process_frame
		var busy: bool=_busy();seen_busy=seen_busy or busy
		var candidate: SceneScript=current_scene.get("_current_scene") as SceneScript if is_instance_valid(current_scene) and current_scene.has_method("get_field_loading_state") else null
		var state: Dictionary=current_scene.call("get_field_loading_state") if candidate!=null else {}
		var signature:=str(busy)+"|"+(String(candidate.scene_id) if candidate!=null else "NONE")+"|"+str(state)+"|"+str(C.errors())
		if signature!=previous: _observe(target,"STATE",started);previous=signature
		if busy: continue
		if candidate!=null and String(candidate.scene_id)==source_id and not source_id.is_empty() and (seen_busy or not C.errors().is_empty()):
			_observe(target,"FINISHED_IDLE_ROLLBACK_TO_SOURCE",started)
			return check(false,"Real Space destination rejected/returned to source only after ALL owners/workers idle",arrival_observations[-1])
		if candidate==null or String(candidate.scene_id)!=target: continue
		if state.get("failed",false): _observe(target,"FIELD_FAILED",started);return check(false,"Actual destination Field failed",state)
		var player: CharacterBody2D=current_scene.get("_player") as CharacterBody2D
		var loading: Node=root.get_node("LoadingManager").get("_screen")
		var panel: Control=loading.get("root") as Control if is_instance_valid(loading) else null
		if not state.get("complete",false) or player==null or not player.is_inside_tree() or not player.get("can_move") or (panel!=null and panel.is_visible_in_tree()): continue
		field=current_scene;scene=candidate
		if C.owns_id(candidate.scene_id):
			var proof: Dictionary=C.resident_receipt(candidate)
			if not check(proof.get("sources_finalized",false) and not proof.get("sources",{}).is_empty(),"Gate own full source first/final owner, not Loading-only ready"): return false
			records.append({"kind":"ACTUAL_GATE_FULL_SOURCE_PROOF","proof":proof})
		_observe(target,"HIDDEN_OPERABLE_READY",started);return true
	_observe(target,"FIXED_60_OR_SHARED120_DEADLINE",started)
	return check(false,"Fixed60s arrival/shared120s, no extension",arrival_observations[-1])
func _exercise() -> bool:
	var world_definition: SceneScript=ResourceLoader.load("res://data/scenes/world_map_jianghu.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not check(world_definition!=null,"Immutable original world definition"): return false
	var portals: Array=[]
	for row: Dictionary in world_definition.map_layout.portals:
		if row.get("target_scene")=="ch4_s0_luoyang_gate": portals.append(row)
	if not check(portals.size()==1,"Original unique world Luoyang portal"): return false
	var entry: Vector2=portals[0].pos*Vector2(12288,8192);var setup:=entry+Vector2(0,96)
	var accepted: bool=root.get_node("SceneRouter").call("go_field_smart",StringName(WORLD_ID),setup/Vector2(12288,8192),"",15)
	records.append({"kind":"PUBLIC_LEGAL_WORLD_NEAR_SETUP_NOT_LONG_TRAVEL","accepted":accepted,"entry":entry,"setup":setup})
	if not check(accepted,"Legal original world entry-near return-context setup") or not await _wait_once(WORLD_ID): return false
	oracle=WORLD_RAW.new()
	var shape: CollisionShape2D=field.get("_player").get_node("CollisionShape2D")
	if not check(shape.shape is CircleShape2D and (shape.shape as CircleShape2D).radius==5.0 and shape.position==Vector2.ZERO and oracle.configure(scene.map_layout) and _clear(field.get("_player").position),"World actual radius5/native17+Physics, no city-body substitution"): return false
	if not await _walk(PackedVector2Array([field.get("_player").position,entry])): return false
	var zones: Array=[]
	for zone: Node in field.get("_exit_nodes"):
		if String(zone.get("target_scene_id"))=="ch4_s0_luoyang_gate": zones.append(zone)
	if not check(zones.size()==1 and zones[0].get("_in_range")==true and not zones[0].get("is_locked"),"Real unlocked world portal overlap after normal96px INPUT"): return false
	var started:=Time.get_ticks_msec();await driver.key(KEY_SPACE)
	if not await _wait_once("ch4_s0_luoyang_gate",WORLD_ID): return false
	records.append({"kind":"REAL_WORLD_SPACE_GATE_READY","elapsed_ms":Time.get_ticks_msec()-started,"direct_city_go_field_used":false})
	oracle=null;district="gate";scene_id="ch4_s0_luoyang_gate"
	if not _bind_actual() or not check(GATE.bound(scene),"Current actual Gate metadata and full87517/native34x24/Physics"): return false
	var player: CharacterBody2D=field.get("_player");var target:=player.position+Vector2(32,0)
	return await _walk(PackedVector2Array([player.position,target])) and await _capture("real_world_space_gate_ready")
func _run() -> void:
	var began:=Time.get_ticks_msec();deadline=began+ENTRY_WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/world_gate_stable_import_entry_20261017/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete:=false
	if precheck():
		driver=INPUT.new();driver.configure(self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		complete=await _exercise()
		if not await _leave_actual_field(): complete=false
		root.get_node("SceneRouter").call("reset_for_new_game");await process_frame;await process_frame
	if driver!=null: driver.release();driver=null
	field=null;scene=null;oracle=null;frame_images.clear()
	records.append({"kind":"SCOPE","whole_ms":ENTRY_WHOLE_MS,"arrival_ms":ENTRY_ARRIVAL_MS,"captures":captures,"native_queries":native_queries,"world_long_travel_or_warm_or_rooms":false})
	finish(folder,began,complete,"ONLY_ACTUAL_WORLD96INPUT_SPACE_GATE32INPUT_NOT_ISOLATED_CITY_BIRTH")
