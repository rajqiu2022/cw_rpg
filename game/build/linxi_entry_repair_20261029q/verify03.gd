extends "res://build/linxi_entry_repair_20261029q/probe01.gd"
var checks:Array=[]
func check(name:String,ok:bool)->bool:
	checks.append({"name":name,"ok":ok});print(name,": ",ok);return ok
func origin(f:Node)->Vector2:
	return f.get("_player").position/f.get("_world_size")
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var authority=load("res://scripts/city/luoyang_execution_authority_20261022ap.gd")
	var header:Dictionary=authority.header()
	if not check("source_header",not header.is_empty()):finish(false);return
	var router_path:="res://scripts/autoload/scene_router.gd"
	var owned:Dictionary=header.owned[router_path]
	check("successor_18_edges",owned.edges.size()==18)
	check("new_exact_inverse",authority.edge_valid(owned.edges[-1],router_path,owned.current_sha256,header.source_sha256))
	check("historical_admission",authority.approved(router_path,"d25da6fe7f5dd4ec47a7d6821163acc8c51862c40207facd3e7fa6ebe2d586bc"))
	check("unknown_rejected",not authority.approved(router_path,"0".repeat(64)))
	check("culture_readiness",load("res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd").readiness().get("ok",false))
	check("presentation_sources",not load("res://build/luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd").source_paths().is_empty())
	var contract=load("res://scripts/field/linxi_entry_contract_20261029q.gd")
	check("legacy_wall_repaired",contract.repair_saved_origin(Vector2(.835,.60)).is_equal_approx(Vector2(.5,.76)))
	check("legacy_nearest_wall_repaired",contract.repair_saved_origin(Vector2(.837883,.646675)).is_equal_approx(Vector2(.5,.76)))
	check("valid_indoor_restore_preserved",contract.repair_saved_origin(Vector2(.5,.65)).is_equal_approx(Vector2(.5,.65)))
	sr.call("go_field_smart",&"linxi_village_center",Vector2(.835,.470))
	var field:=await wait_field("linxi_village_center")
	if not check("exterior_loaded",field!=null):finish(false);return
	await key(KEY_SPACE);field=await wait_field("linxi_farmer_cottage")
	if not check("space_at_exterior_arrow_enters",field!=null):finish(false);return
	check("entry_at_door",origin(field).is_equal_approx(Vector2(.5,.76)))
	await capture("entry_after03",field)
	await key(KEY_S,7);await key(KEY_SPACE);field=await wait_field("linxi_village_center")
	if not check("real_walk_space_return",field!=null):finish(false);return
	check("return_at_same_arrow",origin(field).is_equal_approx(Vector2(.835,.470)))
	await capture("return_after03",field)
	var remembered:Dictionary=sr.get("_portal_return_spawns")
	remembered["linxi_village_center->linxi_farmer_cottage"]=Vector2(.835,.60)
	await key(KEY_SPACE);field=await wait_field("linxi_farmer_cottage")
	if not check("reenter_with_old_cache",field!=null):finish(false);return
	check("old_cache_uses_door",origin(field).is_equal_approx(Vector2(.5,.76)))
	sr.call("go_field_smart",&"linxi_farmer_cottage",Vector2(.837883,.646675))
	field=await wait_field("linxi_farmer_cottage")
	if not check("legacy_restore_loaded",field!=null):finish(false);return
	check("actual_legacy_restore_at_door",origin(field).is_equal_approx(Vector2(.5,.76)))
	await capture("legacy_after03",field)
	sr.call("go_field_smart",&"linxi_farmer_cottage",Vector2(.75,.65))
	field=await wait_field("linxi_farmer_cottage")
	if not check("wall_test_loaded",field!=null):finish(false);return
	check("wall_test_start_preserved",origin(field).distance_to(Vector2(.75,.65))<.002)
	await key(KEY_D,80)
	check("wall_blocks_walk",origin(field).x<.80 and origin(field).x>=.75)
	await capture("wall_after03",field)
	finish(true)
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open(OUT+"verify03.json",FileAccess.WRITE);f.store_string(JSON.stringify({"finished":ok,"checks":checks,"rows":rows},"\t"));f.close();quit(0 if ok else 1)
