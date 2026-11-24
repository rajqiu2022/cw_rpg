extends RefCounted
## Pure in-memory inventory transaction; no SaveManager, scene, quest or reward.
## Never call Inventory.add_item/remove_item here: they mutate/emit incrementally.
const RECIPES = preload("res://scripts/life_skills/recipes.gd")
const HERBS := preload("res://scripts/life_skills/field_herbs.gd")
const TEMPER := preload("res://scripts/life_skills/weapon_tempering.gd")
const ALLOWED_MATERIALS := ["herb_bundle", "iron_ore"]
const MAX_QUANTITY := 10
static var _busy: bool = false

static func is_busy() -> bool:
	return _busy


static func preview_temper(instance_id: String, station: String) -> Dictionary:
	if _busy or station != "blacksmith":
		return {"ok": false, "message": "需要在铁匠铺升级。"}
	var weapon := Inventory.find_slot_by_instance(instance_id).get("item") as Equipment
	if weapon == null or weapon.slot != Equipment.Slot.WEAPON:
		return {"ok": false, "message": "没有这件武器。"}
	var rank := weapon.forge_rank
	if rank >= TEMPER.MAX_RANK:
		return {"ok": false, "message": "已达 +3，不可重铸词条。"}
	var ore: int = TEMPER.ORE[rank]
	var gold: int = TEMPER.GOLD[rank]
	var enough := Inventory.count_of(&"iron_ore") >= ore and GameState.gold >= gold
	return {"ok": enough, "rank": rank + 1, "ore": ore, "gold": gold,
		"message": "" if enough else "铁矿或工钱不足。"}


static func temper(instance_id: String, station: String, expected_rank: int) -> Dictionary:
	var plan := preview_temper(instance_id, station)
	if not plan.ok:
		return plan
	if int(plan.rank) != expected_rank:
		return {"ok": false, "message": "武器已变化，请重新确认。"}
	var current := Inventory.find_slot_by_instance(instance_id).item as Equipment
	var base := Inventory.load_item_by_id(current.item_id) as Equipment
	if base == null or base.slot != Equipment.Slot.WEAPON:
		return {"ok": false, "message": "原武器数据不可用。"}
	var updated: Array[Dictionary] = []
	var ore_left: int = plan.ore
	for old: Dictionary in Inventory.slots:
		var entry := old.duplicate()
		var item := entry.item as Item
		if item != null and item.item_id == &"iron_ore" and item.stackable and String(entry.instance_id).is_empty():
			var debit := mini(int(entry.count), ore_left)
			entry.count = int(entry.count) - debit
			ore_left -= debit
			if int(entry.count) == 0:
				continue
		updated.append(entry)
	if ore_left != 0:
		return {"ok": false, "message": "铁矿状态异常，未扣费。"}
	_busy = true
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var affixes: Array[String] = []
	if expected_rank == TEMPER.MAX_RANK:
		affixes = TEMPER.roll_affixes(base, rng)
	var weapon := TEMPER.make_weapon(base, expected_rank, affixes)
	for entry: Dictionary in updated:
		if String(entry.instance_id) == instance_id:
			entry.item = weapon
			break
	Inventory.commit_weapon_temper(updated, weapon, instance_id, GameState.gold - int(plan.gold))
	EventBus.item_dropped.emit(&"iron_ore", int(plan.ore))
	_busy = false
	return {"ok": true, "message": "已完成：%s%s" % [weapon.display_name, " · 新词条已入装备详情" if not affixes.is_empty() else ""]}

static func preview(recipe_id: String, quantity: int, station: String, stock: Array = []) -> Dictionary:
	if _busy:
		return _failure("BUSY", "正在制作，请稍候。", recipe_id, quantity, station)
	return _public_result(_plan(recipe_id, quantity, station, stock))

static func craft(recipe_id: String, quantity: int, station: String, stock: Array = []) -> Dictionary:
	if _busy:
		return _failure("BUSY", "正在制作，请稍候。", recipe_id, quantity, station)
	_busy = true
	var plan: Dictionary = _plan(recipe_id, quantity, station, stock)
	if not bool(plan.ok):
		_busy = false
		return _public_result(plan)
	# No awaits or events between planning and the complete state commit.
	# Dictionary copies retain the original Item references and equipped instances.
	Inventory.slots.assign(plan._slots)
	Inventory.set("_next_instance_serial", int(plan._serial))
	GameState.gold = int(plan.gold_after)
	var result: Dictionary = _public_result(plan)
	result["crafted"] = true
	# Every synchronous observer sees all three committed values. Keep the lock
	# through every callback, so slots/gold listeners cannot spend twice via craft.
	Inventory.slots_changed.emit()
	for row: Dictionary in plan.materials:
		EventBus.item_dropped.emit(StringName(row.item_id), int(row.required))
	EventBus.item_picked_up.emit(StringName(plan.output), int(plan.output_count))
	if int(plan.gold) > 0:
		GameState.gold_changed.emit(GameState.gold)
		EventBus.gold_changed.emit(GameState.gold)
	_busy = false
	return result

static func _plan(recipe_id: String, quantity: int, station: String, stock: Array) -> Dictionary:
	var result: Dictionary = _failure("UNKNOWN_RECIPE", "没有这种配方。", recipe_id, quantity, station)
	var recipe: Dictionary = RECIPES.find(recipe_id)
	if recipe.is_empty():
		return result
	result["recipe"] = recipe
	result["output"] = String(recipe.output)
	result["min_level"] = int(recipe.min_level)
	if quantity < 1 or quantity > MAX_QUANTITY:
		return _reject(result, "INVALID_QUANTITY", "每次只能制作1至10份。")
	result["output_count"] = int(recipe.count) * quantity
	result["gold"] = int(recipe.gold) * quantity
	var ingredients: Dictionary = {}
	for material: String in recipe.ingredients:
		if (material not in ALLOWED_MATERIALS and not HERBS.is_material(material)) or int(recipe.ingredients[material]) <= 0:
			return _reject(result, "INVALID_RECIPE", "配方材料无效。")
		ingredients[material] = int(recipe.ingredients[material]) * quantity
	result["ingredients"] = ingredients
	if station != String(recipe.station):
		return _reject(result, "WRONG_STATION", "此处不能使用该配方。")
	var level: int = GameState.player.level if GameState.player != null else 0
	result["level"] = level
	if level < int(recipe.min_level):
		return _reject(result, "LEVEL_REQUIRED", "需要达到%d级。" % int(recipe.min_level))
	if bool(recipe.require_stock) and not RECIPES.stock_has(stock, String(recipe.output)):
		return _reject(result, "STOCK_REQUIRED", "这位铁匠尚不能锻造此物。")
	var output: Item = Inventory.load_item_by_id(StringName(recipe.output))
	if output == null or output.item_id != StringName(recipe.output) or output.max_stack < 1:
		return _reject(result, "OUTPUT_UNAVAILABLE", "制作物品的资源不可用。")
	if (station == "blacksmith" and (not output is Equipment or output.stackable)) or (station == "medicine" and not output.stackable):
		return _reject(result, "OUTPUT_UNAVAILABLE", "制作物品的类型无效。")
	var slots: Array[Dictionary] = []
	var used_ids: Dictionary = {}
	for existing: Dictionary in Inventory.slots:
		var item: Item = existing.get("item") as Item
		var amount: int = int(existing.get("count", 0))
		var instance_id: String = String(existing.get("instance_id", ""))
		if item == null or amount <= 0 or (not item.stackable and (amount != 1 or instance_id.is_empty())):
			return _reject(result, "INVALID_INVENTORY", "背包数据无效，无法制作。")
		if not instance_id.is_empty():
			if used_ids.has(instance_id):
				return _reject(result, "INVALID_INVENTORY", "背包装备编号重复。")
			used_ids[instance_id] = true
		slots.append(existing.duplicate())
	if slots.size() > Inventory.MAX_SLOTS:
		return _reject(result, "INVALID_INVENTORY", "背包格数无效。")
	var serial: int = int(Inventory.get("_next_instance_serial"))
	if serial < 1 or serial > 9223372036854775700:
		return _reject(result, "INVALID_INVENTORY", "背包装备编号无效。")
	result["slots_before"] = slots.size()
	result["gold_before"] = GameState.gold
	result["gold_after"] = GameState.gold - int(result.gold)
	var materials: Array[Dictionary] = []
	var missing: Array[Dictionary] = []
	for material: String in ingredients:
		var owned: int = 0
		for slot: Dictionary in slots:
			var item: Item = slot.item
			if String(item.item_id) == material:
				# Consuming materials must never unequip or alter a physical instance.
				if item is Equipment or not item.stackable or not String(slot.get("instance_id", "")).is_empty():
					return _reject(result, "INVALID_INVENTORY", "材料背包数据无效。")
				owned += int(slot.count)
		var row: Dictionary = {"item_id":material,"required":int(ingredients[material]),"owned":owned,"missing":maxi(0, int(ingredients[material]) - owned)}
		materials.append(row)
		if int(row.missing) > 0:
			missing.append(row.duplicate())
	result["materials"] = materials
	result["missing_materials"] = missing
	if not missing.is_empty():
		return _reject(result, "MISSING_MATERIALS", "制作材料不足。")
	if GameState.gold < int(result.gold):
		return _reject(result, "INSUFFICIENT_GOLD", "工钱不足。")
	# Reverse order matches normal Inventory.remove_item for these non-equipped
	# materials. Fully consumed stacks are removed before capacity is calculated.
	for material: String in ingredients:
		var remaining: int = int(ingredients[material])
		for i: int in range(slots.size() - 1, -1, -1):
			if remaining == 0:
				break
			var item: Item = slots[i].item
			if String(item.item_id) != material:
				continue
			var take: int = mini(int(slots[i].count), remaining)
			slots[i]["count"] = int(slots[i].count) - take
			remaining -= take
			if int(slots[i].count) == 0:
				slots.remove_at(i)
	var remaining_output: int = int(result.output_count)
	if output.stackable:
		for slot: Dictionary in slots:
			if remaining_output == 0:
				break
			var item: Item = slot.item
			if item.item_id != output.item_id:
				continue
			var put: int = mini(maxi(0, output.max_stack - int(slot.count)), remaining_output)
			slot["count"] = int(slot.count) + put
			remaining_output -= put
	var created_instances: Array[String] = []
	while remaining_output > 0:
		if slots.size() >= Inventory.MAX_SLOTS:
			return _reject(result, "INVENTORY_FULL", "背包空间不足。")
		var put: int = mini(output.max_stack if output.stackable else 1, remaining_output)
		var instance_id: String = ""
		if not output.stackable:
			# Same <item_id>#<serial> rule and collision skipping as Inventory.
			while instance_id.is_empty() or used_ids.has(instance_id):
				instance_id = "%s#%d" % [String(output.item_id), serial]
				serial += 1
			used_ids[instance_id] = true
			created_instances.append(instance_id)
		slots.append({"item":output,"count":put,"instance_id":instance_id})
		remaining_output -= put
	result["ok"] = true
	result["reason"] = "OK"
	result["message"] = "可以制作。"
	result["slots_after"] = slots.size()
	result["created_instances"] = created_instances
	result["_slots"] = slots
	result["_serial"] = serial
	return result

static func _failure(reason: String, message: String, recipe_id: String, quantity: int, station: String) -> Dictionary:
	return {"ok":false,"reason":reason,"message":message,"recipe_id":recipe_id,"quantity":quantity,"station":station,"crafted":false}

static func _reject(result: Dictionary, reason: String, message: String) -> Dictionary:
	result["ok"] = false
	result["reason"] = reason
	result["message"] = message
	return result

static func _public_result(plan: Dictionary) -> Dictionary:
	var result: Dictionary = plan.duplicate(true)
	result.erase("_slots")
	result.erase("_serial")
	return result
