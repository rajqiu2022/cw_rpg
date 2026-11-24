extends SceneTree

func _initialize() -> void:
	var paths: Array[String] = []
	for file: String in DirAccess.get_files_at("res://data/scenes"):
		if not file.ends_with(".tres"):
			continue
		var scene := load("res://data/scenes/" + file) as SceneScript
		if scene == null:
			continue
		for data: Dictionary in scene.npcs:
			var path := String(data.get("sprite_path", ""))
			if path == "" or paths.has(path):
				continue
			if path.contains("guard") or path.contains("waiter") or path.contains("farmer"):
				paths.append(path)
				var image := (load(path) as Texture2D).get_image()
				var cell_width := mini(image.get_width(), image.get_height())
				var rect := image.get_region(Rect2i(0, 0, cell_width, image.get_height())).get_used_rect()
				print("[BodyProbe] %s canvas=%s alpha=%s" % [path, image.get_size(), rect])
	quit()
