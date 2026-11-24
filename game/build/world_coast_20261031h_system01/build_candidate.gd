extends SceneTree
## ROOT-ONLY, additive publication. Refuses existing outputs; never adopts.
const AUTHOR=preload("res://build/world_coast_20261031h_system01/coast_author.gd")
const FARMLAND=preload("res://scripts/world/world_farmland_visual_patch_resolver_20261015.gd")
const ROOT := "res://build/world_coast_20261031h_system01/"
const OUT := "res://art/maps/world_coast_20261031h/candidate/"
const BASE := "res://art/maps/world_map_v15_complete_v9c/"
const LAYOUT := "res://data/maps/world_map_jianghu_layout_v15.tres"
const STREAM := "res://data/background_sets/world_map_jianghu_v15_streamed.tres"
const SCENE := "res://data/scenes/world_map_jianghu_v15.tres"
var _plan: Dictionary
var _source_graph: Dictionary={}
var _new_heights: PackedFloat32Array
var _terrain: ShaderMaterial
var _water: ShaderMaterial
var _rf_texture: ImageTexture
var _view3: SubViewport
var _receiver: MeshInstance3D
var _water_node: MeshInstance3D
var _camera: Camera3D
var _land: ShaderMaterial
var _layout: WalkableMapLayout
var _stream: StreamedBackgroundSet
var _scene: SceneScript
var _retired: Array[String]=[]
var _changed: Array[Dictionary]=[]
var _navigation: Array[Dictionary]=[]
var _all_ports: Array[Dictionary]=[]
var _error := ""
var _done := false
var _checkpoint_suspended := false
var _deadline_msec := 0

func _initialize() -> void:
	_deadline_msec=Time.get_ticks_msec()+180000
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	paused=true
	call_deferred("_run");call_deferred("_watchdog")

func _early(node: Node) -> void:
	if node.name==&"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true)
		_checkpoint_suspended=bool(node.call("is_checkpoint_saves_suspended"))

func _watchdog() -> void:
	await create_timer(180.0,true,false,true).timeout
	if not _done:_fail("HARD180S_WATCHDOG; all partial NEW outputs retained")

func _fail(message: String) -> void:
	if _done:return
	_done=true
	push_error("[CoastV16Candidate] "+message);quit(1)

func _argument(key: String) -> String:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	for i: int in args.size()-1:
		if args[i]==key:return args[i+1]
	return ""

func _run() -> void:
	if not "--publish-coast-v16-candidate" in OS.get_cmdline_user_args():_fail("EXPLICIT_ROOT_PUBLICATION_FLAG_REQUIRED");return
	if DisplayServer.get_name()=="headless" or "--headless" in OS.get_cmdline_args():_fail("REAL_GPU_DISPLAY_REQUIRED_NO_HEADLESS_CAPTURE");return
	await process_frame
	if not _checkpoint_suspended:_fail("EARLIEST_CHECKPOINT_SUSPEND_REQUIRED");return
	var expected: String=_argument("--source-plan-sha").to_lower()
	if expected.length()!=64 or FileAccess.get_sha256(ROOT+"source_plan.json")!=expected:_fail("EXACT_SOURCE_PLAN_SHA_REQUIRED");return
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"source_plan.json"))
	if not parsed is Dictionary or parsed.get("coordinate_space_version")!=16:_fail("SOURCE_PLAN_SCHEMA");return
	_plan=parsed
	for path: String in [ROOT+"source_plan.json",ROOT+"coast_author.gd",ROOT+"build_candidate.gd",ROOT+"coast_composite.gdshader",ROOT+"native_land.gdshader"]:_pin(path)
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(OUT)):_fail("OUTPUT_ALREADY_EXISTS_NO_OVERWRITE");return
	for path: String in [ROOT+"world_v16_layout.tres",ROOT+"world_v16_stream.tres",ROOT+"world_v16_scene.tres"]:
		if FileAccess.file_exists(path):_fail("NEW_RESOURCE_ALREADY_EXISTS: "+path);return
	for path: String in _plan.source_sha256:
		if FileAccess.get_sha256(path)!=_plan.source_sha256[path]:_fail("PINNED_BASELINE_CHANGED: "+path);return
		_source_graph[path]=_plan.source_sha256[path]
	var old_heights: PackedFloat32Array=FileAccess.get_file_as_bytes(BASE+"terrain_height.rf").to_float32_array()
	var derived: Dictionary=AUTHOR.derive(old_heights)
	if derived.get("ok")!=true:_fail("RF_DERIVATION: "+String(derived.get("error","EMPTY_CHANGE")));return
	_new_heights=derived.heights
	_layout=(load(LAYOUT) as WalkableMapLayout).duplicate(true) as WalkableMapLayout
	_stream=(load(STREAM) as StreamedBackgroundSet).duplicate(true) as StreamedBackgroundSet
	_scene=(load(SCENE) as SceneScript).duplicate(false) as SceneScript
	if _layout==null or _stream==null or _scene==null:_fail("BASELINE_RESOURCE_LOAD");return
	var effective: Array[Dictionary]=FARMLAND.effective_chunks(load(STREAM),false)
	if effective.size()!=64 or _layout.walkable_mask_tiles.size()!=64 or _layout.portals.size()!=16:_fail("BASELINE_64_CELLS_16_PORTALS_REQUIRED");return
	if not _retire_water_objects():_fail(_error);return
	_collect_ports()
	if _all_ports.size()!=22:_fail("EXACT_22_PORTALS_REQUIRED");return
	if not _bridge_and_door_protection():_fail(_error);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+"chunks/"))
	var rf_file:=FileAccess.open(OUT+"terrain_height.rf",FileAccess.WRITE)
	if rf_file==null:_fail("RF_WRITE");return
	rf_file.store_buffer(_new_heights.to_byte_array());rf_file.close()
	var patch: ArrayMesh=AUTHOR.patch_mesh(_new_heights,AUTHOR.DOMAIN.grow(AUTHOR.HALO))
	if ResourceSaver.save(patch,OUT+"terrain_patch.res")!=OK:_fail("PATCH_MESH_WRITE");return
	if not _make_native_world(patch):_fail(_error);return
	var rows: Array[Dictionary]=[]
	for i: int in effective.size():
		var row: Dictionary=effective[i].duplicate(true)
		var rect: Rect2=row.logical_rect
		var id: String="r%d_c%d"%[int(rect.position.y)/1024,int(rect.position.x)/1536]
		var nav: Dictionary=_layout.walkable_mask_tiles[i].duplicate(true)
		if nav.logical_rect!=rect:_fail("ROW_ORDER_RECT_MISMATCH");return
		_pin(String(row.path));_pin(String(nav.path))
		if rect.intersects(AUTHOR.DOMAIN.grow(AUTHOR.HALO)):
			var native: Dictionary=await _capture_native(rect)
			if _done:return
			if native.is_empty():_fail(_error);return
			var visual: Image=await _composite(rect,_image_texture(row.path),ImageTexture.create_from_image(native.visual),0)
			var walk: Image=await _composite(rect,_image_texture(nav.path),ImageTexture.create_from_image(native.land),1)
			if _done:return
			if visual==null or walk==null:_fail("BOUNDED_COMPOSITE_EMPTY");return
			row.path=OUT+"chunks/"+id+"_visual.png";nav.path=OUT+"chunks/"+id+"_walk.png"
			if visual.save_png(row.path)!=OK or walk.save_png(nav.path)!=OK:_fail("CHANGED_CELL_WRITE");return
			if native.land.save_png(OUT+"chunks/"+id+"_new_rf_land.png")!=OK:_fail("LANDFOOT_EVIDENCE_WRITE");return
			_changed.append({"id":id,"logical_rect":_rect_array(rect),"visual_path":row.path,"nav_path":nav.path,"land_evidence":OUT+"chunks/"+id+"_new_rf_land.png","baseline_visual_path":effective[i].path,"baseline_nav_path":_layout.walkable_mask_tiles[i].path})
		rows.append(row);_layout.walkable_mask_tiles[i]=nav
		_navigation.append({"path":nav.path,"logical_rect":_rect_array(rect),"sha256":FileAccess.get_sha256(nav.path)})
		print("[CoastV16Candidate] cell ",id," changed=",rect.intersects(AUTHOR.DOMAIN.grow(AUTHOR.HALO)))
	_stream.mobile_chunks=rows;_stream.desktop_chunks=rows.duplicate(true)
	var overview_ok: bool=await _build_overview()
	if _done:return
	if not overview_ok:_fail(_error);return
	_layout.set_meta("coordinate_space_version",16);_layout.set_meta("geography_revision","world_coast_20261031h")
	_stream.mobile_preview_path=OUT+"overview.png";_stream.desktop_preview_path=OUT+"overview.png"
	_scene.scene_id=&"world_map_jianghu_v16";_scene.map_layout=_layout;_scene.streamed_background=_stream;_scene.background_path=OUT+"overview.png"
	_scene.set_meta("coordinate_space_version",16);_scene.set_meta("geography_revision","world_coast_20261031h")
	if ResourceSaver.save(_layout,ROOT+"world_v16_layout.tres",ResourceSaver.FLAG_CHANGE_PATH)!=OK or ResourceSaver.save(_stream,ROOT+"world_v16_stream.tres",ResourceSaver.FLAG_CHANGE_PATH)!=OK or ResourceSaver.save(_scene,ROOT+"world_v16_scene.tres",ResourceSaver.FLAG_CHANGE_PATH)!=OK:_fail("NEW_PRIVATE_RESOURCE_WRITE");return
	if not _ports_safe():_fail(_error);return
	for path: String in _source_graph:
		if FileAccess.get_sha256(path)!=_source_graph[path]:_fail("SOURCE_CHANGED_DURING_BUILD: "+path);return
	var manifest: Dictionary={"schema":"WORLD_COAST_V16_CANDIDATE_1","coordinate_version":16,"coordinate_space_version":16,"layout_format_version":15,"world_size":[12288,8192],"scene_id":"world_map_jianghu_v16","scene_path":ROOT+"world_v16_scene.tres","layout_path":ROOT+"world_v16_layout.tres","stream_path":ROOT+"world_v16_stream.tres","geometry":{"rf_path":OUT+"terrain_height.rf","rf_sha256":FileAccess.get_sha256(OUT+"terrain_height.rf"),"mesh_path":OUT+"terrain_patch.res","mesh_sha256":FileAccess.get_sha256(OUT+"terrain_patch.res"),"mesh_scope":"BOUNDED_NEW_RF_PATCH_NOT_A_FULL_WORLD_MESH","baseline_mesh_path":BASE+"terrain_mesh.res","baseline_mesh_sha256":_source_graph[BASE+"terrain_mesh.res"],"grid_size":[1537,1025],"grid_step_px":8,"changed_vertices":derived.changed_vertices},"navigation_tiles":_navigation,"changed_cells":_changed,"unchanged_cells_reused_by_path":64-_changed.size(),"migration_regions":AUTHOR.migration_regions(),"moved_portals":[],"portals":_all_ports,"original_portal_count":16,"runtime_portal_count":6,"bridge_rows_unchanged":true,"retired_water_object_ids":_retired,"source_graph":_source_graph,"baseline_reference_layout":LAYOUT,"baseline_reference_stream":STREAM,"overview_path":OUT+"overview.png","seeds":{"island":[11700,3417.3652],"mainland":[10200,2988.9077],"bailu":[9300,4301.3623]},"status":"CANDIDATE_REQUIRES_FULL_RESOLUTION_COMPONENT_AND_FIELD_QA","production_approved":false,"visual_approved":false,"old_navigation_credit":false,"bianzhou_status":"NOT_MOVED_PENDING_GEOMETRY_CHECKS"}
	manifest.layout_sha256=FileAccess.get_sha256(ROOT+"world_v16_layout.tres")
	manifest.stream_sha256=FileAccess.get_sha256(ROOT+"world_v16_stream.tres")
	manifest.scene_sha256=FileAccess.get_sha256(ROOT+"world_v16_scene.tres")
	if _done:return
	if Time.get_ticks_msec()>=_deadline_msec:_fail("HARD180S_BEFORE_SUCCESS; all partial NEW outputs retained");return
	if not _write_json(OUT+"runtime_contract.json",manifest):_fail("RUNTIME_MANIFEST_WRITE");return
	print("[CoastV16Candidate] CANDIDATE_WRITTEN; not adopted; full-resolution flood/Field/ART pending")
	_done=true
	quit(0)

func _pin(path: String) -> void:
	if not _source_graph.has(path):_source_graph[path]=FileAccess.get_sha256(path)

func _retire_water_objects() -> bool:
	var kept: Array[Dictionary]=[]
	for row: Dictionary in _layout.visual_objects:
		var raw: Variant=row.get("world_foot_px")
		var foot: Vector2=Vector2(raw[0],raw[1]) if raw is Array else Vector2(row.get("pos",Vector2.ZERO))*AUTHOR.WORLD_SIZE
		if not raw is Array and row.has("depth_sort_foot_y"):foot.y=float(row.depth_sort_foot_y)*AUTHOR.WORLD_SIZE.y
		if AUTHOR.is_sea(foot):
			var id: String=String(row.get("id",""))
			if id.begins_with("compound_") or id.begins_with("bridge_"):_error="PROTECTED_OBJECT_IN_NEW_WATER: "+id;return false
			_retired.append(id)
		else:kept.append(row)
	_layout.visual_objects=kept
	# V15's object solids are owned by their exact visual rows. No separate
	# blockers exist in this baseline; refuse instead of guessing an ID mapping.
	if not _layout.blockers.is_empty():_error="UNEXPECTED_SEPARATE_BLOCKERS_REQUIRE_EXPLICIT_MAPPING";return false
	return true

func _collect_ports() -> void:
	for row: Dictionary in _layout.portals:
		_all_ports.append({"id":String(row.id),"target_scene":String(row.get("target_scene","")),"world_foot":[row.pos.x*12288,row.pos.y*8192],"origin":"ORIGINAL16"})
	var towns: Variant=load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	var adventures: Variant=load("res://build/adventure_world_20261031f_system01/world_links.gd")
	for rows: Array in [towns.portal_rows(),adventures.portal_rows()]:
		for row: Dictionary in rows:_all_ports.append({"id":String(row.id),"target_scene":String(row.target_scene),"world_foot":[row.world_foot.x,row.world_foot.y],"origin":"RUNTIME6"})
	_pin("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	_pin("res://build/adventure_world_20261031f_system01/world_links.gd")

func _bridge_and_door_protection() -> bool:
	for row: Dictionary in _all_ports:
		var p:=Vector2(row.world_foot[0],row.world_foot[1])
		if AUTHOR.sea_distance(p)>-48:_error="PROTECTED_DOOR_NEAR_CARVE: "+String(row.id);return false
	return true

func _make_native_world(mesh: ArrayMesh) -> bool:
	_terrain=(load(BASE+"capture/primary/actual_terrain_material.res") as ShaderMaterial).duplicate(false) as ShaderMaterial
	_water=(load(BASE+"capture/primary/actual_water_material.res") as ShaderMaterial).duplicate(false) as ShaderMaterial
	if _terrain==null or _water==null:_error="PINNED_ACTUAL_NATIVE_MATERIAL_LOAD";return false
	var rf:=Image.create_from_data(1537,1025,false,Image.FORMAT_RF,_new_heights.to_byte_array())
	_rf_texture=ImageTexture.create_from_image(rf)
	_water.set_shader_parameter("actual_height_rf",_rf_texture)
	_water.set_shader_parameter("grid_origin",Vector2i.ZERO);_water.set_shader_parameter("grid_shape",AUTHOR.GRID_SIZE)
	_view3=SubViewport.new();_view3.own_world_3d=true;_view3.msaa_3d=Viewport.MSAA_DISABLED;_view3.transparent_bg=false
	_view3.process_mode=Node.PROCESS_MODE_ALWAYS;_view3.render_target_update_mode=SubViewport.UPDATE_DISABLED;root.add_child(_view3)
	var world:=Node3D.new();_view3.add_child(world)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color.BLACK
	var recipe: Variant=load("res://scripts/dev/world_map_v15_complete_v5_surface.gd").new()
	_pin("res://scripts/dev/world_map_v15_complete_v5_surface.gd")
	environment.environment=recipe.environment();world.add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-34,0);sun.light_energy=.85;sun.shadow_enabled=false;world.add_child(sun)
	_receiver=MeshInstance3D.new();_receiver.mesh=mesh;_receiver.material_override=_terrain;world.add_child(_receiver)
	_water_node=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=AUTHOR.WORLD_SIZE/Vector2(AUTHOR.PPM,AUTHOR.Z_PPM)
	_water_node.mesh=plane;_water_node.position.y=AUTHOR.WATER_Y;_water_node.material_override=_water;world.add_child(_water_node)
	_camera=Camera3D.new();_camera.projection=Camera3D.PROJECTION_ORTHOGONAL;_camera.keep_aspect=Camera3D.KEEP_HEIGHT;_camera.near=.05;_camera.far=200;world.add_child(_camera);_camera.current=true
	_land=ShaderMaterial.new();_land.shader=load(ROOT+"native_land.gdshader")
	# The land pass must have a genuinely black background, not sky-coloured NAV.
	_view3.set_meta("environment",environment)
	return true

func _capture_native(rect: Rect2) -> Dictionary:
	var canvas: Rect2=rect.grow(AUTHOR.HALO)
	if canvas.size.x*canvas.size.y>8404992:_error="CPU_ROI_BUDGET";return {}
	_view3.size=Vector2i(canvas.size);_camera.size=canvas.size.y/AUTHOR.PPM
	var target: Vector3=AUTHOR.point3(canvas.get_center(),0)
	_camera.position=target+Vector3(0,60,60);_camera.look_at(target)
	_receiver.material_override=_terrain;_water_node.visible=true
	var env: WorldEnvironment=_view3.get_meta("environment")
	env.environment.background_mode=Environment.BG_SKY
	_view3.render_target_update_mode=SubViewport.UPDATE_ONCE
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var visual: Image=_view3.get_texture().get_image().get_region(Rect2i(Vector2i.ONE*int(AUTHOR.HALO),Vector2i(rect.size)))
	_receiver.material_override=_land;_water_node.visible=false;env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color.BLACK
	_view3.render_target_update_mode=SubViewport.UPDATE_ONCE
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var land: Image=_view3.get_texture().get_image().get_region(Rect2i(Vector2i.ONE*int(AUTHOR.HALO),Vector2i(rect.size)))
	return {"visual":visual,"land":land}

func _image_texture(path: String) -> ImageTexture:
	if not path.begins_with(OUT):_pin(path)
	var image: Image=Image.load_from_file(path)
	if image==null or image.is_empty():return null
	return ImageTexture.create_from_image(image)

func _composite(rect: Rect2,old: Texture2D,fresh: Texture2D,mode: int) -> Image:
	if old==null or fresh==null:return null
	var viewport:=SubViewport.new();viewport.size=Vector2i(rect.size);viewport.disable_3d=true;viewport.process_mode=Node.PROCESS_MODE_ALWAYS;viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	root.add_child(viewport)
	var node:=ColorRect.new();node.size=rect.size
	var material:=ShaderMaterial.new();material.shader=load(ROOT+"coast_composite.gdshader")
	material.set_shader_parameter("baseline",old);material.set_shader_parameter("native_image",fresh);material.set_shader_parameter("canvas_origin",rect.position);material.set_shader_parameter("canvas_size",rect.size);material.set_shader_parameter("mode",mode)
	material.set_shader_parameter("bay",AUTHOR.outer_bay());material.set_shader_parameter("island",AUTHOR.island())
	node.material=material;viewport.add_child(node)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var result: Image=viewport.get_texture().get_image();viewport.queue_free();return result

func _build_overview() -> bool:
	# One 3072x2048 GPU frame; unchanged regions remain the exact effective
	# reviewed overview. Only changed cells are rendered over it from new chunks.
	var viewport:=SubViewport.new();viewport.size=Vector2i(3072,2048);viewport.disable_3d=true;viewport.process_mode=Node.PROCESS_MODE_ALWAYS;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;root.add_child(viewport)
	var baseline_scene: SceneScript=load(SCENE) as SceneScript
	var old_overview: String=FARMLAND.overview_path(baseline_scene);_pin(old_overview)
	var back:=Sprite2D.new();back.texture=_image_texture(old_overview);back.centered=false;viewport.add_child(back)
	for cell: Dictionary in _changed:
		var rect:=Rect2(cell.logical_rect[0],cell.logical_rect[1],1536,1024)
		var cell_view:=SubViewport.new();cell_view.size=Vector2i(1536,1024);cell_view.disable_3d=true;cell_view.process_mode=Node.PROCESS_MODE_ALWAYS;cell_view.render_target_update_mode=SubViewport.UPDATE_ONCE;root.add_child(cell_view)
		var terrain:=Sprite2D.new();terrain.texture=_image_texture(cell.visual_path);terrain.centered=false;cell_view.add_child(terrain)
		for row: Dictionary in _layout.visual_objects:
			var size: Vector2=row.get("render_size_px",Vector2.ZERO);var pos: Vector2=Vector2(row.get("pos",Vector2.ZERO))*AUTHOR.WORLD_SIZE
			var draw_rect:=Rect2(pos-(size*.5 if bool(row.get("centered",true)) else Vector2.ZERO),size)
			if not draw_rect.intersects(rect):continue
			var sprite:=Sprite2D.new();sprite.texture=_image_texture(String(row.get("texture","")))
			if sprite.texture==null:continue
			sprite.centered=bool(row.get("centered",true));sprite.position=pos-rect.position
			sprite.scale=size/sprite.texture.get_size();sprite.z_index=clampi(int(float(row.get("depth_sort_foot_y",0))*8192/8),0,4095);cell_view.add_child(sprite)
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		var stamp:=Sprite2D.new();stamp.texture=ImageTexture.create_from_image(cell_view.get_texture().get_image());stamp.centered=false;stamp.position=rect.position*.25;stamp.scale=Vector2.ONE*.25;viewport.add_child(stamp);cell_view.queue_free()
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var image: Image=viewport.get_texture().get_image();viewport.queue_free()
	if image.save_png(OUT+"overview.png")!=OK:_error="OVERVIEW_WRITE";return false
	return true

func _ports_safe() -> bool:
	var images: Dictionary={}
	for row: Dictionary in _all_ports:
		images.clear()
		var foot:=Vector2(row.world_foot[0],row.world_foot[1])
		for y: int in range(-12,13):
			for x: int in range(-17,18):
				var p: Vector2=foot+Vector2(x,y);var col:=floori(p.x/1536);var r:=floori(p.y/1024);var index: int=r*8+col
				if index<0 or index>=64:_error="PORT_OUTSIDE_WORLD";return false
				if not images.has(index):images[index]=Image.load_from_file(_navigation[index].path)
				var image: Image=images[index]
				if image.get_pixel(floori(p.x)-col*1536,floori(p.y)-r*1024).r<=.5:_error="PORT_FULL_FOOT_NAV_REJECTED: "+String(row.id);return false
	return true

func _rect_array(rect: Rect2) -> Array:return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]

func _write_json(path: String,value: Dictionary) -> bool:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify(value,"\t")+"\n");file.close();return true
