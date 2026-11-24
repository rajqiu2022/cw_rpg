extends SceneTree
const OWN := "res://build/desert_city_rework_20261029o_qa/"
var spec: Dictionary={}
var checks:=0
var errors: Array[String]=[]
var records: Array=[]
var source_before: Dictionary={}
var save_before: Dictionary={}
var state_before: Dictionary={}
var began:=0
var input_ticks:=0
var png_count:=0
var m_map_checked:=false
var sr: Node
var gs: Node
var lm: Node
var dp: Node


func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	began=Time.get_ticks_msec()
	spec=JSON.parse_string(FileAccess.get_file_as_string(OWN+"fixture02.json"))
	source_before=file_facts(spec.fixed_sources.keys());save_before=file_facts(spec.registered_save_paths)
	for path: String in spec.fixed_sources:need(source_before[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path)
	sr=root.get_node("SceneRouter");gs=root.get_node("GameState");lm=root.get_node("LoadingManager");dp=root.get_node("DialogPlayer")
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"CHECKPOINT_SAVES_SUSPENDED")
	state_before=live_state()
	need(load(String(spec.overlay_script)).call("source_valid"),"UPDATED_NATIVE_SOURCE_MANIFEST_VALID")
	if not errors.is_empty():finish();return
	for leg: Dictionary in spec.legs:
		if not need(sr.call("go_field_smart",StringName(leg.world_id),point(leg.world_setup_foot)/point(spec.world_size),"",15,-1),"WORLD_SETUP:"+leg.id):finish();return
		var world: Node=await wait_world(String(leg.world_id))
		if world==null:finish();return
		for i in range(4):await physics_frame
		var group: Node=world.get_node_or_null("WorldContainer/ThreeTownWorldAdditions/"+String(leg.id))
		if not need(group!=null,"LIVE_NEW_WORLD_GROUP:"+leg.id):finish();return
		var sprites: Array=[]
		for child in group.get_children():
			if child is Sprite2D:sprites.append(child)
		if not need(sprites.size()==1 and sprites[0].texture.resource_path==String(leg.new_landmark) and sprites[0].scale==Vector2(.46,.46),"ONE_NATIVE_WHOLE_TOWN_COMPOUND:"+leg.id):finish();return
		var original: Resource=world.get("_current_scene")
		need(original.map_layout.portals.size()==16,"ORIGINAL_16_WORLD_PORTALS_UNCHANGED")
		var zones: Array=[]
		for zone in world.get("_exit_nodes"):
			if zone.target_scene_id==String(leg.id):zones.append(zone)
		if not need(zones.size()==1 and zones[0].call("can_enter"),"NEW_LANDMARK_ACTUAL_DOOR_AND_BODY_CLEAR:"+leg.id):finish();return
		if not await capture(String(leg.screenshot_name)+"_world"):finish();return
		await key(KEY_SPACE)
		var wrapper: Node=await wait_town(leg)
		if wrapper==null:finish();return
		var town: Node=wrapper.get_node(String(leg.town_node))
		need(town.actor.global_position.distance_to(point(leg.arrival_foot))<=1,"SAME_NATIVE_ARRIVAL:"+leg.id)
		var texture: Texture2D=town.get_node(String(leg.replacement_node)).texture
		need(texture.resource_path==String(leg.replacement_texture),"FORMAL_SCENE_USES_NEW_NATIVE_MODULE:"+leg.id)
		if not await capture(String(leg.screenshot_name)+"_town"):finish();return
		if not need(wrapper.get("town_exit").call("can_enter"),"FORMAL_EXIT_CLEAR:"+leg.id):finish();return
		await key(KEY_SPACE);world=await wait_world(String(leg.world_id))
		if world==null:finish();return
		need(world.get("_player").position.distance_to(point(leg.world_setup_foot))<=1,"UNCHANGED_WORLD_RETURN_FOOT:"+leg.id)
		need(live_state()==state_before,"SAME_LIVE_SESSION:"+leg.id)
		if not errors.is_empty():finish();return
	finish()
func capture(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var im:=root.get_texture().get_image();var path:=OWN+"actual/"+str(OS.get_process_id())+"/"+name+".png"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not need(im.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"NATIVE_NORMAL_CAPTURE:"+name):return false
	if not need(im.save_png(path)==OK,"SAVED:"+name):return false
	png_count+=1;records.append({"image":path,"sha256":FileAccess.get_sha256(path)});return true
func finish() -> void:
	release_input()
	if not source_before.is_empty():need(source_before==file_facts(source_before.keys()),"SOURCE_FIRST_FINAL")
	if not save_before.is_empty():need(save_before==file_facts(save_before.keys()),"SAVE_FIRST_FINAL_HASH_BYTES_SECONDS")
	var path:=OWN+"actual/"+str(OS.get_process_id())+"/result.json"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir());var f:=FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"errors":errors,"input_ticks":input_ticks,"images":records,"elapsed_ms":Time.get_ticks_msec()-began,"fixture_sha256":FileAccess.get_sha256(OWN+"fixture02.json"),"qa_actor_or_camera_writes":0,"save_writes":0},"\t"));f.close()
	print("DESERT_NATIVE_WORLD ",checks," / ",errors.size()," : ",path);quit(0 if errors.is_empty() else 1)

func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label);printerr("THREE_TOWNS_FAIL ",label)
	return ok

func point(raw: Variant) -> Vector2:
	return Vector2(float(raw[0]),float(raw[1])) if raw is Array and raw.size()==2 else Vector2(INF,INF)

func active() -> bool: return Time.get_ticks_msec()-began<int(spec.get("whole_seconds",120))*1000

func file_facts(paths: Array) -> Dictionary:
	var facts: Dictionary={}
	for path: String in paths:
		if not FileAccess.file_exists(path):facts[path]={"exists":false};continue
		var f:=FileAccess.open(path,FileAccess.READ)
		facts[path]={"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":f.get_length() if f!=null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return facts

func live_state() -> Dictionary:
	var hero: Resource=gs.get("player") as Resource
	var party: Array=[]
	for member: Resource in gs.get("party"):
		party.append({"instance":str(member.get_instance_id()),"data":root.get_node("SaveManager").call("_serialize_stats",member)})
	return {"player_instance":str(hero.get_instance_id()) if hero!=null else "0","player":root.get_node("SaveManager").call("_serialize_stats",hero) if hero!=null else {},"party":party,"gold":gs.get("gold"),"chapter":gs.get("current_chapter"),"flags":gs.get("flags").duplicate(true),"mastery":gs.get("skill_mastery").duplicate(true),"reputation":gs.get("reputation"),"inventory":root.get_node("Inventory").call("to_dict"),"quests":root.get_node("QuestManager").call("to_dict"),"bounties":root.get_node("BountyManager").call("to_dict")}

func wait_world(world_id: String) -> Node:
	var start:=Time.get_ticks_msec()
	while active() and Time.get_ticks_msec()-start<int(spec.entry_seconds)*1000:
		await process_frame
		var field: Node=current_scene
		if field==null or not field.has_method("get_field_loading_state"):continue
		var state: Dictionary=field.call("get_field_loading_state")
		if String(state.get("scene_id"))!=world_id:continue
		if state.get("failed")==true:need(false,"WORLD_LOAD_FAILED");return null
		if state.get("complete")!=true or lm.get("_transition_active")==true or lm.get("_external_active")==true:continue
		var actor: Node=field.get("_player")
		if not is_instance_valid(actor) or actor.get("can_move")!=true or dp.call("is_playing")==true:continue
		await RenderingServer.frame_post_draw
		return field
	need(false,"WORLD_ENTRY_20S_NO_EXTENSION");return null

func wait_town(leg: Dictionary) -> Node:
	var start:=Time.get_ticks_msec()
	while active() and Time.get_ticks_msec()-start<int(spec.entry_seconds)*1000:
		await process_frame
		var wrapper: Node=current_scene
		if wrapper==null or String(wrapper.scene_file_path)!=String(leg.wrapper_scene):continue
		if lm.get("_transition_active")==true or lm.get("_external_active")==true:continue
		var town: Node=wrapper.get_node_or_null(NodePath(leg.town_node))
		if town==null or not is_instance_valid(town.get("actor")):continue
		if town.get("controls_enabled")!=true:continue
		await RenderingServer.frame_post_draw
		return wrapper
	need(false,"TOWN_ENTRY_20S_NO_EXTENSION:"+leg.id);return null

func held_key(code: int,ticks: int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true
	Input.parse_input_event(event);Input.flush_buffered_events();await process_frame
	for _tick: int in range(ticks):await physics_frame;input_ticks+=1
	event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false
	Input.parse_input_event(event);Input.flush_buffered_events();await process_frame;await physics_frame

func key(code: int) -> void: await held_key(code,1)

func release_input() -> void:
	for code: int in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SPACE]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false
		Input.parse_input_event(event)
	Input.flush_buffered_events()
