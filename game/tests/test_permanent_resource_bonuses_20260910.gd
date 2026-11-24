extends SceneTree

var checks := 0
var failures := 0
var gs: Node
var inv: Node
var saver: Node

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	gs = root.get_node("GameState")
	inv = root.get_node("Inventory")
	gs.reset_for_new_game()
	inv.reset_for_new_game()
	inv.slots.clear()
	var player: CharacterStats = gs.player
	var base := Vector2i(player.max_hp, player.max_mp)
	player.hp -= 20
	player.mp -= 10
	_check(inv.add_item(&"linxi_jiu", 2), "two legitimate items added")
	_check(inv.use_item(&"linxi_jiu"), "actual use_item succeeds")
	_check(_caps(player) == base + Vector2i(100, 50), "wine adds exactly 100/50")
	_check(Vector2i(player.hp, player.mp) == base + Vector2i(80, 40), "wine preserves wounds while healing 100/50")
	_check(inv.use_item(&"linxi_jiu"), "second legitimate use succeeds")
	_check(not inv.use_item(&"linxi_jiu"), "absent third item grants nothing")
	_check(_caps(player) == base + Vector2i(200, 100), "two applications stack exactly")
	_check(player.permanent_resource_bonuses["item:linxi_jiu"].applications == 2, "source records two applications")
	_check(gs.learn_skill(&"linxi_inner_breath"), "actual heart art learning succeeds")
	_check(_bonus(player) == Vector2i(200, 100), "learning retains permanent bonus")
	var learned_caps := _caps(player)
	_check(gs.equip_internal_art(&"linxi_inner_breath"), "heart art equips")
	_check(gs.unequip_internal_art(), "heart art unequips")
	_check(_caps(player) == learned_caps, "heart art switching does not duplicate growth")
	_check(player.gain_exp(player.exp_required_for_next_level()), "level up succeeds")
	_check(_bonus(player) == Vector2i(200, 100), "level up retains permanent bonus")
	for i in 5:
		player.refresh_derived_stats(false)
	_check(_bonus(player) == Vector2i(200, 100), "repeated recalculation is idempotent")
	var copied := player.duplicate(true) as CharacterStats
	copied.add_permanent_resource_bonus(&"item:linxi_jiu", 100, 50)
	_check(_bonus(player) == Vector2i(200, 100) and _bonus(copied) == Vector2i(300, 150), "deep duplicate owns independent ledger")
	_check(gs.add_companion(&"tang_xingzhou"), "companion joins via normal template copy")
	var companion: CharacterStats = gs.get_party_member(&"tang_xingzhou")
	_check(inv.add_item(&"linxi_jiu", 1) and inv.use_item_for(&"tang_xingzhou", &"linxi_jiu"), "companion actual item path succeeds")
	companion.gain_exp(companion.exp_required_for_next_level())
	_check(_bonus(companion) == Vector2i(100, 50), "companion keeps bonus after leveling")
	saver = load("res://tests/isolated_permanent_resource_save_20260910.gd").new()
	saver.isolated_dir = "user://permanent_resource_test_%d" % Time.get_ticks_usec()
	_check(DirAccess.make_dir_recursive_absolute(saver.isolated_dir) == OK, "isolated save directory created")
	root.add_child(saver)
	_check(saver.save_to_slot(0), "real atomic save uses isolated directory")
	_check(saver.get_slot_meta(0).version == 14, "save schema is 14")
	var saved_caps := _caps(player)
	var companion_caps := _caps(companion)
	for i in 3:
		gs.reset_for_new_game()
		_check(saver.load_from_slot(0), "real save load iteration %d" % i)
		await process_frame
		player = gs.player
		companion = gs.get_party_member(&"tang_xingzhou")
		_check(_caps(player) == saved_caps and _caps(companion) == companion_caps, "player/party duplicate apply preserves exact capacities %d" % i)
		_check(_bonus(player) == Vector2i(200, 100) and _bonus(companion) == Vector2i(100, 50), "source totals survive load %d" % i)
	# Equipment lives outside CharacterStats capacities, so it must not enter migration.
	_check(inv.add_item(&"battle_helmet", 1) and inv.equip(&"battle_helmet"), "life equipment equips")
	_check(_caps(player) == saved_caps, "equipment does not write saved base capacities")
	_check(saver.save_to_slot(1), "equipped checkpoint saved")
	var old: Dictionary = saver._read_slot_data(1)
	old.version = 12
	old.player.erase("permanent_resource_bonuses")
	for raw: Dictionary in old.party:
		raw.erase("permanent_resource_bonuses")
	_check(saver._write_slot_atomic(1, JSON.stringify(old)), "v12 fixture written only in isolated directory")
	for i in 2:
		_check(saver.load_from_slot(1), "v12 real load %d" % i)
		await process_frame
		player = gs.player
		_check(_caps(player) == saved_caps and _bonus(player) == Vector2i(200, 100), "v12 positive saved delta retained once %d" % i)
		_check(player.permanent_resource_bonuses.legacy_saved_capacity.applications == 0, "migration does not invent item counts")
	var helmet := load("res://data/equipment/battle_helmet.tres") as Equipment
	inv.unequip(helmet.slot)
	_check(_caps(player) == saved_caps, "unequip cannot remove or duplicate migrated bonus")
	var baseline := CharacterStats.new()
	baseline.refresh_derived_stats(true)
	var legacy: Dictionary = saver._serialize_stats(baseline)
	legacy.erase("permanent_resource_bonuses")
	saver._apply_stats(player, legacy, 12)
	_check(player.permanent_resource_bonuses.is_empty() and _caps(player) == _caps(baseline), "old already-lost reward is not guessed or compensated")
	legacy.erase("strength")
	saver._apply_stats(player, legacy, 1)
	_check(player.permanent_resource_bonuses.is_empty(), "missing legacy core attributes never invent sources")
	player.restore_permanent_resource_bonuses({"bad": {"max_hp": -4, "max_mp": "50"}, "bad2": [], "good": {"max_hp": 7}})
	_check(player.get_permanent_resource_bonus("max_hp") == 7 and player.get_permanent_resource_bonus("max_mp") == 0, "malformed and negative source amounts ignored")
	# Remove only explicitly named files under this test's freshly created directory.
	for slot in [0, 1]:
		for suffix in ["", ".bak", ".tmp"]:
			var path: String = saver.slot_path(slot) + suffix
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saver.isolated_dir))
	saver.queue_free()
	await process_frame
	print("[PermanentResources20260910] checks=%d failures=%d (isolated saves cleaned)" % [checks, failures])
	quit(1 if failures else 0)

func _caps(s: CharacterStats) -> Vector2i:
	return Vector2i(s.max_hp, s.max_mp)

func _bonus(s: CharacterStats) -> Vector2i:
	return _caps(s) - Vector2i(s._calc_max_hp(), s._calc_max_mp())

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[FAIL] " + message)
	else:
		print("[PASS] " + message)
