extends RefCounted

# Project-authored geometry; not a licensed photogrammetry asset or bitmap edit.
# Six bent canes and tapered leaf ribbons, metric units, rooted at ground Y=0.
static func mesh(variant: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for cane in range(6):
		var angle: float=cane*2.399963+variant*.43
		var root:=Vector3(cos(angle),0,sin(angle))*(.065+.019*cane)
		var height: float=.84+.065*((cane*3+variant)%6)
		var bend:=Vector3(cos(angle+.5),0,sin(angle+.5))*.13
		for section in range(6):
			var t0: float=section/6.
			var t1: float=(section+1)/6.
			var a: Vector3=root+Vector3.UP*height*t0+bend*t0*t0
			var b: Vector3=root+Vector3.UP*height*t1+bend*t1*t1
			var radius: float=.0085*(1.-t0*.45)
			for side in range(5):
				var p0:=Vector3(cos(side*TAU/5.),0,sin(side*TAU/5.))*radius
				var p1:=Vector3(cos((side+1)*TAU/5.),0,sin((side+1)*TAU/5.))*radius
				_quad(st,a+p0,b+p0,b+p1,a+p1,Color(.29,.32,.12))
		for leaf in range(3):
			var t: float=.30+leaf*.19
			var start: Vector3=root+Vector3.UP*height*t+bend*t*t
			var direction:=Vector3(cos(angle+leaf*2.1),.16,sin(angle+leaf*2.1)).normalized()
			var lateral:=direction.cross(Vector3.UP).normalized()
			var length: float=.32+.06*((cane+leaf+variant)%3)
			for section in range(4):
				var t0: float=section/4.
				var t1: float=(section+1)/4.
				var a: Vector3=start+direction*length*t0-Vector3.UP*.12*t0*t0
				var b: Vector3=start+direction*length*t1-Vector3.UP*.12*t1*t1
				var width0: float=sin(t0*PI)*.025+.003*(1.-t0)
				var width1: float=sin(t1*PI)*.025+.003*(1.-t1)
				_quad(st,a-lateral*width0,b-lateral*width1,b+lateral*width1,a+lateral*width0,Color(.27+.025*leaf,.34+.02*leaf,.12))
		if cane%2==0:
			var top: Vector3=root+Vector3.UP*height+bend
			var axis:=Vector3(.014,.12,.014)
			_quad(st,top-axis*Vector3(1,0,1),top+Vector3.UP*.12-axis*Vector3(1,0,1),top+Vector3.UP*.12+axis*Vector3(1,0,1),top+axis*Vector3(1,0,1),Color(.42,.31,.18))
	st.generate_normals()
	var result: ArrayMesh=st.commit()
	var material:=StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.roughness=.94
	result.surface_set_material(0,material)
	return result

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3,color: Color) -> void:
	for p in [a,b,c,a,c,d]:
		st.set_color(color)
		st.set_uv(Vector2(p.x,p.y))
		st.add_vertex(p)
