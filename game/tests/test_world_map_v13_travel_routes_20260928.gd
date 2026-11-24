extends SceneTree

## Verifies that staging roads are visible runtime Line2D nodes, rather than
## layout-only paths. Every drawn lane is sampled against full player-foot
## clearance at its centre and both near-edge tracks.

const STAGING_ID := &"world_map_jianghu_v13_staging"
const STAGING_PATH := "res://data/scenes/world_map_jianghu_v13_staging.tres"
const WORLD_SIZE := Vector2(4608, 3072)
const EXPECTED_PORTALS := [
	"yanmen_pass", "huashan", "wudang", "gufeng", "lingyue",
	"bianzhou", "linxi_village", "luoyang", "xiangzhou",
	"east_sea_port", "bailu_ferry", "zhuwei_village",
	"qinghe_town", "jinling", "mingwu", "lieyun_valley",
]

var _checks := 0
var _failures := 0
var _pending := 0
var _strict := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var production := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	_strict = OS.get_cmdline_user_args().has("--strict-v13") or (production != null and production.map_layout != null and production.map_layout.schema_version == 13)
	if not ResourceLoader.exists(STAGING_PATH):
		_pending_note("v13 staging scene not yet present")
		_finish()
		return
	var scene := load(STAGING_PATH) as SceneScript
	if scene == null or scene.map_layout == null:
		_check(false, "v13 staging scene and map layout load")
		_finish()
		return
	var routes: Array[Dictionary] = scene.map_layout.travel_routes
	_require(routes.size() >= EXPECTED_PORTALS.size(), "at least one rendered route per gateway")
	if routes.is_empty():
		_finish()
		return
	var router := root.get_node_or_null("SceneRouter")
	if router == null:
		_check(false, "SceneRouter autoload is available")
		_finish()
		return
	router.go_field_smart(STAGING_ID, scene.player_spawn)
	var field: Node = null
	for tick in range(160):
		await create_timer(0.05).timeout
		if current_scene != null and current_scene.has_method("_spawn_has_foot_clearance"):
			field = current_scene
			break
	if field == null:
		_check(false, "staging Field runtime loads")
		_finish()
		return
	var visual_layer: Node = field.get("_visual_layer")
	_check(visual_layer != null, "staging Field owns a visual layer")
	if visual_layer == null:
		_finish()
		return
	var route_ids := {}
	var route_portals := {}
	var route_nodes := 0
	var route_warned_missing := 0
	var pending_visual := 0
	for route in routes:
		var route_id := String(route.get("id", ""))
		var portal_id := String(route.get("portal_id", ""))
		_check(route_id != "" and not route_ids.has(route_id), "travel route owns unique ID: " + route_id)
		route_ids[route_id] = true
		_check(EXPECTED_PORTALS.has(portal_id), "travel route targets a public gateway: " + route_id)
		route_portals[portal_id] = true
		if String(route.get("validation_status", "")).begins_with("PENDING"):
			pending_visual += 1
		var points_value: Variant = route.get("points", PackedVector2Array())
		if not points_value is PackedVector2Array or (points_value as PackedVector2Array).size() < 2:
			_check(false, "travel route has at least two points: " + route_id)
			continue
		var points: PackedVector2Array = points_value
		var width_px := float(route.get("width_px", 0.0))
		_check(width_px >= 24.0 and width_px <= 100.0, "route has foot-scale rendered width: " + route_id)
		var path := String(route.get("texture", ""))
		_check(ResourceLoader.exists(path), "route has an imported road texture: " + route_id)
		var line := visual_layer.get_node_or_null("TravelRoute_" + route_id) as Line2D
		if line == null:
			route_warned_missing += 1
			_check(false, "runtime route was not skipped and has a Line2D: " + route_id)
			continue
		route_nodes += 1
		_check(line.visible and line.points.size() == points.size() and line.texture != null, "runtime route renders all authored points: " + route_id)
		_check(absf(line.width - width_px) < 1.0, "runtime route width matches layout: " + route_id)
		var portal_pos := Vector2(-1, -1)
		for raw in scene.map_layout.portals:
			var portal: Dictionary = raw
			if String(portal.get("id", "")) == portal_id:
				portal_pos = portal.get("pos", Vector2(-1, -1))
				break
		var closest := INF
		for point in points:
			closest = minf(closest, (point * WORLD_SIZE).distance_to(portal_pos * WORLD_SIZE))
		_check(closest <= 100.0, "visible route reaches the gateway's landing area: " + route_id)
		var sampled := 0
		var unsafe_centre := 0
		var unsafe_edges := 0
		var centre_examples: Array[String] = []
		var edge_examples: Array[String] = []
		for index in range(points.size() - 1):
			var a := points[index] * WORLD_SIZE
			var b := points[index + 1] * WORLD_SIZE
			var segment := b - a
			if segment.length() < 1.0:
				continue
			var normal := segment.normalized().orthogonal()
			var samples := maxi(1, int(ceil(segment.length() / 24.0)))
			for sample_index in range(samples + 1):
				var centre := a.lerp(b, float(sample_index) / float(samples))
				var centre_norm := centre / WORLD_SIZE
				sampled += 1
				if not field.call("_spawn_has_foot_clearance", scene, centre_norm):
					unsafe_centre += 1
					if centre_examples.size() < 3:
						centre_examples.append(_unsafe_detail(field, centre_norm, "centre"))
				var lane_offset := maxf(0.0, width_px * 0.5 - 8.0)
				for side in [-1.0, 1.0]:
					var edge_norm: Vector2 = (centre + normal * side * lane_offset) / WORLD_SIZE
					if not field.call("_spawn_has_foot_clearance", scene, edge_norm):
						unsafe_edges += 1
						if edge_examples.size() < 3:
							edge_examples.append(_unsafe_detail(field, edge_norm, "edge %s" % ("left" if side < 0.0 else "right")))
		_check(sampled > 0 and unsafe_centre == 0, "road centre has full-foot clearance (%d/%d unsafe): %s %s" % [unsafe_centre, sampled, route_id, "; ".join(centre_examples)])
		_check(sampled > 0 and unsafe_edges == 0, "road near-edges have full-foot clearance (%d/%d unsafe): %s %s" % [unsafe_edges, sampled * 2, route_id, "; ".join(edge_examples)])
	for portal_id in EXPECTED_PORTALS:
		_check(route_portals.has(portal_id), "public gateway has a rendered route: " + portal_id)
	_check(route_nodes == routes.size() and route_warned_missing == 0, "no authored travel route was skipped at runtime")
	if pending_visual > 0:
		_pending_note("%d/%d road textures still await screenshot-based alignment approval" % [pending_visual, routes.size()])
	_finish()


func _unsafe_detail(field: Node, point: Vector2, lane: String) -> String:
	return "%s pos=%s mask=%s blocker=%s" % [lane, str(point), str(field.call("_is_walkable_by_mask", point)), str(field.call("_is_blocked_by_layout", point))]


func _require(condition: bool, message: String) -> void:
	if condition:
		_check(true, message)
	else:
		_pending_note(message)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("[FAIL] " + message)
	else:
		print("[PASS] " + message)


func _pending_note(message: String) -> void:
	if _strict:
		_check(false, "strict v13 route gate: " + message)
		return
	_pending += 1
	print("[PENDING] " + message)


func _finish() -> void:
	print("[WorldMapV13TravelRoutes] checks=%d failed=%d pending=%d" % [_checks, _failures, _pending])
	quit(1 if _failures > 0 else 0)
