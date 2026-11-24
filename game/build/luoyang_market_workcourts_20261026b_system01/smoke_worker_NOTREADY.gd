extends "res://build/luoyang_city_finish_20261025i_system01/qa_role_new/real_fields04_ROOT_READY/worker_ROOT_READY.gd"
## One public Market entry, 32px actual INPUT and one untouched current-camera image.
## System selftest only; no city ART, detailed geometry, doors or gameplay acceptance.
const CITY: StringName=&"ch4_s3_luoyang_market"
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
func precheck() -> bool:
	if not check(spec.get("ready")==true and spec.get("formal_deployed")==true and spec.get("whole_ms")==60000 and spec.get("entry_ms")==20000,"FORMAL_FIXED60_20_SINGLE_MARKET_SMOKE"): return false
	first=facts(spec.dependencies.keys())
	for path: String in spec.dependencies:
		if not check(first[path].get("sha256")==spec.dependencies[path],"FIXED_HEAD:"+path): return false
	return check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and tree.root.get_visible_rect().size==Vector2(1920,1080),"NORMAL_GUI_NATIVE_CAMERA_NO_OVERRIDE")
func exercise() -> bool:
	var start: int=Time.get_ticks_usec()
	if not check(router().call("go_field_smart",CITY,Vector2(2197,1468)/Vector2(3072,2048),"",-1,C.VERSION),"SINGLE_PUBLIC_SOURCE_NEAR_NOT_DEFAULT_TRAVEL"): return false
	var until: int=mini(deadline,Time.get_ticks_msec()+20000)
	while Time.get_ticks_msec()<until:
		var state: Dictionary=router().call("get_public_city_preparation_state")
		if state.get("scene_id")==String(CITY) and state.get("phase")=="FAILED": return check(false,"PUBLIC_REJECT_NO_RETRY",{"public":state,"C_errors":C.errors()})
		var current: Node=tree.current_scene
		if is_instance_valid(current) and current.has_method("get_field_loading_state"):
			var loading: Dictionary=current.call("get_field_loading_state")
			var resource: SceneScript=current.get("_current_scene") as SceneScript
			if resource!=null and resource.scene_id==CITY:
				if loading.get("failed")==true: return check(false,"FIELD_REJECT_NO_RETRY",loading)
				var p: CharacterBody2D=current.get("_player") as CharacterBody2D
				if loading.get("complete")==true and p!=null and p.can_move and hidden():
					field=current;scene=resource
					await RenderingServer.frame_post_draw
					var draw: int=Time.get_ticks_usec()
					if not check(tree.current_scene==field and hidden() and player().can_move,"NATURAL_COMPLETE_HIDDEN_OPERABLE"): return false
					var proof: Dictionary=C._resident_ready
					if not check(proof.get("scene")==scene and proof.get("sources_finalized")==true,"PRODUCTION_NATURAL_FINAL_NO_COLLECTOR"): return false
					records.append({"kind":"EXPLICIT_MARKET_NEAR_ENTRY_NOT_WORLD_BENCHMARK","elapsed_us":draw-start,"foot":player().position,"natural_source_count":proof.get("sources",{}).size(),"profile":field.call("get_field_loading_profile")})
					break
		await tree.process_frame
	if not check(field!=null and Time.get_ticks_msec()<until,"FIXED20S_ENTRY"): return false
	if not check(player().position.distance_to(Vector2(2197,1468))<=.3,"FIXED_SOURCE_START_NO_INSPECTION_WRITE"): return false
	var moved: Dictionary=await driver.drive(field,Vector2(2197,1500),func(foot: Vector2) -> bool: return budget() and foot.is_finite() and tree.current_scene==field and player().can_move)
	records.append({"kind":"REAL32PX_INPUT_ONLY_NO_INDEPENDENT_GEOMETRY_CLAIM","movement":moved})
	if not check(moved.get("ok")==true and driver.observed_positions.size()>0 and hidden() and player().can_move,"BASIC_REAL_INPUT32PX"): return false
	await RenderingServer.frame_post_draw
	var image: Image=tree.root.get_texture().get_image()
	if not check(image!=null and image.get_size()==Vector2i(1920,1080),"ONE_NATIVE_CURRENT_CAMERA_IMAGE"): return false
	var path: String=output+"market_living_street_current_camera.png"
	if not check(image.save_png(path)==OK,"SAVE_ONE_IMAGE"): return false
	pictures=1;records.append({"kind":"UNMODIFIED_CAMERA_VIEW","path":path,"sha256":FileAccess.get_sha256(path),"foot":player().position})
	return true
func run(owner_tree: SceneTree,fixture: Dictionary) -> void:
	tree=owner_tree;spec=fixture;began=Time.get_ticks_msec();deadline=began+60000
	output=String(spec.output_root)+str(OS.get_process_id())+"/"
	if DirAccess.dir_exists_absolute(output): tree.quit(2);return
	DirAccess.make_dir_recursive_absolute(output);saves_first=saves()
	var complete: bool=false
	if precheck() and check(FileAccess.get_sha256(DRIVER_PATH)==DRIVER_SHA,"EXISTING_INPUT_DRIVER"):
		var script: GDScript=load(DRIVER_PATH) as GDScript
		if check(script!=null and script.can_instantiate(),"INPUT_DRIVER_LOAD"):
			driver=script.new();driver.configure(tree);complete=await exercise()
	if driver!=null: driver.release()
	var last: Dictionary=facts(spec.get("dependencies",{}).keys());var last_saves: Dictionary=saves()
	check(first==last,"FIXED_SOURCES_UNCHANGED");check(saves_first==last_saves,"15_SAVE_BYTES_SHA_SECONDS_UNCHANGED_ROOT_EXTERNAL_EXACTTICKS")
	check(complete and budget(),"FIXED60S_NO_EXTENSION")
	var report: Dictionary={"complete":complete and errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"records":records,"pictures":pictures,"source_first":first,"source_final":last,"save_first":saves_first,"save_final":last_saves,"collector_calls":0,"position_writes":0,"camera_writes":0,"Space_or_dialog_calls":0,"claim":"Single explicit Market entry and basic motion only; detailed routes/ART/whole city remain user playtest."}
	var file:=FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file==null: tree.quit(2);return
	file.store_string(JSON.stringify(report,"\t")+"\n");file.close();print("MARKET_SIMPLE_SMOKE ",output+"result.json");tree.quit(0 if report.complete else 1)
