extends SceneTree
## Authoring aid ONLY: derives proposed witnesses from current raw navigation
## and original measured solids. Never signs visual/technical/Field approval.
const SOURCE := "res://data/maps/world_map_v15_complete_v6_source.json"
const MANIFEST := "res://art/maps/world_map_v15_complete_v6/art_contract.json"
const FOOTPRINT := "res://data/maps/world_map_v15_complete_v5_landmark_footprints_candidate.json"
const RAW = preload("res://tests/helpers/joint_v15_world_raw_oracle.gd")
const SIZE := Vector2(12288,8192)
const VECTOR_KEYS := ["pos","size","collision_size","collision_offset","walkability_margin_px","render_size_px","scale"]
var error := ""
var oracle: RefCounted

func _initialize() -> void:
	_run.call_deferred()

func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

func _pair(value: Vector2) -> Array:
	return [value.x,value.y]

func _polygon(raw: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for pair: Array in raw: result.append(_point(pair))
	return result

func _runtime(raw: Dictionary) -> Dictionary:
	var value := raw.duplicate(true)
	for key: String in VECTOR_KEYS:
		if value.get(key) is Array and value[key].size()==2: value[key]=_point(value[key])
	if value.get("solid_polygons_px") is Array:
		var polygons: Array=[]
		for polygon: Array in value.solid_polygons_px: polygons.append(_polygon(polygon))
		value.solid_polygons_px=polygons
	return value

func _legal_outside(point: Vector2, polygon: PackedVector2Array) -> bool:
	return bool(oracle.call("clear",point)) and not Geometry2D.is_point_in_polygon(point,polygon)

func _wall(compound: Dictionary, door_polygon: PackedVector2Array) -> Dictionary:
	# Prefer a front wall face that can actually be approached on clear ground.
	for raw_polygon: Array in compound.solid_polygons_px:
		var solid := _polygon(raw_polygon)
		var bounds := Rect2(solid[0],Vector2.ZERO)
		for point: Vector2 in solid: bounds=bounds.expand(point)
		for x in range(ceili(bounds.position.x+12),floori(bounds.end.x-12)+1,16):
			for inset: float in [8.,16.,24.,40.]:
				var blocked := Vector2(x,bounds.end.y-inset)
				var reason: Dictionary=oracle.call("foot_evidence",blocked)
				if reason.get("kind")!="source_collision" or reason.get("id")!=compound.id: continue
				for distance: float in [24.,40.,64.,96.]:
					var stand := Vector2(x,bounds.end.y+distance)
					if _legal_outside(stand,door_polygon):
						return {"kind":"wall_approach","legal_start_px":_pair(stand),"blocked_foot_px":_pair(blocked),"solid_id":compound.id,"solid_polygon_world_px":raw_polygon,"navigation_preflight":reason}
	return {}

func _roof(compound: Dictionary, portal: Dictionary, stand: Vector2) -> Dictionary:
	var image := Image.load_from_file(String(compound.texture))
	if image==null: return {}
	var center := _point(compound.pos)*SIZE
	var size := _point(compound.render_size_px)
	var door_polygon := _polygon(portal.interaction_polygon_px)
	for uv: Vector2 in [Vector2(.5,.22),Vector2(.5,.30),Vector2(.5,.36),Vector2(.4,.25),Vector2(.6,.25)]:
		var pixel := Vector2i(floori(uv.x*image.get_width()),floori(uv.y*image.get_height()))
		var click := center+(uv-Vector2(.5,.5))*size
		if image.get_pixelv(pixel).a>.5 and not Geometry2D.is_point_in_polygon(click,door_polygon):
			return {"kind":"roof_click","legal_stand_px":_pair(stand),"source_uv":_pair(uv),"world_click_px":_pair(click),"source_pixel_rgba":image.get_pixelv(pixel).to_html(true),"semantic_verdict":"PENDING_ROOT_ORIGINAL_ROOF_PIXEL_REVIEW"}
	return {}

func _wrongside(portal: Dictionary) -> Dictionary:
	var foot := _point(portal.door_foot_px)
	var polygon := _polygon(portal.interaction_polygon_px)
	for offset: Vector2 in [Vector2(220,80),Vector2(-220,80),Vector2(180,120),Vector2(-180,120),Vector2(0,160),Vector2(0,240)]:
		var stand := foot+offset
		if _legal_outside(stand,polygon): return {"kind":"wrongside","legal_stand_px":_pair(stand),"world_click_px":_pair(foot)}
	return {}

func _run() -> void:
	if "--draft-current-whole-negative-witnesses" not in OS.get_cmdline_user_args():
		push_error("Explicit authoring-only draft flag required"); quit(1); return
	var source: Variant=JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	var manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not source is Dictionary or not manifest is Dictionary or source.get("status")!="ART_ASSETS_READY":
		push_error("Actual FULL source absent; no proposed witnesses"); quit(1); return
	var layout := WalkableMapLayout.new()
	layout.schema_version=15
	layout.design_size=Vector2i(SIZE)
	for chunk: Dictionary in source.chunks:
		var rect: Array=chunk.logical_rect_px
		layout.walkable_mask_tiles.append({"path":chunk.walk_path,"logical_rect":Rect2(rect[0],rect[1],rect[2],rect[3])})
	var compounds: Dictionary={}
	for object: Dictionary in source.objects:
		layout.visual_objects.append(_runtime(object))
		if String(object.id).begins_with("compound_"): compounds[object.id]=object
	for blocker: Dictionary in source.get("blockers",[]): layout.blockers.append(_runtime(blocker))
	oracle=RAW.new()
	if not bool(oracle.call("configure",layout)):
		push_error(str(oracle.get("errors"))); quit(1); return
	var proposals: Dictionary={}
	for portal: Dictionary in source.portals:
		var compound: Dictionary=compounds.get(portal.compound_id,{})
		var wall := _wall(compound,_polygon(portal.interaction_polygon_px)) if not compound.is_empty() else {}
		var wrong := _wrongside(portal)
		var roof := _roof(compound,portal,_point(wrong.legal_stand_px)) if not wrong.is_empty() and not compound.is_empty() else {}
		if wall.is_empty() or roof.is_empty() or wrong.is_empty():
			error="Missing valid proposed negative geometry: "+String(portal.id); break
		for row: Dictionary in [wall,roof,wrong]: row["semantic_review_status"]="PENDING_ROOT_ACTUAL_CURRENT_CAPTURE"
		proposals[portal.id]={"status":"PENDING_ROOT_REVIEW_NOT_APPROVAL","source":portal.source,"source_sha256":portal.source_sha256,"door_foot_px":portal.door_foot_px,"source_doorstep_uv":portal.source_doorstep_uv,"compound_id":portal.compound_id,"doorstep_review_image_path":portal.doorstep_review_image_path,"doorstep_review_image_sha256":portal.doorstep_review_image_sha256,"negative_origin":"INDEPENDENT_ROOT_REVIEW_AUTHORED_NEGATIVES_V1","negative_source_footprint_path":FOOTPRINT,"negative_source_footprint_sha256":FileAccess.get_sha256(FOOTPRINT),"input_negative_probes":[wall,roof,wrong]}
	var unchanged := bool(oracle.call("verify_sources"))
	oracle.call("release")
	oracle=null
	if not error.is_empty() or not unchanged:
		push_error(error if not error.is_empty() else "Original nav mutated"); quit(1); return
	var output := "res://build/joint_world_luoyang_20261003_qa/negative_draft_%d_%d.json"%[Time.get_unix_time_from_system(),Time.get_ticks_usec()]
	if FileAccess.file_exists(output):
		push_error("Refusing to overwrite an existing authoring proposal"); quit(1); return
	var report := {"schema":1,"scope":"AUTHORING_PROPOSALS_NOT_APPROVED_NOT_FIELD_INPUT","source_sha256":FileAccess.get_sha256(SOURCE),"manifest_sha256":FileAccess.get_sha256(MANIFEST),"executing_source_sha256":FileAccess.get_sha256(get_script().resource_path),"doors":proposals,"visual_approved":false,"field_executed":false}
	var file := FileAccess.open(output,FileAccess.WRITE)
	if file==null: push_error("Cannot save new unapproved draft"); quit(1); return
	file.store_string(JSON.stringify(report,"\t")); file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_error("Draft write failed: "+str(write_error)); quit(1); return
	if JSON.parse_string(FileAccess.get_file_as_string(output))!=JSON.parse_string(JSON.stringify(report)):
		push_error("Draft readback failed"); quit(1); return
	print("WORLD_WHOLE_NEGATIVE_DRAFT_NOT_APPROVED: ",output)
	quit(0)
