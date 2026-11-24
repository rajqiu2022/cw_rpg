extends SceneTree
## Real project/autoload context compile and source-only closed-gate check.
## Does not instantiate Field, load saves, publish resources or approve art.
const SCRIPTS := [
	"res://scripts/world/world_map_v15_contract.gd",
	"res://scripts/dev/world_map_v15_complete_v5_publication_gate.gd",
	"res://scripts/dev/publish_world_map_v15_complete_v5.gd",
	"res://scripts/city/luoyang_layered_v3_contract.gd",
	"res://scripts/field/field_walkable_controller.gd",
	"res://scripts/autoload/scene_router.gd",
]
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var router: Node = root.get_node_or_null("SceneRouter")
	if router == null:
		push_error("Project autoload context missing")
		quit(1)
		return
	var before: Dictionary = router.get_navigation_state().duplicate(true)
	var hashes: Dictionary = {}
	for path: String in SCRIPTS:
		var script: Script = load(path) as Script
		if script == null or not script.can_instantiate(): failures.append("Not instantiable: " + path)
		hashes[path] = FileAccess.get_sha256(path)
	var city: Script = load("res://scripts/city/luoyang_layered_v3_contract.gd") as Script
	if city != null and city.can_instantiate():
		var counts := Vector3i.ZERO
		for id: String in city.LEGACY_SHAS:
			var original: Variant = city.legacy_scene(StringName(id))
			if not original is SceneScript or original.map_layout == null:
				failures.append("Immutable city source unavailable: " + id)
				continue
			counts += Vector3i(original.npcs.size(), original.map_layout.interactions.size(), original.map_layout.portals.size())
			if "--expect-city-pending" in OS.get_cmdline_user_args():
				if city.prepare(StringName(id)) or city.errors().is_empty(): failures.append("Unready city was not closed: " + id)
		if counts != Vector3i(15, 11, 12): failures.append("Original gameplay identity counts changed: " + str(counts))
	if "--expect-world-pending" in OS.get_cmdline_user_args():
		var gate: Script = load("res://scripts/dev/world_map_v15_complete_v5_publication_gate.gd") as Script
		if gate == null or not gate.can_instantiate() or gate.validate({}, {}).is_empty(): failures.append("Unready world was not closed")
	if router.get_navigation_state() != before: failures.append("Source-only checks changed navigation")
	for failure: String in failures: push_error(failure)
	print(JSON.stringify({"phase": "SOURCE_ONLY", "scripts": SCRIPTS.size(), "failed": failures.size(), "failures": failures, "source_sha256": hashes, "field_input_physics_rewards": "NOT_RUN", "art": "NOT_APPROVED"}))
	quit(0 if failures.is_empty() else 1)
