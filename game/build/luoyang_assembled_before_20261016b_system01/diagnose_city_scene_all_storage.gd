extends "res://build/luoyang_assembled_before_20261016b_system01/diagnose_city_scene_storage.gd"
## Collect ALL predicate-rejected storage leaves in one bounded pure replay.
var _all_differences: Array=[]
func _collect(a: Variant,b: Variant,p: Array,visual: bool,entry: Dictionary={}) -> void:
	if visual and C.equal_visual_serialized_value(a,b,p): return
	if not visual and C._equal_value(a,b): return
	if typeof(a)==typeof(b):
		if a is Dictionary and a.size()==b.size():
			for k: Variant in a:
				if not b.has(k): _all_differences.append({"path":p+[k],"missing_right":true}); continue
				_collect(a[k],b[k],p+[k],visual,entry)
			return
		if a is Array and a.size()==b.size():
			for i: int in a.size():
				var context: Dictionary=a[i] if p==["visual_objects"] and a[i] is Dictionary else entry
				_collect(a[i],b[i],p+[i],visual,context)
			return
	var row:=_diff(a,b,p)
	row["object_id"]=entry.get("id",""); row["transform_source"]=entry.get("assembled_transform_20261016b",{})
	if typeof(a)==TYPE_FLOAT and typeof(b)==TYPE_FLOAT:
		row["left_float32_bits"]=PackedFloat32Array([a]).to_byte_array().hex_encode()
		row["right_float32_bits"]=PackedFloat32Array([b]).to_byte_array().hex_encode()
		row["native_float32_exact"]=is_finite(a) and is_finite(b) and PackedFloat32Array([a]).to_byte_array()==PackedFloat32Array([b]).to_byte_array()
	_all_differences.append(row)
func _storage_diff(a: SceneScript,b: SceneScript) -> Dictionary:
	_all_differences.clear()
	for pair: Array in [[a,b],[a.map_layout,b.map_layout]]:
		for property: Dictionary in pair[1].get_property_list():
			var key: String=property.name
			if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or key in ["script","map_layout","resource_path","resource_name","resource_local_to_scene"]: continue
			_collect(pair[0].get(key),pair[1].get(key),[key],key=="visual_objects")
	return {"difference_count":_all_differences.size(),"all_differences":_all_differences.duplicate(true),"adapter_not_implemented":true}
