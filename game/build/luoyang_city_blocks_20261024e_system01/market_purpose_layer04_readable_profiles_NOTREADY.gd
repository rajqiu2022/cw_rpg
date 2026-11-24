extends RefCounted
## Fixed five visual-use unions only; native/storage/NAV stay under Source authority.
const SPEC="res://build/luoyang_city_blocks_20261024e_system01/market_five_use_spec04_readable_profiles_NOTREADY.json"
const SPEC_SHA="dda3588304159d2f2272854632eb695640ae79201ef94e65aa77cd04f2cf95b7"
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
 var base: Variant=data.get("clean_base")
 if not base is Dictionary or base.get("id")!="market_clean_base" or base.get("asset")!="court_stone" or not textures.has("court_stone") or not base.get("rect") is Array or base.rect.size()!=4 or _vec4(base.rect)!=Vector4(0,0,3072,2048) or float(base.get("uniform_scale",0))!=.25 or not base.get("tone") is Array or base.tone.size()!=4 or _vec4(base.tone)!=Vector4(.57,.58,.56,1) or float(base.get("contrast",0))!=.34 or float(base.get("core",0))!=1 or float(base.get("edge",0))!=1 or float(base.get("wear",-1))!=0 or base.get("exclusions",null)!=[] or base.get("world_phase")!=true: return {"ok":false,"error":"MARKET_USE_EXACT_CLEAN_BASE"}
 var base_texture: Texture2D=textures.court_stone
 var base_sprite:=Sprite2D.new();base_sprite.name="MarketUse_clean_base";base_sprite.texture=base_texture
 base_sprite.centered=false;base_sprite.position=Vector2.ZERO;base_sprite.scale=Vector2.ONE*.25
 base_sprite.region_enabled=true;base_sprite.region_rect=Rect2(Vector2.ZERO,Vector2(3072,2048)/.25)
 base_sprite.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 var base_material:=ShaderMaterial.new();base_material.shader=shader
 base_material.set_shader_parameter("source_size",base_texture.get_size())
 base_material.set_shader_parameter("source_to_world",.25)
 base_material.set_shader_parameter("world_origin",Vector2.ZERO)
 base_material.set_shader_parameter("use_rects",_padded([base.rect],8))
 base_material.set_shader_parameter("use_rect_count",1)
 base_material.set_shader_parameter("exterior_segments",_padded([[0,0,3072,0],[3072,0,3072,2048],[3072,2048,0,2048],[0,2048,0,0]],32))
 base_material.set_shader_parameter("exterior_count",4)
 base_material.set_shader_parameter("building_exclusions",_padded([],8))
 base_material.set_shader_parameter("exclusion_count",0)
 base_material.set_shader_parameter("edge_width",1.0)
 base_material.set_shader_parameter("wear_world",0.0)
 base_material.set_shader_parameter("material_tone",Color(.57,.58,.56,1))
 base_material.set_shader_parameter("texture_contrast",.34)
 base_material.set_shader_parameter("core_opacity",1.0)
 base_sprite.material=base_material
 base_sprite.set_meta("market_use_source_bound",{"spec_sha256":SPEC_SHA,"space_author_sha256":AUTHOR_SHA,"purpose":"clean_base_baked_shadow_replacement","world_phase":true,"exclusions":[],"uniform_scale":.25,"core_opacity":1.0,"no_native_geometry_delta":true})
 rows.append(base_sprite) # First child in this layer: below the unchanged five purpose unions.
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
 return {"ok":true,"count":6,"clean_base":true,"five_purpose_count":5,"purposes":GROUPS.duplicate(),"old_L_not_drawn":true,"native_geometry_unchanged":true,"approximate_purpose_ART_pending":true}
