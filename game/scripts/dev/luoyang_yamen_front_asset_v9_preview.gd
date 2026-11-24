extends RefCounted

## Actual generated original, sampled directly by GPU. No bitmap edits,
## colour shader, alpha discard, native roof or PBR claim.
const WALL_REL := "assets/raw/scene_module/luoyang_yamen_front_v9/front_wall_v9_candidate.png"
const WALL_SHA := "b903c3aef333e0c3880ad0fb2fc83e131336cc381fde8d4f0fa88b59585149fb"
const GATE_PATH := "res://art/maps/luoyang_modular_v3/source/courtyard_wall_gate_v3.png"
const GATE_SHA := "dbe22e8e6072cbfee28fd5fb01cbc393f532de12ed9f356e7ec269fff5248221"
const WALL_UV := Rect2(100,200,1980,372)
const UNIFORM_SCALE := 1150./1980.
const WALL_ORIGIN := Vector2(960.,1689.5-563.*UNIFORM_SCALE)-Vector2(100.*UNIFORM_SCALE,0)
const GATE_ORIGIN := Vector2(1050.5,1347.5)
const GATE_SCALE := .5
const LEFT_END := 1450.5 # Wall ends behind left original timber, not aperture.
const RIGHT_START := 1620.5 # Right timber overlaps wall, original hole is clear.
# Manually traced source-domain outline: roof, tapering wood brackets/header,
# posts/reveals and stone shoes. NO original side/front wall strip below y350.
# This is an explicit source UV selection, not an edited/masked bitmap.
const GATE_UV := [Vector2(600,0),Vector2(1340,0),Vector2(1340,340),Vector2(1250,340),Vector2(1226,350),Vector2(1204,350),Vector2(1204,636),Vector2(1201,637),Vector2(1201,710),Vector2(1134,710),Vector2(1134,704),Vector2(1100,704),Vector2(1100,407),Vector2(1094,407),Vector2(1094,374),Vector2(846,374),Vector2(846,407),Vector2(840,407),Vector2(840,704),Vector2(810,704),Vector2(810,712),Vector2(744,712),Vector2(744,637),Vector2(750,637),Vector2(750,350),Vector2(716,350),Vector2(694,340),Vector2(600,340)]
const KEEP_PROBES := [Vector2i(971,210),Vector2i(971,355),Vector2i(780,500),Vector2i(1160,500),Vector2i(777,680),Vector2i(1170,680)]
const EXCLUDE_PROBES := [Vector2i(700,380),Vector2i(720,420),Vector2i(1240,400),Vector2i(1250,520),Vector2i(720,500),Vector2i(1240,500),Vector2i(90,420),Vector2i(1850,420)]
const HOLE_PROBES := [Vector2i(971,420),Vector2i(971,600),Vector2i(971,690)]
var wall_image: Image
var gate_image: Image
var wall_texture: ImageTexture
var gate_texture: ImageTexture
var error := ""

static func repo_path(relative: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../"+relative).simplify_path()

func prepare() -> bool:
	if FileAccess.get_sha256(repo_path(WALL_REL)).to_lower() != WALL_SHA or FileAccess.get_sha256(GATE_PATH).to_lower() != GATE_SHA:
		error = "Actual V9 wall/original gate SHA mismatch."
		return false
	wall_image = Image.load_from_file(repo_path(WALL_REL))
	gate_image = Image.load_from_file(GATE_PATH)
	if wall_image == null or gate_image == null or wall_image.get_size() != Vector2i(2172,724) or gate_image.get_size() != Vector2i(1942,809) or wall_image.get_format() != Image.FORMAT_RGBA8 or gate_image.get_format() != Image.FORMAT_RGBA8:
		error = "Exact actual RGBA8 source sizes required; no fallback/conversion."
		return false
	var domain := PackedVector2Array(GATE_UV)
	if Geometry2D.triangulate_polygon(domain).is_empty():
		error = "Explicit gate-only source domain cannot triangulate."
		return false
	for point: Vector2i in KEEP_PROBES:
		if not Geometry2D.is_point_in_polygon(Vector2(point),domain):
			error = "Gate-only source domain lost an original roof/wood/foot probe."
			return false
	for point: Vector2i in EXCLUDE_PROBES+HOLE_PROBES:
		if Geometry2D.is_point_in_polygon(Vector2(point),domain):
			error = "Gate-only source domain retained an old wall or aperture."
			return false
	wall_texture = ImageTexture.create_from_image(wall_image)
	gate_texture = ImageTexture.create_from_image(gate_image)
	return true

func _polygon(parent: Node2D,uv: PackedVector2Array,texture: Texture2D,source_origin: Vector2,source_scale: float,rect: Rect2i,zoom: int,label: String,z: int) -> Polygon2D:
	var node := Polygon2D.new()
	node.name = label
	node.polygon = uv.duplicate()
	node.uv = uv.duplicate()
	node.texture = texture
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	node.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	node.position = (source_origin-Vector2(rect.position))*float(zoom)*2.
	node.scale = Vector2.ONE*source_scale*float(zoom)*2.
	node.z_index = z
	parent.add_child(node)
	return node

func gate(parent: Node2D,rect: Rect2i,zoom: int) -> Polygon2D:
	return _polygon(parent,PackedVector2Array(GATE_UV),gate_texture,GATE_ORIGIN,GATE_SCALE,rect,zoom,"OriginalCentralGateUV",20)

func walls(parent: Node2D,rect: Rect2i,zoom: int) -> Array[Polygon2D]:
	var nodes: Array[Polygon2D] = []
	for span: Vector2 in [Vector2(960.,LEFT_END),Vector2(RIGHT_START,2110.)]:
		var lo: float = (span.x-WALL_ORIGIN.x)/UNIFORM_SCALE
		var hi: float = (span.y-WALL_ORIGIN.x)/UNIFORM_SCALE
		var uv := PackedVector2Array([Vector2(lo,200),Vector2(hi,200),Vector2(hi,572),Vector2(lo,572)])
		nodes.append(_polygon(parent,uv,wall_texture,WALL_ORIGIN,UNIFORM_SCALE,rect,zoom,"UnifiedWallLeft" if nodes.is_empty() else "UnifiedWallRight",10))
	return nodes

func release() -> void:
	wall_texture = null
	gate_texture = null
	wall_image = null
	gate_image = null
