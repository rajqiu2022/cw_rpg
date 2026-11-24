extends SceneTree
## 30h changed-scale/new-bamboo rendering only. Root owns execution; no Input API.
const QA := "res://build/linxi_adult_scale_20261030h_qa01/"
const FIXTURE := QA+"STATIC_NORMAL_PREVIEW_ROOT_ONLY.json"
const FACTS_PS := QA+"preview_facts_READONLY_ROOT_ONLY.ps1"
const FACTS_SHA := "e34a21a32912673d8b13b1cee1c45447fc790d09d77529020e106eb7315b8b16"
const PWSH := "C:/Users/rajqiu/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/powershell/pwsh.exe"
const SOUTH: StringName=&"linxi_village_scrollmap"
const ROAD: StringName=&"ch1_s1_road"
const GREEN := "res://art/modules/linxi_scale_polish_20261030h/green_bamboo.png"
var spec: Dictionary={}
var checks: int=0
var errors: Array[String]=[]
var records: Array=[]
var finished: bool=false
var earliest_suspended: bool=false
var output: String
var router: Node
var game: Node
var dialog: Node
var first_facts: Dictionary={}
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge!=null:_early(bridge)
	_run.call_deferred();_watchdog.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true);earliest_suspended=bool(node.call("is_checkpoint_saves_suspended"))
func _watchdog() -> void:
	await create_timer(55.0,true,false,true).timeout
	if not finished:need(false,"55S_WATCHDOG_NO_INPUT_OR_PRIVATE_RECOVERY");finish()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("LINXI30H_RENDER_FAIL ",label)
	return ok
func exact_facts(label: String) -> Dictionary:
	var path: String=output+"/"+label+"_facts.json";var log: Array=[]
	var code: int=OS.execute(PWSH,PackedStringArray(["-NoProfile","-NonInteractive","-File",ProjectSettings.globalize_path(FACTS_PS),"-FixturePath",ProjectSettings.globalize_path(FIXTURE),"-OutputPath",ProjectSettings.globalize_path(path)]),log,true,false)
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	records.append({"phase":"readonly_first_final_source171save_exact_SHA_bytes_UTCticks","label":label,"code":code,"log":log,"path":path})
	return raw as Dictionary if need(code==0 and raw is Dictionary,"EXACT_METADATA_HELPER:"+label) else {}
func state() -> Dictionary:
	var save: Node=root.get_node("SaveManager");var hero: Resource=game.get("player") as Resource;var party: Array=[]
	for member: Resource in game.get("party"):party.append({"instance":str(member.get_instance_id()),"stats":save.call("_serialize_stats",member)})
	return {"hero_instance":str(hero.get_instance_id()),"hero":save.call("_serialize_stats",hero),"party":party,"gold":game.get("gold"),"flags":game.get("flags").duplicate(true),"quests":root.get_node("QuestManager").call("to_dict"),"inventory":root.get_node("Inventory").call("to_dict"),"bounties":root.get_node("BountyManager").call("to_dict")}.duplicate(true)
func wait_field(id: StringName,intro: bool=false) -> Node:
	var started: int=Time.get_ticks_msec()
	while Time.get_ticks_msec()-started<14000 and not finished:
		await process_frame
		var field: Node=current_scene
		if field==null or not field.has_method("get_field_loading_state"):continue
		var loading: Dictionary=field.call("get_field_loading_state")
		if String(loading.get("scene_id"))!=String(id):continue
		if loading.get("failed")==true:need(false,"REAL_FIELD_LOADING_FAILED:"+String(id));return null
		var manager: Node=root.get_node("LoadingManager")
		if loading.get("complete")!=true or manager.get("_transition_active")==true or manager.get("_external_active")==true:continue
		if bool(dialog.call("is_playing"))!=intro:continue
		if not intro and field.get("_scene_refresh_pending")==true:continue
		await process_frame;return field
	need(false,"14S_REAL_FIELD_RENDER_WAIT:"+String(id));return null
func foot(field: Node) -> Vector2:
	return (field.get("world_container") as Node2D).to_local((field.get("_player") as Node2D).global_position)
func alpha_visual(sprite: Sprite2D) -> Dictionary:
	if sprite==null or sprite.texture==null:return {}
	var image: Image=sprite.texture.get_image()
	if image==null:return {}
	if image.is_compressed():
		if image.decompress()!=OK:return {}
	var cell:=Vector2i(image.get_width()/sprite.hframes,image.get_height()/sprite.vframes)
	var origin: Vector2i=sprite.frame_coords*cell
	var bounds: Rect2i=image.get_region(Rect2i(origin,cell)).get_used_rect()
	var local: Rect2=Rect2(Vector2(bounds.position)+sprite.get_rect().position,Vector2(bounds.size))
	var screen: Rect2=sprite.get_global_transform_with_canvas()*local
	return {"texture":sprite.texture.resource_path,"frame":sprite.frame,"source_cell":cell,"alpha_bounds":bounds,"global_scale":sprite.global_scale,"visible_height_world_px":float(bounds.size.y)*absf(sprite.global_scale.y),"screen_rect":screen,"alpha_not_whole_canvas":true}
func _run() -> void:
	output=QA+"static_normal_preview/%d"%OS.get_process_id()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not need(raw is Dictionary and raw.get("ready")==true,"ROOT_FROZEN_POSTDEPLOY_H_FIXTURE"):finish();return
	spec=raw
	if not need(earliest_suspended and root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"EARLIEST_CHECKPOINT_SUSPENDED"):finish();return
	if not need(FileAccess.get_sha256(FACTS_PS)==FACTS_SHA,"FROZEN_READONLY_FACTS_HELPER"):finish();return
	first_facts=exact_facts("first")
	if first_facts.is_empty():finish();return
	for path: String in spec.fixed_sources:
		if not need(first_facts.sources[path].get("sha256")==spec.fixed_sources[path],"EXACT_POSTDEPLOY_PIN:"+path):finish();return
	router=root.get_node("SceneRouter");game=root.get_node("GameState");dialog=root.get_node("DialogPlayer")
	var before: Dictionary=state()
	if not need(router.call("go_field_smart",SOUTH,null,"",-1,-1)==true,"PUBLIC_DEFAULT_SOUTH_BOOTSTRAP_NOT_WORLD_ENTRY_TEST"):finish();return
	var field: Node=await wait_field(SOUTH)
	if field==null or finished:finish();return
	if not need(router.call("go_field_smart",SOUTH,Vector2(1970,1070)/Vector2(4200,2600),"",-1,3004)==true,"PUBLIC_SAME_ID3004_TEACHER_HERO_NEAR_SETUP"):finish();return
	field=await wait_field(SOUTH)
	if field==null or finished:finish();return
	if not await south_image(field):finish();return
	if not need(state()==before,"SOUTH_RENDER_NO_BUSINESS_OR_HERO_STATE_MUTATION"):finish();return
	# Fresh owned process has no seen flag. Allow only the original intro to run;
	# prior g intro/functional credit is inherited, never private-set or toured.
	if not need(router.call("go_field_smart",ROAD,null,"",-1,-1)==true,"PUBLIC_DEFAULT_ROAD_BOOTSTRAP_RENDER_ONLY"):finish();return
	field=await wait_field(ROAD,true)
	if field==null or finished:finish();return
	var intro_before: Dictionary=state()
	for expected: String in ["start","meta","hint"]:
		var script: Resource=dialog.get("_current_script") as Resource;var node: Resource=dialog.get("_current_node") as Resource
		if not need(script!=null and String(script.get("dialog_id"))=="ch1_road_intro" and node!=null and String(node.get("node_id"))==expected and not node.call("has_choices"),"REAL_ORIGINAL_INTRO_PUBLIC_ADVANCE_ONLY:"+expected):finish();return
		dialog.call("advance");await process_frame
	field=await wait_field(ROAD)
	if field==null or finished:finish();return
	var after_intro: Dictionary=state()
	records.append({"phase":"original_intro_naturally_advanced_for_fresh_render_only","before_road":before,"intro_start":intro_before,"after":after_intro,"private_flag_writes":0,"g_intro_success_inherited_not_new_chapter_tour":true})
	for shot: Dictionary in [{"name":"h_main_road_natural_green_bamboo","foot":Vector2(1200,2700)},{"name":"h_cave_shoulder_ground_blend","foot":Vector2(2400,1610)}]:
		if not need(router.call("go_field_smart",ROAD,shot.foot/Vector2(4608,3456),"",-1,3003)==true,"PUBLIC_SAME_ID3003_ROAD_NEW_VISUAL_NEAR_SETUP"):finish();return
		field=await wait_field(ROAD)
		if field==null or finished:finish();return
		if not need(foot(field).distance_to(shot.foot)<=1,"EXACT_ROAD_PUBLIC_NEAR_FOOT"):finish();return
		var green_nodes: int=0
		for sprite: Sprite2D in field.get("_road_static"):
			if sprite.texture.resource_path==GREEN:green_nodes+=1
		if not need(green_nodes==13,"REAL_FIELD_USES13_FROZEN_GREEN_BAMBOO_MODULES_NOT_GALLERY_ONLY"):finish();return
		records.append({"phase":"new_road_visual_source","green_native_nodes":green_nodes,"new_ground_layout_sha256":FileAccess.get_sha256("res://build/linxi_mountain_road_20261030g_system01/road_layout.json")})
		if not await image(field,String(shot.name),Vector2.ONE):finish();return
		if not need(state()==after_intro,"ROAD_RENDER_ONLY_NO_FURTHER_BUSINESS_STATE_CHANGE"):finish();return
	finish()
func south_image(field: Node) -> bool:
	if not need(field.has_method("get_linxi_adult_visual_debug") and foot(field).distance_to(Vector2(1970,1070))<=1,"REAL_SOUTH_HOST_AND_PUBLIC_FOOT"):return false
	var debug: Dictionary=field.call("get_linxi_adult_visual_debug")
	if not need(String(debug.get("scene_id"))==String(SOUTH) and debug.get("records",[]).size()==11,"ELEVEN_ORIGINAL_SOUTH_ADULT_RECORDS"):return false
	for row: Dictionary in debug.records:
		if not need(row.get("ok")==true and row.get("same_physical_and_business")==true and row.get("same_ground")==true and var_to_bytes(row.before)==var_to_bytes(row.after),"CALIBRATION_EXACT_ORIGINAL_BODY_AREA_PATROL_BUSINESS_FOOT:"+String(row.npc_id)):return false
		if not need(float(row.new_visible_height_px)>=120 and float(row.new_visible_height_px)<=132 and absf(float(row.new_visible_height_px)-float(row.target_visible_height_px))<.01,"TRUE_ALPHA_TARGET_RANGE:"+String(row.npc_id)):return false
	var teacher: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id=="linxi_south_teacher":teacher=npc;break
	var actor: Node2D=field.get("_player") as Node2D
	var hero_visual: Dictionary=alpha_visual(actor.get("sprite") as Sprite2D)
	var teacher_visual: Dictionary=alpha_visual(teacher.sprite) if teacher!=null else {}
	if not need(not hero_visual.is_empty() and not teacher_visual.is_empty(),"REAL_TEACHER_AND_HERO_ACTIVE_ALPHA_FRAMES"):return false
	if not need(absf(float(hero_visual.visible_height_world_px)-128.52)<=1 and absf(float(teacher_visual.visible_height_world_px)-124)<=1 and teacher.position.distance_to(Vector2(1850,1070))<=.1,"ACTIVE_ALPHA_ADULT_SIZE_AND_UNMOVED_TEACHER_GROUND"):return false
	var screen: Rect2=root.get_viewport().get_visible_rect()
	if not need(screen.encloses(hero_visual.screen_rect) and screen.encloses(teacher_visual.screen_rect),"HERO_AND_TEACHER_FULL_VISIBLE_SAME_NORMAL_CAMERA"):return false
	records.append({"phase":"south_active_alpha_calibration_not_canvas_size","hero":hero_visual,"teacher":teacher_visual,"raw_calibration_before_after":debug,"body_sizes_intentionally_original_not_scaled":true,"not_continuous_from_default_bootstrap":true})
	return await image(field,"h_south_teacher_hero_adult_house_normal",Vector2(.9,.9))
func image(field: Node,label: String,zoom: Vector2) -> bool:
	var camera: Camera2D=field.get("_world_camera") as Camera2D;var actor: Node2D=field.get("_player") as Node2D
	if not need(camera!=null and actor!=null and camera.zoom.distance_to(zoom)<.001,"ORIGINAL_NORMAL_CAMERA_NOT_QA_OVERVIEW"):return false
	var at: Vector2=foot(field);var actor_id: int=actor.get_instance_id()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	if finished:return false
	var path: String=output+"/"+label+".png";var pixels: Image=root.get_viewport().get_texture().get_image()
	if not need(pixels!=null and pixels.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path) and actor_id==(field.get("_player") as Node2D).get_instance_id() and foot(field).distance_to(at)<=.1,"NEW_NORMAL1920_IMAGE_NO_ACTOR_MOVEMENT"):return false
	DirAccess.make_dir_recursive_absolute(output)
	if not need(pixels.save_png(path)==OK,"NORMAL_IMAGE_CAPTURE"):return false
	records.append({"phase":"public_near_setup_render_not_continuous_walk_or_World_entry","image":path,"sha256":FileAccess.get_sha256(path),"foot":at,"zoom":camera.zoom,"player_instance":str(actor_id),"scene":field.scene_file_path})
	return true
func finish() -> void:
	if finished:return
	finished=true
	var final: Dictionary=exact_facts("final") if not first_facts.is_empty() else {}
	if not first_facts.is_empty():
		need(not final.is_empty() and final.get("sources")==first_facts.get("sources"),"SOURCE_FIRST_FINAL_EXACT_SHA_BYTES_TICKS")
		need(not final.is_empty() and final.get("saves")==first_facts.get("saves") and final.get("save_stable")==true,"171SAVE_FIRST_FINAL_EXACT_NO_REBASE")
	if output.is_empty():output=QA+"static_normal_preview/%d"%OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(output)
	var path: String=output+"/result.json"
	if FileAccess.file_exists(path):quit(2);return
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"first_exact_facts":first_facts,"final_exact_facts":final,"scope":"30H_CHANGED_ADULT_HOUSE_SCALE_AND_TWO_NEW_ROAD_VISUALS_ONLY","input_events":0,"actor_or_camera_writes":0,"private_flags":0,"save_loads":0,"save_contents_deserialized":false,"save_writes_requested":0,"checkpoint_remains_suspended_until_owned_exit":true,"movement_or_World_entry_acceptance":false,"old11room_or_gameplay_matrix_retested":false},"\t")+"\n");file.close()
	print("LINXI30H_NORMAL_PREVIEW_RESULT ",checks," / ",errors.size());quit(0 if errors.is_empty() else 1)
