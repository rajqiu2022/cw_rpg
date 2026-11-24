extends Node2D
## Local scene session only, without shared routing/save/quest/economy writes.
const START := Vector2(650,3780)
const DOOR := Vector2(590,1255)
const ART_ROOT := "res://art/modules/miao_town_20261029f/"
const FOCUS := [Vector2(850,3420),Vector2(3900,3350),Vector2(3800,2430),Vector2(700,2050),Vector2(3800,1250),Vector2(5900,1200)]
const NAMES := ["山口寨门","临溪街市","芦笙坪","蜡染绣坊","吊脚民巷","梯田粮院"]
@export var view_mode := 1
var controls_enabled := true
var show_details := false
var in_hall := false
var return_foot := DOOR
var entry_count := 0
@onready var actor: CharacterBody2D = $Town/Player
@onready var hall: Node2D = $HouseHall

func _ready() -> void:
	actor.set_ground_anchored(true)
	actor.set_can_move(false)
	initialize_foot_depth()
	update_view()

func _physics_process(delta: float) -> void:
	var direction:=Vector2.ZERO
	var before:=actor.global_position
	if controls_enabled and not show_details:
		direction=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		actor.velocity=direction.normalized()*(600.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 330.0)
		actor.move_and_slide()
	else:actor.velocity=Vector2.ZERO
	actor.animate_preview(direction,actor.global_position.distance_squared_to(before)>.0001,delta)
	update_view()

func enter_hall() -> void:
	if in_hall or actor.global_position.distance_to(DOOR)>100:return
	return_foot=actor.global_position
	actor.reparent(hall.get_node("Sort"),true)
	actor.global_position=hall.to_global(Vector2(0,-60))
	$Town.visible=false;hall.visible=true;in_hall=true;show_details=false;view_mode=1;entry_count+=1
	update_view()

func leave_hall() -> void:
	if not in_hall:return
	actor.reparent($Town,true);actor.global_position=return_foot
	$Town.visible=true;hall.visible=false;in_hall=false;show_details=false;view_mode=1
	update_view()

func update_view() -> void:
	actor.z_as_relative=false
	actor.z_index=foot_depth(actor.global_position.y)
	if in_hall:
		$Camera.position=hall.position-Vector2(0,265);$Camera.zoom=Vector2.ONE*.95
		$UI/Title.text="苗风山城 · 木楼前厅"
	else:
		match view_mode:
			0:$Camera.position=Vector2(3250,2410);$Camera.zoom=Vector2.ONE*.215
			1:$Camera.position=actor.global_position-Vector2(0,190);$Camera.zoom=Vector2.ONE*.9
			_:$Camera.position=FOCUS[clampi(view_mode-2,0,5)];$Camera.zoom=Vector2.ONE*.78
		var zone:=0;var distance:=INF
		for i in range(FOCUS.size()):
			var d:=actor.global_position.distance_squared_to(FOCUS[i])
			if d<distance:distance=d;zone=i
		if view_mode>=2:zone=clampi(view_mode-2,0,5)
		$UI/Title.text="苗风山城 · "+("六区全景" if view_mode==0 else NAMES[zone])
	$UI/Status.text="木楼顺坡 / 溪街回环　｜　冷孤云行走　｜　绣坊前厅可进入"
	$UI/Hint.text="WASD / 方向键移动　Shift快走　Tab全景/跟随　1—6分区　空格查看　Esc关闭说明"
	if in_hall and actor.global_position.distance_to(hall.get_node("Exit").global_position)<100:$UI/Hint.text="空格：返回绣坊门前"
	elif not in_hall and actor.global_position.distance_to(DOOR)<100:$UI/Hint.text="空格：进入绣坊木楼前厅"
	$UI/Detail.visible=show_details
	for item in $Town.get_children():
		if item.has_meta("fade"):
			var area: Rect2=item.get_meta("visual_rect")
			var d: Vector2=actor.global_position-item.global_position
			var enabled:=view_mode==1 and not in_hall and d.y < -5 and d.y > -area.size.y and absf(d.x)<area.size.x*.5
			set_fade(item.get_node("Art"),enabled)
		elif item.has_meta("bridge"):
			var d: Vector2=actor.global_position-item.global_position
			var enabled:=view_mode==1 and not in_hall and absf(d.x)<800 and absf(d.y)<125
			for art in item.get_node("Foreground").get_children():set_fade(art,enabled)

func set_fade(art: CanvasItem,enabled: bool) -> void:
	var mat:=art.material as ShaderMaterial
	if mat!=null:
		mat.set_shader_parameter("hero_foot",actor.global_position)
		mat.set_shader_parameter("fade_enabled",1.0 if enabled else 0.0)

func examine() -> void:
	$UI/Detail/Portrait.visible=false
	if in_hall:
		if actor.global_position.distance_to(hall.get_node("Exit").global_position)<100:leave_hall();return
		if actor.global_position.distance_to(hall.get_node("Sort/Keeper").global_position)<190:
			$UI/Detail/Portrait.texture=load(ART_ROOT+"woman_portrait.png");$UI/Detail/Portrait.visible=true
			$UI/Detail/Text.text="绣坊主人\n\n点蜡、染布和晾晒各有位置，来往行旅可在前厅歇脚。"
		else:$UI/Detail/Text.text="木楼前厅\n\n桌凳、柜台与货架分列两侧，门内留出通道。\n\n从前方入口按空格返回绣坊。"
		show_details=true;return
	if actor.global_position.distance_to(DOOR)<100:enter_hall();return
	var nearest: Node2D;var distance:=220.0
	for item in $Town.get_children():
		if not item.has_meta("label"):continue
		var d:=actor.global_position.distance_to(item.global_position)
		if d<distance:distance=d;nearest=item
	if nearest!=null:
		$UI/Detail/Text.text=str(nearest.get_meta("label"))
		if nearest.has_meta("portrait"):
			$UI/Detail/Portrait.texture=load(ART_ROOT+str(nearest.get_meta("portrait"))+".png");$UI/Detail/Portrait.visible=true
	else:$UI/Detail/Text.text="过溪入市，沿短阶进入木楼街巷；山口、绣坊和粮院由桥路相连。"
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
			actor.global_position=START;show_details=false;view_mode=1
		_:return
	update_view();get_viewport().set_input_as_handled()

func foot_depth(y: float) -> int:
	return clampi(roundi(y/4.0),-4000,4000)

func initialize_foot_depth() -> void:
	for item in $Town.get_children():
		if not item is Node2D or item is StaticBody2D:continue
		item.z_as_relative=false
		if not item.has_meta("ground_cover") and not (item.has_meta("visual_rect") and item.z_index<0):
			item.z_index=foot_depth(item.global_position.y)
		if item.has_node("Base"):
			item.get_node("Base").z_as_relative=false
		if item.has_node("Foreground"):
			item.get_node("Foreground").z_as_relative=false
			item.get_node("Foreground").z_index=foot_depth(item.global_position.y+22)
	for item in $HouseHall/Sort.get_children():
		if item is Node2D:
			item.z_as_relative=false
			item.z_index=foot_depth(item.global_position.y)
