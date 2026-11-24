extends "res://build/world_sects_cities_20261031c_qa01/probe_base_ROOT_ONLY.gd"
## Root-only bounded neighborhood checks. No water/facing/World/service repeat.
const FIXTURE := "res://build/world_cities_20261031d_qa01/cities_inputs_READY.json"
const SIZE := Vector2(5632,4096)
const MARKET := &"ch4_s3_luoyang_market"
const REGION := "luoyang_civic_market_region_27d"
const LEGACY_UV := Vector2(.380859375,.78125)

func _watch() -> void:
	await create_timer(60.0,true,false,true).timeout
	if not done:need(false,"HARD60S_CITY_NEW_NEIGHBORHOODS_ONLY");finish()

func boot(_domain: String) -> bool:
	directory="res://build/world_cities_20261031d_qa01/cities_actual/"+str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"EARLIEST_CHECKPOINT_SUSPEND"):return false
	router=root.get_node("SceneRouter")
	cfg=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)) as Dictionary
	for path: String in cfg.pins:
		if not need(FileAccess.get_sha256(path)==String(cfg.pins[path]),"CITY31D_EXPLICIT_FINAL_PIN:"+path):return false
	var registry: Script=load(String(cfg.registry)) as Script
	return need(registry!=null and registry.call("source_valid")==true,"NATIVE226_SOURCE_VALID")

func city_restore(path: String,old_version: int,new_version: int,covered: Vector2,target: Vector2,unchanged: Vector2,illegal: Vector2) -> bool:
	var author: Script=load(path) as Script
	if not need(author!=null and int(author.get_script_constant_map().get("VERSION",-1))==new_version,"CANONICAL_CITY_NEW_VERSION:"+path):return false
	var migrated: Variant=author.call("migration",covered/SIZE,old_version)
	var retained: Variant=author.call("migration",unchanged/SIZE,old_version)
	var refused: Variant=author.call("migration",illegal/SIZE,old_version)
	records.append({"public_author_migration":path,"old_version":old_version,"new_version":new_version,"covered_old_foot":covered,"migrated":migrated,"declared_target":target,"unchanged_old_foot":unchanged,"retained":retained,"old_illegal":illegal,"refused":refused,"no_real_save_API":true})
	if not need(bool(author.call("safe_foot_before31d",covered/SIZE)) and not bool(author.call("safe_foot",covered/SIZE)) and migrated is Vector2 and (migrated as Vector2).distance_to(target/SIZE)<.0000001 and bool(author.call("safe_foot",target/SIZE)),"ONLY_OLD_VALID_NEW_BODY_COVERED_TO_DECLARED_CLEAR_TARGET"):return false
	if not need(retained is Vector2 and (retained as Vector2).distance_to(unchanged/SIZE)<.0000001 and bool(author.call("safe_foot_before31d",unchanged/SIZE)) and bool(author.call("safe_foot",unchanged/SIZE)),"UNCHANGED_OLD_VALID_FOOT_EXACT"):return false
	if not need(not bool(author.call("safe_foot_before31d",illegal/SIZE)) and refused==null and author.call("migration",covered/SIZE,new_version)==null and author.call("migration",covered/SIZE,777)==null and author.call("migration",Vector2(-.01,.5),old_version)==null,"OLD_ILLEGAL_CURRENT_BLOCKED_UNKNOWN_VERSION_AND_OUTSIDE_REJECT"):return false
	return true

func extension(point: Vector2) -> Dictionary:
	return {"region_id":REGION,"revision":1,"logical_id":String(MARKET),"global_foot_px":[point.x,point.y]}

func region_case(point: Vector2,expected: Variant,patch: Dictionary={}) -> bool:
	var entry: Script=load(String(cfg.region_entry)) as Script
	var request: Dictionary=extension(point);request.merge(patch,true)
	var result: Dictionary=entry.call("prepare",MARKET,LEGACY_UV,3,request,String(cfg.region_manifest_sha))
	entry.call("abort_pending")
	records.append({"public_RegionEntry_prepare":request,"result":result,"pending_aborted_after_case":true})
	if expected==null:return need(result.get("ok")!=true,"REGION_REJECT_OLD_ILLEGAL_OR_UNKNOWN_ID_REVISION")
	return need(result.get("ok")==true and result.get("world_uv") is Vector2 and (result.world_uv*Vector2(6144,4608)).distance_to(expected as Vector2)<.01,"REGION_PUBLIC_OLD_FOOT_RESTORE_OR_EXACT_PRESERVATION")

func ly_actual() -> bool:
	if not region_case(Vector2(2017,3650),Vector2(2640,4280)):return false
	if not region_case(Vector2(2490,3400),Vector2(2640,4280)):return false
	if not region_case(Vector2(2730,3930),Vector2(2730,3930)):return false
	if not region_case(Vector2(2017,3800),null):return false
	if not region_case(Vector2(2017,3650),null,{"revision":777}):return false
	if not region_case(Vector2(2017,3650),null,{"region_id":"unknown_region"}):return false
	var dispatch: Script=load(String(cfg.region_dispatch)) as Script
	var old: int=current_scene.get_instance_id()
	records.append({"public_RegionDispatch_start":extension(Vector2(2640,4280)),"legacy_uv":LEGACY_UV,"legacy_version":3,"not_fake_owner_or_global_as_legacy_UV":true})
	if not need(dispatch.call("start",router,MARKET,LEGACY_UV,"",3,extension(Vector2(2640,4280)))==true,"PUBLIC_LY_REGION_START"):return false
	if not await ready_field(MARKET,old):return false
	if not need(foot().distance_to(Vector2(2640,4280))<.04,"LY_AUTHENTICATED_EXACT_WORKCOURT_ARRIVAL"):return false
	if not await walk(Vector2(2640,4220),25):return false
	await shot("luoyang_complete_cloth_workcourt_and_side_lanes")
	return true

func _run() -> void:
	if not await boot("cities"):finish();return
	if not city_restore(String(cfg.j_author),31,32,Vector2(2710,900),Vector2(2816,1450),Vector2(2816,1450),Vector2(2250,1700)):finish();return
	if not city_restore(String(cfg.x_author),30,31,Vector2(560,1180),Vector2(1380,2520),Vector2(1536,2520),Vector2(700,1450)):finish();return
	var j:=&"openworld_jinling_city";var x:=&"openworld_xiangzhou_city"
	if not await setup(j,null,32) or not await setup(j,Vector2(2816,1450)/SIZE,32):finish();return
	if not need(foot().distance_to(Vector2(2816,1450))<.04,"J_CURRENT32_EXACT_NEW_NEIGHBORHOOD"):finish();return
	if not await walk(Vector2(2880,1450),25):finish();return
	await shot("jinling_silk_rear_lanes_complete_mixed_buildings")
	if not await setup(x,null,31) or not await setup(x,Vector2(1410,2430)/SIZE,31):finish();return
	if not need(foot().distance_to(Vector2(1410,2430))<.04,"X_CURRENT31_EXACT_NEW_SUPPLY_COURT"):finish();return
	if not await walk(Vector2(1410,2494),25):finish();return
	await shot("xiangzhou_warehouse_courts_and_service_passage")
	if not await ly_actual():finish();return
	finish()

func finish() -> void:
	if done:return
	key(KEY_NONE);done=true
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"input_events":inputs,"records":records,"scope":"31d new city neighborhoods only: three disclosed local setups/one real short leg and image per city; pure public limited old-foot restoration/invalid rejection; no repeated water/NPC/World/stairs/service matrices","real_save_API_calls":0},"\t"));file.close()
	quit(0 if errors.is_empty() else 1)
