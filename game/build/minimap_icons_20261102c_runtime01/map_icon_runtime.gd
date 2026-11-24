extends Node
## Presentation-only minimap replacement. The original map builders keep ownership
## of coordinates, thumbnails, player state, portal safety and scene loading.
const OVERLAY := preload("res://build/minimap_icons_20261102c_runtime01/icon_overlay.gd")
const SERVICES := preload("res://build/city_navigation_minimap_20261101d_candidate01/service_semantics.gd")
const VISIT_PREFIX := "map_visit_v1/"
const WORLDS := ["world_map_jianghu", "world_map_jianghu_v15", "world_map_jianghu_v16"]
const WORLD_MINI := "res://scripts/ui/world_travel_minimap.gd"
const CITY_MINIS := ["res://build/linxi_road_portrait_20261030g_source01/road_minimap.gd", "res://build/luoyang_garden_city_minimap_20261030b_system01/city_minimap.gd", "res://build/three_settlements_20261030e_system01/city_minimap.gd", "res://build/four_settlements_20261030e_system01/minimap.gd"]
const WORLD_CATEGORIES := {
	"openworld_yanmen_pass":"city", "ch4_s0_luoyang_gate":"city", "openworld_bianzhou_city":"city", "openworld_xiangzhou_city":"city", "openworld_jinling_city":"city", "openworld_desert_city":"city",
	"linxi_village_scrollmap":"village", "openworld_qinghe_town":"village", "ch1_s2_qingfeng":"village", "openworld_redrock_town":"village", "openworld_lanxi_zhai":"village", "openworld_east_sea_port":"village",
	"openworld_huashan_forecourt":"sect", "openworld_wudang_gate":"sect", "ch2_s4_lingyue_gate":"sect", "ch7_s2_mingwu_tea_town":"sect", "ch7_s1_lieyun_valley_ferry":"sect", "ch5_s1_relief_road":"sect",
	"openworld_bailu_ferry":"ferry", "adventure_zhuwei_hunting_ground":"outskirts", "adventure_xiangzhou_deep_mine":"outskirts", "adventure_luoyang_riverside_route":"outskirts"
}
const LUOYANG_AREAS := ["ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen", "ch4_s2_canal_docks", "ch4_s3_luoyang_market", "ch4_s4_ancient_temple", "luoyang_civic_market_region_27d", "luoyang_temple_region_27d", "luoyang_estate_region_27d", "luoyang_estate_riverside_20261021ai", "luoyang_artisan_residential_20261022ap", "luoyang_riverside_garden_20261022ap"]
const LINXI_AREAS := ["linxi_tutorial", "linxi_village_center", "linxi_village_scrollmap", "linxi_herbal_home", "linxi_master_hall", "linxi_south_apothecary_home", "linxi_cottage"]
const SHOP_ACTIONS := {"shop:linxi_apothecary":"medicine", "shop:linxi_shenbanzhan":"medicine", "shop:zhuwei_apothecary":"medicine", "shop:gufeng_smithy":"smith", "shop:luoyang_armory":"smith", "shop:luoyang_services_20261025h/smith":"smith", "shop:luoyang_services_20261025h/herbal":"medicine", "shop:luoyang_services_20261025h/pawn":"pawn"}
var _clock := 1.0
var _field: WeakRef
var _overlay: WeakRef
var _room_services: Dictionary = {}
var _label_nodes: Array[WeakRef] = []
var _label_ids: Dictionary = {}
var _visit_writes := 0
var _label_changes := 0

func _ready() -> void:
	process_priority = 1200
	_room_services = SERVICES.service_rooms()
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_adopt_existing_zones")

func _adopt_existing_zones() -> void:
	for node: Node in get_tree().get_nodes_in_group("exit_zone"):
		_register_zone(node)

func _on_node_added(node: Node) -> void:
	if node is ExitZone:
		call_deferred("_register_weak_zone", weakref(node))

func _register_weak_zone(reference: WeakRef) -> void:
	var zone: Node = reference.get_ref() as Node
	if is_instance_valid(zone) and zone.is_inside_tree() and not zone.is_queued_for_deletion():
		_register_zone(zone)

func _register_zone(node: Node) -> void:
	if not node is ExitZone:
		return
	if not _label_ids.has(node.get_instance_id()):
		_label_ids[node.get_instance_id()] = true
		_label_nodes.append(weakref(node))
	_clean_zone_label(node as ExitZone)

static func clean_destination(text: String) -> String:
	# Only the explicit input-key prefix is presentation. Destination content,
	# hotspot identity and the underlying keyboard action are unchanged.
	var result: String = text
	for prefix: String in ["空格 · ", "空格·", "空格：", "空格: ", "空格 "]:
		if result.begins_with(prefix):
			return result.trim_prefix(prefix)
	return result

func _clean_zone_label(zone: ExitZone) -> void:
	var cleaned: String = clean_destination(zone.exit_label)
	if cleaned != zone.exit_label:
		zone.exit_label = cleaned
		_label_changes += 1
	zone.destination_name = clean_destination(zone.destination_name)
	if is_instance_valid(zone.prompt):
		zone.prompt.text = clean_destination(zone.prompt.text)

func _process(delta: float) -> void:
	# Small registered list, never a per-frame whole-tree scan. Legacy range
	# handlers can set Prompt.text later, so sanitize that display tail too.
	for index: int in range(_label_nodes.size() - 1, -1, -1):
		var zone: ExitZone = _label_nodes[index].get_ref() as ExitZone
		if not is_instance_valid(zone) or zone.is_queued_for_deletion():
			_label_nodes.remove_at(index)
			continue
		_clean_zone_label(zone)
	_clock += delta
	if _clock < 0.2:
		return
	_clock = 0.0
	var field: Node = get_tree().current_scene
	if not is_instance_valid(field) or not field.has_method("get_field_loading_state"):
		return
	var loading: Dictionary = field.call("get_field_loading_state")
	if loading.get("complete") != true or loading.get("failed") == true or field.get("_scene_rebuilding") == true:
		return
	var manager: Node = get_node_or_null("/root/LoadingManager")
	if manager != null and (manager.get("_transition_active") == true or manager.get("_external_active") == true):
		return
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	if scene == null:
		return
	prepare_field_for_loading(field)

func prepare_field_for_loading(field: Node) -> bool:
	# Loading's final barrier can call this while its screen is still visible.
	# The actual Field itself must already be complete; no requested destination
	# or temporary old Field is promoted into an accepted ready/visited state.
	if not is_instance_valid(field) or field != get_tree().current_scene or not field.has_method("get_field_loading_state"):
		return false
	var loading: Dictionary = field.call("get_field_loading_state")
	if loading.get("complete") != true or loading.get("failed") == true or field.get("_scene_rebuilding") == true:
		return false
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	if scene == null:
		return false
	_mark_successful_visit(field, scene)
	var mini: Control = field.get("_world_travel_minimap") as Control
	if not is_instance_valid(mini):
		return true # This Field has no city/World mini owned by this adapter.
	if mini.get_script() == null or mini.get("_configured") != true:
		return false
	var path: String = mini.get_script().resource_path
	if path != WORLD_MINI and path not in CITY_MINIS:
		return true # e.g. the independent adventure map has a different owner.
	var installed: Node = _overlay.get_ref() as Node if _overlay != null else null
	if not is_instance_valid(installed) or installed.get_parent() != mini:
		var overlay: Control = OVERLAY.new()
		overlay.name = "PureMapIcons02c"
		overlay.call("configure", self, field, mini, path == WORLD_MINI)
		mini.add_child(overlay)
		_field = weakref(field)
		_overlay = weakref(overlay)
	else:
		installed.call("refresh_rows")
	installed = _overlay.get_ref() as Node if _overlay != null else null
	return is_instance_valid(installed) and bool(installed.call("ready_for_loading_release"))

static func canonical_location(id: String) -> String:
	if id in LUOYANG_AREAS or id.begins_with("luoyang_market_") or id in ["luoyang_functional_pawnshop_candidate_20261016", "luoyang_functional_mansion_candidate_20261016", "estate27d_living_hall", "estate27d_west_study", "estate27d_east_bedroom", "temple27d_main_hall", "temple27d_monks_room", "temple27d_sutra_room", "yihongyuan27n_interior"]:
		return "ch4_s0_luoyang_gate"
	if id in LINXI_AREAS:
		return "linxi_village_scrollmap"
	if id in ["ch1_s2_qingfeng", "ch2_s1_zhuwei_market"]:
		return "ch1_s2_qingfeng"
	if id.begins_with("openworld_wudang_"):
		return "openworld_wudang_gate"
	if id.begins_with("openworld_huashan_"):
		return "openworld_huashan_forecourt"
	if id == "openworld_lingyue_inner_court":
		return "ch2_s4_lingyue_gate"
	if id == "ch7_s3_lieyun_outpost_outer_ward":
		return "ch7_s1_lieyun_valley_ferry"
	if id == "ch7_s4_mingwu_manor_outer_court":
		return "ch7_s2_mingwu_tea_town"
	return id

func _mark_successful_visit(_field_node: Node, scene: SceneScript) -> void:
	var router: Node = get_node_or_null("/root/SceneRouter")
	var game: Node = get_node_or_null("/root/GameState")
	if router == null or game == null:
		return
	# Router layout_versions are written before loading and are NOT visit proof.
	# Here the actual current Field has already finished without a loading error.
	var id: String = String(router.call("get_current_field_id"))
	if id.is_empty() or id in WORLDS:
		return
	var canonical: String = canonical_location(id)
	var physical_canonical: String = canonical_location(String(scene.scene_id))
	# A router may record its requested destination before a transition starts.
	# The already-loaded old Field must never make that destination look visited.
	if canonical != physical_canonical or not WORLD_CATEGORIES.has(canonical):
		return
	var flags: Dictionary = game.get("flags")
	var key: String = VISIT_PREFIX + canonical
	if flags.get(key) != true:
		flags[key] = true
		_visit_writes += 1

func visited(target: String) -> bool:
	var game: Node = get_node_or_null("/root/GameState")
	if game == null:
		return false
	var flags: Dictionary = game.get("flags")
	var canonical: String = canonical_location(target)
	if flags.get(VISIT_PREFIX + canonical) == true:
		return true
	# Original arrival flag is trustworthy. No guessing from chapter/quest state.
	return canonical == "ch1_s2_qingfeng" and flags.get("entered_zhuwei_village") == true

func service_role(target: String) -> String:
	return String(_room_services.get(target, {}).get("service", ""))

func city_rows(field: Node, world: Node2D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	if scene == null:
		return result
	for zone: ExitZone in field.get("_exit_nodes"):
		if not is_instance_valid(zone) or zone.is_queued_for_deletion() or not zone.is_visible_in_tree():
			continue
		var endpoint: Dictionary = zone.get_meta("citynav_endpoint", {})
		var target: String = zone.target_scene_id
		var role: String = service_role(target)
		var kind: String = role if not role.is_empty() else ("exit" if not endpoint.is_empty() or zone.action == "world_map" or target in LUOYANG_AREAS or WORLD_CATEGORIES.has(target) or target in WORLDS else "")
		if kind.is_empty():
			continue # Ordinary building doors are deliberately not map markers.
		var foot: Vector2 = world.to_local(zone.global_position)
		var key: String = "exit:" + str(zone.get_instance_id())
		result.append({"id":key, "kind":kind, "foot":foot, "target":target, "visited":true, "outward":endpoint.get("outward", Vector2.DOWN)})
	for row: Dictionary in SERVICES.active_actor_markers(field, world, _room_services):
		var role: String = String(row.get("service", ""))
		if not role.is_empty():
			result.append({"id":String(row.id), "kind":role, "foot":row.foot, "target":String(scene.scene_id), "visited":true})
	for actor: NPCNode in field.get("_npc_nodes"):
		if not is_instance_valid(actor) or not actor.is_visible_in_tree() or not SHOP_ACTIONS.has(actor.interaction_action):
			continue
		var role: String = String(SHOP_ACTIONS[actor.interaction_action])
		result.append({"id":"shop:" + actor.npc_id, "kind":role, "foot":world.to_local(actor.global_position), "target":"", "visited":true})
	return result

func world_rows(field: Node, world: Node2D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen: Dictionary = {}
	var mini: Control = field.get("_world_travel_minimap") as Control
	# The configured map retains authored targets even when a locked ExitZone
	# intentionally clears target_scene_id. Unvisited/locked landmarks stay gray,
	# rather than vanishing from the atlas because they cannot yet be entered.
	if is_instance_valid(mini):
		var extent: Vector2 = mini.get("_world_size")
		var authored: Array = (mini.get("_portals") as Array).duplicate(true)
		for child_name: String in ["ThreeTownPips", "AdventureWorldPips31f"]:
			var pips: Node = mini.get_node_or_null(NodePath(child_name))
			if is_instance_valid(pips) and pips.has_method("get_debug_state"):
				var information: Dictionary = pips.call("get_debug_state")
				authored.append_array(information.get("portals", []))
		for row: Dictionary in authored:
			var target: String = String(row.get("target_scene", ""))
			var foot: Vector2 = row.get("world_foot", row.get("uv", row.get("pos", Vector2.ZERO)) * extent)
			if target.is_empty() or target in WORLDS or seen.has(target) or not foot.is_finite():
				continue
			seen[target] = true
			result.append({"id":target, "kind":String(WORLD_CATEGORIES.get(target, "outskirts")), "foot":foot, "target":target, "visited":visited(target)})
	for zone: ExitZone in field.get("_exit_nodes"):
		if not is_instance_valid(zone) or zone.is_queued_for_deletion() or not zone.is_visible_in_tree():
			continue
		var target: String = zone.target_scene_id
		if target.is_empty() or target in WORLDS or seen.has(target):
			continue
		seen[target] = true
		result.append({"id":target, "kind":String(WORLD_CATEGORIES.get(target, "outskirts")), "foot":world.to_local(zone.global_position), "target":target, "visited":visited(target)})
	return result

func get_debug_state() -> Dictionary:
	var overlay: Node = _overlay.get_ref() as Node if _overlay != null else null
	return {"schema":"PURE_MAP_ICONS_20261102C_V1", "label_changes":_label_changes, "visit_flags_written_on_success":_visit_writes, "visit_namespace":VISIT_PREFIX, "ordinary_building_markers":false, "icon_backplates":false, "icon_text":false, "source_or_save_file_writes":0, "overlay":overlay.call("get_debug_state") if is_instance_valid(overlay) else {}}
