extends "res://build/scene_quality_20261102c_qa01/NEW_DOMAIN_ROOT_ONLY.gd"
## Inherit original 35-second readiness oracle and early save suspension.
## One exact public near request, never default-bootstrap an already loaded map.
## Original 34956 Civic/Docks accepted prefix is not rerun or counted here.
func near_legacy(id: String, point: Vector2) -> Node:
	var size: Vector2 = geometry.call("size_for", id)
	if not need(size.x > 0 and size.y > 0, "EXACT_PUBLIC_NEAR_SIZE:" + id): return null
	if not need(router.call("go_field_smart", StringName(id), point / size, "", -1, 3) == true, "SINGLE_ABSOLUTE_PUBLIC_NEAR:" + id): return null
	var field: Node = await wait_field(id)
	if field != null: need(foot(field).distance_to(point) < .05, "SINGLE_PUBLIC_NEAR_EXACT_FOOT:" + id)
	return field

func diagnostic() -> Dictionary:
	var actual: Dictionary = super.diagnostic()
	var screen: Node = prop(loader, "_screen") as Node
	var events: Variant = prop(screen, "_barrier_events", [])
	actual["screen_barrier_events"] = events.duplicate(true) if events is Array else []
	actual["public_city_preparation"] = router.call("get_public_city_preparation_state") if is_instance_valid(router) and router.has_method("get_public_city_preparation_state") else {}
	return actual

func bind_residual(scope: String) -> bool:
	if not need(suspended, "EARLY_CHECKPOINT_SUSPEND"): return false
	router = root.get_node("SceneRouter"); nav = root.get_node("CityNavigationRuntime"); icons = root.get_node("MapIconRuntime"); loader = root.get_node("LoadingManager")
	pairs = load(PAIRS) as GDScript; geometry = load(GEO) as GDScript
	if not need(geometry.call("load_fixed") == true, "ORIGINAL_IMMUTABLE_GEOMETRY_READY"): return false
	records.append({"residual_scope":scope,"inherited_prefix_actual":34956,"inherited_passed_checks_not_recounted":27,"inherited_normal_images_not_repeated":2,"default_bootstraps":0,"private_state_writes":false})
	return true
