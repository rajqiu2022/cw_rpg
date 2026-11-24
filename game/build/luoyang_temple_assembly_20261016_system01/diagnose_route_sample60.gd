extends SceneTree
## One exact failed native sample; no publication or gameplay mutation.
const T=preload("res://scripts/city/luoyang_temple_assembly_20261016.gd")
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var author: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/luoyang_temple_assembly_20261016/author.json"))
	var size:=Vector2(1920,1280)
	var geometry: Dictionary=T.GEOMETRY.compile_geometry(author.geometry,size)
	var a: Vector2=T._v([768,430])*size/T.SOURCE_SIZE
	var b: Vector2=T._v([1210,430])*size/T.SOURCE_SIZE
	var steps: int=maxi(1,ceili(a.distance_to(b)/4.0))
	var foot: Vector2=a.lerp(b,60.0/steps)
	var body:=PackedVector2Array([foot+Vector2(-17,-12),foot+Vector2(17,-12),foot+Vector2(17,12),foot+Vector2(-17,12)])
	var floors: Array=[]; var solids: Array=[]; var failed_pixel: Dictionary={}; var perimeter: Array=[]
	for region: PackedVector2Array in geometry._compiled.world_floors:
		floors.append({"outside":Geometry2D.clip_polygons(body,region),"body":body,"floor":region})
	for i: int in geometry._compiled.world_solids.size():
		var hit: Array=Geometry2D.intersect_polygons(body,geometry._compiled.world_solids[i])
		if not hit.is_empty(): solids.append({"id":author.geometry.furniture_bases[i].id,"intersection":hit})
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			var point: Vector2=(foot+Vector2(x,y))/(size/T.SOURCE_SIZE)
			if failed_pixel.is_empty() and not T.GEOMETRY._point_clear(geometry,point): failed_pixel={"offset":[x,y],"source_point":point}
	for offset: Vector2 in [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]:
		if not T.GEOMETRY._point_clear(geometry,(foot+offset)/(size/T.SOURCE_SIZE)): perimeter.append(offset)
	print(JSON.stringify({"author_sha256":FileAccess.get_sha256("res://data/maps/luoyang_temple_assembly_20261016/author.json"),"steps":steps,"foot":foot,"safe_foot":T.safe_foot(geometry,foot,size,true),"floors":floors,"solid_hits":solids,"first_bad_875":failed_pixel,"bad17":perimeter,"diagnosis_only":true},"\t",true,true))
	quit(0)
