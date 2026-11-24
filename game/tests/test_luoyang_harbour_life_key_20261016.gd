extends "res://tests/test_luoyang_assembled_scenes_key_retry4_20261016b.gd"
## Utility inheritance only: never calls the old _run/_precheck/_exercise.
## Two public near-NPC setups, fixed120s/60s, no new room or quest chain.
const H = preload("res://scripts/city/luoyang_harbour_life_runtime_20261016.gd")
const CROWD = preload("res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd")
const KEY_PINS = {
	"res://tests/test_luoyang_assembled_scenes_key_retry4_20261016b.gd":"91f27cf8b07d1b65d459c75661052d87895c715a6ca6f24377342ea1d6d5af35",
	"res://scripts/city/luoyang_harbour_life_runtime_20261016.gd":"fefc623b1fa5d4b4bcd78b9c3f79d0ca3c2d6aa7d0dad85e5d7359a001e17a8c",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"cc0d50787a79007f943e771e8d777abbb50918e3f5943eb5749adb9ae69144e4",
	"res://scripts/field/field_walkable_controller.gd":"3b7824e99ea4cd423adf62324a134aa88aadaea39dac70b6692acfc9fb3ff0e8",
	"res://scripts/autoload/scene_router.gd":"1877df7c4544275e66241552cee63e00f69d84a4c38bf5166976a4e401b2c1e1",
	"res://scripts/autoload/loading_manager.gd":"d3dff3a613707774e38c1888cd8d9eae3611f6f35be1e7c96a7b4234e7578c17",
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://tests/helpers/v15_field_raw_oracle.gd":"dc36f4144496477508f9ad8b346f846043db109415760ab87205fa814aad26fb"
}
const BIND_PIN = "4a2e9a4985c0548672f00e8fee46c33588da5f27d0c803a345d32a2f86704bca"
var cases: Array[Dictionary] = [
	{"id":"ch4_s0_luoyang_gate","size":Vector2(3072,2048),"setup_foot":Vector2(1740,1632),"npc":"luoyang_gate_sergeant","stand":Vector2(1740,1600),"portal_id":"return_world","portal_foot":Vector2(1536,1860),"route":[Vector2(1740,1600),Vector2(1536,1600),Vector2(1536,1860)]},
	{"id":"ch4_s2_canal_docks","size":Vector2(3072,2048),"setup_foot":Vector2(1740,1402),"npc":"canal_work_chief","stand":Vector2(1740,1370),"portal_id":"canal_world_ferry","portal_foot":Vector2(2140,1840),"route":[Vector2(1740,1370),Vector2(1200,1370),Vector2(1200,1840),Vector2(2140,1840)]}
]
var crowd_refs: Array[WeakRef] = []
var frame_images: Dictionary = {}
var binding: Dictionary = {}

func _precheck() -> bool:
	if not _check(H.enabled() and not H.FORMAL_ENABLED and H.FLAG in OS.get_cmdline_user_args(),"Exact candidate flag, not formal credit"): return false
	for path: String in KEY_PINS:
		if not _track(path,KEY_PINS[path]): return false
	if not _track(H.BIND_PATH,BIND_PIN): return false
	binding=JSON.parse_string(FileAccess.get_file_as_string(H.BIND_PATH))
	if not _check(binding.source_sha256.size()==58 and binding.cities==H.CITIES,"Frozen58 child leaves and two exact publications"): return false
	for path: String in binding.source_sha256:
		if not _track(path,binding.source_sha256[path]): return false
	if not _track(binding.cpu_result,binding.cpu_result_sha256): return false
	var cpu: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(binding.cpu_result))
	if not _check(cpu.passed and cpu.not_runtime and cpu.not_formal and cpu.rows.size()==2,"Actual93032 CPU scope only, not a runtime substitute"): return false
	for id: String in binding.cities:
		var item: Dictionary=binding.cities[id]
		if not _track(item.manifest_path,item.manifest_sha256) or not _track(item.parent_canonical_path,item.parent_canonical_sha256): return false
		var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(item.manifest_path))
		manifest_records[id]=manifest.record
		candidate_manifest_paths[id]=item
	return _track(get_script().resource_path)

func _bind_geometry() -> bool:
	if oracle!=null: oracle.call("release")
	oracle=RAW.new(); floors.clear(); exact_solids.clear()
	current_size=field.get("_world_size")
	var id:=String(scene.scene_id)
	if not _check(H.bound(scene) and C.harbour_bound(scene) and current_size==Vector2(3072,2048) and C._records.has(id),"Actual harbour Scene and already-prepared current record"): return false
	var record: Dictionary=C._records[id].duplicate(true)
	var receipt: String=record.get("harbour_runtime_binding_sha","")
	var preserved: bool=record.get("harbour_parent_task_semantics_preserved",false)
	record.erase("harbour_runtime_binding_sha"); record.erase("harbour_parent_task_semantics_preserved")
	if not _check(receipt==BIND_PIN and preserved and C._equal_value(_writer_domain_record(record),manifest_records[id]),"Whole native record in exact publisher wire domain, only two declared receipts removed"): return false
	var item: Dictionary=candidate_manifest_paths[id]
	if not _check(scene.get_meta("city_harbour_life_published_scene_path","")==item.scene_path and scene.map_layout.walkable_mask_path==item.walk_path and record.objects.size()==28 and scene.npcs.size()==(1 if id==cases[0].id else 4),"Exact new28 props with original NPC definitions/portals, not renamed counts"): return false
	var clone: Resource=scene.map_layout.duplicate(true)
	clone.set("design_size",Vector2i(current_size))
	var declarations: Array[Dictionary]=[]
	for object: Dictionary in record.objects:
		var shapes: Array[PackedVector2Array]=[]
		var size:=Vector2(object.collision_size_px[0],object.collision_size_px[1])
		if size.x>0:
			var center:=Vector2(object.physical_center_px[0],object.physical_center_px[1]); var rect:=Rect2(center-size*.5,size)
			shapes.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
		for raw: Array in object.solid_polygons_px:
			var polygon:=PackedVector2Array()
			for pair: Array in raw: polygon.append(Vector2(pair[0],pair[1]))
			shapes.append(polygon)
		if not shapes.is_empty(): declarations.append({"id":object.id,"solid_polygons_px":shapes})
	clone.set("visual_objects",declarations)
	if not _check(bool(oracle.call("configure",clone,"round_world_pixel",0.0)),"Independent actual new mask and source polygons",oracle.get("errors")): return false
	for poly: PackedVector2Array in oracle.get("regions"):
		var projected:=PackedVector2Array()
		for point: Vector2 in poly: projected.append(point*current_size)
		floors.append(projected)
	for solid: Dictionary in oracle.get("solids"):
		if solid.kind=="exact_world_polygon": exact_solids.append(solid.polygon)
		else:
			var rect: Rect2=solid.rect
			exact_solids.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
	var player:=field.get("_player") as CharacterBody2D
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	var state: Dictionary=C.transition_validation_state()
	# Live transition token is normally cleared after install. Its strict ready
	# receipt, not the now-idle transition state, retains the final source proof.
	var proof: Dictionary=C.resident_receipt(scene)
	rows.append({"kind":"ACTUAL_HARBOUR_BIND","id":id,"state":state,"ready_sources_finalized":proof.get("sources_finalized",false),"ready_source_count":proof.get("sources",{}).size(),"task":field.call("get_city_task_projection_state"),"record_binding":receipt})
	return _check(scene.actor_positions_are_feet and shape.position==Vector2.ZERO and (shape.shape as RectangleShape2D).size==Vector2(34,24) and proof.get("sources_finalized",false) and not proof.get("sources",{}).is_empty() and _clear(player.position),"Production source-finalized ready receipt and independent spawn87517/Physics/native34x24")

func _npc_ground(npc: Node2D) -> bool:
	var point:=npc.position
	if not bool(oracle.call("clear",point)): return false
	var body:=PackedVector2Array([point+Vector2(-17,-15),point+Vector2(17,-15),point+Vector2(17,15),point+Vector2(-17,15)])
	for poly: PackedVector2Array in exact_solids:
		if not Geometry2D.intersect_polygons(body,poly).is_empty(): return false
	for y: int in range(roundi(point.y)-15,roundi(point.y)+16):
		for x: int in range(roundi(point.x)-17,roundi(point.x)+18):
			if not bool((oracle.call("pixel_evidence",Vector2(x,y)) as Dictionary).get("clear",false)): return false
	var physical:=npc.get("_body_collider") as StaticBody2D
	var shape:=physical.get_child(0) as CollisionShape2D
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape; query.transform=shape.global_transform
	query.collision_mask=1; query.exclude=[physical.get_rid()]; query.collide_with_areas=false
	return physical.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _npc_frame(npc: Node2D,detail: bool) -> Dictionary:
	var sprite:=npc.get("sprite") as Sprite2D
	var row: Dictionary={"id":npc.get("npc_id"),"engine_frame":Engine.get_process_frames(),"position":npc.position,"frame":sprite.frame,"hframes":sprite.hframes,"texture":sprite.texture.resource_path,"flip_h":sprite.flip_h}
	if not detail: return row
	var texture: Texture2D=sprite.texture
	var key:=texture.get_instance_id()
	if not frame_images.has(key): frame_images[key]=texture.get_image()
	var image: Image=frame_images[key]
	if image!=null and image.is_compressed():
		if not _check(image.decompress()==OK,"Lossless actual NPC image decompression before alpha frame bounds"): return {}
	var size:=Vector2i(texture.get_size())
	if not _check(image!=null and image.get_size()==size and not sprite.region_enabled,"Actual NPC texture-local frame image"): return {}
	var cell:=Vector2i(size.x/sprite.hframes,size.y/sprite.vframes)
	var region:=Rect2i(sprite.frame_coords*cell,cell)
	var frame_image:=image.get_region(region); var bounds:=frame_image.get_used_rect()
	var last:=bounds.end.y-1; var last_x: int=-1
	if last>=0:
		for x: int in range(bounds.position.x,bounds.end.x):
			if frame_image.get_pixel(x,last).a>0: last_x=x; break
	if not _check(last_x>=0,"Actual visible NPC alpha foot exists"): return {}
	var rect:=sprite.get_rect()
	var local:=rect.position+Vector2((last_x+.5)/cell.x*rect.size.x,(last+.5)/cell.y*rect.size.y)
	var world:=field.get("world_container") as Node2D
	var alpha:=world.to_local(sprite.to_global(local))
	var physical:=npc.get("_body_collider") as StaticBody2D
	var shape:=physical.get_child(0) as CollisionShape2D
	var collider:=world.to_local(shape.global_position)
	var depth:=world.to_local(Vector2(npc.global_position.x,float(npc.call("get_depth_sort_y"))))
	row.merge({"alpha_bounds":bounds,"frame_rect":region,"alpha_foot_world":alpha,"alpha_delta_y":alpha.y-npc.position.y,"collider_world":collider,"depth_y":depth.y,"body_size":(shape.shape as RectangleShape2D).size,"body_layer":physical.collision_layer,"body_mask":physical.collision_mask,"query_uses_explicit_layer1_not_native_mask0":true})
	_check(bool(npc.get("_ground_anchored")) and collider.distance_to(npc.position)<.03 and absf(depth.y-npc.position.y)<.03 and absf(alpha.y-npc.position.y)<=12.0 and (shape.shape as RectangleShape2D).size==Vector2(22.4,28.8),"Same-frame true NPC feet/body/depth and original <=12 visible-foot bound",row)
	return row

func _crowd_observation() -> bool:
	var expected: Array=CROWD.project(scene.scene_id)
	var nodes: Dictionary={}; var moving: Array[Node2D]=[]
	for npc: Node2D in field.get("_npc_nodes"):
		if String(npc.get("npc_id")).begins_with("harbour_life_"): nodes[String(npc.get("npc_id"))]=npc; crowd_refs.append(weakref(npc))
	var live: Dictionary=field.call("get_harbour_life_state")
	if not _check(nodes.size()==10 and live.npcs.size()==10 and live.receipt.binding_sha256==BIND_PIN,"Ten actual new actors with source-bound receipt"): return false
	for data: Dictionary in expected:
		if not _check(nodes.has(data.npc_id),"Unique authored ambient identity "+String(data.npc_id)): return false
		var npc: Node2D=nodes[data.npc_id]
		var area:=npc.get("interact_area") as Area2D
		if not _check(npc.get("movement_mode")==data.movement_mode and npc.get("sprite_path")==data.sprite_path and npc.get("walk_sprite_path")==data.walk_sprite_path and not area.monitoring and not area.input_pickable and String(npc.get("dialog_id")).is_empty() and String(npc.get("interaction_action")).is_empty(),"Original NPC motion/art API and no false ambient interaction "+String(data.npc_id)): return false
		if data.movement_mode=="patrol": moving.append(npc)
	if not _check(moving.size()==6,"Six actual native patrol actors; not six renamed definitions"): return false
	var seen: Dictionary={}; var starts: Dictionary={}; var maximum_motion: Dictionary={}
	for npc: Node2D in moving: seen[npc.get("npc_id")]={}; starts[npc.get("npc_id")]=npc.position; maximum_motion[npc.get("npc_id")]=0.0
	var original:=field.get("_world_camera") as Camera2D
	var position_before:=original.position; var zoom_before:=original.zoom
	var player:=field.get("_player") as CharacterBody2D; var foot_before:=player.position
	var camera:=Camera2D.new(); camera.position=Vector2(1536,1024); camera.zoom=Vector2(.5,.5)
	(field.get("world_container") as Node2D).add_child(camera); camera.make_current()
	await process_frame
	for index: int in [0,2]:
		if not _check(_npc_ground(moving[index]),"Two representative actual nativePhysics plus87517/continuous34x30, start"): return false
	var until:=mini(deadline,Time.get_ticks_msec()+4000)
	while Time.get_ticks_msec()<until:
		await RenderingServer.frame_post_draw
		if not _operable(): return false
		for index: int in range(moving.size()):
			var npc: Node2D=moving[index]; var sprite:=npc.get("sprite") as Sprite2D
			maximum_motion[npc.get("npc_id")]=maxf(float(maximum_motion[npc.get("npc_id")]),npc.position.distance_to(starts[npc.get("npc_id")]))
			var frames: Dictionary=seen[npc.get("npc_id")]
			if not frames.has(sprite.frame):
				frames[sprite.frame]=true
				rows.append(_npc_frame(npc,index in [0,2]))
	for index: int in range(moving.size()):
		var npc: Node2D=moving[index]; var sprite:=npc.get("sprite") as Sprite2D
		var frames: Dictionary=seen[npc.get("npc_id")]
		if not _check(frames.size()==8 and sprite.hframes==8 and sprite.texture==npc.get("_walk_texture") and float(maximum_motion[npc.get("npc_id")])>4,"Four-second shared window: all six natural8 walk frames and actual displacement",{"id":npc.get("npc_id"),"start":starts[npc.get("npc_id")],"end":npc.position,"maximum_actual_displacement":maximum_motion[npc.get("npc_id")],"frames":frames}): return false
	for index: int in [0,2]:
		if not _check(_npc_ground(moving[index]),"Two representative nativePhysics plus87517/continuous34x30, end"): return false
	await _capture(String(scene.scene_id)+"_whole_layout_actual_crowd")
	rows.append({"kind":"QA_WHOLE_LAYOUT_SHARED_CROWD_WINDOW","scene_id":String(scene.scene_id),"duration_ms":4000,"moving_count":moving.size(),"detailed_native_alpha_representatives":2,"not_ordinary_camera_travel":true,"dynamic_pathfinding_or_player_avoidance_credit":false})
	original.make_current(); camera.queue_free(); await process_frame
	return _check(original.is_current() and original.position==position_before and original.zoom==zoom_before and player.position==foot_before,"QA overview removed, ordinary camera and player restored exactly")

func _boats() -> bool:
	var nodes: Dictionary={}
	for node: Sprite2D in field.get("_scene_object_nodes"): nodes[String(node.name)]=node
	if String(scene.scene_id)==cases[0].id: return true
	if not _check(not nodes.has("SceneObject_moored_canal_boat"),"Old low-detail boat actually absent"): return false
	for pair: Array in [["harbour_cargo_ship","cargo_ship_v1.png"],["harbour_covered_ferry","covered_ferry_v1.png"],["harbour_main_warehouse","harbour_warehouse_v1.png"]]:
		var name:="SceneObject_"+String(pair[0])
		if not _check(nodes.has(name),"Actual new model node "+name): return false
		var node: Sprite2D=nodes[name]
		var path:="res://art/maps/luoyang_harbour_life_20261016/"+String(pair[1])
		var source:=Image.load_from_file(path); var actual:=node.texture.get_image()
		if actual!=null and actual.is_compressed(): actual.decompress()
		if source==null or actual==null: return _check(false,"Actual new texture decode "+name)
		source.convert(Image.FORMAT_RGBA8); actual.convert(Image.FORMAT_RGBA8)
		if not _check(node.texture.resource_path==path and node.is_visible_in_tree() and node.self_modulate.a>0 and source.get_size()==actual.get_size() and source.get_data()==actual.get_data(),"Actual visible new texture fullRGBA identity "+name): return false
	return true

func _original_npc_space(item: Dictionary) -> bool:
	var target: Node2D=null
	for npc: Node2D in field.get("_npc_nodes"):
		if npc.get("npc_id")==item.npc: target=npc
	if not _check(is_instance_valid(target) and target.is_visible_in_tree(),"Original task NPC remains visible "+String(item.npc)): return false
	await driver.call("key",KEY_SPACE)
	var dp: Node=root.get_node("DialogPlayer")
	if not _check(bool(dp.call("is_playing")) and field.get("_active_dialog_npc")==target,"Normal Space reaches original NPC, not ambient or cargo"): return false
	var opened: Resource=dp.get("_current_script") as Resource
	rows.append({"kind":"ORIGINAL_NPC_NORMAL_SPACE","npc":item.npc,"dialog":String(opened.get("dialog_id")),"player_foot":(field.get("_player") as Node2D).position})
	var end:=mini(deadline,Time.get_ticks_msec()+5000)
	while bool(dp.call("is_playing")) and Time.get_ticks_msec()<end:
		var layer:=dp.get("_box") as Node
		var box: Node=layer.get_node_or_null("DialogBox") if is_instance_valid(layer) else null
		var value: Variant=box.get("_choice_rects") if is_instance_valid(box) else null
		var choices: int=value.size() if value is Array else 0
		if choices>0:
			if not _check(item.npc=="canal_work_chief" and choices==2,"Original two-choice offer UI, decline only"): return false
			await driver.call("key",KEY_2)
		else: await driver.call("key",KEY_SPACE)
		await process_frame
	return _check(not bool(dp.call("is_playing")) and _operable() and not root.get_node("GameState").call("get_flag",&"canal_grudge_started") and not root.get_node("QuestManager").call("is_active",&"q_ch4_side_06_canal_grudge"),"Dialog closes without accepting task; original NPC not replaced")

func _original_portal(item: Dictionary) -> bool:
	var definition: Dictionary={}
	for data: Dictionary in scene.map_layout.portals:
		if data.id==item.portal_id: definition=data
	var found: Array[Node]=[]
	for zone: Node2D in (field.get("_portal_layer") as Node).get_children():
		if zone.position.distance_to(item.portal_foot)<.02 and zone.get("action")=="world_map": found.append(zone)
	if not _check(not definition.is_empty() and definition.get("action")=="world_map" and String(definition.get("target_scene","")).is_empty() and found.size()==1,"Original action-only world portal exact identity"): return false
	var available: bool=bool(found[0].call("can_enter"))
	rows.append({"kind":"ORIGINAL_PORTAL_AVAILABLE_NO_TRIP","id":item.portal_id,"player_foot":(field.get("_player") as Node2D).position,"can_enter":available,"action":found[0].get("action")})
	return _check(available and _clear(item.portal_foot) and not bool(found[0].get("is_locked")),"Normal input reaches original portal, can_enter without extra world transition")

func _exercise() -> bool:
	for item: Dictionary in cases:
		if not await _setup(item) or not _boats() or not await _crowd_observation(): return false
		if not await _way(PackedVector2Array([item.setup_foot,item.stand]),"Short normal input to original "+String(item.npc)) or not await _original_npc_space(item): return false
		if not await _way(PackedVector2Array(item.route),"Original exit approach, exact new mask/continuous87517/Physics before normal input") or not _original_portal(item): return false
	return true

func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+120000
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true); players_before=_players()
	output="res://build/luoyang_harbour_life_key_20261016/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	var complete:=false
	if _precheck():
		_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1,"Real GPU and natural clock")
		driver=INPUT.new(); driver.call("configure",self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4); initialized=true
		complete=await _exercise()
	if driver!=null: driver.call("release"); driver=null
	if oracle!=null: oracle.call("release"); oracle=null
	frame_images.clear()
	if initialized:
		root.get_node("SceneRouter").call("reset_for_new_game")
		if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
		field=null; scene=null
		await process_frame; await process_frame; await process_frame
		var released:=true
		for reference: WeakRef in crowd_refs:
			if reference.get_ref()!=null: released=false
		_check(released and not _busy(),"Single reset releases actual crowd actors and all owned transition jobs")
	var source_after: Dictionary={}
	for path: String in source_before: source_after[path]=_fact(path)
	var players_after:=_players()
	_check(source_before==source_after,"Exact declared source closure remains unchanged")
	_check(players_before==players_after and bridge.call("is_checkpoint_saves_suspended")==true,"Observed15 actual saves unchanged; own checkpoint suspended; never restore files",{"possible_external_user_process_writes_are_not_attributed_to_test":true})
	_check(complete and Time.get_ticks_msec()<deadline,"Fixed120s two-domain key complete, arrival ceiling60s unchanged")
	var file:=FileAccess.open(output.path_join("result.json"),FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify({"scope":"HARBOUR_GATE_DOCKS_ONLY_TWO_PUBLIC_SETUPS_NO_NEW_ROOM","complete":complete and failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"shared_ms":120000,"arrival_ms":60000,"records":rows,"captures":captures,"source_before":source_before,"source_after":source_after,"players_before":players_before,"players_after":players_after,"save_restore_performed":false,"no_world_travel_room_trip_or_quest_chain_credit":true},"\t")); file.close()
	print("HARBOUR_LIFE_KEY=",output,"/result.json")
	quit(0 if complete and failures==0 else 1)
