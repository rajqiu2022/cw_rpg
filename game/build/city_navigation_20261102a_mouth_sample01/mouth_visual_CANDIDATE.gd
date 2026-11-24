extends RefCounted
## Continuous existing-material street approaches with complete native wayposts.
## Geometry only follows the fixed approach/outward axis while original full feet
## remain safe. No new walkability, props' bodies, shader-drawn signs or image edits.
const SELF := "res://build/city_navigation_20261101d_candidate01/mouth_visual.gd"
const Geo = preload("res://build/city_navigation_20261101d_candidate01/navigation_geometry.gd")
const Pair = preload("res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd")
const STONE := "res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png"
const SOIL := "res://art/modules/miao_town_20261029f/ground.png"
const SHOULDER := "res://art/modules/miao_town_20261029f/path.png"
const SIGN := "res://art/modules/prop/prop_zhuwei_road_sign.png"
const SOFT := "res://build/city_navigation_20261101d_candidate01/mouth_shoulder.gdshader"
const META := "city_navigation_20261101d_mouth_visual"

static func source_paths() -> Array[String]:
 var paths: Array[String] = [SELF,SOFT]
 for media: String in [STONE,SHOULDER,SIGN,SOIL]: paths.append_array(Geo.media_paths(media))
 return paths

static func _face(parent: Node, name: String, points: PackedVector2Array, texture: Texture2D, z: int) -> Polygon2D:
 var polygon := Polygon2D.new()
 polygon.name=name; polygon.polygon=points; polygon.texture=texture
 polygon.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 polygon.z_as_relative=true; polygon.z_index=z
 var uv := PackedVector2Array()
 for point: Vector2 in points: uv.append(point/Vector2(256.0,512.0/3.0)*texture.get_size())
 polygon.uv=uv; parent.add_child(polygon)
 return polygon

static func _extent(id: String, origin: Vector2, direction: Vector2, distance: int) -> Vector2:
 var last: Vector2=origin
 for i: int in range(1,distance+1):
  var next: Vector2=origin+direction*float(i)
  if not Geo.safe_static(id,next): break
  last=next
 return last

static func _waypost(parent: Node, endpoint: Dictionary, texture: Texture2D) -> Dictionary:
 var side: Vector2=Vector2(-endpoint.outward.y,endpoint.outward.x)
 # Outside the complete contact-foot corridor, not over the walking approach.
 var foot: Vector2=endpoint.mouth+side*118.0
 var sign:=Sprite2D.new(); sign.name="NativeStreetWaypost_"+String(endpoint.pair_id)
 sign.texture=texture; sign.position=foot; sign.scale=Vector2.ONE*.45
 sign.centered=true; sign.offset=Vector2(0,-texture.get_height()*.5)
 sign.z_as_relative=true; sign.z_index=0
 parent.add_child(sign)
 var label:=Label.new(); label.name="WaypostDestination"; label.text=Pair.destination_name(String(endpoint.target.logical_id))
 label.position=foot+Vector2(-45,-119); label.size=Vector2(90,36)
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label.add_theme_font_size_override("font_size",14)
 label.add_theme_color_override("font_color",Color(.94,.87,.64))
 label.add_theme_color_override("font_shadow_color",Color(.08,.06,.03))
 label.add_theme_constant_override("shadow_offset_x",1); label.add_theme_constant_override("shadow_offset_y",1)
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE; parent.add_child(label)
 return {"source":SIGN,"source_size":texture.get_size(),"uniform_scale":.45,"foot":foot,"contact_corridor_outside":true}


static func _temple_docks_sample(parent: Node, endpoint: Dictionary, stone: Texture2D, shader: Shader) -> Dictionary:
 # Exact ONE endpoint sample; do not infer expansion to the other21 endpoints.
 if endpoint.scene_id!="luoyang_temple_region_27d" or endpoint.source_portal!="legacy_portal_7" or endpoint.mouth!=Vector2(2390,4380) or endpoint.arrival!=Vector2(2390,4276) or endpoint.outward!=Vector2(0,1):
  return {"ok":false,"error":"SAMPLE02A_FIXED_ENDPOINT"}
 var region: Dictionary=Geo.region_for(String(endpoint.scene_id))
 var forecourt:=Rect2(512,3680,2048,928)
 if region.get("size")!=Vector2(3072,4608) or not region.get("floor_rects",[]).has(forecourt):
  return {"ok":false,"error":"SAMPLE02A_ORIGINAL_FORECOURT"}
 var soil: Texture2D=load(SOIL) as Texture2D
 if soil==null: return {"ok":false,"error":"SAMPLE02A_EXISTING_SOIL"}
 var points:=PackedVector2Array([Vector2(1536,4096),Vector2(1800,4144),Vector2(2170,4192),Vector2(2390,4276),Vector2(2390,4596)])
 var widths:=PackedFloat32Array([96.0,96.0,88.0,72.0,72.0])
 # Fixed route/visible road-band only. The original NAV and actual activation
 # remain authoritative; no nearest repair, new body, floor or target mutation.
 for i: int in range(points.size()-1):
  var side: Vector2=(points[i+1]-points[i]).normalized().orthogonal()
  var half: float=maxf(widths[i],widths[i+1])
  for offset: float in [-half,0.0,half]:
   if not Geo.safe_segment(String(endpoint.scene_id),points[i]+side*offset,points[i+1]+side*offset):
    return {"ok":false,"error":"SAMPLE02A_ORIGINAL_FULL_ROAD_BAND"}
 # This overlay closes the ONE southern forecourt into the existing soil base.
 # Full-quad world UV does not restart at bends and no detached dirt stamp is used.
 # Six decorative soil pixels also cover the old outer curb dust envelope,
 # avoiding an orphaned old stone rectangle around the new natural opening.
 # This visual bleed adds no floor and never changes the validated route end.
 var area:=Rect2(506,4096,2060,518)
 var cap: Polygon2D=_face(parent,"TempleDocksContinuousOpening02a",PackedVector2Array([area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)]),stone,-997)
 var material:=ShaderMaterial.new(); material.shader=shader
 material.set_shader_parameter("sample_mode",1)
 material.set_shader_parameter("sample_points",points)
 material.set_shader_parameter("sample_half_widths",widths)
 material.set_shader_parameter("soil_texture",soil)
 material.set_shader_parameter("soil_period",Vector2(768,768))
 material.set_shader_parameter("sample_soft_shoulder",28.0)
 cap.material=material
 cap.set_meta("sample02a_visual_only",true)
 # Formal court ends in TWO continuous at-grade stone courses with ONE open
 # branch. This is flat ground edging, not a knee wall, doorway or collision.
 var curbs: Array[Rect2]=[Rect2(512,4087,904,18),Rect2(1656,4087,904,18)]
 for i: int in range(curbs.size()):
  var curb: Rect2=curbs[i]
  var node: Polygon2D=_face(parent,"TempleDocksFlatCourtCourse02a_"+str(i),PackedVector2Array([curb.position,Vector2(curb.end.x,curb.position.y),curb.end,Vector2(curb.position.x,curb.end.y)]),stone,-996)
  var uv:=PackedVector2Array()
  for point: Vector2 in node.polygon: uv.append(Vector2(point.x*6.0,704.0+(point.y-curb.position.y)*6.0))
  node.uv=uv; node.modulate=Color(.84,.84,.84,1.0)
  node.set_meta("at_grade_not_a_body",true)
 return {"ok":true,"pair_id":endpoint.pair_id,"sample_revision":"20261102a_temple_docks_one_endpoint","sample_endpoint_id":endpoint.id,"soil_cap_area":area,"decorative_soil_bleed_px":6,"start":points[0],"end":points[-1],"centerline":points,"half_widths":widths,"one_pixel_full_body_route_safe":true,"one_pixel_original_full_road_band_safe":true,"soil_source":SOIL,"soil_period":Vector2(768,768),"world_uv_period":Vector2(256,512.0/3.0),"relative_cap_z":-997,"relative_flat_course_z":-996,"ground_covering_other21_endpoints":false,"activation_and_arrival_unchanged":true}

static func attach(field: Node, metadata: Dictionary) -> Dictionary:
 var parent: Node=field.get("_visual_layer") as Node
 if parent==null: return {"ok":false,"error":"MOUTH_VISUAL_PARENT"}
 if field.has_meta(META):
  var prior: Dictionary=field.get_meta(META)
  if prior.get("parent_instance")==parent.get_instance_id() and parent.has_node("CityNavigationRoadMouths11d"): return prior
  field.remove_meta(META)
 var stone: Texture2D=load(STONE) as Texture2D
 var dirt: Texture2D=load(SHOULDER) as Texture2D
 var post: Texture2D=load(SIGN) as Texture2D
 var shader: Shader=load(SOFT) as Shader
 if stone==null or dirt==null or post==null or shader==null: return {"ok":false,"error":"MOUTH_EXISTING_MEDIA"}
 var layer:=Node2D.new(); layer.name="CityNavigationRoadMouths11d"; parent.add_child(layer)
 var rows: Array[Dictionary]=[]
 for endpoint: Dictionary in metadata.get("mouths",[]):
  var sign: Dictionary=_waypost(layer,endpoint,post)
  # The riverside already owns the accepted full natural trail down to its mouth.
  if endpoint.scene_id==Geo.ADVENTURE:
   rows.append({"pair_id":endpoint.pair_id,"adopted_natural_trail_retained":true,"waypost":sign}); continue
  if endpoint.get("id","")=="citynav/docks_temple/b":
   var sample: Dictionary=_temple_docks_sample(layer,endpoint,stone,shader)
   if sample.get("ok")!=true: return sample
   sample["waypost"]=sign; rows.append(sample); continue
  var a: Vector2=_extent(endpoint.scene_id,endpoint.arrival,-endpoint.outward,180)
  var b: Vector2=_extent(endpoint.scene_id,endpoint.mouth,endpoint.outward,320)
  if not Geo.safe_segment(endpoint.scene_id,a,b): return {"ok":false,"error":"EXTENDED_LANE_FULL_BODY"}
  var side: Vector2=Vector2(-endpoint.outward.y,endpoint.outward.x)
  var half: float=float(endpoint.lane_width)*.5
  var natural: bool=endpoint.pair_id=="temple_riverside"
  var texture: Texture2D=dirt if natural else stone
  # Same world UV as the adopted fine stone; no sudden foreign rectangular tile.
  _face(layer,"StreetApproach_"+String(endpoint.pair_id),PackedVector2Array([a-side*half,b-side*half,b+side*half,a+side*half]),texture,-998)
  var shoulder: Polygon2D=_face(layer,"NativeRoadShoulder",PackedVector2Array([a-side*(half+18),b-side*(half+18),b+side*(half+18),a+side*(half+18)]),dirt,-999)
  var material:=ShaderMaterial.new(); material.shader=shader
  material.set_shader_parameter("line_start",a); material.set_shader_parameter("line_end",b)
  material.set_shader_parameter("lane_half",half); material.set_shader_parameter("shoulder",18.0)
  shoulder.material=material
  rows.append({"pair_id":endpoint.pair_id,"start":a,"end":b,"one_pixel_full_body_route_safe":true,"waypost":sign,"world_uv_period":Vector2(256,512.0/3.0)})
 var result: Dictionary={"ok":true,"approach_lanes":rows.size(),"rows":rows,"world_uv":true,"original_NAV_and_bodies_unchanged":true,"parent_instance":parent.get_instance_id()}
 field.set_meta(META,result)
 return result
