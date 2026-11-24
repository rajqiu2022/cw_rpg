extends SceneTree
const HOME := "res://build/loading_20261106_system01/"
const FAMILY = preload("res://scripts/city/luoyang_quarters_family_20261022ap.gd")
const B = preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
var suspended := false
var rows: Array[Dictionary] = []
var failures: Array[String] = []
func _initialize() -> void:
	root.child_entered_tree.connect(func(node: Node) -> void:
		if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
			node.call("set_checkpoint_saves_suspended",true)
			suspended=bool(node.call("is_checkpoint_saves_suspended")))
	_run.call_deferred()
func record(name: String, start: int, okay: bool = true) -> void:
	rows.append({"phase":name,"ms":(Time.get_ticks_usec()-start)/1000.0,"ok":okay})
	if not okay: failures.append(name)
func _run() -> void:
	await process_frame
	if not suspended: failures.append("EARLY_SAVE_SUSPEND");finish();return
	var id:=&"luoyang_artisan_residential_20261022ap"
	var start:=Time.get_ticks_usec()
	var okay:=FAMILY.validation_begin()
	record("original_validation_begin",start,okay)
	if not okay: finish();return
	start=Time.get_ticks_usec()
	var path:=FAMILY.scene_path(id)
	record("original_scene_path",start,not path.is_empty())
	start=Time.get_ticks_usec()
	var scene:=load(path) as SceneScript
	record("original_resource_load",start,scene!=null)
	start=Time.get_ticks_usec()
	okay=FAMILY.matches(scene)
	record("original_cold_matches_including_finish_ensure",start,okay)
	if not okay: finish();return
	start=Time.get_ticks_usec()
	okay=FAMILY.validation_finish()
	record("original_validation_finish",start,okay)
	var receipt:=FAMILY.validation_receipt()
	rows.append({"phase":"original_source_receipt","first_hash_elapsed_us":receipt.get("first_hash_elapsed_us",-1),"final_hash_elapsed_us":receipt.get("final_hash_elapsed_us",-1),"source_count":receipt.get("source_first",{}).size(),"full_source_hash_passes":receipt.get("full_source_hash_passes",0),"finalized":receipt.get("finalized",false)})
	start=Time.get_ticks_usec()
	okay=FAMILY.matches(scene)
	record("original_warm_matches",start,okay)
	start=Time.get_ticks_usec()
	var a:=B.storage(scene)
	record("original_scene_whole_storage",start,not a.is_empty())
	start=Time.get_ticks_usec()
	var b:=B.storage(scene.map_layout)
	record("original_layout_whole_storage",start,not b.is_empty())
	var packet:=FAMILY.packet(id)
	start=Time.get_ticks_usec()
	okay=B.equal(a,packet.scene_storage) and B.equal(b,packet.layout_storage)
	record("original_whole_storage_equality",start,okay)
	start=Time.get_ticks_usec()
	var loaded: Variant=root.get_node("SceneRouter").call("_load_field_scene_def",id)
	record("original_router_warm_load_and_matches",start,loaded==scene)
	finish()
func finish() -> void:
	var path:=HOME+"actual/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(path)
	var file:=FileAccess.open(path+"/validation_result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":failures.is_empty(),"failures":failures,"rows":rows,"scope":"ORIGINAL_VALIDATION_PHASES_ONLY_NOT_TRAVEL","real_save_contents_accessed":false,"formal_source_writes":false},"\t")+"\n")
	file.close()
	print("VALIDATION_RESULT ",failures.size()," ",path)
	quit(0 if failures.is_empty() else 1)
