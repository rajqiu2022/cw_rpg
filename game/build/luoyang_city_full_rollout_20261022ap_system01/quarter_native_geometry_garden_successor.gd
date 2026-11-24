extends RefCounted
## Only two AP ordinary scenes; native packet equality owns these polygons.
## Not a C-domain alias, not ENV scenery, not a generic blocker bypass.
const FAMILY="res://scripts/city/luoyang_quarters_family_20261022ap.gd"
const FIELD="res://scripts/field/field_walkable_controller.gd"
const SIZE=Vector2(3072,2048)
const NATIVE_ROOT="res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/"
const BUNDLE="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const IDS=[&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"]
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
	return {"ok":true,"node":node}
