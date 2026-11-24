extends RefCounted
## NEW, pure author overlay only. No install, save, source approval or navigation.
const SCENE := "ch4_s1_luoyang_yamen"
const CLERK := "yamen_clerk"
const OLD_FOOT := Vector2(1260, 1500)
const NEW_FOOT := Vector2(1130, 1360)

static func _pair(value: Variant, expected: Vector2) -> bool:
	if not value is Array or value.size() != 2:
		return false
	for item in value:
		if not (item is int or item is float) or not is_finite(float(item)):
			return false
	return Vector2(float(value[0]), float(value[1])) == expected

static func apply_clerk_foot(parent: Dictionary) -> Dictionary:
	var districts: Variant = parent.get("districts")
	if not districts is Dictionary or not districts.get(SCENE) is Dictionary:
		return {}
	var district: Dictionary = districts[SCENE]
	var crowd: Variant = district.get("crowd")
	if not crowd is Array or crowd.size() != 6:
		return {}
	var index := -1
	for i in range(crowd.size()):
		if not crowd[i] is Dictionary:
			return {}
		if crowd[i].get("id") == CLERK:
			if index != -1 or not _pair(crowd[i].get("foot_px"), OLD_FOOT):
				return {}
			if crowd[i].get("name") != "书办" or crowd[i].get("family") != "merchant" or crowd[i].get("distance_px") != 0:
				return {}
			index = i
	if index == -1:
		return {}
	var child := parent.duplicate(true)
	child["districts"][SCENE]["crowd"][index]["foot_px"] = [1130, 1360]
	var inverse := child.duplicate(true)
	inverse["districts"][SCENE]["crowd"][index]["foot_px"] = crowd[index]["foot_px"].duplicate()
	if inverse != parent:
		return {}
	return child

static func inverse_clerk_foot(child: Dictionary, original_pair: Array) -> Dictionary:
	if not _pair(original_pair, OLD_FOOT):
		return {}
	var district: Variant = child.get("districts", {}).get(SCENE)
	if not district is Dictionary or not district.get("crowd") is Array:
		return {}
	var inverse := child.duplicate(true)
	var found := 0
	for row in inverse["districts"][SCENE]["crowd"]:
		if row.get("id") == CLERK:
			if not _pair(row.get("foot_px"), NEW_FOOT):
				return {}
			row["foot_px"] = original_pair.duplicate()
			found += 1
	return inverse if found == 1 else {}
