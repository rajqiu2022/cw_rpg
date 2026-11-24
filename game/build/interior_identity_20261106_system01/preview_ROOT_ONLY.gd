extends SceneTree
## Source-native layout/visual fixture; not a production Field or travel test.
## Writes screenshots and bounded geometry receipts only in this task directory.
const HOME := "res://build/interior_identity_20261106_system01/"
const Layout = preload(HOME + "room_layout_candidate.gd")
var _checks: int = 0
var _errors: Array[String] = []
var _cache: Dictionary = {}
var _world: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> bool:
	_checks += 1
	if not value:
		_errors.append(label)
		push_error(label)
	return value

func _load_native(path: String) -> Image:
	if not _cache.has(path):
		# The fixture audits source PNG bytes directly; formal paths must import.
		var src := Image.new()
		_cache[path] = src if src.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK else null
	return _cache[path] as Image

func _sprite(texture: Texture2D, origin: Vector2, ratio: float, depth: int, id: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = id
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.texture = texture
	s.centered = false
	s.position = origin
	s.scale = Vector2.ONE * ratio
	s.z_index = depth
	_world.add_child(s)
	return s

func _texture(img: Image) -> Texture2D:
	# Native samples are not resized or reauthored; only GPU mip levels are built.
	var copy := img.duplicate() as Image
	copy.generate_mipmaps()
	return ImageTexture.create_from_image(copy)

func _draw_actor(row: Dictionary) -> bool:
	var path: String = row.texture
	var source := _load_native(path)
	if not _check(source != null and not source.is_empty(),"ACTOR_TEXTURE:" + row.id): return false
	var frames: int = row.frames
	var cell: Vector2 = row.get("cell", Vector2(float(source.get_width())/float(frames),source.get_height()))
	if not _check(cell.x * frames == source.get_width() and cell.y == source.get_height(),"ACTOR_CELL:" + row.id): return false
	var first := source.get_region(Rect2i(Vector2i.ZERO, Vector2i(cell)))
	var bounds := first.get_used_rect()
	if not _check(bounds.size.y > 0,"ACTOR_ALPHA:" + row.id): return false
	var atlas := AtlasTexture.new()
	atlas.atlas = _texture(source)
	atlas.region = Rect2(Vector2.ZERO, cell)
	atlas.filter_clip = true
	var ratio := float(row.height)/float(row.get("native_height",bounds.size.y))
	var foot: Vector2 = row.foot
	var offset: Vector2 = row.get("cell_foot", Vector2(bounds.get_center().x,bounds.end.y))
	_sprite(atlas, foot-offset*ratio, ratio, 100+floori(foot.y/8.0),row.id)
	if not String(row.get("name","")).is_empty():
		var label := Label.new()
		label.text = row.name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = foot - Vector2(90,float(row.height)+23.0)
		label.size = Vector2(180,20)
		label.z_index = 370
		var font := load(Layout.FONT) as Font
		if font != null: label.add_theme_font_override("font",font)
		label.add_theme_font_size_override("font_size",15)
		label.add_theme_color_override("font_color",Color("f4e5ca"))
		label.add_theme_color_override("font_outline_color",Color("241411"))
		label.add_theme_constant_override("outline_size",4)
		_world.add_child(label)
	return true

func _draw_shell(room: Dictionary) -> bool:
	var source := _load_native(room.shell)
	if not _check(source != null and source.get_size() == Vector2i(1664,1152),"EXACT_NATIVE_PADDED_SHELL:" + room.id): return false
	var shell_texture := _texture(source)
	_sprite(shell_texture,room.shell_origin,room.shell_ratio,-1000,"NativeShell")
	# Front rails occlude bodies only where the rails are painted. Same intact
	# source and UV, no reshaping the room and no blind portal-wide foreground.
	var lip_y := 887 if room.id == Layout.YIHONG else 890
	for rect: Rect2 in [Rect2(80,lip_y,634,195),Rect2(949,lip_y,635,195)]:
		var part := AtlasTexture.new()
		part.atlas = shell_texture
		part.region = rect
		part.filter_clip = true
		_sprite(part,room.shell_origin+rect.position*float(room.shell_ratio),room.shell_ratio,300,"FrontRail")
	return true

func _draw_room(room: Dictionary) -> bool:
	_world = Node2D.new()
	_world.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_world.position = (Vector2(root.size)-room.size)*0.5
	if room.id == Layout.COMMON:
		_world.position.y += 36.0
	root.add_child(_world)
	if not _draw_shell(room): return false
	if room.has("flat_rug"):
		var rug := _load_native(Layout.RUG)
		if not _check(rug != null and not rug.is_empty(),"RUG_NATIVE"): return false
		var rect: Rect2 = room.flat_rug
		var content := Rect2(108,190,1687,646)
		var ratio := minf(rect.size.x/content.size.x,rect.size.y/content.size.y)
		var top := rect.get_center()-content.size*ratio*0.5-content.position*ratio
		_sprite(_texture(rug),top,ratio,-985,"SaloonPerformanceRug")
	for item: Dictionary in room.furniture:
		if not _check(not item.is_empty(),"FURNITURE_AUTHORED_SOURCE"): return false
		var image := _load_native(item.texture)
		if not _check(image != null and image.get_size()==Vector2i(1536,1024),"FURNITURE_NATIVE:" + item.donor_id): return false
		_sprite(_texture(image),item.origin,item.scale,100+floori(item.foot.y/8.0),item.donor_id)
	for actor: Dictionary in room.actors:
		if not _check(not actor.is_empty(),"ACTOR_EXPLICIT_IDENTITY"): return false
		if not _draw_actor(actor): return false
	return _draw_actor({"id":"hero_scale_reference","name":"","texture":Layout.HERO,"foot":room.entry,"frames":4,"height":128.52})

func _geometry(room: Dictionary) -> void:
	var approach: Vector2 = room.counter_approach
	var turn := Vector2(room.entry.x,approach.y)
	_check(Layout.safe_segment(room,room.entry,room.exit),"ENTRY_AND_EXIT_BODY_CORRIDOR:" + room.id)
	_check(Layout.safe_segment(room,room.entry,turn),"CENTER_TO_COUNTER_TURN:" + room.id)
	_check(Layout.safe_segment(room,turn,approach),"TURN_TO_COUNTER_BODY_CORRIDOR:" + room.id)
	_check(not Layout.safe(room,Vector2(room.exit.x-220,room.exit.y)),"NO_SIDE_WALL_EXIT:" + room.id)
	var ids: Dictionary = {}
	for actor: Dictionary in room.actors:
		if actor.is_empty(): continue
		var id: String = actor.id
		_check(not ids.has(id),"UNIQUE_ACTOR_ID:" + id)
		ids[id] = true
		_check(Layout.safe(room,actor.foot,Vector2(10,8)),"ACTOR_BODY_CLEAR:" + id)
		# Do not put an actor's solid onto the protected center route.
		_check(absf(actor.foot.x-room.entry.x) > 35.0,"ACTOR_OUTSIDE_CENTER_AISLE:" + id)
	if room.id == Layout.YIHONG:
		_check(ids.size()==10,"ORIGINAL_SIX_PLUS_FOUR_EXPLICIT_ACTORS")
		_check(room.return_foot==Vector2(5206.18,4280),"UNCHANGED_CIVIC_RETURN_FOOT")
	if room.id == Layout.PREMIUM:
		_check(room.service_contract.rest_gold==20 and room.service_contract.rest_recovery==1.0,"EXISTING_REST_CONTRACT_RECORDED_NOT_EXECUTED")

func _run() -> void:
	var output := HOME + "preview_actual/" + str(OS.get_process_id()) + "/"
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1600,1050)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("1d1613"))
	var selected: Array[String] = [Layout.YIHONG]
	if "--all-rooms" in OS.get_cmdline_user_args():
		selected = [Layout.YIHONG,Layout.PREMIUM,Layout.COMMON]
	var images: Array[String] = []
	for id: String in selected:
		var room: Dictionary = Layout.compose_room(id)
		if not _check(not room.is_empty(),"COMPOSE:" + id): continue
		_geometry(room)
		if _draw_room(room) and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var screenshot := root.get_texture().get_image()
			var image_path := output+id+".png"
			if _check(screenshot != null and screenshot.save_png(image_path)==OK,"CANDIDATE_SCREENSHOT:" + id):
				images.append(image_path)
		if is_instance_valid(_world): _world.free()
	var report := {"checks":_checks,"failures":_errors,"images":images,"rooms":selected,"real_field":false,"formal_writes":false,"real_save_content_access":false}
	var result := FileAccess.open(output+"result.json",FileAccess.WRITE)
	if result != null:
		result.store_string(JSON.stringify(report,"  ")+"\n")
		result.close()
	print(JSON.stringify(report))
	quit(0 if _errors.is_empty() else 1)
