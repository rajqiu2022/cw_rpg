extends SceneTree
## NEW bounded SOURCE_ONLY compilation in registered normal autoload context.
## No helper.run/materialize/publisher/Field/input/save call is made.
const PATHS: Array[String] = [
	"res://tests/helpers/joint_v15_source_context_oracle.gd",
	"res://tests/helpers/joint_v15_world_raw_oracle.gd",
	"res://tests/helpers/joint_v15_ordinary_raw_oracle.gd",
	"res://tests/helpers/joint_v15_world_geometry_phase.gd",
	"res://tests/helpers/joint_v15_overview_input_probe.gd",
	"res://tests/helpers/joint_v15_battle_return_probe.gd",
	"res://tests/helpers/joint_v15_normal_npc_depth_probe.gd",
	"res://tests/helpers/joint_v15_world_prepared_phase.gd",
	"res://tests/test_joint_world_luoyang_v15_20261004.gd",
]
var failed: int = 0
var loaded_source_refs: Array[Dictionary] = []
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	for path: String in PATHS:
		var before: String = FileAccess.get_sha256(path)
		var script: GDScript = load(path) as GDScript
		var ok: bool = before.length()==64 and script!=null and script.can_instantiate() and FileAccess.get_sha256(path)==before
		if script!=null: loaded_source_refs.append({"path":path,"instance_id":script.get_instance_id(),"ref":weakref(script)})
		print(JSON.stringify({"scope":"JOINT_WORLD_PREPARED_SOURCE_ONLY_NOT_FIELD","path":path,"sha256":before,"source_load_ok":ok}))
		if not ok:
			failed+=1
			push_error("Prepared joint world source did not compile: "+path)
		script=null
	for stage in 4: await process_frame
	# Read-only exit diagnostics. A cached GDScript alive here is NOT itself a leak
	# verdict. --verbose's actual ObjectDB listing is needed for causal identity.
	var source_lifetimes: Array[Dictionary]=[]
	for entry: Dictionary in loaded_source_refs:
		source_lifetimes.append({"path":entry.path,"instance_id":entry.instance_id,"alive":(entry.ref as WeakRef).get_ref()!=null})
	var audio_nodes: Array[Dictionary]=[]
	var audio: Node=root.get_node_or_null("AudioManager")
	if audio!=null:
		for node: Node in audio.get_children():
			if not node is AudioStreamPlayer: continue
			var stream: AudioStream=node.stream
			audio_nodes.append({"path":str(node.get_path()),"playing":node.playing,"stream_id":stream.get_instance_id() if stream!=null else 0,"stream_class":stream.get_class() if stream!=null else "","stream_path":stream.resource_path if stream!=null else ""})
			stream=null
	print(JSON.stringify({"scope":"LOAD_ONLY_EXIT_READONLY_DIAGNOSTIC_NOT_CAUSAL_PASS","source_refs":source_lifetimes,"audio_nodes":audio_nodes,"orphan_nodes":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),"engine_objects":Performance.get_monitor(Performance.OBJECT_COUNT)}))
	loaded_source_refs.clear()
	print("JOINT_WORLD_PREPARED_SOURCE_CHECK: %d sources / %d failures; NOT_FIELD_NOT_GPU"%[PATHS.size(),failed])
	quit(0 if failed==0 else 1)
