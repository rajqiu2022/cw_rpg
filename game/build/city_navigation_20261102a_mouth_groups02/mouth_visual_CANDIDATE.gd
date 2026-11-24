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


static func _endpoint_class(endpoint: Dictionary) -> Dictionary:
 var id: String=String(endpoint.get("id",""))
 if endpoint.scene_id==Geo.ADVENTURE: return {"surface_class":"accepted_riverside_trail","treatment":"retained_real_route","retained":true}
 if endpoint.scene_id=="luoyang_riverside_garden_20261022ap": return {"surface_class":"accepted_garden_path","treatment":"retained_real_route","retained":true}
 if id=="citynav/gate_civic/a": return {"surface_class":"existing_gate_passage","treatment":"retained_real_route","retained":true}
 if id in ["citynav/gate_civic/b","citynav/yamen_docks/a"]: return {"surface_class":"existing_civic_cross_street","treatment":"retained_real_route","retained":true}
 if id=="citynav/docks_garden/a": return {"surface_class":"existing_quay_street","treatment":"retained_real_route","retained":true}
 if endpoint.scene_id=="ch4_s2_canal_docks": return {"surface_class":"dry_quay_edge","treatment":"connected_verge_nav_clipped","retained":false}
 if id in ["citynav/yamen_artisan/a","citynav/market_estate/a"]: return {"surface_class":"urban_court_edge","treatment":"connected_verge_preserve_existing_paving","retained":false}
 return {"surface_class":"outward_existing_road","treatment":"connected_verge_existing_safe_axis","retained":false}

static func _planned_half(endpoint: Dictionary) -> float:
 var id: String=String(endpoint.id)
 var halves: Dictionary={"citynav/market_artisan/a":44.0,"citynav/market_artisan/b":48.0,"citynav/yamen_artisan/a":32.0,"citynav/yamen_artisan/b":40.0,"citynav/market_temple/a":64.0,"citynav/market_temple/b":40.0,"citynav/docks_temple/a":32.0,"citynav/market_estate/a":48.0,"citynav/market_estate/b":40.0,"citynav/estate_garden/a":40.0,"citynav/temple_riverside/a":40.0,"citynav/yamen_docks/b":28.0,"citynav/market_docks/a":40.0,"citynav/market_docks/b":40.0}
 return float(halves.get(id,28.0))

static func _class_road(parent: Node, endpoint: Dictionary, stone: Texture2D, shader: Shader, category: Dictionary) -> Dictionary:
 var row: Dictionary={"ok":true,"pair_id":endpoint.pair_id,"endpoint_id":endpoint.id,"surface_class":category.surface_class,"treatment":category.treatment,"original_NAV_and_bodies_unchanged":true,"activation_and_arrival_unchanged":true}
 if category.retained:
  row["retained_real_route"]=true; row["no_generic80px_strip"]=true
  return row
 var a: Vector2=_extent(endpoint.scene_id,endpoint.arrival,-endpoint.outward,180)
 var b: Vector2=_extent(endpoint.scene_id,endpoint.mouth,endpoint.outward,320)
 var side:=Vector2(-endpoint.outward.y,endpoint.outward.x)
 var half: float=_planned_half(endpoint)
 # A view-only guard can defer ONE paint operation, never retire working paired
 # exits or cause the host to roll back an otherwise accepted physical field.
 var safe_band:=false
 while half>=20.0:
  if Geo.safe_segment(endpoint.scene_id,a-side*half,b-side*half) and Geo.safe_segment(endpoint.scene_id,a,b) and Geo.safe_segment(endpoint.scene_id,a+side*half,b+side*half):
   safe_band=true; break
  half-=8.0
 if not safe_band:
  row["retained_real_route"]=true; row["visual_deferred_reason"]="ORIGINAL_SAFE_AXIS_BAND"; return row
 var soil: Texture2D=load(SOIL) as Texture2D
 if soil==null:
  row["retained_real_route"]=true; row["visual_deferred_reason"]="FROZEN_SOIL_UNAVAILABLE"; return row
 var mask: Texture2D
 var clipped: bool=String(endpoint.scene_id)=="ch4_s2_canal_docks"
 if clipped:
  if parent.has_meta("class02a_nav_texture"): mask=parent.get_meta("class02a_nav_texture") as Texture2D
  else:
   var binding: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Geo.FINISH_BIND)) as Dictionary
   var source: String=String(binding.get("scenes",{}).get(String(endpoint.scene_id),{}).get("mask",{}).get("path",""))
   if not source.is_empty(): mask=load(source) as Texture2D
   if mask!=null: parent.set_meta("class02a_nav_texture",mask)
  if mask==null:
   row["retained_real_route"]=true; row["visual_deferred_reason"]="ORIGINAL_SHORE_MASK_UNAVAILABLE"; return row
 var body_margin: float=17.0 if endpoint.outward.x!=0 else 12.0
 var edge: Vector2=b+endpoint.outward*body_margin
 var verge: float=minf(160.0,maxf(half+28.0,half*3.0))
 var polygon:=PackedVector2Array([a-side*verge,edge+endpoint.outward*6.0-side*verge,edge+endpoint.outward*6.0+side*verge,a+side*verge])
 var node: Polygon2D=_face(parent,"RoadOpening02a_"+String(endpoint.pair_id)+"_"+String(endpoint.side),polygon,stone,-997)
 var material:=ShaderMaterial.new(); material.shader=shader
 material.set_shader_parameter("sample_mode",2)
 material.set_shader_parameter("soil_texture",soil); material.set_shader_parameter("soil_period",Vector2(768,768))
 material.set_shader_parameter("class_start",a); material.set_shader_parameter("class_end",b)
 material.set_shader_parameter("class_edge",edge); material.set_shader_parameter("class_outward",endpoint.outward)
 material.set_shader_parameter("class_half",half); material.set_shader_parameter("class_verge_half",verge)
 material.set_shader_parameter("class_preserve_center",not String(endpoint.scene_id).begins_with("luoyang_") or String(endpoint.scene_id)=="luoyang_artisan_residential_20261022ap")
 material.set_shader_parameter("class_clip_shore",clipped)
 material.set_shader_parameter("class_world_size",Geo.size_for(String(endpoint.scene_id)))
 if clipped: material.set_shader_parameter("class_shore_mask",mask)
 node.material=material
 node.set_meta("class02a_endpoint",String(endpoint.id)); node.set_meta("at_grade_not_a_body",true)
 row.merge({"retained_real_route":false,"start":a,"end":b,"edge":edge,"half_width":half,"footprint_polygon":polygon,"one_pixel_full_body_route_safe":true,"nav_mask_clipped":clipped,"relative_ground_z":-997,"world_uv_period":Vector2(256,512.0/3.0),"soil_period":Vector2(768,768),"existing_legacy_center_material_retained":not String(endpoint.scene_id).begins_with("luoyang_") or String(endpoint.scene_id)=="luoyang_artisan_residential_20261022ap"})
 return row

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
  if endpoint.get("id","")=="citynav/docks_temple/b":
   var sample: Dictionary=_temple_docks_sample(layer,endpoint,stone,shader)
   if sample.get("ok")!=true:
    rows.append({"ok":true,"pair_id":endpoint.pair_id,"endpoint_id":endpoint.id,"surface_class":"accepted_temple_south_sample","treatment":"retained_real_route","retained_real_route":true,"visual_deferred_reason":sample.get("error","SAMPLE_GUARD")}); continue
   sample["endpoint_id"]=endpoint.id; sample["surface_class"]="accepted_temple_south_sample"; sample["treatment"]="accepted_continuous_court_opening"; sample["retained_real_route"]=false
   sample["waypost"]=sign; rows.append(sample); continue
  var category: Dictionary=_endpoint_class(endpoint)
  var row: Dictionary=_class_road(layer,endpoint,stone,shader,category)
  row["waypost"]=sign; rows.append(row)
 var result: Dictionary={"ok":true,"approach_lanes":rows.size(),"rows":rows,"world_uv":true,"original_NAV_and_bodies_unchanged":true,"parent_instance":parent.get_instance_id()}
 field.set_meta(META,result)
 return result
