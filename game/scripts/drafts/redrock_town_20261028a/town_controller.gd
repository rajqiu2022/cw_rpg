extends Node2D
## Dedicated editor town. No global router, quest, save, import or editor operations.

const START := Vector2(2250,4480)
const ZONE_FOCUS := [Vector2(2250,3910),Vector2(2500,1240),Vector2(2380,2860),Vector2(4540,2210),Vector2(1100,2180),Vector2(4350,850)]
const ZONE_NAMES := ["峡口关门","阶街民巷","驿舍马院","石作修坊","蓄水小院","高台望关"]
@export var view_mode := 0
var controls_enabled := true
var show_details := false


func _ready() -> void:
	update_view()


func _physics_process(_delta: float) -> void:
	var actor: CharacterBody2D = $Town/Inspector
	if controls_enabled and not show_details:
		var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		actor.velocity = direction.normalized() * (600.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 330.0)
		actor.move_and_slide()
	update_view()


func update_view() -> void:
	var actor: CharacterBody2D = $Town/Inspector
	match view_mode:
		0:
			$Camera.position = Vector2(2870,2600)
			$Camera.zoom = Vector2.ONE * 0.205
		1:
			$Camera.position = actor.position - Vector2(0,190)
			$Camera.zoom = Vector2.ONE * 0.90
		_:
			var index := clampi(view_mode-2,0,5)
			$Camera.position = ZONE_FOCUS[index]
			$Camera.zoom = Vector2.ONE * (0.65 if index==0 else 0.92)
	var zone := current_zone(actor.position)
	if view_mode>=2:
		zone = clampi(view_mode-2,0,5)
	$UI/Title.text = "赤岩关镇 · "+("六区全景" if view_mode==0 else ZONE_NAMES[zone])
	$UI/Status.text = "六区连通布局草案　｜　原生可编辑　｜　查看角色仅待机，行走动画未接"
	$UI/Detail.visible = show_details
	# Fade only local architecture when a foot is behind its front, not all props.
	for item in $Town.get_children():
		if not item.has_meta("visual_rect") or not item.has_node("Art"):
			continue
		var area: Rect2 = item.get_meta("visual_rect")
		var relative: Vector2 = actor.position-item.position
		var covered := relative.y < -10 and relative.y > -160 and absf(relative.x) < area.size.x*0.45
		item.get_node("Art").modulate.a = 0.55 if covered else 1.0
	$Town/Gate/Core.modulate.a = 0.55 if actor.position.x>2060 and actor.position.x<2440 and actor.position.y>3680 and actor.position.y<4050 else 1.0


func current_zone(point: Vector2) -> int:
	var best := 0
	var distance := INF
	for index in range(ZONE_FOCUS.size()):
		var d := point.distance_squared_to(ZONE_FOCUS[index])
		if d < distance:
			best = index
			distance = d
	return best


func examine_nearest() -> void:
	var actor: CharacterBody2D = $Town/Inspector
	var nearest: Node2D
	var distance := 225.0
	for item in $Town.get_children():
		if not item.has_meta("label") or str(item.get_meta("label")).is_empty():
			continue
		var d: float = actor.position.distance_to(item.position)
		if d < distance:
			distance = d
			nearest = item
	$UI/Detail/Text.text = str(nearest.get_meta("label")) if nearest != null else "此处可继续沿主路查看六个分区。\n按1—6查看分区，Tab切换全景与角色跟随。"
	show_details = true


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_TAB:
			view_mode = 1 if view_mode==0 else 0
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
			view_mode = int(event.physical_keycode-KEY_1)+2
		KEY_R:
			$Town/Inspector.position = START
			show_details = false
			view_mode = 1
		KEY_SPACE:
			examine_nearest()
		KEY_ESCAPE:
			show_details = false
		_:
			return
	update_view()
	get_viewport().set_input_as_handled()
