extends "res://build/world_sects_cities_20261031c_qa01/probe_base_ROOT_ONLY.gd"
## Root-only: no Space, actor/camera/material edits, phase writes or real save APIs.
const FIXTURE := "res://build/world_cities_20261031d_qa01/visual_residual_inputs_READY.json"
const H := &"openworld_huashan_forecourt"

func _watch() -> void:
	await create_timer(40.0,true,false,true).timeout
	if not done:need(false,"HARD40S_VISUAL_RESIDUAL");finish()

func boot(_domain: String) -> bool:
	directory="res://build/world_cities_20261031d_qa01/visual_actual/"+str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"EARLIEST_CHECKPOINT_SUSPEND"):return false
	router=root.get_node("SceneRouter")
	cfg=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)) as Dictionary
	for path: String in cfg.pins:
		if not need(FileAccess.get_sha256(path)==String(cfg.pins[path]),"VISUAL31D_PIN:"+path):return false
	var registry: Script=load(String(cfg.registry)) as Script
	return need(registry!=null and registry.call("source_valid")==true,"EXPLICIT226_SOURCE_VALID")

func effective_z(item: CanvasItem) -> int:
	var value := 0;var node: Node=item
	while node is CanvasItem:
		value+=(node as CanvasItem).z_index
		if not (node as CanvasItem).z_as_relative:break
		node=node.get_parent()
	return value

func sprite_bounds(sprite: Sprite2D) -> Rect2:
	var rect: Rect2=sprite.get_rect();var t: Transform2D=sprite.get_global_transform_with_canvas()
	var bounds:=Rect2(t*rect.position,Vector2.ZERO)
	for point: Vector2 in [rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]:bounds=bounds.expand(t*point)
	return bounds

func save_normal(image: Image,label: String) -> void:
	var path: String=directory+"/"+label+".png"
	if need(image!=null and image.save_png(path)==OK,"NORMAL_IMAGE:"+label):records.append({"normal_image":path,"sha256":FileAccess.get_sha256(path),"foot":foot()})

func rgb_distance(a: Color,b: Color) -> float:
	return maxf(maxf(absf(a.r-b.r),absf(a.g-b.g)),absf(a.b-b.b))

func world_display() -> bool:
	if not await setup(&"world_map_jianghu",Vector2(900,6000)/Vector2(12288,8192)):return false
	var until: int=Time.get_ticks_msec()+6000
	while Time.get_ticks_msec()<until:
		var stream: Dictionary=field.call("get_world_v15_stream_debug")
		if not String(stream.get("error","")).is_empty():records.append(stream);return need(false,"WORLD_STREAM_ERROR")
		if int(stream.get("pending",-1))==0:break
		await process_frame
	var group: Node=world.get_node_or_null("ThreeTownWorldAdditions/openworld_lanxi_zhai")
	var landmark: Sprite2D
	if group!=null:
		for child: Node in group.get_children():
			if child is Sprite2D:landmark=child;break
	var player:=actor as Player;var sprite: Sprite2D=player.sprite
	if not need(landmark!=null and sprite!=null,"ACTUAL_LANXI_AND_PLAYER_SPRITES"):return false
	var layer:=actor.get_parent() as Node2D
	var expected_art_z: int=740+layer.z_index+world.z_index
	if not need(landmark.z_as_relative and landmark.z_index==760 and effective_z(landmark)==660 and effective_z(sprite)==669 and expected_art_z==660,"ACTUAL_RELATIVE_ART660_BELOW_PLAYER669_IN_WORLD_MINUS100"):return false
	if not need(foot().distance_to(Vector2(900,6000))<.01 and sprite.is_visible_in_tree() and sprite.modulate.a==1.0 and sprite.self_modulate.a==1.0 and sprite.material==null,"ORIGINAL_DOOR_FOOT_VISIBLE_SOURCE_UNCHANGED"):return false
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image()
	var source: Image=sprite.texture.get_image()
	if source.is_compressed():source.decompress()
	var cell:=Vector2i(source.get_width()/sprite.hframes,source.get_height()/sprite.vframes)
	var origin: Vector2i=sprite.frame_coords*cell
	var t: Transform2D=sprite.get_global_transform_with_canvas();var local_start: Vector2=sprite.get_rect().position
	var alpha_pixels := 0;var compared := 0;var matching := 0
	for y: int in range(1,cell.y-1):
		for x: int in range(1,cell.x-1):
			var color: Color=source.get_pixelv(origin+Vector2i(x,y))
			if color.a>.1:alpha_pixels+=1
			if color.a<.99:continue
			var interior := true
			for step: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				if source.get_pixelv(origin+Vector2i(x,y)+step).a<.99:interior=false;break
			if not interior:continue
			var pixel:=Vector2i((t*(local_start+Vector2(float(x)+.5,float(y)+.5))).floor())
			if not Rect2i(Vector2i.ZERO,image.get_size()).has_point(pixel):continue
			compared+=1
			if rgb_distance(image.get_pixelv(pixel),color)<.15:matching+=1
	var ratio: float=float(matching)/maxf(float(compared),1.0)
	records.append({"World_relative_art_z":landmark.z_index,"World_effective_art_z":effective_z(landmark),"World_effective_player_z":effective_z(sprite),"WorldContainer_z":world.z_index,"ActorLayer_z":layer.z_index,"source_texture":sprite.texture.resource_path,"source_frame":sprite.frame,"source_alpha_pixels_actual":alpha_pixels,"prior_diagnostic_alpha_frame1":3972,"opaque_interior_source_points":compared,"normal_frame_RGB_matching_points":matching,"match_ratio":ratio,"screen_bounds":sprite_bounds(sprite),"no_actor_or_camera_or_material_writes":true})
	save_normal(image,"lanxi_original_door_actual_visible_hero")
	return need(alpha_pixels>2000 and compared>1000 and ratio>.70,"ACTUAL_VIEWPORT_CONTAINS_OPAQUE_HERO_RGB_NOT_ONLY_Z_ASSERTION")

func huashan_display() -> bool:
	# Original public versioned initialization, then disclosed near setup; no travel credit.
	if not await setup(H,null,3006) or not await setup(H,Vector2(2770,890)/Vector2(5800,5000),3006):return false
	var debug: Dictionary=field.call("get_sect_adoption_debug")
	if not need(foot().distance_to(Vector2(2770,890))<.04 and int(debug.actor_level)==2,"PUBLIC_H_L2_NEAR_ORIGINAL_FOOT"):return false
	var state: Dictionary=town.call("get_environment31d_debug")
	var art:=town.get_node_or_null("HuashanFarMountains31d/WholeNativeMountainBackdrop") as Sprite2D
	var canvas:=town.get_node_or_null("HuashanFarMountains31d") as CanvasLayer
	if not need(art!=null and canvas!=null and bool(state.get("ready",false)) and String(state.get("source",""))==String(cfg.mountain_source) and String(state.get("source_sha256",""))==String(cfg.pins[String(cfg.mountain_source)]) and art.texture.get_size()==Vector2(1672,941),"ACTUAL_FD08_WHOLE_NATIVE1672_941_BACKDROP"):return false
	var view: Rect2=root.get_visible_rect();var bounds: Rect2=sprite_bounds(art)
	var expected_scale: float=maxf(view.size.x/1672.0,view.size.y/941.0)
	if not need(canvas.layer==-10 and art.is_visible_in_tree() and is_equal_approx(art.scale.x,art.scale.y) and is_equal_approx(art.scale.x,expected_scale) and bounds.position.x<=view.position.x+.01 and bounds.position.y<=view.position.y+.01 and bounds.end.x>=view.end.x-.01 and bounds.end.y>=view.end.y-.01,"VISIBLE_UNIFORM_WHOLE_IMAGE_COVER_NO_STRETCH"):return false
	var mirrors: Array=[]
	for id: String in ["CliffNative1","CliffNative3"]:
		var cliff:=town.get_node_or_null("Terrain/NativeSectRepair31c/"+id) as Sprite2D
		if not need(cliff!=null and cliff.flip_h and cliff.texture.get_size()==Vector2(1536,1024) and is_equal_approx(cliff.scale.x,cliff.scale.y),"WHOLE_NATIVE_NORTH_CLIFF_MIRROR:"+id):return false
		mirrors.append({"id":id,"flip_h":cliff.flip_h,"scale":cliff.scale,"position":cliff.position})
	var opaque := true;var count := 0
	for item: Node in town.get_node("Town").get_children():
		if not item.has_meta("fade"):continue
		var building:=item.get_node_or_null("Art") as Sprite2D
		if building==null:continue
		count+=1;opaque=opaque and building.modulate.a>.999 and building.self_modulate.a>.999
		if building.material is ShaderMaterial:opaque=opaque and float(building.material.get_shader_parameter("fade_enabled"))==0.0
	if not need(opaque and count>0,"BUILDINGS_STAY_OPAQUE_WITH_NEW_BACKGROUND"):return false
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image()
	var old: Image=Image.load_from_file(String(cfg.old_huashan_normal_image))
	var roi:=Rect2i(1120,20,300,90);var clear: Color=old.get_pixel(1120,20)
	var previous_gray := 0;var filled := 0
	for y: int in range(roi.position.y,roi.end.y):
		for x: int in range(roi.position.x,roi.end.x):
			if rgb_distance(old.get_pixel(x,y),clear)>.01:continue
			previous_gray+=1
			if rgb_distance(image.get_pixel(x,y),clear)>.03:filled+=1
	records.append({"normal_camera_no_edits":true,"new_background":state,"render_bounds":bounds,"old_gray_ROI":roi,"previous_clear_RGB":clear,"old_clear_pixels":previous_gray,"new_background_RGB_pixels_in_old_clear_area":filled,"whole_mirror_cliffs":mirrors,"opaque_building_count":count,"old_stairs_physics_travel_not_repeated":true})
	save_normal(image,"huashan_original_north_view_far_mountains")
	return need(previous_gray>25000 and float(filled)/maxf(float(previous_gray),1.0)>.95,"ACTUAL_OLD_GRAY_VOID_ROI_NOW_DRAWN_NOT_CLEAR_COLOR")

func _run() -> void:
	if not await boot("visual_residual"):finish();return
	if not await world_display():finish();return
	if not await huashan_display():finish();return
	finish()

func finish() -> void:
	if done:return
	done=true
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"input_events":inputs,"records":records,"scope":"31d only new effective World draw depth/pixels and Huashan background/mirrors; original portal, stairs, NPC/water matrices inherited not repeated","real_save_API_calls":0},"\t"));file.close()
	quit(0 if errors.is_empty() else 1)
