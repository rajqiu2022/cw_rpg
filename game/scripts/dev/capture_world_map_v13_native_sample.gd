extends SceneTree

## Isolated candidate render. It never edits or routes to the formal v12 map
## or the existing v13 staging scene, and it does not create gameplay nav.

const STANDARD_MASTER := "res://build/world_map_v13_native_center_east_candidate/terrain_master_native_candidate.png"
const LOW_DETAIL_MASTER := "res://build/world_map_v13_native_center_east_lowdetail_candidate/terrain_master_native_candidate.png"
const TOPOLOGY_REFERENCE := "res://art/backgrounds/world_map_v13_tiles/world_map_v13_unified_topology_master_v1_candidate.png"
const STANDARD_OUTPUT := "res://build/world_map_v13_native_center_east_candidate"
const LOW_DETAIL_OUTPUT := "res://build/world_map_v13_native_center_east_lowdetail_candidate"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("A rendering display is required for native terrain screenshots")
		quit(1)
		return
	var low_detail := "--low-detail" in OS.get_cmdline_user_args()
	var master_path := LOW_DETAIL_MASTER if low_detail else STANDARD_MASTER
	var output_path := LOW_DETAIL_OUTPUT if low_detail else STANDARD_OUTPUT
	var texture := load(master_path) as Texture2D
	if texture == null or texture.get_size() != Vector2(4608, 3072):
		push_error("Native candidate master is missing or not 4608x3072")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path))
	var canvas := Node2D.new()
	canvas.name = "V13NativeTerrainCandidateOnly"
	root.add_child(canvas)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	canvas.add_child(sprite)
	var camera := Camera2D.new()
	camera.zoom = Vector2(1.25, 1.25)
	canvas.add_child(camera)
	camera.make_current()
	var shots := {
		"center_east_seam_1p25": Vector2(3072, 1536),
		"heartland_1p25": Vector2(2304, 1536),
		"double_cove_1p25": Vector2(3830, 1510),
	}
	for name in shots:
		camera.position = shots[name]
		for frame in range(5):
			await process_frame
		await create_timer(0.15).timeout
		var frame_image := root.get_texture().get_image()
		var path := output_path.path_join(String(name) + ".png")
		if frame_image == null or frame_image.save_png(path) != OK:
			push_error("Failed to save " + path)
			quit(1)
			return
		print("[NATIVE_CANDIDATE] " + ProjectSettings.globalize_path(path))
	var reference := load(TOPOLOGY_REFERENCE) as Texture2D
	if reference != null and reference.get_size() == Vector2(1536, 1024):
		sprite.texture = reference
		sprite.scale = Vector2(3.0, 3.0)
		camera.position = shots["center_east_seam_1p25"]
		for frame in range(5):
			await process_frame
		var reference_path := output_path.path_join("topology_reference_same_camera_1p25.png")
		if root.get_texture().get_image().save_png(reference_path) != OK:
			push_error("Failed to save " + reference_path)
			quit(1)
			return
		print("[NATIVE_REFERENCE] " + ProjectSettings.globalize_path(reference_path))
	canvas.queue_free()
	for frame in range(3):
		await process_frame
	quit(0)
