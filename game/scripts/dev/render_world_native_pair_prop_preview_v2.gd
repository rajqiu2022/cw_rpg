extends SceneTree

# Art/depth preview only. Navigation and collision are not inferred from this
# screenshot: each candidate prop still needs an authored foot contract.
const SIZE := Vector2i(3072, 1024)
const GROUND := "res://build/world_native_pair_shared_v2_visual.png"
const BOULDER := "res://art/modules/world_map_v13/boulder_01_cc0_southwest_v1.png"
const SHRUB := "res://art/modules/world_map_v13/shrub_cluster_generated_v1_candidate.png"
const PLAYER := "res://art/characters/weapon_variants/lengguyun/v7_idle_stable/sword/lengguyun_sword_idle_down_25d_4f.png"
const OUTPUT := "res://build/world_native_pair_prop_preview_v2.png"
const TOPOLOGY := "res://build/world_native_pair_shared_v2_topology.png"
const WALK := "res://build/world_native_pair_shared_v2_walk.png"
const PROP_CONTRACT := preload("res://scripts/dev/world_native_pair_prop_contract_v1.gd")


func _initialize() -> void:
	call_deferred("_render")


func _texture(path: String) -> Texture2D:
	var source := _read_png(path)
	return ImageTexture.create_from_image(source) if source != null else null


func _read_png(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	return image if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK else null


func _add_prop(parent: Node2D, name: String, texture: Texture2D, foot: Vector2, size: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.name = name
	sprite.texture = texture
	sprite.position = foot - Vector2(0.0, size.y * 0.5 - 6.0)
	sprite.scale = size / Vector2(texture.get_size())
	sprite.z_index = clampi(int(floor(foot.y / 8.0)), 0, 255)
	parent.add_child(sprite)


func _add_actor(parent: Node2D, name: String, strip: Texture2D, foot: Vector2) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = strip
	atlas.region = Rect2(0, 0, 160, 160)
	var sprite := Sprite2D.new()
	sprite.name = name
	sprite.texture = atlas
	sprite.position = foot - Vector2(0.0, 75.0)
	sprite.scale = Vector2.ONE * 0.72
	sprite.z_index = clampi(int(floor(foot.y / 8.0)), 0, 255)
	parent.add_child(sprite)


func _validate_placement(topology: Image, walk: Image, props: Array[Dictionary], actors: Array[Vector2]) -> bool:
	for prop in props:
		var foot: Vector2 = prop["foot"]
		var footprint: Vector2 = prop["footprint"]
		var footprint_rect := Rect2(foot - footprint * 0.5, footprint)
		for offset in [Vector2.ZERO, Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(-0.5, 0.5), Vector2(0.5, 0.5)]:
			var sample := Vector2i((foot + footprint * offset).round())
			if not Rect2i(Vector2i.ZERO, SIZE).has_point(sample):
				push_error("Prop footprint leaves terrain: " + String(prop["id"]))
				return false
			if walk.get_pixelv(sample).r < 0.9 or topology.get_pixelv(sample).g > 0.12:
				push_error("Prop footprint intersects sea/cliff/road: " + String(prop["id"]))
				return false
		for actor in actors:
			if footprint_rect.has_point(actor):
				push_error("Actor feet inside prop footprint: " + String(prop["id"]))
				return false
	return true


func _render() -> void:
	var ground := _texture(GROUND)
	var boulder := _texture(BOULDER)
	var shrub := _texture(SHRUB)
	var player := _texture(PLAYER)
	var topology := _read_png(TOPOLOGY)
	var walk := _read_png(WALK)
	if ground == null or boulder == null or shrub == null or player == null or topology == null or walk == null:
		push_error("Pair ground or preview prop is missing")
		quit(1)
		return
	var props: Array[Dictionary] = PROP_CONTRACT.props()
	for prop in props:
		prop["texture"] = boulder if prop["texture"] == PROP_CONTRACT.BOULDER else shrub
	var actor_feet: Array[Vector2] = [Vector2(1175, 665), Vector2(1275, 835), Vector2(2030, 640)]
	if not _validate_placement(topology, walk, props, actor_feet):
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node2D.new()
	viewport.add_child(world)
	var background := Sprite2D.new()
	background.texture = ground
	background.position = Vector2(SIZE) * 0.5
	background.z_index = -100
	world.add_child(background)
	for prop in props:
		_add_prop(world, String(prop["id"]), prop["texture"], prop["foot"], prop["size"])
	_add_actor(world, "ActorBehindShrub", player, actor_feet[0])
	_add_actor(world, "ActorInFrontOfShrub", player, actor_feet[1])
	_add_actor(world, "ActorBehindBoulder", player, actor_feet[2])
	for frame in 12:
		await process_frame
	var image := viewport.get_texture().get_image()
	if image == null or image.get_size() != SIZE or image.save_png(OUTPUT) != OK:
		push_error("Could not render isolated prop/depth preview")
		quit(1)
		return
	print("[WorldNativePairPropPreview] ", OUTPUT, " 4 prop foot contracts and 3 actor feet validated")
	viewport.queue_free()
	await process_frame
	quit(0)
