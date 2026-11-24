extends SceneTree
## ROOT ONLY. Two formally mapped families + ten explicitly candidate families.
## Normal 128px body comparison; no field/router or real save operations.
const Adapter = preload("res://build/npc_hd_20261106_candidate01/pc_sprite_view_runtime.sampling_candidate.gd")
var suspended := false
var failures := 0

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	call_deferred("_run")

func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		suspended = bool(node.call("is_checkpoint_saves_suspended"))

func _label(canvas: Node, text: String, at: Vector2, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", 13)
	label.modulate = color
	canvas.add_child(label)

func _run() -> void:
	if not suspended:
		printerr("NPC_HD_VIS EARLY_SUSPEND_MISSING")
		quit(1)
		return
	root.size = Vector2i(1600, 900)
	var canvas := Node2D.new()
	root.add_child(canvas)
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2.ZERO, Vector2(1600,0), Vector2(1600,900), Vector2(0,900)])
	background.color = Color(0.19,0.21,0.20)
	canvas.add_child(background)
	var formal_adapter := root.get_node("PCSpriteViewRuntime")
	formal_adapter.set_process(false)
	var primary: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/characters/pc_hd_20261102c/source.json"))
	var combined: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://build/npc_hd_20261106_candidate01/source.twelve.candidate.json"))
	print("NPC_HD_VIS formal mappings before candidates: ", formal_adapter._mappings.size())
	if formal_adapter._mappings.size() != 3 or not formal_adapter._map_errors.is_empty():
		printerr("NPC_HD_VIS FORMAL_MAPPING_IMPORT_OR_SOURCE_ERROR ", formal_adapter._map_errors)
		quit(1)
		return
	var adapter := Adapter.new()
	root.add_child(adapter)
	adapter.set_process(false)
	var mip_plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://build/npc_hd_20261106_candidate01/mipmap_import_plan.json"))
	var mip_sources: Dictionary = {}
	for record: Dictionary in mip_plan.records:
		mip_sources[record.source] = record
	var index := 0
	for source: String in combined.mappings:
		var row: Dictionary = combined.mappings[source]
		var is_formal: bool = primary.mappings.has(source)
		var role := String(row.atlas).get_file().replace("_20261106.png", "").replace("_native", "")
		# All new mipmapped imports are isolated candidates, including the two
		# already-formal families. Keep formal3 assertion above before injection.
		var mip_record: Dictionary = mip_sources[source]
		var mip_texture := CompressedTexture2D.new()
		var import_error := mip_texture.load(String(mip_record.ctex))
		if import_error != OK:
			printerr("NPC_HD_VIS CTEX_LOAD_FAILED ",source," ",import_error)
			quit(1)
			return
		var source_image := Image.load_from_file(String(mip_record.png))
		var mip_image := mip_texture.get_image()
		var base_bytes := source_image.get_width()*source_image.get_height()*4
		var exact_base := source_image.get_format() == Image.FORMAT_RGBA8 and mip_image.get_format() == Image.FORMAT_RGBA8 and source_image.get_data() == mip_image.get_data().slice(0,base_bytes)
		if not exact_base or not mip_image.has_mipmaps() or source_image.get_size() != mip_image.get_size():
			failures += 1
		print("NPC_HD_VIS MIP_BASE ",JSON.stringify({"source":source,"base_rgba_exact":exact_base,"base_bytes":base_bytes,"mips":mip_image.get_mipmap_count(),"source_size":source_image.get_size(),"imported_size":mip_image.get_size()}))
		adapter._mappings[source] = Adapter.prepare_mapping(load(source), mip_texture, row)
		var mapping: Dictionary = adapter._mappings[source]
		if mapping.is_empty():
			failures += 1
			continue
		var origin := Vector2((index % 4)*400, (index / 4)*225)
		_label(canvas, role + (" [FAMILY FORMAL / MIP CAND.]" if is_formal else " [CANDIDATE]"), origin+Vector2(8,8), Color(0.75,0.90,0.83))
		_label(canvas, "native                         HD view", origin+Vector2(76,30))
		_label(canvas, "source body %d -> native HD %d" % [row.source_body_height,row.body_height], origin+Vector2(25,205))
		var line := Line2D.new()
		line.points = PackedVector2Array([origin+Vector2(30,188),origin+Vector2(390,188)])
		line.default_color = Color(0.65,0.65,0.55,0.35)
		line.width = 1.0
		canvas.add_child(line)
		var display_scale := 128.0 / float(row.source_body_height)
		var original := Sprite2D.new()
		original.texture = load(source)
		original.hframes = int(row.source_hframes)
		original.vframes = int(row.source_vframes)
		original.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		original.scale = Vector2.ONE*display_scale
		var foot: Vector2 = mapping.source_anchors[0]
		original.position = origin+Vector2(110,188) - (original.get_rect().position+foot)*display_scale
		canvas.add_child(original)
		var npc := load("res://scenes/npc_node.tscn").instantiate() as NPCNode
		npc.sprite_path = source
		npc.position = origin+Vector2(300,188)
		canvas.add_child(npc)
		npc.set_process(false)
		npc.set_physics_process(false)
		if npc.has_node("NameLabel"):
			npc.get_node("NameLabel").hide()
		npc.sprite.scale = Vector2.ONE*display_scale
		npc.sprite.position = -(npc.sprite.get_rect().position+foot)*display_scale
		adapter._adopt_actor(npc)
		adapter._sync_entry(adapter._actors[npc.get_instance_id()])
		if adapter._actors[npc.get_instance_id()].reason != "AUTHORED_NATIVE_HD_VIEW":
			failures += 1
		var hd_view := adapter._actors[npc.get_instance_id()].view.get_ref() as Sprite2D
		var global_body := float(row.body_height) * absf(hd_view.global_scale.y)
		if absf(global_body-128.0) > 0.01 or hd_view.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS:
			failures += 1
		print("NPC_HD_VIS ", role, " ", "FORMAL_FAMILY_MIP_CANDIDATE" if is_formal else "CANDIDATE", " ", adapter._actors[npc.get_instance_id()].reason," body_world_px=",global_body)
		index += 1
	for tick: int in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var dir := "res://build/npc_hd_20261106_candidate01/visual03"
	DirAccess.make_dir_recursive_absolute(dir)
	var err := root.get_texture().get_image().save_png(dir+"/normal128_comparison.png")
	if err != OK: failures += 1
	print("NPC_HD_VIS_RESULT ",JSON.stringify({"panels":index,"failures":failures,"formal_new_families":2,"candidate_remaining_families":10,"mipmap_imports_all_candidate":true,"viewport_size":root.get_visible_rect().size,"canvas_transform":root.get_canvas_transform(),"screenshot_size":root.get_texture().get_size(),"body_world_px":128,"screenshot":dir+"/normal128_comparison.png","real_field":false,"real_save_content_access":false}))
	quit(0 if failures == 0 else 1)
