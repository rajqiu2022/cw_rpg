extends Node2D

const ACTOR = preload("res://layered_actor.gd")

func _ready() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
	var old_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://evidence/grip_v1_rejected/manifest.json"))
	var textures: Dictionary = {}
	var base := ProjectSettings.globalize_path("res://").path_join(data.source_root).simplify_path()
	for key in data.textures:
		var img := Image.load_from_file(base.path_join(key+".png"))
		img.generate_mipmaps()
		textures[key] = ImageTexture.create_from_image(img)
	var font := FontFile.new()
	font.load_dynamic_font(ProjectSettings.globalize_path("res://../../art/fonts/LXGWWenKaiLite-Regular.ttf").simplify_path())
	for i in range(3):
		var label := Label.new()
		label.text = ["原版 · 中指附近接柄", "调整 · 七星龙泉剑", "调整 · 烬河断岳刀"][i]
		label.add_theme_font_override("font",font)
		label.add_theme_font_size_override("font_size",27)
		label.position = Vector2(30+i*530,35)
		add_child(label)
		var container := SubViewportContainer.new()
		container.position = Vector2(16+i*530,95)
		add_child(container)
		var view := SubViewport.new()
		view.size = Vector2i(510,750)
		view.world_2d = World2D.new()
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		container.add_child(view)
		var actor := ACTOR.new()
		view.add_child(actor)
		actor.configure(old_data if i==0 else data,textures)
		actor.equip("jinhe_duanyue_blade" if i==2 else "seven_star_sword")
		actor.play("attack")
		actor.paused = true
		actor.fx_enabled = false
		actor.frame_index = 2
		actor.scale = Vector2.ONE*5.0
		actor.position = Vector2(240,370)-Vector2(471-256,338-726)*5.0
		actor.apply_pose()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://evidence/grip_closeup.png")
	get_tree().quit()
