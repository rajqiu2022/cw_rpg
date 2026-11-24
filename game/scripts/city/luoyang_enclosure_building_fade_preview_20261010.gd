extends "res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd"
## Preview selection only: not wired into Field or any canonical scene.
## Mild building display fade; native feet/order and the inherited ghost stay intact.
## No Tween, callbacks, physics edits, Player alpha writes, or shared static cache.
const PREVIEW_BUILDINGS := {
	"ch4_s0_luoyang_gate": ["south_gate", "south_wall_388", "south_wall_708", "south_wall_1028", "south_wall_2044", "south_wall_2364", "south_wall_2684", "west_street_front", "east_street_front", "north_court_boundary", "notice_pavilion", "v13_gate_west_plot_wall_0", "v13_gate_west_plot_wall_1", "v13_gate_east_plot_wall_0", "v13_gate_east_plot_wall_1"],
	"ch4_s1_luoyang_yamen": ["magistrate_hall", "notice_pavilion", "south_court_gate", "v11_yamen_west_south_1680", "v11_yamen_west_south_1520", "v11_yamen_west_south_1360", "v11_yamen_west_north_940", "v11_yamen_west_north_780", "v11_yamen_east_south_1680", "v11_yamen_east_south_1520", "v11_yamen_east_south_1360", "v11_yamen_east_north_940", "v11_yamen_east_north_780"],
	"ch4_s2_canal_docks": ["north_canal_warehouse", "south_canal_front", "dock_notice"],
	"ch4_s3_luoyang_market": ["inn", "shop", "north_market_front", "southwest_market_front", "southeast_market_front", "v13_market_west_plot_wall", "v13_market_east_plot_wall"],
}
var _fade_scene := ""
var _fade_opacity := .55
var _fade_seconds := .18
var _fade_records: Array[Dictionary] = []
var _fade_player: WeakRef
var _fade_delta := 0.0
var _fade_last_ticks := 0
var _fade_status := "NOT_CONFIGURED"

func configure_preview(world: Node2D, scene_id: String, opacity: float = .55, seconds: float = .18) -> bool:
	release_preview()
	if not is_instance_valid(world) or not PREVIEW_BUILDINGS.has(scene_id) or not is_finite(opacity) or opacity <= 0.0 or opacity >= 1.0 or not is_finite(seconds) or seconds <= 0.0 or seconds > 1.0:
		_fade_status = "INVALID_CONFIGURATION"
		return false
	super.configure(world)
	_fade_scene = scene_id
	_fade_opacity = opacity
	_fade_seconds = seconds
	_fade_status = "READY_PREVIEW_ONLY"
	return true

func add_prop(sprite: Sprite2D, id: String, foot_y: float) -> void:
	if not is_instance_valid(_world) or not is_instance_valid(sprite) or not is_finite(foot_y): return
	for existing: Dictionary in _props:
		if is_instance_valid(existing.sprite) and existing.sprite == sprite: return
	super.add_prop(sprite, id, foot_y)
	if not PREVIEW_BUILDINGS.get(_fade_scene, []).has(id) or not _finite_color(sprite.self_modulate): return
	# Non-occluding water/ground is not registered in _props; explicit IDs alone
	# cannot turn such a Sprite into a fade target. No name-prefix/regex guessing.
	for prop: Dictionary in _props:
		if prop.sprite == sprite:
			_fade_records.append({"sprite":weakref(sprite),"id":id,"base_color":sprite.self_modulate,"factor":1.0,"target":1.0,"hit":false,"eligible":false})
			return

func refresh(player: Player, force: bool = false) -> void:
	var ticks: int = Time.get_ticks_usec()
	var delta: float = 0.0 if _fade_last_ticks == 0 else float(maxi(0, ticks - _fade_last_ticks)) / 1000000.0
	_fade_last_ticks = ticks
	refresh_preview(player, delta, force)

func refresh_preview(player: Player, delta: float, force: bool = false) -> bool:
	# This explicit finite clock is for NEW fixtures only, not a production flag.
	if _fade_scene.is_empty() or not is_finite(delta) or delta < 0.0:
		_clear_fade(player, "INVALID_PREVIEW_CLOCK_OR_CONFIGURATION")
		return false
	_fade_delta = delta
	if not _actor_ready(player):
		_clear_fade(player, "INVALID_PLAYER_IMAGE_OR_FRAME")
		return false
	_fade_player = weakref(player)
	# The inherited refresh calls our override once, giving one native snapshot.
	# Fade is applied there BEFORE the unchanged inherited mask samples display
	# alpha. Its original signature already includes the resulting self alpha.
	super.refresh(player, force)
	return _native_snapshot_valid and _fade_status == "READY_PREVIEW_ONLY"

func _refresh_depth_order() -> void:
	super._refresh_depth_order()
	var player: Player = _fade_player.get_ref() as Player if _fade_player != null else null
	if not _native_snapshot_valid or not _actor_ready(player) or not _native_snapshot.has(player.get_instance_id()):
		_clear_fade(player, "INVALID_DEPTH_SNAPSHOT_OR_PLAYER")
		return
	var actor: Sprite2D = player.sprite
	var actor_image: Image = _image(actor.texture)
	var frame: Rect2i = _frame_rect(actor, actor_image)
	var rect: Rect2 = actor.get_rect()
	var actor_snapshot: Dictionary = _native_snapshot[player.get_instance_id()]
	var actor_z: int = effective_z(actor)
	var bounds: Rect2 = _world_bounds(actor)
	var key: String = "%d:%s" % [actor.texture.get_instance_id(), str(frame)]
	if not _actor_pixels.has(key):
		var points := PackedVector2Array()
		for y in frame.size.y:
			for x in frame.size.x:
				if actor_image.get_pixel(frame.position.x + x, frame.position.y + y).a > 0:
					points.append(Vector2(x, y))
		_actor_pixels[key] = points
	# No hit cache: sample the CURRENT frame/base alpha every refresh. Animation
	# still advances while standing. Own prior display fade cannot feed back.
	for index in range(_fade_records.size() - 1, -1, -1):
		var record: Dictionary = _fade_records[index]
		var node: Sprite2D = record.sprite.get_ref() as Sprite2D
		if not is_instance_valid(node):
			_fade_records.remove_at(index)
			continue
		record.hit = false
		record.eligible = false
		var snap: Dictionary = _native_snapshot.get(node.get_instance_id(), {})
		# Front/equal native feet restore immediately, even during fade-out.
		if snap.is_empty() or not depth_key_before(actor_snapshot.key, snap.key) or int(snap.effective_z) < actor_z or (int(snap.effective_z) == actor_z and int(snap.sibling_index) <= int(actor_snapshot.sibling_index)):
			_restore_record(record, node)
			continue
		var image: Image = _image(node.texture)
		if not _sprite_ready(node, image) or not _finite_color(node.modulate) or node.modulate.a <= 0.0 or float(record.base_color.a) <= 0.0:
			_restore_record(record, node)
			continue
		record.eligible = true
		if bounds.intersects(_world_bounds(node)):
			for point: Vector2 in _actor_pixels[key]:
				var uv: Vector2 = (point + Vector2(.5, .5)) / Vector2(frame.size)
				if actor.flip_h: uv.x = 1.0 - uv.x
				if actor.flip_v: uv.y = 1.0 - uv.y
				var world_point: Vector2 = actor.to_global(rect.position + uv * rect.size)
				if _author_alpha_at(node, image, world_point, record.base_color.a) > 0.0:
					record.hit = true
					break
		record.target = _fade_opacity if record.hit else 1.0
		var step: float = (minf(_fade_delta, _fade_seconds) / _fade_seconds) * (1.0 - _fade_opacity)
		record.factor = move_toward(float(record.factor), float(record.target), step)
		var display: Color = record.base_color
		display.a *= float(record.factor)
		node.self_modulate = display
	_fade_status = "READY_PREVIEW_ONLY"

func _author_alpha_at(sprite: Sprite2D, image: Image, world_point: Vector2, base_alpha: float) -> float:
	# Same atlas/flip/LINEAR source semantics as inherited _alpha_at; only replace
	# live self_modulate.a with the immutable authored alpha captured at add_prop.
	var rect: Rect2 = sprite.get_rect()
	var uv: Vector2 = (sprite.to_local(world_point) - rect.position) / rect.size
	if not uv.is_finite() or uv.x < 0.0 or uv.y < 0.0 or uv.x >= 1.0 or uv.y >= 1.0: return 0.0
	if sprite.flip_h: uv.x = 1.0 - uv.x
	if sprite.flip_v: uv.y = 1.0 - uv.y
	var frame: Rect2i = _frame_rect(sprite, image)
	var alpha: float
	if sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR:
		alpha = _linear_alpha(image, Vector2(frame.position) + uv * Vector2(frame.size) - Vector2(.5, .5))
	else:
		var pixel: Vector2i = frame.position + Vector2i(clampi(int(uv.x * frame.size.x), 0, frame.size.x - 1), clampi(int(uv.y * frame.size.y), 0, frame.size.y - 1))
		alpha = image.get_pixelv(pixel).a
	return alpha * sprite.modulate.a * base_alpha if is_finite(alpha) else 0.0

func _actor_ready(player: Player) -> bool:
	if not is_instance_valid(player) or player.is_queued_for_deletion() or not player.is_inside_tree() or not is_instance_valid(player.sprite): return false
	var actor: Sprite2D = player.sprite
	return _sprite_ready(actor, _image(actor.texture)) and _finite_color(actor.modulate) and _finite_color(actor.self_modulate) and actor.modulate.a > 0.0 and actor.self_modulate.a > 0.0

func _sprite_ready(sprite: Sprite2D, image: Image) -> bool:
	if not is_instance_valid(sprite) or not sprite.is_inside_tree() or sprite.is_queued_for_deletion() or not sprite.is_visible_in_tree() or sprite.texture == null or image == null or image.is_compressed(): return false
	if sprite.hframes <= 0 or sprite.vframes <= 0 or sprite.frame < 0 or sprite.frame >= sprite.hframes * sprite.vframes: return false
	var transform: Transform2D = sprite.global_transform
	if not transform.x.is_finite() or not transform.y.is_finite() or not transform.origin.is_finite() or not is_finite(transform.determinant()) or transform.determinant() == 0.0: return false
	if sprite.region_enabled:
		var region: Rect2 = sprite.region_rect
		if not region.position.is_finite() or not region.size.is_finite() or region.position.x < 0.0 or region.position.y < 0.0 or region.size.x <= 0.0 or region.size.y <= 0.0 or region.end.x > image.get_width() or region.end.y > image.get_height(): return false
	var rect: Rect2 = sprite.get_rect()
	if not rect.position.is_finite() or not rect.size.is_finite() or rect.size.x <= 0.0 or rect.size.y <= 0.0: return false
	var frame: Rect2i = _frame_rect(sprite, image)
	return frame.size.x > 0 and frame.size.y > 0

static func _finite_color(color: Color) -> bool:
	return is_finite(color.r) and is_finite(color.g) and is_finite(color.b) and is_finite(color.a) and color.a >= 0.0 and color.a <= 1.0

func _restore_record(record: Dictionary, node: Sprite2D) -> void:
	node.self_modulate = record.base_color
	record.factor = 1.0
	record.target = 1.0
	record.hit = false
	record.eligible = false

func _clear_fade(player: Player, reason: String) -> void:
	for record: Dictionary in _fade_records:
		var node: Sprite2D = record.sprite.get_ref() as Sprite2D
		if is_instance_valid(node): _restore_record(record, node)
	_signature.clear()
	_debug = {"active":false,"pixels":0,"prop_hits":{},"candidate_count":0,"fade_preview_invalid":reason}
	if _mask != null: _mask.fill(Color(0, 0, 0, 0))
	if _texture != null and _mask != null: _texture.update(_mask)
	var previous_player: Player = _fade_player.get_ref() as Player if _fade_player != null else null
	if is_instance_valid(previous_player) and previous_player != player: previous_player.set_building_overlap(false, .46, true)
	if is_instance_valid(player): player.set_building_overlap(false, .46, true)
	_fade_player = null
	_fade_delta = 0.0
	_fade_status = reason

func get_fade_preview_state() -> Dictionary:
	var records: Array[Dictionary] = []
	for record: Dictionary in _fade_records:
		var node: Sprite2D = record.sprite.get_ref() as Sprite2D
		if is_instance_valid(node): records.append({"id":record.id,"base_color":record.base_color,"display_color":node.self_modulate,"factor":record.factor,"target":record.target,"hit":record.hit,"eligible":record.eligible})
	return {"preview_only":true,"production_hooked":false,"scene_id":_fade_scene,"status":_fade_status,"opacity":_fade_opacity,"seconds":_fade_seconds,"delta":_fade_delta,"building_count":records.size(),"buildings":records}

func release_preview() -> void:
	var player: Player = _fade_player.get_ref() as Player if _fade_player != null else null
	_clear_fade(player, "RELEASED")
	_fade_records.clear()
	_fade_player = null
	_fade_scene = ""
	_fade_last_ticks = 0
	_props.clear()
	_depth_entries.clear()
	_depth_bands.clear()
	_native_snapshot.clear()
	_native_snapshot_valid = false
	_images.clear()
	_actor_pixels.clear()
	_signature.clear()
	_mask = null
	_texture = null
	_world = null
	_depth_ordinal = 0
	_order_revision = 0
