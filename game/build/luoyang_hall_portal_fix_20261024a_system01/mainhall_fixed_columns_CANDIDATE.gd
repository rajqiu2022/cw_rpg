extends RefCounted
## Main-hall only: source-bound native bases and approximate source-pixel pillar overlays.
## No disk image writes, collision nodes, actor transform edits or pillar fading.
const ROOM := &"luoyang_yamen_official_hall_20261018t"
const AUTHOR := "res://data/maps/luoyang_layout_rooms_20261018t/luoyang_yamen_official_hall_20261018t/author.json"
const AUTHOR_SHA := "b5622dbe1c8717c83dedd76d591e5f633a187ec828b9430d72eba00dd98381f9"
const SHELL := "res://art/modules/luoyang_assembled_interiors_20261016g/shell_formal_hall_v1.png"
const SHELL_SHA := "b9e589ceed81bd28dd7b3d866aa931fc1f8a6e3f59e426bae94f2a384b2f879a"
const POLICY_KEY := "_mainhall_fixed_base_only_20261024a"
const SOURCE_SIZE := Vector2(1536,1024)
const COLUMNS := [
 {"id":"fixed_column_0","overlay_id":"mainhall_fixed_column_0_foreground","base":[[473,592],[548,592],[548,632],[473,632]],"projection":[[470,292],[552,292],[552,634],[470,634]],"region":[470,292,83,343],"silhouette":[[482,292],[514,292],[518,297],[519,310],[514,321],[521,583],[527,588],[528,598],[531,603],[532,625],[527,630],[480,630],[477,624],[480,603],[483,597],[483,586],[488,581],[484,323],[479,312],[479,299]]},
 {"id":"fixed_column_1","overlay_id":"mainhall_fixed_column_1_foreground","base":[[998,592],[1068,592],[1068,632],[998,632]],"projection":[[995,292],[1070,292],[1070,634],[995,634]],"region":[995,292,76,343],"silhouette":[[1024,292],[1051,293],[1056,298],[1056,311],[1051,321],[1052,583],[1057,591],[1057,600],[1060,605],[1061,626],[1056,630],[1007,630],[1003,626],[1004,606],[1009,599],[1010,588],[1017,583],[1017,321],[1019,311],[1018,299]]}
]

static func _v(raw: Array) -> Vector2:
 return Vector2(float(raw[0]),float(raw[1]))

static func _poly(raw: Array,scale: Vector2=Vector2.ONE) -> PackedVector2Array:
 var points:=PackedVector2Array()
 for point: Array in raw: points.append(_v(point)*scale)
 return points

static func geometry_matches(data: Dictionary) -> bool:
 if data.get("coordinate_contract")!="source_feet_assembled_interiors_20261016g" or data.get(POLICY_KEY)!=AUTHOR_SHA: return false
 var rows: Array=data.get("fixed_architecture",[])
 if rows.size()!=2: return false
 for i: int in range(2):
  var row: Dictionary=rows[i];var expected: Dictionary=COLUMNS[i]
  if row.get("id")!=expected.id or float(row.get("depth_front_px",-1))!=634.0: return false
  if _poly(row.get("ground_base_polygon_px",[]))!=_poly(expected.base) or _poly(row.get("full_visual_projection_px",[]))!=_poly(expected.projection): return false
 return true

static func compile_bases(data: Dictionary,compiled: Dictionary,world_size: Vector2) -> Dictionary:
 if not geometry_matches(data) or not world_size.is_finite() or world_size.x<=0 or world_size.y<=0 or not compiled.get("_compiled") is Dictionary: return {}
 var values: Dictionary=compiled._compiled
 if values.get("world_size")!=world_size or values.get("source_solids",[]).size()!=4 or values.get("world_solids",[]).size()!=4 or values.get("world_foot_forbidden",[]).size()!=2: return {}
 # The source-bound predecessor has already performed its original full compile.
 # Replace only the two visual-clearance exclusions; native layout bases stay untouched.
 var scale: Vector2=world_size/SOURCE_SIZE
 for row: Dictionary in COLUMNS:
  values.source_solids.append(_poly(row.base))
  values.world_solids.append(_poly(row.base,scale))
 values.world_foot_forbidden.clear()
 compiled["_mainhall_fixed_base_receipt"]={"author_sha256":AUTHOR_SHA,"native_base_ids":["fixed_column_0","fixed_column_1"],"original_furniture_solids":4,"compiled_solids":6,"visual_exclusions_removed":2,"native_body_unchanged":true}
 return compiled

static func _masked_region(source: Image,row: Dictionary) -> Image:
 var region: Array=row.region
 var area:=Rect2i(int(region[0]),int(region[1]),int(region[2]),int(region[3]))
 var result: Image=source.get_region(area)
 var polygon: PackedVector2Array=_poly(row.silhouette)
 for y: int in range(area.size.y):
  for x: int in range(area.size.x):
   if not Geometry2D.is_point_in_polygon(Vector2(area.position)+Vector2(x+.5,y+.5),polygon):
    var color: Color=result.get_pixel(x,y)
    color.a=0.0
    result.set_pixel(x,y,color)
 return result

static func install(world: Node2D,scene: SceneScript,author: Dictionary,fade: RefCounted,world_size: Vector2) -> bool:
 if not is_instance_valid(world) or scene==null or scene.scene_id!=ROOM or scene.background_path!=SHELL or fade==null: return false
 if author.get("room",{}).get("scene_id")!=String(ROOM) or author.get("shell",{}).get("texture")!=SHELL or author.shell.get("source_sha256")!=SHELL_SHA: return false
 var data: Dictionary=author.get("geometry",{}).duplicate(true);data[POLICY_KEY]=AUTHOR_SHA
 if not geometry_matches(data) or not world_size.is_finite() or world_size.x<=0 or world_size.y<=0: return false
 var background: Sprite2D=world.get_node_or_null("WorldBackground") as Sprite2D
 var scale: Vector2=world_size/SOURCE_SIZE
 if background==null or background.texture==null or background.texture.resource_path!=SHELL or background.position!=Vector2.ZERO or background.centered or background.scale!=scale: return false
 var source: Image=background.texture.get_image()
 if source==null or source.is_empty(): return false
 if source.is_compressed() and source.decompress()!=OK: return false
 if source.get_size()!=Vector2i(1536,1024) or source.get_format()!=Image.FORMAT_RGBA8: return false
 var assembly_ids: Variant=fade.get("_assembly_ids")
 var fade_ids: Variant=fade.get("_assembly_fade_ids")
 if not assembly_ids is Array or not fade_ids is Array or assembly_ids.size()!=4: return false
 for row: Dictionary in COLUMNS:
  if row.overlay_id in assembly_ids or row.overlay_id in fade_ids or world.get_node_or_null(String(row.overlay_id))!=null: return false
 var sprites: Array[Sprite2D]=[]
 for row: Dictionary in COLUMNS:
  var clipped: Image=_masked_region(source,row)
  if clipped==null or clipped.is_empty():
   for pending: Sprite2D in sprites: pending.free()
   return false
  var sprite:=Sprite2D.new()
  sprite.name=String(row.overlay_id)
  sprite.texture=ImageTexture.create_from_image(clipped)
  sprite.centered=false;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  sprite.position=Vector2(float(row.region[0]),float(row.region[1]))*scale
  sprite.scale=scale
  sprite.set_meta("mainhall_pillar_source_clip",{"source":SHELL,"source_sha256":SHELL_SHA,"source_region":row.region.duplicate(),"source_silhouette":row.silhouette.duplicate(true),"approximate_silhouette_ART_pending":true,"depth_source_y":634.0,"no_PNG_write":true,"no_pillar_fade":true})
  sprites.append(sprite)
 for i: int in range(sprites.size()):
  var sprite: Sprite2D=sprites[i];var row: Dictionary=COLUMNS[i]
  world.add_child(sprite)
  assembly_ids.append(String(row.overlay_id))
  # Existing current-frame ImageTexture alpha is also the exact ghost mask.
  # No fade ID is appended, so the pillar keeps full native opacity.
  fade.call("add_prop",sprite,String(row.overlay_id),634.0*scale.y)
 return true
