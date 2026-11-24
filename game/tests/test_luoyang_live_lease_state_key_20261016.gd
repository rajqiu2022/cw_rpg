extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Controlled Node/state fixtures, not a real city/Physics/SHA cache acceptance.
const LEASE=preload("res://scripts/city/luoyang_resident_field_20261016.gd")
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const PINS={"res://scripts/city/luoyang_resident_field_20261016.gd":"20086323c7aca3bb3efe51b77cdad393ec5e4ccdacdf98856eaca4beccd22624","res://scripts/autoload/scene_router.gd":"1082a842eb283a7eba339f9589bbcb0a5803d934c79f60d9e7a7f0413069bd92","res://scripts/autoload/loading_manager.gd":"5550a037e8001069713b0af317a6db2cd2ac427189f8f75d2e87e755ece210db","res://scripts/field/field_walkable_controller.gd":"50b35b21520b2d10d24e2582b4de4440178252df9f29f79e013146ac3c8e62c2","res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"82df07a7411aa10327485db7c9e7d90df7770defb4b677907a9bc0a57c62d1d1"}
class FixtureField extends Node2D:
	var _current_scene: SceneScript=SceneScript.new()
	var mask: Image=Image.create(2,2,false,Image.FORMAT_RGBA8)
	var estimate: int=1024
	var discarded:=false
	func resident_estimated_bytes() -> int: return estimate
	func resident_static_identity() -> Dictionary: return {"field":get_instance_id(),"scene":_current_scene,"mask":mask}
	func resident_begin_park() -> bool: return true
	func resident_abort_park(mode: int) -> void: process_mode=mode
	func resident_discard() -> void: discarded=true
	func get_field_loading_state() -> Dictionary: return {"complete":true,"failed":false,"scene_id":String(_current_scene.scene_id)}
func _fixture(id: StringName=&"ch4_s0_luoyang_gate") -> FixtureField:
	var node:=FixtureField.new();node._current_scene.scene_id=id;root.add_child(node);return node
func _stage(slot: RefCounted,node: FixtureField) -> bool:
	return slot.stage(node,&"world_map_jianghu",{"sources":{"CONTROLLED_FIXTURE":true}},Vector2(.5,.9),Vector2.ZERO,Node.PROCESS_MODE_INHERIT,"world")
func _run() -> void:
	var began: int=Time.get_ticks_msec(); deadline=began+60000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var folder: String="res://build/luoyang_live_city_lease_20261016g/state/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=check(LEASE.LIVE_WORLD_FLAG in OS.get_cmdline_user_args() and not LEASE.LIVE_WORLD_FORMAL_ENABLED,"Exact candidate state fixture")
	for path: String in PINS:
		if not track(path,PINS[path]): complete=false
	for path: String in [get_script().resource_path,"res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"]:
		if not track(path,FileAccess.get_sha256(path)): complete=false
	if complete: complete=await _units(folder)
	finish(folder,began,complete,"STATE_ONLY_CONTROLLED_LIVE_NODES_NO_FIELD_PHYSICS_OR_FRESH_SHA")
func _units(folder: String) -> bool:
	var router: Node=root.get_node("SceneRouter")
	router.call("reset_for_new_game")
	var original: RefCounted=router.get("_resident_city")
	if not check(not original.state().occupied,"Fresh process no user lease to replace"): return false
	var slot: RefCounted=LEASE.new();router.set("_resident_city",slot)
	var city: FixtureField=_fixture();current_scene=city
	check(_stage(slot,city) and slot.identities_match(),"Controlled living node positive identity")
	check(not _stage(slot,_fixture(&"ch4_s1_luoyang_yamen")),"Single occupied slot refuses accumulation")
	var saved_mask: Image=city.mask;city.mask=city.mask.duplicate()
	check(not slot.identities_match(),"Equal-byte different mask Image identity rejected")
	city.mask=saved_mask
	var saved_scene: SceneScript=city._current_scene;city._current_scene=city._current_scene.duplicate(true) as SceneScript
	check(not slot.identities_match(),"Cloned same-value live Scene identity rejected")
	city._current_scene=saved_scene
	var stamps: Dictionary=slot.implementation_stamps.duplicate(true)
	var key: String=String(stamps.keys()[0]);slot.implementation_stamps[key].length=int(stamps[key].length)+1
	check(not slot.identities_match(),"Changed implementation length stamp invalidates live lease")
	slot.implementation_stamps=stamps.duplicate(true);slot.implementation_stamps[key].mtime_seconds=int(stamps[key].mtime_seconds)+1
	check(not slot.identities_match(),"Normal changed editor mtime stamp invalidates live lease")
	slot.implementation_stamps=stamps
	check(slot.identities_match(),"Negative fixture clones did not alter actual implementation metadata")
	# Real metadata writes are restricted to this QA-owned fixture, never a production source.
	var probe: String=folder.path_join("metadata_fixture.txt")
	var file:=FileAccess.open(probe,FileAccess.WRITE);file.store_string("a");file.close()
	var before: Dictionary=C.resident_source_stamps({probe:true})
	file=FileAccess.open(probe,FileAccess.WRITE);file.store_string("longer");file.close()
	var after: Dictionary=C.resident_source_stamps({probe:true})
	check(before[probe].length==1 and after[probe].length==6 and before!=after,"Actual controlled metadata change detected without touching production files")
	check(slot.detach(self),"Controlled world excursion detach")
	var city_ref: WeakRef=weakref(city)
	router.call("reset_for_new_game")
	check(city_ref.get_ref()==null and not slot.state().occupied and slot.last.reason=="NEW_GAME_RESET" and C._resident_ready.is_empty(),"Public newgame frees real parked fixture and trusted receipt")
	var huge: FixtureField=_fixture();huge.estimate=LEASE.LIMIT_BYTES+1
	check(not _stage(slot,huge) and slot.state().phase=="MEMORY_REFUSED" and not slot.state().occupied,"512MiB conservative estimate rejects oversize fixture")
	var world: FixtureField=_fixture(&"world_map_jianghu");current_scene=world
	city=_fixture();check(_stage(slot,city),"Fresh city fixture for eviction")
	current_scene=city;check(slot.detach(self),"Park before different-city public request");current_scene=world
	router.set("_current_field_id",&"world_map_jianghu");router.set("_current_field_spawn",Vector2(.5,.5))
	city_ref=weakref(city)
	var accepted: bool=router.call("go_field_smart",&"ch4_s1_luoyang_yamen",Vector2(.5,.9),"",-1,C.VERSION)
	var queued: Dictionary=router.call("get_public_city_preparation_state")
	check(accepted and city_ref.get_ref()==null and slot.last.reason=="COLD_CITY_REQUEST","Actual public different-city cold enqueue evicts parked fixture before C prepare")
	check(router.call("cancel_public_city_preparation",int(queued.get("token",0))),"Actual queued cold public token cancelled before deferred source work")
	check(not router.call("cancel_public_city_preparation",int(queued.get("token",0))) and current_scene==world,"Stale cancelled token rejected, original fixture source preserved")
	await process_frame;await process_frame
	check(not C.transition_validation_state().source_worker_active,"Cancelled deferred fixture never started source worker")
	# Attached cancellation uses the real public lifecycle method with controlled nodes.
	city=_fixture();check(_stage(slot,city),"New controlled attach-cancel lease")
	current_scene=city;check(slot.detach(self),"Controlled park before attach")
	root.remove_child(world);check(slot.attach(self),"Controlled attached restoration")
	router.set("_resident_return",{"token":812345,"generation":slot.generation,"attached":true,"room":world,"room_mode":Node.PROCESS_MODE_INHERIT,"source_id":&"world_map_jianghu","source_current_spawn":Vector2(.5,.5),"payload":{},"public_request":false})
	router.set("_resident_return_state",{"active":true,"phase":"RESTORING_LIVE_FIELD"})
	city_ref=weakref(city)
	check(not router.call("cancel_public_city_preparation",812344),"Wrong old token cannot cancel attached successor")
	check(router.call("cancel_public_city_preparation",812345) and current_scene==world and world.is_inside_tree() and city_ref.get_ref()==null and not slot.state().occupied,"Attached warm cancellation disposes resumed fixture and restores exact source node")
	check(not router.call("cancel_public_city_preparation",812345),"Completed cancellation token cannot act again")
	records.append({"kind":"FIXTURE_SCOPE","real_city_geometry_tested":false,"normal_editor_metadata_only":true,"same_length_forged_timestamp_attack_tested":false,"controlled_attached_cancel_not_actual_Physics_handoff":true,"actual_world_queued_cancel_in_separate_GPU_key":true,"source_bytes_not_modified":true,"limit_bytes":LEASE.LIMIT_BYTES})
	router.call("reset_for_new_game");router.set("_resident_city",original)
	for child: Node in root.get_children():
		if child is FixtureField: child.queue_free()
	await process_frame;await process_frame
	return failures==0
