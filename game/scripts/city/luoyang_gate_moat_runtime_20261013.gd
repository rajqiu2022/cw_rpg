extends RefCounted
## Real Field-owned visual module. No Player, portal, physics, save or autoload.
## Isolated water canvas keeps approved MODEL_MATRIX water UV world-fixed even
## when Field scrolls its world_container instead of a Camera2D.
const CONTRACT = preload("res://scripts/city/luoyang_gate_fortification_contract_20261013.gd")
const FACE := "res://art/modules/luoyang_moat_v1/mossy_rock_diff_1k.jpg"
const CAP := "res://art/modules/luoyang_moat_v1/cobblestone_floor_08_diff_1k.jpg"
var _config: Dictionary = {}
var _manifest: Dictionary = {}
var _textures: Dictionary = {}
var _water_viewport: SubViewport
var _reflection_viewport: SubViewport
var _output: Sprite2D
var _material: ShaderMaterial
var _water_world: Node2D
var _bank_shader: Shader
var _reflection_ids: Array[String] = []
var _error := ""

func prepare(scene: SceneScript) -> bool:
	release()
	_error = ""
	if not CONTRACT.bound(scene): _error = "Unbound Gate module"; return false
	_config = CONTRACT.author(); _manifest = CONTRACT.runtime_manifest()
	if _config.is_empty() or not _manifest.get("asset_sha256") is Dictionary: _error = "Gate source package missing"; return false
	return true

func texture_for(entry: Dictionary) -> Texture2D:
	var path: String = entry.get("texture", "")
	var texture := _texture(path)
	if texture == null: return null
	if not entry.has("gate_atlas_region"): return texture
	var region: Variant = entry.gate_atlas_region
	if not region is Rect2i or region.position.x < 0 or region.position.y < 0 or region.size.x <= 0 or region.size.y <= 0 or region.end.x > texture.get_width() or region.end.y > texture.get_height(): _error = "Gate atlas outside exact source"; return null
	var atlas := AtlasTexture.new(); atlas.atlas = texture; atlas.region = Rect2(region)
	return atlas

func _texture(path: String) -> Texture2D:
	if _textures.has(path): return _textures[path]
	var sha: Variant = _manifest.get("asset_sha256", {}).get(path)
	if not CONTRACT.BASE._hash(sha) or FileAccess.get_sha256(path) != sha: _error = "Gate runtime source changed: "+path; return null
	var image: Image = Image.load_from_file(path)
	if image == null: _error = "Gate runtime image undecodable"; return null
	var result := ImageTexture.create_from_image(image)
	_textures[path] = result
	return result

func configure(visual_layer: Node2D, objects: Array) -> bool:
	if not is_instance_valid(visual_layer) or _manifest.is_empty() or _water_viewport != null or not _error.is_empty(): return false
	for path: String in ["res://shaders/luoyang_moat_water_v2.gdshader","res://shaders/luoyang_moat_bank_contact_v1.gdshader"]:
		if not CONTRACT.BASE._hash(_manifest.asset_sha256.get(path)) or FileAccess.get_sha256(path) != _manifest.asset_sha256[path]: _error = "Approved shader bytes changed"; return false
	var water_shader := Shader.new()
	water_shader.code = FileAccess.get_file_as_string("res://shaders/luoyang_moat_water_v2.gdshader")
	_bank_shader = Shader.new()
	_bank_shader.code = FileAccess.get_file_as_string("res://shaders/luoyang_moat_bank_contact_v1.gdshader")
	if water_shader.code.is_empty() or _bank_shader.code.is_empty(): _error = "Approved shader unavailable"; return false
	_reflection_viewport = SubViewport.new(); _reflection_viewport.name = "GateArchitectureReflection"
	_reflection_viewport.size = Vector2i(3072,560); _reflection_viewport.transparent_bg = true
	_reflection_viewport.disable_3d = true; _reflection_viewport.world_2d = World2D.new()
	_reflection_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	visual_layer.add_child(_reflection_viewport)
	var architecture := Node2D.new(); _reflection_viewport.add_child(architecture)
	for entry: Dictionary in objects:
		var oid: String = entry.get("id", "")
		if oid not in ["north_court_boundary","gate_wall_333","gate_wall_950","gate_wall_2122","gate_wall_2739"]: continue
		var texture := texture_for(entry)
		if texture == null: release(); return false
		var sprite := Sprite2D.new(); sprite.name = oid; sprite.texture = texture; sprite.centered = true
		sprite.position = entry.pos * Vector2(3072,2048); sprite.scale = entry.render_size_px / Vector2(texture.get_size())
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR; architecture.add_child(sprite)
		_reflection_ids.append(oid)
	if _reflection_ids.size() != 5: _error = "Five actual gate/wall reflection sources required"; release(); return false
	_water_viewport = SubViewport.new(); _water_viewport.name = "GateMoatWorldCanvas"
	_water_viewport.size = Vector2i(3072,380); _water_viewport.transparent_bg = true
	_water_viewport.disable_3d = true; _water_viewport.world_2d = World2D.new()
	_water_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	visual_layer.add_child(_water_viewport)
	_water_world = Node2D.new(); _water_viewport.add_child(_water_world)
	var camera := Camera2D.new(); camera.position = Vector2(1536,780)
	_water_world.add_child(camera); camera.make_current()
	_material = ShaderMaterial.new(); _material.shader = water_shader
	_material.set_shader_parameter("building_reflection", _reflection_viewport.get_texture())
	var water := Polygon2D.new(); water.name = "GateMoatWater"; water.polygon = _quad(Rect2(0,620,3072,320))
	water.material = _material; water.z_index = -10; _water_world.add_child(water)
	var face := _texture(FACE); var cap := _texture(CAP)
	if face == null or cap == null: release(); return false
	for bounds: Vector2 in [Vector2(0,1436),Vector2(1636,3072)]:
		_bank_strip("North",bounds,Rect2(bounds.x,620,bounds.y-bounds.x,24),Rect2(bounds.x,602,bounds.y-bounds.x,20),face,cap,false)
		_bank_strip("South",bounds,Rect2(bounds.x,916,bounds.y-bounds.x,22),Rect2(bounds.x,936,bounds.y-bounds.x,22),face,cap,true)
	_output = Sprite2D.new(); _output.name = "GateMoatWorldWater"; _output.centered = false
	_output.texture = _water_viewport.get_texture(); _output.position = Vector2(0,590)
	_output.z_index = -1; _output.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Added after original travel lines, same layer -1; deck is layer 0.
	visual_layer.add_child(_output)
	return true

static func _quad(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])

func _stone(label: String, rect: Rect2, texture: Texture2D, tint: Color, layer: int) -> Polygon2D:
	var node := Polygon2D.new(); node.name = label; node.polygon = _quad(rect)
	var uv := PackedVector2Array()
	for point: Vector2 in node.polygon: uv.append(point / 192.0 * Vector2(texture.get_size()))
	node.uv = uv; node.texture = texture; node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR; node.color = tint; node.z_index = layer
	_water_world.add_child(node)
	return node

func _bank_strip(label: String, bounds: Vector2, face_rect: Rect2, cap_rect: Rect2, face: Texture2D, cap: Texture2D, south: bool) -> void:
	var suffix := str(int(bounds.x))
	var wall := _stone(label+"WetFace"+suffix,face_rect,face,Color(.56,.60,.53,1),-8)
	var material := ShaderMaterial.new(); material.shader = _bank_shader
	material.set_shader_parameter("south_bank",south)
	material.set_shader_parameter("contact_y",face_rect.position.y if south else face_rect.end.y)
	wall.material = material
	_stone(label+"Coping"+suffix,cap_rect,cap,Color(.81,.81,.77,1),-7)
	var y: float = face_rect.position.y if south else face_rect.end.y-4
	_stone(label+"WetLedge"+suffix,Rect2(bounds.x,y,bounds.y-bounds.x,4),face,Color(.37,.43,.36,1),-6)
	var join_x: float = bounds.y-18 if bounds.x == 0 else bounds.x
	_stone(label+"BridgeAbutment"+suffix,Rect2(join_x,cap_rect.position.y-4,18,cap_rect.size.y+8),cap,Color(.86,.85,.79,1),-5)

func get_debug_state() -> Dictionary:
	return {"scope":"REAL_FIELD_GATE_ONLY_CANDIDATE","error":_error,"configured":is_instance_valid(_output),"manifest_sha":CONTRACT.MANIFEST_SHA,"reflection_ids":_reflection_ids.duplicate(),"world_water_rect":Rect2(0,620,3072,320),"viewport_world_origin":Vector2(0,590),"water_uv":"ISOLATED_MODEL_MATRIX_WORLD_PIXELS","reflection_viewport_id":_reflection_viewport.get_instance_id() if is_instance_valid(_reflection_viewport) else 0,"water_viewport_id":_water_viewport.get_instance_id() if is_instance_valid(_water_viewport) else 0,"texture_count":_textures.size()}

func release() -> void:
	if _material != null: _material.set_shader_parameter("building_reflection",null)
	if is_instance_valid(_output): _output.texture = null; _output.free()
	_output = null; _material = null; _bank_shader = null; _water_world = null
	if is_instance_valid(_water_viewport): _water_viewport.free()
	if is_instance_valid(_reflection_viewport): _reflection_viewport.free()
	_water_viewport = null; _reflection_viewport = null
	_textures.clear(); _reflection_ids.clear(); _config.clear(); _manifest.clear()
