extends SceneTree
## Two hidden calls, no map transition, actor mutation or production edits.
const Fixture = preload("res://build/transition_latency_20261102c_candidate01/typed_dispatch_fixture_ROOT_ONLY.gd")
const OriginalScene = preload("res://scenes/ui/loading_screen.tscn")
var suspended := false

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	_run.call_deferred()

func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		suspended = bool(node.call("is_checkpoint_saves_suspended"))

func _run() -> void:
	await process_frame
	if not suspended:
		printerr("TYPED_DISPATCH_DIAGNOSTIC EARLY_SUSPEND_MISSING")
		quit(1)
		return
	var instance: Node = OriginalScene.instantiate()
	instance.set_script(Fixture)
	root.add_child(instance)
	await process_frame
	var typed: LoadingScreen = instance as LoadingScreen
	if typed == null or typed.is_showing():
		printerr("TYPED_DISPATCH_DIAGNOSTIC HIDDEN_ORIGINAL_SCENE_REQUIRED")
		quit(1)
		return
	var before: int = int(instance.get("override_calls"))
	await typed.hide_screen()
	var after_typed: int = int(instance.get("override_calls"))
	await typed.call("hide_screen")
	var after_call: int = int(instance.get("override_calls"))
	print("TYPED_DISPATCH_DIAGNOSTIC ", JSON.stringify({"early_save_suspension":suspended,"same_original_packed_scene":true,"hidden_both_calls":not typed.is_showing(),"typed_override_delta":after_typed-before,"call_override_delta":after_call-after_typed,"map_transition_count":0,"production_sources_written":false,"real_save_contents_accessed":false}))
	instance.queue_free()
	await process_frame
	quit(0)
