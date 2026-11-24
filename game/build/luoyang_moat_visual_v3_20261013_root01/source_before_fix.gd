extends Node2D
## LOCAL VISUAL CANDIDATE ONLY. No Field, router, portal, navigation or saves.
## Existing v2 gate/wall/bridge/guards retain exact placement and source bytes.

const SIZE := Vector2(3072, 2048)
const PORTAL_FOOT := Vector2(1536, 500)
const PLACEMENTS := "assets/previews/scene_module/luoyang_city_enrichment_20261013/gate_fortification_candidate_v2/luoyang_gate_fortification_placements_v2.json"
const MATERIAL_ROOT := "game/art/modules/luoyang_moat_v1/"
const BANK_FACE := "mossy_rock_diff_1k.jpg"
const BANK_CAP := "cobblestone_floor_08_diff_1k.jpg"
const FACE_SHA := "4DBF37F1B0465C9C8914213163923BE159716F5B97FB6946437B6C5E143EF540"
const CAP_SHA := "EC131F7A99A1E7F9DF25D4725609C55A6DAD1DF487630685E9A66ECBF41EC33A"
var repository_root := ""
var _world: Node2D
var _camera: Camera2D
var _water: Polygon2D
var _water_material: ShaderMaterial
var _textures: Dictionary = {}
var _sources: Dictionary = {}
var _bank_geometry: Array[Dictionary] = []
var _error := ""

func _ready() -> void:
	if repository_root.is_empty():
		repository_root = ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir()
	if not build_preview():
		push_error("LUOYANG_MOAT_PREVIEW: " + _error)
		get_tree().quit(1)
		return
	if "--capture" in OS.get_cmdline_user_args(): _capture_run()

func _texture(relative: String, expected_sha: String) -> Texture2D:
	var absolute: String = repository_root.path_join(relative)
	if _textures.has(absolute): return _textures[absolute]
	if not FileAccess.file_exists(absolute) or FileAccess.get_sha256(absolute).to_upper() != expected_sha.to_upper():
		_error = "Source missing/changed: " + relative
		return null
	var image: Image = Image.load_from_file(absolute)
	if image == null:
		_error = "Source image cannot decode: " + relative
		return null
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	_textures[absolute] = texture
	_sources[relative] = {"sha256":expected_sha,"size":[image.get_width(),image.get_height()]}
	return texture

func _sprite(label: String, texture: Texture2D, top_left: Vector2, size_px: Vector2, layer: int) -> void:
	var sprite := Sprite2D.new()
	sprite.name = label; sprite.centered = false; sprite.texture = texture
	sprite.position = top_left; sprite.scale = size_px / Vector2(texture.get_size())
	sprite.z_index = layer; _world.add_child(sprite)

func build_preview() -> bool:
	if _world != null: return false
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(repository_root.path_join(PLACEMENTS)))
	if not value is Dictionary or value.get("candidate_id") != "luoyang_gate_fortification_candidate_v2":
		_error = "Exact v2 placement source required"; return false
	var pins: Dictionary = value.source_pins
	var source: Dictionary = {}
	for key: String in ["base_floor","gate","wall","west_front","east_front","bridge","guard"]:
		var entry: Dictionary = pins[key]
		var texture: Texture2D = _texture(entry.path, entry.sha256)
		if texture == null: return false
		source[key] = texture
	var face: Texture2D = _texture(MATERIAL_ROOT+BANK_FACE, FACE_SHA)
	var cap: Texture2D = _texture(MATERIAL_ROOT+BANK_CAP, CAP_SHA)
	if face == null or cap == null: return false
	if source.base_floor.get_size() != Vector2i(3072,2048):
		_error = "V2 floor size changed"; return false
	_world = Node2D.new(); _world.name = "MoatVisualWorld"; add_child(_world)
	_sprite("OriginalFloor",source.base_floor,Vector2.ZERO,SIZE,-20)
	_sprite("InsideWestFront",source.west_front,Vector2(300,5),Vector2(700,467),-18)
	_sprite("InsideEastFront",source.east_front,Vector2(2072,5),Vector2(700,467),-18)
	var shader := Shader.new()
	shader.code = FileAccess.get_file_as_string(repository_root.path_join("game/shaders/luoyang_moat_water_v1.gdshader"))
	if shader.code.is_empty(): _error = "Water shader missing"; release_preview(); return false
	_water_material = ShaderMaterial.new(); _water_material.shader = shader
	_water = Polygon2D.new(); _water.name = "WorldAnchoredMoatWater"
	_water.polygon = _quad(Rect2(0,620,3072,320)); _water.material = _water_material
	_water.z_index = -10; _world.add_child(_water)
	# Independent coping and visible wet faces. Bridge openings touch both abutments.
	for bounds: Vector2 in [Vector2(0,1436),Vector2(1636,3072)]:
		_bank_strip("North",bounds,Rect2(bounds.x,620,bounds.y-bounds.x,24),Rect2(bounds.x,602,bounds.y-bounds.x,20),face,cap,false)
		_bank_strip("South",bounds,Rect2(bounds.x,916,bounds.y-bounds.x,22),Rect2(bounds.x,936,bounds.y-bounds.x,22),face,cap,true)
	_sprite("OriginalStoneBridge",source.bridge,Vector2(1376,480),Vector2(320,480),0)
	for center: float in [333.0,950.0,2122.0,2739.0]:
		_sprite("OriginalWall"+str(int(center)),source.wall,Vector2(roundf(center-333),247),Vector2(666,266),5)
	_sprite("OriginalCityGate",source.gate,Vector2(1136,8),Vector2(800,533),6)
	if source.guard.get_size() != Vector2i(640,160):
		_error = "Original scale witness sheet changed"; release_preview(); return false
	var atlas := AtlasTexture.new(); atlas.atlas = source.guard; atlas.region = Rect2(0,0,160,160)
	_sprite("OriginalGuardLeft",atlas,Vector2(1288,448),Vector2(160,160),10)
	_sprite("OriginalGuardRight",atlas,Vector2(1624,448),Vector2(160,160),10)
	_camera = Camera2D.new(); _camera.name = "NormalV2CropCamera"
	_camera.position = Vector2(1536,540); _camera.position_smoothing_enabled = false
	add_child(_camera); _camera.make_current()
	return true

func _quad(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])

func _stone_polygon(label: String, rect: Rect2, texture: Texture2D, tint: Color, layer: int) -> void:
	var stone := Polygon2D.new(); stone.name = label; stone.polygon = _quad(rect)
	var uv := PackedVector2Array()
	# World-space 192 px repeats: NEVER stretch one 1k texture along the whole bank.
	for point: Vector2 in stone.polygon: uv.append(point / 192.0 * Vector2(texture.get_size()))
	stone.uv = uv; stone.texture = texture; stone.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	stone.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR; stone.color = tint
	stone.z_index = layer; _world.add_child(stone)
	_bank_geometry.append({"id":label,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"uv_repeat_world_px":192})

func _bank_strip(label: String, bounds: Vector2, face_rect: Rect2, cap_rect: Rect2, face: Texture2D, cap: Texture2D, south: bool) -> void:
	var suffix := str(int(bounds.x))
	_stone_polygon(label+"WetFace"+suffix,face_rect,face,Color(0.56,0.60,0.53,1),-8)
	_stone_polygon(label+"Coping"+suffix,cap_rect,cap,Color(0.81,0.81,0.77,1),-7)
	# A narrow independently textured wet ledge adds volume at the water contact.
	var y: float = face_rect.position.y if south else face_rect.end.y-4
	_stone_polygon(label+"WetLedge"+suffix,Rect2(bounds.x,y,bounds.y-bounds.x,4),face,Color(0.37,0.43,0.36,1),-6)
	var join_x: float = bounds.y-18 if bounds.x==0 else bounds.x
	_stone_polygon(label+"BridgeAbutment"+suffix,Rect2(join_x,cap_rect.position.y-4,18,cap_rect.size.y+8),cap,Color(0.86,0.85,0.79,1),-5)

func set_preview_time(seconds: float) -> void:
	if _water_material == null: return
	_water_material.set_shader_parameter("use_preview_time",seconds>=0)
	_water_material.set_shader_parameter("preview_time",maxf(0,seconds))

func set_camera_pose(center: Vector2, zoom_factor: float = 1.0) -> void:
	if _camera != null and center.is_finite() and is_finite(zoom_factor) and zoom_factor>0:
		_camera.position=center; _camera.zoom=Vector2.ONE*zoom_factor

func get_debug_state() -> Dictionary:
	return {"scope":"LOCAL_MOAT_VISUAL_CANDIDATE_NOT_FIELD_OR_FORMAL","error":_error,"portal_foot":[1536,500],"design_size":[3072,2048],"normal_crop":[576,0,1920,1080],"water_rect":[0,620,3072,320],"water_uv":"MODEL_MATRIX_WORLD_PIXEL_NO_SCREEN_TEXTURE","bank_geometry":_bank_geometry.duplicate(true),"sources":_sources.duplicate(true),"formal_or_physics_changed":false,"audio_or_save_claim":false}

func _capture_png(path: String) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	return image != null and image.get_size() == Vector2i(1920,1080) and image.save_png(path) == OK

func _capture_run() -> void:
	var output := ""
	var seconds := 2.5
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
		if argument.begins_with("--seconds="): seconds=clampf(argument.trim_prefix("--seconds=").to_float(),0.25,10.0)
	if output.is_empty() or not output.is_absolute_path():
		push_error("Preview capture requires --output=<absolute path>"); release_preview(); get_tree().quit(1); return
	for existing: String in ["moat_t0.png","moat_t2.png","moat_natural.png","preview_result.json"]:
		if FileAccess.file_exists(output.path_join(existing)):
			push_error("Preview refuses to overwrite existing evidence: "+existing); release_preview(); get_tree().quit(1); return
	if DirAccess.make_dir_recursive_absolute(output) != OK:
		push_error("Preview output cannot be created"); release_preview(); get_tree().quit(1); return
	set_preview_time(0)
	if not await _capture_png(output.path_join("moat_t0.png")): _error="t0 GPU capture failed"
	set_preview_time(2)
	if not await _capture_png(output.path_join("moat_t2.png")): _error="t2 GPU capture failed"
	# Natural shader TIME runs only this bounded local preview, no animation timers.
	set_preview_time(-1)
	var start: int=Time.get_ticks_msec()
	var frames:=0
	while Time.get_ticks_msec()-start < seconds*1000:
		await get_tree().process_frame
		frames+=1
	if not await _capture_png(output.path_join("moat_natural.png")): _error="Natural GPU capture failed"
	var report: Dictionary=get_debug_state()
	report["natural_frames"]=frames; report["natural_elapsed_ms"]=Time.get_ticks_msec()-start
	report["fixed_time_seconds"]=[0,2]; report["output_png_sha256"]={}
	for filename: String in ["moat_t0.png","moat_t2.png","moat_natural.png"]:
		report.output_png_sha256[filename]=FileAccess.get_sha256(output.path_join(filename))
	var file: FileAccess=FileAccess.open(output.path_join("preview_result.json"),FileAccess.WRITE)
	if file==null: _error="Preview report write failed"
	else: file.store_string(JSON.stringify(report,"\t")); file.close()
	print("LUOYANG_MOAT_LOCAL_PREVIEW "+JSON.stringify(report))
	release_preview()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if _error.is_empty() else 1)

func release_preview() -> void:
	_water=null; _water_material=null
	if is_instance_valid(_camera): _camera.free()
	_camera=null
	if is_instance_valid(_world): _world.free()
	_world=null; _textures.clear()

func _exit_tree() -> void:
	_water_material=null; _textures.clear()
