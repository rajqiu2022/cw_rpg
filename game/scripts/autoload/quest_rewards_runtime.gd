extends "res://scripts/autoload/quest_manager.gd"

const TIP := preload("res://scripts/ui/quest_reward_tip.gd")
const PENDING_KEY := "__pending_quest_items"
const GOLD := Color("#ffcf74")
const EXPERIENCE := Color("#88dcf3")
const ITEM := Color("#b9e8b2")
const PENDING := Color("#f2ba82")
const ITEM_FALLBACK := preload("res://art/ui/inventory/icons/icon_scroll_sm.png")
const MOUNTAIN_PATROL := &"q_ch1_side_08_mountain_patrol"

var _reward_tip := TIP.new()
var _pending_items: Dictionary = {}
var _delivering := false
var _granting_reward_item := false


func _ready() -> void:
	super._ready()
	_reward_tip.name = "QuestRewardTip"
	add_child(_reward_tip)
	Inventory.slots_changed.connect(_schedule_pending_delivery)


func get_tracked_side_quest() -> QuestDef:
	var quest := super.get_tracked_side_quest()
	if quest == null:
		return null
	for index in range(quest.progress_records.size() - 1, -1, -1):
		var record := quest.progress_records[index]
		var destination := String(record.get("tracker_hint", ""))
		if not destination.is_empty() and _trigger_historically_satisfied(String(record.get("trigger", ""))):
			var tracked := quest.duplicate() as QuestDef
			tracked.tracker_hint = destination
			return tracked
	return quest


func _grant_rewards(def: QuestDef) -> void:
	var rows: Array[Dictionary] = []
	var previous_skills: Array[StringName] = []
	if GameState.player != null:
		previous_skills.assign(GameState.player.skills)
	var previous_pending := GameState.pending_skill_unlocks.duplicate()
	var without_items := def.duplicate() as QuestDef
	without_items.reward_items = []
	super._grant_rewards(without_items)
	if def.reward_gold > 0:
		rows.append(_row("金钱", "+%d 两" % def.reward_gold, GOLD))
	if def.reward_exp > 0 and GameState.player != null:
		rows.append(_row("经验", "+%d" % def.reward_exp, EXPERIENCE))
		rows.append(_row("阅历", "+%d" % def.reward_exp, EXPERIENCE))
	for entry in def.reward_items:
		var id := StringName(entry.get("id", entry.get("item_id", "")))
		var quantity := int(entry.get("count", 1))
		var item := Inventory.load_item_by_id(id) if id != &"" and quantity > 0 else null
		if item == null:
			continue
		var delivered := _deliverable_count(item, quantity)
		if delivered > 0:
			_add_reward_item(id, delivered)
			rows.append(_row(item.display_name, "×%d" % delivered, ITEM, item))
		var remaining := quantity - delivered
		if remaining > 0:
			_pending_items[id] = int(_pending_items.get(id, 0)) + remaining
			rows.append(_row("待入包 · " + item.display_name, "×%d" % remaining, PENDING, item))
	if GameState.player != null:
		for skill_id: StringName in GameState.player.skills:
			if skill_id not in previous_skills or skill_id in def.reward_skills:
				rows.append(_row("习得", GameState._skill_display_name(skill_id), ITEM))
	for skill_id: StringName in GameState.pending_skill_unlocks:
		if skill_id not in previous_pending or skill_id in def.reward_skills:
			var skill := GameState._load_skill(skill_id)
			var requirement := "有效悟性达到 %d 时领悟" % skill.get_required_insight()
			rows.append(_row(GameState._skill_display_name(skill_id), requirement, PENDING))
	_reward_tip.enqueue("任务完成", def.title, rows)


func _row(label: String, value: String, color: Color, item: Item = null) -> Dictionary:
	var row := {"label": label, "value": value, "color": color}
	if item != null:
		var icon := load(item.icon_path) as Texture2D if not item.icon_path.is_empty() and ResourceLoader.exists(item.icon_path) else null
		row["icon"] = icon if icon != null else ITEM_FALLBACK
	return row


func grant_companion_manuals(companion_name: String, ids: Array) -> void:
	var rows: Array[Dictionary] = []
	for id: StringName in ids:
		var item := Inventory.load_item_by_id(id)
		if item == null or Inventory.has_item(id) or _pending_items.has(id) or item.study_skill_id in GameState.player.skills:
			continue
		if _deliverable_count(item, 1) > 0:
			_add_reward_item(id, 1)
			rows.append(_row(item.display_name, "×1", ITEM, item))
		else:
			_pending_items[id] = 1
			rows.append(_row("待入包 · " + item.display_name, "×1", PENDING, item))
	if not rows.is_empty():
		_reward_tip.enqueue("同行赠礼", companion_name, rows)


func _add_reward_item(id: StringName, quantity: int) -> void:
	var was_granting := _granting_reward_item
	_granting_reward_item = true
	Inventory.add_item(id, quantity)
	_granting_reward_item = was_granting


func _deliverable_count(item: Item, quantity: int) -> int:
	var stack_size := item.max_stack if item.stackable else 1
	var space := maxi(0, Inventory.MAX_SLOTS - Inventory.slots.size()) * stack_size
	if item.stackable:
		for slot: Dictionary in Inventory.slots:
			if slot.get("item") == item:
				space += maxi(0, stack_size - int(slot.get("count", 0)))
	return mini(space, quantity)


func _schedule_pending_delivery() -> void:
	if not _delivering and not _pending_items.is_empty():
		_deliver_pending.call_deferred()


func _deliver_pending() -> void:
	_delivering = true
	var rows: Array[Dictionary] = []
	for id: StringName in _pending_items.keys():
		var item := Inventory.load_item_by_id(id)
		if item == null:
			continue
		var quantity := int(_pending_items[id])
		var delivered := _deliverable_count(item, quantity)
		if delivered == quantity:
			_pending_items.erase(id)
		else:
			_pending_items[id] = quantity - delivered
		if delivered > 0:
			_add_reward_item(id, delivered)
			rows.append(_row(item.display_name, "×%d" % delivered, ITEM, item))
	_delivering = false
	if not rows.is_empty():
		_reward_tip.enqueue("奖励已入包", "任务奖励", rows)


func _on_item_picked_up(id: StringName, count: int) -> void:
	if count <= 0:
		return
	var field := get_tree().current_scene
	if not _granting_reward_item and is_instance_valid(field) and field.has_meta("uses_reward_pickup_tip"):
		var item := Inventory.load_item_by_id(id)
		var item_name := item.display_name if item != null else String(id)
		var quality_colors := ["#c0c8d0", "#1eff00", "#67afff", "#cb83ff", "#ffae59"]
		var color := Color(quality_colors[int(item.quality)] if item != null and int(item.quality) < quality_colors.size() else quality_colors[0])
		if item != null and item.category == Item.Category.CONSUMABLE:
			color = Color("#e3a64a")
		var row := _row(item_name, "× %d" % count, Color("#f2eadb"), item)
		row["label_color"] = color
		var hint := ""
		if id == &"linxi_iron_sword" and not bool(GameState.get_flag(&"seen_linxi_sword_equip_tip")):
			hint = "装备剑后，方可使用林西剑法。"
			GameState.set_flag(&"seen_linxi_sword_equip_tip", true)
		_reward_tip.enqueue("获得物品", hint, [row], true)
	super._on_item_picked_up(id, count)


func complete(qid: StringName) -> bool:
	if qid == MOUNTAIN_PATROL and GameState.get_flag(&"mountain_patrol_bandits_repelled") != true:
		return false
	return super.complete(qid)


func _on_enemy_defeated(id: StringName) -> void:
	super._on_enemy_defeated(id)
	if id == &"bandit_mountain" and is_active(MOUNTAIN_PATROL) and StringName(SceneRouter.get_battle_payload().get("return_scene", "")) == &"ch1_s1_road":
		if GameState.get_flag(&"mountain_patrol_bandits_repelled") != true:
			GameState.set_flag(&"mountain_patrol_bandits_repelled", true)


func to_dict() -> Dictionary:
	var data := super.to_dict()
	if not _pending_items.is_empty():
		data[PENDING_KEY] = _pending_items.duplicate()
	return data


func from_dict(data: Dictionary) -> void:
	_reward_tip.clear()
	_pending_items.clear()
	var pending: Variant = data.get(PENDING_KEY, {})
	if pending is Dictionary:
		for id: Variant in pending:
			if int(pending[id]) > 0:
				_pending_items[StringName(id)] = int(pending[id])
	var progress := data.duplicate()
	progress.erase(PENDING_KEY)
	super.from_dict(progress)
	_schedule_pending_delivery()


func reset_for_new_game() -> void:
	_reward_tip.clear()
	_pending_items.clear()
	super.reset_for_new_game()
