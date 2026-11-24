extends "res://scripts/dev/luoyang_yamen_corner_pair_v10b_preview.gd"

## V10c consumer-only change. Frozen original atlas/V9 images unmodified.
## All horizontal plaster and brick use V9; atlas draws ONLY short roof
## turns+north tops and separately traced corner piers. No long atlas arm.
const BODY_TOP_UV_Y := 337.
const CAP_EAVE_UV_Y := 574.
const LEFT_TANGENT_UV_X := 560.
const RIGHT_TANGENT_UV_X := 1640.
const LEFT_TANGENT_X := 960.+(LEFT_TANGENT_UV_X-480.)*CORNER_SCALE
const RIGHT_TANGENT_X := 2110.+(RIGHT_TANGENT_UV_X-1707.)*CORNER_SCALE

func roof_cap_uv(left: bool) -> PackedVector2Array:
	# Actual atlas tangent domains: continuous straight roof begins beyond
	# Bx560/Cx1640. Clip there, not at former240logical arm boundary.
	# source574 maps1558.245; V9 source337 maps1558.237 (manual anchors,
	# not a GPU-perfect-contact claim). No atlas wall panel below this edge.
	if left:
		return PackedVector2Array([Vector2(426,NORTH_CUT),Vector2(560,NORTH_CUT),Vector2(560,CAP_EAVE_UV_Y),Vector2(426,CAP_EAVE_UV_Y)])
	return PackedVector2Array([Vector2(1640,NORTH_CUT),Vector2(1760,NORTH_CUT),Vector2(1760,CAP_EAVE_UV_Y),Vector2(1640,CAP_EAVE_UV_Y)])

func pier_uv(left: bool) -> PackedVector2Array:
	# Narrow authored corner post/stone base, not a wall-colour overlay.
	# Trace the actual upper shaft and wider base, not a broad rectangle
	# containing the atlas's horizontal plaster/brick courses.
	if left:
		return PackedVector2Array([Vector2(444,CAP_EAVE_UV_Y),Vector2(480,CAP_EAVE_UV_Y),Vector2(480,695),Vector2(489,699),Vector2(489,766),Vector2(437,766),Vector2(437,699),Vector2(444,695)])
	return PackedVector2Array([Vector2(1702,CAP_EAVE_UV_Y),Vector2(1740,CAP_EAVE_UV_Y),Vector2(1740,695),Vector2(1746,699),Vector2(1746,766),Vector2(1696,766),Vector2(1696,699),Vector2(1702,695)])

func prepare() -> bool:
	if not super.prepare(): return false
	for uv: PackedVector2Array in [roof_cap_uv(true),roof_cap_uv(false),pier_uv(true),pier_uv(false)]:
		if Geometry2D.triangulate_polygon(uv).is_empty():
			error = "V10c actual roof/pier UV cannot triangulate."
			return false
	return true

func _v9_strip(parent: Node2D,span: Vector2,top: float,bottom: float,rect: Rect2i,zoom: int,label: String) -> Polygon2D:
	var lo: float = (span.x-WALL_ORIGIN.x)/UNIFORM_SCALE
	var hi: float = (span.y-WALL_ORIGIN.x)/UNIFORM_SCALE
	return _polygon(parent,PackedVector2Array([Vector2(lo,top),Vector2(hi,top),Vector2(hi,bottom),Vector2(lo,bottom)]),wall_texture,WALL_ORIGIN,UNIFORM_SCALE,rect,zoom,label,10)

func walls(parent: Node2D,rect: Rect2i,zoom: int) -> Array[Polygon2D]:
	var nodes: Array[Polygon2D] = []
	# FULL horizontal wallbody/plinth, never atlas panels or duplicate V9.
	nodes.append(_v9_strip(parent,Vector2(960.,LEFT_END),BODY_TOP_UV_Y,572.,rect,zoom,"V9FullHorizontalBodyLeft"))
	nodes.append(_v9_strip(parent,Vector2(RIGHT_START,2110.),BODY_TOP_UV_Y,572.,rect,zoom,"V9FullHorizontalBodyRight"))
	# Straight roof ends at actual cap tangent. No old full roof below caps.
	nodes.append(_v9_strip(parent,Vector2(LEFT_TANGENT_X,LEFT_END),200.,BODY_TOP_UV_Y,rect,zoom,"V9StraightRoofLeft"))
	nodes.append(_v9_strip(parent,Vector2(RIGHT_START,RIGHT_TANGENT_X),200.,BODY_TOP_UV_Y,rect,zoom,"V9StraightRoofRight"))
	nodes.append(_polygon(parent,roof_cap_uv(true),atlas_texture,LEFT_ORIGIN,CORNER_SCALE,rect,zoom,"AtlasB_RoofTurnOnly",11))
	nodes.append(_polygon(parent,roof_cap_uv(false),atlas_texture,RIGHT_ORIGIN,CORNER_SCALE,rect,zoom,"AtlasC_RoofTurnOnly",11))
	nodes.append(_polygon(parent,pier_uv(true),atlas_texture,LEFT_ORIGIN,CORNER_SCALE,rect,zoom,"AtlasB_CornerPierOnly",12))
	nodes.append(_polygon(parent,pier_uv(false),atlas_texture,RIGHT_ORIGIN,CORNER_SCALE,rect,zoom,"AtlasC_CornerPierOnly",12))
	return nodes
