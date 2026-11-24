extends RefCounted
const ROOT := "res://build/sect_repair_20261031c_system01/"
const PROFILES := ROOT+"visual_profiles.json"
static var _textures: Dictionary={}

static func vec(pair: Array) -> Vector2:return Vector2(float(pair[0]),float(pair[1]))
static func points(pairs: Array) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for pair: Array in pairs:result.append(vec(pair))
	return result

static func setup(town: Node2D,key: String) -> bool:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(PROFILES))
	if not parsed is Dictionary or not parsed.get("towns",{}).has(key):return false
	var binding: Dictionary=parsed
	for path: String in binding.textures:
		var expected: Dictionary=binding.textures[path]
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path)!=String(expected.sha256):return false
		if _textures.has(path):continue
		var im:=Image.new()
		if im.load(path)!=OK or im.get_width()!=int(expected.size[0]) or im.get_height()!=int(expected.size[1]):return false
		_textures[path]=ImageTexture.create_from_image(im)
	var source: String=ROOT+"cliff_stair_slots.gdshader"
	if FileAccess.get_sha256(source)!=String(binding.slot_shader_sha256):return false
	var shader:=Shader.new();shader.code=FileAccess.get_file_as_string(source)
	var material:=ShaderMaterial.new();material.shader=shader
	var data: Dictionary=binding.towns[key];var slots: Array=data.slots
	material.set_shader_parameter("slot_count",slots.size())
	for i: int in range(slots.size()):
		var r: Array=slots[i];material.set_shader_parameter("slot"+str(i),Vector4(float(r[0]),float(r[1]),float(r[2]),float(r[3])))
	var parent:=Node2D.new();parent.name="NativeSectRepair31c";town.get_node("Terrain").add_child(parent)
	for row: Dictionary in data.cliffs:
		var art:=Sprite2D.new();art.name=String(row.id);art.centered=false;art.texture=_textures[row.texture]
		art.position=vec(row.position);art.scale=Vector2.ONE*float(row.scale);art.z_as_relative=false;art.z_index=int(row.z);art.material=material;art.set_meta("repair_static_stair_slots",slots);parent.add_child(art)
	for row: Dictionary in data.stairs:
		var anchor:=Node2D.new();anchor.name=String(row.id);anchor.position=vec(row.projected_bottom);parent.add_child(anchor)
		var foot:=vec(row.source_foot);var scale: float=float(row.scale)
		var art:=Sprite2D.new();art.name="WholeNativeStair";art.centered=false;art.texture=_textures[row.texture]
		art.position=-foot*scale;art.scale=Vector2.ONE*scale;art.z_as_relative=false;art.z_index=-4;anchor.add_child(art)
		for side: String in ["left","right"]:
			var rail:=Polygon2D.new();rail.name=side.capitalize()+"RailForeground";rail.texture=art.texture;rail.uv=points(binding.stair_rails[side])
			var local:=PackedVector2Array()
			for point: Vector2 in rail.uv:local.append((point-foot)*scale)
			rail.polygon=local;rail.z_as_relative=false;rail.z_index=int(row.rail_z);anchor.add_child(rail)
	town.set_meta("sect_native_visual31c",{"key":key,"cliff_count":data.cliffs.size(),"stair_count":data.stairs.size(),"texture_count":_textures.size(),"uniform_only":true,"PNG_import_required":false,"physical_nodes_created":0})
	return true
