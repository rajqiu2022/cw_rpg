extends SceneTree
var failures:Array[String]=[]
var checks:int=0
var inputs:int=0
var done:bool=false
var out:String
var records:Array=[]
func _initialize()->void:
	root.child_entered_tree.connect(_early)
	for node:Node in root.get_children():_early(node)
	_run.call_deferred();_watch.call_deferred()
func _early(n:Node)->void:
	if n.name==&"PlatformBridge":n.call("set_checkpoint_saves_suspended",true)
func _watch()->void:
	await create_timer(110,true,false,true).timeout
	if not done:check(false,"WATCHDOG110");finish()
func check(ok:bool,label:String)->bool:
	checks+=1
	print("ADVENTURE_CHECK ",label," ",ok)
	if not ok:failures.append(label)
	return ok
func ready_field(id:String)->Node:
	var began:int=Time.get_ticks_msec()
	while Time.get_ticks_msec()-began<22000 and not done:
		await process_frame
		if current_scene==null or not current_scene.has_method("get_field_loading_state"):continue
		var state:Dictionary=current_scene.call("get_field_loading_state")
		if state.get("complete")!=true or state.get("failed")==true:continue
		if String(root.get_node("SceneRouter").call("get_current_field_id"))!=id:continue
		if bool(root.get_node("LoadingManager").get("_transition_active")):continue
		if root.get_node("DialogPlayer").call("is_playing"):
			root.get_node("DialogPlayer").call("advance");continue
		await create_timer(.5).timeout
		return current_scene
	check(false,"READY:"+id);return null
func key(code:Key)->void:
	for down:bool in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
		Input.parse_input_event(event);inputs+=1;await process_frame
	await create_timer(.2).timeout
func shot(name:String)->void:
	await RenderingServer.frame_post_draw
	var image:Image=root.get_viewport().get_texture().get_image()
	var path:String=out+"/"+name+".png"
	check(image!=null and image.save_png(path)==OK,"IMAGE:"+name)
	records.append({"image":path,"sha256":FileAccess.get_sha256(path)})
func go(id:String,uv:Vector2)->Node:
	if not check(root.get_node("SceneRouter").call("go_field_smart",StringName(id),uv,"",-1,-1)==true,"PUBLIC_GO:"+id):return null
	return await ready_field(id)
func _run()->void:
	out="res://build/adventure_20261030k_root01/live01/%d"%OS.get_process_id();DirAccess.make_dir_recursive_absolute(out)
	if not check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"SAVES_SUSPENDED"):finish();return
	var adventure:Node=root.get_node("AdventureRuntime")
	if not check(adventure.get("_maps").size()==3,"THREE_MAPS_LOADED"):finish();return
	var life:Node=root.get_node("LifeSkills")
	var inv:Node=root.get_node("Inventory")
	var rows:Array=[
		["adventure_zhuwei_hunting_ground","ch1_s3_zhuwei_forest",Vector2(680,850),"forest_old_marks"],
		["adventure_xiangzhou_deep_mine","openworld_xiangzhou_mine_valley",Vector2(1150,790),"mine_old_cut"],
		["adventure_luoyang_riverside_route","ch4_s4_ancient_temple",Vector2(1460,1590),"luoyang_shelter_observation"]]
	for row:Array in rows:
		var field:Node=await go(row[0],row[2]/Vector2(4096,3072))
		if field==null:finish();return
		if not check(field.get("_world_size")==Vector2(4096,3072),"WORLD_SIZE:"+row[0]):finish();return
		check(adventure.get("_features").has(row[3]),"FEATURE_INSTALLED:"+row[3])
		await shot(row[0])
		await key(KEY_G)
		if not check(adventure.call("get_adventure_state").modal_open,"REAL_G_CLUE:"+row[3]):finish();return
		await key(KEY_ENTER)
		if not check(adventure.call("get_adventure_state").progress.get("viewed",{}).get(row[3])==true and field.get("_system_panel_open")==false,"REAL_CLUE_CONFIRM_RELEASE:"+row[3]):finish();return
		if row[0]=="adventure_zhuwei_hunting_ground":
			field=await go(row[0],Vector2(1120,2090)/Vector2(4096,3072))
			if field==null:finish();return
			var before:int=inv.call("count_of",&"herb_bundle")
			await key(KEY_F)
			if not check(inv.call("count_of",&"herb_bundle")==before+2,"NEW_HUNTING_REAL_F_TWO_HERBS"):finish();return
		field=await go(row[0],Vector2(.5,.93) if row[0]=="adventure_luoyang_riverside_route" else Vector2(.5,.9))
		if field==null:finish();return
		await key(KEY_SPACE)
		field=await ready_field(row[1])
		if field==null:finish();return
		check(true,"REAL_SPACE_RETURN:"+row[1])
		if row[0]!="adventure_luoyang_riverside_route":
			check(String(adventure.get("_near"))=="entry_"+row[0],"CONNECTOR_NEAR_RETURN:"+row[0])
			await key(KEY_G)
			field=await ready_field(row[0])
			if field==null:finish();return
			check(true,"REAL_G_ORIGINAL_CONNECTOR:"+row[0])
	check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"SAVES_STILL_SUSPENDED")
	finish()
func finish()->void:
	if done:return
	done=true
	var file:=FileAccess.open(out+"/result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"errors":failures,"inputs":inputs,"records":records,"save_loads":0,"save_writes":0,"public_near_placements_not_continuous_walk":true},"\t")+"\n");file.close()
	print("ADVENTURE_LIVE_RESULT ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
