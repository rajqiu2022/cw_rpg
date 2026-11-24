extends SceneTree
## Root-only finite new presentation semantics checks. No travel or save API.
var ADAPTER: GDScript
var OVERLAY: GDScript
var checks := 0
var errors: Array[String] = []
var suspended := false

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	run.call_deferred()

func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		suspended = bool(node.call("is_checkpoint_saves_suspended"))

func need(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label); printerr("MAP_ICONS02C_FAIL ", label)

func run() -> void:
	await process_frame
	# SceneTree test scripts parse before autoload names are registered. Loading
	# the real portrait consumer here preserves its legitimate GameState global.
	ADAPTER = load("res://build/minimap_icons_20261102c_runtime01/map_icon_runtime.gd")
	OVERLAY = load("res://build/minimap_icons_20261102c_runtime01/icon_overlay.gd")
	need(suspended, "EARLY_CHECKPOINT_SUSPEND")
	need(ADAPTER.clean_destination("空格 · 前往府衙街") == "前往府衙街", "KEY_PREFIX_REMOVED")
	need(ADAPTER.clean_destination("进入采药人家") == "进入采药人家", "ORDINARY_NAME_UNCHANGED")
	need(ADAPTER.canonical_location("luoyang_civic_market_region_27d") == "ch4_s0_luoyang_gate", "PHYSICAL_CITY_CANONICAL_ALIAS")
	need(ADAPTER.canonical_location("ch4_s3_luoyang_market") == "ch4_s0_luoyang_gate", "LOGICAL_CITY_CANONICAL_ALIAS")
	need(ADAPTER.canonical_location("linxi_village_center") == "linxi_village_scrollmap", "LINXI_ALIAS")
	need(ADAPTER.canonical_location("openworld_wudang_taiji_court") == "openworld_wudang_gate", "SECT_ALIAS")
	need(ADAPTER.WORLD_CATEGORIES.size() == 22, "WORLD22_CATEGORY_IDENTITIES")
	var kinds: Dictionary = {}
	for kind: String in ADAPTER.WORLD_CATEGORIES.values(): kinds[kind] = true
	need(kinds.size() == 5 and kinds.has("city") and kinds.has("village") and kinds.has("outskirts") and kinds.has("sect") and kinds.has("ferry"), "WORLD_FIVE_REAL_CLASSES")
	need(OVERLAY.ATLAS_CELLS.size() == 6 and OVERLAY.ATLAS_CELLS.pawn == Vector2i(2,1), "ROOT_SIX_CELL_ATLAS_INTERFACE")
	var adapter: Node = ADAPTER.new(); root.add_child(adapter)
	need(adapter.call("service_role", "luoyang_functional_pawnshop_candidate_20261016") == "pawn", "ACTUAL_PAWN_ROOM_SEMANTICS")
	need(adapter.call("service_role", "estate27d_living_hall") == "", "ORDINARY_HALL_NOT_SERVICE_MARKER")
	need(not adapter.call("visited", "qa_never_entered_unknown_location"), "VIEWING_UNKNOWN_DOES_NOT_MARK_VISITED")
	adapter.queue_free()
	await process_frame
	var path: String = "res://build/minimap_icons_20261102c_runtime01/unit_actual_%d.json" % OS.get_process_id()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"passed":errors.is_empty(), "checks":checks, "errors":errors, "scope":"NEW_ICON_SEMANTICS_ONLY_NOT_NORMAL_VISUAL_OR_TRAVEL", "input_events":0, "save_contents_read":false, "save_writes_requested":0}, "\t") + "\n")
		file.close()
	print("MAP_ICONS02C_UNIT_RESULT ", checks, " / ", errors.size(), " ", path)
	quit(0 if errors.is_empty() else 1)
