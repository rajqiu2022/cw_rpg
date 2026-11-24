extends "res://scripts/dev/build_luoyang_modular_v3_street_detail_capture_proposal.gd"

## Isolated upper-wall geometry + continuous finish proposal. NOT material-only.
## Frozen authoring/layout and ordinary physical/nav contracts remain untouched.
const WALL_ADAPTER := preload("res://scripts/dev/build_luoyang_modular_v3_wall_street_adapter_proposal.gd")
const WALL_ADAPTER_PATH := "res://scripts/dev/build_luoyang_modular_v3_wall_street_adapter_proposal.gd"
const WALL_ADAPTER_SHA := "531bfcee9eababe944fd366904355fab57a74b47104eaba2598c6224f3d69f2c"
const WALL_SURFACE_PATH := "res://scripts/dev/luoyang_modular_v3_wall_street_surface_proposal.gd"
const WALL_SURFACE_SHA := "7ccbb9f4a27234de3da4d41076e5374d7702d276a01c13e968c5790f537153eb"
const STREET_PARENT_PATH := "res://scripts/dev/build_luoyang_modular_v3_street_detail_capture_proposal.gd"
const STREET_PARENT_SHA := "be5f9fdbfb463c32b97d80a2f4fca95284199f64759c0bb63adda5244a679630"
const WALL_ART_ROOT := "res://art/maps/luoyang_modular_v3_wall_street_proposal/"
const WALL_AUDIT_ROOT := "res://build/luoyang_modular_v3_wall_street_proposal/"
const WALL_IDENTITY := "PROJECT_CITY_RETAINED_FOOT_FINER_UPPER_MASONRY_CURVED_TILE_V1"
const BASELINE_ROOT := "res://art/maps/luoyang_modular_v3_street_detail_proposal/root_material_v1/"
const BASELINE_MANIFEST_SHA := {
	"ch4_s0_luoyang_gate":"54e963a515bdc057a85491e082cbf705e48c9c68e718e896fe2dac01375ca704",
	"ch4_s1_luoyang_yamen":"c50902972d08575f1aafd2e08644467981bb55de97392cf70234ef3c77c4fe49",
	"ch4_s2_canal_docks":"f6fae4d241fa076a1ee30ff53618007d260be6d1941a3bb75d5ed8485a424cc9",
	"ch4_s3_luoyang_market":"183f19e16d22ad451e44293682e66f8250f4215fdae2031f7170f9d0fff998ac"}
var wall_sampler_comparisons: Dictionary={}
var wall_material_failure: Dictionary={}

func _run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	for required: String in ["--luoyang-v3-wall-street-capture","--luoyang-modular-v3-capture"]:
		if required not in args:
			error="Isolated street detail requires all explicit capture flags; no default export."
			await _roof_refuse()
			return
	if DisplayServer.get_name()=="headless" or "--luoyang-v3-source-plan" in args:
		error="This proposal requires an actual serial GPU capture, not headless or plan-only."
		await _roof_refuse()
		return
	var pins: Dictionary=WALL_ADAPTER.PINS.duplicate()
	pins[WALL_ADAPTER_PATH]=WALL_ADAPTER_SHA
	pins[WALL_SURFACE_PATH]=WALL_SURFACE_SHA
	pins[ROOF_TRIAL_PATH]=ROOF_TRIAL_SHA
	pins[STREET_PARENT_PATH]=STREET_PARENT_SHA
	pins[DETAIL_ADAPTER_PATH]=DETAIL_ADAPTER_SHA
	pins[DETAIL_SURFACE_PATH]=DETAIL_SURFACE_SHA
	for path: String in pins:
		if FileAccess.get_sha256(path).to_lower()!=String(pins[path]):
			error="Frozen street-detail dependency changed: "+path
			await _roof_refuse()
			return
	var chosen := "ch4_s0_luoyang_gate"
	var run_tag := ""
	for arg: String in args:
		if arg.begins_with("--city-region="): chosen=arg.trim_prefix("--city-region=")
		if arg.begins_with("--wall-street-run-tag="): run_tag=arg.trim_prefix("--wall-street-run-tag=")
	if run_tag!="root_wall_v4":
		error="ROOT152 isolated masonry material retry requires root_wall_v4; previous evidence cannot be overwritten."
		await _roof_refuse()
		return
	var tag_rule:=RegEx.new()
	if tag_rule.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$")!=OK or tag_rule.search(run_tag)==null or chosen not in SOURCE.REGIONS:
		error="Explicit safe unique run tag and exact canonical city region required."
		await _roof_refuse()
		return
	OUT=WALL_ART_ROOT+run_tag+"/"+chosen+"/"
	detail_audit=WALL_AUDIT_ROOT+run_tag+"/"+chosen+"/"
	if FileAccess.get_sha256(BASELINE_ROOT+chosen+"/art_contract.json").to_lower()!=String(BASELINE_MANIFEST_SHA[chosen]):
		error="Current immutable street-detail baseline manifest changed."
		await _roof_refuse()
		return
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(OUT)) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(detail_audit)):
		error="Proposal refuses overwrite, including failed output; choose a fresh run tag."
		await _roof_refuse()
		return
	source=SOURCE.new()
	source.prepare(chosen)
	if source.preparation_error!="":
		error=source.preparation_error
		await _roof_refuse()
		return
	# Only the output locator changes, never routes, solids, actors or functions.
	source.region_out=OUT
	detail_baseline_navigation=_detail_navigation_identity()
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(detail_audit))!=OK or DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+"entities/"))!=OK:
		error="Cannot create new isolated output/audit directories."
		await _finish(false)
		return
	var forecast: Dictionary=source.forecast()
	if not _json(detail_audit+"source_forecast.json",forecast) or not bool(forecast.get("passed",false)):
		error="Unchanged city full17/Rectangle34x24 source forecast failed; no visual fallback."
		await _finish(false)
		return
	if not _json(OUT+"art_contract.json",{"schema_version":1,"status":"BUILD_IN_PROGRESS","production_approved":false,"scope":WALL_IDENTITY}):
		await _finish(false)
		return
	detail_adapter=WALL_ADAPTER.new()
	if not detail_adapter.prepare(source.snapshot()):
		error=detail_adapter.error
		await _finish(false)
		return
	# Parent _capture_city calls these instance methods for its actual paving and
	# shoulder materials. Static SURFACE.plain/environment/water geometry remain.
	surface=detail_adapter.detail
	if not _measure_buildings() or not _stage_generated_textures():
		await _finish(false)
		return
	var needed: Array[String]=[]
	for object: Dictionary in source.objects:
		var kind: String=object["prototype"]
		if kind!="" and kind not in needed: needed.append(kind)
	for kind: String in needed:
		if not await _prototype(kind):
			await _finish(false)
			return
	if not await _capture_city():
		await _finish(false)
		return
	await _finish(true)


func _source_graph() -> Dictionary:
	var graph: Dictionary=super._source_graph()
	for path: String in [STREET_PARENT_PATH,WALL_ADAPTER_PATH,WALL_SURFACE_PATH]:
		graph[path]=FileAccess.get_sha256(path)
	return graph

func _prop_mesh(kind: String) -> ArrayMesh:
	if kind not in ["wall_horizontal","wall_vertical"]: return super._prop_mesh(kind)
	var original: ArrayMesh=_detail_original_wall(kind)
	var result: ArrayMesh=(detail_adapter as WALL_ADAPTER).build_wall(original,kind,_masonry_profile())
	if result==null: error=detail_adapter.error
	return result

func _wall_support_exact(a: Dictionary,b: Dictionary) -> bool:
	return not a.is_empty() and not b.is_empty() and var_to_bytes(a["support"])==var_to_bytes(b["support"]) and int(a["support_count"])==int(b["support_count"]) and var_to_bytes(Vector3(a["minimum"]).y)==var_to_bytes(Vector3(b["minimum"]).y)

func _wall_actual_slots(mesh: ArrayMesh) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for index in range(mesh.get_surface_count()):
		var arrays: Array=mesh.surface_get_arrays(index)
		var slots: Array[Dictionary]=[]
		for slot in range(Mesh.ARRAY_MAX):
			slots.append({"slot":slot,"variant_type":typeof(arrays[slot]),"sha256":_variant_sha(arrays[slot])})
		result.append({"surface_index":index,"primitive":mesh.surface_get_primitive_type(index),"slots":slots})
	return result

func _detail_measure_paving_binding() -> bool:
	if not super._detail_measure_paving_binding(): return false
	var material: ShaderMaterial=null
	for world: Node in view.get_children():
		for node: Node in world.get_children():
			if node is MeshInstance3D and node.mesh==detail_paving_mesh:
				material=node.material_override as ShaderMaterial
	if material==null or material.get_shader_parameter("wall_street_finish_identity")!=1. or material.get_shader_parameter("quay_wet_profile")!=(1. if source.region=="ch4_s2_canal_docks" else 0.):
		error="Actual new ground finish/quay owner binding invalid."
		return false
	var path: String=OUT+"paving_material.res"
	if ResourceSaver.save(material,path)!=OK: return false
	var saved: ShaderMaterial=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
	if not _wall_saved_material_exact(material,saved):
		_json(OUT+"paving_material_comparison_failure.json",wall_material_failure)
		error="Actual paving material override differs from independently reloaded saved material."
		return false
	detail_paving_binding["actual_material_override_path"]=path
	detail_paving_binding["actual_material_override_sha256"]=FileAccess.get_sha256(path)
	detail_paving_binding["actual_parameters"]=_detail_uniform_evidence(material)
	detail_paving_binding["saved_material_code_all_parameters_sampler_mip_bytes_exact"]=true
	detail_paving_binding["actual_sampler_sources_and_mips"]=surface.evidence.duplicate(true)
	return true

func _wall_saved_material_exact(actual: ShaderMaterial,saved: ShaderMaterial) -> bool:
	wall_material_failure.clear()
	if actual==null or saved==null or actual.shader==null or saved.shader==null:
		return _wall_material_mismatch("material_or_shader_null",actual,saved)
	if actual.shader.code!=saved.shader.code: return _wall_material_mismatch("shader_code",actual.shader.code,saved.shader.code)
	if var_to_bytes(actual.shader.get_shader_uniform_list())!=var_to_bytes(saved.shader.get_shader_uniform_list()):
		return _wall_material_mismatch("uniform_schema",actual.shader.get_shader_uniform_list(),saved.shader.get_shader_uniform_list())
	for uniform: Dictionary in actual.shader.get_shader_uniform_list():
		var name: String=uniform["name"]
		var a: Variant=actual.get_shader_parameter(name)
		var b: Variant=saved.get_shader_parameter(name)
		if a is Texture2D:
			if not b is Texture2D: return _wall_material_mismatch(name+"_texture_type",a,b)
			# All18 materials share the same immutable source texture objects.
			# Verify each actual/source saved pair once; never read9GB of identical
			# mip chains per prototype. Only ID-pair booleans remain, not Resources.
			var pair: String=str(a.get_instance_id())+":"+str(b.get_instance_id())
			if not wall_sampler_comparisons.has(pair):
				var ai: Image=a.get_image()
				var bi: Image=b.get_image()
				if ai==null or bi==null: return _wall_material_mismatch(name+"_image_null",ai,bi)
				if ai.get_size()!=bi.get_size() or ai.get_format()!=bi.get_format() or ai.get_mipmap_count()!=bi.get_mipmap_count() or ai.get_data()!=bi.get_data():
					wall_material_failure={"field":name,"actual_image":{"size":[ai.get_width(),ai.get_height()],"format":ai.get_format(),"mips":ai.get_mipmap_count(),"bytes":ai.get_data().size(),"sha256":detail_adapter._hash(ai.get_data())},"saved_image":{"size":[bi.get_width(),bi.get_height()],"format":bi.get_format(),"mips":bi.get_mipmap_count(),"bytes":bi.get_data().size(),"sha256":detail_adapter._hash(bi.get_data())},"passed":false,"tolerance":0}
					return false
				wall_sampler_comparisons[pair]=true
		elif var_to_bytes(a)!=var_to_bytes(b): return _wall_material_mismatch(name,a,b)
	return true

func _wall_material_mismatch(field: String,a: Variant,b: Variant) -> bool:
	wall_material_failure={"field":field,"actual_type":typeof(a),"saved_type":typeof(b),"actual":str(a),"saved":str(b),"actual_variant_sha256":_variant_sha(a),"saved_variant_sha256":_variant_sha(b),"passed":false,"tolerance":0}
	return false

func _finish(passed: bool) -> void:
	wall_sampler_comparisons.clear()
	await super._finish(passed)

func _prototype(kind: String) -> bool:
	if kind not in ["wall_horizontal","wall_vertical"]: return await super._prototype(kind)
	var original: ArrayMesh=_detail_original_wall(kind)
	var mesh: ArrayMesh=_prop_mesh(kind)
	var old_path: String=BASELINE_ROOT+source.region+"/entities/native_"+kind+".res"
	var baseline: ArrayMesh=ResourceLoader.load(old_path,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if original==null or mesh==null or baseline==null or not _roof_arrays_byte_exact(original,baseline):
		error="Frozen constructed wall does not equal immutable current baseline saved arrays."
		return false
	var old_bounds: Dictionary=_bounds(baseline,Basis.IDENTITY)
	var bounds: Dictionary=_bounds(mesh,Basis.IDENTITY)
	if not _wall_support_exact(old_bounds,bounds):
		error="New full used-index wall support/count/minY differs; cannot shift foot or collider."
		return false
	var adapter: WALL_ADAPTER=detail_adapter as WALL_ADAPTER
	var recipe: Dictionary=adapter.wall_recipe_records[kind].duplicate(true)
	var material_rows: Array[Dictionary]=[]
	for index in range(mesh.get_surface_count()):
		var material: ShaderMaterial=mesh.surface_get_material(index) as ShaderMaterial
		if material==null or material.shader==null:
			error="New native wall has absent actual material; no fallback."
			return false
		var uniforms: Array[String]=[]
		for uniform: Dictionary in material.shader.get_shader_uniform_list(): uniforms.append(String(uniform["name"]))
		for channel: String in ["original_stone","registered_normal","registered_arm","masonry_tint","masonry_profile"]:
			if channel not in uniforms:
				error="New actual masonry/curved tile material reflection missing: "+channel
				return false
		if material.get_shader_parameter("original_stone")!=surface.textures["stone"] or material.get_shader_parameter("registered_normal")!=surface.textures["nor_gl"] or material.get_shader_parameter("registered_arm")!=surface.textures["arm"]:
			error="New wall registered sampler object binding differs."
			return false
		var row: Dictionary={"surface_index":index,"actual_shader_code_sha256":_text_sha(material.shader.code),"actual_uniform_schema":uniforms,"actual_parameters":_detail_uniform_evidence(material),"actual_sampler_objects_equal_registered_textures":true,"registered_sampler_evidence":surface.evidence.duplicate(true),"role":"retained_ground_support_mesh_new_material" if index<14 else ("actual_curved_clay_tile" if index>=16 else "new_finer_upper_masonry")}
		material_rows.append(row)
	var roof: Dictionary=_roof_cap_evidence(mesh,16)
	if int(roof["degenerate_faces"])!=0 or float(roof["actual_normal_y_min"])<=0. or int(roof["clockwise_up_faces"])!=int(roof["triangle_count"]):
		error="Actual curved roof normals/winding/triangles invalid."
		return false
	var support: Vector3=bounds["support"]
	view=_viewport(Vector2i(1536,1536),true)
	var world: Node3D=_world(view,true)
	var body:=MeshInstance3D.new()
	body.mesh=mesh
	body.transform=Transform3D(Basis.IDENTITY,-support)
	body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(body)
	var camera: Camera3D=_camera(world,Vector2i(768,768),Vector3(0,1.6,0))
	await _sync()
	var raw: Image=_read(view)
	await _sync()
	var repeat: Image=_read(view)
	var prefix: String=OUT+"entities/native_"+kind
	if raw==null or repeat==null or raw.get_size()!=Vector2i(1536,1536) or repeat.get_size()!=raw.get_size():
		error="Actual wall raw size/readback invalid."
		return false
	if raw.save_png(prefix+"_raw.png")!=OK or repeat.save_png(prefix+"_raw_repeat.png")!=OK: return false
	if raw.get_data()!=repeat.get_data():
		error="Actual new wall raw RGBA repeat differs; no tolerance."
		return false
	var logical: Image=_alpha_resize(raw,Vector2i(768,768))
	if logical==null: return false
	var used: Rect2i=logical.get_used_rect()
	if used.size.x<=0 or used.position.x<4 or used.position.y<4 or used.end.x>764 or used.end.y>764:
		error="Actual new wall silhouette touches capture boundary or is empty."
		return false
	var crop:=Rect2i(used.position-Vector2i(4,4),used.size+Vector2i(8,8))
	var image: Image=logical.get_region(crop)
	var foot: Vector2=camera.unproject_position(Vector3.ZERO)/SSAA-Vector2(crop.position)
	if image.save_png(prefix+".png")!=OK or ResourceSaver.save(mesh,prefix+".res")!=OK: return false
	var stored: ArrayMesh=ResourceLoader.load(prefix+".res","",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if stored==null or not _roof_arrays_byte_exact(mesh,stored) or not _wall_support_exact(bounds,_bounds(stored,Basis.IDENTITY)):
		error="Saved actual new wall differs from captured mesh arrays/support."
		return false
	for index in range(mesh.get_surface_count()):
		if not _wall_saved_material_exact(mesh.surface_get_material(index) as ShaderMaterial,stored.surface_get_material(index) as ShaderMaterial):
			wall_material_failure["surface_index"]=index
			_json(prefix+"_material_comparison_failure.json",wall_material_failure)
			error="Saved wall actual material/code/samplers differs from body/caster source."
			return false
	recipe["identity"]=WALL_IDENTITY
	recipe["original_mesh_path"]=old_path
	recipe["original_mesh_sha256"]=FileAccess.get_sha256(old_path)
	recipe["actual_mesh_path"]=prefix+".res"
	recipe["actual_mesh_sha256"]=FileAccess.get_sha256(prefix+".res")
	recipe["actual_surface_materials"]=material_rows
	recipe["actual_all_surface_slots"]=_wall_actual_slots(mesh)
	recipe["actual_saved_arrays_byte_exact_to_captured_mesh"]=true
	recipe["actual_saved_materials_exact_to_captured_mesh"]=true
	recipe["support_old"]=_roof_bound_record(old_bounds)
	recipe["support_new"]=_roof_bound_record(bounds)
	recipe["actual_support_vector_count_minY_byte_exact"]=true
	recipe["actual_curved_roof_winding_normal_evidence"]=roof
	recipe["support_scope"]="Complete new used-index minimum2% algorithm, not retained subset-only measurement."
	recipe["scope"]="NEW_UPPER_GEOMETRY_AND_ALPHA; NOT_MATERIAL_ONLY; unchanged foot/support/physical layout/navigation."
	detail_wall_comparisons[kind]=recipe
	var record: Dictionary={"kind":kind,"texture":prefix+".png","metadata_path":prefix+".json","source_size_px":[image.get_width(),image.get_height()],"render_size_px":[image.get_width(),image.get_height()],"foot_uv":[foot.x/image.get_width(),foot.y/image.get_height()],"sourcebody_raw":prefix+"_raw.png","sourcebody_raw_repeat":prefix+"_raw_repeat.png","raw_camera":_camera_data(camera,view.size,Vector2i(768,768)),"crop_rect_px":[crop.position.x,crop.position.y,crop.size.x,crop.size.y],"native_mesh_path":prefix+".res","draw_basis_columns":[_v3(Basis.IDENTITY.x),_v3(Basis.IDENTITY.y),_v3(Basis.IDENTITY.z)],"support_m":_v3(support),"used_bounds_m":{"minimum":_v3(bounds["minimum"]),"maximum":_v3(bounds["maximum"])},"actual_used_vertices":bounds["actual_used_vertices"],"scale":1.,"alpha_resampling_algorithm":"RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1","alpha_unpremultiply_epsilon":.00001,"repeat_byte_exact":true,"source":"Project native retained ground support + NEW genuine finer upper brick/curved clay tile geometry; not CC0 architecture; licensed microdetail separately recorded.","source_min_vertex_ground_delta_m":Vector3(bounds["minimum"]).y-support.y,"sourcebody_and_ground_caster_same_mesh_material_basis_support":true,"geometry_change_scope":"NEW_UPPER_WALL_GEOMETRY_AND_ALPHA_NOT_MATERIAL_ONLY","geometry_array_evidence":_geometry_array_evidence(mesh),"upper_wall_geometry_revision":recipe}
	record["actual_body_mesh_binding"]={"native_mesh_path":prefix+".res","native_mesh_sha256":FileAccess.get_sha256(prefix+".res"),"basis_columns":[_v3(body.basis.x),_v3(body.basis.y),_v3(body.basis.z)],"origin_m":_v3(body.position),"actual_node_mesh_equals_saved_checked_mesh":body.mesh==mesh,"caster_scope":"Parent real city caster reuses this exact prototype mesh/material resource and own SOURCE.point3(world_foot)-support transform; final object native_transform records actual node, not old sprite metadata."}
	if not _json(prefix+".json",record): return false
	prototypes[kind]={"mesh":mesh,"basis":Basis.IDENTITY,"support":support,"image":image,"record":record}
	baseline=null
	stored=null
	view.queue_free()
	view=null
	await _sync()
	return true

func _json(path: String,data: Dictionary) -> bool:
	var destination: String=path
	if path.begins_with(AUDIT): destination=detail_audit+path.trim_prefix(AUDIT)
	if detail_audit=="" or not (destination.begins_with(OUT) or destination.begins_with(detail_audit)) or not OUT.begins_with(WALL_ART_ROOT):
		error="New wall/street writer refused path outside isolated output."
		return false
	if destination==OUT+"material_binding.json" and not _detail_measure_paving_binding(): return false
	var measured: Dictionary=data.duplicate(true)
	if destination==OUT+"material_binding.json" or measured.has("material_binding_evidence"):
		var binding: Dictionary=measured if destination==OUT+"material_binding.json" else measured["material_binding_evidence"]
		binding["stone_albedo_used_in_fragment"]="Actual unchanged stone UV ALBEDO plus continuous route polish/apron/wet-quay owner finishes; no checker palette, new terrain vertices, nav painting or fake cast."
		binding["actual_surface_script"]={"path":WALL_SURFACE_PATH,"sha256":FileAccess.get_sha256(WALL_SURFACE_PATH)}
		binding["native_detail_material_records"]=detail_adapter.detail.material_records.duplicate(true)
		binding["native_geometry_owner_uniforms"]=detail_paving_binding.duplicate(true)
	if destination==OUT+"art_contract.json" and measured.get("status","")=="ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA":
		if surface==null or surface.get_script().resource_path!=WALL_SURFACE_PATH or surface!=detail_adapter.detail:
			error="Final new contract actual surface binding mismatch."
			return false
		measured["scope"]="ISOLATED_WALL_STREET_GEOMETRY_PROPOSAL_NOT_RUNTIME_OR_FORMAL_APPROVED"
		measured["capture_surface_binding"]={"path":WALL_SURFACE_PATH,"sha256":FileAccess.get_sha256(WALL_SURFACE_PATH),"actual_instance_equals_prepared_adapter_surface":true}
		measured["upper_wall_street_revision"]={"identity":WALL_IDENTITY,"scope":"NEW_UPPER_GEOMETRY_AND_ALPHA_NOT_MATERIAL_ONLY","baseline_manifest_path":BASELINE_ROOT+source.region+"/art_contract.json","baseline_manifest_sha256":BASELINE_MANIFEST_SHA[source.region],"parent_builder":{"path":STREET_PARENT_PATH,"sha256":STREET_PARENT_SHA},"executed_builder":{"path":get_script().resource_path,"sha256":FileAccess.get_sha256(get_script().resource_path)},"adapter_script":{"path":WALL_ADAPTER_PATH,"sha256":FileAccess.get_sha256(WALL_ADAPTER_PATH)},"surface_script":{"path":WALL_SURFACE_PATH,"sha256":FileAccess.get_sha256(WALL_SURFACE_PATH)},"actual_wall_comparisons":detail_wall_comparisons.duplicate(true),"ground_native_clone_evidence":detail_adapter.evidence.duplicate(true),"source_navigation_identity_sha256":detail_adapter._hash(var_to_bytes(detail_baseline_navigation)),"unchanged_scope":["source3072camera","groundRF/paving/support arrays","worldfoot/solids/ordinary34x24+17","15NPC/11actions/12portals/route coordinates","original generated source PNG bytes"],"changed_scope":["finer wall upper arrays","narrow genuinely curved tile cap","actual body alpha/bbox/crop/footUV","new continuous registered-material finishes"],"production_approved":false}
		measured["capture_graph"]["surface_script"]={"path":WALL_SURFACE_PATH,"sha256":FileAccess.get_sha256(WALL_SURFACE_PATH)}
		measured["capture_graph"]["material_adapter_script"]={"path":WALL_ADAPTER_PATH,"sha256":FileAccess.get_sha256(WALL_ADAPTER_PATH)}
		measured["capture_graph"]["paving_material"]={"path":OUT+"paving_material.res","sha256":FileAccess.get_sha256(OUT+"paving_material.res")}
		measured["asset_sha256"][OUT+"paving_material.res"]=FileAccess.get_sha256(OUT+"paving_material.res")
		measured["asset_sha256"][OUT+"material_binding.json"]=FileAccess.get_sha256(OUT+"material_binding.json")
		measured["asset_sha256"][BASELINE_ROOT+source.region+"/art_contract.json"]=BASELINE_MANIFEST_SHA[source.region]
		for kind: String in detail_wall_comparisons:
			var old_path: String=detail_wall_comparisons[kind]["original_mesh_path"]
			measured["asset_sha256"][old_path]=FileAccess.get_sha256(old_path)
	var file:=FileAccess.open(destination,FileAccess.WRITE)
	if file==null:
		error="New isolated checked JSON open failed: "+destination
		return false
	var text: String=JSON.stringify(measured,"\t")
	file.store_string(text)
	file.flush()
	var code: int=file.get_error()
	file.close()
	if code!=OK or FileAccess.get_file_as_string(destination)!=text or not JSON.parse_string(text) is Dictionary:
		error="New isolated exact JSON write/readback failed."
		return false
	return true

