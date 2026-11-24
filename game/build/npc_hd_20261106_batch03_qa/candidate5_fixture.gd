extends SceneTree
## ROOT ONLY. Five candidate consumers only, no travel or save contents.
const Adapter = preload("res://build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd")
const BASE := "res://build/npc_hd_20261106_batch03/"
const OUT := "res://build/npc_hd_20261106_batch03_qa/visual02/"
## run01 passed all 36 frames / 72 flip-foot cases before a fixture material-read error.
## Residual run02 only repeats setup and verifies switch/material release + normal image.
const RESIDUAL_ONLY := true
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
	print("NPC_B03 ", "PASS " if ok else "FAIL ", label)

func caption(parent: Node, words: String, pos: Vector2) -> void:
	var label := Label.new()
	label.text = words
	label.position = pos
	label.add_theme_font_size_override("font_size", 16)
	parent.add_child(label)

func _run() -> void:
	if not suspended:
		printerr("NPC_B03 EARLY_SUSPEND_MISSING")
		quit(1)
		return
	root.size = Vector2i(1600,900)
	var adapter := root.get_node("PCSpriteViewRuntime")
	adapter.set_process(false)
	check("formal before19", adapter._mappings.size()==19 and adapter._map_errors.is_empty())
	var guard: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"mapping_plan.json"))
	check("complete5rows36frames",bool(guard.get("complete",false)) and guard.new_mappings==5 and guard.expected_new_frames==36)
	if failures>0:
		quit(1)
		return
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"mipmap_import_plan.json"))
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"source.batch03.candidate.json"))
	var canvas := Node2D.new()
	root.add_child(canvas)
	var bg := Polygon2D.new()
	bg.polygon=PackedVector2Array([Vector2.ZERO,Vector2(1600,0),Vector2(1600,900),Vector2(0,900)])
	bg.color=Color(0.18,0.21,0.19)
	canvas.add_child(bg)
	caption(canvas,"BATCH03 - source / native HD: 128 world-unit body, only 5 new consumers",Vector2(20,15))
	var actors: Array[NPCNode]=[]
	var sources: Array[String]=[]
	var index:=0
	var unique_frames:=0
	var foot_cases:=0
	for record: Dictionary in plan.records:
		var source:=String(record.source)
		var row: Dictionary=payload.mappings[source]
		var texture:=CompressedTexture2D.new()
		check(source+" ctex",texture.load(String(record.ctex))==OK)
		var img:=Image.load_from_file(String(record.png))
		var imp:=texture.get_image()
		check(source+" baseRGBA+mips",imp!=null and imp.has_mipmaps() and imp.get_size()==img.get_size() and imp.get_format()==Image.FORMAT_RGBA8 and img.get_format()==Image.FORMAT_RGBA8 and imp.get_data().slice(0,img.get_width()*img.get_height()*4)==img.get_data())
		var mapping: Dictionary=Adapter.prepare_mapping(load(source),texture,row)
		check(source+" prepare",not mapping.is_empty())
		if mapping.is_empty(): continue
		adapter._mappings[source]=mapping
		var at:=Vector2(30+(index%3)*520,70+(index/3)*375)
		caption(canvas,String(record.png).get_file().replace("_native_candidate.png",""),at)
		var display_scale:=128.0/float(row.source_body_height)
		var old:=Sprite2D.new()
		old.texture=load(source)
		old.hframes=int(row.source_hframes)
		old.vframes=1
		old.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		old.scale=Vector2.ONE*display_scale
		old.position=at+Vector2(100,220)-(old.get_rect().position+mapping.source_anchors[0])*display_scale
		canvas.add_child(old)
		var npc:=load("res://scenes/npc_node.tscn").instantiate() as NPCNode
		npc.sprite_path=source
		npc.position=at+Vector2(335,220)
		canvas.add_child(npc)
		npc.set_process(false)
		npc.set_physics_process(false)
		if npc.prompt!=null: npc.prompt.hide()
		var body:=npc.get("_body_collider") as StaticBody2D
		var shape:=body.get_child(0) as CollisionShape2D
		var before: Array=[npc.sprite.texture,body.position,shape.position,shape.shape,shape.shape.get_rect()]
		npc.sprite.scale=Vector2.ONE*display_scale
		npc.sprite.position=-(npc.sprite.get_rect().position+mapping.source_anchors[0])*display_scale
		adapter._adopt_actor(npc)
		var entry: Dictionary=adapter._actors[npc.get_instance_id()]
		var view: Sprite2D=entry.view.get_ref()
		for frame: int in range(0 if RESIDUAL_ONLY else int(row.framecount)):
			unique_frames+=1
			for flip: bool in [false,true]:
				npc.sprite.frame=frame
				npc.sprite.flip_h=flip
				adapter._sync_entry(entry)
				var sf: Vector2=mapping.source_anchors[frame]
				var hf: Vector2=mapping.body_anchors[frame]
				if flip:
					sf.x=mapping.source_cell.x-sf.x
					hf.x=mapping.cell.x-hf.x
				var error:=npc.sprite.to_global(npc.sprite.get_rect().position+sf).distance_to(view.to_global(hf))
				check(source+" frame%d flip%s"%[frame,flip],error<0.001 and entry.reason=="AUTHORED_NATIVE_HD_VIEW" and (view.texture as AtlasTexture).atlas==texture)
				foot_cases+=1
		npc.sprite.frame=0
		npc.sprite.flip_h=false
		adapter._sync_entry(entry)
		check(source+" source/physics retained",before==[npc.sprite.texture,body.position,shape.position,shape.shape,shape.shape.get_rect()])
		check(source+" body/filter",absf(float(row.body_height)*absf(view.global_scale.y)-128.0)<0.01 and view.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS)
		actors.append(npc)
		sources.append(source)
		index+=1
	check("exact5 residual setup" if RESIDUAL_ONLY else "exact5/36/72",index==5 and (RESIDUAL_ONLY or (unique_frames==36 and foot_cases==72)))
	if actors.size()==5:
		var actor: NPCNode=actors[0]
		var entry: Dictionary=adapter._actors[actor.get_instance_id()]
		var cycle: Array[String]=sources.duplicate()
		cycle.append(sources[0])
		for source: String in cycle:
			actor.sprite.texture=load(source)
			actor.sprite.hframes=int(payload.mappings[source].source_hframes)
			actor.sprite.vframes=1
			actor.sprite.frame=0
			actor.set("_in_range",true)
			actor._set_interaction_highlight(true)
			# Capture the true owner material before the adapter leases/suppresses it.
			var original: ShaderMaterial=actor.sprite.material
			adapter._sync_entry(entry)
			var view: Sprite2D=entry.view.get_ref()
			var m: Dictionary=adapter._mappings[source]
			var material: ShaderMaterial=view.material
			check("switch/highlight "+source,entry.reason=="AUTHORED_NATIVE_HD_VIEW" and (view.texture as AtlasTexture).atlas==m.atlas and material!=null and original!=null and material!=original and is_equal_approx(float(material.get_shader_parameter("outline_width"))*float(m.ratio),float(original.get_shader_parameter("outline_width"))))
			check("switch foot "+source,actor.sprite.to_global(actor.sprite.get_rect().position+m.source_anchors[0]).distance_to(view.to_global(m.body_anchors[0]))<0.001)
			actor.set("_in_range",false)
			actor._set_interaction_highlight(false)
			adapter._sync_entry(entry)
			check("release "+source,view.material==null and actor.sprite.material==null and view.visible)
	for tick: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(OUT)
	check("normal screenshot",root.get_texture().get_image().save_png(OUT+"normal_comparison.png")==OK)
	print("NPC_B03_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"rows":index,"frames":unique_frames,"foot_cases":foot_cases,"inherited_run01_frames":36 if RESIDUAL_ONLY else 0,"inherited_run01_foot_cases":72 if RESIDUAL_ONLY else 0,"residual_only":RESIDUAL_ONLY,"candidate_injection":true,"formal_before":19,"real_field":false,"real_save_content_access":false}))
	quit(0 if failures==0 else 1)
