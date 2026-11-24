extends "res://scripts/ui/inventory_panel.gd"

const CRAFTED_ITEMS := [&"field_edge_pill", &"field_breath_pill", &"field_guard_powder", &"field_focus_pill", &"clear_sight_powder"]

func _use_item_now(id: StringName) -> bool:
	if id not in CRAFTED_ITEMS or not _battle_mode:
		return super._use_item_now(id)
	var battle := get_tree().current_scene
	var item := Inventory.load_item_by_id(id)
	if item == null or not item.can_use(true) or not Inventory.has_item(id) or not is_instance_valid(battle) or not battle.has_method("apply_field_medicine") or not battle.call("apply_field_medicine", String(id)):
		_show_tip("当前状态无法使用该道具", false)
		return false
	Inventory.remove_item(id, 1)
	EventBus.item_used.emit(id)
	_show_tip("已使用：" + item.display_name, true)
	_refresh()
	action_committed.emit(&"use_item")
	return true
