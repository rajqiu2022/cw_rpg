extends RefCounted
## Candidate only. Draws existing floor footprints; never writes compiled data,
## bodies, navigation, actors, saved feet, buildings, or portals.
const SELF := "res://build/luoyang_quality_20261101b_ground01/ground_visual.gd"
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Garden = preload("res://build/luoyang_garden_city_minimap_20261030b_system01/garden_visual.gd")
const District = preload("res://build/city_visual_diversity_20261031c/district_visuals.gd")
const STONE := "res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png"
const STONE_SHA := "39c898f7ac8c409b7b244077dd30016c398b21313156c8fc36911ddc859a5c0e"
const SOIL := "res://art/modules/miao_town_20261029f/ground.png"
const SOIL_SHA := "7dac9c249212fde5cbda1d005b0915a2e6ca3f86e2b465667edc088e1334ed7e"
const SOIL_GPU := "res://.godot/imported/ground.png-f9185ad954bdaa371273ad0152373913.ctex"
const SOIL_PERIOD := Vector2(768, 768)
const CURB_SHADER := "res://build/luoyang_quality_20261101b_ground01/curb_transition.gdshader"
const PERIOD := Vector2(256.0, 512.0 / 3.0)
const BORDER := 18.0
const DUST := 6.0
const FIELD := "res://build/luoyang_regions_20261027d_source01/region_field.gd"
const FIELD_SHA := "b6a8ce785d74d22a46fa680afcf0c365e15a0e83a887ccd8a40fffab875118cd"
const REGIONS := {
	"luoyang_estate_region_27d": 14,
	"luoyang_civic_market_region_27d": 22,
	"luoyang_temple_region_27d": 13,
}

static func handles(region: Dictionary) -> bool:
	return REGIONS.has(String(region.get("id", "")))

static func source_paths() -> Array[String]:
	var paths: Array[String] = [SELF, CURB_SHADER, SOIL, SOIL + ".import", SOIL_GPU]
	return paths

static func _stone(row: Dictionary) -> bool:
	return String(row.get("texture_role", "")) in ["court_stone", "public_stone", "shop_pavers"]

static func _add_cut(cuts: Array[float], value: float) -> void:
	if not cuts.has(value): cuts.append(value)

static func _quad(area: Rect2) -> PackedVector2Array:
	return PackedVector2Array([area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)])

static func _draw(layer: Node, area: Rect2, texture: Texture2D, border: bool) -> void:
	if area.size.x <= 0.0 or area.size.y <= 0.0: return
	var node := Polygon2D.new()
	node.name = "GroundQuality31b_Edging" if border else "GroundQuality31b_Paving"
	node.polygon = _quad(area)
	node.texture = texture
	node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Existing garden ribbons at -998 must cover a base-court edge where they
	# join it. Do not draw a false transverse curb across a continuous route.
	node.z_index = -999 if border else -1000
	node.z_as_relative = true
	# The edging is flat stone at grade, not an obstacle or raised wall.
	node.modulate = Color(0.84, 0.84, 0.84, 1.0) if border else Color.WHITE
	var uv := PackedVector2Array()
	for point: Vector2 in node.polygon: uv.append(point / PERIOD * texture.get_size())
	node.uv = uv
	node.set_meta("visual_only_at_grade", true)
	layer.add_child(node)

static func _add_boundary(buckets: Dictionary, vertical: bool, coordinate: float, low: float, high: float, normal: Vector2) -> void:
	var key := Vector3(coordinate, normal.x, normal.y)
	if not buckets.has(key): buckets[key] = {"vertical": vertical, "coordinate": coordinate, "normal": normal, "spans": []}
	buckets[key].spans.append(Vector2(low, high))

static func _continuous_edges(buckets: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for bucket: Dictionary in buckets.values():
		var spans: Array = bucket.spans
		spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var merged: Array[Vector2] = []
		for span: Vector2 in spans:
			if not merged.is_empty() and span.x <= merged[-1].y:
				merged[-1] = Vector2(merged[-1].x, maxf(merged[-1].y, span.y))
			else: merged.append(span)
		for span: Vector2 in merged:
			var a := Vector2(bucket.coordinate, span.x) if bucket.vertical else Vector2(span.x, bucket.coordinate)
			var b := Vector2(bucket.coordinate, span.y) if bucket.vertical else Vector2(span.y, bucket.coordinate)
			result.append({"a": a, "b": b, "normal": bucket.normal})
	return result

static func _draw_curb(layer: Node, edge: Dictionary, stone: Texture2D, soil: Texture2D, shader: Shader) -> void:
	var a: Vector2 = edge.a
	var b: Vector2 = edge.b
	var normal: Vector2 = edge.normal
	var tangent: Vector2 = (b - a).normalized()
	var node := Polygon2D.new()
	node.name = "GroundQuality31b_ContinuousStoneCurb"
	node.polygon = PackedVector2Array([a - normal * BORDER, b - normal * BORDER, b + normal * DUST, a + normal * DUST])
	node.texture = stone
	node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	node.z_as_relative = true; node.z_index = -999
	# Sample a single 108-source-pixel-high coursed row at the same 1/6
	# source-to-world scale. It is a clipped stone course, not a shrunk whole tile.
	# Along-edge phase is world anchored and never restarts at former cell cuts.
	var uv := PackedVector2Array()
	for point: Vector2 in node.polygon:
		var across := clampf((point - a).dot(normal) + BORDER, 0.0, BORDER)
		uv.append(Vector2(point.dot(tangent) * 6.0, 704.0 + across * 6.0))
	node.uv = uv
	var material := ShaderMaterial.new(); material.shader = shader
	material.set_shader_parameter("soil_texture", soil)
	material.set_shader_parameter("soil_period", SOIL_PERIOD)
	material.set_shader_parameter("edge_origin", a)
	material.set_shader_parameter("edge_outward", normal)
	material.set_shader_parameter("dust_width", DUST)
	material.set_shader_parameter("curb_width", BORDER)
	node.material = material
	node.set_meta("visual_only_at_grade", true)
	node.set_meta("continuous_source_edge", edge.duplicate(true))
	layer.add_child(node)

static func plan(region: Dictionary) -> Dictionary:
	if not handles(region): return {"ok": false, "error": "GROUND31B_UNKNOWN_REGION"}
	var rows: Array = region.get("surfaces", [])
	if rows.size() != int(REGIONS[String(region.id)]): return {"ok": false, "error": "GROUND31B_SURFACE_SET"}
	var xs: Array[float] = []
	var ys: Array[float] = []
	var surfaces: Array[Dictionary] = []
	for row: Dictionary in rows:
		if not Garden.visible_surface(region, row): continue
		var area := Core.rect(row.get("rect"))
		if area.size.x <= 0 or area.size.y <= 0: return {"ok": false, "error": "GROUND31B_RECT"}
		if String(row.get("texture_role", "")) not in ["court_stone", "public_stone", "shop_pavers", "service_earth", "workyard_earth"]:
			return {"ok": false, "error": "GROUND31B_MATERIAL"}
		surfaces.append({"rect": area, "stone": _stone(row)})
		_add_cut(xs, area.position.x); _add_cut(xs, area.end.x)
		_add_cut(ys, area.position.y); _add_cut(ys, area.end.y)
	var patches: Array[Dictionary] = []
	if String(region.id) == "luoyang_civic_market_region_27d":
		patches.append_array(District.rows("luoyang"))
	if String(region.id) == "luoyang_civic_market_region_27d" and patches.size() != 3:
		return {"ok": false, "error": "GROUND31B_DISTRICT_SET"}
	for patch: Dictionary in patches:
		for point: Vector2 in patch.polygon:
			_add_cut(xs, point.x); _add_cut(ys, point.y)
	xs.sort(); ys.sort()
	if xs.size() > 96 or ys.size() > 96: return {"ok": false, "error": "GROUND31B_FINITE_GRID"}
	var cells: Dictionary = {}
	for y: int in range(ys.size() - 1):
		for x: int in range(xs.size() - 1):
			var middle := Vector2((xs[x] + xs[x + 1]) * 0.5, (ys[y] + ys[y + 1]) * 0.5)
			var paved := false
			# Preserve authored painter priority, including earth work-courts.
			for surface: Dictionary in surfaces:
				if surface.rect.has_point(middle): paved = bool(surface.stone)
			for patch: Dictionary in patches:
				if Geometry2D.is_point_in_polygon(middle, patch.polygon): paved = true
			if paved: cells[Vector2i(x, y)] = true
	var quads: Array[Rect2] = []
	var boundaries: Dictionary = {}
	# Merge horizontal spans vertically. Internal cell edges are never drawn.
	var active: Dictionary = {}
	for y: int in range(ys.size() - 1):
		var next: Dictionary = {}
		var x := 0
		while x < xs.size() - 1:
			if not cells.has(Vector2i(x, y)):
				x += 1; continue
			var start := x
			while x < xs.size() - 1 and cells.has(Vector2i(x, y)): x += 1
			var span := Vector2i(start, x)
			var area := Rect2(Vector2(xs[start], ys[y]), Vector2(xs[x] - xs[start], ys[y + 1] - ys[y]))
			if active.has(span):
				var previous: Rect2 = active[span]
				area.position.y = previous.position.y; area.size.y = ys[y + 1] - previous.position.y
				next[span] = area; active.erase(span)
			else: next[span] = area
		for area: Rect2 in active.values(): quads.append(area)
		active = next
	for area: Rect2 in active.values(): quads.append(area)
	for cell: Vector2i in cells:
		var area := Rect2(Vector2(xs[cell.x], ys[cell.y]), Vector2(xs[cell.x + 1] - xs[cell.x], ys[cell.y + 1] - ys[cell.y]))
		if not cells.has(cell + Vector2i.LEFT): _add_boundary(boundaries, true, area.position.x, area.position.y, area.end.y, Vector2.LEFT)
		if not cells.has(cell + Vector2i.RIGHT): _add_boundary(boundaries, true, area.end.x, area.position.y, area.end.y, Vector2.RIGHT)
		if not cells.has(cell + Vector2i.UP): _add_boundary(boundaries, false, area.position.y, area.position.x, area.end.x, Vector2.UP)
		if not cells.has(cell + Vector2i.DOWN): _add_boundary(boundaries, false, area.end.y, area.position.x, area.end.x, Vector2.DOWN)
	var edging: Array[Dictionary] = _continuous_edges(boundaries)
	return {"ok": true, "paving": quads, "edging": edging, "period_px": PERIOD, "soil_period_px": SOIL_PERIOD, "curb_width_px": BORDER, "dust_width_px": DUST, "cell_count": cells.size(), "same_world_uv": true}

static func _uv(polygon: PackedVector2Array, texture: Texture2D, period: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in polygon: result.append(point / period * texture.get_size())
	return result

static func attach_view(field: Node, runtime_sources: Dictionary) -> Dictionary:
	# A separately approved presentation host supplies its frozen source pins.
	# Do not insert new files into, or impersonate, the old Region FIRST receipt.
	if not is_instance_valid(field) or not field.is_inside_tree() or field.get_script() == null or field.get_script().resource_path != FIELD:
		return {"ok": false, "error": "GROUND31B_FIELD"}
	if FileAccess.get_sha256(FIELD) != FIELD_SHA or runtime_sources.get(SELF) != FileAccess.get_sha256(SELF):
		return {"ok": false, "error": "GROUND31B_HOST_SOURCE"}
	for path: String in source_paths():
		var expected: String = String(runtime_sources.get(path, ""))
		if expected.length() != 64 or expected != FileAccess.get_sha256(path): return {"ok": false, "error": "GROUND31B_NEW_VIEW_SOURCE:" + path}
	if runtime_sources.get(SOIL) != SOIL_SHA: return {"ok": false, "error": "GROUND31B_APPROVED_FINE_SOIL"}
	if field.get_meta("ground_quality31b", {}).get("attached", false): return {"ok": true, "already_attached": true}
	var region: Dictionary = field.get("_region")
	var owner: RefCounted = field.get("_region_owner")
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	if not handles(region) or owner == null or not bool(field.get("_field_loading_complete")) or bool(field.get("_field_loading_failed")) or bool(field.get("_scene_rebuilding")):
		return {"ok": false, "error": "GROUND31B_NOT_LIVE"}
	if owner.call("revalidate_boundary", field, scene, region) != true:
		return {"ok": false, "error": "GROUND31B_ORIGINAL_BOUNDARY"}
	var first: Dictionary = owner.call("receipt").get("source_first", {})
	if first.get(STONE) != STONE_SHA or FileAccess.get_sha256(STONE) != STONE_SHA:
		return {"ok": false, "error": "GROUND31B_STONE_SOURCE"}
	for path: String in [Garden.SELF, Garden.SPEC, District.DATA]:
		if first.get(path) != FileAccess.get_sha256(path): return {"ok": false, "error": "GROUND31B_OLD_VIEW_SOURCE"}
	var layer: Node = field.get("_visual_layer")
	var texture: Texture2D = load(STONE) as Texture2D
	var soil: Texture2D = load(SOIL) as Texture2D
	var shader: Shader = load(CURB_SHADER) as Shader
	if not is_instance_valid(layer) or texture == null or soil == null or shader == null or layer.get_node_or_null("SourceBoundGroundView31b") != null:
		return {"ok": false, "error": "GROUND31B_LAYER"}
	var underlay: Polygon2D = layer.get_node_or_null("RegionDecorativeUnderlay") as Polygon2D
	var old_ground: Dictionary = region.get("visual_underlay", {})
	if underlay == null or underlay.z_index != -1100 or underlay.texture == null or underlay.texture.resource_path != old_ground.get("texture") or underlay.polygon != _quad(Rect2(Vector2.ZERO, region.size)) or underlay.transform != Transform2D.IDENTITY or not underlay.visible:
		return {"ok": false, "error": "GROUND31B_ORIGINAL_UNDERLAY_LAYER"}
	var prepared := plan(region)
	if not prepared.get("ok", false): return prepared
	var retire: Array[Polygon2D] = []
	# Match the complete existing leaf, not a name, texture-only filter, or an
	# arbitrary rectangle. Resident floor leaves are independent of render chunks.
	for row: Dictionary in region.surfaces:
		if not Garden.visible_surface(region, row): continue
		var shape := _quad(Core.rect(row.rect))
		var path := String(row.get("texture", ""))
		var matches: Array[Polygon2D] = []
		for child: Node in layer.get_children():
			if not child is Polygon2D or child.z_index != -1000 or child.texture == null: continue
			if child.texture.resource_path != path or child.polygon != shape: continue
			if child.uv != _uv(shape, child.texture, Core.vec(row.period_px)) or child.material != null or child.modulate != Color.WHITE or child.transform != Transform2D.IDENTITY or not child.visible:
				return {"ok": false, "error": "GROUND31B_OLD_FLOOR_CHANGED"}
			matches.append(child)
		if matches.size() != 1: return {"ok": false, "error": "GROUND31B_OLD_FLOOR_NOT_UNIQUE", "id": row.id}
		retire.append(matches[0])
	if String(region.id) == "luoyang_civic_market_region_27d":
		for patch: Dictionary in District.rows("luoyang"):
			var node: Polygon2D = layer.get_node_or_null("District31c_" + String(patch.id)) as Polygon2D
			if node == null or node.texture == null or node.texture.resource_path != String(patch.texture) or node.polygon != patch.polygon or node.uv != _uv(patch.polygon, node.texture, patch.period) or not node.visible:
				return {"ok": false, "error": "GROUND31B_OLD_DISTRICT_CHANGED"}
			retire.append(node)
	var garden_leaves: Array[Polygon2D] = []
	if Garden.handles(region):
		for child: Node in layer.get_children():
			if child is Polygon2D and child.texture == texture and child.z_index == -998:
				if child.uv != _uv(child.polygon, texture, Vector2(384, 256)) or child.material != null or child.transform != Transform2D.IDENTITY or not child.visible:
					return {"ok": false, "error": "GROUND31B_OLD_GARDEN_CHANGED"}
				garden_leaves.append(child)
		if garden_leaves.is_empty(): return {"ok": false, "error": "GROUND31B_GARDEN_MISSING"}
	var view := Node2D.new()
	view.name = "SourceBoundGroundView31b"
	_draw(view, Rect2(Vector2.ZERO, region.size), soil, false)
	var fine_base: Polygon2D = view.get_child(0) as Polygon2D
	fine_base.name = "GroundQuality31b_CompactedFineSoil"
	fine_base.z_as_relative = true; fine_base.z_index = -1050
	fine_base.uv = _uv(fine_base.polygon, soil, SOIL_PERIOD)
	for area: Rect2 in prepared.paving: _draw(view, area, texture, false)
	for edge: Dictionary in prepared.edging: _draw_curb(view, edge, texture, soil, shader)
	# Allocate/validate every replacement before one atomic view switch.
	if owner.call("revalidate_boundary", field, scene, region) != true:
		view.free(); return {"ok": false, "error": "GROUND31B_FINAL_ORIGINAL_BOUNDARY"}
	layer.add_child(view)
	for node: Polygon2D in retire: node.hide()
	for node: Polygon2D in garden_leaves: node.uv = _uv(node.polygon, texture, PERIOD)
	# Rebuild only the existing one-shot visual thumbnail, preserving its retained
	# portal/actor marker model. Its scanner ignores hidden old leaves.
	var mini: Node = field.get("_world_travel_minimap")
	if is_instance_valid(mini) and mini.get_script() != null and mini.get_script().resource_path == "res://build/luoyang_garden_city_minimap_20261030b_system01/city_minimap.gd":
		mini.call("_build_plan")
	var receipt: Dictionary = {"ok": true, "attached": true, "visual_revision": 4, "region_id": region.id, "old_source_receipt_unchanged": true, "old_compiled_sha256": owner.call("receipt").get("compiled_SHA256", ""), "retired_floor_leaves": retire.size(), "paving_quads": prepared.paving.size(), "edge_quads": prepared.edging.size(), "cell_count": prepared.cell_count, "period_px": PERIOD, "soil_texture": SOIL, "soil_period_px": SOIL_PERIOD, "soil_parent_relative_z": -1050, "all_new_ground_uses_original_parent_z_family": true, "curb_width_px": BORDER, "dust_width_px": DUST, "continuous_edges_not_grid_fragments": true, "physics_changed": false, "compiled_changed": false}
	field.set_meta("ground_quality31b", receipt)
	return receipt
