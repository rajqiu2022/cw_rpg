extends SceneTree
## ROOT-only source compile, not a map or gameplay test.
const R=preload("res://scripts/city/luoyang_district_life_20261016f.gd")
const G=preload("res://scripts/city/luoyang_district_life_geometry_20261016f.gd")
const F=preload("res://scripts/city/luoyang_district_life_fade_20261016f.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended"):
		push_error("CHECKPOINT_SUSPEND_API_UNAVAILABLE"); quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	var ok: bool=true
	var scripts: Array[Script]=[R,G,F]
	for script: Script in scripts: ok=ok and script.can_instantiate()
	for path: String in ["res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd","res://scripts/field/field_walkable_controller.gd"]:
		var script: Script=load(path)
		var ready: bool=script!=null and script.can_instantiate()
		print(JSON.stringify({"script":path,"can_instantiate":ready,"sha256":FileAccess.get_sha256(path)})); ok=ok and ready
	print("DISTRICT_LIFE_SOURCE_CHECK:"+str(ok)); quit(0 if ok else 1)
