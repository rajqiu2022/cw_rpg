extends SceneTree

var _failed := 0


func _init() -> void:
	var scene := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	_check(scene != null, "world map scene loads")
	if scene != null:
		_check(scene.streamed_background != null, "world map declares streamed background set")
		if scene.streamed_background != null:
			_validate_set(scene.streamed_background)
			_validate_runtime_streamer(scene.streamed_background)
	var controller_text := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check("BackgroundChunkStreamer.new()" in controller_text, "walkable controller constructs chunk streamer")
	_check("not uses_streamed_background" in controller_text, "streamed scenes skip eager full-image load")
	if _failed == 0:
		print("[PASS] streamed background platform contract")
	quit(_failed)


func _validate_set(definition: StreamedBackgroundSet) -> void:
	_check(definition.logical_size == Vector2i(2304, 1536), "streamed map preserves v8 logical coordinates")
	_check(definition.mobile_chunks.size() == 15, "mobile map has 15 chunks")
	_check(definition.desktop_chunks.size() == 15, "desktop map has 15 chunks")
	_validate_variant(definition.mobile_chunks, 1.0, "mobile")
	_validate_variant(definition.desktop_chunks, 0.5, "desktop")


func _validate_variant(chunks: Array[Dictionary], expected_scale: float, label: String) -> void:
	var covered_area := 0.0
	for entry: Dictionary in chunks:
		var path := String(entry.get("path", ""))
		var rect: Rect2 = entry.get("logical_rect", Rect2())
		covered_area += rect.get_area()
		_check(ResourceLoader.exists(path), "%s chunk exists: %s" % [label, path.get_file()])
		_check(is_equal_approx(float(entry.get("draw_scale", 0.0)), expected_scale), "%s chunk draw scale is correct" % label)
	_check(is_equal_approx(covered_area, 2304.0 * 1536.0), "%s chunk cores cover the logical map once" % label)


func _validate_runtime_streamer(definition: StreamedBackgroundSet) -> void:
	var focus := Node2D.new()
	root.add_child(focus)
	focus.position = Vector2(265.0, 860.0)
	var streamer := BackgroundChunkStreamer.new()
	root.add_child(streamer)
	streamer.configure(definition, true)
	streamer.bind_view(focus, null, Vector2(1920, 1080), 1.0)
	_check(streamer.loaded_chunk_count() > 0, "first visible PC chunks load before gameplay is revealed")
	_check(streamer.loaded_chunk_count() < definition.desktop_chunks.size(), "off-screen PC chunks remain unloaded")
	streamer.free()
	focus.free()


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed += 1
	push_error("[FAIL] %s" % message)
