extends "res://tests/test_luoyang_ap_garden_native_overview_READY_20261022ap.gd"
## One image-only visual successor. D906 geometry and the original image remain immutable.
const SHORE_FIXTURE: String="res://build/luoyang_city_full_rollout_20261022ap_qa01/garden_shore_visual_overview_exact_READY.json"
const SHORE_FIXTURE_SHA: String="e4fdc39c8ea647cf05dda128708c82cc8287e54c96af9d68d662c355c681a96d"
var shore_fixed: Dictionary={}
var shore_actual: Dictionary={}

func precheck() -> bool:
	if not super.precheck() or not track(SHORE_FIXTURE,SHORE_FIXTURE_SHA): return false
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(SHORE_FIXTURE))
	if not check(parsed is Dictionary and parsed.get("schema")=="AP_GARDEN_SHORE_VISUAL_OVERVIEW_SUCCESSOR_V1" and parsed.get("status")=="READY_FOR_ROOT_SINGLE_IMAGE_NOT_FIELD" and parsed.get("limit_ms")==30000,"Frozen one-image pure visual successor"): return false
	shore_fixed=parsed
	if not check(shore_fixed.base_fixture_path==FIXTURE and shore_fixed.base_fixture_sha256==FIXTURE_SHA and shore_fixed.expected_tiles==37 and shore_fixed.expected_segments==19 and shore_fixed.expected_water_and_shore_nodes==39,"No changed base fixture/native/geometry scope"): return false
	if not track(shore_fixed.base_test_path,shore_fixed.base_test_sha256) or not track(shore_fixed.successor_receipt_path,shore_fixed.successor_receipt_sha256) or not track(shore_fixed.helper_path,shore_fixed.helper_sha256): return false
	var receipt: Variant=JSON.parse_string(FileAccess.get_file_as_string(shore_fixed.successor_receipt_path))
	if not check(receipt is Dictionary and receipt.get("candidate_path")==shore_fixed.helper_path and receipt.get("candidate_sha256")==shore_fixed.helper_sha256 and receipt.get("parent_path")==fixed.water_helper_path and receipt.get("parent_sha256")==fixed.water_helper_sha256 and receipt.get("whole_source_inverse")==true and b.equal(receipt.get("fixed_texture_source_sha256"),shore_fixed.media_sha256),"Exact declared visual-only predecessor and three unchanged media leaves"): return false
	for path: String in shore_fixed.media_sha256:
		if not check(not fixed.publication_sources.has(path) and not fixed.additional_render_source_sha256.has(path),"Only explicitly additional render media, no historical source backfill "+path) or not track(path,shore_fixed.media_sha256[path]): return false
	fixed.additional_render_source_sha256.merge(shore_fixed.media_sha256)
	fixed.water_helper_path=shore_fixed.helper_path
	fixed.water_helper_sha256=shore_fixed.helper_sha256
	return true

func _build_props() -> bool:
	# Original54-prop renderer, with canvas transform set only after real canvas
	# creation inside the tree. This ordering avoids the old canvas_map setup ERROR.
	view=SubViewport.new();view.name="APNativeArtProbe";view.size=Vector2i(1920,1280)
	view.disable_3d=true;view.world_2d=World2D.new();view.transparent_bg=false
	view.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	root.add_child(view)
	view.canvas_transform=Transform2D(Vector2(.625,0),Vector2(0,.625),Vector2.ZERO)
	world=Node2D.new();world.name="ActualWorldScaleOne";view.add_child(world)
	var background: Texture2D=_texture(native_scene.background_path)
	if background==null: return false
	var floor_sprite:=Sprite2D.new();floor_sprite.name="PublishedBackground";floor_sprite.texture=background;floor_sprite.centered=false;floor_sprite.scale=SIZE/Vector2(background.get_size());floor_sprite.z_index=-1000
	world.add_child(floor_sprite)
	var seen: Dictionary={}
	for data: Dictionary in native_layout.visual_objects:
		var id: String=String(data.get("id",""))
		if not check(not id.is_empty() and not seen.has(id) and data.get("pos") is Vector2 and data.get("render_size_px") is Vector2,"Exact typed authored visual identity/position/render size"): return false
		seen[id]=true
		var prop_texture: Texture2D=_texture(String(data.texture))
		if prop_texture==null: return false
		var prop:=Sprite2D.new();prop.name="SceneObject_"+id;prop.texture=prop_texture;prop.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		prop.centered=bool(data.get("centered",true));prop.position=data.pos*SIZE
		prop.scale=data.render_size_px/Vector2(prop_texture.get_size());prop.rotation_degrees=float(data.get("rotation",0.0));prop.z_index=int(data.get("z_index",0))
		if data.get("modulate") is Color: prop.modulate=data.modulate
		if data.get("sort_by_feet",false):
			if not check(data.has("depth_sort_foot_y"),"Authored sort foot exists "+id): return false
			prop.z_index=clampi(int(floor(clampf(float(data.depth_sort_foot_y),0.0,1.0)*SIZE.y/8.0)),0,255)
		world.add_child(prop)
		rendered.append({"id":id,"position":prop.position,"render_size_px":data.render_size_px,"scale":prop.scale,"z_index":prop.z_index,"texture":String(data.texture)})
	var water_api: Script=load(fixed.water_helper_path) as Script
	if not check(water_api!=null and water_api.can_instantiate(),"Fixed pure water visual constructor loads"): return false
	var constructed: Dictionary=water_api.make_garden_water_visual(native_scene,native_layout.blockers)
	if not check(constructed.get("ok")==true and constructed.get("node") is Polygon2D,"Same native water visual constructor, not Field install"): return false
	var water_node: Polygon2D=constructed.node
	var water_meta: Dictionary=native_scene.get_meta("ap_garden_scenic_water",{})
	if not check(b.equal(water_node.polygon,water_meta.get("polygon")) and water_node.z_index==-18 and water_node.texture.resource_path==fixed.water_visual_expected.texture and water_node.get_meta("ap_scenic_water").water_rgba_sha256==fixed.water_visual_expected.rgba_sha256,"Exact published water polygon/texture/scale/depth receipt"): water_node.free();return false
	world.add_child(water_node)
	records.append({"kind":"AP_NATIVE_GARDEN_WATER_VISUAL","native_polygon":water_node.polygon,"z_index":water_node.z_index,"texture":fixed.water_visual_expected.texture,"rgba_sha256":fixed.water_visual_expected.rgba_sha256,"Physics_install_called":false,"Field_owner_fabricated":false,"no_bridge_positive_support":true})
	if not check(rendered.size()==54 and rendered.size()==fixed.expected.visuals,"All54 actual native visual rows rendered once"): return false
	var water: Polygon2D=world.get_node_or_null("APGardenSameCaptureWater") as Polygon2D
	var shore: Node2D=water.get_node_or_null("APGardenShoreVisualOnly") as Node2D if water!=null else null
	if not check(water!=null and shore!=null and water.get_child_count()==1 and shore.get_child_count()==37,"One original water Polygon with one pure shore group and37 tiles"): return false
	var api: Variant=load(shore_fixed.helper_path)
	if not check(api.SHORE_POSES.size()==37 and api.SHORE_WATER_POLYGON.size()==19 and b.equal(api.SHORE_SOURCE_SHA,shore_fixed.media_sha256),"Exact frozen tile poses/native19 boundary declarations"): return false
	var texture: Texture2D=_texture(api.SHORE_TEXTURE)
	if not check(texture!=null and texture.get_size()==Vector2(320,100),"Same complete320x100 source; no crop/pixel edit/import"): return false
	var segments: Dictionary={}
	for i: int in range(37):
		var pose: Array=api.SHORE_POSES[i]
		var sprite: Sprite2D=shore.get_child(i) as Sprite2D
		# Independent setter/getter encoding, fixed source angle only. Never read
		# an actual tile to construct the expected value; no floating epsilon.
		var expected_encoding:=Node2D.new()
		expected_encoding.rotation=float(pose[1])
		var expected_rotation: float=expected_encoding.rotation
		expected_encoding.free()
		if not check(sprite!=null and sprite.name=="Shore_%02d_%02d"%[pose[2],pose[3]] and sprite.texture==texture and sprite.centered==false and sprite.offset==Vector2(-160,-75) and sprite.scale==Vector2(.5,.5) and sprite.position==pose[0] and sprite.rotation==expected_rotation and sprite.z_index==1 and sprite.get_meta("ap_visual_only",false)==true and sprite.get_meta("native_water_segment",-1)==pose[2],"Exact full-source uniform tile and visual-only owner "+str(i)): return false
		segments[int(pose[2])]=true
	if not check(segments.size()==19 and b.equal(shore.get_meta("ap_shore_receipt",{}),{"tiles":37,"native_segments":19,"uniform_scale":.5,"source_boundary_y":75,"stone_water_side":12.5,"grass_land_side":37.5,"no_geometry_delta":true,"no_positive_support":true,"no_image_edit_or_crop":true}),"All19 native water segments covered once by fixed37 visual tiles; no walk support"): return false
	shore_actual={"tiles":37,"native_segments":19,"water_group_tile_nodes":39,"helper":shore_fixed.helper_path,"helper_sha256":shore_fixed.helper_sha256,"render_media":shore_fixed.media_sha256,"source_complete":Vector2i(320,100),"uniform_scale":.5,"offset":Vector2(-160,-75),"no_geometry_or_mask_delta":true,"no_Physics_Field_portal_credit":true}
	records.append({"kind":"AP_GARDEN_VISUAL_SHORE_SUCCESSOR", "actual":shore_actual})
	return true

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+LIMIT_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_city_full_rollout_20261022ap_qa01/garden_shore_visual_overview/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=false
	if precheck(): complete=await _probe()
	if is_instance_valid(view): view.queue_free()
	await process_frame;await process_frame
	world=null;view=null;textures.clear();native_scene=null;native_layout=null;packet.clear();scene_before.clear();layout_before.clear();b=null
	finish(folder,began,complete,"AP_GARDEN_ONE_SHORE_VISUAL_SUCCESSOR_FIT0625_NOT_FIELD_NAV_OR_FORMAL_30S")
