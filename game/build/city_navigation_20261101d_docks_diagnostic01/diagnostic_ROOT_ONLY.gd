extends SceneTree
## Root-only READ-ONLY collector diagnostic. NO go_field/transition/field/NAV/save writes.
## snapshot(router) may also be called at a future QA timeout to retain the real
## asynchronous public state. Standalone cannot recover a prior exited process.
const HOME := "res://build/city_navigation_20261101d_docks_diagnostic01/"
const DOCKS := &"ch4_s2_canal_docks"
const C_PATH := "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const B_PATH := "res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
var suspended := false
var toasts: Array[String] = []

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children(): _early(node)
	run.call_deferred()

func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true)
		suspended = node.call("is_checkpoint_saves_suspended") == true
	if node.name == &"EventBus" and node.has_signal("toast_requested"):
		node.connect("toast_requested",Callable(self,"_toast"))

func _toast(message: String) -> void:
	toasts.append(message)

static func snapshot(router: Node) -> Dictionary:
	var tree: SceneTree = router.get_tree()
	var loader: Node = tree.root.get_node_or_null("LoadingManager")
	var c: GDScript = load(C_PATH) as GDScript
	var b: GDScript = load(B_PATH) as GDScript
	var result: Dictionary = {"read_only":true,"travel_requests":0,"canonical_writes":0,
		"public_preparation_state":router.call("get_public_city_preparation_state"),
		"C_errors_before_collection":c.call("errors"),"C_transition_before_collection":c.call("transition_validation_state"),
		"current_logical":router.call("get_current_field_id"),"current_physical":""}
	var field: Node = tree.current_scene
	if is_instance_valid(field):
		for property: Dictionary in field.get_property_list():
			if property.name == "_current_scene":
				var current: SceneScript = field.get("_current_scene") as SceneScript
				if current != null: result.current_physical = String(current.scene_id)
	if loader != null:
		var loading: Dictionary = {}
		for key: String in ["_transition_active","_external_active","_field_preparation_token","_external_token","_loading_path","_transition_context","_handoff_progress"]:
			loading[key] = loader.get(key)
		var screen: Node = loader.get("_screen") as Node
		if is_instance_valid(screen):
			for key: String in ["stage_label","percent_label"]:
				var label: Label = screen.get(key) as Label
				loading[key] = label.text if is_instance_valid(label) else ""
		result.loading = loading
	var raw: SceneScript = ResourceLoader.load("res://data/scenes/ch4_s2_canal_docks.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if raw == null: result.error = "CANONICAL_DOCKS_RESOURCE_MISSING"; return result
	# Original C collector + original selected B entry only, not a reconstructed
	# list of direct scripts and not the dormant retry2 Docks bundle.
	var actual: Dictionary = c.call("_transition_sources",raw)
	var config: Dictionary = b.call("manifest",DOCKS)
	var entry: Dictionary = b.call("_entry",DOCKS)
	result.selected_B_entry = entry
	result.actual_count = actual.size()
	result.B_manifest_available = not config.is_empty()
	if config.is_empty() or entry.is_empty(): result.error = "ORIGINAL_B_HEADER_EMPTY"; return result
	var expected: Dictionary = config.legacy_source_sha256.duplicate(true)
	expected.merge(config.runtime_authority_sha256); expected.merge(config.artifacts)
	var constants: Dictionary = b.get_script_constant_map()
	for key: String in ["INDEX","ESTATE_INDEX","AO_INDEX","AP_INDEX","AP_ENV_INDEX","AP_EXEC_INDEX","AP_QUARTER_INDEX","AC_INDEX","AD_INDEX","AE_INDEX"]:
		var path: String = String(constants[key]); expected[path] = FileAccess.get_sha256(path)
	var aa: GDScript = load("res://scripts/city/luoyang_docks_district08_20261019aa.gd") as GDScript
	var aa_index: String = String(aa.get_script_constant_map()["INDEX"])
	expected[aa_index] = FileAccess.get_sha256(aa_index)
	expected[entry.manifest_path] = entry.manifest_sha256
	var missing: Array[Dictionary] = []; var added: Array[Dictionary] = []; var stale: Array[Dictionary] = []
	for path: String in expected:
		var origin: String = "legacy_source_sha256" if config.legacy_source_sha256.has(path) else ("runtime_authority_sha256" if config.runtime_authority_sha256.has(path) else ("artifacts" if config.artifacts.has(path) else "original_dynamic_index_or_entry"))
		if not actual.has(path): missing.append({"path":path,"expected":expected[path],"origin":origin})
		elif actual[path] != expected[path]: stale.append({"path":path,"expected":expected[path],"actual":actual[path],"origin":origin})
	for path: String in actual:
		if not expected.has(path): added.append({"path":path,"actual":actual[path]})
	result.merge({"expected_count":expected.size(),"missing":missing,"added":added,"stale":stale,
		"actual_complete":actual,"expected_complete":expected,"B_describe_pass":not b.call("describe",DOCKS,actual).is_empty(),
		"C_errors_after_collection":c.call("errors"),"public_state_after_collection":router.call("get_public_city_preparation_state")})
	return result

func run() -> void:
	await process_frame
	if not suspended: printerr("DOCKS_DIAGNOSTIC_EARLY_SAVE_SUSPEND_REQUIRED"); quit(1); return
	var router: Node = root.get_node_or_null("SceneRouter")
	if router == null: printerr("DOCKS_DIAGNOSTIC_ROUTER_MISSING"); quit(1); return
	var result: Dictionary = snapshot(router)
	result["toasts_observed_this_process"] = toasts.duplicate()
	result["standalone_no_navigation_requested"] = true
	result["prior_process_public_state_not_recoverable"] = true
	var directory: String = HOME + "actual/" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(directory)
	var output: FileAccess = FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if output == null: printerr("DOCKS_DIAGNOSTIC_OUTPUT_OPEN_FAILED"); quit(1); return
	output.store_string(JSON.stringify(result,"\t")+"\n"); output.close()
	print("DOCKS_DIAGNOSTIC ",JSON.stringify({"result":directory+"/result.json","actual_count":result.get("actual_count",0),"expected_count":result.get("expected_count",0),"missing":result.get("missing",[]).size(),"added":result.get("added",[]).size(),"stale":result.get("stale",[]).size(),"B_describe_pass":result.get("B_describe_pass",false),"travel_requests":0}))
	quit(0)
