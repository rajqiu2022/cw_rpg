extends "res://build/world_sects_cities_20261031c_qa01/probe_base_ROOT_ONLY.gd"
func digest(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new();context.start(HashingContext.HASH_SHA256);context.update(bytes);return context.finish().hex_encode()
func screen_region(rect: Rect2) -> Rect2i:
	var transform: Transform2D=world.get_global_transform_with_canvas()
	var bounds:=Rect2(transform*rect.position,Vector2.ZERO)
	for p: Vector2 in [Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:bounds=bounds.expand(transform*p)
	return Rect2i(bounds.intersection(root.get_visible_rect()))
func water_pair(node_name: String,world_rect: Rect2) -> bool:
	var water: Polygon2D=world.get_node_or_null(node_name) as Polygon2D
	if not need(water!=null and water.material is ShaderMaterial and water.material.shader.resource_path==String(cfg.water_shader),"REAL_STANDALONE_WATER_FLOW_MATERIAL:"+node_name):return false
	var geometry: PackedByteArray=var_to_bytes([water.polygon,water.uv,water.position,water.scale,water.modulate])
	var camera: Transform2D=world.get_global_transform_with_canvas();var at: Vector2=foot();var roi: Rect2i=screen_region(world_rect)
	if not need(roi.size.x>=50 and roi.size.y>=25,"WATER_REAL_VIEWPORT_ROI_IN_NORMAL_CAMERA"):return false
	await RenderingServer.frame_post_draw
	var first: Image=root.get_viewport().get_texture().get_image().get_region(roi);first.convert(Image.FORMAT_RGBA8)
	var began: int=Time.get_ticks_msec()
	await create_timer(1.6).timeout;await RenderingServer.frame_post_draw
	var second: Image=root.get_viewport().get_texture().get_image().get_region(roi);second.convert(Image.FORMAT_RGBA8)
	var a: PackedByteArray=first.get_data();var b: PackedByteArray=second.get_data();var changed := 0
	for i: int in range(0,a.size(),4):
		if a[i]!=b[i] or a[i+1]!=b[i+1] or a[i+2]!=b[i+2]:changed+=1
	records.append({"real_water_viewport_two_times":node_name,"world_ROI":world_rect,"screen_ROI":roi,"elapsed_ms":Time.get_ticks_msec()-began,"RGBA_first":digest(a),"RGBA_second":digest(b),"changed_RGB_pixels":changed,"no_time_uniform_or_actor_or_camera_write":true})
	return need(changed>20 and foot().distance_to(at)<.01 and world.get_global_transform_with_canvas().is_equal_approx(camera) and geometry==var_to_bytes([water.polygon,water.uv,water.position,water.scale,water.modulate]),"REAL_TIME_WATER_PIXELS_CHANGE_GEOMETRY_CAMERA_UNCHANGED")
func districts(paths: Array) -> bool:
	var good := true;var seen: Array=[]
	for path: String in paths:
		var parts: PackedStringArray=path.split(":",true,1)
		var parent: Node=world if parts[0]=="world" else field.get("_visual_layer") as Node
		var node: Polygon2D=parent.get_node_or_null(parts[1]) as Polygon2D
		good=good and node!=null
		if node!=null:
			good=good and node.is_visible_in_tree() and node.texture!=null and node.polygon.size()>=3 and node.uv.size()==node.polygon.size()
			seen.append({"path":path,"z":node.z_index,"polygon":node.polygon,"texture":node.texture.resource_path,"period":node.get_meta("jl_period",Vector2.ZERO),"feather_px":node.get_meta("jl_feather_px",0)})
	records.append({"actual_new_district_polygons":seen})
	return need(good,"ONLY_NEW_DISTRICT_RUNTIME_POLYGONS")
func npc_identity(npc: NPCNode) -> PackedByteArray:
	return var_to_bytes([npc.npc_id,npc.npc_name,npc.dialog_id,npc.interaction_action,npc.patrol_axis,npc.patrol_distance,npc.patrol_speed,npc.get("_patrol_origin"),npc.sprite_path,npc.walk_sprite_path,npc.portrait_path])
func _run() -> void:
	if not await boot("cities"):finish();return
	var x:=&"openworld_xiangzhou_city";var j:=&"openworld_jinling_city"
	if not await setup(x,null,30) or not await setup(x,Vector2(1200,3030)/Vector2(5632,4096),30):finish();return
	var npc: NPCNode
	for item: NPCNode in field.get("_npc_nodes"):
		if item.npc_id=="xiangzhou_life_18":npc=item;break
	if not need(npc!=null and npc.invert_patrol_facing and npc.walk_sprite_path==String(cfg.merchant_left_source),"EXACT_MERCHANT_ROW_INVERSION_NOT_GLOBAL_NPC_FLIP"):finish();return
	var identity: PackedByteArray=npc_identity(npc);var last: float=npc.position.x;var last_phase: float=float(npc.get("_patrol_phase"));var right := 0;var left := 0;var mismatch := 0;var frames: Array[int]=[];var samples: Array=[];var turn_intervals := 0
	var until: int=Time.get_ticks_msec()+8100
	while not done and Time.get_ticks_msec()<until:
		await process_frame
		var dx: float=npc.position.x-last;last=npc.position.x
		var phase: float=float(npc.get("_patrol_phase"));var same_direction_interval: bool=cos(last_phase)*cos(phase)>0.0;last_phase=phase
		if not frames.has(npc.sprite.frame):frames.append(npc.sprite.frame)
		if not same_direction_interval:turn_intervals+=1
		if absf(dx)>.01 and same_direction_interval:
			if dx>0:right+=1
			else:left+=1
			if npc.sprite.flip_h!=(dx>0):mismatch+=1
			if samples.size()<6 or (left==1 or right==1):samples.append({"x":npc.position.x,"dx":dx,"flip_h":npc.sprite.flip_h,"frame":npc.sprite.frame})
	records.append({"merchant_true_delta_and_actual_left_source":samples,"right_samples":right,"left_samples":left,"frames_seen":frames,"mismatches":mismatch,"turn_straddling_intervals_not_direction_oracle":turn_intervals,"phase_read_only_never_written":true})
	if not need(right>=3 and left>=3 and mismatch==0 and frames.size()>=2 and identity==npc_identity(npc),"REAL_BOTH_PATROL_DIRECTIONS_AND_FRAME_ADVANCE_IDENTITY_PRESERVED"):finish();return
	if not districts(cfg.x_district_paths):finish();return
	if not await water_pair("JinlingPaving_river",Rect2(1000,3270,150,70)):finish();return
	await shot("xiangzhou_courtyard_correct_merchant_and_water")
	if not await setup(j,Vector2(2816,1340)/Vector2(5632,4096),31):finish();return
	if not need(foot().distance_to(Vector2(2816,1340))<.1,"J_PUBLIC_NATIVE31_EXACT_SAFE_NEW_DISTRICT"):finish();return
	if not districts(cfg.j_district_paths) or not await walk(Vector2(2880,1340),25):finish();return
	await shot("jinling_silk_court_native_side_building")
	if not await setup(j,Vector2(2816,1980)/Vector2(5632,4096),31):finish();return
	if not await water_pair("JinlingPaving_canal_water",Rect2(2700,2180,180,70)):finish();return
	var dispatch: Script=load(cfg.region_dispatch) as Script
	var old: int=current_scene.get_instance_id()
	var extension: Dictionary={"region_id":"luoyang_civic_market_region_27d","revision":1,"logical_id":"ch4_s3_luoyang_market","global_foot_px":[2470,3400]}
	records.append({"public_versioned_RegionDispatch_start_not_fake_owner":extension,"legacy_uv":Vector2(.380859375,.78125),"legacy_version":3})
	if not need(dispatch.call("start",router,&"ch4_s3_luoyang_market",Vector2(.380859375,.78125),"",3,extension)==true,"PUBLIC_REGION_AUTHENTICATED_EXTENSION_ACCEPTED"):finish();return
	if not await ready_field(&"ch4_s3_luoyang_market",old):finish();return
	if not need(foot().distance_to(Vector2(2470,3400))<.1 and String(field.call("get_region27d_state").id)=="luoyang_civic_market_region_27d","LY_PHYSICAL2470_3400_NOT_MISUSED_MARKET_UV"):finish();return
	if not districts(cfg.ly_district_paths) or not await walk(Vector2(2470,3464),25):finish();return
	await shot("luoyang_cloth_frontage_workcourt_difference")
	finish()
