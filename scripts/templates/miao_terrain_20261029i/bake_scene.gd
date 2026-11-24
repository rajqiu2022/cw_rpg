extends SceneTree
func own_branch(node: Node,scene: Node) -> void:
	node.owner=scene
	for child: Node in node.get_children():own_branch(child,scene)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var path: String="res://scenes/drafts/miao_terrain_20261029i/miao_town.tscn"
	var town: Node2D=load(path).instantiate();root.add_child(town);town.controls_enabled=false
	# Synchronous setup: export the exact initial editor state, before any patrol advances.
	own_branch(town.get_node("Terrain"),town)
	town.set_meta("terrain_baked",true)
	var packed:=PackedScene.new();var status:=packed.pack(town)
	if status==OK:status=ResourceSaver.save(packed,path)
	print("BAKE_STATUS ",status," NODES ",town.get_node("Terrain").get_child_count())
	town.queue_free();await process_frame;quit(0 if status==OK else 1)
