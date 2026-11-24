extends Node
## Additive optional local expeditions. Original quests and reward tables stay owned.
const CONFIGS: Array[String]=["res://data/maps/adventure_20261030k/adventure_config.json","res://data/maps/adventure_20261030k/luoyang_adventure_config.json","res://data/maps/chapter1_exploration.json"]
const STATE_KEY:="adventure_progress_v1"
const CHALLENGE_RESPAWN_SECONDS := 600
const CHALLENGE_CLOCK_PATH := "user://wild_challenge_respawns.cfg"
const THEME=preload("res://scripts/ui/wuxia_theme.gd")
const INTERACTION_GLOW := preload("res://scripts/field/interaction_glow.gd")
var _maps: Dictionary={}
var _connectors: Array[Dictionary]=[]
var _field_points: Dictionary = {}
var _owner: Node
var _world: Node2D
var _root: Node2D
var _logical: String=""
var _features: Dictionary={}
var _near: String=""
var _clock: float=0
var _zone: String=""
var _hint: Label
var _ui: CanvasLayer
var _dialog: FormalConfirmDialog
var _pending: Dictionary={}
var _modal_owner: Node
var _battle_point: String=""
var _battle_challenge_key := ""
var _challenge_clock := ConfigFile.new()
var _patrol_time := 0.0
var _wolf_prompt_latched := false
var _wolf_battle_return := false
var _inner_confrontation_latched := false
const RIDGE_WOLF := "forest_wolf_ridge"
const WOLF_DEN := "ch1_s4_cave_deep_den"
const WOLF_IDLE := preload("res://art/sprites/battle/zhuwei_wolf_20261115/field_idle_frames.tres")

func _ready() -> void:
	var cooldown_error := _challenge_clock.load(CHALLENGE_CLOCK_PATH)
	if cooldown_error != OK and cooldown_error != ERR_FILE_NOT_FOUND:
		push_warning("[Adventure] Could not read challenge respawn times: %d" % cooldown_error)
	for path: String in CONFIGS:
		if not FileAccess.file_exists(path):continue
		var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
		if not raw is Dictionary or int(raw.get("schema_version",0))!=1:continue
		for row: Dictionary in raw.get("maps",[]):_maps[String(row.scene_id)]=row
		for connector: Dictionary in raw.get("connectors",[]):_connectors.append(connector)
		for scene_id: String in raw.get("field_points", {}):
			var points: Array = _field_points.get(scene_id, [])
			points.append_array(raw.field_points[scene_id])
			_field_points[scene_id] = points
	_ui=CanvasLayer.new();_ui.name="AdventureExplorationUI";_ui.layer=92;add_child(_ui)
	_hint=Label.new();_hint.position=Vector2(610,900);_hint.size=Vector2(700,40)
	_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;_hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
	THEME.style_label(_hint,22,THEME.GOLD_LIGHT);_ui.add_child(_hint);_hint.hide()
	_dialog=load("res://scenes/ui/formal_confirm_dialog.tscn").instantiate() as FormalConfirmDialog
	_ui.add_child(_dialog);_dialog.confirmed.connect(_accept);_dialog.cancelled.connect(_cancel)
	EventBus.battle_ended.connect(_battle_ended)
	EventBus.field_cutscene_requested.connect(_on_field_cutscene)
	var world_links: Node=load("res://build/adventure_world_20261031f_system01/world_links.gd").new()
	world_links.name="AdventureWorldLinks31f";add_child(world_links)

func _process(delta: float) -> void:
	_clock+=delta
	if _clock<.3:return
	_clock=0
	var field: Node=get_tree().current_scene
	prepare_loaded_field(field)
	var now := int(Time.get_unix_time_from_system())
	for id: String in _features:
		var feature: Dictionary = _features[id]
		if feature.kind == "challenge":
			var node := feature.get("node") as Node2D
			if is_instance_valid(node):
				node.visible = _challenge_available(id, now)

func _challenge_key(id: String) -> String:
	return _logical + "/" + id

func _challenge_available(id: String, now: int = -1) -> bool:
	if now < 0:
		now = int(Time.get_unix_time_from_system())
	return now >= int(_challenge_clock.get_value("respawn_at", _challenge_key(id), 0))

func prepare_loaded_field(field: Node) -> void:
	if not is_instance_valid(field) or not field.has_method("get_field_loading_state"):
		if is_instance_valid(_root) or not _logical.is_empty():_clear()
		return
	var loading: Dictionary=field.call("get_field_loading_state")
	if loading.get("complete")!=true or loading.get("failed")==true:return
	var logical: String=String(SceneRouter.get_current_field_id())
	if logical == WOLF_DEN:
		_animate_den_wolf(field)
	if logical not in ["ch1_s3_zhuwei_forest", "ch1_s3_west_ruin", "ch1_s3_ruin_inner"] and not _maps.has(logical) and not _field_points.has(logical):
		var has_connector := false
		for row: Dictionary in _connectors:
			if row.source_scene == logical:
				has_connector = true
				break
		if not has_connector:
			if is_instance_valid(_root):
				_clear()
			return
	if field!=_owner or logical!=_logical or not is_instance_valid(_root) or _root.is_queued_for_deletion():_install(field,logical)

func _animate_den_wolf(field: Node) -> void:
	var actors := field.get("_actor_layer") as Node2D
	if not is_instance_valid(actors):
		return
	var wolf := actors.get_node_or_null("SceneObject_deep_den_wolf_king") as Sprite2D
	if wolf == null or wolf.has_node("WolfIdle"):
		return
	var idle := AnimatedSprite2D.new()
	idle.name = "WolfIdle"
	idle.sprite_frames = WOLF_IDLE
	idle.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	wolf.texture = null
	wolf.add_child(idle)
	idle.play()

func _clear() -> void:
	if is_instance_valid(_root):_root.queue_free()
	_root=null;_world=null;_owner=null;_features.clear();_near="";_logical="";_zone=""
	_pending.clear();_modal_owner=null
	_wolf_prompt_latched = false
	_inner_confrontation_latched = false
	if is_instance_valid(_dialog):_dialog.close_dialog()
	if is_instance_valid(_hint):_hint.hide()

func _point(value: Variant) -> Vector2:
	return value if value is Vector2 else Vector2(float(value[0]),float(value[1]))

func _install(field: Node, logical: String) -> void:
	_clear();_owner=field;_logical=logical;_world=field.get("world_container") as Node2D
	if _world==null:return
	_root=Node2D.new();_root.name="OptionalAdventureFeatures";_world.add_child(_root)
	var size: Vector2=field.get("_world_size")
	var physical: String=String((field.get("_current_scene") as SceneScript).scene_id)
	if logical == "ch1_s3_west_ruin":
		load("res://build/riverside_visual_20261101a_system01/natural_ground.gd").install(field, logical)
		var depth := preload("res://scripts/field/west_ruin_depth.gd").new()
		depth.configure(field)
		_root.add_child(depth)
	if logical == "ch1_s3_zhuwei_forest":
		load("res://build/riverside_visual_20261101a_system01/natural_ground.gd").install(field,logical)
		for zone: ExitZone in field.get("_exit_nodes"):
			if zone.target_scene_id == "adventure_zhuwei_hunting_ground":
				zone.exit_triggered.connect(func(target: String, _spawn: Vector2) -> void:
					get_node("AdventureWorldLinks31f").local_connector_requested(field, target)
				)
	for row: Dictionary in _connectors:
		if String(row.source_scene)!=logical:continue
		if row.has("source_region_id") and String(row.source_region_id)!=physical:continue
		var basis: Vector2=_point(row.source_basis)
		var feature: Dictionary=row.duplicate(true)
		feature["kind"]="connector";feature["foot"]=_point(row.source_foot)/basis*size
		feature["id"]="entry_"+String(row.target_scene)
		_add_feature(feature)
	for raw: Dictionary in _field_points.get(logical, []):
		var feature := raw.duplicate(true)
		feature["foot"] = _point(raw.foot_uv) * size if raw.has("foot_uv") else _point(raw.foot)
		_add_feature(feature)
	if not _maps.has(logical):return
	var spec: Dictionary=_maps[logical]
	var visuals: Node=field.get("_visual_layer") as Node
	if visuals!=null:
		for child: Node in visuals.get_children():
			if child is Line2D and String(child.name).begins_with("TravelRoute_"):
				child.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
				var trail_material:=ShaderMaterial.new();trail_material.shader=load("res://scripts/adventure/soft_trail.gdshader")
				child.material=trail_material
	if logical in ["adventure_luoyang_riverside_route", "adventure_zhuwei_hunting_ground"]:
		load("res://build/riverside_visual_20261101a_system01/natural_ground.gd").install(field,logical)
	if logical=="adventure_zhuwei_hunting_ground":
		_fix_hunting_depth(field, size)
	for raw: Dictionary in spec.get("points",[]):
		var feature: Dictionary=raw.duplicate(true);feature["foot"]=_point(raw.foot)
		_add_feature(feature)
	for signpost: Dictionary in spec.get("signposts",[]):
		var label:=Label.new();label.text=String(signpost.text).replace("｜","\n")
		label.position=_point(signpost.foot)+Vector2(-170,-86);label.size=Vector2(340,64)
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		if logical=="adventure_zhuwei_hunting_ground":
			label.z_as_relative=false
			label.z_index=4096
			label.position+=Vector2(0,-102)
		THEME.style_label(label,18,THEME.GOLD_LIGHT);_root.add_child(label)
	var mini: Control=load("res://scripts/adventure/adventure_minimap.gd").new()
	mini.name="AdventureTerrainMinimap";_ui.add_child(mini);mini.call("configure",field)
	var mini_ref: WeakRef=weakref(mini)
	_root.tree_exiting.connect(func()->void:
		var existing: Control=mini_ref.get_ref() as Control
		if is_instance_valid(existing):existing.queue_free()
	)

func _fix_hunting_depth(field: Node, size: Vector2) -> void:
	var scene: SceneScript=field.get("_current_scene") as SceneScript
	var actors: Node2D=field.get("_actor_layer") as Node2D
	if scene==null or scene.map_layout==null or actors==null:
		return
	# The generic field's 255 buckets end at y=2048. This map is 3072 high.
	# Use one ladder for the real tree feet, the actor, and world-space markers.
	var hero: Player=field.get("_player") as Player
	if hero!=null:
		hero.set_meta("depth_band_max", 1024)
		hero.refresh_depth_sort()
	for row: Dictionary in scene.map_layout.visual_objects:
		if not row.get("sort_by_feet",false):
			continue
		var sprite: Sprite2D=actors.get_node_or_null("SceneObject_"+String(row.id)) as Sprite2D
		if sprite==null:
			continue
		var foot_y: float=float(row.depth_sort_foot_y)*size.y
		sprite.z_index=clampi(floori(_world.to_global(Vector2(0,foot_y)).y/8.0),0,1024)

func _add_feature(feature: Dictionary) -> void:
	var id: String=String(feature.id)
	if feature.kind in ["clue", "cache"] and _progress().get("viewed", {}).get(id, false):
		return
	_features[id]=feature
	var point:=Node2D.new();point.name="Adventure_"+id;point.position=feature.foot
	point.z_index=clampi(int(point.position.y/8),0,1024 if _logical=="adventure_zhuwei_hunting_ground" else 255)
	_root.add_child(point)
	if feature.kind == "challenge":
		point.visible = _challenge_available(id)
	if id == RIDGE_WOLF:
		point.z_as_relative = false
		_update_wolf_depth(point)
		_wolf_prompt_latched = _wolf_battle_return
		_wolf_battle_return = false
	var text:=Label.new();text.text=String(feature.label)
	text.position=Vector2(-160,-172);text.size=Vector2(320,34)
	if feature.get("trail_entrance",false):
		point.z_as_relative=false
		point.z_index=4096
		text.position.y=-58
	text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;text.mouse_filter=Control.MOUSE_FILTER_IGNORE
	THEME.style_label(text,19,THEME.GOLD_LIGHT if feature.kind=="connector" else THEME.TEXT)
	if id == RIDGE_WOLF:
		text.z_as_relative = false
		text.z_index = 4096
		text.position.y = -130
	if feature.kind in ["clue", "cache"]:
		text.free()
	else:
		point.add_child(text)
	if feature.get("trail_entrance", false) or feature.get("visual_baked", false):
		feature["node"] = point
		return
	var marker:=Sprite2D.new();marker.texture=load("res://art/ui/inventory/icons/icon_scroll.png")
	marker.scale=Vector2.ONE*(30.0/maxf(1,marker.texture.get_height()));marker.position=Vector2(0,-15)
	if feature.kind == "cache":
		# Show a small physical trace when authored; never float the loot's inventory icon.
		var trace_path := String(feature.get("trace_texture", ""))
		var trace := load(trace_path) as Texture2D if not trace_path.is_empty() else null
		if trace == null:
			marker.hide()
		else:
			marker.texture = trace
			marker.scale = Vector2.ONE * (float(feature.get("trace_width", 24.0)) / maxf(1.0, trace.get_width()))
			marker.position.y = -trace.get_height() * marker.scale.y * 0.35
	if feature.kind=="challenge":
		var enemy_ids := _challenge_enemy_ids(feature)
		if not enemy_ids.is_empty():
			var marker_id: StringName = enemy_ids.front() if feature.has("enemy_ids") else enemy_ids.back()
			var enemy_path := "res://data/enemies/%s.tres" % marker_id
			var enemy := load(enemy_path) as EnemyDef
			if enemy != null and ResourceLoader.exists(enemy.battle_actor_path):
				marker.texture = load(enemy.battle_actor_path)
				marker.scale = Vector2.ONE * (110.0 / maxf(1, marker.texture.get_height()))
				marker.position.y = -marker.texture.get_height() * marker.scale.y * .5
				if id == RIDGE_WOLF:
					var idle := AnimatedSprite2D.new()
					idle.name = "WolfIdle"
					idle.sprite_frames = WOLF_IDLE
					idle.scale = Vector2.ONE * (100.0 / 463.0)
					idle.position.y = -(698.0 - 400.0) * idle.scale.y
					point.add_child(idle)
					idle.play()
					marker.hide()
				if id == "forest_wolf_trail":
					var frames: Array[Texture2D] = []
					for path in enemy.move_frame_paths:
						var frame := load(path) as Texture2D
						if frame != null:
							frames.append(frame)
					feature["patrol_frames"] = frames
					feature["patrol_marker"] = marker
					feature["patrol_base"] = feature.foot
	var glow := INTERACTION_GLOW.new()
	glow.hide()
	point.add_child(glow)
	feature["glow"] = glow
	point.add_child(marker)
	feature["node"]=point

func _can_use() -> bool:
	return is_instance_valid(_owner) and _owner==get_tree().current_scene and is_instance_valid(_root) and not _root.is_queued_for_deletion() and not DialogPlayer.is_playing() and not bool(_owner.get("_system_panel_open")) and not bool(_owner.get("_scene_rebuilding")) and not bool(LoadingManager.get("_transition_active")) and not bool(LoadingManager.get("_external_active")) and String(SceneRouter.get_current_field_id())==_logical

func _update_wolf_depth(point: Node2D) -> void:
	var actors := _owner.get("_actor_layer") as Node2D
	var player := _owner.get("_player") as Player
	var max_band := int(player.get_meta("depth_band_max", 255)) if player != null else 255
	point.z_index = actors.z_index + clampi(floori(point.global_position.y / 8.0), 0, max_band)

func _set_near(id: String) -> void:
	if id == _near:
		return
	if _features.has(_near) and _features[_near].has("glow"):
		_features[_near].glow.hide()
	_near = id
	if _features.has(id) and _features[id].has("glow"):
		_features[id].glow.show()

func _update_patrol(delta: float, actor: Player) -> void:
	const ID := "forest_wolf_trail"
	if not _features.has(ID) or not _features[ID].has("patrol_frames"):
		return
	var row: Dictionary = _features[ID]
	var marker: Sprite2D = row.patrol_marker
	var node: Node2D = row.node
	var foot: Vector2 = row.patrol_base
	_patrol_time = fmod(_patrol_time + delta, 10.0)
	foot.x += -72.0 + pingpong(_patrol_time * 28.8, 144.0)
	if actor.movement_constraint.is_valid() and not actor.movement_constraint.call(_world.to_global(foot)):
		return
	row.foot = foot
	node.position = foot
	var frames: Array = row.patrol_frames
	if not frames.is_empty():
		marker.texture = frames[int(_patrol_time * 7.0) % frames.size()]
		marker.position.y = -marker.texture.get_height() * marker.scale.y * .5
	marker.flip_h = _patrol_time < 5.0

func _physics_process(delta: float) -> void:
	if _features.has(RIDGE_WOLF) and is_instance_valid(_features[RIDGE_WOLF].node):
		_update_wolf_depth(_features[RIDGE_WOLF].node)
	if not _can_use():
		_set_near("")
		return
	var actor: Player=_owner.get("_player") as Player
	if actor==null or not actor.can_move:
		_set_near("")
		return
	_update_patrol(delta, actor)
	var foot: Vector2=_world.to_local(actor.global_position);var nearest: float=104
	if _logical == "ch1_s3_ruin_inner" and _try_inner_confrontation(foot):
		return
	var near_id := ""
	for id: String in _features:
		if _features[id].kind == "challenge" and not _challenge_available(id):
			continue
		var distance: float=foot.distance_to(_features[id].foot)
		if distance < nearest and _clearance(_features[id].foot):
			nearest=distance;near_id=id
	_set_near(near_id if near_id != RIDGE_WOLF else "")
	if _features.has(RIDGE_WOLF):
		var distance_to_wolf := foot.distance_to(_features[RIDGE_WOLF].foot as Vector2)
		if distance_to_wolf >= 140.0:
			_wolf_prompt_latched = false
		elif near_id == RIDGE_WOLF and not _wolf_prompt_latched:
			interact(RIDGE_WOLF)
			if DialogPlayer.is_playing():
				return
	if _maps.has(_logical):
		var zone_label: String=""
		for zone: Dictionary in _maps[_logical].get("zones",[]):
			var polygon:=PackedVector2Array()
			for raw: Array in zone.polygon:polygon.append(_point(raw))
			if Geometry2D.is_point_in_polygon(foot,polygon):
				zone_label=String(zone.label)+( " · 自愿挑战，可绕行" if zone.kind=="danger" else " · 通行区")
		if zone_label!=_zone:
			_zone=zone_label
			if not _zone.is_empty():EventBus.toast_requested.emit(_zone)

func _try_inner_confrontation(foot: Vector2) -> bool:
	if GameState.get_flag(&"defeated_boss_zhao_wuji"):
		return false
	var extent: Vector2 = _owner.get("_world_size")
	var uv := foot / extent
	if not Rect2(0.35, 0.45, 0.3, 0.22).has_point(uv):
		_inner_confrontation_latched = false
		return false
	if _inner_confrontation_latched:
		return false
	_inner_confrontation_latched = true
	var dialog := "ch1_s3_ruin_boss" if GameState.get_flag(&"master_training_done") else "ch1_s3_ruin_boss_unprepared"
	SceneRouter.resolve_action("dialog:" + dialog)
	return true

func _clearance(foot: Vector2) -> bool:
	var actor: Player=_owner.get("_player") as Player
	if actor==null or _world.to_local(actor.global_position).distance_to(foot)>104:return false
	var space: PhysicsDirectSpaceState2D=actor.get_world_2d().direct_space_state
	var ray:=PhysicsRayQueryParameters2D.create(actor.global_position,_world.to_global(foot),actor.collision_mask,[actor.get_rid()]);ray.collide_with_areas=false
	if not space.intersect_ray(ray).is_empty():return false
	var shape: CollisionShape2D=actor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape==null or shape.shape==null:return false
	var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape.shape;query.transform=shape.global_transform
	query.transform.origin+=_world.to_global(foot)-actor.global_position;query.exclude=[actor.get_rid()]
	query.collision_mask=actor.collision_mask;query.collide_with_areas=false
	if not space.intersect_shape(query,1).is_empty():return false
	return not actor.movement_constraint.is_valid() or bool(actor.movement_constraint.call(_world.to_global(foot)))

func interact(id: String) -> bool:
	if not _can_use() or not _features.has(id):return false
	var feature: Dictionary=_features[id]
	if feature.kind == "challenge" and not _challenge_available(id):
		return false
	if not _clearance(feature.foot):return false
	if id == RIDGE_WOLF:
		if _wolf_prompt_latched:
			return false
		_wolf_prompt_latched = true
		DialogPlayer.play(preload("res://data/dialogs/zhuwei_ridge_wolf_choice.tres"))
		return true
	if feature.kind=="connector":
		var actor: Player=_owner.get("_player") as Player
		var size: Vector2=_owner.get("_world_size")
		var world_links: Node=get_node_or_null("AdventureWorldLinks31f")
		if world_links!=null:world_links.call("local_connector_requested",_owner,String(feature.target_scene))
		var return_uv: Vector2=_world.to_local(actor.global_position)/size
		if feature.has("source_return_uv"):
			return_uv=_point(feature.source_return_uv)
		SceneRouter.go_field_from_portal(StringName(feature.target_scene),_point(feature.get("target_spawn",feature.get("target_pos",[.5,.9]))),return_uv)
		return true
	_pending=feature.duplicate();_modal_owner=_owner
	_owner.call("_on_system_panel_opened")
	if String(feature.get("kind","clue"))=="challenge":
		var elite: bool=String(feature.get("tier","normal"))=="elite"
		_dialog.show_confirm(String(feature.label),String(feature.text)+"\n[b]"+("精英队伍" if elite else "普通敌人")+"[/b]：主动交战才开始，亦可取消绕行。\n胜负、经验与掉落沿用现有战斗规则。","交战","暂避")
	elif feature.kind == "cache":
		_dialog.show_confirm(String(feature.label), String(feature.text), "取出", "先离开")
	else:_dialog.show_notice(String(feature.label),String(feature.get("text","此处留下了一些旧痕。"))+"\n\n记入探索札记；不推进主线或领取新奖励。","记下")
	return true

func _progress() -> Dictionary:
	var state: Variant=GameState.get_flag(StringName(STATE_KEY),{})
	return state.duplicate(true) if state is Dictionary else {}

func _release_modal() -> void:
	if is_instance_valid(_modal_owner) and _modal_owner==get_tree().current_scene:
		_modal_owner.call("_on_system_panel_closed")
	_modal_owner=null

func _cancel() -> void:
	_pending.clear();_release_modal()

func _challenge_enemy_ids(feature: Dictionary) -> Array[StringName]:
	var ids: Array[StringName] = []
	for enemy_id: String in feature.get("enemy_ids", []):
		ids.append(StringName(enemy_id))
	if not ids.is_empty():
		return ids
	var elite: bool = feature.get("tier") == "elite"
	match feature.get("enemy_group"):
		"wolf":
			ids.append(&"zhuwei_pack_wolf")
			if elite:
				ids.append(&"zhuwei_pack_wolf")
		"mine":
			if elite:
				ids.append(&"mine_brute")
			ids.append(&"mine_outlaw")
	return ids

func _accept() -> void:
	if _pending.is_empty():_release_modal();return
	var feature: Dictionary=_pending.duplicate();_pending.clear()
	var valid: bool=is_instance_valid(_modal_owner) and _modal_owner==get_tree().current_scene and not DialogPlayer.is_playing() and not LoadingManager._transition_active
	_release_modal()
	if not valid:return
	if String(feature.get("kind","clue"))=="challenge":
		_start_challenge(feature)
	else:
		var state: Dictionary=_progress();var viewed: Dictionary=state.get("viewed",{}).duplicate()
		if feature.kind == "cache":
			if viewed.get(String(feature.id), false) or not _can_use() or not _clearance(feature.foot):
				return
			var item_id := StringName(feature.item_id)
			var item := Inventory.load_item_by_id(item_id)
			if item == null:
				return
			var has_room := Inventory.slots.size() < Inventory.MAX_SLOTS
			if not has_room and item.stackable:
				for slot: Dictionary in Inventory.slots:
					var stored := slot.get("item") as Item
					if stored != null and stored.item_id == item_id and int(slot.count) < item.max_stack:
						has_room = true
						break
			if not has_room:
				EventBus.toast_requested.emit("背包已满，东西仍留在原处。")
				return
		viewed[String(feature.id)]=true;state["viewed"]=viewed;GameState.flags[STATE_KEY]=state
		_set_near("")
		_features.erase(String(feature.id))
		var node := feature.get("node") as Node2D
		if is_instance_valid(node):
			node.hide()
			node.queue_free()
		if feature.kind == "cache":
			Inventory.add_item(StringName(feature.item_id), 1)
		else:
			EventBus.toast_requested.emit("已记下："+String(feature.label))

func _battle_ended(victory: bool,fled: bool) -> void:
	if _battle_point.is_empty():return
	if victory and not fled:
		var state: Dictionary=_progress();var wins: Dictionary=state.get("wins",{}).duplicate()
		wins[_battle_point]=int(wins.get(_battle_point,0))+1;state["wins"]=wins;GameState.flags[STATE_KEY]=state
		# Keep cleared encounters independent of the selected save's age.
		_challenge_clock.set_value("respawn_at", _battle_challenge_key, int(Time.get_unix_time_from_system()) + CHALLENGE_RESPAWN_SECONDS)
		var error := _challenge_clock.save(CHALLENGE_CLOCK_PATH)
		if error != OK:
			push_warning("[Adventure] Could not save challenge respawn times: %d" % error)
	_battle_point=""
	_battle_challenge_key=""

func _start_challenge(feature: Dictionary) -> bool:
	var id := String(feature.id)
	if not _challenge_available(id) or LoadingManager._transition_active or LoadingManager._external_active:
		return false
	var ids := _challenge_enemy_ids(feature)
	var actor := _owner.get("_player") as Player
	if ids.is_empty() or not is_instance_valid(actor):
		return false
	_battle_point = id
	_battle_challenge_key = _challenge_key(id)
	var extent: Vector2 = _owner.get("_world_size")
	SceneRouter.start_encounter(ids, StringName(_logical), _world.to_local(actor.global_position) / extent)
	return true

func _on_field_cutscene(id: StringName) -> void:
	if id != &"zhuwei_ridge_wolf_challenge" or not _can_use() or not _features.has(RIDGE_WOLF):
		return
	_wolf_battle_return = _start_challenge(_features[RIDGE_WOLF])

func interact_nearby(field: Node) -> bool:
	if field != _owner or _near.is_empty() or not _can_use():
		return false
	var actor := _owner.get("_player") as Player
	return actor != null and actor.can_move and interact(_near)

func _unhandled_input(event: InputEvent) -> void:
	# The native Player processes doors/NPCs first. Never steal their Space.
	if event.is_echo() or not (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		return
	if not _can_use() or not is_instance_valid(_owner.get("_player")) or not _owner.get("_player").can_move:
		return
	if interact_nearby(_owner) or LifeSkills.interact_nearby(_owner):
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(_dialog) or not _dialog.is_open():return
	if event.is_action_pressed("ui_cancel"):
		_dialog.close_dialog();_cancel();get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_I,KEY_E,KEY_C,KEY_K,KEY_J,KEY_M,KEY_TAB,KEY_F5]:
		get_viewport().set_input_as_handled()

func get_adventure_state() -> Dictionary:
	return {"logical_id":_logical,"maps":_maps.keys(),"features":_features.keys(),"nearest":_near,"progress":_progress(),"modal_open":is_instance_valid(_dialog) and _dialog.is_open()}
