extends SceneTree

# Model and terrain use the same orthographic direction and daylight.
# The projected bottom-center of the model is recorded instead of assuming
# the PNG's bottom edge is its physical foot.
const SOURCE := "res://art/external/polyhaven/boulder_01/boulder_01_1k.gltf"
const OUTPUT := "res://art/modules/world_map_v13/boulder_01_cc0_ortho_v3.png"
const META := "res://art/modules/world_map_v13/boulder_01_cc0_ortho_v3.json"


func _initialize() -> void:
	call_deferred("_render")


func _output_path() -> String:
	return OUTPUT


func _meta_path() -> String:
	return META


func _source_path() -> String:
	return SOURCE


func _camera_size() -> float:
	return 2.8


func _configure_model(_model: Node3D) -> void:
	pass


func _processing_metadata() -> Dictionary:
	return {}


func _bounds(node: Node3D, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		if child is Node3D:
			_bounds(child, meshes)


func _render() -> void:
	var packed := load(_source_path()) as PackedScene
	if packed == null:
		push_error("Licensed boulder glTF is missing")
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(768, 768)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var model := packed.instantiate() as Node3D
	world.add_child(model)
	_configure_model(model)
	var meshes: Array[MeshInstance3D] = []
	_bounds(model, meshes)
	var box := AABB()
	for index in meshes.size():
		var mesh_box: AABB = meshes[index].global_transform * meshes[index].get_aabb()
		box = mesh_box if index == 0 else box.merge(mesh_box)
	var foot := Vector3(box.get_center().x, box.position.y, box.get_center().z)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color.WHITE
	settings.ambient_light_energy = 0.62
	environment.environment = settings
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -34, 0)
	light.light_energy = 1.15
	world.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = _camera_size()
	camera.position = box.get_center() + Vector3(0, 5, 5)
	world.add_child(camera)
	camera.look_at(box.get_center())
	camera.current = true
	for frame in range(12):
		await process_frame
	var image := viewport.get_texture().get_image()
	if image == null:
		push_error("Run the boulder renderer with --rendering-driver opengl3")
		quit(1)
		return
	var crop := image.get_used_rect().grow(12).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var sprite := image.get_region(crop)
	var foot_uv := (camera.unproject_position(foot) - Vector2(crop.position)) / Vector2(crop.size)
	if sprite.save_png(_output_path()) != OK:
		quit(1)
		return
	var meta := FileAccess.open(_meta_path(), FileAccess.WRITE)
	var record := {"source": _source_path(), "license": "CC0", "foot_uv": [foot_uv.x, foot_uv.y], "size": [sprite.get_width(), sprite.get_height()], "camera_direction": [0, 1, 1]}
	record.merge(_processing_metadata())
	meta.store_string(JSON.stringify(record, "\t"))
	meta.close()
	print("[CC0BoulderOrthoV3] ", sprite.get_size(), " projected foot=", foot_uv)
	viewport.queue_free()
	await process_frame
	quit(0)
