extends SceneTree
## ROOT-only actual native Sprite preview after one AK geometry publication.
const E=preload("res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const HERE="res://build/luoyang_estate_courtyard_20261021ak_system01/"
const NATIVE=HERE+"native_candidate/"
const GEOMETRY_REPORT="PENDING_ROOT_ACTUAL_AK_GEOMETRY_REPORT"
const GEOMETRY_SHA="PENDING_ROOT_ACTUAL_AK_GEOMETRY_SHA"
const VIEW=Vector2i(1536,1024)
var error: String=""
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	if not ok and error.is_empty(): error=label;push_error("AK_PREVIEW "+label)
	return ok
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var began: int=Time.get_ticks_msec()
	if not need(OS.get_cmdline_user_args().is_empty() and GEOMETRY_REPORT.begins_with(HERE+"geometry/") and GEOMETRY_SHA.length()==64 and FileAccess.get_sha256(GEOMETRY_REPORT)==GEOMETRY_SHA,"EXACT_AK_ACTUAL_REPORT_REQUIRED"): quit(1);return
	var proof: Dictionary=E.json(GEOMETRY_REPORT)
	if not need(proof.get("passed")==true and proof.get("parent_inverse")==true and proof.get("source_first")==proof.get("source_final"),"ACTUAL_INCREMENTAL_GEOMETRY_AND_PARENT_INVERSE"): quit(1);return
	for path: String in proof.source_first:
		if not need(FileAccess.get_sha256(path)==proof.source_first[path],"PRIOR_SOURCE:"+path): quit(1);return
	for path: String in proof.artifacts:
		if not need(FileAccess.get_sha256(path)==proof.artifacts[path],"ACTUAL_NATIVE:"+path): quit(1);return
	var packet: Variant=bytes_to_var(FileAccess.get_file_as_bytes(NATIVE+"packet.bin"))
	var scene:=ResourceLoader.load(NATIVE+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(packet is Dictionary and scene!=null and B.equal(B.storage(scene),packet.scene_storage) and B.equal(B.storage(scene.map_layout),packet.layout_storage) and scene.map_layout.visual_objects.size()==62,"COMPLETE_ACTUAL_NATIVE62_STORAGE"): quit(1);return
	var viewport:=SubViewport.new();viewport.size=VIEW;viewport.disable_3d=true;viewport.transparent_bg=false
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var world:=Node2D.new();world.scale=Vector2(.5,.5);viewport.add_child(world)
	var count: int=0
	for row: Dictionary in scene.map_layout.visual_objects:
		var texture: Variant
		if String(row.id).begins_with("estate_ak_"):
			var raw: Image=Image.load_from_file(row.texture)
			if not need(raw!=null,"EXACT_NEW_RAW_IMAGE:"+String(row.texture)): viewport.queue_free();quit(1);return
			texture=ImageTexture.create_from_image(raw)
		else: texture=load(row.texture)
		if not need(texture is Texture2D,"ACTUAL_ASSET:"+String(row.texture)): viewport.queue_free();quit(1);return
		var sprite:=Sprite2D.new();sprite.name=String(row.id);sprite.texture=texture;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.centered=true;sprite.position=row.pos*E.SIZE;sprite.scale=row.render_size_px/Vector2(texture.get_size())
		sprite.z_index=int(floor(float(row.depth_sort_foot_y)*2048.0/8.0)) if row.get("sort_by_feet",false) else int(row.get("z_index",0))
		world.add_child(sprite);count+=1
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image=viewport.get_texture().get_image()
	if not need(image!=null and image.get_size()==VIEW and count==62,"FULL_NATIVE_HALF_SCALE_1536X1024"): viewport.queue_free();quit(1);return
	var dir: String=HERE+"preview/"+str(OS.get_process_id())+"/"
	if not need(not DirAccess.dir_exists_absolute(dir) and DirAccess.make_dir_recursive_absolute(dir)==OK,"NEW_PREVIEW_OUTPUT"): viewport.queue_free();quit(1);return
	var path: String=dir+"estate_architecture_actual_sprites.png"
	if not need(image.save_png(path)==OK,"NEW_ACTUAL_SPRITE_PNG"): viewport.queue_free();quit(1);return
	for source: String in proof.source_first:
		need(FileAccess.get_sha256(source)==proof.source_first[source],"SOURCE_FINAL:"+source)
	var result: Dictionary={"passed":error.is_empty(),"error":error,"geometry_report":GEOMETRY_REPORT,"geometry_report_sha256":GEOMETRY_SHA,"image":path,"image_sha256":FileAccess.get_sha256(path),"sprites":count,"viewport_size":[1536,1024],"native_crop":[0,0,3072,2048],"uniform_preview_scale":.5,"elapsed_ms":Time.get_ticks_msec()-began,"new5_texture_method":"exact_candidate_raw_ImageTexture_no_import_credit","scope":"EXACT_CANDIDATE_NATIVE_SPRITES_NOT_FIELD_OR_NPC_OR_CONNECTED_PORTAL_TRIP","not_claimed":["formal map deployment","new3_texture_formal_import","full garden art","actual avatar occlusion/Physics","room return trip","NPC dialogue or audio","loading improvement"]}
	var file:=FileAccess.open(dir+"result.json",FileAccess.WRITE)
	if file==null: viewport.queue_free();quit(1);return
	file.store_string(JSON.stringify(result,"\t",true,true));file.close()
	viewport.queue_free();print(JSON.stringify(result));quit(0 if result.passed else 1)
