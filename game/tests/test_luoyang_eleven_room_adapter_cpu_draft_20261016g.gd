extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## API-only candidate smoke. No Field/GPU, 71-route or 28-import replay.
const KEY_READY=false
const MODULE_PATH="res://scripts/city/luoyang_assembled_interiors_20261016g.gd"
const MODULE_SHA="PENDING_SYSTEM_FINAL_MODULE_SHA"
const REGISTRY_PATH="PENDING_SYSTEM_FINAL_CANDIDATE_REGISTRY_PATH"
const REGISTRY_SHA="PENDING_SYSTEM_FINAL_CANDIDATE_REGISTRY_SHA"
const FACADE_PATH="res://scripts/city/luoyang_assembled_rooms_20261016b.gd"
const FACADE_SHA="PENDING_SYSTEM_FINAL_FACADE_SHA"
const RAW_PATH="res://tests/helpers/luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd"
const RAW_SHA="0f00d4a8a7bc7f514d4b0859275c2eb6d03296dd81eaa170416694c6068b2835"
const M=preload("res://scripts/city/luoyang_assembled_interiors_20261016g.gd")
const F=preload("res://scripts/city/luoyang_assembled_rooms_20261016b.gd")
const RAW=preload("res://tests/helpers/luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd")
const WORLD:=Vector2(1920,1280)
var pillar_count: int=0
var dialogue_count: int=0
func _v(raw: Variant) -> Vector2: return raw if raw is Vector2 else Vector2(raw[0],raw[1])
func _room(row: Dictionary) -> bool:
	var id:=StringName(row.scene_id)
	for path: String in row.source_sha256:
		if not track(path,row.source_sha256[path]): return false
	var scene: SceneScript=ResourceLoader.load(row.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not check(scene!=null and M.known(id) and M.matches(scene,id) and F.matches(scene,id) and M.is_room(scene),"Real source Scene/session, candidate exact identity "+String(row.type_id)): return false
	var geometry: Dictionary=F.geometry_for(scene)
	if not check(geometry.get("coordinate_contract")==M.META,"Validated live geometry explicitly selects new facade branch"): return false
	var compiled: Dictionary=F.compile_geometry(geometry,WORLD)
	var zones: Array=compiled.get("_compiled",{}).get("world_foot_forbidden",[])
	if not check(not compiled.is_empty() and zones.size()==geometry.fixed_architecture.size(),"Every baked column reaches actual facade compiled world forbidden"): return false
	var independent:=RAW.new()
	for index: int in geometry.foot_forbidden_regions_px.size():
		var source: Array=geometry.foot_forbidden_regions_px[index]
		var low: Vector2=_v(source[0]);var high: Vector2=low
		for point: Variant in source: low=low.min(_v(point));high=high.max(_v(point))
		var foot: Vector2=(low+high)*.5*1.25
		if not check(independent._inside_closed(foot,zones[index]) and not F.safe_foot(compiled,foot,WORLD,true),"Compiled pillar point belongs to forbidden and real facade rejects, no dropped META/legacy fallback"): return false
		pillar_count+=1
		records.append({"kind":"ACTUAL_FACADE_COMPILED_COLUMN","type":row.type_id,"index":index,"foot":foot,"contains_in_real_compiled_zone":true,"native_Physics_claimed":false,"floor_only_isolation_claimed":false})
	if not check(F.safe_foot(compiled,_v(geometry.spawn_foot_px)*1.25,WORLD,true),"Actual facade source-foot spawn clears without extra42"): return false
	var clone: SceneScript=scene.duplicate(true) as SceneScript
	if not check(not M.matches(clone,id) and not M.finalize_setup(clone),"Resource clone has no trusted live Scene/session"): return false
	var original_name: String=scene.display_name
	scene.display_name=original_name+"__controlled_storage_negative"
	var altered_rejected: bool=not M.matches(scene,id) and not M.finalize_setup(scene)
	scene.display_name=original_name
	if not check(altered_rejected and M.matches(scene,id),"Actual in-memory storage change rejected and exact restoration revalidates; no file write"): return false
	var catalogue_before: Dictionary=M._catalogue_snapshot.duplicate(true)
	var fake: Dictionary=catalogue_before.duplicate(true)
	fake.rooms[String(id)].source_sha256[String(row.scene_path)]="0".repeat(64)
	M._catalogue_snapshot=fake
	var fake_rejected: bool=not M.finalize_setup(scene)
	M._catalogue_snapshot=catalogue_before
	if not check(fake_rejected and M.finalize_setup(scene),"Cloned per-row source SHA fails native finalize, exact real row succeeds after restoration"): return false
	var expected: String="luoyang_distinct_rooms_20261016/cloth_daily" if row.type_id=="cloth_shop" else ("luoyang_distinct_rooms_20261016/warehouse_daily" if row.type_id=="warehouse" else "")
	if not expected.is_empty():
		var wrong: String="luoyang_distinct_rooms_20261016/warehouse_daily" if row.type_id=="cloth_shop" else "luoyang_distinct_rooms_20261016/cloth_daily"
		if not check(M.dialog_allowed(scene,expected) and not M.dialog_allowed(scene,wrong) and not M.dialog_allowed(scene,"../cloth_daily"),"Pinned original own-room dialogue accepted; wrong-room and traversal refused"): return false
		dialogue_count+=1
	records.append({"kind":"ACTUAL_ROOM_ADAPTER_SESSION","type":row.type_id,"Scene_path":scene.resource_path,"finalize_real":true,"clone_rejected":true,"fake_source_clone_rejected":true,"storage_change_rejected":true,"zero_actor_offset_contract":scene.actor_positions_are_feet,"Field_or_Gpu_claimed":false})
	return Time.get_ticks_msec()<deadline
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+60000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=check(KEY_READY,"Draft fail-closed until candidate registry/module freezes")
	if complete: complete=track(MODULE_PATH,MODULE_SHA) and track(REGISTRY_PATH,REGISTRY_SHA) and track(FACADE_PATH,FACADE_SHA) and track(RAW_PATH,RAW_SHA)
	var room_count: int=0
	if complete:
		complete=check(not M.FORMAL_ENABLED and M.FLAG in OS.get_cmdline_user_args() and M.REGISTRY_PATH==REGISTRY_PATH and M.REGISTRY_SHA==REGISTRY_SHA,"Exact candidate flag and frozen registry, not formal activation")
		var catalogue: Dictionary=M.catalogue()
		if complete: complete=check(catalogue.get("rooms",{}).size()==11,"Actual catalogue11, unchanged smith is reuse")
		if complete:
			for path: String in catalogue.source_sha256:
				if not track(path,catalogue.source_sha256[path]): complete=false;break
		for path: String in [get_script().resource_path,"res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"]:
			if not track(path,FileAccess.get_sha256(path)): complete=false
		if complete:
			for row: Dictionary in catalogue.rooms.values():
				if row.get("reuse_existing_accepted",false): continue
				if not _room(row): complete=false;break
				room_count+=1
		if complete: complete=check(room_count==10 and pillar_count==8 and dialogue_count==2,"Ten real new sessions, eight compiled pillar exclusions, two original dialogues")
	M._scene_sessions.clear()
	records.append({"kind":"SCOPE","rooms":room_count,"compiled_pillars":pillar_count,"original_dialogues":dialogue_count,"routes71_replayed":false,"imports28_replayed":false,"Field_Gpu_or_Physics_claimed":false})
	finish("res://build/luoyang_eleven_room_adapter_cpu_20261016g/%d_%d"%[OS.get_process_id(),began],began,complete,"CANDIDATE_REAL_SCENE_ADAPTER_ONLY_NOT_FIELD_GPU_OR_DOOR_SPACE")
