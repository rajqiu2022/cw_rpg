extends SceneTree
## Root only, one default public entry and one continuous bounded journey.
## No save/reset/load, owner/status injection, teleport, camera adjustment or trade.
const FIXTURE := "res://build/major_cities_20261028_qa01/bianzhou_bounded_READY.json"
const OUTPUT := "res://build/major_cities_20261028_qa01/actual/"
const TOLERANCE := 10.0 # One normal 480px/s physics tick plus 2px, no snapping.
var spec: Dictionary={}
var checks: int=0
var errors: Array[String]=[]
var records: Array=[]
var texts: Array=[]
var choices: Array=[]
var source_before: Dictionary={}
var save_before: Dictionary={}
var state_before: Array=[]
var began: int=0
var input_ticks: int=0
var png_count: int=0
var sr: Node
var dp: Node
var lm: Node

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> bool:
	checks+=1
	if not ok:errors.append(label)
	return ok

func point(raw: Variant) -> Vector2:
	return Vector2(float(raw[0]),float(raw[1])) if raw is Array and raw.size()==2 else Vector2(INF,INF)

func active() -> bool:
	return Time.get_ticks_msec()-began<int(spec.get("whole_seconds",120))*1000

func file_facts(paths: Array) -> Dictionary:
	var out: Dictionary={}
	for path: String in paths:
		if not FileAccess.file_exists(path):out[path]={"exists":false};continue
		var file:=FileAccess.open(path,FileAccess.READ)
		out[path]={"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file!=null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return out

func business_state() -> Array:
	return [(root.get_node("GameState").get("flags") as Dictionary).duplicate(true),root.get_node("GameState").get("gold"),root.get_node("Inventory").call("to_dict"),root.get_node("QuestManager").call("to_dict"),root.get_node("BountyManager").call("to_dict")]

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true,"ROOT_FROZEN_READY_FIXTURE_ONLY"):finish();return
	spec=raw
	if not check(spec.whole_seconds==120 and spec.entry_seconds==20 and spec.max_png==2 and spec.fixed_sources.size()>0,"BOUNDED_SINGLE_RUN"):finish();return
	var baseline: Variant=JSON.parse_string(FileAccess.get_file_as_string(spec.baseline))
	if not check(baseline is Dictionary and baseline.save15.size()==15,"REGISTERED_FIFTEEN_SAVE_PATHS_ONLY"):finish();return
	source_before=file_facts(spec.fixed_sources.keys());save_before=file_facts(baseline.save15.keys())
	for path: String in spec.fixed_sources:check(source_before[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path)
	sr=root.get_node_or_null("SceneRouter");dp=root.get_node_or_null("DialogPlayer");lm=root.get_node_or_null("LoadingManager")
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if not check(sr!=null and dp!=null and lm!=null and platform!=null,"NORMAL_AUTOLOADS"):finish();return
	platform.call("set_checkpoint_saves_suspended",true)
	check(platform.call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED_UNTIL_QUIT")
	state_before=business_state()
	dp.connect("text_displayed",_on_text);dp.connect("choices_displayed",_on_choices)
	if not errors.is_empty():finish();return
	if not check(sr.call("go_field_smart",StringName(spec.city_id))==true,"DEFAULT_PUBLIC_CITY_ENTRY_ACCEPTED_NOT_COMPLETED"):finish();return
	var field: Node=await wait_field(spec.city_id)
	if field==null:finish();return
	if not check(city(field) and (field.get("_player") as Node2D).position.distance_to(point(spec.default_foot))<=1.0,"DEFAULT_SPAWN_NO_QA_POSE_WRITE"):finish();return
	if not await walk_route(field,spec.ambient.route):finish();return
	var static_before: Dictionary=static_identity(field)
	if not await speak(field,spec.ambient,true):finish();return
	check(static_identity(field)==static_before,"AMBIENT_DIALOG_NO_TERRAIN_OR_BODY_REBUILD")
	if not await capture("southgate_ambient"):finish();return
	if not await walk_route(field,spec.postmaster.route):finish();return
	if not await speak(field,spec.postmaster,false):finish();return
	if not await walk_route(field,spec.merchant.route):finish();return
	if not verify_npc(field,spec.merchant):finish();return
	var merchant_foot: Vector2=(field.get("_player") as Node2D).position
	await key(KEY_SPACE)
	var shop_start: int=Time.get_ticks_msec()
	while active() and Time.get_ticks_msec()-shop_start<5000:
		await process_frame
		if current_scene!=null and current_scene.scene_file_path=="res://scenes/shop.tscn":break
	if not check(current_scene!=null and current_scene.scene_file_path=="res://scenes/shop.tscn" and String(sr.call("get_shop_payload").get("shop_id"))=="wulin_trade_hall","ORIGINAL_SHOP_UI_NO_PURCHASE"):finish();return
	await process_frame;await key(KEY_ESCAPE)
	field=await wait_field(spec.city_id)
	if field==null:finish();return
	if not check(city(field) and (field.get("_player") as Node2D).position.distance_to(merchant_foot)<=1.0 and business_state()==state_before,"SHOP_RETURN_EXACT_FEET_NO_ECONOMY_OR_QUEST_CHANGE"):finish();return
	if not await capture("city_market_after_shop_return"):finish();return
	if not await walk_route(field,spec.north.route):finish();return
	var north_source_foot: Vector2=(field.get("_player") as Node2D).position
	records.append({"north_expected_remembered_return_captured_before_exit":north_source_foot})
	await key(KEY_SPACE)
	var old_post: Node=await wait_field(spec.north.target)
	if old_post==null:finish();return
	if not check((old_post.get("_player") as Node2D).position.distance_to(Vector2(1536,1802.24))<=1.0,"NORTH_ORIGINAL_OLD_POST_ARRIVAL"):finish();return
	if not await walk_route(old_post,spec.north.old_post_return_route):finish();return
	await key(KEY_SPACE)
	field=await wait_field(spec.city_id)
	if field==null:finish();return
	if not check(city(field) and (field.get("_player") as Node2D).position.distance_to(north_source_foot)<=1.0,"OLD_POST_ORIGINAL_REMEMBERED_RETURN_CAPTURED_BEFORE_EXIT"):finish();return
	if not await walk_route(field,spec.south.route):finish();return
	if not check((field.get("_player") as Node2D).position.distance_to(point(spec.south.portal_foot))<=TOLERANCE,"SOUTH_ORIGINAL_EXIT_STAND"):finish();return
	var expected_world: String=String(sr.get("_active_world_map_scene"))
	await key(KEY_SPACE)
	var world: Node=await wait_field(expected_world)
	if world==null:finish();return
	check(sr.call("is_world_map_scene",StringName(expected_world))==true and business_state()==state_before,"SOUTH_REAL_WORLD_DESTINATION_AND_NO_BUSINESS_MUTATION")
	check(active(),"WHOLE_120_SECONDS_NO_RETRY")
	finish()

func wait_field(id: String) -> Node:
	var started: int=Time.get_ticks_msec()
	while active() and Time.get_ticks_msec()-started<int(spec.entry_seconds)*1000:
		await process_frame
		var field: Node=current_scene
		if field==null or not field.has_method("get_field_loading_state"):continue
		var status: Dictionary=field.call("get_field_loading_state")
		if String(status.get("scene_id"))!=id:continue
		if status.get("failed")==true:check(false,"FIELD_FAILED:"+id);return null
		if status.get("complete")!=true or lm.get("_transition_active")==true or lm.get("_external_active")==true:continue
		var player: Node=field.get("_player")
		if not is_instance_valid(player) or player.get("can_move")!=true or dp.call("is_playing")==true:continue
		await RenderingServer.frame_post_draw
		records.append({"field_arrival":id,"milliseconds":Time.get_ticks_msec()-started,"default_cold_performance_claim":false})
		return field
	check(false,"ENTRY_20S_NO_EXTENSION:"+id);return null

func city(field: Node) -> bool:
	if not check(field.get_script().resource_path==spec.city_field and field.has_method("get_bianzhou_debug"),"REAL_NEW_BIANZHOU_FIELD"):return false
	var debug: Dictionary=field.call("get_bianzhou_debug")
	check(debug.get("size")==point(spec.get("size")) and debug.layout_version==spec.layout_version and debug.layout_revision>0 and debug.objects>0 and debug.blockers>0,"REAL_CONTINUOUS_CITY_CONTENT")
	var scene: Resource=field.get("_current_scene")
	var layout: Resource=scene.get("map_layout")
	var board_count: int=0
	for row: Dictionary in layout.get("interactions"):
		if String(row.get("action"))=="bounty_board:bianzhou":board_count+=1
	check(board_count==1 and (layout.get("portals") as Array).size()==2,"ONE_ORIGINAL_BOUNTY_BOARD_TWO_ORIGINAL_EXITS")
	var targets: Array=[]
	for zone: Node in field.get("_exit_nodes"):
		var label: String=String(zone.get("exit_label"))
		check((label.contains("汴州") or label.contains("旧驿")) and zone.get("is_locked")==false,"ENTERABLE_CHINESE_PORTAL:"+label)
		targets.append(String(zone.get("action")) if not String(zone.get("action")).is_empty() else String(zone.get("target_scene_id")))
	targets.sort();check(targets==["openworld_bianzhou_old_post","world_map"],"TWO_ACTUAL_ORIGINAL_EXIT_TARGETS")
	records.append({"city_debug":debug})
	return errors.is_empty()

func verify_npc(field: Node, row: Dictionary) -> bool:
	var found: Array=[]
	for npc: Node in field.get("_npc_nodes"):
		if String(npc.get("npc_id"))==row.npc_id:found.append(npc)
	if not check(found.size()==1,"EXACT_NPC:"+row.npc_id):return false
	var actor: Node2D=found[0]
	if row.has("action"):check(String(actor.get("interaction_action"))==row.action,"ORIGINAL_OR_AUTHORED_ACTION:"+row.npc_id)
	if row.has("dialog_id"):check(String(actor.get("dialog_id"))==row.dialog_id,"ORIGINAL_GUIDE_DIALOG")
	return check((field.get("_player") as Node2D).global_position.distance_to(actor.global_position)<=120.0,"REAL_NPC_APPROACH:"+row.npc_id)

func speak(field: Node, row: Dictionary, ambient: bool) -> bool:
	if not verify_npc(field,row):return false
	texts.clear();choices.clear();await key(KEY_SPACE)
	var started: int=Time.get_ticks_msec()
	var inputs: int=0
	while active() and Time.get_ticks_msec()-started<8000 and inputs<12:
		await process_frame
		if dp.call("is_playing")!=true:break
		if not choices.is_empty():
			var safe: int=-1
			for i: int in range(choices.size()):
				if String(choices[i].get("text"))=="告辞":safe=i
			if not check(not ambient and safe>=0 and safe<9,"SOURCE_SAFE_EXIT_CHOICE_NO_GUESS"):return false
			await key(KEY_1+safe)
		else:await key(KEY_SPACE)
		inputs+=1
	var npc_text: bool=false
	for item: Dictionary in texts:
		if item.speaker==row.name and not item.text.is_empty():npc_text=true
	if ambient:check(texts.size()>=2 and texts[0].speaker=="冷孤云" and texts[0].portrait=="res://art/characters/protagonist_portrait.png" and texts[1].text==row.reply,"LIFE_HERO_FIRST_MATCHING_PORTRAIT_THEN_SOURCE_REPLY")
	records.append({"conversation":row.npc_id,"texts":texts.duplicate(true),"keyboard_inputs":inputs})
	return check(dp.call("is_playing")==false and npc_text and (field.get("_player") as Node).get("can_move")==true and business_state()==state_before,"DIALOG_END_INPUT_UNLOCKED_NO_BUSINESS_CHANGE")

func walk_route(field: Node, points: Array) -> bool:
	for raw: Array in points:
		if not await walk(field,point(raw)):return false
	return true

func walk(field: Node, target: Vector2) -> bool:
	var actor: Node2D=field.get("_player")
	var start: Vector2=actor.position
	var delta: Vector2=target-start
	if not check(target.is_finite() and (absf(delta.x)<=TOLERANCE or absf(delta.y)<=TOLERANCE),"SOURCE_AXIS_ROUTE_NO_TELEPORT"):return false
	if delta.length()<=TOLERANCE:return true
	var horizontal: bool=absf(delta.x)>absf(delta.y)
	var forward: float=signf(delta.x if horizontal else delta.y)
	var action: String=("move_right" if forward>0 else "move_left") if horizontal else ("move_down" if forward>0 else "move_up")
	var limit: int=ceili(delta.length()/480.0*Engine.physics_ticks_per_second)+24
	Input.action_press(action)
	for index: int in range(limit):
		await physics_frame;input_ticks+=1
		if not active() or not is_instance_valid(actor) or current_scene!=field:break
		if (target.x-actor.position.x if horizontal else target.y-actor.position.y)*forward<=1.0:break
	release_input();await physics_frame
	var actual: Vector2=actor.position if is_instance_valid(actor) else Vector2(INF,INF)
	records.append({"true_input_start":start,"target":target,"actual":actual,"axis":action})
	return check(active() and actual.distance_to(target)<=TOLERANCE,"TRUE_INPUT_REACHED_SOURCE_FOOT")

func static_identity(field: Node) -> Dictionary:
	var ids: Array=[]
	for node: Node in field.get("_scene_object_nodes"):ids.append(str(node.get_instance_id()))
	for node: Node in field.get("_collision_bodies"):ids.append(str(node.get_instance_id()))
	return {"revision":field.call("get_bianzhou_debug").layout_revision,"ids":ids}

func release_input() -> void:
	for action: String in ["move_left","move_right","move_up","move_down"]:Input.action_release(action)

func key(code: int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true
	Input.parse_input_event(event);await process_frame
	event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false
	Input.parse_input_event(event);await process_frame

func _on_text(speaker: String, text: String, _has_choices: bool, portrait: String) -> void:
	choices.clear();texts.append({"speaker":speaker,"text":text,"portrait":portrait})

func _on_choices(rows: Array) -> void:
	choices=rows.duplicate(true)

func capture(label: String) -> bool:
	if not check(png_count<int(spec.max_png) and active(),"MAX_TWO_NORMAL_CAMERA_PNG"):return false
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image()
	var path: String=OUTPUT+str(OS.get_process_id())+"/"+label+".png"
	if not check(image!=null and not image.is_empty() and image.get_width()==1920 and image.get_height()==1080 and not FileAccess.file_exists(path),"NEW_NATIVE_1920_1080_PNG_ONLY"):return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not check(image.save_png(path)==OK,"PNG_SAVED"):return false
	png_count+=1;records.append({"png":path,"size":[image.get_width(),image.get_height()],"sha256":FileAccess.get_sha256(path),"camera_modified_by_QA":false})
	return true

func finish() -> void:
	release_input()
	if not source_before.is_empty():check(source_before==file_facts(source_before.keys()),"SMALL_CURRENT_SOURCE_FIRST_FINAL")
	if not save_before.is_empty():check(save_before==file_facts(save_before.keys()),"SAVE15_HASH_BYTES_SECONDS_SAME_ROOT_EXACTTICKS_SEPARATE")
	var path: String=OUTPUT+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(path):quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":input_ticks,"png_count":png_count,"records":records,"fixture_sha256":FileAccess.get_sha256(FIXTURE),"save_writes":0,"qa_pose_or_camera_writes":0,"reset_calls":0},"\t"));file.close()
	print("[BianzhouBounded] "+str(checks)+" checks / "+str(errors.size())+" failures; "+path)
	quit(0 if errors.is_empty() else 1)
