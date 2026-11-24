extends SceneTree
## ROOT ONLY. Isolated actors, no field/router/real saves. Candidate is not autoload.
const Adapter = preload("res://build/npc_hd_20261106_candidate01/pc_sprite_view_runtime.candidate.gd")
var passed := 0
var failed := 0
var suspended := false

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	call_deferred("_run")

func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		suspended = bool(node.call("is_checkpoint_saves_suspended"))

func check(label: String, ok: bool) -> void:
	if ok: passed += 1
	else: failed += 1
	print("NPC_HD06 ", "PASS " if ok else "FAIL ", label)

func _run() -> void:
	if not suspended:
		printerr("NPC_HD06 EARLY_SUSPEND_MISSING")
		quit(1)
		return
	# Fixture-only isolation: the formal display autoload must not compete with
	# this candidate. Its production file and all NPC business remain untouched.
	var existing := root.get_node_or_null("PCSpriteViewRuntime")
	if existing != null:
		existing.free()
	var adapter := Adapter.new()
	root.add_child(adapter)
	adapter.set_process(false)
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://build/npc_hd_20261106_candidate01/source.candidate.json"))
	for source: String in payload.mappings:
		var row: Dictionary = payload.mappings[source]
		var key := "waiter" if "waiter" in source else "vendor"
		var im := Image.load_from_file("res://build/npc_hd_20261106_candidate01/" + key + "_idle_down.png")
		adapter._mappings[source] = Adapter.prepare_mapping(load(source), ImageTexture.create_from_image(im), row)
	check("candidate two mappings plus unchanged farmer", adapter._mappings.size() == 3)
	for source: String in adapter._mappings:
		var npc := load("res://scenes/npc_node.tscn").instantiate() as NPCNode
		npc.sprite_path = source
		root.add_child(npc)
		npc.set_process(false)
		npc.set_physics_process(false)
		adapter._adopt_actor(npc)
		var entry: Dictionary = adapter._actors[npc.get_instance_id()]
		var sprite: Sprite2D = npc.sprite
		var view := sprite.get_node(Adapter.VIEW_NAME) as Sprite2D
		var mapping: Dictionary = adapter._mappings[source]
		var original_texture := sprite.texture
		var body := npc.get("_body_collider") as StaticBody2D
		var shape := body.get_child(0) as CollisionShape2D
		var body_state := [body.position, shape.position, shape.shape, shape.shape.get_rect()]
		var anchors_ok := true
		for frame: int in range(4):
			for flip: bool in [false, true]:
				sprite.frame = frame
				sprite.flip_h = flip
				sprite.offset = Vector2(3.25, -2.5)
				adapter._sync_entry(entry)
				var native_foot: Vector2 = mapping.source_anchors[frame]
				var hd_foot: Vector2 = mapping.body_anchors[frame]
				if flip:
					native_foot.x = mapping.source_cell.x - native_foot.x
					hd_foot.x = mapping.cell.x - hd_foot.x
				anchors_ok = anchors_ok and sprite.to_global(sprite.get_rect().position + native_foot).distance_to(view.to_global(hd_foot)) < 0.001
		check(source + " four frames+flips exact foot", anchors_ok)
		npc.set("_in_range", true)
		npc._set_interaction_highlight(true)
		var original_outline: ShaderMaterial = sprite.material
		adapter._sync_entry(entry)
		var copied: ShaderMaterial = view.material
		check("highlight HD preserved, native discarded", view.visible and copied != null and sprite.material == adapter._suppression_material and sprite.self_modulate.a == 0)
		check("outline pulse/color/strength and world width", copied.get_shader_parameter("pulse") == original_outline.get_shader_parameter("pulse") and copied.get_shader_parameter("outline_color") == original_outline.get_shader_parameter("outline_color") and copied.get_shader_parameter("base_strength") == original_outline.get_shader_parameter("base_strength") and is_equal_approx(float(copied.get_shader_parameter("outline_width")) * float(mapping.ratio), float(original_outline.get_shader_parameter("outline_width"))))
		for i: int in range(8):
			sprite.material = original_outline
			adapter._sync_entry(entry)
		check("repeated owner material assignment reuses clone", view.material == copied)
		npc.set("_in_range", false)
		npc._set_interaction_highlight(false)
		adapter._sync_entry(entry)
		check("range exit no stale outline", sprite.material == null and view.material == null and view.visible)
		var external := CanvasItemMaterial.new()
		sprite.material = external
		adapter._sync_entry(entry)
		check("foreign material honest native fallback", sprite.material == external and sprite.self_modulate.a == 1 and not view.visible)
		sprite.material = null
		adapter._sync_entry(entry)
		check("external release restores HD", view.visible)
		sprite.texture = ImageTexture.create_from_image(Image.create(160, 160, false, Image.FORMAT_RGBA8))
		adapter._sync_entry(entry)
		check("unmapped action restores native", sprite.self_modulate.a == 1 and not view.visible)
		sprite.texture = original_texture
		adapter._sync_entry(entry)
		check("return mapped action restores HD", view.visible)
		check("business body unchanged", body_state == [body.position, shape.position, shape.shape, shape.shape.get_rect()])
		adapter._release_entry(npc.get_instance_id())
		check("release native restored", sprite.self_modulate.a == 1 and sprite.material == null)
		npc.queue_free()
	await process_frame
	adapter.queue_free()
	await process_frame
	print("NPC_HD06_RESULT ", JSON.stringify({"passed":passed,"failed":failed,"real_save_access":false,"real_field":false}))
	quit(0 if failed == 0 else 1)
