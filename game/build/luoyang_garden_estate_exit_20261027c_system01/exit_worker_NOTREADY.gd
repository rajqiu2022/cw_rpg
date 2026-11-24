extends "res://build/luoyang_seven_fields_layout_20261026c_system01/smoke_seven_worker_NOTREADY.gd"
## One natural-cold Garden -> Estate Space; no owner resets or private activation.
const AP=preload("res://scripts/city/luoyang_quarters_family_20261022ap.gd")
const ESTATE=preload("res://scripts/city/luoyang_estate_family_20261021am.gd")
const GARDEN_ID: StringName=&"luoyang_riverside_garden_20261022ap"
const ESTATE_ID: StringName=&"luoyang_estate_riverside_20261021ai"
func receipt_ok(value: Dictionary,expected: Dictionary) -> bool:
	return int(value.get("serial",0))>0 and value.get("finalized")==true and value.get("full_source_hash_passes")==2 and value.get("source_first")==expected and value.get("source_final")==expected
func snapshot(label: String) -> void:
	var actors: Array=[];var exits: Array=[]
	for actor: Node2D in field.get("_npc_nodes"):
		actors.append({"id":actor.get("npc_id"),"foot":actor.position,"in_range":actor.get("_in_range")})
	for zone: Node2D in field.get("_exit_nodes"):
		exits.append({"name":String(zone.name),"foot":zone.position,"target":zone.get("target_scene_id"),"target_uv":zone.get("target_spawn_pos"),"locked":zone.get("is_locked"),"in_range":zone.get("_in_range"),"can_enter":zone.call("can_enter") if zone.has_method("can_enter") else null})
	records.append({"kind":"PASSIVE_DISPATCH","phase":label,"actors":actors,"exits":exits,"Estate_receipt":ESTATE.validation_receipt(),"AP_receipt":AP.validation_receipt(),"public":router().call("get_public_city_preparation_state")})
func photo(label: String) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image=tree.root.get_texture().get_image()
	if not check(image!=null and image.get_size()==Vector2i(1920,1080),"NATIVE_CURRENT_CAMERA_NO_WRITES"): return false
	var path: String=output+label+".png"
	if not check(image.save_png(path)==OK,"ONE_CURRENT_IMAGE:"+label): return false
	pictures+=1;records.append({"kind":"CURRENT_CAMERA","path":path,"sha256":FileAccess.get_sha256(path)})
	return true
func exercise() -> bool:
	var cold: Dictionary=ESTATE.validation_receipt()
	if not check(int(ESTATE._serial)==0 and int(cold.get("serial",0))==0 and cold.get("finalized",false)==false,"NATURALLY_COLD_ESTATE_SERIAL0_NO_RESET",cold): return false
	if not await public_setup(GARDEN_ID,Vector2(256,1680)/Vector2(3072,2048)): return false
	var garden_scene: SceneScript=scene
	if not check(receipt_ok(AP.original_receipt_for(garden_scene),spec.expected_Family_sources) and player().position.distance_to(Vector2(256,1680))<=.3,"GARDEN_NATURAL_FIRST_FINAL_SOURCE_DEFINED_DOOR_FOOT"): return false
	for sprite: Sprite2D in field.get("_scene_object_nodes"):
		if not check(sprite.name!="SceneObject_seven26c_garden_west_dry_outer_edge","ONLY_RETIRED_WALL_ABSENT"): return false
	for body_node: StaticBody2D in field.get("_collision_bodies"):
		if body_node.get_child_count()!=1: continue
		var poly: CollisionPolygon2D=body_node.get_child(0) as CollisionPolygon2D
		if poly!=null and not check(var_to_bytes(poly.polygon)!=var_to_bytes(PackedVector2Array([Vector2(92.5,1454),Vector2(407.5,1454),Vector2(407.5,1460),Vector2(92.5,1460)])),"RETIRED_WALL_TRUE_BASE_ABSENT"): return false
	if not await photo("Garden_retired_wall_original_view"): return false
	for physics_stage: int in range(2): await tree.physics_frame;await tree.process_frame
	snapshot("BEFORE_SINGLE_SPACE")
	var eligible: Array=[]
	for candidate_zone: Node2D in field.get("_exit_nodes"):
		if candidate_zone.get("target_scene_id")==String(ESTATE_ID) and candidate_zone.position==Vector2(256,1680): eligible.append(candidate_zone)
	if not check(eligible.size()==1,"ONE_AUTHORED_GARDEN_ESTATE_EXIT"): return false
	var zone: Node2D=eligible[0]
	var allowed: Variant=zone.call("can_enter") if zone.has_method("can_enter") else zone.get("_in_range")
	if not check(allowed==true and zone.get("target_spawn_pos")==Vector2(2944,1840)/Vector2(3072,2048) and zone.get("is_locked")==false and zone.get("auto_trigger")==false and AP.safe_body(GARDEN_ID,player().position),"ORIGINAL_PUBLIC_EXIT_FULLBODY_AND_EXACT_TARGET"): return false
	var started: int=Time.get_ticks_usec();await driver.key(KEY_SPACE);space_calls+=1
	if not await arrive_simple(ESTATE_ID,started,"ONE_TRUE_GARDEN_SPACE_COLD_ESTATE"): return false
	snapshot("AFTER_SINGLE_SPACE")
	var ap_final: Dictionary=AP.validation_receipt();var estate_final: Dictionary=ESTATE.original_receipt_for(scene)
	if not check(receipt_ok(ap_final,spec.expected_Family_sources) and receipt_ok(estate_final,spec.expected_Estate_sources) and player().position.distance_to(Vector2(2944,1840))<=.3,"BOTH_REAL_FAMILY_FIRST_FINAL_AND_SOURCE_AUTHORED_ARRIVAL",{"AP":ap_final,"Estate":estate_final,"foot":player().position}): return false
	var movement: Dictionary=await driver.drive(field,Vector2(2912,1840),func(foot: Vector2) -> bool: return budget() and foot.is_finite() and tree.current_scene==field and player().can_move)
	records.append({"kind":"ESTATE32PX_REAL_INPUT","movement":movement})
	if not check(movement.get("ok")==true and hidden(),"COLD_ESTATE_BASIC_MOVABLE"): return false
	return await photo("Estate_cold_arrival_original_view")
func run(owner_tree: SceneTree,fixture: Dictionary) -> void:
	tree=owner_tree;spec=fixture;began=Time.get_ticks_msec();deadline=began+60000
	output=String(spec.output_root)+str(OS.get_process_id())+"/"
	if DirAccess.dir_exists_absolute(output): tree.quit(2);return
	DirAccess.make_dir_recursive_absolute(output);saves_first=saves()
	var complete: bool=false
	if precheck() and check(FileAccess.get_sha256(DRIVER_PATH)==DRIVER_SHA,"MATURE_REAL_INPUT_DRIVER"):
		var input_script: GDScript=load(DRIVER_PATH) as GDScript
		if check(input_script!=null and input_script.can_instantiate(),"INPUT_DRIVER_LOAD"):
			driver=input_script.new();driver.configure(tree);complete=await exercise()
	if driver!=null: driver.release()
	var last: Dictionary=facts(spec.get("dependencies",{}).keys());var last_saves: Dictionary=saves()
	check(first==last,"FIXED_SOURCE_HEAD_UNCHANGED");check(saves_first==last_saves,"15_SAVES_UNCHANGED_EXTERNAL_EXACTTICKS")
	check(complete and budget() and pictures==2 and space_calls==1 and writes==0,"FIXED60S_ONE_SPACE_TWO_VIEWS_NO_POSITION_WRITES")
	var report: Dictionary={"complete":complete and errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"records":records,"pictures":pictures,"Space_calls":space_calls,"position_writes":writes,"camera_writes":0,"source_first":first,"source_final":last,"save_first":saves_first,"save_final":last_saves,"collector_calls":0,"claim":"One Garden public near setup, one true Space into naturally cold Estate with both original FIRSTFINAL; one retired wall and basic Estate movement only. No other city/routes/gameplay regression or default-load benchmark."}
	var file:=FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file==null: tree.quit(2);return
	file.store_string(JSON.stringify(report,"\t")+"\n");file.close();print("GARDEN_COLD_ESTATE ",output+"result.json");tree.quit(0 if report.complete else 1)
