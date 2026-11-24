extends RefCounted
## Actual-foot canvas geography. Never consume the design PNG as terrain.
const VERSION := 16
const WORLD_SIZE := Vector2(12288,8192)
const GRID_SIZE := Vector2i(1537,1025)
const GRID_STEP := 8.0
const PPM := 102.4
const Z_PPM := 72.4077343935025
const WATER_Y := -0.025
const DOMAIN := Rect2(10400,2100,1888,2160)
const HALO := 192.0
const SHORE_WIDTH := 64.0
const SEA_DEPTH := 1.6

static func outer_bay() -> PackedVector2Array:
	return PackedVector2Array([Vector2(10900,2290),Vector2(11550,2240),Vector2(12288,2340),Vector2(12288,4120),Vector2(11680,4120),Vector2(10920,3960),Vector2(10680,3490),Vector2(10640,2860)])

static func island() -> PackedVector2Array:
	return PackedVector2Array([Vector2(11350,2710),Vector2(11700,2610),Vector2(12020,2790),Vector2(12110,3100),Vector2(12110,3480),Vector2(11930,3700),Vector2(11520,3740),Vector2(11250,3540),Vector2(11170,3180)])

static func signed_inside(p: Vector2,polygon: PackedVector2Array) -> float:
	var distance:=INF
	for i: int in polygon.size():
		var a: Vector2=polygon[i];var b: Vector2=polygon[(i+1)%polygon.size()]
		var v: Vector2=b-a
		distance=minf(distance,p.distance_to(a+v*clampf((p-a).dot(v)/maxf(v.length_squared(),.00001),0,1)))
	return distance if Geometry2D.is_point_in_polygon(p,polygon) else -distance

static func sea_distance(canvas_foot: Vector2) -> float:
	return minf(signed_inside(canvas_foot,outer_bay()),-signed_inside(canvas_foot,island()))

static func is_sea(canvas_foot: Vector2) -> bool:return sea_distance(canvas_foot)>0.0

static func water_canvas(source: Vector2) -> Vector2:
	# The fixed old camera projects (sourceX,sourceY,height) to this canvas.
	# Coastline intersection has height=WATER_Y, not an arbitrary XZ/UV alias.
	return Vector2(source.x,source.y-WATER_Y*Z_PPM)

static func derive(old: PackedFloat32Array) -> Dictionary:
	if old.size()!=GRID_SIZE.x*GRID_SIZE.y:return {"ok":false,"error":"RF_GRID_SIZE"}
	var heights: PackedFloat32Array=old.duplicate();var changed:=0
	for y: int in range(GRID_SIZE.y):
		for x: int in range(GRID_SIZE.x):
			var p:=Vector2(x,y)*GRID_STEP
			if not DOMAIN.has_point(water_canvas(p)):continue
			var weight: float=smoothstep(0,SHORE_WIDTH,sea_distance(water_canvas(p)))
			var index: int=y*GRID_SIZE.x+x
			if not is_finite(old[index]):return {"ok":false,"error":"NONFINITE_OLD_RF"}
			if weight<=0:continue
			# Cut only. No old sea or rejected ground can become new land.
			heights[index]=minf(old[index],lerpf(old[index],WATER_Y-SEA_DEPTH,weight))
			if heights[index]!=old[index]:changed+=1
	return {"ok":changed>0,"heights":heights,"changed_vertices":changed,"new_land_opened":false}

static func height_at(heights: PackedFloat32Array,p: Vector2) -> float:
	var q: Vector2=p.clamp(Vector2.ZERO,WORLD_SIZE)/GRID_STEP
	var cell:=Vector2i(mini(floori(q.x),GRID_SIZE.x-2),mini(floori(q.y),GRID_SIZE.y-2))
	var f: Vector2=q-Vector2(cell);var index: int=cell.y*GRID_SIZE.x+cell.x
	var a: float=heights[index];var b: float=heights[index+1]
	var c: float=heights[index+GRID_SIZE.x];var d: float=heights[index+GRID_SIZE.x+1]
	return a+(b-a)*f.x+(c-a)*f.y if f.x+f.y<=1 else d+(c-d)*(1-f.x)+(b-d)*(1-f.y)

static func point3(source: Vector2,height: float) -> Vector3:
	return Vector3((source.x-WORLD_SIZE.x*.5)/PPM,height,(source.y-WORLD_SIZE.y*.5)/Z_PPM)

static func patch_mesh(heights: PackedFloat32Array,rect: Rect2) -> ArrayMesh:
	var first:=Vector2i((rect.position/GRID_STEP).floor()).max(Vector2i.ZERO)
	var last:=Vector2i((rect.end/GRID_STEP).ceil()).min(GRID_SIZE-Vector2i.ONE)
	var width: int=last.x-first.x+1;var rows: int=last.y-first.y+1
	var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var uv:=PackedVector2Array();var indices:=PackedInt32Array()
	for y: int in rows:
		for x: int in width:
			var p:=Vector2(first+Vector2i(x,y))*GRID_STEP;var h: float=height_at(heights,p)
			vertices.append(point3(p,h));uv.append(p/WORLD_SIZE)
			var dx: float=(height_at(heights,p+Vector2(8,0))-height_at(heights,p-Vector2(8,0)))*PPM/16
			var dz: float=(height_at(heights,p+Vector2(0,8))-height_at(heights,p-Vector2(0,8)))*Z_PPM/16
			normals.append(Vector3(-dx,1,-dz).normalized())
	for y: int in rows-1:
		for x: int in width-1:
			var a: int=y*width+x
			indices.append_array(PackedInt32Array([a,a+1,a+width,a+1,a+width+1,a+width]))
	var arrays: Array=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);return mesh

static func migration_regions() -> Array[Dictionary]:
	# Fixed historical destination by declared side, not a nearest-safe search.
	# The caller must first prove old15 legal and new16 unsafe. The safe island
	# interior and every unchanged legal foot therefore remain exactly in place.
	return [{"id":"east_bay_mainland_cut","source_polygon_px":[[10400,2100],[11200,2100],[11200,4260],[10400,4260]],"source_x_range":[10400,11200],"historic_portal_id":"bailu_ferry"},{"id":"east_bay_island_cut","source_polygon_px":[[11200,2100],[12288,2100],[12288,4260],[11200,4260]],"source_x_range":[11200,12288],"historic_portal_id":"east_sea_port"}]
