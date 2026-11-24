extends RefCounted
## Current complete-v7 normal Field ONLY. Every runtime visual ID is checked;
## finite station failure is INCONCLUSIVE/FAIL, never an absence certificate.
## Actor motion, facing, late ordering and ghost are ordinary node stages.
const ALPHA := preload("res://tests/helpers/v15_geometry_oracle.gd")
const SIZE := Vector2(12288,8192)
const ROOT := "res://art/maps/world_map_v15_complete_v7/"
var phase: RefCounted
var tree: SceneTree
var field: Node
var driver: RefCounted
var raw: RefCounted
var alpha: RefCounted=ALPHA.new()
var checks: int=0
var failures: int=0
var records: Array[Dictionary]=[]
var entries: Dictionary={}
var props: Dictionary={}

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures+=1
	phase.call("_check",ok,"all-world current object: "+label)
	return ok

func _p(v: Variant) -> Vector2:
	if v is Vector2: return v
	if v is Array and v.size()==2: return Vector2(float(v[0]),float(v[1]))
	return Vector2(INF,INF)

func _rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])

func _physical_inventory(entry: Dictionary,sprite: Sprite2D) -> Dictionary:
	var container: Node2D=field.get("world_container") as Node2D
	var expected: Array[PackedVector2Array]=[]
	if entry.has("solid_polygons_px"):
		for polygon: PackedVector2Array in entry.solid_polygons_px: expected.append(polygon)
	elif entry.has("collision_size"):
		var center: Vector2=(_p(entry.pos)+_p(entry.get("collision_offset",Vector2.ZERO)))*SIZE
		var size: Vector2=_p(entry.collision_size)*SIZE
		if size.x>0 and size.y>0: expected.append(_rect_polygon(Rect2(center-size*.5,size)))
	var id: String=String(entry.id)
	var bodies: Array[StaticBody2D]=[]
	for child: Node in (field.get("_collision_layer") as Node).get_children():
		if child is StaticBody2D and String(child.name)=="ObjectCollision_"+id: bodies.append(child)
	var actual: Array[PackedVector2Array]=[]
	var rows: Array[Dictionary]=[]
	for body: StaticBody2D in bodies:
		_check(body.collision_layer==1 and body.collision_mask==0,"object real static body layers: "+id)
		for shape: Node in body.get_children():
			var polygon:=PackedVector2Array()
			if shape is CollisionPolygon2D and not shape.disabled:
				for vertex: Vector2 in shape.polygon: polygon.append(container.to_local(shape.to_global(vertex)))
			elif shape is CollisionShape2D and not shape.disabled and shape.shape is RectangleShape2D:
				for vertex: Vector2 in _rect_polygon(Rect2(-shape.shape.size*.5,shape.shape.size)): polygon.append(container.to_local(shape.to_global(vertex)))
			else:
				_check(false,"unexpected or disabled declared world physical shape: "+id)
				continue
			actual.append(polygon)
			var points: Array=[]
			for vertex: Vector2 in polygon: points.append([vertex.x,vertex.y])
			rows.append({"path":str(shape.get_path()),"rid":body.get_rid().get_id(),"points_px":points})
	var equal: bool=actual.size()==expected.size() and bodies.size()==(1 if not expected.is_empty() else 0)
	# Shape vertices reconstructed through actual Float32 parent transforms;
	# .01px is existing source/runtime spatial budget, not footprint shrink.
	for index in mini(actual.size(),expected.size()):
		equal=equal and actual[index].size()==expected[index].size()
		for vertex in mini(actual[index].size(),expected[index].size()): equal=equal and actual[index][vertex].distance_to(expected[index][vertex])<.01
	_check(equal,"source full footprint equals actual polygon/rectangle geometry with own world parent transform: "+id)
	return {"blocking":not expected.is_empty(),"exact_binding":equal,"source_polygons":expected,"actual_shapes":rows,"sprite_global_position":[sprite.global_position.x,sprite.global_position.y]}

func _clear(p: Vector2) -> bool:
	return bool(raw.call("clear",p)) and bool(phase.call("_physical_clear",p))

func _segment(a: Vector2,b: Vector2) -> Dictionary:
	var count: int=maxi(1,ceili(a.distance_to(b)/4))
	for i in range(count+1):
		var at: Vector2=a.lerp(b,float(i)/count)
		if not _clear(at): return {"clear":false,"point":[at.x,at.y],"raw":raw.call("foot_evidence",at),"physical_clear":phase.call("_physical_clear",at)}
	return {"clear":true,"centers":count+1,"max_step_px":a.distance_to(b)/count}

func _move(target: Vector2) -> Dictionary:
	var player: Node2D=field.get("_player") as Node2D
	var path: PackedVector2Array=driver.call("plan",player.position,target,SIZE,_clear,_segment)
	if path.size()<2: return {"ok":false,"reason":"NO_FULL17_PHYSICAL_PATH","target":[target.x,target.y]}
	return await driver.call("follow",field,path,_clear,_segment)

func _collision_trial(id: String,geometry: Dictionary) -> Dictionary:
	var polygons: Array=geometry.source_polygons
	var bound:=Rect2()
	var initialized: bool=false
	for polygon: PackedVector2Array in polygons:
		for p: Vector2 in polygon:
			if not initialized: bound=Rect2(p,Vector2.ZERO); initialized=true
			else: bound=bound.expand(p)
	var origins: Array[Vector2]=[]
	var cores: Array[Vector2]=[]
	for polygon: PackedVector2Array in polygons:
		var triangles: PackedInt32Array=Geometry2D.triangulate_polygon(polygon)
		for n in range(0,triangles.size(),3):
			var center: Vector2=(polygon[triangles[n]]+polygon[triangles[n+1]]+polygon[triangles[n+2]])/3
			if Geometry2D.is_point_in_polygon(center,polygon) and not _clear(center): cores.append(center)
	for direction: Vector2 in [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]:
		var edge: Vector2=bound.get_center()+direction*(bound.size*.5+Vector2(32,24))
		if _clear(edge): origins.append(edge)
	var record: Dictionary={"scope":"ACTUAL_FRONT_STOP_AND_LEGAL_ALTERNATE_INPUT_NOT_ALL_FOUR_IMPOSSIBLE_SIDES","stop":{},"bypass":{}}
	for start: Vector2 in origins:
		var approach: Dictionary=await _move(start)
		if not bool(approach.get("ok",false)): continue
		if cores.is_empty(): break
		var target: Vector2=cores[0]
		for core: Vector2 in cores:
			if core.distance_to(start)<target.distance_to(start): target=core
		var raw_denied: Dictionary=raw.call("foot_evidence",target)
		if bool(raw_denied.get("clear",true)) or bool(phase.call("_physical_clear",target)): continue
		var drive: Dictionary=await driver.call("drive",field,target,_clear)
		await driver.call("completed_actor_stage")
		var player: Node2D=field.get("_player") as Node2D
		var stopped: bool=not bool(drive.get("reached",true)) and bool(drive.get("all_recorded_feet_clear",false)) and _clear(player.position)
		_check(stopped,"real movement stops before independently forbidden shoe/physical core: "+id)
		record.stop={"approach":approach,"input":drive,"raw_target":raw_denied,"actual_stop_px":[player.position.x,player.position.y],"passed":stopped}
		break
	_check(not (record.stop as Dictionary).is_empty(),"each blocking object has actual legal frontstop witness: "+id)
	for first in origins.size():
		if not (record.bypass as Dictionary).is_empty(): break
		for second in range(first+1,origins.size()):
			var a: Vector2=origins[first]
			var b: Vector2=origins[second]
			if a.distance_to(b)<minf(bound.size.x,bound.size.y): continue
			var approach: Dictionary=await _move(a)
			if not bool(approach.get("ok",false)): continue
			var bypass: Dictionary=await _move(b)
			if not bool(bypass.get("ok",false)): continue
			_check(true,"independent <=4px edge/full17/Physics alternate executes normal input around physical object: "+id)
			record.bypass={"from":[a.x,a.y],"to":[b.x,b.y],"approach":approach,"actual_input":bypass}
			break
	_check(not (record.bypass as Dictionary).is_empty(),"blocking object real bypass exists; nearby rock/water failures not waived: "+id)
	return record

func _ghost_exact(debug: Dictionary) -> Dictionary:
	var player: Node2D=field.get("_player") as Node2D
	var actor: Sprite2D=player.get("sprite") as Sprite2D
	var image: Image=alpha.call("image_for",actor)
	var frame: Rect2i=alpha.call("frame",actor,image)
	if image==null or frame.size.x<=0: return {"exact":false,"cause":"NO_ACTUAL_CURRENT_FRAME"}
	var candidates: Array[Sprite2D]=[]
	var container: Node2D=field.get("world_container") as Node2D
	var actor_bounds: Rect2=alpha.call("bounds_in",actor,container)
	var foot: float=float(player.call("get_depth_sort_y"))
	for id: String in props:
		var prop: Sprite2D=props[id]
		var entry: Dictionary=entries[id]
		if not bool(entry.get("sort_by_feet",false)): continue
		var depth: float=container.to_global(Vector2(0,float(entry.depth_sort_foot_y)*SIZE.y)).y
		if depth<=foot or not bool(alpha.call("actual_in_front",prop,player)): continue
		var bounds: Rect2=alpha.call("bounds_in",prop,container)
		if actor_bounds.intersects(bounds): candidates.append(prop)
	var expected_pixels: int=0
	var exact: bool=true
	var mask: Image=debug.get("mask_image") as Image
	var expected:=Image.create(frame.size.x,frame.size.y,false,Image.FORMAT_RGBA8)
	expected.fill(Color(0,0,0,0))
	var rect: Rect2=actor.get_rect()
	for y in frame.size.y:
		for x in frame.size.x:
			var coverage: float=0
			if image.get_pixelv(frame.position+Vector2i(x,y)).a>0:
				var uv:=Vector2((x+.5)/frame.size.x,(y+.5)/frame.size.y)
				if actor.flip_h: uv.x=1-uv.x
				if actor.flip_v: uv.y=1-uv.y
				var global_point: Vector2=actor.to_global(rect.position+uv*rect.size)
				var uncovered: float=1
				for prop: Sprite2D in candidates: uncovered*=1-float(alpha.call("alpha_at",prop,global_point))
				coverage=1-uncovered
			if coverage>0:
				expected_pixels+=1
				expected.set_pixel(x,y,Color(1,1,1,coverage))
	exact=bool(debug.get("active",false))==(expected_pixels>0) and int(debug.get("pixels",-1))==expected_pixels
	if expected_pixels>0: exact=exact and mask!=null and mask.get_size()==frame.size and mask.get_data()==expected.get_data() and debug.get("space")=="actor_frame"
	return {"exact":exact,"independent_union_pixels":expected_pixels,"current_frame":[frame.position.x,frame.position.y,frame.size.x,frame.size.y],"independent_candidate_count":candidates.size(),"source_path":actor.texture.resource_path,"source_sha256":FileAccess.get_sha256(actor.texture.resource_path),"mask_RGBA8_no_tolerance":true}

func _station(sprite: Sprite2D,entry: Dictionary,relation: String,direction: Vector2) -> Dictionary:
	var player: Node2D=field.get("_player") as Node2D
	var actor: Sprite2D=player.get("sprite") as Sprite2D
	var container: Node2D=field.get("world_container") as Node2D
	var bound: Rect2=alpha.call("bounds_in",sprite,container)
	var actor_bound: Rect2=alpha.call("bounds_in",actor,container)
	var domain: Rect2=bound.grow(maxf(actor_bound.size.x,actor_bound.size.y))
	var prop_foot: float=container.to_global(Vector2(0,float(entry.depth_sort_foot_y)*SIZE.y)).y
	var actor_offset: float=float(player.call("get_depth_sort_y"))-player.global_position.y
	var tested: int=0
	for step: int in [8,1]:
		for y in range(maxi(0,floori(domain.position.y)),mini(int(SIZE.y),ceili(domain.end.y)),step):
			for x in range(maxi(0,floori(domain.position.x)),mini(int(SIZE.x),ceili(domain.end.x)),step):
				var p:=Vector2(x,y)
				var foot: float=container.to_global(p).y+actor_offset
				if (foot<prop_foot)!=(relation=="behind") or foot==prop_foot: continue
				if not _clear(p) or not bool(_segment(p-direction*4,p).get("clear",false)): continue
				var shift: Vector2=container.to_global(p)-player.global_position
				if not actor_bound.position.is_finite() or not Rect2(actor_bound.position+p-player.position,actor_bound.size).intersects(bound): continue
				tested+=1
				var overlap: Dictionary=alpha.call("strong_intersection",actor,sprite,shift)
				if bool(overlap.get("valid",false)) and int(overlap.get("hits",0))>0: return {"found":true,"point":p,"hypothetical_strong_hits":overlap.hits,"tested":tested,"step":step}
				if tested>=5000: return {"found":false,"status":"INCONCLUSIVE_FINITE_SEARCH_NOT_CONTINUOUS_DENIAL","tested":tested,"domain":[domain.position.x,domain.position.y,domain.size.x,domain.size.y]}
	return {"found":false,"status":"INCONCLUSIVE_NO_WITNESS_NOT_ABSENCE_PROOF","tested":tested,"domain":[domain.position.x,domain.position.y,domain.size.x,domain.size.y]}

func _face(direction: Vector2) -> bool:
	var player: Node2D=field.get("_player") as Node2D
	var at: Vector2=player.position
	if not bool(_segment(at-direction*4,at).get("clear",false)): return false
	var drive: Dictionary=await driver.call("follow",field,PackedVector2Array([at,at-direction*4,at]),_clear,_segment)
	await driver.call("completed_actor_stage")
	var expected: String="down" if direction==Vector2.DOWN else "up" if direction==Vector2.UP else "left" if direction==Vector2.LEFT else "right"
	return bool(drive.get("ok",false)) and String(player.get("_direction"))==expected

func _alpha_trial(entry: Dictionary,sprite: Sprite2D) -> Dictionary:
	var cases: Array[Dictionary]=[]
	for direction: Vector2 in [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]:
		# Find a legal motion origin for this actual-facing frame. Never assign
		# actor texture/frame/direction or force the production helper to refresh.
		var face_origin:=Vector2(INF,INF)
		var player: Node2D=field.get("_player") as Node2D
		for radius: int in [0,8,16,32,64,128]:
			for index in 16:
				var p: Vector2=player.position+Vector2(cos(TAU*index/16),sin(TAU*index/16))*radius
				if _clear(p) and bool(_segment(p-direction*4,p).get("clear",false)): face_origin=p; break
			if face_origin.is_finite(): break
		if not _check(face_origin.is_finite(),"legal normal movement origin exists for current facing"): continue
		var approach: Dictionary=await _move(face_origin)
		var face_ready: bool=false
		if bool(approach.get("ok",false)): face_ready=await _face(direction)
		if not _check(face_ready,"normal input establishes real current facing, no frame setter"): continue
		for relation: String in ["behind","front"]:
			var station: Dictionary=_station(sprite,entry,relation,direction)
			_check(bool(station.get("found",false)),"actual strong legal "+relation+" station; finite missing remains FAIL for "+String(entry.id))
			if not bool(station.get("found",false)):
				cases.append({"direction":[direction.x,direction.y],"relation":relation,"station":station,"passed":false})
				continue
			var drive: Dictionary=await _move(station.point)
			var faced: bool=false
			if bool(drive.get("ok",false)): faced=await _face(direction)
			await driver.call("completed_actor_stage")
			var actor: Sprite2D=player.get("sprite") as Sprite2D
			var overlap: Dictionary=alpha.call("strong_intersection",actor,sprite)
			var container: Node2D=field.get("world_container") as Node2D
			var prop_foot: float=container.to_global(Vector2(0,float(entry.depth_sort_foot_y)*SIZE.y)).y
			var actor_foot: float=float(player.call("get_depth_sort_y"))
			var actual_relation: bool=(actor_foot<prop_foot) if relation=="behind" else (actor_foot>prop_foot)
			var actual_front: bool=alpha.call("actual_in_front",player,sprite)
			var debug: Dictionary=field.call("get_v14_modular_overlap_debug")
			var ghost: int=int((debug.get("prop_hits",{}) as Dictionary).get(String(entry.id),0))
			var union: Dictionary=_ghost_exact(debug)
			var correct: bool=faced and _clear(player.position) and actual_relation and bool(overlap.get("valid",false)) and int(overlap.get("hits",0))>0 and actual_front==(relation=="front") and player.z_index==clampi(floori(actor_foot/8),0,1024) and sprite.z_index==clampi(floori(prop_foot/8),0,1024)
			_check(correct,"current strong alpha/full17/Physics/actual foot/effective front-order all independently agree: "+String(entry.id))
			_check(bool(union.get("exact",false)) and (ghost>0 if relation=="behind" else ghost==0),"actual current-frame LOCAL alpha union exactRGBA8; front not rectangular fade: "+String(entry.id))
			cases.append({"direction":[direction.x,direction.y],"relation":relation,"actual_feet_px":[player.position.x,player.position.y],"actor_foot_global":actor_foot,"prop_foot_global":prop_foot,"actor_band":player.z_index,"prop_band":sprite.z_index,"overlap":overlap,"union":union,"target_ghost_pixels":ghost,"actual_input":drive,"passed":correct and bool(union.get("exact",false))})
			await phase.call("_capture_world","object_"+String(entry.id)+"_"+relation+"_"+str(cases.size()))
	var complete: bool=cases.size()==8
	for row: Dictionary in cases: complete=complete and bool(row.get("passed",false))
	return {"scope":"FOUR_ACTUAL_IDLE_FACINGS_NOT_ALL_ANIMATION","cases":cases,"complete":complete}

func run(owner: RefCounted) -> Dictionary:
	phase=owner
	tree=phase.get("owner_tree") as SceneTree
	driver=phase.get("input_driver") as RefCounted
	raw=phase.get("oracle") as RefCounted
	var world: SceneScript=phase.get("world") as SceneScript
	if not _check(bool(await phase.call("_open_owned_world_fixture",world.player_spawn*SIZE)),"real normal full-world Field opens exact native fixture"): return _finish()
	field=phase.get("field")
	var container: Node2D=field.get("world_container") as Node2D
	for entry: Dictionary in world.map_layout.visual_objects:
		var id: String=String(entry.get("id",""))
		_check(not id.is_empty() and not entries.has(id),"unique declared independent visual ID")
		entries[id]=entry
	for sprite: Sprite2D in field.get("_scene_object_nodes"):
		if not String(sprite.name).begins_with("SceneObject_"): continue
		var id: String=String(sprite.name).trim_prefix("SceneObject_")
		_check(entries.has(id) and not props.has(id),"runtime object has exact current declared identity")
		props[id]=sprite
	_check(props.size()==entries.size() and not entries.is_empty(),"all current independent props exist, no fixed old native count")
	for id: String in entries:
		if not props.has(id): continue
		var entry: Dictionary=entries[id]
		var sprite: Sprite2D=props[id]
		var texture_path: String=String(entry.get("texture",""))
		_check(texture_path.begins_with(ROOT) and sprite.texture!=null and sprite.texture.resource_path==texture_path and FileAccess.get_sha256(texture_path).length()==64,"actual independent current-root PNG, not baked-background/source-local replacement: "+id)
		_check(container.to_local(sprite.global_position).distance_to(_p(entry.pos)*SIZE)<.01 and (sprite.get_rect().size*sprite.scale.abs()).distance_to(_p(entry.render_size_px))<.01 and sprite.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR,"actual renderer position/size/filter matches published spatial contract: "+id)
		var geometry: Dictionary=_physical_inventory(entry,sprite)
		var collision: Dictionary=await _collision_trial(id,geometry) if bool(geometry.blocking) else {"blocking":false,"actual_body_absent":geometry.exact_binding}
		var visibility: Dictionary={}
		if bool(entry.get("sort_by_feet",false)):
			visibility=await _alpha_trial(entry,sprite)
		else:
			var foot: float=float((field.get("_player") as Node2D).call("get_depth_sort_y"))
			_check(not bool(geometry.blocking) and sprite.z_index<clampi(floori(foot/8),0,1024),"non-depth ground visual never supplies foreground/strong-alpha credit: "+id)
			visibility={"scope":"GROUND_VISUAL_NO_FOREGROUND_CREDIT","z_index":sprite.z_index,"complete":not bool(geometry.blocking)}
		records.append({"id":id,"texture":texture_path,"texture_sha256":FileAccess.get_sha256(texture_path),"geometry":geometry,"collision":collision,"current_alpha":visibility})
	_check(records.size()==entries.size(),"every current visual has independent binding/physics/input/alpha classification")
	return _finish()

func _finish() -> Dictionary:
	var result: Dictionary={"scope":"ALL_CURRENT_WORLD_VISUAL_BINDING_PHYSICS_NORMAL_INPUT_CURRENT_ALPHA_NOT_VISUAL_APPROVAL","checks":checks,"failures":failures,"complete":failures==0 and not entries.is_empty() and records.size()==entries.size(),"object_ids":entries.keys(),"records":records.duplicate(true),"executing_script_path":get_script().resource_path,"executing_script_sha256":FileAccess.get_sha256(get_script().resource_path)}
	_check(bool(phase.call("_write_json","all_current_world_object_input.json",result)),"all actual object evidence flush/readback succeeded")
	result.checks=checks
	result.failures=failures
	result.complete=failures==0 and not entries.is_empty() and records.size()==entries.size()
	alpha.call("release")
	alpha=null
	entries.clear()
	props.clear()
	field=null
	driver=null
	raw=null
	phase=null
	tree=null
	return result
