extends RefCounted
## Runtime reads the genuine source resource only. Projection/publication code
## and old owner collectors are deliberately not preloaded through this adapter.
static func source_context(terminal: Dictionary) -> Dictionary:
	var path: String = String(terminal.get("source_scene_path", ""))
	if not path.begins_with("res://") or terminal.get("sources", {}).get(path) != terminal.get("source_scene_sha256", "") or FileAccess.get_sha256(path) != terminal.get("source_scene_sha256", ""): return {"ok": false, "error": "REGION_SOURCE_SCENE_PIN"}
	var source: SceneScript = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if source == null or String(source.scene_id) != terminal.get("logical_id") or source.map_layout == null: return {"ok": false, "error": "REGION_SOURCE_SCENE_IDENTITY"}
	var layout_path: String = String(terminal.get("source_layout_path", ""))
	if not layout_path.is_empty():
		if terminal.sources.get(layout_path) != terminal.get("source_layout_sha256", "") or FileAccess.get_sha256(layout_path) != terminal.get("source_layout_sha256", ""): return {"ok": false, "error": "REGION_SOURCE_PAIRED_LAYOUT_PIN"}
		var layout: WalkableMapLayout = ResourceLoader.load(layout_path, "", ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
		if layout == null: return {"ok": false, "error": "REGION_SOURCE_PAIRED_LAYOUT_TYPE"}
		source = source.duplicate(true) as SceneScript
		source.map_layout = layout
	return {"ok": true, "source_scene": source, "terminal": terminal}
