extends SceneTree
## Frozen Root-only single owned-process action QA; checkpoint saves suspended before fields.
## New actions only. Public map placements are setup, never continuous-route evidence.
const OUT := "res://build/gather_actions_20261030l_qa01/actual02/"
const PIN_FILE := "res://build/gather_actions_20261030l_qa01/action_pins02_READY.json"
const GATHER_PATH := "res://scripts/life_skills/gathering_service.gd"
const KEY := "life_skills_resources_v1"
const ROWS := [
	{"scene":"adventure_zhuwei_hunting_ground","site":"adventure_forest_herb_01","item":"herb_bundle","kind":"herb","near":Vector2(1120,2100)},
	{"scene":"adventure_xiangzhou_deep_mine","site":"adventure_mine_ore_01","item":"iron_ore","kind":"ore","near":Vector2(1040,1730)}]
var checks := 0
var inputs := 0
var errors: Array[String] = []
var records: Array = []
var done := false
var suspended := false
var directory := ""
var pins: Dictionary = {}
var first_sources: Dictionary = {}
var life: Node
var inventory: Node
var game: Node
var gather: Script
var field: Node
var actor: Player
var profiles: Dictionary = {}

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred();_watch.call_deferred()

func _early(node: Node) -> void:
	if node.name==&"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true)
		suspended=bool(node.call("is_checkpoint_saves_suspended"))

func _watch() -> void:
	await create_timer(60.0,true,false,true).timeout
	if not done:need(false,"WATCHDOG60_NO_RECOVERY_NO_SAVE");finish()

func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("GATHER_ACTION_FAIL ",label)
	return ok

func sources() -> Dictionary:
	var result: Dictionary={}
	for path: String in pins:
		var file:=FileAccess.open(path,FileAccess.READ)
		result[path]={"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file!=null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return result

func debug_action() -> Dictionary:
	var raw: Dictionary=life.call("get_gather_action_debug")
	var payload: Dictionary=raw.duplicate(true)
	if not bool(raw.get("active",false)) and raw.get("last") is Dictionary:
		payload=(raw["last"] as Dictionary).duplicate(true)
	payload["active"]=bool(raw.get("active",false));payload["start_serial"]=int(raw.get("start_serial",0))
	payload["raw_debug"]=raw.duplicate(true)
	return payload
func count_item(id: String) -> int:return int(inventory.call("count_of",StringName(id)))
func resource_state() -> Dictionary:return gather.call("state")
func serial() -> int:return int(debug_action().get("start_serial",0))

func business() -> Dictionary:
	var flags: Dictionary=game.get("flags").duplicate(true);flags.erase(KEY)
	return {"flags":flags,"quests":root.get_node("QuestManager").call("to_dict"),"gold":game.get("gold"),"player_instance":game.get("player").get_instance_id()}.duplicate(true)

func bag() -> Dictionary:
	return {"inventory":inventory.call("to_dict"),"serial":inventory.get("_next_instance_serial"),"resources":resource_state(),"business":business()}.duplicate(true)

func body() -> Dictionary:
	var shape: CollisionShape2D=actor.get_node("CollisionShape2D") as CollisionShape2D
	return {"actor":actor.get_instance_id(),"layer":actor.collision_layer,"mask":actor.collision_mask,"shape_node":shape.get_instance_id(),"shape_resource":shape.shape.get_instance_id(),"shape_transform":shape.transform,"disabled":shape.disabled,"size":shape.shape.size if shape.shape is RectangleShape2D else Vector2.ZERO,"constraint_hash":actor.movement_constraint.hash(),"sprite":actor.sprite.get_instance_id(),"texture":actor.sprite.texture.resource_path}.duplicate(true)

func seed_inventory_case(full: bool) -> void:
	# Only this new private process's inventory fixture. Never loads any user save.
	var slots: Array=[]
	if full:
		for i: int in range(30):slots.append({"item_id":"straw_sandals","count":1,"instance_id":"qa_action_filler#%d"%i})
	inventory.call("from_dict",{"slots":slots,"equipped_by_character":{}})

func ready_field(id: String) -> Node:
	var began: int=Time.get_ticks_msec()
	while Time.get_ticks_msec()-began<15000 and not done:
		await process_frame
		if current_scene==null or not current_scene.has_method("get_field_loading_state"):continue
		var state: Dictionary=current_scene.call("get_field_loading_state")
		if state.get("complete")!=true or state.get("failed")==true:continue
		if String(root.get_node("SceneRouter").call("get_current_field_id"))!=id:continue
		if bool(root.get_node("LoadingManager").get("_transition_active")):continue
		if not need(not root.get_node("DialogPlayer").call("is_playing"),"NEW_MAP_NO_INTRO_ADVANCE_OR_STORY_FLAG:"+id):return null
		await create_timer(.35).timeout
		return current_scene
	need(false,"FIELD_READY_TIMEOUT:"+id);return null

func go(id: String,uv: Variant) -> bool:
	if not need(root.get_node("SceneRouter").call("go_field_smart",StringName(id),uv,"",-1,-1)==true,"PUBLIC_SETUP:"+id):return false
	field=await ready_field(id)
	if field==null:return false
	actor=field.get("_player") as Player
	return need(actor!=null and actor.can_move,"REAL_PLAYER_READY_NOT_PRIVATE_POSITION_WRITE")

func near_row(row: Dictionary,bootstrap: bool) -> bool:
	if bootstrap:
		if not await go(String(row.scene),null):return false
		if not need(String(life.get("_field_id"))==String(row.scene),"LIFE_OWNER_AFTER_PUBLIC_DEFAULT_BOOTSTRAP"):return false
	if not await go(String(row.scene),row.near/Vector2(4096,3072)):return false
	var world: Node2D=field.get("world_container") as Node2D
	if not need(world.to_local(actor.global_position).distance_to(row.near)<.1,"EXACT_PUBLIC_NEAR_SETUP_NOT_CONTINUOUS_ROUTE"):return false
	return need(life.get("_active_sites").has(String(row.site)) and gather.call("is_available",String(row.site)),"ONE_AVAILABLE_NEW_ACTION_SITE:"+String(row.site))

func key_edge(code: Key,down: bool) -> void:
	await physics_frame
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
	Input.parse_input_event(event);inputs+=1
	await process_frame

func tap(code: Key) -> void:
	await key_edge(code,true);await key_edge(code,false)

func click_site(row: Dictionary) -> void:
	var point: Node2D=life.get("_site_nodes")[String(row.site)].point
	var at: Vector2=point.get_global_transform_with_canvas().origin
	for down: bool in [true,false]:
		await physics_frame
		var event:=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
		Input.parse_input_event(event);inputs+=1;await process_frame

func begin_row(row: Dictionary) -> void:
	if String(row.kind)=="herb":await tap(KEY_F)
	else:await click_site(row)

func sample() -> Dictionary:
	var state: Dictionary=debug_action()
	if not bool(state.get("active",false)):return {"debug":state}
	var visual: Sprite2D=root.get_node_or_null(String(state.get("visual_node_path",""))) as Sprite2D
	var audio: AudioStreamPlayer=root.get_node_or_null(String(state.get("audio_node_path",""))) as AudioStreamPlayer
	return {"debug":state,"node_frame":visual.frame if visual!=null else -1,"hframes":visual.hframes if visual!=null else -1,"sheet":visual.texture.resource_path if visual!=null and visual.texture!=null else "","visual_visible":visual.is_visible_in_tree() if visual!=null else false,"audio_playing":audio.playing if audio!=null else false,"audio_position":audio.get_playback_position() if audio!=null else 0.0,"audio_stream":audio.stream.resource_path if audio!=null and audio.stream!=null else ""}

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image()
	var path: String=directory+"/"+label+".png"
	need(image!=null and image.save_png(path)==OK,"NORMAL_ACTION_IMAGE:"+label)
	records.append({"image":path,"sha256":FileAccess.get_sha256(path)})

func unchanged_no_start(row: Dictionary,label: String) -> bool:
	var before: Dictionary=bag();var previous: int=serial()
	await begin_row(row);await process_frame
	var observed: Dictionary=debug_action();records.append({"phase":label,"raw_debug":observed.raw_debug,"observed":observed,"before":before,"after":bag()})
	return need(not observed.get("active",false) and serial()==previous and bag()==before,"NO_ACTION_NO_MATERIAL_NO_SITE_CONSUMPTION:"+label)

func cancel_escape(row: Dictionary) -> bool:
	var before: Dictionary=bag();var physical: Dictionary=body();var at: Vector2=actor.global_position
	await begin_row(row)
	if not need(debug_action().get("active",false) and not actor.can_move and not actor.sprite.visible and bag()==before,"REAL_F_PENDING_NO_EARLY_HERB"):return false
	var during: Dictionary=sample()
	var audio_path: String=String(during.debug.get("audio_node_path",""))
	if not need(not audio_path.is_empty() and root.get_node_or_null(audio_path) is AudioStreamPlayer,"REAL_AUDIO_NODE_CAPTURED_BEFORE_CANCEL"):return false
	records.append({"phase":"before_Esc","sample":during,"captured_real_audio_node_path":audio_path})
	await tap(KEY_ESCAPE);await process_frame
	var state: Dictionary=debug_action()
	var remaining_audio: AudioStreamPlayer=root.get_node_or_null(audio_path) as AudioStreamPlayer
	var actual_audio_stopped: bool=remaining_audio==null or not remaining_audio.playing
	var actual_token_absent: bool=not actor.has_meta(&"life_gather_action_token_20261030l")
	records.append({"phase":"after_Esc","raw_debug":state.raw_debug,"observed":state,"captured_real_audio_node_path":audio_path,"actual_audio_node_absent_or_not_playing":actual_audio_stopped,"actual_actor_token_absent":actual_token_absent,"before":before,"after":bag()})
	return need(not state.get("active",false) and String(state.get("cancel_reason",""))=="ESCAPE" and actual_audio_stopped and actual_token_absent and bag()==before and body()==physical and actor.global_position==at and actor.can_move and actor.sprite.visible,"REAL_ESC_CANCEL_RESTORES_OWN_SPRITE_BODY_MOVEMENT_ZERO_RESOURCES")

func cancel_move_and_boundary(row: Dictionary) -> bool:
	var before: Dictionary=bag();var physical: Dictionary=body();var at: Vector2=actor.global_position
	await begin_row(row)
	if not need(debug_action().get("active",false),"SECOND_REAL_F_ACTION_FOR_MOVEMENT_CANCEL"):return false
	await key_edge(KEY_D,true);await create_timer(.04).timeout;await key_edge(KEY_D,false)
	await process_frame
	var state: Dictionary=debug_action();var world: Node2D=field.get("world_container") as Node2D
	var foot: Vector2=life.get("_active_sites")[String(row.site)].runtime_foot
	records.append({"phase":"real_short_D_cancel_not_boundary_walk","raw_debug":state.raw_debug,"observed":state,"before_foot":at,"after_foot":actor.global_position,"distance_to_site":world.to_local(actor.global_position).distance_to(foot)})
	if not need(not state.get("active",false) and String(state.get("cancel_reason",""))=="MOVE_INPUT" and actor.can_move and actor.sprite.visible and actor.global_position.distance_to(at)>1 and bag()==before,"REAL_SHORT_MOVE_CANCEL_NOT_SWALLOWED_NO_MATERIAL"):return false
	# Walking legitimately changes the normal directional texture, not its body.
	var after: Dictionary=body();after.texture=physical.texture
	if not need(after==physical,"SAME_BODY_AFTER_SHORT_REAL_MOVEMENT"):return false
	# Outside-range negative uses a separate public setup, not a claimed long walk.
	if not await go(String(row.scene),Vector2(1120,2140)/Vector2(4096,3072)):return false
	world=field.get("world_container") as Node2D
	var distance: float=world.to_local(actor.global_position).distance_to(life.get("_active_sites")[String(row.site)].runtime_foot)
	if not need(absf(distance-90)<.1,"PUBLIC90PX_BOUNDARY_SETUP_NOT_CONTINUOUS_WALK"):return false
	return await unchanged_no_start(row,"PUBLIC_SETUP_OUTSIDE82")

func complete_one(row: Dictionary) -> bool:
	var before: Dictionary=bag();var physical: Dictionary=body();var at: Vector2=actor.global_position
	var owned: int=count_item(String(row.item));var previous: int=serial()
	await begin_row(row)
	if not need(debug_action().get("active",false) and serial()==previous+1,"ONE_REAL_INPUT_BEGINS_NEW_ACTION:"+String(row.kind)):return false
	var action_serial: int=serial();var frames: Dictionary={};var samples: Array=[]
	var playing_positions: Array[float]=[];var showed := false;var repeated := false
	var began: int=Time.get_ticks_msec()
	while bool(debug_action().get("active",false)) and Time.get_ticks_msec()-began<5000:
		var seen: Dictionary=sample()
		seen["actual_material_count"]=count_item(String(row.item));seen["actual_resource_state"]=resource_state()
		samples.append(seen)
		if not need(bag()==before and body()==physical and actor.global_position==at and not actor.can_move and not actor.sprite.visible,"ACTIVE_NO_GRANT_OR_PHYSICAL_CHANGE:"+String(row.kind)):return false
		if not need(bool(seen.get("visual_visible",false)) and String(seen.get("sheet",""))==String(profiles[String(row.kind)].sheet) and int(seen.get("hframes",0))==4 and int(seen.get("node_frame",-1))==int(seen.debug.get("frame_index",-2)),"REAL_CONFIGURED_FOUR_CELL_SPRITE_NOT_DEBUG_ONLY:"+String(row.kind)):return false
		frames[int(seen.node_frame)]=String(seen.sheet)
		if bool(seen.get("audio_playing",false)):
			if not need(String(seen.get("audio_stream",""))==String(profiles[String(row.kind)].cues[0].path),"REAL_CONFIGURED_DEDICATED_AUDIO_STREAM:"+String(row.kind)):return false
			playing_positions.append(float(seen.audio_position))
		if not repeated:
			repeated=true
			await tap(KEY_F)
			if String(row.kind)=="ore":await click_site(row)
			if not need(serial()==action_serial and bag()==before,"REPEATED_F_OR_CLICK_NO_RESTART_NO_EARLY_GRANT:"+String(row.kind)):return false
		if not showed and int(seen.node_frame)==2:
			showed=true;await shot(String(row.kind)+"_frame2_normal")
		await process_frame
	var final: Dictionary=debug_action();records.append({"phase":"completed_"+String(row.kind),"raw_debug_final":final.raw_debug,"observed_final":final,"before":before,"after":bag(),"samples":samples,"actual_frames":frames,"actual_audio_positions":playing_positions})
	var advanced := false
	for position: float in playing_positions:
		if position>playing_positions[0]+.005:advanced=true
	if not need(not final.get("active",false) and final.get("completed")==true and serial()==action_serial,"COMPLETED_EXACTLY_ONCE:"+String(row.kind)):return false
	if not need(frames.size()==4 and frames.has(0) and frames.has(1) and frames.has(2) and frames.has(3) and advanced and final.get("audio_cues",[]).size()==1,"FOUR_REAL_POSES_AND_REAL_AUDIO_PLAYBACK_TICK:"+String(row.kind)):return false
	if not need(count_item(String(row.item))==owned+2 and not gather.call("is_available",String(row.site)) and business()==before.business,"EXACT_TWO_ONLY_AFTER_COMPLETION_NO_STORY_CHANGE:"+String(row.kind)):return false
	if not need(actor.can_move and actor.sprite.visible and body()==physical and actor.global_position==at,"RESTORE_ORIGINAL_SPRITE_BODY_OWN_MOVEMENT:"+String(row.kind)):return false
	var after: Dictionary=bag();await begin_row(row)
	if not need(bag()==after and not debug_action().get("active",false) and serial()==action_serial,"HARVESTED_POINT_REPEATED_REAL_INPUT_NO_DUPLICATE:"+String(row.kind)):return false
	await key_edge(KEY_D,true);await create_timer(.04).timeout;await key_edge(KEY_D,false)
	return need(actor.global_position.distance_to(at)>1 and actor.can_move,"REAL_SMALL_MOVEMENT_AFTER_COMPLETION:"+String(row.kind))

func _run() -> void:
	directory=OUT+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	if not need(suspended and root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"EARLIEST_CHECKPOINT_SUSPEND"):finish();return
	if not need(FileAccess.file_exists(PIN_FILE),"FINAL_EXACT_PIN_FIXTURE_REQUIRED_DRAFT_MUST_NOT_RUN"):finish();return
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(PIN_FILE))
	if not need(raw is Dictionary and raw.get("ready")==true and raw.get("pins",{}).size()>0,"FINAL_READY_PIN_SCHEMA"):finish();return
	pins=raw.pins;first_sources=sources()
	for path: String in pins:
		if not need(first_sources[path].sha256==String(pins[path]).to_lower(),"EXACT_SOURCE:"+path):finish();return
	life=root.get_node("LifeSkills");inventory=root.get_node("Inventory");game=root.get_node("GameState");gather=load(GATHER_PATH) as Script
	profiles=JSON.parse_string(FileAccess.get_file_as_string("res://scripts/life_skills/gathering_actions_20261030l.json")).get("actions",{})
	if not need(life.has_method("get_gather_action_debug"),"FINAL_REAL_LIFESKILLS_ACTION_API"):finish();return
	if not await near_row(ROWS[0],true):finish();return
	if not need(game.get("player")!=null,"REAL_FIELD_CREATED_PRIVATE_PLAYER"):finish();return
	seed_inventory_case(true)
	if not await unchanged_no_start(ROWS[0],"FULL_BAG_BEFORE_ACTION"):finish();return
	seed_inventory_case(false)
	if not await cancel_escape(ROWS[0]) or not await cancel_move_and_boundary(ROWS[0]):finish();return
	if not await near_row(ROWS[0],false) or not await complete_one(ROWS[0]):finish();return
	if not await near_row(ROWS[1],true) or not await complete_one(ROWS[1]):finish();return
	finish()

func finish() -> void:
	if done:return
	done=true
	var last: Dictionary=sources() if not first_sources.is_empty() else {}
	if not first_sources.is_empty():need(first_sources==last,"EXACT_FIRST_FINAL_SOURCE_METADATA")
	need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"CHECKPOINT_SUSPENDED_UNTIL_OWNED_EXIT")
	var path: String=directory+"/result.json"
	if FileAccess.file_exists(path):quit(2);return
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"inputs":inputs,"records":records,"first_sources":first_sources,"final_sources":last,"private_inventory_fixture_only":true,"real_save_reads":0,"real_save_writes":0,"SaveManager_API_calls":0,"public_default_bootstrap_then_same_ID_near_setup_not_continuous_route":true,"real171save_metadata_guard_owned_by_Root":true,"old754_146_and11doors_retested":false},"\t")+"\n");file.close()
	print("GATHER_ACTION_RESULT ",checks," / ",errors.size());quit(0 if errors.is_empty() else 1)
