extends "res://scripts/world/v14_modular_overlap.gd"
## Reuse exact frame-alpha intersection; retain ordinary field 255 depth bands.
func add_actor(actor: Node2D) -> void:
	actor.set_meta("depth_band_max", 255)
	_register_depth(actor, String(actor.name), Vector2.ZERO, true)

func _refresh_depth_order() -> void:
	var dirty: Dictionary = {}
	for index in range(_depth_entries.size() - 1, -1, -1):
		var entry: Dictionary = _depth_entries[index]
		var old_band: int = entry.band
		if not is_instance_valid(entry.node):
			if old_band >= 0:
				_depth_bands[old_band].erase(entry)
				dirty[old_band] = true
			_depth_entries.remove_at(index)
			continue
		var node := entry.node as Node2D
		var foot_y: float = float(node.call("get_depth_sort_y")) if entry.actor else node.to_global(entry.foot_local).y
		var band := clampi(int(floor(foot_y / 8.0)), 0, 255)
		node.z_index = band
		if old_band == band and float(entry.foot_y) == foot_y: continue
		if old_band != band:
			if old_band >= 0:
				_depth_bands[old_band].erase(entry)
				dirty[old_band] = true
			if not _depth_bands.has(band): _depth_bands[band] = []
			_depth_bands[band].append(entry)
		entry.band = band
		entry.foot_y = foot_y
		dirty[band] = true
	for band in dirty:
		var members: Array = _depth_bands[band]
		members.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.foot_y) < float(b.foot_y) if float(a.foot_y) != float(b.foot_y) else int(a.ordinal) < int(b.ordinal))
		for entry: Dictionary in members:
			if is_instance_valid(entry.node): (entry.node as Node2D).get_parent().move_child(entry.node, -1)
	if not dirty.is_empty(): _order_revision += 1
