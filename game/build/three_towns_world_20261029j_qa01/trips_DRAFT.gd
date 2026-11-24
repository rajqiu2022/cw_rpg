extends SceneTree
## Root-only three new World↔town legs. No old layout/bridge/stair replay.
const FIXTURE := "res://build/three_towns_world_20261029j_qa01/trips_READY.json"
const OUTPUT := "res://build/three_towns_world_20261029j_qa01/actual/"
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

func _initialize() -> void: _run.call_deferred()
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

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not need(raw is Dictionary and raw.get("ready")==true,"EXACT_ROOT_FROZEN_FIXTURE"):finish();return
	spec=raw
	if not need(spec.legs.size()>=1 and spec.legs.size()<=3 and spec.whole_seconds<=120 and spec.entry_seconds==20,"ONE_TO_THREE_BOUNDED_NEW_LEGS"):finish();return
	source_before=file_facts(spec.fixed_sources.keys());save_before=file_facts(spec.registered_save_paths)
	for path: String in spec.fixed_sources:need(source_before[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path)
	sr=root.get_node_or_null("SceneRouter");gs=root.get_node_or_null("GameState");lm=root.get_node_or_null("LoadingManager");dp=root.get_node_or_null("DialogPlayer")
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if not need(sr!=null and gs!=null and lm!=null and dp!=null and platform!=null,"FORMAL_AUTOLOADS"):finish();return
	platform.call("set_checkpoint_saves_suspended",true)
	need(platform.call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED_FOR_COMPLETE_TEST_PROCESS")
	if spec.get("process_only_stats_sentinel",false):
		var hero: Resource=gs.get("player") as Resource
		if not need(hero!=null,"EXISTING_LIVE_PLAYER_FOR_SENTINEL_NOT_CREATED_FAKE_STATS"):finish();return
		hero.set("hp",maxi(1,int(hero.get("max_hp"))-7));hero.set("mp",maxi(0,int(hero.get("max_mp"))-3));gs.set("gold",137)
		records.append({"qa_process_only_sentinel":true,"hp":"max-7","mp":"max-3","gold":137,"user_save_read_or_write":false})
	state_before=live_state()
	if not errors.is_empty():finish();return
	for leg: Dictionary in spec.legs:
		if not await run_leg(leg):finish();return
	need(png_count==spec.legs.size() and live_state()==state_before and active(),"ALL_NEW_LEGS_PRESERVE_SAME_SESSION_AND_ONE_IMAGE_EACH")
	finish()

func run_leg(leg: Dictionary) -> bool:
	var started:=Time.get_ticks_msec()
	var world_id: String=String(leg.world_id)
	if not need(world_id in ["world_map_jianghu","world_map_jianghu_v15"],"ONLY_TWO_EXISTING_WORLD_ALIASES"):return false
	if not need(sr.call("go_field_smart",StringName(world_id),point(leg.world_setup_foot)/point(spec.world_size),"",15,-1)==true,"PUBLIC_WORLD_GATE_SETUP:"+leg.id):return false
	var world: Node=await wait_world(world_id)
	if world==null:return false
	var scene: Resource=world.get("_current_scene") as Resource
	var layout: Resource=scene.get("map_layout") as Resource
	need((layout.get("portals") as Array).size()==16,"ORIGINAL_CACHED_WORLD_SIXTEEN_PORTALS_RETAINED")
	var rows: Array=[]
	# New town portals are an explicit overlay; the original cached 16 stay intact.
	var overlay: Variant=load(String(spec.overlay_script))
	var all_rows: Array=overlay.call(String(spec.portal_rows_method))
	for row: Dictionary in all_rows:
		if String(row.get("id"))==String(leg.portal_id):rows.append(row)
	if not need(rows.size()==1 and String(rows[0].get("target_scene"))==String(leg.id) and String(rows[0].get("label"))==String(leg.label),"ONE_FORMAL_CHINESE_PORTAL:"+leg.id):return false
	var expected_anchor: Vector2=rows[0].get("source_spawn_pos",rows[0].get("pos"))
	if not need(expected_anchor.distance_to(point(leg.expected_world_anchor_uv))<.0000001,"AUTHORED_ANCHOR_FROZEN_BEFORE_DEPARTURE:"+leg.id):return false
	var zones: Array=[]
	for zone: Node in world.get("_exit_nodes"):
		if String(zone.get("target_scene_id"))==String(leg.id):zones.append(zone)
	for _tick: int in range(3):await physics_frame
	if not need(zones.size()==1 and zones[0].call("can_enter")==true,"REAL_WORLD_ENTRY_CAN_ENTER:"+leg.id):return false
	if not verify_world_labels(world,leg):return false
	await key(KEY_SPACE)
	var wrapper: Node=await wait_town(leg)
	if wrapper==null:return false
	var town: Node=wrapper.get_node(NodePath(leg.town_node))
	var actor: Node2D=town.get("actor") as Node2D
	if not need(is_instance_valid(actor) and actor.global_position.distance_to(point(leg.arrival_foot))<=1,"LATEST_NATIVE_TOWN_ARRIVAL:"+leg.id):return false
	if not need(String(town.scene_file_path)==String(leg.source_scene) and String(town.get_script().resource_path)==String(leg.source_controller),"LATEST_SCENE_AND_CONTROLLER_NOT_OLD_DRAFT:"+leg.id):return false
	if not need(live_state()==state_before,"LIVE_PLAYER_PARTY_HP_MP_GOLD_QUESTS_CARRIED:"+leg.id):return false
	if not verify_live_hud(wrapper,leg):return false
	if not m_map_checked:
		if not await verify_m_map(wrapper,point(leg.expected_world_anchor_uv)):return false
	if leg.get("terrain",false):
		var terrain: Node=town.get("terrain") as Node
		if not need(terrain!=null and String(terrain.get_script().resource_path)==String(leg.terrain_script) and terrain.get("actor_level")==0,"LANXI_LATEST_REAL_THREE_LEVEL_TERRAIN_RETAINED"):return false
	var before: Vector2=actor.global_position
	var controller_id: int=town.get_instance_id();var actor_id: int=actor.get_instance_id()
	await held_key(int(leg.step_key),int(leg.step_ticks))
	var after: Vector2=actor.global_position
	if not need(after.distance_to(before)>=24 and after.distance_to(before)<=50,"SHORT_TRUE_PHYSICAL_INPUT_NOT_ACTOR_ASSIGNMENT:"+leg.id):return false
	await held_key(int(leg.reverse_key),int(leg.step_ticks))
	if not need(actor.global_position.distance_to(before)<=8 and town.get_instance_id()==controller_id and actor.get_instance_id()==actor_id,"RETURN_SHORT_WALK_SAME_REAL_TOWN_AND_ACTOR:"+leg.id):return false
	if not verify_navigation(leg,actor):return false
	if not await capture(String(leg.screenshot_name)):return false
	if not need(live_state()==state_before,"NO_STATE_CHANGE_AFTER_NATIVE_SHORT_MOVE:"+leg.id):return false
	var exit: Node=wrapper.get("town_exit")
	if not need(is_instance_valid(exit) and exit.call("can_enter")==true,"NATIVE_RETURN_EXIT_ACTUALLY_ENTERABLE:"+leg.id):return false
	await key(KEY_SPACE)
	world=await wait_world(world_id)
	if world==null:return false
	var world_actor: Node2D=world.get("_player") as Node2D
	if not need(world_actor.position.distance_to(expected_anchor*point(spec.world_size))<=1,"REAL_EXIT_RETURNS_PRECAPTURED_WORLD_ANCHOR:"+leg.id):return false
	if not need(live_state()==state_before,"SAME_CURRENT_PLAYER_PARTY_AND_BUSINESS_AFTER_RETURN:"+leg.id):return false
	records.append({"town":leg.id,"world_alias":world_id,"elapsed_ms":Time.get_ticks_msec()-started,"world_anchor_frozen_before_space":expected_anchor,"arrived_native_foot":before,"short_walk_end":after,"source_scene":town.scene_file_path if is_instance_valid(town) else leg.source_scene,"default_long_distance_or_cold_performance_claim":false})
	return true

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

func verify_live_hud(wrapper: Node,leg: Dictionary) -> bool:
	var hud: Node=wrapper.get("_primary_hud") as Node
	var hero: Resource=gs.get("player") as Resource
	if not need(hud!=null and hud.get_script()!=null and String(hud.get_script().resource_path)=="res://scripts/ui/field_primary_hud.gd" and (hud as CanvasItem).is_visible_in_tree(),"FORMAL_VISIBLE_FIELD_PRIMARY_HUD:"+leg.id):return false
	var hp: Label=hud.get_node("PlayerInfoPanel/HpText") as Label
	var mp: Label=hud.get_node("PlayerInfoPanel/MpText") as Label
	var name: Label=hud.get_node("PlayerInfoPanel/NameLabel") as Label
	var gold: Label=hud.get_node("PlayerInfoPanel/GoldLabel") as Label
	return need(hp.text=="%d / %d"%[hero.get("hp"),hero.get("max_hp")] and mp.text=="%d / %d"%[hero.get("mp"),hero.get("max_mp")] and name.text==String(hero.get("display_name")) and gold.text.begins_with("金 %d"%gs.get("gold")),"HUD_SHOWS_ACTUAL_NONRESET_LIVE_PLAYER:"+leg.id)

func verify_navigation(leg: Dictionary,actor: Node2D) -> bool:
	# Read the actual serialization input; do not save, restore or stage real user data.
	var navigation: Dictionary=sr.call("get_navigation_state")
	var scene: Resource=load("res://data/scenes/%s.tres"%String(leg.id)) as Resource
	if not need(scene!=null and String(scene.get("scene_id"))==String(leg.id),"CANONICAL_SCENE_RECOGNIZABLE_WITHOUT_SAVE_WRITE:"+leg.id):return false
	var foot: Vector2=point(navigation.get("current_field_spawn",[]))*point(leg.town_size)
	var returns: Dictionary=navigation.get("portal_return_spawns",{})
	var return_key:=String(leg.id)+"->"+String(leg.world_id)
	if not need(String(navigation.get("current_field"))==String(leg.id) and foot.distance_to(actor.global_position)<=1 and int(navigation.get("local_layout_versions",{}).get(String(leg.id),-1))==1,"SERIALIZABLE_CURRENT_TOWN_FOOT_AND_LAYOUT_VERSION:"+leg.id):return false
	return need(point(returns.get(return_key,[])).distance_to(point(leg.expected_world_anchor_uv))<.0000001,"SERIALIZABLE_RETURN_TO_SAME_ACTUAL_WORLD_ALIAS:"+leg.id)

func verify_world_labels(world: Node,leg: Dictionary) -> bool:
	var minimap: Node=world.get("_world_travel_minimap")
	if not need(is_instance_valid(minimap) and minimap.has_method("get_debug_state"),"LIVE_WORLD_MINIMAP_EXISTS"):return false
	var data: Dictionary=minimap.call("get_debug_state")
	var pips: Node=minimap.get_node_or_null("ThreeTownPips")
	if not need(pips!=null and pips.has_method("get_debug_state"),"NEW_MINIMAP_PIPS_NODE_EXISTS"):return false
	var extra: Dictionary=pips.call("get_debug_state")
	if not need((data.get("portals",[]) as Array).size()==16 and (extra.get("portals",[]) as Array).size()==3 and extra.get("view_only")==true,"MINIMAP_ORIGINAL16_PLUS_THREE_READONLY_ADDITIONS"):return false
	var found:=0
	for row: Dictionary in extra.get("portals",[]):
		if String(row.get("id"))==String(leg.portal_id) and String(row.get("target_scene"))==String(leg.id):found+=1
	return need(found==1,"MINIMAP_SAME_NEW_TOWN_PORTAL_ID_AND_TARGET:"+leg.id)

func verify_m_map(field: Node,expected_world_marker_uv: Vector2) -> bool:
	await key(KEY_M)
	for _frame: int in range(3):await process_frame
	var panel: Node=field.get("_world_map_panel")
	if not need(is_instance_valid(panel) and (panel as CanvasItem).is_visible_in_tree(),"FORMAL_M_MAP_OPENS"):return false
	var map_root: Node=panel.get("map_rect")
	if not need(map_root!=null,"FORMAL_M_MAP_LABEL_ROOT"):return false
	for leg: Dictionary in spec.legs:
		var count:=0
		for child: Node in map_root.get_children():
			if child is Label and (child as Label).text==String(leg.label):count+=1
		need(count==1,"M_MAP_ONE_CHINESE_NEW_TOWN_LABEL:"+leg.id)
	var markers: Array=[]
	for child: Node in map_root.get_children():
		if child is Sprite2D and child.has_meta("world_map_runtime"):markers.append(child)
	need(markers.size()==1 and (markers[0] as Sprite2D).position.distance_to(expected_world_marker_uv*(map_root as Control).size+Vector2(0,-29))<.01,"M_MAP_PLAYER_MARKER_MATCHES_CURRENT_TOWN_WORLD_LOCATION")
	await key(KEY_ESCAPE)
	for _frame: int in range(2):await process_frame
	m_map_checked=true
	return need(not (panel as CanvasItem).is_visible_in_tree(),"M_MAP_CLOSES_WITHOUT_FAST_TRAVEL_OR_STATE_CHANGE") and errors.is_empty()

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

func capture(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image()
	var path:=OUTPUT+str(OS.get_process_id())+"/"+name+".png"
	if not need(image!=null and image.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"ONE_NEW_NORMAL_NATIVE_IMAGE:"+name):return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not need(image.save_png(path)==OK,"SAVE_NATIVE:"+name):return false
	png_count+=1;records.append({"normal_native_image":path,"sha256":FileAccess.get_sha256(path),"actor_or_camera_writes":0});return true
func finish() -> void:
	release_input()
	if not source_before.is_empty():need(source_before==file_facts(source_before.keys()),"BOUNDED_SOURCE_FIRST_FINAL")
	if not save_before.is_empty():need(save_before==file_facts(save_before.keys()),"REGISTERED_SAVES_HASH_BYTES_SECONDS_SAME_ROOT_EXACTTICKS_SEPARATE")
	var path:=OUTPUT+str(OS.get_process_id())+"/three_towns_result.json"
	if FileAccess.file_exists(path):quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f:=FileAccess.open(path,FileAccess.WRITE)
	if f==null:quit(2);return
	f.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":input_ticks,"normal_png_count":png_count,"records":records,"fixture_sha256":FileAccess.get_sha256(FIXTURE),"qa_actor_or_camera_writes":0,"qa_save_writes":0,"old_layout_bridge_stair_matrices_replayed":false},"\t"));f.close()
	print("[ThreeTowns] "+str(checks)+" checks / "+str(errors.size())+" failures; "+path);quit(0 if errors.is_empty() else 1)
