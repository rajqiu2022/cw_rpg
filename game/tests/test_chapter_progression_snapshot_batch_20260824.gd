extends SceneTree

const SNAPSHOT_PATH := "res://../docs/chapter-progression-snapshot-v1.json"
const RETIRED_SOURCE_IDS := ["q_ch1_main_01_thug", "q_ch1_main_02_qingfeng", "q_ch1_side_yuewuxing"]

var failures := 0


func _initialize() -> void:
	var snapshot := _load_snapshot()
	_check(not snapshot.is_empty(), "progression snapshot loads")
	if snapshot.is_empty():
		quit(1)
		return
	var chapters: Array = snapshot.get("chapters", [])
	var entries: Array = snapshot.get("entries", [])
	_check(chapters.size() == 8, "snapshot covers all eight chapters")
	_check(entries.size() >= 150, "snapshot contains the current equipment and martial-art acquisition graph")
	_check(_validate_chapter_ranges(chapters), "recommended level bands are ordered and stay inside Lv1-20")
	_check(_validate_implementation_states(chapters), "chapters 1-5 are implemented and 6-8 remain planning")
	_check(_validate_entries(entries), "every snapshot entry resolves to a real equipment or skill resource")
	_check(_retired_sources_absent(entries), "retired compatibility quests do not enter the formal snapshot")
	_check(_chapter_status(chapters, 1) == "完整", "chapter one has a complete guaranteed progression package")
	_check(_chapter_status(chapters, 3) == "完整", "chapter three treats one faction package as a required branch")
	_check(_chapter_status(chapters, 2) == "完整", "chapter two now owns equipment, attack-art and internal-art main rewards")
	_check(_chapter_status(chapters, 4) == "完整", "chapter four now owns equipment, attack-art and internal-art main rewards")
	_check(_has_reward(entries, 2, "zhuwei_bamboo_sleeve_crossbow") and _has_reward(entries, 2, "bamboo_rain_piercing_shot") and _has_reward(entries, 2, "zhuwei_bamboo_guard_art"), "chapter two snapshot includes its complete hidden-weapon package")
	_check(_has_reward(entries, 4, "luoshui_canal_staff") and _has_reward(entries, 4, "rolling_cloud_staff_storm"), "chapter four snapshot includes the staff package")
	_check("缺正式战斗锚点" not in _chapter_gaps(chapters, 5), "chapter five owns formal battle anchors for its implemented scene chain")
	_check(_chapter_anchor_count(chapters, 5) == 5, "chapter five snapshot records all five formal battle groups")
	_check(_chapter_status(chapters, 5) == "完整", "chapter five becomes complete after the finale choice is linked")
	_check(_has_reward(entries, 5, "battle_helmet"), "chapter five relief slice owns its first guaranteed equipment reward")
	_check("缺主线/必选分支装备成长" not in _chapter_gaps(chapters, 5), "chapter five no longer reports a missing equipment step")
	_check(_has_reward(entries, 5, "gufeng_diamond_blade") and _has_reward(entries, 5, "snow_pass_returning_blade") and _has_reward(entries, 5, "cold_ridge_guard_breath"), "chapter five snow-and-mine slice owns a compatible blade, attack art and internal art")
	_check("缺主线/必选分支武功成长" not in _chapter_gaps(chapters, 5) and "缺主线/必选分支心法成长" not in _chapter_gaps(chapters, 5), "chapter five no longer reports missing attack-art or internal-art growth")
	_check("缺正式战斗锚点" in _chapter_gaps(chapters, 7) and _chapter_anchor_count(chapters, 7) == 1, "chapter seven records its first anchor without claiming full combat coverage")
	_check(_has_reward(entries, 8, "wanxiang_breaking_sword") and _has_reward(entries, 8, "xuanshuang_hidden_current"), "chapter eight includes both Linxi final evolutions")
	print("[ChapterProgressionSnapshot20260824] entries=%d failures=%d" % [entries.size(), failures])
	quit(1 if failures > 0 else 0)


func _load_snapshot() -> Dictionary:
	if not FileAccess.file_exists(SNAPSHOT_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SNAPSHOT_PATH))
	return parsed as Dictionary if parsed is Dictionary else {}


func _validate_chapter_ranges(chapters: Array) -> bool:
	var previous_min := 0
	for raw: Variant in chapters:
		var chapter := raw as Dictionary
		var minimum := int(chapter.get("recommendedLevelMin", 0))
		var maximum := int(chapter.get("recommendedLevelMax", 0))
		if minimum < 1 or maximum < minimum or maximum > 20 or minimum < previous_min:
			return false
		previous_min = minimum
	return true


func _validate_implementation_states(chapters: Array) -> bool:
	for raw: Variant in chapters:
		var chapter := raw as Dictionary
		var number := int(chapter.get("chapter", 0))
		var expected := "已实装" if number <= 5 else "规划"
		if String(chapter.get("implementation", "")) != expected:
			return false
	return true


func _validate_entries(entries: Array) -> bool:
	for raw: Variant in entries:
		var entry := raw as Dictionary
		var reward_id := String(entry.get("rewardId", ""))
		var reward_name := String(entry.get("rewardName", ""))
		var reward_kind := String(entry.get("rewardKind", ""))
		if reward_id.is_empty() or reward_name.is_empty() or reward_kind not in ["装备", "武功", "心法"]:
			return false
		var resource_path := "res://data/%s/%s.tres" % ["equipment" if reward_kind == "装备" else "skills", reward_id]
		if ResourceLoader.load(resource_path) == null:
			return false
		var quality := int(entry.get("quality", -1))
		if quality < 0 or quality > 4:
			return false
	return true


func _retired_sources_absent(entries: Array) -> bool:
	for raw: Variant in entries:
		var source_id := String((raw as Dictionary).get("sourceId", ""))
		if source_id in RETIRED_SOURCE_IDS:
			return false
	return true


func _chapter_status(chapters: Array, number: int) -> String:
	for raw: Variant in chapters:
		var chapter := raw as Dictionary
		if int(chapter.get("chapter", 0)) == number:
			return String(chapter.get("coverageStatus", ""))
	return ""


func _chapter_gaps(chapters: Array, number: int) -> Array:
	for raw: Variant in chapters:
		var chapter := raw as Dictionary
		if int(chapter.get("chapter", 0)) == number:
			return chapter.get("gaps", []) as Array
	return []


func _chapter_anchor_count(chapters: Array, number: int) -> int:
	for raw: Variant in chapters:
		var chapter := raw as Dictionary
		if int(chapter.get("chapter", 0)) == number:
			return int(chapter.get("formalBattleAnchorCount", 0))
	return 0


func _has_reward(entries: Array, chapter_number: int, reward_id: String) -> bool:
	for raw: Variant in entries:
		var entry := raw as Dictionary
		if int(entry.get("chapter", 0)) == chapter_number and String(entry.get("rewardId", "")) == reward_id:
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
