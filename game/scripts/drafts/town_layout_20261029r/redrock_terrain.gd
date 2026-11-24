extends "res://scripts/drafts/sect_maps_20261029k/terrain.gd"
func assign_objects()->void:
	for room_name in ["HomeRoom","InnHall"]:
		for body in town.get_node(room_name).find_children("*","StaticBody2D",true,false):body.collision_layer=2
	for item in town.get_node("Town").get_children():
		if not item is Node2D or item==town.actor:continue
		var level:=level_at(item.global_position)
		if str(item.name).contains("Stairs"):level=0 if item.name=="LaneStairs" else 1
		item.set_meta("terrain_level",level);item.set_meta("elevation",elevation(level))
		if item is StaticBody2D:
			item.collision_layer=8;continue
		for body in item.find_children("*","StaticBody2D",true,false):body.collision_layer=layer(level)
		if item is CharacterBody2D:
			item.collision_mask=8|layer(level)
			continue
		for visual in item.get_children():
			if visual is CanvasItem and not visual is CollisionObject2D:visual.position.y-=elevation(level)
		item.z_as_relative=false;item.z_index=town.foot_depth(item.global_position.y)
	for name in ["TownWestBank","TownEastBank","TownNorthBank","ApproachWestBank","ApproachEastBank"]:
		for body in town.get_node("Town/"+name).find_children("*","StaticBody2D",true,false):body.collision_layer=8
func build_boundaries()->void:
	var tex:Texture2D=load("res://art/modules/desert_city_rework_20261029o/redrock_cliff.png")
	var serial:=0
	for row in platforms:
		var level:=int(row.level);var points:PackedVector2Array=row.polygon
		for i in range(points.size()):
			var a:=points[i];var b:=points[(i+1)%points.size()]
			for pair in edge_pieces(a,b,level,float(data.portal_half_width)):
				fence(pair[0],pair[1],layer(level)|layer(level-1),"TerraceEdge"+str(serial));serial+=1
			if b.x>=a.x:continue
			for pair in edge_pieces(a,b,level,float(data.facade_opening_half_width)):
				var p:Vector2=pair[0];var q:Vector2=pair[1];var n:=maxi(1,ceili(p.distance_to(q)/260.0))
				for j in range(n):
					var u:=p.lerp(q,float(j)/n);var v:=p.lerp(q,float(j+1)/n)
					var high:=Vector2(0,elevation(level));var low:=Vector2(0,elevation(level-1))
					var x:=430.0+float(j%4)*280.0;var w:=u.distance_to(v);var h:=high.y-low.y
					polygon_node(PackedVector2Array([u-high,v-high,v-low,u-low]),PackedVector2Array([Vector2(x,520),Vector2(x+w,520),Vector2(x+w,520+h),Vector2(x,520+h)]),tex,self,town.foot_depth(p.y)-2)
func build_stairs()->void:
	# Keep the original stair art and source-UV rail separation; register real layer portals.
	for i in range(ramps.size()):
		var r:Dictionary=ramps[i];var stair:Node2D=town.get_node("Town/"+str(r.id))
		for body in stair.find_children("*","StaticBody2D",true,false):
			# Legacy rail footprints were in projected XY, now use the physical ramp rails below.
			body.collision_layer=0
		var top:=Vector2(r.top[0],r.top[1]);var bottom:=Vector2(r.bottom[0],r.bottom[1])
		for side in [-1,1]:
			var x:=top.x+float(side)*float(data.portal_half_width)
			fence(Vector2(x,top.y-24),Vector2(x,bottom.y+24),layer(int(r.low))|layer(int(r.high)),"StairRail"+str(i)+str(side))
