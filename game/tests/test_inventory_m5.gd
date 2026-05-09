extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_reset_state()
	_test_consumable_use_heals_and_consumes()
	_test_equipment_slots_and_bonuses_roundtrip()
	if _failures > 0:
		push_error("[M5 Inventory Test] %d failure(s)" % _failures)
	quit(_failures)


func _reset_state() -> void:
	GameState.reset_for_new_game()
	GameState.player.hp = 70
	GameState.player.mp = 10
	Inventory.from_dict({})


func _test_consumable_use_heals_and_consumes() -> void:
	Inventory.add_item(&"healing_pill_minor", 2)
	var used := Inventory.use_item(&"healing_pill_minor")
	_expect(used, "healing_pill_minor can be used in field")
	_expect_eq(GameState.player.hp, 100, "healing_pill_minor heals 30 HP")
	_expect_eq(Inventory.count_of(&"healing_pill_minor"), 1, "using consumable consumes one item")

	GameState.player.hp = GameState.player.max_hp
	var used_at_full_hp := Inventory.use_item(&"healing_pill_minor")
	_expect(not used_at_full_hp, "HP-only consumable is not consumed at full HP")
	_expect_eq(Inventory.count_of(&"healing_pill_minor"), 1, "failed use keeps item count")

	Inventory.add_item(&"mana_pill", 1)
	var used_mp := Inventory.use_item(&"mana_pill")
	_expect(used_mp, "mana_pill can be used in field")
	_expect_eq(GameState.player.mp, 25, "mana_pill restores 15 MP")


func _test_equipment_slots_and_bonuses_roundtrip() -> void:
	for item_id in [&"iron_sword", &"cloth_armor", &"straw_sandals", &"jade_ring"]:
		Inventory.add_item(item_id, 1)
		_expect(Inventory.equip(item_id), "can equip %s" % String(item_id))

	_expect_eq(Inventory.get_equipped_id(Equipment.Slot.WEAPON), &"iron_sword", "weapon slot equipped")
	_expect_eq(Inventory.get_equipped_id(Equipment.Slot.ARMOR), &"cloth_armor", "armor slot equipped")
	_expect_eq(Inventory.get_equipped_id(Equipment.Slot.SHOES), &"straw_sandals", "shoes slot equipped")
	_expect_eq(Inventory.get_equipped_id(Equipment.Slot.ACCESSORY), &"jade_ring", "accessory slot equipped")
	_expect_eq(Inventory.get_atk_bonus(), 6, "atk bonus includes weapon and accessory")
	_expect_eq(Inventory.get_def_bonus(), 4, "def bonus includes armor and accessory")
	_expect_eq(Inventory.get_speed_bonus(), 2, "speed bonus includes shoes")

	var saved := Inventory.to_dict()
	Inventory.from_dict(saved)
	_expect_eq(Inventory.get_equipped_id(Equipment.Slot.WEAPON), &"iron_sword", "weapon restored from save")
	_expect_eq(Inventory.get_equipped_id(Equipment.Slot.SHOES), &"straw_sandals", "shoes restored from save")
	_expect_eq(Inventory.get_equipped_id(Equipment.Slot.ACCESSORY), &"jade_ring", "accessory restored from save")


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		push_error("[FAIL] %s" % message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s (expected=%s actual=%s)" % [message, str(expected), str(actual)])
