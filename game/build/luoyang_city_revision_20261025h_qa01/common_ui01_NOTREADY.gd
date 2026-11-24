extends "res://build/luoyang_city_revision_20261024c_qa01/finite_Field_NOTREADY/common.gd"
## No private NPC event, direct go_shop, DP.play/choose or Player position write.
var service25h: RefCounted
var room_refs25h: Array=[]
var old_service25h: RefCounted
var dialog_id25h: String=""
var return_uv25h: Vector2
func _room_session25h() -> Dictionary:
	return G._sessions.get(scene.get_instance_id(),{})
func _room_picture25h(name: String) -> bool:
	var camera: Camera2D=field.get("_world_camera") as Camera2D
	if not check(pictures<int(fixture.max_pictures) and Time.get_ticks_msec()<deadline and current_scene==field and camera!=null and camera==root.get_camera_2d() and camera.enabled and scene.camera_zoom==1.0 and camera.zoom==Vector2.ONE and root.get_visible_rect().size==Vector2(1920,1080),"One bounded original room camera1 image, no camera change"): return false
	await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image()
	if not check(image!=null and image.get_size()==Vector2i(1920,1080),"Original room viewport, no edited composite"): return false
	DirAccess.make_dir_recursive_absolute(output);var path: String=output.path_join(name+".png")
	if not check(not FileAccess.file_exists(path) and image.save_png(path)==OK,"NEW representative image only"): return false
	pictures+=1;records.append({"kind":"25H_ORIGINAL_ROOM_PNG_LOCAL_ONLY","path":path,"sha256":FileAccess.get_sha256(path),"camera":_id(camera),"number":pictures})
	return true
func _room25h(row: Dictionary) -> bool:
	var router: Node=root.get_node("SceneRouter")
	if not check(router.call("go_field_smart",StringName(row.room_id),_v(row.approach_uv)),"Explicit source-bound room QA setup, not external city travel") or not await _arrive(StringName(row.room_id),20000,"25H_EXPLICIT_ROOM_SOURCE_APPROACH_NOT_DEFAULT_OR_TRAVEL"): return false
	var state: Dictionary=G._sessions.get(scene.get_instance_id(),{})
	service25h=field.get("_indoor_services") as RefCounted
	if not check(state.get("finalized")==true and state.get("scene") is WeakRef and state.scene.get_ref()==scene and state.layout.get_ref()==scene.map_layout and scene.resource_path==row.scene_path and scene.map_layout.resource_path==row.layout_path and scene.npcs.size()==row.original_npc_count and field.get("_world_size")==_v(row.world_size_px),"Natural source-bound room identity; original serialized NPC/storage not rewritten"): return false
	if not check(service25h!=null and service25h.get_script().resource_path==fixture.runtime_path and _player().position==_v(row.approach_position_px) and _clear(_player().position),"Exact attached helper and safe source-f32 approach pose, no private position write"): return false
	var actors: Array=[]
	for actor: NPCNode in field.get("_npc_nodes"):
		if actor.npc_id==row.npc_id: actors.append(actor)
	if not check(actors.size()==1,"Exactly one native service actor, existing smith reused "+row.npc_id): return false
	var npc: NPCNode=actors[0];var body: StaticBody2D=npc.get("_body_collider") as StaticBody2D
	var shape: CollisionShape2D=body.get_child(0) as CollisionShape2D if body!=null and body.get_child_count()==1 else null
	if not check(npc.is_visible_in_tree() and npc.sprite!=null and npc.sprite.is_visible_in_tree() and npc.sprite.texture!=null and npc.sprite_path==row.sprite_path and npc.portrait_path==row.portrait_path and npc.interaction_action=="indoor_service25h" and npc.movement_mode=="idle" and npc.position==_v(row.npc_position_px),"Actual keeper Sprite/source pose/portrait/action, no rename-only or invented actor"): return false
	if not check(body!=null and body.collision_layer==1 and shape!=null and not shape.disabled and shape.shape is RectangleShape2D and shape.shape.size==_v(row.npc_body_size_px) and shape.position==_v(row.npc_body_shape_offset_px) and body.position==_v(row.npc_body_position_px),"Only source-derived service NPC physical body, no old furniture/whole-room raster replay"): return false
	room_refs25h=[weakref(field),weakref(_player()),weakref(scene),weakref(scene.map_layout)]
	records.append({"kind":"25H_EXPLICIT_QA_ROOM_SETUP_AND_SERVICE_ACTOR","room":row.room_id,"npc":row.npc_id,"foot":_player().position,"npc_position":npc.position,"body_size":shape.shape.size,"source_npcs_unchanged":scene.npcs.size(),"Field":_id(field),"Scene":_id(scene),"continuous_city_travel_or_default_performance_credit":false})
	await driver.completed_actor_stage()
	return true
func _same_room_owner25h() -> bool:
	return is_instance_valid(field) and current_scene==field and field==room_refs25h[0].get_ref() and _player()==room_refs25h[1].get_ref() and scene==room_refs25h[2].get_ref() and scene.map_layout==room_refs25h[3].get_ref()
func _dialog25h(id: String,choices: bool,portrait: String) -> bool:
	await process_frame
	var box: Control=_dialog_box();var node: DialogNode=_node()
	var image: TextureRect=box.get("portrait") as TextureRect if box!=null else null
	var choice_box: Control=box.get("choices_container") as Control if box!=null else null
	var texture: Texture2D=image.texture if image!=null else null
	var rects: Variant=box.get("_choice_rects") if box!=null else null
	return check(_same_room_owner25h() and _dp().call("is_playing")==true and node!=null and String(node.node_id)==id and _script()!=null and String(_script().dialog_id)==dialog_id25h and box!=null and box.is_visible_in_tree() and choice_box!=null and choice_box.is_visible_in_tree()==choices and (not choices or (rects is Array and rects.size()==node.choices.size() and not rects.is_empty())) and image!=null and image.is_visible_in_tree() and texture!=null and texture.resource_path==portrait,"Real local DialogBox node/choice rectangles/speaker portrait "+id)
func _open_menu25h(row: Dictionary) -> bool:
	var npc: NPCNode=_npc(row.npc_id)
	if not check(_same_room_owner25h() and npc!=null and npc.global_position.distance_to(_player().global_position)<=118.0 and not _dp().call("is_playing"),"Actual source keeper in118 range before real Space"): return false
	if not await _key(KEY_SPACE): return false
	var actual: Dictionary=service25h.call("debug_state")
	dialog_id25h=String(actual.get("dialog_id",""))
	if not check(actual.get("active")==true and actual.get("npc_id")==row.npc_id and not dialog_id25h.is_empty() and field.get("_active_dialog_npc")==npc,"Native Space opened exact source service actor, not direct helper open"): return false
	if not await _dialog25h("hero",false,"res://art/characters/protagonist_portrait.png"): return false
	if not await _key(KEY_SPACE) or not await _dialog25h("menu",true,row.portrait_path): return false
	return_uv25h=root.get_node("SceneRouter").get("_current_field_spawn")
	records.append({"kind":"25H_NATIVE_KEEPER_HERO_THEN_MENU","room":row.room_id,"npc":row.npc_id,"dialog_id":dialog_id25h,"actual_return_uv_before_departure":return_uv25h,"private_NPC_signal_or_DP_play":false})
	return true
func _choice25h(index: int,target: String,row: Dictionary) -> bool:
	var node: DialogNode=_node()
	if not check(node!=null and index>=0 and index<node.choices.size() and node.choices[index].get("next")==target,"Exact source local choice index and destination, before real number key"): return false
	await driver.key(KEY_1+index)
	return await _dialog25h(target,target.ends_with("_confirm"),row.portrait_path)
func _finish_node25h() -> bool:
	if not check(_node()!=null and not _node().has_choices(),"Actual terminal local text before real final Space"): return false
	if not await _key(KEY_SPACE): return false
	await process_frame
	return check(not _dp().call("is_playing"),"Original DialogPlayer ended through real INPUT, not direct finish")
