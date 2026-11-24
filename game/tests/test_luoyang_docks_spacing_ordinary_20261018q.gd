extends "res://tests/test_luoyang_three_doors_actual_retry3_20261018q.gd"
## Ordinary no-flag spacing smoke. Parent is utilities only; no old180px/north-door trip.
const SPACING_READY=true
const SPACING_WHOLE_MS=90000
const P=preload("res://scripts/city/luoyang_building_spacing_20261017p.gd")
const CITY_TASKS=preload("res://scripts/city/luoyang_city_tasks_20261016.gd")
const OFFICE=preload("res://scripts/city/luoyang_docks_office_roles_20261016h.gd")
const CROWD=preload("res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd")
const DISTRICT_PATH="res://scripts/city/luoyang_district_life_20261016f.gd"
const TEMPLE_BIND="res://data/maps/luoyang_temple_assembly_20261016/binding_spacing_fusion_v11.json"
var spacing: Dictionary={}
var publication: Dictionary={}
var spacing_sources: Dictionary={}
var actual_record: Dictionary={}
func _spacing_precheck() -> bool:
	if not check(SPACING_READY,"NOTREADY until ROOT freezes and deploys exact spacing+g+Temple fused dependencies"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and OS.get_cmdline_user_args().is_empty(),"Ordinary no candidate flags and real GUI clock"): return false
	var pins: Dictionary={P.SELF:"1c94f23ad8e69022712aeffdf7ebd125d201cede2838e4e45d38fadbacb35b16",P.BIND_PATH:"a52e4b51474c4b5232448004e7de85aaad6a8918140127f1ad3453764d22c06c",P.AUTHOR_PATH:"a6eccd68c78947af74de4fed5e1d844f464d316e21d9524688cf5439f92571ad",M.SELF:"d82232b96035f365652831238bad490e79dc973b75d3550c79d6ab6b2070b979","res://data/maps/luoyang_assembled_interiors_20261016g/registry_spacing_dependency_v3.json":"959bc6f5408261586a6165bf731347959e6287bea9afa8bfb40f6e4035302ad5","res://scripts/city/luoyang_harbour_life_runtime_20261016.gd":"1a269bc65df4aa70edd59a67ee5415768bee039ea52188939905746a99ef61ad",DISTRICT_PATH:"6921fa796c419202fc9707559addabdb013ea0b37ec51e6303e9f4923a79fc17","res://scripts/autoload/scene_router.gd":"9cfbf3d17cb263b63d50558b5d95a574286bfe921da45dccda04a84272caa869","res://scripts/city/luoyang_temple_assembly_20261016.gd":"cde7675f20904610c3fba203e2a4fa9bb947d049e23f2e154a2d9c0ff1b56f90",TEMPLE_BIND:"33dcf6d9e1eb55841951c5610f71d021deb5ba3f0ed72bc3d617131e07c1d3be","res://scripts/field/field_walkable_controller.gd":"638cd8f0a37aacff56d074383d868f2d00bab3b81fcf56bf4d148fb84f556839","res://scripts/autoload/loading_manager.gd":"5550a037e8001069713b0af317a6db2cd2ac427189f8f75d2e87e755ece210db","res://scripts/city/luoyang_resident_field_20261016.gd":"f1730e461fe6328763cfd70c79b2bbc36c80a2afb7609c364fa7ea7af8acdd7f","res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"06244b1dc286149ce8299cd83f766d2d9f5fd9b61bcb59180261dff40d8e9d3d",OFFICE.SELF:"627920a95b7352f2913d074df38a9ad6de1afcd9da0ae73d81477f6e03662f6e",OFFICE.AUTHOR_PATH:OFFICE.AUTHOR_SHA,RAW_PATH:RAW_SHA,"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7","res://tests/test_luoyang_three_doors_actual_retry3_20261018q.gd":"52aaaa3db603ba52504cd7dff1667e18d5f1013020d362fa7897181fb086b8e2","res://tests/test_luoyang_three_exterior_doors_cpu_20261016g.gd":"91c09043fc1ad85fb392909ed3b6235ddf064dee3bea943365c91cd88fdb5b89","res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd":"a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895"}
	for path: String in pins:
		if not track(path,pins[path]): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	if not track("res://scripts/city/luoyang_city_tasks_20261016.gd","27944bbb516bce10fad01b02efd714f1ce63029adcdaf83e701445962d34e13c") or not track(CITY_TASKS.SPEC_PATH,CITY_TASKS.SPEC_SHA): return false
	spacing=JSON.parse_string(FileAccess.get_file_as_string(P.BIND_PATH))
	if not check(P.FORMAL_ENABLED and P.enabled() and spacing.get("status")=="SPACING_CPU_AND_IMPORT_READY_CANDIDATE","Exact sole formal switch with historical CPU/import binding; old103 receipt never refreshed"): return false
	for path: String in spacing.source_sha256:
		if not track(path,spacing.source_sha256[path]): return false
	spacing_sources=spacing.source_sha256.duplicate(true)
	for path: String in [P.SELF,P.BIND_PATH,P.AUTHOR_PATH]: spacing_sources[path]=pins[path]
	package=M.catalogue()
	if not check(M.FORMAL_ENABLED and not package.is_empty(),"Default g remains enabled with explicit strict District dependency revision"): return false
	for path: String in package.source_sha256:
		if not track(path,package.source_sha256[path]): return false
	publication=JSON.parse_string(FileAccess.get_file_as_string(spacing.manifest_path))
	author=JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/luoyang_district_life_20261016f/author.json"))
	return check(spacing.cpu_source_first_final.result_sha256=="38844700a468cb966123926c694daae739458289650b4cda0a04f972d1338dfd" and spacing.cpu_source_first_final.source_count==103 and spacing.cpu_source_first_final.passed==true and publication.native_physics_not_run==true and publication.record.objects.size()==27,"Reuse immutable67340 CPU+isolatedimport; this key alone grants new runtime/Physics credit")
func _sprite(id: String) -> Sprite2D:
	for node: Node in field.get("_scene_object_nodes"):
		if String(node.name)=="SceneObject_"+id: return node as Sprite2D
	return null
func _spacing_bind() -> bool:
	actual_record=C._records.get(P.ID,{}).duplicate(true) # Existing prepared record only; never prepare/getter.
	if not check(P.bound(scene) and scene.actor_positions_are_feet and field.get("_world_size")==WORLD and actual_record.objects.size()==27,"Actual child Scene/metadata/27record/NAV identity"): return false
	var plain: Dictionary=actual_record.duplicate(true)
	for key: String in ["harbour_runtime_binding_sha","harbour_parent_task_semantics_preserved","spacing_runtime_binding_sha"]:
		if not check(plain.has(key),"Declared actual runtime receipt "+key): return false
		plain.erase(key)
	if not check(P.equal(plain,publication.record) and actual_record.spacing_runtime_binding_sha==P.BIND_SHA,"Complete child record in exact writer domain; no hidden field omissions"): return false
	var proof: Dictionary=C.resident_receipt(scene)
	for path: String in spacing_sources:
		if not check(proof.get("sources_finalized")==true and proof.get("sources",{}).get(path)==spacing_sources[path],"Actual same-owner finalized spacing source must be present "+path): return false
	var saved: Image=Image.load_from_file(spacing.walk_path)
	var actual_mask: Image=C._masks.get(P.ID)
	if not check(saved!=null and actual_mask!=null and saved.get_size()==Vector2i(WORLD) and saved.get_data()==actual_mask.get_data() and C._equal_value(C._solids.get(P.ID),C.object_solids(actual_record.objects)),"Actual committed full mask bytes and every native parent solid equal published child"): return false
	var flags: Dictionary=root.get_node("GameState").get("flags").duplicate(true)
	var quests: Dictionary=root.get_node("QuestManager").get("states").duplicate(true)
	var task_projection: Dictionary=CITY_TASKS.project(scene,flags,quests,scene.map_layout.interactions.duplicate(true))
	if not check(task_projection.get("ok")==true and task_projection.get("matched")==true,"Exact current task projection on the unchanged source Scene/interactions"): return false
	var expected_visuals: Dictionary={}
	for entry: Dictionary in task_projection.visual_objects:
		if not check(not expected_visuals.has(entry.id) and _sprite(entry.id)!=null,"Every exact task-projected parent Sprite exists "+entry.id): return false
		expected_visuals[entry.id]=true
	var task_phase: Dictionary=CITY_TASKS.stages(flags,quests)
	var intentionally_hidden: Array[String]=[]
	var physical: Array=[]
	for object: Dictionary in publication.record.objects:
		if not check(object.id!=P.REMOVED,"Removed duplicate cannot remain in the complete parent record"): return false
		if expected_visuals.has(object.id):
			if not check(_sprite(object.id)!=null,"Retained task-projected parent Sprite identity "+object.id): return false
		else:
			if not check(object.id=="warehouse_mud_trace" and object.get("blocking")==false and object.get("solid_polygons_px",[]).is_empty() and _v(object.collision_size_px)==Vector2.ZERO and int(quests.get(CITY_TASKS.CANAL,0))==0 and task_phase.canal=="not_started" and not bool(flags.get("canal_grudge_started",false)) and _sprite(object.id)==null,"Only exact new-game nonblocking zero-footprint mud is absent as authorized by current task projection, not a blanket Sprite exemption"): return false
			intentionally_hidden.append(object.id)
		var index:=0
		for poly: Array in object.get("solid_polygons_px",[]): physical.append({"id":String(object.id)+"_poly_"+str(index),"points_px":poly});index+=1
		var extent: Vector2=_v(object.collision_size_px)
		if extent.x>0 and extent.y>0:
			var center: Vector2=_v(object.physical_center_px);var low: Vector2=center-extent*.5;var high: Vector2=center+extent*.5
			physical.append({"id":String(object.id)+"_box","points_px":[low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)]})
	records.append({"kind":"EXACT_TASK_PROJECTED_PARENT_VISUALS","projected_count":expected_visuals.size(),"complete_record_count":publication.record.objects.size(),"intentionally_hidden":intentionally_hidden,"canal_status":int(quests.get(CITY_TASKS.CANAL,0)),"phase":task_phase,"all27_record_solids_checked_unchanged":true})
	var spec: Dictionary=author.districts[String(P.ID)]
	for placement: Dictionary in spec.placements:
		var asset: Dictionary=author.assets[placement.asset_id]
		if not check(_sprite(placement.id)!=null,"Existing District render addition retained "+placement.id): return false
		var index:=0
		for poly: Array in asset.ground_solid_polygons_px:
			var points: Array=[]
			for point: Array in poly: points.append(_v(placement.foot_px)+(_v(point)-_v(asset.source_ground_anchor_px))*float(placement.scale))
			physical.append({"id":String(placement.id)+"_delta_"+str(index),"points_px":points});index+=1
	independent=RAW.new();active_mask=actual_mask
	if not check(independent.configure([[[0,0],[3072,0],[3072,2048],[0,2048]]],physical,WORLD,WORLD),"Independent remove-only parent plus every retained District base"): return false
	if not check(_sprite(P.REMOVED)==null and field.find_child("CityV3Physical_"+P.REMOVED,true,false)==null and _clear_actual(field.get("_player").position),"No removed render/physical residual; actual ready birth full87517/nativePhysics"): return false
	for object: Dictionary in publication.record.objects:
		var body:=field.find_child("CityV3Physical_"+String(object.id),true,false) as StaticBody2D
		if not object.get("blocking",false): continue
		if not check(body!=null,"Every retained physical body exists "+object.id): return false
		var polygons: Array[PackedVector2Array]=[]
		for child: Node in body.get_children():
			if child is CollisionPolygon2D: polygons.append(child.polygon)
		if not check(polygons.size()==object.get("solid_polygons_px",[]).size(),"Retained exact polygon count "+object.id): return false
		for i: int in polygons.size():
			if not check(polygons[i]==C._polygon(object.solid_polygons_px[i]),"Retained actual native polygon coordinates "+object.id): return false
	return _preserved_people_office()
func _preserved_people_office() -> bool:
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OFFICE.AUTHOR_PATH))
	var office:=_sprite(OFFICE.BUILDING)
	if not check(office!=null and office.texture.resource_path==source.office.texture and scene.get_meta(OFFICE.META,"")==OFFICE.AUTHOR_SHA,"h office actual texture and visual-author metadata preserved"): return false
	var nodes: Dictionary={}
	for npc: Node2D in field.get("_npc_nodes"):
		if String(npc.get("npc_id")).begins_with("harbour_life_"): nodes[String(npc.get("npc_id"))]=npc
	if not check(nodes.size()==10,"Original ten Harbour crowd nodes retained"): return false
	var movers:=0;var observed: Array=[]
	for expected: Dictionary in CROWD.project(P.ID):
		if not check(nodes.has(expected.npc_id),"Exact original crowd ID "+expected.npc_id): return false
		var npc: NPCNode=nodes[expected.npc_id]
		var texture: String=source.roles[expected.npc_id].texture if source.roles.has(expected.npc_id) else expected.sprite_path
		if not check(npc.sprite_path==texture and npc.walk_sprite_path==expected.walk_sprite_path and npc.movement_mode==expected.movement_mode and npc.patrol_axis==expected.patrol_axis and npc.patrol_distance==expected.patrol_distance and npc.patrol_speed==expected.patrol_speed and npc.invert_patrol_facing==expected.invert_patrol_facing,"Original six lane configuration and only two h profession sprites preserved"): return false
		if expected.movement_mode=="patrol": movers+=1
		if source.roles.has(expected.npc_id):
			var body:=npc.get("_body_collider") as StaticBody2D;var collider:=body.get_child(0) as CollisionShape2D
			if not check(npc.position==_v(source.roles[expected.npc_id].expected_foot_px) and npc.sprite.hframes==1 and npc.sprite.vframes==1 and npc.sprite.texture.get_size()==Vector2(160,160) and (collider.shape as RectangleShape2D).size==Vector2(22.4,28.8),"Both real h160/1f profession actors retain feet/nativebody"): return false
		observed.append({"id":expected.npc_id,"position":npc.position,"mode":npc.movement_mode,"sprite":npc.sprite_path,"patrol_distance":npc.patrol_distance})
	records.append({"kind":"PRESERVED_HARBOUR_AND_OFFICE","npcs":observed,"moving_configuration":movers,"old8frame_walk_not_repeated":true,"office_texture":office.texture.resource_path})
	return check(movers==6,"Original six moving lanes configured; no repeat four-second crowd suite")
func _spacing_run() -> bool:
	var started: int=Time.get_ticks_usec()
	var accepted: bool=root.get_node("SceneRouter").call("go_field_smart",P.ID,Vector2(1500,662)/WORLD,"",-1,3)
	if not check(accepted,"Ordinary no-flag public version3 near restored ground; not travel") or not await _wait_actual(P.ID,60000) or not _spacing_bind(): return false
	records.append({"kind":"ORDINARY_SPACING_PUBLIC_SETUP_ONLY","elapsed_usec":Time.get_ticks_usec()-started,"travel_credit":false,"candidate_flags":OS.get_cmdline_user_args()})
	if not await _input(PackedVector2Array([Vector2(1500,662),Vector2(1500,630)]),"ordinary32px_restored_ground_only"): return false
	if not check(_clear_actual(Vector2(1500,630)),"Restored point native34x24/full87517 Physics, no residual invisible warehouse"): return false
	await RenderingServer.frame_post_draw
	var path: String=folder.path_join("ordinary_docks_spacing_32px.png")
	var image: Image=root.get_texture().get_image()
	if not check(image!=null and image.save_png(path)==OK,"One ordinary no-flag spacing screenshot"): return false
	pictures.append({"path":path,"sha256":FileAccess.get_sha256(path),"qa_camera_modified":false,"player":field.get("_player").position})
	records.append({"kind":"ORDINARY_SPACING_SMOKE_SCOPE","removed":P.REMOVED,"record_count":actual_record.objects.size(),"restored_foot":Vector2(1500,630),"normal_input_px":32,"old180px_and_north_door_repeated":false,"three_doors_or_rooms_repeated":false,"native_queries":native_queries,"captures":pictures})
	return true
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+SPACING_WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_docks_spacing_ordinary_20261018q/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=_spacing_precheck()
	if complete:
		driver=INPUT.new();driver.configure(self)
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		complete=await _spacing_run()
	if driver!=null: driver.release();driver=null
	if is_instance_valid(current_scene):
		var own: Node=current_scene;var weak: WeakRef=weakref(own);current_scene=null;own.queue_free();field=null;scene=null;own=null
		await process_frame;await process_frame
		if not check(weak.get_ref()==null,"Own spacing Field actually tree-exited"): complete=false
	independent=null;active_mask=null;contexts.clear();actual_record.clear()
	finish(folder,began,complete,"ORDINARY_NO_FLAG_DOCKS_RESTORED_GROUND_32PX_NOT_NORTH_DOOR_OR_ROOM_RETEST")


