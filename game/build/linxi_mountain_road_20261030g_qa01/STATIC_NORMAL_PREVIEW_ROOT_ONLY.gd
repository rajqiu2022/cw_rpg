extends SceneTree
## Optional Root-only live Field render. Zero Input events, motion cases or user save loading.
const QA := "res://build/linxi_mountain_road_20261030g_qa01/"
const FIXTURE := QA+"STATIC_NORMAL_PREVIEW_ROOT_ONLY.json"
const FACTS_PS := QA+"preview_facts_READONLY_ROOT_ONLY.ps1"
const FACTS_SHA := "b7380f3dfc3036a7a672a9d25aa5beb7327802a120b64bbd2244b6e23b4e50c6"
const ID: StringName = &"ch1_s1_road"
const SIZE := Vector2(4608,3456)
const FIELD := "res://build/linxi_mountain_road_20261030g_system01/road_field.tscn"
var checks: int=0
var errors: Array[String]=[]
var records: Array=[]
var spec: Dictionary={}
var first_facts: Dictionary={}
var finished: bool=false
var checkpoint_suspended_at_first_bridge: bool=false
var router: Node
var game: Node
var dialog: Node
var output: String
func _initialize() -> void:
	# Catch the autoload before its _ready/focus notifications, with no await.
	root.child_entered_tree.connect(_early_root_child)
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge!=null:_early_root_child(bridge)
	_watchdog.call_deferred();_run.call_deferred()
func _early_root_child(node: Node) -> void:
	if node.name==&"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true)
		checkpoint_suspended_at_first_bridge=bool(node.call("is_checkpoint_saves_suspended"))
func _watchdog() -> void:
	await create_timer(55.0,true,false,true).timeout
	if not finished:need(false,"55S_WATCHDOG_NATURAL_QUIT_NO_INPUT_OR_RECOVERY");finish()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("ROAD30G_RENDER_FAIL ",label)
	return ok
func exact_facts(label: String) -> Dictionary:
	if output.is_empty():return {}
	var path: String=output+"/"+label+"_facts.json"
	var log: Array=[]
	var code: int=OS.execute("powershell.exe",PackedStringArray(["-NoProfile","-NonInteractive","-File",ProjectSettings.globalize_path(FACTS_PS),"-FixturePath",ProjectSettings.globalize_path(FIXTURE),"-OutputPath",ProjectSettings.globalize_path(path)]),log,true,false)
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	records.append({"phase":"readonly_source_and171save_SHA_bytes_exact_UTC_ticks","label":label,"exit_code":code,"output":log,"path":path,"no_save_deserialization":true})
	if not need(code==0 and raw is Dictionary,"EXACT_METADATA_HELPER:"+label):return {}
	return raw as Dictionary
func state() -> Dictionary:
	var save: Node=root.get_node("SaveManager")
	var hero: Resource=game.get("player") as Resource
	var party: Array=[]
	for member: Resource in game.get("party"):party.append({"instance":str(member.get_instance_id()),"stats":save.call("_serialize_stats",member)})
	var weather: Node=root.get_node("WeatherManager")
	return {"hero_instance":str(hero.get_instance_id()),"hero":save.call("_serialize_stats",hero),"party":party,"gold":game.get("gold"),"flags":game.get("flags").duplicate(true),"quests":root.get_node("QuestManager").call("to_dict"),"inventory":root.get_node("Inventory").call("to_dict"),"bounties":root.get_node("BountyManager").call("to_dict"),"weather":{"id":weather.get("current_weather"),"strength":weather.get("strength")}}.duplicate(true)
func ids(field: Node) -> Array:
	var out: Array=[]
	for value: Variant in field.call("road_static_identity"):
		out.append(str(value.get_instance_id()) if value is Object and is_instance_valid(value) else str(value))
	return out
func foot(field: Node) -> Vector2:
	var world: Node2D=field.get("world_container") as Node2D
	var actor: Node2D=field.get("_player") as Node2D
	return world.to_local(actor.global_position)
func _run() -> void:
	output=QA+"static_normal_preview/%d"%OS.get_process_id()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not need(raw is Dictionary and raw.get("ready")==true,"ROOT_FROZEN_POSTDEPLOY_FIXTURE_REQUIRED"):finish();return
	spec=raw
	if not need(checkpoint_suspended_at_first_bridge and root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"EARLIEST_BRIDGE_SUSPEND_BEFORE_ANY_TRANSITION"):finish();return
	if not need(FileAccess.get_sha256(FACTS_PS)==FACTS_SHA and spec.registered_save_paths.size()==171,"FROZEN_READONLY_HELPER_AND171_REGISTERED_PATHS"):finish();return
	first_facts=exact_facts("first")
	if first_facts.is_empty():finish();return
	for path: String in spec.fixed_sources:
		if not need(first_facts.sources[path].get("sha256")==spec.fixed_sources[path],"POSTDEPLOY_SOURCE_PIN:"+path):finish();return
	router=root.get_node("SceneRouter");game=root.get_node("GameState");dialog=root.get_node("DialogPlayer")
	var before: Dictionary=state()
	if not need(not dialog.call("is_playing") and not bool(game.get("flags").get("seen_ch1_road_intro",false)),"FRESH_PRIVATE_DEFAULT_STATE_NO_USER_SAVE_LOADED"):finish();return
	# World is the default router state. First public default setup is NOT a World portal test.
	if not need(router.call("go_field_smart",ID,null,"",-1,-1)==true,"PUBLIC_DEFAULT_BOOTSTRAP_NOT_WORLD_ENTRY_VALIDATION"):finish();return
	var field: Node=await wait_field(true)
	if field==null or finished:finish();return
	var start_ids: Array=ids(field);var start_foot: Vector2=foot(field)
	var start: Dictionary=state()
	records.append({"phase":"real_intro_start","before_bootstrap":before,"at_start":start,"field_static_ids":start_ids,"foot":start_foot,"once_flag_set_by_original_Field_before_DialogPlayer":true,"private_flag_writes_by_QA":0})
	var expected: Array[String]=["start","meta","hint"]
	for node_id: String in expected:
		var script: Resource=dialog.get("_current_script") as Resource
		var node: Resource=dialog.get("_current_node") as Resource
		if not need(dialog.call("is_playing") and script!=null and String(script.get("dialog_id"))=="ch1_road_intro" and node!=null and String(node.get("node_id"))==node_id and not node.call("has_choices"),"ORIGINAL_NO_CHOICE_INTRO_NODE:"+node_id):finish();return
		records.append({"phase":"public_DialogPlayer.advance_not_Input","node":node_id,"state_before_advance":state()})
		dialog.call("advance")
		await process_frame
	field=await wait_field(false)
	if field==null or finished:finish();return
	var after: Dictionary=state()
	if not need(ids(field)==start_ids and foot(field).distance_to(start_foot)<=.1,"INTRO_DYNAMIC_REFRESH_PRESERVES_STATIC_PLAYER_CAMERA_MINI_AND_FOOT"):finish();return
	if not verify_intro_delta(before,after):finish();return
	records.append({"phase":"real_intro_complete_private_state_only","before":before,"after":after,"dynamic_refresh":field.call("get_road_dynamic_refresh_state"),"static_identity_preserved":ids(field)==start_ids,"seen_flag_and_main_quest_are_real_original_side_effects_not_rolled_back":true})
	for shot: Dictionary in [{"name":"main_road_bamboo_crags_portrait_normal","foot":Vector2(1200,2700)},{"name":"cave_return_adult_scale_portrait_normal","foot":Vector2(2400,1610)}]:
		if not need(router.call("go_field_smart",ID,shot.foot/SIZE,"",-1,3003)==true,"PUBLIC_SAME_ID3003_NEAR_RENDER_SETUP:"+String(shot.name)):finish();return
		field=await wait_field(false)
		if field==null or finished:finish();return
		if not need(foot(field).distance_to(shot.foot)<=1,"EXACT_PUBLIC_NEAR_FOOT:"+String(shot.name)):finish();return
		if not await capture(field,String(shot.name)):finish();return
		if not need(state()==after,"NO_FURTHER_QUEST_INVENTORY_HERO_FLAG_CHANGE_FROM_RENDER_SETUP"):finish();return
	finish()
func verify_intro_delta(before: Dictionary,after: Dictionary) -> bool:
	for key: String in ["hero_instance","hero","party","gold","inventory","bounties"]:
		if not need(before[key]==after[key],"INTRO_NO_ITEMS_REWARDS_OR_HERO_MUTATION:"+key):return false
	var expected_flags: Dictionary=before.flags.duplicate(true);expected_flags["seen_ch1_road_intro"]=true
	if not need(after.flags==expected_flags,"ONLY_REAL_ORIGINAL_ONCE_FLAG_ADDED"):return false
	var quests: Dictionary=before.quests.duplicate(true);quests["q_ch1_main_road"]=1
	return need(after.quests==quests and String(after.weather.id)=="rain_light" and is_equal_approx(float(after.weather.strength),.8),"ONLY_ORIGINAL_MAIN_QUEST_ACCEPT_AND_RAIN_EFFECT_NO_COMPLETION")
func wait_field(require_intro: bool) -> Node:
	var started: int=Time.get_ticks_msec()
	while Time.get_ticks_msec()-started<14000 and not finished:
		await process_frame
		var field: Node=current_scene
		if field==null or field.scene_file_path!=FIELD or not field.has_method("get_field_loading_state"):continue
		var loading: Dictionary=field.call("get_field_loading_state")
		if loading.get("failed")==true:need(false,"NEW_ROAD_FIELD_LOAD_FAILED");return null
		var manager: Node=root.get_node("LoadingManager")
		if loading.get("complete")!=true or String(loading.get("scene_id"))!=String(ID) or manager.get("_transition_active")==true or manager.get("_external_active")==true:continue
		if bool(dialog.call("is_playing"))!=require_intro or field.get("_scene_refresh_pending")==true:continue
		await process_frame
		return field
	need(false,"14S_RENDER_FIELD_WAIT_NO_PRIVATE_DIALOG_CLOSE_OR_RECOVERY");return null
func capture(field: Node,label: String) -> bool:
	var mini: Control=field.get("_world_travel_minimap") as Control
	var camera: Camera2D=field.get("_world_camera") as Camera2D
	var actor: Node2D=field.get("_player") as Node2D
	if not need(mini!=null and camera!=null and actor!=null and camera.get_parent()==actor and camera.zoom==Vector2.ONE,"ORIGINAL_NORMAL_FOLLOW_CAMERA_NOT_QA_OVERVIEW"):return false
	var started: int=Time.get_ticks_msec();var debug: Dictionary={}
	while Time.get_ticks_msec()-started<5000 and not finished:
		debug=mini.call("get_debug_state")
		if debug.get("visual_cache_ready")==true:break
		await process_frame
	if finished:return false
	var marker: Control=mini.get_node_or_null("PlayerPortraitMarker") as Control
	var portrait: Dictionary=debug.get("player_portrait_marker",{})
	var actual: String=String((game.get("player") as Resource).get("portrait_path"))
	if not need(marker!=null and marker.is_visible_in_tree() and mini.is_visible_in_tree() and portrait.get("requested_portrait_path")==actual and portrait.get("portrait_path")==actual and portrait.get("fallback_kind")=="NONE" and debug.get("legacy_arrow_visible")==false,"REAL_HERO_PORTRAIT_AND_NO_LEGACY_ARROW"):return false
	if not need(debug.get("visual_cache_ready")==true and int(debug.get("cache_render_requests",0))==1 and int(debug.get("static_build_count",0))==1,"ONE_SHOT_REAL_SCENE_CACHE_NOT_ABSTRACT_OR_PER_FRAME_REBUILD"):return false
	var identity: Array=ids(field);var at: Vector2=foot(field)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	if finished:return false
	if not need(root.get_viewport().get_visible_rect().size==Vector2(1920,1080) and ids(field)==identity and foot(field).distance_to(at)<=.1,"NORMAL1920_1080_RENDER_NO_INPUT_OR_ACTOR_MOVEMENT"):return false
	var image: Image=root.get_viewport().get_texture().get_image()
	var path: String=output+"/"+label+".png"
	if not need(image!=null and image.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"NEW_IMMUTABLE_NORMAL_RENDER_IMAGE"):return false
	DirAccess.make_dir_recursive_absolute(output)
	if not need(image.save_png(path)==OK,"NORMAL_RENDER_CAPTURE"):return false
	records.append({"phase":"public_near_setup_static_normal_render_not_continuous_route","name":label,"image":path,"image_sha256":FileAccess.get_sha256(path),"foot":at,"camera_zoom":camera.zoom,"field_instance":str(field.get_instance_id()),"player_instance":str(actor.get_instance_id()),"portrait_minimap":debug,"dynamic_refresh":field.call("get_road_dynamic_refresh_state"),"movement_or_Physics_route_validation":false})
	return true
func finish() -> void:
	if finished:return
	finished=true
	var final_facts: Dictionary=exact_facts("final") if not first_facts.is_empty() else {}
	if not first_facts.is_empty():
		need(not final_facts.is_empty() and final_facts.get("sources")==first_facts.get("sources"),"SOURCE_SHA_BYTES_EXACT_TICKS_FIRST_FINAL")
		need(not final_facts.is_empty() and final_facts.get("saves")==first_facts.get("saves") and final_facts.get("save_stable")==true,"171SAVE_SHA_BYTES_EXACT_TICKS_FIRST_FINAL_RECORD_EXTERNAL_CHANGES_NO_ROLLBACK")
	if output.is_empty():output=QA+"static_normal_preview/%d"%OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(output)
	var path: String=output+"/result.json"
	if FileAccess.file_exists(path):quit(2);return
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"first_exact_facts":first_facts,"final_exact_facts":final_facts,"scope":"OPTIONAL_LIVE_FIELD_STATIC_NORMAL_RENDER_ONLY_NOT_WORLD_ENTRY_OR_MOVEMENT_PHYSICS_ACCEPTANCE","input_events_injected":0,"system_input":0,"private_seen_flag_writes":0,"actor_or_camera_writes":0,"save_load_calls":0,"save_contents_deserialized":false,"save_writes_requested":0,"checkpoint_remains_suspended_until_owned_process_exits":true,"user139344_or_editor_controls":0,"source_changes_or_production_writes":0},"\t")+"\n");file.close()
	print("ROAD30G_STATIC_NORMAL_PREVIEW_RESULT ",checks," / ",errors.size());quit(0 if errors.is_empty() else 1)
