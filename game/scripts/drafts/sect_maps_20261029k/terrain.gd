extends Node2D
## XY is physical ground; Z is elevation. Only bounded stair ramps change floor.
const ROOT := "res://art/modules/miao_town_20261029f/"
var data: Dictionary
var platforms: Array=[]
var ramps: Array=[]
var heights: Array=[]
var town: Node2D
var actor_level := 0
var active_ramp := -1
var actor_height := 0.0
var transitions: Array=[]

func setup(owner_town: Node2D) -> void:
	town=owner_town
	data=town.layout.terrain
	heights=data.heights;ramps=data.ramps
	for row: Dictionary in data.platforms:
		var points:=PackedVector2Array()
		for p: Array in row.polygon:points.append(Vector2(p[0],p[1]))
		platforms.append({"level":int(row.level),"polygon":points})
	for body: StaticBody2D in town.find_children("*","StaticBody2D",true,false):
		if str(body.get_path()).contains("/HouseHall/") or str(body.get_path()).contains("/Terrain/"):continue
		body.collision_layer=8 if body.has_meta("common_layer") or str(body.name).begins_with("Water") else layer(level_at(body.global_position))
	assign_objects()
	if not bool(town.get_meta("terrain_baked",false)):
		build_surfaces()
		build_boundaries()
		build_stairs()
	reset_actor(0)

func layer(level: int) -> int:return 16<<level
func elevation(level: int) -> float:return float(heights[level])
func level_at(p: Vector2) -> int:
	var result:=0
	for row: Dictionary in platforms:
		if Geometry2D.is_point_in_polygon(p,row.polygon):result=maxi(result,int(row.level))
	return result

func assign_objects() -> void:
	for item: Node in town.get_node("Town").get_children():
		if not item is Node2D or item==town.actor or item is StaticBody2D:continue
		if data.object_moves.has(str(item.name)):
			var destination: Array=data.object_moves[str(item.name)];item.position=Vector2(destination[0],destination[1])
		var level:=level_at(item.global_position)
		if item.name=="DyeWorker":
			item.route=PackedVector2Array([Vector2(2460,2170),Vector2(2700,2170)]);item.position=item.route[0];level=1
		item.set_meta("terrain_level",level)
		for body: StaticBody2D in item.find_children("*","StaticBody2D",true,false):body.collision_layer=layer(level)
		if item is CharacterBody2D:
			item.floor_level=level;item.elevation=elevation(level);item.collision_mask=8|layer(level);item.show_frame()
		elif not bool(town.get_meta("terrain_baked",false)):
			# Visuals move; physical roots and foot colliders stay in ground coordinates.
			for visual: Node in item.get_children():
				if visual is CanvasItem and not visual is CollisionObject2D and not visual is CollisionShape2D and not visual is CollisionPolygon2D:
					visual.position.y-=elevation(level)
		# Building front feet cannot silently acquire a different physical floor.
		item.set_meta("elevation",elevation(level))

func polygon_node(points: PackedVector2Array,uvs: PackedVector2Array,texture: Texture2D,parent: Node,z: int) -> Polygon2D:
	var p:=Polygon2D.new();p.polygon=points;p.uv=uvs;p.texture=texture;p.z_as_relative=false;p.z_index=z;parent.add_child(p);return p

func build_surfaces() -> void:
	var original: Polygon2D=town.get_node("Ground")
	for row: Dictionary in platforms:
		var top:=Polygon2D.new();top.name="Platform"+str(row.level);top.z_index=-9+int(row.level)
		top.polygon=row.polygon;top.position.y=-elevation(int(row.level))
		# Shader receives polygon-local ground XY; node transform supplies projected Z.
		top.material=original.material.duplicate();add_child(top)

func fence(a: Vector2,b: Vector2,mask: int,label: String) -> void:
	var body:=StaticBody2D.new();body.name=label;body.collision_layer=mask;body.collision_mask=0;add_child(body)
	var outline:=CollisionPolygon2D.new();var n: Vector2=(b-a).normalized().orthogonal()*5.0
	outline.polygon=PackedVector2Array([a+n,b+n,b-n,a-n]);body.add_child(outline)

func edge_pieces(a: Vector2,b: Vector2,level: int,opening: float) -> Array:
	var pieces: Array=[[a,b]]
	for ramp: Dictionary in ramps:
		if int(ramp.high)!=level:continue
		var t:=Vector2(ramp.top[0],ramp.top[1])
		if absf(a.y-b.y)>.01 or absf(a.y-t.y)>.01:continue
		var next: Array=[]
		for pair: Array in pieces:
			var p: Vector2=pair[0];var q: Vector2=pair[1]
			if t.x<=minf(p.x,q.x) or t.x>=maxf(p.x,q.x):next.append(pair);continue
			var left:=Vector2(maxf(t.x-opening,minf(p.x,q.x)),p.y)
			var right:=Vector2(minf(t.x+opening,maxf(p.x,q.x)),p.y)
			next.append([p,left] if p.x<q.x else [p,right]);next.append([right,q] if p.x<q.x else [left,q])
		pieces=next
	return pieces

func build_boundaries() -> void:
	var texture: Texture2D=load(ROOT+"terrace.png")
	var index:=0
	for row: Dictionary in platforms:
		var level:=int(row.level);var points: PackedVector2Array=row.polygon
		for i in range(points.size()):
			var a: Vector2=points[i];var b: Vector2=points[(i+1)%points.size()]
			for pair: Array in edge_pieces(a,b,level,float(data.portal_half_width)):
				fence(pair[0],pair[1],layer(level)|layer(level-1),"Cliff"+str(index));index+=1
			for pair: Array in edge_pieces(a,b,level,float(data.facade_opening_half_width)):
				var p: Vector2=pair[0];var q: Vector2=pair[1]
				if q.x>=p.x:continue
				var count:=maxi(1,ceili(p.distance_to(q)/300.0))
				for j in range(count):
					var u: Vector2=p.lerp(q,float(j)/count);var v: Vector2=p.lerp(q,float(j+1)/count)
					var high:=Vector2(0,elevation(level));var low:=Vector2(0,elevation(level-1))
					# Native stone face sampled by UV in-engine. No new PNG, crop or resample file.
					var x0:=273.0+220.0+float(j%4)*350.0;var x1:=x0+u.distance_to(v)/.7
					var uv:=PackedVector2Array([Vector2(x0,92+305),Vector2(x1,92+305),Vector2(x1,92+455),Vector2(x0,92+455)])
					polygon_node(PackedVector2Array([u-high,v-high,v-low,u-low]),uv,texture,self,town.foot_depth((u.y+v.y)*.5)-2)

func native_poly(source: Array,parent: Node,s: float,pivot: Vector2,z: int) -> void:
	var points:=PackedVector2Array();var uvs:=PackedVector2Array()
	for p: Array in source:
		points.append((Vector2(p[0],p[1])-pivot)*s);uvs.append(Vector2(p[0]+194,p[1]+89))
	polygon_node(points,uvs,load(ROOT+"stairs.png"),parent,z)

func build_stairs() -> void:
	var s:=float(data.source_stair_scale)
	for i in range(ramps.size()):
		var r: Dictionary=ramps[i];var top:=Vector2(r.top[0],r.top[1]);var bottom:=Vector2(r.bottom[0],r.bottom[1])
		var stair:=Node2D.new();stair.name=r.id;stair.position=bottom-Vector2(0,elevation(int(r.low)));add_child(stair)
		native_poly([[500,0],[1040,0],[1040,358],[1125,780],[1125,1024],[410,1024],[410,780],[500,358]],stair,s,Vector2(768,780),-4)
		native_poly([[0,0],[500,0],[500,358],[410,780],[410,1024],[0,1024]],stair,s,Vector2(768,780),town.foot_depth(bottom.y+24))
		native_poly([[1040,0],[1536,0],[1536,1024],[1125,1024],[1125,780],[1040,358]],stair,s,Vector2(768,780),town.foot_depth(bottom.y+24))
		# Side rails extend past both portals; only the two open ends are traversable.
		for sign_x in [-1,1]:
			var x:=top.x+float(sign_x)*float(data.portal_half_width)
			fence(Vector2(x,top.y-22),Vector2(x,bottom.y+22),layer(int(r.low))|layer(int(r.high)),"RampRail"+str(i)+str(sign_x))

func reset_actor(level: int) -> void:
	actor_level=level;active_ramp=-1;actor_height=elevation(level)
	apply_actor_mask()

func apply_actor_mask() -> void:
	var mask:=layer(actor_level)
	if active_ramp>=0:
		var r: Dictionary=ramps[active_ramp];mask=layer(int(r.low))|layer(int(r.high))
	town.actor.collision_mask=8|mask

func before_move(velocity: Vector2) -> Vector2:
	if active_ramp<0:
		var p: Vector2=town.actor.global_position
		for i in range(ramps.size()):
			var r: Dictionary=ramps[i];var x:=float(r.top[0]);var y0:=float(r.top[1]);var y1:=float(r.bottom[1])
			if absf(p.x-x)>float(data.portal_half_width)-20:continue
			if (actor_level==int(r.low) and velocity.y<0 and p.y>=y0 and p.y<=y1+25) or (actor_level==int(r.high) and velocity.y>0 and p.y<=y1 and p.y>=y0-25):
				active_ramp=i;apply_actor_mask();break
	if active_ramp>=0:
		var r: Dictionary=ramps[active_ramp]
		velocity.y/=1.0+float(r.rise)/float(r.ground_run)
	return velocity

func after_move() -> void:
	if active_ramp<0:actor_height=elevation(actor_level);return
	var r: Dictionary=ramps[active_ramp];var y:=float(town.actor.global_position.y)
	var t:=clampf((float(r.bottom[1])-y)/float(r.ground_run),0.0,1.0)
	actor_height=lerpf(elevation(int(r.low)),elevation(int(r.high)),t)
	if y<float(r.top[1])-1 or y>float(r.bottom[1])+1:
		var previous:=actor_level;actor_level=int(r.high) if t>.5 else int(r.low)
		transitions.append({"ramp":r.id,"from":previous,"to":actor_level,"foot":town.actor.global_position,"height":actor_height})
		active_ramp=-1;apply_actor_mask()

func project_actor() -> void:
	# animate_preview reapplies the canonical feet baseline every tick; Z is never cumulative.
	town.actor.set_ground_anchored(true)
	var sprite: Sprite2D=town.actor.get_node("Sprite2D")
	sprite.position.y-=actor_height

func projected_foot() -> Vector2:return town.actor.global_position-Vector2(0,actor_height)
