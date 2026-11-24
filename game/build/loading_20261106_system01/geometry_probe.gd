extends SceneTree
const HOME := "res://build/loading_20261106_system01/"
const OLD = preload("res://build/city_navigation_20261101d_candidate01/navigation_geometry.gd")
const NEW = preload("res://build/loading_20261106_system01/geometry_candidate.gd")
const PAIRS = preload("res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd")
const MOUTH = preload("res://build/city_navigation_20261101d_candidate01/mouth_visual.gd")
var suspended := false
var failures: Array[String] = []
var rows: Array[Dictionary] = []
var checks := 0
func _initialize() -> void:
	root.child_entered_tree.connect(func(node: Node) -> void:
		if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
			node.call("set_checkpoint_saves_suspended",true)
			suspended = bool(node.call("is_checkpoint_saves_suspended")))
	_run.call_deferred()
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)
func extent(geo: GDScript,id: String,origin: Vector2,direction: Vector2,distance: int) -> Vector2:
	var last := origin
	for i: int in range(1,distance+1):
		var next := origin+direction*float(i)
		if not geo.call("safe_static",id,next): break
		last=next
	return last
func road(geo: GDScript,e: Dictionary) -> Dictionary:
	var id: String=e.scene_id
	var a:=extent(geo,id,e.arrival,-e.outward,180)
	var b:=extent(geo,id,e.mouth,e.outward,320)
	var side:=Vector2(-e.outward.y,e.outward.x)
	var half: float=MOUTH._planned_half(e)
	var safe_band:=false
	while half>=20.0:
		if geo.call("safe_segment",id,a-side*half,b-side*half) and geo.call("safe_segment",id,a,b) and geo.call("safe_segment",id,a+side*half,b+side*half):
			safe_band=true;break
		half-=8.0
	return {"a":a,"b":b,"half":half,"safe_band":safe_band}
func _run() -> void:
	await process_frame
	check(suspended,"EARLY_SAVE_SUSPENDED")
	var begin:=Time.get_ticks_usec()
	check(OLD.load_fixed(),"ORIGINAL_FIXED_SOURCES_AND_MASK_RGBA")
	rows.append({"phase":"load_fixed","ms":(Time.get_ticks_usec()-begin)/1000.0})
	var id: String="luoyang_artisan_residential_20261022ap"
	for e: Dictionary in PAIRS.endpoints(id):
		begin=Time.get_ticks_usec()
		var before:=road(OLD,e)
		var before_ms: float=(Time.get_ticks_usec()-begin)/1000.0
		begin=Time.get_ticks_usec()
		var after:=road(NEW,e)
		var after_ms: float=(Time.get_ticks_usec()-begin)/1000.0
		check(before==after,"EXACT_MOUTH:"+e.id)
		rows.append({"phase":"original_class_road_geometry","id":e.id,"before_ms":before_ms,"after_ms":after_ms,"before":before,"after":after})
	# Boundary-heavy differential samples: every authored solid vertex and touching
	# full-body boundary, plus fixed random points. No approximate acceptance.
	var points: Array[Vector2]=[]
	for poly: PackedVector2Array in OLD._legacy[id].effective_solids:
		for point: Vector2 in poly:
			for offset: Vector2 in [Vector2.ZERO,Vector2(17,0),Vector2(-17,0),Vector2(0,12),Vector2(0,-12),Vector2(17.001,0),Vector2(16.999,0)]: points.append(point+offset)
	var random:=RandomNumberGenerator.new();random.seed=61106
	for i: int in range(100): points.append(Vector2(random.randf_range(20,3050),random.randf_range(20,2020)))
	begin=Time.get_ticks_usec()
	for point: Vector2 in points:
		check(OLD.safe_static(id,point)==NEW.safe_static(id,point),"POINT:"+str(point))
	rows.append({"phase":"differential_boundaries","points":points.size(),"ms":(Time.get_ticks_usec()-begin)/1000.0})
	var result: Dictionary={"passed":failures.is_empty(),"checks":checks,"failures":failures,"rows":rows,"real_save_contents_accessed":false,"formal_source_writes":false,"scope":"GEOMETRY_ONLY_NOT_REAL_PAIR_PERFORMANCE"}
	var output:=HOME+"actual/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(output)
	var file:=FileAccess.open(output+"/geometry_result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t")+"\n");file.close()
	print("GEOMETRY_RESULT ",checks,"/",failures.size()," ",output)
	quit(0 if failures.is_empty() else 1)
