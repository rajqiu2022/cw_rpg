extends SceneTree
## ROOT-only light native Sprite preview. NOT Field, NAV, Physics or formal QA.
const A_PATH="res://scripts/city/luoyang_docks_district08_20261019aa.gd"
const B_PATH="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const NEW_ROOT="res://data/maps/luoyang_docks_district08_20261019aa/runtime/ch4_s2_canal_docks/"
const IDS=["north_canal_warehouse","harbour_small_cargo_store","south_canal_front","harbour_rope_shop","street_tree_3"]
const WORLD=Vector2(3072,2048)
const CROP=Rect2(0,500,1280,1548)
const DISPLAY_SCALE=.5
var _sources: Dictionary={}
var _error: String=""
var _output: String=""
func _initialize() -> void: call_deferred("_run")
func need(value: bool,message: String) -> bool:
	if not value and _error.is_empty(): _error=message; push_error("[aa local Sprite] "+message)
	return value
func track(path: String) -> bool:
	var sha: String=FileAccess.get_sha256(path)
	if not need(sha.length()==64 and (not _sources.has(path) or _sources[path]==sha),"Exact preview source "+path): return false
	_sources[path]=sha; return true
func v(value: Variant) -> Vector2:
	return value if value is Vector2 else (Vector2(value[0],value[1]) if value is Array and value.size()==2 else Vector2(INF,INF))
func panel(scene: SceneScript,x: int,title: String) -> SubViewport:
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(640,774); viewport.transparent_bg=false
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world:=Node2D.new()
	world.position=-CROP.position*DISPLAY_SCALE; world.scale=Vector2.ONE*DISPLAY_SCALE
	viewport.add_child(world)
	if not track(scene.background_path): return null
	var floor_texture:=load(scene.background_path) as Texture2D
	if floor_texture==null: return null
	var floor_sprite:=Sprite2D.new()
	floor_sprite.texture=floor_texture; floor_sprite.centered=false; floor_sprite.z_index=-3000
	world.add_child(floor_sprite)
	for entry: Dictionary in scene.map_layout.visual_objects:
		if String(entry.get("id","")) not in IDS: continue
		var path: String=String(entry.get("texture",""))
		if not track(path): return null
		var texture:=load(path) as Texture2D
		if texture==null: return null
		var sprite:=Sprite2D.new()
		sprite.name=String(entry.id); sprite.texture=texture
		sprite.centered=entry.get("centered",true)
		sprite.position=v(entry.pos)*WORLD
		sprite.scale=v(entry.render_size_px)/texture.get_size()
		sprite.z_index=clampi(roundi(float(entry.get("depth_sort_foot_y",0))*WORLD.y),-2000,3000)
		world.add_child(sprite)
	var display:=TextureRect.new()
	display.position=Vector2(x,48); display.size=Vector2(640,774)
	display.texture=viewport.get_texture(); display.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(display)
	var label:=Label.new(); label.position=Vector2(x+16,10)
	label.text=title; label.add_theme_font_size_override("font_size",20)
	root.add_child(label)
	return viewport
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	_output="res://build/luoyang_docks_district08_20261019aa_preview/"+str(OS.get_process_id())+"/"
	var a: Variant=load(A_PATH); var b: Variant=load(B_PATH)
	if not need(a is GDScript and a.can_instantiate() and b is GDScript and b.can_instantiate(),"Real APIs compile"): quit(1); return
	var author: Dictionary=a.author()
	if not need(not author.is_empty(),"Frozen author"): quit(1); return
	for path: String in [A_PATH,B_PATH,a.AUTHOR,get_script().resource_path]:
		if not track(path): quit(1); return
	var old_root: String=author.parent_bundle_root
	for suffix: String in ["scene.res","layout.res"]:
		if not track(old_root+suffix) or not track(NEW_ROOT+suffix): quit(1); return
	var old:=ResourceLoader.load(old_root+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var child:=ResourceLoader.load(NEW_ROOT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if old!=null: old.map_layout=ResourceLoader.load(old_root+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if child!=null: child.map_layout=ResourceLoader.load(NEW_ROOT+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(old!=null and child!=null and old.map_layout!=null and child.map_layout!=null and old.map_layout.visual_objects.size()==27 and child.map_layout.visual_objects.size()==25 and old.background_path==child.background_path,"Actual old27/new25 artifacts with same original floor"): quit(1); return
	root.size=Vector2i(1280,822)
	var before: SubViewport=panel(old,0,"BEFORE - original scale / west block")
	var after: SubViewport=panel(child,640,"AFTER - remove 2 / retain rope shop")
	if not need(before!=null and after!=null,"Limited original Sprite construction"): quit(1); return
	for tick: int in range(3): await process_frame
	await RenderingServer.frame_post_draw
	if DirAccess.make_dir_recursive_absolute(_output)!=OK: quit(1); return
	var output_image: Image=root.get_texture().get_image()
	var ok: bool=need(output_image!=null and output_image.save_png(_output+"west_block_before_after.png")==OK,"Combined actual viewport PNG")
	var final_sources: Dictionary={}
	for path: String in _sources:
		final_sources[path]=FileAccess.get_sha256(path)
		if not need(final_sources[path]==_sources[path],"Preview source changed"): ok=false
	var report: Dictionary={"passed":ok,"error":_error,"scope":"LIMITED_NATIVE_SPRITE_BEFORE_AFTER_NOT_FIELD_NOT_PHYSICS","image_path":_output+"west_block_before_after.png","image_sha256":FileAccess.get_sha256(_output+"west_block_before_after.png"),"world_crop_px":[0,500,1280,1548],"viewport_display_scale_only":DISPLAY_SCALE,"original_asset_render_scale_unchanged":true,"shown_ids":IDS,"floor_unchanged":true,"npcs_not_shown":true,"no_collision_shapes_or_navigation_instantiated":true,"source_first":_sources,"source_final":final_sources}
	var file:=FileAccess.open(_output+"result.json",FileAccess.WRITE)
	if file==null: quit(1); return
	file.store_string(JSON.stringify(report,"\t",true,true)); file.close()
	print(JSON.stringify({"passed":ok,"output":_output,"scope":report.scope}))
	quit(0 if ok else 1)
