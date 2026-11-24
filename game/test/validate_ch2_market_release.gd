extends SceneTree

const SCENE_PATH := "res://data/scenes/ch2_s1_zhuwei_market.tres"
const MARKET_BACKGROUND_PATH := "res://art/backgrounds/bg_zhuwei_market_gameplay_v3.png"
const MARKET_BACKGROUND_SHA256 := "120a8ec00d5b7628aaf88b03d236394b83391d0232c30055e6b635003d29315c"
const HAWKER_RUNTIME_PATH := "res://art/characters/npc_zhuwei_merchant_idle_down_25d_4f_v3_runtime.png"
const HAWKER_RUNTIME_SHA256 := "2082d5dbe2c73b4d397c091d068901aa0e50a991149856f716b7bc428ef0c3ad"
const GINSENG_FARMER_RUNTIME_PATH := "res://art/characters/conversation_direction_v1/linxi_farmer/npc_linxi_farmer_down_conversation_1f.png"
const EXPECTED_GROUNDED_POSITIONS := {
	"zhuwei_gatekeeper_ch2": Vector2(0.29, 0.76),
}
const REQUIRED_NPC_IDS: Array[String] = [
	"zhuwei_gatekeeper_ch2",
	"zhuwei_hawker_ch2",
	"zhuwei_apothecary_ch2",
	"zhuwei_ginseng_farmer_ch2",
	"zhuwei_constable_ch2",
	"zhuwei_tournament_host_ch2",
	"zhuwei_boatman_ch2",
]
const REQUIRED_INN_NPC_IDS: Array[String] = [
	"zhuwei_innkeeper_ch2",
	"zhuwei_chess_elder_ch2",
	"zhuwei_guqin_musician_ch2",
]

var _failed: int = 0


func _initialize() -> void:
	var scene := load(SCENE_PATH) as SceneScript
	_check(scene != null, "market scene cannot load")
	if scene == null or scene.map_layout == null:
		quit(1)
		return
	_check(scene.on_enter_dialog != null, "chapter 2 intro is not bound to scene entry")
	_check(String(scene.on_enter_once_flag) == "seen_ch2_zhuwei_intro", "chapter 2 intro lacks its once flag")
	_check(not scene.map_layout.display_at_native_size, "market must cover wide viewports without a gray side strip")
	_check(scene.background_path == MARKET_BACKGROUND_PATH, "market is not using the approved sharp gameplay background")
	_check(FileAccess.get_sha256(MARKET_BACKGROUND_PATH) == MARKET_BACKGROUND_SHA256, "market gameplay background changed without visual review")

	var npc_ids: Dictionary = {}
	var sprite_paths: Dictionary = {}
	for raw_npc: Variant in scene.npcs:
		var npc: Dictionary = raw_npc
		var npc_id: String = String(npc.get("npc_id", ""))
		var sprite_path: String = String(npc.get("sprite_path", ""))
		_check(npc_id != "", "market has an NPC with no id")
		_check(not npc_ids.has(npc_id), "duplicate market NPC id: %s" % npc_id)
		npc_ids[npc_id] = true
		_check(not sprite_path.contains("npc_xingfantian"), "%s still reuses the master sprite" % npc_id)
		_check(not sprite_paths.has(sprite_path), "%s reuses another market NPC sprite" % npc_id)
		sprite_paths[sprite_path] = npc_id
		_check(_foot_safe(sprite_path), "%s has a cropped or unsafe foot margin: %s" % [npc_id, sprite_path])
		if EXPECTED_GROUNDED_POSITIONS.has(npc_id):
			var expected_position: Vector2 = EXPECTED_GROUNDED_POSITIONS[npc_id]
			var actual_position: Vector2 = npc.get("pos", Vector2.ZERO)
			_check(actual_position.is_equal_approx(expected_position), "%s drifted back onto a building footprint" % npc_id)
			_check(_walkable_ground(actual_position, scene.map_layout), "%s is not standing on clear walkable ground" % npc_id)
		if npc_id == "zhuwei_hawker_ch2":
			_check(sprite_path == HAWKER_RUNTIME_PATH, "market hawker is not using the approved full-body runtime strip")
			_check(FileAccess.get_sha256(sprite_path) == HAWKER_RUNTIME_SHA256, "market hawker runtime strip changed without full-body review")
		elif npc_id == "zhuwei_ginseng_farmer_ch2":
			_check(sprite_path == GINSENG_FARMER_RUNTIME_PATH, "ginseng farmer still uses the bound-prisoner sprite")
			_check(not sprite_path.contains("bound"), "ginseng farmer cannot use a shackled or bound NPC asset")
		elif npc_id == "zhuwei_gatekeeper_ch2":
			_check(float(npc.get("scale", 0.0)) >= 1.10, "%s is still undersized" % npc_id)
		elif npc_id == "zhuwei_apothecary_ch2":
			_check(float(npc.get("scale", 0.0)) >= 1.0, "%s is still undersized" % npc_id)
	for npc_id: String in REQUIRED_NPC_IDS:
		_check(npc_ids.has(npc_id), "missing visible market NPC: %s" % npc_id)
	var inn_scene := load("res://data/scenes/ch2_s1_market_inn.tres") as SceneScript
	_check(inn_scene != null, "market inn scene cannot load")
	var inn_npcs: Dictionary = {}
	if inn_scene != null:
		for raw_npc: Variant in inn_scene.npcs:
			var inn_npc: Dictionary = raw_npc
			inn_npcs[String(inn_npc.get("npc_id", ""))] = true
	for npc_id: String in REQUIRED_INN_NPC_IDS:
		_check(inn_npcs.has(npc_id), "missing reviewed inn NPC: %s" % npc_id)
	var gatekeeper: Dictionary = {}
	for raw_npc: Variant in scene.npcs:
		var npc: Dictionary = raw_npc
		if String(npc.get("npc_id", "")) == "zhuwei_gatekeeper_ch2":
			gatekeeper = npc
			break
	var has_three_clue_gate: bool = false
	for raw_variant: Variant in gatekeeper.get("dialog_variants", []):
		var variant: Dictionary = raw_variant
		if String(variant.get("dialog_id", "")) != "ch2_market_gatekeeper_followup":
			continue
		var required: Array = variant.get("require_flags", [])
		has_three_clue_gate = required.has("chapter2_started") and required.has("ch2_market_hawker_heard") and required.has("ch2_market_apothecary_heard")
	_check(has_three_clue_gate, "gatekeeper can conclude the main quest before both witnesses are heard")

	var interaction_ids: Array[String] = []
	for raw_interaction: Variant in scene.map_layout.interactions:
		var interaction: Dictionary = raw_interaction
		interaction_ids.append(String(interaction.get("id", "")))
	_check(interaction_ids == ["market_old_book_stall"], "market interactions do not match the reviewed physical-object layout")

	var portals: Dictionary = {}
	for raw_portal: Variant in scene.map_layout.portals:
		var portal: Dictionary = raw_portal
		portals[String(portal.get("id", ""))] = portal
	_check(portals.has("market_return_to_ruin_inner"), "market has no return to the west-ruin inner hall")
	if portals.has("market_return_to_ruin_inner"):
		_check(String((portals["market_return_to_ruin_inner"] as Dictionary).get("target_scene", "")) == "ch1_s3_ruin_inner", "market return points to the wrong scene")
	_check(portals.has("market_enter_inn"), "market has no entrance to the reviewed inn interior")
	_check(portals.has("market_enter_training_hall"), "market has no entrance to the reviewed training-hall interior")
	for portal_id: String in ["market_to_forest_edge", "market_to_river_camp"]:
		_check(portals.has(portal_id), "missing chapter 2 route: %s" % portal_id)
		if portals.has(portal_id):
			var portal: Dictionary = portals[portal_id]
			_check(String(portal.get("require_flag", "")) == "heard_about_missing_lingyue", "%s is not gated by the completed investigation" % portal_id)
			_check(String(portal.get("locked_label", "")) != "", "%s disappears instead of showing a locked direction" % portal_id)

	var quest := load("res://data/quests/q_ch2_main_01_investigate.tres") as QuestDef
	_check(quest != null, "investigation quest cannot load")
	if quest != null:
		_check(quest.completion_triggers == ["flag_set:heard_about_missing_lingyue"], "investigation must complete from one aggregate flag")
	var legacy_dialog := load("res://data/dialogs/ch2_market_investigation.tres") as DialogScript
	if legacy_dialog != null:
		for node: DialogNode in legacy_dialog.nodes:
			_check(String(node.complete_quest) == "" and node.set_flags.is_empty(), "legacy exclamation dialog can still award the quest")
	for dialog_id: String in ["ch2_market_hawker", "ch2_market_apothecary"]:
		var witness_dialog := load("res://data/dialogs/%s.tres" % dialog_id) as DialogScript
		_check(witness_dialog != null, "missing witness dialog: %s" % dialog_id)
		if witness_dialog == null:
			continue
		for node: DialogNode in witness_dialog.nodes:
			_check(String(node.complete_quest) == "", "%s directly completes the main quest" % dialog_id)
			for flag_entry: Dictionary in node.set_flags:
				_check(String(flag_entry.get("key", "")) != "heard_about_missing_lingyue", "%s sets the aggregate completion flag early" % dialog_id)

	print("[Ch2MarketRelease] npcs=%d portals=%d failed=%d" % [npc_ids.size(), portals.size(), _failed])
	quit(1 if _failed > 0 else 0)


func _foot_safe(resource_path: String) -> bool:
	if resource_path == "" or not ResourceLoader.exists(resource_path):
		return false
	var absolute_path := ProjectSettings.globalize_path(resource_path)
	var image := Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return false
	var frame_count: int = 1
	if image.get_width() > image.get_height() and image.get_width() % image.get_height() == 0:
		frame_count = image.get_width() / image.get_height()
	var frame_width: int = image.get_width() / frame_count
	var baseline: int = -1
	for frame_index: int in range(frame_count):
		var min_alpha_y: int = image.get_height()
		var max_alpha_y: int = -1
		for y: int in range(image.get_height()):
			for x: int in range(frame_index * frame_width, (frame_index + 1) * frame_width):
				if image.get_pixel(x, y).a > 0.02:
					min_alpha_y = mini(min_alpha_y, y)
					max_alpha_y = y
		var visible_height: int = max_alpha_y - min_alpha_y + 1
		var bottom_margin: int = image.get_height() - 1 - max_alpha_y
		if max_alpha_y < 0 or bottom_margin < 6 or bottom_margin > 16:
			return false
		if visible_height < 110 or visible_height > 145:
			return false
		if baseline < 0:
			baseline = max_alpha_y
		elif absi(max_alpha_y - baseline) > 1:
			return false
	return true


func _walkable_ground(point: Vector2, layout: WalkableMapLayout) -> bool:
	var inside_walkable := false
	for region: PackedVector2Array in layout.walkable_regions:
		if Geometry2D.is_point_in_polygon(point, region):
			inside_walkable = true
			break
	if not inside_walkable:
		return false
	for raw_blocker: Variant in layout.blockers:
		var blocker: Dictionary = raw_blocker
		var center: Vector2 = blocker.get("pos", Vector2.ZERO)
		var size: Vector2 = blocker.get("size", Vector2.ZERO)
		var rect := Rect2(center - size * 0.5, size)
		if rect.has_point(point):
			return false
	return true


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed += 1
	push_error("[Ch2MarketRelease] %s" % message)
