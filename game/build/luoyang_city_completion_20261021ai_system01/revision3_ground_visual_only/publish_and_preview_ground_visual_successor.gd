extends SceneTree
## ROOT only: new visual-only native candidate and actual Sprite preview.
## Never rerasterizes or resamples the already accepted 2226-point geometry.
const E=preload("res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const HERE="res://build/luoyang_city_completion_20261021ai_system01/revision3_ground_visual_only/"
const OUTPUT=HERE+"native_candidate/"
const GEOMETRY_REPORT="res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/geometry/114084/result.json"
const GEOMETRY_SHA="91c95216c2e422fa7389ef291683dd25fe1d499acd369d80b941367be5bb88af"
const WALK="res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/publication_assets/estate_walk_candidate.png"
const TILE384=HERE+"stone_square_384.tres"
const TILE64=HERE+"stone_square_64.tres"
const CROP=Rect2(480,480,2112,1408)
const VIEW=Vector2i(1280,854)
var error: String=""
var pins: Dictionary={}
var began: int=0
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	if not ok and error.is_empty(): error=label;push_error("AI_VISUAL_ONLY "+label)
	return ok
func track(path: String,expected: String="") -> bool:
	var hash: String=FileAccess.get_sha256(path)
	if not need(path.begins_with("res://") and ".." not in path and hash.length()==64 and (expected.is_empty() or hash==expected) and (not pins.has(path) or pins[path]==hash),"SOURCE:"+path): return false
	pins[path]=hash;return true
func tile(id: String,texture: String,center: Vector2,size: Vector2) -> Dictionary:
	return {"id":id,"texture":texture,"pos":center/E.SIZE,"render_size_px":size,"sort_by_feet":false,"z_index":-9}
func save_json(path: String,data: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(data,"\t",true,true));file.close();return true
func derive() -> Dictionary:
	if not need(OS.get_cmdline_user_args().is_empty() and track(GEOMETRY_REPORT,GEOMETRY_SHA),"FIXED_ACTUAL_RECEIPT_NO_ARGS"): return {}
	var prior: Dictionary=E.json(GEOMETRY_REPORT)
	if not need(prior.get("passed")==true and prior.get("source_first")==prior.get("source_final") and prior.get("geometry",{}).get("samples")==2226 and prior.get("geometry",{}).get("rectangular_solids")==6,"ACTUAL_GEOMETRY_2226_SIX_REUSED_NOT_RERUN"): return {}
	for path: String in prior.source_first:
		if not track(path,prior.source_first[path]): return {}
	for path: String in prior.artifacts:
		if not track(path,prior.artifacts[path]): return {}
	if not track(WALK,prior.walk_candidate.sha256): return {}
	for path: String in [get_script().resource_path,TILE384,TILE64]:
		if not track(path): return {}
	for path: String in [TILE384,TILE64]:
		var texture: Variant=load(path)
		var length: float=384.0 if path==TILE384 else 64.0
		if not need(texture is AtlasTexture and texture.atlas.resource_path=="res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png" and texture.region.size==Vector2(length,length) and texture.get_size()==Vector2(length,length),"SQUARE_NATIVE_ATLAS_NO_ANISOTROPIC_SCALE"): return {}
	var old_packet: Variant=bytes_to_var(FileAccess.get_file_as_bytes(E.ROOT+"packet.bin"))
	var scene:=ResourceLoader.load(E.ROOT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(old_packet is Dictionary and scene!=null and B.equal(B.storage(scene),old_packet.scene_storage) and B.equal(B.storage(scene.map_layout),old_packet.layout_storage),"OLD_NATIVE_WHOLE_STORAGE"): return {}
	var old_visual: Array[Dictionary]=scene.map_layout.visual_objects.duplicate(true)
	if not need(old_visual.size()==13 and old_visual[6].id=="estate_stone_path_0" and old_visual[7].id=="estate_stone_path_1","EXACT_TWO_OLD_GROUND_ROWS"): return {}
	var visual: Array[Dictionary]=[]
	for i: int in 6: visual.append(old_visual[i].duplicate(true))
	# Two native 384x384 squares: width384, y1216..1984. No stretched stone.
	for y: int in 2: visual.append(tile("estate_ground_v2_path_"+str(y),TILE384,Vector2(1536,1408+y*384),Vector2(384,384)))
	# Forecourt x1184..1888 / y1120..1376: 11x4 actual64px square tiles.
	for y: int in 4:
		for x: int in 11: visual.append(tile("estate_ground_v2_court_"+str(x)+"_"+str(y),TILE64,Vector2(1216+x*64,1152+y*64),Vector2(64,64)))
	for i: int in range(8,13): visual.append(old_visual[i].duplicate(true))
	scene.map_layout.visual_objects=visual
	var storage: Dictionary={"scene":B.storage(scene),"layout":B.storage(scene.map_layout)}
	# Independent typed whole inverse: restore only the original visual array.
	scene.map_layout.visual_objects=old_visual
	if not need(B.equal(B.storage(scene),old_packet.scene_storage) and B.equal(B.storage(scene.map_layout),old_packet.layout_storage),"ENTIRE_SCENE_LAYOUT_VISUAL_ONLY_INVERSE"): return {}
	scene.map_layout.visual_objects=visual
	var packet: Dictionary=old_packet.duplicate(true)
	packet.scene_storage=storage.scene;packet.layout_storage=storage.layout
	packet.visual_only_successor={"parent_packet":E.ROOT+"packet.bin","parent_sha256":prior.artifacts[E.ROOT+"packet.bin"],"only_removed_ids":["estate_stone_path_0","estate_stone_path_1"],"added_ground_rows":46,"main_path_width":384,"forecourt_size":[704,256],"source_native_square_no_nonuniform_scale":true,"geometry_receipt":GEOMETRY_REPORT,"geometry_receipt_sha256":GEOMETRY_SHA,"geometry_rerun":false}
	var inverse: Dictionary=packet.duplicate(true)
	inverse.scene_storage=old_packet.scene_storage;inverse.layout_storage=old_packet.layout_storage;inverse.erase("visual_only_successor")
	if not need(B.equal(inverse,old_packet) and B.equal(packet.rectangular_solids,old_packet.rectangular_solids) and packet.walk_bytes==old_packet.walk_bytes and B.equal(packet.geometry,old_packet.geometry) and B.equal(packet.alpha,old_packet.alpha),"ENTIRE_PACKET_INVERSE_MASK_SIX_RECTS_FOUR_ROUTES_ALPHA_UNCHANGED"): return {}
	if not need(not DirAccess.dir_exists_absolute(OUTPUT) and DirAccess.make_dir_recursive_absolute(OUTPUT)==OK,"NEW_NATIVE_OUTPUT_ONLY"): return {}
	if not need(ResourceSaver.save(scene.map_layout,OUTPUT+"layout.res")==OK,"SAVE_NEW_LAYOUT"): return {}
	scene.map_layout=ResourceLoader.load(OUTPUT+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(scene.map_layout!=null and ResourceSaver.save(scene,OUTPUT+"scene.res")==OK,"SAVE_NEW_SCENE"): return {}
	var file:=FileAccess.open(OUTPUT+"packet.bin",FileAccess.WRITE)
	if not need(file!=null,"NEW_PACKET_WRITE"): return {}
	file.store_buffer(var_to_bytes(packet));file.close()
	var reread:=ResourceLoader.load(OUTPUT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(reread!=null and B.equal(B.storage(reread),storage.scene) and B.equal(B.storage(reread.map_layout),storage.layout) and B.equal(bytes_to_var(FileAccess.get_file_as_bytes(OUTPUT+"packet.bin")),packet),"NEW_NATIVE_AND_PACKET_COMPLETE_READBACK"): return {}
	var artifacts: Dictionary={}
	for name: String in ["scene.res","layout.res","packet.bin"]: artifacts[OUTPUT+name]=FileAccess.get_sha256(OUTPUT+name)
	return {"published":true,"artifacts":artifacts,"scene":reread,"visual_rows":visual.size(),"geometry_reused_samples":2226,"geometry_rerun":false,"full_inverse":true,"original_11_grass_prop_rows_unchanged":true,"mask_png_not_written_or_imported":true,"main_path":{"width":384,"bounds":[1344,1216,384,768]},"forecourt":{"bounds":[1184,1120,704,256],"square_tile_size":64},"scope":"VISUAL_GROUND_ONLY_CANDIDATE_NOT_FIELD_OR_FORMAL_ART"}
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	began=Time.get_ticks_msec()
	var result: Dictionary=derive()
	var scene: SceneScript=result.get("scene") as SceneScript
	result.erase("scene")
	if scene!=null and error.is_empty():
		var viewport:=SubViewport.new();viewport.size=VIEW;viewport.disable_3d=true;viewport.transparent_bg=false
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
		var world:=Node2D.new();world.scale=Vector2.ONE*(float(VIEW.x)/CROP.size.x);world.position=-CROP.position*world.scale;viewport.add_child(world)
		var count: int=0
		for row: Dictionary in scene.map_layout.visual_objects:
			var texture: Variant=load(row.texture)
			if not need(texture is Texture2D,"ACTUAL_TEXTURE:"+String(row.texture)): break
			var sprite:=Sprite2D.new();sprite.name=String(row.id);sprite.texture=texture;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
			sprite.centered=true;sprite.position=row.pos*E.SIZE;sprite.scale=row.render_size_px/Vector2(texture.get_size())
			sprite.z_index=int(floor(float(row.depth_sort_foot_y)*2048.0/8.0)) if row.get("sort_by_feet",false) else int(row.get("z_index",0))
			world.add_child(sprite);count+=1
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image: Image=viewport.get_texture().get_image()
		if need(image!=null and image.get_size()==VIEW and count==57,"INDEPENDENT_1280X854_57_REAL_SPRITES"):
			var image_path: String=HERE+"preview/"+str(OS.get_process_id())+"/estate_ground_visual_successor.png"
			if need(not FileAccess.file_exists(image_path) and DirAccess.make_dir_recursive_absolute(image_path.get_base_dir())==OK and image.save_png(image_path)==OK,"NEW_PREVIEW_PNG"):
				result.image=image_path;result.image_sha256=FileAccess.get_sha256(image_path)
		result.viewport_size=[1280,854];result.crop_native_xywh=[480,480,2112,1408];result.uniform_preview_scale=float(VIEW.x)/2112.0;result.sprites=count
		viewport.queue_free()
	var final: Dictionary={}
	for path: String in pins:
		final[path]=FileAccess.get_sha256(path);need(final[path]==pins[path],"SOURCE_FINAL:"+path)
	need(Time.get_ticks_msec()-began<60000,"FIXED_60S_BUDGET")
	result.merge({"passed":error.is_empty() and result.get("published")==true and result.has("image"),"error":error,"source_first":pins,"source_final":final,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":60000,"old_geometry_actual_report":GEOMETRY_REPORT,"old_geometry_actual_sha256":GEOMETRY_SHA,"not_completed":["main hall and side court modules","garden composition and replacement of mirrored tree repetition","Market25 and room returns","source admission/Router connection","actual Field/NPC/physics/portal checks"]},true)
	var report: String=HERE+"results/"+str(OS.get_process_id())+"/result.json"
	var ok: bool=save_json(report,result)
	print(JSON.stringify({"path":report,"passed":ok and result.passed,"error":error}));quit(0 if ok and result.passed else 1)
