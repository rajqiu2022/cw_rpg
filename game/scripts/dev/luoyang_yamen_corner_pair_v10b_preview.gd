extends "res://scripts/dev/luoyang_yamen_front_asset_v9_preview.gd"

## Two actual atlas corners only. A is deliberately NOT used. B/C remain
## uniformly scaled; no bitmap edits, shaders, alpha threshold or mirroring.
const ATLAS_REL := "assets/raw/scene_module/luoyang_yamen_enclosure_v10b/enclosure_modules_v10b_candidate.png"
const ATLAS_SHA := "77e422646067b34d98f2e76a9582139f2b93801ca0271c1452e0f1889a915e0e"
const CORNER_SCALE := (344.*UNIFORM_SCALE)/274.
const ARM_LENGTH := 240.
const NORTH_LENGTH := 160.
const SOURCE_FRONT_FOOT := 754.
const SOURCE_FRONT_RIDGE := 480.
const NORTH_CUT := SOURCE_FRONT_RIDGE-NORTH_LENGTH/CORNER_SCALE
const LEFT_CUT := 480.+ARM_LENGTH/CORNER_SCALE
const RIGHT_CUT := 1707.-ARM_LENGTH/CORNER_SCALE
const LEFT_ORIGIN := Vector2(960.,1689.5)-Vector2(480.,SOURCE_FRONT_FOOT)*CORNER_SCALE
const RIGHT_ORIGIN := Vector2(2110.,1689.5)-Vector2(1707.,SOURCE_FRONT_FOOT)*CORNER_SCALE
var atlas_image: Image
var atlas_texture: ImageTexture

func prepare() -> bool:
	if not super.prepare(): return false
	if FileAccess.get_sha256(repo_path(ATLAS_REL)).to_lower() != ATLAS_SHA:
		error = "Actual V10b atlas SHA mismatch."
		return false
	atlas_image = Image.load_from_file(repo_path(ATLAS_REL))
	if atlas_image == null or atlas_image.get_size() != Vector2i(1882,836) or atlas_image.get_format() != Image.FORMAT_RGBA8:
		error = "Actual V10b1882x836 RGBA8 required; no fallback/conversion."
		return false
	for uv: PackedVector2Array in [corner_uv(true),corner_uv(false)]:
		if Geometry2D.triangulate_polygon(uv).is_empty():
			error = "Actual B/C source-domain polygon cannot triangulate."
			return false
	atlas_texture = ImageTexture.create_from_image(atlas_image)
	return true

func corner_uv(left: bool) -> PackedVector2Array:
	# Explicit semantic B/C L domains, not canvas-third splitting. North run
	# and horizontal arm shortened ONLY by UV selection, unchanged XY scale.
	# x426 excludes distant residue while leaving visible B's x428 silhouette.
	if left:
		return PackedVector2Array([Vector2(426,NORTH_CUT),Vector2(560,NORTH_CUT),Vector2(560,466),Vector2(LEFT_CUT,466),Vector2(LEFT_CUT,772),Vector2(426,772)])
	return PackedVector2Array([Vector2(1640,NORTH_CUT),Vector2(1760,NORTH_CUT),Vector2(1760,772),Vector2(RIGHT_CUT,772),Vector2(RIGHT_CUT,466),Vector2(1640,466)])

func baseline_walls(parent: Node2D,rect: Rect2i,zoom: int) -> Array[Polygon2D]:
	return super.walls(parent,rect,zoom)

func walls(parent: Node2D,rect: Rect2i,zoom: int) -> Array[Polygon2D]:
	var nodes: Array[Polygon2D] = []
	# No approved old wall remains UNDER the new x960..1200/1870..2110 arms.
	for span: Vector2 in [Vector2(1200.,LEFT_END),Vector2(RIGHT_START,1870.)]:
		var lo: float = (span.x-WALL_ORIGIN.x)/UNIFORM_SCALE
		var hi: float = (span.y-WALL_ORIGIN.x)/UNIFORM_SCALE
		var uv := PackedVector2Array([Vector2(lo,200),Vector2(hi,200),Vector2(hi,572),Vector2(lo,572)])
		nodes.append(_polygon(parent,uv,wall_texture,WALL_ORIGIN,UNIFORM_SCALE,rect,zoom,"ApprovedV9InnerLeft" if nodes.is_empty() else "ApprovedV9InnerRight",10))
	nodes.append(_polygon(parent,corner_uv(true),atlas_texture,LEFT_ORIGIN,CORNER_SCALE,rect,zoom,"ActualAtlasB_Southwest",10))
	nodes.append(_polygon(parent,corner_uv(false),atlas_texture,RIGHT_ORIGIN,CORNER_SCALE,rect,zoom,"ActualAtlasC_Southeast",10))
	return nodes

func release() -> void:
	atlas_texture = null
	atlas_image = null
	super.release()
