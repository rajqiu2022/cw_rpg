extends "res://tests/test_live_city_world_gate_warm_key_20261017j.gd"
## One old inn only. No eleven-interiors flag, no world trip, no new geometry.
const INN_ID="luoyang_market_inn_interior_20261015"
const MARKET_ID="ch4_s3_luoyang_market"
const ROOM_RAW=preload("res://tests/helpers/v15_field_raw_oracle.gd")
const TASK=preload("res://scripts/city/luoyang_city_tasks_20261016.gd")
const ELEVEN=preload("res://scripts/city/luoyang_assembled_interiors_20261016g.gd")
const PAPER_QUEST=&"q_ch4_side_02_luoyang_paper"
const PAPER_FLAG=&"luoyang_paper_started"
const DIRTY_PINS={
	"res://tests/test_live_city_world_gate_warm_key_20261017j.gd":"5d58e78714760b29f82fc8a0d22355883e45a6a3609128037e2ac15a12ba2118",
	"res://tests/helpers/v15_field_raw_oracle.gd":"dc36f4144496477508f9ad8b346f846043db109415760ab87205fa814aad26fb",
	"res://data/scenes/luoyang_home_candidates_20261015/inn_room.tres":"03089c37565ff6ada3ca923def003a2dabb118683ad843f6ab50c241eac02af3",
	"res://data/maps/luoyang_home_candidates_20261015/inn_room_layout.tres":"51500c5ee31ec092e42b8975f7e6c70860882ef4e90de427b1f0a66b41ed8fc6",
	"res://scripts/city/luoyang_city_tasks_20261016.gd":"27944bbb516bce10fad01b02efd714f1ce63029adcdaf83e701445962d34e13c",
	"res://scripts/city/luoyang_assembled_interiors_20261016g.gd":"b84fc5a6a8db5d2ec7f0235b5985fc0ae0f605f5a0c960f183b2f5005b785731",
	"res://scripts/city/luoyang_temple_assembly_20261016.gd":"9d0a5d265ab40d2b7f8fc5a82cb8493d9812bec7fc7479f634d733aba15deb07",
	"res://data/maps/luoyang_temple_assembly_20261016/binding_eleven_interiors_v4.json":"b900c84a8f0980d37ef92bff4569722730bae013e2e0d19272ba643a1ac883b4"}
var room_raw: RefCounted
var market_static: Dictionary={}
var market_nav: Dictionary={}
var market_ambient: Dictionary={}
var market_node: Node
var market_scene: SceneScript
var market_oracle: RefCounted

func _ambient(node: Node) -> Dictionary:
	var result: Dictionary=super._ambient(node)
	for npc: Node in node.get("_npc_nodes"):
		var id: String=String(npc.get("npc_id"))
		if not id.begins_with("district_life_"): continue
		var body: Node=npc.get("_body_collider")
		result[id]={"node":npc.get_instance_id(),"sprite":npc.get_node("Sprite2D").get_instance_id(),"body":body.get_instance_id(),"shape":body.get_child(0).get_instance_id()}
	return result

func precheck() -> bool:
	if not super.precheck(): return false
	for path: String in DIRTY_PINS:
		if not track(path,DIRTY_PINS[path]): return false
	if not check(not ELEVEN.enabled() and not ELEVEN.known(StringName(INN_ID)),"Current old inn only; eleven room candidate stays disabled"): return false
	for path: String in TASK.source_paths():
		if not source_before.has(path) and not track(path,FileAccess.get_sha256(path)): return false
	var png: String="res://art/backgrounds/bg_interior_inn_hall_v1.png"
	if not track(png,"773926b48b8687bc3831208f8ba3948e89d25f275bc021c86f0f9b7df326abee"): return false
	var config:=ConfigFile.new()
	if not check(config.load(png+".import")==OK,"Actual old inn importer available"): return false
	if not track(png+".import","6c7d69b8436f6b72316afb509ff075158d3c8f57436e5433595d673954d8cc19"): return false
	return track(String(config.get_value("remap","path","")),"039cb5f62a7e1bdd1a6dc4309653bbb01bfdbeec4e4c97f5538713e67a0b8405")

func _wait_once(target: String,source_id: String="") -> bool:
	var began: int=Time.get_ticks_msec();var until: int=mini(deadline,began+60000)
	while Time.get_ticks_msec()<until:
		await process_frame
		if _busy() or not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): continue
		var candidate: SceneScript=current_scene.get("_current_scene") as SceneScript
		if candidate==null or String(candidate.scene_id)!=target: continue
		var state: Dictionary=current_scene.call("get_field_loading_state")
		if state.get("failed",false): return check(false,"Actual inn/Market Field failure",state)
		var player: CharacterBody2D=current_scene.get("_player") as CharacterBody2D
		var screen: Node=root.get_node("LoadingManager").get("_screen")
		var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
		if not state.get("complete",false) or player==null or not player.is_inside_tree() or not player.get("can_move") or (panel!=null and panel.is_visible_in_tree()): continue
		field=current_scene;scene=candidate
		if target==MARKET_ID:
			var proof: Dictionary=C.resident_receipt(scene)
			if not check(proof.get("sources_finalized")==true and not proof.get("sources",{}).is_empty(),"Market full original first/final source owner still bound, warm not fresh SHA"): return false
			for path: String in DIRTY_PINS:
				if path.begins_with("res://scripts/") or path.contains("binding_eleven_interiors"):
					if not check(proof.sources.get(path)==DIRTY_PINS[path],"Market actual source proof includes current dependency "+path): return false
			for path: String in source_before:
				if proof.sources.has(path) and not check(proof.sources[path]==source_before[path].sha256,"Actual source first/final unchanged "+path): return false
			records.append({"kind":"MARKET_READY_FULL_SOURCE_PROOF","proof":proof})
		return true
	return check(false,"Fixed60 arrival/90 shared, no extension",{"target":target,"source":source_id,"C":C.transition_validation_state(),"errors":C.errors(),"resident":root.get_node("SceneRouter").call("get_resident_city_state")})

func _old_room_bind() -> bool:
	var player: CharacterBody2D=field.get("_player")
	var shape: CollisionShape2D=player.get_node("CollisionShape2D")
	var actual: Vector2=field.get("_world_size")
	if not check(scene.resource_path=="res://data/scenes/luoyang_home_candidates_20261015/inn_room.tres" and not scene.actor_positions_are_feet and actual==Vector2(1920,1280) and scene.player_visual_scale==1.18 and shape.position==Vector2(0,42) and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size==Vector2(34,24),"Actual old inn legacy origin/cover/native42 and34x24, not assembled feettrue"): return false
	var clone: Resource=scene.map_layout.duplicate(true)
	clone.set("design_size",Vector2i(actual))
	room_raw=ROOM_RAW.new()
	records.append({"kind":"ACTUAL_OLD_INN_COORDINATES","origin":player.position,"collider_center":player.position+shape.position,"visual_foot_offset":player.call("_visual_foot_offset"),"depth":player.call("get_depth_sort_y"),"world_size":actual,"sprite_scale":player.get_node("Sprite2D").scale,"legacy_visible_foot_alignment_claimed":false})
	return check(room_raw.configure(clone) and room_raw.solids.size()==4 and room_raw.regions.size()==1 and _clear(player.position),"Independent actual cover/raw legacy layout; physical and visual anchor domains kept separate",room_raw.get("errors"))

func _room_ground(origin: Vector2) -> bool:
	if room_raw==null or not room_raw.clear(origin): return false
	var shape: CollisionShape2D=field.get("_player").get_node("CollisionShape2D")
	var center: Vector2=origin+shape.position
	if not room_raw.clear(center): return false
	var rect:=Rect2(center-Vector2(17,12),Vector2(34,24))
	var body:=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	var inside:=false
	for region: PackedVector2Array in room_raw.regions:
		var world:=PackedVector2Array()
		for point: Vector2 in region: world.append(point*room_raw.size)
		if Geometry2D.clip_polygons(body,world).is_empty(): inside=true;break
	if not inside: return false
	for solid: Dictionary in room_raw.solids:
		if rect.intersects(solid.rect,true): return false
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			var sample: Vector2=center.round()+Vector2(x,y)
			if not room_raw.pixel_evidence(sample).get("clear",false): return false
			for solid: Dictionary in room_raw.solids:
				if (solid.rect as Rect2).has_point(sample): return false
	return true

func _clear(origin: Vector2) -> bool:
	if scene==null or String(scene.scene_id)!=INN_ID: return super._clear(origin)
	if Time.get_ticks_msec()>=deadline or current_scene!=field or not _room_ground(origin): return false
	var player: CharacterBody2D=field.get("_player")
	var shape: CollisionShape2D=player.get_node("CollisionShape2D")
	var world: Node2D=field.get("world_container")
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape;query.transform=shape.global_transform;query.transform.origin+=world.to_global(origin)-player.global_position
	query.exclude=[player.get_rid()];query.collision_mask=1;query.collide_with_areas=false;native_queries+=1
	return player.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _segment(a: Vector2,b: Vector2) -> Dictionary:
	if scene==null or String(scene.scene_id)!=INN_ID: return super._segment(a,b)
	var count: int=maxi(1,ceili(a.distance_to(b)/4.0))
	for index: int in range(count+1):
		if not _room_ground(a.lerp(b,float(index)/count)): return {"clear":false,"index":index}
	return {"clear":true,"samples":count+1,"max_step_px":a.distance_to(b)/count}

func _exercise() -> bool:
	var router: Node=root.get_node("SceneRouter")
	var began: int=Time.get_ticks_usec()
	var accepted: bool=router.call("go_field_smart",StringName(MARKET_ID),Vector2(735,920)/Vector2(3072,2048),"",-1,C.VERSION)
	records.append({"kind":"PUBLIC_LEGAL_MARKET_NEAR_SETUP_ONLY","accepted":accepted,"call_usec":Time.get_ticks_usec()-began,"not_world_or_cross_city_travel":true})
	if not check(accepted,"One legal current3 Market setup") or not await _wait_once(MARKET_ID): return false
	district="market";scene_id=MARKET_ID
	if not _bind_actual() or not await _walk(PackedVector2Array([Vector2(735,920),Vector2(735,864)])) or not _zone(INN_ID): return false
	market_node=field;market_scene=scene;market_oracle=oracle;market_static=field.call("resident_static_identity")
	market_nav={"record":C._records[MARKET_ID].duplicate(true),"solids":C._solids[MARKET_ID].duplicate(true),"mask":C._masks[MARKET_ID],"bytes":C._masks[MARKET_ID].get_data(),"using":C._using_patch[MARKET_ID]}
	market_ambient=_ambient(field);validations_before=int(C.transition_validation_state().get("full_validations_total"));watch_jobs=true
	if not check(market_ambient.size()==10,"All10 current Market ambient instances captured, not empty-prefix proxy"): return false
	if not await _space_to(INN_ID,"ONE_REAL_OLD_INN_ENTRY") or not _old_room_bind(): return false
	if not check(not market_node.is_inside_tree() and router.call("get_resident_city_state").get("excursion_kind")=="room","Actual original exterior parked while old inn current"): return false
	var quests: Node=root.get_node("QuestManager")
	var before: Dictionary=quests.call("to_dict")
	var accepted_quest: bool=quests.call("accept",PAPER_QUEST)
	root.get_node("GameState").call("set_flag",PAPER_FLAG,true)
	var expected: Dictionary=quests.call("to_dict")
	if not check(accepted_quest and not C._equal_value(before,expected),"Actual isolated in-memory quest acceptance and flag dirty state; no save call"): return false
	var exits: Array=scene.map_layout.portals
	if not check(exits.size()==1 and exits[0].target_scene==MARKET_ID,"Original old inn unique return door"): return false
	var target: Vector2=exits[0].pos*Vector2(field.get("_world_size"))-Vector2(0,36)
	if not await _walk(PackedVector2Array([field.get("_player").position,target])) or not _zone(MARKET_ID): return false
	if not await _space_to(MARKET_ID,"DIRTY_OLD_INN_RETURN",true): return false
	watch_jobs=false;oracle=market_oracle
	var refreshed: Dictionary=field.call("get_resident_dynamic_refresh_state")
	var scholars: Array=[]
	for npc: Node in field.get("_npc_nodes"):
		if String(npc.get("npc_id"))=="luoyang_paper_scholar": scholars.append(npc)
	if not check(field==market_node and scene==market_scene and field.call("resident_static_identity")==market_static and _ambient(field)==market_ambient and C._masks[MARKET_ID]==market_nav.mask and C._masks[MARKET_ID].get_data()==market_nav.bytes and C._equal_value(C._records[MARKET_ID],market_nav.record) and C._equal_value(C._solids[MARKET_ID],market_nav.solids) and C._using_patch[MARKET_ID]==market_nav.using,"Dirty return same Field/Scene/static/ambient/native nav and mask Image+RGBA"): return false
	if not check(refreshed.get("dynamic_only")==true and refreshed.get("static_objects_preserved")==true and refreshed.get("current_flags_applied")==true and int(refreshed.get("ambient_preserved",0))==market_ambient.size() and C._equal_value(quests.call("to_dict"),expected) and root.get_node("GameState").call("get_flag",PAPER_FLAG)==true and scholars.size()==1 and String(scholars[0].get("dialog_id"))=="luoyang_city_tasks_20261016/paper_progress" and (scholars[0] as CanvasItem).is_visible_in_tree() and field.get("_player").position==Vector2(735,864),"Current task NPC/dialog projected from live queststate, exact remembered non-axis door return",refreshed): return false
	records.append({"kind":"DIRTY_CURRENT_STATE","refresh":refreshed,"quest":expected,"ambient_ids":market_ambient,"cold_job_frames":cold_job_frames,"source_fresh_sha":false})
	return await _walk(PackedVector2Array([Vector2(735,864),Vector2(751,864)])) and await _capture("old_inn_dirty_live_return")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+90000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_live_city_dirty_inn_20261017j/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete:=false
	if precheck():
		driver=INPUT.new();driver.configure(self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		complete=await _exercise()
	if driver!=null: driver.release();driver=null
	root.get_node("SceneRouter").call("reset_for_new_game")
	if is_instance_valid(current_scene): current_scene.queue_free()
	await process_frame;await process_frame
	field=null;scene=null;oracle=null;market_node=null;market_scene=null;market_oracle=null;room_raw=null;market_static.clear();market_nav.clear();market_ambient.clear();frame_images.clear()
	records.append({"kind":"SCOPE","whole_ms":90000,"arrival_ms":60000,"dirty_return_limit_usec":2000000,"captures":captures,"native_queries":native_queries,"eleven_rooms_enabled":false,"old_legacy_inn_only":true})
	finish(folder,began,complete,"ONE_OLD_INN_DIRTY_DYNAMIC_RETURN_ONLY")
