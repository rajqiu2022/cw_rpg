extends "res://tests/test_world_gate_stable_import_entry_key_20261017.gd"
## One real world96 -> cold Gate -> real world -> same Gate warm.
## Last park/reset is explicitly QA lifecycle setup, NOT a second world travel.
const WARM_READY=true
const WARM_WHOLE_MS=160000
const LEASE=preload("res://scripts/city/luoyang_resident_field_20261016.gd")
const BASE_ENTRY="res://tests/test_world_gate_stable_import_entry_key_20261017.gd"
const BASE_ENTRY_SHA="055c5dcac7f6fcade80c8408041914bcd594ece674962522b341f955009de55f"
const COLD_RESULT="res://build/world_gate_stable_import_entry_20261017/96048_2544/result.json"
const COLD_RESULT_SHA="6e8ad7db63b97979509d906b23b274b2bc0f2dfecbf24f3fe947469b0b78cb74"
const GATE_ID="ch4_s0_luoyang_gate"
var retained: Node
var retained_scene: SceneScript
var retained_static: Dictionary={}
var retained_nav: Dictionary={}
var retained_crowd: Dictionary={}
var retained_oracle: RefCounted
var watch_jobs:=false
var cold_job_frames:=0
var validations_before:=0
func precheck() -> bool:
	if not check(WARM_READY and not FINAL_SOURCE_PINS.is_empty(),"Exact i-repaired Gate dependencies frozen; only g live-city lease"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0,"Real GPU/native clock"): return false
	if not check(OS.get_cmdline_user_args()==PackedStringArray([LEASE.LIVE_WORLD_FLAG]) and not LEASE.LIVE_WORLD_FORMAL_ENABLED,"Only exact g lease candidate flag, no eleven-room flag"): return false
	if not track(BASE_ENTRY,BASE_ENTRY_SHA) or not track(COLD_RESULT,COLD_RESULT_SHA): return false
	var evidence: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(COLD_RESULT))
	if not check(evidence.get("complete")==true and evidence.get("failures")==0,"Reuse i96048 real world entrance/cold profile, not new profiling suite"): return false
	for path: String in FINAL_SOURCE_PINS:
		if not track(path,FINAL_SOURCE_PINS[path]): return false
	var approval: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(STABLE.APPROVAL_PATH))
	for path: String in approval.source_sha256:
		if not track(path,approval.source_sha256[path]): return false
	var historical: Dictionary=GATE.runtime_manifest()
	if not check(historical.get("asset_sha256",{}).size()==56,"Original immutable56 catalog, no historical pin rewrite"): return false
	var authorized: int=0;var unchanged: int=0
	for path: String in historical.asset_sha256:
		if STABLE.handles(path):
			var effective: String=STABLE.effective_sha(path,historical.asset_sha256[path])
			if not check(effective.length()==64,"Actual FINAL exact8 approval plus raw/import/ctex pair identity") or not track(path,effective): return false
			authorized+=1
		else:
			if not track(path,historical.asset_sha256[path]): return false
			unchanged+=1
	if not check(authorized==8 and unchanged==48,"Only exact8 variants; remaining48 actual historical SHA unchanged"): return false
	for paths: Dictionary in [STABLE.source_paths(),OFFICE.source_paths()]:
		for path: String in paths:
			if not source_before.has(path) and not track(path,FileAccess.get_sha256(path)): return false
	if not track(R.BIND_PATH,FINAL_BIND_SHA): return false
	package=R.binding();author=R.author(package)
	if not check(R.cpu_proof_valid(package,author),"Existing district CPU geometry reused; no old city rebuild"): return false
	for path: String in R.source_paths():
		if not source_before.has(path) and not track(path,FileAccess.get_sha256(path)): return false
	for path: String in [get_script().resource_path,"res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd","res://data/scenes/world_map_jianghu.tres"]:
		if not track(path,FileAccess.get_sha256(path)): return false
	return true

func _busy() -> bool:
	if watch_jobs:
		var state: Dictionary=C.transition_validation_state()
		var active: bool=C._live_module_task>=0
		for key: String in ["source_worker_active","navigation_worker_active","base_cpu_worker_active","revision_worker_active","BASE_live_active","module_worker_active"]:
			active=active or state.get(key,false)==true
		if active: cold_job_frames+=1
	return super._busy()

func _zone(target: String,action: String="") -> bool:
	var zones: Array=[]
	for zone: Node in field.get("_exit_nodes"):
		if (not target.is_empty() and String(zone.get("target_scene_id"))==target) or (not action.is_empty() and String(zone.get("action"))==action): zones.append(zone)
	return check(zones.size()==1 and zones[0].get("_in_range")==true and not zones[0].get("is_locked"),"Actual original unlocked portal overlap",{"target":target,"action":action})

func _world_bind() -> bool:
	oracle=WORLD_RAW.new()
	var player: CharacterBody2D=field.get("_player")
	var shape: CollisionShape2D=player.get_node("CollisionShape2D")
	if not check(shape.shape is CircleShape2D and (shape.shape as CircleShape2D).radius==5.0 and shape.position==Vector2.ZERO and oracle.configure(scene.map_layout) and _clear(player.position),"Actual original world radius5/17 plus native Physics"): return false
	for tile: Dictionary in oracle.tiles.values():
		if not source_before.has(tile.path) and not track(tile.path,tile.sha256): return false
	return true

func _ambient(node: Node) -> Dictionary:
	var result: Dictionary={}
	for npc: Node in node.get("_npc_nodes"):
		var id: String=String(npc.get("npc_id"))
		if not id.begins_with("harbour_life_"): continue
		var body: Node=npc.get("_body_collider")
		var sprite: Node=npc.get_node("Sprite2D")
		result[id]={"node":npc.get_instance_id(),"sprite":sprite.get_instance_id(),"body":body.get_instance_id(),"shape":body.get_child(0).get_instance_id()}
	return result

func _identity_values() -> Dictionary:
	var value: Dictionary=field.call("resident_static_identity")
	var result: Dictionary={}
	for key: String in value:
		result[key]=value[key].get_instance_id() if value[key] is Object else value[key]
	return result

func _retain_gate() -> bool:
	retained=field;retained_scene=scene;retained_static=field.call("resident_static_identity");retained_oracle=oracle
	retained_nav={"record":C._records[GATE_ID].duplicate(true),"solids":C._solids[GATE_ID].duplicate(true),"mask":C._masks[GATE_ID],"using":C._using_patch[GATE_ID],"mask_bytes":C._masks[GATE_ID].get_data()}
	retained_crowd=_ambient(field)
	records.append({"kind":"RETAINED_GATE_IDENTITIES","static":_identity_values(),"ambient":retained_crowd.duplicate(true),"navigation_mask_id":retained_nav.mask.get_instance_id()})
	return check(retained_crowd.size()==10 and retained_static.get("scene")==scene.get_instance_id() and _clear(field.get("_player").position),"Cold finalized live Field/static/native/nav and all10 ambient identity snapshot")

func _same_gate() -> bool:
	records.append({"kind":"RETURNED_GATE_IDENTITIES","static":_identity_values(),"ambient":_ambient(field),"navigation_mask_id":C._masks[GATE_ID].get_instance_id()})
	return check(field==retained and scene==retained_scene and field.call("resident_static_identity")==retained_static and _ambient(field)==retained_crowd and C._masks[GATE_ID]==retained_nav.mask and C._masks[GATE_ID].get_data()==retained_nav.mask_bytes and C._equal_value(C._records[GATE_ID],retained_nav.record) and C._equal_value(C._solids[GATE_ID],retained_nav.solids) and C._using_patch[GATE_ID]==retained_nav.using,"Same actual Field/Scene/Player/static sprites/textures/bodies/nav Image+RGBA/10ambient; no reconstruction")

func _clone_negatives() -> bool:
	var proof: Dictionary=C.resident_receipt(scene)
	if not check(C.resident_matches(proof,scene),"Actual trusted cold receipt valid before controlled negative clones"): return false
	var changed: Dictionary=proof.duplicate(true)
	var key: String=String(changed.stamps.keys()[0])
	changed.stamps[key].length=int(changed.stamps[key].length)+1
	if not check(not C.resident_matches(changed,scene),"Controlled receipt length change rejected, no source file write"): return false
	changed=proof.duplicate(true);changed.stamps[key].mtime_seconds=int(changed.stamps[key].mtime_seconds)+1
	if not check(not C.resident_matches(changed,scene),"Controlled normal-editor timestamp change rejected, not timestamp attack defense"): return false
	changed=proof.duplicate(true);changed.mask=proof.mask.duplicate()
	return check(not C.resident_matches(changed,scene) and not C.resident_matches(proof,scene.duplicate(true)) and C.resident_matches(proof,scene),"Different live mask/Scene identity rejected; trusted state unchanged")

func _space_to(id: String,label: String,warm: bool=false) -> bool:
	var started: int=Time.get_ticks_usec()
	await driver.key(KEY_SPACE)
	if not await _wait_once(id,String(scene.scene_id)): return false
	var elapsed: int=Time.get_ticks_usec()-started
	var lease: Dictionary=root.get_node("SceneRouter").call("get_resident_city_state")
	var returned: Dictionary=lease.get("return",{})
	records.append({"kind":"REAL_SPACE_HIDDEN_OPERABLE","label":label,"until_Loading_hidden_canmove_usec":elapsed,"lease":lease,"cold_job_frames":cold_job_frames,"full_validations_total":C.transition_validation_state().get("full_validations_total"),"fresh_warm_disk_sha_claimed":false})
	if not warm: return true
	return check(elapsed<2000000 and returned.get("hit")==true and returned.get("final_live_identity")==true and returned.get("source_fresh_sha")==false and returned.get("source_basis")=="SAME_LIVE_OBJECTS_AND_EDITOR_METADATA" and cold_job_frames==0 and C.transition_validation_state().get("full_validations_total")==validations_before,"Warm strict <2000ms includes real Space/Loadinghidden/canmove/final live identity, 0 cold jobs; bounded evidence reads allowed",returned)

func _exercise() -> bool:
	var router: Node=root.get_node("SceneRouter")
	var definition: SceneScript=ResourceLoader.load("res://data/scenes/world_map_jianghu.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var portals: Array=[]
	for item: Dictionary in definition.map_layout.portals:
		if item.get("target_scene")==GATE_ID: portals.append(item)
	if not check(portals.size()==1,"Immutable original unique world Gate entry"): return false
	var entry: Vector2=portals[0].pos*Vector2(12288,8192)
	var setup: Vector2=entry+Vector2(0,96)
	var accepted: bool=router.call("go_field_smart",StringName(WORLD_ID),setup/Vector2(12288,8192),"",15)
	records.append({"kind":"PUBLIC_LEGAL_NEAR_SETUP_NOT_LONG_TRAVEL","accepted":accepted,"setup":setup,"entry":entry})
	if not check(accepted,"Public legal world near-entry setup") or not await _wait_once(WORLD_ID) or not _world_bind(): return false
	if not await _walk(PackedVector2Array([field.get("_player").position,entry])) or not _zone(GATE_ID): return false
	if not await _space_to(GATE_ID,"FIRST_COLD_GATE"): return false
	district="gate";scene_id=GATE_ID
	if not _bind_actual() or not check(GATE.bound(field.get("_harbour_gate_visual_scene")) and field.get("_player").position==Vector2(1536,1860),"Actual Harbour Gate/original fortified visual parent and original feet1860"): return false
	if not await _walk(PackedVector2Array([Vector2(1536,1860),Vector2(1568,1860),Vector2(1536,1860)])) or not _zone("","world_map") or not _retain_gate() or not _clone_negatives(): return false
	if not await _space_to(WORLD_ID,"NORMAL_GATE_SPACE_EXIT_WORLD") or not _world_bind(): return false
	var parked: Dictionary=router.call("get_resident_city_state")
	var old_player: CharacterBody2D=retained.get("_player")
	if not check(parked.get("occupied")==true and parked.get("parked")==true and parked.get("excursion_kind")=="world" and parked.get("field_id")==retained.get_instance_id() and parked.get("estimated_bytes",0)>0 and parked.get("estimated_bytes",LEASE.LIMIT_BYTES+1)<=LEASE.LIMIT_BYTES and not retained.is_inside_tree() and not old_player.is_inside_tree() and not PhysicsServer2D.body_get_space(old_player.get_rid()).is_valid(),"Actual world ready, one bounded city lease outside tree and Physics",parked): return false
	var world_field: Node=field
	var world_foot: Vector2=field.get("_player").position
	watch_jobs=true;validations_before=int(C.transition_validation_state().get("full_validations_total"))
	if not check(router.call("go_field_smart",&"ch4_s0_luoyang_gate",Vector2(1536,1860)/Vector2(3072,2048),"",-1,C.VERSION),"Actual public warm enqueue for immediate cancellation"): return false
	var queued: Dictionary=router.call("get_resident_city_state")
	var token: int=int(queued.get("return",{}).get("token",0))
	if not check(token>0 and router.call("cancel_public_city_preparation",token),"Actual QUEUED warm token cancel before handoff"): return false
	await process_frame;await physics_frame
	if not check(current_scene==world_field and field.get("_player").position==world_foot and field.get("_player").get("can_move")==true and not router.call("cancel_public_city_preparation",token) and router.call("get_resident_city_state").get("parked")==true,"Cancelled warm preserves world/feet/parked city and old token refuses successor"): return false
	if not await _walk(PackedVector2Array([world_foot,entry])) or not _zone(GATE_ID): return false
	if not await _space_to(GATE_ID,"SECOND_SAME_GATE_AFTER_REAL_WORLD",true): return false
	watch_jobs=false;oracle=retained_oracle;district="gate";scene_id=GATE_ID
	if not _same_gate() or not check(field.get("_player").position==Vector2(1536,1860) and _clear(Vector2(1536,1860)),"Same Gate original exact arrival/full87517/native34x24 Physics"): return false
	if not await _walk(PackedVector2Array([Vector2(1536,1860),Vector2(1568,1860)])) or not await _capture("same_gate_real_world_warm"): return false
	# This last explicit public park is a QA lifecycle fixture, NOT another
	# claimed trip or a substitute for the real Space exit/reentry above.
	if not await _walk(PackedVector2Array([Vector2(1568,1860),Vector2(1536,1860)])): return false
	var city_ref: WeakRef=weakref(field)
	var npc_refs: Array[WeakRef]=[]
	for npc: Node in field.get("_npc_nodes"):
		if String(npc.get("npc_id")).begins_with("harbour_life_"): npc_refs.append(weakref(npc))
	if not check(router.call("park_resident_exterior_for_excursion",StringName(WORLD_ID)),"QA_LIFECYCLE_SETUP_ONLY public park at exact remembered safe foot, not second world travel"): return false
	router.call("reset_for_new_game")
	await process_frame;await process_frame
	var released: bool=city_ref.get_ref()==null and not router.call("get_resident_city_state").get("occupied") and C._resident_ready.is_empty()
	for ref: WeakRef in npc_refs: released=released and ref.get_ref()==null
	records.append({"kind":"REAL_PARKED_GATE_NEWGAME_RELEASE","QA_lifecycle_setup_not_second_world_travel":true,"ambient_weak_count":npc_refs.size(),"released":released})
	return check(released and npc_refs.size()==10,"Actual parked Gate plus10ambient freed by newgame, trusted receipt cleared")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+WARM_WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_live_city_world_gate_20261017j/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete:=false
	if precheck():
		driver=INPUT.new();driver.configure(self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		complete=await _exercise()
	if driver!=null: driver.release();driver=null
	root.get_node("SceneRouter").call("reset_for_new_game")
	if is_instance_valid(current_scene): current_scene.queue_free()
	await process_frame;await process_frame
	field=null;scene=null;oracle=null;retained=null;retained_scene=null;retained_oracle=null;retained_static.clear();retained_nav.clear();retained_crowd.clear();frame_images.clear()
	records.append({"kind":"SCOPE","whole_ms":WARM_WHOLE_MS,"arrival_ms":60000,"warm_limit_usec":2000000,"captures":captures,"native_queries":native_queries,"cold_profile_reused_i96048":true,"warm_fresh_disk_sha":false,"eleven_rooms_enabled":false,"whole_four_cities":false})
	finish(folder,began,complete,"REAL_WORLD_GATE_WORLD_SAME_GATE_WARM_ONLY")

