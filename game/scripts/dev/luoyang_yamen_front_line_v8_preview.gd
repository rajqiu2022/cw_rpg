extends "res://scripts/dev/luoyang_yamen_gate_join_native_v7_preview.gd"

## V8 topology only. Reuse frozen V7 material/geometry helpers, not its
## build(): no pier, end-wrap, coping, return wall or branch is authored.
const V7_PIN := "2b711b1a8af12517f0abc3838fba1255bd1e08ad568e2fdd65f441e97ca26371"
const FRONT_ORIGIN := Vector2(1050.5,1347.5)
const FRONT_SCALE := .5
const FRONT_LEFT := 260.
const FRONT_RIGHT := 1680.
# Explicit T-shaped source-UV domain, safely INSIDE the straight front wall.
# The two original return walls lie outside x260..1680. Above y340 only the
# central gate roof is selected; no whole-PNG blend or cover-up is performed.
const FRONT_UV_POINTS := [Vector2(260,340),Vector2(600,340),Vector2(600,0),Vector2(1340,0),Vector2(1340,340),Vector2(1680,340),Vector2(1680,809),Vector2(260,809)]
const PPU_Y := 55.4256258422
const BASE_Y := 1689.5 # Original brick-foot source y684 at original .5 scale.
const WALL_SCALE_Y := (117.-.16)/(PPU_Y*2.015)
# Fit original y436 eave and y355 ridge, not a colour/material iteration.
const ROOF_DEPTH_SCALE := (40.5-PPU_Y*.385)/27.2
const ROOF_LIFT := (124.+32.*ROOF_DEPTH_SCALE*.34)/PPU_Y-2.145

func prepare() -> bool:
	if FileAccess.get_sha256("res://scripts/dev/luoyang_yamen_gate_join_native_v7_preview.gd").to_lower() != V7_PIN:
		error = "Frozen V7 material/geometry helper changed."
		return false
	return super.prepare()

func span(side: String) -> Vector2:
	return Vector2(960.,FRONT_ORIGIN.x+FRONT_LEFT*.5) if side == "left" else Vector2(FRONT_ORIGIN.x+FRONT_RIGHT*.5,2110.)

func placement(side: String) -> Transform3D:
	var limits: Vector2 = span(side)
	return Transform3D(Basis.IDENTITY,Vector3(((limits.x+limits.y)*.5-1536.)/64.,0.,(BASE_Y-1024.)/32.-.71))

func build(side: String) -> ArrayMesh:
	if side not in ["left","right"] or materials.is_empty():
		error = "Explicit prepared V8 straight-wing side required."
		return null
	buckets.clear()
	counts = {"brick_blocks":0,"barrel_tiles":0,"pan_tiles":0,"tile_end_rims":0,"plaster_faces":0,"crack_paths":0,"end_piers":0,"return_walls":0}
	_box(Vector3(5.,2.05,.96),Vector3(0,1.025,.20),"mortar")
	_courses(-2.5,2.5,0.,.50,.20,1.02,3,.52)
	_courses(-2.5,2.5,.50,2.05,.20,.98,10,.46)
	_plaster(side)
	_box(Vector3(5.10,.075,1.09),Vector3(0,2.055,.20),"brick")
	_box(Vector3(5.15,.055,1.16),Vector3(0,2.12,.20),"mortar")
	_roof(-2.5,2.5,.20)
	var limits: Vector2 = span(side)
	var scale_x: float = (limits.y-limits.x)/320.
	var mesh := ArrayMesh.new()
	for role: String in buckets:
		var bucket: Dictionary = buckets[role]
		var vertices: PackedVector3Array = bucket["v"].duplicate()
		var normals: PackedVector3Array = bucket["n"].duplicate()
		var roof: bool = role in ["tile","tile_rim"]
		var sy: float = 1. if roof else WALL_SCALE_Y
		var sz: float = ROOF_DEPTH_SCALE if roof else 1.
		for i in range(vertices.size()):
			var p: Vector3 = vertices[i]
			p.x *= scale_x
			if roof:
				p.y += ROOF_LIFT
				p.z = .71+(p.z-.71)*sz
			else:
				p.y *= sy
			vertices[i] = p
			var n: Vector3 = normals[i]
			normals[i] = Vector3(n.x/scale_x,n.y/sy,n.z/sz).normalized()
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = bucket["uv"].duplicate()
		arrays[Mesh.ARRAY_INDEX] = bucket["i"].duplicate()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		mesh.surface_set_name(mesh.get_surface_count()-1,role)
		var material: ShaderMaterial = materials[role].duplicate() as ShaderMaterial
		if role == "plaster" and side == "right":
			var rect: Rect2i = SOURCE_PATCHES["plaster_right"]
			material.set_shader_parameter("project_patch_px",Vector4(rect.position.x,rect.position.y,rect.size.x,rect.size.y))
		mesh.surface_set_material(mesh.get_surface_count()-1,material)
	return mesh

func _roof_y(_x: float,z: float,center_z: float) -> float:
	return 2.42-absf(z-center_z)*.34

func _roof(x0: float,x1: float,center_z: float) -> void:
	# Same V7 roof construction/material, with seam-ending edge tiles rather
	# than a gap at the selected carrier cut plane. No rearward wall segment.
	var columns: int = int(ceil((x1-x0)/.205))
	var pitch: float = (x1-x0)/columns
	for wing in [-1.,1.]:
		for course in range(3):
			var near: float = center_z+wing*course*.265
			var far: float = center_z+wing*minf((course+1)*.265+.055,.85)
			for column in range(columns):
				var x: float = x0+(column+.5)*pitch
				_tile(x0 if column == 0 else x-.059,x1 if column == columns-1 else x+.059,near,far,center_z,true)
				counts["barrel_tiles"] += 1
				if column < columns-1:
					_tile(x+.054,x+pitch-.054,near,far,center_z,false)
					counts["pan_tiles"] += 1
				if course == 2:
					_rim(x,far,center_z,wing)
					counts["tile_end_rims"] += 1
	for section in range(12):
		var lo: float = x0+(x1-x0)*section/12.
		var hi: float = x0+(x1-x0)*(section+1)/12.-.008
		for arc in range(8):
			var a: float = PI*arc/8.
			var b: float = PI*(arc+1)/8.
			_quad_uv(Vector3(lo,2.455+sin(a)*.075,center_z+cos(a)*.075),Vector3(hi,2.455+sin(a)*.075,center_z+cos(a)*.075),Vector3(hi,2.455+sin(b)*.075,center_z+cos(b)*.075),Vector3(lo,2.455+sin(b)*.075,center_z+cos(b)*.075),Vector3(0,sin((a+b)*.5),cos((a+b)*.5)),"tile_rim",Vector2(0,arc/8.),Vector2(1,arc/8.),Vector2(1,(arc+1)/8.),Vector2(0,(arc+1)/8.))

func witnesses(side: String) -> Array[Dictionary]:
	var limits: Vector2 = span(side)
	var x: float = (limits.y-limits.x)/128.*(1. if side == "left" else -1.)
	var sx: float = FRONT_LEFT if side == "left" else FRONT_RIGHT
	return [
		{"name":"brick_foot","role":"brick","source":Vector2(sx,684),"target":Vector3(x,0,.71)},
		{"name":"wall_top","role":"plaster","source":Vector2(sx,450),"target":Vector3(x,2.015*WALL_SCALE_Y,.705)},
		{"name":"eave","role":"tile","source":Vector2(sx,436),"target":Vector3(x,2.145+ROOF_LIFT,.71+.34*ROOF_DEPTH_SCALE)},
		{"name":"ridge","role":"tile_rim","source":Vector2(sx,355),"target":Vector3(x,2.53+ROOF_LIFT,.71-.51*ROOF_DEPTH_SCALE)}
	]
