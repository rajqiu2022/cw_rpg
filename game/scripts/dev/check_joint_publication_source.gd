extends SceneTree
## Autoload-context source/closed-gate checks only; never instantiate publishers
## or activation, run Field, write resources, load a save or approve any art.
const GATE = preload("res://scripts/dev/joint_world_city_v15_acceptance.gd")
const CITY = preload("res://scripts/city/luoyang_layered_v3_contract.gd")
const OUTSKIRTS = preload("res://scripts/world/outskirts_native_contract.gd")
const SCRIPTS := [
	"res://scripts/dev/publish_luoyang_layered_v3.gd",
	"res://scripts/dev/joint_world_city_v15_acceptance.gd",
	"res://scripts/dev/activate_joint_world_city_v15.gd",
	"res://scripts/world/outskirts_native_contract.gd",
	"res://scripts/city/luoyang_layered_v3_contract.gd",
	"res://scripts/city/luoyang_v3_modular_overlap.gd",
]
var failures: Array[String] = []
var checks := 0
var hashes: Dictionary = {}

func _initialize() -> void:
	call_deferred("_check")

func _expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition: failures.append(description)

func _check() -> void:
	var router: Node = root.get_node_or_null("SceneRouter")
	if router == null: push_error("Project autoload context required"); quit(1); return
	var before: Dictionary = router.get_navigation_state().duplicate(true)
	var baseline: Dictionary = {}
	for target: String in GATE.BASELINE: baseline[target] = FileAccess.get_sha256(target)
	for path: String in SCRIPTS:
		var script: Script = load(path) as Script
		_expect(script != null and script.can_instantiate(), "Instantiable source: " + path)
		hashes[path] = FileAccess.get_sha256(path)
	_expect(OUTSKIRTS.root_for_args(PackedStringArray()) == OUTSKIRTS.ROOT, "Default outskirts root unchanged")
	_expect(OUTSKIRTS.root_for_args(PackedStringArray(["--outskirts-complete-v5"])) == "", "Single new-root flag rejected")
	_expect(OUTSKIRTS.root_for_args(PackedStringArray(["--outskirts-complete-v5", "--outskirts-candidate-preview"])) == OUTSKIRTS.COMPLETE_V5_ROOT, "Explicit new-root dual flag selects fixed literal")
	_expect(OUTSKIRTS.root_for_args(PackedStringArray(["--outskirts-complete-v5", "--outskirts-candidate-preview", "--outskirts-visual-v4"])) == "", "Mixed v4/v5 preview rejected")
	_expect(OUTSKIRTS.root_for_args(PackedStringArray(["--outskirts-visual-v4"])) == "", "Historical v4 single-flag refusal preserved")
	_expect(OUTSKIRTS.root_for_args(PackedStringArray(["--outskirts-visual-v4", "--outskirts-candidate-preview"])) == OUTSKIRTS.V4_PREVIEW_ROOT, "Historical v4 dual-root identity preserved")
	_expect(not GATE._complete_coverage({}), "Empty/FAST coverage cannot approve joint formal gameplay")
	_expect(not GATE._water_absence_proofs([], {}), "Empty station search cannot certify full water-decoration domain")
	_expect(not GATE._water_absence_proofs([{"complete": true, "region_id": "ch4_s2_canal_docks", "object_id": "moored_canal_boat", "method": "continuous_full_drawrect_axis_separation"}], {}), "Unbound complete boolean cannot certify actual actor/nav/source domain")
	_expect(not GATE.matches_snapshot({"res://one": "0".repeat(64)}, {"res://one": "1".repeat(64)}), "Same-size stale hashes rejected")
	_expect(not GATE.matches_snapshot({}, {"res://one": "1".repeat(64)}), "Missing actual-source fingerprint rejected")
	_expect(not CITY._capture_graph_error({"capture_graph": {"source_script": 1}, "source_graph": {}}, {}, &"ch4_s0_luoyang_gate").is_empty(), "Malformed capture role rejects without dynamic get SCRIPTERROR")
	_expect(not CITY._native_camera_matches({"projection": Camera3D.PROJECTION_ORTHOGONAL, "raw_canvas_px": [3072, 2048], "logical_canvas_px": [3072, 2048], "raw_to_logical_factor": 2}, Vector2(6144, 4096), 2), "Logical image cannot masquerade as native SSAA capture")
	var boat := {"id": "moored_canal_boat", "role": "water_decoration", "blocking": false, "ghost_occlusion": false, "walk_support": false, "interaction_required": false, "collision_size_px": [0, 0], "solid_polygons_px": []}
	_expect(CITY._object_role_error(&"ch4_s2_canal_docks", boat).is_empty(), "Only declared dock boat has depth-only decoration role, NOT absence credit")
	_expect(not CITY._object_role_error(&"ch4_s0_luoyang_gate", boat).is_empty(), "Other district cannot borrow water role to disable ghost")
	var stolen: Dictionary = boat.duplicate(true)
	stolen.id = "south_gate"
	_expect(not CITY._object_role_error(&"ch4_s2_canal_docks", stolen).is_empty(), "Ordinary building cannot borrow boat role")
	stolen = boat.duplicate(true)
	stolen.walk_support = true
	_expect(not CITY._object_role_error(&"ch4_s2_canal_docks", stolen).is_empty(), "Water decorator cannot become walk support")
	_expect(not CITY._object_role_error(&"ch4_s2_canal_docks", {"id": "street_tree", "ghost_occlusion": false}).is_empty(), "Ordinary high prop cannot turn off ghost")
	_expect(not CITY._object_role_error(&"ch4_s2_canal_docks", {"id": "street_tree", "role": "invented"}).is_empty(), "Unknown role rejected")
	_expect(not CITY._reuse_error({"id": "copied", "original_source": "res://missing.png"}, {}).is_empty(), "Missing original/provenance byte binding cannot claim reuse")
	if "--expect-joint-pending" in OS.get_cmdline_user_args(): _expect(not GATE.candidate_error().is_empty(), "Unready full art cannot become a candidate")
	_expect(router.get_navigation_state() == before, "No source-check navigation mutation")
	for target: String in baseline: _expect(FileAccess.get_sha256(target) == baseline[target], "No formal/adoption byte mutation: " + target)
	for failure: String in failures: push_error(failure)
	print(JSON.stringify({"phase": "SOURCE_SYNTHETIC_ONLY", "checks": checks, "failed": failures.size(), "failures": failures, "source_sha256": hashes, "field_physics_input_rewards": "NOT_RUN", "formal_activation": "NOT_RUN", "visual": "NOT_APPROVED"}))
	call_deferred("_finish")

func _finish() -> void:
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
