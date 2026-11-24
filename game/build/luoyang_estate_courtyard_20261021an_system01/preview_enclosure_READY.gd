extends SceneTree
## ROOT-only whole actual95 Sprite preview. Does not republish or run geometry.
const E=preload("res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const HERE="res://build/luoyang_estate_courtyard_20261021an_system01/"
const NATIVE=HERE+"native_candidate/"
const REPORT=HERE+"geometry/120540/result.json"
const REPORT_SHA="e5cdbd812293266d16c4b2a4357eb308bf7ca9467cb824b3cc2316847d219625"
const VIEW=Vector2i(1536,1024)
var error: String=""
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	if not ok and error.is_empty(): error=label;push_error("AN_PREVIEW "+label)
	return ok
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);var began: int=Time.get_ticks_msec()
	if not need(OS.get_cmdline_user_args().is_empty() and FileAccess.get_sha256(REPORT)==REPORT_SHA,"EXACT_NEW_GEOMETRY_REPORT"): quit(1);return
	var proof: Dictionary=E.json(REPORT)
	if not need(proof.get("passed")==true and proof.get("whole_parent_inverse")==true and proof.get("source_first")==proof.get("source_final") and proof.get("visual_rows")==95 and proof.get("physical_rectangles")==32,"ACTUAL95_VISUAL32_RECT_PARENT"): quit(1);return
	for path: String in proof.source_first:
		if not need(FileAccess.get_sha256(path)==proof.source_first[path],"SOURCE_FIRST:"+path): quit(1);return
	for path: String in proof.artifacts:
		if not need(FileAccess.get_sha256(path)==proof.artifacts[path],"ACTUAL_NATIVE:"+path): quit(1);return
	var packet: Variant=bytes_to_var(FileAccess.get_file_as_bytes(NATIVE+"packet.bin"))
	var scene:=ResourceLoader.load(NATIVE+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(packet is Dictionary and scene!=null and B.equal(B.storage(scene),packet.scene_storage) and B.equal(B.storage(scene.map_layout),packet.layout_storage) and scene.map_layout.visual_objects.size()==95,"FULL_ACTUAL_NATIVE_STORAGE"): quit(1);return
	var viewport:=SubViewport.new();viewport.size=VIEW;viewport.disable_3d=true;viewport.transparent_bg=false;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var world:=Node2D.new();world.scale=Vector2(.5,.5);viewport.add_child(world);var count: int=0
	for row: Dictionary in scene.map_layout.visual_objects:
		var texture: Variant
		if String(row.texture).begins_with("res://build/") and String(row.texture).ends_with(".png"):
			var raw: Image=Image.load_from_file(row.texture)
			if not need(raw!=null,"EXACT_CANDIDATE_RAW_TEXTURE:"+String(row.texture)): break
			texture=ImageTexture.create_from_image(raw)
		else: texture=load(row.texture)
		if not need(texture is Texture2D,"ACTUAL_NATIVE_TEXTURE:"+String(row.texture)): break
		var sprite:=Sprite2D.new();sprite.name=String(row.id);sprite.texture=texture;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;sprite.centered=true
		sprite.position=row.pos*E.SIZE;sprite.scale=row.render_size_px/Vector2(texture.get_size());sprite.rotation_degrees=float(row.get("rotation",0))
		sprite.z_index=floori(float(row.depth_sort_foot_y)*2048.0/8.0) if row.get("sort_by_feet",false) else int(row.get("z_index",0))
		if row.get("modulate") is Color: sprite.modulate=row.modulate
		world.add_child(sprite);count+=1
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image=viewport.get_texture().get_image();var dir: String=HERE+"preview/"+str(OS.get_process_id())+"/"
	if not need(error.is_empty() and image!=null and image.get_size()==VIEW and count==95 and not DirAccess.dir_exists_absolute(dir) and DirAccess.make_dir_recursive_absolute(dir)==OK,"NEW_WHOLE_NATIVE_HALF_SCALE_IMAGE"): viewport.queue_free();quit(1);return
	var path: String=dir+"estate_enclosure_actual_native_sprites.png"
	if not need(image.save_png(path)==OK,"NEW_IMAGE_SAVE"): viewport.queue_free();quit(1);return
	var final: Dictionary={}
	for source: String in proof.source_first:
		final[source]=FileAccess.get_sha256(source);need(final[source]==proof.source_first[source],"SOURCE_FINAL:"+source)
	var result: Dictionary={"passed":error.is_empty(),"error":error,"geometry_report":REPORT,"geometry_report_sha256":REPORT_SHA,"source_first":proof.source_first,"source_final":final,"image":path,"image_sha256":FileAccess.get_sha256(path),"sprites":count,"physical_rectangles_inherited":32,"viewport_size":[1536,1024],"native_crop":[0,0,3072,2048],"uniform_native_scale":.5,"elapsed_ms":Time.get_ticks_msec()-began,"geometry_rerun":false,"scope":"WHOLE_ACTUAL_NATIVE95_SPRITES_NOT_FIELD_OR_PLAYER_INPUT_OR_FORMAL_TRAVEL","not_claimed":["art acceptance before Root whole view","actual Field input or Physics","formal Router trip or room return","new media import or loading improvement"]}
	var file:=FileAccess.open(dir+"result.json",FileAccess.WRITE)
	if file==null: viewport.queue_free();quit(1);return
	file.store_string(JSON.stringify(result,"\t",true,true));file.close();viewport.queue_free()
	print(JSON.stringify({"path":dir+"result.json","passed":result.passed}));quit(0 if result.passed else 1)
