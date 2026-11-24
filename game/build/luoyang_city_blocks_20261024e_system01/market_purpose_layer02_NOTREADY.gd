extends RefCounted
## Fixed five visual-use unions only; native/storage/NAV stay under Source authority.
const SPEC="res://build/luoyang_city_blocks_20261024e_system01/market_five_use_spec02_NOTREADY.json"
const SPEC_SHA="43dac773ce3521f78325663cda83f7e3fb435f00c1df892bd60488828b8883a8"
const SHADER="res://build/luoyang_city_blocks_20261024e_system01/market_use_union01_NOTREADY.gdshader"
const SHADER_SHA="18c45381f30776af9c1255e3c3c72ff8403b09f54fbc15c1899061125fda7166"
const AUTHOR="res://build/luoyang_city_blocks_20261024e_system01/author_market_block07_paper_foot_NOTREADY.json"
const AUTHOR_SHA="de1911cceb5fb10e6b3b1aba1fa6d9d34057358841febdd285d25a1a1eb65e95"
const GROUPS=["main_public_route","shop_front_public_stone","side_service_alley","working_stall_court","rear_court_and_tree_soil"]
static func pins() -> Dictionary:
 return {SPEC:SPEC_SHA,SHADER:SHADER_SHA,AUTHOR:AUTHOR_SHA}
static func _rect(a: Array) -> Rect2:
 return Rect2(float(a[0]),float(a[1]),float(a[2]),float(a[3]))
static func _vec4(a: Array) -> Vector4:
 return Vector4(float(a[0]),float(a[1]),float(a[2]),float(a[3]))
static func _padded(rows: Array,count: int) -> PackedVector4Array:
 var result:=PackedVector4Array()
 for row: Array in rows: result.append(_vec4(row))
 while result.size()<count: result.append(Vector4.ZERO)
 return result
static func append_to(layer: Node2D,scene: SceneScript,textures: Dictionary,binding: Dictionary,owner: Callable) -> Dictionary:
 if scene==null or scene.scene_id!=&"ch4_s3_luoyang_market" or not is_instance_valid(layer) or not owner.is_valid() or not owner.call(): return {"ok":false,"error":"MARKET_USE_OWNER"}
 if binding.get("ok")!=true or binding.get("ready")!=true or binding.get("author_path")!=AUTHOR or String(binding.get("author_sha256","")).to_lower()!=AUTHOR_SHA: return {"ok":false,"error":"MARKET_USE_EXACT_SPACE_BINDING"}
 if FileAccess.get_sha256(SPEC)!=SPEC_SHA or FileAccess.get_sha256(SHADER)!=SHADER_SHA: return {"ok":false,"error":"MARKET_USE_SPEC_OR_SHADER"}
 var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(SPEC))
 if not data is Dictionary or data.get("status")!="MARKET_FIVE_USE_VISUAL_SPEC_BUILD_ONLY" or data.get("groups",[]).size()!=5 or data.get("building_exclusions",[]).size()!=8: return {"ok":false,"error":"MARKET_USE_FIXED_FIVE"}
 var shader: Shader=load(SHADER) as Shader
 if shader==null or shader.resource_path!=SHADER: return {"ok":false,"error":"MARKET_USE_SHADER_LOAD"}
 var rows: Array=[]
 for i: int in range(5):
  var group: Dictionary=data.groups[i]
  if group.get("id")!=GROUPS[i] or not textures.has(group.get("asset")) or group.get("rects",[]).is_empty() or group.rects.size()>8 or group.get("exterior_segments",[]).is_empty() or group.exterior_segments.size()>32: return {"ok":false,"error":"MARKET_USE_EXACT_GROUP"}
  var texture: Texture2D=textures[group.asset]
  var bounds: Rect2=_rect(group.rects[0])
  for rect: Array in group.rects: bounds=bounds.merge(_rect(rect))
  if not Rect2(0,0,3072,2048).encloses(bounds) or float(group.uniform_scale)!=.25: return {"ok":false,"error":"MARKET_USE_SCOPE"}
  var sprite:=Sprite2D.new();sprite.name="MarketUse_"+String(group.id);sprite.texture=texture
  sprite.centered=false;sprite.position=bounds.position;sprite.scale=Vector2.ONE*.25
  sprite.region_enabled=true;sprite.region_rect=Rect2(Vector2.ZERO,bounds.size/.25)
  sprite.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
  var material:=ShaderMaterial.new();material.shader=shader
  material.set_shader_parameter("source_size",texture.get_size())
  material.set_shader_parameter("source_to_world",.25)
  material.set_shader_parameter("world_origin",bounds.position)
  material.set_shader_parameter("use_rects",_padded(group.rects,8))
  material.set_shader_parameter("use_rect_count",group.rects.size())
  material.set_shader_parameter("exterior_segments",_padded(group.exterior_segments,32))
  material.set_shader_parameter("exterior_count",group.exterior_segments.size())
  material.set_shader_parameter("building_exclusions",_padded(data.building_exclusions,8))
  material.set_shader_parameter("exclusion_count",8)
  material.set_shader_parameter("edge_width",float(group.edge))
  material.set_shader_parameter("wear_world",float(group.wear))
  material.set_shader_parameter("material_tone",Color(float(group.tone[0]),float(group.tone[1]),float(group.tone[2]),float(group.tone[3])))
  material.set_shader_parameter("texture_contrast",float(group.contrast))
  material.set_shader_parameter("core_opacity",float(group.core))
  sprite.material=material
  sprite.set_meta("market_use_source_bound",{"spec_sha256":SPEC_SHA,"space_author_sha256":AUTHOR_SHA,"purpose":group.id,"union_rects":group.rects.duplicate(true),"world_phase":true,"building_authored_bbox_exclusions":data.building_exclusions.duplicate(true),"no_native_geometry_delta":true})
  rows.append(sprite)
 if not owner.call():
  for sprite: Sprite2D in rows: sprite.free()
  return {"ok":false,"error":"MARKET_USE_CANCELLED"}
 for sprite: Sprite2D in rows: layer.add_child(sprite)
 return {"ok":true,"count":5,"purposes":GROUPS.duplicate(),"old_L_not_drawn":true,"native_geometry_unchanged":true,"approximate_purpose_ART_pending":true}
