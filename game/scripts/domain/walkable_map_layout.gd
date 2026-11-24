class_name WalkableMapLayout
extends Resource

## 自由行走地图 V2：只保存地图空间数据，不保存剧情、任务或 UI 状态。
## 所有坐标均为相对背景可视区域的归一化坐标（0~1）。

@export var schema_version: int = 2
@export var design_size: Vector2i = Vector2i(1920, 1080)

## Keep a reviewed single-image scene at its actual pixel dimensions. This is
## intended for compact maps that must not be enlarged to imitate a panorama.
## The controller centers any unused viewport space; it never duplicates or
## stretches the map art.
@export var display_at_native_size: bool = false

## Keep the reviewed native stage metadata while using an equal-ratio cover
## scale for modern wide windows. This is for compact interiors only; it never
## applies non-uniform stretching.
@export var fill_viewport: bool = false

## 正向可行走区域。每个 PackedVector2Array 是一个闭合边界，多边形边缘会生成物理墙。
@export var walkable_regions: Array[PackedVector2Array] = []

## Optional pixel-accurate navigation mask. White/opaque pixels are walkable;
## dark/transparent pixels are blocked. Complex caves and winding forest roads
## should prefer this over a handful of broad polygons. Polygons remain as a
## fallback and as human-readable topology documentation.
@export_file("*.png", "*.svg") var walkable_mask_path: String = ""

## Optional per-tile masks for large streamed maps. Each entry owns a
## `logical_rect` in design pixels and a native-size `path`. Omitted tiles
## remain blocked; never treat an unpainted staging tile as open ground.
@export var walkable_mask_tiles: Array[Dictionary] = []

## Staging atlas manifest: one unique terrain source, matching navigation tile,
## and logical rect per cell. This metadata is not a runtime open-area fallback.
@export var tiles: Array[Dictionary] = []

## Optional visible travel centerlines for staged large maps. A route uses
## normalized `points`, a finite `width_px`, and a road `texture`. Rendering a
## route never opens navigation: every centerline sample must already be safe
## in the authored mask and outside paired object/building blockers.
@export var travel_routes: Array[Dictionary] = []

## 五层地图数据：视觉、局部阻挡、交互、出口。NPC 仍由 SceneScript 管理。
@export var visual_objects: Array[Dictionary] = []
## Baked-background foreground samples. `depth_mode = overlap` owns a visual
## cover plus player-foot fade region for gates/roofs. `depth_mode = y_sort`
## owns a depth_y line and appears only while the actor is behind the prop.
## Occluders never own collision; matching blockers remain explicit.
@export var occluders: Array[Dictionary] = []
## Player-only transparency zones for buildings already painted into the base
## map. These zones add no foreground sprite and never fade the building; they
## only lower the player's alpha while the normalized foot point is inside.
@export var actor_fade_zones: Array[Dictionary] = []
@export var blockers: Array[Dictionary] = []
@export var interactions: Array[Dictionary] = []
@export var portals: Array[Dictionary] = []

## 关键地图验收点。用于防止美术或碰撞调整后重新出现穿帮。
@export var walkable_probes: Array[Dictionary] = []
@export var blocked_probes: Array[Dictionary] = []

## Staged multi-tile travel contracts. Each sample carries `from`, `to`,
## normalized points on both sides, and `status` (`open` or `pending_*`).
## QA must never count a pending seam as a passed crossing.
@export var seam_crossing_probes: Array[Dictionary] = []
