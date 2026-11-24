extends Node2D
## Cached local courtyard/room session; no shared save, quest, money or routing access.
const START := Vector2(2250,4480)
const DOOR := Vector2(1530,3110)
const FOCUS := [Vector2(2250,3910),Vector2(2500,1240),Vector2(2430,3000),Vector2(4500,2300),Vector2(1100,2280),Vector2(4350,850)]
const NAMES := ["峡口关门","阶街民巷","驿舍马院","石作修坊","蓄水小院","高台望关"]
@export var view_mode := 1
var controls_enabled := true
var show_details := false
var in_hall := false
var return_foot := DOOR
var entry_count := 0
@onready var actor: CharacterBody2D = $Town/Player
@onready var hall: Node2D = $InnHall

func _ready() -> void:
	actor.set_ground_anchored(true)
	actor.set_can_move(false)
	update_view()

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	var before := actor.global_position
	if controls_enabled and not show_details:
		var d := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		direction = d
		actor.velocity=d.normalized()*(600.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 330.0)
		actor.move_and_slide()
	else:
		actor.velocity=Vector2.ZERO
	actor.animate_preview(direction, actor.global_position.distance_squared_to(before) > 0.0001, delta)
	update_view()

func enter_hall() -> void:
	if in_hall or actor.global_position.distance_to(DOOR)>100.0:return
	return_foot=actor.global_position
	actor.reparent(hall.get_node("Sort"),true)
	actor.global_position=hall.to_global(Vector2(0,-75))
	$Town.visible=false
	hall.visible=true
	in_hall=true
	show_details=false
	view_mode=1
	entry_count+=1
	update_view()

func leave_hall() -> void:
	if not in_hall:return
	actor.reparent($Town,true)
	actor.global_position=return_foot
	$Town.visible=true
	hall.visible=false
	in_hall=false
	show_details=false
	view_mode=1
	update_view()

func update_view() -> void:
	if in_hall:
		$Camera.position=hall.position-Vector2(0,240)
		$Camera.zoom=Vector2.ONE*.9
		$UI/Title.text="赤岩驿舍 · 前厅"
	else:
		match view_mode:
			0:
				$Camera.position=Vector2(2870,2600)
				$Camera.zoom=Vector2.ONE*.205
			1:
				$Camera.position=actor.global_position-Vector2(0,190)
				$Camera.zoom=Vector2.ONE*.9
			_:
				$Camera.position=FOCUS[clampi(view_mode-2,0,5)]
				$Camera.zoom=Vector2.ONE*(.65 if view_mode==2 else .92)
		var zone:=0
		var best:=INF
		for i in range(FOCUS.size()):
			var distance:=actor.global_position.distance_squared_to(FOCUS[i])
			if distance<best:zone=i;best=distance
		if view_mode>=2:zone=clampi(view_mode-2,0,5)
		$UI/Title.text="赤岩关镇 · "+("六区全景" if view_mode==0 else NAMES[zone])
	$UI/Status.text="生活街段改造　｜　主角四向待机 / 行走已接　｜　NPC仍为待机"
	$UI/Hint.text="WASD移动　Shift快走　Tab全景/跟随　1—6分区　空格查看　Esc关闭说明"
	if in_hall:
		if actor.global_position.distance_to(hall.get_node("Exit").global_position)<100:
			$UI/Hint.text="空格：返回驿舍马院　｜　保持原角色与街上位置"
	elif actor.global_position.distance_to(DOOR)<100:
		$UI/Hint.text="空格：进入驿舍前厅"
	if not in_hall and view_mode>=2:
		$UI/Hint.text="分区观察镜头　Tab切回全景/跟随；空格交互以角色位置为准"
	$UI/Detail.visible=show_details
	for item in $Town.get_children():
		if not item.has_meta("visual_rect") or not item.has_node("Art"):continue
		var area: Rect2=item.get_meta("visual_rect")
		var d: Vector2=actor.global_position-item.global_position
		item.get_node("Art").modulate.a=.55 if d.y < -10 and d.y > -160 and absf(d.x)<area.size.x*.45 else 1.0
	$Town/Gate/Core.modulate.a=.55 if actor.global_position.x>2060 and actor.global_position.x<2440 and actor.global_position.y>3680 and actor.global_position.y<4050 else 1.0

func examine() -> void:
	$UI/Detail/Portrait.visible=false
	if in_hall:
		if actor.global_position.distance_to(hall.get_node("Exit").global_position)<100:
			leave_hall()
			return
		if actor.global_position.distance_to(hall.get_node("Sort/Keeper").global_position)<190:
			$UI/Detail/Portrait.visible=true
			$UI/Detail/Text.text="驿舍掌柜 · 布局人物\n\n地图待机与肖像为同一位中年女掌柜。\n\n本地前厅可查看柜台、桌凳与货架。正式剧情、收费服务和商店经济尚未绑定。\n\nEsc关闭后继续行走。"
		else:
			$UI/Detail/Text.text="驿舍前厅\n\n独立桌凳、柜台与货架均有实际碰撞。\n\n从前方入口按空格返院，保留同一角色与原室外节点。"
		show_details=true
		return
	if actor.global_position.distance_to(DOOR)<100:
		enter_hall()
		return
	var nearest: Node2D
	var distance:=225.0
	for item in $Town.get_children():
		if not item.has_meta("label") or str(item.get_meta("label")).is_empty():continue
		var d:=actor.global_position.distance_to(item.global_position)
		if d<distance:distance=d;nearest=item
	$UI/Detail/Text.text=str(nearest.get_meta("label")) if nearest!=null else "沿街与院门通路已分开；院界均有实际阻挡。\n\n新前厅从驿舍主门进入。"
	show_details=true

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.physical_keycode:
		KEY_SPACE:
			if not show_details:examine()
		KEY_ESCAPE:
			show_details=false
		KEY_TAB:
			if not in_hall:view_mode=1 if view_mode==0 else 0
		KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6:
			if not in_hall:view_mode=int(event.physical_keycode-KEY_1)+2
		KEY_R:
			if in_hall:leave_hall()
			actor.global_position=START
			show_details=false
			view_mode=1
		_:
			return
	update_view()
	get_viewport().set_input_as_handled()
