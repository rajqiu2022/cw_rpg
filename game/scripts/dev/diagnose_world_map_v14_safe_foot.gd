extends SceneTree
## System-owner read-only optimization equivalence probe; no Field/GPU/save.
const CONTRACT = preload("res://scripts/world/world_map_v14_contract.gd")
var _scene: SceneScript
var _mask: Image
var _rects: Array[Rect2] = []
var _checks := 0
var _mismatches := 0

func _initialize() -> void:
	call_deferred("_run")

func _baseline(point: Vector2) -> bool:
	if not point.is_finite(): return false
	for i in range(17):
		var p := point if i == 16 else point + Vector2(cos(TAU * i / 16.0) * 10, sin(TAU * i / 16.0) * 6) / CONTRACT.SIZE
		if p.x < 0 or p.y < 0 or p.x >= 1 or p.y >= 1: return false
		var sample := _mask.get_pixel(int(round(p.x * (CONTRACT.SIZE.x - 1))), int(round(p.y * (CONTRACT.SIZE.y - 1))))
		if sample.a < .5 or maxf(sample.r, maxf(sample.g, sample.b)) < .5: return false
		for rect: Rect2 in _rects:
			if rect.has_point(p): return false
	return true

func _compare(point: Vector2) -> void:
	_checks += 1
	if CONTRACT.safe_foot(_scene, point) != _baseline(point):
		_mismatches += 1
		push_error("safe_foot optimization changed result at %s" % point)

func _run() -> void:
	_scene = load(CONTRACT.CANDIDATE_PATH) as SceneScript
	if not CONTRACT.is_v14(_scene): quit(1); return
	_mask = (load(_scene.map_layout.walkable_mask_path) as Texture2D).get_image()
	if _mask.is_compressed(): _mask.decompress()
	for d: Dictionary in _scene.map_layout.visual_objects:
		if d.has("collision_size"):
			var center: Vector2 = d.get("pos", Vector2.ZERO) + d.get("collision_offset", Vector2.ZERO)
			var extent: Vector2 = d["collision_size"]
			_rects.append(Rect2(center - extent * .5, extent).grow(.004))
	for d: Dictionary in _scene.map_layout.blockers:
		var extent: Vector2 = d.get("size", Vector2.ZERO)
		_rects.append(Rect2(d.get("pos", Vector2.ZERO) - extent * .5, extent).grow(maxf(0, float(d.get("walkability_margin", .014)))))
	for y in range(-8, 3081, 32):
		for x in range(-8, 4617, 32): _compare(Vector2(x, y) / CONTRACT.SIZE)
	for rect: Rect2 in _rects:
		for point: Vector2 in [rect.position, rect.end, rect.get_center(), Vector2(rect.position.x, rect.get_center().y), Vector2(rect.end.x, rect.get_center().y), Vector2(rect.get_center().x, rect.position.y), Vector2(rect.get_center().x, rect.end.y)]:
			for i in range(17):
				var offset := Vector2.ZERO if i == 16 else Vector2(cos(TAU * i / 16.0) * 10, sin(TAU * i / 16.0) * 6) / CONTRACT.SIZE
				for delta: Vector2 in [Vector2.ZERO, Vector2(.000001, 0), Vector2(-.000001, 0), Vector2(0, .000001), Vector2(0, -.000001)]: _compare(point - offset + delta)
	print("WORLD_V14_SAFE_FOOT_EQUIVALENCE checks=%d mismatches=%d blockers=%d; no Field/GPU/save tested" % [_checks, _mismatches, _rects.size()])
	quit(0 if _mismatches == 0 else 1)
