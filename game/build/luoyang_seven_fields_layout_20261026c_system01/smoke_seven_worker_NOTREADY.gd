extends "res://build/luoyang_city_finish_20261025i_system01/qa_role_new/real_fields04_ROOT_READY/worker_ROOT_READY.gd"
## Two bounded fresh processes. One entry/32px/current-camera image per new field.
## Group B uses one real Market Space to reach Temple; no actor/service regression.
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const MARKET: StringName=&"ch4_s3_luoyang_market"
const TEMPLE: StringName=&"ch4_s4_ancient_temple"
func precheck() -> bool:
	if not check(spec.get("ready")==true and spec.get("formal_deployed")==true and spec.get("whole_ms")==60000 and spec.get("entry_ms")==20000 and spec.get("group") in ["A","B"],"FORMAL_TWO_GROUP_SINGLE_ENTRY_SMOKE"): return false
	first=facts(spec.dependencies.keys())
	for path: String in spec.dependencies:
		if not check(first[path].get("sha256")==spec.dependencies[path],"FIXED_BATCH_HEAD:"+path): return false
	return check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and tree.root.get_visible_rect().size==Vector2(1920,1080),"NORMAL_GUI_NO_CAMERA_OR_SPEED_OVERRIDE")
func arrive_simple(id: StringName,start: int,label: String) -> bool:
	var until: int=mini(deadline,Time.get_ticks_msec()+20000)
	field=null;scene=null
	while Time.get_ticks_msec()<until:
		var public: Dictionary=router().call("get_public_city_preparation_state")
		if public.get("scene_id")==String(id) and public.get("phase")=="FAILED": return check(false,"PUBLIC_REJECT_NO_RETRY",{"leg":label,"public":public,"C_errors":C.errors()})
		var current: Node=tree.current_scene
		if is_instance_valid(current) and current.has_method("get_field_loading_state"):
			var loading: Dictionary=current.call("get_field_loading_state")
			var resource: SceneScript=current.get("_current_scene") as SceneScript
			if resource!=null and resource.scene_id==id:
				if loading.get("failed")==true: return check(false,"FIELD_REJECT_NO_RETRY",{"leg":label,"state":loading})
				var p: CharacterBody2D=current.get("_player") as CharacterBody2D
				if loading.get("complete")==true and p!=null and p.can_move and hidden():
					field=current;scene=resource;await RenderingServer.frame_post_draw
					var draw: int=Time.get_ticks_usec();var lease: Dictionary=field.call("get_finish25i_state")
					if not check(tree.current_scene==field and hidden() and player().can_move and lease.get("finalized")==true and lease.get("scene_instance")==scene.get_instance_id(),"NATURAL_ORIGINAL_AND_FINISH_FINAL_OPERABLE:"+String(id)): return false
					records.append({"kind":"SINGLE_FIELD_ENTRY","scene":String(id),"leg":label,"elapsed_us":draw-start,"foot":player().position,"owner_kind":lease.get("owner_kind"),"original_token":str(lease.get("token")),"solid_count":lease.get("solid_count"),"profile":field.call("get_field_loading_profile")})
					return true
		await tree.process_frame
	return check(false,"FIXED20S_ENTRY_NO_RETRY",{"leg":label,"C_errors":C.errors(),"public":router().call("get_public_city_preparation_state")})
func public_setup(id: StringName,uv: Vector2) -> bool:
	var started: int=Time.get_ticks_usec()
	var version: int=C.VERSION if String(id) in ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"] else -1
	if not check(router().call("go_field_smart",id,uv,"",-1,version),"ONE_EXPLICIT_PUBLIC_NEAR_SETUP:"+String(id)): return false
	return await arrive_simple(id,started,"PUBLIC_SOURCE_DEFINED_NEAR_NOT_DEFAULT_BENCHMARK")
func market_space_to_temple() -> bool:
	if not await public_setup(MARKET,Vector2(1170,1600)/Vector2(3072,2048)): return false
	if not check(player().position.distance_to(Vector2(1170,1600))<=.3,"FIXED_ORIGINAL_MARKET_DOOR_FOOT_NO_INSPECTION"): return false
	var patrol: Node2D=null
	for candidate: Node in field.get("_npc_nodes"):
		if candidate.get("npc_id")=="spar_luoyang_patrol":
			if patrol!=null: return check(false,"UNIQUE_PATROL")
			patrol=candidate as Node2D
	if not check(patrol!=null and patrol.position==Vector2(1380,1580) and patrol.position.distance_to(player().position)>118.0,"ACTUAL_ONLY_AUTHORIZED_PATROL_MIGRATION"): return false
	for stage: int in range(2): await tree.physics_frame;await tree.process_frame
	var zones: Array=[]
	for candidate_zone: Node in field.get("_exit_nodes"):
		if candidate_zone is Area2D and candidate_zone.get("target_scene_id")==String(TEMPLE) and candidate_zone.position==Vector2(1170,1600): zones.append(candidate_zone)
	if not check(zones.size()==1,"ONE_FIXED_REAL_TEMPLE_EXIT"): return false
	var zone: Area2D=zones[0];var allowed: Variant=zone.call("can_enter") if zone.has_method("can_enter") else zone.get("_in_range")
	if not check(allowed==true and zone.get("target_spawn_pos")==Vector2(170,926)/Vector2(1536,1024) and zone.get("is_locked")==false and zone.get("auto_trigger")==false,"ORIGINAL_PUBLIC_EXIT_AUTHORITY_NO_PRIVATE_ACTIVATE"): return false
	var began_us: int=Time.get_ticks_usec();await driver.key(KEY_SPACE);space_calls+=1
	return await arrive_simple(TEMPLE,began_us,"ORIGINAL_MARKET_TRUE_SPACE_TO_TEMPLE")
func exercise() -> bool:
	for row: Dictionary in spec.cases:
		var id: StringName=StringName(row.scene_id);var coordinates: Vector2=v(row.coordinate_size_px);var world: Vector2=v(row.world_size_px)
		if row.get("via_market_space",false):
			if not await market_space_to_temple(): return false
		else:
			if not await public_setup(id,v(row.start)/coordinates): return false
		if not check(scene.scene_id==id and player().position.distance_to(v(row.start)/coordinates*world)<=.3,"DECLARED_START_FOOT_NO_POSITION_WRITE:"+String(id)): return false
		var target: Vector2=v(row.end)/coordinates*world
		var moved: Dictionary=await driver.drive(field,target,func(foot: Vector2) -> bool: return budget() and foot.is_finite() and tree.current_scene==field and player().can_move)
		records.append({"kind":"ONE_SHORT_TRUE_INPUT_NOT_GEOMETRY_MATRIX","scene":String(id),"movement":moved})
		if not check(moved.get("ok")==true and driver.observed_positions.size()>0 and hidden(),"BASIC32PX_MOVABLE:"+String(id)): return false
		await RenderingServer.frame_post_draw
		var image: Image=tree.root.get_texture().get_image()
		if not check(image!=null and image.get_size()==Vector2i(1920,1080),"NATIVE_CURRENT_CAMERA_IMAGE"): return false
		var path: String=output+String(id)+".png"
		if not check(image.save_png(path)==OK,"ONE_IMAGE:"+String(id)): return false
		pictures+=1;records.append({"kind":"UNMODIFIED_CURRENT_CAMERA","scene":String(id),"path":path,"sha256":FileAccess.get_sha256(path)})
	return true
func run(owner_tree: SceneTree,fixture: Dictionary) -> void:
	tree=owner_tree;spec=fixture;began=Time.get_ticks_msec();deadline=began+60000
	output=String(spec.output_root)+str(OS.get_process_id())+"/"
	if DirAccess.dir_exists_absolute(output): tree.quit(2);return
	DirAccess.make_dir_recursive_absolute(output);saves_first=saves()
	var complete: bool=false
	if precheck() and check(FileAccess.get_sha256(DRIVER_PATH)==DRIVER_SHA,"MATURE_REAL_INPUT_DRIVER"):
		var script: GDScript=load(DRIVER_PATH) as GDScript
		if check(script!=null and script.can_instantiate(),"INPUT_DRIVER_LOAD"):
			driver=script.new();driver.configure(tree);complete=await exercise()
	if driver!=null: driver.release()
	var last: Dictionary=facts(spec.get("dependencies",{}).keys());var last_saves: Dictionary=saves()
	check(first==last,"FIXED_SOURCE_HEAD_UNCHANGED");check(saves_first==last_saves,"15_SAVES_UNCHANGED_ROOT_EXTERNAL_EXACTTICKS")
	check(complete and budget(),"FIXED60S_NO_EXTENSION")
	var report: Dictionary={"complete":complete and errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"records":records,"pictures":pictures,"Space_calls":space_calls,"source_first":first,"source_final":last,"save_first":saves_first,"save_final":last_saves,"collector_calls":0,"position_writes":0,"camera_writes":0,"claim":"Only seven new fields entry/short real motion; detailed ART/doors/gameplay left for user playtest. Market Space is one necessary old-ring fix, not old whole-test replay."}
	var file:=FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file==null: tree.quit(2);return
	file.store_string(JSON.stringify(report,"\t")+"\n");file.close();print("SEVEN_SIMPLE_SMOKE ",output+"result.json");tree.quit(0 if report.complete else 1)
