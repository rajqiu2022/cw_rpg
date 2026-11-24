extends RefCounted
## Only two AP ordinary scenes; native packet equality owns these polygons.
## Not a C-domain alias, not ENV scenery, not a generic blocker bypass.
const FAMILY="res://scripts/city/luoyang_quarters_family_20261022ap.gd"
const FIELD="res://scripts/field/field_walkable_controller.gd"
const SIZE=Vector2(3072,2048)
const NATIVE_ROOT="res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/"
const BUNDLE="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const IDS=[&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"]
const SHORE_TEXTURE="res://art/modules/ground/road_stone_grass_edge.png"
const SHORE_SOURCE_SHA={"res://art/modules/ground/road_stone_grass_edge.png": "527d8babc86461c7f37c49bbed9f6d7c348df827b483bfedd1f1e1b8117cacd3", "res://art/modules/ground/road_stone_grass_edge.png.import": "294459d47ab301dea317c12a5c07692b758a2673819dbd2e0fb507e30150ea33", "res://.godot/imported/road_stone_grass_edge.png-f8db63f60ecff0d9b90b7a21c86f93c4.ctex": "ebc846a88af85527c64ac0b82f58457f7ca32237f30e217d1f66e59b72d31838"}
const SHORE_WATER_POLYGON=[[1000,940],[1320,860],[1780,850],[2090,930],[2220,1110],[2110,1170],[1935,1190],[1860,1250],[1870,1320],[2130,1380],[2000,1480],[1170,1470],[1360,1410],[1360,1350],[1290,1280],[1170,1270],[970,1260],[920,1220],[900,1070]]
# Fixed source y75 follows the real water boundary; source +y is inward.
# Whole unchanged 320x100 texture at uniform .5: 37.5 land /12.5 water.
const SHORE_POSES=[
	[Vector2(1053.333333333333,926.666666666667),-0.244978663126864,0,0],
	[Vector2(1160.000000000000,900.000000000000),-0.244978663126864,0,1],
	[Vector2(1266.666666666667,873.333333333333),-0.244978663126864,0,2],
	[Vector2(1396.666666666667,858.333333333333),-0.021735706841793,1,0],
	[Vector2(1550.000000000000,855.000000000000),-0.021735706841793,1,1],
	[Vector2(1703.333333333333,851.666666666667),-0.021735706841793,1,2],
	[Vector2(1831.666666666667,863.333333333333),0.252554275778060,2,0],
	[Vector2(1935.000000000000,890.000000000000),0.252554275778060,2,1],
	[Vector2(2038.333333333333,916.666666666667),0.252554275778060,2,2],
	[Vector2(2122.500000000000,975.000000000000),0.945311286555668,3,0],
	[Vector2(2187.500000000000,1065.000000000000),0.945311286555668,3,1],
	[Vector2(2165.000000000000,1140.000000000000),2.642245931909663,4,0],
	[Vector2(2066.250000000000,1175.000000000000),3.027800646446085,5,0],
	[Vector2(1978.750000000000,1185.000000000000),3.027800646446085,5,1],
	[Vector2(1897.500000000000,1220.000000000000),2.466851711366241,6,0],
	[Vector2(1865.000000000000,1285.000000000000),1.428899272190733,7,0],
	[Vector2(1935.000000000000,1335.000000000000),0.226798848053886,8,0],
	[Vector2(2065.000000000000,1365.000000000000),0.226798848053886,8,1],
	[Vector2(2097.500000000000,1405.000000000000),2.485897027348257,9,0],
	[Vector2(2032.500000000000,1455.000000000000),2.485897027348257,9,1],
	[Vector2(1930.833333333333,1479.166666666667),-3.129545043735607,10,0],
	[Vector2(1792.500000000000,1477.500000000000),-3.129545043735607,10,1],
	[Vector2(1654.166666666667,1475.833333333333),-3.129545043735607,10,2],
	[Vector2(1515.833333333333,1474.166666666667),-3.129545043735607,10,3],
	[Vector2(1377.500000000000,1472.500000000000),-3.129545043735607,10,4],
	[Vector2(1239.166666666667,1470.833333333333),-3.129545043735607,10,5],
	[Vector2(1217.500000000000,1455.000000000000),-0.305878871404852,11,0],
	[Vector2(1312.500000000000,1425.000000000000),-0.305878871404852,11,1],
	[Vector2(1360.000000000000,1380.000000000000),-1.570796326794897,12,0],
	[Vector2(1325.000000000000,1315.000000000000),-2.356194490192345,13,0],
	[Vector2(1230.000000000000,1275.000000000000),-3.058451421701352,14,0],
	[Vector2(1120.000000000000,1267.500000000000),-3.091634257867851,15,0],
	[Vector2(1020.000000000000,1262.500000000000),-3.091634257867851,15,1],
	[Vector2(945.000000000000,1240.000000000000),-2.466851711366241,16,0],
	[Vector2(910.000000000000,1145.000000000000),-1.703347859091571,17,0],
	[Vector2(925.000000000000,1037.500000000000),-0.915100700553360,18,0],
	[Vector2(975.000000000000,972.500000000000),-0.915100700553360,18,1],
]
static func fail(error: String) -> Dictionary: return {"ok":false,"error":error,"bodies":[]}
static func install(field: Node,scene: SceneScript,entries: Array,container: Node2D,world_size: Vector2,owner: Callable) -> Dictionary:
	if scene==null or scene.scene_id not in IDS: return {"ok":true,"matched":false,"bodies":[]}
	if not is_instance_valid(field) or field.get_script().resource_path!=FIELD or not field.is_inside_tree() or field.get("_current_scene")!=scene or not is_instance_valid(container) or field.get("_collision_layer")!=container or world_size!=SIZE or not owner.is_valid() or not owner.call(): return fail("AP_NATIVE_BODY_OWNER")
	var family: Variant=load(FAMILY)
	if not family.matches(scene) or not family.b().equal(entries,scene.map_layout.blockers): return fail("AP_NATIVE_WHOLE_PACKET_BLOCKERS")
	if container.get_node_or_null("APNativeObstacles")!=null: return fail("AP_NATIVE_BODY_DUPLICATE_INSTALL")
	var group:=Node2D.new();group.name="APNativeObstacles"
	var bodies: Array[StaticBody2D]=[];var seen: Dictionary={};var polygons: int=0;var rectangles: int=0
	for raw: Variant in entries:
		if not raw is Dictionary or not raw.get("id") is String or seen.has(raw.id): group.free();return fail("AP_NATIVE_BODY_EXACT_ID")
		var row: Dictionary=raw;var body:=StaticBody2D.new();body.name="Collision_"+row.id;body.collision_layer=1;body.collision_mask=0
		if row.has("ground_polygon_world"):
			if not row.ground_polygon_world is PackedVector2Array or row.ground_polygon_world.size()<3 or Geometry2D.triangulate_polygon(row.ground_polygon_world).is_empty(): body.free();group.free();return fail("AP_NATIVE_REAL_POLYGON")
			for point: Vector2 in row.ground_polygon_world:
				if not point.is_finite() or not Rect2(Vector2.ZERO,SIZE).has_point(point): body.free();group.free();return fail("AP_NATIVE_POLYGON_DOMAIN")
			var shape:=CollisionPolygon2D.new();shape.polygon=row.ground_polygon_world.duplicate();body.add_child(shape);polygons+=1
		else:
			if not row.get("pos") is Vector2 or not row.get("size") is Vector2: body.free();group.free();return fail("AP_NATIVE_RECT_DOMAIN")
			var size: Vector2=row["size"]
			if size.x<=0 or size.y<=0: body.free();group.free();return fail("AP_NATIVE_RECT_DOMAIN")
			body.position=row.pos*SIZE
			var collision:=CollisionShape2D.new();var rect:=RectangleShape2D.new();rect.size=size*SIZE;collision.shape=rect;body.add_child(collision);rectangles+=1
		body.set_meta("authoring_id",row.id);body.set_meta("ap_exact_native_geometry",true)
		group.add_child(body);bodies.append(body);seen[row.id]=true
	if bodies.is_empty() or not owner.call() or not family.matches(scene): group.free();return fail("AP_NATIVE_BODY_FINAL_OWNER")
	group.set_meta("ap_body_receipt",{"scene_id":String(scene.scene_id),"count":bodies.size(),"rectangles":rectangles,"polygons":polygons,"native_packet_exact":true,"mask_geometry_not_modified":true})
	var water: Polygon2D=null
	if scene.scene_id==IDS[1]:
		var checked: Dictionary=garden_water(field,scene,entries,family)
		if checked.get("ok")!=true: group.free();return checked
		water=checked.node
	if not owner.call():
		group.free()
		if is_instance_valid(water): water.free()
		return fail("AP_NATIVE_CANCELLED_BEFORE_ATTACH")
	container.add_child(group)
	if water!=null: (field.get("_visual_layer") as Node2D).add_child(water)
	return {"ok":true,"matched":true,"bodies":bodies,"count":bodies.size(),"rectangles":rectangles,"polygons":polygons,"scenic_water_polygons":1 if water!=null else 0}


static func garden_water(field: Node,scene: SceneScript,entries: Array,family: Variant) -> Dictionary:
	var visual: Node2D=field.get("_visual_layer") as Node2D
	if family.ROOT!=NATIVE_ROOT or not is_instance_valid(visual) or visual.get_node_or_null("APGardenSameCaptureWater")!=null: return fail("AP_GARDEN_WATER_NATIVE_BODY_OR_LAYER")
	return make_garden_water_visual(scene,entries)
# Pure native visual constructor, shared with the honest local Sprite preview.
# It grants no Family session, Field owner, Physics install or runtime readiness.
static func make_garden_water_visual(scene: SceneScript,entries: Array) -> Dictionary:
	if scene==null or scene.scene_id!=IDS[1] or scene.map_layout==null: return fail("AP_GARDEN_WATER_SCENE")
	var bundle: Variant=load(BUNDLE)
	if not bundle.equal(entries,scene.map_layout.blockers): return fail("AP_GARDEN_WATER_NATIVE_BLOCKERS")
	var raw: Variant=scene.get_meta("ap_garden_scenic_water",null)
	if not raw is Dictionary or raw.size()!=7 or not raw.get("polygon") is PackedVector2Array or raw.get("texture")!=NATIVE_ROOT+String(IDS[1])+"/deepwater.res" or raw.get("texture_size")!=Vector2i(200,280) or raw.get("rgba_sha256")!="dc4ba07d16eb32cccc44ee72215e1f2904b5a1998c0163f80c7c5be78c37f63e" or raw.get("uniform_texture_scale")!=1.0 or raw.get("z_index")!=-18 or raw.get("scenic_bridge_no_support")!=true: return fail("AP_GARDEN_WATER_EXACT_NATIVE_METADATA")
	var matches: int=0
	for row: Dictionary in entries:
		if row.id=="ap_garden_deepwater_1":
			if not bundle.equal(row.get("ground_polygon_world"),raw.polygon): return fail("AP_GARDEN_WATER_VISUAL_BODY_POLYGON_DIFF")
			matches+=1
	if matches!=1: return fail("AP_GARDEN_WATER_UNIQUE_REAL_BODY")
	var texture: Texture2D=ResourceLoader.load(raw.texture) as Texture2D
	if texture==null or texture.get_size()!=Vector2(200,280): return fail("AP_GARDEN_WATER_EXACT_TEXTURE")
	var image: Image=texture.get_image()
	if image==null: return fail("AP_GARDEN_WATER_IMAGE")
	image.convert(Image.FORMAT_RGBA8)
	if bundle.bytes_sha(image.get_data())!=raw.rgba_sha256: return fail("AP_GARDEN_WATER_FULL_RGBA")
	var node:=Polygon2D.new();node.name="APGardenSameCaptureWater";node.polygon=raw.polygon.duplicate();node.uv=raw.polygon.duplicate();node.texture=texture;node.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED;node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;node.z_index=-18
	node.set_meta("ap_scenic_water",{"same_native_body_polygon":true,"no_positive_support":true,"water_rgba_sha256":raw.rgba_sha256,"scene_id":String(scene.scene_id)})
	var shore: Dictionary=attach_garden_shore_visual(node,raw.polygon)
	if shore.get("ok")!=true: node.free();return shore
	return {"ok":true,"node":node}

# Strict visual-only successor: never changes native Scene, mask, water polygon,
# entries, bodies, walk support, navigation, NPCs, portals or authored routes.
static func shore_source_paths() -> Array[String]:
	var paths: Array[String]=[]
	for path: String in SHORE_SOURCE_SHA: paths.append(path)
	return paths

static func attach_garden_shore_visual(water: Polygon2D,polygon: PackedVector2Array) -> Dictionary:
	if water==null or water.name!="APGardenSameCaptureWater" or polygon.size()!=SHORE_WATER_POLYGON.size(): return fail("AP_SHORE_REAL_WATER_OWNER")
	for i: int in range(polygon.size()):
		if polygon[i]!=Vector2(SHORE_WATER_POLYGON[i][0],SHORE_WATER_POLYGON[i][1]): return fail("AP_SHORE_EXACT_NATIVE_19_SEGMENTS")
	for path: String in SHORE_SOURCE_SHA:
		if FileAccess.get_sha256(path)!=SHORE_SOURCE_SHA[path]: return fail("AP_SHORE_EXACT_THREE_MEDIA_LEAVES "+path)
	var texture: Texture2D=ResourceLoader.load(SHORE_TEXTURE) as Texture2D
	if texture==null or texture.get_size()!=Vector2(320,100): return fail("AP_SHORE_UNCHANGED_FULL_TEXTURE_320_100")
	var group:=Node2D.new();group.name="APGardenShoreVisualOnly"
	for pose: Array in SHORE_POSES:
		var sprite:=Sprite2D.new();sprite.name="Shore_%02d_%02d"%[pose[2],pose[3]]
		sprite.texture=texture;sprite.centered=false;sprite.offset=Vector2(-160,-75)
		sprite.scale=Vector2(.5,.5);sprite.position=pose[0];sprite.rotation=pose[1]
		sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;sprite.z_index=1
		sprite.set_meta("ap_visual_only",true);sprite.set_meta("native_water_segment",pose[2])
		group.add_child(sprite)
	group.set_meta("ap_shore_receipt",{"tiles":37,"native_segments":19,"uniform_scale":.5,"source_boundary_y":75,"stone_water_side":12.5,"grass_land_side":37.5,"no_geometry_delta":true,"no_positive_support":true,"no_image_edit_or_crop":true})
	water.add_child(group)
	return {"ok":true,"visual_shore_tiles":37}
