extends SceneTree
## Root only: normal project autoload registration, no field or actor instances.
const BASE := "res://build/linxi_adult_scale_20261030h_system01/"
const SELF := BASE+"PARSE_ROOT_ONLY.gd"
const AUTH := BASE+"closure01_READY/auth_READY.json"
const RECEIPT := BASE+"closure01_READY/receipt_READY.json"
const OUT := BASE+"PARSE_ROOT_ACTUAL.json"
var checks: Array[Dictionary]=[]
var errors: Array[String]=[]
var resources: Array[Dictionary]=[]
var hashes: Dictionary={}
var suspended := false

func _initialize() -> void:
	call_deferred("_run")

func need(okay: bool,label: String) -> bool:
	checks.append({"check":label,"passed":okay})
	if not okay:errors.append(label);printerr("PARSE30H_FAIL ",label)
	return okay

func _run() -> void:
	if FileAccess.file_exists(OUT):printerr("IMMUTABLE_PARSE_OUTPUT_ALREADY_EXISTS");quit(2);return
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if not need(bridge!=null,"PLATFORM_BRIDGE_PRESENT"):_finish();return
	if not need(bridge.has_method("set_checkpoint_saves_suspended") and bridge.has_method("is_checkpoint_saves_suspended"),"CHECKPOINT_API_PRESENT"):_finish();return
	bridge.call("set_checkpoint_saves_suspended",true)
	suspended=bridge.call("is_checkpoint_saves_suspended")==true
	if not need(suspended,"CHECKPOINT_SAVES_SUSPENDED"):_finish();return
	if not need(current_scene==null and get_nodes_in_group("player").is_empty(),"NO_MAIN_SCENE_OR_PLAYER_BEFORE"):_finish();return
	var auth: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTH))
	var receipt: Variant=JSON.parse_string(FileAccess.get_file_as_string(RECEIPT))
	if not need(auth is Dictionary and receipt is Dictionary,"CLOSURE_DOCUMENTS_PARSE"):_finish();return
	var paths: Dictionary={}
	for row: Dictionary in receipt.targets:
		paths["res://"+String(row.candidate).trim_prefix("game/")]=String(row.new_sha256)
	for section: String in ["new_modules","runtime_inputs"]:
		for target: String in auth.get(section,{}):
			paths["res://"+target.trim_prefix("game/")]=String(auth[section][target].sha256)
	for path: String in paths:
		var actual: String=FileAccess.get_sha256(path)
		hashes[path]=actual
		need(actual==paths[path],"SOURCE_SHA:"+path)
		if path.get_extension() not in ["gd","tscn","tres","gdshader","png","jpg","jpeg","svg"]:continue
		var resource: Resource=load(path)
		var okay: bool=resource!=null
		var row: Dictionary={"path":path,"sha256":actual,"loaded":okay,"resource_class":resource.get_class() if resource!=null else "","can_instantiate":null}
		if resource is Script:
			okay=resource.can_instantiate();row.can_instantiate=okay
		elif resource is PackedScene:
			okay=resource.can_instantiate();row.can_instantiate=okay
		resources.append(row);need(okay,"RESOURCE_LOAD:"+path)
		print("PARSE30H_RESOURCE ",okay," ",path," SHA256=",actual)
	need(current_scene==null and get_nodes_in_group("player").is_empty(),"NO_MAIN_SCENE_OR_PLAYER_AFTER")
	suspended=bridge.call("is_checkpoint_saves_suspended")==true
	need(suspended,"CHECKPOINT_SAVES_REMAIN_SUSPENDED")
	_finish()

func _finish() -> void:
	var result: Dictionary={"status":"RUNTIME_AUTOLOAD_SYNTAX_RESOURCE_ONLY","passed":errors.is_empty(),"checks":checks,"errors":errors,"resources":resources,"source_sha256":hashes,"script_sha256":FileAccess.get_sha256(SELF),"auth_sha256":FileAccess.get_sha256(AUTH),"receipt_sha256":FileAccess.get_sha256(RECEIPT),"checkpoint_saves_suspended":suspended,"current_scene_is_null":current_scene==null,"player_group_count":get_nodes_in_group("player").size(),"field_instantiations":0,"actor_instantiations":0,"input_events_injected":0,"real_save_contents_read":false,"save_calls":0,"save_writes":0,"physics_or_input_or_ART_credit":false,"raw_stderr_must_be_reviewed":true}
	var file:=FileAccess.open(OUT,FileAccess.WRITE)
	if file==null:printerr("PARSE30H_OUTPUT_OPEN_FAILED");quit(2);return
	file.store_string(JSON.stringify(result,"\t")+"\n");file.close()
	print("PARSE30H_RESULT checks=",checks.size()," failures=",errors.size()," resources=",resources.size()," output=",OUT," SHA256=",FileAccess.get_sha256(OUT))
	# Keep checkpoint saves suspended during headless autoload shutdown.
	quit(1 if not errors.is_empty() else 0)
