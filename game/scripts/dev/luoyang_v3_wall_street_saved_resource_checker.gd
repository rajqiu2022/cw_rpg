extends RefCounted
## NEW independent stored-resource oracle. Read-only; never executes a builder,
## material adapter or capture. Recipe controls below are project specifications,
## not metadata-derived geometry. PENDING pins refuse every candidate.
const OLD_ROOT := "res://art/maps/luoyang_modular_v3_street_detail_proposal/root_material_v1/"
const NEW_ROOT := "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v4/"
const OLD_MANIFEST_SHAS := {
	"ch4_s0_luoyang_gate":"54e963a515bdc057a85491e082cbf705e48c9c68e718e896fe2dac01375ca704",
	"ch4_s1_luoyang_yamen":"c50902972d08575f1aafd2e08644467981bb55de97392cf70234ef3c77c4fe49",
	"ch4_s2_canal_docks":"f6fae4d241fa076a1ee30ff53618007d260be6d1941a3bb75d5ed8485a424cc9",
	"ch4_s3_luoyang_market":"183f19e16d22ad451e44293682e66f8250f4215fdae2031f7170f9d0fff998ac"}
const GEOMETRY_ID := "PROJECT_CITY_RETAINED_FOOT_FINER_UPPER_MASONRY_CURVED_TILE_V1"
const MATERIAL_ID := "PROJECT_CONTINUOUS_TRAFFIC_APRON_QUAY_FINE_MASONRY_FINISH_V1"
const EXECUTOR := "res://scripts/dev/build_luoyang_modular_v3_wall_street_capture_proposal.gd"
const SURFACE := "res://scripts/dev/luoyang_modular_v3_wall_street_surface_proposal.gd"
const ADAPTER := "res://scripts/dev/build_luoyang_modular_v3_wall_street_adapter_proposal.gd"
const PINS := {
	EXECUTOR:"8282794a079f9118c6a4e5fbba482d682b092676882a74df6972ce6bfa64b771",
	SURFACE:"7ccbb9f4a27234de3da4d41076e5374d7702d276a01c13e968c5790f537153eb",
	ADAPTER:"531bfcee9eababe944fd366904355fab57a74b47104eaba2598c6224f3d69f2c"}
const OLD_STREET_SURFACE := "res://scripts/dev/luoyang_modular_v3_street_detail_surface_proposal.gd"
const OLD_STREET_SURFACE_SHA := "5f6a3f901645bdaed5e8a544c617375e2e2e02f5f2730b42d43895cf129c4dfa"
const RETAINED := [0,1,2,3,4,5,6,7,41,43,45,47,49,51]
const TEXTURES := {
	"original_stone":"res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png",
	"registered_normal":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_nor_gl_2k.jpg",
	"registered_arm":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_arm_2k.jpg"}
const ALPHA_ID := "RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1"
const ALPHA_EPSILON := .00001
const TEXTURE_SHAS := {
	"res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png":"7e9c7d892f86ced04ad3b8ad293208e05d87a01afffc2729804e4469f87deb7d",
	"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_diff_2k.jpg":"fe9013368539b5604602e64bfa48bef1a2a4c452fcb6894868fb556d0b14501c",
	"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_nor_gl_2k.jpg":"70427a2c81f85c0e1ee4a147e273d028c3d0188bad2583f2509d6df9a3d55b89",
	"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_arm_2k.jpg":"a954de58336738e6f963466f1453202ef7e186bd6492106c3b989c39f0d2e23c"}

static func validate(record: Dictionary,catalog: Dictionary,id: StringName) -> String:
	var region: String=String(id)
	if not OLD_MANIFEST_SHAS.has(region): return "Unknown new wall/street city region"
	for path: String in PINS:
		if not _hash(PINS[path]) or FileAccess.get_sha256(path).to_lower()!=PINS[path]: return "New wall/street executed source PENDING/missing/changed: "+path
	var old_prefix: String=OLD_ROOT+region+"/"
	var prefix: String=NEW_ROOT+region+"/"
	var old_path: String=old_prefix+"art_contract.json"
	if FileAccess.get_sha256(old_path).to_lower()!=OLD_MANIFEST_SHAS[region]: return "Frozen current street-detail baseline manifest changed"
	var old_value: Variant=JSON.parse_string(FileAccess.get_file_as_string(old_path))
	if not old_value is Dictionary or not old_value.get("asset_sha256") is Dictionary: return "Frozen street-detail baseline malformed"
	var old: Dictionary=old_value
	for path: Variant in old.asset_sha256:
		if not path is String or not _hash(old.asset_sha256[path]) or FileAccess.get_sha256(path).to_lower()!=String(old.asset_sha256[path]).to_lower(): return "Frozen street-detail catalog changed: "+str(path)
	for path: Variant in catalog:
		if not path is String or not String(path).begins_with("res://") or ".." in String(path) or not _hash(catalog[path]) or FileAccess.get_sha256(path).to_lower()!=String(catalog[path]).to_lower(): return "New wall/street catalog missing/changed: "+str(path)
	var revision: Variant=record.get("upper_wall_street_revision")
	if record.get("scope")!="ISOLATED_WALL_STREET_GEOMETRY_PROPOSAL_NOT_RUNTIME_OR_FORMAL_APPROVED" or not revision is Dictionary or revision.get("identity")!=GEOMETRY_ID or revision.get("scope")!="NEW_UPPER_GEOMETRY_AND_ALPHA_NOT_MATERIAL_ONLY" or revision.get("production_approved")!=false or revision.get("baseline_manifest_path")!=old_path or String(revision.get("baseline_manifest_sha256","")).to_lower()!=OLD_MANIFEST_SHAS[region]: return "Missing honest changed-upper-geometry baseline/scope"
	var graph: Variant=record.get("capture_graph")
	if not graph is Dictionary: return "New wall/street actual capture graph absent"
	for pair: Array in [["builder_script",EXECUTOR],["surface_script",SURFACE],["material_adapter_script",ADAPTER]]:
		var node: Variant=graph.get(pair[0])
		if not node is Dictionary or node.get("path")!=pair[1] or String(node.get("sha256","")).to_lower()!=PINS[pair[1]] or not catalog.has(pair[1]) or String(catalog[pair[1]]).to_lower()!=PINS[pair[1]]: return "New exact source graph mismatch: "+str(pair[0])
	var surface_binding: Variant=record.get("capture_surface_binding")
	if not surface_binding is Dictionary or surface_binding.get("path")!=SURFACE or String(surface_binding.get("sha256","")).to_lower()!=PINS[SURFACE] or surface_binding.get("actual_instance_equals_prepared_adapter_surface")!=true: return "Actual new surface instance not bound"
	for key: String in ["canonical_scene_id","logical_size_px","pixel_sampling","physical_navigation_margin_px","ordinary_actor_body_px","ordinary_actor_visual_scale","entry_foot_px","return_foot_px","gameplay_slots","routes","npc_stations","interaction_anchors","height_grid","capture_camera","authority_camera"]:
		if not _equal(old.get(key),record.get(key)): return "Upper-wall proposal changed protected city semantics/camera: "+key
	for file: String in ["land.png","raw_walk.png","walk.png","terrain_height.rf","capture_camera.json","authority_camera.json"]:
		if not _catalog_file(catalog,prefix+file) or FileAccess.get_sha256(old_prefix+file)=="" or FileAccess.get_sha256(old_prefix+file)!=FileAccess.get_sha256(prefix+file): return "Upper-wall proposal changed protected authority/camera bytes: "+file
	var geometry_files: Array[String]=["paving_mesh.res","support_plane.res"]
	if region=="ch4_s2_canal_docks": geometry_files.append_array(["canal_bed_mesh.res","water_plane.res","quay_wall_mesh.res"])
	for file: String in geometry_files:
		if not _catalog_file(catalog,prefix+file): return "Actual protected ground mesh not in current catalog: "+file
		var error: String=_meshes_error(old_prefix+file,prefix+file,file)
		if error!="": return error
	var ground_error: String=_ground_repeat_error(prefix,catalog)
	if ground_error!="": return ground_error
	var material_error: String=_paving_error(record,catalog,prefix,old_prefix)
	if material_error!="": return material_error
	var before_objects: Variant=old.get("objects")
	var objects: Variant=record.get("objects")
	if not before_objects is Array or not objects is Array or before_objects.size()!=objects.size(): return "Upper-wall proposal changed full object set"
	var previous: Dictionary={}
	for item: Variant in before_objects:
		if not item is Dictionary or previous.has(item.get("id")): return "Malformed frozen baseline object IDs"
		previous[item.id]=item
	var seen: Dictionary={}
	var prototypes: Dictionary={}
	for item: Variant in objects:
		if not item is Dictionary or not previous.has(item.get("id")) or seen.has(item.get("id")): return "Upper-wall proposal changed object identity"
		seen[item.id]=true
		var before: Dictionary=previous[item.id]
		for key: String in ["id","prototype","world_foot_px","depth_foot_y","physical_center_px","collision_size_px","solid_polygons_px","blocking","z_index","sort_by_feet","ghost_occlusion","walk_support","role"]:
			if not _equal(before.get(key),item.get(key)): return "Upper-wall proposal changed physical/feet identity: "+str(item.id)+"/"+key
		var kind: String=String(item.get("prototype",""))
		var wall: bool=kind in ["wall_horizontal","wall_vertical"]
		if not wall:
			for key: String in ["render_size_px","foot_uv","source_size_px"]:
				if not _equal(before.get(key),item.get(key)): return "Unaffected object draw mapping changed: "+str(item.id)+"/"+key
			if FileAccess.get_sha256(String(before.get("texture","")))=="" or FileAccess.get_sha256(String(before.texture))!=FileAccess.get_sha256(String(item.get("texture",""))): return "Unaffected source/body PNG changed: "+str(item.id)
		if kind=="": continue
		var stem: String=prefix+"entities/native_"+kind
		var old_stem: String=old_prefix+"entities/native_"+kind
		var metadata_value: Variant=JSON.parse_string(FileAccess.get_file_as_string(stem+".json"))
		var old_metadata: Variant=JSON.parse_string(FileAccess.get_file_as_string(old_stem+".json"))
		if not metadata_value is Dictionary or not old_metadata is Dictionary: return "Actual native prototype metadata missing: "+kind
		var metadata: Dictionary=metadata_value
		for key: String in ["render_size_px","foot_uv","source_size_px"]:
			if not _equal(item.get(key),metadata.get(key)): return "Instance differs from current actual prototype mapping: "+str(item.id)+"/"+key
		if String(item.get("texture",""))!=stem+".png": return "Native instance texture not exact current prototype: "+str(item.id)
		var transform_error: String=_caster_error(item,metadata)
		if transform_error!="": return transform_error
		if prototypes.has(kind): continue
		prototypes[kind]=true
		for suffix: String in [".res",".json",".png","_raw.png","_raw_repeat.png"]:
			if not _catalog_file(catalog,stem+suffix): return "Incomplete actual native catalog: "+kind+suffix
		if wall:
			var error: String=_wall_error(metadata,old_metadata,catalog,stem,old_stem,region)
			if error!="": return error
		else:
			var error: String=_meshes_error(old_stem+".res",stem+".res",kind)
			if error!="": return error
			for key: String in ["kind","support_m","draw_basis_columns","used_bounds_m","actual_used_vertices","scale","source_min_vertex_ground_delta_m","crop_rect_px","source_size_px","render_size_px","foot_uv","raw_camera","alpha_resampling_algorithm"]:
				if not _equal(old_metadata.get(key),metadata.get(key)): return "Unaffected native geometry/body mapping changed: "+kind+"/"+key
			for suffix: String in [".png","_raw.png","_raw_repeat.png"]:
				if FileAccess.get_sha256(old_stem+suffix)!=FileAccess.get_sha256(stem+suffix): return "Unaffected native rendered bytes changed: "+kind+suffix
			var a: Mesh=ResourceLoader.load(old_stem+".res","",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
			var b: Mesh=ResourceLoader.load(stem+".res","",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
			for index in range(a.get_surface_count()):
				var problem: String=_material_equal_error(a.surface_get_material(index),b.surface_get_material(index))
				if problem!="": return "Unaffected native actual material changed: "+kind+"/"+problem
	return ""

static func _wall_error(metadata: Dictionary,old_metadata: Dictionary,catalog: Dictionary,stem: String,old_stem: String,region: String) -> String:
	var kind: String=String(metadata.get("kind",""))
	var horizontal: bool=kind=="wall_horizontal"
	if kind not in ["wall_horizontal","wall_vertical"]: return "Unknown upper-wall geometry role"
	var a: ArrayMesh=ResourceLoader.load(old_stem+".res","",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var b: ArrayMesh=ResourceLoader.load(stem+".res","",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if a==null or b==null or a.get_surface_count()!=54 or b.get_surface_count()!=18: return "Actual upper-wall surface set is not old54/new18"
	var revision: Variant=metadata.get("upper_wall_geometry_revision")
	if not revision is Dictionary or revision.get("algorithm_identity")!=GEOMETRY_ID or revision.get("identity")!=GEOMETRY_ID or revision.get("not_material_only")!=true or revision.get("scope")!="NEW_UPPER_GEOMETRY_AND_ALPHA; NOT_MATERIAL_ONLY; unchanged foot/support/physical layout/navigation.": return "Actual new wall geometry identity missing"
	if revision.get("original_mesh_path")!=old_stem+".res" or revision.get("original_mesh_sha256")!=FileAccess.get_sha256(old_stem+".res"): return "New wall baseline original saved mesh unbound"
	if revision.get("actual_mesh_path")!=stem+".res" or revision.get("actual_mesh_sha256")!=catalog[stem+".res"] or metadata.get("geometry_change_scope")!="NEW_UPPER_WALL_GEOMETRY_AND_ALPHA_NOT_MATERIAL_ONLY": return "Actual revised wall is not bound to its current stored geometry"
	if not _json_exact(revision.get("old_surface_count"),54) or not _json_exact(revision.get("new_surface_count"),18) or not _json_exact(revision.get("new_surface_range"),[14,17]): return "Upper-wall declared surface partition differs"
	var recipe_value: Variant=revision.get("new_surface_recipe")
	if not recipe_value is Dictionary or not recipe_value.get("upper_bricks") is Dictionary: return "Actual merged-brick recipe absent"
	var bricks: Dictionary=recipe_value.upper_bricks
	var expected_brick_recipe: Dictionary={"first_surface":14,"rows":12,"columns":20,"merged_source_brick_surface_count":240}
	for key: String in expected_brick_recipe:
		if not _num(bricks.get(key),float(expected_brick_recipe[key])): return "Actual complete merged-brick recipe identity differs: "+key
	if bricks.get("merged_surface")!=true: return "Actual upper brick surface is not the complete merged native geometry"
	for pair: Array in [["cornice",15],["curved_tiles",16],["ridge",17]]:
		var part: Variant=recipe_value.get(pair[0])
		if not part is Dictionary or not _num(part.get("surface_index"),float(pair[1])): return "Actual upper surface recipe mapping differs"
	var roof_recipe: Dictionary=recipe_value.curved_tiles
	var expected_roof: Dictionary={"column_count":32,"course_count_per_wing":2,"wings":2,"along_sections":4,"column_pitch_m":.15625,"column_gap_m":.018,"course_gap_fraction":.012}
	for key: String in expected_roof:
		if not _num(roof_recipe.get(key),float(expected_roof[key])): return "Actual revised curved-tile recipe differs: "+key
	if roof_recipe.get("peak_formula")!="y=1.94-.21*abs(across)/half+.035*sin(PI*t)*(1-abs(across)/half*.35)": return "Actual revised curved-tile mathematical identity differs"
	var mapping: Variant=revision.get("retained_surface_map")
	if not mapping is Array or mapping.size()!=RETAINED.size(): return "Retained support surface map incomplete"
	var removed: Array[int]=[]
	for index in range(54):
		if not index in RETAINED: removed.append(index)
	if not _json_exact(revision.get("replaced_original_surface_indices"),removed): return "Unexpected removed upper-wall original surfaces"
	for index in range(RETAINED.size()):
		var old_index: int=RETAINED[index]
		var row: Variant=mapping[index]
		if not row is Dictionary or not _num(row.get("old_index"),old_index) or not _num(row.get("new_index"),index) or not _num(row.get("primitive"),a.surface_get_primitive_type(old_index)): return "Retained surface identity differs"
		var error: String=_surface_error(a,old_index,b,index,"retained")
		if error!="": return error
		var slots: Variant=row.get("slots")
		if not slots is Array or slots.size()!=Mesh.ARRAY_MAX: return "Retained surface full slot evidence incomplete"
		var actual: Array=b.surface_get_arrays(index)
		for slot in range(Mesh.ARRAY_MAX):
			var entry: Variant=slots[slot]
			var sha: String=_sha(var_to_bytes(actual[slot]))
			if not entry is Dictionary or not _num(entry.get("slot"),slot) or entry.get("old_sha256")!=sha or entry.get("new_sha256")!=sha or entry.get("byte_exact")!=true: return "Retained support slot record differs from actual bytes"
	var control: ArrayMesh=_upper_control(horizontal)
	if control==null or control.get_surface_count()!=4: return "Independent upper-wall mathematical control failed"
	for index in range(control.get_surface_count()):
		var error: String=_surface_error(control,index,b,index+14,"independent finer-brick/cornice/curved-tile/ridge")
		if error!="": return error
	var curved: Dictionary=_curved_geometry_evidence(b,16)
	if curved.is_empty() or curved.triangle_count!=1024 or curved.clockwise_up_faces!=1024 or curved.degenerate_faces!=0 or curved.actual_normal_y_min<=0.0 or not _json_exact(revision.get("actual_curved_roof_winding_normal_evidence"),curved): return "Actual curved tile winding/normals differ from independent stored triangles"
	for flag: String in ["actual_saved_arrays_byte_exact_to_captured_mesh","actual_saved_materials_exact_to_captured_mesh","actual_support_vector_count_minY_byte_exact"]:
		if revision.get(flag)!=true: return "Actual wall capture/stored/support evidence incomplete: "+flag
	var all_slots: Variant=revision.get("actual_all_surface_slots")
	if not all_slots is Array or all_slots.size()!=18: return "Complete actual new-wall array evidence missing"
	for index in range(18):
		var row: Variant=all_slots[index]
		if not row is Dictionary or not _num(row.get("surface_index"),index) or not _num(row.get("primitive"),b.surface_get_primitive_type(index)) or not row.get("slots") is Array or row.slots.size()!=Mesh.ARRAY_MAX: return "Actual new-wall surface primitive/slots evidence malformed"
		var arrays: Array=b.surface_get_arrays(index)
		for slot in range(Mesh.ARRAY_MAX):
			var entry: Variant=row.slots[slot]
			if not entry is Dictionary or not _num(entry.get("slot"),slot) or not _num(entry.get("variant_type"),typeof(arrays[slot])) or entry.get("sha256")!=_sha(var_to_bytes(arrays[slot])): return "Actual new-wall slot metadata disagrees with stored .res"
	var old_bounds: Dictionary=_used_bounds(a)
	var bounds: Dictionary=_used_bounds(b)
	if old_bounds.is_empty() or bounds.is_empty(): return "Invalid actual used-index bounds"
	for key: String in ["support","support_count"]:
		if var_to_bytes(old_bounds[key])!=var_to_bytes(bounds[key]): return "New full-mesh minimum2% changed actual original support: "+key
	if old_bounds.minimum.y!=bounds.minimum.y: return "New upper wall changed lowest actual vertex"
	for pair: Array in [["support_old",old_bounds],["support_new",bounds]]:
		var measured: Dictionary=pair[1]
		var expected: Dictionary={"valid":true,"minimum_m":_v3(measured.minimum),"maximum_m":_v3(measured.maximum),"support_m":_v3(measured.support),"support_count":measured.support_count,"actual_used_vertices":measured.actual_used_vertices}
		if not _json_exact(revision.get(pair[0]),expected): return "Actual old/new complete used-index support evidence differs"
	if not _json_exact(metadata.get("support_m"),_v3(bounds.support)) or not _json_exact(metadata.get("used_bounds_m"),{"minimum":_v3(bounds.minimum),"maximum":_v3(bounds.maximum)}) or not _json_exact(metadata.get("actual_used_vertices"),bounds.actual_used_vertices): return "Current wall metadata differs from independently measured stored native bounds/support"
	for key: String in ["draw_basis_columns","raw_camera","scale","support_m","source_min_vertex_ground_delta_m"]:
		if not _equal(old_metadata.get(key),metadata.get(key)): return "New wall changed retained capture basis/camera/support: "+key
	if not _json_exact(metadata.get("draw_basis_columns"),[_v3(Vector3.RIGHT),_v3(Vector3.UP),_v3(Vector3.BACK)]) or not _num(metadata.get("scale"),1): return "New wall draw basis is not actual identity"
	var rows: Variant=revision.get("actual_surface_materials")
	if not rows is Array or rows.size()!=18: return "Actual new wall saved material evidence incomplete"
	var source_material: ShaderMaterial=a.surface_get_material(0) as ShaderMaterial
	if source_material==null or source_material.shader==null: return "Frozen actual masonry material unavailable"
	var checked: Dictionary={}
	for index in range(18):
		var row: Variant=rows[index]
		var material: ShaderMaterial=b.surface_get_material(index) as ShaderMaterial
		if not row is Dictionary or material==null or material.shader==null or not _num(row.get("surface_index"),index): return "Actual stored new wall surface/material identity missing"
		var curve: bool=index in [16,17]
		var expected_code: String=_masonry_code(source_material.shader.code,curve)
		if material.shader.code!=expected_code: return "Actual saved wall shader differs from independent frozen-code recipe: "+str(index)
		var tint:=Vector3(.99,.99,.97) if curve else (Vector3(.88,.88,.875) if index==15 else Vector3(.95,.95,.95))
		var parameters: Dictionary={"masonry_tint":tint,"masonry_profile":1.0 if region=="ch4_s1_luoyang_yamen" else 0.0}
		if curve: parameters["actual_curved_tile_geometry_identity"]=1.0
		var error: String=_uniform_error(row,material,parameters,catalog,checked)
		if error!="": return "Stored wall "+str(index)+": "+error
	var render_error: String=_body_error(metadata,catalog,stem)
	if render_error!="": return render_error
	return ""

static func _upper_control(horizontal: bool) -> ArrayMesh:
	# No adapter/builder call. Fixed dimensions and construction order separately
	# reproduce real native packing; every ARRAY_MAX slot remains byte-exact.
	var mesh:=ArrayMesh.new()
	var individual_bricks:=ArrayMesh.new()
	var thickness: float=22.0/32.0 if horizontal else 26.0/64.0
	for course in range(12):
		for brick in range(20):
			var left: float=-2.5+float(brick)*.25+(.125 if course%2==1 else 0.0)
			var right: float=minf(left+.25,2.5)
			if course%2==1 and brick==0: left=-2.5
			var middle: float=(left+right)*.5
			var dimensions:=Vector3(right-left-.007,.114,thickness) if horizontal else Vector3(thickness,.114,right-left-.007)
			var center:=Vector3(middle,.303+float(course)*.122,0) if horizontal else Vector3(0,.303+float(course)*.122,middle)
			_control_box(individual_bricks,dimensions,center)
	# First native-pack each independent BoxMesh, then concatenate its actual
	# stored attributes and offset only indices. All 240 boxes remain present;
	# this changes surface organization, not geometry or support precision.
	var joined: Array=_control_brick_union(individual_bricks)
	if joined.is_empty(): return null
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,joined)
	_control_box(mesh,Vector3(5,.04,thickness+.035) if horizontal else Vector3(thickness+.035,.04,5),Vector3(0,1.685,0))
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_span: float=(thickness+.10)*.5
	for wing: float in [-1.0,1.0]:
		for course in range(2):
			var inner: float=wing*half_span*(float(course)/2.0+.006)
			var outer: float=wing*half_span*((float(course)+1.0)/2.0-.006)
			for tile in range(32):
				var start: float=-2.5+float(tile)*.15625+.009
				var width: float=.15625-.018
				for section in range(4):
					var t0: float=float(section)/4.0
					var t1: float=float(section+1)/4.0
					var a: Vector3=_roof_point(horizontal,half_span,start+width*t0,inner,t0)
					var b: Vector3=_roof_point(horizontal,half_span,start+width*t1,inner,t1)
					var c: Vector3=_roof_point(horizontal,half_span,start+width*t0,outer,t0)
					var d: Vector3=_roof_point(horizontal,half_span,start+width*t1,outer,t1)
					if (b-a).cross(c-a).y>0.0:
						_control_triangle(tool,a,c,b,horizontal)
						_control_triangle(tool,b,c,d,horizontal)
					else:
						_control_triangle(tool,a,b,c,horizontal)
						_control_triangle(tool,b,d,c,horizontal)
	var roof: ArrayMesh=tool.commit()
	if roof==null: return null
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,roof.surface_get_arrays(0))
	_control_box(mesh,Vector3(5,.025,.065) if horizontal else Vector3(.065,.025,5),Vector3(0,1.9675,0))
	return mesh

static func _control_brick_union(bricks: ArrayMesh) -> Array:
	if bricks.get_surface_count()!=240: return []
	var vertices:=PackedVector3Array()
	var normals:=PackedVector3Array()
	var tangents:=PackedFloat32Array()
	var uv:=PackedVector2Array()
	var indices:=PackedInt32Array()
	for surface in range(240):
		if bricks.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES: return []
		var arrays: Array=bricks.surface_get_arrays(surface)
		if arrays.size()!=Mesh.ARRAY_MAX or not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array or not arrays[Mesh.ARRAY_NORMAL] is PackedVector3Array or not arrays[Mesh.ARRAY_TANGENT] is PackedFloat32Array or not arrays[Mesh.ARRAY_TEX_UV] is PackedVector2Array or not arrays[Mesh.ARRAY_INDEX] is PackedInt32Array: return []
		var offset: int=vertices.size()
		vertices.append_array(arrays[Mesh.ARRAY_VERTEX])
		normals.append_array(arrays[Mesh.ARRAY_NORMAL])
		tangents.append_array(arrays[Mesh.ARRAY_TANGENT])
		uv.append_array(arrays[Mesh.ARRAY_TEX_UV])
		for index: int in arrays[Mesh.ARRAY_INDEX]: indices.append(offset+index)
		for slot in range(Mesh.ARRAY_MAX):
			if slot not in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_INDEX] and arrays[slot]!=null: return []
	var result: Array=[]
	result.resize(Mesh.ARRAY_MAX)
	result[Mesh.ARRAY_VERTEX]=vertices
	result[Mesh.ARRAY_NORMAL]=normals
	result[Mesh.ARRAY_TANGENT]=tangents
	result[Mesh.ARRAY_TEX_UV]=uv
	result[Mesh.ARRAY_INDEX]=indices
	return result

static func _control_box(mesh: ArrayMesh,dimensions: Vector3,center: Vector3) -> void:
	var primitive:=BoxMesh.new()
	primitive.size=dimensions
	var arrays: Array=primitive.get_mesh_arrays()
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	for index in range(vertices.size()): vertices[index]+=center
	arrays[Mesh.ARRAY_VERTEX]=vertices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)

static func _curved_geometry_evidence(mesh: ArrayMesh,surface: int) -> Dictionary:
	var arrays: Array=mesh.surface_get_arrays(surface)
	if arrays.size()!=Mesh.ARRAY_MAX or not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array or not arrays[Mesh.ARRAY_NORMAL] is PackedVector3Array: return {}
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var indices:=PackedInt32Array()
	if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array: indices=arrays[Mesh.ARRAY_INDEX]
	elif arrays[Mesh.ARRAY_INDEX]!=null: return {}
	var draw:=PackedVector3Array()
	if indices.is_empty(): draw=vertices
	else:
		for index: int in indices:
			if index<0 or index>=vertices.size(): return {}
			draw.append(vertices[index])
	if draw.is_empty() or draw.size()%3!=0 or normals.is_empty(): return {}
	var minimum: float=INF
	var maximum: float=-INF
	for normal: Vector3 in normals:
		if not normal.is_finite(): return {}
		minimum=minf(minimum,normal.y)
		maximum=maxf(maximum,normal.y)
	var clockwise: int=0
	var degenerate: int=0
	for offset in range(0,draw.size(),3):
		var cross: Vector3=(draw[offset+1]-draw[offset]).cross(draw[offset+2]-draw[offset])
		if cross.length_squared()==0.0: degenerate+=1
		if cross.y<0.0: clockwise+=1
	var slots: Array[Dictionary]=[]
	for slot in range(Mesh.ARRAY_MAX): slots.append({"slot":slot,"variant_type":typeof(arrays[slot]),"sha256":_sha(var_to_bytes(arrays[slot]))})
	return {"surface_index":surface,"primitive_type":mesh.surface_get_primitive_type(surface),"vertex_count":vertices.size(),"normal_count":normals.size(),"index_count":indices.size(),"actual_draw_vertex_count":draw.size(),"triangle_count":int(draw.size()/3),"actual_normal_y_min":minimum,"actual_normal_y_max":maximum,"clockwise_up_faces":clockwise,"degenerate_faces":degenerate,"normal_sha256":_sha(var_to_bytes(normals)),"all_actual_surface_array_slots":slots}

static func _roof_point(horizontal: bool,half: float,along: float,across: float,t: float) -> Vector3:
	var height: float=1.94-.21*absf(across)/half+.035*sin(PI*t)*(1.0-absf(across)/half*.35)
	return Vector3(along,height,across) if horizontal else Vector3(across,height,along)

static func _control_triangle(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,horizontal: bool) -> void:
	var normal: Vector3=-(b-a).cross(c-a).normalized()
	for point: Vector3 in [a,b,c]:
		tool.set_normal(normal)
		tool.set_uv(Vector2(point.x,absf(point.z))/1.5 if horizontal else Vector2(point.z,absf(point.x))/1.5)
		tool.add_vertex(point)

static func _used_bounds(mesh: ArrayMesh) -> Dictionary:
	var points:=PackedVector3Array()
	var minimum:=Vector3(INF,INF,INF)
	var maximum:=Vector3(-INF,-INF,-INF)
	for surface in range(mesh.get_surface_count()):
		if mesh.surface_get_primitive_type(surface)!=Mesh.PRIMITIVE_TRIANGLES: return {}
		var arrays: Array=mesh.surface_get_arrays(surface)
		if arrays.size()!=Mesh.ARRAY_MAX or not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array: return {}
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices:=PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array: indices=arrays[Mesh.ARRAY_INDEX]
		elif arrays[Mesh.ARRAY_INDEX]!=null: return {}
		if indices.is_empty():
			for index in range(vertices.size()): indices.append(index)
		if indices.is_empty() or indices.size()%3!=0: return {}
		var seen: Dictionary={}
		for index: int in indices:
			if index<0 or index>=vertices.size() or not vertices[index].is_finite(): return {}
			if seen.has(index): continue
			seen[index]=true
			minimum=minimum.min(vertices[index])
			maximum=maximum.max(vertices[index])
			points.append(vertices[index])
	if points.is_empty(): return {}
	var sum: float=0.0
	var front: float=-INF
	var count: int=0
	for point: Vector3 in points:
		if point.y<=minimum.y+(maximum.y-minimum.y)*.02:
			sum+=point.x
			front=maxf(front,point.z)
			count+=1
	if count==0: return {}
	return {"minimum":minimum,"maximum":maximum,"support":Vector3(sum/count,minimum.y,front),"support_count":count,"actual_used_vertices":points.size()}

static func _surface_error(a: Mesh,ai: int,b: Mesh,bi: int,label: String) -> String:
	if not a is ArrayMesh or not b is ArrayMesh: return "Unknown array representation: "+label
	var aa_mesh: ArrayMesh=a as ArrayMesh
	var bb_mesh: ArrayMesh=b as ArrayMesh
	if aa_mesh.surface_get_primitive_type(ai)!=bb_mesh.surface_get_primitive_type(bi): return "Stored primitive changed: "+label
	var aa: Array=a.surface_get_arrays(ai)
	var bb: Array=b.surface_get_arrays(bi)
	if aa.size()!=Mesh.ARRAY_MAX or bb.size()!=Mesh.ARRAY_MAX: return "Incomplete native surface: "+label
	for slot in range(Mesh.ARRAY_MAX):
		if var_to_bytes(aa[slot])!=var_to_bytes(bb[slot]): return "Stored native slot mismatch: "+label+"/"+str(ai)+"→"+str(bi)+"/"+str(slot)
	return ""

static func _meshes_error(old_path: String,new_path: String,label: String) -> String:
	var a: Mesh=ResourceLoader.load(old_path,"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	var b: Mesh=ResourceLoader.load(new_path,"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	if a==null or b==null or a.get_class()!=b.get_class() or a.get_surface_count()<=0 or a.get_surface_count()!=b.get_surface_count(): return "Protected mesh representation/count changed: "+label
	for index in range(a.get_surface_count()):
		if a is ArrayMesh:
			var error: String=_surface_error(a,index,b,index,label)
			if error!="": return error
		elif a is PrimitiveMesh and b is PrimitiveMesh:
			var aa: Array=a.surface_get_arrays(index)
			var bb: Array=b.surface_get_arrays(index)
			if aa.size()!=Mesh.ARRAY_MAX or bb.size()!=Mesh.ARRAY_MAX: return "Incomplete primitive array set: "+label
			for slot in range(Mesh.ARRAY_MAX):
				if var_to_bytes(aa[slot])!=var_to_bytes(bb[slot]): return "Protected primitive slot changed: "+label
		else: return "Unknown protected mesh representation: "+label
	if a is PrimitiveMesh:
		if a.get_faces().is_empty() or a.get_faces().to_byte_array()!=b.get_faces().to_byte_array(): return "Protected primitive triangles changed: "+label
		for property: Dictionary in a.get_property_list():
			var name: String=property.name
			if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or name in ["material","resource_path","resource_name","resource_local_to_scene","script"]: continue
			if var_to_bytes(a.get(name))!=var_to_bytes(b.get(name)): return "Protected primitive geometry parameter changed: "+label+"/"+name
	return ""

static func _masonry_code(baseline: String,curve: bool) -> String:
	# Exact root_wall_v4 recipe. Keep independent reconstruction and complete
	# shader equality; do not accept a saved code hash as its own specification.
	var code: String=baseline.replace("cap=smoothstep(1.22,1.28,p.y)","cap=smoothstep(1.66,1.70,p.y)")
	code=code.replace("vec3 brick=vec3(.355,.37,.38)*(.79+luma*.36)+(stone-vec3(luma))*.05;","vec3 brick=vec3(.34,.355,.365)*(.58+luma*.85)+(stone-vec3(luma))*.13;")
	code=code.replace("vec3 lime=vec3(.675,.675,.65)*(.95+luma*.07);","vec3 lime=vec3(.70,.695,.665)*(.87+luma*.20);")
	code=code.replace("face*=.975+(age-.5)*.035;","face*=.965+(age-.5)*.075;")
	code=code.replace("tangent*d.x*.032+bitangent*d.y*.032","tangent*d.x*.075+bitangent*d.y*.075")
	if curve:
		code=code.replace("uniform vec3 masonry_tint=vec3(1.);","uniform float actual_curved_tile_geometry_identity=1.;\nuniform vec3 masonry_tint=vec3(1.);")
		code=code.replace("vec3 face=masonry_profile>.5?lime:brick;","vec3 face=vec3(.265,.28,.29)*(.79+luma*.35)+(stone-vec3(luma))*.055;")
		code=code.replace("face=mix(face,vec3(.25,.27,.285)*(.83+luma*.28),base);","// Real narrow curved tile vertices, not material-only barrel illusion.")
		code=code.replace("face=mix(face,vec3(.25,.265,.275)*(.86+luma*.23),cap);","face*=actual_curved_tile_geometry_identity;")
	return code

static func _uniform_error(row: Dictionary,material: ShaderMaterial,parameters: Dictionary,catalog: Dictionary,checked: Dictionary) -> String:
	var expected: Dictionary={"original_stone":TYPE_OBJECT,"registered_normal":TYPE_OBJECT,"registered_arm":TYPE_OBJECT}
	for name: String in parameters: expected[name]=typeof(parameters[name])
	var names: Array[String]=[]
	for uniform: Dictionary in material.shader.get_shader_uniform_list():
		var name: String=String(uniform.get("name",""))
		if names.has(name) or not expected.has(name) or uniform.get("type")!=expected[name] or (expected[name]==TYPE_OBJECT and uniform.get("hint_string")!="Texture2D"): return "Actual shader complete reflection/type differs: "+name
		names.append(name)
	var recorded: Variant=row.get("actual_parameters")
	var registered: Variant=row.get("registered_sampler_evidence")
	if names.size()!=expected.size() or not _equal(names,row.get("actual_uniform_schema")) or not recorded is Dictionary or recorded.size()!=expected.size() or not registered is Array or row.get("actual_sampler_objects_equal_registered_textures")!=true or row.get("actual_shader_code_sha256")!=_sha(material.shader.code.to_utf8_buffer()): return "Actual saved shader schema/code/evidence incomplete"
	var texture_keys: Dictionary={"original_stone":"stone","registered_normal":"nor_gl","registered_arm":"arm"}
	for name: String in names:
		var actual: Variant=material.get_shader_parameter(name)
		var evidence: Variant=recorded.get(name)
		if typeof(actual)!=expected[name] or not evidence is Dictionary or not _num(evidence.get("type"),expected[name]): return "Actual saved shader parameter type differs: "+name
		if expected[name]==TYPE_OBJECT:
			var texture: Texture2D=actual as Texture2D
			var path: String=TEXTURES[name]
			if texture==null or evidence.get("registered_texture_key")!=texture_keys[name] or evidence.get("same_actual_registered_object")!=true or not _json_exact(evidence.get("actual_size_px"),[texture.get_width(),texture.get_height()]): return "Stored registered sampler identity/size changed: "+name
			var error: String=_sampler_error(texture,path,registered,catalog,checked)
			if error!="": return error
		else:
			if var_to_bytes(actual)!=var_to_bytes(parameters[name]) or evidence.get("variant_sha256")!=_sha(var_to_bytes(actual)): return "Actual shader parameter differs from independent constant recipe: "+name
			var value: Variant=_v3(actual) if actual is Vector3 else actual
			if not _json_exact(evidence.get("value"),value): return "Saved shader parameter numeric evidence differs: "+name
	return ""

static func _body_error(metadata: Dictionary,catalog: Dictionary,stem: String) -> String:
	for pair: Array in [["texture",".png"],["metadata_path",".json"],["native_mesh_path",".res"],["sourcebody_raw","_raw.png"],["sourcebody_raw_repeat","_raw_repeat.png"]]:
		if metadata.get(pair[0])!=stem+pair[1] or not _catalog_file(catalog,stem+pair[1]): return "Actual current wall render role points at unrelated evidence"
	if metadata.get("alpha_resampling_algorithm")!=ALPHA_ID or not _num(metadata.get("alpha_unpremultiply_epsilon"),ALPHA_EPSILON) or metadata.get("repeat_byte_exact")!=true or metadata.get("sourcebody_and_ground_caster_same_mesh_material_basis_support")!=true: return "Unknown exact wall alpha/repeat/caster contract"
	var raw: Image=Image.load_from_file(stem+"_raw.png")
	var repeat: Image=Image.load_from_file(stem+"_raw_repeat.png")
	var image: Image=Image.load_from_file(stem+".png")
	if raw==null or repeat==null or image==null or raw.get_size()!=Vector2i(1536,1536) or raw.get_format()!=Image.FORMAT_RGBA8 or repeat.get_size()!=raw.get_size() or repeat.get_format()!=raw.get_format() or raw.get_data()!=repeat.get_data() or catalog[stem+"_raw.png"]!=catalog[stem+"_raw_repeat.png"]: return "Actual wall raw repeat/canvas/format not byte exact"
	var logical: Image=_alpha_reconstruct(raw,Vector2i(768,768))
	var used: Rect2i=logical.get_used_rect()
	if used.size.x<=0 or used.position.x<4 or used.position.y<4 or used.end.x>764 or used.end.y>764: return "Actual new wall alpha capture is empty/touches edge"
	var crop:=Rect2i(used.position-Vector2i(4,4),used.size+Vector2i(8,8))
	if not _json_exact(metadata.get("crop_rect_px"),[crop.position.x,crop.position.y,crop.size.x,crop.size.y]) or not _json_exact(metadata.get("source_size_px"),[crop.size.x,crop.size.y]) or not _equal(metadata.get("source_size_px"),metadata.get("render_size_px")): return "Actual wall fresh tight alpha crop differs"
	var expected: Image=logical.get_region(crop)
	if image.get_size()!=expected.get_size() or image.get_format()!=expected.get_format() or image.get_data()!=expected.get_data(): return "Independent alpha-aware logical wall crop differs byte-for-byte"
	var camera_value: Variant=metadata.get("raw_camera")
	if not camera_value is Dictionary: return "Actual wall camera unavailable"
	var camera: Dictionary=camera_value
	if not _json_exact(camera.get("raw_canvas_px"),[1536,1536]) or not _json_exact(camera.get("logical_canvas_px"),[768,768]) or not _num(camera.get("raw_to_logical_factor"),2) or not _num(camera.get("msaa"),0) or not _num(camera.get("projection"),Camera3D.PROJECTION_ORTHOGONAL) or not _num(camera.get("orthographic_size_m"),12): return "Actual wall raw/logical camera contract differs"
	var pixel: Vector2=_actual_camera_foot(camera)
	if not pixel.is_finite(): return "Independent bound Camera3D projection unavailable"
	var foot: Vector2=pixel/2.0-Vector2(crop.position)
	if not _json_exact(metadata.get("foot_uv"),[foot.x/image.get_width(),foot.y/image.get_height()]): return "New actual wall foot UV does not reconstruct current camera/crop"
	return ""

static func _alpha_reconstruct(raw: Image,size: Vector2i) -> Image:
	# Independent packed-float implementation, not an executor call. Epsilon is
	# the fixed named algorithm's zero rule, never an alpha/geometry tolerance.
	var converted: Image=raw.duplicate() as Image
	converted.convert(Image.FORMAT_RGBAF)
	# Replay conversion before multiplication: the source channels are native
	# float32 before Color multiplication, not double byte/255 intermediates.
	var floats: PackedFloat32Array=converted.get_data().to_float32_array()
	for index in range(0,floats.size(),4):
		var alpha: float=floats[index+3]
		floats[index]*=alpha
		floats[index+1]*=alpha
		floats[index+2]*=alpha
	var result: Image=Image.create_from_data(raw.get_width(),raw.get_height(),false,Image.FORMAT_RGBAF,floats.to_byte_array())
	result.resize(size.x,size.y,Image.INTERPOLATE_LANCZOS)
	var values: PackedFloat32Array=result.get_data().to_float32_array()
	for index in range(0,values.size(),4):
		var alpha: float=values[index+3]
		if alpha>ALPHA_EPSILON:
			values[index]/=alpha
			values[index+1]/=alpha
			values[index+2]/=alpha
		else:
			for channel in range(4): values[index+channel]=0.0
	result=Image.create_from_data(size.x,size.y,false,Image.FORMAT_RGBAF,values.to_byte_array())
	result.convert(Image.FORMAT_RGBA8)
	return result

static func _actual_camera_foot(data: Dictionary) -> Vector2:
	var tree: SceneTree=Engine.get_main_loop() as SceneTree
	var columns: Variant=data.get("basis_columns")
	if tree==null or not columns is Array or columns.size()!=3: return Vector2(INF,INF)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(1536,1536)
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	viewport.own_world_3d=true
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=12.0
	camera.near=float(data.get("near",NAN))
	camera.far=float(data.get("far",NAN))
	camera.transform=Transform3D(Basis(_vector3(columns[0]),_vector3(columns[1]),_vector3(columns[2])),_vector3(data.get("position_m")))
	if not camera.position.is_finite() or not camera.basis.is_finite() or not is_finite(camera.near) or not is_finite(camera.far):
		camera.free()
		viewport.free()
		return Vector2(INF,INF)
	tree.root.add_child(viewport)
	viewport.add_child(camera)
	camera.make_current()
	var projected: Vector2=camera.unproject_position(Vector3.ZERO)
	viewport.free()
	return projected

static func _ground_repeat_error(prefix: String,catalog: Dictionary) -> String:
	var on: Image=null
	for role: String in ["on","off"]:
		var path: String=prefix+"ground_"+role+"_raw.png"
		var repeat_path: String=prefix+"ground_"+role+"_raw_repeat.png"
		if not _catalog_file(catalog,path) or not _catalog_file(catalog,repeat_path) or catalog[path]!=catalog[repeat_path]: return "Actual ground caster ON/OFF raw repeats unbound/different: "+role
		var image: Image=Image.load_from_file(path)
		var repeat: Image=Image.load_from_file(repeat_path)
		if image==null or repeat==null or image.get_size()!=Vector2i(6144,4096) or image.get_format()!=Image.FORMAT_RGBA8 or repeat.get_size()!=image.get_size() or repeat.get_format()!=image.get_format() or repeat.get_data()!=image.get_data(): return "Actual ground caster ON/OFF raw pixels differ: "+role
		if role=="on": on=image
	if not _catalog_file(catalog,prefix+"floor.png"): return "Actual derived floor not catalog-bound"
	var floor: Image=Image.load_from_file(prefix+"floor.png")
	if floor==null or floor.get_format()!=Image.FORMAT_RGBA8: return "Actual derived floor PNG unavailable"
	var derived: Image=on.duplicate() as Image
	derived.resize(3072,2048,Image.INTERPOLATE_LANCZOS)
	if floor.get_size()!=derived.get_size() or floor.get_data()!=derived.get_data(): return "Independent ground ON→logical floor byte reconstruction differs"
	return ""

static func _paving_error(record: Dictionary,catalog: Dictionary,prefix: String,old_prefix: String) -> String:
	# A live material_override must be saved independently; a self-reported hash
	# in material_binding.json alone cannot prove the actual stored sampler.
	var graph: Dictionary=record.capture_graph
	var value: Variant=graph.get("paving_material")
	if not value is Dictionary or value.get("path")!=prefix+"paving_material.res" or not _catalog_file(catalog,prefix+"paving_material.res") or value.get("sha256")!=catalog[prefix+"paving_material.res"]: return "Actual paving material_override has no bound saved resource"
	var material: ShaderMaterial=ResourceLoader.load(prefix+"paving_material.res","",ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
	if material==null or material.shader==null: return "Actual saved paving shader unavailable"
	if FileAccess.get_sha256(OLD_STREET_SURFACE).to_lower()!=OLD_STREET_SURFACE_SHA or not _catalog_file(catalog,OLD_STREET_SURFACE): return "Frozen paving shader source provenance changed"
	# Read the frozen literal shader, never instantiate/call the production
	# surface. Apply only the approved textual recipe to its exact code.
	var text: String=FileAccess.get_file_as_string(OLD_STREET_SURFACE).replace("\r\n","\n")
	var function_start: int=text.find("func paving() -> ShaderMaterial:")
	var begin: int=text.find("shader.code=\"\"\"",function_start)
	if function_start<0 or begin<0: return "Frozen original paving literal unavailable"
	begin+="shader.code=\"\"\"".length()
	var end: int=text.find("\"\"\"",begin)
	if end<0: return "Frozen original paving literal malformed"
	var expected_code: String=_paving_code(text.substr(begin,end-begin))
	if expected_code=="" or material.shader.code!=expected_code: return "Saved actual paving shader differs from independent frozen-literal recipe"
	var control_shader:=Shader.new()
	control_shader.code=expected_code
	if var_to_bytes(material.shader.get_shader_uniform_list())!=var_to_bytes(control_shader.get_shader_uniform_list()): return "Saved actual paving complete reflected schema differs"
	var binding_value: Variant=JSON.parse_string(FileAccess.get_file_as_string(prefix+"material_binding.json"))
	if not _catalog_file(catalog,prefix+"material_binding.json") or not binding_value is Dictionary or not _equal(binding_value,record.get("material_binding_evidence")): return "Saved actual paving JSON differs from final manifest evidence"
	var binding: Dictionary=binding_value
	var owner_value: Variant=binding.get("native_geometry_owner_uniforms")
	if not owner_value is Dictionary: return "Saved actual paving geometry-owner evidence absent"
	var owner: Dictionary=owner_value
	if owner.get("actual_material_override_path")!=prefix+"paving_material.res" or owner.get("actual_material_override_sha256")!=catalog[prefix+"paving_material.res"] or owner.get("actual_shader_code_sha256")!=_sha(expected_code.to_utf8_buffer()): return "Actual saved paving node/override/code binding differs"
	var arrays: Dictionary=_owner_arrays(record)
	if arrays.is_empty(): return "Independent route/contact/apron owner construction failed"
	var expected_counts: Dictionary={"route_count":arrays.route_segments.size(),"contact_count":arrays.contact_segments.size(),"apron_count":arrays.apron_rects.size()}
	if not _json_exact(owner.get("actual_counts"),expected_counts): return "Actual paving owner counts differ from independent unchanged source"
	var parameters_value: Variant=owner.get("actual_parameters")
	if not parameters_value is Dictionary: return "Saved paving all parameter evidence missing"
	var parameters: Dictionary=parameters_value
	var names: Array[String]=[]
	for entry: Dictionary in control_shader.get_shader_uniform_list(): names.append(String(entry.name))
	if parameters.size()!=names.size() or not _equal(names,owner.get("uniforms")) or not _equal(names,binding.get("reflected_uniforms")): return "Actual paving complete parameter/name set differs"
	var constants: Dictionary={"native_flagstone_identity":1.0,"quay_wet_profile":1.0 if record.canonical_scene_id=="ch4_s2_canal_docks" else 0.0,"wall_street_finish_identity":1.0}
	for name: String in expected_counts: constants[name]=int(expected_counts[name])
	var sampler_paths: Dictionary={"stone_albedo":TEXTURES.original_stone,"rock_diff":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_diff_2k.jpg","rock_normal":TEXTURES.registered_normal,"rock_arm":TEXTURES.registered_arm}
	var sampler_keys: Dictionary={"stone_albedo":"stone","rock_diff":"diff","rock_normal":"nor_gl","rock_arm":"arm"}
	var checked: Dictionary={}
	for name: String in names:
		var actual: Variant=material.get_shader_parameter(name)
		var evidence: Variant=parameters.get(name)
		if not evidence is Dictionary or not _num(evidence.get("type"),typeof(actual)): return "Actual saved paving parameter/evidence type differs: "+name
		if sampler_paths.has(name):
			var texture: Texture2D=actual as Texture2D
			if texture==null or evidence.get("registered_texture_key")!=sampler_keys[name] or evidence.get("same_actual_registered_object")!=true or not _json_exact(evidence.get("actual_size_px"),[texture.get_width(),texture.get_height()]): return "Actual saved paving sampler/key/size differs: "+name
			var error: String=_sampler_error(texture,sampler_paths[name],owner.get("actual_sampler_sources_and_mips"),catalog,checked)
			if error!="": return error
		elif constants.has(name):
			if var_to_bytes(actual)!=var_to_bytes(constants[name]) or evidence.get("variant_sha256")!=_sha(var_to_bytes(actual)) or not _json_exact(evidence.get("value"),actual): return "Actual saved paving scalar differs: "+name
		elif arrays.has(name):
			var limit: int=32 if name=="apron_rects" else 128
			# Explicit untyped Array is the declared saved-resource construction,
			# not a post-readback coercion. Each original Vector4 remains exact.
			var expected: Array=arrays[name]
			while expected.size()<limit: expected.append(Vector4.ZERO)
			if not actual is Array or actual.size()!=limit: return "Actual saved paving owner array representation/count differs: "+name
			var current_array: Array=actual
			if current_array.is_typed() or expected.is_typed() or var_to_bytes(current_array)!=var_to_bytes(expected): return "Actual saved paving complete untyped owner array bytes differ: "+name
			for index in range(limit):
				if not actual[index] is Vector4 or var_to_bytes(actual[index])!=var_to_bytes(expected[index]): return "Actual saved paving world-metre owner vector differs: "+name+"/"+str(index)
			if evidence.get("variant_sha256")!=_sha(var_to_bytes(actual)) or not _json_exact(evidence.get("value"),actual): return "Actual saved paving array evidence differs from stored native values: "+name
		else: return "Unknown saved paving uniform: "+name
	# The physical ground geometry was independently compared above; this
	# shader check is finish-only, not an assertion of new wall arrays unchanged.
	if not _catalog_file(catalog,old_prefix+"art_contract.json"): return "Frozen paving baseline provenance absent from new catalog"
	return ""

static func _paving_code(base: String) -> String:
	var code: String=base.replace("uniform float native_flagstone_identity=1.;","uniform float native_flagstone_identity=1.;\nuniform float quay_wet_profile=0.;\nuniform float wall_street_finish_identity=1.;")
	code=code.replace("float traffic=1.-smoothstep(.65,1.65,route_d);","float traffic=1.-smoothstep(.90,2.10,route_d);")
	code=code.replace("float verge=smoothstep(2.2,4.5,route_d)*(1.-apron);","float verge=smoothstep(2.8,5.8,route_d)*(1.-apron);\n float wet=quay_wet_profile*(1.-smoothstep(.45,4.2,abs(p.x-10.84375)));")
	code=code.replace("vec3 finish=mix(vec3(.81,.815,.80),vec3(.89,.885,.85),traffic);","vec3 finish=mix(vec3(.76,.765,.755),vec3(.92,.91,.865),traffic);")
	code=code.replace("finish=mix(finish,vec3(.87,.86,.82),apron*.48);","finish=mix(finish,vec3(.94,.925,.87),apron*.72);\n finish=mix(finish,vec3(.56,.60,.60),wet*.42);")
	code=code.replace("finish*=.985+(broad-.5)*.045;","finish*=.97+(broad-.5)*.11;")
	code=code.replace("verge*.18+contact*.055","verge*.24+contact*.10")
	code=code.replace("ROUGHNESS=clamp(.88-traffic*.15+verge*.035+(arm.g-.5)*.035,.69,.96);","ROUGHNESS=clamp(.91-traffic*.21-wet*.17+verge*.025+(arm.g-.5)*.035,.62,.97);")
	return code

static func _owner_arrays(record: Dictionary) -> Dictionary:
	var routes: Array=[]
	var contacts: Array=[]
	var aprons: Array=[]
	for route: Variant in record.get("routes",[]):
		if not route is Dictionary or not route.get("points_px") is Array: return {}
		var points: Array=route.points_px
		for index in range(points.size()-1):
			var a: Vector2=_world_m(points[index])
			var b: Vector2=_world_m(points[index+1])
			if not a.is_finite() or not b.is_finite(): return {}
			routes.append(Vector4(a.x,a.y,b.x,b.y))
	for object: Dictionary in record.objects:
		if not bool(object.get("blocking",false)): continue
		var polygons: Array=object.get("solid_polygons_px",[]).duplicate(true)
		if polygons.is_empty():
			var dimensions: Variant=object.get("collision_size_px")
			var midpoint: Variant=object.get("physical_center_px")
			if not dimensions is Array or dimensions.size()!=2 or not midpoint is Array or midpoint.size()!=2: return {}
			if float(dimensions[0])>0.0 and float(dimensions[1])>0.0:
				var x0: float=float(midpoint[0])-float(dimensions[0])*.5
				var x1: float=float(midpoint[0])+float(dimensions[0])*.5
				var y0: float=float(midpoint[1])-float(dimensions[1])*.5
				var y1: float=float(midpoint[1])+float(dimensions[1])*.5
				polygons.append([[x0,y0],[x1,y0],[x1,y1],[x0,y1]])
		for polygon: Variant in polygons:
			if not polygon is Array or polygon.size()<3: return {}
			var low:=Vector2(INF,INF)
			var high:=Vector2(-INF,-INF)
			for index in range(polygon.size()):
				var a: Vector2=_world_m(polygon[index])
				var b: Vector2=_world_m(polygon[(index+1)%polygon.size()])
				if not a.is_finite() or not b.is_finite(): return {}
				contacts.append(Vector4(a.x,a.y,b.x,b.y))
				low=low.min(a)
				high=high.max(a)
			var id: String=String(object.get("id",""))
			if "front" in id or id in ["inn","shop","north_canal_warehouse"]: aprons.append(Vector4(low.x,high.y,high.x,high.y+3.2))
	if routes.is_empty() or routes.size()>128 or contacts.size()>128 or aprons.size()>32: return {}
	return {"route_segments":routes,"contact_segments":contacts,"apron_rects":aprons}

static func _world_m(point: Variant) -> Vector2:
	if not point is Array or point.size()!=2: return Vector2(INF,INF)
	for component: Variant in point:
		if not typeof(component) in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(component)): return Vector2(INF,INF)
	return Vector2((float(point[0])-1536.0)/64.0,(float(point[1])-1024.0)/32.0)

static func _sampler_error(texture: Texture2D,path: String,registered: Variant,catalog: Dictionary,checked: Dictionary) -> String:
	if not registered is Array or not TEXTURE_SHAS.has(path) or not _catalog_file(catalog,path) or String(catalog[path]).to_lower()!=TEXTURE_SHAS[path]: return "Actual registered literal sampler source SHA changed: "+path
	var entry: Dictionary={}
	for row: Variant in registered:
		if not row is Dictionary: return "Registered material source evidence malformed"
		if row.get("path")==path:
			if not entry.is_empty(): return "Duplicate registered sampler source evidence"
			entry=row
	if entry.is_empty() or String(entry.get("sha256","")).to_lower()!=TEXTURE_SHAS[path] or not _catalog_file(catalog,String(entry.get("source_path",""))) or entry.get("source_sha256")!=catalog[entry.source_path]: return "Actual registered sampler provenance absent/changed"
	var key: String=path+"|"+str(texture.get_instance_id())
	if checked.has(key): return ""
	var original: Image=Image.load_from_file(path)
	var stored: Image=texture.get_image()
	if original==null or stored==null or original.generate_mipmaps()!=OK: return "Independent sampler decode/mipmap failed: "+path
	if stored.get_size()!=original.get_size() or stored.get_format()!=original.get_format() or stored.has_mipmaps()!=original.has_mipmaps() or stored.get_mipmap_count()!=original.get_mipmap_count() or stored.get_data()!=original.get_data() or not _num(entry.get("actual_mip_count"),original.get_mipmap_count()): return "Actual saved sampler complete bytes/mips differ from original: "+path
	checked[key]=true
	return ""

static func _caster_error(object: Dictionary,metadata: Dictionary) -> String:
	var transform: Variant=object.get("native_transform")
	var foot_value: Variant=object.get("world_foot_px")
	var support: Vector3=_vector3(metadata.get("support_m"))
	if not transform is Dictionary or not foot_value is Array or foot_value.size()!=2 or not support.is_finite(): return "Actual native caster transform/source feet unavailable"
	var foot:=Vector2(float(foot_value[0]),float(foot_value[1]))
	if not foot.is_finite(): return "Nonfinite actual native caster feet"
	var anchor:=Vector3((foot.x-1536.0)/64.0,0.0,(foot.y-1024.0)/32.0)
	if not _equal(transform.get("basis_columns"),metadata.get("draw_basis_columns")) or not _json_exact(transform.get("origin"),_v3(anchor-support)): return "Actual native caster pose does not reconstruct own feet/basis/support: "+str(object.get("id"))
	if String(metadata.get("kind","")) in ["wall_horizontal","wall_vertical"]:
		var body: Variant=metadata.get("actual_body_mesh_binding")
		var path: String=String(metadata.get("native_mesh_path",""))
		if not body is Dictionary or body.get("native_mesh_path")!=path or body.get("native_mesh_sha256")!=FileAccess.get_sha256(path) or not _equal(body.get("basis_columns"),metadata.get("draw_basis_columns")) or not _json_exact(body.get("origin_m"),_v3(-support)) or body.get("actual_node_mesh_equals_saved_checked_mesh")!=true: return "Actual body/caster native mesh/basis/support not exact bound stored resource"
	return ""

static func _material_equal_error(a: Material,b: Material) -> String:
	if a==null or b==null or a.get_class()!=b.get_class(): return "Actual material representation missing/changed"
	if a is ShaderMaterial:
		var aa: ShaderMaterial=a as ShaderMaterial
		var bb: ShaderMaterial=b as ShaderMaterial
		if aa.shader==null or bb.shader==null or aa.shader.code!=bb.shader.code or not _equal(aa.shader.get_shader_uniform_list(),bb.shader.get_shader_uniform_list()): return "Actual shader code/schema changed"
		for uniform: Dictionary in aa.shader.get_shader_uniform_list():
			var name: String=uniform.name
			var error: String=_value_error(aa.get_shader_parameter(name),bb.get_shader_parameter(name))
			if error!="": return name+"/"+error
		return ""
	for property: Dictionary in a.get_property_list():
		var name: String=property.name
		if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or name in ["resource_path","resource_name","resource_local_to_scene","script"]: continue
		var error: String=_value_error(a.get(name),b.get(name))
		if error!="": return name+"/"+error
	return ""

static func _value_error(a: Variant,b: Variant) -> String:
	if typeof(a)!=typeof(b): return "Variant type changed"
	if a is Texture2D:
		if not b is Texture2D: return "Texture representation changed"
		var x: Image=a.get_image()
		var y: Image=b.get_image()
		if x==null or y==null or x.get_size()!=y.get_size() or x.get_format()!=y.get_format() or x.has_mipmaps()!=y.has_mipmaps() or x.get_mipmap_count()!=y.get_mipmap_count() or x.get_data()!=y.get_data(): return "Actual sampler full pixels/mips changed"
	elif a is Resource or b is Resource:
		if a==null or b==null: return "Nested resource presence changed"
		return "Unsupported nested material Resource; must explicitly bind it"
	elif var_to_bytes(a)!=var_to_bytes(b): return "Actual value bytes changed"
	return ""

static func _vector3(value: Variant) -> Vector3:
	if not value is Array or value.size()!=3: return Vector3(INF,INF,INF)
	for component: Variant in value:
		if not typeof(component) in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(component)): return Vector3(INF,INF,INF)
	return Vector3(float(value[0]),float(value[1]),float(value[2]))

static func _v3(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

static func _json_exact(saved: Variant,native: Variant) -> bool:
	# Only explicit native→metadata representation. No epsilon/rounding of
	# actual resource arrays or source bytes; parsed records compare recursively.
	return _equal(saved,JSON.parse_string(JSON.stringify(native)))

static func _equal(a: Variant,b: Variant) -> bool:
	if typeof(a)!=typeof(b): return false
	if a is Array:
		if a.size()!=b.size(): return false
		for index in range(a.size()):
			if not _equal(a[index],b[index]): return false
		return true
	if a is Dictionary:
		if a.size()!=b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _equal(a[key],b[key]): return false
		return true
	return a==b

static func _num(value: Variant,expected: float) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value)==expected

static func _catalog_file(catalog: Dictionary,path: String) -> bool:
	return catalog.has(path) and _hash(catalog[path]) and FileAccess.get_sha256(path).to_lower()==String(catalog[path]).to_lower()

static func _hash(value: Variant) -> bool:
	if not value is String or value.length()!=64: return false
	for character: String in value.to_lower():
		if not character in "0123456789abcdef": return false
	return true

static func _sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	if context.start(HashingContext.HASH_SHA256)!=OK: return ""
	if not bytes.is_empty() and context.update(bytes)!=OK: return ""
	return context.finish().hex_encode()
