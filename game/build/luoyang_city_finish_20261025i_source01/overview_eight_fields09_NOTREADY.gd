extends SceneTree
# BUILD authoring overview, not Field/ART/Physics or native publication acceptance.
const READY: bool=false
const INPUT: String="res://build/luoyang_city_finish_20261025i_source01/overview_eight_fields09_NOTREADY_input.json"
const INPUT_SHA: String="015bcbeb3eddc301e18928bfaed5af6d58d57d5b27d43741f8dad42e4d6fb30a"
const SELF: String="res://build/luoyang_city_finish_20261025i_source01/overview_eight_fields09_NOTREADY.gd"
var errors: Array=[]
var checks: int=0
var first: Dictionary={}
var fixture: Dictionary={}
var texture_cache: Dictionary={}
var save_first: Dictionary={}
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label)
	return ok
func j(path: String) -> Dictionary:
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}
func binary(path: String) -> Variant: return bytes_to_var(FileAccess.get_file_as_bytes(path))
func v(raw: Variant) -> Vector2:
	if raw is Vector2: return raw
	if raw is Array and raw.size()==2: return Vector2(float(raw[0]),float(raw[1]))
	return Vector2(INF,INF)
func _initialize() -> void: call_deferred("run")
func source_snapshot() -> Dictionary:
	var values: Dictionary={}
	for path: String in fixture.sources: values[path]=FileAccess.get_sha256(path)
	# Entry bytes are separately pinned by ROOT launcher, not cyclically by INPUT.
	values[SELF]=FileAccess.get_sha256(SELF)
	return values
func save_facts() -> Dictionary:
	var result: Dictionary={}
	for path: String in fixture.save_absolute_paths:
		if not FileAccess.file_exists(path): result[path]={"exists":false};continue
		var file: FileAccess=FileAccess.open(path,FileAccess.READ)
		if file==null: result[path]={"unreadable":true};continue
		var count: int=file.get_length();file.close()
		result[path]={"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":count,"modified_seconds":FileAccess.get_modified_time(path)}
	return result
func texture_for(row: Dictionary) -> Texture2D:
	var path: String=String(row.get("texture",""))
	if texture_cache.has(path): return texture_cache[path]
	var texture: Texture2D
	if path.begins_with("RAW_EXTERNAL_ONLY:"):
		var relative: String=path.trim_prefix("RAW_EXTERNAL_ONLY:")
		var absolute: String=fixture.repository_absolute.path_join(relative)
		if not fixture.raw_sources.has(relative) or FileAccess.get_sha256(absolute)!=String(fixture.raw_sources[relative]): return null
		var image: Image=Image.load_from_file(absolute)
		if image==null: return null
		texture=ImageTexture.create_from_image(image)
	else:
		if not fixture.texture_authority.has(path): return null
		if FileAccess.get_sha256(path)!=String(fixture.texture_authority[path]): return null
		texture=load(path) as Texture2D
	if texture!=null: texture_cache[path]=texture
	return texture
func add_rows(parent: Node2D,rows: Array,size: Vector2) -> bool:
	var actor_layer: Node2D=Node2D.new();actor_layer.y_sort_enabled=true;parent.add_child(actor_layer)
	for row: Dictionary in rows:
		var texture: Texture2D=texture_for(row)
		if not check(texture!=null,"ROW_TEXTURE:"+String(row.get("id",""))): return false
		var sprite: Sprite2D=Sprite2D.new();sprite.texture=texture;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		var position: Vector2
		var fallback_foot: Vector2
		if row.has("placement_foot_px"):
			var ratio: Vector2=size/Vector2(1536,1024)
			sprite.centered=false;sprite.scale=v(row.native_scale)*ratio
			position=v(row.placement_foot_px)*ratio-v(row.source_ground_anchor_px)*sprite.scale
			fallback_foot=v(row.placement_foot_px)*ratio
		else:
			sprite.centered=bool(row.get("centered",true));position=v(row.get("pos",[0,0]))*size
			if row.has("render_size_px"): sprite.scale=v(row.render_size_px)/texture.get_size()
			elif row.has("scale"): sprite.scale=Vector2.ONE*float(row.scale) if row.scale is float or row.scale is int else v(row.scale)
			fallback_foot=position
		var foot: Vector2=v(row.get("world_foot_px",[fallback_foot.x,fallback_foot.y]))
		if not foot.is_finite(): foot=position
		var pivot: Node2D=Node2D.new();pivot.position=foot;pivot.name=String(row.get("id","row"))
		sprite.position=position-foot;sprite.z_index=int(row.get("z_index",0));pivot.add_child(sprite);actor_layer.add_child(pivot)
	return true
func padded4(rows: Array,count: int) -> PackedVector4Array:
	var result: PackedVector4Array=PackedVector4Array()
	for r: Array in rows: result.append(Vector4(float(r[0]),float(r[1]),float(r[2]),float(r[3])))
	while result.size()<count: result.append(Vector4.ZERO)
	return result
func add_old_market_materials(parent: Node2D,textures: Dictionary) -> bool:
	# Authoring renderer of the fixed six source groups, not a fabricated live lease.
	var data: Dictionary=j(fixture.market_surface_spec)
	var shader: Shader=load(fixture.market_surface_shader) as Shader
	if not check(data.get("groups",[]).size()==5 and shader!=null,"FIXED_25F_SIX_SOURCE_GROUPS"): return false
	var layer: Node2D=Node2D.new();layer.z_index=-4;parent.add_child(layer)
	var groups: Array=[data.clean_base.duplicate(true)];groups.append_array(data.groups)
	for i: int in range(groups.size()):
		var group: Dictionary=groups[i];var base: bool=i==0
		var rects: Array=[group.rect] if base else group.rects
		var bounds: Rect2=Rect2(float(rects[0][0]),float(rects[0][1]),float(rects[0][2]),float(rects[0][3]))
		for r: Array in rects: bounds=bounds.merge(Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3])))
		var texture: Texture2D=textures[String(group.asset)]
		var sprite: Sprite2D=Sprite2D.new();sprite.texture=texture;sprite.centered=false;sprite.position=bounds.position
		sprite.scale=Vector2.ONE*.25;sprite.region_enabled=true;sprite.region_rect=Rect2(Vector2.ZERO,bounds.size/.25);sprite.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
		var material: ShaderMaterial=ShaderMaterial.new();material.shader=shader
		material.set_shader_parameter("source_size",texture.get_size());material.set_shader_parameter("source_to_world",.25);material.set_shader_parameter("world_origin",bounds.position)
		material.set_shader_parameter("use_rects",padded4(rects,8));material.set_shader_parameter("use_rect_count",rects.size())
		var exterior: Array=[[0,0,3072,0],[3072,0,3072,2048],[3072,2048,0,2048],[0,2048,0,0]] if base else group.exterior_segments
		material.set_shader_parameter("exterior_segments",padded4(exterior,32));material.set_shader_parameter("exterior_count",exterior.size())
		var exclusions: Array=[] if base else data.building_exclusions
		material.set_shader_parameter("building_exclusions",padded4(exclusions,8));material.set_shader_parameter("exclusion_count",exclusions.size())
		material.set_shader_parameter("edge_width",float(group.edge));material.set_shader_parameter("wear_world",float(group.wear));material.set_shader_parameter("texture_contrast",float(group.contrast));material.set_shader_parameter("core_opacity",float(group.core))
		var t: Array=group.tone;material.set_shader_parameter("material_tone",Color(float(t[0]),float(t[1]),float(t[2]),float(t[3])))
		if i>0 and i<5:
			material.set_shader_parameter("use_uv_transform",true);material.set_shader_parameter("uv_world_scale",float(group.sampling.world_scale))
			material.set_shader_parameter("uv_axis_rotation",Vector2.RIGHT if float(group.sampling.rotation_degrees)==0 else Vector2.DOWN)
			material.set_shader_parameter("priority_rects",padded4(group.priority_rects,8));material.set_shader_parameter("priority_count",group.priority_rects.size())
			if i==3:
				material.set_shader_parameter("gutter_segments",padded4(group.texture_edge.segments,4));material.set_shader_parameter("gutter_count",4)
				for pair: Array in [["gutter_inset","inset_world"],["gutter_width","gutter_width_world"],["shoulder_width","shoulder_width_world"],["gutter_multiplier","gutter_multiplier"],["shoulder_multiplier","shoulder_multiplier"],["gutter_end_fade","end_fade_world"]]: material.set_shader_parameter(pair[0],float(group.texture_edge[pair[1]]))
		sprite.material=material;layer.add_child(sprite)
	return true
func add_source_actors(parent: Node2D,rows: Array) -> bool:
	# Static source-origin silhouettes for layout only, not ActorLayer/body/walk proof.
	for row: Dictionary in rows:
		var texture: Texture2D=texture_for({"texture":row.sprite_path,"id":row.npc_id})
		if not check(texture!=null,"SOURCE_ACTOR_TEXTURE:"+String(row.npc_id)): return false
		var sprite: Sprite2D=Sprite2D.new();sprite.texture=texture;sprite.hframes=int(row.get("idle_frames",4));sprite.frame=0
		var scale_value: float=float(row.get("sprite_scale",1.0));sprite.scale=Vector2.ONE*scale_value
		var frame_size: Vector2=texture.get_size()/Vector2(sprite.hframes,1)
		sprite.position=v(row.foot_px)-Vector2(0,frame_size.y*scale_value*.5);sprite.z_index=4;parent.add_child(sprite)
	return true
func docks_source_render(native_rows: Array,projection: Dictionary,district: Dictionary) -> Array:
	# The frozen publication artifact is record projection, not a render array.
	if native_rows.size()!=29 or projection.get("child",{}).get("objects",[]).size()!=29: return []
	var result: Array=native_rows.duplicate(true)
	var spec: Dictionary=district.get("districts",{}).get("ch4_s2_canal_docks",{})
	if spec.get("placements",[]).size()!=10: return []
	for placement: Dictionary in spec.placements:
		if placement.has("replaces"): return []
		var asset: Dictionary=district.assets.get(placement.asset_id,{})
		if asset.is_empty(): return []
		var foot: Vector2=v(placement.foot_px);var source_size: Vector2=v(asset.size_px);var ratio: float=float(placement.scale)
		var anchor: Vector2=v(asset.source_ground_anchor_px);var polys: Array=[]
		for raw: Variant in asset.get("ground_solid_polygons_px",[]):
			var p: Array=[]
			for q: Variant in raw:
				var world: Vector2=foot+(v(q)-anchor)*ratio;p.append([float(world.x),float(world.y)])
			polys.append(p)
		result.append({"id":placement.id,"texture":String(asset.texture),"pos":(foot+(source_size*.5-anchor)*ratio)/Vector2(3072,2048),"render_size_px":source_size*ratio,"centered":true,"world_foot_px":[float(foot.x),float(foot.y)],"physical_center_px":[float(foot.x),float(foot.y)],"collision_size_px":[0.0,0.0],"city_v3_solid_polygons_px":polys,"blocking":true})
	for target: String in projection.changed_ids:
		var matches: int=0
		var child: Dictionary={}
		for r: Dictionary in projection.child.objects:
			if String(r.id)==target: child=r
		if child.is_empty(): return []
		for r: Dictionary in result:
			if String(r.id)!=target: continue
			var foot: Vector2=v(child.world_foot_px);var size: Vector2=v(child.render_size_px)
			r.pos=(foot+(Vector2(.5,.5)-v(child.foot_uv))*size)/Vector2(3072,2048)
			r.render_size_px=size;r.world_foot_px=child.world_foot_px.duplicate();r.physical_center_px=child.physical_center_px.duplicate();r.city_v3_solid_polygons_px=child.solid_polygons_px.duplicate(true);matches+=1
		if matches!=1: return []
	return result if result.size()==39 else []
func finish(out: String,started: int) -> void:
	var final: Dictionary=source_snapshot()
	check(final==first,"EXACT_INPUT_SOURCE_FIRST_FINAL")
	var save_final: Dictionary=save_facts();check(var_to_bytes(save_first)==var_to_bytes(save_final),"READONLY_SAVE15_FIRST_FINAL")
	var report: Dictionary={"status":"BUILD_EIGHT_FIELD_AUTHORING_OVERVIEW_NOT_FIELD_OR_WHOLE_ART","complete":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-started,"source_first":first,"source_final":final,"save_first":save_first,"save_final":save_final,"Field_calls":0,"packet_decode_calls":0,"collector_calls":0,"new_geometry_replay_calls":0,"processed_imported_whole_building3_original_uniform_and_padding_anchors":true,"static_source_actor_silhouettes_not_actual_ActorLayer_proof":true}
	var file: FileAccess=FileAccess.open(out+"result.json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	quit(0 if errors.is_empty() else 1)
func run() -> void:
	var started: int=Time.get_ticks_msec()
	if not READY or FileAccess.get_sha256(INPUT)!=INPUT_SHA: push_error("OVERVIEW_NOT_ROOT_READY");quit(1);return
	fixture=j(INPUT)
	var platform: Node=get_root().get_node_or_null("PlatformBridge")
	if platform!=null: platform.call("set_checkpoint_saves_suspended",true)
	save_first=save_facts()
	if not check(fixture.get("ready")==true and not DirAccess.dir_exists_absolute(fixture.output_absolute),"NEW_ROOT_ONLY_OUTPUT"): quit(1);return
	first=source_snapshot()
	for path: String in fixture.sources:
		if not check(first[path]==fixture.sources[path],"PIN:"+path): quit(1);return
	var out: String=String(fixture.output_absolute).path_join(str(OS.get_process_id()))+"/"
	if DirAccess.make_dir_recursive_absolute(out)!=OK: quit(1);return
	create_timer(float(fixture.whole_budget_ms)/1000.0).timeout.connect(func() -> void: errors.append("WHOLE_AUTHORING_BUDGET");finish(out,started))
	# Five dependency parse components inherited from ROOT18176; no explicit replay.
	var axis: Variant=load(fixture.axis_helper);var artisan: Variant=load(fixture.artisan_helper)
	var adjacent: Variant=load(fixture.adjacent_helper);var temple: Variant=load(fixture.temple_builder)
	var surfaces: Variant=load(fixture.surface_factory)
	var material_author: Dictionary=j(fixture.surface_author)
	var axis_author: Dictionary=j(fixture.axis_author);var axis_library: Dictionary=j(fixture.axis_library)
	var adjacent_author: Dictionary=j(fixture.adjacent_author);var adjacent_library: Dictionary=j(fixture.adjacent_library)
	var seed: Dictionary=binary(fixture.parent_seed)
	var craft: Dictionary=artisan.derive(j(fixture.artisan_old_author),j(fixture.artisan_life_author),j(fixture.artisan_author),j(fixture.processed_buildings))
	if not check(craft.get("ok")==true,"ARTISAN_SOURCE_DERIVE"): finish(out,started);return
	var kitchen: Dictionary={}
	for row: Dictionary in craft.building_and_life_render:
		if String(row.id)=="new_plain_kitchen_rear_house": kitchen=row
	var surface_textures: Dictionary={}
	for role: String in material_author.textures:
		var spec: Dictionary=material_author.textures[role]
		surface_textures[role]=load(spec.path) as Texture2D
	var shader: Shader=load(fixture.surface_shader) as Shader
	var sheet: Image=Image.create(4096,1366,false,Image.FORMAT_RGBA8);sheet.fill(Color("24262a"))
	for index: int in range(fixture.scenes.size()):
		var spec: Dictionary=fixture.scenes[index];var id: String=spec.id
		if id=="luoyang_estate_riverside_20261021ai":
			var inherited: Dictionary=fixture.inherited_images.get(id,{})
			if not check(not inherited.is_empty() and FileAccess.get_sha256(inherited.path)==inherited.sha256,"FIXED_ALREADY_RENDERED_VIEW:"+id): break
			var parent_view: Image=Image.load_from_file(inherited.path)
			if not check(parent_view!=null and parent_view.get_size()==Vector2i(1024,683),"INHERITED_FULL_VIEW_SIZE:"+id): break
			sheet.blit_rect(parent_view,Rect2i(0,0,1024,683),Vector2i((index%4)*1024,int(index/4)*683))
			continue
		var size: Vector2=v(spec.world_size_px);var rows: Array=[];var original_scene: SceneScript
		if index<2:
			var result: Dictionary=axis.derive(id,axis_author,axis_library,seed)
			if not check(result.get("ok")==true,"AXIS_SOURCE_DERIVE:"+id): break
			rows=result.render_objects
		elif id=="luoyang_artisan_residential_20261022ap":
			var old_layout: WalkableMapLayout=load(spec.parent_layout) as WalkableMapLayout
			if not check(old_layout!=null and old_layout.visual_objects.size()==136,"ARTISAN_118_OLD_GROUND_PREFIX"): break
			rows=old_layout.visual_objects.slice(0,118);rows.append_array(craft.building_and_life_render)
		elif id=="ch4_s4_ancient_temple":
			original_scene=load(spec.parent_scene) as SceneScript
			var result: Dictionary=temple.build(original_scene,j(fixture.temple_old_author),j(fixture.temple_author))
			if not check(result.get("ok")==true,"TEMPLE_PURE_NATIVE"): break
			rows=result.layout.visual_objects
		else:
			var before: Array=[]
			if id=="ch4_s2_canal_docks":
				original_scene=load(spec.parent_scene) as SceneScript
				if not check(original_scene!=null and original_scene.map_layout!=null,"DOCKS_FROZEN_NATIVE29_RESOURCE"): break
				before=docks_source_render(original_scene.map_layout.visual_objects,binary(spec.parent_projection),j(fixture.district_author))
			elif spec.has("parent_projection"): before=binary(spec.parent_projection).render
			else:
				original_scene=load(spec.parent_scene) as SceneScript
				if not check(original_scene!=null and original_scene.map_layout!=null,"PARENT_NATIVE_RESOURCE:"+id): break
				before=original_scene.map_layout.visual_objects
			var result: Dictionary=adjacent.derive(id,adjacent_author,adjacent_library,before,kitchen,before if id=="ch4_s2_canal_docks" else [])
			if not check(result.get("ok")==true,"ADJACENT_SOURCE_DERIVE:"+id): break
			rows=result.render
		var viewport: SubViewport=SubViewport.new();viewport.size=Vector2i(1024,683);viewport.transparent_bg=false
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;get_root().add_child(viewport)
		var world: Node2D=Node2D.new();world.scale=Vector2.ONE*(1024.0/size.x);viewport.add_child(world)
		var ground: Polygon2D=Polygon2D.new();ground.polygon=PackedVector2Array([Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)])
		ground.color=Color("8a8b78");ground.z_index=-30;world.add_child(ground)
		var background: String=String(spec.get("background_path",""))
		if background=="" and original_scene!=null: background=original_scene.background_path
		if background!="":
			var texture: Texture2D=texture_for({"texture":background,"id":id+"_ground"})
			if not check(texture!=null,"FIXED_PARENT_GROUND:"+id): break
			var base: Sprite2D=Sprite2D.new();base.texture=texture;base.centered=false;base.scale=Vector2.ONE*(size.x/float(texture.get_width()));base.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;base.z_index=-1000;world.add_child(base)
		if id=="ch4_s3_luoyang_market" and not add_old_market_materials(world,surface_textures): break
		if not add_rows(world,rows,size): break
		if id=="luoyang_artisan_residential_20261022ap":
			var fidelity: Variant=load(fixture.artisan_fidelity_helper)
			var existing_shader: Shader=load(fixture.artisan_existing_material_shader) as Shader
			if not check(fidelity is GDScript and fidelity.can_instantiate() and fidelity.attach_authoring_only(world,j(fixture.artisan_existing_material_contract),existing_shader),"FAITHFUL_EXISTING_ARTISAN_118_MATERIALS"): break
		var visible: Node2D=surfaces.create(material_author.scenes[id],surface_textures,shader)
		if not check(visible!=null,"VISIBLE_PURPOSE_MATERIALS:"+id): break
		world.add_child(visible)
		if not add_source_actors(world,fixture.source_actors.get(id,[])): break
		if id=="luoyang_riverside_garden_20261022ap":
			var river: Variant=load(fixture.garden_river_visual)
			var water: Dictionary=river.make_water_visual(original_scene,original_scene.map_layout.blockers)
			if not check(water.get("ok")==true,"UNCHANGED_GARDEN_RIVER_NATIVE_VISUAL"): break
			world.add_child(water.node)
		var label: Label=Label.new();label.text=String(spec.label)+"  [BUILD source overview]";label.position=Vector2(8,5)
		label.add_theme_font_size_override("font_size",20);viewport.add_child(label)
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		var image: Image=viewport.get_texture().get_image()
		if not check(image!=null and image.save_png(out+id+".png")==OK,"NEW_VIEWPORT_IMAGE:"+id): break
		sheet.blit_rect(image,Rect2i(0,0,1024,683),Vector2i((index%4)*1024,int(index/4)*683))
		viewport.queue_free();await process_frame
	check(sheet.save_png(out+"eight_fields_contact_sheet.png")==OK,"NEW_CONTACT_SHEET")
	finish(out,started)
