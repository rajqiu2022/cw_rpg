extends RefCounted
## Caller-domain adapter only. Original JSON and frozen material never change.
static func snapshot(record: Dictionary) -> Dictionary:
	var size: Variant = record.get("logical_size_px")
	if not size is Array or size.size() != 2: return {"error":"Exact two original logical dimensions required"}
	for index: int in 2:
		if typeof(size[index]) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(size[index])) or float(size[index]) != (3072. if index == 0 else 2048.): return {"error":"Exact finite original3072x2048 dimensions required; no coercion"}
	var value: Dictionary = record.duplicate(true)
	value.logical_size_px = [3072,2048]
	return {"value":value}
static func stored(value: Variant) -> Variant:
	# Same original Godot JSON writer/read domain, never an epsilon or a
	# reduction to selected camera fields. Unknown fields remain in comparison.
	return JSON.parse_string(JSON.stringify(value,"\t",false))
