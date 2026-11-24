extends SceneTree
## ROOT-only: --check-only checks these helpers; ordinary headless checks
## autoload-aware production scripts, without changing scenes or player saves.
const T=preload("res://scripts/city/luoyang_temple_assembly_20261016.gd")
const A=preload("res://scripts/city/luoyang_temple_task_adapter_20261016.gd")
const F=preload("res://scripts/city/luoyang_temple_fade_20261016.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var ok: bool=true
	for path: String in ["res://scripts/autoload/scene_router.gd","res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd","res://scripts/field/field_walkable_controller.gd"]:
		var script: Script=load(path) as Script
		var valid: bool=script!=null and script.can_instantiate()
		print(JSON.stringify({"path":path,"can_instantiate":valid,"sha256":FileAccess.get_sha256(path)})); ok=ok and valid
	print(JSON.stringify({"compiled":ok,"formal_enabled":T.FORMAL_ENABLED,"binding_pending":T.binding().is_empty(),"no_gameplay":true}))
	quit(0 if ok else 1)
