extends SceneTree

const MESH_PATH := "res://art/maps/world_map_v15_complete_v5/terrain_mesh.res"
const MESH_SHA := "2eb9ad81081768f938798bf4879df705505783d2aeb9b328927289f7b51d2a9a"

func _initialize() -> void:
	call_deferred("_run")

func _bytes(value: Variant) -> PackedByteArray:
	if value == null: return PackedByteArray()
	if value is PackedByteArray: return value
	return value.to_byte_array()

func _digest(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func _comparison(before: Array, after: Array) -> Array:
	var rows: Array = []
	for slot in Mesh.ARRAY_MAX:
		var a := _bytes(before[slot])
		var b := _bytes(after[slot])
		var mismatches: Array = []
		if a != b:
			for index in mini(a.size(),b.size()):
				if a[index] != b[index]:
					mismatches.append({"offset":index,"before":a[index],"after":b[index]})
					if mismatches.size() == 8: break
		rows.append({"slot":slot,"before_type":typeof(before[slot]),"after_type":typeof(after[slot]),"before_bytes":a.size(),"after_bytes":b.size(),"before_sha256":_digest(a),"after_sha256":_digest(b),"exact":typeof(before[slot])==typeof(after[slot]) and a==b,"first_byte_differences":mismatches})
	return rows

func _run() -> void:
	if FileAccess.get_sha256(MESH_PATH).to_lower() != MESH_SHA:
		push_error("Frozen baseline mesh SHA changed")
		quit(1)
		return
	var baseline := ResourceLoader.load(MESH_PATH,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if baseline == null or baseline.get_surface_count() != 1:
		quit(1)
		return
	var arrays: Array = baseline.surface_get_arrays(0)
	var clone := ArrayMesh.new()
	clone.add_surface_from_arrays(baseline.surface_get_primitive_type(0),arrays.duplicate(true))
	print(JSON.stringify({"scope":"READONLY_NATIVE_BASELINE_ROUNDTRIP_DIAGNOSTIC_NOT_GEOMETRY_APPROVAL","baseline_path":MESH_PATH,"baseline_sha256":MESH_SHA,"baseline_format":baseline.surface_get_format(0),"clone_format":clone.surface_get_format(0),"slots":_comparison(arrays,clone.surface_get_arrays(0))}))
	for method: Dictionary in ClassDB.class_get_method_list("ArrayMesh"):
		if method.name == "add_surface_from_arrays": print(JSON.stringify({"method":method}))
	clone = null
	baseline = null
	quit(0)
