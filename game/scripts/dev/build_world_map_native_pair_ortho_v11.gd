extends "res://scripts/dev/build_world_map_native_pair_ortho_v10.gd"

# Static GEOGRAPHY intentionally remains v9 for natural water and old physical
# pads. We override build/save explicitly: v10's whole-image mask SHA hook is
# inappropriate for a REAL local mesh/height candidate.
const V11 := preload("res://scripts/dev/world_native_pair_landmark_contract_v11.gd")
const BOULDER_DIFF := "res://art/external/polyhaven/boulder_01/textures/boulder_01_diff_1k.jpg"
var _models: Array[Dictionary]=[]
var _entities: Array[Dictionary]=[]
var _v11_contacts: Array[Dictionary]=[]


func _initialize() -> void:
	call_deferred("_build")


func _output_prefix() -> String:
	return V11.PREFIX


func terrain_height_before(p: Vector2, topology: Image) -> float:
	return super._height(p,topology)


func terrain_height(p: Vector2, topology: Image) -> float:
	return _height(p,topology)


func terrain_gradient(p: Vector2, topology: Image) -> float:
	return _gradient(p,topology)


func terrain_project(p: Vector2, topology: Image) -> Vector2:
	return Vector2(p.x,p.y-_height(p,topology)*SIZE.y/CAMERA_SIZE/sqrt(2.0))


func _height(p: Vector2, topology: Image) -> float:
	var original := terrain_height_before(p,topology)
	# A finite asymmetric rock ridge. All amplitude and first derivatives are
	# zero at the ROI edge. Actual triangles/normals change, not a painted mask.
	if not V11.HEIGHT_SOURCE_ROI.has_point(p):
		return original
	var window := smoothstep(120.0,162.0,p.x)*(1.0-smoothstep(514.0,560.0,p.x))
	window*=smoothstep(160.0,193.0,p.y)*(1.0-smoothstep(319.0,360.0,p.y))
	var ridge := 238.0+22.0*sin((p.x-180.0)/85.0)
	var lateral := p.y-ridge
	var shoulder_width := 45.0 if lateral<0.0 else 82.0
	var volume := 1.62*exp(-pow(lateral/shoulder_width,2.0))*exp(-pow((p.x-342.0)/153.0,4.0))
	var terrace := 0.43*exp(-pow((p.x-458.0)/58.0,2.0)-pow((p.y-292.0)/38.0,2.0))
	# Preserve the existing road's genuinely flat pad even within a buffer.
	return original+(volume+terrace)*window*smoothstep(55.0,100.0,_height_road_distance(p))


func _contact_sites_v10() -> Array[Dictionary]:
	# This is VISUAL only. Inherited _contacts used to flatten physical height
	# stays untouched, otherwise replacing herbs would alter old pads/nav.
	if not _v11_contacts.is_empty():
		return _v11_contacts
	for site in super._contact_sites_v10():
		if String(site["id"]) not in V11.REPLACED_IDS:
			_v11_contacts.append(site)
	for entry in _models:
		var spec: Dictionary=entry["spec"]
		var footprint: Vector2=entry["footprint_size"]
		var foot: Vector2=entry["collision_center"]
		_v11_contacts.append({"id":spec["id"],"foot":foot,"radius":footprint*Vector2(0.50,0.51),"offset":Vector2(2,1),"strength":0.0})
	return _v11_contacts


func _surface_material(color: Texture2D, selector: Texture2D, mask: bool) -> ShaderMaterial:
	var material := super._surface_material(color,selector,mask)
	if mask:
		return material
	var code := material.shader.code
	code=code.replace("uniform bool contact_debug=false;","uniform bool contact_debug=false;\nuniform sampler2D native_rock_tex : source_color,repeat_enable,filter_linear_mipmap;\nvarying vec3 ground_world;")
	code=code.replace("void vertex(){terrain_normal=NORMAL;}","void vertex(){terrain_normal=NORMAL;ground_world=VERTEX;}")
	code=code.replace("float road=topo.g;", """
 // Geometric western ridge gets scanned rock on steep shoulders. Triplanar
 // mapping follows actual xyz; it does not stretch a flat photograph upward.
 vec3 n=abs(normalize(terrain_normal));n=pow(n,vec3(4.0));n/=max(n.x+n.y+n.z,0.001);
 vec3 native_rock=texture(native_rock_tex,ground_world.yz/1.65).rgb*n.x+
	texture(native_rock_tex,ground_world.xz/1.65).rgb*n.y+
	texture(native_rock_tex,ground_world.xy/1.65).rgb*n.z;
 float local=smoothstep(120.0,162.0,p.x)*(1.0-smoothstep(514.0,560.0,p.x))*smoothstep(160.0,193.0,p.y)*(1.0-smoothstep(319.0,360.0,p.y));
 land=mix(land,native_rock*0.80,local*smoothstep(0.04,0.28,slope)*0.92);
 float road=topo.g;
""")
	material.shader.code=code
	material.set_shader_parameter("native_rock_tex",load(BOULDER_DIFF))
	return material


func _mesh_instances(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_mesh_instances(child,result)


func _corners(bounds: AABB) -> Array[Vector3]:
	var corners: Array[Vector3]=[]
	for x in [bounds.position.x,bounds.end.x]:
		for y in [bounds.position.y,bounds.end.y]:
			for z in [bounds.position.z,bounds.end.z]:
				corners.append(Vector3(x,y,z))
	return corners


func _prepare_models(topology: Image) -> void:
	for spec in V11.model_specs():
		var packed := load(String(spec["source"])) as PackedScene
		assert(packed!=null,"Missing verified local model")
		var imported := packed.instantiate() as Node3D
		var meshes: Array[MeshInstance3D]=[]
		_mesh_instances(imported,meshes)
		var entity := Node3D.new()
		entity.rotation_degrees.y=spec["yaw"]
		entity.scale=Vector3.ONE*float(spec["scale"])
		var selected := meshes[int(spec["variant"])]
		var mesh := selected.duplicate() as MeshInstance3D
		# Catalogue a/b/c/d x translations are not physical cluster placement.
		# Every herb is its own mesh with its own explicit anchored transform.
		mesh.transform=Transform3D.IDENTITY
		for child in mesh.get_children():
			child.free()
		entity.add_child(mesh)
		var bounds := AABB()
		var vertices: Array[Vector3]=[]
		var first := true
		# Rotated AABB corners invent extremities that the source geometry
		# never contains. Use every actual vertex after the SAME yaw/scale.
		for surface in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var positions: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			for vertex in positions:
				var transformed: Vector3=entity.transform*vertex
				vertices.append(transformed)
				if first:
					bounds=AABB(transformed,Vector3.ZERO)
					first=false
				else:
					bounds=bounds.expand(transformed)
		var support := AABB()
		var support_first := true
		var support_vertex_count := 0
		for vertex in vertices:
			if vertex.y>bounds.position.y+bounds.size.y*0.06:
				continue
			support_vertex_count+=1
			if support_first:
				support=AABB(vertex,Vector3.ZERO)
				support_first=false
			else:
				support=support.expand(vertex)
		assert(not support_first)
		var source_foot: Vector2=spec["foot"]
		var ground := _point(source_foot,topology)
		# Foot is the actual front edge of XZ support at minimum model Y,
		# not top-of-picture / sprite center. Model height remains untouched.
		var contact_local := Vector3(support.get_center().x,bounds.position.y,support.end.z)
		entity.position=ground-contact_local
		var projected_foot := terrain_project(source_foot,topology)
		var projected_size := Vector2(bounds.size.x*SIZE.x/30.0,bounds.size.z*SIZE.y/(Z_HALF*2.0))
		var footprint_center := projected_foot+Vector2((bounds.get_center().x-contact_local.x)*SIZE.x/30.0,(bounds.get_center().z-contact_local.z)*SIZE.y/(Z_HALF*2.0))
		_models.append({"spec":spec,"node":entity,"bounds":bounds,"support_bounds":support,"support_vertex_count":support_vertex_count,"actual_vertex_count":vertices.size(),"ground_world":ground,"projected_foot":projected_foot,"footprint_size":projected_size,"collision_center":footprint_center})
		imported.free()


func _camera(world: Node) -> Camera3D:
	for child in world.get_children():
		if child is Camera3D:
			return child
	return null


func _native_viewport(color: Texture2D, selector: Texture2D, topology: Image, cast: bool) -> SubViewport:
	var viewport := _make_viewport(color,selector,topology,false)
	var world := viewport.get_child(0)
	# Compatibility SHADOWS_ONLY produced no shadows in the first capture.
	# Keep real ON casters on layer 2, camera layer 1: native light shadow
	# rendering still sees the same meshes, ordinary ground capture cannot.
	_camera(world).cull_mask=1
	for child in world.get_children():
		if child is MeshInstance3D:
			child.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if child is DirectionalLight3D:
			child.shadow_enabled=true
			child.shadow_bias=0.02
			child.shadow_normal_bias=0.08
			child.directional_shadow_max_distance=32.0
			child.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	for entry in _models:
		var caster := entry["node"].duplicate() as Node3D
		var meshes: Array[MeshInstance3D]=[]
		_mesh_instances(caster,meshes)
		for mesh in meshes:
			mesh.layers=2
			mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# In the off reference, model opacity must not contaminate ground.
			if not cast:
				mesh.visible=false
		world.add_child(caster)
	return viewport


func _entity_viewport(color: Texture2D, selector: Texture2D, topology: Image, entry: Dictionary) -> SubViewport:
	var viewport := _make_viewport(color,selector,topology,false)
	viewport.transparent_bg=true
	var world := viewport.get_child(0)
	for child in world.get_children():
		if child is MeshInstance3D:
			child.visible=false
		if child is WorldEnvironment:
			child.environment.background_color=Color(0,0,0,0)
		if child is DirectionalLight3D:
			child.shadow_enabled=false # No ground plane in transparent alpha.
	world.add_child(entry["node"].duplicate())
	return viewport


func _json(path: String, data: Dictionary) -> void:
	var output := FileAccess.open(path,FileAccess.WRITE)
	assert(output!=null)
	output.store_string(JSON.stringify(data,"\t"))
	output.close()


func _capture_entity(color: Texture2D, selector: Texture2D, topology: Image, entry: Dictionary) -> void:
	var viewport := _entity_viewport(color,selector,topology,entry)
	for frame in range(12):
		await process_frame
	var source := viewport.get_texture().get_image()
	source.convert(Image.FORMAT_RGBA8)
	var used := source.get_used_rect()
	assert(used.size.x>0 and used.size.y>0)
	var crop := used.grow(4).intersection(Rect2i(Vector2i.ZERO,SIZE))
	var image := source.get_region(crop)
	var world := viewport.get_child(0)
	var camera := _camera(world)
	var projected_foot := camera.unproject_position(entry["ground_world"])
	assert(projected_foot.distance_to(entry["projected_foot"])<0.01)
	var foot_uv := (projected_foot-Vector2(crop.position))/Vector2(crop.size)
	var spec: Dictionary=entry["spec"]
	var id: String=spec["id"]
	var texture_path := V11.PREFIX+"entity_"+id+".png"
	var metadata_path := V11.PREFIX+"entity_"+id+".json"
	assert(image.save_png(texture_path)==OK)
	var footprint: Vector2=entry["footprint_size"]
	var collision_center: Vector2=entry["collision_center"]
	var bounds: AABB=entry["bounds"]
	var meta := {"id":id,"old_id":spec["old_id"],"source_path":spec["source"],"source_sha256":FileAccess.get_sha256(spec["source"]),"texture_path":texture_path,"metadata_path":metadata_path,"size":[crop.size.x,crop.size.y],"render_size":[crop.size.x,crop.size.y],"foot_uv":[foot_uv.x,foot_uv.y],"source_foot":[spec["foot"].x,spec["foot"].y],"world_foot":[projected_foot.x,projected_foot.y],"world_base_y":projected_foot.y,"collision_center":[collision_center.x,collision_center.y],"collision_size":[footprint.x,footprint.y],"blocking":spec["blocking"],"nature":"solid_rock" if spec["blocking"] else "low_herb_nonblocking","variant":spec["variant"],"model_scale":spec["scale"],"yaw":spec["yaw"],"projected_used_rect":[used.position.x,used.position.y,used.size.x,used.size.y],"model_bounds_m":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z],"camera":{"position":[0,12,12],"ortho_size":10,"canvas":[3072,1024]},"light":{"rotation_degrees":[-55,-34,0],"energy":1.15,"ambient":0.62},"ground_anchor_is_front_XZ_min_Y":true,"cast_source_transform":[entry["node"].position.x,entry["node"].position.y,entry["node"].position.z],"same_transform_shadow_and_alpha":true,"group_anchor":[spec.get("group_anchor",spec["foot"]).x,spec.get("group_anchor",spec["foot"]).y]}
	var support: AABB=entry["support_bounds"]
	meta["bounds_method"]="all_actual_mesh_vertices_after_yaw_scale_not_rotated_AABB_corners"
	meta["actual_vertex_count"]=entry["actual_vertex_count"]
	meta["support_vertex_count"]=entry["support_vertex_count"]
	meta["support_method"]="lowest_six_percent_height_actual_vertices_front_z_min_y"
	meta["support_bounds_m"]=[support.position.x,support.position.y,support.position.z,support.size.x,support.size.y,support.size.z]
	_entities.append(meta)
	_json(metadata_path,meta)
	viewport.queue_free()
	await process_frame


func _geometry_diagnostics(topology: Image) -> void:
	var before := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RF)
	var after := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RF)
	var before_png := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGB8)
	var after_png := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGB8)
	var normal_before := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGB8)
	var normal_after := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGB8)
	var witnesses: Array=[]
	# Full native source frames: actual model units retained in RF EXR, PNG
	# normalized to 4m for inspection. These are geometry data, not nav masks.
	for y in range(0,SIZE.y,4):
		for x in range(0,SIZE.x,4):
			var p := Vector2(x,y)
			var old := terrain_height_before(p,topology)
			var current := _height(p,topology)
			before.fill_rect(Rect2i(x,y,4,4),Color(old,0,0))
			after.fill_rect(Rect2i(x,y,4,4),Color(current,0,0))
			before_png.fill_rect(Rect2i(x,y,4,4),Color(old/4.0,old/4.0,old/4.0))
			after_png.fill_rect(Rect2i(x,y,4,4),Color(current/4.0,current/4.0,current/4.0))
			# Every 4px cell uses exact before/after analytic derivative.
			if x%4==0 and y%4==0:
				var normals: Array[Vector3]=[]
				for version in [0,1]:
					var dx: float=((terrain_height_before(p+Vector2(4,0),topology)-terrain_height_before(p-Vector2(4,0),topology)) if version==0 else (_height(p+Vector2(4,0),topology)-_height(p-Vector2(4,0),topology)))/(8.0*30.0/SIZE.x)
					var dz: float=((terrain_height_before(p+Vector2(0,4),topology)-terrain_height_before(p-Vector2(0,4),topology)) if version==0 else (_height(p+Vector2(0,4),topology)-_height(p-Vector2(0,4),topology)))/(8.0*Z_HALF*2.0/SIZE.y)
					normals.append(Vector3(-dx,1,-dz).normalized())
				normal_before.fill_rect(Rect2i(x,y,4,4),Color(normals[0].x*0.5+0.5,normals[0].y*0.5+0.5,normals[0].z*0.5+0.5))
				normal_after.fill_rect(Rect2i(x,y,4,4),Color(normals[1].x*0.5+0.5,normals[1].y*0.5+0.5,normals[1].z*0.5+0.5))
			if x in [200,280,340,420,500] and y in [200,240,280,320]:
				var projected := terrain_project(p,topology)
				witnesses.append({"source_point":[x,y],"height_before":old,"height_after":current,"delta_m":current-old,"projected_point":[projected.x,projected.y],"world_gradient":_gradient(p,topology)})
	before.save_exr(V11.PREFIX+"height_before.exr",true)
	after.save_exr(V11.PREFIX+"height_after.exr",true)
	before_png.save_png(V11.PREFIX+"height_before.png")
	after_png.save_png(V11.PREFIX+"height_after.png")
	normal_before.save_png(V11.PREFIX+"normal_before.png")
	normal_after.save_png(V11.PREFIX+"normal_after.png")
	_json(V11.PREFIX+"geometry.json",{"source_roi":[120,160,440,200],"projected_roi":[64,0,576,400],"height_units":"RF_EXR_world_metres_PNG_divide_4","height_sampling_resolution":4,"normal_resolution":4,"witnesses":witnesses,"mesh":"same_200x92_padded_grid_actual_vertex_height_and_analytic_normals_changed","route_controlpoints_frozen":true})


func _nav_freeze(actual: Image, old: Image, label: String) -> bool:
	actual.convert(Image.FORMAT_RGBA8)
	old.convert(Image.FORMAT_RGBA8)
	var mismatches := 0
	var changes := 0
	for y in SIZE.y:
		for x in SIZE.x:
			if actual.get_pixel(x,y)==old.get_pixel(x,y):
				continue
			changes+=1
			if not V11.HEIGHT_PROJECTED_ROI.has_point(Vector2(x,y)):
				mismatches+=1
	print("[V11 NavCapture] ",label," changed=",changes," outside approved projection=",mismatches)
	return mismatches==0


func _shadow_difference(on: Image, off: Image, land: Image) -> Image:
	on.convert(Image.FORMAT_RGBA8)
	off.convert(Image.FORMAT_RGBA8)
	var shadow := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
	var used_pixels := 0
	var excluded_nonzero := 0
	for y in SIZE.y:
		for x in SIZE.x:
			var bright := off.get_pixel(x,y)
			var shaded := on.get_pixel(x,y)
			var before := bright.r*0.299+bright.g*0.587+bright.b*0.114
			var after := shaded.r*0.299+shaded.g*0.587+shaded.b*0.114
			var alpha := clampf((before-after)/maxf(before,0.025),0.0,0.85)
			if alpha<0.015:
				continue
			var p := Vector2(x,y)
			var excluded := land.get_pixel(x,y).r<0.5 or V11.BRIDGE_DECK.has_point(p)
			for deck in V11.DOCK_DECKS:
				excluded=excluded or deck.has_point(p)
			if excluded:
				excluded_nonzero+=1
				continue
			shadow.set_pixel(x,y,Color(0,0,0,alpha))
			used_pixels+=1
	print("[V11 ShadowCapture] native nonzero pixels=",used_pixels," water/deck rejected numerical samples=",excluded_nonzero)
	return shadow


func _after_outputs_saved(topology: Image) -> void:
	# Do not call v10 or v9 hooks. New route is genuinely projected through
	# v11 height; old ferry polygons are immutable byte copies to v11 only.
	var route: Array=[]
	var road_end: Vector2=V11.ROAD_STOPS[-1]
	for x in range(32,roundi(road_end.x),16):
		var projected := terrain_project(Vector2(x,_road_y(x)),topology)
		route.append([projected.x,projected.y])
	var last := terrain_project(road_end,topology)
	route.append([last.x,last.y])
	var dock_rects: Array=[]
	for rect in V11.DOCK_DECKS:
		dock_rects.append([rect.position.x,rect.position.y,rect.size.x,rect.size.y])
	_json(V11.PREFIX+"route.json",{"road_feet":route,"bridge_deck":[1418,348,484,35],"dock_decks":dock_rects,"land_mask_excludes_structures":true})
	topology.save_png(V11.PREFIX+"topology.png")
	var suffixes: Array[String]=["ferry_pavilion_foreground.png","ferry_near_rail.png"]
	for part in V11.RAIL_PARTS:
		suffixes.append("ferry_rail_"+String(part["name"])+".png")
	for suffix in suffixes:
		var output := FileAccess.open(V11.PREFIX+suffix,FileAccess.WRITE)
		output.store_buffer(FileAccess.get_file_as_bytes(GEOGRAPHY.PREFIX+suffix))
		output.close()
	var geometry: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(V11.PREFIX+"geometry.json"))
	var steep: Array=[]
	for witness in geometry["witnesses"]:
		if witness["world_gradient"]>0.72 and witness["projected_point"][1]>=0:
			steep.append(witness)
	var gentle: Array=[]
	for p in [Vector2(900,390),Vector2(2390,735),Vector2(380,448),Vector2(560,368)]:
		var projected := terrain_project(p,topology)
		gentle.append({"source_point":[p.x,p.y],"projected_point":[projected.x,projected.y],"world_gradient":_gradient(p,topology)})
	var rois: Array=[]
	for rect in V11.VISUAL_ROIS:
		rois.append([rect.position.x,rect.position.y,rect.size.x,rect.size.y])
	_json(V11.PREFIX+"art.json",{"status":"ISOLATED_VISUAL_CANDIDATE","version":"v11","visual_status":"AWAITING_FIELD_REVIEW_NOT_PROMOTED","render_rounds":1,"geometry_contract":"v9_topology_v11_local_height_actual_capture","same_camera_visual_land_walk":true,"entities_baked":false,"replaced_ids":V11.REPLACED_IDS,"entities":_entities,"source_height_roi":[120,160,440,200],"projected_navigation_roi":[64,0,576,400],"visual_rois":rois,"height_normal_evidence":"geometry.json","steep_examples":steep,"gentle_examples":gentle,"shadow_on":"shadow_on.png","shadow_off":"shadow_off.png","shadow_layer":"shadow.png","shadow_capture_method":"same_ground_camera_material_light_model_transform_caster_ON_layer2_camera_layer1_vs_hidden_OFF_relative_luminance_difference_0.015_threshold","shadow_exclusions":["natural_water","bridge_deck","dock_decks"],"contact_soil_separate_from_cast":true,"legacy_lighting_exceptions":["city","bridge","ferry","nine_unreplaced_props"],"missing_resources_limit":"Shrub03_is_0.25_to_0.40m_herb_not_tree_no_tree_assets","v9_source_hashes":_frozen_hashes,"asset_sources":{"CC0":[GRASS_PH,ROAD_PH,BOULDER_DIFF,V11.BOULDER_SOURCE,V11.HERB_SOURCE],"existing_project_materials":[ROCK_MAT,WATER_MAT]}})


func _build() -> void:
	_freeze_hashes()
	# Include all old v10 source outputs as immutable baseline too.
	for suffix in ["visual.png","land.png","walk.png","art.json","route.json","topology.png"]:
		_frozen_hashes[V10.PREFIX+suffix]=_sha(V10.PREFIX+suffix)
	var topology := _read_png(GEOGRAPHY.PREFIX+"topology.png")
	var color := load(V10.PREFIX+"visual.png") as Texture2D
	var walk := load(V10.PREFIX+"walk.png") as Texture2D
	assert(topology!=null and color!=null and walk!=null)
	_prepare_models(topology)
	var selector := ImageTexture.create_from_image(topology)
	var off_viewport := _native_viewport(color,selector,topology,false)
	var on_viewport := _native_viewport(color,selector,topology,true)
	var mask_viewport := _make_viewport(color,_walk_texture(topology,walk),topology,true)
	var land_viewport := _make_viewport(color,selector,topology,true)
	var contact_viewport := _contact_viewport(color,selector,topology)
	for frame in range(32):
		await process_frame
	var off := off_viewport.get_texture().get_image()
	var on := on_viewport.get_texture().get_image()
	var mask_image := mask_viewport.get_texture().get_image()
	var land_image := land_viewport.get_texture().get_image()
	var contact := contact_viewport.get_texture().get_image()
	assert(off!=null and on!=null and mask_image!=null and land_image!=null)
	if not _nav_freeze(mask_image,_read_png(V10.PREFIX+"walk.png"),"walk") or not _nav_freeze(land_image,_read_png(V10.PREFIX+"land.png"),"land"):
		push_error("v11 actual nav capture changed outside approved geometry projected ROI; stop for producer decision")
		quit(1)
		return
	var shadow := _shadow_difference(on,off,land_image)
	if shadow.get_used_rect().size==Vector2i.ZERO:
		push_error("v11 actual compatibility native cast capture remains empty; FAIL, no procedural shadow substitute")
		quit(1)
		return
	assert(_save_pair(off,"visual") and _save_pair(on,"shadow_on") and _save_pair(off,"shadow_off") and _save_pair(shadow,"shadow") and _save_pair(mask_image,"walk") and _save_pair(land_image,"land") and _save_pair(contact,"contact"))
	for viewport in [off_viewport,on_viewport,mask_viewport,land_viewport,contact_viewport]:
		viewport.queue_free()
	await process_frame
	for entry in _models:
		await _capture_entity(color,selector,topology,entry)
	_geometry_diagnostics(topology)
	_after_outputs_saved(topology)
	for path in _frozen_hashes:
		assert(_sha(path)==_frozen_hashes[path],"Old immutable v9/v10 file modified")
	for entry in _models:
		entry["node"].free()
	print("[WorldNativePairV11] FIRST native local-relief/two-rock/eight-herb/cast-shadow candidate READY for producer import/review; no formal promotion")
	quit(0)

