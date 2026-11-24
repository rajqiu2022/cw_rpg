extends RefCounted
## Read-only observers around the unmodified Player physics callback.
## Constraint results are observations, never independent navigation authority.
class TickObserver extends Node:
	var recorder: RefCounted
	var before: bool
	func _physics_process(delta: float) -> void:
		if before: recorder.call("pre",delta)
		else: recorder.call("post",delta)

const LIMIT := 4096
var field: Control
var probe: RefCounted
var player: CharacterBody2D
var pre_node: TickObserver
var post_node: TickObserver
var rows: Array[Dictionary]=[]
var physics_boundaries: Array[Dictionary]=[]
var pending: Dictionary={}
var errors: Array[String]=[]
var active: bool=false
var setup: Dictionary={}

func vector(p: Vector2) -> Dictionary:
	return {"value":[p.x,p.y],"native_float32_hex":PackedVector2Array([p]).to_byte_array().hex_encode()}

func attach(actual: Control, independent: RefCounted) -> bool:
	field=actual; probe=independent; player=field.get("_player") as CharacterBody2D
	if player==null or not player.is_inside_tree() or not player.is_physics_processing(): return false
	var priority: int=player.process_physics_priority
	if priority<=-2147483648 or priority>=2147483647: return false
	pre_node=TickObserver.new(); post_node=TickObserver.new()
	pre_node.name="ReadOnlyShopPrePhysics"; post_node.name="ReadOnlyShopPostPhysics"
	pre_node.recorder=self; post_node.recorder=self; pre_node.before=true; post_node.before=false
	pre_node.process_physics_priority=priority-1; post_node.process_physics_priority=priority+1
	# Same parent/inherited thread group as Player; Player properties untouched.
	player.get_parent().add_child(pre_node); player.get_parent().add_child(post_node)
	field.get_tree().physics_frame.connect(_boundary)
	setup={"player_priority":priority,"pre_priority":pre_node.process_physics_priority,"post_priority":post_node.process_physics_priority,"parent":str(player.get_parent().get_path()),"player_thread_group":player.process_thread_group,"pre_thread_group":pre_node.process_thread_group,"post_thread_group":post_node.process_thread_group,"player_safe_margin":player.safe_margin,"player_collision_mask":player.collision_mask,"player_collision_layer":player.collision_layer,"physics_ticks_per_second":Engine.physics_ticks_per_second,"limit":LIMIT}
	return pre_node.process_physics_priority<priority and post_node.process_physics_priority>priority

func _boundary() -> void:
	if not active: return
	if physics_boundaries.size()>=LIMIT: errors.append("boundary_buffer_exhausted"); active=false; return
	physics_boundaries.append({"frame":Engine.get_physics_frames(),"ticks_usec":Time.get_ticks_usec(),"actor_local":vector(player.position),"last_completed_post_frame":rows.back().post_frame if not rows.is_empty() else -1,"scope":"TREE_SIGNAL_BEFORE_NODE_PHYSICS; original driver awaits same signal, input callback order not inferred"})

func independent(p: Vector2) -> Dictionary:
	var minimum:=Vector2i(roundi(p.x-17),roundi(p.y-12))
	var maximum:=Vector2i(roundi(p.x+17),roundi(p.y+12))
	var rectangle:=Rect2(p-Vector2(17,12),Vector2(34,24))
	var image: Image=probe.get("walk")
	var bytes:=PackedByteArray()
	var denied: Array=[]
	var pixels: int=0
	if p.is_finite() and minimum.x>=0 and minimum.y>=0 and maximum.x<image.get_width() and maximum.y<image.get_height():
		for y: int in range(minimum.y,maximum.y+1):
			for x: int in range(minimum.x,maximum.x+1):
				var color: Color=image.get_pixel(x,y)
				pixels+=1
				for channel: float in [color.r,color.g,color.b,color.a]: bytes.append(roundi(channel*255))
				if color.r<.5 or color.a<.5: denied.append([x,y])
	var hash:=HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(bytes)
	var shoes: Array=[]
	for index: int in 17:
		var q: Vector2=p if index==0 else p+Vector2(cos(TAU*(index-1)/16)*10,sin(TAU*(index-1)/16)*6)
		var pixel:=Vector2i(roundi(q.x),roundi(q.y))
		var valid: bool=pixel.x>=0 and pixel.y>=0 and pixel.x<image.get_width() and pixel.y<image.get_height()
		var color: Color=image.get_pixelv(pixel) if valid else Color(0,0,0,0)
		var solid_ids: Array[String]=[]
		for id: String in probe.get("solids"):
			for polygon: PackedVector2Array in probe.get("solids")[id]:
				if Geometry2D.is_point_in_polygon(q,polygon): solid_ids.append(id)
		shoes.append({"index":index,"point":vector(q),"pixel":[pixel.x,pixel.y],"in_domain":valid,"rgba":[color.r,color.g,color.b,color.a],"source_solid_ids":solid_ids})
	return {"point":vector(p),"raw_full875_and17":probe.call("raw_evidence",p),"body_minimum":[minimum.x,minimum.y],"body_maximum":[maximum.x,maximum.y],"production_Rect2_minimum":[roundi(rectangle.position.x),roundi(rectangle.position.y)],"production_Rect2_maximum":[roundi(rectangle.end.x),roundi(rectangle.end.y)],"all_body_pixels_read":pixels,"all_body_RGBA_sha256":hash.finish().hex_encode(),"all_denied_body_pixels":denied,"all17_shoes":shoes,"actual_Physics_clear":probe.call("physical_clear",p),"actual_Physics_hits":probe.call("_physical_hits",p)}

func pre(delta: float) -> void:
	if not active: return
	if rows.size()>=LIMIT: errors.append("bounded_buffer_exhausted"); active=false; return
	if not pending.is_empty(): errors.append("unpaired_pre"); active=false; return
	var container: Node2D=field.get("world_container")
	var input: Vector2=Input.get_vector("move_left","move_right","move_up","move_down")
	var requested: Vector2=input*480.0
	var full: Vector2=player.global_position+requested*delta
	var horizontal: Vector2=Vector2(requested.x,0)
	var vertical: Vector2=Vector2(0,requested.y)
	var hx: Vector2=player.global_position+horizontal*delta
	var vy: Vector2=player.global_position+vertical*delta
	var constraint: Callable=player.get("movement_constraint")
	var bound: bool=constraint.is_valid()
	var full_allowed: bool=bool(constraint.call(full)) if bound else true
	var horizontal_allowed: bool=bool(constraint.call(hx)) if bound and horizontal!=Vector2.ZERO else false
	var vertical_allowed: bool=bool(constraint.call(vy)) if bound and vertical!=Vector2.ZERO else false
	var chosen: Vector2=requested
	var branch: String="full"
	if not player.get("can_move"): chosen=Vector2.ZERO; branch="can_move_false"
	elif bound and requested!=Vector2.ZERO and not full_allowed:
		if horizontal!=Vector2.ZERO and horizontal_allowed: chosen=horizontal; branch="horizontal"
		elif vertical!=Vector2.ZERO and vertical_allowed: chosen=vertical; branch="vertical"
		else: chosen=Vector2.ZERO; branch="zero"
	# Formula mirrors frozen Player321; never calls/overrides its private body.
	pending={"frame":Engine.get_physics_frames(),"pre_ticks_usec":Time.get_ticks_usec(),"delta":delta,"delta_float64_hex":PackedFloat64Array([delta]).to_byte_array().hex_encode(),"input":vector(input),"before_local":vector(player.position),"before_global":vector(player.global_position),"requested_velocity":vector(requested),"previous_velocity":vector(player.velocity),"can_move":player.get("can_move"),"constraint_valid":bound,"constraint_object_id":str(constraint.get_object_id()),"constraint_method":str(constraint.get_method()),"observed_full_allowed":full_allowed,"observed_horizontal_allowed":horizontal_allowed,"observed_vertical_allowed":vertical_allowed,"formula_chosen_velocity":vector(chosen),"formula_branch":branch,"world_transform":str(container.global_transform),"before":independent(player.position),"full_requested_target":independent(container.to_local(full)),"horizontal_requested_target":independent(container.to_local(hx)),"vertical_requested_target":independent(container.to_local(vy))}

func post(delta: float) -> void:
	if not active: return
	if pending.is_empty(): errors.append("post_without_pre"); active=false; return
	if int(pending.frame)!=Engine.get_physics_frames() or float(pending.delta)!=delta: errors.append("frame_or_delta_pair_mismatch")
	var collisions: Array=[]
	for index: int in player.get_slide_collision_count():
		var collision: KinematicCollision2D=player.get_slide_collision(index)
		var collider: Object=collision.get_collider()
		collisions.append({"index":index,"collider_id":str(collision.get_collider_id()),"collider_rid":str(collision.get_collider_rid().get_id()),"collider_path":str(collider.get_path()) if collider is Node else "NON_NODE","position":vector(collision.get_position()),"normal":vector(collision.get_normal()),"travel":vector(collision.get_travel()),"remainder":vector(collision.get_remainder()),"depth":collision.get_depth()})
	pending["post_frame"]=Engine.get_physics_frames(); pending["post_ticks_usec"]=Time.get_ticks_usec()
	pending["after_local"]=vector(player.position); pending["after_global"]=vector(player.global_position)
	pending["actual_velocity"]=vector(player.velocity); pending["actual_real_velocity"]=vector(player.get_real_velocity())
	pending["actual_position_delta"]=vector(player.get_position_delta()); pending["slide_collisions"]=collisions
	pending["after"]=independent(player.position)
	pending["chosen_matches_actual_velocity"]=pending.formula_chosen_velocity.native_float32_hex==PackedVector2Array([player.velocity]).to_byte_array().hex_encode()
	rows.append(pending); pending={}

func _neighbor(value: float,direction: int) -> float:
	var bytes: PackedByteArray=PackedFloat32Array([value]).to_byte_array()
	bytes.encode_u32(0,bytes.decode_u32(0)+direction)
	return bytes.decode_float(0)

func rounding_events(a: Vector2,b: Vector2) -> Dictionary:
	var events: Dictionary={0.0:[],1.0:[]}
	var offsets: Array[Vector2]=[Vector2(-17,-12),Vector2(17,12),Vector2.ZERO]
	for i: int in 16: offsets.append(Vector2(cos(TAU*i/16)*10,sin(TAU*i/16)*6))
	for index: int in offsets.size():
		for axis: int in 2:
			var start: float=float(a[axis])+float(offsets[index][axis])
			var change: float=float(b[axis])-float(a[axis])
			if change==0: continue
			var end: float=start+change
			for integer: int in range(floori(minf(start,end)) - 1,ceili(maxf(start,end))+1):
				var boundary: float=integer+.5
				var t: float=(boundary-start)/change
				if t<0 or t>1: continue
				if not events.has(t): events[t]=[]
				events[t].append({"offset_index":index,"axis":axis,"half_integer":boundary,"offset":vector(offsets[index])})
	var times: Array=events.keys(); times.sort()
	var actual_events: Array=[]; var cells: Array=[]
	for index: int in times.size():
		var t: float=times[index]
		var p: Vector2=a.lerp(b,t)
		var neighbors: Array=[]
		for axis: int in 2:
			for direction: int in [-1,1]:
				var q: Vector2=p; q[axis]=_neighbor(p[axis],direction)
				neighbors.append({"axis":axis,"float32_ulp_direction":direction,"evidence":independent(q)})
		actual_events.append({"parameter":t,"parameter_native_hex":PackedFloat64Array([t]).to_byte_array().hex_encode(),"analytical_half_integer_events":events[t],"actual_Vector2_lerp":independent(p),"native_Float32_neighbors":neighbors})
		if index+1<times.size():
			var mid: float=(t+float(times[index+1]))*.5
			cells.append({"open_parameter_interval":[t,times[index+1]],"midpoint":mid,"native_midpoint_evidence":independent(a.lerp(b,mid))})
	return {"method":"ALL_BODY_ENDPOINT_AND17_SHOE_AXIS_HALF_INTEGER_EVENTS_PLUS_ACTUAL_FLOAT32_LERP_AND_ADJACENT_BITS","from":vector(a),"to":vector(b),"events":actual_events,"open_cells":cells,"no_threshold_change":true,"no_dense_step_sampling_claim":true,"continuous_Physics_sweep_proved":false}

func release() -> void:
	active=false
	if is_instance_valid(field) and field.get_tree().physics_frame.is_connected(_boundary): field.get_tree().physics_frame.disconnect(_boundary)
	if is_instance_valid(pre_node): pre_node.queue_free()
	if is_instance_valid(post_node): post_node.queue_free()
	pre_node=null; post_node=null; player=null; field=null; probe=null
