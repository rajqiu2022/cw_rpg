extends SceneTree
## Root-owned short probes. No save APIs, phase/actor/camera/private Router writes.
const CONFIG_ROOT := "res://build/world_sects_cities_20261031c_qa01/"
var errors: Array[String]=[]
var records: Array=[]
var checks := 0
var inputs := 0
var done := false
var suspended := false
var directory := ""
var field: Node
var actor: CharacterBody2D
var world: Node2D
var town: Node2D
var router: Node
var cfg: Dictionary={}
var held: Key=KEY_NONE
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred();_watch.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true);suspended=bool(node.call("is_checkpoint_saves_suspended"))
func _watch() -> void:
	await create_timer(75.0,true,false,true).timeout
	if not done:need(false,"HARD75S");finish()
func _run() -> void:pass
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("POLISH31C_FAIL ",label)
	return ok
func vec(value: Variant) -> Vector2:return Vector2(float(value[0]),float(value[1]))
func boot(domain: String) -> bool:
	directory="res://build/world_sects_cities_20261031c_qa01/"+domain+"_actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"EARLIEST_CHECKPOINT_SUSPEND"):return false
	router=root.get_node("SceneRouter")
	var all: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CONFIG_ROOT+domain+"_inputs_READY.json"));cfg=all[domain]
	var pins: Dictionary=all.common_pins.duplicate();pins.merge(cfg.get("pins",{}),true)
	for path: String in pins:
		if not need(FileAccess.get_sha256(path)==String(pins[path]),"FINAL_NARROW_PIN:"+path):return false
	for path: String in cfg.get("parse_scripts",[]):
		var script: Script=load(path) as Script
		if not need(script!=null and script.can_instantiate(),"SCRIPT_PARSE:"+path):return false
	var registry: Script=load(String(all.registry)) as Script
	if not need(registry!=null and registry.call("source_valid")==true,"MERGED_SOURCE_VALID_FAIL_FAST"):return false
	return true
func key(code: Key) -> void:
	if held==code:return
	if held!=KEY_NONE:
		var up:=InputEventKey.new();up.keycode=held;up.physical_keycode=held;up.pressed=false;Input.parse_input_event(up);inputs+=1
	held=code
	if held!=KEY_NONE:
		var down:=InputEventKey.new();down.keycode=held;down.physical_keycode=held;down.pressed=true;Input.parse_input_event(down);inputs+=1
func tick() -> void:await physics_frame;await process_frame
func space() -> void:key(KEY_SPACE);await tick();key(KEY_NONE);await tick()
func ready_field(id: StringName,old: int=0) -> bool:
	var until: int=Time.get_ticks_msec()+16000
	while not done and Time.get_ticks_msec()<until:
		await process_frame
		if current_scene==null or current_scene.get_instance_id()==old or router.call("get_current_field_id")!=id:continue
		if bool(root.get_node("LoadingManager").get("_transition_active")):continue
		if current_scene.has_method("get_field_loading_state"):
			var state: Dictionary=current_scene.call("get_field_loading_state")
			if state.get("failed",false):records.append({"load_failure":state});return need(false,"FIELD_LOAD_FAILED:"+String(id))
			if not state.get("complete",false):continue
		var candidate: CharacterBody2D=current_scene.get("_player") as CharacterBody2D
		if candidate==null or not bool(candidate.get("can_move")):continue
		field=current_scene;actor=candidate;world=field.get("world_container") as Node2D
		if world==null:continue
		town=field.get("native_town") as Node2D if field.has_method("get_sect_adoption_debug") or field.has_method("get_world_town_debug") else null
		await tick();await tick();return true
	records.append({"requested":id,"current_id":router.call("get_current_field_id"),"current_scene":str(current_scene),"loading_metrics":root.get_node("LoadingManager").get("_field_preload_metrics")})
	return need(false,"FIELD_READY_TIMEOUT:"+String(id))
func setup(id: StringName,uv: Variant,version: int=-1) -> bool:
	key(KEY_NONE);var old: int=current_scene.get_instance_id() if current_scene!=null else 0
	records.append({"public_setup_not_continuous_travel":id,"uv":uv,"local_version":version})
	if not need(router.call("go_field_smart",id,uv,"",15 if id==&"world_map_jianghu" else -1,version)==true,"PUBLIC_SETUP:"+String(id)):return false
	return await ready_field(id,old)
func foot() -> Vector2:return world.to_local(actor.global_position)
func walk(target: Vector2,max_frames: int=120) -> bool:
	var start: Vector2=foot()
	for frame: int in range(max_frames):
		var delta: Vector2=target-foot()
		if delta.length()<4.8:break
		key((KEY_D if delta.x>0 else KEY_A) if absf(delta.x)>absf(delta.y) else (KEY_S if delta.y>0 else KEY_W));await tick()
	key(KEY_NONE);await tick();records.append({"real_short_leg_start":start,"target":target,"end":foot()})
	return need(foot().distance_to(target)<7,"REAL_SHORT_LEG")
func enter(id: StringName) -> bool:
	var old: int=current_scene.get_instance_id();await space();return await ready_field(id,old)
func shot(label: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image();var path: String=directory+"/"+label+".png"
	if need(image!=null and image.save_png(path)==OK,"NORMAL_IMAGE:"+label):records.append({"normal_image":path,"sha256":FileAccess.get_sha256(path),"foot":foot()})
func finish() -> void:
	if done:return
	key(KEY_NONE);done=true
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"input_events":inputs,"records":records,"scope":"31c new domains only; local public setups explicitly noncontinuous; no real save APIs; inherited successful matrices not rerun"},"\t"));file.close()
	quit(0 if errors.is_empty() else 1)
