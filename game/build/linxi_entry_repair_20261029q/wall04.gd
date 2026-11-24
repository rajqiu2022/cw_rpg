extends "res://build/linxi_entry_repair_20261029q/probe01.gd"
var checks:Array=[]
func check(name:String,ok:bool)->bool:
	checks.append({"name":name,"ok":ok});print(name,": ",ok);return ok
func origin(f:Node)->Vector2:
	return f.get("_player").position/f.get("_world_size")
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var contract=load("res://scripts/field/linxi_entry_contract_20261029q.gd")
	check("old_basket_origin_repaired",contract.repair_saved_origin(Vector2(.7875,.65)).is_equal_approx(Vector2(.5,.76)))
	check("door_still_valid",contract.repair_saved_origin(Vector2(.5,.76)).is_equal_approx(Vector2(.5,.76)))
	sr.call("go_field_smart",&"linxi_farmer_cottage",Vector2(.70,.72))
	var field:=await wait_field("linxi_farmer_cottage")
	if not check("field_loaded",field!=null):finish(false);return
	check("start_preserved",origin(field).distance_to(Vector2(.70,.72))<.002)
	await key(KEY_D,50)
	check("baskets_block_before_wall",origin(field).x>.70 and origin(field).x<.735)
	await capture("basket_boundary_after04",field)
	await key(KEY_A,10)
	check("can_leave_boundary",origin(field).x<.71)
	finish(true)
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open(OUT+"wall04.json",FileAccess.WRITE);f.store_string(JSON.stringify({"finished":ok,"checks":checks,"rows":rows},"\t"));f.close();quit(0 if ok else 1)
