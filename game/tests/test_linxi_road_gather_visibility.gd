extends SceneTree

var road: Script
var gather: Script
var failures := 0
var checks := 0
var pickups: Array = []
var toasts: Array[String] = []
var suspended := false

func _initialize() -> void:
	root.child_entered_tree.connect(_suspend)
	for node in root.get_children():_suspend(node)
	_run.call_deferred()

func _suspend(node: Node) -> void:
	if node.name==&"PlatformBridge":
		node.call("set_checkpoint_saves_suspended",true)
		suspended=bool(node.call("is_checkpoint_saves_suspended"))

func _check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("LINXI_ROAD_FAIL ",label)

func _finish() -> void:
	print("LINXI_ROAD_RESULT ",checks," / ",failures)
	quit(0 if failures==0 else 1)

func _settle() -> void:
	await physics_frame
	await process_frame
	await process_frame

func _check_depth(field: Node, actor: Player, prop: Sprite2D, id: String, behind: Vector2, front: Vector2) -> void:
	var depth: RefCounted=field.get("_road_depth")
	for p in [behind,front]:
		actor.global_position=p
		await _settle()
		var obscured: bool=p==behind
		var state: Dictionary=depth.get_debug_state()
		var hits: Dictionary=state.get("prop_hits",{})
		_check(road.safe_foot(p/road.SIZE),id+" valid sample "+str(p))
		_check(prop.is_visible_in_tree() and is_equal_approx(prop.modulate.a,1.0),id+" stays opaque")
		_check((prop.z_index>actor.z_index)==obscured,id+" follows the feet")
		_check(bool(hits.has(id))==obscured,id+" clipped character overlap "+str(hits))
		_check(actor._overlap_ghost.visible==obscured and is_equal_approx(actor.modulate.a,1.0),id+" character ghost only when behind")

func _harvest(field: Node, actor: Player, life: Node, id: String, item: StringName, foot: Vector2) -> void:
	# Position fixture is confined to this new private process; input and commit are real.
	actor.global_position=foot+Vector2(24,0)
	await _settle()
	var nodes: Dictionary=life.get("_site_nodes")
	var point: Node2D=nodes.get(id)
	if point==null:
		_check(false,id+" runtime node")
		return
	_check(point.is_visible_in_tree() and String(life.get("_nearest"))==id,id+" starts visible and selectable")
	var item_notice_count: int=field.get("_item_toast_lines").size()
	pickups.clear()
	toasts.clear()
	var press:=InputEventKey.new()
	press.keycode=KEY_F
	press.pressed=true
	Input.parse_input_event(press)
	await create_timer(2.0).timeout
	_check(pickups==[[item,2]] and toasts.is_empty(),id+" one pickup and no second toast: "+str([pickups,toasts]))
	var item_toast: RichTextLabel=field.get("_item_toast")
	_check(item_toast!=null and item_toast.visible and field.get("_item_toast_lines").size()==item_notice_count+1,id+" standard HUD notice")
	_check(not point.is_visible_in_tree() and not point.get_child(0).is_visible_in_tree() and not point.get_child(1).is_visible_in_tree(),id+" sprite and name hidden")
	_check(String(life.get("_nearest")).is_empty() and not gather.is_available(id),id+" no repeat interaction")

func _run() -> void:
	_check(suspended,"checkpoints suspended before entry")
	if not suspended:
		_finish()
		return
	var router:=root.get_node("SceneRouter")
	var game:=root.get_node("GameState")
	var life:=root.get_node("LifeSkills")
	var bus:=root.get_node("EventBus")
	road=load("res://build/linxi_mountain_road_20261030g_system01/road_author.gd")
	gather=load("res://scripts/life_skills/gathering_service.gd")
	game.get("flags")["seen_ch1_road_intro"]=true
	bus.item_picked_up.connect(func(id: StringName,count: int) -> void:pickups.append([id,count]))
	bus.toast_requested.connect(func(message: String) -> void:toasts.append(message))
	_check(router.call("go_field_smart",road.ID,null,"",-1,-1)==true,"formal road admitted")
	var until:=Time.get_ticks_msec()+22000
	while Time.get_ticks_msec()<until:
		await process_frame
		if current_scene==null or not current_scene.has_method("road_static_identity"):continue
		if current_scene.call("get_field_loading_state").get("complete",false) and not bool(root.get_node("LoadingManager").get("_transition_active")) and life.get("_site_nodes").size()==3:break
	if current_scene==null or not current_scene.has_method("road_static_identity") or life.get("_site_nodes").size()!=3:
		_check(false,"formal road and gathering mounted")
		_finish()
		return
	var field:=current_scene
	var actor: Player=field.get("_player")
	var cave: Sprite2D=field.get("_road_cave")
	var tablet: Sprite2D=actor.get_parent().get_node_or_null("SceneObject_road_stone_tablet_visual")
	if cave==null or tablet==null:
		_check(false,"cave and tablet mounted on real road")
		_finish()
		return
	await _check_depth(field,actor,cave,"original_bandit_cave_native_mouth",Vector2(2420,1410),Vector2(2420,1540))
	await _check_depth(field,actor,tablet,"road_stone_tablet_visual",Vector2(1050,2650),Vector2(1050,2760))
	await _harvest(field,actor,life,"life_road_herb_01",&"herb_bundle",Vector2(850,2860))
	await _harvest(field,actor,life,"life_road_ore_01",&"iron_ore",Vector2(3250,2080))
	for i in range(3):gather.record_battle(true,false)
	await create_timer(.4).timeout
	var nodes: Dictionary=life.get("_site_nodes")
	_check(nodes.life_road_herb_01.visible and nodes.life_road_ore_01.visible,"original regeneration restores both nodes")
	_finish()
