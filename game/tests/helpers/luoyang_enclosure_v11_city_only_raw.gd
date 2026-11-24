extends "res://tests/helpers/v15_field_raw_oracle.gd"
## City-only V11 independent BASE + patch reader. Production prepare/materialize
## are never used to create the QA expected author record.
const ENCLOSURE = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const SNAPSHOT_ORIGIN_PATH: String = "res://tests/helpers/joint_v15_street_detail_ordinary_raw_oracle.gd"
const SNAPSHOT_ORIGIN_SHA: String = "e40c5643d7a2336960b951fa1a14cf4c9e17de4ae191e84daca886f65c1844cd"
## NEW joint sibling. Legacy fields retain the exact original PNG/polygon
## sampler. New city solids come independently from the current frozen raw
## manifest, never from Field clearance or its scoped rendering dictionaries.
const CITY_ROOT: String = "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/"
const CITY_IDS: Array[String] = ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
var source_record: Dictionary = {}
var source_manifest_path: String = ""
var source_manifest_sha256: String = ""
var ground_source_pins: Dictionary = {}

func configure_city(scene: SceneScript, candidate: bool) -> bool:
	release()
	errors.clear()
	source_record.clear()
	if not FileAccess.get_sha256(SNAPSHOT_ORIGIN_PATH).to_lower()==SNAPSHOT_ORIGIN_SHA:
		errors.append("frozen ordinary raw parent bytes changed")
		return false
	if scene==null or scene.map_layout==null or String(scene.scene_id) not in CITY_IDS:
		errors.append("not an exact joint city identity")
		return false
	source_manifest_path=ENCLOSURE.manifest_path(scene.scene_id)
	source_manifest_sha256=FileAccess.get_sha256(source_manifest_path)
	var parsed: Variant = independent_record(scene.scene_id)
	if not parsed is Dictionary or parsed.get("canonical_scene_id")!=String(scene.scene_id) or parsed.get("status") not in ["ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA","PRODUCTION_APPROVED"]:
		errors.append("new city source NOT_READY or wrong identity")
		return false
	var record: Dictionary = parsed
	var catalog: Variant = record.get("asset_sha256")
	if not catalog is Dictionary or catalog.is_empty():
		errors.append("new city has no independently readable asset catalog")
		return false
	for path: Variant in catalog:
		if not path is String or not path.begins_with("res://") or ".." in path or not catalog[path] is String or catalog[path].length()!=64 or not FileAccess.file_exists(path) or FileAccess.get_sha256(path).to_lower()!=String(catalog[path]).to_lower():
			errors.append("new city current source bytes mismatch: "+str(path))
	var ordinary_size: Vector2 = Vector2(scene.map_layout.design_size)
	if ordinary_size!=Vector2(3072,2048) or scene.map_layout.schema_version!=3 or record.get("pixel_sampling")!="round_world_pixel" or float(record.get("physical_navigation_margin_px",-1))!=0:
		errors.append("new city must explicitly declare ordinary3072/full-body/direct-round/margin0")
	var expected_scene: String = "res://data/scenes/%s.tres"%scene.scene_id
	var expected_candidate: String = ENCLOSURE.candidate_path(scene.scene_id)
	var materialized: bool = candidate and scene.resource_path.is_empty() and scene.get_meta("luoyang_layered_revision",0)==3 and scene.get_meta("city_manifest_sha","")==ENCLOSURE.base_manifest_sha(scene.scene_id) and (not ENCLOSURE.PATCH_MANIFEST_SHAS.has(String(scene.scene_id)) or scene.get_meta("city_enclosure_manifest_sha","")==source_manifest_sha256)
	if scene.resource_path!=expected_scene and not (candidate and scene.resource_path==expected_candidate) and not materialized:
		errors.append("new city scene is neither exact formal/candidate path nor SHA-bound explicit candidate clone")
	if scene.background_path!=record.get("ground_path") or scene.map_layout.walkable_mask_path!=record.get("walk_path"):
		errors.append("actual city background/nav differ from frozen current manifest")
	if scene.get_meta("city_ground_manifest_path",null)!=record.get("ground_capture_path") or scene.get_meta("city_ground_manifest_sha",null)!=record.get("ground_capture_sha256"):
		errors.append("actual city native ground sidecar metadata differs")
	var objects: Variant = record.get("objects")
	if not objects is Array or objects.is_empty():
		errors.append("new city independent solids missing")
		return false
	var declarations: Array[Dictionary] = []
	var ids: Dictionary = {}
	for raw_object: Variant in objects:
		if not raw_object is Dictionary:
			errors.append("invalid source object")
			continue
		var object: Dictionary = raw_object
		var id: String = String(object.get("id",""))
		var polygons: Variant = object.get("solid_polygons_px")
		var extent: Vector2 = _pair(object.get("collision_size_px"))
		var center: Vector2 = _pair(object.get("physical_center_px"))
		if id.is_empty() or ids.has(id) or typeof(object.get("blocking"))!=TYPE_BOOL or not polygons is Array or not extent.is_finite() or not center.is_finite() or extent.x<0 or extent.y<0 or (extent.x==0)!=(extent.y==0):
			errors.append("malformed/duplicate source physical object: "+id)
			continue
		ids[id]=true
		var has_rectangle: bool = extent.x>0
		if bool(object.blocking)!=(has_rectangle or not polygons.is_empty()) or (has_rectangle and not polygons.is_empty()):
			errors.append("source blocking identity mismatch or double collider: "+id)
			continue
		if not bool(object.blocking): continue
		if has_rectangle:
			declarations.append({"id":id,"pos":center/ordinary_size,"collision_size":extent/ordinary_size,"collision_offset":Vector2.ZERO})
		else:
			var actual_polygons: Array[PackedVector2Array] = []
			for value: Variant in polygons:
				var polygon: PackedVector2Array = PackedVector2Array()
				if value is Array:
					for vertex: Variant in value: polygon.append(_pair(vertex))
				actual_polygons.append(polygon)
			declarations.append({"id":id,"solid_polygons_px":actual_polygons})
	if not errors.is_empty(): return false
	var owned_layout: Resource = scene.map_layout.duplicate(true)
	owned_layout.set("visual_objects",declarations)
	# Legacy blockers are forbidden here, not silently inherited or removed.
	if not (owned_layout.get("blockers") as Array).is_empty():
		errors.append("new city inherited old source blockers")
		return false
	# The original configure begins with release(); keep only this call's owned
	# immutable ground pins, then restore them after that normal lifecycle reset.
	var current_ground_pins: Dictionary=ground_source_pins.duplicate(true)
	var good: bool = super.configure(owned_layout,"round_world_pixel",0.0)
	owned_layout=null
	if good:
		source_record=record.duplicate(true)
		ground_source_pins=current_ground_pins
	return good

func _pair(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size()==2 and typeof(value[0]) in [TYPE_INT,TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT,TYPE_FLOAT]: return Vector2(float(value[0]),float(value[1]))
	return Vector2(INF,INF)


func independent_record(id: StringName) -> Dictionary:
	var base_path: String=ENCLOSURE.base_manifest_path(id)
	if not ENCLOSURE.owns_id(id) or not _bound(base_path,ENCLOSURE.base_manifest_sha(id)): return {}
	var base: Variant=_json(base_path)
	if not base is Dictionary or typeof(base.get("canonical_scene_id"))!=TYPE_STRING or base.canonical_scene_id!=String(id): return {}
	if not ENCLOSURE.PATCH_MANIFEST_SHAS.has(String(id)): return base.duplicate(true)
	var path: String=ENCLOSURE.manifest_path(id)
	if not _bound(path,ENCLOSURE.manifest_sha(id)): return {}
	var patch: Variant=_json(path)
	var plan_path: String=ENCLOSURE.ROOT+String(id)+"/export_plan.json"
	if not patch is Dictionary or not _bound(plan_path,ENCLOSURE.EXPORT_PLAN_SHAS.get(String(id),"")): return {}
	var plan: Variant=_json(plan_path)
	if not plan is Dictionary: return {}
	var exact: Dictionary={"canonical_scene_id":String(id),"status":"GPU_EXPORTED_REQUIRES_FIELD_VISUAL_QA","base_manifest_path":base_path,"base_manifest_sha256":ENCLOSURE.base_manifest_sha(id),"export_plan_path":plan_path,"export_plan_sha256":ENCLOSURE.EXPORT_PLAN_SHAS[String(id)]}
	for key: String in exact:
		if typeof(patch.get(key))!=TYPE_STRING or patch[key]!=exact[key]: return {}
	if not patch.get("remove_object_ids") is Array or not patch.get("objects") is Array or not patch.get("asset_sha256") is Dictionary or not plan.get("objects") is Array: return {}
	if patch.remove_object_ids!=plan.get("remove_object_ids") or patch.get("source_catalog")!=plan.get("source_catalog") or patch.objects.size()!=plan.objects.size(): return {}
	var removed: Dictionary={}
	for value: Variant in patch.remove_object_ids:
		if typeof(value)!=TYPE_STRING or value.is_empty() or removed.has(value): return {}
		removed[value]=false
	var seen: Dictionary={}
	var objects: Array=[]
	for value: Variant in base.get("objects",[]):
		if not value is Dictionary or typeof(value.get("id"))!=TYPE_STRING or seen.has(value.id): return {}
		seen[value.id]=true
		if removed.has(value.id): removed[value.id]=true
		else: objects.append(value.duplicate(true))
	for key: String in removed:
		if not removed[key]: return {}
	var appended: Dictionary={}
	for index in patch.objects.size():
		var value: Variant=patch.objects[index]
		var author: Variant=plan.objects[index]
		if not value is Dictionary or not author is Dictionary or typeof(value.get("id"))!=TYPE_STRING or appended.has(value.id) or (seen.has(value.id) and not removed.has(value.id)) or value.get("authoring")!=author or value.id!=author.get("id"): return {}
		if typeof(value.get("texture"))!=TYPE_STRING or value.texture!=ENCLOSURE.ROOT+String(id)+"/entities/"+value.id+".png" or value.get("source")!=value.texture or value.get("source_sha256")!=patch.asset_sha256.get(value.texture): return {}
		seen[value.id]=true
		appended[value.id]=true
		objects.append(value.duplicate(true))
	var record: Dictionary=base.duplicate(true)
	record.objects=objects
	if typeof(patch.get("walk_path"))!=TYPE_STRING or patch.walk_path!=ENCLOSURE.ROOT+String(id)+"/walk.png" or not patch.asset_sha256.has(patch.walk_path): return {}
	for file: Variant in patch.asset_sha256:
		if not _bound(file,patch.asset_sha256[file]): return {}
		record.asset_sha256[file]=patch.asset_sha256[file]
	record.walk_path=patch.walk_path
	record.enclosure_patch_path=path
	record.enclosure_patch_sha256=ENCLOSURE.manifest_sha(id)
	record.enclosure_base_manifest_path=base_path
	record.enclosure_base_manifest_sha256=ENCLOSURE.base_manifest_sha(id)
	return _independent_ground(id,base,plan,record)

func _ground_equal(a: Variant,b: Variant) -> bool:
	# Both sides already inhabit the original JSON writer domain. Saved values
	# are never rounded/cast; only independently reconstructed native poses below
	# cross the original writer once. Dictionary insertion order is irrelevant.
	if typeof(a)!=typeof(b): return false
	if a is Array:
		if a.size()!=b.size(): return false
		for index in a.size():
			if not _ground_equal(a[index],b[index]): return false
		return true
	if a is Dictionary:
		if a.size()!=b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _ground_equal(a[key],b[key]): return false
		return true
	return a==b

func _ground_native_writer(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value,"\t",false))

func _ground_v3(value: Variant) -> Vector3:
	if not value is Array or value.size()!=3: return Vector3(INF,INF,INF)
	for scalar: Variant in value:
		if typeof(scalar) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(scalar)): return Vector3(INF,INF,INF)
	return Vector3(value[0],value[1],value[2])

func _ground_array(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

func _ground_png_size(path: String,expected: Vector2i) -> bool:
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()<24: return false
	var header: PackedByteArray=file.get_buffer(24)
	if header.slice(0,8).hex_encode()!="89504e470d0a1a0a" or header.slice(12,16).get_string_from_ascii()!="IHDR": return false
	return ((int(header[16])<<24)|(int(header[17])<<16)|(int(header[18])<<8)|int(header[19]))==expected.x and ((int(header[20])<<24)|(int(header[21])<<16)|(int(header[22])<<8)|int(header[23]))==expected.y

func _independent_ground(id: StringName,base: Dictionary,plan: Dictionary,record: Dictionary) -> Dictionary:
	# Only path/SHA selection comes from the frozen consumer constants. Expected
	# camera, caster membership, native meshes and poses come from bound original
	# BASE/author JSON, not production GROUND.read/prepare/materialize.
	var binding: Variant=ENCLOSURE.GROUND_MANIFESTS.get(String(id))
	if not binding is Dictionary: return {}
	var path: Variant=binding.get("path")
	var digest: Variant=binding.get("sha256")
	var prefix: String=ENCLOSURE.ROOT+String(id)+"/"
	if typeof(path)!=TYPE_STRING or path!=prefix+"ground_v14/root_ground_v14_02/ground_capture.json" or not _bound(path,digest): return {}
	var side: Variant=_json(path)
	if not side is Dictionary: return {}
	var identity: Dictionary={"canonical_scene_id":String(id),"status":"NATIVE_GROUND_GPU_CAPTURE_REQUIRES_VISUAL_FIELD_REVIEW","base_manifest_path":record.enclosure_base_manifest_path,"base_manifest_sha256":record.enclosure_base_manifest_sha256,"export_plan_path":prefix+"export_plan.json","export_plan_sha256":ENCLOSURE.EXPORT_PLAN_SHAS[String(id)]}
	for key: String in identity:
		if typeof(side.get(key))!=TYPE_STRING or side[key]!=identity[key]: return {}
	if typeof(side.get("schema_version"))!=TYPE_FLOAT or side.schema_version!=1.: return {}
	for key: String in ["actual_on_off_repeat_exact","original_support_paving_material_arrays_unchanged","original_vertex_contact_dirt_unchanged"]:
		if typeof(side.get(key))!=TYPE_BOOL or side[key]!=true: return {}
	for key: String in ["png_wall_proxy_casters","navigation_or_height_changed","production_approved","visual_approved","field_approved"]:
		if typeof(side.get(key))!=TYPE_BOOL or side[key]!=false: return {}
	if not _ground_equal(side.get("capture_camera"),base.get("capture_camera")) or not _ground_equal(side.get("requested_remove_object_ids"),plan.get("remove_object_ids")): return {}
	var catalog: Variant=side.get("asset_sha256")
	if not catalog is Dictionary or catalog.is_empty(): return {}
	var pins: Dictionary={path:digest,record.enclosure_base_manifest_path:record.enclosure_base_manifest_sha256,identity.export_plan_path:identity.export_plan_sha256}
	for file: Variant in catalog:
		if not _bound(file,catalog[file]): return {}
		pins[file]=catalog[file]
	for original: Dictionary in [base.asset_sha256,plan.source_catalog]:
		for file: Variant in original:
			if not _ground_equal(catalog.get(file),original[file]): return {}
	var removed: Array=[]
	var expected_casters: Array=[]
	var added: Array=[]
	var original_ids: Dictionary={}
	for old: Variant in base.objects:
		if not old is Dictionary or typeof(old.get("id"))!=TYPE_STRING or original_ids.has(old.id): return {}
		original_ids[old.id]=true
		if not old.has("native_transform"): continue
		if old.id in plan.remove_object_ids: removed.append(old.id); continue
		var metadata: Variant=old.get("metadata_path")
		if typeof(metadata)!=TYPE_STRING or not catalog.has(metadata): return {}
		var source: Variant=_json(metadata)
		var pose: Variant=old.native_transform
		if not source is Dictionary or not pose is Dictionary or not pose.get("basis_columns") is Array or pose.basis_columns.size()!=3: return {}
		var x: Vector3=_ground_v3(pose.basis_columns[0]); var y: Vector3=_ground_v3(pose.basis_columns[1]); var z: Vector3=_ground_v3(pose.basis_columns[2]); var origin: Vector3=_ground_v3(pose.get("origin"))
		if not x.is_finite() or not y.is_finite() or not z.is_finite() or not origin.is_finite(): return {}
		expected_casters.append({"id":old.id,"mesh":source.get("native_mesh_path"),"pose":Transform3D(Basis(x,y,z),origin),"added":false})
	for authored: Variant in plan.objects:
		if not authored is Dictionary: return {}
		if authored.get("source_kind")!="actual_native_gpu_capture": continue
		var native: Variant=authored.get("original_native_record")
		if typeof(authored.get("id"))!=TYPE_STRING or added.has(authored.id) or not native is Dictionary or not _ground_equal(native.get("draw_transform"),_ground_native_writer({"basis_columns":[[1.,0.,0.],[0.,1.,0.],[0.,0.,1.]],"origin_m":[0.,0.,0.]})) or not _ground_equal(native.get("local_ground_anchor_m"),_ground_native_writer([0.,0.,0.])): return {}
		var foot: Vector2=_pair(authored.get("world_foot_px"))
		if not foot.is_finite() or foot.x<0 or foot.y<0 or foot.x>=3072 or foot.y>=2048: return {}
		# Independent original point3 formula; actual Vector2 then Vector3 native
		# constructor order matches the writer, not a saved-side pose conversion.
		var origin:=Vector3((foot.x-1536)/64.,0.,(foot.y-1024)/32.)
		added.append(authored.id)
		expected_casters.append({"id":authored.id,"mesh":native.get("native_mesh_path"),"pose":Transform3D(Basis.IDENTITY,origin),"added":true})
	if not _ground_equal(side.get("removed_old_caster_ids"),removed) or not _ground_equal(side.get("added_native_caster_ids"),added) or not side.get("retained_or_new_casters") is Array or side.retained_or_new_casters.size()!=expected_casters.size(): return {}
	var meshes: Dictionary={}
	for index in expected_casters.size():
		var expected: Dictionary=expected_casters[index]
		var caster: Variant=side.retained_or_new_casters[index]
		if not caster is Dictionary or typeof(caster.get("id"))!=TYPE_STRING or caster.id!=expected.id or typeof(caster.get("added395"))!=TYPE_BOOL or caster.added395!=expected.added or typeof(caster.get("actual_saved_mesh_only"))!=TYPE_BOOL or caster.actual_saved_mesh_only!=true: return {}
		var mesh_path: Variant=expected.mesh
		if typeof(mesh_path)!=TYPE_STRING or not catalog.has(mesh_path) or typeof(caster.get("native_mesh_path"))!=TYPE_STRING or caster.native_mesh_path!=mesh_path or not _ground_equal(caster.get("native_mesh_sha256"),catalog[mesh_path]): return {}
		if not meshes.has(mesh_path): meshes[mesh_path]=ResourceLoader.load(mesh_path,"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
		if meshes[mesh_path]==null: return {}
		var pose: Transform3D=expected.pose
		var encoded: Variant=_ground_native_writer({"basis_columns":[_ground_array(pose.basis.x),_ground_array(pose.basis.y),_ground_array(pose.basis.z)],"origin_m":_ground_array(pose.origin)})
		if not _ground_equal(caster.get("basis_columns"),encoded.basis_columns) or not _ground_equal(caster.get("origin_m"),encoded.origin_m): return {}
	var floor_path: String=path.get_base_dir()+"/floor.png"
	if typeof(side.get("ground_path"))!=TYPE_STRING or side.ground_path!=floor_path or not catalog.has(floor_path) or not _ground_png_size(floor_path,Vector2i(3072,2048)): return {}
	for role: String in ["off","on"]:
		var raw_path: String=path.get_base_dir()+"/ground_"+role+"_raw.png"
		var repeat_path: String=path.get_base_dir()+"/ground_"+role+"_raw_repeat.png"
		if not catalog.has(raw_path) or not catalog.has(repeat_path) or not _ground_equal(catalog[raw_path],catalog[repeat_path]) or not _ground_png_size(raw_path,Vector2i(6144,4096)) or not _ground_png_size(repeat_path,Vector2i(6144,4096)): return {}
	var source: Image=Image.load_from_file(floor_path)
	var texture: Texture2D=ResourceLoader.load(floor_path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var imported: Image=texture.get_image() if texture!=null else null
	if source==null or imported==null or (imported.is_compressed() and imported.decompress()!=OK): return {}
	source.convert(Image.FORMAT_RGBA8); imported.convert(Image.FORMAT_RGBA8)
	if source.get_size()!=imported.get_size() or source.get_data()!=imported.get_data().slice(0,3072*2048*4): return {}
	for file: String in pins:
		if not _bound(file,pins[file]): return {}
	for file: String in catalog:
		if record.asset_sha256.has(file) and not _ground_equal(record.asset_sha256[file],catalog[file]): return {}
		record.asset_sha256[file]=catalog[file]
	record.ground_path=floor_path
	record.ground_capture_path=path
	record.ground_capture_sha256=digest
	ground_source_pins.merge(pins,true)
	return record

func verify_sources() -> bool:
	if not super.verify_sources(): return false
	for file: String in ground_source_pins:
		if not _bound(file,ground_source_pins[file]): return false
	return true

func release() -> void:
	ground_source_pins.clear()
	super.release()

func _bound(path: Variant,digest: Variant) -> bool:
	return typeof(path)==TYPE_STRING and path.begins_with("res://") and not ".." in path and typeof(digest)==TYPE_STRING and digest.length()==64 and FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==digest.to_lower()

func _json(path: String) -> Variant:
	var parser:=JSON.new()
	return parser.data if parser.parse(FileAccess.get_file_as_string(path))==OK else null

