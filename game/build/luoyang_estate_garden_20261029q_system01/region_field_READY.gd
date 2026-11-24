extends "res://build/luoyang_regions_20261027d_source01/base_field_business_snapshot01.gd"
## Reuses existing HUD, Player, real DialogPlayer/QuestManager and Shop actions.
## It does NOT call the old _setup_scene with an invented legacy Scene identity.
const RegionCompiler = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const HallBoundary = preload("res://build/luoyang_hall_boundary_20261029p_system01/hall_boundary.gd")
const GardenVisual = preload("res://build/luoyang_estate_garden_20261029q_system01/garden_visual.gd")
const RegionAlias = preload("res://build/luoyang_regions_20261027d_source01/legacy_alias.gd")
const RegionOwner = preload("res://build/luoyang_regions_20261027d_source01/region_session.gd")
const RegionEntry = preload("res://build/luoyang_regions_20261027d_source01/region_entry.gd")
const RegionChildren = preload("res://build/luoyang_city_rectification_20261027d_system01/region_render_auxiliary.gd")
const RegionActorVisuals = preload("res://build/luoyang_regions_20261027d_source01/region_actor_visuals.gd")
const YihongLayers = preload("res://build/luoyang_yihongyuan_20261029n_system01/native_layers.gd")
const YihongDaily = preload("res://build/luoyang_yihongyuan_20261029n_system01/ambient_conversation.gd")
var _yihong_daily: RefCounted = YihongDaily.new()
var _region: Dictionary = {}
var _region_owner: RefCounted
var _region_scene: SceneScript
var _region_sources: Dictionary = {}
var _region_entry: Vector2 = Vector2(INF, INF)
var _region_visuals: Dictionary = {}
var _region_actors: Dictionary = {}
var _region_portals: Dictionary = {}
var _region_busy: bool = false
var _region_phase_projector: Callable
var _region_phase_owner: RefCounted
var _region_chunk_clock: float = 0.0
var _region_refresh_pending: bool = false
var _region_phase_queued: bool = false
var _region_logical_contexts: Dictionary = {}
var _region_logic: RefCounted
var _region_logical_id: String = ""
var _region_visual_state: Dictionary = {}
var _region_initial_phase: Dictionary = {}

func _ready() -> void:
	# Deliberately do not run the legacy _ready tail: it publishes scene_entered
	# even after a non-progressive setup failure and assumes one physical/logical ID.
	var started: Dictionary = _field_loading_profile_clock()
	_init_ui_canvas_layers()
	EventBus.flag_set.connect(_on_flag_set)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.reputation_changed.connect(_on_reputation_changed)
	EventBus.dialog_started.connect(_on_dialog_started)
	EventBus.dialog_ended.connect(_on_dialog_ended)
	DialogPlayer.text_displayed.connect(_on_region_text_displayed)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.skill_learned.connect(_on_skill_learned)
	EventBus.companion_joined.connect(_on_companion_joined)
	EventBus.dialog_spar_requested.connect(_on_dialog_spar_requested)
	EventBus.field_cutscene_requested.connect(_on_field_cutscene_requested)
	EventBus.equipment_changed.connect(_on_field_equipment_changed)
	EventBus.weather_changed.connect(_on_weather_changed)
	EventBus.ui_requested.connect(_on_ui_requested)
	EventBus.toast_requested.connect(_show_toast)
	QuestManager.active_quests_changed.connect(_on_active_quests_changed)
	QuestManager.tracked_quest_changed.connect(_on_tracked_quest_changed)
	EventBus.quest_accepted.connect(_on_quest_accepted)
	EventBus.quest_progressed.connect(_on_quest_progressed)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.evidence_acquired.connect(_on_evidence_acquired)
	quest_log_btn.pressed.connect(_on_quest_log_pressed)
	inventory_btn.pressed.connect(_toggle_inventory_panel)
	equipment_btn.pressed.connect(_toggle_equipment_panel)
	skill_btn.pressed.connect(_toggle_skill_panel)
	system_btn.pressed.connect(_open_system_menu)
	_init_m5_panels(); _init_sparring_confirmation(); _init_field_ui_styles()
	_init_formal_hud(); _apply_formal_hud_mode(); _disable_gameplay_button_focus(self)
	_field_loading_ui_profile = _field_loading_profile_span(started, _field_loading_profile_clock())
	var payload: Dictionary = SceneRouter.get_field_payload()
	_current_scene = _load_scene(StringName(payload.get("scene_id", "")))
	if _current_scene == null: _region_fail("REGION_REQUEST_NOT_AVAILABLE"); return
	await _setup_scene(_current_scene)
	if not is_inside_tree() or _field_loading_failed or not _field_loading_complete: return
	_refresh_gold(); _refresh_quest_panel()
	var pending: String = SceneRouter.take_pending_field_action()
	if not pending.is_empty(): SceneRouter.resolve_action(pending)

func adopt_compiled(compiled: Dictionary, declared_sources: Dictionary, entry: Vector2, phase_projector: Callable, logical_contexts: Dictionary = {}, business_bridge: RefCounted = null) -> bool:
	# Called once by the Router candidate before source FIRST and actor creation.
	if not _region.is_empty() or not compiled.get("ok", false) or not phase_projector.is_valid(): return false
	var phase_owner: RefCounted = phase_projector.get_object() as RefCounted
	if phase_owner == null or phase_owner.get_script() == null or phase_owner.get_script().resource_path != "res://build/luoyang_regions_20261027d_source01/region_phase_scope.gd" or phase_projector.get_method() != &"project": return false
	if not RegionCompiler.safe_body(compiled, entry, Vector2(17, 12)): return false
	_region = compiled.duplicate(true); _region_sources = declared_sources.duplicate(true); _region_entry = entry; _region_phase_projector = phase_projector
	_region_phase_owner = phase_owner
	_region_logical_contexts = logical_contexts.duplicate(true); _region_logic = business_bridge
	return true

func _load_scene(_legacy_id: StringName) -> SceneScript:
	if _region.is_empty() and not RegionEntry.take_setup(self): return null
	var path: String = String(RegionEntry.SCENE_RESOURCES.get(_region.id, ""))
	if path.is_empty() or not _region_sources.has(path): return null
	_region_scene = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if _region_scene == null or String(_region_scene.scene_id) != _region.id or _region_scene.map_layout == null or Vector2(_region_scene.map_layout.design_size) != _region.size: return null
	return _region_scene

func _setup_scene(scene: SceneScript, _spawn: Variant = null, _progressive: bool = false) -> void:
	_scene_rebuilding = true; _field_loading_failed = false
	_region_owner = RegionOwner.new()
	if not _region_owner.begin(self, scene, _region, _region_sources): _region_fail("REGION_FIRST"); return
	if _region_logic == null or not _region_logic.has_method("attach") or not _region_logic.call("attach", self, _region_owner, _region_logical_contexts): _region_fail("REGION_LOGICAL_CONTEXT"); return
	_world_size = _region.size; _screen_size = _world_size
	_viewport_size = get_viewport_rect().size; _camera_zoom = 1.0; _camera_scroll_enabled = true
	_world_origin = Vector2.ZERO; world_container.position = Vector2.ZERO
	_visual_layer = Node2D.new(); _visual_layer.name = "RegionVisuals"; world_container.add_child(_visual_layer)
	_actor_layer = Node2D.new(); _actor_layer.name = "RegionActors"; world_container.add_child(_actor_layer)
	_portal_layer = Node2D.new(); _portal_layer.name = "RegionPortals"; world_container.add_child(_portal_layer)
	_collision_layer = Node2D.new(); _collision_layer.name = "RegionBodies"; world_container.add_child(_collision_layer)
	_interaction_layer = Node2D.new(); _interaction_layer.name = "RegionInteractions"; world_container.add_child(_interaction_layer)
	_foreground_layer = Node2D.new(); world_container.add_child(_foreground_layer)
	# All static collision is resident in phase one. Visual chunks alone unload.
	for polygon: PackedVector2Array in _region.solids:
		var body := StaticBody2D.new(); body.collision_layer = 1; body.collision_mask = 0
		var shape := CollisionPolygon2D.new(); shape.polygon = polygon
		body.add_child(shape); _collision_layer.add_child(body)
	_spawn_map_bounds()
	if not _draw_region_surfaces(): _region_fail("REGION_SURFACE_SOURCE"); return
	if not _draw_room_enclosure(): _region_fail("REGION_ROOM_ENCLOSURE"); return
	if not _spawn_region_actors(): _region_fail("REGION_ACTOR_PROJECTION"); return
	_spawn_region_doors()
	if _field_loading_failed: return
	if not _spawn_region_interactions(): _region_fail("REGION_INTERACTION_PROJECTION"); return
	if not _region_owner.finalize(self, scene, _region): _region_fail("REGION_FINAL"); return
	_spawn_player(_region_entry / _world_size)
	if not is_instance_valid(_player): _region_fail("REGION_PLAYER"); return
	_player.set_visual_scale_multiplier(1.12)
	_player.set_movement_constraint(_region_motion_constraint)
	_setup_world_camera()
	if HallBoundary.handles(_region) and not HallBoundary.camera(self, _region_owner, _region, _world_camera): _region_fail("HALL29P_CAMERA"); return
	_refresh_region_chunks(true)
	if _field_loading_failed: return # Never publish logical entry after a visual/source rejection.
	_snap_camera_to_player()
	_scene_rebuilding = false; _field_loading_complete = true; _field_loading_progress = 1.0
	_publish_region_navigation()

func _region_fail(reason: String) -> void:
	_field_loading_failed = true; _field_loading_complete = false; _scene_rebuilding = true
	if is_instance_valid(_player): _player.set_can_move(false)
	push_error("[Region27d] " + reason)

func _draw_region_surfaces() -> bool:
	if HallBoundary.handles(_region): return HallBoundary.floor(self, _region_owner, _region)
	if not _draw_region_underlay(): return false
	for row: Dictionary in _region.surfaces:
		var path: String = String(row.get("texture", ""))
		if path.is_empty() or not _region_sources.has(path): return false
		var texture: Texture2D = load(path) as Texture2D
		if texture == null: return false
		var area: Rect2 = RegionCompiler.rect(row.rect)
		var floor := Polygon2D.new(); floor.texture = texture; floor.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		floor.polygon = PackedVector2Array([area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)])
		var period: Vector2 = RegionCompiler.vec(row.get("period_px", [384, 256]))
		if not period.is_finite() or period.x <= 0 or period.y <= 0: return false
		var uv := PackedVector2Array()
		for point: Vector2 in floor.polygon: uv.append(point / period * texture.get_size())
		floor.uv = uv; floor.z_index = -1000; _visual_layer.add_child(floor)
	if GardenVisual.handles(_region): return GardenVisual.install(self, _region_owner, _region)
	return true

func _draw_region_underlay() -> bool:
	var descriptor: Dictionary = _region.get("visual_underlay", {})
	if descriptor.is_empty(): return true # Authored interiors keep their own floor.
	var path: String = String(descriptor.get("texture", ""))
	if descriptor.get("decorative_only") != true or descriptor.get("z_index") != -1100 or descriptor.get("source_sha256", {}).get(path) != _region_sources.get(path) or not _region_sources.has(path): return false
	var texture: Texture2D = load(path) as Texture2D
	var period: Vector2 = RegionCompiler.vec(descriptor.get("period_px"))
	if texture == null or not period.is_finite() or period.x <= 0 or period.y <= 0: return false
	var floor := Polygon2D.new(); floor.name = "RegionDecorativeUnderlay"
	floor.texture = texture; floor.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor.polygon = PackedVector2Array([Vector2.ZERO, Vector2(_world_size.x, 0), _world_size, Vector2(0, _world_size.y)])
	var uv := PackedVector2Array()
	for point: Vector2 in floor.polygon: uv.append(point / period * texture.get_size())
	floor.uv = uv; floor.z_index = -1100; _visual_layer.add_child(floor)
	return true

func _draw_room_enclosure() -> bool:
	if HallBoundary.handles(_region): return HallBoundary.enclosure(self, _region_owner, _region)
	if _region.get("navigation_kind") != "AUTHORED_INTERIOR": return true
	if _region.get("id") == "yihongyuan27n_interior": return YihongLayers.complete_room_enclosure(self, _region_owner, _region)
	var walls: Variant = _region.get("room_enclosure", {}).get("wall_ground_polygons_px")
	if not walls is Array or walls.is_empty(): return false
	var descriptor: Dictionary = _region.get("room_wall_material", {})
	var texture: Texture2D = load(String(descriptor.get("texture", ""))) as Texture2D
	var shader: Shader = load(String(descriptor.get("shader", ""))) as Shader
	if texture == null or shader == null or texture.get_size() != RegionCompiler.vec(descriptor.get("source_size_px")): return false
	for raw: Array in walls:
		var base := PackedVector2Array()
		for point: Variant in raw:
			var value: Vector2 = RegionCompiler.vec(point)
			if not value.is_finite(): return false
			base.append(value)
		if base.size() != 4: return false
		# The visible face is a 96px extrusion of the actual authored wall base,
		# not a whole-building PNG stretched over a different collision footprint.
		var face := Polygon2D.new()
		face.polygon = PackedVector2Array([base[3], base[2], base[2] - Vector2(0, 96), base[3] - Vector2(0, 96)])
		face.texture = texture
		face.uv = PackedVector2Array([Vector2(0, 96), Vector2(base[2].distance_to(base[3]), 96), Vector2(base[2].distance_to(base[3]), 0), Vector2.ZERO])
		face.material = _room_patch_material(shader, descriptor, "wall_patch_px")
		if face.material == null: return false
		face.z_index = clampi(floori(maxf(base[2].y, base[3].y) / 8.0), 0, 4095)
		_visual_layer.add_child(face)
		var cap := Polygon2D.new()
		var raised := PackedVector2Array()
		for point: Vector2 in base: raised.append(point - Vector2(0, 96))
		cap.polygon = raised; cap.texture = texture
		cap.uv = base.duplicate()
		cap.material = _room_patch_material(shader, descriptor, "cap_patch_px")
		if cap.material == null: return false
		cap.z_index = face.z_index; _visual_layer.add_child(cap)
	return true

func _room_patch_material(shader: Shader, descriptor: Dictionary, key: String) -> ShaderMaterial:
	var patch: Rect2 = RegionCompiler.rect(descriptor.get(key))
	var dimensions: Vector2 = RegionCompiler.vec(descriptor.get("source_size_px"))
	if patch.size.x <= 0 or patch.size.y <= 0 or not Rect2(Vector2.ZERO, dimensions).encloses(patch): return null
	var material := ShaderMaterial.new(); material.shader = shader
	material.set_shader_parameter("patch_origin_px", patch.position)
	material.set_shader_parameter("patch_size_px", patch.size)
	material.set_shader_parameter("source_size_px", dimensions)
	return material

func _spawn_region_actors() -> bool:
	var initial: Variant = _region_phase_projector.call(GameState.flags.duplicate(true), QuestManager.states.duplicate(true))
	if not initial is Dictionary or initial.get("ok") != true: return false
	_region_initial_phase = initial.duplicate(true)
	var slots: Dictionary = initial.get("actor_slots", {})
	var active_ids: Dictionary = {}
	for source: Dictionary in _region.npcs:
		var active: bool = bool(source.get("default_active", true))
		var phase: Dictionary = slots.get(source.slot_key, {})
		if phase.has("active"): active = phase.active == true
		if not active: continue
		if active_ids.has(source.data.npc_id): return false
		active_ids[source.data.npc_id] = true
		if not _create_region_actor(source, phase.get("data", source.data)): return false
	return true

func _create_region_actor(source: Dictionary, data: Dictionary) -> bool:
	if data.get("npc_id") != source.data.npc_id: return false
	var visual: Dictionary = RegionActorVisuals.actor_data(source, data, _region_owner.receipt().source_first)
	if visual.get("ok") != true: return false
	data = visual.data
	if data.get("movement_mode", "idle") == "patrol":
		var axis: Vector2 = data.get("patrol_axis", Vector2.RIGHT)
		var distance: float = float(data.get("patrol_distance", 0))
		if not axis.is_finite() or axis.is_zero_approx() or not is_finite(distance) or distance < 0: return false
		axis = axis.normalized() * distance # Same range equation as NPCNode.
		var center: Vector2 = source.foot + source.get("body_offset_px", Vector2.ZERO)
		if not RegionCompiler.safe_segment(_region, center - axis, center + axis, source.get("half_body", Vector2(17, 15))): return false
	var npc: NPCNode = NPC_SCENE.instantiate() as NPCNode
	if npc == null: return false
	var mapping: Dictionary = {"npc_id":"npc_id", "npc_name":"npc_name", "dialog_id":"dialog_id", "interaction_action":"interaction_action", "portrait_path":"portrait_path", "sprite_path":"sprite_path", "walk_sprite_path":"walk_sprite_path", "scale":"sprite_scale", "movement_mode":"movement_mode", "patrol_axis":"patrol_axis", "patrol_distance":"patrol_distance", "patrol_speed":"patrol_speed", "invert_patrol_facing":"invert_patrol_facing", "idle_frame_seconds":"idle_frame_seconds", "walk_frame_seconds":"walk_frame_seconds", "conversation_base_facing":"conversation_base_facing", "conversation_sprite_paths":"conversation_sprite_paths"}
	for key: String in mapping:
		if data.has(key): npc.set(mapping[key], data[key])
	npc.dialog_variants.assign(data.get("dialog_variants", []))
	npc.position = source.foot + source.get("node_origin_offset_px", Vector2.ZERO)
	npc.set_meta("region27d_logical_id", source.logical_id); npc.set_meta("region27d_slot_key", source.slot_key)
	npc.set_ground_anchored(bool(source.get("ground_anchored", true)))
	# Catalog/scale/media/calibration are settled BEFORE NPCNode._ready snapshots
	# its origin and creates the original body. No post-ready body resizing.
	if _region_logic == null or not _region_logic.has_method("configure_actor_before_ready"):
		npc.free(); return false
	var phase_source: Dictionary = source.duplicate(true)
	phase_source.data = data.duplicate(true)
	var configured: Variant = _region_logic.call("configure_actor_before_ready", npc, phase_source)
	if not configured is Dictionary or configured.get("ok") != true:
		npc.free(); return false
	_actor_layer.add_child(npc); _npc_nodes.append(npc)
	_region_actors[source.slot_key] = {"node": npc, "source": source, "parked": false, "process_mode": npc.process_mode}
	npc.npc_interacted.connect(_on_npc_interacted); npc.npc_action_requested.connect(_on_npc_action_requested)
	npc.interact_area.input_pickable = false
	_update_actor_depth(npc)
	return true

func _spawn_region_doors() -> void:
	for row: Dictionary in _region.portals:
		var data: Dictionary = row.get("data", row).duplicate(true)
		data.pos = row.foot / _world_size
		data["source_spawn_pos"] = row.foot / _world_size
		data["size"] = row.get("size_px", Vector2(48, 40)) / _world_size
		var before: int = _exit_nodes.size(); _spawn_exits([data])
		if _exit_nodes.size() == before + 1:
			var zone: ExitZone = _exit_nodes.back()
			# BaseField selects this existing callable-based ExitZone for an explicit
			# source_spawn_pos. Bind the real NEW owner/feet, not the old local-field
			# clearance helper. It does not acquire or impersonate an old owner.
			if not zone.has_method("configure_feet"): _region_fail("REGION_PORTAL_FEET_API"); return
			zone.call("configure_feet", Rect2(data.pos - data.size * .5, data.size), _region_source_foot_uv, _region_door_clearance)
			_region_portals[zone.get_instance_id()] = row

func _region_source_foot_uv() -> Vector2:
	return _player.position / _world_size if is_instance_valid(_player) else Vector2(INF, INF)

func _region_door_clearance(uv: Vector2) -> bool:
	return _region_owner != null and uv.is_finite() and _region_owner.safe_foot(self, _current_scene, uv * _world_size)

func _spawn_region_interactions() -> bool:
	var changes: Dictionary = _region_initial_phase.get("interactions", {})
	for key: String in changes:
		if _region.interactions.filter(func(row: Dictionary) -> bool: return row.key == key).size() != 1: return false
		for property: String in changes[key]:
			if property not in ["active", "action", "require_flag", "hide_flag", "require_quest_active", "require_quest_completed"]: return false
	for row: Dictionary in _region.interactions:
		var change: Dictionary = changes.get(row.key, {})
		if change.get("active", row.get("default_active", true)) != true: continue
		var data: Dictionary = row.get("data", row).duplicate(true)
		data.merge(change, true); data.erase("active")
		data.pos = row.foot / _world_size
		# Preserve source action/flags/activation, but never reinterpret old UV size
		# against the new region dimensions.
		data.size = row.get("size_px", Vector2(76, 40)) / _world_size
		data["id"] = row.key
		if not _install_region_trigger(row, data): return false
	for key: String in _region_initial_phase.get("dynamic_visual_state", {}):
		if _region.render.filter(func(row: Dictionary) -> bool: return row.key == key).size() != 1: return false
		var active: Variant = _region_initial_phase.dynamic_visual_state[key]
		if not active is bool: return false
		_region_visual_state[key] = active
	_region_initial_phase.clear()
	return true

func _install_region_trigger(source: Dictionary, data: Dictionary) -> bool:
	var before: int = _trigger_areas.size()
	_spawn_trigger_zones([data])
	if _trigger_areas.size() == before: return true # Original flag/Quest gates.
	if _trigger_areas.size() != before + 1: return false
	var area: Area2D = _trigger_areas.back()
	area.set_meta("region27d_logical_id", source.logical_id)
	if data.has("city_v3_interaction_polygon_px"):
		var polygon: Variant = data.city_v3_interaction_polygon_px
		if not polygon is PackedVector2Array or polygon.size() < 3: return false
		var original: CollisionShape2D = area.get_child(0) as CollisionShape2D
		if original == null: return false
		original.disabled = true
		var shape := CollisionPolygon2D.new()
		var local := PackedVector2Array()
		for point: Vector2 in polygon: local.append(point - source.foot)
		shape.polygon = local; area.add_child(shape)
	return true

func _region_motion_constraint(next_origin: Vector2) -> bool:
	if _region_owner == null or not _region_owner.matches(self, _current_scene) or not is_instance_valid(_player): return false
	return RegionCompiler.safe_segment(_region, _player.position, next_origin, Vector2(17, 12))

func _process(delta: float) -> void:
	super._process(delta)
	if not _field_loading_complete or not is_instance_valid(_player): return
	_region_chunk_clock += delta
	if _region_chunk_clock >= 0.15:
		_region_chunk_clock = 0.0; _refresh_region_chunks(false)

func _refresh_region_chunks(force: bool) -> void:
	if not is_instance_valid(_player): return
	var visible := Rect2(_player.position - _viewport_size * 0.5, _viewport_size).grow(512)
	for row: Dictionary in _region.render:
		var key: String = row.key
		var texture_size: Vector2 = row.get("texture_size_px", Vector2.ZERO)
		var top: Vector2 = row.position_px - texture_size * row.scale * (0.5 if row.get("centered", true) else 0.0)
		var area := Rect2(top, texture_size * row.scale)
		if area.intersects(visible):
			if not _region_visuals.has(key):
				var path: String = String(row.texture)
				if not _region_sources.has(path): _region_fail("UNDECLARED_TEXTURE:" + path); return
				var sprite := Sprite2D.new(); sprite.texture = load(path) as Texture2D
				if sprite.texture == null: _region_fail("TEXTURE:" + path); return
				sprite.position = row.position_px; sprite.scale = row.scale; sprite.centered = bool(row.get("centered", true))
				var original: Dictionary = row.get("source_row", {})
				sprite.z_index = clampi(floori(row.foot_px.y / 8.0), 0, 4095) if original.get("sort_by_feet", true) else int(original.get("z_index", 0))
				if original.get("modulate") is Color: sprite.modulate = original.modulate
				_visual_layer.add_child(sprite); _region_visuals[key] = sprite
				if not RegionChildren.install(self, _region_owner, row, sprite): _region_fail("SOURCE_DOOR_DEPTH_CHILD:" + key); return
				if not YihongLayers.install(self, _region_owner, row, sprite): _region_fail("YIHONG_NATIVE_DEPTH:" + key); return
				if _region_visual_state.has(key): sprite.visible = _region_visual_state[key]
		elif _region_visuals.has(key):
			_region_visuals[key].queue_free(); _region_visuals.erase(key)
	# Phase one only unloads visual props. NPCs and all bodies remain resident.
	# No NPC may be parked while a Shop/Dialog/battle session still owns it.

func _on_player_moved(_global_pos: Vector2) -> void:
	if _scene_rebuilding or not is_instance_valid(_player): return
	_update_actor_depth(_player)
	_publish_region_navigation()

func _publish_region_navigation() -> void:
	if not is_instance_valid(_player): return
	var navigation: Dictionary = RegionAlias.navigation(_region, _player.position)
	if navigation.get("ok") != true: _region_fail("REGION_NAVIGATION_SAVE"); return
	# This explicit Router API is introduced by the companion candidate, not set().
	SceneRouter.call("commit_region27d_navigation", navigation)
	if _region_logical_id != navigation.current_field:
		_region_logical_id = navigation.current_field
		_enter_logical_district(_region_logical_id)

func _enter_logical_district(logical_id: String) -> void:
	if _region_logic == null or not _region_logic.has_method("source_scene"): _region_fail("LOGICAL_SOURCE_SCENE_API"); return
	var source_id: String = String(_region.get("room_source_logical_id", logical_id))
	var source: SceneScript = _region_logic.call("source_scene", source_id) as SceneScript
	if source == null or String(source.scene_id) != source_id: _region_fail("LOGICAL_SOURCE_SCENE"); return
	var display_name: String = _current_scene.display_name if _region.get("navigation_kind") == "AUTHORED_INTERIOR" else String(_region.get("hud_display_names", {}).get(source_id, source.display_name))
	if scene_title != null: scene_title.text = display_name
	if _primary_hud != null: _primary_hud.set_scene_info(display_name)
	EventBus.scene_entered.emit(StringName(logical_id))
	if _region.get("navigation_kind") == "AUTHORED_INTERIOR":
		# Actual room navigation remains distinct from the resident's business ID.
		# Reuse its authored BGM, not a nonexistent old Scene path for this new ID.
		AudioManager.play_bgm(source.bgm_path, .18, logical_id)
		_clear_active_weather()
		return
	AudioManager.ensure_bgm_for_scene(StringName(logical_id))
	_spawn_active_weather(source)
	if _should_play_enter_dialog(source):
		_mark_enter_dialog_played(source)
		_player.set_can_move(false)
		DialogPlayer.play(source.on_enter_dialog)

func _on_weather_changed(_weather_id: StringName, _strength: float) -> void:
	if _region_logical_id.is_empty() or _region_logic == null: return
	if _region.get("navigation_kind") == "AUTHORED_INTERIOR": _clear_active_weather(); return
	var source: SceneScript = _region_logic.call("source_scene", _region_logical_id) as SceneScript
	if source != null: _spawn_active_weather(source)

func _on_exit_triggered(target_scene: String, target_pos: Vector2, source_portal_spawn: Vector2) -> void:
	if not is_instance_valid(_player): return
	var foot: Vector2 = source_portal_spawn * _world_size
	var matches: Array = _region.portals.filter(func(row: Dictionary) -> bool: return row.foot == foot and row.get("data", row).get("target_scene", "") == target_scene)
	if matches.size() != 1: _region_fail("UNIQUE_EXTERNAL_DOOR"); return
	var door: Dictionary = matches[0]
	if not RegionCompiler.safe_body(_region, _player.position, Vector2(17, 12)): return
	_publish_region_navigation()
	SceneRouter.call("go_from_region27d_portal", door.logical_id, String(door.id), target_scene, target_pos, door.legacy_source_uv)

func _refresh_scene_preserving_player() -> void:
	# Dialog/Quest changes update declared dynamic rows, never static terrain.
	if _region.is_empty(): return
	if _scene_rebuilding or not _field_loading_complete:
		_region_refresh_pending = true; return
	if DialogPlayer.is_playing() or _region_busy:
		_region_refresh_pending = true; _scene_refresh_pending = true; return
	if _region_phase_queued: return
	_region_phase_queued = true
	_apply_region_phase.call_deferred()

func _apply_region_phase() -> void:
	_region_phase_queued = false
	if not is_inside_tree() or _field_loading_failed: return
	if DialogPlayer.is_playing() or _region_busy:
		_region_refresh_pending = true; _scene_refresh_pending = true; return
	if _region_owner == null or not _region_owner.revalidate_boundary(self, _current_scene, _region): _region_fail("DYNAMIC_BOUNDARY_SOURCE"); return
	var projected: Variant = _region_phase_projector.call(GameState.flags.duplicate(true), QuestManager.states.duplicate(true))
	if not projected is Dictionary or projected.get("ok") != true: _region_fail("DYNAMIC_PHASE_PROJECTION"); return
	# The projector returns only NPC dialog/action/variants and interaction flags.
	var slots: Dictionary = projected.get("actor_slots", {})
	var declared: Dictionary = {}
	var active_ids: Dictionary = {}
	for source: Dictionary in _region.npcs: declared[source.slot_key] = source
	for key: String in slots:
		if not declared.has(key): _region_fail("UNDECLARED_DYNAMIC_ACTOR_SLOT"); return
	# Plan all removals before births so one cultural hand-off never duplicates ID.
	for key: String in declared:
		var source: Dictionary = declared[key]
		var active: bool = slots.get(key, {}).get("active", source.get("default_active", true)) == true
		if active:
			if active_ids.has(source.data.npc_id): _region_fail("DYNAMIC_DUPLICATE_ACTOR_ID"); return
			active_ids[source.data.npc_id] = true
	for key: String in _region_actors.keys():
		if slots.has(key) and slots[key].get("active") == false:
			var source: Dictionary = declared[key]
			var npc: NPCNode = _region_actors[key].node
			npc.interact_area.monitoring = false; npc.interact_area.monitorable = false; npc.visible = false
			_npc_nodes.erase(npc); _region_actors.erase(key); npc.free()
	for key: String in slots:
		if slots[key].get("active") == true and not _region_actors.has(key):
			var source: Dictionary = declared[key]
			if not _create_region_actor(source, slots[key].get("data", source.data)): _region_fail("DYNAMIC_ACTOR_BIRTH"); return
	for id: String in projected.get("npcs", {}):
		if not declared.has(id): _region_fail("DYNAMIC_UNKNOWN_ACTOR:" + id); return
		if not _region_actors.has(id): continue # Inactive declared slots own no body/Area.
		var npc: NPCNode = _region_actors[id].node
		var row: Dictionary = projected.npcs[id]
		for key: String in row:
			if key not in ["dialog_id", "interaction_action", "dialog_variants"]: _region_fail("DYNAMIC_STATIC_FIELD:" + key); return
		if row.has("dialog_id"): npc.dialog_id = row.dialog_id
		if row.has("interaction_action"): npc.interaction_action = row.interaction_action
		if row.has("dialog_variants"): npc.dialog_variants.assign(row.dialog_variants)
		if slots.has(id) and slots[id].get("data") is Dictionary:
			if not _region_logic.call("update_actor_primary", npc, slots[id].data): _region_fail("DYNAMIC_PRIMARY_SOURCE"); return
	# Interaction phase projection can only alter declared task availability and
	# action. Geometry, source logical owner and exact authored foot are immutable.
	var interaction_changes: Dictionary = projected.get("interactions", {})
	for key: String in interaction_changes:
		var originals: Array = _region.interactions.filter(func(row: Dictionary) -> bool: return row.key == key)
		if originals.size() != 1: _region_fail("DYNAMIC_UNKNOWN_INTERACTION:" + key); return
		var row: Dictionary = interaction_changes[key]
		for property: String in row:
			if property not in ["active", "action", "require_flag", "hide_flag", "require_quest_active", "require_quest_completed"]: _region_fail("DYNAMIC_INTERACTION_GEOMETRY"); return
	if not interaction_changes.is_empty():
		# Only task Areas are replaced after physics synchronization. Static floor,
		# collision, sprites, actors, camera and Player are the same objects.
		for area: Area2D in _trigger_areas:
			area.monitoring = false; area.monitorable = false; area.queue_free()
		_trigger_areas.clear()
		for source: Dictionary in _region.interactions:
			var change: Dictionary = interaction_changes.get(source.key, {})
			if change.get("active", source.get("default_active", true)) != true: continue
			var data: Dictionary = source.get("data", source).duplicate(true)
			data.merge(change, true); data.erase("active")
			data.pos = source.foot / _world_size; data.size = source.get("size_px", Vector2(76, 40)) / _world_size; data.id = source.key
			if not _install_region_trigger(source, data): _region_fail("DYNAMIC_INTERACTION_POLYGON"); return
	for key: String in projected.get("dynamic_visual_state", {}):
		if _region.render.filter(func(row: Dictionary) -> bool: return row.key == key).size() != 1: _region_fail("DYNAMIC_UNKNOWN_VISUAL"); return
		var visible: Variant = projected.dynamic_visual_state[key]
		if not visible is bool: _region_fail("DYNAMIC_VISUAL_TYPE"); return
		_region_visual_state[key] = visible
		if _region_visuals.has(key): _region_visuals[key].visible = visible
	_region_refresh_pending = false
	_scene_refresh_pending = false

func _scene_depth_band_max() -> int:
	return 1024

func get_region27d_state() -> Dictionary:
	return {"id": _region.get("id", ""), "owner": _region_owner.receipt() if _region_owner != null else {}, "visual_chunks": _region_visuals.size(), "static_bodies_resident": true, "logical_id": RegionAlias.district_at(_region, _player.position) if is_instance_valid(_player) else "", "ready": _field_loading_complete}

func terminal_by_logical_id() -> Dictionary:
	return _region_logical_contexts.duplicate(true)

func region_session_handle() -> RefCounted:
	return _region_owner

func region_physical_scene() -> SceneScript:
	return _region_scene

func _region_actor(id: String) -> Node:
	var matches: Array = _region_actors.values().filter(func(row: Dictionary) -> bool: return row.source.data.npc_id == id)
	return matches[0].node if matches.size() == 1 else null

func _current_player_spawn() -> Vector2:
	# Legacy modal/battle callers use this UV as an OLD logical save coordinate.
	# Exact region position is committed separately, never normalized into that slot.
	if not is_instance_valid(_player): return Vector2(INF, INF)
	var navigation: Dictionary = RegionAlias.navigation(_region, _player.position)
	return navigation.current_field_spawn if navigation.get("ok") == true else Vector2(INF, INF)

func _remember_interaction_spawn() -> void:
	if _scene_rebuilding or not is_instance_valid(_player): return
	_publish_region_navigation()
	_last_return_spawn_sample = _current_player_spawn()

func _on_npc_interacted(id: String, dialog_id: String) -> void:
	var actor: Node = _region_actor(id)
	if _region_logic == null or actor == null: _region_fail("REGION_DIALOG_CONTEXT"); return
	if actor is NPCNode and _yihong_daily.handles(_region, actor):
		var daily: Dictionary = _yihong_daily.open(self, actor)
		if daily.get("ok") != true: _region_fail("YIHONG_DAILY_SOURCE"); return
		_play_region_dispatch(daily); return
	var dispatch: Variant = _region_logic.call("open", actor, "dialog", dialog_id)
	if not dispatch is Dictionary or dispatch.get("ok") != true: _region_fail("REGION_DIALOG_AUTHORIZATION"); return
	if dispatch.get("matched") == true:
		_play_region_dispatch(dispatch); return
	if dispatch.get("allow_original_dispatch") != true: _region_fail("REGION_UNSUPPORTED_DIALOG"); return
	super._on_npc_interacted(id, dialog_id)

func _on_npc_action_requested(id: String, action: String) -> void:
	var actor: Node = _region_actor(id)
	if _region_logic == null or actor == null: _region_fail("REGION_ACTION_CONTEXT"); return
	var dispatch: Variant = _region_logic.call("open", actor, "action", action)
	if not dispatch is Dictionary or dispatch.get("ok") != true: _region_fail("REGION_ACTION_AUTHORIZATION"); return
	if dispatch.get("matched") == true:
		_play_region_dispatch(dispatch); return
	if dispatch.get("allow_original_dispatch") != true: _region_fail("REGION_UNSUPPORTED_ACTION"); return
	super._on_npc_action_requested(id, action)

func _play_region_dispatch(dispatch: Dictionary) -> void:
	var graph: DialogScript = dispatch.get("script") as DialogScript
	var npc: NPCNode = dispatch.get("npc") as NPCNode
	if graph == null or not is_instance_valid(npc) or not _npc_nodes.has(npc) or DialogPlayer.is_playing(): _region_fail("REGION_PLAYABLE_DISPATCH"); return
	_remember_interaction_spawn()
	_active_dialog_npc = npc; npc.begin_conversation(_player.global_position)
	_player.set_walk_direction(npc.global_position - _player.global_position, false)
	_player.set_can_move(false)
	DialogPlayer.set_default_portrait(npc.portrait_path)
	DialogPlayer.set_default_speaker(npc.npc_name)
	DialogPlayer.play(graph)
	EventBus.npc_talked_to.emit(StringName(npc.npc_id))

func _prepare_npc_conversation_24b(graph: DialogScript, _preserve_instance: bool, include_opening: bool = true) -> DialogScript:
	if not include_opening or not is_instance_valid(_active_dialog_npc): return graph
	return _region_logic.call("prepare_primary", _active_dialog_npc, graph) as DialogScript

func _on_region_text_displayed(_speaker: String, _text: String, _choices: bool, _portrait: String) -> void:
	if _region_logic != null: _region_logic.call("observe_node")

func _on_dialog_ended(id: StringName) -> void:
	_yihong_daily.finish(id)
	# Quest/flag callbacks during the reducer commit may only queue one refresh.
	_region_busy = true
	var result: Dictionary = _region_logic.call("finish", id) if _region_logic != null else {"ok": true, "matched": false}
	if result.get("ok") != true:
		_region_busy = false; _region_fail("REGION_DIALOG_COMMIT"); return
	if result.get("feedback") is DialogScript:
		DialogPlayer.play(result.feedback)
		_region_busy = false; return # Feedback end owns the eventual unlock/refresh.
	if result.get("primary") is Dictionary:
		var npc: NPCNode = _region_actor(String(result.get("npc_id", ""))) as NPCNode
		if not is_instance_valid(npc): _region_busy = false; _region_fail("REGION_PRIMARY_ACTOR"); return
		var primary: Dictionary = result.primary
		if not String(primary.get("interaction_action", "")).is_empty():
			_on_npc_primary_action(npc.npc_id, primary.interaction_action, false)
		elif not String(primary.get("dialog_id", "")).is_empty():
			_on_npc_primary_dialog(npc.npc_id, primary.dialog_id, false)
		_region_busy = false
		if DialogPlayer.is_playing(): return
	else:
		_region_busy = false
	if is_instance_valid(_active_dialog_npc): _active_dialog_npc.end_conversation()
	_active_dialog_npc = null
	if is_instance_valid(_player) and not _scene_rebuilding and not (_sparring_confirm_dialog != null and _sparring_confirm_dialog.visible): _player.set_can_move(true)
	if _primary_hud != null: _primary_hud.set_hint_visible(true)
	if _formal_bottom_bar != null: _formal_bottom_bar.visible = true
	if _formal_hint_label != null: _formal_hint_label.visible = true
	if _region_refresh_pending or _scene_refresh_pending or result.get("refresh_dynamic", false): _refresh_scene_preserving_player()

func _on_trigger_zone_entered(body: Node2D, data: Dictionary) -> void:
	if not body.is_in_group("player"): return
	var matches: Array = _trigger_areas.filter(func(area: Area2D) -> bool: return area.get_meta("trigger_data", {}).get("id") == data.get("id"))
	if matches.size() != 1: _region_fail("REGION_INTERACTION_INSTANCE"); return
	var result: Dictionary = _region_logic.call("interaction", matches[0], String(data.get("action", "")))
	if result.get("ok") != true: _region_fail("REGION_INTERACTION_SOURCE"); return
	if result.get("matched") != true: super._on_trigger_zone_entered(body, data)

func _exit_tree() -> void:
	if _region_logic != null: _region_logic.call("abort", "field_exit")
	if _region_owner != null: _region_owner.release()
	super._exit_tree()
