extends "res://tests/test_joint_v15_city_wall_v5_authored_choices_limited_20261004.gd"
## NEW compact GPU diagnostic. No FULL/actions52/geometry73/migration credit.
## Only current four-city arrivals, first authored road segment, and water UI.
const RETRY189_ORIGIN_PATH: String="res://tests/test_joint_v15_city_wall_v5_visual_water_ui_limited_20261004.gd"
const RETRY189_ORIGIN_SHA: String="d35b4de3d71087ffff4738eef80ef62ca89e923cd3eb7a1a211cea18bfb83ea5"
const CITY_SCENE_FORMAT_TEMPLATE: String="res://data/scenes/%s.tres"
const VISUAL_ORIGIN_PATH: String="res://tests/test_joint_v15_city_wall_v5_authored_choices_limited_20261004.gd"
const VISUAL_ORIGIN_SHA: String="fdb0e7550a5dd26a7cd6901647294772b98def4ec450600caa9d11eaca2a7932"
const CHOICE_PATH: String="res://tests/helpers/joint_v15_v8_city_authored_choice_phase.gd"
const CHOICE_SHA: String="6ac90705b6c40866f307af188a7382f70fed0a4d1d08d2cf5ac607306b40ef79"
const WATER_SOURCE: String="res://data/dialogs/huilan_openworld_water_rule.tres"
const WATER_SHA: String="e6bb99f246af07f4d447881c05d1b0591aea9bd8be14426341d7e92a95e1acd5"
const WATER_ID: String="hanjia_water_rule"
const SCOPE: String="LIMITED_NORMAL_FOUR_CITY_VISUAL_AND_WATER_UI_NOT_FULL"
const IDLE_HEIGHTS: Dictionary={"down":132,"up":131,"left":130,"right":130}
var water_cases: Array[Dictionary]=[]
var dynamic_template_declarations: Array[Dictionary]=[]
var dynamic_template_declarations_before: Array[Dictionary]=[]

func _source_snapshot(_ready: Dictionary) -> Dictionary:
	# Explicit current city/gameplay closure. Do not enumerate res://data/scenes
	# or res://data/maps recursively: unrelated future world candidate additions
	# are not executed in this limited process and must not contaminate evidence.
	dynamic_template_declarations.clear()
	var resolved_city_scenes: Array[String]=[]
	for id: String in CITY_IDS: resolved_city_scenes.append("res://data/scenes/"+id+".tres")
	var paths: Dictionary={RETRY189_ORIGIN_PATH:true,VISUAL_ORIGIN_PATH:true,CHOICE_PATH:true,WATER_SOURCE:true,get_script().resource_path:true,"res://project.godot":true,"res://scenes/field_walkable.tscn":true,"res://scenes/player.tscn":true,"res://scenes/npc_node.tscn":true}
	for path: String in SOURCE_SHA: paths[path]=true
	for path: String in RUNTIME_PATHS: paths[path]=true
	for id: String in CITY_IDS:
		for path: String in ["res://data/scenes/"+id+".tres","res://data/scenes/luoyang_v3_candidates/"+id+".tres","res://data/maps/"+id+"_layout_v3.tres","res://data/maps/luoyang_v3_legacy/"+id+"_scene.tres","res://data/maps/luoyang_v3_legacy/"+id+"_layout.tres",ART_ROOT+id+"/art_contract.json"]: paths[path]=true
		var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(ART_ROOT+id+"/art_contract.json"))
		if parsed is Dictionary:
			for path: String in parsed.get("asset_sha256",{}): paths[path]=true
			for path: String in parsed.get("source_graph",{}): paths[path]=true
	# Normal public fixtures and the exact authored dialogue use these real
	# gameplay catalogues. No candidate/world scene catalogue enumeration.
	for category: String in ["dialogs","quests","items","equipment","skills","shops","enemies"]:
		_collect_sources("res://data/"+category,["tres"],paths)
	_collect_sources("res://art/characters/weapon_variants/lengguyun/v7_idle_stable",["png"],paths)
	var queue: Array=[]
	queue.append_array(paths.keys())
	var seen: Dictionary={}
	var dependencies: RegEx=RegEx.new()
	dependencies.compile("(?:extends\\s+|(?:preload|load)\\(\\s*)[\"'](res://[^\"']+)[\"']")
	var resources: RegEx=RegEx.new()
	resources.compile("[\"'](res://[^\"']+)[\"']")
	var index: int=0
	while index<queue.size():
		var path: String=String(queue[index])
		index+=1
		if seen.has(path): continue
		seen[path]=true
		if not FileAccess.file_exists(path) or path.get_extension() not in ["gd","tres","tscn","godot"]: continue
		var source: String=FileAccess.get_file_as_string(path)
		var matcher: RegEx=dependencies if path.get_extension()=="gd" else resources
		for match: RegExMatch in matcher.search_all(source):
			var dependency: String=match.get_string(1)
			# Only this exact scene template followed by the actual format operator
			# is a declaration, not a physical filename. Concrete missing resources
			# and other templates still enter the strict MISSING check unchanged.
			if path.get_extension()=="gd" and dependency==CITY_SCENE_FORMAT_TEMPLATE and source.substr(match.get_end()).strip_edges().begins_with("%"):
				dynamic_template_declarations.append({"declaring_source_path":path,"declaring_source_sha256":FileAccess.get_sha256(path),"match_offset":match.get_start(),"template":dependency,"reason":"FORMAT_TEMPLATE_NOT_PHYSICAL_DEPENDENCY","resolution_scope":"LIMITED_CURRENT_CITY_INPUTS_ONLY_NOT_ALL_POSSIBLE_TEMPLATE_CALLS","resolved_required_paths":resolved_city_scenes.duplicate()})
				continue
			if dependency.get_extension() not in ["gd","tres","tscn","png","wav","ogg","gdshader","res"]: continue
			if not paths.has(dependency): paths[dependency]=true; queue.append(dependency)
	var result: Dictionary={}
	for path: String in paths: result[path]=FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "MISSING"
	return result

func _actor_evidence(id: String) -> Dictionary:
	var field: Node=phase.get("field") as Node
	var live: bool=is_instance_valid(field) and current_scene==field and field.is_inside_tree() and not field.is_queued_for_deletion()
	if not _check(live,"actual current normal city Field remains live: "+id): return {"live":false}
	var player: Node2D=field.get("_player") as Node2D
	var sprite: Sprite2D=player.get("sprite") as Sprite2D if is_instance_valid(player) else null
	var shape: CollisionShape2D=player.get_node_or_null("CollisionShape2D") as CollisionShape2D if is_instance_valid(player) else null
	var camera: Camera2D=field.get("_world_camera") as Camera2D
	var probe: RefCounted=phase.get("probe") as RefCounted
	var raw: RefCounted=phase.get("raw") as RefCounted
	_check(field.get_script().resource_path=="res://scripts/field/field_walkable_controller.gd" and is_instance_valid(player) and player.is_inside_tree() and is_instance_valid(sprite) and sprite.texture!=null,"normal production Field and actual Player Sprite, no preview subclass")
	if not is_instance_valid(player) or not is_instance_valid(sprite) or sprite.texture==null: return {"live":true,"actor_valid":false}
	_check(shape!=null and not shape.disabled and shape.shape is RectangleShape2D and shape.shape.size==Vector2(34,24) and shape.position==Vector2.ZERO,"real centered enabled ordinary 34x24 body, never world travel circle")
	_check(absf(sprite.scale.y-.945*.91)<.000001 and absf(float(player.call("get_depth_sort_y"))-player.global_position.y)<.01,"actual adult .91 scale and ground feet")
	_check(is_instance_valid(camera) and camera.is_current() and camera.zoom.distance_to(Vector2(1.05,1.05))<.000001,"actual normal city Camera2D current and authored zoom1.05")
	var body: Dictionary=probe.call("raw_evidence",player.position)
	var physics: bool=bool(probe.call("physical_clear",player.position))
	_check(bool(body.get("clear",false)) and int(body.get("body_pixels",0))==875 and int(body.get("shoe_samples",0))==17 and physics,"arrival/current road complete875+17 independent PNG and actual Physics")
	_check(raw!=null and bool(raw.call("clear",player.position)),"independent current RAW oracle agrees on full foot legality")
	var alpha: RefCounted=probe.get("alpha") as RefCounted
	var image: Image=alpha.call("image_for",sprite)
	var rect: Rect2i=alpha.call("frame",sprite,image)
	var top: int=rect.size.y
	var bottom: int=-1
	for y in rect.size.y:
		for x in rect.size.x:
			if image.get_pixelv(rect.position+Vector2i(x,y)).a>.12: top=mini(top,y); bottom=maxi(bottom,y)
	var facing: String=String(player.get("_direction"))
	var expected_path: String="res://art/characters/weapon_variants/lengguyun/v7_idle_stable/sword/lengguyun_sword_idle_%s_25d_4f.png"%facing
	_check(IDLE_HEIGHTS.has(facing) and sprite.texture.resource_path==expected_path,"actual naturally obtained idle facing has exact source strip")
	if IDLE_HEIGHTS.has(facing):
		_check(bottom>=top and bottom-top+1==int(IDLE_HEIGHTS[facing]) and absf((bottom-top+1)*sprite.scale.y-int(IDLE_HEIGHTS[facing])*.945*.91)<.0001,"actual current idle alpha height uses exact facing reference, not blanket DOWN height")
	return {"live":true,"scene_id":id,"field_id":field.get_instance_id(),"field_script":field.get_script().resource_path,"foot_px":[player.position.x,player.position.y],"body":body,"physical_clear":physics,"sprite_path":sprite.texture.resource_path,"sprite_sha256":FileAccess.get_sha256(sprite.texture.resource_path),"frame":sprite.frame,"facing":facing,"scale":[sprite.scale.x,sprite.scale.y],"strong_alpha_height_px":bottom-top+1,"camera_zoom":[camera.zoom.x,camera.zoom.y] if camera!=null else [],"independent_raw_safe":raw!=null and bool(raw.call("clear",player.position))}

func _run() -> void:
	before_files=_normal_files()
	before_slot=root.get_node("SaveManager").get("active_slot")
	navigation_before=root.get_node("SceneRouter").call("get_navigation_state")
	output="res://build/joint_world_luoyang_20261003_qa/city_wall_v5_visual_water_ui_retry1_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(output)==OK,"unique compact visual/water diagnostic output")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	_check("--joint-city-wall-v5-visual-water-ui" in args and "--luoyang-v3-candidate" in args and "--qa-gpu-approved" in args and DisplayServer.get_name()!="headless","explicit ROOT GPU and city candidate diagnostic flags required")
	for argument: String in args: _check(argument in ["--joint-city-wall-v5-visual-water-ui","--luoyang-v3-candidate","--qa-gpu-approved"],"no world bypass or undeclared argument: "+argument)
	for path: String in SOURCE_SHA: _check(FileAccess.get_sha256(path).to_lower()==SOURCE_SHA[path],"exact existing scoped source: "+path)
	_check(FileAccess.get_sha256(VISUAL_ORIGIN_PATH).to_lower()==VISUAL_ORIGIN_SHA and FileAccess.get_sha256(CHOICE_PATH).to_lower()==CHOICE_SHA and FileAccess.get_sha256(WATER_SOURCE).to_lower()==WATER_SHA,"exact new choice and original ordinary action helper closure")
	_check(FileAccess.get_sha256(RETRY189_ORIGIN_PATH).to_lower()==RETRY189_ORIGIN_SHA,"ROOT189 executed origin remains exact and unchanged")
	source_before=_source_snapshot({})
	dynamic_template_declarations_before=dynamic_template_declarations.duplicate(true)
	_check(not source_before.values().has("MISSING"),"all explicitly used city/catalog/actor/gameplay sources present")
	if failed>0: await _finish({}); return
	_preflight()
	_check(_write("four_city_source_preflight.json",preflight),"strict all-four current prepare evidence, not Field/visual approval")
	if failed>0: await _finish({}); return
	root.get_node("SceneRouter").call("reset_for_new_game")
	_check(int((root.get_node("SceneRouter").call("get_navigation_state") as Dictionary).get("world_map_version",-1))==14,"ordinary formal14 process fixture, no unpublished world restore")
	var script: GDScript=load(CHOICE_PATH) as GDScript
	if not _check(script!=null and script.can_instantiate(),"exact authored-choice ordinary lifecycle phase compiles"): await _finish({}); return
	phase=script.new() as RefCounted
	script=null
	phase.set("tree",self); phase.set("candidate",true); phase.set("output",output)
	phase.set("before_files",phase.call("_normal_files")); phase.set("before_slot",before_slot)
	var input_script: GDScript=load(INPUT_PATH) as GDScript
	if not _check(input_script!=null and input_script.can_instantiate(),"actual frozen normal input driver compiles"): await _finish({}); return
	var driver: RefCounted=input_script.new() as RefCounted
	driver.call("configure",self); phase.set("driver",driver)
	phase.call("_connect_events")
	for id: String in CITY_IDS:
		phase.call("_public_fixture",{})
		if not await phase.call("_open",id): continue
		await driver.call("completed_actor_stage")
		var arrival: Dictionary=_actor_evidence(id)
		await phase.call("_capture","arrival_"+id)
		var manifest: Dictionary=phase.get("manifest") as Dictionary
		var route: Dictionary=manifest.routes[0] if manifest.get("routes") is Array and not manifest.routes.is_empty() else {}
		_check(route.get("points_px") is Array and route.points_px.size()>=2,"first actual authored road segment exists: "+id)
		if not route.get("points_px") is Array or route.points_px.size()<2: continue
		var probe: RefCounted=phase.get("probe") as RefCounted
		var a: Vector2=probe.call("point",route.points_px[0])
		var b: Vector2=probe.call("point",route.points_px[1])
		var approach: Dictionary=await probe.call("move_to",a)
		var segment: Dictionary=probe.call("segment",a,b)
		_check(bool(approach.get("ok",false)) and bool(segment.get("clear",false)),"normal approach and authored road full875/17/Physics <=4px plan: "+id)
		var movement: Dictionary=await driver.call("follow",phase.get("field"),PackedVector2Array([a,b]),Callable(probe,"clear"),Callable(probe,"segment")) if bool(approach.get("ok",false)) and bool(segment.get("clear",false)) else {"ok":false,"reason":"independent_approach_or_segment_failed"}
		_check(bool(movement.get("ok",false)),"normal real input follows first authored road segment: "+id)
		var road: Dictionary=_actor_evidence(id)
		await phase.call("_capture","road_"+id)
		trials[id]={"manifest_sha256":FileAccess.get_sha256(ART_ROOT+id+"/art_contract.json"),"arrival":arrival,"route_id":route.id,"first_authored_points":route.points_px.slice(0,2),"approach":approach,"segment":segment,"normal_input":movement,"road":road}
	var subject: GDScript=load(SUBJECT_PATH) as GDScript
	var legacy: SceneScript=subject.call("legacy_scene",&"ch4_s1_luoyang_yamen") as SceneScript
	var entry: Dictionary={}
	if legacy!=null:
		for value: Dictionary in legacy.map_layout.interactions:
			if String(value.get("id",""))==WATER_ID: entry=value.duplicate(true)
	_check(not entry.is_empty() and String(entry.get("action",""))=="dialog:huilan_openworld_water_rule","actual immutable yamen hanjia_water_rule identity/action, not invented interaction")
	if not entry.is_empty() and String(entry.get("action",""))=="dialog:huilan_openworld_water_rule":
		for mode: String in ["space","mouse"]:
			var start: int=(phase.get("records") as Dictionary).interactions.size()
			await phase.call("_normal_action_case","ch4_s1_luoyang_yamen","interactions",entry,mode)
			var rows: Array=(phase.get("records") as Dictionary).interactions
			_check(rows.size()==start+1,"exact one actual water interaction evidence row: "+mode)
			var row: Dictionary=rows.back().duplicate(true) if rows.size()==start+1 else {}
			var flag: bool=bool((root.get_node("GameState").get("flags") as Dictionary).get("huilan_water_rule_understood",false))
			_check(flag and not bool(root.get_node("DialogPlayer").call("is_playing")),"normal authored right flag and real dialog completion: "+mode)
			var policy_rows: Array=(phase.get("records") as Dictionary).get("dialog_ui_identity",[])
			var latest: Dictionary=policy_rows.back() if not policy_rows.is_empty() else {}
			var choices: Array=latest.get("authored_choice_inputs",[])
			_check(choices.size()==1 and choices[0].identity=="huilan_openworld_water_rule/choice" and choices[0].source_sha256.to_lower()==WATER_SHA and int(choices[0].selected_index)==1 and bool(choices[0].selection_valid),"actual second-option normal pointer policy recorded once: "+mode)
			water_cases.append({"mode":mode,"original_entry":entry,"original_action_record":row,"choice_ui_evidence":latest.duplicate(true),"actual_right_flag":flag,"dialog_playing_after":root.get_node("DialogPlayer").call("is_playing")})
	legacy=null; subject=null; driver=null; input_script=null
	await _finish({})

func _finish(_ready: Dictionary) -> void:
	var actual_field: bool=phase!=null and bool(phase.get("runtime_started"))
	var records: Dictionary=(phase.get("records") as Dictionary).duplicate(true) if phase!=null else {}
	var field_ref: WeakRef=weakref(current_scene) if is_instance_valid(current_scene) else null
	if phase!=null:
		var bus: Node=root.get_node("EventBus")
		for connection: Dictionary in phase.get("event_connections"):
			if bus.is_connected(connection.signal,connection.callable): bus.disconnect(connection.signal,connection.callable)
		(phase.get("event_connections") as Array).clear()
		await phase.call("natural_field_grace","before_compact_visual_water_release")
		checks+=int(phase.get("checks")); failed+=int(phase.get("failures"))
		phase.call("_release_field_oracles")
		var driver: RefCounted=phase.get("driver") as RefCounted
		if driver!=null: driver.call("release")
		driver=null
		phase.set("driver",null); phase.set("field",null); phase.set("tree",null); phase=null
	if is_instance_valid(current_scene):
		var owned: Node=current_scene
		current_scene=null; owned.queue_free()
	for stage in 8: await process_frame
	_check(field_ref==null or field_ref.get_ref()==null,"owned ordinary Field naturally released")
	var start: int=Time.get_ticks_usec()
	var frames: int=0
	while Time.get_ticks_usec()-start<9000000: await process_frame; frames+=1
	var audio: Node=root.get_node_or_null("AudioManager")
	if audio!=null: audio.call("stop_bgm",.15)
	var drain: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-drain<250000: await process_frame
	for shape: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for stage in 4: await process_frame
	var after_files: Dictionary=_normal_files()
	var after_slot: Variant=root.get_node("SaveManager").get("active_slot")
	var after_sources: Dictionary=_source_snapshot({})
	_check(before_files==after_files and before_slot==after_slot,"all15 normal player file SHA/size/mtime and active slot unchanged")
	_check(source_before==after_sources,"explicit current city/catalog/runtime/actor/gameplay source bytes unchanged")
	_check(not dynamic_template_declarations_before.is_empty() and dynamic_template_declarations_before==dynamic_template_declarations,"exact formatted scene declarations and explicit resolved city dependencies unchanged")
	_check(trials.size()==4 and water_cases.size()==2,"all four arrivals/road segments and two normal water UI inputs actually executed")
	var screenshots: Array=records.get("screenshots",[])
	var arrival_count: int=0
	var road_count: int=0
	for shot: Dictionary in screenshots:
		arrival_count+=1 if String(shot.label).begins_with("arrival_") else 0
		road_count+=1 if String(shot.label).begins_with("road_") else 0
		_check(FileAccess.file_exists(shot.path) and FileAccess.get_sha256(shot.path)==shot.sha256,"each current raw PNG retains actual SHA")
	_check(arrival_count==4 and road_count==4,"exact four raw arrival plus four normal road screenshots, no inherited captures")
	var result: Dictionary={"scope":SCOPE,"checks":checks+1,"failed":failed,"full_complete":false,"source_complete":false,"dry_run":false,"visual_approved":false,"ordinary_field_executed":actual_field,"engine_pid":OS.get_process_id(),"executing_script_path":get_script().resource_path,"executing_script_sha256":FileAccess.get_sha256(get_script().resource_path),"origin189":{"path":RETRY189_ORIGIN_PATH,"sha256":RETRY189_ORIGIN_SHA},"dynamic_template_declarations_before":dynamic_template_declarations_before,"dynamic_template_declarations_after":dynamic_template_declarations.duplicate(true),"source_sha256_before":source_before,"source_sha256_after":after_sources,"frozen_manifest_sha256":MANIFEST_SHA,"normal_files_before":before_files,"normal_files_after":after_files,"active_slot_before":before_slot,"active_slot_after":after_slot,"exact_UTCticks":"ROOT_EXTERNAL_FRESH_PROOF_REQUIRED","preflight":preflight,"trials":trials,"water_cases":water_cases,"dialog_records":records,"raw_screenshots":screenshots,"screenshot_counts":{"arrival":arrival_count,"road":road_count,"water_action":screenshots.size()-arrival_count-road_count},"cleanup":{"natural_grace_usec":Time.get_ticks_usec()-start,"natural_frames":frames,"public_fade_seconds":.15,"drain_usec":Time.get_ticks_usec()-drain,"timer_cancelled":false},"not_run":["FULL","ALL52NPC_ACTIONS","ALL73OBJECT_GEOMETRY","ALL20ROUTES","PORTALS","WORLD15","MIGRATION80","BATTLE_SHOP_BOUNTY","VISUAL_APPROVAL"],"stderr_acceptance":"ROOT_READ_ACTUAL_VERBOSE_AND_OS_EXIT_REQUIRED","output":output}
	_check(_write("result.json",result),"compact actual result saved with exact parsed readback")
	print(SCOPE," checks=",checks," failed=",failed," output=",output)
	quit(0 if failed==0 else 1)
