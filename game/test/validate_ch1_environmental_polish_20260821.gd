extends SceneTree

const CASES: Array[Dictionary] = [
	{
		"map": "res://data/maps/ch1_s1_road_layout_v5.tres",
		"interaction": "road_cold_brazier",
		"dialog": "ch1_env_road_cold_brazier",
		"flag": "examined_road_cold_brazier",
		"item": "herb_bundle",
		"count": 1,
	},
	{
		"map": "res://data/maps/ch1_s4_zhuwei_beast_cave_layout_v3.tres",
		"interaction": "cave_mine_cart",
		"dialog": "ch1_env_cave_mine_cart",
		"flag": "examined_cave_mine_cart",
		"item": "iron_ore",
		"count": 2,
	},
	{
		"map": "res://data/maps/ch1_s3_west_ruin_layout_v2.tres",
		"interaction": "ruin_drying_rack",
		"dialog": "ch1_env_ruin_drying_rack",
		"flag": "examined_ruin_drying_rack",
		"item": "healing_salve",
		"count": 1,
	},
]

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for case: Dictionary in CASES:
		_validate_case(case)
	_validate_main_route_unchanged()
	print("[Ch1EnvironmentalPolish20260821] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[Ch1EnvironmentalPolish20260821] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_case(case: Dictionary) -> void:
	var layout := load(String(case["map"])) as WalkableMapLayout
	var case_id := String(case["interaction"])
	_check(layout != null, "%s地图布局可加载" % case_id)
	if layout == null:
		return
	var interaction := _find_entry(layout.interactions, case_id)
	_check(not interaction.is_empty(), "%s环境调查点存在" % case_id)
	if interaction.is_empty():
		return
	var point: Vector2 = interaction.get("pos", Vector2.ZERO)
	_check(_inside_any_region(point, layout.walkable_regions), "%s位于真实可行走区域" % case_id)
	_check(not _inside_any_blocker(point, layout.blockers), "%s不在建筑或道具阻挡中心" % case_id)
	_check(String(interaction.get("activation", "")) == "interact", "%s必须由玩家主动调查" % case_id)
	_check(String(interaction.get("action", "")) == "dialog:%s" % String(case["dialog"]), "%s连接正确环境对白" % case_id)
	_check(String(interaction.get("hide_flag", "")) == String(case["flag"]), "%s拥有一次性隐藏旗标" % case_id)
	_check(String(interaction.get("require_flag", "")).is_empty(), "%s不是主线推进门槛" % case_id)
	_check(String(interaction.get("require_quest_active", "")).is_empty(), "%s可由自由探索发现" % case_id)

	var dialog_path := "res://data/dialogs/%s.tres" % String(case["dialog"])
	var dialog := load(dialog_path) as DialogScript
	_check(dialog != null, "%s环境对白资源存在" % case_id)
	if dialog == null:
		return
	var found_reward := false
	var found_flag := false
	for node: DialogNode in dialog.nodes:
		if node == null:
			continue
		for reward: Dictionary in node.give_items:
			if String(reward.get("item_id", "")) == String(case["item"]):
				found_reward = int(reward.get("count", 0)) == int(case["count"])
		for entry: Dictionary in node.set_flags:
			if String(entry.get("key", "")) == String(case["flag"]) and bool(entry.get("value", false)):
				found_flag = true
		_check(node.accept_quest == &"" and node.complete_quest == &"", "%s环境点不私自改变任务状态" % case_id)
	_check(found_reward, "%s提供已审核的小额探索收益" % case_id)
	_check(found_flag, "%s对白写入与隐藏条件相同的旗标" % case_id)
	_check(ResourceLoader.exists("res://data/items/%s.tres" % String(case["item"])), "%s奖励物品存在" % case_id)


func _validate_main_route_unchanged() -> void:
	var road := load("res://data/maps/ch1_s1_road_layout_v5.tres") as WalkableMapLayout
	var cave := load("res://data/maps/ch1_s4_cave_deep_den_layout_v1.tres") as WalkableMapLayout
	var ruin := load("res://data/maps/ch1_s3_west_ruin_layout_v2.tres") as WalkableMapLayout
	_check(not _find_entry(road.portals, "exit_to_zhuwei").is_empty(), "山道前往竹尾村主出口保留")
	_check(not _find_entry(cave.interactions, "cave_supply_clue").is_empty(), "洞窟运货记录主线交互保留")
	_check(not _find_entry(ruin.interactions, "ruin_watch_roster").is_empty(), "废宅值守册主线交互保留")
	_check(not _find_entry(ruin.portals, "ruin_main_hall_door").is_empty(), "废宅内堂主出口保留")


func _find_entry(entries: Array, entry_id: String) -> Dictionary:
	for raw_entry: Variant in entries:
		if raw_entry is Dictionary and String((raw_entry as Dictionary).get("id", "")) == entry_id:
			return raw_entry as Dictionary
	return {}


func _inside_any_region(point: Vector2, regions: Array[PackedVector2Array]) -> bool:
	for region: PackedVector2Array in regions:
		if Geometry2D.is_point_in_polygon(point, region):
			return true
	return false


func _inside_any_blocker(point: Vector2, blockers: Array[Dictionary]) -> bool:
	for blocker: Dictionary in blockers:
		var center: Vector2 = blocker.get("pos", Vector2.ZERO)
		var size: Vector2 = blocker.get("size", Vector2.ZERO)
		if Rect2(center - size * 0.5, size).has_point(point):
			return true
	return false


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
