extends Node

var _failures: int = 0


func _ready() -> void:
	_test_duplicate_equipment_instances()
	_test_legacy_save_migration()
	if _failures == 0:
		print("[PASS] inventory equipment instance regression")
	else:
		push_error("[FAIL] inventory equipment instance regression: %d failure(s)" % _failures)
	get_tree().quit(_failures)


func _test_duplicate_equipment_instances() -> void:
	Inventory.from_dict({})
	_expect(Inventory.add_item(&"straw_sandals", 2), "two straw sandals can be added")
	_expect(Inventory.count_of(&"straw_sandals") == 2, "duplicate equipment is stored twice")

	var instance_ids: Array[String] = []
	for entry: Dictionary in Inventory.slots:
		var item: Item = entry.get("item")
		if item != null and item.item_id == &"straw_sandals":
			instance_ids.append(String(entry.get("instance_id", "")))

	_expect(instance_ids.size() == 2, "both equipment copies have slots")
	if instance_ids.size() != 2:
		return
	_expect(instance_ids[0] != "" and instance_ids[1] != "", "equipment instance ids are non-empty")
	_expect(instance_ids[0] != instance_ids[1], "same equipment type has unique instance ids")
	_expect(Inventory.equip_instance(instance_ids[0]), "specific equipment instance can be equipped")
	_expect(Inventory.is_instance_equipped(instance_ids[0]), "selected instance is equipped")
	_expect(not Inventory.is_instance_equipped(instance_ids[1]), "duplicate instance remains unequipped")

	_expect(Inventory.remove_item(&"straw_sandals", 1), "one duplicate can be sold/removed")
	_expect(Inventory.count_of(&"straw_sandals") == 1, "one straw sandal remains")
	_expect(Inventory.find_slot_by_instance(instance_ids[1]).is_empty(), "unequipped duplicate is removed first")
	_expect(Inventory.is_instance_equipped(instance_ids[0]), "equipped copy remains equipped")

	var saved: Dictionary = Inventory.to_dict()
	Inventory.from_dict(saved)
	_expect(Inventory.count_of(&"straw_sandals") == 1, "save/load preserves equipment copy")
	_expect(Inventory.get_equipped_instance_id(Equipment.Slot.SHOES) == instance_ids[0], "save/load preserves equipped instance")


func _test_legacy_save_migration() -> void:
	Inventory.from_dict({
		"slots": [{"item_id": "straw_sandals", "count": 2}],
		"equipped": {"shoes": "straw_sandals"},
	})
	var migrated_ids: Array[String] = []
	for entry: Dictionary in Inventory.slots:
		var item: Item = entry.get("item")
		if item != null and item.item_id == &"straw_sandals":
			migrated_ids.append(String(entry.get("instance_id", "")))
	_expect(migrated_ids.size() == 2, "legacy duplicate equipment is split into two slots")
	if migrated_ids.size() != 2:
		return
	_expect(migrated_ids[0] != migrated_ids[1], "legacy duplicate equipment receives unique instance ids")
	var equipped_count: int = 0
	for instance_id: String in migrated_ids:
		if Inventory.is_instance_equipped(instance_id):
			equipped_count += 1
	_expect(equipped_count == 1, "legacy save equips exactly one duplicate instance")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("[InventoryInstanceTest] %s" % message)
