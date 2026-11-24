extends RefCounted
## Only two AP ordinary scenes; native packet equality owns these polygons.
## Not a C-domain alias, not ENV scenery, not a generic blocker bypass.
const FAMILY="res://scripts/city/luoyang_quarters_family_20261022ap.gd"
const FIELD="res://scripts/field/field_walkable_controller.gd"
const SIZE=Vector2(3072,2048)
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
	container.add_child(group)
	return {"ok":true,"matched":true,"bodies":bodies,"count":bodies.size(),"rectangles":rectangles,"polygons":polygons}
