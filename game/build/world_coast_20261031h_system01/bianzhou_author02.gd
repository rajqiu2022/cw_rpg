extends RefCounted
## One exact compound/portal retreat; all bridge rows are immutable.
const WORLD := Vector2(12288,8192)
const DELTA := Vector2(0,-640)
const DOMAIN := Rect2(7000,1000,1350,1600)
const PLAZA_CENTER := Vector2(7600,1800)
const PLAZA_RADIUS := Vector2(250,160)
const BRIDGE_EAST := Vector2(7830.06396484375,2294.90063476563)
static var _record: Dictionary={}

static func approach() -> PackedVector2Array:
	return PackedVector2Array([BRIDGE_EAST,Vector2(8050,2150),Vector2(8050,1850),PLAZA_CENTER,Vector2(7600,1556.8779296875)])

static func _polygons(row: Dictionary) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array]=[]
	if row.has("solid_polygons_px"):
		for p: PackedVector2Array in row.solid_polygons_px:result.append(p)
	elif row.has("collision_size"):
		var size: Vector2=Vector2(row.collision_size)*WORLD
		var center: Vector2=(Vector2(row.get("pos",Vector2.ZERO))+Vector2(row.get("collision_offset",Vector2.ZERO)))*WORLD
		result.append(_rect(Rect2(center-size*.5,size)))
	return result

static func _rect(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])

static func _translate_pair(row: Dictionary,key: String) -> void:
	if not row.has(key):return
	var raw: Variant=row[key]
	if raw is Vector2:row[key]=raw+DELTA
	elif raw is Array and raw.size()==2:row[key]=[float(raw[0])+DELTA.x,float(raw[1])+DELTA.y]

static func place(layout: WalkableMapLayout) -> Dictionary:
	var compound_index: int=-1;var portal_index: int=-1
	for i: int in layout.visual_objects.size():
		if layout.visual_objects[i].get("id")=="compound_bianzhou":
			if compound_index!=-1:return {"ok":false,"error":"DUPLICATE_BIANZHOU_COMPOUND"}
			compound_index=i
	for i: int in layout.portals.size():
		if layout.portals[i].get("id")=="bianzhou":portal_index=i
	if compound_index<0 or portal_index<0:return {"ok":false,"error":"EXACT_BIANZHOU_COMPOUND_AND_PORTAL_REQUIRED"}
	var compound: Dictionary=layout.visual_objects[compound_index].duplicate(true)
	var portal: Dictionary=layout.portals[portal_index].duplicate(true)
	var old_door: Vector2=Vector2(portal.pos)*WORLD
	if old_door!=Vector2(7600,2196.8779296875):return {"ok":false,"error":"UNEXPECTED_OLD_BIANZHOU_FOOT"}
	var old_solids: Array[PackedVector2Array]=_polygons(compound)
	compound.pos=Vector2(compound.pos)+DELTA/WORLD
	compound.depth_sort_foot_y=float(compound.depth_sort_foot_y)+DELTA.y/WORLD.y
	for key: String in ["world_foot_px","source_XZ_foot_px","collision_center_world_px"]:_translate_pair(compound,key)
	var new_solids: Array[PackedVector2Array]=[]
	for old: PackedVector2Array in old_solids:
		var shifted:=PackedVector2Array()
		for p: Vector2 in old:shifted.append(p+DELTA)
		new_solids.append(shifted)
	compound.solid_polygons_px=new_solids
	compound["candidate_placement_translation_px"]=[DELTA.x,DELTA.y]
	portal.pos=Vector2(portal.pos)+DELTA/WORLD
	if portal.has("source_spawn_pos"):portal.source_spawn_pos=Vector2(portal.source_spawn_pos)+DELTA/WORLD
	for key: String in ["door_foot_px","source_XZ_foot_px","arrival_foot_px"]:_translate_pair(portal,key)
	for key: String in ["interaction_polygon_px","passage_polygon_px","passage_path_px"]:
		if not portal.has(key):continue
		var raw: Variant=portal[key];var shifted:=PackedVector2Array()
		if raw is PackedVector2Array:
			for p: Vector2 in raw:shifted.append(p+DELTA)
			portal[key]=shifted
		elif raw is Array:
			var points: Array=[]
			for p: Array in raw:points.append([float(p[0])+DELTA.x,float(p[1])+DELTA.y])
			portal[key]=points
	layout.visual_objects[compound_index]=compound;layout.portals[portal_index]=portal
	_record={"portal_id":"bianzhou","old_door_foot_px":[old_door.x,old_door.y],"new_door_foot_px":[(old_door+DELTA).x,(old_door+DELTA).y],"compound_translation_px":[0,-640],"old_compound_solid_polygons_px":_json_polygons(old_solids),"new_compound_solid_polygons_px":_json_polygons(new_solids),"approach_points_px":_json_polygon(approach()),"plaza":{"center_px":[7600,1800],"radius_px":[250,160],"probe_feet_px":[[7600,1800],[7350,1800],[7850,1800],[7600,1640],[7600,1960]]},"retired_conflicting_tree_ids":[],"geometry_check":{"status":"PENDING"},"bridge_93_rows_changed":false}
	return {"ok":true,"record":_record}

static func _json_polygon(polygon: PackedVector2Array) -> Array:
	var result: Array=[]
	for p: Vector2 in polygon:result.append([p.x,p.y])
	return result

static func _json_polygons(polygons: Array[PackedVector2Array]) -> Array:
	var result: Array=[]
	for polygon: PackedVector2Array in polygons:result.append(_json_polygon(polygon))
	return result

static func migration_region() -> Dictionary:
	return {"id":"bianzhou_new_compound_old_legal_site","source_polygon_px":[[7270,1360],[7970,1360],[7970,1590],[7270,1590]],"historic_portal_id":"bianzhou"}

static func verify(layout: WalkableMapLayout,nav_clear: Callable) -> Dictionary:
	var obstacles: Array[Dictionary]=[];var building: Array[PackedVector2Array]=[]
	for row: Dictionary in layout.visual_objects:
		var polygons: Array[PackedVector2Array]=_polygons(row)
		if row.get("id")=="compound_bianzhou":building=polygons;continue
		for polygon: PackedVector2Array in polygons:
			var bounds:=Rect2(polygon[0],Vector2.ZERO)
			for p: Vector2 in polygon:bounds=bounds.expand(p)
			if DOMAIN.grow(32).intersects(bounds):obstacles.append({"id":String(row.get("id","")),"polygon":polygon,"bounds":bounds})
	# No arbitrary clearing: a protected bridge/stone/building or any other
	# undeclared body conflict rejects this exact proposal rather than deleting it.
	for solid: PackedVector2Array in building:
		for obstacle: Dictionary in obstacles:
			if not Geometry2D.intersect_polygons(solid,obstacle.polygon).is_empty():return {"ok":false,"error":"NEW_COMPOUND_BODY_CONFLICT:"+String(obstacle.id)}
	var checks:=0;var samples:=PackedVector2Array()
	samples.append(Vector2(_record.new_door_foot_px[0],_record.new_door_foot_px[1]))
	for p: Array in _record.plaza.probe_feet_px:samples.append(Vector2(p[0],p[1]))
	var path: PackedVector2Array=approach()
	for i: int in path.size()-1:
		var steps: int=ceili(path[i].distance_to(path[i+1])/8.0)
		for step: int in steps+1:samples.append(path[i].lerp(path[i+1],float(step)/maxf(1,steps)))
	for y: int in range(1640,1961,24):
		for x: int in range(7350,7851,24):
			var p:=Vector2(x,y)
			if ((p-PLAZA_CENTER)/PLAZA_RADIUS).length()<=1:samples.append(p)
	var full_obstacles: Array[Dictionary]=obstacles.duplicate()
	for solid: PackedVector2Array in building:
		var bounds:=Rect2(solid[0],Vector2.ZERO)
		for p: Vector2 in solid:bounds=bounds.expand(p)
		full_obstacles.append({"id":"compound_bianzhou","polygon":solid,"bounds":bounds})
	for p: Vector2 in samples:
		if not _full_foot_clear(p,full_obstacles,nav_clear):return {"ok":false,"error":"BIANZHOU_DOOR_PLAZA_APPROACH_FOOT_REJECTED","foot_px":[p.x,p.y]}
		checks+=1
	# Check the complete occupied foundation on original RF/terrain NAV, not an
	# assumed level grass rectangle. Own footprint is excluded only for support.
	var foundation_samples:=0
	for y: int in range(1360,1591,16):
		for x: int in range(7270,7971,16):
			var p:=Vector2(x,y);var inside:=false
			for solid: PackedVector2Array in building:
				if Geometry2D.is_point_in_polygon(p,solid):inside=true;break
			if inside:
				if not _full_foot_clear(p,obstacles,nav_clear):return {"ok":false,"error":"NEW_COMPOUND_FOUNDATION_UNSUPPORTED","foot_px":[p.x,p.y]}
				foundation_samples+=1
	_record.geometry_check={"status":"PASSED_CANDIDATE_SOURCE_GEOMETRY_ONLY","door_approach_plaza_full35x25_feet":checks,"foundation_full35x25_feet":foundation_samples,"other_obstacle_polygons_checked":obstacles.size(),"native_RF_unchanged_in_bianzhou":true,"not_Field_or_ART_approval":true}
	return {"ok":true,"record":_record}

static func _full_foot_clear(p: Vector2,obstacles: Array[Dictionary],nav_clear: Callable) -> bool:
	var rect:=Rect2(p-Vector2(17,12),Vector2(34,24));var polygon: PackedVector2Array=_rect(rect)
	for obstacle: Dictionary in obstacles:
		if rect.intersects(obstacle.bounds) and not Geometry2D.intersect_polygons(polygon,obstacle.polygon).is_empty():return false
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			if not bool(nav_clear.call(p+Vector2(x,y))):return false
	return true

static func road_shader_functions() -> String:
	return """
float coast31h_segment(vec2 p,vec2 a,vec2 b){vec2 v=b-a;return length(p-a-v*clamp(dot(p-a,v)/max(dot(v,v),.001),0.,1.));}
vec3 coast31h_bianzhou_road(vec3 original,vec2 p){
 float d=min(min(coast31h_segment(p,vec2(7830.06396484375,2294.90063476563),vec2(8050.,2150.)),coast31h_segment(p,vec2(8050.,2150.),vec2(8050.,1850.))),min(coast31h_segment(p,vec2(8050.,1850.),vec2(7600.,1800.)),coast31h_segment(p,vec2(7600.,1800.),vec2(7600.,1556.8779296875))));
 float ellipse=(length((p-vec2(7600.,1800.))/vec2(250.,160.))-1.)*160.;
 float owner=1.-smoothstep(38.,64.,d);owner=max(owner,1.-smoothstep(-12.,18.,ellipse));
 float retired=min(coast31h_segment(p,vec2(7840.,2295.),vec2(7840.,2230.)),min(coast31h_segment(p,vec2(7840.,2230.),vec2(7600.,2230.)),coast31h_segment(p,vec2(7600.,2230.),vec2(7600.,2196.8779296875))));
 float remove=1.-smoothstep(42.,70.,retired);
 original.rg*=1.-remove;original.rg=max(original.rg,vec2(owner));return original;
}
"""
