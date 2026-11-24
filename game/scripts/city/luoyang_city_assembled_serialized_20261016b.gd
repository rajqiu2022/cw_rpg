extends RefCounted
## Only three NEW authored trees need TRES decimal -> native Vector2 bridging.
## C/BASE/SERIAL and every other storage field retain their existing predicates.
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const A=preload("res://scripts/city/luoyang_city_assembled_retry2_20261016b.gd")
const TREES={
	"ch4_s3_luoyang_market":{
		"assembled_market_tree_group_a":{"source_id":"street_tree_0","old_foot_px":[300.0,550.0],"new_foot_px":[820.0,1750.0],"scale":0.85},
		"assembled_market_tree_group_b":{"source_id":"street_tree_1","old_foot_px":[2800.0,520.0],"new_foot_px":[2230.0,1740.0],"scale":0.85}},
	"ch4_s1_luoyang_yamen":{
		"assembled_east_garden_tree_b":{"source_id":"street_tree_1","old_foot_px":[2800.0,520.0],"new_foot_px":[2470.0,1610.0],"scale":0.9}}
}
static func _native_vector(a: Variant,b: Variant) -> bool:
	if not a is Array or not b is Array or a.size()!=2 or b.size()!=2: return false
	for axis: int in 2:
		if typeof(a[axis])!=TYPE_FLOAT or typeof(b[axis])!=TYPE_FLOAT or not is_finite(a[axis]) or not is_finite(b[axis]): return false
		var left:=PackedFloat32Array([a[axis]]); var right:=PackedFloat32Array([b[axis]])
		if not is_finite(left[0]) or not is_finite(right[0]) or left.to_byte_array()!=right.to_byte_array(): return false
	return true
static func _visual(a: Variant,b: Variant,id: StringName) -> bool:
	if not a is Array or not b is Array or a.size()!=b.size(): return false
	var allowed: Dictionary=TREES.get(String(id),{})
	for index: int in a.size():
		var left: Dictionary=a[index]; var right: Dictionary=b[index]
		var key:=String(left.get("id",""))
		if not allowed.has(key):
			if not C.equal_visual_serialized_value(left,right,["visual_objects",index]): return false
			continue
		if key!=right.get("id") or left.size()!=right.size() or not C._equal_value(left.get("assembled_transform_20261016b"),allowed[key]) or not C._equal_value(right.get("assembled_transform_20261016b"),allowed[key]): return false
		for field: Variant in left:
			if not right.has(field): return false
			if field in ["collision_size_px","physical_center_px"]:
				# C.object_solids and Field._spawn_scene_objects both convert these
				# exact two components through _vec() to native Vector2 before use.
				if not _native_vector(left[field],right[field]): return false
			elif not C.equal_visual_serialized_value(left[field],right[field],["visual_objects",index,field]): return false
	return true
static func equal(actual: SceneScript,expected: SceneScript) -> bool:
	if actual==null or expected==null or actual.scene_id!=expected.scene_id or not TREES.has(String(actual.scene_id)) or actual.map_layout==null or expected.map_layout==null or actual.get_meta(A.META,"")!=A.AUTHOR_SHA or expected.get_meta(A.META,"")!=A.AUTHOR_SHA: return false
	for pair: Array in [[actual,expected],[actual.map_layout,expected.map_layout]]:
		for property: Dictionary in pair[1].get_property_list():
			var key: String=property.name
			if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or key in ["script","map_layout","resource_path","resource_name","resource_local_to_scene"]: continue
			if key=="visual_objects":
				if not _visual(pair[0].get(key),pair[1].get(key),actual.scene_id): return false
			elif not C._equal_value(pair[0].get(key),pair[1].get(key)): return false
	return true
