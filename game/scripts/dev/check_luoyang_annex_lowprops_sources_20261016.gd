extends SceneTree
## ROOT-only proper check then normal dynamic autoload-aware compilation.
const A=preload("res://scripts/city/luoyang_yamen_annex_revision_20261016.gd")
const R=preload("res://scripts/city/luoyang_yamen_annex_runtime_20261016.gd")
const F=preload("res://scripts/city/luoyang_assembled_low_furniture_fade_20261016.gd")
const AF=preload("res://scripts/city/luoyang_yamen_annex_fade_20261016.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var ok: bool=true
	for path: String in ["res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd","res://scripts/field/field_walkable_controller.gd"]:
		var script: Script=load(path) as Script
		var valid: bool=script!=null and script.can_instantiate()
		print(JSON.stringify({"path":path,"can_instantiate":valid,"sha256":FileAccess.get_sha256(path)})); ok=ok and valid
	print(JSON.stringify({"compiled":ok,"formal_enabled":R.FORMAL_ENABLED,"no_gameplay":true})); quit(0 if ok else 1)
