extends SceneTree

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_validate_equipment_catalog()
	_validate_slot_fallbacks_and_quality_frames()
	_validate_palm_equipment()
	_finish()


func _validate_equipment_catalog() -> void:
	var dir := DirAccess.open("res://data/equipment")
	_check(dir != null, "equipment directory opens")
	if dir == null:
		return
	var total := 0
	var weapons := 0
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var equipment := load("res://data/equipment/%s" % file_name) as Equipment
			_check(equipment != null, "equipment loads: %s" % file_name)
			if equipment != null:
				total += 1
				if equipment.slot == Equipment.Slot.WEAPON:
					weapons += 1
					_check(not equipment.icon_path.is_empty(), "weapon owns an explicit icon: %s" % equipment.display_name)
				if not equipment.icon_path.is_empty():
					_check(ResourceLoader.exists(equipment.icon_path), "explicit equipment icon exists: %s" % equipment.display_name)
					var icon := load(equipment.icon_path) as Texture2D
					_check(icon != null and icon.get_width() >= 64 and icon.get_height() >= 64, "equipment icon has runtime resolution: %s" % equipment.display_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	_check(total >= 121, "full equipment catalog is audited")
	_check(weapons >= 42, "all weapon entries are audited")
	var immortal := load("res://data/equipment/immortal_gauntlets.tres") as Equipment
	_check(immortal != null and immortal.slot == Equipment.Slot.WEAPON, "仙尊护手 is a palm weapon")
	_check(immortal != null and immortal.icon_path.ends_with("icon_immortal_gauntlets_v1.png"), "仙尊护手 uses its dedicated gauntlet icon")


func _validate_slot_fallbacks_and_quality_frames() -> void:
	for path in ["res://scripts/ui/character_panel.gd", "res://scripts/ui/inventory_panel.gd"]:
		var source := FileAccess.get_file_as_string(path)
		_check(source.contains("ICON_HEAD"), "%s has a head-slot fallback" % path.get_file())
		_check(source.contains("ICON_HANDS"), "%s has a hand-slot fallback" % path.get_file())
		_check(source.contains("icon_leather_bracers.png"), "%s uses a real bracer silhouette for the hands slot" % path.get_file())
		_check(source.contains("icon_deer_leather_boots.png"), "%s uses leather boots instead of straw sandals for the shoes slot" % path.get_file())
		_check(not source.contains("const ICON_HANDS := preload(\"res://art/ui/inventory/icons/icon_silk_gloves.png\")"), "%s no longer uses gloves as the empty bracer icon" % path.get_file())
		_check(not source.contains("const ICON_SHOES := preload(\"res://art/ui/inventory/icons/icon_shoes.png\")"), "%s no longer uses the old straw-like empty shoes icon" % path.get_file())
		_check(not source.contains("Equipment.Slot.HEAD, Equipment.Slot.ARMOR, Equipment.Slot.HANDS"), "%s no longer maps three slots to armor" % path.get_file())
		_check(source.contains("QualityFrame"), "%s renders an inner quality border" % path.get_file())
		_check(source.contains("Item.Quality.LEGENDARY else"), "%s gives legendary equipment a thicker border" % path.get_file())


func _validate_palm_equipment() -> void:
	var ids := [
		"iron_knuckles", "steel_gauntlets", "tiger_claw_gloves", "thunder_gauntlets",
		"xuantong_fist_gauntlets", "diamond_gauntlets", "immortal_gauntlets",
	]
	var last_bonus := 0
	for id in ids:
		var equipment := load("res://data/equipment/%s.tres" % id) as Equipment
		_check(equipment != null, "palm hand equipment loads: %s" % id)
		_check(equipment != null and equipment.slot == Equipment.Slot.WEAPON, "%s occupies the weapon slot" % id)
		_check(equipment != null and equipment.get_martial_style() == &"palm", "%s explicitly strengthens palm arts" % id)
		_check(equipment != null and equipment.get_weapon_skill_scaling_bonus() > 0, "%s has a palm scaling bonus" % id)
		if equipment != null:
			last_bonus = maxi(last_bonus, equipment.get_weapon_skill_scaling_bonus())
	_check(last_bonus >= 20, "legendary palm hand gear reaches an orange-tier bonus")
	for skill_path in [
		"res://data/skills/palm_strike.tres",
		"res://data/skills/canghai_zhenyue_palms.tres",
		"res://data/skills/canglong_three_turns.tres",
	]:
		var skill := load(skill_path) as Skill
		_check(skill != null and skill.get_bonus_weapon_style() == &"palm", "%s is classified as a palm art" % skill_path.get_file())
	var inventory_source := FileAccess.get_file_as_string("res://scripts/autoload/inventory.gd")
	_check(inventory_source.contains("_weapon_style_matches(e.get_martial_style(), weapon_style)"), "non-weapon hand gear participates in martial-style bonuses")
	var inventory := root.get_node_or_null("Inventory")
	_check(inventory != null, "Inventory autoload is available for runtime palm bonus verification")
	if inventory == null:
		return
	inventory.call("reset_for_new_game")
	inventory.call("add_item", &"immortal_gauntlets", 1)
	var gauntlet_instance := ""
	for entry: Dictionary in inventory.get("slots"):
		var item := entry.get("item") as Item
		if item != null and item.item_id == &"immortal_gauntlets":
			gauntlet_instance = String(entry.get("instance_id", ""))
			break
	_check(not gauntlet_instance.is_empty() and bool(inventory.call("equip_instance_for", &"protagonist", gauntlet_instance)), "仙尊护手 can be equipped from the shared inventory")
	var palm_bonus := inventory.call("get_equipped_skill_bonus_for", &"protagonist", "generic", &"palm") as Dictionary
	var sword_bonus := inventory.call("get_equipped_skill_bonus_for", &"protagonist", "generic", &"sword") as Dictionary
	_check(int(palm_bonus.get("weapon_scaling", 0)) == 20, "仙尊护手 grants +20% to palm arts at runtime")
	_check(int(sword_bonus.get("weapon_scaling", 0)) == 0, "palm hand gear does not leak into sword arts")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _finish() -> void:
	print("[EquipmentIconsQualityPalm20260817] checks=%d failed=%d" % [checks, failures.size()])
	for failure in failures:
		push_error("[EquipmentIconsQualityPalm20260817] %s" % failure)
	quit(1 if not failures.is_empty() else 0)
