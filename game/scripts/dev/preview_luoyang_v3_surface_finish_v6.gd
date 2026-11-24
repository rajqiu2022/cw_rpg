extends "res://scripts/dev/build_luoyang_modular_v3.gd"

## READ saved V5 meshes/PNGs. WRITE only a new build preview directory.
## Never call parent _run/_capture_city/_prototype/_finish or any publisher.
## Scene composites at 1 logical px per source px, not Field/gameplay captures.
const FINISH := preload("res://scripts/dev/luoyang_modular_v3_surface_finish_v6_preview.gd")
const INPUT_ROOT := "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/"
const OUTPUT_ROOT := "res://build/luoyang_surface_finish_v6_preview/"
const REGIONS := ["ch4_s1_luoyang_yamen", "ch4_s2_canal_docks"]
const MANIFEST_SHA := {
	"ch4_s1_luoyang_yamen":"b7bfdd920ba69858b70c9cf77c5d3b65161f14032ae3eb0e1f5f5f0b04385315",
	"ch4_s2_canal_docks":"5ac079c73a9ab7716c62d7ba540d39a513be93ed17f5feef0effbd2e1ac26cdb"
}
const HELPER_PINS := {
	"res://scripts/dev/build_luoyang_modular_v3.gd":"3a7fa038d977c3671eeeda1dabaf8cd6c5e20807964b89eaee09ae0091950a30",
	"res://scripts/dev/luoyang_modular_v3_source.gd":"3a6f96cd823eb5e3f6d3b4fb1801d5e90342ed020ab293d3a578ccac048dbad5",
	"res://scripts/dev/luoyang_modular_v3_surface.gd":"76c65fa55f3e133829b3aab5b835ff7bf1d82bafb5ff99e54019df5458ee4f52",
	"res://scripts/dev/luoyang_modular_v3_zone_finish_candidate.gd":"26299495f76c3236d622f899efedf6fe27605b8e6783ea9c345f61030820b5be"
}
const SAMPLE_RECTS := {
	"ch4_s1_luoyang_yamen":Rect2i(576,650,1920,1080),
	"ch4_s2_canal_docks":Rect2i(1152,720,1920,1080)
}
var preview_out := ""
var inputs: Dictionary = {}
var results: Array[Dictionary] = []
var finish: FINISH
var active_manifest: Dictionary = {}
var active_region := ""
var clone_rows: Array[Dictionary] = []
var alpha_rows: Array[Dictionary] = []
var sampler_pairs: Dictionary = {}
var checkpoint_guard: Dictionary = {}
var preview_outputs: Dictionary = {}
var dependency_checked: Dictionary = {}

func _run() -> void:
	# Deferred entry runs after autoload ready. Before the first await or any
	# fixture/render work, require the new PUBLIC checkpoint-suspension API.
	# Keep it suspended until this exclusive tool process quits; never restore
	# fixture navigation as a production save checkpoint.
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		push_error("Preview requires the public PlatformBridge checkpoint-save guard; no fallback/private mutation.")
		quit(2)
		return
	bridge.call("set_checkpoint_saves_suspended", true)
	var suspended: Variant = bridge.call("is_checkpoint_saves_suspended")
	if not suspended is bool or not suspended:
		push_error("Preview public checkpoint-save suspension was not verified.")
		quit(2)
		return
	checkpoint_guard = {"public_api":"PlatformBridge.set_checkpoint_saves_suspended(true)", "actual_verified_suspended":true, "set_before_first_await":true, "restore_before_quit":false}
	var bridge_script: Script = bridge.get_script() as Script
	if bridge_script == null or not _input(bridge_script.resource_path):
		push_error("Preview cannot bind the actual public checkpoint-guard implementation.")
		quit(2)
		return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var tag := ""
	for arg: String in args:
		if arg.begins_with("--preview-run-tag="): tag = arg.trim_prefix("--preview-run-tag=")
	var rule := RegEx.new()
	if "--luoyang-surface-v6-preview" not in args or rule.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$") != OK or rule.search(tag) == null:
		error = "Explicit --luoyang-surface-v6-preview and a fresh --preview-run-tag are required."
		await _preview_finish(false)
		return
	if DisplayServer.get_name() == "headless":
		error = "Preview requires a real serial GPU window; headless refused."
		await _preview_finish(false)
		return
	preview_out = OUTPUT_ROOT + tag + "/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(preview_out)):
		error = "Preview refuses overwrite, including earlier failed evidence."
		preview_out = ""
		await _preview_finish(false)
		return
	for path: String in HELPER_PINS:
		if not _input(path, HELPER_PINS[path]):
			await _preview_finish(false)
			return
	for path: String in [get_script().resource_path, "res://scripts/dev/luoyang_modular_v3_surface_finish_v6_preview.gd"]:
		if not _input(path):
			await _preview_finish(false)
			return
	finish = FINISH.new()
	if not finish.load_sources():
		error = finish.error
		await _preview_finish(false)
		return
	for row: Dictionary in finish.evidence:
		for key: String in ["path", "source_path"]:
			if not _input(String(row[key])):
				await _preview_finish(false)
				return
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(preview_out)) != OK:
		error = "Cannot create isolated preview directory."
		preview_out = ""
		await _preview_finish(false)
		return
	for region: String in REGIONS:
		if not await _region_preview(region):
			await _preview_finish(false)
			return
	await _preview_finish(true)

func _input(path: String, expected: String = "") -> bool:
	if not FileAccess.file_exists(path):
		error = "Missing read-only preview input: " + path
		return false
	var actual: String = FileAccess.get_sha256(path).to_lower()
	if actual == "" or (expected != "" and actual != expected.to_lower()) or (inputs.has(path) and inputs[path] != actual):
		error = "Preview input SHA mismatch/change: " + path
		return false
	inputs[path] = actual
	return true

func _bound(path: String) -> bool:
	var catalog: Dictionary = active_manifest.get("asset_sha256", {})
	if not catalog.has(path):
		error = "Consumed V5 asset is not bound by the exact manifest: " + path
		return false
	return _input(path, String(catalog[path]))

func _dictionary(path: String, catalogued: bool = true) -> Dictionary:
	if not (_bound(path) if catalogued else _input(path)): return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary:
		error = "Preview expected an actual JSON dictionary: " + path
		return {}
	return value

func _load_mesh(path: String) -> Mesh:
	if not _bound_resource(path): return null
	var mesh: Mesh = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	if mesh == null: error = "Saved preview Mesh cannot be loaded: " + path
	return mesh

func _bound_resource(path: String) -> bool:
	if not _bound(path): return false
	if dependency_checked.has(path): return true
	dependency_checked[path] = true
	# Saved native materials may have external imported texture dependencies.
	# Bind their original paths too; don't report only the containing .res SHA.
	for dependency: String in ResourceLoader.get_dependencies(path):
		var target := ""
		for part: String in dependency.split("::"):
			if part.begins_with("res://"): target = part
		if target == "" or not _bound_resource(target):
			error = "Unbound/unresolved saved resource dependency: " + dependency
			return false
	return true

func _geometry(mesh: Mesh) -> Dictionary:
	var rows: Array[Dictionary] = []
	for index in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(index)
		var slots: Array[Dictionary] = []
		for slot in range(Mesh.ARRAY_MAX):
			slots.append({"slot":slot, "type":typeof(arrays[slot]), "sha256":_hash(var_to_bytes(arrays[slot]))})
		rows.append({"surface":index, "primitive":mesh.surface_get_primitive_type(index), "slots":slots})
	return {"surfaces":rows, "aabb_sha256":_hash(var_to_bytes(mesh.get_aabb())), "custom_aabb_sha256":_hash(var_to_bytes((mesh as ArrayMesh).custom_aabb)) if mesh is ArrayMesh else "not_arraymesh"}

func _hash(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK: return ""
	if not bytes.is_empty() and context.update(bytes) != OK: return ""
	return context.finish().hex_encode()

func _vec(values: Array) -> Vector3:
	return Vector3(values[0], values[1], values[2])

func _basis(columns: Array) -> Basis:
	return Basis(_vec(columns[0]), _vec(columns[1]), _vec(columns[2]))

func _samplers(material: ShaderMaterial) -> bool:
	for uniform: Dictionary in material.shader.get_shader_uniform_list():
		var name: String = uniform["name"]
		var texture: Variant = material.get_shader_parameter(name)
		if not texture is Texture2D: continue
		var channel: String = String({"stone_albedo":"stone", "original_stone":"stone", "rock_diff":"diff", "rock_normal":"nor_gl", "registered_normal":"nor_gl", "rock_arm":"arm", "registered_arm":"arm"}.get(name, ""))
		if channel == "":
			error = "Unexpected saved sampler in modified material: " + name
			return false
		var approved: Texture2D = finish.textures[channel]
		var pair: String = str(texture.get_instance_id()) + ":" + str(approved.get_instance_id())
		if sampler_pairs.has(pair): continue
		var a: Image = texture.get_image()
		var b: Image = approved.get_image()
		if a == null or b == null or a.get_size() != b.get_size() or a.get_format() != b.get_format() or a.get_mipmap_count() != b.get_mipmap_count() or a.get_data() != b.get_data():
			error = "Saved sampler differs from registered original complete mip bytes: " + name
			return false
		sampler_pairs[pair] = true
	return true

func _clone_native(original: ArrayMesh, kind: String, path: String) -> ArrayMesh:
	var result: ArrayMesh = original.duplicate(false) as ArrayMesh
	var before: Dictionary = _geometry(original)
	var modified: Array[int] = []
	var old_wood: ShaderMaterial = SURFACE.wood()
	for index in range(original.get_surface_count()):
		var old: ShaderMaterial = original.surface_get_material(index) as ShaderMaterial
		var next: ShaderMaterial = null
		if kind in ["wall_horizontal", "wall_vertical"]:
			if original.get_surface_count() != 18 or old == null or not _samplers(old):
				error = "Preview requires exact saved18-surface V5 wall and registered samplers."
				return null
			next = finish.revise_wall(old, kind, index)
		elif kind in ["loading_wharf", "quay_rail", "cargo"] and old != null and old.shader != null and old.shader.code == old_wood.shader.code:
			next = finish.revise_wood(old)
		else:
			continue
		if next == null:
			error = finish.error
			return null
		result.surface_set_material(index, next)
		modified.append(index)
	if modified.is_empty():
		error = "Preview expected but did not replace a material: " + kind
		return null
	var after: Dictionary = _geometry(result)
	if var_to_bytes(before) != var_to_bytes(after):
		error = "Material-only preview changed a geometry slot/primitive/AABB."
		return null
	var b0: Dictionary = _bounds(original, Basis.IDENTITY)
	var b1: Dictionary = _bounds(result, Basis.IDENTITY)
	if b0.is_empty() or var_to_bytes(b0) != var_to_bytes(b1):
		error = "Material-only preview changed actual complete used-index support/bounds."
		return null
	clone_rows.append({"path":path, "kind":kind, "replaced_surface_indices":modified, "all_slots_before":before, "all_slots_after":after, "actual_arrays_primitive_aabb_exact":true, "used_index_bounds_support_sha256":_hash(var_to_bytes(b0)), "scope":"Only surface material resources replaced; no Mesh save/export"})
	return result

func _body_image(mesh: ArrayMesh, record: Dictionary, original: Image, label: String) -> Image:
	var c: Dictionary = record["raw_camera"]
	var raw_size := Vector2i(c["raw_canvas_px"][0], c["raw_canvas_px"][1])
	var logical_size := Vector2i(c["logical_canvas_px"][0], c["logical_canvas_px"][1])
	if raw_size != Vector2i(1536,1536) or logical_size != Vector2i(768,768):
		error = "Preview refuses an unexpected sourcebody canvas."
		return null
	view = _viewport(raw_size, true)
	var world: Node3D = _world(view, true)
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.transform = Transform3D(_basis(record["draw_basis_columns"]), -_vec(record["support_m"]))
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(body)
	var camera := Camera3D.new()
	camera.projection = int(c["projection"])
	camera.size = float(c["orthographic_size_m"])
	camera.near = float(c["near"])
	camera.far = float(c["far"])
	world.add_child(camera)
	camera.transform = Transform3D(_basis(c["basis_columns"]), _vec(c["position_m"]))
	await _sync()
	var raw: Image = _read(view)
	await _sync()
	var repeat: Image = _read(view)
	if raw.get_data() != repeat.get_data():
		error = "New preview body RGBA repeat is not exact: " + label
		return null
	var logical: Image = _alpha_resize(raw, logical_size)
	var crop_data: Array = record["crop_rect_px"]
	var crop := Rect2i(crop_data[0],crop_data[1],crop_data[2],crop_data[3])
	var image: Image = logical.get_region(crop)
	var equal: bool = image.get_size() == original.get_size()
	var differences := 0
	if equal:
		var a: PackedByteArray = image.get_data()
		var b: PackedByteArray = original.get_data()
		for offset in range(3,a.size(),4):
			if a[offset] != b[offset]: differences += 1
		equal = differences == 0
	var measured: Rect2i = logical.get_used_rect()
	var measured_crop := Rect2i(measured.position-Vector2i(4,4), measured.size+Vector2i(8,8))
	var row: Dictionary = {"id":label, "old_size":[original.get_width(),original.get_height()], "new_size":[image.get_width(),image.get_height()], "saved_crop_px":crop_data, "measured_new_crop_px":[measured_crop.position.x,measured_crop.position.y,measured_crop.size.x,measured_crop.size.y], "actual_new_alpha_byte_differences":differences, "actual_alpha_exact":equal, "actual_crop_exact":measured_crop == crop, "independent_visual_review":"PENDING", "no_old_alpha_pasted":true}
	alpha_rows.append(row)
	if not _png(preview_out+active_region+"_"+label+"_body_raw.png",raw) or not _png(preview_out+active_region+"_"+label+"_body.png",image): return null
	view.queue_free()
	view = null
	await _sync()
	if not equal or measured_crop != crop:
		error = "New alpha/crop differs; preview refused, evidence retained: " + label
		return null
	return image

func _exact_v5_logical_size(value: Variant) -> bool:
	# JSON decodes writer integers as floats; check exact numeric values, not
	# Array Variant types. No truncation, string/bool coercion, or tolerance.
	if not value is Array or value.size() != 2: return false
	for index in range(2):
		if typeof(value[index]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value[index])) or float(value[index]) != [3072.0,2048.0][index]: return false
	return true

func _region_preview(region: String) -> bool:
	active_region = region
	clone_rows.clear()
	alpha_rows.clear()
	dependency_checked.clear()
	finish.replacements_evidence.clear()
	var prefix: String = INPUT_ROOT+region+"/"
	if not _input(prefix+"art_contract.json", MANIFEST_SHA[region]): return false
	active_manifest = _dictionary(prefix+"art_contract.json", false)
	if active_manifest.is_empty() or active_manifest.get("scene_id","") != region or not _exact_v5_logical_size(active_manifest.get("logical_size_px")):
		error = "Wrong exact V5 region/size manifest."
		return false
	var snapshot_sha: String = _hash(var_to_bytes(active_manifest))
	var camera_record: Dictionary = _dictionary(prefix+"capture_camera.json")
	if camera_record.is_empty(): return false
	var original_paving: ArrayMesh = _load_mesh(prefix+"paving_mesh.res") as ArrayMesh
	var support: Mesh = _load_mesh(prefix+"support_plane.res")
	if original_paving == null or support == null or not _bound_resource(prefix+"paving_material.res"): return false
	var old_paving: ShaderMaterial = ResourceLoader.load(prefix+"paving_material.res", "", ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
	if old_paving == null or not _samplers(old_paving): return false
	var new_paving: ShaderMaterial = finish.revise_paving(old_paving)
	if new_paving == null:
		error = finish.error
		return false
	var sprite_images: Dictionary = {}
	var native_meshes: Dictionary = {}
	var revised_meshes: Dictionary = {}
	var revised_images: Dictionary = {}
	for object: Dictionary in active_manifest["objects"]:
		var texture_path: String = object["texture"]
		if not _bound(texture_path): return false
		var image: Image = Image.load_from_file(texture_path)
		if image == null: return false
		image.convert(Image.FORMAT_RGBA8)
		sprite_images[object["id"]] = image
		var kind: String = object.get("prototype", "")
		if kind == "" or native_meshes.has(kind): continue
		var record: Dictionary = _dictionary(object["metadata_path"])
		if record.is_empty(): return false
		var path: String = record["native_mesh_path"]
		var mesh: ArrayMesh = _load_mesh(path) as ArrayMesh
		if mesh == null: return false
		native_meshes[kind] = mesh
		if kind not in ["wall_horizontal","wall_vertical","loading_wharf","quay_rail","cargo"]: continue
		var changed: ArrayMesh = _clone_native(mesh, kind, path)
		if changed == null: return false
		revised_meshes[kind] = changed
		var body: Image = await _body_image(changed, record, image, kind)
		if body == null: return false
		revised_images[kind] = body
	var sample: Rect2i = SAMPLE_RECTS[region]
	view = _viewport(sample.size*2, false)
	var world: Node3D = _world(view, false)
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = support
	floor_node.material_override = finish.shoulder()
	floor_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(floor_node)
	var paving_node := MeshInstance3D.new()
	paving_node.mesh = original_paving
	paving_node.material_override = old_paving
	paving_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(paving_node)
	if region == "ch4_s2_canal_docks":
		for entry: Array in [["canal_bed_mesh.res", SURFACE.plain(Color(.20,.215,.19))], ["quay_wall_mesh.res", SURFACE.plain(Color(.31,.325,.315))], ["water_plane.res", finish.canal_water()]]:
			var extra := MeshInstance3D.new()
			extra.mesh = _load_mesh(prefix+String(entry[0]))
			if extra.mesh == null: return false
			extra.material_override = entry[1]
			extra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if entry[0] == "water_plane.res": extra.position = SOURCE.point3(Vector2((2230.+3072.)*.5,1024),-.025)
			world.add_child(extra)
	var center := Vector2(sample.position)+Vector2(sample.size)*.5
	var camera: Camera3D = _camera(world, sample.size, SOURCE.point3(center))
	var nodes: Dictionary = {}
	var transforms: Array[Dictionary] = []
	for object: Dictionary in active_manifest["objects"]:
		var kind: String = object.get("prototype", "")
		if kind == "": continue
		var transform_data: Dictionary = object["native_transform"]
		var exact_transform := Transform3D(_basis(transform_data["basis_columns"]),_vec(transform_data["origin"]))
		var caster := MeshInstance3D.new()
		caster.mesh = native_meshes[kind]
		caster.transform = exact_transform
		caster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		world.add_child(caster)
		nodes[object["id"]] = caster
		transforms.append({"id":object["id"], "source_transform":transform_data, "actual_transform_sha256":_hash(var_to_bytes(caster.transform)), "expected_transform_sha256":_hash(var_to_bytes(exact_transform)), "actual_transform_exact":var_to_bytes(caster.transform) == var_to_bytes(exact_transform)})
	await _sync()
	var baseline: Image = await _ground_repeat("baseline")
	if baseline == null: return false
	paving_node.material_override = new_paving
	for object: Dictionary in active_manifest["objects"]:
		var kind: String = object.get("prototype", "")
		if revised_meshes.has(kind):
			var node: MeshInstance3D = nodes[object["id"]]
			var exact: Transform3D = node.transform
			node.mesh = revised_meshes[kind]
			if var_to_bytes(node.transform) != var_to_bytes(exact):
				error = "Preview material replacement changed a native transform."
				return false
	await _sync()
	var revised: Image = await _ground_repeat("revised")
	if revised == null: return false
	var ordered: Array = active_manifest["objects"].duplicate()
	ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(a.get("z_index",0)) < int(b.get("z_index",0)) if int(a.get("z_index",0)) != int(b.get("z_index",0)) else a["depth_foot_y"] < b["depth_foot_y"])
	for object: Dictionary in ordered:
		var old_image: Image = sprite_images[object["id"]]
		var kind: String = object.get("prototype", "")
		var next_image: Image = revised_images.get(kind,old_image)
		var size := Vector2i(int(round(object["render_size_px"][0])),int(round(object["render_size_px"][1])))
		if old_image.get_size() != size: old_image = _alpha_resize(old_image,size)
		if next_image.get_size() != size: next_image = _alpha_resize(next_image,size)
		var foot := Vector2(object["world_foot_px"][0],object["world_foot_px"][1])
		var uv := Vector2(object["foot_uv"][0],object["foot_uv"][1])
		var origin := Vector2i((foot-uv*Vector2(size)).round())-sample.position
		baseline.blend_rect(old_image,Rect2i(Vector2i.ZERO,size),origin)
		revised.blend_rect(next_image,Rect2i(Vector2i.ZERO,size),origin)
	if not _png(preview_out+region+"_baseline.png",baseline) or not _png(preview_out+region+"_preview.png",revised): return false
	if snapshot_sha != _hash(var_to_bytes(active_manifest)):
		error = "Preview mutated the actual loaded object/layout manifest."
		return false
	results.append({"scene_id":region, "scope":"PREVIEW_NOT_ADOPTED; native scene composite, NOT Field/HUD/Physics/gameplay or formal approval", "sample_source_rect":[sample.position.x,sample.position.y,sample.size.x,sample.size.y], "sample_logical_px":[1920,1080], "native_raw_px":[3840,2160], "camera":_camera_data(camera,view.size,sample.size), "source_capture_camera":camera_record, "original_manifest_variant_sha256":snapshot_sha, "actual_manifest_unchanged":true, "saved_paving_geometry":_geometry(original_paving), "actual_paving_same_resource":paving_node.mesh == original_paving, "saved_support_geometry":_geometry(support), "changed_native_meshes":clone_rows.duplicate(true), "new_body_alpha_crop_observations":alpha_rows.duplicate(true), "native_transforms":transforms, "material_replacements":finish.replacements_evidence.duplicate(true), "sampler_scope":"Actual registered source image/full-mip bytes checked; original objects retained in revised clones", "visual_review":"PENDING_INDEPENDENT_REVIEW", "field_executed":false, "visual_approved":false, "production_approved":false})
	view.queue_free()
	view = null
	await _sync()
	return true

func _ground_repeat(label: String) -> Image:
	var a: Image = _read(view)
	await _sync()
	var b: Image = _read(view)
	if a.get_data() != b.get_data():
		error = "Preview sample native RGBA repeat differs: " + label
		return null
	if not _png(preview_out+active_region+"_"+label+"_ground_raw.png",a): return null
	a.resize(1920,1080,Image.INTERPOLATE_LANCZOS)
	return a

func _png(path: String, image: Image) -> bool:
	if preview_out == "" or not path.begins_with(preview_out) or FileAccess.file_exists(path) or image.save_png(path) != OK:
		error = "Preview PNG writer refused overwrite/path/save: " + path
		return false
	var stored: Image = Image.load_from_file(path)
	if stored == null or stored.get_size() != image.get_size() or stored.get_format() != image.get_format() or stored.get_data() != image.get_data():
		error = "Preview PNG readback differs from actual captured pixels: " + path
		return false
	preview_outputs[path] = {"sha256":FileAccess.get_sha256(path), "rgba_sha256":_hash(image.get_data()), "size_px":[image.get_width(),image.get_height()], "actual_lossless_readback_exact":true}
	return true

func _preview_finish(passed: bool) -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("is_checkpoint_saves_suspended") or bridge.call("is_checkpoint_saves_suspended") != true:
		passed = false
		error = "Preview checkpoint suspension did not remain active through cleanup."
	var changes: Array[String] = []
	for path: String in inputs:
		if FileAccess.get_sha256(path).to_lower() != inputs[path]: changes.append(path)
	if not changes.is_empty():
		passed = false
		error = "Read-only preview input changed during run."
	if preview_out != "":
		var report: Dictionary = {"status":"PREVIEW_NOT_ADOPTED" if passed else "PREVIEW_FAILED_NOT_ADOPTED", "passed_render_checks":passed, "reason":error, "inputs_sha256":inputs, "input_changes":changes, "outputs":preview_outputs, "checkpoint_save_guard":checkpoint_guard, "regions":results, "partial_region":active_region, "partial_mesh_observations":clone_rows, "partial_alpha_observations":alpha_rows, "scope":"ISOLATED_TWO_REGION_MATERIAL_PREVIEW_ONLY; NO Field, save/load, Physics, candidate publication, release or adoption", "independent_alpha_crop_visual_review":"PENDING", "visual_approved":false, "production_approved":false}
		var path: String = preview_out+"preview_result.json"
		if FileAccess.file_exists(path) or not _json(path,report): passed = false
	if not passed: push_error(error)
	if view != null:
		view.queue_free()
		view = null
	if finish != null: finish.release()
	finish = null
	active_manifest.clear()
	sampler_pairs.clear()
	# Same tool-process cursor release as the frozen helper; never saves a game.
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	var cursor: Node = root.get_node_or_null("CursorManager")
	if cursor != null:
		for key: String in ["_arrow","_hand","_wait"]: cursor.set(key,null)
	for frame in range(16): await process_frame
	quit(0 if passed else 1)
