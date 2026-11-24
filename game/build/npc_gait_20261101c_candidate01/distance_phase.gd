extends RefCounted
## Pure distance mapping. The clock is never a source of animation phase.
static func table_valid(fractions: Array, frames: int) -> bool:
	if frames < 2 or fractions.size() != frames or float(fractions[0]) != 0.0: return false
	var previous: float = -1.0
	for raw: Variant in fractions:
		if typeof(raw) not in [TYPE_INT, TYPE_FLOAT]: return false
		var value: float = float(raw)
		if not is_finite(value) or value <= previous or value < 0.0 or value >= 1.0: return false
		previous = value
	return true

static func frame_for_distance(distance: float, cycle: float, fractions: Array) -> int:
	if not is_finite(distance) or not is_finite(cycle) or cycle <= 0.0 or fractions.is_empty(): return 0
	var fraction: float = fposmod(distance, cycle) / cycle
	var frame: int = 0
	for index: int in range(1, fractions.size()):
		if fraction < float(fractions[index]): break
		frame = index
	return frame
