extends RefCounted
## Source-only normal discovery acceptance. No production dialogue/inventory edits.
## The owner must provide a fresh isolated SaveManager and checked evidence I/O.
const GEOMETRY := preload("res://tests/helpers/v15_geometry_oracle.gd")
var tree: SceneTree
var driver: RefCounted
var field_probe: RefCounted
var slots: Node
var check: Callable
var waiter: Callable
var intro: Callable
var screenshot: Callable
var geometry: RefCounted = GEOMETRY.new()

func configure(owner: SceneTree, input: RefCounted, probe: RefCounted, isolated_slots: Node, reporter: Callable, field_waiter: Callable, normal_intro: Callable, capture: Callable) -> void:
	tree = owner
	driver = input
	field_probe = probe
	slots = isolated_slots
	check = reporter
	waiter = field_waiter
	intro = normal_intro
	screenshot = capture

func _check(value: bool, message: String) -> void:
	check.call(value, message)

func _point(value: Variant) -> Vector2:
	return Vector2(float(value[0]), float(value[1])) if value is Array and value.size() == 2 else Vector2(INF, INF)

func _flag(state: Node, key: StringName) -> bool:
	return bool((state.get("flags") as Dictionary).get(String(key), false))

func _finish_dialog() -> bool:
	var dialog: Node = tree.root.get_node("DialogPlayer")
	for step in 40:
		if not bool(dialog.call("is_playing")): return true
		var node: DialogNode = dialog.get("_current_node") as DialogNode
		if node != null and not node.choices.is_empty(): dialog.call("choose", 0)
		else: await driver.call("key", KEY_SPACE)
		for settle in 4: await tree.process_frame
	_check(false, "discovery dialogue completes through ordinary UI advance")
	return false

func _click_original_entity() -> Dictionary:
	var field: Node = tree.current_scene
	var sprite: Sprite2D
	var area: Area2D
	for node: Node in field.get("_scene_object_nodes"):
		if node is Sprite2D and node.name == "SceneObject_discovery_cache": sprite = node as Sprite2D
	for node: Node in field.get("_trigger_areas"):
		if node is Area2D and node.name == "ObjectInteraction_discovery_cache": area = node as Area2D
	_check(sprite != null and area != null, "normal discovery entity and real interaction Area both exist")
	if sprite == null or area == null: return {"ok": false}
	var image: Image = geometry.call("image_for", sprite)
	var frame: Rect2i = geometry.call("frame", sprite, image)
	var rect: Rect2 = sprite.get_rect()
	var chosen := Vector2(INF, INF)
	var best: float = INF
	var alpha: float = 0.0
	if image == null or frame.size.x <= 0: return {"ok": false}
	for y in range(frame.size.y):
		for x in range(frame.size.x):
			var sample: Color = image.get_pixel(frame.position.x + x, frame.position.y + y)
			if sample.a <= .12: continue
			var local: Vector2 = rect.position + (Vector2(x, y) + Vector2(.5, .5)) / Vector2(frame.size) * rect.size
			var global: Vector2 = sprite.to_global(local)
			var inside := false
			for shape_node: Node in area.get_children():
				if shape_node is CollisionShape2D and shape_node.shape is RectangleShape2D:
					var size: Vector2 = shape_node.shape.size
					inside = Rect2(-size * .5, size).has_point(shape_node.to_local(global))
					break
			if not inside: continue
			var distance: float = local.distance_squared_to(rect.get_center())
			if distance < best:
				best = distance
				chosen = local
				alpha = sample.a
	_check(chosen.is_finite(), "click point is actual original entity alpha>.12 inside its real interaction shape")
	if not chosen.is_finite(): return {"ok": false}
	var viewport_point: Vector2 = sprite.get_global_transform_with_canvas() * chosen
	_check(tree.root.get_visible_rect().has_point(viewport_point), "original material entity click is visible, not offscreen or an arrow replacement")
	var event: Dictionary = await driver.call("pointer", viewport_point)
	return {"ok": true, "event": event, "original_alpha": alpha, "texture_path": sprite.texture.resource_path, "texture_sha256": FileAccess.get_sha256(sprite.texture.resource_path), "local_point": [chosen.x, chosen.y]}

func _replay(script: DialogScript, at: bool, inventory: Node, state: Node, item: StringName, flag: StringName) -> Dictionary:
	var before: Dictionary = inventory.call("to_dict")
	var was_claimed: bool = _flag(state, flag)
	var dialog: Node = tree.root.get_node("DialogPlayer")
	if at: dialog.call("play_at", script, script.entry_node_id)
	else: dialog.call("play", script)
	var live: DialogScript = dialog.get("_current_script") as DialogScript
	_check(bool(dialog.call("is_playing")) and live != null and live.dialog_id != script.dialog_id, "public %s uses real blocked fallback rather than reward nodes" % ("play_at" if at else "play"))
	await _finish_dialog()
	var unchanged: bool = inventory.call("to_dict") == before and _flag(state, flag) == was_claimed
	_check(unchanged, "public replay cannot award material or alter its once-only flag")
	return {"api": "play_at" if at else "play", "inventory_unchanged": unchanged, "claimed_before": was_claimed, "claimed_after": _flag(state, flag), "item_count": inventory.call("count_of", item)}

func run(entry: Dictionary) -> Dictionary:
	var ecology: String = String(entry.ecology)
	var item_ids := {"bamboo": &"herb_bundle", "forest": &"timber_bundle", "marsh": &"cloth_roll"}
	var result: Dictionary = {"scope": "LIMITED_NORMAL_MATERIAL_ENTITY_DIALOG_REPLAY_RELOAD_FULL_INVENTORY", "ecology": ecology, "scene_id": entry.scene_id, "replays": []}
	_check(item_ids.has(ecology), "only the three approved ordinary discoveries are tested")
	if not item_ids.has(ecology): return result
	var item: StringName = item_ids[ecology]
	var flag := StringName("outskirts_%s_material_found" % ecology)
	var script_path: String = "res://data/dialogs/outskirts_%s_discovery.tres" % ecology
	var script: DialogScript = load(script_path) as DialogScript
	_check(script != null and script.blocked_story_flag == flag and script.required_free_inventory_slots == 1, "actual discovery resource owns once-only and capacity gates")
	if script == null: return result
	var reward_node: DialogNode = script.get_entry_node()
	_check(reward_node != null and reward_node.give_items.size() == 1 and String(reward_node.give_items[0].get("id", "")) == String(item) and int(reward_node.give_items[0].get("count", 0)) == 1, "actual discovery reward is precisely the approved single material")
	result["dialog_path"] = script_path
	result["dialog_sha256"] = FileAccess.get_sha256(script_path)
	var inventory: Node = tree.root.get_node("Inventory")
	var state: Node = tree.root.get_node("GameState")
	var original_inventory: Dictionary = inventory.call("to_dict")
	var original_flags: Dictionary = (state.get("flags") as Dictionary).duplicate(true)
	inventory.call("reset_for_new_game")
	state.call("set_flag", flag, false) # Fresh test-owned in-memory fixture only.
	tree.root.get_node("SceneRouter").call("go_field_smart", StringName(entry.scene_id), _point(entry.art.return_foot_px) / Vector2(1536, 1024))
	if not await waiter.call(StringName(entry.scene_id)) or not await intro.call() or not bool(field_probe.call("bind_current", StringName(entry.scene_id))):
		inventory.call("from_dict", original_inventory)
		state.set("flags", original_flags)
		return result
	var field: Node = tree.current_scene
	var definition: SceneScript = field.get("_current_scene") as SceneScript
	var original_chance: float = definition.encounter_chance
	definition.encounter_chance = 0.0 # Only deterministic discovery movement, never battle credit.
	var actor: Node2D = field.get("_player") as Node2D
	var target: Vector2 = _point(entry.art.discovery_foot_px)
	var clear := Callable(field_probe, "clear")
	var segment := Callable(field_probe, "segment")
	var path: PackedVector2Array = driver.call("plan", actor.position, target, Vector2(1536, 1024), clear, segment)
	_check(path.size() >= 2, "material entity is reached through independently full17/physical-clear path")
	if path.size() >= 2: result["movement"] = await driver.call("follow", field, path, clear, segment)
	_check(bool((result.get("movement", {}) as Dictionary).get("ok", false)) and bool(clear.call(actor.position)), "normal input actually reaches legal material doorstep")
	var capacity: int = int((inventory.get_script() as Script).get_script_constant_map().get("MAX_SLOTS", -1))
	var filler: Item = inventory.call("load_item_by_id", &"wudang_sword") as Item
	_check(capacity > 0 and filler != null and not filler.stackable, "capacity fixture reads real Inventory constant and real unstackable item")
	inventory.call("from_dict", {})
	if capacity > 0 and filler != null and not filler.stackable:
		_check(bool(inventory.call("add_item", filler.item_id, capacity)), "full inventory built through ordinary add_item, not forged slot dictionaries")
	_check((inventory.get("slots") as Array).size() == capacity, "all actual inventory slots occupied")
	var full_inventory: Dictionary = inventory.call("to_dict")
	result["full_inventory_click"] = await _click_original_entity()
	var capacity_dialog: Node = tree.root.get_node("DialogPlayer")
	var blocked_live: DialogScript = capacity_dialog.get("_current_script") as DialogScript
	_check(bool(capacity_dialog.call("is_playing")) and blocked_live != null and blocked_live.dialog_id != script.dialog_id, "full-bag original entity click opens real normal capacity fallback dialogue")
	await _finish_dialog()
	_check(inventory.call("to_dict") == full_inventory and not _flag(state, flag), "normal entity click with full bag grants nothing and leaves discovery unclaimed")
	inventory.call("reset_for_new_game")
	var count_before: int = int(inventory.call("count_of", item))
	result["normal_entity_click"] = await _click_original_entity()
	var live: DialogScript = tree.root.get_node("DialogPlayer").get("_current_script") as DialogScript
	_check(live != null and live.dialog_id == script.dialog_id, "normal original entity click opens authored discovery dialogue")
	await _finish_dialog()
	_check(int(inventory.call("count_of", item)) == count_before + 1 and _flag(state, flag), "normal authored dialogue grants exactly one material and real story flag")
	await screenshot.call(ecology + "_material_claimed")
	for at: bool in [false, true]: result.replays.append(await _replay(script, at, inventory, state, item, flag))
	var slot_path: String = String(slots.call("slot_path", 0))
	_check(slot_path.begins_with("user://world_map_v15_qa/"), "material persistence uses only isolated real SaveManager slot")
	var claimed_inventory: Dictionary = inventory.call("to_dict")
	var saved: bool = slot_path.begins_with("user://world_map_v15_qa/") and bool(slots.call("save_to_slot", 0))
	_check(saved, "claimed material and flag saved through inherited atomic SaveManager")
	if saved:
		result["isolated_save"] = {"path": slot_path, "sha256": FileAccess.get_sha256(slot_path)}
		inventory.call("reset_for_new_game")
		state.call("set_flag", flag, false)
		_check(bool(slots.call("load_from_slot", 0)), "real isolated load restores claimed material state")
		_check(inventory.call("to_dict") == claimed_inventory and _flag(state, flag), "loaded inventory and once-only flag exactly match saved reward")
		for at: bool in [false, true]: result.replays.append(await _replay(script, at, inventory, state, item, flag))
	definition.encounter_chance = original_chance
	result["actual_item_count"] = inventory.call("count_of", item)
	result["actual_claimed"] = _flag(state, flag)
	inventory.call("from_dict", original_inventory)
	state.set("flags", original_flags)
	return result

func release() -> void:
	if geometry != null: geometry.call("release")
	geometry = null
	driver = null
	field_probe = null
	slots = null
	check = Callable()
	waiter = Callable()
	intro = Callable()
	screenshot = Callable()
	tree = null
