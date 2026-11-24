extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## NOTREADY: ROOT-only one process, ten real rooms/10 PNG/59 furniture. No exterior city prepare or new-door trip.
const KEY_READY=false
const WHOLE_MS=180000
const ARRIVAL_MS=60000
const M=preload("res://scripts/city/luoyang_assembled_interiors_20261016g.gd")
const RAW=preload("res://tests/helpers/luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd")
const INPUT=preload("res://tests/helpers/v15_input_driver.gd")
const MODULE_SHA="9e8e02af2b20938ebe9b4ab7000a3fba6a2eab22abb756c15442689410da64d3"
const REGISTRY_SHA="725551952029cfabc92d5d875484a2b09e37fa64a451c3410351036cfa13d144"
const SOURCE_AUDIT="res://build/luoyang_spacing_interiors_20261017p_source01/source_audit.json"
const SOURCE_AUDIT_SHA="66791e1c29941f7f723d3a6d2aa083ad7b85a62d3eccbc4e92ddf5f3bc1841ea"
const TYPES=["small_home","general_stall","scholar_study","inn_hall","guest_room","herbal_shop","cloth_shop","pawnshop","warehouse","mansion_reception"]
const COUNTS={"small_home":5,"general_stall":5,"scholar_study":6,"inn_hall":7,"guest_room":5,"herbal_shop":6,"cloth_shop":4,"pawnshop":6,"warehouse":7,"mansion_reception":8}
var field: Node
var scene: SceneScript
var independent: RefCounted
var driver: RefCounted
var data: Dictionary={}
var folder: String
var captures: Array[Dictionary]=[]
var rooms: Array[Dictionary]=[]
var component_count:=0
var native_queries:=0
var representatives: Dictionary={}
func _v(raw: Variant) -> Vector2: return raw if raw is Vector2 else Vector2(raw[0],raw[1])
func _precheck() -> bool:
	if not check(KEY_READY,"NOTREADY until ROOT approves source/deployment and bounded representative plan"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and OS.get_cmdline_user_args().is_empty(),"Ordinary real GUI clock, no candidate/newgame flags"): return false
	var pins: Dictionary={M.SELF:MODULE_SHA,M.REGISTRY_PATH:REGISTRY_SHA,SOURCE_AUDIT:SOURCE_AUDIT_SHA,"res://scripts/field/field_walkable_controller.gd":"638cd8f0a37aacff56d074383d868f2d00bab3b81fcf56bf4d148fb84f556839","res://scripts/autoload/scene_router.gd":"1082a842eb283a7eba339f9589bbcb0a5803d934c79f60d9e7a7f0413069bd92","res://scripts/city/luoyang_assembled_rooms_20261016b.gd":"8facee0dadacf6cf79c4484fb814310d5b444458d6c80646083614c08041b5c8","res://scripts/city/luoyang_assembled_low_furniture_fade_20261016.gd":"cab76af6cd5baadddb1d6bbfe282934b5c5d8170e8a6803b8faaf77c1c844b54","res://tests/helpers/luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd":"0f00d4a8a7bc7f514d4b0859275c2eb6d03296dd81eaa170416694c6068b2835","res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7"}
	for path: String in pins:
		if not track(path,pins[path]): return false
	if not track("res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd","a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895") or not track("res://scripts/autoload/loading_manager.gd","5550a037e8001069713b0af317a6db2cd2ac427189f8f75d2e87e755ece210db"): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	package=M.catalogue()
	if not check(M.FORMAL_ENABLED and package.get("rooms",{}).size()==11,"Exact proposed default switch, eleven catalogue entries not eleven tested rooms"): return false
	for path: String in package.source_sha256:
		if not track(path,package.source_sha256[path]): return false
	return true
func _wait_room(id: StringName) -> bool:
	var until: int=mini(deadline,Time.get_ticks_msec()+ARRIVAL_MS)
	while Time.get_ticks_msec()<until:
		await process_frame
		if not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): continue
		var state: Dictionary=current_scene.call("get_field_loading_state")
		if state.get("failed",false): return check(false,"Actual room setup failed",state)
		var candidate:=current_scene.get("_current_scene") as SceneScript
		var player:=current_scene.get("_player") as CharacterBody2D
		if candidate==null or candidate.scene_id!=id or player==null or not player.is_inside_tree() or not bool(player.get("can_move")) or not state.get("complete",false): continue
		var screen: Node=root.get_node("LoadingManager").get("_screen")
		var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
		if panel!=null and panel.is_visible_in_tree(): continue
		field=current_scene;scene=candidate;return true
	return check(false,"Room fixed60 arrival includes native ready/Loadinghidden/canmove",String(id))
func _physics(foot: Vector2,expect_clear: bool=true) -> bool:
	var player:=field.get("_player") as CharacterBody2D
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	var world:=field.get("world_container") as Node2D
	var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape.shape;query.transform=shape.global_transform
	query.transform.origin+=world.to_global(foot)-player.global_position
	query.exclude=[player.get_rid()];query.collision_mask=1;query.collide_with_areas=false;native_queries+=1
	return player.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()==expect_clear
func _clear(foot: Vector2) -> bool:
	return Time.get_ticks_msec()<deadline and is_instance_valid(field) and current_scene==field and independent.clear(foot) and _physics(foot)
func _segment(a: Vector2,b: Vector2) -> Dictionary: return independent.segment(a,b,deadline)
func _walk(points: PackedVector2Array,label: String) -> bool:
	var result: Dictionary=await driver.follow(field,points,_clear,_segment)
	records.append({"kind":"NORMAL_ROOM_INPUT","type":data.type_id,"label":label,"result":result})
	return check(result.get("ok")==true,"Actual INPUT independent875/17/34x24/4px+Physics "+label,result)
func _prop(id: String) -> Sprite2D:
	for sprite: Sprite2D in field.get("_scene_object_nodes"):
		if String(sprite.name)=="SceneObject_"+id: return sprite
	return null
func _actor_frame(actor: Node2D,shape: CollisionShape2D,label: String) -> bool:
	var sprite:=actor.get("sprite") as Sprite2D
	var image: Image=sprite.texture.get_image()
	if image!=null and image.is_compressed(): image.decompress()
	if not check(image!=null and image.get_size()==Vector2i(sprite.texture.get_size()) and not sprite.region_enabled,"Actual texture-local actor image "+label): return false
	var cell:=Vector2i(image.get_width()/sprite.hframes,image.get_height()/sprite.vframes)
	var frame:=image.get_region(Rect2i(sprite.frame_coords*cell,cell));var bounds:=frame.get_used_rect()
	if not check(bounds.has_area(),"Actual actor alpha nonempty "+label): return false
	var x: int=-1;var y: int=bounds.end.y-1
	for candidate: int in range(bounds.position.x,bounds.end.x):
		if frame.get_pixel(candidate,y).a>0: x=candidate;break
	if not check(x>=0,"Actual lowest alpha pixel "+label): return false
	var rect:=sprite.get_rect();var world:=field.get("world_container") as Node2D
	var alpha:=world.to_local(sprite.to_global(rect.position+Vector2((x+.5)/cell.x*rect.size.x,(y+.5)/cell.y*rect.size.y)))
	var collider:=world.to_local(shape.global_position);var depth:=world.to_local(Vector2(actor.global_position.x,float(actor.call("get_depth_sort_y"))))
	var detail: Dictionary={"kind":"ACTUAL_ACTOR_FOOT","label":label,"frame":Engine.get_process_frames(),"sprite_frame":sprite.frame,"texture":sprite.texture.resource_path,"foot":actor.position,"alpha":alpha,"delta_y":alpha.y-actor.position.y,"collider":collider,"depth_y":depth.y,"body":(shape.shape as RectangleShape2D).size}
	records.append(detail)
	return check(collider.distance_to(actor.position)<.03 and absf(depth.y-actor.position.y)<.03 and absf(alpha.y-actor.position.y)<=12.0,"Same-frame real actor feet/body/depth and unchanged12px visible-foot limit "+label,detail)
func _bind(row: Dictionary) -> bool:
	data=M.author_for_id(scene.scene_id)
	var world: Vector2=field.get("_world_size");var player:=field.get("_player") as CharacterBody2D
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	if not check(M.is_room(scene) and scene.resource_path==row.scene_path and scene.map_layout.resource_path==row.layout_path and scene.background_path==data.shell.texture and scene.background_path.begins_with("res://art/modules/luoyang_assembled_interiors_20261016g/") and scene.actor_positions_are_feet and world==Vector2(1920,1280) and shape.position==Vector2.ZERO and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size==Vector2(34,24),"Actual new path/shell/components/cover and native34x24/child0 "+row.type_id): return false
	var session: Dictionary=M._scene_sessions.get(scene.get_instance_id(),{})
	if not check(session.get("setup_source_finalized")==true,"Production actual setup completed full own row source/storage final verification, not C proxy"): return false
	var solids: Array=[]
	for base: Dictionary in data.geometry.furniture_bases:
		if base.get("blocking",false): solids.append({"id":base.id,"kind":base.kind,"points_px":base.ground_polygon_px})
	independent=RAW.new()
	if not check(independent.configure(data.geometry.floor_regions_px,solids,Vector2(1536,1024),world,data.geometry.foot_forbidden_regions_px),"Independent new source floor/physical polygons/foot-only pillar zones"): return false
	if not check(player.position==_v(data.geometry.spawn_foot_px)*(world/Vector2(1536,1024)) and _clear(player.position),"Actual source-feet spawn full875/17/continuous native Physics"): return false
	var ids: Dictionary={}
	for sprite: Sprite2D in field.get("_scene_object_nodes"):
		if String(sprite.name).begins_with("SceneObject_"): ids[String(sprite.name).trim_prefix("SceneObject_")]=true
	if not check(ids.size()==COUNTS[row.type_id] and ids.size()==data.furniture.size(),"Exact independent furniture count, no old baked furniture or renamed IDs "+row.type_id): return false
	for item: Dictionary in data.furniture:
		var sprite:=_prop(item.id);var position: Vector2=(_v(item.placement_foot_px)-_v(item.source_ground_anchor_px)*float(item.render_scale))/Vector2(1536,1024)*world
		var render: Vector2=_v(item.source_size_px)*float(item.render_scale)*(world/Vector2(1536,1024))
		if not check(ids.has(item.id) and sprite!=null and sprite.texture.resource_path==item.texture and not sprite.centered and sprite.position==position and sprite.scale==render/Vector2(sprite.texture.get_size()),"Actual furniture Sprite source/position/size "+item.id): return false
	var negative: Dictionary=data.geometry.negative_points[0]
	if not check(not independent.clear(_v(negative.foot_px)*1.25) and _physics(_v(negative.foot_px)*1.25,false),"One real furniture base rejects independent full body and nativePhysics "+row.type_id): return false
	for npc: Node2D in field.get("_npc_nodes"):
		var physical:=npc.get("_body_collider") as StaticBody2D
		if not _actor_frame(npc,physical.get_child(0) as CollisionShape2D,"npc/"+String(npc.get("npc_id"))): return false
	return _actor_frame(player,shape,"spawn/"+String(row.type_id))
func _occlusion(type: String) -> bool:
	var low: bool=type=="inn_hall"
	var id: String="inn_hall_inn_counter_0" if low else "mansion_reception_folding_screen_6"
	# New, explicit representative extensions only. Final READY requires ROOT review; actual independent segments must all pass before INPUT.
	var raw: Array=[[768,840],[990,540],[990,510],[1150,530],[1160,510]] if low else [[768,840],[900,750],[930,690],[930,640],[768,640],[768,660]]
	var points:=PackedVector2Array()
	for point: Array in raw: points.append(_v(point)*1.25)
	if not await _walk(points,"one_"+("LOW" if low else "HIGH")+"_behind"): return false
	var settled: int=mini(deadline,Time.get_ticks_msec()+350)
	while Time.get_ticks_msec()<settled: await process_frame
	var until: int=mini(deadline,Time.get_ticks_msec()+3000);var seen: Dictionary={}
	while Time.get_ticks_msec()<until and seen.size()<4:
		await RenderingServer.frame_post_draw
		var player:=field.get("_player") as CharacterBody2D;var sprite:=player.get("sprite") as Sprite2D
		var key: String=str(sprite.texture.get_instance_id())+":"+str(sprite.frame)
		if seen.has(key): continue
		seen[key]=true
		var prop:=_prop(id);var fade: Dictionary=field.call("get_city_building_fade_debug");var debug: Dictionary=field.call("get_v14_modular_overlap_debug")
		var valid: bool=_clear(player.position) and sprite.self_modulate.a==1.0 and sprite.modulate.a==1.0
		if low:
			var ghost:=player.get("_overlap_ghost") as Sprite2D;var cpu:=debug.get("mask_image") as Image;var texture:=debug.get("mask_texture") as Texture2D
			var gpu: Image=texture.get_image() if texture!=null else null
			if gpu!=null and gpu.is_compressed(): gpu.decompress()
			valid=valid and prop.self_modulate.a==1.0 and id in fade.get("opaque_low_ids",[]) and ghost!=null and ghost.visible and ghost.texture==sprite.texture and ghost.frame==sprite.frame and ghost.get_groups().is_empty() and absf(ghost.modulate.a-.46)<.000001 and cpu!=null and gpu!=null and cpu.get_data()==gpu.get_data() and gpu.get_used_rect().has_area() and debug.get("active")==true and int(debug.get("prop_hits",{}).get(id,0))>0
		else:
			var found:=false
			for building: Dictionary in fade.get("buildings",[]):
				if building.id==id: found=true;valid=valid and building.hit==true and building.eligible==true and absf(float(building.factor)-.55)<.000001
			valid=valid and found
		records.append({"kind":"REPRESENTATIVE_LOW_OR_HIGH","type":type,"id":id,"frame":Engine.get_process_frames(),"actor_frame":sprite.frame,"foot":player.position,"alpha":prop.self_modulate.a,"ghost_pixels":debug.get("pixels",0),"valid":valid})
		if not check(valid,"One actual representative opaque-low ghost or high fade, natural frame"): return false
	if not check(seen.size()==4,"Four naturally advancing frames of the selected representative only"): return false
	points.reverse()
	if not await _walk(points,"representative_return_to_spawn"): return false
	if not check(_prop(id).self_modulate.a==1.0,"Representative front/spawn restores target furniture opacity"): return false
	representatives["LOW" if low else "HIGH"]=true;return true
func _room(row: Dictionary) -> bool:
	var started: int=Time.get_ticks_usec();var accepted: bool=root.get_node("SceneRouter").call("go_field_smart",StringName(row.scene_id),null,"",-1,-1)
	if not check(accepted,"Ordinary public new-room setup, not exterior travel") or not await _wait_room(StringName(row.scene_id)) or not _bind(row): return false
	if row.type_id in ["inn_hall","small_home"]:
		var foot: Vector2=field.get("_player").position
		if not await _walk(PackedVector2Array([foot,foot+Vector2(0,16),foot]),"sixteen_px_out_and_back"): return false
	if row.type_id in ["inn_hall","mansion_reception"] and not await _occlusion(row.type_id): return false
	await RenderingServer.frame_post_draw
	var path: String=folder.path_join(String(row.type_id)+".png");var image:=root.get_texture().get_image()
	if not check(image!=null and image.save_png(path)==OK,"Actual independent assembled room component screenshot"): return false
	captures.append({"type":row.type_id,"path":path,"sha256":FileAccess.get_sha256(path)})
	rooms.append({"type":row.type_id,"scene_id":row.scene_id,"actual_scene_path":scene.resource_path,"shell":scene.background_path,"furniture":data.furniture.size(),"elapsed_usec":Time.get_ticks_usec()-started,"actual_source_finalized":true})
	component_count+=data.furniture.size();return true
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_ten_rooms_actual_20261017p/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=_precheck()
	if complete:
		driver=INPUT.new();driver.configure(self)
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		for type: String in TYPES:
			var row: Dictionary={}
			for item: Dictionary in package.rooms.values():
				if item.type_id==type: row=item;break
			if row.is_empty() or not await _room(row): complete=false;break
	if driver!=null: driver.release();driver=null
	if is_instance_valid(current_scene):
		var own: Node=current_scene;var weak: WeakRef=weakref(own);current_scene=null;own.queue_free();field=null;scene=null;own=null
		await process_frame;await process_frame
		if not check(weak.get_ref()==null,"Own final Field tree actually exited, not Router reset proxy"): complete=false
	independent=null;data.clear()
	records.append({"kind":"TEN_ROOM_SCOPE","rooms":rooms,"captures":captures,"components":component_count,"native_queries":native_queries,"representatives":representatives,"whole_ms":WHOLE_MS,"arrival_ms":ARRIVAL_MS,"exterior_doors_tested":false,"old_smith_retested":false,"whole71routes_or28imports_retested":false})
	complete=check(rooms.size()==10 and captures.size()==10 and component_count==59 and representatives.size()==2,"Ten distinct actual rooms/ten pictures/59 real furniture/two representative policies") and complete
	finish(folder,began,complete,"TEN_NEW_ASSEMBLED_ROOM_ACTUAL_FIELD_NOT_EXTERIOR_DOOR_TRIPS")
