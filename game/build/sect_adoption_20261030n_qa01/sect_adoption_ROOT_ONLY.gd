extends SceneTree
## Root-only owned process. Local public setups are NOT continuous mountain travel.
const FIXTURE := "res://build/sect_adoption_20261030n_qa01/actual_inputs_READY.json"
const WORLD_SIZE := Vector2(12288,8192)
var errors: Array[String]=[]
var records: Array=[]
var checks := 0
var inputs := 0
var done := false
var suspended := false
var directory := ""
var field: Node
var actor: Node2D
var router: Node
var contract: Script
var held: Key=KEY_NONE

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred();_watch.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true);suspended=bool(node.call("is_checkpoint_saves_suspended"))
func _watch() -> void:
	await create_timer(95.0,true,false,true).timeout
	if not done:need(false,"HARD95S");finish()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("SECT30N_FAIL ",label)
	return ok
func key(code: Key) -> void:
	if held==code:return
	if held!=KEY_NONE:
		var up:=InputEventKey.new();up.keycode=held;up.physical_keycode=held;up.pressed=false;Input.parse_input_event(up);inputs+=1
	held=code
	if held!=KEY_NONE:
		var down:=InputEventKey.new();down.keycode=held;down.physical_keycode=held;down.pressed=true;Input.parse_input_event(down);inputs+=1
func tick() -> void:
	await physics_frame;await process_frame
func space() -> void:
	key(KEY_SPACE);await tick();key(KEY_NONE);await tick()
func ready_field(id: StringName) -> bool:
	var until: int=Time.get_ticks_msec()+15000
	while not done and Time.get_ticks_msec()<until:
		await process_frame
		if router.call("get_current_field_id")!=id or current_scene==null:continue
		if bool(root.get_node("LoadingManager").get("_transition_active")):continue
		if current_scene.has_method("get_field_loading_state"):
			var state: Dictionary=current_scene.call("get_field_loading_state")
			if state.get("failed",false):records.append({"load_failure":state});return need(false,"FIELD_LOAD_FAILED:"+String(id))
			if not state.get("complete",false):continue
		var candidate: Node2D=current_scene.get("_player") as Node2D
		if candidate==null or not bool(candidate.get("can_move")):continue
		field=current_scene;actor=candidate;await tick();return true
	records.append({"timeout_id":id,"router_id":router.call("get_current_field_id"),"current_scene":str(current_scene),"loading_metrics":root.get_node("LoadingManager").get("_field_preload_metrics")})
	return need(false,"FIELD_READY_TIMEOUT:"+String(id))
func setup(id: StringName,uv: Vector2,version: int) -> bool:
	key(KEY_NONE)
	records.append({"public_local_setup_not_continuous_travel":id,"uv":uv,"local_version":version})
	if not need(router.call("go_field_smart",id,uv,"",15 if id==&"world_map_jianghu" else -1,version)==true,"PUBLIC_SETUP_ACCEPTED:"+String(id)):return false
	return await ready_field(id)
func debug() -> Dictionary:return field.call("get_sect_adoption_debug")
func native_near(id: StringName,at: Vector2) -> bool:
	var row: Dictionary=contract.call("town",id)
	if not need(contract.call("safe_native",id,at)==true,"FULL35X25_NEAR_SAFE:"+String(id)):return false
	if not await setup(id,at/Vector2(row.size),3005):return false
	var state: Dictionary=debug();records.append({"near_debug":state})
	return need(Vector2(state.actor_foot).distance_to(at)<.03,"PUBLIC_CURRENT3005_EXACT_FOOT")
func enter_by_space(id: StringName) -> bool:
	await space()
	return await ready_field(id)
func screenshot(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image()
	var path: String=directory+"/"+label+".png"
	if need(image!=null and image.save_png(path)==OK,"NORMAL_CAMERA_IMAGE:"+label):records.append({"normal_image":path,"sha256":FileAccess.get_sha256(path),"debug":debug()})
func finish() -> void:
	if done:return
	key(KEY_NONE);done=true
	var out:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if out!=null:out.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"input_events":inputs,"records":records,"scope":"two original World outer IDs only; public local setups noncontinuous; no save APIs; inherited original inner/bridge matrices not rerun"},"\t"));out.close()
	quit(0 if errors.is_empty() else 1)
func _run() -> void:
	directory="res://build/sect_adoption_20261030n_qa01/actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"EARLIEST_CHECKPOINT_SUSPENDED"):finish();return
	router=root.get_node("SceneRouter")
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	for path: String in fixture.pins:
		if not need(FileAccess.get_sha256(path)==String(fixture.pins[path]),"FINAL_REQUIRED_PIN:"+path):finish();return
	for path: String in fixture.parse_scripts:
		var loaded: Resource=ResourceLoader.load(path)
		if not need(loaded is Script and (loaded as Script).can_instantiate(),"NEW_SCRIPT_LOAD_CAN_INSTANTIATE:"+path):finish();return
	var scene: PackedScene=ResourceLoader.load(fixture.field_scene) as PackedScene
	if not need(scene!=null and scene.can_instantiate(),"NEW_FIELD_SCENE_PARSE_NO_INSTANCE"):finish();return
	contract=load(fixture.contract) as Script
	var registry: Script=load(fixture.registry) as Script
	if not need(registry!=null and registry.call("source_valid")==true,"REG_SOURCE_VALID_FAIL_FAST"):finish();return
	# Four representative pure cases only. Original local restore tag is 1, not map schema 5.
	var w:=&"openworld_wudang_gate"
	var old: Dictionary=contract.call("resolve_spawn",w,Vector2(.5,.875),&"",1,1,true,null)
	var current: Dictionary=contract.call("resolve_spawn",w,Vector2(1700,4100)/Vector2(5200,4400),w,3005,3005,true,null)
	var blocked: Dictionary=contract.call("resolve_spawn",w,Vector2(2700,900)/Vector2(5200,4400),w,3005,3005,true,null)
	var future: Dictionary=contract.call("resolve_spawn",w,null,w,3006,3005,true,null)
	records.append({"four_version_cases":{"old":old,"current":current,"new_body_rejected":blocked,"future_rejected":future}})
	if not need(old.get("ok",false) and current.get("ok",false) and blocked.is_empty() and future.is_empty(),"FOUR_REPRESENTATIVE_VERSION_CASES"):finish();return
	for id: StringName in [w,&"openworld_huashan_forecourt"]:
		var row: Dictionary=contract.call("town",id)
		var raw: Dictionary=contract.call("raw",id)
		var arrival: Vector2=row.arrival
		if not await setup(&"world_map_jianghu",Vector2(row.world_foot)/WORLD_SIZE,-1):finish();return
		var world_container: Node2D=field.get("world_container") as Node2D
		var original_world_foot: Vector2=world_container.to_local(actor.global_position)
		records.append({"original_world_entry_foot":original_world_foot,"target":id})
		if not await enter_by_space(id):finish();return
		var entered: Dictionary=debug();records.append({"original_world_space_entry":entered})
		if not need(Vector2(entered.actor_foot).distance_to(arrival)<.03 and int(entered.npcs.size())==(1 if id==w else 0),"AUTHORED_ARRIVAL_AND_ORIGINAL_NPC_COUNT"):finish();return
		if id==w:
			if not await native_near(id,Vector2(1900,3970)):finish();return
			await space()
			var dialog: Node=root.get_node("DialogPlayer")
			var saw_original := false
			for turn: int in range(4):
				if not bool(dialog.call("is_playing")):break
				var current_script: Resource=dialog.get("_current_script") as Resource
				var current_node: Resource=dialog.get("_current_node") as Resource
				records.append({"real_dialog_id":current_script.get("dialog_id") if current_script!=null else null,"speaker":current_node.get("speaker") if current_node!=null else null,"text":current_node.get("text") if current_node!=null else null})
				if current_script!=null and current_script.get("dialog_id")==&"openworld_wudang_gate_disciple" and current_node!=null and String(current_node.get("speaker"))=="武当守山弟子":saw_original=true
				dialog.call("advance");await tick()
			if not need(saw_original and not bool(dialog.call("is_playing")),"REAL_ORIGINAL_DISCIPLE_SINGLE_NODE_DIALOG"):finish();return
			if not await native_near(id,Vector2(2400,3070)):finish();return
			var begin: Dictionary=debug();var ramp_seen := false;var heights: Array=[]
			for frame: int in range(190):
				key(KEY_W);await tick()
				var state: Dictionary=debug();ramp_seen=ramp_seen or int(state.active_ramp)>=0;heights.append(state.actor_height)
				if float(Vector2(state.actor_foot).y)<=2865:break
			key(KEY_NONE);await tick()
			var end: Dictionary=debug();records.append({"real_MainRise_start":begin,"end":end,"ramp_seen":ramp_seen,"height_samples":heights})
			if not need(int(begin.actor_level)==0 and ramp_seen and int(end.actor_level)==1 and int(end.active_ramp)==-1 and absf(float(end.actor_height)-180)<.01,"TRUE_W_MAINRISE_L0_TO_L1"):finish();return
		var inner_return: Vector2=Vector2(float(raw.inner_return[0]),float(raw.inner_return[1]))
		if not await native_near(id,inner_return):finish();return
		await screenshot("wudang_normal" if id==w else "huashan_normal")
		if not errors.is_empty():finish();return
		var inner: StringName=row.inner_source
		# Exact mapped outer doorway, real Space transition; no zone signals called by QA.
		var inner_arrow: Vector2=Vector2(float(raw.inner_arrow[0]),float(raw.inner_arrow[1]))
		if not await native_near(id,inner_arrow):finish();return
		if not await enter_by_space(inner):finish();return
		var original_inner: SceneScript=load("res://data/scenes/"+String(inner)+".tres") as SceneScript
		var return_uv:=Vector2.ZERO
		for portal: Dictionary in original_inner.map_layout.portals:
			if String(portal.get("target_scene",""))==String(id):return_uv=portal.pos
		if not need(return_uv!=Vector2.ZERO,"ORIGINAL_FIRST_INNER_RETURN_PORTAL_EXISTS"):finish();return
		if not await setup(inner,return_uv,1):finish();return
		if not await enter_by_space(id):finish();return
		var returned: Dictionary=debug();records.append({"original_inner_space_return":returned})
		if not need(Vector2(returned.actor_foot).distance_to(inner_return)<.03 and int(returned.actor_level)==1,"ORIGINAL_INNER_EXACT_NATIVE_RETURN_LEVEL"):finish();return
		var leave: Vector2=Vector2(float(raw.leave_arrow[0]),float(raw.leave_arrow[1]))
		if not await native_near(id,leave):finish();return
		if not await enter_by_space(&"world_map_jianghu"):finish();return
		world_container=field.get("world_container") as Node2D
		var final_world_foot: Vector2=world_container.to_local(actor.global_position)
		records.append({"same_original_world_return_foot":final_world_foot,"expected":original_world_foot})
		if not need(final_world_foot.distance_to(original_world_foot)<.08,"DOWNMOUNTAIN_SAME_ACTUAL_ORIGINAL_WORLD_FOOT"):finish();return
	finish()
