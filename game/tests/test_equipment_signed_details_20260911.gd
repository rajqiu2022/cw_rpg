extends SceneTree

var checks := 0
var failed := 0
var unequip_events := 0
const STATS := preload("res://scripts/ui/equipment_stat_presentation.gd")

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error("[EquipmentSigned] " + message)

func _run() -> void:
	root.size = Vector2i(1920,1080)
	var gs := root.get_node("GameState")
	var inv := root.get_node("Inventory")
	gs.reset_for_new_game()
	inv.reset_for_new_game()
	check(gs.add_companion(&"tang_xingzhou"), "real companion added for selector regression")
	inv.add_item(&"heavy_iron_sword", 1)
	var instance := ""
	for entry: Dictionary in inv.slots:
		if entry.item.item_id == &"heavy_iron_sword": instance = entry.instance_id
	check(not instance.is_empty() and inv.equip_instance_for(&"protagonist", instance), "equip real purple heavy sword")
	var sword := inv.get_equipped_for(&"protagonist", 0) as Equipment
	check(sword.speed_bonus == -2 and sword.atk_bonus == 44 and sword.quality == Item.Quality.EPIC, "real signed fixture stats")
	var panel: Control = load("res://scenes/ui/character_panel.tscn").instantiate()
	root.add_child(panel)
	panel.open()
	for i in range(5): await process_frame
	var equipment_list: VBoxContainer = panel.get("_equipment_list")
	check(equipment_list.get_child_count() == 6, "six equipment slots remain")
	for button: Control in equipment_list.get_children():
		check(button.get_global_rect().end.y <= panel.get("_panel").get_global_rect().end.y, "slot fits visible panel " + button.name)
		check(button.get_node("EquipmentSlotIcon").texture != null, "slot has equipment/fallback icon " + button.name)
		check(button.get_node("EquipmentSlotLabel").text != "", "slot type label " + button.name)
	var hands_icon: TextureRect = equipment_list.get_child(3).get_node("EquipmentSlotIcon")
	var shoes_icon: TextureRect = equipment_list.get_child(4).get_node("EquipmentSlotIcon")
	check(hands_icon.texture.resource_path.ends_with("icon_leather_bracers.png"), "empty hands slot uses a bracer rather than glove silhouette")
	check(shoes_icon.texture.resource_path.ends_with("icon_deer_leather_boots.png"), "empty shoes slot uses leather boots rather than straw sandals")
	# Rebuild uses queue_free: Godot may uniquify same-frame child names.
	# Inventory.all_slots order is the actual six-slot public UI contract.
	var weapon: Button = equipment_list.get_child(0)
	check(weapon.get_node("EquipmentSlotName").text == sword.display_name, "slot name is equipped item")
	check(weapon.get_node("EquipmentSlotName").get_theme_color("font_color").is_equal_approx(Color("#b56cff")), "purple item name")
	check(weapon.get_node("EquipmentSlotIcon").texture.resource_path == sword.icon_path, "same real sword icon")
	var tooltip: Control = weapon.call("_make_custom_tooltip", weapon.tooltip_text)
	var hover: RichTextLabel = tooltip.find_child("EquipmentTooltipStats",true,false)
	check(hover.text.contains("[color=#ff8770]速度 -2[/color]") and hover.text.contains("[color=#72d2a6]攻击 +44[/color]"), "hover uses signed rows")
	tooltip.free()
	# Real native mouse GUI event sent through the Viewport, not button.pressed.emit.
	await click(weapon, MOUSE_BUTTON_LEFT)
	check(panel.get("_selected_inventory_instance_id") == instance, "left click selects worn instance")
	var detail: RichTextLabel = panel.get("_inventory_detail_label")
	check(detail.text.contains(sword.display_name) and detail.text.contains("[color=#ff8770]速度 -2[/color]") and detail.text.contains("[color=#72d2a6]攻击 +44[/color]"), "persistent detail shows name and signed intrinsic bonuses")
	check(panel.get("_inventory_detail_icon").texture.resource_path == sword.icon_path, "persistent detail icon matches slot")
	var selected_text := detail.text
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(20,900)
	root.push_input(motion,true)
	await process_frame
	check(detail.text == selected_text, "details persist when pointer leaves slot")
	var action: Button = panel.get("_inventory_action_button")
	check(action.visible and not action.disabled and action.text == "卸下", "selected worn item offers explicit unequip action")
	# Negative base arithmetic: -1 minus -2 is +1, -4 minus -2 is -2.
	var candidate := sword.duplicate(true) as Equipment
	candidate.speed_bonus = -1
	check(panel.call("_equipment_comparison_delta_bbcode", candidate, sword).contains("[color=#73d99b]速度 +1[/color]"), "negative-to-less-negative comparison is positive")
	candidate.speed_bonus = -4
	check(panel.call("_equipment_comparison_delta_bbcode", candidate, sword).contains("[color=#ff8770]速度 -2[/color]"), "negative-to-more-negative comparison is negative")
	# Heavy iron has no special effect: use a real effect-bearing purple item
	# for the quality-color contract instead of pretending it owns an effect.
	var special := load("res://data/equipment/dragon_tendon_staff.tres") as Equipment
	if special == null:
		check(false, "real special weapon exists")
	else:
		var quality: String = panel.QUALITY_COLORS[special.quality]
		check(not special.special_effect_description.is_empty() and STATS.bbcode(special,quality).contains("[color=%s]◆" % quality), "special effect uses actual item quality color")
	inv.equipped_changed.connect(func(_slot: int, item: Equipment):
		if item == null: unequip_events += 1)
	weapon = equipment_list.get_child(0)
	await click(weapon,MOUSE_BUTTON_RIGHT)
	check(inv.get_equipped_for(&"protagonist",0) == null and unequip_events == 1, "right press unequips exactly once")
	check(inv.find_slot_by_instance(instance).item == sword, "unequip preserves same backpack instance")
	check(inv.equip_instance_for(&"protagonist",instance), "re-equip for touch contract")
	panel.call("_set_inventory_filter", "consumable")
	await process_frame
	check(panel.get("_selected_inventory_instance_id") != instance, "touch starts without stale selected weapon")
	weapon = equipment_list.get_child(0)
	await tap(weapon)
	check(panel.get("_selected_inventory_instance_id") == instance and action.text == "卸下", "touch selects persistent equipped detail")
	await tap(action)
	check(inv.get_equipped_for(&"protagonist",0) == null and unequip_events == 2, "visible touch action unequips once")
	for key: String in ["all","equipment","consumable","key","material"]:
		var filter: Button = panel.get("_inventory_filter_buttons")[key]
		await click(filter,MOUSE_BUTTON_LEFT)
		check(panel.get("_inventory_filter") == key, "filter remains operable " + key)
	var character_list: VBoxContainer = panel.get("_character_list")
	check(character_list.get_child_count() == 2, "party cards retained")
	await click(character_list.get_child(1),MOUSE_BUTTON_LEFT)
	check(panel.get("_selected_character_id") == &"tang_xingzhou", "team member selector still works")
	await click(character_list.get_child(0),MOUSE_BUTTON_LEFT)
	check(panel.get("_selected_character_id") == &"protagonist", "protagonist selector still works")
	panel.close()
	check(not panel.visible, "close remains usable")
	panel.queue_free()
	await process_frame
	print("[EquipmentSigned] checks=%d failed=%d" % [checks,failed])
	quit(1 if failed else 0)

func click(control: Control, button: MouseButton) -> void:
	var point := control.get_global_rect().get_center()
	for down: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = button
		event.pressed = down
		root.push_input(event,true)
		await process_frame
	await process_frame

func tap(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	for down: bool in [true,false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = down
		# Input, unlike Viewport.push_input, applies the project's native
		# emulate_mouse_from_touch setting before GUI Button dispatch.
		Input.parse_input_event(event)
		await process_frame
	await process_frame
