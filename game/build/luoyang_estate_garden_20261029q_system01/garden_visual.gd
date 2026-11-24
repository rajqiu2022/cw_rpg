extends RefCounted
## One Estate garden's source-bound lawn/path overlay. No navigation changes.
const Core=preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const SELF:="res://build/luoyang_estate_garden_20261029q_system01/garden_visual.gd"
const SPEC:="res://build/luoyang_estate_garden_20261029q_system01/garden_definition_READY.json"
static func handles(region: Dictionary) -> bool:return region.get("id")=="luoyang_estate_region_27d" and region.has("garden29q_visual")
static func _points(raw: Array) -> PackedVector2Array:
	var points:=PackedVector2Array()
	for value: Variant in raw:points.append(Core.vec(value))
	return points
static func _draw(layer: Node,shape: PackedVector2Array,texture: Texture2D,period: Vector2,z: int,alpha: float) -> void:
	var floor:=Polygon2D.new();floor.texture=texture;floor.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
	floor.polygon=shape;floor.modulate=Color(1,1,1,alpha);floor.z_index=z
	var uv:=PackedVector2Array()
	for point: Vector2 in shape:uv.append(point/period*texture.get_size())
	floor.uv=uv;layer.add_child(floor)
static func install(field: Node,owner: RefCounted,region: Dictionary) -> bool:
	if not handles(region) or owner==null or owner.call("matches",field,field.get("_current_scene"))!=true:return false
	if var_to_bytes(owner.get("_compiled"))!=var_to_bytes(region):return false
	var first: Dictionary=owner.call("receipt").get("source_first",{})
	for path: String in [SELF,SPEC]:
		if first.get(path)!=FileAccess.get_sha256(path):return false
	var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SPEC))
	var grass: Dictionary=spec.groundcover
	if first.get(grass.texture)!=FileAccess.get_sha256(grass.texture):return false
	var texture: Texture2D=load(grass.texture) as Texture2D
	var period: Vector2=Core.vec(grass.texture_period_px)
	if texture==null or not period.is_finite() or period.x<=0 or period.y<=0:return false
	var layer: Node=field.get("_visual_layer")
	# Eight inset layers yield a 64px inward alpha feather without making or
	# modifying a raster image. Every layer has identical world UV phase.
	for raw: Array in grass.polygons:
		var outer: PackedVector2Array=_points(raw)
		for i: int in range(8):
			var inset: Array=[outer] if i==0 else Geometry2D.offset_polygon(outer,-8.0*i)
			for shape: PackedVector2Array in inset:_draw(layer,shape,texture,period,-999,1.0/float(8-i))
	for route: Dictionary in spec.garden_routes:
		if first.get(route.texture)!=FileAccess.get_sha256(route.texture):return false
		var paving: Texture2D=load(route.texture) as Texture2D
		var step: Vector2=Core.vec(route.texture_period_px)
		if paving==null or not step.is_finite() or step.x<=0 or step.y<=0:return false
		var points: PackedVector2Array=_points(route.points)
		# Rounded per-segment unions avoid filled holes on a closed pond circuit;
		# overlap is visually exact because all segments sample the same world UV.
		for i: int in range(1,points.size()):
			if points[i]==points[i-1]:continue
			var line:=PackedVector2Array([points[i-1],points[i]])
			for shape: PackedVector2Array in Geometry2D.offset_polyline(line,float(route.width_px)*.5,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND):_draw(layer,shape,paving,step,-998,1.0)
	return true
