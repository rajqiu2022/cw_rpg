class_name StreamedBackgroundSet
extends Resource

## One logical map with platform-specific raster variants. Chunk dictionaries use:
## {
##   "path": "res://art/background_chunks/.../tile_00_00.png",
##   "logical_rect": Rect2(x, y, width, height),
##   "draw_position": Vector2(x, y),
##   "draw_scale": 1.0
## }
## `logical_rect` excludes the overlap used by the source crop, while
## `draw_position` includes it. This keeps adjacent filtered tiles seam-free.

@export var logical_size: Vector2i = Vector2i(1920, 1080)
@export var mobile_preview_path: String = ""
@export var desktop_preview_path: String = ""
@export var mobile_chunks: Array[Dictionary] = []
@export var desktop_chunks: Array[Dictionary] = []
@export_range(0.0, 1024.0, 1.0) var load_padding: float = 192.0
@export_range(0.0, 2048.0, 1.0) var retain_padding: float = 448.0


func has_chunks(prefer_desktop: bool) -> bool:
	return not get_chunks(prefer_desktop).is_empty()


func get_chunks(prefer_desktop: bool) -> Array[Dictionary]:
	if prefer_desktop and not desktop_chunks.is_empty():
		return desktop_chunks
	return mobile_chunks


func get_preview_path(prefer_desktop: bool) -> String:
	if prefer_desktop and not desktop_preview_path.is_empty():
		return desktop_preview_path
	return mobile_preview_path


func uses_desktop_variant() -> bool:
	return OS.get_name() in ["Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"] \
		and not desktop_chunks.is_empty()
