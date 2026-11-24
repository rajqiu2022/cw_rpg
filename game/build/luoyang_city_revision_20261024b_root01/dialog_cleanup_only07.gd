extends SceneTree
## Only completion-signal cleanup after accepted 42 functional observations.
## Does not replay Field, DP, UI, or any conversation assertion.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var worker := Node.new()
	worker.add_user_signal("finished", [{"name":"exit_code","type":TYPE_INT}])
	root.add_child(worker)
	worker.call_deferred("emit_signal", "finished", 0)
	var code: int = int(await Signal(worker, &"finished"))
	var reference: WeakRef = weakref(worker)
	worker.queue_free()
	await process_frame
	await process_frame
	var cleared: bool = reference.get_ref() == null
	print(JSON.stringify({"scope":"COMPLETION_SIGNAL_QUEUE_FREE_ONLY_NOT_42_FUNCTIONAL_REPLAY", "worker_gone":cleared, "code":code, "passed":cleared and code==0}))
	quit(0 if cleared and code==0 else 1)
