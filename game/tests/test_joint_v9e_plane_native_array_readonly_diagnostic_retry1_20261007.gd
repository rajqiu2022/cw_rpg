extends SceneTree
## Read-only geometry codec diagnostic; NOT publication, RF reconstruction or Field QA.
## Independently authored arrays enter the same native ArrayMesh storage boundary.
## Saved resources and recorded hashes are observations, never expected geometry inputs.
const GATE = preload("res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd")
const PINS := {
	"res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd":"460fb5d0dad60917429a169e4be502894a156a1ac4ed88fbdfb50153ef3376c2",
	"res://scripts/dev/world_map_v15_complete_v7_billboard_caster_proposal.gd":"d2d3795942aa452a18abc006d45bcde44749ccad276a7ec16e0f897604611290",
	"res://data/maps/world_map_v15_complete_v9c_source.json":"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
	"res://art/maps/world_map_v15_complete_v9c/art_contract.json":"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
	"res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json":"cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851"
}
const SOURCE_PATH := "res://data/maps/world_map_v15_complete_v9c_source.json"
const MANIFEST_PATH := "res://art/maps/world_map_v15_complete_v9c/art_contract.json"
const REPORT_PATH := "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const SLOTS := {Mesh.ARRAY_VERTEX:"native_stored_vertex_sha256", Mesh.ARRAY_NORMAL:"native_stored_normal_sha256", Mesh.ARRAY_TEX_UV:"native_stored_uv_sha256", Mesh.ARRAY_INDEX:"native_stored_index_sha256"}
var checks := 0
var errors: Array[String] = []
var pins: Dictionary = PINS.duplicate()

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func _read(path: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary: return {}
	return parser.data

func _bytes(value: Variant) -> PackedByteArray:
	if value == null: return var_to_bytes(value)
	return value.to_byte_array()

func _difference(a: PackedByteArray, b: PackedByteArray) -> Dictionary:
	for i in mini(a.size(), b.size()):
		if a[i] != b[i]:
			var scalar: int = (i / 4) * 4
			var result: Dictionary = {"byte":i,"a_byte":a[i],"b_byte":b[i]}
			if scalar + 4 <= mini(a.size(), b.size()):
				result["float32_scalar_index"] = scalar / 4
				result["a_scalar_hex"] = a.slice(scalar, scalar + 4).hex_encode()
				result["b_scalar_hex"] = b.slice(scalar, scalar + 4).hex_encode()
				result["a_scalar"] = a.decode_float(scalar)
				result["b_scalar"] = b.decode_float(scalar)
			return result
	return {"length_a":a.size(),"length_b":b.size()} if a.size() != b.size() else {}

func _authored(body: Dictionary, literal_basis: bool) -> Array:
	var foot: Array = body.prototype_actual_sourcebody_evidence.foot_uv
	var uv := Vector2(float(foot[0]), float(foot[1]))
	var canvas := Vector2(float(body.render_size_px[0]), float(body.render_size_px[1]))
	var up := Vector3(0, sqrt(.5), -sqrt(.5))
	var back := Vector3(0, sqrt(.5), sqrt(.5))
	if literal_basis:
		up = Vector3(0, 0.7071067811865476, -0.7071067811865476)
		back = Vector3(0, 0.7071067811865476, 0.7071067811865476)
	var uv_values := PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)])
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	for t: Vector2 in uv_values:
		var screen := Vector2((t.x-uv.x)*canvas.x,(uv.y-t.y)*canvas.y)
		positions.append(Vector3.RIGHT*(screen.x/102.4)+up*(screen.y/102.4))
		normals.append(back)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uv_values
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0,1,2,1,3,2])
	return arrays

func _bind(path: String, catalog: Dictionary) -> void:
	_check(GATE._bound(catalog,path) and GATE._same_hash(catalog.get(path),FileAccess.get_sha256(path)), "actual catalog/file SHA: " + path)
	if GATE._bound(catalog,path): pins[path] = catalog[path]

func _material(mesh: ArrayMesh, body: Dictionary, record: Dictionary, path: String) -> void:
	# These checks were not reached by ROOT293 after the first plane-array error.
	var material := mesh.surface_get_material(0) as StandardMaterial3D
	_check(material != null, "actual StandardMaterial3D: " + path)
	if material == null: return
	_check(material.albedo_texture != null and material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR and GATE._near(material.alpha_scissor_threshold,.12) and material.cull_mode == BaseMaterial3D.CULL_DISABLED and material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC and material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "actual strict plane alpha/material/sampler: " + path)
	var r: Dictionary = record.actual_material_properties
	_check(GATE._num(r.get("transparency"),material.transparency) and GATE._near(r.get("alpha_scissor_threshold"),material.alpha_scissor_threshold) and GATE._num(r.get("cull_mode"),material.cull_mode) and GATE._num(r.get("texture_filter"),material.texture_filter) and GATE._num(r.get("shading_mode"),material.shading_mode), "actual material record association: " + path)
	if material.albedo_texture == null: return
	var embedded := material.albedo_texture.get_image()
	var original := Image.load_from_file(body.prototype_actual_sourcebody_evidence.texture)
	_check(embedded != null and original != null, "actual PNG/embedded images: " + path)
	if embedded == null or original == null: return
	if embedded.is_compressed(): _check(embedded.decompress() == OK, "actual embedded decompress: " + path)
	_check(original.generate_mipmaps() == OK, "actual original mip generation: " + path)
	_check(embedded.get_format() == original.get_format() and embedded.get_size() == original.get_size() and embedded.get_data() == original.get_data(), "actual entire embedded mip bytes equal original generated mip chain: " + path)
	print("V9E_PLANE_MATERIAL ", JSON.stringify({"path":path,"embedded_bytes":embedded.get_data().size(),"embedded_sha":GATE._bytes_sha(embedded.get_data()),"original_mip_sha":GATE._bytes_sha(original.get_data())}))

func _run() -> void:
	for path: String in pins: _check(GATE._same_hash(pins[path],FileAccess.get_sha256(path)), "frozen source pin: " + path)
	var source := _read(SOURCE_PATH)
	var manifest := _read(MANIFEST_PATH)
	var report := _read(REPORT_PATH)
	_check(not source.is_empty() and not manifest.is_empty() and not report.is_empty(), "actual S/M/report parsed")
	var unique: Dictionary = {}
	var populations: Dictionary = {"primary":0,"reference":0}
	if errors.is_empty():
		var catalog: Dictionary = manifest.asset_sha256
		var bodies: Dictionary = {}
		for body: Dictionary in source.objects: bodies[body.id] = body
		for identity: String in ["primary","reference"]:
			var world_paths: Dictionary = {}
			for record: Dictionary in report.worlds[identity].casters:
				if record.get("identity") != "V7_ACTUAL_PROTOTYPE_RGBA_CAMERA_PLANE_CASTER_SOURCE_ONLY": continue
				populations[identity] += 1
				_check(bodies.has(record.id), "actual source plane body: " + str(record.id))
				if not bodies.has(record.id): continue
				var body: Dictionary = bodies[record.id]
				var path: String = record.actual_draw_mesh_path
				_check(path == "res://art/maps/world_map_v15_complete_v9c/capture/" + identity + "/actual_plane_prototype_" + String(body.kind) + str(int(body.pose)) + ".res", "exact world/kind/pose saved path: " + path)
				world_paths[path] = true
				var signature: Dictionary = {"kind":body.kind,"pose":body.pose,"foot":body.prototype_actual_sourcebody_evidence.foot_uv,"size":body.render_size_px,"texture":body.prototype_actual_sourcebody_evidence.texture,"material":record.actual_material_properties}
				for slot in SLOTS: signature[SLOTS[slot]] = record.get(SLOTS[slot])
				if unique.has(path):
					_check(GATE._equal_exact_value(unique[path].signature,signature), "all reused actual pose records agree: " + path)
					unique[path].count += 1
					continue
				_bind(path,catalog)
				_bind(signature.texture,catalog)
				unique[path] = {"signature":signature,"count":1}
				var mesh := ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
				_check(mesh != null and mesh.get_surface_count() == 1 and mesh.surface_get_primitive_type(0) == Mesh.PRIMITIVE_TRIANGLES, "actual saved two-triangle mesh: " + path)
				if mesh == null or mesh.get_surface_count() != 1: continue
				var saved: Array = mesh.surface_get_arrays(0)
				var authored: Array = _authored(body,false)
				var literal: Array = _authored(body,true)
				var control := ArrayMesh.new()
				control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,authored)
				var stored: Array = control.surface_get_arrays(0)
				_check(mesh.surface_get_format(0) == control.surface_get_format(0), "actual/native independent control surface format: " + path)
				for slot in Mesh.ARRAY_MAX:
					var a := _bytes(authored[slot])
					var c := _bytes(stored[slot])
					var s := _bytes(saved[slot])
					_check(typeof(authored[slot]) == typeof(literal[slot]) and a == _bytes(literal[slot]), "sqrt vs exact frozen literal basis native authored bytes: %s/%d" % [path,slot])
					_check(typeof(saved[slot]) == typeof(stored[slot]) and s == c, "saved vs independently native-stored complete slot: %s/%d" % [path,slot])
					if SLOTS.has(slot): _check(GATE._same_hash(record.get(SLOTS[slot]),GATE._bytes_sha(s)), "actual saved native record SHA: %s/%d" % [path,slot])
					print("V9E_PLANE_NATIVE_SLOT ",JSON.stringify({"path":path,"slot":slot,"authored_type":typeof(authored[slot]),"stored_type":typeof(stored[slot]),"saved_type":typeof(saved[slot]),"authored_sha":GATE._bytes_sha(a),"stored_sha":GATE._bytes_sha(c),"saved_sha":GATE._bytes_sha(s),"record_sha":record.get(SLOTS.get(slot,"")),"authored_saved_first_difference":_difference(a,s),"control_saved_first_difference":_difference(c,s)}))
				_material(mesh,body,record,path)
			_check(world_paths.size() == 6, "exact six world-specific pose paths: " + identity)
		_check(populations.primary == 1861 and populations.reference == 1861 and unique.size() == 12, "both complete actual plane populations/twelve world-specific paths, six poses each")
	for path: String in pins: _check(GATE._same_hash(pins[path],FileAccess.get_sha256(path)), "consumed frozen source unchanged: " + path)
	print("V9E_PLANE_NATIVE_ARRAY_READONLY_DIAGNOSTIC ",JSON.stringify({"scope":"READ_ONLY_INDEPENDENT_NATIVE_ARRAYMESH_CODEC_NOT_PUBLICATION","checks":checks,"failures":errors.size(),"errors":errors,"populations":populations,"unique":unique,"consumed_files":pins.size(),"factory_called":false,"art_written":false,"RF_rebuilt":false,"Field_executed":false,"formal_cutover":false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm",.15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
