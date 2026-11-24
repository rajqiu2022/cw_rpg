extends SceneTree
const OUT="res://build/linxi_entry_repair_20261029q/"
var sr:Node
var lm:Node
var rows:Array=[]
func _initialize()->void:run.call_deferred()
func wait_field(id:String)->Node:
	var start:=Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<15000:
		await process_frame
		var f:=current_scene
		if f==null or not f.has_method("get_field_loading_state"):continue
		var s:Dictionary=f.call("get_field_loading_state")
		if s.get("scene_id")!=id:continue
		if s.get("failed"):return null
		if s.get("complete") and not lm.get("_transition_active") and not lm.get("_external_active"):
			await physics_frame;await RenderingServer.frame_post_draw;return f
	return null
func key(code:int,ticks:int=1)->void:
	var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;Input.parse_input_event(e);Input.flush_buffered_events()
	for i in range(ticks):await physics_frame
	e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=false;Input.parse_input_event(e);Input.flush_buffered_events();await physics_frame
func capture(label:String,f:Node)->void:
	var player:Node2D=f.get("_player");var scene:Resource=f.get("_current_scene");var size:Vector2=f.get("_world_size")
	var portals:Array=[]
	for z in f.get("_exit_nodes"):portals.append({"position":z.position,"target":z.target_scene_id,"target_spawn":z.target_spawn_pos})
	rows.append({"label":label,"scene":scene.scene_id,"world_size":size,"player_origin":player.position,"normalized_origin":player.position/size,"visual_foot_offset":player.call("_visual_foot_offset"),"portals":portals,"candidate_right_wall_accepted":f.call("_spawn_has_foot_clearance",scene,Vector2(.835,.60))})
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OUT+label+".png")
func finish(ok:bool)->void:
	var f:=FileAccess.open(OUT+"probe01.json",FileAccess.WRITE);f.store_string(JSON.stringify({"finished":ok,"rows":rows},"\t"));f.close();quit(0 if ok else 1)
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	sr.call("go_field_smart",&"linxi_village_center",Vector2(.835,.470))
	var field:=await wait_field("linxi_village_center")
	if field==null:finish(false);return
	await key(KEY_SPACE);field=await wait_field("linxi_farmer_cottage")
	if field==null:finish(false);return
	await capture("normal_before",field)
	# Reproduce a legacy remembered/saved foot on the right wall without reading user saves.
	sr.call("go_field_smart",&"linxi_farmer_cottage",Vector2(.835,.60))
	field=await wait_field("linxi_farmer_cottage")
	if field==null:finish(false);return
	await capture("legacy_before",field);finish(true)
