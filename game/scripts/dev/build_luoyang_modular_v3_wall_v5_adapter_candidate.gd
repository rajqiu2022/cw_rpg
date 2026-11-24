extends "res://scripts/dev/build_luoyang_modular_v3_wall_street_adapter_proposal.gd"

## Independent V5 upper-outline candidate. No exporter or adoption here.
const V5_ZONE := preload("res://scripts/dev/luoyang_modular_v3_zone_finish_candidate.gd")
const V5_GEOMETRY_ID := "PROJECT_CITY_SAME_FOOT_VERTICAL_BATTERED_SHOULDER_ZONE_FINISH_V5_CANDIDATE"
const V5_EXTRA_PINS := {
	"res://scripts/dev/build_luoyang_modular_v3_wall_street_adapter_proposal.gd": "531bfcee9eababe944fd366904355fab57a74b47104eaba2598c6224f3d69f2c",
	"res://scripts/dev/luoyang_modular_v3_wall_street_surface_proposal.gd": "7ccbb9f4a27234de3da4d41076e5374d7702d276a01c13e968c5790f537153eb",
	"res://scripts/dev/luoyang_modular_v3_zone_finish_candidate.gd": "26299495f76c3236d622f899efedf6fe27605b8e6783ea9c345f61030820b5be"
}

func prepare(snapshot: Dictionary) -> bool:
	error = ""
	evidence.clear()
	wall_recipe_records.clear()
	for pins: Dictionary in [PINS, V5_EXTRA_PINS]:
		for path: String in pins:
			if FileAccess.get_sha256(path).to_lower() != pins[path]:
				error = "V5 refuses changed frozen dependency: " + path
				return false
	if detail != null: detail.release()
	detail = V5_ZONE.new()
	if not detail.configure(snapshot) or not detail.load_sources():
		error = detail.error
		return false
	frozen_snapshot = snapshot.duplicate(true)
	return true

func build_wall(original: ArrayMesh, kind: String, profile: String) -> ArrayMesh:
	var parent_mesh: ArrayMesh = super.build_wall(original, kind, profile)
	if parent_mesh == null: return null
	if parent_mesh.get_surface_count() != 18:
		error = "V5 requires actual current18-surface wall, not a guessed split."
		return null
	var parent_recipe: Dictionary = wall_recipe_records[kind].duplicate(true)
	if kind == "wall_horizontal":
		# Actual parent arrays returned unchanged; only installed Zone materials.
		parent_recipe["v5_revision"] = {"identity": V5_GEOMETRY_ID, "horizontal_geometry_changed": false, "vertical_geometry_changed": false, "source_only_not_validated": true}
		wall_recipe_records[kind] = parent_recipe
		return parent_mesh
	if kind != "wall_vertical":
		error = "V5 outline change is limited to the exact vertical-wall kind."
		return null
	var result := ArrayMesh.new()
	var changes: Array[Dictionary] = []
	for index in range(18):
		var arrays: Array = parent_mesh.surface_get_arrays(index)
		var before: Array = arrays.duplicate(true)
		if index in [14, 16]:
			if not _v5_relocate_upper(arrays, index): return null
		result.add_surface_from_arrays(parent_mesh.surface_get_primitive_type(index), arrays)
		result.surface_set_material(index, parent_mesh.surface_get_material(index))
		var actual: Array = result.surface_get_arrays(index)
		var slots: Array[Dictionary] = []
		for slot in range(Mesh.ARRAY_MAX):
			var same: bool = var_to_bytes(before[slot]) == var_to_bytes(actual[slot])
			if not same and (index not in [14,16] or slot not in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT]):
				error = "V5 changed forbidden support/UV/index/colour/surface slot."
				return null
			slots.append({"slot": slot, "parent_sha256": _hash(var_to_bytes(before[slot])), "actual_sha256": _hash(var_to_bytes(actual[slot])), "byte_exact": same})
		changes.append({"surface_index": index, "same_primitive": parent_mesh.surface_get_primitive_type(index) == result.surface_get_primitive_type(index), "parent_vertex_count": before[Mesh.ARRAY_VERTEX].size(), "actual_vertex_count": actual[Mesh.ARRAY_VERTEX].size(), "slots": slots})
	parent_recipe["algorithm_identity"] = V5_GEOMETRY_ID
	parent_recipe["v5_revision"] = {
		"identity": V5_GEOMETRY_ID, "not_material_only": true,
		"horizontal_geometry_changed": false, "vertical_geometry_changed": true,
		"parent_adapter": V5_EXTRA_PINS, "parent_upper_recipe_retained_as_input": true,
		"modified_surface_indices": [14,16], "retained_support_surface_indices": RETAINED_OLD,
		"upper_brick_shoulder": {"original_half_thickness_m": 26./64./2., "maximum_outward_each_side_m": .12, "start_y_m": .90, "peak_y_m": 1.38, "end_y_m": 1.665, "formula": "x += sign(x)*.12*smoothstep(.90,1.38,y)*(1-smoothstep(1.38,1.665,y)); y/z unchanged; existing per-brick faces become genuine sloped shoulder"},
		"curved_tile_eave": {"x_scale": 1.10, "y_z_unchanged": true, "peak_height_unchanged": true},
		"normal_tangent_recipe": "Existing clockwise INDEX triangles; -cross area-weighted vertex NORMAL then original TANGENT projected orthogonal to actual NORMAL; original tangent.w retained; no culling fallback",
		"actual_all_surface_slot_comparisons": changes,
		"scope": "NEW upper vertices/normals/tangents/alpha/cast; not a texture trick. Same count/INDEX/UV, original14 retained arrays, worldfoot/collision/source layout/nav. Complete used-index support/count/minY remains an actual capture gate, not assumed here.",
		"source_only_not_validated": true, "visual_approved": false, "production_approved": false
	}
	wall_recipe_records[kind] = parent_recipe
	return result

func _v5_relocate_upper(arrays: Array, surface_index: int) -> bool:
	if not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array or not arrays[Mesh.ARRAY_NORMAL] is PackedVector3Array:
		error = "V5 requires original native vertices/normals."
		return false
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices := PackedInt32Array()
	if arrays[Mesh.ARRAY_INDEX] == null:
		# Parent curved tiles are nonindexed SurfaceTool triangles. Temporary
		# identity indices only compute normals; stored INDEX remains null.
		for i in range(vertices.size()): indices.append(i)
	elif arrays[Mesh.ARRAY_INDEX] is PackedInt32Array:
		indices = arrays[Mesh.ARRAY_INDEX]
	else:
		error = "V5 refuses an unknown stored INDEX type."
		return false
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	if indices.is_empty() or indices.size()%3 != 0:
		error = "V5 refuses absent/nontriangle INDEX."
		return false
	for i in range(vertices.size()):
		var p: Vector3 = vertices[i]
		if not p.is_finite() or p.y <= .246:
			error = "V5 upper edit reached retained ground/support height."
			return false
		if surface_index == 14:
			p.x += signf(p.x)*.12*smoothstep(.90,1.38,p.y)*(1.-smoothstep(1.38,1.665,p.y))
		else:
			p.x *= 1.10
		vertices[i] = p
	for i in range(0,indices.size(),3):
		var a: int = indices[i]
		var b: int = indices[i+1]
		var c: int = indices[i+2]
		if mini(a,mini(b,c)) < 0 or maxi(a,maxi(b,c)) >= vertices.size():
			error = "V5 original INDEX outside actual vertex domain."
			return false
		var n: Vector3 = -(vertices[b]-vertices[a]).cross(vertices[c]-vertices[a])
		if not n.is_finite() or n.length_squared() <= .000000000001:
			error = "V5 relocated upper triangle is nonfinite/degenerate."
			return false
		normals[a] += n
		normals[b] += n
		normals[c] += n
	for i in range(normals.size()):
		if not normals[i].is_finite() or normals[i].length_squared() <= .000000000001:
			error = "V5 upper vertex has no valid actual normal."
			return false
		normals[i] = normals[i].normalized()
	if arrays[Mesh.ARRAY_TANGENT] != null:
		var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
		if tangents.size() != vertices.size()*4:
			error = "V5 original tangent domain is inconsistent."
			return false
		for i in range(vertices.size()):
			var tangent := Vector3(tangents[i*4],tangents[i*4+1],tangents[i*4+2])
			tangent -= normals[i]*tangent.dot(normals[i])
			if not tangent.is_finite() or tangent.length_squared() <= .000000000001:
				error = "V5 cannot preserve orthogonal actual tangent."
				return false
			tangent = tangent.normalized()
			tangents[i*4] = tangent.x
			tangents[i*4+1] = tangent.y
			tangents[i*4+2] = tangent.z
		arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	return true
