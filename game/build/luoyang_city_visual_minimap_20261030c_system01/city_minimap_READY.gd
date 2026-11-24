extends "res://build/luoyang_city_visual_minimap_20261030c_system01/legacy_marker_layout_snapshot.gd"
## Existing local HUD/portals/marker with a one-shot real scene thumbnail.
const VisualCache = preload("res://build/luoyang_city_visual_minimap_20261030c_system01/visual_cache.gd")
var _visual_cache: Node
var _visible_model_roads := 0
var _visible_model_buildings := 0

func _build_plan() -> void:
	super._build_plan()
	_visible_model_roads = _plan.roads.size(); _visible_model_buildings = _plan.buildings.size()
	# Keep only real portal glyphs in the old retained draw layer. Its abstract
	# road/entity colors must not cover the actual textured city image.
	_plan.roads.clear(); _plan.buildings.clear()
	if is_instance_valid(_visual_cache):
		remove_child(_visual_cache); _visual_cache.queue_free()
	_visual_cache = VisualCache.new(); _visual_cache.name = "CityVisualThumbnail"
	add_child(_visual_cache)
	var world: Node2D = _world.get_ref() as Node2D
	var native: Variant = _native.get_ref() if _native != null else null
	var source: Node = native.get("hall") as Node if is_instance_valid(native) and bool(native.get("in_hall")) else world
	_plan.base_texture = _visual_cache.call("configure", world, source, _world_size, _world_origin, _compiled) as Texture2D
	_plan.queue_redraw()

func configure(field: Node, scene: SceneScript, player: Node2D, camera: Camera2D, world: Node2D, compiled: Dictionary = {}) -> bool:
	var ok: bool = super.configure(field, scene, player, camera, world, compiled)
	if ok and is_instance_valid(_visual_cache):
		# The original Xiangzhou-only static background fallback runs after the
		# virtual build hook. Keep the cache as the final texture in every city.
		_plan.base_texture = _visual_cache.call("get_texture") as Texture2D
		_plan.queue_redraw()
	return ok

func update_view() -> void:
	super.update_view()
	if is_instance_valid(_visual_cache):
		var ready: bool = bool(_visual_cache.get("capture_ready"))
		if is_instance_valid(_plan): _plan.visible = ready
		if is_instance_valid(_marker): _marker.visible = ready

func get_debug_state() -> Dictionary:
	var state: Dictionary = super.get_debug_state()
	var cache: Dictionary = _visual_cache.call("get_debug_state") if is_instance_valid(_visual_cache) else {}
	state["visual_cache"] = cache
	state["visual_cache_ready"] = bool(cache.get("ready", false))
	state["cache_render_requests"] = int(cache.get("render_requests", 0))
	state["road_count"] = _visible_model_roads
	state["building_count"] = _visible_model_buildings
	state["render_mode"] = "ONE_SHOT_REAL_SCENE_TEXTURE"
	return state
