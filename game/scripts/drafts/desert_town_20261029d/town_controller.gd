extends Node2D
## Local editable city session. No shared Router, quest, inventory or save writes.
const START := Vector2(2560,4550)
const DOOR := Vector2(1330,2895)
const FOCUS := [Vector2(2560,4130),Vector2(4100,2970),Vector2(1780,2800),Vector2(6610,2840),Vector2(6200,3440),Vector2(5100,2220)]
const NAMES := ["沙路城门","遮阳巷市","驼队客院","井台蓄水","土坯民巷","防沙工坊"]
const PORTRAITS := "res://art/modules/redrock_desert_complete_20261028d/"
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
		direction=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		actor.velocity=direction.normalized()*(600.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 330.0)
		actor.move_and_slide()
	else:
		actor.velocity=Vector2.ZERO
	actor.animate_preview(direction,actor.global_position.distance_squared_to(before)>.0001,delta)
	update_view()

func enter_hall() -> void:
	if in_hall or actor.global_position.distance_to(DOOR)>100.0:return
	return_foot=actor.global_position
	actor.reparent(hall.get_node("Sort"),true)
	actor.global_position=hall.to_global(Vector2(0,-60))
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
		$Camera.position=hall.position-Vector2(0,260)
		$Camera.zoom=Vector2.ONE*.95
		$UI/Title.text="沙漠城镇 · 客栈前厅"
	else:
		match view_mode:
			0:
				$Camera.position=Vector2(4260,2890)
				$Camera.zoom=Vector2.ONE*.19
			1:
				$Camera.position=actor.global_position-Vector2(0,190)
				$Camera.zoom=Vector2.ONE*.9
			_:
				$Camera.position=FOCUS[clampi(view_mode-2,0,5)]
				$Camera.zoom=Vector2.ONE*.82
		var zone:=0
		var best:=INF
		for i in range(FOCUS.size()):
			var d:=actor.global_position.distance_squared_to(FOCUS[i])
			if d<best:best=d;zone=i
		if view_mode>=2:zone=clampi(view_mode-2,0,5)
		$UI/Title.text="沙漠城镇 · "+("六区全景" if view_mode==0 else NAMES[zone])
	$UI/Status.text="黄沙与土坯街院　｜　冷孤云四向行走　｜　客栈前厅可进入"
	$UI/Hint.text="WASD / 方向键移动　Shift快走　Tab全景/跟随　1—6分区　空格查看　Esc关闭说明"
	if in_hall:
		if actor.global_position.distance_to(hall.get_node("Exit").global_position)<100:
			$UI/Hint.text="空格：返回驼队客院"
	elif actor.global_position.distance_to(DOOR)<100:
		$UI/Hint.text="空格：进入客栈前厅"
	$UI/Detail.visible=show_details
	for item in $Town.get_children():
		if not item.has_meta("visual_rect") or not item.has_node("Art"):continue
		var area: Rect2=item.get_meta("visual_rect")
		var d: Vector2=actor.global_position-item.global_position
		item.get_node("Art").modulate.a=.45 if view_mode==1 and d.y < -8 and d.y > -area.size.y and absf(d.x)<area.size.x*.46 else 1.0
		if item.has_node("ForeArt"):item.get_node("ForeArt").modulate.a=item.get_node("Art").modulate.a
	# The complete original front wall remains joined; only proximity transparency changes.
	var wall_material: ShaderMaterial=$Town/WallFront/Art.material
	wall_material.set_shader_parameter("hero_foot",actor.global_position)
	wall_material.set_shader_parameter("fade_enabled",1.0 if view_mode==1 and not in_hall and actor.global_position.y>3500 and actor.global_position.y<4290 else 0.0)

func examine() -> void:
	$UI/Detail/Portrait.visible=false
	if in_hall:
		if actor.global_position.distance_to(hall.get_node("Exit").global_position)<100:
			leave_hall()
			return
		if actor.global_position.distance_to(hall.get_node("Sort/Keeper").global_position)<195:
			$UI/Detail/Portrait.texture=load("res://art/modules/redrock_luoyang_standard_20261028b/keeper_portrait.png")
			$UI/Detail/Portrait.visible=true
			$UI/Detail/Text.text="客栈掌柜\n\n客院行旅可在前厅歇脚，货架与桌凳分列两旁。"
		else:$UI/Detail/Text.text="客栈前厅\n\n桌凳、柜台和货架均可绕行。\n\n从前方入口按空格返回客院。"
		show_details=true
		return
	if actor.global_position.distance_to(DOOR)<100:
		enter_hall()
		return
	var nearest: Node2D
	var distance:=220.0
	for item in $Town.get_children():
		if not item.has_meta("label"):continue
		var d:=actor.global_position.distance_to(item.global_position)
		if d<distance:distance=d;nearest=item
	if nearest!=null:
		$UI/Detail/Text.text=str(nearest.get_meta("label"))
		if nearest.has_meta("portrait"):
			$UI/Detail/Portrait.texture=load(PORTRAITS+str(nearest.get_meta("portrait"))+".png")
			$UI/Detail/Portrait.visible=true
	else:$UI/Detail/Text.text="沙路入城后，经遮阳巷市抵达客院、井院与民巷。"
	show_details=true

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.physical_keycode:
		KEY_SPACE:
			if not show_details:examine()
		KEY_ESCAPE:show_details=false
		KEY_TAB:
			if not in_hall:view_mode=1 if view_mode==0 else 0
		KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6:
			if not in_hall:view_mode=int(event.physical_keycode-KEY_1)+2
		KEY_R:
			if in_hall:leave_hall()
			actor.global_position=START
			show_details=false
			view_mode=1
		_:return
	update_view()
	get_viewport().set_input_as_handled()
