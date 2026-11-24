extends Node
## Small additive owner for life-skill UI and explicit ordinary gathering sites.
## No changes to original tasks, native geometry, portraits, or save schema.
const CRAFT_PANEL=preload("res://scripts/life_skills/crafting_panel.gd")
const GATHER=preload("res://scripts/life_skills/gathering_service.gd")
const GATHER_ACTION=preload("res://build/gather_actions_20261030l_system01/gather_action.gd")
const THEME=preload("res://scripts/ui/wuxia_theme.gd")
const SMITHS: Array[String]=["gufeng_smithy","luoyang_services_20261025h/smith"]
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
var _medicine_button: Button
var _medicine_owner: Node
var _gather_action: Node

func _ready() -> void:
	_gather_action=GATHER_ACTION.new();_gather_action.name="GatherAction";add_child(_gather_action)
	_gather_action.finished.connect(_on_gather_action_finished)
	_ui=CanvasLayer.new();_ui.name="LifeSkillsUI";_ui.layer=90;add_child(_ui)
	_hint=Label.new();_hint.position=Vector2(660,960);_hint.size=Vector2(600,44)
	_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;_hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
	THEME.style_label(_hint,23,THEME.GOLD_LIGHT);_ui.add_child(_hint);_hint.hide()
	_medicine_button=Button.new();_medicine_button.name="MedicineRecipes";_medicine_button.text="药方 · 制药"
	_medicine_button.position=Vector2(24,1008);_medicine_button.size=Vector2(174,48)
	CRAFT_PANEL.style_button(_medicine_button);_ui.add_child(_medicine_button);_medicine_button.hide()
	_medicine_button.pressed.connect(func()->void:
		var field: Node=get_tree().current_scene
		if is_instance_valid(field) and field.has_method("get_field_loading_state") and not bool(field.get("_system_panel_open")):_open_panel("medicine",[],field)
	)
	EventBus.battle_ended.connect(GATHER.record_battle)
	Inventory.slots_changed.connect(_refresh_panel)
	EventBus.gold_changed.connect(_gold_changed)

func _process(delta: float) -> void:
	_scan_clock+=delta
	if _scan_clock<.25:return
	_scan_clock=0
	_medicine_button.hide()
	var owner: Node=get_tree().current_scene
	if owner!=_owner:
		_close_panel();_clear_sites();_owner=owner
	if not is_instance_valid(owner):return
	if owner.scene_file_path=="res://scenes/shop.tscn":
		_attach_smith(owner);return
	if not owner.has_method("get_field_loading_state"):return
	var loading: Dictionary=owner.call("get_field_loading_state")
	if loading.get("complete")!=true or loading.get("failed")==true:return
	_medicine_button.visible=not _gather_action.is_active() and not DialogPlayer.is_playing() and not bool(owner.get("_system_panel_open")) and not is_instance_valid(_panel) and not bool(LoadingManager.get("_transition_active"))
	_attach_inventory(owner)
	var id: String=String(loading.get("scene_id",""))
	var has_sites: bool=GATHER.catalog().get("coordinate_basis",{}).has(id)
	if _field!=owner or _field_id!=id or (has_sites and (not is_instance_valid(_site_root) or _site_root.is_queued_for_deletion())):_install_sites(owner,id)
	_refresh_sites()

func _attach_inventory(field: Node) -> void:
	var inventory: Control=field.get("_inventory_panel") as Control
	if inventory==null:return
	var parent: Control=inventory.get_node_or_null("MainPanel") as Control
	if parent==null or parent.has_node("LifeMedicineButton"):return
	var button:=Button.new();button.name="LifeMedicineButton";button.text="药方 · 制药"
	button.position=Vector2(65,440);button.size=Vector2(160,48);CRAFT_PANEL.style_button(button)
	parent.add_child(button)
	button.pressed.connect(func()->void:
		if field==get_tree().current_scene and inventory.is_visible_in_tree() and not bool(inventory.get("_battle_mode")) and not DialogPlayer.is_playing():
			_open_panel("medicine",[],field)
	)

func _attach_smith(shop: Node) -> void:
	var data: ShopDef=shop.get("_shop") as ShopDef
	var parent: Control=shop.get_node_or_null("Panel") as Control
	if data==null or parent==null or String(data.shop_id) not in SMITHS or parent.has_node("LifeSmithButton"):return
	var button:=Button.new();button.name="LifeSmithButton";button.text="制造装备"
	button.position=Vector2(82,151);button.size=Vector2(220,48);CRAFT_PANEL.style_button(button);parent.add_child(button)
	button.pressed.connect(func()->void:
		var confirmation: Control=shop.get("confirm_overlay") as Control
		if shop==get_tree().current_scene and (confirmation==null or not confirmation.visible):_open_panel("blacksmith",data.stock,shop)
	)

func _open_panel(station: String, stock: Array, source: Node) -> void:
	if is_instance_valid(_gather_action) and _gather_action.is_active():return
	if is_instance_valid(_panel) or DialogPlayer.is_playing() or source!=get_tree().current_scene or bool(LoadingManager.get("_transition_active")) or bool(LoadingManager.get("_external_active")) or GameState.player==null:return
	if station=="medicine":
		var inventory: Control=source.get("_inventory_panel") as Control
		if inventory==null or not inventory.is_visible_in_tree():
			if bool(source.get("_system_panel_open")) or not source.has_method("_on_system_panel_opened"):return
			_medicine_owner=source;source.call("_on_system_panel_opened")
	_panel=CRAFT_PANEL.new();_panel.station=station;_panel.stock=stock.duplicate()
	_panel.station_valid=func()->bool:
		if not is_instance_valid(source) or source!=get_tree().current_scene or DialogPlayer.is_playing():return false
		if station=="blacksmith":
			var shop: ShopDef=source.get("_shop") as ShopDef
			return shop!=null and String(shop.shop_id) in SMITHS
		var inventory: Control=source.get("_inventory_panel") as Control
		return source==_medicine_owner or (inventory!=null and inventory.is_visible_in_tree() and not bool(inventory.get("_battle_mode")))
	_panel.closed.connect(_panel_closed)
	_ui.add_child(_panel)
	_medicine_button.hide()

func _panel_closed() -> void:
	_panel=null
	if is_instance_valid(_medicine_owner) and _medicine_owner==get_tree().current_scene:
		_medicine_owner.call("_on_system_panel_closed")
	_medicine_owner=null

func _close_panel() -> void:
	if is_instance_valid(_panel):_panel.queue_free()
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
		var point:=Node2D.new();point.position=foot
		var sprite:=Sprite2D.new();sprite.texture=load(String(site.texture));sprite.centered=false
		sprite.offset=-Vector2(site.source_foot[0],site.source_foot[1]);sprite.scale=Vector2.ONE*float(site.scale)
		sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		point.add_child(sprite)
		var label:=Label.new();label.position=Vector2(-70,-88 if site.type=="ore" else -72);label.size=Vector2(140,30)
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		label.text="铁矿脉" if site.type=="ore" else "药草";THEME.style_label(label,17,THEME.GOLD_LIGHT);point.add_child(label)
		point.z_index=clampi(int(foot.y/8),0,1024);_site_root.add_child(point)
		_site_nodes[String(site.id)]={"point":point,"sprite":sprite,"label":label}
		_active_sites[String(site.id)]=site

func _can_interact(allow_owned_action: bool=false) -> bool:
	return (allow_owned_action or not is_instance_valid(_gather_action) or not _gather_action.is_active()) and is_instance_valid(_field) and is_instance_valid(_site_root) and not _site_root.is_queued_for_deletion() and _field==get_tree().current_scene and not _field.is_queued_for_deletion() and not DialogPlayer.is_playing() and not is_instance_valid(_panel) and not bool(_field.get("_system_panel_open")) and not bool(_field.get("_scene_rebuilding")) and not bool(LoadingManager.get("_transition_active")) and not bool(LoadingManager.get("_external_active")) and String(SceneRouter.get_current_field_id())==_field_id

func _physics_process(_delta: float) -> void:
	_nearest=""
	if not _can_interact():
		if is_instance_valid(_hint):_hint.hide()
		return
	var actor: Player=_field.get("_player") as Player
	if actor==null or not actor.can_move or not is_instance_valid(_world):return
	var foot: Vector2=_world.to_local(actor.global_position);var distance: float=82
	for id: String in _active_sites:
		var d: float=foot.distance_to(_active_sites[id].runtime_foot)
		if d<distance and GATHER.is_available(id):distance=d;_nearest=id
	_hint.visible=not _nearest.is_empty()
	if not _nearest.is_empty():_hint.text="F 采药" if _active_sites[_nearest].type=="herb" else "F 采矿"

func _refresh_sites() -> void:
	for id: String in _site_nodes:
		var available: bool=GATHER.is_available(id);var row: Dictionary=_site_nodes[id]
		if not is_instance_valid(row.sprite) or not is_instance_valid(row.label):continue
		row.sprite.modulate=Color.WHITE if available else Color(.5,.5,.5,.45)
		row.label.text=("铁矿脉" if _active_sites[id].type=="ore" else "药草") if available else "已采集"

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
	else:_hint.hide();_medicine_button.hide()
	return result

func _on_gather_action_finished(result: Dictionary) -> void:
	if _can_interact():_refresh_sites()
	if result.get("completed")==true or String(result.get("cancel_reason","")) in ["ESCAPE","MOVE_INPUT","FINAL_VALIDATION"]:
		EventBus.toast_requested.emit(String(result.get("message","采集已取消。")))

func get_gather_action_debug() -> Dictionary:
	return _gather_action.get_debug_state() if is_instance_valid(_gather_action) else {"active":false}

func _validate_gather(id: String, allow_owned_action: bool=false) -> Dictionary:
	var rejected: Dictionary={"ok":false,"message":"请靠近资源点，在没有阻隔的位置采集。"}
	if not _can_interact(allow_owned_action) or not _active_sites.has(id):return rejected
	var actor: Player=_field.get("_player") as Player
	if actor==null or (not actor.can_move and not (allow_owned_action and is_instance_valid(_gather_action) and _gather_action.owns_actor(actor))):return rejected
	var foot: Vector2=_active_sites[id].runtime_foot
	if _world.to_local(actor.global_position).distance_to(foot)>82:return rejected
	var ray:=PhysicsRayQueryParameters2D.create(actor.global_position,_world.to_global(foot),actor.collision_mask,[actor.get_rid()])
	ray.collide_with_areas=false
	if not actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():return rejected
	# Full original foot shape at the gather point, not a center-only sample.
	var shape: CollisionShape2D=actor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape==null or shape.shape==null:return rejected
	var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape.shape
	query.transform=shape.global_transform;query.transform.origin+=_world.to_global(foot)-actor.global_position
	query.collision_mask=actor.collision_mask;query.exclude=[actor.get_rid()];query.collide_with_areas=false
	if not actor.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():return rejected
	if actor.movement_constraint.is_valid() and not actor.movement_constraint.call(_world.to_global(foot)):return rejected
	return GATHER.preview(id)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F and not _nearest.is_empty():
		try_gather(_nearest);get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and _can_interact():
		for id: String in _site_nodes:
			var point: Node2D=_site_nodes[id].point
			var screen: Vector2=point.get_global_transform_with_canvas().origin
			if event.position.distance_to(screen)<38:
				try_gather(id);get_viewport().set_input_as_handled();break
