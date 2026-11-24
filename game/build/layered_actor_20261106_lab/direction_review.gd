extends Node2D
const ACTOR = preload("res://layered_actor.gd")

func _ready() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
	var base := ProjectSettings.globalize_path("res://").path_join(data.source_root).simplify_path()
	var textures: Dictionary = {}
	for key in data.textures:
		var img := Image.load_from_file(base.path_join(key+".png"))
		img.generate_mipmaps()
		textures[key] = ImageTexture.create_from_image(img)
	var font := FontFile.new()
	font.load_dynamic_font(ProjectSettings.globalize_path("res://../../art/fonts/LXGWWenKaiLite-Regular.ttf").simplify_path())
	var title := Label.new()
	title.add_theme_font_override("font",font)
	title.add_theme_font_size_override("font_size",28)
	title.text = "分层2D · 四向动作样板    同一人物换剑／换刀，虎口挂点逐帧标定"
	title.position = Vector2(35,14)
	add_child(title)
	for row in range(3):
		for col in range(4):
			var direction: String = ["down","up","right","left"][col]
			var action: String = ["idle","walk","attack"][row]
			var actor := ACTOR.new()
			add_child(actor)
			actor.configure(data,textures)
			actor.set_direction(direction)
			actor.play_action(action)
			actor.equip("jinhe_duanyue_blade" if row==1 else "seven_star_sword")
			actor.frame_index = 2
			actor.paused = true
			actor.fx_enabled = false
			actor.position = Vector2(195+400*col,310+300*row)
			actor.scale = Vector2.ONE*.32
			actor.apply_pose()
			var label := Label.new()
			label.add_theme_font_override("font",font)
			label.add_theme_font_size_override("font_size",22)
			label.text = ["正面","背面","右向","左镜像"][col]+" · "+["待机／七星剑","行走／断岳刀","挥击／七星剑"][row]
			label.position = Vector2(75+400*col,45+300*row)
			add_child(label)
	var note := Label.new()
	note.add_theme_font_override("font",font)
	note.text = "原生新图，原RGBA保留。每动作4关键帧；侧向受击／倒地另页。未替换正式主角，非最终动作验收。"
	note.position = Vector2(35,932)
	add_child(note)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://evidence/directions_overview.png")
	get_tree().quit()

func _draw() -> void:
	draw_rect(Rect2(0,0,1600,960),Color("17242d"))
