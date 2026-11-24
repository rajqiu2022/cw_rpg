extends SceneTree
var bad: int=0
func _initialize()->void:
	root.child_entered_tree.connect(func(n:Node)->void:
		if n.name==&"PlatformBridge":n.call("set_checkpoint_saves_suspended",true)
	)
	_run.call_deferred()
func _run()->void:
	for path: String in ["res://scripts/adventure/adventure_runtime.gd","res://scripts/adventure/adventure_minimap.gd","res://data/scenes/adventure_zhuwei_hunting_ground.tres","res://data/scenes/adventure_xiangzhou_deep_mine.tres","res://data/scenes/adventure_luoyang_riverside_route.tres"]:
		var resource:Resource=load(path)
		if resource==null:bad+=1;printerr("NEW_RESOURCE_FAIL ",path)
	for name:String in ["forest","mine","luoyang"]:
		var texture:Texture2D=load("res://data/maps/adventure_20261030k/"+name+"_walk.svg")
		if texture==null or texture.get_size()!=Vector2(4096,3072):bad+=1
	await process_frame
	print("ADVENTURE_NEW_PARSE ",bad)
	quit(bad)
