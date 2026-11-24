extends RefCounted
## Independent saved-caster oracle only. No renderer, production gate or selector
## calls. FULL raw/repeat/64/112, original body used-index/material/support and
## every Field/17-foot/Physics assertion remain mandatory in the caller.
const ROOT: String = "res://art/maps/world_map_v15_complete_v8/"
const SOURCE: String = "res://data/maps/world_map_v15_complete_v8_source.json"
const MANIFEST: String = ROOT + "art_contract.json"
const REPORT: String = ROOT + "whole_actual_capture.json"
const BUILDER: String = "res://scripts/dev/build_world_map_v15_coherent_whole_v8_full_proposal.gd"
const PROTOCOL: String = "COHERENT_WHOLE_FIXED_CAMERA_INTEGER_TEXEL_ROI_V1_FULL"
const PLANE: String = "V7_ACTUAL_PROTOTYPE_RGBA_CAMERA_PLANE_CASTER_SOURCE_ONLY"
const SIZE: Vector2 = Vector2(12288, 8192)
const GRID: Vector2i = Vector2i(1537, 1025)
const PPM: float = 102.4
const Z_PPM: float = PPM * 0.7071067811865476
const RF_WORLD_BUDGET: float = 0.0001
const PROJECTED_FOOT_BUDGET: float = 0.01
var checks: int = 0
var failures: int = 0
var catalog: Dictionary = {}
var heights: PackedFloat32Array = PackedFloat32Array()
var cached_planes: Dictionary = {}
var records: Array[Dictionary] = []

func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("[V7 CASTER FAIL] " + label)
	return ok

func _sha(bytes: PackedByteArray) -> String:
	var context: HashingContext = HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK: return ""
	return context.finish().hex_encode()

func _bound(path: String, expected: String = "") -> bool:
	if not path.begins_with("res://") or ".." in path or not FileAccess.file_exists(path): return false
	var recorded: String = String(catalog.get(path, ""))
	var current: String = FileAccess.get_sha256(path).to_lower()
	return recorded.length() == 64 and recorded.to_lower() == current and (expected.is_empty() or expected.length() == 64 and expected.to_lower() == current)

func _json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

func _p(value: Variant) -> Vector2:
	if value is Array and value.size() == 2 and typeof(value[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT, TYPE_FLOAT]: return Vector2(float(value[0]), float(value[1]))
	return Vector2(INF, INF)

func _v(value: Variant) -> Vector3:
	if value is Array and value.size() == 3:
		for component: Variant in value:
			if typeof(component) not in [TYPE_INT, TYPE_FLOAT]: return Vector3(INF, INF, INF)
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return Vector3(INF, INF, INF)

func _basis(value: Variant) -> Basis:
	if value is Array and value.size() == 3: return Basis(_v(value[0]), _v(value[1]), _v(value[2]))
	return Basis(Vector3(INF, INF, INF), Vector3(INF, INF, INF), Vector3(INF, INF, INF))

func _height(point: Vector2) -> float:
	if heights.size() != GRID.x * GRID.y or not point.is_finite() or point.x < 0 or point.y < 0 or point.x >= SIZE.x or point.y >= SIZE.y: return NAN
	var cell: Vector2i = Vector2i(floori(point.x / 8), floori(point.y / 8))
	var f: Vector2 = (point - Vector2(cell * 8)) / 8
	var n: int = cell.y * GRID.x + cell.x
	var a: float = heights[n]
	var b: float = heights[n + 1]
	var c: float = heights[n + GRID.x]
	var d: float = heights[n + GRID.x + 1]
	return a + (b - a) * f.x + (c - a) * f.y if f.x + f.y <= 1 else d + (c - d) * (1 - f.x) + (b - d) * (1 - f.y)

func _ground(point: Vector2, height: float) -> Vector3:
	return Vector3((point.x - SIZE.x * .5) / PPM, height, (point.y - SIZE.y * .5) / Z_PPM)

## pins: exact current source/M/report/builder/RF path -> SHA, supplied only
## after root freezes final artifacts. Unknown paths, PENDING and regional fail.
func run(pins: Dictionary) -> Dictionary:
	checks = 0
	failures = 0
	records.clear()
	cached_planes.clear()
	heights.clear()
	catalog.clear()
	var required: Array[String] = [SOURCE, MANIFEST, REPORT, BUILDER, ROOT + "terrain_height.rf"]
	if not _check(pins.size() == required.size(), "exact five final inputs; no implicit latest/PENDING authority"): return _result()
	for path: String in required:
		var hash: String = String(pins.get(path, ""))
		if not _check(hash.length() == 64 and FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower() == hash.to_lower(), "literal final current input: " + path): return _result()
	var source: Dictionary = _json(SOURCE)
	var manifest: Dictionary = _json(MANIFEST)
	var report: Dictionary = _json(REPORT)
	var capture: Variant = source.get("capture")
	if not _check(source.get("status") == "ART_ASSETS_READY" and source.get("art_revision") == "complete_v8_coherent_whole" and manifest.get("art_revision") == "complete_v8_coherent_whole" and manifest.get("source_contract_path") == SOURCE and capture is Dictionary and capture.get("capture_protocol") == PROTOCOL and manifest.get("capture_protocol") == PROTOCOL, "new final v7 artifacts, not v6 relabel or authoring plan"): return _result()
	var assets: Variant = manifest.get("asset_sha256")
	if not _check(assets is Dictionary, "current actual asset catalog typed"): return _result()
	catalog = assets.duplicate(true)
	var binding: Variant = manifest.get("whole_actual_capture")
	var executed: Variant = report.get("executed_builder")
	if not _check(binding is Dictionary and binding.get("path") == REPORT and _bound(REPORT, String(binding.get("sha256", ""))) and executed is Dictionary and executed.get("path") == BUILDER and _bound(BUILDER, String(executed.get("sha256", ""))), "current report and actually executed final source bytes"): return _result()
	if not _check(report.get("capture_protocol") == PROTOCOL and report.get("scope") == "FULL64_112SEAMS_NEW_PROTOCOL_NOT_FORMAL_APPROVED" and report.get("status") == "FULL64_112SEAMS_NEW_PROTOCOL_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_REVIEW" and report.get("chunk_count_required") == 64 and report.get("seam_count_required") == 112 and report.get("input_hashes_unchanged_after") == true, "FULL-only container; regional result is schema reference never acceptance"): return _result()
	if not _check(_bound(SOURCE, String(pins[SOURCE])) and _bound(ROOT + "terrain_height.rf", String(pins[ROOT + "terrain_height.rf"])), "captured source and actual RF catalog bound"): return _result()
	var grid: Variant = source.get("geometry")
	if not _check(grid is Dictionary and grid.get("height_grid_shape") == [1537,1025] and grid.get("height_grid_origin_px") == [0,0] and grid.get("source_node_spacing_px") == 8 and grid.get("height_rf_path") == ROOT + "terrain_height.rf" and String(grid.get("height_rf_sha256", "")).to_lower() == String(pins[ROOT + "terrain_height.rf"]).to_lower(), "literal zero-origin 8px RF authority, not same-length differently spaced bytes"): return _result()
	var rf: PackedByteArray = FileAccess.get_file_as_bytes(ROOT + "terrain_height.rf")
	if not _check(rf.size() == GRID.x * GRID.y * 4, "actual little-endian Float32 8px RF byte count"): return _result()
	heights = rf.to_float32_array()
	var objects: Variant = source.get("objects")
	var worlds: Variant = report.get("worlds")
	if not _check(objects is Array and worlds is Dictionary and worlds.size() == 2 and worlds.get("primary") is Dictionary and worlds.get("reference") is Dictionary, "typed native objects and exact two fresh worlds"): return _result()
	var expected: Dictionary = {}
	for value: Variant in objects:
		if not _check(value is Dictionary, "typed source object"): continue
		if not value.has("prototype_actual_sourcebody_evidence"): continue
		var id: String = String(value.get("id", ""))
		if not _check(not id.is_empty() and not expected.has(id) and value.get("prototype_actual_sourcebody_evidence") is Dictionary, "unique native ID with original body evidence"): continue
		var pose_value: Variant = value.get("pose")
		if not _check(value.get("kind") in ["tree","bamboo","boulder","herb"] and typeof(pose_value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(pose_value)) and float(pose_value) == floorf(float(pose_value)) and float(pose_value) >= 0 and float(pose_value) <= 2, "literal licensed/original native kind and three-pose domain"): continue
		expected[id] = value
	if not _check(not expected.is_empty(), "actual native caster domain is nonempty"): return _result()
	var world_ids: Dictionary = {}
	var signatures: Dictionary = {}
	for identity: String in ["primary", "reference"]:
		var world: Dictionary = worlds[identity]
		var actual_id: Variant = world.get("world_3d_instance_id")
		var node_id: Variant = world.get("world_node_instance_id")
		_check(world.get("identity") == identity and typeof(actual_id) in [TYPE_INT, TYPE_FLOAT] and float(actual_id) != 0 and not world_ids.has(str(actual_id)) and typeof(node_id) in [TYPE_INT, TYPE_FLOAT] and float(node_id) != 0, "distinct actual World3D and typed world node: " + identity)
		world_ids[str(actual_id)] = true
		var casters: Variant = world.get("casters")
		if not _check(casters is Array and casters.size() == expected.size(), "all native caster IDs, no missing or extra stems: " + identity): continue
		var roles: Variant = world.get("roles")
		if _check(roles is Dictionary and roles.size() == 5, "all actual capture roles disclose real caster visibility"):
			for role: String in ["visual","shadow_off","land","raw_walk","walk"]:
				var role_record: Variant = roles.get(role)
				_check(role_record is Dictionary and role_record.get("caster_actual_visible") == (role == "visual") and role_record.get("caster_shadow_setting_actual") == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY, "actual caster visible only for visual shadow pass, no binary contamination: " + identity + "/" + role)
		var seen: Dictionary = {}
		var own_signatures: Dictionary = {}
		for value: Variant in casters:
			if not _check(value is Dictionary, "typed actual caster row"): continue
			var id: String = String(value.get("id", ""))
			if not _check(expected.has(id) and not seen.has(id), "exact unique original source ID in " + identity + ": " + id): continue
			seen[id] = true
			var entry: Dictionary = expected[id]
			var first: int = failures
			var is_plane: bool = id.begins_with("v7_") and entry.get("kind") in ["tree", "bamboo"]
			_check(value.get("kind") == entry.get("kind") and value.get("pose") == entry.get("pose") and _p(value.get("source_foot_px")) == _p(entry.get("source_XZ_foot_px")) and value.get("sourcebody_baked") == false and value.get("shadow_on_enum") == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY, "own original kind/pose/source foot and real shadows-only node: " + id)
			_instance(value, entry, is_plane)
			if is_plane: _plane(value, entry, identity)
			else: _native(value, entry)
			# Independently serialized RES files have different embedded resource
			# identifiers. Compare exact decoded arrays/material pixels across worlds;
			# each original file SHA remains independently checked above, never equal
			# solely because a record says they share a pose.
			var physical_geometry: Variant = [value.get("native_stored_vertex_sha256"), value.get("native_stored_normal_sha256"), value.get("native_stored_uv_sha256"), value.get("native_stored_index_sha256")] if is_plane else value.get("actual_draw_mesh_sha256")
			var signature: Dictionary = {"kind":value.get("kind"), "pose":value.get("pose"), "source_foot_px":value.get("source_foot_px"), "transform":value.get("transform"), "geometry_sha256":physical_geometry, "recipe":value.get("caster_recipe"), "sourcebody_sha256":value.get("actual_sourcebody_sha256", ""), "foot_uv":value.get("actual_foot_uv", []), "size":value.get("logical_canvas_px", [])}
			own_signatures[id] = signature
			records.append({"world":identity,"id":id,"branch":"ACTUAL_RGBA_CAMERA_PLANE" if is_plane else "ORIGINAL_NATIVE_CASTER_BINDING","complete":failures == first,"mesh_path":value.get("actual_draw_mesh_path"),"mesh_sha256":value.get("actual_draw_mesh_sha256"),"source_png_sha256":value.get("actual_sourcebody_sha256", ""),"ground_height_m":_height(_p(value.get("source_foot_px"))),"original_body_oracle_still_required":true})
		_check(seen.size() == expected.size(), "complete unique native ID coverage: " + identity)
		signatures[identity] = own_signatures
	_check(signatures.get("primary", {}) == signatures.get("reference", {}) and not signatures.get("primary", {}).is_empty(), "both independently captured worlds bind every identical physical caster pose/source SHA")
	for path: String in required: _check(FileAccess.get_sha256(path).to_lower() == String(pins[path]).to_lower(), "final inputs unchanged during independent caster reads: " + path)
	return _result()

func _instance(record: Dictionary, entry: Dictionary, plane: bool) -> void:
	var point: Vector2 = _p(record.get("source_foot_px"))
	var h: float = _height(point)
	var ground: Vector3 = _ground(point, h)
	var transform: Variant = record.get("transform")
	if not _check(is_finite(h) and transform is Dictionary, "own actual affine RF ground and full instance transform"): return
	var basis: Basis = _basis(transform.get("basis_columns"))
	var origin: Vector3 = _v(transform.get("origin"))
	var prototype: Dictionary = entry.prototype_actual_sourcebody_evidence
	var expected_basis: Basis = Basis.IDENTITY if plane else _basis(prototype.get("basis_columns"))
	var expected_origin: Vector3 = ground if plane else ground - _v(prototype.get("support_m"))
	_check(basis.x == expected_basis.x and basis.y == expected_basis.y and basis.z == expected_basis.z and origin.is_finite() and origin.distance_to(expected_origin) <= RF_WORLD_BUDGET, "identity plane or unchanged native pose/support transformed onto signed RF (.0001m)")
	var projected: Vector2 = point - Vector2(0, h * Z_PPM)
	_check(_p(entry.get("world_foot_px")).distance_to(projected) < PROJECTED_FOOT_BUDGET and (_p(entry.get("pos")) * SIZE + (_p(entry.get("foot_uv")) - Vector2(.5,.5)) * _p(entry.get("render_size_px"))).distance_to(projected) < PROJECTED_FOOT_BUDGET, "own original body sprite foot/projected RF contact (.01px existing budget)")
	if plane: _check(_v(record.get("world_foot_m")) == origin, "plane record origin is actual RF support, not original GLTF minimumY")
	else:
		var original_transform: Variant = entry.get("actual_model_transform")
		_check(original_transform is Dictionary and _basis(original_transform.get("basis_columns")) == basis and _v(original_transform.get("origin")) == origin and _v(record.get("support_m")) == _v(prototype.get("support_m")), "native caster retains body model transform and original measured support")

func _native(record: Dictionary, entry: Dictionary) -> void:
	var body: Dictionary = entry.prototype_actual_sourcebody_evidence
	var origin: Variant = body.get("sourcebody_capture_origin", {})
	var path: String = String(origin.get("actual_GPU_loaded_mesh_path", body.get("actual_draw_mesh_path", ""))) if origin is Dictionary else ""
	var hash: String = String(origin.get("actual_GPU_loaded_mesh_sha256", body.get("actual_draw_mesh_sha256", ""))) if origin is Dictionary else ""
	_check(not record.has("identity") and record.get("caster_recipe") == "original unchanged native used-index model/pose; herb and boulder are never camera planes" and record.get("actual_draw_mesh_path") == path and record.get("actual_draw_mesh_sha256") == hash and _bound(path, hash) and body.get("sourcebody_and_caster_same_model_material_transform") == true, "original native caster binding stays strict; caller must still run original used-index/material/support oracle")

func _plane(record: Dictionary, entry: Dictionary, identity: String) -> void:
	var body: Dictionary = entry.prototype_actual_sourcebody_evidence
	var original: String = String(body.get("texture", ""))
	var path: String = String(record.get("actual_draw_mesh_path", ""))
	var uv: Vector2 = _p(body.get("foot_uv"))
	var size: Vector2 = _p(body.get("render_size_px"))
	if not _check(record.get("identity") == PLANE and record.get("caster_recipe") == "NEW actual RGBA camera plane; NOT original GLTF/native support mesh" and path == ROOT + "capture/" + identity + "/actual_plane_prototype_" + String(entry.kind) + str(int(entry.pose)) + ".res" and _bound(path, String(record.get("actual_draw_mesh_sha256", ""))) and record.get("actual_sourcebody_path") == original and _bound(original, String(record.get("actual_sourcebody_sha256", ""))), "actual world-specific saved plane and bound original native PNG, not a shadow raster"): return
	_check(record.get("status") == "SOURCE_ONLY_NOT_GPU_VERIFIED_OR_APPROVED" and record.get("sourcebody_baked") == false, "prototype source-only status honestly retained; container is separate actual FULL evidence")
	if not _check(record.get("actual_surface_count") == 1 and record.get("actual_draw_vertices") == 4 and record.get("actual_draw_indices") == 6 and record.get("actual_triangles") == 2 and record.get("actual_cast_shadow_enum") == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY and record.get("logical_pixels_per_metre") == PPM and _p(record.get("actual_foot_uv")) == uv and _p(record.get("logical_canvas_px")) == size and (_p(entry.get("foot_uv")) * size).distance_to(uv * size) < PROJECTED_FOOT_BUDGET and _p(entry.get("render_size_px")) == size and Rect2(Vector2.ZERO, Vector2.ONE).has_point(uv), "measured prototype foot exact; instance pixel foot uses original .01px projection budget; 1surface/4vertices/2triangles and literal metre scale"): return
	var signature: String = JSON.stringify([record.actual_draw_mesh_sha256, record.actual_sourcebody_sha256, uv.x, uv.y, size.x, size.y, record.get("native_stored_vertex_sha256"), record.get("native_stored_normal_sha256"), record.get("native_stored_uv_sha256"), record.get("native_stored_index_sha256"), record.get("actual_material_properties"), record.get("basis_columns")]).sha256_text()
	if cached_planes.has(signature):
		_check(cached_planes[signature] == true, "same verified complete plane bytes reused, own instance RF still checked")
		return
	var before: int = failures
	var mesh: ArrayMesh = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if not _check(mesh != null and mesh.get_surface_count() == 1 and mesh.surface_get_primitive_type(0) == Mesh.PRIMITIVE_TRIANGLES, "saved real ArrayMesh triangle surface"): return
	var png: Image = Image.load_from_file(original)
	if not _check(png != null and not png.is_empty() and not png.is_compressed() and png.get_size() == Vector2i(size) and not png.has_mipmaps(), "actual original PNG canvas, no alpha threshold or resize"): return
	var embedded_original: Image = png.duplicate() as Image
	if not _check(embedded_original.generate_mipmaps() == OK, "independent original PNG mip pyramid generation on private copy"): return
	var right: Vector3 = Vector3.RIGHT
	var up: Vector3 = Vector3(0, 1, -1).normalized()
	var back: Vector3 = Vector3(0, 1, 1).normalized()
	_check(_basis(record.get("basis_columns")) == Basis(right, up, back), "actual saved orthographic plane axes independently normalized")
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var tex_uv: PackedVector2Array = PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)])
	for corner: Vector2 in tex_uv:
		# Pixel corners are first represented in native Vector2, then projected
		# into metres. This preserves declared Float32 pixel representation before
		# the independent saved ArrayMesh control; no decoded vertex is copied.
		var screen: Vector2 = Vector2((corner.x - uv.x) * size.x, (uv.y - corner.y) * size.y)
		vertices.append(right * (screen.x / PPM) + up * (screen.y / PPM))
		normals.append(back)
	var indices: PackedInt32Array = PackedInt32Array([0,1,2,1,3,2])
	var input: Array = []
	input.resize(Mesh.ARRAY_MAX)
	input[Mesh.ARRAY_VERTEX] = vertices
	input[Mesh.ARRAY_NORMAL] = normals
	input[Mesh.ARRAY_TEX_UV] = tex_uv
	input[Mesh.ARRAY_INDEX] = indices
	var control: ArrayMesh = ArrayMesh.new()
	control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, input)
	var actual: Array = mesh.surface_get_arrays(0)
	var expected: Array = control.surface_get_arrays(0)
	if not _check(actual.size() == Mesh.ARRAY_MAX, "complete saved array slot domain"): return
	var exact: bool = true
	for slot: int in Mesh.ARRAY_MAX:
		exact = exact and typeof(actual[slot]) == typeof(expected[slot]) and actual[slot] == expected[slot]
	if not _check(exact, "ALL saved array slots equal independent four-corner control through same native packing; no tangent/normal waiver"): return
	for binding: Array in [[Mesh.ARRAY_VERTEX,"native_stored_vertex_sha256"],[Mesh.ARRAY_NORMAL,"native_stored_normal_sha256"],[Mesh.ARRAY_TEX_UV,"native_stored_uv_sha256"],[Mesh.ARRAY_INDEX,"native_stored_index_sha256"]]:
		_check(record.get(binding[1]) == _sha(actual[binding[0]].to_byte_array()), "actual stored array SHA: " + String(binding[1]))
	var material: StandardMaterial3D = mesh.surface_get_material(0) as StandardMaterial3D
	if _check(material != null and material.albedo_texture != null, "saved actual material and embedded PNG texture"):
		var threshold: float = PackedFloat32Array([.12])[0]
		_check(material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR and material.alpha_scissor_threshold == threshold and material.cull_mode == BaseMaterial3D.CULL_DISABLED and material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC and material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "literal .12 nativeFloat32 scissor/linear+mips/aniso/no cull/unshaded material")
		var properties: Variant = record.get("actual_material_properties")
		_check(properties is Dictionary and properties.get("transparency") == material.transparency and properties.get("cull_mode") == material.cull_mode and properties.get("texture_filter") == material.texture_filter and properties.get("shading_mode") == material.shading_mode and typeof(properties.get("alpha_scissor_threshold")) in [TYPE_INT,TYPE_FLOAT] and PackedFloat32Array([float(properties.get("alpha_scissor_threshold"))])[0] == threshold, "record mirrors actual native properties; Float32 re-encoding only, no tolerance")
		var image: Image = material.albedo_texture.get_image()
		var private_image: Image = image.duplicate() as Image if image != null else null
		_check(private_image != null and private_image.get_size() == embedded_original.get_size() and private_image.get_format() == embedded_original.get_format() and private_image.get_mipmap_count() == embedded_original.get_mipmap_count() and private_image.get_data() == embedded_original.get_data(), "entire embedded PNG RGBA and all mip bytes exactly equal independent source reconstruction")
		private_image = null
		image = null
	material = null
	png = null
	embedded_original = null
	mesh = null
	control = null
	actual.clear()
	expected.clear()
	input.clear()
	cached_planes[signature] = failures == before

func _result() -> Dictionary:
	return {"scope":"INDEPENDENT_V7_SAVED_CASTER_GEOMETRY_AND_MATERIAL_ONLY_NOT_BODY_OR_FIELD_OR_FULL_ACCEPTANCE","checks":checks,"failed":failures,"complete":failures == 0 and not records.is_empty(),"records":records.duplicate(true),"source_body_geometry_material_support_and_raw_repeat":"REQUIRES_UNMODIFIED_ORIGINAL_BODY_ORACLE","whole_64_112_zero_pixel_predicates":"NOT_RUN_BY_THIS_PROBE","full17_actual_physics_normal_input":"NOT_RUN_BY_THIS_PROBE","visual_approved":false,"production_approved":false}

func release() -> void:
	heights.clear()
	cached_planes.clear()
	catalog.clear()
	records.clear()

