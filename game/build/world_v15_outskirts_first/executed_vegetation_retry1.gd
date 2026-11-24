extends RefCounted

# Honest project-native plant geometry: segmented bent culms and lance leaves.
# These are NOT claimed to be PolyHaven or photogrammetry.
static func material(color: Color) -> StandardMaterial3D:
	var value:=StandardMaterial3D.new()
	value.albedo_color=color
	value.roughness=.87
	value.cull_mode=BaseMaterial3D.CULL_DISABLED
	return value

static func tube(tool: SurfaceTool,points: PackedVector3Array,radius: float,sides: int=7) -> void:
	for i in range(points.size()-1):
		var forward: Vector3=(points[i+1]-points[i]).normalized()
		var x: Vector3=forward.cross(Vector3.FORWARD).normalized()
		var z: Vector3=forward.cross(x).normalized()
		for j in range(sides):
			var a: Vector3=x*cos(TAU*j/sides)*radius+z*sin(TAU*j/sides)*radius
			var b: Vector3=x*cos(TAU*(j+1)/sides)*radius+z*sin(TAU*(j+1)/sides)*radius
			for vertex in [points[i]+a,points[i+1]+a,points[i]+b,points[i]+b,points[i+1]+a,points[i+1]+b]: tool.add_vertex(vertex)

static func leaf(tool: SurfaceTool,start: Vector3,direction: Vector3,length: float,width: float,drop: float) -> void:
	var sideways: Vector3=direction.cross(Vector3.UP).normalized()
	if sideways.length_squared()<.01: sideways=Vector3.RIGHT
	var left:=PackedVector3Array()
	var right:=PackedVector3Array()
	for i in range(7):
		var t: float=i/6.
		var center: Vector3=start+direction*length*t+Vector3(0,-drop*t*t,0)
		var breadth: float=sin(PI*t)*width
		left.append(center-sideways*breadth)
		right.append(center+sideways*breadth)
	for i in range(6):
		for p in [left[i],right[i],left[i+1],right[i],right[i+1],left[i+1]]: tool.add_vertex(p)

static func plant(kind: String,variant: int=0) -> ArrayMesh:
	var result:=ArrayMesh.new()
	var stem:=SurfaceTool.new()
	var foliage:=SurfaceTool.new()
	stem.begin(Mesh.PRIMITIVE_TRIANGLES)
	foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bamboo: bool=kind=="bamboo"
	var count: int=4 if bamboo else 9
	for i in range(count):
		var angle: float=i*2.399963+variant*.4
		var base:=Vector3(cos(angle)*.055,0,sin(angle)*.055)
		var high: float=(2.1+i*.19+variant*.12) if bamboo else (.62+(i%4)*.13)
		var drift:=Vector3(cos(angle)*.13,0,sin(angle)*.13)
		var points:=PackedVector3Array()
		for n in range(13):
			var t: float=n/12.
			points.append(base+Vector3(0,high*t,0)+drift*t*t)
		tube(stem,points,.017 if bamboo else .0035)
		if bamboo:
			# Culm nodes are discrete native collars, not a plain straight cylinder.
			for n in range(1,12):
				tube(stem,PackedVector3Array([points[n]-Vector3(0,.004,0),points[n]+Vector3(0,.004,0)]),.022,9)
			for n in range(3,11):
				var root: Vector3=points[n]
				var branch_dir:=Vector3(cos(angle+n*1.8),.16,sin(angle+n*1.8)).normalized()
				var end: Vector3=root+branch_dir*(.28+(n%3)*.1)
				tube(stem,PackedVector3Array([root,end]),.004)
				for j in range(9):
					var side: float=-1. if j%2==0 else 1.
					var dir: Vector3=(branch_dir+branch_dir.cross(Vector3.UP)*side*.65+Vector3(0,.1,0)).normalized()
					leaf(foliage,root.lerp(end,(j+1)/10.),dir,.16+(j%3)*.035,.016,.055)
		else:
			for n in range(3):
				var dir:=Vector3(cos(angle+n*2.),.30,sin(angle+n*2.)).normalized()
				leaf(foliage,points[4+n*2],dir,.30+n*.08,.018,.22)
			# Bent seed head uses real short tube geometry rather than one capsule.
			tube(stem,PackedVector3Array([points[-1],points[-1]+Vector3(.01,.085,.016),points[-1]+Vector3(.025,.16,.025)]),.01)
	stem.generate_normals()
	foliage.generate_normals()
	stem.commit(result)
	foliage.commit(result)
	result.surface_set_material(0,material(Color(.22,.31,.10) if bamboo else Color(.37,.31,.15)))
	result.surface_set_material(1,material(Color(.19,.30,.075) if bamboo else Color(.30,.37,.12)))
	return result

static func waymarker() -> ArrayMesh:
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var box:=BoxMesh.new()
	box.size=Vector3(.08,.75,.08)
	tool.append_from(box,0,Transform3D(Basis.IDENTITY,Vector3(0,.375,0)))
	box=BoxMesh.new()
	box.size=Vector3(.42,.16,.035)
	tool.append_from(box,0,Transform3D(Basis.IDENTITY,Vector3(.08,.57,0)))
	var mesh: ArrayMesh=tool.commit()
	mesh.surface_set_material(0,material(Color(.31,.22,.13)))
	return mesh

static func discovery() -> ArrayMesh:
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base:=BoxMesh.new()
	base.size=Vector3(.30,.17,.20)
	tool.append_from(base,0,Transform3D(Basis.IDENTITY,Vector3(0,.085,0)))
	var plank:=BoxMesh.new()
	plank.size=Vector3(.33,.022,.22)
	tool.append_from(plank,0,Transform3D(Basis.IDENTITY,Vector3(0,.18,0)))
	var mesh: ArrayMesh=tool.commit()
	mesh.surface_set_material(0,material(Color(.32,.25,.15)))
	return mesh
