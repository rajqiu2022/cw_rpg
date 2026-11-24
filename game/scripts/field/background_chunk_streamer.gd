class_name BackgroundChunkStreamer
extends Node2D
const WORLD_VISUAL_PATCH := preload("res://scripts/world/world_farmland_visual_patch_resolver_20261015.gd")

## Loads the first visible chunk set synchronously so scene transitions never
## reveal a blank map, then streams future chunks on Godot's resource loader.

var _definition: StreamedBackgroundSet = null
var _chunks: Array[Dictionary] = []
var _focus: Node2D = null
var _camera: Camera2D = null
var _viewport_size: Vector2 = Vector2(1920, 1080)
var _camera_zoom: float = 1.0
var _loaded: Dictionary = {}
var _pending: Dictionary = {}
var _wanted: Dictionary = {}
var _last_visible_rect := Rect2(-99999.0, -99999.0, 1.0, 1.0)


func configure(definition: StreamedBackgroundSet, prefer_desktop: bool) -> void:
	_definition = definition
	_chunks = WORLD_VISUAL_PATCH.effective_chunks(definition, prefer_desktop)
	z_index = -1000
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func bind_view(focus: Node2D, camera: Camera2D, viewport_size: Vector2, camera_zoom: float) -> void:
	_focus = focus
	_camera = camera
	_viewport_size = viewport_size
	_camera_zoom = maxf(0.01, camera_zoom)
	if OS.has_feature("web"):
		# Web/WeChat cannot depend on a worker loader. Pay the small tiled-map
		# cost once at scene entry so movement never synchronously loads a tile.
		_load_all_chunks_now()
		set_process(false)
	else:
		_refresh_visible(true)
		set_process(true)


func _load_all_chunks_now() -> void:
	_wanted.clear()
	for entry: Dictionary in _chunks:
		var path := String(entry.get("path", ""))
		if path.is_empty():
			continue
		_wanted[path] = entry
		_load_chunk_now(path, entry)


func loaded_chunk_count() -> int:
	return _loaded.size()


func pending_chunk_count() -> int:
	return _pending.size()


func _process(_delta: float) -> void:
	_poll_pending()
	_refresh_visible(false)


func _visible_world_rect() -> Rect2:
	var visible_size := _viewport_size / _camera_zoom
	var center := _focus.global_position if is_instance_valid(_focus) else Vector2(_definition.logical_size) * 0.5
	var world_size := Vector2(_definition.logical_size)
	var half_visible := visible_size * 0.5
	center.x = clampf(center.x, minf(half_visible.x, world_size.x * 0.5), maxf(half_visible.x, world_size.x - half_visible.x))
	center.y = clampf(center.y, minf(half_visible.y, world_size.y * 0.5), maxf(half_visible.y, world_size.y - half_visible.y))
	return Rect2(center - visible_size * 0.5, visible_size)


func _refresh_visible(force_sync: bool) -> void:
	if _definition == null or _chunks.is_empty() or not is_instance_valid(_focus):
		return
	var visible_rect := _visible_world_rect()
	if not force_sync and visible_rect.get_center().distance_squared_to(_last_visible_rect.get_center()) < 128.0 * 128.0:
		return
	_last_visible_rect = visible_rect
	var load_rect := visible_rect.grow(_definition.load_padding)
	var retain_rect := visible_rect.grow(maxf(_definition.load_padding, _definition.retain_padding))
	_wanted.clear()
	for entry: Dictionary in _chunks:
		var path := String(entry.get("path", ""))
		var logical_rect: Rect2 = entry.get("logical_rect", Rect2())
		if path.is_empty() or not logical_rect.intersects(load_rect, true):
			continue
		_wanted[path] = entry
		if _loaded.has(path) or _pending.has(path):
			continue
		if force_sync:
			_load_chunk_now(path, entry)
		else:
			_queue_chunk(path, entry)
	for loaded_path: Variant in _loaded.keys():
		var path := String(loaded_path)
		var entry: Dictionary = _entry_for_path(path)
		var logical_rect: Rect2 = entry.get("logical_rect", Rect2())
		if not logical_rect.intersects(retain_rect, true):
			var sprite: Sprite2D = _loaded[path]
			_loaded.erase(path)
			if is_instance_valid(sprite):
				sprite.queue_free()


func _queue_chunk(path: String, entry: Dictionary) -> void:
	if not ResourceLoader.exists(path):
		push_warning("[BackgroundChunkStreamer] missing chunk: %s" % path)
		return
	# Godot Web/WeChat has no dependable worker-thread file loader. The visible
	# neighborhood is already primed; a rare edge chunk can load synchronously.
	if OS.has_feature("web"):
		_load_chunk_now(path, entry)
		return
	var error := ResourceLoader.load_threaded_request(path, "Texture2D")
	if error == OK:
		_pending[path] = entry
	else:
		_load_chunk_now(path, entry)


func _poll_pending() -> void:
	for pending_path: Variant in _pending.keys():
		var path := String(pending_path)
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var entry: Dictionary = _pending[path]
			_pending.erase(path)
			if _wanted.has(path):
				_add_chunk_sprite(path, entry, ResourceLoader.load_threaded_get(path) as Texture2D)
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			var entry: Dictionary = _pending[path]
			_pending.erase(path)
			_load_chunk_now(path, entry)


func _load_chunk_now(path: String, entry: Dictionary) -> void:
	if not ResourceLoader.exists(path):
		push_warning("[BackgroundChunkStreamer] missing chunk: %s" % path)
		return
	_add_chunk_sprite(path, entry, load(path) as Texture2D)


func _add_chunk_sprite(path: String, entry: Dictionary, texture: Texture2D) -> void:
	if texture == null or _loaded.has(path):
		return
	var sprite := Sprite2D.new()
	sprite.name = "Chunk_%s" % path.get_file().get_basename()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.centered = false
	sprite.position = entry.get("draw_position", Vector2.ZERO)
	var draw_scale := float(entry.get("draw_scale", 1.0))
	sprite.scale = Vector2.ONE * draw_scale
	add_child(sprite)
	_loaded[path] = sprite


func _entry_for_path(path: String) -> Dictionary:
	for entry: Dictionary in _chunks:
		if String(entry.get("path", "")) == path:
			return entry
	return {}
