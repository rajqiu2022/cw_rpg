extends RefCounted

## Read-only independent stored-resource checker. No scene, save, art or candidate
## writes, no builder calls and no author boolean used as an array oracle.
const OLD_ROOT := "res://art/maps/luoyang_modular_v3/"
const NEW_ROOT := "res://art/maps/luoyang_modular_v3_street_detail_proposal/root_material_v1/"
const OLD_MANIFEST_SHAS := {
	"ch4_s0_luoyang_gate":"c88a39ca11019908c1824034ecc90e2cd4738062d96f06b1b18f964226a77f0a",
	"ch4_s1_luoyang_yamen":"da1e92bceac2ed30f3142b9a68887440484d2c187f8755a6250b1012bc647c68",
	"ch4_s2_canal_docks":"77c516cbda1523cb676a4cd835c20424fcdb1b26dfd5374637cb4ab7b1f7ec05",
	"ch4_s3_luoyang_market":"023efa30d997e8866a755e25da777cd1d840ad806f472282f8dc75fb86993dae"}
const DETAIL_ID := "ISOLATED_CONTINUOUS_CITY_STREET_MASONRY_MATERIAL_PROPOSAL_V1"
const EXECUTOR := "res://scripts/dev/build_luoyang_modular_v3_street_detail_capture_proposal.gd"
const EXECUTOR_SHA := "be5f9fdbfb463c32b97d80a2f4fca95284199f64759c0bb63adda5244a679630"
const DETAIL_SURFACE := "res://scripts/dev/luoyang_modular_v3_street_detail_surface_proposal.gd"
const DETAIL_SURFACE_SHA := "5f6a3f901645bdaed5e8a544c617375e2e2e02f5f2730b42d43895cf129c4dfa"
const ADAPTER := "res://scripts/dev/build_luoyang_modular_v3_street_detail_proposal.gd"
const ADAPTER_SHA := "fed19382beb77e9bec1d147dedb70bea548041718b2be372624033b229b1ae11"

static func validate(record: Dictionary,catalog: Dictionary,id: StringName) -> String:
	var region: String=String(id)
	if not OLD_MANIFEST_SHAS.has(region): return "Unknown material-only city region"
	var old_prefix: String=OLD_ROOT+region+"/"
	var prefix: String=NEW_ROOT+region+"/"
	var old_manifest: String=old_prefix+"art_contract.json"
	if FileAccess.get_sha256(old_manifest).to_lower()!=OLD_MANIFEST_SHAS[region]: return "Frozen baseline city manifest changed"
	var old: Variant=JSON.parse_string(FileAccess.get_file_as_string(old_manifest))
	if not old is Dictionary or not old.get("asset_sha256") is Dictionary: return "Frozen baseline city manifest malformed"
	for path: Variant in old.asset_sha256:
		if not path is String or FileAccess.get_sha256(path).to_lower()!=String(old.asset_sha256[path]).to_lower(): return "Frozen baseline city catalog changed: "+str(path)
	var revision: Variant=record.get("material_iteration")
	var binding: Variant=record.get("capture_surface_binding")
	if record.get("scope")!="ISOLATED_STREET_DETAIL_PROPOSAL_NOT_RUNTIME_OR_FORMAL_APPROVED" or not revision is Dictionary or revision.get("identity")!=DETAIL_ID or revision.get("production_approved")!=false: return "Missing explicit new material-only iteration scope"
	if not binding is Dictionary or binding.get("path")!=DETAIL_SURFACE or String(binding.get("sha256","")).to_lower()!=DETAIL_SURFACE_SHA or binding.get("actual_instance_equals_prepared_adapter_surface")!=true: return "Missing actual material surface instance binding"
	var graph: Variant=record.get("capture_graph")
	if not graph is Dictionary: return "Missing actual material capture graph"
	for pair: Array in [["builder_script",EXECUTOR,EXECUTOR_SHA],["surface_script",DETAIL_SURFACE,DETAIL_SURFACE_SHA],["material_adapter_script",ADAPTER,ADAPTER_SHA]]:
		var node: Variant=graph.get(pair[0])
		if not node is Dictionary or node.get("path")!=pair[1] or String(node.get("sha256","")).to_lower()!=pair[2] or FileAccess.get_sha256(pair[1]).to_lower()!=pair[2]: return "Material graph is not exact frozen actual capture: "+pair[0]
	# JSON numbers in both old and new manifests share the same representation.
	# These comparisons exclude source/capture paths, not any geometric gameplay.
	for key: String in ["canonical_scene_id","logical_size_px","pixel_sampling","physical_navigation_margin_px","ordinary_actor_body_px","ordinary_actor_visual_scale","entry_foot_px","return_foot_px","gameplay_slots","routes","npc_stations","interaction_anchors","height_grid"]:
		if not _equal(old.get(key),record.get(key)): return "Material-only changed authored city field "+key
	for file: String in ["land.png","raw_walk.png","walk.png","terrain_height.rf"]:
		if FileAccess.get_sha256(old_prefix+file)=="" or FileAccess.get_sha256(old_prefix+file)!=FileAccess.get_sha256(prefix+file): return "Material-only changed authoritative bytes "+file
	for key: String in ["capture_camera","authority_camera"]:
		if not _equal(old.get(key),record.get(key)): return "Material-only changed actual camera "+key
	var geometry_files: Array[String]=["paving_mesh.res","support_plane.res"]
	if region=="ch4_s2_canal_docks": geometry_files.append_array(["canal_bed_mesh.res","water_plane.res","quay_wall_mesh.res"])
	for file: String in geometry_files:
		if not catalog.has(prefix+file): return "New geometry absent from actual catalog "+file
		var problem: String=_meshes_error(old_prefix+file,prefix+file,file)
		if problem!="": return problem
	var old_objects: Variant=old.get("objects")
	var objects: Variant=record.get("objects")
	if not old_objects is Array or not objects is Array or old_objects.size()!=objects.size(): return "Material-only changed object count"
	var previous: Dictionary={}
	for object: Variant in old_objects:
		if not object is Dictionary or previous.has(object.get("id")): return "Malformed frozen baseline object set"
		previous[object.id]=object
	var seen: Dictionary={}
	var prototypes: Dictionary={}
	for object: Variant in objects:
		if not object is Dictionary or not previous.has(object.get("id")) or seen.has(object.get("id")): return "Material-only changed object IDs"
		seen[object.id]=true
		var before: Dictionary=previous[object.id]
		for key: String in ["id","prototype","world_foot_px","depth_foot_y","physical_center_px","collision_size_px","solid_polygons_px","blocking","z_index","sort_by_feet","ghost_occlusion","walk_support","role","render_size_px","foot_uv","source_size_px"]:
			if not _equal(before.get(key),object.get(key)): return "Material-only changed object geometry/alpha mapping "+object.id+"/"+key
		var kind: String=String(object.get("prototype",""))
		if kind=="":
			if FileAccess.get_sha256(String(before.texture))!=FileAccess.get_sha256(String(object.texture)): return "Generated/original project body PNG changed "+object.id
			continue
		if prototypes.has(kind): continue
		prototypes[kind]=true
		var stem: String="entities/native_"+kind
		for suffix: String in [".res",".json",".png","_raw.png","_raw_repeat.png"]:
			if not catalog.has(prefix+stem+suffix): return "Incomplete actual prototype catalog "+kind
		var problem: String=_meshes_error(old_prefix+stem+".res",prefix+stem+".res",kind)
		if problem!="": return problem
		var old_metadata: Variant=JSON.parse_string(FileAccess.get_file_as_string(old_prefix+stem+".json"))
		var metadata: Variant=JSON.parse_string(FileAccess.get_file_as_string(prefix+stem+".json"))
		if not old_metadata is Dictionary or not metadata is Dictionary: return "Malformed actual native metadata "+kind
		for key: String in ["kind","support_m","draw_basis_columns","used_bounds_m","actual_used_vertices","scale","source_min_vertex_ground_delta_m","crop_rect_px","source_size_px","render_size_px","foot_uv","raw_camera","alpha_resampling_algorithm"]:
			if not _equal(old_metadata.get(key),metadata.get(key)): return "Material-only changed actual prototype support/camera/body mapping "+kind+"/"+key
		if metadata.get("repeat_byte_exact")!=true or FileAccess.get_sha256(prefix+stem+"_raw.png")!=FileAccess.get_sha256(prefix+stem+"_raw_repeat.png"): return "Native material body raw repeat is not exact "+kind
		if kind in ["wall_horizontal","wall_vertical"]:
			var error: String=_wall_error(metadata,catalog,prefix+stem,old_prefix+stem)
			if error!="": return error
		else:
			for suffix: String in [".png","_raw.png","_raw_repeat.png"]:
				if FileAccess.get_sha256(old_prefix+stem+suffix)!=FileAccess.get_sha256(prefix+stem+suffix): return "Out-of-scope native body pixels changed "+kind+suffix
	return ""

static func _wall_error(metadata: Dictionary,catalog: Dictionary,stem: String,old_stem: String) -> String:
	for pair: Array in [["texture",".png"],["metadata_path",".json"],["native_mesh_path",".res"],["sourcebody_raw","_raw.png"],["sourcebody_raw_repeat","_raw_repeat.png"]]:
		if metadata.get(pair[0])!=stem+pair[1] or not catalog.has(stem+pair[1]): return "New native wall role points at unrelated evidence"
	var revision: Variant=metadata.get("material_revision")
	if not revision is Dictionary or revision.get("identity")!=DETAIL_ID or revision.get("production_approved")!=false: return "New wall missing honest changed masonry scope"
	var executed: Variant=revision.get("executed_builder")
	if not executed is Dictionary or executed.get("path")!=EXECUTOR or String(executed.get("sha256","")).to_lower()!=EXECUTOR_SHA: return "New wall executor not actual exact builder"
	var a: ArrayMesh=ResourceLoader.load(old_stem+".res","",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var b: ArrayMesh=ResourceLoader.load(stem+".res","",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if a==null or b==null or a.get_surface_count()!=54 or b.get_surface_count()!=54: return "New native wall complete raised-cap surface set invalid"
	var problem: String=_material_error(a.surface_get_material(53),b.surface_get_material(53))
	if problem!="": return "Frozen dedicated grey tile cap changed: "+problem
	var rows: Variant=revision.get("actual_surface_materials")
	if not rows is Array or rows.size()!=54: return "New actual wall material evidence incomplete"
	var checked_samplers: Dictionary={}
	for index in range(54):
		var row: Variant=rows[index]
		var material: ShaderMaterial=b.surface_get_material(index) as ShaderMaterial
		if not row is Dictionary or not material is ShaderMaterial or material.shader==null or float(row.get("surface_index",-1))!=index: return "New actual wall shader/surface identity invalid"
		if row.get("actual_shader_code_sha256")!=_sha(material.shader.code.to_utf8_buffer()): return "New actual wall shader differs from stored current material"
		var original_material: ShaderMaterial=a.surface_get_material(index) as ShaderMaterial
		if original_material==null: return "Frozen wall actual material missing"
		var tint: Variant=material.get_shader_parameter("masonry_tint")
		var profile: Variant=material.get_shader_parameter("masonry_profile")
		var recorded_tint: Variant=row.get("actual_tint")
		if not tint is Vector3 or not profile is float or not recorded_tint is Array or recorded_tint.size()!=3 or not typeof(row.get("actual_profile")) in [TYPE_INT,TYPE_FLOAT]: return "New wall actual material parameters missing"
		var restored_tint:=Vector3(float(recorded_tint[0]),float(recorded_tint[1]),float(recorded_tint[2]))
		if restored_tint!=tint or float(row.actual_profile)!=profile or var_to_bytes(tint)!=var_to_bytes(original_material.get_shader_parameter("masonry_tint")) or var_to_bytes(profile)!=var_to_bytes(original_material.get_shader_parameter("masonry_profile")): return "New wall actual retained tint/profile differs"
		if index==53 and row.get("surface_role")!="unchanged_9FF_raised_grey_tile_cap": return "Dedicated cap masquerades as original masonry"
		if index<53 and row.get("surface_role")!="revised_original_masonry_material": return "Original masonry hides changed material role"
		var uniform_error: String=_stored_uniform_error(row,material,original_material,index,catalog,checked_samplers)
		if not uniform_error.is_empty(): return uniform_error
	return ""

static func _stored_uniform_error(row: Dictionary,material: ShaderMaterial,previous: ShaderMaterial,index: int,catalog: Dictionary,checked: Dictionary) -> String:
	# Decode the saved resource independently. Capture instance IDs are not
	# portable across processes; actual stored values/pixels are the oracle.
	var expected: Dictionary={"original_stone":TYPE_OBJECT,"registered_normal":TYPE_OBJECT,"registered_arm":TYPE_OBJECT,"masonry_tint":TYPE_VECTOR3,"masonry_profile":TYPE_FLOAT}
	if index==53:
		for name: String in ["native_grey_tile_cap_identity","horizontal_axis","cap_half_span_m","tile_pitch_m","course_pitch_m"]: expected[name]=TYPE_FLOAT
	var names: Array[String]=[]
	for uniform: Dictionary in material.shader.get_shader_uniform_list():
		var name: String=String(uniform.get("name",""))
		if names.has(name) or not expected.has(name) or uniform.get("type")!=expected[name]: return "Stored wall uniform reflection/type differs: "+name
		if expected[name]==TYPE_OBJECT and uniform.get("hint_string")!="Texture2D": return "Stored wall sampler reflection is not Texture2D: "+name
		names.append(name)
	var recorded_names: Variant=row.get("actual_uniform_schema")
	var parameters: Variant=row.get("actual_parameters")
	var samplers: Variant=row.get("samplers")
	if names.size()!=expected.size() or not _equal(names,recorded_names) or not parameters is Dictionary or parameters.size()!=expected.size() or not samplers is Dictionary or samplers.size()!=3: return "Stored wall complete uniform/schema/parameter evidence differs"
	if row.get("previous_shader_code_sha256")!=_sha(previous.shader.code.to_utf8_buffer()): return "Stored wall frozen original shader binding differs"
	var paths: Dictionary={"original_stone":"res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png","registered_normal":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_nor_gl_2k.jpg","registered_arm":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_arm_2k.jpg"}
	var keys: Dictionary={"original_stone":"stone","registered_normal":"nor_gl","registered_arm":"arm"}
	for name: String in names:
		var actual: Variant=material.get_shader_parameter(name)
		var evidence: Variant=parameters.get(name)
		if typeof(actual)!=expected[name] or not evidence is Dictionary or evidence.get("type")!=expected[name]: return "Stored wall actual parameter type differs: "+name
		if expected[name]==TYPE_OBJECT:
			var texture: Texture2D=actual as Texture2D
			var sampler: Variant=samplers.get(name)
			var path: String=paths[name]
			if texture==null or not sampler is Dictionary or sampler.get("path")!=path or not catalog.has(path) or sampler.get("sha256")!=catalog[path] or FileAccess.get_sha256(path)!=catalog[path]: return "Stored wall registered sampler source binding differs: "+name
			var size: Variant=evidence.get("actual_size_px")
			if evidence.get("registered_texture_key")!=keys[name] or evidence.get("same_actual_registered_object")!=true or not size is Array or size.size()!=2: return "Stored wall actual sampler size/key evidence differs: "+name
			if not typeof(size[0]) in [TYPE_INT,TYPE_FLOAT] or not typeof(size[1]) in [TYPE_INT,TYPE_FLOAT] or float(size[0])!=texture.get_width() or float(size[1])!=texture.get_height(): return "Stored wall actual sampler dimensions differ: "+name
			var cache_key: String=path+"|"+str(texture.get_instance_id())
			if not checked.has(cache_key):
				var original: Image=Image.load_from_file(path)
				var stored: Image=texture.get_image()
				if original==null or stored==null or original.generate_mipmaps()!=OK: return "Stored wall registered sampler decode/mipmap generation failed: "+name
				if stored.get_size()!=original.get_size() or stored.get_format()!=original.get_format() or stored.has_mipmaps()!=original.has_mipmaps() or stored.get_mipmap_count()!=original.get_mipmap_count() or stored.get_data()!=original.get_data(): return "Stored wall sampler full pixels/mipmaps differ from independent registered original: "+name
				checked[cache_key]=true
		else:
			var value: Variant=evidence.get("value")
			if expected[name]==TYPE_VECTOR3:
				if not value is Array or value.size()!=3: return "Stored wall vector parameter evidence malformed: "+name
				for component: Variant in value:
					if not typeof(component) in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(component)): return "Stored wall vector parameter evidence nonfinite: "+name
				value=Vector3(float(value[0]),float(value[1]),float(value[2]))
			elif not typeof(value) in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)):
				return "Stored wall float parameter evidence nonfinite: "+name
			else:
				value=float(value)
			if var_to_bytes(value)!=var_to_bytes(actual) or evidence.get("variant_sha256")!=_sha(var_to_bytes(actual)): return "Stored wall actual complete parameter value/SHA differs: "+name
	return ""

static func _meshes_error(old_path: String,new_path: String,label: String) -> String:
	var a: Mesh=ResourceLoader.load(old_path,"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	var b: Mesh=ResourceLoader.load(new_path,"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	if a==null or b==null or a.get_class()!=b.get_class() or a.get_surface_count()<=0 or a.get_surface_count()!=b.get_surface_count(): return "Mesh representation/count changed "+label
	for index in range(a.get_surface_count()):
		if a is ArrayMesh:
			var array_a: ArrayMesh=a as ArrayMesh
			var array_b: ArrayMesh=b as ArrayMesh
			if array_b==null or array_a.surface_get_primitive_type(index)!=array_b.surface_get_primitive_type(index): return "Native primitive changed "+label
		elif not (a is PrimitiveMesh and b is PrimitiveMesh): return "Unknown actual mesh representation "+label
		var aa: Array=a.surface_get_arrays(index)
		var bb: Array=b.surface_get_arrays(index)
		if aa.size()!=Mesh.ARRAY_MAX or bb.size()!=Mesh.ARRAY_MAX: return "Incomplete actual native array set "+label
		for slot in range(Mesh.ARRAY_MAX):
			if var_to_bytes(aa[slot])!=var_to_bytes(bb[slot]): return "Native stored slot changed "+label+"/"+str(index)+"/"+str(slot)
	if a is PrimitiveMesh:
		# Each representation old/new exact; do not require faces==surface arrays.
		var faces: PackedVector3Array=a.get_faces()
		if faces.is_empty() or faces.size()%3!=0 or faces.to_byte_array()!=b.get_faces().to_byte_array(): return "Primitive actual native triangles changed "+label
		for property: Dictionary in a.get_property_list():
			var name: String=property.name
			if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or name in ["material","resource_path","resource_name","resource_local_to_scene","script"]: continue
			if var_to_bytes(a.get(name))!=var_to_bytes(b.get(name)): return "Primitive geometry parameter changed "+label+"/"+name
	return ""

static func _material_error(a: Material,b: Material) -> String:
	var aa: ShaderMaterial=a as ShaderMaterial
	var bb: ShaderMaterial=b as ShaderMaterial
	if aa==null or bb==null or aa.shader==null or bb.shader==null or aa.shader.code!=bb.shader.code: return "Dedicated cap code differs"
	for entry: Dictionary in aa.shader.get_shader_uniform_list():
		var name: String=entry.name
		var x: Variant=aa.get_shader_parameter(name)
		var y: Variant=bb.get_shader_parameter(name)
		if x is Texture2D:
			if not y is Texture2D: return "Dedicated cap texture type differs "+name
			var xi: Image=x.get_image()
			var yi: Image=y.get_image()
			if xi==null or yi==null or xi.get_size()!=yi.get_size() or xi.get_format()!=yi.get_format() or xi.get_data()!=yi.get_data(): return "Dedicated cap actual sampler bytes differ "+name
		elif var_to_bytes(x)!=var_to_bytes(y): return "Dedicated cap actual uniform differs "+name
	return ""

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

static func _sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	if context.start(HashingContext.HASH_SHA256)!=OK: return ""
	if not bytes.is_empty() and context.update(bytes)!=OK: return ""
	return context.finish().hex_encode()
