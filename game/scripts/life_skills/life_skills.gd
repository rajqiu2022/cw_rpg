extends Node
## Small additive owner for life-skill UI and explicit ordinary gathering sites.
## No changes to original tasks, native geometry, portraits, or save schema.
const CRAFT_PANEL=preload("res://scripts/life_skills/crafting_panel.gd")
const GATHER=preload("res://scripts/life_skills/gathering_service.gd")
const INTERACTION_GLOW := preload("res://scripts/field/interaction_glow.gd")
const GATHER_ACTION=preload("res://build/gather_actions_20261030l_system01/gather_action.gd")
const THEME=preload("res://scripts/ui/wuxia_theme.gd")
const JOURNAL := preload("res://scripts/ui/life_skills_journal.gd")
const FIELD_MENU := preload("res://scripts/ui/field_menu_runtime.gd")
const SMITHS: Array[String]=["linxi_du_smithy","gufeng_smithy","luoyang_services_20261025h/smith"]
const UPGRADE_COUNTER := "qingfeng_merchant"
var _owner: Node
var _field: Node
var _world: Node2D
var _site_root: Node2D
var _site_nodes: Dictionary={}
var _active_sites: Dictionary={}
var _panel: Control
var _ui: CanvasLayer
var _scan_clock: float=0
var _field_id: String=""
var _nearest: String=""
var _hint: Label
var _medicine_owner: Node
var _journal: Control
var _gather_action: Node

func _ready() -> void:
	# Sample depth after the active map has updated its actor bands.
	process_priority = 20
	add_child(FIELD_MENU.new())
	_gather_action=GATHER_ACTION.new();_gather_action.name="GatherAction";add_child(_gather_action)
	_gather_action.finished.connect(_on_gather_action_finished)
	_ui=CanvasLayer.new();_ui.name="LifeSkillsUI";_ui.layer=90;add_child(_ui)
	_hint=Label.new();_hint.position=Vector2(660,960);_hint.size=Vector2(600,44)
	_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;_hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
	THEME.style_label(_hint,23,THEME.GOLD_LIGHT);_ui.add_child(_hint);_hint.hide()
	EventBus.battle_ended.connect(GATHER.record_battle)
	Inventory.slots_changed.connect(_refresh_panel)
	EventBus.gold_changed.connect(_gold_changed)

func _interaction_host() -> Node:
	var field := get_tree().current_scene
	if is_instance_valid(field):
		var shop := field.get_node_or_null("NPCShopLayer/Shop") as Control
		if is_instance_valid(shop) and shop.is_visible_in_tree():
			return shop
	return field

func _process(delta: float) -> void:
	_update_site_depth()
	_scan_clock+=delta
	if _scan_clock<.25:return
	_scan_clock=0
	var owner: Node=_interaction_host()
	if is_instance_valid(owner) and owner.scene_file_path=="res://scenes/shop.tscn":
		_set_nearest("")
		_attach_smith(owner)
		return
	if owner!=_owner:
		_close_panel();_clear_sites();_owner=owner
	if not is_instance_valid(owner):return
	if not owner.has_method("get_field_loading_state"):return
	var loading: Dictionary=owner.call("get_field_loading_state")
	if loading.get("complete")!=true or loading.get("failed")==true:return
	_attach_inventory(owner)
	var id: String=String(loading.get("scene_id",""))
	var has_sites: bool=GATHER.catalog().get("coordinate_basis",{}).has(id)
	if _field!=owner or _field_id!=id or (has_sites and (not is_instance_valid(_site_root) or _site_root.is_queued_for_deletion())):_install_sites(owner,id)
	_refresh_sites()

func _update_site_depth() -> void:
	if not is_instance_valid(_site_root) or not is_instance_valid(_field):
		return
	var actor := _field.get("_player") as Player
	if not is_instance_valid(actor):
		return
	var actor_foot := actor.get_depth_sort_y()
	var depth_limit := int(actor.get_meta("depth_band_max", 255))
	var parent_depth := 0
	var ancestor := actor.get_parent() as CanvasItem if actor.z_as_relative else null
	while ancestor != null:
		parent_depth += ancestor.z_index
		if not ancestor.z_as_relative:
			break
		ancestor = ancestor.get_parent() as CanvasItem
	var actor_depth := parent_depth + actor.z_index
	for id: String in _site_nodes:
		var point := _site_nodes[id] as Node2D
		var foot := point.global_position.y
		var band := clampi(floori(foot / 8.0), 0, depth_limit)
		var depth := parent_depth + band
		# Use exact feet near the sprite, even if the field rounds or adjusts
		# the actor's band independently of its visual foot.
		if absf(foot - actor_foot) < 128.0:
			depth = maxi(depth, actor_depth + 1) if foot > actor_foot else mini(depth, actor_depth - 1)
		point.z_index = clampi(depth, -4096, 4096)

func _attach_inventory(field: Node) -> void:
	var inventory: Control=field.get("_inventory_panel") as Control
	if inventory==null:return
	var parent: Control=inventory.get_node_or_null("MainPanel") as Control
	if parent==null or parent.has_node("LifeMedicineButton"):return
	var button:=Button.new();button.name="LifeMedicineButton";button.text="药方 · 制药"
	button.position=Vector2(65,440);button.size=Vector2(160,48);CRAFT_PANEL.style_button(button)
	parent.add_child(button)
	button.pressed.connect(func()->void:
		if field==_interaction_host() and inventory.is_visible_in_tree() and not bool(inventory.get("_battle_mode")) and not DialogPlayer.is_playing():
			_open_panel("medicine",[],field)
	)

func _attach_smith(shop: Node) -> void:
	var data: ShopDef=shop.get("_shop") as ShopDef
	var parent: Control=shop.get_node_or_null("Panel") as Control
	if data==null or parent==null or not _offers_tempering(data.shop_id) or parent.has_node("LifeSmithButton"):return
	var button:=Button.new();button.name="LifeSmithButton";button.text="升级兵器" if String(data.shop_id)==UPGRADE_COUNTER else "升级／打造"
	button.position=Vector2(82,151);button.size=Vector2(220,48);CRAFT_PANEL.style_button(button);parent.add_child(button)
	button.pressed.connect(func()->void:
		var confirmation: Control=shop.get("confirm_overlay") as Control
		if shop==_interaction_host() and (confirmation==null or not confirmation.visible):_open_panel("blacksmith",data.stock,shop)
	)

func _offers_tempering(id: StringName) -> bool:
	return String(id) in SMITHS or String(id) == UPGRADE_COUNTER

func open_journal() -> void:
	var field := _interaction_host()
	if not is_instance_valid(field) or not field.has_method("get_field_loading_state"):
		return
	var loading: Dictionary = field.get_field_loading_state()
	if loading.get("complete") != true or loading.get("failed") == true or bool(field.get("_system_panel_open")):
		return
	if _gather_action.is_active() or DialogPlayer.is_playing() or bool(LoadingManager.get("_transition_active")) or bool(LoadingManager.get("_external_active")):
		return
	_journal = JOURNAL.new()
	_journal.closed.connect(_journal_closed.bind(field))
	_journal.medicine_requested.connect(func() -> void:
		_journal.close()
		_open_panel("medicine", [], field)
	)
	field.call("_on_system_panel_opened")
	_ui.add_child(_journal)

func _journal_closed(field: Node) -> void:
	_journal = null
	if is_instance_valid(field) and field == _interaction_host():
		field.call("_on_system_panel_closed")

func _open_panel(station: String, stock: Array, source: Node) -> void:
	if is_instance_valid(_gather_action) and _gather_action.is_active():return
	if is_instance_valid(_panel) or DialogPlayer.is_playing() or source!=_interaction_host() or bool(LoadingManager.get("_transition_active")) or bool(LoadingManager.get("_external_active")) or GameState.player==null:return
	if station=="medicine":
		var inventory: Control=source.get("_inventory_panel") as Control
		if inventory==null or not inventory.is_visible_in_tree():
			if bool(source.get("_system_panel_open")) or not source.has_method("_on_system_panel_opened"):return
			_medicine_owner=source;source.call("_on_system_panel_opened")
	_panel=CRAFT_PANEL.new();_panel.station=station;_panel.stock=stock.duplicate()
	if station=="blacksmith":
		var shop: ShopDef=source.get("_shop") as ShopDef
		_panel.tempering_only=shop!=null and String(shop.shop_id)==UPGRADE_COUNTER
	_panel.station_valid=func()->bool:
		if not is_instance_valid(source) or source!=_interaction_host() or DialogPlayer.is_playing():return false
		if station=="blacksmith":
			var shop: ShopDef=source.get("_shop") as ShopDef
			return shop!=null and _offers_tempering(shop.shop_id)
		var inventory: Control=source.get("_inventory_panel") as Control
		return source==_medicine_owner or (inventory!=null and inventory.is_visible_in_tree() and not bool(inventory.get("_battle_mode")))
	_panel.closed.connect(_panel_closed)
	_ui.add_child(_panel)

func _panel_closed() -> void:
	_panel=null
	if is_instance_valid(_medicine_owner) and _medicine_owner==_interaction_host():
		_medicine_owner.call("_on_system_panel_closed")
	_medicine_owner=null

func _close_panel() -> void:
	if is_instance_valid(_panel):_panel.queue_free()
	if is_instance_valid(_journal):_journal.queue_free()
	_journal=null
	_panel=null
	_medicine_owner=null

func _refresh_panel() -> void:
	if is_instance_valid(_panel):_panel.call_deferred("refresh")

func _gold_changed(_amount: int) -> void:_refresh_panel()

func _clear_sites() -> void:
	if is_instance_valid(_gather_action):_gather_action.cancel("SITE_ROOT_CLEARED")
	if is_instance_valid(_site_root):_site_root.queue_free()
	_site_root=null;_field=null;_world=null;_site_nodes.clear();_active_sites.clear();_nearest="";_field_id=""
	if is_instance_valid(_hint):_hint.hide()

func _install_sites(field: Node, id: String) -> void:
	_clear_sites();_field=field;_field_id=id
	var sites: Dictionary=GATHER.catalog()
	if not sites.get("coordinate_basis",{}).has(id):return
	_world=field.get("world_container") as Node2D
	var size: Vector2=field.get("_world_size")
	var raw: Array=sites.coordinate_basis[id];var basis:=Vector2(raw[0],raw[1])
	if _world==null or basis.x<=0 or basis.y<=0:return
	_site_root=Node2D.new();_site_root.name="OrdinaryGatheringSites";_world.add_child(_site_root)
	for source: Dictionary in sites.get("sites",[]):
		if String(source.get("scene_id"))!=id:continue
		var site: Dictionary=source.duplicate(true)
		var foot:=Vector2(site.foot[0],site.foot[1])/basis*size
		site["runtime_foot"]=foot
		_add_approach_scree(site.get("approach_scree", []), basis, size)
		var point:=Node2D.new();point.position=foot
		var ring := INTERACTION_GLOW.new()
		ring.name = "GatherGlow"
		ring.hide()
		point.add_child(ring)
		var sprite:=Sprite2D.new();sprite.texture=load(String(site.texture));sprite.centered=false
		sprite.offset=-Vector2(site.source_foot[0],site.source_foot[1]);sprite.scale=Vector2.ONE*float(site.scale)
		sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		point.add_child(sprite)
		point.z_as_relative = false
		_site_root.add_child(point)
		_site_nodes[String(site.id)]=point
		_active_sites[String(site.id)]=site
	_update_site_depth()

func _add_approach_scree(rows: Array, basis: Vector2, size: Vector2) -> void:
	if rows.is_empty(): return
	var texture := preload("res://art/modules/zhuwei_gather_20261110/iron_vein.png")
	for i: int in rows.size():
		var row: Array = rows[i]
		var stone := Sprite2D.new()
		stone.texture = texture
		stone.position = Vector2(row[0], row[1]) / basis * size
		stone.scale = Vector2.ONE * (float(row[2]) / texture.get_width())
		stone.modulate = Color(1.0, 0.95, 0.89, 0.84)
		stone.flip_h = (i % 2) == 1
		stone.z_index = -24
		stone.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_site_root.add_child(stone)

func _can_interact(allow_owned_action: bool=false) -> bool:
	return (allow_owned_action or not is_instance_valid(_gather_action) or not _gather_action.is_active()) and is_instance_valid(_field) and is_instance_valid(_site_root) and not _site_root.is_queued_for_deletion() and _field==_interaction_host() and not _field.is_queued_for_deletion() and not DialogPlayer.is_playing() and not is_instance_valid(_panel) and not bool(_field.get("_system_panel_open")) and not bool(_field.get("_scene_rebuilding")) and not bool(LoadingManager.get("_transition_active")) and not bool(LoadingManager.get("_external_active")) and String(SceneRouter.get_current_field_id())==_field_id

func _set_nearest(id: String) -> void:
	if id == _nearest:
		return
	if _site_nodes.has(_nearest):
		_site_nodes[_nearest].get_node("GatherGlow").hide()
	_nearest = id
	if _site_nodes.has(id):
		_site_nodes[id].get_node("GatherGlow").show()
	_hint.hide()

func _physics_process(_delta: float) -> void:
	if not _can_interact():
		_set_nearest("")
		return
	var actor: Player=_field.get("_player") as Player
	if actor==null or not actor.can_move or not is_instance_valid(_world):
		_set_nearest("")
		return
	var foot: Vector2=_world.to_local(actor.global_position);var distance: float=82
	var nearest := ""
	for id: String in _active_sites:
		var d: float=foot.distance_to(_active_sites[id].runtime_foot)
		if d<distance and _site_nodes[id].visible and _site_reachable(actor, _active_sites[id].runtime_foot):
			distance=d
			nearest=id
	_set_nearest(nearest)

func _refresh_sites() -> void:
	for id: String in _site_nodes:
		var point: Node2D=_site_nodes[id]
		if is_instance_valid(point):point.visible=GATHER.is_available(id)

func try_gather(id: String) -> Dictionary:
	if is_instance_valid(_gather_action) and _gather_action.is_active():return {"ok":false,"pending":false,"message":"正在采集，请稍候。"}
	var ready: Dictionary=_validate_gather(id)
	if ready.get("ok")!=true:
		EventBus.toast_requested.emit(String(ready.get("message","当前不能采集。")));return ready
	var actor: Player=_field.get("_player") as Player
	var site: Dictionary=_active_sites[id]
	var context: Dictionary={"manager":self,"field":_field,"actor":actor,"world":_world,"site_root":_site_root,"field_id":_field_id,"site_id":id,"kind":String(site.type),"resource_foot":site.runtime_foot}
	var result: Dictionary=_gather_action.start(context,GATHER_ACTION.profile_for(String(site.type)),func()->Dictionary:return _validate_gather(id,true),func()->Dictionary:return GATHER.collect(id))
	if result.get("ok")!=true:EventBus.toast_requested.emit(String(result.get("message","当前不能采集。")))
	else:_set_nearest("")
	return result

func _on_gather_action_finished(result: Dictionary) -> void:
	_refresh_sites()
	if not _nearest.is_empty() and not GATHER.is_available(_nearest):
		_nearest=""
		_hint.hide()
	# A successful commit already sends item_picked_up for the standard HUD notice.
	if (result.get("completed")==true and result.get("ok")!=true) or String(result.get("cancel_reason","")) in ["ESCAPE","MOVE_INPUT","FINAL_VALIDATION"]:
		EventBus.toast_requested.emit(String(result.get("message","采集已取消。")))

func get_gather_action_debug() -> Dictionary:
	return _gather_action.get_debug_state() if is_instance_valid(_gather_action) else {"active":false}

func _validate_gather(id: String, allow_owned_action: bool=false) -> Dictionary:
	var rejected: Dictionary={"ok":false,"message":"请靠近资源点，在没有阻隔的位置采集。"}
	if not _can_interact(allow_owned_action) or not _active_sites.has(id):return rejected
	var actor: Player=_field.get("_player") as Player
	if actor==null or (not actor.can_move and not (allow_owned_action and is_instance_valid(_gather_action) and _gather_action.owns_actor(actor))):return rejected
	if not _site_reachable(actor, _active_sites[id].runtime_foot):return rejected
	return GATHER.preview(id)

func _site_reachable(actor: Player, foot: Vector2) -> bool:
	if _world.to_local(actor.global_position).distance_to(foot)>82:return false
	var ray:=PhysicsRayQueryParameters2D.create(actor.global_position,_world.to_global(foot),actor.collision_mask,[actor.get_rid()])
	ray.collide_with_areas=false
	if not actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():return false
	# Full original foot shape at the gather point, not a center-only sample.
	var shape: CollisionShape2D=actor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape==null or shape.shape==null:return false
	var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape.shape
	query.transform=shape.global_transform;query.transform.origin+=_world.to_global(foot)-actor.global_position
	query.collision_mask=actor.collision_mask;query.exclude=[actor.get_rid()];query.collide_with_areas=false
	if not actor.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():return false
	return not actor.movement_constraint.is_valid() or bool(actor.movement_constraint.call(_world.to_global(foot)))

func interact_nearby(field: Node) -> bool:
	if field != _field or _nearest.is_empty() or not _can_interact():
		return false
	try_gather(_nearest)
	return true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F and not _nearest.is_empty():
		try_gather(_nearest);get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and _can_interact():
		for id: String in _site_nodes:
			var point: Node2D=_site_nodes[id]
			if not point.is_visible_in_tree() or not GATHER.is_available(id):continue
			var screen: Vector2=point.get_global_transform_with_canvas().origin
			if event.position.distance_to(screen)<38:
				try_gather(id);get_viewport().set_input_as_handled();break
