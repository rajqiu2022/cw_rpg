extends "res://tests/test_luoyang_city_life_cpu_key_retry2_20261016f.gd"
## Final one-district GPU. Actual independentCPU447 reused; no CPU exercise/four-city process.
const GPU_READY=true
const INPUT=preload("res://tests/helpers/v15_input_driver.gd")
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const CROWD=preload("res://scripts/city/luoyang_district_life_crowd_20261016f.gd")
const CPU_RESULT="res://build/luoyang_city_life_cpu_20261016f/111920_1662/result.json"
const CPU_SHA="493f9f9ed94d7e8c68cbe43de1ce174012caa27785c6b945726bf63b987bb7d3"
const SHARED_MS=90000
const ARRIVAL_MS=60000
const DISTRICTS={"market":"ch4_s3_luoyang_market","yamen":"ch4_s1_luoyang_yamen","docks":"ch4_s2_canal_docks","gate":"ch4_s0_luoyang_gate"}
var district: String=""
var scene_id: String=""
var field: Node
var scene: SceneScript
var driver: RefCounted
var oracle: RefCounted
var record: Dictionary={}
var projected: Dictionary={}
var frame_images: Dictionary={}
var captures: Array[Dictionary]=[]
var crowd_refs: Array[WeakRef]=[]
var folder: String
var native_queries:=0
func _district_argument() -> bool:
	var count:=0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--district="): count+=1; district=arg.trim_prefix("--district=")
	if not check(count==1 and DISTRICTS.has(district),"Exactly one district per process/deadline"): return false
	scene_id=String(DISTRICTS[district]); return true
func _operable() -> bool:
	return Time.get_ticks_msec()<deadline and is_instance_valid(field) and current_scene==field and is_instance_valid(field.get("_player")) and bool(field.get("_player").get("can_move"))
func _clear(foot: Vector2) -> bool:
	if not _operable() or not oracle.clear(foot): return false
	var player:=field.get("_player") as CharacterBody2D
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	var world:=field.get("world_container") as Node2D
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape; query.transform=shape.global_transform
	query.transform.origin+=world.to_global(foot)-player.global_position
	query.exclude=[player.get_rid()]; query.collision_mask=1; query.collide_with_areas=false
	native_queries+=1
	return player.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
func _segment(from: Vector2,to: Vector2) -> Dictionary:
	return oracle.path([from,to],false,deadline)
func _walk(points: PackedVector2Array) -> bool:
	var result: Dictionary=await driver.follow(field,points,_clear,_segment)
	records.append({"kind":"NORMAL_INPUT","result":result})
	return check(result.ok,"Actual INPUT fullcombined87517/continuous34x24/4px and nativePhysics",result)
func _wait() -> bool:
	var until:=mini(deadline,Time.get_ticks_msec()+ARRIVAL_MS)
	while Time.get_ticks_msec()<until:
		await process_frame
		var public: Dictionary=root.get_node("SceneRouter").call("get_public_city_preparation_state")
		if public.get("scene_id")==scene_id and public.get("phase")=="FAILED": return check(false,"Matching public request failed immediately",public)
		if not is_instance_valid(current_scene) or not current_scene.has_method("get_district_life_state"): continue
		var live: Dictionary=current_scene.call("get_district_life_state")
		if not String(live.get("error","")).is_empty(): return check(false,"District lease error",live)
		var candidate:=current_scene.get("_current_scene") as SceneScript
		var player:=current_scene.get("_player") as CharacterBody2D
		if candidate==null or candidate.scene_id!=StringName(scene_id) or player==null or not player.is_inside_tree() or not bool(player.get("can_move")) or not live.get("finalized",false): continue
		var loading: Node=root.get_node("LoadingManager").get("_screen")
		var panel: Control=loading.get("root") as Control if is_instance_valid(loading) else null
		if panel!=null and panel.is_visible_in_tree(): continue
		field=current_scene; scene=candidate
		var proof: Dictionary=C.resident_receipt(scene)
		if not check(live.get("active") and live.get("matched") and live.scene_instance==scene.get_instance_id() and live.scene_id==scene_id and live.binding_sha256==FINAL_BIND_SHA and live.author_sha256==package.author_sha256 and live.source_first_in_city_receipt and proof.get("sources_finalized",false) and not proof.get("sources",{}).is_empty(),"Actual per-district finalized owner/source proof, never harbour proxy",live): return false
		for path: String in source_before:
			if proof.sources.has(path) and not check(proof.sources[path]==source_before[path].sha256,"Prepared source first/final SHA "+path): return false
		records.append({"kind":"ACTUAL_READY","district_state":live,"source_count":proof.sources.size(),"complete_actual_source_proof":proof.sources})
		return true
	return check(false,"Fixed60s arrival including finalSHA/Loadinghidden/can_move")
func _bind_actual() -> bool:
	var spec: Dictionary=author.districts[scene_id]
	var parent: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.parent_manifest.path))
	record=C._records.get(scene_id,{}).duplicate(true) # Read existing prepared record only. Never getter/prepare.
	if not check(not record.is_empty() and R._parent_bound(scene) and scene.map_layout.walkable_mask_path==parent.walk_path and Vector2(field.get("_world_size"))==Vector2(3072,2048),"Actual parent native source/record/NAV identity retained"): return false
	var original:=record.duplicate(true)
	var receipts: Dictionary={}
	if district=="market": receipts={"assembled_runtime_binding_sha":load("res://scripts/city/luoyang_city_assembled_runtime_20261016b.gd").BIND_SHA,"assembled_parent_task_semantics_preserved":true}
	elif district=="yamen": receipts={"annex_runtime_binding_sha":load("res://scripts/city/luoyang_yamen_annex_runtime_20261016.gd").BIND_SHA,"annex_parent_semantics_unchanged":true}
	else: receipts={"harbour_runtime_binding_sha":load("res://scripts/city/luoyang_harbour_life_runtime_20261016.gd").BIND_SHA,"harbour_parent_task_semantics_preserved":true}
	for key: String in receipts:
		if not check(original.get(key)==receipts[key],"Exact preexisting runtime receipt "+key): return false
		original.erase(key)
	if not check(C._equal_value(JSON.parse_string(JSON.stringify(original,"\t",true,true)),parent.record),"Full immutable parent record writer+parse domain; no field omission"): return false
	oracle=RAW.new()
	var delta: Dictionary=oracle.compile_delta(author,spec)
	if not check(oracle.configure_record(parent.record,Image.load_from_file(parent.walk_path),delta),"Independent actual combined geometry, no C/G clearance oracle"): return false
	projected=G.project(author,StringName(scene_id))
	var player:=field.get("_player") as CharacterBody2D
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	if not check(scene.actor_positions_are_feet and (shape.shape as RectangleShape2D).size==Vector2(34,24) and shape.position==Vector2.ZERO and _clear(player.position),"Ordinary native34x24/zerooffset/actualspawn87517Physics"): return false
	var live: Dictionary=field.call("get_district_life_state")
	if not check(live.physical_delta_count==G.delta_solids(projected).size() and live.new_object_ids.size()==projected.additions.size() and live.replacement_ids.size()==projected.replacements.size(),"Actual delta identities/counts bound, not renamed original objects"): return false
	for entry: Dictionary in projected.additions+projected.replacements:
		var sprite:=_prop(String(entry.id))
		if not check(sprite!=null and sprite.texture.resource_path==entry.texture and sprite.scale==(entry.render_size_px as Vector2)/Vector2(sprite.texture.get_size()) and sprite.position==(entry.pos as Vector2)*Vector2(3072,2048),"Actual authored visual source/native position and same-operation scale "+String(entry.id)): return false
	return true
func _prop(id: String) -> Sprite2D:
	for node: Node in field.get("_scene_object_nodes"):
		if String(node.name)=="SceneObject_"+id: return node as Sprite2D
	return null
func _npc_ground(npc: Node2D) -> bool:
	if not oracle.npc_clear(npc.position): return false
	var physical:=npc.get("_body_collider") as StaticBody2D
	var shape:=physical.get_child(0) as CollisionShape2D
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=shape.shape; query.transform=shape.global_transform; query.collision_mask=1
	query.exclude=[physical.get_rid()]; query.collide_with_areas=false
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
		if not check(image.decompress()==OK,"Lossless actual NPC image decompression before alpha frame bounds"): return {}
	var size:=Vector2i(texture.get_size())
	if not check(image!=null and image.get_size()==size and not sprite.region_enabled,"Actual NPC texture-local frame image"): return {}
	var cell:=Vector2i(size.x/sprite.hframes,size.y/sprite.vframes)
	var region:=Rect2i(sprite.frame_coords*cell,cell)
	var frame_image:=image.get_region(region); var bounds:=frame_image.get_used_rect()
	var last:=bounds.end.y-1; var last_x: int=-1
	if last>=0:
		for x: int in range(bounds.position.x,bounds.end.x):
			if frame_image.get_pixel(x,last).a>0: last_x=x; break
	if not check(last_x>=0,"Actual visible NPC alpha foot exists"): return {}
	var rect:=sprite.get_rect()
	var local:=rect.position+Vector2((last_x+.5)/cell.x*rect.size.x,(last+.5)/cell.y*rect.size.y)
	var world:=field.get("world_container") as Node2D
	var alpha:=world.to_local(sprite.to_global(local))
	var physical:=npc.get("_body_collider") as StaticBody2D
	var shape:=physical.get_child(0) as CollisionShape2D
	var collider:=world.to_local(shape.global_position)
	var depth:=world.to_local(Vector2(npc.global_position.x,float(npc.call("get_depth_sort_y"))))
	row.merge({"alpha_bounds":bounds,"frame_rect":region,"alpha_foot_world":alpha,"alpha_delta_y":alpha.y-npc.position.y,"collider_world":collider,"depth_y":depth.y,"body_size":(shape.shape as RectangleShape2D).size,"body_layer":physical.collision_layer,"body_mask":physical.collision_mask,"query_uses_explicit_layer1_not_native_mask0":true})
	check(bool(npc.get("_ground_anchored")) and collider.distance_to(npc.position)<.03 and absf(depth.y-npc.position.y)<.03 and absf(alpha.y-npc.position.y)<=12.0 and (shape.shape as RectangleShape2D).size==Vector2(22.4,28.8),"Same-frame true NPC feet/body/depth and original <=12 visible-foot bound",row)
	return row

func _crowd() -> bool:
	var expected: Array=CROWD.project(author.districts[scene_id].crowd)
	var live: Dictionary=field.call("get_district_life_state")
	var nodes: Dictionary={}; var movers: Array[Node2D]=[]
	for npc: Node2D in field.get("_npc_nodes"):
		if String(npc.get("npc_id")).begins_with("district_life_"): nodes[String(npc.get("npc_id"))]=npc; crowd_refs.append(weakref(npc))
	if not check(nodes.size()==expected.size() and live.npcs.size()==expected.size() and live.new_npc_ids.size()==expected.size(),"Own district new identities; Market10/Yamen6/GateDocks0"): return false
	for data: Dictionary in expected:
		if not check(nodes.has(data.npc_id),"Exact authored new actor "+String(data.npc_id)): return false
		var npc: Node2D=nodes[data.npc_id]
		var area:=npc.get("interact_area") as Area2D
		if not check(npc.get("movement_mode")==data.movement_mode and npc.get("sprite_path")==data.sprite_path and npc.get("walk_sprite_path")==data.walk_sprite_path and not area.monitoring and not area.input_pickable and String(npc.get("dialog_id")).is_empty() and String(npc.get("interaction_action")).is_empty(),"Native NPC motion/art preserved, no false ambient dialogue"): return false
		if data.movement_mode=="patrol": movers.append(npc)
		if data.sprite_path==CROWD.VENDOR:
			var static_frame:=_npc_frame(npc,true); records.append(static_frame)
			if not check(_npc_ground(npc),"New stationary woman uses actual visible feet/nativebody, not scale-only equality"): return false
	var wanted:=4 if district=="market" else (2 if district=="yamen" else 0)
	if not check(movers.size()==wanted,"Exact new moving counts4/2/0/0"): return false
	if wanted==0:
		var preserved: Dictionary=field.call("get_harbour_life_state")
		return check(preserved.npcs.size()==10 and preserved.receipt.moving==6,"Original ten harbour actors preserved; prior actual96frame evidence reused")
	var seen: Dictionary={}; var starts: Dictionary={}; var displacement: Dictionary={}
	for npc: Node2D in movers:
		var id: String=npc.get("npc_id"); seen[id]={}; starts[id]=npc.position; displacement[id]=0.0
	var until:=mini(deadline,Time.get_ticks_msec()+4000)
	for index: int in [0,1]:
		if not check(_npc_ground(movers[index]),"Two new representatives start actualPhysics/34x30/87517"): return false
	while Time.get_ticks_msec()<until:
		await RenderingServer.frame_post_draw
		if not _operable(): return false
		for index: int in movers.size():
			var npc: Node2D=movers[index]; var sprite:=npc.get("sprite") as Sprite2D; var id: String=npc.get("npc_id")
			displacement[id]=maxf(float(displacement[id]),npc.position.distance_to(starts[id]))
			if not seen[id].has(sprite.frame):
				seen[id][sprite.frame]=true; records.append(_npc_frame(npc,index<2))
	for npc: Node2D in movers:
		var id: String=npc.get("npc_id"); var sprite:=npc.get("sprite") as Sprite2D
		if not check(seen[id].size()==8 and sprite.hframes==8 and sprite.texture==npc.get("_walk_texture") and float(displacement[id])>4,"One4s common window: actual natural8walk + displacement",{"id":id,"frames":seen[id],"motion":displacement[id]}): return false
	for index: int in [0,1]:
		if not check(_npc_ground(movers[index]),"Two new representatives end actualPhysics/34x30/87517"): return false
	return true
func _capture(label: String) -> bool:
	await RenderingServer.frame_post_draw
	var path:=folder.path_join(label+".png")
	var image:=root.get_texture().get_image()
	if not check(image!=null and image.save_png(path)==OK,"Actual GPU "+label): return false
	captures.append({"path":path,"sha256":FileAccess.get_sha256(path),"label":label}); return true
func _overview() -> bool:
	var previous:=field.get("_world_camera") as Camera2D
	var world:=field.get("world_container") as Node2D
	var camera:=Camera2D.new(); camera.position=Vector2(1536,1024); camera.zoom=Vector2(.5,.5)
	var pos:=previous.position; var zoom:=previous.zoom
	var player:=field.get("_player") as CharacterBody2D; var foot:=player.position
	world.add_child(camera); camera.make_current(); await process_frame
	var good:=await _crowd()
	if good: good=await _capture(district+"_whole_layout")
	previous.make_current(); camera.queue_free(); await process_frame
	return check(previous.is_current() and previous.position==pos and previous.zoom==zoom and player.position==foot,"QA overview removed; ordinary camera and player exactly retained") and good
func _portal() -> bool:
	var id: String={"market":"to_ancient_temple","yamen":"to_canal_quay","docks":"canal_world_ferry","gate":"return_world"}[district]
	var expected: Dictionary={}
	for row: Dictionary in scene.map_layout.portals:
		if row.id==id: expected=row
	if not check(not expected.is_empty(),"Original native portal remains"): return false
	var exact: Vector2=(expected.pos as Vector2)*Vector2(3072,2048)
	var player:=field.get("_player") as CharacterBody2D
	if district=="yamen":
		if not await _walk(PackedVector2Array([player.position,Vector2(2790,1180),Vector2(2790,1260)])): return false
	# Native UV first, same operations as real Field. Never sourcePx round-trip.
	if not await _walk(PackedVector2Array([player.position,exact])): return false
	await driver.completed_actor_stage()
	var layer:=field.get("_portal_layer") as Node
	for zone: Node in layer.get_children():
		if zone.position!=exact: continue
		var available: bool=zone.has_method("can_enter") and bool(zone.call("can_enter")) and not zone.get("is_locked") and String(zone.get("target_scene_id"))==String(expected.get("target_scene","")) and String(zone.get("action"))==String(expected.get("action","")) and zone.get("target_spawn_pos")==expected.get("target_pos",Vector2(.5,.5)) and _clear(player.position)
		if not check(available,"Original portal available after real INPUT; no activation/travel"): return false
		return await _adjacent_air() if district=="yamen" else true
	return check(false,"Actual native portal instance missing")
func _adjacent_air() -> bool:
	var player:=field.get("_player") as CharacterBody2D
	if not await _walk(PackedVector2Array([player.position,Vector2(2790,1430)])): return false
	await driver.completed_actor_stage()
	await RenderingServer.frame_post_draw
	var actor:=player.get("sprite") as Sprite2D
	var prop:=_prop("assembled_east_service_annex")
	if not check(prop!=null,"Actual new east facade exists"): return false
	var world:=field.get("world_container") as Node2D
	var actor_rect:=actor.get_rect(); var prop_rect:=prop.get_rect()
	var actor_top:=INF; var prop_bottom:=-INF
	for point: Vector2 in [actor_rect.position,Vector2(actor_rect.end.x,actor_rect.position.y),actor_rect.end,Vector2(actor_rect.position.x,actor_rect.end.y)]: actor_top=minf(actor_top,world.to_local(actor.to_global(point)).y)
	for point: Vector2 in [prop_rect.position,Vector2(prop_rect.end.x,prop_rect.position.y),prop_rect.end,Vector2(prop_rect.position.x,prop_rect.end.y)]: prop_bottom=maxf(prop_bottom,world.to_local(prop.to_global(point)).y)
	var overlap: Dictionary=field.call("get_v14_modular_overlap_debug")
	var hits: Dictionary=overlap.get("prop_hits",{})
	records.append({"kind":"ONE_NEW_ASSET_ADJACENT_AIR","foot":player.position,"actual_actor_sprite_top":actor_top,"actual_prop_full_canvas_bottom":prop_bottom,"sprite_scale":actor.scale,"prop_scale":prop.scale,"annex_prop_hits":hits.get("assembled_east_service_annex",0),"other_prop_hits_allowed":hits,"actual_prop_alpha":prop.self_modulate.a,"original_alpha1_not_thresholded":true})
	return check(actor_top>prop_bottom and hits.get("assembled_east_service_annex",0)==0 and prop.self_modulate.a==1.0 and _clear(player.position),"Actual disjoint FULL current Sprite canvases => new annex cannot false-fade from A1 tails") and await _capture("new_annex_adjacent_air")
func _exercise() -> bool:
	var spawn: Vector2={"market":Vector2(1536,1924),"yamen":Vector2(2790,1260),"docks":Vector2(2140,1904),"gate":Vector2(1536,1924)}[district]
	var began:=Time.get_ticks_msec()
	var accepted: bool=root.get_node("SceneRouter").call("go_field_smart",StringName(scene_id),spawn/Vector2(3072,2048),"",-1,C.VERSION)
	records.append({"kind":"PUBLIC_NEAR_FOOT_SETUP_NOT_TRAVEL","scene_id":scene_id,"spawn":spawn,"accepted":accepted,"call_ms":Time.get_ticks_msec()-began})
	if not check(accepted,"One real public current-version3 setup") or not await _wait() or not _bind_actual(): return false
	return await _overview() and await _portal()
func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+SHARED_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true); players_before=saves()
	var complete:=false
	if check(GPU_READY,"Prepared GPU refuses until final API/source/result pins") and _district_argument() and precheck() and track("res://tests/test_luoyang_city_life_cpu_key_retry2_20261016f.gd","00ed4cd77ede1a470470726bcba60c2b5fe3099c11218e74d1b708ec3b9cef93") and track(CPU_RESULT,CPU_SHA) and track("res://tests/helpers/v15_input_driver.gd","a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7"):
		folder="res://build/luoyang_city_life_gpu_20261016f/"+district+"/%d_%d"%[OS.get_process_id(),began]; DirAccess.make_dir_recursive_absolute(folder)
		driver=INPUT.new(); driver.configure(self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		complete=await _exercise()
		root.get_node("SceneRouter").call("reset_for_new_game"); await process_frame; await process_frame
	if driver!=null: driver.release(); driver=null
	field=null; scene=null; oracle=null; frame_images.clear()
	for reference: WeakRef in crowd_refs: check(reference.get_ref()==null,"Actual new crowd released with Field reset")
	records.append({"kind":"SCOPE","district":district,"shared_ms":SHARED_MS,"arrival_ms":ARRIVAL_MS,"captures":captures,"native_queries":native_queries,"no_temple_room_story_or_portal_activation":true})
	if folder.is_empty(): folder="res://build/luoyang_city_life_gpu_20261016f/draft/%d_%d"%[OS.get_process_id(),began]
	finish(folder,began,complete,"ONE_DISTRICT_ONLY")
