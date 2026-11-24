extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var town: Node2D=load("res://scenes/drafts/miao_terrain_20261029i/miao_town.tscn").instantiate();root.add_child(town)
	for i in range(4):await physics_frame
	var results: Array=[]
	for p in [Vector2(1620,3840),Vector2(1615.5,3867),Vector2(1615.5,3860),Vector2(1620,3870)]:
		var q:=PhysicsShapeQueryParameters2D.new();var s:=RectangleShape2D.new();s.size=Vector2(35,25);q.shape=s;q.transform=Transform2D(0,p);q.collision_mask=8|town.terrain.layer(town.terrain.level_at(p))
		var hits: Array=[]
		for hit: Dictionary in town.get_world_2d().direct_space_state.intersect_shape(q):hits.append(str(hit.collider.get_path()))
		results.append({"point":p,"hits":hits})
	print(JSON.stringify(results));print("ACTOR_SHAPE ",town.actor.get_node("CollisionShape2D").shape," ",town.actor.get_node("CollisionShape2D").position)
	town.queue_free();await process_frame;quit()
