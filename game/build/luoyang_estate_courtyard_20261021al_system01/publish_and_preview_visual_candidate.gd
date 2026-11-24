extends SceneTree
## ROOT only. One visual descendant and one native Sprite image; no geometry.
const E=preload("res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const HERE="res://build/luoyang_estate_courtyard_20261021al_system01/"
const AUTHOR=HERE+"author_READY.json"
const AUTHOR_SHA="d5686a95c4e5a5c92b5b1a5ff2121263c0db2d492a12402da1ba2fde7949271e"
const AK="res://build/luoyang_estate_courtyard_20261021ak_system01/"
const PARENT=AK+"native_candidate/"
const GEOMETRY=AK+"geometry/110824/result.json"
const GEOMETRY_SHA="248273fca90108ed14655c5dd9baee9cdd4fd66d1174c2951580cde725834b9d"
const AK_AUTHOR=AK+"author_READY.json"
const AK_AUTHOR_SHA="c21097071d8a13ee9e427309a9203fe74ae28250eb36d067c2a101e08185de55"
const OUTPUT=HERE+"native_candidate/"
const VIEW=Vector2i(1536,1024)
const REQUIRED=["north_court","hall_approach","west_wing_approach","east_wing_approach"]
const DOOR_HALL_MODULATE=Color(.48,.44,.40,1)
const DOOR_WING_MODULATE=Color(.46,.42,.38,1)
var error: String=""
var pins: Dictionary={}
var began: int=0
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	if not ok and error.is_empty(): error=label;push_error("AL_VISUAL "+label)
	return ok
func track(path: String,wanted: String="") -> bool:
	var hash: String=FileAccess.get_sha256(path)
	if not need(path.begins_with("res://") and ".." not in path and hash.length()==64 and (wanted.is_empty() or wanted==hash) and (not pins.has(path) or pins[path]==hash),"EXACT_SOURCE:"+path): return false
	pins[path]=hash;return true
func number(value: Variant) -> bool: return (value is int or value is float) and is_finite(float(value))
func pair(value: Variant) -> bool: return value is Array and value.size()==2 and number(value[0]) and number(value[1])
func integer(value: Variant) -> bool: return number(value) and float(value)==floorf(float(value))
func json_new(path: String,value: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true));file.close();return true
func ground_rows(a: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary]=[];var seen: Array=[]
	if not a.get("ground_sections") is Array: return out
	for section: Dictionary in a.ground_sections:
		if not need(section.get("id") in REQUIRED and not section.id in seen and pair(section.get("origin_px")) and number(section.get("uniform_scale")) and float(section.uniform_scale)>0 and integer(section.get("columns")) and integer(section.get("rows")) and int(section.columns)>0 and int(section.rows)>0 and int(section.columns)<=48 and int(section.rows)<=48 and a.source_sha256.has(section.get("texture")),"EXACT_GROUND_SECTION"): return []
		var texture: Variant=load(section.texture)
		if not need(texture is AtlasTexture and texture.get_width()>0 and texture.get_height()>0,"REAL_NATIVE_TEXTURE_REGION"): return []
		var size: Vector2=Vector2(texture.get_size())*float(section.uniform_scale)
		for y: int in int(section.rows):
			for x: int in int(section.columns):
				var top_left: Vector2=E.v(section.origin_px)+Vector2(x,y)*size
				if not need(Rect2(Vector2.ZERO,E.SIZE).encloses(Rect2(top_left,size)),"GROUND_TILE_IN_NATIVE_MAP"): return []
				out.append({"id":"estate_al_ground_"+String(section.id)+"_"+str(x)+"_"+str(y),"texture":section.texture,"pos":(top_left+size*.5)/E.SIZE,"render_size_px":size,"centered":true,"sort_by_feet":false,"z_index":-9})
		seen.append(section.id)
	if not need(seen.size()==4,"FOUR_ACTUAL_APPROACH_PAVING_SECTIONS"): return []
	return out
func door_rows(a: Dictionary,ak: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	if not need(a.get("door_textures") is Dictionary and a.door_textures.size()==2,"TWO_REAL_INTERIOR_ATLASES"): return []
	for component: Dictionary in ak.components:
		if component.role not in ["main_hall","west_wing","east_wing"]: continue
		var asset: Dictionary={}
		for entry: Dictionary in ak.assets:
			if entry.id==component.asset_id: asset=entry
		if not need(not asset.is_empty() and a.door_textures.has(asset.id),"EXACT_AK_DOOR_ASSET"): return []
		var metadata: Dictionary=E.json(asset.metadata_path)
		var source_rect: Variant=metadata.get("output_annotations",{}).get("door_clear_rect_px")
		if not need(source_rect is Array and source_rect.size()==4,"PINNED_SOURCE_DOOR_RECTANGLE"): return []
		# Three source-pixel overlap (1.06px wing /1.34px hall in world),
		# behind the unchanged opaque jamb: no grass seam, no PNG edits.
		var rect: Rect2=E.rect(source_rect).grow(3);var path: String=String(a.door_textures[asset.id])
		var texture: Variant=load(path)
		if not need(a.source_sha256.has(path) and texture is AtlasTexture and Vector2(texture.get_size())==rect.size,"REAL_INTERIOR_CROP_SAME_SOURCE_DOOR_ASPECT"): return []
		var scale: float=float(component.scale);var center: Vector2=E.v(component.foot)+(rect.get_center()-E.v(asset.ground_anchor))*scale
		out.append({"id":"estate_al_door_"+String(component.role),"texture":path,"pos":center/E.SIZE,"render_size_px":rect.size*scale,"centered":true,"sort_by_feet":false,"z_index":floori(float(component.foot[1])/8.0)-1,"modulate":DOOR_HALL_MODULATE if asset.id=="main_hall" else DOOR_WING_MODULATE})
	if not need(out.size()==3,"ONLY_THREE_HOUSE_DOOR_BACKDROPS_NOT_OPEN_ARCH_OR_CORRIDOR"): return []
	return out
func derive() -> Dictionary:
	if not need(OS.get_cmdline_user_args().is_empty() and AUTHOR_SHA.length()==64,"READY_ART_AUTHOR_NO_UNKNOWN_ARGS"): return {}
	if not track(GEOMETRY,GEOMETRY_SHA) or not track(AK_AUTHOR,AK_AUTHOR_SHA) or not track(AUTHOR,AUTHOR_SHA): return {}
	var proof: Dictionary=E.json(GEOMETRY);var ak: Dictionary=E.json(AK_AUTHOR);var a: Dictionary=E.json(AUTHOR)
	if not need(proof.get("passed")==true and proof.get("source_first")==proof.get("source_final") and a.get("status")=="ROOT_ADMITTED_AL_VISUAL_ONLY_CANDIDATE" and a.get("formal_enabled")==false and a.get("source_sha256") is Dictionary,"EXACT_ACTUAL_PARENT_AND_ART_AUTHOR"): return {}
	for path: String in proof.source_first:
		if not track(path,proof.source_first[path]): return {}
	for path: String in proof.artifacts:
		if not track(path,proof.artifacts[path]): return {}
	if not track(get_script().resource_path): return {}
	for path: String in a.source_sha256:
		if not track(path,a.source_sha256[path]): return {}
	var parent: Variant=bytes_to_var(FileAccess.get_file_as_bytes(PARENT+"packet.bin"))
	var scene:=ResourceLoader.load(PARENT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(parent is Dictionary and scene!=null and B.equal(B.storage(scene),parent.scene_storage) and B.equal(B.storage(scene.map_layout),parent.layout_storage) and scene.map_layout.visual_objects.size()==62 and scene.map_layout.blockers.size()==20,"AK62_VISUAL20_RECT_WHOLE_NATIVE_STORAGE"): return {}
	var old_visual: Array[Dictionary]=scene.map_layout.visual_objects.duplicate(true);var visual: Array[Dictionary]=[];var removed: Array=[]
	if not need(a.get("remove_ground_ids") is Array,"EXPLICIT_GROUND_REMOVAL_LIST"): return {}
	for value: Variant in a.remove_ground_ids:
		if not need(value is String and value.begins_with("estate_ground_v2_") and not value in removed,"ONLY_OLD_GROUND_IDS_REMOVABLE"): return {}
		removed.append(value)
	var found: int=0
	for row: Dictionary in old_visual:
		if row.id in removed: found+=1
		else: visual.append(row.duplicate(true))
	if not need(found==removed.size(),"ALL_REMOVED_IDS_EXIST_ON_FIXED_PARENT"): return {}
	var grounds: Array[Dictionary]=ground_rows(a);var doors: Array[Dictionary]=door_rows(a,ak)
	if not need(error.is_empty() and not grounds.is_empty() and doors.size()==3,"ACTUAL_GROUND_AND_DOOR_ROWS"): return {}
	visual.append_array(grounds);visual.append_array(doors);scene.map_layout.visual_objects=visual
	var storage: Dictionary={"scene":B.storage(scene),"layout":B.storage(scene.map_layout)}
	scene.map_layout.visual_objects=old_visual
	if not need(B.equal(B.storage(scene),parent.scene_storage) and B.equal(B.storage(scene.map_layout),parent.layout_storage),"COMPLETE_TYPED_NATIVE_INVERSE_ONLY_VISUAL_ROWS_CHANGED"): return {}
	scene.map_layout.visual_objects=visual
	var packet: Dictionary=parent.duplicate(true);packet.scene_storage=storage.scene;packet.layout_storage=storage.layout
	packet.visual_successor_AL={"author_path":AUTHOR,"author_sha256":AUTHOR_SHA,"parent_packet":PARENT+"packet.bin","parent_sha256":proof.artifacts[PARENT+"packet.bin"],"removed_ground_ids":removed,"ground_rows":grounds.size(),"door_rows":3,"all20rect_mask_routes_portals_and_building_poses_unchanged":true,"geometry_rerun":false}
	var inverse: Dictionary=packet.duplicate(true);inverse.scene_storage=parent.scene_storage;inverse.layout_storage=parent.layout_storage;inverse.erase("visual_successor_AL")
	if not need(B._plain(packet) and B.equal(inverse,parent),"COMPLETE_PACKET_INVERSE_MASK_GEOMETRY_AND_ROUTE_FIELDS_UNCHANGED"): return {}
	if not need(not DirAccess.dir_exists_absolute(OUTPUT) and DirAccess.make_dir_recursive_absolute(OUTPUT)==OK,"NEW_NATIVE_OUTPUT_ONLY"): return {}
	if not need(ResourceSaver.save(scene.map_layout,OUTPUT+"layout.res")==OK,"NEW_VISUAL_LAYOUT"): return {}
	scene.map_layout=ResourceLoader.load(OUTPUT+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(scene.map_layout!=null and ResourceSaver.save(scene,OUTPUT+"scene.res")==OK,"NEW_VISUAL_SCENE"): return {}
	var file:=FileAccess.open(OUTPUT+"packet.bin",FileAccess.WRITE)
	if not need(file!=null,"NEW_PACKET"): return {}
	file.store_buffer(var_to_bytes(packet));file.close()
	var readback:=ResourceLoader.load(OUTPUT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(readback!=null and B.equal(B.storage(readback),storage.scene) and B.equal(B.storage(readback.map_layout),storage.layout) and B.equal(bytes_to_var(FileAccess.get_file_as_bytes(OUTPUT+"packet.bin")),packet),"FULL_NATIVE_AND_PACKET_READBACK"): return {}
	var artifacts: Dictionary={}
	for name: String in ["scene.res","layout.res","packet.bin"]: artifacts[OUTPUT+name]=FileAccess.get_sha256(OUTPUT+name)
	return {"published":true,"scene":readback,"artifacts":artifacts,"visual_rows":visual.size(),"ground_rows":grounds.size(),"door_depth_rows":3,"removed_ground_ids":removed,"parent_native_packet_inverse":true,"all20rect_mask_routes_portals_unchanged":true,"geometry_rerun":false}
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);began=Time.get_ticks_msec()
	var result: Dictionary=derive();var scene: SceneScript=result.get("scene") as SceneScript;result.erase("scene")
	if scene!=null and error.is_empty():
		var viewport:=SubViewport.new();viewport.size=VIEW;viewport.disable_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
		var world:=Node2D.new();world.scale=Vector2(.5,.5);viewport.add_child(world);var count: int=0
		for row: Dictionary in scene.map_layout.visual_objects:
			var texture: Variant
			if String(row.id).begins_with("estate_ak_"):
				var raw: Image=Image.load_from_file(row.texture)
				if not need(raw!=null,"ORIGINAL_AK_RAW_TEXTURE"): break
				texture=ImageTexture.create_from_image(raw)
			else: texture=load(row.texture)
			if not need(texture is Texture2D,"ACTUAL_TEXTURE:"+String(row.texture)): break
			var sprite:=Sprite2D.new();sprite.name=String(row.id);sprite.texture=texture;sprite.centered=true;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
			sprite.position=row.pos*E.SIZE;sprite.scale=row.render_size_px/Vector2(texture.get_size())
			sprite.z_index=floori(float(row.depth_sort_foot_y)*2048.0/8.0) if row.get("sort_by_feet",false) else int(row.get("z_index",0))
			if row.get("modulate") is Color: sprite.modulate=row.modulate
			world.add_child(sprite);count+=1
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image: Image=viewport.get_texture().get_image();var dir: String=HERE+"actual/"+str(OS.get_process_id())+"/"
		if need(image!=null and image.get_size()==VIEW and count==int(result.visual_rows) and not DirAccess.dir_exists_absolute(dir) and DirAccess.make_dir_recursive_absolute(dir)==OK,"INDEPENDENT_FULL_NATIVE_HALF_SCALE_IMAGE"):
			var image_path: String=dir+"estate_paving_depth_native_sprites.png"
			if need(image.save_png(image_path)==OK,"NEW_PREVIEW_IMAGE"): result.image=image_path;result.image_sha256=FileAccess.get_sha256(image_path)
		result.sprites=count;viewport.queue_free()
	var final: Dictionary={}
	for path: String in pins:
		final[path]=FileAccess.get_sha256(path);need(final[path]==pins[path],"SOURCE_FINAL:"+path)
	need(Time.get_ticks_msec()-began<60000,"FIXED60S_BUDGET")
	result.merge({"passed":error.is_empty() and result.get("published")==true and result.has("image"),"error":error,"source_first":pins,"source_final":final,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":60000,"viewport_size":[1536,1024],"uniform_native_scale":.5,"scope":"VISUAL_ONLY_CANDIDATE_NOT_FORMAL_FIELD_OR_ROUTER_OR_IMPORT","not_claimed":["new physics or geometry validation","NPC/dialogue","room return trips","formal loading or cache improvement","complete estate art"]},true)
	var report: String=HERE+"actual/"+str(OS.get_process_id())+"/result.json";var ok: bool=json_new(report,result)
	print(JSON.stringify({"path":report,"passed":ok and result.passed,"error":error}));quit(0 if ok and result.passed else 1)
