extends Node

var checks := 0
var failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	await _validate_equipment_comparison()
	await _validate_story_portal_visibility()
	print("[EquipmentCompareStoryPortal20260903] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[EquipmentCompareStoryPortal20260903] %s" % failure)
	get_tree().quit(1 if not failures.is_empty() else 0)


func _validate_equipment_comparison() -> void:
	GameState.reset_for_new_game()
	Inventory.reset_for_new_game()
	Inventory.add_item(&"cloth_armor", 1)
	Inventory.add_item(&"heart_guard_armor", 1)
	var cloth_instance := ""
	var candidate_entry: Dictionary = {}
	for entry: Dictionary in Inventory.slots:
		var item := entry.get("item") as Item
		if item != null and item.item_id == &"cloth_armor":
			cloth_instance = String(entry.get("instance_id", ""))
		elif item != null and item.item_id == &"heart_guard_armor":
			candidate_entry = entry
	_check(not cloth_instance.is_empty() and not candidate_entry.is_empty(), "对比测试装备已准备")
	_check(Inventory.equip_instance_for(&"protagonist", cloth_instance), "粗布麻衣可作为当前装备")
	var panel := preload("res://scenes/ui/character_panel.tscn").instantiate() as CharacterPanel
	get_tree().root.add_child(panel)
	await get_tree().process_frame
	panel.open()
	panel.call("_select_inventory_entry", candidate_entry)
	await get_tree().process_frame
	var comparison := panel.find_child("EquipmentComparison", true, false)
	var equipped_name := panel.find_child("EquippedComparisonName", true, false) as Label
	var equipped_stats := panel.find_child("EquippedComparisonStats", true, false) as RichTextLabel
	var delta := panel.find_child("EquipmentComparisonDelta", true, false) as RichTextLabel
	_check(comparison != null, "选择同槽候选时右栏显示对比界面")
	_check(equipped_name != null and equipped_name.text == "粗布麻衣", "右栏显示当前已装备名称")
	_check(equipped_stats != null and equipped_stats.text.contains("防御 +2"), "右栏显示当前已装备属性")
	_check(delta != null and delta.text.contains("防御 +8"), "右栏显示换装后的净变化")
	panel.queue_free()
	await get_tree().process_frame


func _validate_story_portal_visibility() -> void:
	GameState.reset_for_new_game()
	GameState.flags.erase(&"ch6_archive_entry_found")
	var hidden_field := await _instantiate_master_hall()
	_check(hidden_field != null and not _has_archive_exit(hidden_field), "第一章进入师父正屋时地下入口完全隐藏")
	if hidden_field != null:
		hidden_field.queue_free()
	await get_tree().process_frame
	GameState.set_flag(&"ch6_archive_entry_found", true)
	var revealed_field := await _instantiate_master_hall()
	_check(revealed_field != null and _has_archive_exit(revealed_field), "第六章找到机关后地下入口才出现")
	if revealed_field != null:
		revealed_field.queue_free()
	await get_tree().process_frame


func _instantiate_master_hall() -> Node:
	SceneRouter.set("_field_payload", {
		"scene_id": &"linxi_master_hall",
		"player_spawn": Vector2(0.500, 0.805),
	})
	SceneRouter.set("_current_field_id", &"linxi_master_hall")
	var packed := load("res://scenes/field_walkable.tscn") as PackedScene
	if packed == null:
		return null
	var field := packed.instantiate()
	get_tree().root.add_child(field)
	for _frame: int in range(8):
		await get_tree().process_frame
	return field


func _has_archive_exit(field: Node) -> bool:
	var exits: Variant = field.get("_exit_nodes")
	if not exits is Array:
		return false
	for raw_zone: Variant in exits:
		var zone := raw_zone as ExitZone
		if zone != null and zone.target_scene_id == "ch6_s3_underground_archive":
			return true
	return false


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
