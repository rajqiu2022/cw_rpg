extends "res://scripts/drafts/redrock_luoyang_standard_20261028b/town_controller.gd"

const HOME_DOOR := Vector2(1700, 1545)
const ART_ROOT := "res://art/modules/redrock_desert_complete_20261028d/"
var active_room := "inn"

func _ready() -> void:
	super._ready()
	$Town/HomeDoor.set_meta("label", "阶街民居 · 空格进屋")
	$Town/Stable.set_meta("label", "驿舍马院：驮兽、货物与饮水槽分开布置。")
	$Town/Lookout.set_meta("label", "高台望关：沿石阶抵达台前，可回望关镇与峡口。")
	$Town/GateSentinel.set_meta("label", "关门兵：驻守峡口。")
	update_view()

func update_view() -> void:
	super.update_view()
	$UI/Status.text = "赤砂岩阶街 / 六区环路 / 关外商路　｜　冷孤云与居民行走已接"
	if in_hall and active_room == "home":
		$UI/Title.text = "赤岩关镇 · 阶街民居"
		$UI/Hint.text = "WASD移动　空格查看　前方入口空格返街　Esc关闭说明"
	elif not in_hall:
		if view_mode == 0:
			$Camera.position = Vector2(2850, 3850)
			$Camera.zoom = Vector2.ONE * 0.13
			$UI/Title.text = "赤岩关镇 · 城镇与关外商路"
		elif view_mode == 8:
			$Camera.position = Vector2(2850, 6000)
			$Camera.zoom = Vector2.ONE * 0.47
			$UI/Title.text = "赤岩关镇 · 关外商路"
		elif view_mode == 1 and actor.global_position.y > 4650:
			$UI/Title.text = "赤岩关镇 · 关外商路"
		if view_mode < 2:
			$UI/Hint.text = "WASD移动　Shift快走　Tab全景/跟随　1—6城区　7关外　空格查看　Esc关闭说明"
		if actor.global_position.distance_to(HOME_DOOR) < 100.0:
			$UI/Hint.text = "空格：进入阶街民居"
		elif actor.global_position.distance_to(DOOR) < 100.0:
			$UI/Hint.text = "空格：进入驿舍前厅"

func enter_home() -> void:
	if in_hall or actor.global_position.distance_to(HOME_DOOR) > 100.0:
		return
	return_foot = actor.global_position
	hall = $HomeRoom
	active_room = "home"
	actor.reparent(hall.get_node("Sort"), true)
	actor.global_position = hall.to_global(Vector2(0, -75))
	$Town.visible = false
	hall.visible = true
	in_hall = true
	show_details = false
	view_mode = 1
	entry_count += 1
	update_view()

func leave_hall() -> void:
	super.leave_hall()
	hall = $InnHall
	active_room = "inn"
	update_view()

func examine() -> void:
	if in_hall and active_room == "home":
		if actor.global_position.distance_to(hall.get_node("Exit").global_position) < 100.0:
			leave_hall()
			return
		$UI/Detail/Portrait.visible = false
		$UI/Detail/Text.text = "阶街民居\n\n卧榻与衣架独立放置，门内留出通道。\n\n从前方入口按空格原位返街。"
		show_details = true
		return
	if not in_hall:
		if actor.global_position.distance_to(HOME_DOOR) < 100.0:
			enter_home()
			return
		for row in [["Merchant", "merchant_portrait", "商旅", "驿舍马院与关外小驿之间，货物、驮兽和人行通道各有位置。"], ["StoneWorker", "worker_portrait", "石匠", "修坊临街工作，石料与车轮台放在院边，中央通道保持畅通。"]]:
			if actor.global_position.distance_to(get_node("Town/" + row[0]).global_position) < 155.0:
				$UI/Detail/Portrait.texture = load(ART_ROOT + row[1] + ".png")
				$UI/Detail/Portrait.visible = true
				$UI/Detail/Text.text = row[2] + "\n\n" + row[3] + "\n\nEsc关闭后继续行走。"
				show_details = true
				return
	$UI/Detail/Portrait.texture = load("res://art/modules/redrock_luoyang_standard_20261028b/keeper_portrait.png")
	super.examine()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_7 and not in_hall:
		view_mode = 8
		update_view()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_key_input(event)
