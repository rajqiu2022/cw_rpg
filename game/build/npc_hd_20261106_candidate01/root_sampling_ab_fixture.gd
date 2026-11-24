extends SceneTree
## ROOT ONLY: sampling diagnosis, no formal resource/import edits.
const Adapter = preload("res://build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd")
var suspended := false
var failures := 0
var canvas: Node2D

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	call_deferred("_run")

func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		suspended = bool(node.call("is_checkpoint_saves_suspended"))

func _label(text: String, at: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", 20)
	canvas.add_child(label)

func _hd(texture: Texture2D, row: Dictionary, foot: Vector2, filter_mode: int) -> void:
	var mapping := Adapter.prepare_mapping(load(row.source), texture, row)
	if mapping.is_empty():
		failures += 1
		return
	var sprite := Sprite2D.new()
	sprite.texture = mapping.frames[0]
	sprite.centered = false
	sprite.texture_filter = filter_mode
	sprite.scale = Vector2.ONE * (128.0 / float(row.body_height))
	sprite.position = foot - mapping.body_anchors[0] * sprite.scale
	canvas.add_child(sprite)

func _run() -> void:
	if not suspended:
		printerr("NPC_HD_AB EARLY_SUSPEND_MISSING")
		quit(1)
		return
	root.size = Vector2i(1600, 900)
	canvas = Node2D.new()
	root.add_child(canvas)
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1600,0),Vector2(1600,900),Vector2(0,900)])
	background.color = Color(0.19,0.21,0.20)
	canvas.add_child(background)
	var adapter := root.get_node("PCSpriteViewRuntime")
	adapter.set_process(false)
	if adapter._mappings.size() != 3 or not adapter._map_errors.is_empty():
		printerr("NPC_HD_AB FORMAL_MAPPING_ERROR ", adapter._map_errors)
		quit(1)
		return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/characters/pc_hd_20261102c/source.json"))
	var index := 0
	for source: String in manifest.mappings:
		var row: Dictionary = manifest.mappings[source].duplicate(true)
		row.source = source
		var baseline := 310.0 + index * 400.0
		_label(String(row.atlas).get_file() + " | body 128px | unchanged source RGBA", Vector2(30,baseline-270))
		_label("Original low-res / LINEAR",Vector2(140,baseline-220))
		_label("Native HD / LINEAR (current)",Vector2(620,baseline-220))
		_label("Native HD / LINEAR + MIPMAPS",Vector2(1110,baseline-220))
		var original := Sprite2D.new()
		original.texture = load(source)
		original.hframes = int(row.source_hframes)
		original.vframes = int(row.source_vframes)
		original.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		original.scale = Vector2.ONE * (128.0 / float(row.source_body_height))
		original.position = Vector2(290,baseline) - (original.get_rect().position + Vector2(row.source_anchors[0][0],row.source_anchors[0][1]))*original.scale
		canvas.add_child(original)
		var texture := load(row.atlas) as Texture2D
		var image := texture.get_image()
		var source_size := image.get_size()
		var before := image.get_data()
		var base_bytes := source_size.x * source_size.y * 4
		if image.get_format() != Image.FORMAT_RGBA8 or before.size() != base_bytes:
			printerr("NPC_HD_AB UNEXPECTED_SOURCE_FORMAT_OR_BASE_LENGTH")
			quit(1)
			return
		print("NPC_HD_AB original mipmaps ",String(row.atlas)," ",image.has_mipmaps())
		_hd(texture,row,Vector2(790,baseline),CanvasItem.TEXTURE_FILTER_LINEAR)
		var mip_image := image.duplicate() as Image
		var mip_error := mip_image.generate_mipmaps()
		# Full-size get_region can preserve the generated mip chain. Compare
		# exactly the RGBA8 base level, not old base vs new base-plus-mip bytes.
		var after := mip_image.get_data()
		var base_unchanged := before == after.slice(0,base_bytes)
		var first_difference := -1
		if not base_unchanged:
			for offset: int in range(mini(base_bytes,after.size())):
				if before[offset] != after[offset]:
					first_difference = offset
					break
		if mip_error != OK or not mip_image.has_mipmaps() or not base_unchanged:
			failures += 1
		_hd(ImageTexture.create_from_image(mip_image),row,Vector2(1290,baseline),CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
		print("NPC_HD_AB ",JSON.stringify({"source":source,"base_rgba_exact":base_unchanged,"base_first_difference":first_difference,"base_bytes":base_bytes,"before_data_bytes":before.size(),"after_data_bytes":after.size(),"base_size":source_size,"mip_error":mip_error,"mipmap_count":mip_image.get_mipmap_count(),"body_height":row.body_height,"display_body":128}))
		index += 1
	for tick: int in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var dir := "res://build/npc_hd_20261106_candidate01/sampling_ab03"
	DirAccess.make_dir_recursive_absolute(dir)
	var result := root.get_texture().get_image()
	if result.save_png(dir+"/normal128_sampling.png") != OK:
		failures += 1
	print("NPC_HD_AB_RESULT ",JSON.stringify({"families":index,"failures":failures,"screenshot_size":result.get_size(),"formal_edits":false,"base_rgba_edits":false,"real_save_content_access":false}))
	quit(0 if failures == 0 else 1)
