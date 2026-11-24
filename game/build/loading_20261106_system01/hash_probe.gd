extends SceneTree
const HOME := "res://build/loading_20261106_system01/"
const BATCH = preload("res://build/loading_20261106_system01/hash_batch.gd")
const FAMILY = preload("res://scripts/city/luoyang_quarters_family_20261022ap.gd")
var suspended := false
var rows: Array = []
var failures: Array[String] = []
func _initialize() -> void:
	root.child_entered_tree.connect(func(node: Node) -> void:
		if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
			node.call("set_checkpoint_saves_suspended", true)
			suspended = bool(node.call("is_checkpoint_saves_suspended")))
	run.call_deferred()
func run() -> void:
	await process_frame
	if not suspended: failures.append("EARLY_SUSPEND"); finish(); return
	var header := FAMILY.source_header()
	if header.is_empty(): failures.append("ORIGINAL_STRICT_HEADER"); finish(); return
	var paths: Array[String] = []
	for path: String in header.source_sha256: paths.append(path)
	# Alternating order exposes cache-order bias instead of claiming OS-cold equivalence.
	for mode: int in [1,4,4,1]:
		var began := Time.get_ticks_usec()
		var result: Dictionary = BATCH._slice(paths) if mode == 1 else BATCH.fresh(paths,mode)
		var elapsed := Time.get_ticks_usec()-began
		var valid: bool = result == header.source_sha256 and result.keys() == paths
		rows.append({"workers":mode,"elapsed_us":elapsed,"source_count":result.size(),"all_sha_equal_original":valid})
		if not valid: failures.append("EXACT_1311_SET_OR_ORDER")
	# Demonstrate no FIRST->FINAL cache and fail-closed missing file result.
	var fixture := HOME+"actual/%d/hash_mutation_fixture.txt" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(fixture.get_base_dir())
	var file := FileAccess.open(fixture,FileAccess.WRITE)
	file.store_string("FIRST"); file.close()
	var fixture_paths: Array[String] = [fixture,HOME+"never_created_hash_fixture.txt"]
	var first := BATCH.fresh(fixture_paths)
	file = FileAccess.open(fixture,FileAccess.WRITE)
	file.store_string("FINAL changed"); file.close()
	var final := BATCH.fresh(fixture_paths)
	var mutation_ok: bool = first[fixture] != final[fixture] and final[fixture] == FileAccess.get_sha256(fixture) and final[fixture_paths[1]] == ""
	rows.append({"separate_fresh_phases_detect_mutation_and_missing":mutation_ok})
	if not mutation_ok: failures.append("FRESH_PHASE_OR_MISSING")
	finish()
func finish() -> void:
	var output := HOME+"actual/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(output)
	var file := FileAccess.open(output+"/hash_result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failures.is_empty(),"failures":failures,"rows":rows,"scope":"FULL_ORIGINAL_SET_HASH_ONLY_NOT_TRAVEL_NOT_OS_COLD","formal_sources_written":false,"real_save_contents_accessed":false},"\t")+"\n")
	file.close()
	print("HASH_PROBE_RESULT ",output)
	quit(0 if failures.is_empty() else 1)
