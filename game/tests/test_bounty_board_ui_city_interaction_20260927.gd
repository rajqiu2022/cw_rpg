extends SceneTree

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_board_ui()
	_validate_city_board_contracts()
	_validate_guides_do_not_open_board()
	await _validate_runtime_city_boards()
	print("[BountyBoardUICityInteraction] checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)


func _validate_board_ui() -> void:
	var packed := load("res://scenes/bounty_board.tscn") as PackedScene
	_check(packed != null, "通缉榜场景可加载")
	if packed == null:
		return
	var board := packed.instantiate() as Control
	root.add_child(board)
	await process_frame
	await process_frame

	var title := board.get_node_or_null("BoardTitle") as Control
	var reputation := board.get_node_or_null("ReputationLabel") as Control
	var hint := board.get_node_or_null("BoardHint") as Control
	var list := board.get_node_or_null("BountyEntries") as VBoxContainer
	var close := board.get_node_or_null("CloseButton") as Control
	_check(title != null and reputation != null and hint != null and list != null and close != null, "标题、声望、说明、榜文和关闭按钮节点齐全")
	if title != null and reputation != null and hint != null:
		_check(title.anchor_bottom < reputation.anchor_top, "标题不与声望行重叠")
		_check(reputation.anchor_bottom <= hint.anchor_top, "声望行不与说明文字重叠")
		_check(reputation.anchor_top >= 0.16 and hint.anchor_bottom <= 0.24, "声望与说明完整落在上方青色信息牌内")
	if list != null:
		_check(list.anchor_left >= 0.10 and list.anchor_right <= 0.90, "两张榜文限制在木框安全区内")
		_check(list.get_child_count() == 2, "榜单稳定显示两张城市榜文")
		var row_region_tops: Array[Vector3] = []
		for card_node: Node in list.get_children():
			var card := card_node as Control
			var content := card.get_node_or_null("Content") as Control
			var seal := content.get_node_or_null("Seal") as Control if content != null else null
			var text_column := content.get_node_or_null("TextColumn") as Control if content != null else null
			var accept := content.get_node_or_null("AcceptButton") as Control if content != null else null
			_check(content != null and seal != null and text_column != null and accept != null, "每张榜文拥有独立印记、文字和揭榜按钮")
			if seal != null and text_column != null and accept != null:
				row_region_tops.append(Vector3(seal.anchor_top, text_column.anchor_top, accept.anchor_top))
				_check(seal.anchor_right < text_column.anchor_left, "犯人印记不压住姓名与案情")
				_check(text_column.anchor_right < accept.anchor_left, "奖励文字不压住揭榜按钮")
				_check(accept.anchor_right <= 0.98, "揭榜按钮不越出朱红印牌")
				_check(accept.get_theme_font_size("font_size") >= 32, "揭榜文字字号与朱红印牌体量匹配")
		if row_region_tops.size() == 2:
			var first_regions: Vector3 = row_region_tops[0]
			var second_regions: Vector3 = row_region_tops[1]
			_check(
				second_regions.x >= first_regions.x + 0.09
				and second_regions.y >= first_regions.y + 0.09
				and second_regions.z >= first_regions.z + 0.09,
				"第二张榜文的印记、案情和揭榜文字使用统一下移锚点"
			)
	if close != null:
		_check(close.anchor_top >= 0.85 and close.anchor_bottom <= 0.935, "合上榜册按钮落在底部牌匾内")
	board.queue_free()
	await process_frame


func _validate_city_board_contracts() -> void:
	var cities := {
		"luoyang": "res://data/maps/ch4_s0_luoyang_gate_layout_v1.tres",
		"bianzhou": "res://data/maps/openworld_bianzhou_city_layout_v2.tres",
		"xiangzhou": "res://data/maps/openworld_xiangzhou_city_layout_v2.tres",
		"jinling": "res://data/maps/openworld_jinling_city_layout_v2.tres",
	}
	for city_id: String in cities:
		var layout := load(String(cities[city_id])) as WalkableMapLayout
		_check(layout != null, "%s城市布局可加载" % city_id)
		if layout == null:
			continue
		var matching: Array[Dictionary] = []
		for interaction: Dictionary in layout.interactions:
			if String(interaction.get("action", "")) == "bounty_board:%s" % city_id:
				matching.append(interaction)
		_check(matching.size() == 1, "%s拥有唯一实体榜牌入口" % city_id)
		if matching.is_empty():
			continue
		var board: Dictionary = matching[0]
		_check(bool(board.get("visual_baked", false)), "%s入口绑定画面中的实体榜亭" % city_id)
		_check(not String(board.get("baked_feature", "")).is_empty(), "%s记录实体榜亭名称" % city_id)
		_check(bool(board.get("clickable", false)), "%s榜亭支持靠近后直接点击" % city_id)
		_check(String(board.get("activation", "")) == "interact", "%s榜亭不会路过误触" % city_id)
		_check(Vector2(board.get("size", Vector2.ZERO)).x >= 0.14, "%s榜亭点击区覆盖实体画面" % city_id)


func _validate_guides_do_not_open_board() -> void:
	for path in [
		"res://data/dialogs/openworld_bianzhou_guide.tres",
		"res://data/dialogs/openworld_xiangzhou_guide.tres",
		"res://data/dialogs/openworld_jinling_guide.tres",
	]:
		var dialog := load(path) as DialogScript
		_check(dialog != null, "城市指路对白可加载：" + path)
		if dialog == null:
			continue
		var npc_opens_board := false
		var mentions_board_location := false
		for node: DialogNode in dialog.nodes:
			if String(node.text).contains("榜亭"):
				mentions_board_location = true
			for choice: Dictionary in node.choices:
				if String(choice.get("action", "")).begins_with("bounty_board:"):
					npc_opens_board = true
		_check(not npc_opens_board, "NPC只负责指路，不再代开榜单：" + path)
		_check(mentions_board_location, "NPC明确告诉玩家实体榜亭位置：" + path)


func _validate_runtime_city_boards() -> void:
	var router := root.get_node("SceneRouter")
	var state := root.get_node("GameState")
	state.set_flag(&"luoyang_case_found_clue", true)
	var cities := {
		&"ch4_s0_luoyang_gate": "luoyang_repeatable_bounty_board",
		&"openworld_bianzhou_city": "bianzhou_bounty_board",
		&"openworld_xiangzhou_city": "xiangzhou_bounty_board",
		&"openworld_jinling_city": "jinling_bounty_board",
	}
	var packed := load("res://scenes/field_walkable.tscn") as PackedScene
	for scene_id: StringName in cities:
		var scene_def := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		router.set("_current_field_id", scene_id)
		router.set("_current_field_spawn", scene_def.player_spawn)
		router.set("_field_payload", {"scene_id": scene_id, "player_spawn": scene_def.player_spawn})
		var field := packed.instantiate()
		root.add_child(field)
		for _frame in range(5):
			await process_frame
		var area := field.find_child("Trigger_%s" % String(cities[scene_id]), true, false) as Area2D
		_check(area != null, "%s实机生成榜亭交互区" % scene_id)
		if area != null:
			_check(area.input_pickable, "%s实机榜亭可直接点击" % scene_id)
			var trigger: Dictionary = area.get_meta("trigger_data", {})
			_check(String(trigger.get("action", "")).begins_with("bounty_board:"), "%s实机榜亭直达榜单" % scene_id)
		field.queue_free()
		await process_frame


func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[BountyBoardUICityInteraction] " + description)
