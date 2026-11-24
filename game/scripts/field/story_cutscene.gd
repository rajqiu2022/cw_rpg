extends RefCounted


static func walk_to(player: CharacterBody2D, destination: Vector2, safe_foot: Callable) -> void:
	var start := player.global_position
	var direction := destination - start
	var samples := maxi(1, ceili(direction.length() / 12.0))
	for index in range(1, samples + 1):
		if not safe_foot.call(start.lerp(destination, float(index) / samples)):
			return
	player.set_physics_process(false)
	var duration := clampf(direction.length() / 260.0, 0.18, 1.05)
	var tween := player.create_tween()
	tween.tween_method(func(progress: float) -> void:
		player.global_position = start.lerp(destination, progress)
		player.set_walk_direction(direction, true)
		player._advance_walk_frame(player.get_process_delta_time())
	, 0.0, 1.0, duration)
	await tween.finished
	player.set_walk_direction(direction, false)
	player.set_physics_process(true)


static func enter_actor(layer: Node2D, frames: Array[Texture2D], start: Vector2,
		destination: Vector2, height: float, face_right: bool, depth_limit: int,
		jump_height: float = 0.0) -> Sprite2D:
	var actor := Sprite2D.new()
	actor.name = "StoryActor"
	actor.texture = frames[0]
	actor.offset.y = -frames[0].get_height() * 0.5 + 14
	actor.scale = Vector2.ONE * height / (frames[0].get_height() - 20)
	actor.flip_h = destination.x > start.x
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	layer.add_child(actor)
	actor.position = start
	actor.z_index = clampi(floori(start.y / 8.0), 0, depth_limit)
	var tween := actor.create_tween()
	tween.tween_method(func(progress: float) -> void:
		var foot := start.lerp(destination, progress)
		actor.position = foot - Vector2(0.0, sin(progress * PI) * jump_height)
		actor.z_index = clampi(floori(foot.y / 8.0), 0, depth_limit)
		if progress >= 0.76:
			actor.flip_h = face_right
		actor.texture = frames[2] if progress >= 0.76 else frames[int(progress * 8.0) % 2]
	, 0.0, 1.0, 0.56)
	await tween.finished
	actor.flip_h = face_right
	actor.texture = frames[3]
	return actor
