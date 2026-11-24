extends "res://build/luoyang_seven_fields_layout_20261026c_system01/smoke_seven_worker_NOTREADY.gd"
## Two public near setups only, not default-loading benchmarks or portal trips.
func yamen_portals() -> bool:
	var new_zones: Array=[];var old_zones: Array=[]
	for zone: Node in field.get("_exit_nodes"):
		if zone.get("target_scene_id")=="luoyang_artisan_residential_20261022ap": new_zones.append(zone)
		if zone.get("target_scene_id")=="ch4_s3_luoyang_market": old_zones.append(zone)
	if not check(new_zones.size()==1 and old_zones.size()==1,"UNIQUE_NEW_BRANCH_AND_ORIGINAL_SOUTH_MARKET"): return false
	var branch: Node2D=new_zones[0] as Node2D;var market: Node2D=old_zones[0] as Node2D
	if not check(branch.position==Vector2(120,700) and branch.get("exit_label")=="前往百工坊" and branch.get("target_spawn_pos")==Vector2(128,1300)/Vector2(3072,2048) and branch.get("is_locked")==false and branch.get("auto_trigger")==false,"ACTUAL_CHINESE_NORTH_ARTISAN_BRANCH"): return false
	if not check(market.position==Vector2(300,1220) and market.get("exit_label")=="前往洛阳南市" and market.get("target_spawn_pos")==Vector2(.955,.355) and branch.position.distance_to(market.position)>=500.0,"ORIGINAL_SOUTH_MARKET_AND_GEOMETRIC_SEPARATION"): return false
	var runtime: Variant=load(spec.finish_runtime.path)
	var outward: Dictionary=runtime._arrival_contract(&"ch4_s1_luoyang_yamen",&"luoyang_artisan_residential_20261022ap")
	var returning: Dictionary=runtime._arrival_contract(&"luoyang_artisan_residential_20261022ap",&"ch4_s1_luoyang_yamen")
	if not check(outward.get("source_foot")==Vector2(120,700) and outward.get("target_foot")==Vector2(128,1300) and returning.get("source_foot")==Vector2(128,1300) and returning.get("target_foot")==Vector2(120,700) and returning.get("uv")==Vector2(120,700)/Vector2(3072,2048),"STATIC_RECIPROCAL_DECLARED_CONTRACT_NO_ACTIVATION"): return false
	records.append({"kind":"TWO_REAL_ZONES","new_foot":branch.position,"new_label":branch.get("exit_label"),"old_market_foot":market.position,"old_label":market.get("exit_label"),"distance":branch.position.distance_to(market.position),"new_can_enter_diagnostic_only":branch.call("can_enter"),"old_can_enter_diagnostic_only":market.call("can_enter"),"no_Space":true})
	return true
func market_walls() -> bool:
	var art: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.art.path))
	for placement: Dictionary in art.placements:
		var found: Array=[]
		for sprite: Sprite2D in field.get("_scene_object_nodes"):
			if sprite.name=="SceneObject_"+String(placement.id): found.append(sprite)
		if not check(found.size()==1,"UNIQUE_ADULT_WALL:"+String(placement.id)): return false
		var node: Sprite2D=found[0];var foot: Vector2=v(placement.foot)
		var expected_position: Vector2=(foot+v(art.asset.source_size)*.5-v(art.asset.source_anchor))/Vector2(3072,2048)*Vector2(3072,2048)
		if not check(node.texture!=null and node.texture.resource_path==art.asset.texture and node.texture.get_size()==Vector2(129,132) and node.position==expected_position and node.scale==Vector2.ONE and node.centered and node.modulate.a==1.0 and node.self_modulate.a==1.0 and node.get_parent()==field.get("_actor_layer"),"SOURCE_NATIVE_SCALE1_FOOT_OPACITY_DEPTH:"+String(placement.id)): return false
		var expected:=PackedVector2Array()
		for raw: Array in art.asset.true_ground_polygons[0]: expected.append(foot+(v(raw)-v(art.asset.source_anchor)))
		var count: int=0
		for body_node: StaticBody2D in field.get("_collision_bodies"):
			if body_node.get_child_count()!=1: continue
			var shape: CollisionPolygon2D=body_node.get_child(0) as CollisionPolygon2D
			if shape!=null and var_to_bytes(shape.polygon)==var_to_bytes(expected):
				if not check(not shape.disabled and body_node.transform==Transform2D.IDENTITY and shape.transform==Transform2D.IDENTITY and body_node.collision_layer==1 and body_node.collision_mask==0,"SOURCE_NEW_WALL_REAL_STATIC_BODY"): return false
				count+=1
		if not check(count==1,"EXACT_ONE_TRUE_BASE_PER_WALL:"+String(placement.id)): return false
		records.append({"kind":"ACTUAL_ADULT_WALL","id":placement.id,"foot":foot,"position":node.position,"scale":node.scale,"depth_band":node.z_index,"ground_polygon":expected})
	for retired: Dictionary in art.retire_only:
		for sprite: Sprite2D in field.get("_scene_object_nodes"):
			if not check(sprite.name!="SceneObject_"+String(retired.id),"NO_RETIRED_LOW_WALL_SPRITE"): return false
	return true
func exercise() -> bool:
	for row: Dictionary in spec.cases:
		var id: StringName=StringName(row.scene_id)
		if not await public_setup(id,v(row.start)/Vector2(3072,2048)): return false
		var original: Dictionary=C._resident_ready
		if not check(original.get("scene")==scene and original.get("sources_finalized")==true and original.get("sources")==row.expected_sources,"NATURAL_FINAL_FIXED_STAGE_SOURCES:"+String(id)): return false
		if not check(player().position.distance_to(v(row.start))<=.3,"SOURCE_DEFINED_NEAR_SETUP_NOT_OBSERVED_REPOSITION"): return false
		if id==&"ch4_s1_luoyang_yamen":
			if not yamen_portals(): return false
		else:
			if not market_walls(): return false
		var movement: Dictionary=await driver.drive(field,v(row.end),func(foot: Vector2) -> bool: return budget() and foot.is_finite() and tree.current_scene==field and player().can_move)
		records.append({"kind":"SOURCE_CORRIDOR32PX_REAL_INPUT","scene":String(id),"movement":movement})
		if not check(movement.get("ok")==true and hidden(),"LOCAL_CORRIDOR_OPERABLE"): return false
		await RenderingServer.frame_post_draw
		var image: Image=tree.root.get_texture().get_image()
		if not check(image!=null and image.get_size()==Vector2i(1920,1080),"CURRENT_NATIVE_CAMERA_NO_OVERRIDE"): return false
		var image_path: String=output+String(id)+".png"
		if not check(image.save_png(image_path)==OK,"ONE_CURRENT_VIEW_PER_FIELD"): return false
		pictures+=1;records.append({"kind":"LOCAL_CURRENT_CAMERA","path":image_path,"sha256":FileAccess.get_sha256(image_path)})
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
	check(complete and budget() and pictures==2 and space_calls==0 and writes==0,"FIXED60S_TWO_VIEWS_ZERO_SPACE_OR_POSITION_WRITES")
	var report: Dictionary={"complete":complete and errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"records":records,"pictures":pictures,"Space_calls":space_calls,"position_writes":writes,"camera_writes":0,"source_first":first,"source_final":last,"save_first":saves_first,"save_final":last_saves,"collector_calls":0,"claim":"Only two source-defined near entries/current views: Chinese separated Yamen branch and four scale1 Market wall panels/real bases/central corridor. No portal trip, other city, dialogue, services, old geometry or default-load benchmark."}
	var file:=FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file==null: tree.quit(2);return
	file.store_string(JSON.stringify(report,"\t")+"\n");file.close();print("EXIT_WALL_TWO_VIEWS ",output+"result.json");tree.quit(0 if report.complete else 1)
