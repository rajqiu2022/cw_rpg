extends SceneTree
## ROOT ONLY. Three candidate rows; no real field/save contents.
const Adapter = preload("res://build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd")
const BASE := "res://build/npc_hd_20261106_batch02/"
var suspended := false
var failures := 0
var checks := 0

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	call_deferred("_run")

func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		suspended = bool(node.call("is_checkpoint_saves_suspended"))

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: failures += 1
	print("NPC_B02 ", "PASS " if ok else "FAIL ", label)

func label_at(parent: Node, words: String, pos: Vector2) -> void:
	var label := Label.new()
	label.text = words
	label.position = pos
	label.add_theme_font_size_override("font_size", 17)
	parent.add_child(label)

func _run() -> void:
	if not suspended:
		printerr("NPC_B02 EARLY_SUSPEND_MISSING")
		quit(1)
		return
	root.size = Vector2i(1600,900)
	var adapter := root.get_node("PCSpriteViewRuntime")
	adapter.set_process(false)
	check("before candidate injection formal16 present", adapter._mappings.size() == 16 and adapter._map_errors.is_empty())
	if failures > 0:
		quit(1)
		return
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"mipmap_import_plan.json"))
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"source.batch02.candidate.json"))
	var canvas := Node2D.new()
	root.add_child(canvas)
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1600,0),Vector2(1600,900),Vector2(0,900)])
	bg.color = Color(0.18,0.21,0.19)
	canvas.add_child(bg)
	label_at(canvas,"BATCH02 CANDIDATES - old / native HD (128 world-unit body; not screen-pixel claim)",Vector2(30,25))
	var guard: NPCNode
	var guard_entry: Dictionary
	var idle_source := ""
	var walk_source := ""
	var index := 0
	var frames_checked := 0
	for record: Dictionary in plan.records:
		var source := String(record.source)
		var row: Dictionary = payload.mappings[source]
		var texture := CompressedTexture2D.new()
		check(source+" ctex load",texture.load(String(record.ctex)) == OK)
		var src_image := Image.load_from_file(String(record.png))
		var imp := texture.get_image()
		var bytes := src_image.get_width()*src_image.get_height()*4
		check(source+" base RGBA prefix exact and mipmaps",imp != null and imp.has_mipmaps() and imp.get_size()==src_image.get_size() and src_image.get_format()==Image.FORMAT_RGBA8 and imp.get_format()==Image.FORMAT_RGBA8 and imp.get_data().slice(0,bytes)==src_image.get_data())
		var mapping: Dictionary = Adapter.prepare_mapping(load(source),texture,row)
		check(source+" prepared",not mapping.is_empty())
		if mapping.is_empty(): continue
		adapter._mappings[source] = mapping
		var at := Vector2(60+index*510,120)
		label_at(canvas,String(row.atlas).get_file().replace("_native_20261106b02.png",""),at)
		var display_scale := 128.0/float(row.source_body_height)
		var old := Sprite2D.new()
		old.texture = load(source)
		old.hframes = int(row.source_hframes)
		old.vframes = int(row.source_vframes)
		old.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		old.scale = Vector2.ONE*display_scale
		var foot: Vector2 = mapping.source_anchors[0]
		old.position = at+Vector2(100,210)-(old.get_rect().position+foot)*display_scale
		canvas.add_child(old)
		var npc := load("res://scenes/npc_node.tscn").instantiate() as NPCNode
		if npc == null:
			check(source+" NPCNode instantiated",false)
			quit(1)
			return
		npc.sprite_path = source
		npc.position = at+Vector2(340,210)
		canvas.add_child(npc)
		npc.set_process(false)
		npc.set_physics_process(false)
		# NPCNode creates its optional label dynamically only for nonempty npc_name.
		# It is not a child named NameLabel; the blank fixture name creates none.
		if npc._name_label != null: npc._name_label.hide()
		if npc.prompt != null: npc.prompt.hide()
		var body := npc.get("_body_collider") as StaticBody2D
		if npc.sprite == null or body == null or body.get_child_count() == 0:
			check(source+" required sprite/body ready",false)
			quit(1)
			return
		var shape := body.get_child(0) as CollisionShape2D
		if shape == null or shape.shape == null:
			check(source+" required collision shape ready",false)
			quit(1)
			return
		npc.sprite.scale = Vector2.ONE*display_scale
		npc.sprite.position = -(npc.sprite.get_rect().position+foot)*display_scale
		adapter._adopt_actor(npc)
		var entry: Dictionary = adapter._actors[npc.get_instance_id()]
		var view: Sprite2D = entry.view.get_ref()
		var source_texture := npc.sprite.texture
		var body_before := [body.position,shape.position,shape.shape,shape.shape.get_rect()]
		for frame: int in range(int(row.source_hframes)*int(row.source_vframes)):
			for flip: bool in [false,true]:
				npc.sprite.frame = frame
				npc.sprite.flip_h = flip
				adapter._sync_entry(entry)
				var sf: Vector2 = mapping.source_anchors[frame]
				var hf: Vector2 = mapping.body_anchors[frame]
				if flip:
					sf.x = mapping.source_cell.x-sf.x
					hf.x = mapping.cell.x-hf.x
				var error := npc.sprite.to_global(npc.sprite.get_rect().position+sf).distance_to(view.to_global(hf))
				check(source+" frame%d flip%s foot=%.6f"%[frame,flip,error],error<0.001 and entry.reason=="AUTHORED_NATIVE_HD_VIEW" and (view.texture as AtlasTexture).atlas==texture and (view.texture as AtlasTexture).region.has_area())
			frames_checked += 1
		npc.sprite.frame=0
		npc.sprite.flip_h=false
		adapter._sync_entry(entry)
		check(source+" source/physics unchanged",npc.sprite.texture==source_texture and body_before==[body.position,shape.position,shape.shape,shape.shape.get_rect()])
		check(source+" native body128/filter",absf(float(row.body_height)*absf(view.global_scale.y)-128.0)<0.01 and view.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
		label_at(canvas,"source %d / native %d"%[row.source_body_height,row.body_height],at+Vector2(30,245))
		if "idle_down_4f" in source:
			guard=npc
			guard_entry=entry
			idle_source=source
		if "walk_right" in source: walk_source=source
		index+=1
	check("exact three rows and thirteen frames",index==3 and frames_checked==13)
	# One existing NPC switches original source actions; adapter must not change business frame contracts.
	if guard != null and not walk_source.is_empty():
		for source: String in [idle_source,walk_source,idle_source]:
			guard.sprite.texture=load(source)
			guard.sprite.hframes=int(payload.mappings[source].source_hframes)
			guard.sprite.vframes=1
			guard.sprite.frame=0
			guard.set("_in_range",true)
			guard._set_interaction_highlight(true)
			var original: ShaderMaterial=guard.sprite.material
			adapter._sync_entry(guard_entry)
			var v: Sprite2D=guard_entry.view.get_ref()
			var copied: ShaderMaterial=v.material
			var m: Dictionary=adapter._mappings[source]
			var switch_source_foot: Vector2=m.source_anchors[0]
			var switch_hd_foot: Vector2=m.body_anchors[0]
			var switch_error := guard.sprite.to_global(guard.sprite.get_rect().position+switch_source_foot).distance_to(v.to_global(switch_hd_foot))
			check("action switch foot "+source,switch_error<0.001)
			check("action switch+known outline "+source,guard_entry.reason=="AUTHORED_NATIVE_HD_VIEW" and (v.texture as AtlasTexture).atlas==m.atlas and copied!=null and is_equal_approx(float(copied.get_shader_parameter("outline_width"))*float(m.ratio),float(original.get_shader_parameter("outline_width"))))
			guard.set("_in_range",false)
			guard._set_interaction_highlight(false)
			adapter._sync_entry(guard_entry)
			check("action range release "+source,guard.sprite.material==null and v.material==null and v.visible)
	else: check("guard switch fixture actor",false)
	for tick: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	var out := BASE+"visual02/"
	DirAccess.make_dir_recursive_absolute(out)
	check("screenshot",root.get_texture().get_image().save_png(out+"normal_comparison.png")==OK)
	print("NPC_B02_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"new_rows":index,"frames":frames_checked,"candidate_injection":true,"formal_before":16,"body_world_px":128,"viewport":root.get_visible_rect().size,"screenshot_size":root.get_texture().get_size(),"real_field":false,"real_save_content_access":false}))
	quit(0 if failures==0 else 1)
