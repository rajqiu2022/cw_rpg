extends RefCounted
## Fixed five visual-use unions only; native/storage/NAV stay under Source authority.
const SPEC="res://build/luoyang_market_use_20261024b_system01/market_five_use_spec_NOTREADY.json"
const SPEC_SHA="9143c3e5d0e7efb55b531b42aafe33b10b043dec6d7996aba6a60067d10a47bd"
const SHADER="res://build/luoyang_market_use_20261024b_system01/market_use_union_CANDIDATE.gdshader"
const SHADER_SHA="cdaae0a2ac6ba9d403c3d3459e3b54cb74df75a0f220fa381f7baf5933ad83ad"
const AUTHOR="res://build/luoyang_city_space_20261024b_source01/author_space_delta_interaction_successor03_NOTREADY.json"
const AUTHOR_SHA="cd1bf3be0cc7d6ddffb2bcbebd2ea51d3258fc5a4ed7ab603703fb020116a467"
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
 if not data is Dictionary or data.get("status")!="MARKET_FIVE_USE_VISUAL_SPEC_BUILD_ONLY" or data.get("groups",[]).size()!=5 or data.get("building_exclusions",[]).size()!=2: return {"ok":false,"error":"MARKET_USE_FIXED_FIVE"}
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
  material.set_shader_parameter("building_exclusions",_padded(data.building_exclusions,2))
  material.set_shader_parameter("exclusion_count",2)
  material.set_shader_parameter("edge_width",float(group.edge))
  material.set_shader_parameter("wear_world",float(group.wear))
  material.set_shader_parameter("material_tone",Color(float(group.tone[0]),float(group.tone[1]),float(group.tone[2]),float(group.tone[3])))
  material.set_shader_parameter("texture_contrast",float(group.contrast))
  material.set_shader_parameter("core_opacity",float(group.core))
  sprite.material=material
  sprite.set_meta("market_use_source_bound",{"spec_sha256":SPEC_SHA,"space_author_sha256":AUTHOR_SHA,"purpose":group.id,"union_rects":group.rects.duplicate(true),"world_phase":true,"building_A1_bbox_exclusions":data.building_exclusions.duplicate(true),"no_native_geometry_delta":true})
  rows.append(sprite)
 if not owner.call():
  for sprite: Sprite2D in rows: sprite.free()
  return {"ok":false,"error":"MARKET_USE_CANCELLED"}
 for sprite: Sprite2D in rows: layer.add_child(sprite)
 return {"ok":true,"count":5,"purposes":GROUPS.duplicate(),"old_L_not_drawn":true,"native_geometry_unchanged":true,"approximate_purpose_ART_pending":true}
