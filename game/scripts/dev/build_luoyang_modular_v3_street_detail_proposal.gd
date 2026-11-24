extends RefCounted

# NEW SOURCE-ONLY material adapter, deliberately NOT a SceneTree export tool.
# No default capture, filesystem writer or adoption path. Root may later bind
# it to a NEW executor after reading the proposal and preserving old evidence.
const DETAIL := preload("res://scripts/dev/luoyang_modular_v3_street_detail_surface_proposal.gd")
const PINS := {
	"res://scripts/dev/build_luoyang_modular_v3_grey_tile_roof_revision.gd":"9ff930bc7be4f5ee8f7c39c364a01416cf87fc47f073ec3f6edf17ff35dc1e7f",
	"res://scripts/dev/build_luoyang_modular_v3_roof_revision.gd":"9cca9ac63a4a059cc5ac87478ab6ae17ce0c661b1c3d453271da505ea1ca3439",
	"res://scripts/dev/build_luoyang_modular_v3.gd":"3a7fa038d977c3671eeeda1dabaf8cd6c5e20807964b89eaee09ae0091950a30",
	"res://scripts/dev/luoyang_modular_v3_source.gd":"3a6f96cd823eb5e3f6d3b4fb1801d5e90342ed020ab293d3a578ccac048dbad5",
	"res://scripts/dev/luoyang_modular_v3_surface.gd":"76c65fa55f3e133829b3aab5b835ff7bf1d82bafb5ff99e54019df5458ee4f52"}
var detail: DETAIL
var evidence: Array[Dictionary]=[]
var error := ""
var frozen_snapshot: Dictionary={}

func prepare(snapshot: Dictionary) -> bool:
	error=""
	evidence.clear()
	for path: String in PINS:
		if FileAccess.get_sha256(path).to_lower()!=String(PINS[path]):
			error="Frozen city dependency changed: "+path
			return false
	if detail!=null: detail.release()
	detail=DETAIL.new()
	if not detail.configure(snapshot) or not detail.load_sources():
		error=detail.error
		return false
	frozen_snapshot=snapshot.duplicate(true)
	return true

func decorate_native_clone(original: ArrayMesh,role: String) -> ArrayMesh:
	# Copy the resource, not SurfaceTool reconstruction or re-triangulation.
	# Even resource duplication is checked against every stored native array;
	# nothing treats a successful constructor as proof of byte equality.
	if detail==null or original==null or original.get_surface_count()==0:
		error="Prepared actual material sources and nonempty actual native mesh required."
		return null
	if role not in ["paving","base_joints","wall_horizontal","wall_vertical"]:
		error="Outside proposal material scope: "+role
		return null
	var current: ArrayMesh=original.duplicate() as ArrayMesh
	if current==null or not _arrays_equal(original,current):
		error="Native mesh duplicate changed stored geometry; refuse instead of rebuilding it."
		return null
	var changed: Array[int]=[]
	if role=="paving" or role=="base_joints":
		var material: ShaderMaterial=detail.paving() if role=="paving" else detail.shoulder()
		for i in range(current.get_surface_count()):
			current.surface_set_material(i,material)
			changed.append(i)
	else:
		# The existing 9FF final raised grey-tile surface is retained exactly.
		# Original real brick/cap/pier meshes below it receive district masonry.
		var last: int=current.get_surface_count()-1
		if last<1:
			error="No original wall + separately added grey-tile surface; refuse guessed split."
			return null
		for i in range(last):
			var before: ShaderMaterial=original.surface_get_material(i) as ShaderMaterial
			if before==null or before.shader==null:
				error="Missing actual original masonry surface."
				return null
			var tint: Variant=before.get_shader_parameter("masonry_tint")
			var profile: Variant=before.get_shader_parameter("masonry_profile")
			if not tint is Vector3 or not profile is float:
				error="Actual original masonry profile/tint unbound."
				return null
			current.surface_set_material(i,detail.masonry(Color(tint.x,tint.y,tint.z),"yamen_white_lime_dark_stone" if float(profile)>.5 else "gate_grey_brick"))
			changed.append(i)
		if current.surface_get_material(last)!=original.surface_get_material(last):
			error="Proposal changed frozen dedicated grey-tile roof material."
			return null
	if not _arrays_equal(original,current):
		error="Material assignment changed primitive/array bytes."
		return null
	evidence.append({"status":"SOURCE_ONLY_NATIVE_CLONE_CHECK_NOT_CAPTURE_OR_FIELD_APPROVAL","role":role,"changed_material_surface_indices":changed,"original_surface_count":original.get_surface_count(),"current_surface_count":current.get_surface_count(),"actual_native_array_comparison":_array_evidence(original,current),"frozen_source_snapshot_variant_sha256":_hash(var_to_bytes(frozen_snapshot)),"scope":"same primitive/vertex/normal/UV/index/colour/tangent/skin arrays, no displacement or appended surfaces; source layout/collision/door/bodyPNG/physical navigation not mutated","roof_scope":"9FF final raised grey-tile surface unchanged; only original masonry surfaces material changes","material_records":detail.material_records.duplicate(true),"mandatory_future_checks":["independently load old/new .res arrays and sourcePNG/navigation/RF/collision/sourcefoot equality","actual bound shader reflection and sampler SHA; don't accept fallback defaults","raw full camera/SSAA2 repeat and exact OFF binary authority","four city real Field images; no approval inferred from source-only material records"]})
	return current

func source_only_plan() -> Dictionary:
	return {"status":"SOURCE_ONLY_CITY_VISUAL_DETAIL_PROPOSAL_NOT_APPROVED","capture_enabled":false,"parent_dependency_sha256":PINS,"new_surface_path":"res://scripts/dev/luoyang_modular_v3_street_detail_surface_proposal.gd","new_surface_sha256":FileAccess.get_sha256("res://scripts/dev/luoyang_modular_v3_street_detail_surface_proposal.gd"),"new_adapter_path":get_script().resource_path,"new_adapter_sha256":FileAccess.get_sha256(get_script().resource_path),"changes":["continuous route-centred traffic polish/dust and actual front-apron ownership","restrained world-metre patina variation with unchanged original stone ALBEDO","light base-edge grime from real source solid segments; NOT new cast shadow/decal","same real brick-row geometry, matching grey gate and white-lime yamen at declared2m generatedALBEDO/1.5m CC0 microdetail"],"unchanged":["all mesh arrays/UVs/indices/support","9FF grey-tile raised roof","3072x2048 cameras and RF","layout/sourcePNG/ordinary34x24+17 feet","NPC15/hotspots11/portals12/actions","blocking/Y/ghost/physical/body polygons"],"not_solved_by_material_only":["missing architectural density/empty composition cannot be cured by changing stone tone","no added wall/building/clutter or changed public route","no claim procedural wall tile normals are photographic geometry"],"evidence":evidence}

func _arrays_equal(a: ArrayMesh,b: ArrayMesh) -> bool:
	if a.get_surface_count()!=b.get_surface_count(): return false
	for i in range(a.get_surface_count()):
		if a.surface_get_primitive_type(i)!=b.surface_get_primitive_type(i): return false
		var aa: Array=a.surface_get_arrays(i)
		var bb: Array=b.surface_get_arrays(i)
		if aa.size()!=Mesh.ARRAY_MAX or bb.size()!=Mesh.ARRAY_MAX: return false
		for slot in range(Mesh.ARRAY_MAX):
			if var_to_bytes(aa[slot])!=var_to_bytes(bb[slot]): return false
	return true

func _array_evidence(a: ArrayMesh,b: ArrayMesh) -> Array[Dictionary]:
	var rows: Array[Dictionary]=[]
	for i in range(a.get_surface_count()):
		var aa: Array=a.surface_get_arrays(i)
		var bb: Array=b.surface_get_arrays(i)
		var slots: Array[Dictionary]=[]
		for slot in range(Mesh.ARRAY_MAX):
			var old_bytes: PackedByteArray=var_to_bytes(aa[slot])
			var new_bytes: PackedByteArray=var_to_bytes(bb[slot])
			slots.append({"slot":slot,"old_sha256":_hash(old_bytes),"new_sha256":_hash(new_bytes),"byte_exact":old_bytes==new_bytes})
		rows.append({"surface":i,"primitive":a.surface_get_primitive_type(i),"slots":slots})
	return rows

func _hash(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	if context.start(HashingContext.HASH_SHA256)!=OK: return ""
	if not bytes.is_empty() and context.update(bytes)!=OK: return ""
	return context.finish().hex_encode()

func release() -> void:
	if detail!=null: detail.release()
	detail=null
	frozen_snapshot.clear()
	evidence.clear()
