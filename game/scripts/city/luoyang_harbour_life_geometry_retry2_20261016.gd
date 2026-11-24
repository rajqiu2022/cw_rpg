extends RefCounted
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const A=preload("res://scripts/city/luoyang_harbour_life_author_retry2_20261016.gd")
const CROWD=preload("res://scripts/city/luoyang_harbour_life_crowd_retry2_20261016.gd")
static func seventeen(point: Vector2,mask: Image) -> bool:
	for offset: Vector2 in [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]:
		var p:=Vector2i((point+offset).round())
		if p.x<0 or p.y<0 or p.x>=mask.get_width() or p.y>=mask.get_height(): return false
		var color:=mask.get_pixelv(p)
		if color.a<.5 or color.r<.5: return false
	return true
static func _npc_envelope(point: Vector2,mask: Image,solids: Array[PackedVector2Array]) -> bool:
	# All selected runtime strips have160px cells and scale1.0. Existing native
	# NPC body is22.4x28.8, not the Player's34x24. Check the larger34x30 envelope
	# too, retaining all original875+17 checks rather than replacing them.
	var continuous:=PackedVector2Array([point+Vector2(-17,-15),point+Vector2(17,-15),point+Vector2(17,15),point+Vector2(-17,15)])
	for polygon: PackedVector2Array in solids:
		if not Geometry2D.intersect_polygons(continuous,polygon).is_empty(): return false
	for y: int in range(-15,16):
		for x: int in range(-17,18):
			var p:=point+Vector2(x,y); var pixel:=Vector2i(p.round())
			if pixel.x<0 or pixel.y<0 or pixel.x>=mask.get_width() or pixel.y>=mask.get_height(): return false
			var color:=mask.get_pixelv(pixel)
			if color.a<.5 or color.r<.5: return false
			for polygon: PackedVector2Array in solids:
				if Geometry2D.is_point_in_polygon(p,polygon): return false
	return true
static func audit(record: Dictionary,mask: Image,cancel: Callable=Callable()) -> Dictionary:
	var id:=StringName(record.get("canonical_scene_id","")); var solid:=C.object_solids(record.objects)
	var paths: Array=record.routes.duplicate(true); var lanes:=CROWD.lanes(id)
	paths.append_array(lanes)
	var count:=0; var crowd_count:=0
	for path: Dictionary in paths:
		var crowd:=String(path.id).begins_with("crowd_")
		for index: int in range(path.points_px.size()-1):
			var from:=A.v(path.points_px[index]); var to:=A.v(path.points_px[index+1]); var steps:=maxi(1,ceili(from.distance_to(to)/4.0))
			for step: int in range(steps+1):
				if cancel.is_valid() and cancel.call(): return {"passed":false,"cancelled":true}
				var foot:=from.lerp(to,float(step)/steps)
				if not C._safe_body_cpu(foot,mask,solid) or not seventeen(foot,mask) or (crowd and not _npc_envelope(foot,mask,solid)):
					return {"passed":false,"path":path.id,"foot_px":A.xy(foot),"samples":count}
				count+=1
				if crowd: crowd_count+=1
	var boxes: Array[Rect2]=[]
	for lane: Dictionary in lanes:
		var from:=A.v(lane.points_px[0]); var to:=A.v(lane.points_px[1])
		var rect:=Rect2(from-Vector2(34,30),to-from+Vector2(68,60))
		for other: Rect2 in boxes:
			if rect.intersects(other,true): return {"passed":false,"lane_conflict":lane.id}
		for p: Variant in A.spec(id).protected_feet:
			if rect.grow(34).has_point(A.v(p)): return {"passed":false,"protected_foot_conflict":lane.id,"protected_foot":p}
		boxes.append(rect)
	return {"passed":true,"all_routes_and_crowd_samples":count,"crowd_samples":crowd_count,"crowd_count":lanes.size(),"moving":6,"stationary":4,"full875_and17":true,"npc_envelope_px":[34,30],"max_step_px":4,"dynamic_avoidance_promised":false}
