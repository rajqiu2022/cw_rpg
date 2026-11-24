extends SceneTree

const SCENE_ID := &"linxi_village_center"
const OUTPUT_DIR := "res://screenshots/linxi_well_depth_20260929"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var router := root.get_node("SceneRouter")
	for sample in [
		{"name": "behind", "foot": Vector2(0.525, 0.390)},
		{"name": "front", "foot": Vector2(0.525, 0.550)}
	]:
		router.go_field_smart(SCENE_ID, sample.foot)
		for tick in range(120):
			await create_timer(0.05).timeout
			if current_scene != null and current_scene.has_method("_is_inside_walkable_screen"):
				break
		await create_timer(0.5).timeout
		for frame in range(8):
			await process_frame
		var player := current_scene.get("_player") as Player
		var well: Sprite2D = null
		for raw_object in current_scene.get("_scene_object_nodes"):
			if raw_object is Sprite2D and raw_object.name == "SceneObject_village_well":
				well = raw_object
				break
		if player == null or well == null:
			push_error("Linxi well or actor missing in %s capture" % sample.name)
			quit(1)
			return
		var correct_depth: bool = player.z_index < well.z_index if sample.name == "behind" else player.z_index > well.z_index
		if not correct_depth:
			push_error("Linxi well depth order wrong for %s: actor=%d well=%d" % [sample.name, player.z_index, well.z_index])
			quit(1)
			return
		print("[LinxiWellDepthCapture] %s actor=%d well=%d" % [sample.name, player.z_index, well.z_index])
		var output := OUTPUT_DIR.path_join("well_%s.png" % sample.name)
		if root.get_texture().get_image().save_png(output) != OK:
			push_error("Could not save Linxi well capture: %s" % output)
			quit(1)
			return
		print("[LinxiWellDepthCapture] " + output)
		if current_scene != null:
			current_scene.queue_free()
			await process_frame
	quit(0)
