extends Node

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_reset_state()
	_test_consumable_use_heals_and_consumes()
	_test_equipment_slots_and_bonuses_roundtrip()
	_test_duplicate_equipment_instances()
	if _failures > 0:
		push_error("[M5 Inventory Test] %d failure(s)" % _failures)
	get_tree().quit(_failures)


func _reset_state() -> void:
	GameState.reset_for_new_game()
	GameState.player.hp = 70
	GameState.player.mp = 10
	Inventory.from_dict({})


func _test_consumable_use_heals_and_consumes() -> void:
	Inventory.add_item(&"healing_pill_minor", 2)
	var used := Inventory.use_item(&"healing_pill_minor")
	_expect(used, "healing_pill_minor can be used in field")
	_expect_eq(GameState.player.hp, 150, "healing_pill_minor heals its configured 80 HP")
	_expect_eq(Inventory.count_of(&"healing_pill_minor"), 1, "using consumable consumes one item")

	GameState.player.hp = GameState.player.max_hp
	var used_at_full_hp := Inventory.use_item(&"healing_pill_minor")
	_expect(not used_at_full_hp, "HP-only consumable is not consumed at full HP")
	_expect_eq(Inventory.count_of(&"healing_pill_minor"), 1, "failed use keeps item count")

	Inventory.add_item(&"mana_pill", 1)
	var used_mp := Inventory.use_item(&"mana_pill")
	_expect(used_mp, "mana_pill can be used in field")
	_expect_eq(GameState.player.mp, 60, "mana_pill restores its configured 50 MP")


func _test_equipment_slots_and_bonuses_roundtrip() -> void:
	for item_id in [&"iron_sword", &"cloth_armor", &"straw_sandals", &"jade_ring"]:
		Inventory.add_item(item_id, 1)
		_expect(Inventory.equip(item_id), "can equip %s" % String(item_id))

	_expect_eq(Inventory.get_equipped_id(Equipment.Slot.WEAPON), &"iron_sword", "weapon slot equipped")
	_expect_eq(Inventory.get_equipped_id(Equipment.Slot.ARMOR), &"cloth_armor", "armor slot equipped")
	_expect_eq(Inventory.get_equipped_id(Equipment.Slot.SHOES), &"straw_sandals", "shoes slot equipped")
	_expect_eq(Inventory.get_equipped_id(Equipment.Slot.ACCESSORY), &"jade_ring", "accessory slot equipped")
	_expect_eq(Inventory.get_atk_bonus(), 10, "rebalanced weapon attack is aggregated once")
	_expect_eq(Inventory.get_def_bonus(), 2, "def bonus matches equipped armor")
	_expect_eq(Inventory.get_speed_bonus(), 3, "sword agility and speed stack with equipped shoes")
	_expect(is_equal_approx(Inventory.get_crit_chance_bonus(), 0.03), "weapon crit chance is aggregated")
	var sword_bonus: Dictionary = Inventory.get_equipped_skill_bonus("generic", &"sword")
	_expect_eq(int(sword_bonus.get("weapon_scaling", 0)), 4, "iron sword adds its visible sword-technique scaling")

	var saved := Inventory.to_dict()
	Inventory.from_dict(saved)
	_expect_eq(Inventory.get_equipped_id(Equipment.Slot.WEAPON), &"iron_sword", "weapon restored from save")
	_expect_eq(Inventory.get_equipped_id(Equipment.Slot.SHOES), &"straw_sandals", "shoes restored from save")
	_expect_eq(Inventory.get_equipped_id(Equipment.Slot.ACCESSORY), &"jade_ring", "accessory restored from save")


func _test_duplicate_equipment_instances() -> void:
	Inventory.from_dict({})
	_expect(Inventory.add_item(&"straw_sandals", 2), "two copies of the same equipment can be stored")
	var instance_ids: Array[String] = []
	for slot_entry: Dictionary in Inventory.slots:
		var item: Item = slot_entry.get("item")
		if item != null and item.item_id == &"straw_sandals":
			instance_ids.append(String(slot_entry.get("instance_id", "")))
	_expect_eq(instance_ids.size(), 2, "duplicate equipment occupies two inventory slots")
	_expect(instance_ids.size() == 2 and instance_ids[0] != instance_ids[1], "duplicate equipment has unique instance ids")
	if instance_ids.size() != 2:
		return
	_expect(Inventory.equip_instance(instance_ids[0]), "first equipment instance can be equipped")
	_expect(Inventory.is_instance_equipped(instance_ids[0]), "equipped state belongs to the selected instance")
	_expect(not Inventory.is_instance_equipped(instance_ids[1]), "the duplicate instance remains unequipped")
	_expect(Inventory.remove_item(&"straw_sandals", 1), "selling one duplicate equipment succeeds")
	_expect(Inventory.find_slot_by_instance(instance_ids[1]).is_empty(), "selling prefers the unequipped duplicate")
	_expect(Inventory.is_instance_equipped(instance_ids[0]), "selling duplicate keeps the equipped instance")
	var saved: Dictionary = Inventory.to_dict()
	Inventory.from_dict(saved)
	_expect(Inventory.is_instance_equipped(instance_ids[0]), "equipment instance id survives save migration")


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		push_error("[FAIL] %s" % message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s (expected=%s actual=%s)" % [message, str(expected), str(actual)])
