extends Node2D
const ACTOR = preload("res://layered_actor.gd")

func _ready() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
	var base := ProjectSettings.globalize_path("res://").path_join(data.source_root).simplify_path()
	var textures: Dictionary = {}
	for key in data.textures:
		var img := Image.load_from_file(base.path_join(key+".png"))
		img.generate_mipmaps()
		textures[key]=ImageTexture.create_from_image(img)
	var font := FontFile.new()
	font.load_dynamic_font(ProjectSettings.globalize_path("res://../../art/fonts/LXGWWenKaiLite-Regular.ttf").simplify_path())
	var states := ["idle_down","idle_up","walk_down","walk_up","attack_down","attack_up","hit","defeat"]
	for col in range(8):
		var title := Label.new()
		title.text = ["正面待机","背面待机","正面行走","背面行走","正面挥击","背面挥击","侧向受击","侧向倒地"][col]
		title.add_theme_font_override("font",font)
		title.add_theme_font_size_override("font_size",22)
		title.position=Vector2(col*200+20,10)
		add_child(title)
		for frame in range(4):
			var container := SubViewportContainer.new()
			container.position=Vector2(col*200,50+frame*220)
			add_child(container)
			var viewport := SubViewport.new()
			viewport.size=Vector2i(198,218)
			viewport.world_2d=World2D.new()
			viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
			viewport.transparent_bg=true
			container.add_child(viewport)
			var actor := ACTOR.new()
			viewport.add_child(actor)
			actor.configure(data,textures)
			actor.play(states[col])
			actor.equip("jinhe_duanyue_blade" if "--blade" in OS.get_cmdline_user_args() else "seven_star_sword")
			actor.frame_index=frame
			actor.paused=true
			actor.fx_enabled=false
			actor.scale=Vector2.ONE*2.0
			var pose: Dictionary=data.clips[states[col]].frames[frame]
			actor.position=Vector2(99,110)-Vector2(pose.grip[0]-pose.foot[0],pose.grip[1]-pose.foot[1])*2.0*float(data.clips[states[col]].get("body_scale",1.0))
			actor.apply_pose()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var suffix := "blade" if "--blade" in OS.get_cmdline_user_args() else "sword"
	get_viewport().get_texture().get_image().save_png("res://evidence/directions_grips_"+suffix+".png")
	get_tree().quit()

func _draw() -> void:
	draw_rect(Rect2(0,0,1600,960),Color("253742"))
