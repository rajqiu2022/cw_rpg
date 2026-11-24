extends "res://tests/test_luoyang_docks_office_roles_cpu_key_retry1_20261016h.gd"
## One local preview, original world coordinates/depth. NOT Field/Docks birth.
const CPU_BASE="res://tests/test_luoyang_docks_office_roles_cpu_key_retry1_20261016h.gd"
const CPU_BASE_SHA="35a3b1c7e62305091e64adde1a41db9883fa5659bac374563872e4c7b2c494bd"
const FLOOR="res://art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/ground_v14/root_ground_v14_02/floor.png"
const FLOOR_SHA="494c52dac3edc4d82c8a1cb02691b80c8175e5b25ef351866e3733ff5471aba1"
const NPC_SCENE="res://scenes/npc_node.tscn"
const NPC_SCENE_SHA="fd497082cbb1c7e2028cb6063074aeb066f81d4c8505d35f5428bb0607ca4191"
const NPC_SCRIPT="res://scripts/field/npc_node.gd"
const NPC_SCRIPT_SHA="67c0f3deafef65445918b5815f4acdcb4cc577206248f20cd67a998930d00bea"
const LOCAL_TEXTURE_LIMIT_BYTES=268435456
var preview: Node2D
var actors: Array[NPCNode]=[]
func _local_preview(folder: String) -> bool:
	if not check(DisplayServer.get_name()!="headless","Actual GPU display required for local preview"): return false
	var memory_before: int=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)
	root.size=Vector2i(1920,1080);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size=Vector2i.ZERO
	root.canvas_transform=Transform2D(0.0,Vector2(-960,-996))
	preview=Node2D.new();preview.name="LocalMaterialPreviewNotField";root.add_child(preview)
	var full_floor:=Image.load_from_file(FLOOR)
	if not check(full_floor!=null and full_floor.get_size()==Vector2i(3072,2048),"Original Docks floor source, CPU ROI extraction only"): return false
	var crop: Rect2i=Rect2i(1152,1024,1536,1024)
	var floor_roi: Image=full_floor.get_region(crop);full_floor=null
	var ground:=Sprite2D.new();ground.texture=ImageTexture.create_from_image(floor_roi);ground.centered=false;ground.position=Vector2(crop.position);ground.z_index=-1000;preview.add_child(ground)
	var office: Dictionary=data.office
	var building:=Sprite2D.new();building.texture=ResourceLoader.load(office.texture) as Texture2D
	building.centered=false;building.position=_v(office.expected_foot_px)-_v(office.source_ground_anchor_px)*_v(office.render_scale_xy);building.scale=_v(office.render_scale_xy)
	building.z_index=clampi(int(floor(float(office.expected_foot_px[1])/8.0)),0,255);preview.add_child(building)
	if not check(building.texture!=null and building.texture.get_size()==_v(office.source_size_px),"Actual new office texture at source-ground projection"): return false
	var packed: PackedScene=ResourceLoader.load(NPC_SCENE) as PackedScene
	if not check(packed!=null,"Original production NPC scene"): return false
	for id: String in M.ROLE_IDS:
		var role: Dictionary=data.roles[id]
		var npc: NPCNode=packed.instantiate() as NPCNode
		npc.npc_id=id;npc.npc_name=role.expected_name;npc.sprite_path=role.texture;npc.sprite_scale=1.0;npc._calibrate_adult_body=true;npc.movement_mode="idle";npc.position=_v(role.expected_foot_px)
		preview.add_child(npc);npc.set_ground_anchored(true)
		npc.interact_area.monitoring=false;npc.interact_area.monitorable=false;npc.interact_area.input_pickable=false;npc._in_range=false;npc.prompt.visible=false;npc._set_interaction_highlight(false)
		actors.append(npc)
	var caption_layer:=CanvasLayer.new();caption_layer.layer=100;preview.add_child(caption_layer)
	var caption:=Label.new();caption.position=Vector2(24,8);caption.text="码头职业／办公楼局部比例预览 · 非Field出生或遮挡验收\n原world坐标、floor(脚深/8)排序；两角色单帧静驻，无动画信用";caption.add_theme_font_size_override("font_size",18);caption_layer.add_child(caption)
	await process_frame;await physics_frame;await process_frame
	if not check(actors.size()==2 and get_nodes_in_group("npc").size()==2,"Exactly two real NPC nodes, no comparison duplicates or extra npc group actors"): return false
	for npc: NPCNode in actors:
		var image: Image=npc.sprite.texture.get_image()
		if image.is_compressed() and not check(image.decompress()==OK,"Read-only runtime native image decode"): return false
		var bounds: Rect2i=image.get_used_rect()
		var expected_scale: Vector2=Vector2.ONE*(140.0/float(bounds.size.y))
		var body: StaticBody2D=npc.get("_body_collider")
		var collider: CollisionShape2D=body.get_child(0) as CollisionShape2D
		var center: Vector2=body.to_global(collider.position)
		var alpha_foot: float=npc.global_position.y+npc.sprite.position.y+(float(bounds.end.y)-80.0)*npc.sprite.scale.y
		var query:=PhysicsPointQueryParameters2D.new();query.position=npc.global_position;query.collision_mask=1;query.collide_with_areas=false
		var hits: Array[Dictionary]=npc.get_world_2d().direct_space_state.intersect_point(query,4)
		var own_hit: bool=false
		for hit: Dictionary in hits:
			if hit.collider==body: own_hit=true
		if not check(npc._calibrate_adult_body and npc._ground_anchored and npc.sprite_scale==1.0 and npc.sprite.scale==expected_scale and npc.sprite.hframes==1 and npc.sprite.vframes==1 and npc.sprite.frame==0 and npc.movement_mode=="idle" and collider.shape is RectangleShape2D and (collider.shape as RectangleShape2D).size==Vector2(22.4,28.8) and center==npc.global_position and own_hit and absf(alpha_foot-npc.global_position.y)<=12.0 and npc.z_index==clampi(int(floor(npc.get_depth_sort_y()/8.0)),0,255),"Actual native body/140 alpha calibration/zero ground center/1f/depth/visible-foot<=12",npc.npc_id): return false
		records.append({"kind":"ACTUAL_LOCAL_NPC_NODE","id":npc.npc_id,"source_foot":npc.global_position,"runtime_size":image.get_size(),"alpha_bounds":bounds,"scale":npc.sprite.scale,"visible_alpha_height":bounds.size.y*npc.sprite.scale.y,"visible_alpha_foot":alpha_foot,"alpha_foot_delta":alpha_foot-npc.global_position.y,"body_size":(collider.shape as RectangleShape2D).size,"body_center":center,"native_body_point_hit":own_hit,"frame":npc.sprite.frame,"hframes":npc.sprite.hframes,"depth":npc.get_depth_sort_y(),"z":npc.z_index,"Field_claimed":false})
	var estimated_bytes: int=(1536*1024+2*160*160+1536*1024+4*1920*1080)*4
	var memory_after: int=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)
	if not check(estimated_bytes<=LOCAL_TEXTURE_LIMIT_BYTES and maxi(0,memory_after-memory_before)<=LOCAL_TEXTURE_LIMIT_BYTES,"Bounded local texture/view estimate and actual texture counter, not full process VRAM measurement"): return false
	await RenderingServer.frame_post_draw
	var capture: Image=root.get_texture().get_image()
	var png: String=folder.path_join("office_roles_local_preview.png")
	if not check(capture.get_size()==Vector2i(1920,1080) and capture.save_png(png)==OK,"One actual1920x1080 local GPU image"): return false
	records.append({"kind":"ONLY_LOCAL_PREVIEW","png":png,"png_sha256":FileAccess.get_sha256(png),"office_foot":office.expected_foot_px,"office_scale_xy":building.scale,"office_z":building.z_index,"floor_roi":crop,"cpu_crop_no_full_floor_gpu_texture":true,"native_world_coordinates_and_depth":true,"actor_overlay_layer_used":false,"estimated_added_bytes":estimated_bytes,"texture_counter_before":memory_before,"texture_counter_after":memory_after,"requires_root_external_free_guard_mib":512,"full_Field_g_guard_not_changed":true,"Docks_birth_or_performance_claimed":false})
	return true
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+30000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var folder: String="res://build/luoyang_docks_office_roles_local_gpu_20261016h/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=_precheck() and track(CPU_BASE,CPU_BASE_SHA) and track(FLOOR,FLOOR_SHA) and track(NPC_SCENE,NPC_SCENE_SHA) and track(NPC_SCRIPT,NPC_SCRIPT_SHA)
	if complete: complete=await _local_preview(folder)
	var weak: Array[WeakRef]=[]
	for npc: NPCNode in actors: weak.append(weakref(npc))
	actors.clear()
	if is_instance_valid(preview): preview.queue_free()
	await process_frame;await process_frame
	for item: WeakRef in weak: check(item.get_ref()==null,"Own local native actor released")
	root.canvas_transform=Transform2D.IDENTITY
	finish(folder,began,complete,"ONE_LOCAL_GPU_PREVIEW_NOT_FIELD_DOCKS_BIRTH_PERFORMANCE_OR_FULL_WORLD")

