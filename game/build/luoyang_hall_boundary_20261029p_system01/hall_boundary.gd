extends RefCounted
## Exact-room presentation only. Compiled floors/solids/NPCs/portals stay frozen.
const ID:="estate27d_living_hall"
const SELF:="res://build/luoyang_hall_boundary_20261029p_system01/hall_boundary.gd"
const PATCH:="res://build/luoyang_hall_boundary_20261029p_system01/room_patch.gdshader"
const SHELL:="res://art/modules/luoyang_assembled_interiors_20261016g/shell_formal_hall_v1.png"
const FLOOR_PATCH:=Rect2(600,780,280,120)
const WALL_PATCH:=Rect2(650,210,250,100)
const CAP_PATCH:=Rect2(650,180,250,14)
const NORTH_HEIGHT:=224.0
const FRONT_HEIGHT:=128.0
static func handles(region: Dictionary) -> bool:return region.get("id")==ID
static func _valid(field: Node,owner: RefCounted,region: Dictionary) -> bool:
	if not handles(region) or region.get("size")!=Vector2(1920,1440) or owner==null:return false
	if owner.call("matches",field,field.get("_current_scene"))!=true:return false
	if var_to_bytes(owner.get("_compiled"))!=var_to_bytes(region):return false
	var first: Dictionary=owner.call("receipt").get("source_first",{})
	for path: String in [SELF,PATCH,SHELL]:
		if first.get(path)!=FileAccess.get_sha256(path):return false
	return true
static func _quad(area: Rect2) -> PackedVector2Array:
	return PackedVector2Array([area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)])
static func _patch(parent: Node,polygon: PackedVector2Array,sample: Rect2,z: int,name: String) -> bool:
	var texture: Texture2D=load(SHELL) as Texture2D
	var shader: Shader=load(PATCH) as Shader
	if texture==null or texture.get_size()!=Vector2(1536,1024) or shader==null:return false
	var material:=ShaderMaterial.new();material.shader=shader
	material.set_shader_parameter("patch_origin_px",sample.position)
	material.set_shader_parameter("patch_size_px",sample.size)
	material.set_shader_parameter("source_size_px",texture.get_size())
	var node:=Polygon2D.new();node.name=name;node.texture=texture
	node.polygon=polygon;node.uv=polygon.duplicate();node.material=material;node.z_index=z
	parent.add_child(node)
	return true
static func floor(field: Node,owner: RefCounted,region: Dictionary) -> bool:
	if not _valid(field,owner,region):return false
	var layer: Node=field.get("_visual_layer")
	# Camera-visible bounds include the north wall's full height. This bleed is
	# decorative backing only, never positive walking floor or map bounds.
	if not _patch(layer,_quad(Rect2(0,-128,1920,1568).grow(512)),WALL_PATCH,-1200,"Hall29pOpaqueVisualBacking"):return false
	if not _patch(layer,_quad(Rect2(128,128,1664,1184)),FLOOR_PATCH,-1000,"Hall29pInteriorStoneFloor"):return false
	if not _patch(layer,_quad(Rect2(880,-128,160,256)),FLOOR_PATCH,-999,"Hall29pNorthDoorFloor"):return false
	return _patch(layer,_quad(Rect2(880,1312,160,128)),FLOOR_PATCH,-999,"Hall29pSouthDoorFloor")
static func enclosure(field: Node,owner: RefCounted,region: Dictionary) -> bool:
	if not _valid(field,owner,region):return false
	var bases: Array=region.get("room_enclosure",{}).get("wall_ground_polygons_px",[])
	if bases.size()!=6:return false
	var layer: Node=field.get("_visual_layer")
	for i: int in range(bases.size()):
		var base:=PackedVector2Array()
		for point: Variant in bases[i]:
			if not point is Array or point.size()!=2:return false
			base.append(Vector2(float(point[0]),float(point[1])))
		if base.size()!=4:return false
		var edge_a: Vector2
		var edge_b: Vector2
		var offset: Vector2
		var z: int
		if i in [0,1]:
			edge_a=base[3];edge_b=base[2];offset=Vector2(0,-NORTH_HEIGHT);z=20
		elif i==2:
			# The whole INNER vertical edge, not its 32px south end.
			edge_a=base[1];edge_b=base[2];offset=Vector2(-96,-NORTH_HEIGHT);z=240
		elif i==3:
			edge_a=base[0];edge_b=base[3];offset=Vector2(96,-NORTH_HEIGHT);z=240
		else:
			edge_a=base[3];edge_b=base[2];offset=Vector2(0,-FRONT_HEIGHT);z=240
		var face:=PackedVector2Array([edge_a,edge_b,edge_b+offset,edge_a+offset])
		if not _patch(layer,face,WALL_PATCH,z,"Hall29pWallFace"+str(i)):return false
		var cap:=PackedVector2Array()
		for point: Vector2 in base:cap.append(point+offset)
		if not _patch(layer,cap,CAP_PATCH,z+1,"Hall29pWallCap"+str(i)):return false
	return true
static func camera(field: Node,owner: RefCounted,region: Dictionary,current: Camera2D) -> bool:
	if not _valid(field,owner,region) or not is_instance_valid(current) or current.get_parent()!=field.get("_player") or current.zoom!=Vector2.ONE:return false
	if current.limit_left!=0 or current.limit_right!=1920 or current.limit_bottom!=1440:return false
	current.limit_top=-128
	current.reset_smoothing();current.force_update_scroll()
	return true
